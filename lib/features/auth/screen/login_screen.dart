import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cyber_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/password_field.dart';
import '../provider/auth_provider.dart';

/// LoginScreen — layar unlock vault.
///
/// Features:
///   - Auto-trigger biometric jika diaktifkan di profil
///   - Countdown timer saat akun terkunci
///   - Password login + biometric fallback
///   - Error SnackBar
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passController = TextEditingController();
  Timer? _lockoutTimer;
  int   _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onInit());
  }

  Future<void> _onInit() async {
    // Load profil jika belum ada
    final auth = context.read<AuthProvider>();
    if (auth.profile == null) {
      await auth.loadProfile();
    }

    if (!mounted) return;

    // Auto-trigger biometric jika enabled
    final profile = auth.profile;
    if (profile?.biometricEnabled == true && !auth.isLockedOut) {
      await _tryBiometric();
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _passController.dispose();
    super.dispose();
  }

  // ── Lockout countdown ─────────────────────────────────────────────────────

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    final auth = context.read<AuthProvider>();
    if (!auth.isLockedOut) return;

    setState(() {
      _remainingSeconds = auth.remainingLockout?.inSeconds ?? 0;
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds = (_remainingSeconds - 1).clamp(0, 999));
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {}); // Refresh UI — lockout expired
      }
    });
  }

  // ── Login actions ─────────────────────────────────────────────────────────

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final password = _passController.text;
    if (password.isEmpty) {
      _showError('Masukkan master password.');
      return;
    }

    final auth   = context.read<AuthProvider>();
    final result = await auth.login(password);

    if (!mounted) return;

    if (result.isSuccess) {
      _passController.clear();
      Navigator.pushReplacementNamed(context, '/vault', arguments: password);
    } else {
      _passController.clear();
      _showError(result.errorMessage ?? 'Login gagal.');

      // Mulai countdown jika baru terkunci
      if (auth.isLockedOut) _startLockoutCountdown();
    }
  }

  Future<void> _tryBiometric() async {
    final auth   = context.read<AuthProvider>();
    final result = await auth.loginWithBiometric();

    if (!mounted) return;

    if (result.isSuccess) {
      // Biometric tidak return master password, VaultScreen akan handle pop up.
      Navigator.pushReplacementNamed(context, '/vault');
    } else if (result.errorMessage != null &&
        result.errorMessage != 'Autentikasi biometrik dibatalkan.') {
      _showError(result.errorMessage!);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;
    final isLocked  = auth.isLockedOut;
    final profile   = auth.profile;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Mini logo ─────────────────────────────────────────────────
                _MiniLogo()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 10),

                Text(
                  'ZEROCRYPT',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.kPrimaryContainer,
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w700,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 36),

                // ── Login card ────────────────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome
                      Text(
                        'Welcome back,',
                        style: AppTextStyles.bodyMd,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.displayName ?? 'Vault User',
                        style: AppTextStyles.titleLg,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 24),

                      // Password field
                      PasswordField(
                        label: 'Master Password',
                        hintText: 'Masukkan master password',
                        controller: _passController,
                        prefixIcon: Icons.lock_outline_rounded,
                        enabled: !isLocked && !isLoading,
                        onFieldSubmitted: (_) => _login(),
                        autofocus: profile?.biometricEnabled != true,
                      ),

                      // Lockout countdown
                      if (isLocked || _remainingSeconds > 0) ...[
                        const SizedBox(height: 10),
                        _LockoutBanner(seconds: _remainingSeconds),
                      ],

                      const SizedBox(height: 20),

                      // Unlock button
                      CyberButton(
                        label: 'UNLOCK VAULT',
                        icon: Icons.lock_open_rounded,
                        isFullWidth: true,
                        isLoading: isLoading,
                        onPressed: (isLocked || isLoading) ? null : _login,
                      ),

                      // Biometric button
                      if (profile?.biometricEnabled == true) ...[
                        const SizedBox(height: 12),
                        CyberButtonOutlined(
                          label: 'USE BIOMETRIC',
                          icon: Icons.fingerprint_rounded,
                          isFullWidth: true,
                          onPressed: (isLocked || isLoading)
                              ? null
                              : _tryBiometric,
                        ),
                      ],
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.06,
                      end: 0.0,
                      delay: 300.ms,
                      duration: 450.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 20),

                // ── Different account ─────────────────────────────────────────
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/register',
                  ),
                  child: Text(
                    'Different Account?',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.kOnSurfaceVariant,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _MiniLogo ──────────────────────────────────────────────────────────────────

class _MiniLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.kSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.kPrimaryContainer.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kCyberGlow,
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shield_rounded,
            size: 48,
            color: AppColors.kPrimaryContainer.withValues(alpha: 0.15),
          ),
          Text(
            'Z',
            style: AppTextStyles.headlineMd.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _LockoutBanner ─────────────────────────────────────────────────────────────

class _LockoutBanner extends StatelessWidget {
  const _LockoutBanner({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.kErrorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.kErrorContainer.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 16,
            color: AppColors.kOnErrorContainer,
          ),
          const SizedBox(width: 8),
          Text(
            seconds > 0
                ? 'Akun dikunci. Coba lagi dalam ${seconds}s'
                : 'Coba lagi sekarang',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.kOnErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
