import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../../vault/provider/vault_provider.dart';

/// ProfileSettingsScreen — profil pengguna + pengaturan keamanan.
///
/// Layout:
///   - AppBar: ← + "Profile & Security" + avatar
///   - Avatar 128px lingkaran dengan border cyan + glow
///   - Display name (cyan, 28px) + security level
///   - GlassCard: Change Password | Biometric | Auto-Lock
///   - TextButton: Switch Vault Identity
///   - Tombol LOCK VAULT fixed di bawah (Stack + Positioned)
///
/// Menggunakan [AuthProvider.updateProfile] untuk persist settings —
/// tidak langsung instansiasi StorageService (sesuai provider-patterns.md).
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool   _biometricEnabled = false;
  int    _autoLockMinutes  = 0; // 0 = Immediately
  bool   _initialized      = false;

  // Auto-lock label options
  static const List<({int minutes, String label})> _lockOptions = [
    (minutes: 0,  label: 'Immediately'),
    (minutes: 1,  label: '1 Minute'),
    (minutes: 5,  label: '5 Minutes'),
    (minutes: 15, label: '15 Minutes'),
    (minutes: 30, label: '30 Minutes'),
    (minutes: -1, label: 'Never'),
  ];

  String get _autoLockLabel {
    for (final opt in _lockOptions) {
      if (opt.minutes == _autoLockMinutes) return opt.label;
    }
    return 'Custom';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final profile = context.read<AuthProvider>().profile;
    if (!mounted) return;
    setState(() {
      _biometricEnabled = profile?.biometricEnabled ?? false;
      _autoLockMinutes  = profile?.autoLockMinutes  ?? 0;
    });
  }

  // ── Change biometric ──────────────────────────────────────────────────────

  Future<void> _setBiometric(bool val) async {
    setState(() => _biometricEnabled = val);
    await context.read<AuthProvider>().updateProfile(
          biometricEnabled: val,
        );
  }

  // ── Auto-lock picker ──────────────────────────────────────────────────────

  void _showAutoLockPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.kSurfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.kOnSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Auto-Lock Vault',
                  style: AppTextStyles.titleSm.copyWith(
                    fontFamily:  'HankenGrotesk',
                    fontWeight:  FontWeight.w600,
                    color:       AppColors.kOnSurface,
                  )),
              const SizedBox(height: 8),
              ..._lockOptions.map((opt) => ListTile(
                    title: Text(opt.label,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: _autoLockMinutes == opt.minutes
                              ? AppColors.kPrimaryContainer
                              : AppColors.kOnSurface,
                        )),
                    trailing: _autoLockMinutes == opt.minutes
                        ? Icon(Icons.check_rounded,
                            color: AppColors.kPrimaryContainer)
                        : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _autoLockMinutes = opt.minutes);
                      await context.read<AuthProvider>().updateProfile(
                            autoLockMinutes: opt.minutes,
                          );
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Change master password ────────────────────────────────────────────────

  void _showChangeMasterPassword() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangeMasterPasswordSheet(
        onSaved: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Master password updated'),
              backgroundColor: AppColors.kSurfaceContainerHigh,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }

  // ── Lock vault ────────────────────────────────────────────────────────────

  void _lockVault() {
    context.read<VaultProvider>().clearAll();
    context.read<AuthProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (_) => false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final displayName = profile?.displayName ?? 'Vault User';

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131313),
        elevation:       0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: const Color(0xFF00E5FF)),
        title: Text('Profile & Security',
            style: AppTextStyles.titleMd.copyWith(
              fontFamily:  'HankenGrotesk',
              fontSize:    20,
              fontWeight:  FontWeight.w500,
              color:       const Color(0xFF00E5FF),
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A2A2A),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase() : 'U',
                  style: AppTextStyles.titleSm.copyWith(
                    color:      const Color(0xFF00E5FF),
                    fontWeight: FontWeight.w700,
                    fontSize:   15,
                    height:     1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Stack: scrollable content + fixed LOCK VAULT button
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Avatar section ────────────────────────────────────
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 136, height: 136,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:       Color(0x4000E5FF),
                              blurRadius:  24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Avatar circle
                      Container(
                        width: 128, height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1C1B1B),
                          border: Border.all(
                            color: const Color(0xFF00E5FF),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Icon(
                            Icons.person_rounded,
                            size:  64,
                            color: const Color(0xFFBAC9CC),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Display name ───────────────────────────────────────
                Text(
                  displayName,
                  style: AppTextStyles.headlineMd.copyWith(
                    fontFamily:  'HankenGrotesk',
                    fontSize:    28,
                    fontWeight:  FontWeight.w700,
                    color:       const Color(0xFF00E5FF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                Text(
                  'SECURITY LEVEL: MAXIMUM',
                  style: AppTextStyles.labelSm.copyWith(
                    fontFamily:    'JetBrains Mono',
                    fontSize:      11,
                    color:         const Color(0xFFBAC9CC),
                    letterSpacing: 0.08 * 11,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Settings card ──────────────────────────────────────
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // 1. Change Master Password
                      _SettingsTile(
                        iconData: Icons.lock_outline_rounded,
                        title:    'Change Master Password',
                        subtitle: 'Update your primary vault key',
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFBAC9CC)),
                        onTap: _showChangeMasterPassword,
                      ),

                      Divider(
                        color:  const Color(0x1AFFFFFF),
                        height: 1,
                        indent: 68,
                      ),

                      // 2. Biometric
                      _SettingsTile(
                        iconData: Icons.fingerprint_rounded,
                        title:    'Biometric Authentication',
                        subtitle: 'Unlock with Face ID or Fingerprint',
                        trailing: Switch(
                          value:               _biometricEnabled,
                          onChanged:           _setBiometric,
                          activeThumbColor:    const Color(0xFF00363D),
                          activeTrackColor:    const Color(0xFF00E5FF),
                          inactiveThumbColor:  const Color(0xFF849396),
                          inactiveTrackColor:  const Color(0xFF2A2A2A),
                          trackOutlineColor:
                              WidgetStateProperty.all(Colors.transparent),
                        ),
                        onTap: null,
                      ),

                      Divider(
                        color:  const Color(0x1AFFFFFF),
                        height: 1,
                        indent: 68,
                      ),

                      // 3. Auto-Lock
                      _SettingsTile(
                        iconData: Icons.timer_outlined,
                        title:    'Auto-Lock Vault',
                        subtitle: 'Security timeout duration',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color:        const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _autoLockLabel,
                                style: AppTextStyles.labelSm.copyWith(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize:   11,
                                  color:      const Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFFBAC9CC)),
                          ],
                        ),
                        onTap: _showAutoLockPicker,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Switch vault identity ──────────────────────────────
                TextButton.icon(
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                    context.read<VaultProvider>().clearAll();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (_) => false);
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFF849396), size: 16),
                  label: Text('SWITCH VAULT IDENTITY',
                      style: AppTextStyles.labelSm.copyWith(
                        fontFamily:    'JetBrains Mono',
                        fontSize:      12,
                        color:         const Color(0xFF849396),
                        letterSpacing: 0.08 * 12,
                      )),
                ),
              ],
            ),
          ),

          // ── Fixed LOCK VAULT button ────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: const Color(0xFF131313),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SizedBox(
                width:  double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF93000A),
                    foregroundColor: const Color(0xFFFFDAD6),
                    elevation:       0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon:  const Icon(Icons.lock_rounded, size: 20),
                  label: Text('LOCK VAULT',
                      style: AppTextStyles.buttonLabel.copyWith(
                        fontFamily:    'JetBrains Mono',
                        fontSize:      14,
                        fontWeight:    FontWeight.w500,
                        color:         const Color(0xFFFFDAD6),
                        letterSpacing: 0.08 * 14,
                      )),
                  onPressed: _lockVault,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _SettingsTile ─────────────────────────────────────────────────────────────

