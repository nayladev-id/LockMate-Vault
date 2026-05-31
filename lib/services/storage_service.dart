import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// StorageService — wrapper SharedPreferences untuk data NON-sensitif.
///
/// Yang boleh disimpan di sini:
///   ✅ Display name pengguna (bukan password)
///   ✅ Setting biometric (on/off flag)
///   ✅ Setting auto-lock duration
///   ✅ Vault items — TAPI hanya dalam bentuk SUDAH TERENKRIPSI
///      (enkripsi dilakukan di VaultProvider, bukan di sini)
///
/// Yang TIDAK boleh disimpan di sini:
///   ❌ Plaintext password apapun
///   ❌ Master key / derived key
///   ❌ Data sensitif yang belum dienkripsi
///
/// Enkripsi vault items dilakukan di [VaultProvider] sebelum memanggil
/// [saveVaultItems], sehingga StorageService tetap ignorant terhadap
/// isi data — hanya menyimpan dan mengambil JSON string.
class StorageService {
  // ── Key constants ──────────────────────────────────────────────────────────

  static const String _keyDisplayName      = 'zc_display_name';
  static const String _keyBiometricEnabled = 'zc_biometric';
  static const String _keyAutoLockDuration = 'zc_autolock';
  static const String _keyVaultItems       = 'zc_vault_items';

  // ── Default values ─────────────────────────────────────────────────────────

  static const String _defaultDisplayName    = 'Vault User';
  static const bool   _defaultBiometric      = false;
  static const int    _defaultAutoLock       = 5; // menit

  // ── Display Name ───────────────────────────────────────────────────────────

  /// Simpan display name pengguna (bukan username / password).
  Future<void> saveDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, name.trim());
  }

  /// Ambil display name. Return `'Vault User'` jika belum di-set.
  Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName) ?? _defaultDisplayName;
  }

  // ── Biometric Setting ──────────────────────────────────────────────────────

  /// Simpan preferensi apakah biometric login diaktifkan.
  Future<void> setBiometricEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, val);
  }

  /// Ambil status biometric. Return `false` (disabled) jika belum di-set.
  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? _defaultBiometric;
  }

  // ── Auto-Lock Duration ─────────────────────────────────────────────────────

  /// Simpan durasi auto-lock dalam menit.
  ///
  /// Nilai khusus:
  ///   - `0` = lock segera saat app masuk background
  ///   - `-1` = tidak pernah auto-lock (tidak disarankan)
  Future<void> setAutoLockDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoLockDuration, minutes);
  }

  /// Ambil durasi auto-lock. Return `5` menit jika belum di-set.
  Future<int> getAutoLockDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoLockDuration) ?? _defaultAutoLock;
  }

  // ── Vault Items ─────────────────────────────────────────────────────────────

  /// Simpan list vault items dalam bentuk `List<Map<String, dynamic>>`.
  ///
  /// PENTING: Setiap Map sudah berisi field terenkripsi.
  /// Enkripsi dilakukan di [VaultProvider] sebelum method ini dipanggil.
  /// StorageService hanya serialize ke JSON string dan simpan ke prefs.
  ///
  /// Contoh struktur [items] yang masuk:
  /// ```json
  /// [
  ///   {
  ///     "id": "uuid-...",
  ///     "title": "Gmail",            // plaintext — bukan sensitif
  ///     "username": "user@gmail.com", // plaintext — bukan sensitif
  ///     "encryptedPassword": "base64(iv):base64(cipher)", // terenkripsi ✅
  ///     "category": "email",
  ///     "createdAt": 1234567890
  ///   }
  /// ]
  /// ```
  Future<void> saveVaultItems(List<Map<String, dynamic>> items) async {
    final prefs  = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items);
    await prefs.setString(_keyVaultItems, encoded);
  }

  /// Ambil list vault items. Return `[]` jika vault kosong atau belum ada data.
  ///
  /// Data yang dikembalikan masih dalam bentuk Map — password masih terenkripsi.
  /// Dekripsi dilakukan di [VaultProvider] setelah method ini dipanggil.
  Future<List<Map<String, dynamic>>> getVaultItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyVaultItems);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList();
    } on FormatException {
      // Data korup — return kosong daripada crash
      return [];
    }
  }

  // ── Clear Vault ────────────────────────────────────────────────────────────

  /// Hapus semua vault items dari storage.
  ///
  /// Gunakan untuk:
  ///   - Fitur "Clear All" di settings
  ///   - Panic wipe (dikombinasi dengan [SecureStorageService.clearAll])
  Future<void> clearVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVaultItems);
  }

  // ── Clear All Settings ─────────────────────────────────────────────────────

  /// Hapus SEMUA data SharedPreferences — untuk reset total.
  ///
  /// CATATAN: Ini menghapus vault items DAN semua settings.
  /// Untuk full reset, kombinasikan dengan [SecureStorageService.clearAll()].
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Item count helper ──────────────────────────────────────────────────────

  /// Jumlah vault items yang tersimpan (tanpa dekripsi data).
  Future<int> getVaultItemCount() async {
    final items = await getVaultItems();
    return items.length;
  }
}
