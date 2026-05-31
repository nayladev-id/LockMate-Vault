import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../services/crypto_service.dart';
import '../model/vault_item.dart';

/// AccountDetailScreen — detail lengkap satu vault item.
///
/// Menerima [VaultItem] via `Navigator.pushNamed(ctx, '/detail', arguments: item)`.
///
/// Menampilkan:
///   - Icon besar 96×96 + glow + platform name + subtitle
///   - _DetailCard: PLATFORM NAME, USERNAME
///   - Password card khusus: toggle visibility + strength bar + label
///   - NOTES card (kondisional)
///   - Badge pills: AES-256 Encrypted + last updated
///   - Tombol "Edit Credential"
class AccountDetailScreen extends StatefulWidget {
  const AccountDetailScreen({super.key});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  bool   _isPasswordVisible = false;
  Timer? _clipboardTimer;

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Hitung selisih hari dari [dt] hingga sekarang.
  int _daysAgo(DateTime dt) =>
      DateTime.now().difference(dt).inDays;

  /// Password strength 0.0 – 1.0 berdasarkan panjang + variasi karakter.
  double _strengthValue(String? pw) {
    if (pw == null || pw.isEmpty) return 0.0;
    try {
      final s = CryptoService().checkStrength(pw);
      return switch (s) {
        PasswordStrength.weak       => 0.25,
        PasswordStrength.fair       => 0.50,
        PasswordStrength.strong     => 0.75,
        PasswordStrength.veryStrong => 1.0,
      };
    } catch (_) {
      // Fallback manual jika CryptoService tidak tersedia
      final len     = pw.length;
      final hasUp   = pw.contains(RegExp(r'[A-Z]'));
      final hasLow  = pw.contains(RegExp(r'[a-z]'));
      final hasNum  = pw.contains(RegExp(r'[0-9]'));
      final hasSym  = pw.contains(RegExp(r'[^a-zA-Z0-9]'));
      final variety = [hasUp, hasLow, hasNum, hasSym].where((b) => b).length;
      if (len >= 16 && variety >= 4) return 1.0;
      if (len >= 12 && variety >= 3) return 0.75;
      if (len >= 8  && variety >= 2) return 0.5;
      return 0.25;
    }
  }

  /// Label strength untuk strength bar.
  String _strengthLabel(double value) {
    if (value >= 1.0) return 'VERY STRONG ENTROPY';
    if (value >= 0.75) return 'STRONG ENTROPY';
    if (value >= 0.5)  return 'FAIR ENTROPY';
    return 'WEAK ENTROPY';
  }

  /// Warna strength bar.
  Color _strengthColor(double value) {
    if (value >= 1.0) return AppColors.kStrengthStrong;
    if (value >= 0.75) return AppColors.kStrengthGood;
    if (value >= 0.5)  return AppColors.kStrengthFair;
    return AppColors.kStrengthWeak;
  }

