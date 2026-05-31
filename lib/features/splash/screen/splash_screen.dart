import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/provider/auth_provider.dart';

/// SplashScreen — layar pembuka ZeroCrypt.
///
/// Tampilkan logo + animasi, lalu routing berdasarkan profil:
///   - Ada profil → /login
///   - Belum ada  → /register
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Tunggu animasi selesai sebelum navigasi
    await Future<void>.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final hasProfile = await auth.hasExistingProfile();

    if (!mounted) return;

    if (hasProfile) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ──────────────────────────────────────────────────────
              _LogoBadge()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.easeOutBack,
                    duration: 700.ms,
                  ),

              const SizedBox(height: 28),

              // ── App name ──────────────────────────────────────────────────
              Text(
                'ZEROCRYPT',
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.kPrimaryContainer,
                  letterSpacing: 32 * -0.02,
                  fontWeight: FontWeight.w800,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0.0,
                    curve: Curves.easeOutCubic,
                    duration: 500.ms,
                    delay: 400.ms,
                  ),

              const SizedBox(height: 8),

              // ── Tagline ───────────────────────────────────────────────────
              Text(
                'SECURE OFFLINE VAULT  ·  ZERO KNOWLEDGE',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.kOnSurfaceVariant,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 500.ms),

              const SizedBox(height: 56),

              // ── Loading indicator ─────────────────────────────────────────
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.kPrimaryContainer.withValues(alpha: 0.6),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _LogoBadge ─────────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.kSurfaceContainer,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.kPrimaryContainer.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kCyberGlow,
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppColors.kPrimaryContainer.withValues(alpha: 0.08),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shield icon background
          Icon(
            Icons.shield_rounded,
            size: 80,
            color: AppColors.kPrimaryContainer.withValues(alpha: 0.15),
          ),
          // "Z" letter overlay
          Text(
            'Z',
            style: AppTextStyles.headlineLg.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.kPrimaryContainer,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
