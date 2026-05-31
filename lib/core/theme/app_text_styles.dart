import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Semua TextStyle ZeroCrypt — SATU-SATUNYA sumber kebenaran tipografi.
///
/// Font mapping:
///   Headline / Title → HankenGrotesk (w700 / w500)
///   Body             → Inter          (w400)
///   Password / Label → JetBrains Mono (w500)
///
/// Aturan:
/// - Jangan buat TextStyle inline di widget.
/// - Selalu pakai [AppTextStyles.xxx].
/// - Untuk variasi warna, gunakan [copyWith(color: ...)].
abstract final class AppTextStyles {
  // ── Headline (HankenGrotesk) ──────────────────────────────────────────────

  /// Headline besar — hero text, title halaman utama
  /// HankenGrotesk 32px w700 letterSpacing -2%
  static final TextStyle headlineLg = GoogleFonts.hankenGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 32 * -0.02, // -2% dari font size
    color: AppColors.kOnSurface,
    height: 1.2,
  );

  /// Headline medium — judul section, modal title
  /// HankenGrotesk 28px w700 Cyber Blue
  static final TextStyle headlineMd = GoogleFonts.hankenGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.kPrimaryContainer,
    height: 1.25,
  );

  /// Headline kecil — sub-section title
  /// HankenGrotesk 22px w500 kOnSurface
  static final TextStyle titleLg = GoogleFonts.hankenGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.kOnSurface,
    height: 1.3,
  );

  /// Title medium — card title, list item primary
  /// HankenGrotesk 18px w600 kOnSurface
  static final TextStyle titleMd = GoogleFonts.hankenGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.kOnSurface,
    height: 1.35,
  );

  /// Title kecil — secondary label, tag
  /// HankenGrotesk 15px w500 kOnSurface
  static final TextStyle titleSm = GoogleFonts.hankenGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.kOnSurface,
    height: 1.4,
  );

  // ── Body (Inter) ──────────────────────────────────────────────────────────

  /// Body besar — konten utama, deskripsi panjang
  /// Inter 16px w400 kOnSurface
  static final TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.kOnSurface,
    height: 1.55,
  );

  /// Body medium — teks pendukung, label list
  /// Inter 14px w400 kOnSurfaceVariant
  static final TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.kOnSurfaceVariant,
    height: 1.5,
  );

  /// Body kecil — caption, footnote, hint
  /// Inter 12px w400 kOnSurfaceVariant
  static final TextStyle bodySm = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.kOnSurfaceVariant,
    height: 1.45,
  );

  /// Button label — teks tombol
  /// Inter 15px w600 kOnPrimary
  static final TextStyle buttonLabel = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.kOnPrimary,
    letterSpacing: 0.3,
    height: 1.0,
  );

  // ── Mono (JetBrains Mono) ─────────────────────────────────────────────────

  /// Label mono — key name, category tag, metadata
  /// JetBrains Mono 12px w500 letterSpacing 5%
  static final TextStyle labelMd = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 12 * 0.05, // 5% dari font size
    color: AppColors.kOnSurfaceVariant,
    height: 1.4,
  );

  /// Label kecil — badge, chip, status indicator
  /// JetBrains Mono 11px w500 letterSpacing 5%
  static final TextStyle labelSm = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 11 * 0.05,
    color: AppColors.kOnSurfaceVariant,
    height: 1.4,
  );

  /// Teks password / secret — field password, token, key
  /// JetBrains Mono 16px w500 Cyber Blue
  static final TextStyle passwordText = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.kPrimaryContainer,
    height: 1.5,
    letterSpacing: 0.5,
  );

  /// Teks password besar — display di password generator
  /// JetBrains Mono 20px w600 Cyber Blue letterSpacing 2px
  static final TextStyle passwordLg = GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.kPrimaryContainer,
    height: 1.4,
    letterSpacing: 2.0,
  );

  /// Teks password kecil — masked/obscured di list
  /// JetBrains Mono 14px w500 kOnSurfaceVariant
  static final TextStyle passwordSm = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.kOnSurfaceVariant,
    height: 1.5,
  );
}
