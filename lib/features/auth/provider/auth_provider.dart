import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../../../services/crypto_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../services/storage_service.dart';
import '../model/user_profile.dart';

// ── AuthResult ─────────────────────────────────────────────────────────────────

/// Hasil operasi autentikasi — digunakan sebagai return value seluruh
/// method auth agar Screen tidak perlu catch exception secara langsung.
class AuthResult {
  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  /// Operasi berhasil.
  factory AuthResult.success() => const AuthResult._(isSuccess: true);

  /// Operasi gagal dengan pesan error yang aman ditampilkan ke UI.
  factory AuthResult.error(String message) => AuthResult._(
        isSuccess: false,
        errorMessage: message,
      );

  /// `true` jika operasi berhasil.
  final bool isSuccess;

  /// Pesan error untuk ditampilkan di UI. `null` jika [isSuccess] = true.
  final String? errorMessage;

  @override
  String toString() => isSuccess
      ? 'AuthResult.success()'
      : 'AuthResult.error($errorMessage)';
}

// ── AuthProvider ──────────────────────────────────────────────────────────────

/// AuthProvider — mengelola seluruh state dan logika autentikasi ZeroCrypt.
///
/// State yang dikelola:
///   - Status autentikasi ([isAuthenticated])
///   - Profil pengguna ([profile])
///   - Loading indicator ([isLoading])
///   - Lockout setelah gagal berulang ([isLockedOut], [remainingLockout])
///
/// Lockout policy:
///   - ≥ 3 percobaan gagal → lockout 30 detik
///   - Lockout direset otomatis setelah durasi habis
///
/// Semua method mengikuti pola skill/provider-patterns.md:
///   - Logic di Provider, BUKAN di Screen
///   - Services diinjeksi via constructor
///   - notifyListeners() hanya saat state benar-benar berubah
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required CryptoService crypto,
    required SecureStorageService secureStorage,
    required StorageService storage,
  })  : _crypto = crypto,
        _secureStorage = secureStorage,
        _storage = storage;

  // ── Dependencies ─────────────────────────────────────────────────────────────

  final CryptoService _crypto;
  final SecureStorageService _secureStorage;
  final StorageService _storage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ── State ─────────────────────────────────────────────────────────────────────

  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserProfile? _profile;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  // ── Lockout config ───────────────────────────────────────────────────────────

  static const int _maxFailedAttempts  = 3;
  static const int _lockoutSeconds     = 30;

  // ── Getters ──────────────────────────────────────────────────────────────────

  /// `true` jika pengguna sudah berhasil login.
  bool get isAuthenticated => _isAuthenticated;

  /// `true` saat sedang memproses operasi async (tampilkan loading indicator).
  bool get isLoading => _isLoading;

  /// Profil pengguna yang aktif. `null` jika belum login atau belum load.
  UserProfile? get profile => _profile;

  /// Jumlah percobaan login yang gagal sejak terakhir berhasil.
  int get failedAttempts => _failedAttempts;

  /// `true` jika akun sedang dalam masa lockout.
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  /// Sisa waktu lockout. `null` jika tidak sedang locked.
  Duration? get remainingLockout {
    if (_lockoutUntil == null) return null;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  void _setLoading(bool val) {
    if (_isLoading == val) return;
    _isLoading = val;
    notifyListeners();
  }

  /// Aktifkan lockout selama [_lockoutSeconds] detik.
  void _triggerLockout() {
    _lockoutUntil = DateTime.now().add(
      const Duration(seconds: _lockoutSeconds),
    );
    notifyListeners();
  }

  /// Cek dan bersihkan lockout yang sudah expired.
  /// Return `true` jika masih dalam lockout.
  bool _checkAndRefreshLockout() {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isBefore(_lockoutUntil!)) return true;
    // Lockout sudah expired — bersihkan
    _lockoutUntil = null;
    return false;
  }

  // ── 1. hasExistingProfile ─────────────────────────────────────────────────────

  /// Cek apakah sudah ada profil yang tersimpan (pengguna sudah registrasi).
  ///
  /// Digunakan oleh SplashScreen untuk routing:
  ///   - `true`  → /login
  ///   - `false` → /register
  Future<bool> hasExistingProfile() async {
    return _secureStorage.hasProfile();
  }

  // ── 2. loadProfile ────────────────────────────────────────────────────────────

  /// Load profil pengguna dari [StorageService].
  ///
  /// Dipanggil setelah login berhasil untuk mengisi state [_profile].
  Future<void> loadProfile() async {
    final displayName      = await _storage.getDisplayName();
    final biometricEnabled = await _storage.getBiometricEnabled();
    final autoLockMinutes  = await _storage.getAutoLockDuration();

    _profile = UserProfile(
      displayName: displayName,
      biometricEnabled: biometricEnabled,
      autoLockMinutes: autoLockMinutes,
    );
    notifyListeners();
  }

  // ── 3. register ───────────────────────────────────────────────────────────────

  /// Registrasi pengguna baru dengan master password.
  ///
  /// Urutan operasi:
  ///   1. Validasi input
  ///   2. Hash master password (SHA-256) — BUKAN plaintext yang disimpan
  ///   3. Simpan hash ke [SecureStorageService]
  ///   4. Simpan profil (displayName, settings) ke [StorageService]
  ///   5. Set [_isAuthenticated] = true
  ///
  /// Return [AuthResult.success()] atau [AuthResult.error(message)].
  Future<AuthResult> register({
    required String displayName,
    required String masterPassword,
    bool enableBiometric = false,
  }) async {
    _setLoading(true);

    try {
      // Validasi input
      if (displayName.trim().isEmpty) {
        return AuthResult.error('Nama tidak boleh kosong');
      }
      if (masterPassword.length < 8) {
        return AuthResult.error('Master password minimal 8 karakter');
      }

      // Hash password — TIDAK simpan plaintext
      final hash = _crypto.hashPassword(masterPassword);

      // Simpan hash ke secure storage
      await _secureStorage.saveMasterHash(hash);

      // Simpan profil ke SharedPreferences (non-sensitif)
      await _storage.saveDisplayName(displayName.trim());
      await _storage.setBiometricEnabled(enableBiometric);
      await _storage.setAutoLockDuration(5); // default 5 menit

      // Load profil ke state
      _profile = UserProfile(
        displayName: displayName.trim(),
        biometricEnabled: enableBiometric,
        autoLockMinutes: 5,
      );

      // Set authenticated
      _isAuthenticated = true;
      _failedAttempts  = 0;
      _lockoutUntil    = null;

      notifyListeners();
      return AuthResult.success();
    } catch (e) {
      return AuthResult.error('Registrasi gagal. Coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  // ── 4. login ──────────────────────────────────────────────────────────────────

  /// Login dengan master password.
  ///
  /// Lockout policy:
  ///   - Cek lockout sebelum proses apapun
  ///   - ≥ [_maxFailedAttempts] gagal berturut → lockout [_lockoutSeconds] detik
  ///   - Berhasil → reset [_failedAttempts] dan [_lockoutUntil]
  ///
  /// Return [AuthResult.success()] atau [AuthResult.error(message)].
  Future<AuthResult> login(String masterPassword) async {
    // Cek lockout aktif
    if (_checkAndRefreshLockout()) {
      final remaining = remainingLockout;
      final seconds   = remaining?.inSeconds ?? _lockoutSeconds;
      return AuthResult.error(
        'Terlalu banyak percobaan gagal. Coba lagi dalam $seconds detik.',
      );
    }

    if (masterPassword.isEmpty) {
      return AuthResult.error('Master password tidak boleh kosong');
    }

    _setLoading(true);

    try {
      // Ambil hash tersimpan
      final storedHash = await _secureStorage.getMasterHash();
      if (storedHash == null || storedHash.isEmpty) {
        return AuthResult.error('Profil tidak ditemukan. Silakan registrasi.');
      }

      // Verifikasi password
      final isValid = _crypto.verifyPassword(masterPassword, storedHash);

      if (isValid) {
        // ── Login berhasil ──
        _isAuthenticated = true;
        _failedAttempts  = 0;
        _lockoutUntil    = null;

        // Load profil
        await loadProfile();

        notifyListeners();
        return AuthResult.success();
      } else {
        // ── Login gagal ──
        _failedAttempts++;

        if (_failedAttempts >= _maxFailedAttempts) {
          _triggerLockout();
          return AuthResult.error(
            'Password salah. Akun dikunci selama $_lockoutSeconds detik.',
          );
        }

        final remaining = _maxFailedAttempts - _failedAttempts;
        notifyListeners();
        return AuthResult.error(
          'Password salah. $remaining percobaan tersisa.',
        );
      }
    } catch (e) {
      return AuthResult.error('Login gagal. Coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  // ── 5. loginWithBiometric ─────────────────────────────────────────────────────

  /// Login menggunakan biometrik (fingerprint / face ID).
  ///
  /// Prasyarat:
  ///   - [UserProfile.biometricEnabled] = true
  ///   - Device mendukung biometrik
  ///   - Biometrik sudah terdaftar di device
  ///
  /// Return [AuthResult.success()] atau [AuthResult.error(message)].
  Future<AuthResult> loginWithBiometric() async {
    // Cek lockout
    if (_checkAndRefreshLockout()) {
      final seconds = remainingLockout?.inSeconds ?? _lockoutSeconds;
      return AuthResult.error(
        'Akun dikunci. Coba lagi dalam $seconds detik.',
      );
    }

    _setLoading(true);

    try {
      // Cek apakah device support biometrik
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported  = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return AuthResult.error(
          'Perangkat tidak mendukung autentikasi biometrik.',
        );
      }

      // Tampilkan dialog biometrik sistem
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Konfirmasi identitas Anda untuk membuka ZeroCrypt',
        options: const AuthenticationOptions(
          biometricOnly: false, // Fallback ke PIN device jika perlu
          stickyAuth: true,     // Tetap tampil meski app background sebentar
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        _isAuthenticated = true;
        _failedAttempts  = 0;
        _lockoutUntil    = null;

        await loadProfile();

        notifyListeners();
        return AuthResult.success();
      } else {
        return AuthResult.error('Autentikasi biometrik dibatalkan.');
      }
    } catch (e) {
      // Tangkap error platform (biometrik tidak tersedia, dll)
      return AuthResult.error(
        'Autentikasi biometrik gagal. Gunakan master password.',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ── 6. logout ─────────────────────────────────────────────────────────────────

  /// Logout — hapus state autentikasi dan session key.
  ///
  /// Profile tetap tersimpan di storage (pengguna tidak perlu re-registrasi).
  /// Vault items tetap ada (terenkripsi).
  void logout() {
    _isAuthenticated = false;
    _profile         = null;
    _failedAttempts  = 0;
    _lockoutUntil    = null;

    // Hapus session key dari secure storage secara async
    // (tidak perlu await — fire and forget untuk UX yang responsif)
    _secureStorage.clearSessionKey().ignore();

    notifyListeners();
  }

  // ── 7. updateProfile ─────────────────────────────────────────────────────────

  /// Update profil pengguna (display name, biometric, auto-lock).
  ///
  /// Persist ke [StorageService] dan update state [_profile].
  Future<AuthResult> updateProfile({
    String? displayName,
    bool? biometricEnabled,
    int? autoLockMinutes,
  }) async {
    if (_profile == null) {
      return AuthResult.error('Tidak ada profil aktif.');
    }

    _setLoading(true);

    try {
      final updated = _profile!.copyWith(
        displayName: displayName,
        biometricEnabled: biometricEnabled,
        autoLockMinutes: autoLockMinutes,
      );

      if (displayName != null) {
        await _storage.saveDisplayName(displayName);
      }
      if (biometricEnabled != null) {
        await _storage.setBiometricEnabled(biometricEnabled);
      }
      if (autoLockMinutes != null) {
        await _storage.setAutoLockDuration(autoLockMinutes);
      }

      _profile = updated;
      notifyListeners();
      return AuthResult.success();
    } catch (e) {
      return AuthResult.error('Gagal menyimpan perubahan profil.');
    } finally {
      _setLoading(false);
    }
  }

  // ── 8. changeMasterPassword ───────────────────────────────────────────────────

  /// Ganti master password.
  ///
  /// Memerlukan verifikasi password lama sebelum set yang baru.
  /// Vault items yang ada TIDAK perlu di-re-encrypt karena key derivation
  /// selalu dilakukan fresh dari password — tapi di sesi mendatang vault
  /// items lama tidak bisa didekripsi dengan password baru.
  ///
  /// TODO(sesi-3): Implementasi re-encryption vault items saat ganti password.
  Future<AuthResult> changeMasterPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      return AuthResult.error('Password baru minimal 8 karakter.');
    }

    _setLoading(true);

    try {
      // Verifikasi password lama
      final storedHash = await _secureStorage.getMasterHash();
      if (storedHash == null) {
        return AuthResult.error('Profil tidak ditemukan.');
      }

      if (!_crypto.verifyPassword(oldPassword, storedHash)) {
        return AuthResult.error('Password lama tidak cocok.');
      }

      // Simpan hash password baru
      final newHash = _crypto.hashPassword(newPassword);
      await _secureStorage.saveMasterHash(newHash);

      return AuthResult.success();
    } catch (e) {
      return AuthResult.error('Gagal mengganti password.');
    } finally {
      _setLoading(false);
    }
  }
}
