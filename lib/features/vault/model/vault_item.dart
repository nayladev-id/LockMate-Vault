import 'package:flutter/material.dart';

/// Warna preset untuk icon avatar vault item.
/// Dipilih berdasarkan hash dari [VaultItem.platformName].
const List<Color> _kIconColors = [
  Color(0xFF006875),
  Color(0xFF4A4949),
  Color(0xFF3B494C),
  Color(0xFF004F58),
  Color(0xFF474646),
  Color(0xFF595959),
];

/// VaultItem — satu entri di vault ZeroCrypt.
///
/// Kebijakan keamanan WAJIB:
///   - [encryptedPassword] di storage SELALU berisi ciphertext AES-256-GCM
///     format `"base64(iv):base64(ciphertext)"`. TIDAK pernah plaintext.
///   - [decryptedPassword] hanya ada di memori saat vault terbuka —
///     field ini TIDAK di-serialisasi ke JSON / storage.
///   - [notes] jika ada, juga dienkripsi sebelum disimpan.
///
/// Immutable — gunakan [copyWith] untuk salinan dengan field baru.
class VaultItem {
  const VaultItem({
    required this.id,
    required this.platformName,
    required this.username,
    required this.encryptedPassword,
    required this.iconInitials,
    required this.iconColor,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.decryptedPassword,
  });

  /// ID unik item — timestamp milliseconds sejak epoch.
  final String id;

  /// Nama platform/website (contoh: "Gmail", "BCA Mobile").
  final String platformName;

  /// Email atau username (non-sensitif).
  final String username;

  /// Password TERENKRIPSI untuk disimpan ke storage.
  /// Format: `"base64(iv):base64(ciphertext)"`.
  ///
  /// TIDAK PERNAH simpan plaintext di sini.
  /// Enkripsi dilakukan di [VaultProvider] via [CryptoService.encrypt()].
  final String encryptedPassword;

  /// Catatan tambahan — juga dienkripsi sebelum disimpan.
  /// Null jika tidak ada catatan.
  final String? notes;

  /// 2 huruf pertama [platformName] dalam uppercase — dipakai sebagai
  /// avatar icon ketika tidak ada logo.
  final String iconInitials;

  /// Warna icon avatar — konsisten berdasarkan hash [platformName].
  final Color iconColor;

  /// Waktu pembuatan item.
  final DateTime createdAt;

  /// Waktu perubahan terakhir.
  final DateTime updatedAt;

  /// Password plaintext — hanya ada di memori saat vault terbuka.
  ///
  /// Di-set oleh [VaultProvider.loadItems()] setelah dekripsi.
  /// TIDAK di-serialisasi ke JSON — tidak pernah menyentuh storage.
  final String? decryptedPassword;

  // ── Static helpers ─────────────────────────────────────────────────────────

  /// Generate ID unik dari timestamp.
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  /// Extract 2 huruf pertama dari [name] sebagai initials uppercase.
  static String _initialsFrom(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '??';
    if (clean.length == 1) return clean.toUpperCase();
    return clean.substring(0, 2).toUpperCase();
  }

  /// Pilih warna dari preset berdasarkan hash konsisten dari [name].
  static Color _colorFromPlatform(String name) {
    return _kIconColors[name.hashCode.abs() % _kIconColors.length];
  }

  // ── Factory ────────────────────────────────────────────────────────────────

  /// Buat VaultItem baru.
  ///
  /// [encryptedPassword] dan [encryptedNotes] harus sudah dienkripsi
  /// oleh [VaultProvider] sebelum factory ini dipanggil.
  factory VaultItem.create({
    required String platformName,
    required String username,
    required String encryptedPassword,
    String? encryptedNotes,
    String? decryptedPassword,
  }) {
    final now = DateTime.now();
    return VaultItem(
      id:                generateId(),
      platformName:      platformName.trim(),
      username:          username.trim(),
      encryptedPassword: encryptedPassword,
      notes:             encryptedNotes,
      iconInitials:      _initialsFrom(platformName),
      iconColor:         _colorFromPlatform(platformName),
      createdAt:         now,
      updatedAt:         now,
      decryptedPassword: decryptedPassword,
    );
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  /// Konversi ke Map untuk [StorageService.saveVaultItems()].
  ///
  /// [decryptedPassword] TIDAK ikut di-serialize — hanya ada di memori.
  Map<String, dynamic> toJson() => {
        'id':                id,
        'platformName':      platformName,
        'username':          username,
        'encryptedPassword': encryptedPassword,
        if (notes != null) 'notes': notes,
        'iconInitials':      iconInitials,
        'iconColor':         iconColor.toARGB32(),
        'createdAt':         createdAt.millisecondsSinceEpoch,
        'updatedAt':         updatedAt.millisecondsSinceEpoch,
      };

  /// Buat [VaultItem] dari JSON yang diambil [StorageService.getVaultItems()].
  ///
  /// [decryptedPassword] null — harus didekripsi oleh [VaultProvider].
  factory VaultItem.fromJson(Map<String, dynamic> json) {
    final name = json['platformName'] as String? ?? '';
    return VaultItem(
      id:                json['id']                as String?  ?? generateId(),
      platformName:      name,
      username:          json['username']          as String?  ?? '',
      encryptedPassword: json['encryptedPassword'] as String?  ?? '',
      notes:             json['notes']             as String?,
      iconInitials:      json['iconInitials']      as String?  ?? _initialsFrom(name),
      iconColor: json['iconColor'] != null
          ? Color(json['iconColor'] as int)
          : _colorFromPlatform(name),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updatedAt'] as int? ?? 0,
      ),
      // decryptedPassword selalu null dari storage — VaultProvider yang decrypt
      decryptedPassword: null,
    );
  }

  // ── Mutation ───────────────────────────────────────────────────────────────

  /// Buat salinan dengan field yang diubah.
  /// [updatedAt] otomatis di-set ke sekarang jika ada perubahan data.
  VaultItem copyWith({
    String? platformName,
    String? username,
    String? encryptedPassword,
    String? notes,
    String? decryptedPassword,
    bool clearNotes = false,
    bool clearDecrypted = false,
  }) {
    final newName = platformName ?? this.platformName;
    return VaultItem(
      id:                id,
      platformName:      newName,
      username:          username          ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      notes:             clearNotes   ? null : notes    ?? this.notes,
      iconInitials:      _initialsFrom(newName),
      iconColor:         _colorFromPlatform(newName),
      createdAt:         createdAt,
      updatedAt:         DateTime.now(),
      decryptedPassword: clearDecrypted ? null : decryptedPassword ?? this.decryptedPassword,
    );
  }

  /// Buat salinan dengan [decryptedPassword] diisi (setelah dekripsi di provider).
  VaultItem withDecrypted(String plaintext) => VaultItem(
        id:                id,
        platformName:      platformName,
        username:          username,
        encryptedPassword: encryptedPassword,
        notes:             notes,
        iconInitials:      iconInitials,
        iconColor:         iconColor,
        createdAt:         createdAt,
        updatedAt:         updatedAt,
        decryptedPassword: plaintext,
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Formatted tanggal update terakhir untuk UI.
  String get formattedDate {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${updatedAt.day} ${months[updatedAt.month - 1]} ${updatedAt.year}';
  }

  /// `true` jika password sudah didekripsi dan siap ditampilkan.
  bool get hasDecryptedPassword =>
      decryptedPassword != null && decryptedPassword!.isNotEmpty;

  // ── Equality ───────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'VaultItem(id: $id, platform: $platformName, user: $username)';
}