  /// Salin teks ke clipboard + SnackBar + auto-clear 30 detik.
  Future<void> _copyToClipboard(String text, {String label = 'Copied'}) async {
    await Clipboard.setData(ClipboardData(text: text));

    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(const Duration(seconds: 30), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label — clears in 30s',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.kOnSurface),
          ),
          backgroundColor: AppColors.kSurfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Clear',
            textColor: AppColors.kPrimaryContainer,
            onPressed: () {
              _clipboardTimer?.cancel();
              Clipboard.setData(const ClipboardData(text: ''));
            },
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Ambil VaultItem dari route arguments
    final item = ModalRoute.of(context)?.settings.arguments as VaultItem?;

    if (item == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF131313),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131313),
          leading: BackButton(color: AppColors.kPrimaryContainer),
        ),
        body: Center(
          child: Text('Item tidak ditemukan', style: AppTextStyles.bodyLg),
        ),
      );
    }

    final plaintext     = item.decryptedPassword ?? '';
    final strengthVal   = _strengthValue(plaintext);
    final strengthLabel = _strengthLabel(strengthVal);
    final strengthColor = _strengthColor(strengthVal);
    final daysAgo       = _daysAgo(item.updatedAt);

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131313),
        elevation:       0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: const Color(0xFF00E5FF)),
        title: Text(
          'Credential Detail',
          style: AppTextStyles.titleMd.copyWith(
            fontFamily:  'HankenGrotesk',
            fontSize:    20,
            fontWeight:  FontWeight.w500,
            color:       const Color(0xFF00E5FF),
          ),
        ),
        actions: [
          // Avatar
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
                  item.iconInitials.isNotEmpty
                      ? item.iconInitials[0]
                      : '?',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // ── Icon besar 96×96 ─────────────────────────────────────────
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color:        item.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.iconColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      item.iconColor.withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                item.iconInitials,
                style: AppTextStyles.headlineMd.copyWith(
                  fontFamily:  'HankenGrotesk',
                  fontSize:    36,
                  fontWeight:  FontWeight.w700,
                  color:       item.iconColor,
                  height:      1.0,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Platform name besar ──────────────────────────────────────
            Text(
              item.platformName,
              style: AppTextStyles.headlineMd.copyWith(
                fontFamily:  'HankenGrotesk',
                fontSize:    28,
                fontWeight:  FontWeight.w700,
                color:       const Color(0xFFE5E2E1),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // ── Subtitle ─────────────────────────────────────────────────
            Text(
              'PERSONAL ACCOUNT',
              style: AppTextStyles.labelSm.copyWith(
                fontFamily:    'JetBrains Mono',
                fontSize:      11,
                letterSpacing: 0.08 * 11,
                color:         const Color(0xFFBAC9CC),
              ),
            ),

            const SizedBox(height: 28),

            // ── PLATFORM NAME card ───────────────────────────────────────
            _DetailCard(
              label: 'PLATFORM NAME',
              value: item.platformName,
              onCopy: () =>
                  _copyToClipboard(item.platformName, label: 'Platform name copied'),
            ),
            const SizedBox(height: 8),

            // ── USERNAME card ────────────────────────────────────────────
            _DetailCard(
              label: 'USERNAME',
              value: item.username,
              onCopy: () =>
                  _copyToClipboard(item.username, label: 'Username copied'),
            ),
            const SizedBox(height: 8),

            // ── PASSWORD card (special) ──────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Text(
                    'PASSWORD',
                    style: AppTextStyles.labelSm.copyWith(
                      color:         const Color(0xFF00E5FF),
                      letterSpacing: 0.08 * 11,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Password text + toggle + copy
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isPasswordVisible
                              ? (plaintext.isNotEmpty ? plaintext : '—')
                              : '• • • • • • • • • • • •',
                          style: AppTextStyles.passwordText.copyWith(
                            fontSize:      16,
                            color:         const Color(0xFFE5E2E1),
                            letterSpacing: _isPasswordVisible ? 0.5 : 3.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Eye toggle
                      IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFFBAC9CC),
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        tooltip: _isPasswordVisible ? 'Hide' : 'Show',
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.all(8),
                      ),
                      // Copy
                      IconButton(
                        icon: const Icon(
                          Icons.copy_outlined,
                          color: Color(0xFF00E5FF),
                          size: 20,
                        ),
                        onPressed: plaintext.isNotEmpty
                            ? () => _copyToClipboard(plaintext,
                                label: 'Password copied')
                            : null,
                        tooltip: 'Copy password',
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Strength bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:           strengthVal,
                      minHeight:       4,
                      backgroundColor: const Color(0xFF201F1F),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(strengthColor),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Strength label
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      strengthLabel,
                      style: AppTextStyles.labelSm.copyWith(
                        color:         strengthColor,
                        letterSpacing: 0.05 * 10,
                        fontSize:      10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── NOTES card (kondisional) ─────────────────────────────────
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              _DetailCard(label: 'NOTES', value: item.notes!),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),

            // ── Badge pills ──────────────────────────────────────────────
            Row(
              children: [
                _BadgePill(
                  icon:  Icons.shield_outlined,
                  label: 'AES-256 Encrypted',
                  color: const Color(0xFF00E5FF),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _BadgePill(
                  icon: Icons.history_rounded,
                  label: daysAgo == 0
                      ? 'Updated today'
                      : 'Last updated $daysAgo day${daysAgo != 1 ? 's' : ''} ago',
                  color: const Color(0xFFBAC9CC),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Edit button ──────────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF00363D),
                  elevation:       0,
                  shape: const StadiumBorder(),
                ),
                icon:  const Icon(Icons.edit_outlined, size: 20),
                label: Text(
                  'Edit Credential',
                  style: AppTextStyles.buttonLabel.copyWith(
                    fontFamily:  'HankenGrotesk',
                    fontSize:    16,
                    fontWeight:  FontWeight.w700,
                    color:       const Color(0xFF00363D),
                  ),
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, '/edit', arguments: item),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── _DetailCard ───────────────────────────────────────────────────────────────

/// GlassCard generik: label (JetBrains Mono cyan 11px) + value + copy button opsional.
class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String       label;
  final String       value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    color:         const Color(0xFF00E5FF),
                    letterSpacing: 0.08 * 11,
                  ),
                ),
                const SizedBox(height: 6),
                // Value
                Text(
                  value.isNotEmpty ? value : '—',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: const Color(0xFFE5E2E1),
                  ),
                ),
              ],
            ),
          ),
          // Copy button (opsional)
          if (onCopy != null)
            IconButton(
              icon: const Icon(
                Icons.copy_outlined,
                size: 18,
                color: Color(0xFF00E5FF),
              ),
              onPressed: onCopy,
              tooltip:     'Copy',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding:     const EdgeInsets.all(8),
            ),
        ],
      ),
    );
  }
}

// ── _BadgePill ────────────────────────────────────────────────────────────────

/// Pill container dengan icon + label — dipakai untuk "AES-256 Encrypted" dll.
class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String   label;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color:      color,
              fontSize:   11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
