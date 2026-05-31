import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Kekuatan password — digunakan oleh [CryptoService.checkStrength].
enum PasswordStrength {
  /// < 8 karakter
  weak,

  /// ≥ 8 karakter tapi variasi kurang (tidak ada angka / huruf besar)
  fair,

  /// ≥ 12 karakter + huruf besar + angka
  strong,

  /// ≥ 16 karakter + huruf besar + angka + simbol
  veryStrong,
}

/// CryptoService — semua operasi enkripsi/dekripsi ZeroCrypt.
///
/// Prinsip keamanan yang WAJIB dijaga:
///   1. Master password TIDAK pernah disimpan — hanya hash-nya.
///   2. Setiap enkripsi menggunakan IV random baru (tidak pernah reuse).
///   3. Key diderivasi ulang dari password setiap kali dibutuhkan.
///   4. TIDAK ada logging untuk plaintext, key, IV, atau ciphertext.
///   5. TIDAK ada network call apapun.
///
/// Format payload terenkripsi: `"base64(iv):base64(ciphertext+authTag)"`
///
/// Contoh penggunaan:
/// ```dart
/// final crypto = CryptoService();
///
/// // Enkripsi
/// final payload = crypto.encrypt('password123', masterPassword);
///
/// // Dekripsi
/// final plain = crypto.decrypt(payload, masterPassword);
///
/// // Verifikasi master password
/// final hash = crypto.hashPassword(inputPassword);
/// final isValid = hash == storedHash;
///
/// // Cek kekuatan
/// final strength = crypto.checkStrength(password);
/// ```
class CryptoService {
  // ── Konstanta internal ─────────────────────────────────────────────────────

  /// Separator antara IV dan ciphertext dalam payload
  static const String _separator = ':';

  // ── 1. Key Derivation ──────────────────────────────────────────────────────

