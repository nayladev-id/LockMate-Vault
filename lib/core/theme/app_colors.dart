import 'package:flutter/material.dart';

/// Token warna ZeroCrypt — SATU-SATUNYA sumber kebenaran warna.
///
/// Aturan:
/// - Dilarang hardcode hex di widget manapun.
/// - Selalu import file ini dan pakai konstanta berikut.
abstract final class AppColors {
  // ── Backgrounds ───────────────────────────────────────────────────────────

  /// Background utama Scaffold
  static const Color kBackground = Color(0xFF131313);

  /// Surface umum (sama dengan background untuk konsistensi dark mode)
  static const Color kSurface = Color(0xFF131313);

  /// Surface level rendah — divider area, inactive tab
  static const Color kSurfaceContainerLow = Color(0xFF1C1B1B);

  /// Surface container — card, bottom-sheet, dialog
  static const Color kSurfaceContainer = Color(0xFF201F1F);

  /// Surface level tinggi — nested card, input background
  static const Color kSurfaceContainerHigh = Color(0xFF2A2A2A);

  // ── Primary (Cyber Blue) ──────────────────────────────────────────────────

  /// Teks/icon di atas primaryContainer (sangat light blue)
  static const Color kPrimary = Color(0xFFC3F5FF);

  /// Cyber Blue — WAJIB di semua elemen interaktif (button, focused border,
  /// icon aktif, badge, progress indicator)
  static const Color kPrimaryContainer = Color(0xFF00E5FF);

  /// Teks/icon di atas kPrimaryContainer (gelap agar kontras)
  static const Color kOnPrimary = Color(0xFF00363D);

  // ── Text & Icon ───────────────────────────────────────────────────────────

  /// Teks utama — heading, body penting
  static const Color kOnSurface = Color(0xFFE5E2E1);

  /// Teks sekunder — label, hint, placeholder
  static const Color kOnSurfaceVariant = Color(0xFFBAC9CC);

  /// Outline / border default (unfocused)
  static const Color kOutline = Color(0xFF849396);

  // ── Error ─────────────────────────────────────────────────────────────────

  /// Background error container (merah gelap)
  static const Color kErrorContainer = Color(0xFF93000A);

  /// Teks di atas error container
  static const Color kOnErrorContainer = Color(0xFFFFDAD6);

  // ── Glass & Glow ──────────────────────────────────────────────────────────

  /// Background GlassCard — rgba(18,18,18,0.6)
  static const Color kGlassCard = Color(0x99121212);

  /// Cyber Blue glow — rgba(0,229,255,0.15) — BoxShadow aktif
  static const Color kCyberGlow = Color(0x2600E5FF);

  /// Border glass — rgba(255,255,255,0.1)
  static const Color kGlassBorder = Color(0x1AFFFFFF);

  // ── Semantic Status ───────────────────────────────────────────────────────

  /// Password strength — Weak
  static const Color kStrengthWeak = Color(0xFFFF5252);

  /// Password strength — Fair
  static const Color kStrengthFair = Color(0xFFFFB74D);

  /// Password strength — Good
  static const Color kStrengthGood = Color(0xFF69F0AE);

  /// Password strength — Strong (= Cyber Blue)
  static const Color kStrengthStrong = Color(0xFF00E5FF);

  // ── Misc ──────────────────────────────────────────────────────────────────

  /// Divider / hairline
  static const Color kDivider = Color(0xFF2A2A2A);

  /// Accent muted — bg chip aktif, selected state subtle
  static const Color kAccentMuted = Color(0x1A00E5FF);

  /// Disabled / placeholder text
  static const Color kDisabled = Color(0xFF5A5A5A);
}
