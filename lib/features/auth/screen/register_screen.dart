import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cyber_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/password_field.dart';
import '../../../services/crypto_service.dart';
import '../provider/auth_provider.dart';

/// RegisterScreen — layar pembuatan vault pertama kali.
///
/// Flow:
///   1. Input display name + master password + konfirmasi
///   2. Pilihan aktifkan biometrik
///   3. AuthProvider.register() → navigate ke /vault
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  final _confController = TextEditingController();

  PasswordStrength _strength   = PasswordStrength.weak;
  bool             _biometric  = false;

  @override
  void initState() {
    super.initState();
    _passController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    // CryptoService diinstansiasi lokal — stateless, aman dipanggil di sini
    final strength = CryptoService().checkStrength(_passController.text);
    if (strength != _strength) {
      setState(() => _strength = strength);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passController
      ..removeListener(_onPasswordChanged)
      ..dispose();
    _confController.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Tutup keyboard
    FocusScope.of(context).unfocus();

    // Validasi form
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passController.text != _confController.text) {
      _showError('Konfirmasi password tidak cocok.');
      return;
    }

    final auth   = context.read<AuthProvider>();
    final result = await auth.register(
      displayName:     _nameController.text.trim(),
      masterPassword:  _passController.text,
      enableBiometric: _biometric,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, '/vault', arguments: _passController.text);
    } else {
      _showError(result.errorMessage ?? 'Registrasi gagal.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMd),
        backgroundColor: AppColors.kErrorContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Strength helpers ──────────────────────────────────────────────────────

  double get _strengthValue => switch (_strength) {
        PasswordStrength.weak      => 0.25,
        PasswordStrength.fair      => 0.50,
        PasswordStrength.strong    => 0.75,
        PasswordStrength.veryStrong => 1.0,
      };

  Color get _strengthColor => switch (_strength) {
        PasswordStrength.weak       => AppColors.kStrengthWeak,
        PasswordStrength.fair       => AppColors.kStrengthFair,
        PasswordStrength.strong     => AppColors.kStrengthGood,
        PasswordStrength.veryStrong => AppColors.kStrengthStrong,
      };

  String get _strengthLabel => switch (_strength) {
        PasswordStrength.weak       => 'WEAK',
        PasswordStrength.fair       => 'FAIR',
        PasswordStrength.strong     => 'STRONG',
        PasswordStrength.veryStrong => 'VERY STRONG',
      };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Create Vault',
          style: AppTextStyles.titleMd.copyWith(
            color: AppColors.kPrimaryContainer,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar ───────────────────────────────────────────────────
                _AvatarPlaceholder()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.85, 0.85), duration: 500.ms),

                const SizedBox(height: 28),

                // ── Form card ────────────────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display name
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: AppTextStyles.bodyLg,
                        cursorColor: AppColors.kPrimaryContainer,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'Nama yang ditampilkan di vault',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Master password
                      PasswordField(
                        label: 'Master Password',
                        hintText: 'Minimal 8 karakter',
                        controller: _passController,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Password minimal 8 karakter';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Strength bar
                      if (_passController.text.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _strengthValue,
                            minHeight: 4,
                            backgroundColor: AppColors.kSurfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _strengthColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _strengthLabel,
                          style: AppTextStyles.labelMd.copyWith(
                            color: _strengthColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Confirm password
                      PasswordField(
                        label: 'Konfirmasi Password',
                        hintText: 'Ulangi master password',
                        controller: _confController,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.lock_outline_rounded,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.06,
                      end: 0.0,
                      delay: 150.ms,
                      duration: 450.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 16),

                // ── Biometric toggle ─────────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.kPrimaryContainer,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Biometric',
                              style: AppTextStyles.bodyLg,
                            ),
                            Text(
                              'Unlock dengan fingerprint atau face ID',
                              style: AppTextStyles.bodySm,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _biometric,
                        onChanged: (val) => setState(() => _biometric = val),
                        activeThumbColor: AppColors.kOnPrimary,
                        activeTrackColor: AppColors.kPrimaryContainer,
                        inactiveThumbColor: AppColors.kOnSurfaceVariant,
                        inactiveTrackColor: AppColors.kDivider,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── CTA Button ───────────────────────────────────────────────
                CyberButton(
                  label: 'CREATE VAULT',
                  icon: Icons.shield_rounded,
                  isFullWidth: true,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0.0,
                      delay: 450.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 20),

                // ── Disclaimer ───────────────────────────────────────────────
                Text(
                  'Master password tidak dapat dipulihkan.\nSimpan di tempat yang aman.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.kOnSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _AvatarPlaceholder ────────────────────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.kSurfaceContainer,
        border: Border.all(
          color: AppColors.kPrimaryContainer.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kCyberGlow,
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 48,
        color: AppColors.kOnSurfaceVariant,
      ),
    );
  }
}