/// ListTile dengan icon box cyan 44×44 sesuai design Stitch.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.iconData,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData  iconData;
  final String    title;
  final String    subtitle;
  final Widget    trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap:           onTap,
      contentPadding:  const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color:        AppColors.kPrimaryContainer.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.kPrimaryContainer.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(iconData,
            size:  22,
            color: AppColors.kPrimaryContainer),
      ),
      title: Text(title,
          style: AppTextStyles.bodyLg.copyWith(
            fontFamily:  'Inter',
            fontSize:    15,
            fontWeight:  FontWeight.w500,
            color:       AppColors.kOnSurface,
          )),
      subtitle: Text(subtitle,
          style: AppTextStyles.bodyMd.copyWith(
            fontFamily: 'Inter',
            fontSize:   13,
            color:      AppColors.kOnSurfaceVariant,
          )),
      trailing: trailing,
    );
  }
}

// ── _ChangeMasterPasswordSheet ────────────────────────────────────────────────

/// Bottom sheet untuk ganti master password.
///
/// Logic: AuthProvider.changeMasterPassword(oldPassword, newPassword)
/// Tidak langsung memanipulasi SecureStorage — delegasikan ke Provider.
class _ChangeMasterPasswordSheet extends StatefulWidget {
  const _ChangeMasterPasswordSheet({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_ChangeMasterPasswordSheet> createState() =>
      _ChangeMasterPasswordSheetState();
}

class _ChangeMasterPasswordSheetState
    extends State<_ChangeMasterPasswordSheet> {
  final _oldCtrl     = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  bool _oldObscure     = true;
  bool _newObscure     = true;
  bool _confirmObscure = true;
  bool _isLoading      = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() { _isLoading = true; _error = null; });

    final result = await context.read<AuthProvider>().changeMasterPassword(
      oldPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.pop(context);
      widget.onSaved();
    } else {
      setState(() => _error = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.kSurfaceContainer,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
              top: BorderSide(color: AppColors.kGlassBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.kOnSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Change Master Password',
                  style: AppTextStyles.titleMd.copyWith(
                      color: AppColors.kPrimaryContainer)),
              const SizedBox(height: 20),

              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.kErrorContainer
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.kErrorContainer
                            .withValues(alpha: 0.5)),
                  ),
                  child: Text(_error!,
                      style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.kOnErrorContainer)),
                ),
                const SizedBox(height: 16),
              ],

              // Current password
              _PwField(
                controller: _oldCtrl,
                label:      'Current Password',
                obscure:    _oldObscure,
                onToggle:   () =>
                    setState(() => _oldObscure = !_oldObscure),
                validator: (v) =>
                    (v == null || v.isEmpty)
                        ? 'Masukkan password lama' : null,
              ),
              const SizedBox(height: 14),

              // New password
              _PwField(
                controller: _newCtrl,
                label:      'New Password',
                obscure:    _newObscure,
                onToggle:   () =>
                    setState(() => _newObscure = !_newObscure),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Masukkan password baru';
                  }
                  if (v.length < 8) {
                    return 'Minimal 8 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirm password
              _PwField(
                controller: _confirmCtrl,
                label:      'Confirm New Password',
                obscure:    _confirmObscure,
                onToggle:   () => setState(
                    () => _confirmObscure = !_confirmObscure),
                validator: (v) => v != _newCtrl.text
                    ? 'Password tidak cocok' : null,
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width:  double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kPrimaryContainer,
                    foregroundColor: AppColors.kOnPrimary,
                    shape: const StadiumBorder(),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Icon(Icons.lock_reset_rounded),
                  label: Text('Update Password',
                      style: AppTextStyles.buttonLabel),
                  onPressed: _isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _PwField ──────────────────────────────────────────────────────────────────

class _PwField extends StatelessWidget {
  const _PwField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController        controller;
  final String                       label;
  final bool                         obscure;
  final VoidCallback                 onToggle;
  final FormFieldValidator<String>?  validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:     controller,
      obscureText:    obscure,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.passwordText.copyWith(
          color: AppColors.kOnSurface),
      cursorColor: AppColors.kPrimaryContainer,
      validator: validator,
      decoration: InputDecoration(
        labelText:  label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.kOnSurfaceVariant,
          ),
          onPressed: onToggle,
        ),
        floatingLabelStyle: AppTextStyles.labelSm.copyWith(
            color: AppColors.kPrimaryContainer),
        labelStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.kOnSurfaceVariant),
      ),
    );
  }
}