  /// Menurunkan [enc.Key] AES-256 dari [masterPassword] menggunakan SHA-256.
  ///
  /// SHA-256 menghasilkan 32 bytes → cocok untuk AES-256.
  /// Key diderivasi fresh setiap kali dipanggil; tidak di-cache di memori.
  ///
  /// PENTING: Fungsi ini bersifat deterministic — password yang sama
  /// selalu menghasilkan key yang sama. Tidak menggunakan salt karena
  /// key ini hanya dipakai untuk enkripsi data, bukan simpan ke storage.
  enc.Key deriveKey(String masterPassword) {
    final bytes = utf8.encode(masterPassword);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  // ── 2. Enkripsi ─────────────────────────────────────────────────────────────

  /// Mengenkripsi [plaintext] menggunakan AES-256-GCM.
  ///
  /// - IV 16-byte di-generate secara random setiap pemanggilan.
  /// - GCM mode menyertakan authentication tag → integritas terjamin.
  /// - Return format: `"base64(iv):base64(ciphertext)"`
  ///
  /// Throws [ArgumentError] jika [plaintext] atau [masterPassword] kosong.
  String encrypt(String plaintext, String masterPassword) {
    if (plaintext.isEmpty) throw ArgumentError('plaintext tidak boleh kosong');
    if (masterPassword.isEmpty) {
      throw ArgumentError('masterPassword tidak boleh kosong');
    }

    final key       = deriveKey(masterPassword);
    final iv        = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    // Format: base64(iv):base64(ciphertext+authTag)
    return '${iv.base64}$_separator${encrypted.base64}';
  }

  // ── 3. Dekripsi ─────────────────────────────────────────────────────────────

  /// Mendekripsi [payload] yang dihasilkan oleh [encrypt].
  ///
  /// - Memvalidasi format payload sebelum proses.
  /// - GCM mode memverifikasi authentication tag secara otomatis.
  ///
  /// Throws [FormatException] jika format payload tidak valid.
  /// Throws [Exception] jika password salah (GCM auth tag mismatch).
  String decrypt(String payload, String masterPassword) {
    if (payload.isEmpty) throw FormatException('payload tidak boleh kosong');
    if (masterPassword.isEmpty) {
      throw ArgumentError('masterPassword tidak boleh kosong');
    }

    final parts = payload.split(_separator);
    if (parts.length != 2) {
      throw FormatException(
        'Format payload tidak valid — '
        'expected "base64(iv):base64(ciphertext)", got ${parts.length} parts',
      );
    }

    final ivPart         = parts[0];
    final ciphertextPart = parts[1];

    if (ivPart.isEmpty || ciphertextPart.isEmpty) {
      throw FormatException('IV atau ciphertext kosong dalam payload');
    }

    try {
      final key       = deriveKey(masterPassword);
      final iv        = enc.IV.fromBase64(ivPart);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      return encrypter.decrypt64(ciphertextPart, iv: iv);
    } on FormatException {
      rethrow;
    } catch (e) {
      // Tangkap error GCM auth-tag mismatch (password salah / data korup)
      // Jangan expose detail teknis ke luar — log hanya type-nya
      throw Exception('Dekripsi gagal — password salah atau data korup');
    }
  }

  // ── 4. Hash Password ────────────────────────────────────────────────────────

  /// Menghash [password] dengan SHA-256, return hex string (64 karakter).
  ///
  /// Digunakan untuk:
  ///   - Menyimpan bukti master password (bukan password itu sendiri)
  ///   - Verifikasi login: `hashPassword(input) == storedHash`
  ///
  /// CATATAN: Untuk aplikasi produksi level tinggi, gunakan PBKDF2/Argon2.
  /// SHA-256 digunakan di sini sesuai spesifikasi Sesi 1 ZeroCrypt.
  String hashPassword(String password) {
    if (password.isEmpty) throw ArgumentError('password tidak boleh kosong');
    final bytes  = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString(); // hex string 64 karakter
  }

  /// Memverifikasi apakah [inputPassword] cocok dengan [storedHash].
  ///
  /// Gunakan ini daripada membandingkan manual untuk menghindari timing attack
  /// (meski SHA-256 hex comparison masih rentan — sudah cukup untuk scope ini).
  bool verifyPassword(String inputPassword, String storedHash) {
    if (inputPassword.isEmpty || storedHash.isEmpty) return false;
    return hashPassword(inputPassword) == storedHash;
  }

  // ── 5. Password Strength ────────────────────────────────────────────────────

  /// Mengecek kekuatan [password] dan mengembalikan [PasswordStrength].
  ///
  /// Kriteria:
  /// | Level      | Panjang | Huruf Besar | Angka | Simbol |
  /// |------------|---------|-------------|-------|--------|
  /// | weak       | < 8     | —           | —     | —      |
  /// | fair       | ≥ 8     | tidak wajib | —     | —      |
  /// | strong     | ≥ 12    | ✓           | ✓     | —      |
  /// | veryStrong | ≥ 16    | ✓           | ✓     | ✓      |
  PasswordStrength checkStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;

    final hasUpper  = password.contains(RegExp(r'[A-Z]'));
    final hasLower  = password.contains(RegExp(r'[a-z]'));
    final hasDigit  = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;'
        r"'`~/]"));

    // veryStrong: ≥ 16 + huruf besar + angka + simbol
    if (password.length >= 16 && hasUpper && hasDigit && hasSymbol) {
      return PasswordStrength.veryStrong;
    }

    // strong: ≥ 12 + huruf besar + angka
    if (password.length >= 12 && hasUpper && hasDigit) {
      return PasswordStrength.strong;
    }

    // fair: ≥ 8 (tapi tidak memenuhi kriteria strong)
    // Masih fair meski ada beberapa variasi tapi belum lengkap
    final varietyCount = [hasUpper, hasLower, hasDigit, hasSymbol]
        .where((v) => v)
        .length;

    if (password.length >= 8 && varietyCount >= 2) {
      return PasswordStrength.fair;
    }

    // Panjang ≥ 8 tapi variasi sangat kurang
    return PasswordStrength.weak;
  }

  /// Label string untuk [PasswordStrength] (untuk UI).
  static String strengthLabel(PasswordStrength strength) {
    return switch (strength) {
      PasswordStrength.weak      => 'Lemah',
      PasswordStrength.fair      => 'Cukup',
      PasswordStrength.strong    => 'Kuat',
      PasswordStrength.veryStrong => 'Sangat Kuat',
    };
  }

  /// Skor 0–4 untuk progress bar UI.
  static int strengthScore(PasswordStrength strength) {
    return switch (strength) {
      PasswordStrength.weak       => 1,
      PasswordStrength.fair       => 2,
      PasswordStrength.strong     => 3,
      PasswordStrength.veryStrong => 4,
    };
  }
}
