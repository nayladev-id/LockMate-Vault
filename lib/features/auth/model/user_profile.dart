/// Model profil pengguna ZeroCrypt.
///
/// Disimpan secara non-sensitif via [StorageService]:
///   - [displayName]       → SharedPreferences key `zc_display_name`
///   - [biometricEnabled]  → SharedPreferences key `zc_biometric`
///   - [autoLockMinutes]   → SharedPreferences key `zc_autolock`
///
/// TIDAK mengandung password, key, atau data sensitif apapun.
/// Immutable — gunakan [copyWith] untuk menghasilkan instance baru.
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.biometricEnabled,
    required this.autoLockMinutes,
  });

  /// Nama tampilan pengguna (bukan username / credential).
  final String displayName;

  /// Apakah login biometrik (fingerprint/face) diaktifkan.
  final bool biometricEnabled;

  /// Durasi auto-lock dalam menit.
  /// `0` = lock segera saat background. `-1` = tidak pernah lock.
  final int autoLockMinutes;

  // ── Factory / Default ───────────────────────────────────────────────────────

  /// Profil default untuk pengguna baru sebelum registrasi selesai.
  factory UserProfile.defaultProfile() => const UserProfile(
        displayName: 'Vault User',
        biometricEnabled: false,
        autoLockMinutes: 5,
      );

  // ── Serialization ───────────────────────────────────────────────────────────

  /// Konversi ke Map untuk disimpan sebagai JSON.
  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'biometricEnabled': biometricEnabled,
        'autoLockMinutes': autoLockMinutes,
      };

  /// Buat [UserProfile] dari Map JSON.
  ///
  /// Toleran terhadap field yang hilang — menggunakan nilai default.
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        displayName: json['displayName'] as String? ?? 'Vault User',
        biometricEnabled: json['biometricEnabled'] as bool? ?? false,
        autoLockMinutes: json['autoLockMinutes'] as int? ?? 5,
      );

  // ── Mutation ────────────────────────────────────────────────────────────────

  /// Buat instance baru dengan beberapa field diubah.
  ///
  /// Field yang tidak disebutkan tetap menggunakan nilai dari instance ini.
  UserProfile copyWith({
    String? displayName,
    bool? biometricEnabled,
    int? autoLockMinutes,
  }) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      );

  // ── Equality & Debug ────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.displayName == displayName &&
          other.biometricEnabled == biometricEnabled &&
          other.autoLockMinutes == autoLockMinutes;

  @override
  int get hashCode => Object.hash(displayName, biometricEnabled, autoLockMinutes);

  @override
  String toString() =>
      'UserProfile(displayName: $displayName, '
      'biometricEnabled: $biometricEnabled, '
      'autoLockMinutes: $autoLockMinutes)';
}
