import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// SecureStorageService — wrapper FlutterSecureStorage untuk data sensitif.
///
/// Digunakan untuk menyimpan:
///   - Hash master password (untuk verifikasi login)
///   - Session key sementara (in-memory fallback jika diperlukan)
///
/// Platform config:
///   - Android: EncryptedSharedPreferences (AES-256 via Keystore)
///   - iOS: Keychain dengan akses first_unlock
///
/// ATURAN:
///   - TIDAK pernah simpan plaintext master password di sini.
///   - Hanya simpan hasil [CryptoService.hashPassword()].
///   - Hapus semua data saat logout / panic wipe.
class SecureStorageService {
  // ── Storage instance (singleton-friendly, const) ───────────────────────────

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // AES-256 via Android Keystore
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ── Key constants ──────────────────────────────────────────────────────────

  static const String _keyMasterHash  = 'zc_master_hash';
  static const String _keySessionKey  = 'zc_session_key';
  static const String _keyProfileFlag = 'zc_has_profile';

  // ── Master Password Hash ───────────────────────────────────────────────────

  /// Simpan [hash] hasil [CryptoService.hashPassword()].
  ///
  /// JANGAN panggil dengan plaintext password — selalu hash dulu.
  Future<void> saveMasterHash(String hash) async {
    await _storage.write(key: _keyMasterHash, value: hash);
    // Tandai bahwa profil sudah dibuat
    await _storage.write(key: _keyProfileFlag, value: 'true');
  }

  /// Ambil hash master password yang tersimpan.
  ///
  /// Return `null` jika belum pernah di-set (pengguna belum registrasi).
  Future<String?> getMasterHash() async {
    return _storage.read(key: _keyMasterHash);
  }

  // ── Session Key ────────────────────────────────────────────────────────────

  /// Simpan [key] sesi sementara — misal derived key yang di-cache
  /// selama session aktif untuk menghindari re-derive setiap operasi.
  ///
  /// CATATAN: Session key WAJIB dihapus saat logout / auto-lock / app close.
  Future<void> saveSessionKey(String key) async {
    await _storage.write(key: _keySessionKey, value: key);
  }

  /// Ambil session key yang tersimpan.
  ///
  /// Return `null` jika session sudah berakhir atau belum di-set.
  Future<String?> getSessionKey() async {
    return _storage.read(key: _keySessionKey);
  }

  /// Hapus session key — panggil saat logout atau auto-lock aktif.
  Future<void> clearSessionKey() async {
    await _storage.delete(key: _keySessionKey);
  }

  // ── Profile Check ──────────────────────────────────────────────────────────

  /// Return `true` jika pengguna sudah pernah registrasi (ada master hash).
  ///
  /// Digunakan oleh SplashScreen untuk routing:
  ///   - `true`  → navigate ke /login
  ///   - `false` → navigate ke /register
  Future<bool> hasProfile() async {
    final flag = await _storage.read(key: _keyProfileFlag);
    return flag == 'true';
  }

  // ── Clear All ──────────────────────────────────────────────────────────────

  /// Hapus SEMUA data dari secure storage — untuk logout total / panic wipe.
  ///
  /// Setelah pemanggilan ini, [hasProfile()] akan return `false`.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ── Debug helper (hanya untuk development) ────────────────────────────────

  /// Cek apakah master hash sudah tersimpan (alias [hasProfile]).
  /// Disediakan sebagai alias eksplisit untuk keterbacaan kode.
  Future<bool> hasMasterHash() async {
    final hash = await getMasterHash();
    return hash != null && hash.isNotEmpty;
  }
}
