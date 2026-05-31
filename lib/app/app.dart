import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/screen/login_screen.dart';
import '../features/auth/screen/register_screen.dart';
import '../features/generator/screen/generator_screen.dart';
import '../features/settings/screen/settings_screen.dart';
import '../features/splash/screen/splash_screen.dart';
import '../features/vault/screen/account_detail_screen.dart';

import '../features/vault/screen/edit_credential_screen.dart';
import '../features/vault/screen/vault_screen.dart';
import '../features/settings/screen/profile_settings_screen.dart';

/// ZeroCryptApp — root widget yang membungkus [MaterialApp].
///
/// Tanggung jawab widget ini:
///   - Menerapkan [AppTheme.darkTheme] (dark-only, Material 3)
///   - Mendaftarkan semua named routes
///   - Custom slide+fade page transition
///   - Lock orientasi portrait
///   - System UI overlay transparan
///
/// Provider di-inject di atas widget ini oleh [main.dart] menggunakan
/// [MultiProvider], sehingga tersedia di semua route.
class ZeroCryptApp extends StatefulWidget {
  const ZeroCryptApp({super.key});

  @override
  State<ZeroCryptApp> createState() => _ZeroCryptAppState();
}

class _ZeroCryptAppState extends State<ZeroCryptApp> {
  @override
  void initState() {
    super.initState();

    // Status bar transparan + ikon putih di semua screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.kBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Lock portrait — keamanan: cegah shoulder-surfing dari landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── Meta ──────────────────────────────────────────────────────────────
      title: 'ZeroCrypt',
      debugShowCheckedModeBanner: false,

      // ── Theme (dark only) ─────────────────────────────────────────────────
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // ── Initial route ──────────────────────────────────────────────────────
      initialRoute: '/splash',

      // ── Named routes ──────────────────────────────────────────────────────
      // Digunakan oleh Navigator.pushNamed(context, '/vault') dll.
      routes: {
        '/splash':    (_) => const SplashScreen(),
        '/login':     (_) => const LoginScreen(),
        '/register':  (_) => const RegisterScreen(),
        '/vault':     (_) => const VaultScreen(),
        '/generator': (_) => const GeneratorScreen(),
        '/settings':  (_) => const SettingsScreen(),
        '/detail':    (_) => const AccountDetailScreen(),
        '/edit':      (_) => const EditCredentialScreen(),
        '/profile':   (_) => const ProfileSettingsScreen(),
      },

      // ── Custom page transition ─────────────────────────────────────────────
      // Slide subtle dari bawah + fade — lebih premium dari default.
      // onGenerateRoute menggantikan routes table saat nama cocok,
      // sehingga custom transition berlaku untuk semua navigasi.
      onGenerateRoute: (settings) {
        final WidgetBuilder? builder = {
          '/splash':    (_) => const SplashScreen(),
          '/login':     (_) => const LoginScreen(),
          '/register':  (_) => const RegisterScreen(),
          '/vault':     (_) => const VaultScreen(),
          '/generator': (_) => const GeneratorScreen(),
          '/settings':  (_) => const SettingsScreen(),
          '/detail':    (_) => const AccountDetailScreen(),
          '/edit':      (_) => const EditCredentialScreen(),
          '/profile':   (_) => const ProfileSettingsScreen(),
        }[settings.name];

        if (builder == null) return null;

        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder:        (ctx, animation, secondaryAnimation) => builder(ctx),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (ctx, animation, _, child) {
            // Slide 4% dari bawah + fade
            final slideTween = Tween<Offset>(
              begin: const Offset(0.0, 0.04),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            final fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
      },

      // ── Fallback route ────────────────────────────────────────────────────
      onUnknownRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const SplashScreen(),
      ),
    );
  }
}
