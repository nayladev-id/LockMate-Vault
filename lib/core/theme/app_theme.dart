import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// ThemeData ZeroCrypt — dark only, Material 3.
///
/// Penggunaan:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.darkTheme,
///   darkTheme: AppTheme.darkTheme,
///   themeMode: ThemeMode.dark,
/// )
/// ```
abstract final class AppTheme {
  // ── ColorScheme ───────────────────────────────────────────────────────────

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary (Cyber Blue)
    primary: AppColors.kPrimaryContainer,
    onPrimary: AppColors.kOnPrimary,
    primaryContainer: AppColors.kPrimaryContainer,
    onPrimaryContainer: AppColors.kOnPrimary,

    // Secondary
    secondary: AppColors.kPrimary,
    onSecondary: AppColors.kOnPrimary,
    secondaryContainer: AppColors.kAccentMuted,
    onSecondaryContainer: AppColors.kPrimaryContainer,

    // Tertiary
    tertiary: AppColors.kPrimary,
    onTertiary: AppColors.kOnPrimary,
    tertiaryContainer: AppColors.kAccentMuted,
    onTertiaryContainer: AppColors.kPrimaryContainer,

    // Error
    error: AppColors.kOnErrorContainer,
    onError: AppColors.kErrorContainer,
    errorContainer: AppColors.kErrorContainer,
    onErrorContainer: AppColors.kOnErrorContainer,

    // Surface hierarchy
    surface: AppColors.kSurfaceContainer,
    onSurface: AppColors.kOnSurface,
    onSurfaceVariant: AppColors.kOnSurfaceVariant,

    // Outline
    outline: AppColors.kOutline,
    outlineVariant: AppColors.kDivider,

    // Misc
    scrim: Colors.black87,
    inverseSurface: AppColors.kOnSurface,
    onInverseSurface: AppColors.kBackground,
    inversePrimary: AppColors.kOnPrimary,
    surfaceTint: AppColors.kPrimaryContainer,
  );

  // ── TextTheme ─────────────────────────────────────────────────────────────

  static TextTheme get _textTheme => TextTheme(
        // Display
        displayLarge: AppTextStyles.headlineLg,
        displayMedium: AppTextStyles.headlineMd,
        displaySmall: AppTextStyles.titleLg,

        // Headline
        headlineLarge: AppTextStyles.headlineLg,
        headlineMedium: AppTextStyles.headlineMd,
        headlineSmall: AppTextStyles.titleLg,

        // Title
        titleLarge: AppTextStyles.titleMd,
        titleMedium: AppTextStyles.titleSm,
        titleSmall: AppTextStyles.titleSm,

        // Body
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        bodySmall: AppTextStyles.bodySm,

        // Label
        labelLarge: AppTextStyles.buttonLabel,
        labelMedium: AppTextStyles.labelMd,
        labelSmall: AppTextStyles.labelSm,
      );

  // ── darkTheme ─────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: AppColors.kBackground,
      textTheme: _textTheme,
      splashColor: AppColors.kAccentMuted,
      highlightColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.kBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleMd,
        iconTheme: const IconThemeData(
          color: AppColors.kOnSurface,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.kOnSurface,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.kBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // ── NavigationBar (M3) ───────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.kSurfaceContainer,
        indicatorColor: AppColors.kAccentMuted,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.kPrimaryContainer
                : AppColors.kOnSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppTextStyles.labelSm
                  .copyWith(color: AppColors.kPrimaryContainer)
              : AppTextStyles.labelSm;
        }),
      ),

      // ── ElevatedButton ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimaryContainer,
          foregroundColor: AppColors.kOnPrimary,
          disabledBackgroundColor: AppColors.kDivider,
          disabledForegroundColor: AppColors.kDisabled,
          elevation: 0,
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          textStyle: AppTextStyles.buttonLabel,
        ),
      ),

      // ── OutlinedButton ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kPrimaryContainer,
          disabledForegroundColor: AppColors.kDisabled,
          side: const BorderSide(color: AppColors.kPrimaryContainer, width: 1.5),
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          textStyle: AppTextStyles.buttonLabel
              .copyWith(color: AppColors.kPrimaryContainer),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.kPrimaryContainer,
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.bodyMd
              .copyWith(color: AppColors.kPrimaryContainer),
        ),
      ),

      // ── IconButton ────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.kOnSurface,
          highlightColor: AppColors.kAccentMuted,
        ),
      ),

      // ── Input / TextField ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kSurfaceContainerHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.kOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.kOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.kPrimaryContainer, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.kErrorContainer),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: AppColors.kErrorContainer, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.kDisabled),
        labelStyle: AppTextStyles.bodyMd,
        floatingLabelStyle: AppTextStyles.labelMd
            .copyWith(color: AppColors.kPrimaryContainer),
        prefixIconColor: AppColors.kOnSurfaceVariant,
        suffixIconColor: AppColors.kOnSurfaceVariant,
        errorStyle: AppTextStyles.bodySm
            .copyWith(color: AppColors.kOnErrorContainer),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.kSurfaceContainerLow,
        selectedColor: AppColors.kAccentMuted,
        side: const BorderSide(color: AppColors.kOutline),
        shape: const StadiumBorder(),
        labelStyle: AppTextStyles.labelMd,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.kDivider,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.kSurfaceContainer,
        contentTextStyle: AppTextStyles.bodyMd,
        actionTextColor: AppColors.kPrimaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.kSurfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTextStyles.titleMd,
        contentTextStyle: AppTextStyles.bodyMd,
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.kSurfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.kOnSurfaceVariant,
        elevation: 0,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s
                .contains(WidgetState.selected)
            ? AppColors.kOnPrimary
            : AppColors.kOnSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.kPrimaryContainer
                : AppColors.kDivider),
      ),

      // ── Checkbox ──────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.kPrimaryContainer
                : Colors.transparent),
        checkColor: WidgetStateProperty.all(AppColors.kOnPrimary),
        side: const BorderSide(color: AppColors.kOnSurfaceVariant, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.kOnSurfaceVariant,
        textColor: AppColors.kOnSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.kPrimaryContainer,
        foregroundColor: AppColors.kOnPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        shape: CircleBorder(),
      ),

      // ── ProgressIndicator ─────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.kPrimaryContainer,
        linearTrackColor: AppColors.kDivider,
        circularTrackColor: AppColors.kDivider,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.kSurfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.kGlassBorder),
        ),
        textStyle: AppTextStyles.bodySm,
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      // Catatan: Gunakan GlassCard widget, bukan Card() bawaan Flutter.
      // CardTheme ini hanya fallback jika ada Card() yang terselip.
      cardTheme: CardThemeData(
        color: AppColors.kSurfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.kGlassBorder),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}

// ignore: unused_element — expose font package ke linter
final _googleFonts = GoogleFonts.inter;
