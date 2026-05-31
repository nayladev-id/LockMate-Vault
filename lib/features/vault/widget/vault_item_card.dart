import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../model/vault_item.dart';

/// VaultItemCard — kartu item vault sesuai referensi visual Stitch dashboard.
///
/// Layout (kiri ke kanan):
///   [_IconBox 56×56] [Expanded: platform + username + password] [👁 Eye + □ Copy]
///
/// Visibilitas password dikontrol oleh parent via [isPasswordVisible] dan
/// [onTogglePassword] — parent yang menyimpan state mana item yang terbuka
/// (Set of String _visibleIds di VaultScreen).
///
/// Copy feedback: icon berubah jadi ✓ selama 800ms (state internal _isCopied).
class VaultItemCard extends StatefulWidget {
  const VaultItemCard({
    super.key,
    required this.item,
    required this.onCopy,
    required this.onDelete,
    required this.onTap,
    required this.onTogglePassword,
    this.onEdit,
    this.isPasswordVisible = false,
    this.animationIndex    = 0,
  });

  final VaultItem    item;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  /// Callback saat eye button ditekan — parent yang toggle state.
  final VoidCallback onTogglePassword;

  /// Callback saat menu edit dipilih dari action sheet.
  final VoidCallback? onEdit;

  /// Dikontrol oleh parent (VaultScreen._visibleIds).
  final bool isPasswordVisible;

  /// Index untuk staggered animation delay (60ms × index).
  final int animationIndex;

  @override
  State<VaultItemCard> createState() => _VaultItemCardState();
}

class _VaultItemCardState extends State<VaultItemCard> {
  // Copy feedback — state internal, tidak perlu dikontrol parent
  bool   _isCopied = false;
  Timer? _copyResetTimer;

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    super.dispose();
  }

  // ── Copy feedback ─────────────────────────────────────────────────────────

  void _handleCopy() {
    widget.onCopy();
    setState(() => _isCopied = true);
    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  // ── Long press → action sheet ─────────────────────────────────────────────

  void _showActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.kSurfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ActionSheet(
        item:     widget.item,
        onCopy:   () { Navigator.pop(context); _handleCopy(); },
        onEdit:   widget.onEdit != null
            ? () { Navigator.pop(context); widget.onEdit!(); }
            : null,
        onDelete: () { Navigator.pop(context); widget.onDelete(); },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 60 * widget.animationIndex);

    return InkWell(
      onTap:       widget.onTap,
      onLongPress: _showActions,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── 1. Icon avatar ─────────────────────────────────────────────
            _IconBox(item: widget.item),

            const SizedBox(width: 14),

            // ── 2. Content ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Platform name
                  Text(
                    widget.item.platformName,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: const Color(0xFFE5E2E1),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Username
                  Text(
                    widget.item.username,
                    style: AppTextStyles.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Password — masked atau plaintext (dikontrol parent)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      key: ValueKey(widget.isPasswordVisible),
                      widget.isPasswordVisible
                          ? (widget.item.decryptedPassword ?? '••••••••')
                          : '• • • • • • • •',
                      style: AppTextStyles.passwordSm.copyWith(
                        letterSpacing: widget.isPasswordVisible ? 0.5 : 3.0,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // ── 3. Eye + Copy ──────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: widget.isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFFBAC9CC),
                  tooltip: widget.isPasswordVisible ? 'Hide' : 'Show',
                  onTap: widget.onTogglePassword,
                ),
                _ActionBtn(
                  icon: _isCopied
                      ? Icons.check_rounded
                      : Icons.copy_outlined,
                  color: _isCopied
                      ? AppColors.kStrengthGood
                      : AppColors.kPrimaryContainer,
                  tooltip: 'Copy password',
                  onTap: _handleCopy,
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 250.ms)
        .slideX(
          begin: 0.03,
          end: 0.0,
          delay: delay,
          duration: 250.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ── _IconBox ──────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  const _IconBox({required this.item});

  final VaultItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color:        item.iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.iconColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        item.iconInitials,
        style: AppTextStyles.titleSm.copyWith(
          fontFamily:  'HankenGrotesk',
          fontSize:    18,
          fontWeight:  FontWeight.w700,
          color:       item.iconColor,
          height:      1.0,
        ),
      ),
    );
  }
}

// ── _ActionBtn ────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData     icon;
  final Color        color;
  final String       tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed:   onTap,
        icon:        Icon(icon, size: 20, color: color),
        splashRadius: 20,
        padding:     const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}

// ── _ActionSheet ──────────────────────────────────────────────────────────────

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.item,
    required this.onCopy,
    required this.onDelete,
    this.onEdit,
  });

  final VaultItem    item;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.kOnSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                _IconBox(item: item),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.platformName, style: AppTextStyles.titleSm),
                      Text(item.username,     style: AppTextStyles.bodyMd),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.kDivider, height: 1),
            const SizedBox(height: 8),

            _Tile(
              icon:  Icons.copy_outlined,
              label: 'Copy Password',
              color: AppColors.kPrimaryContainer,
              onTap: onCopy,
            ),
            if (onEdit != null)
              _Tile(
                icon:  Icons.edit_outlined,
                label: 'Edit',
                color: AppColors.kOnSurface,
                onTap: onEdit!,
              ),
            _Tile(
              icon:  Icons.delete_outline_rounded,
              label: 'Delete',
              color: AppColors.kStrengthWeak,
              onTap: onDelete,
            ),
            _Tile(
              icon:  Icons.close_rounded,
              label: 'Cancel',
              color: AppColors.kOnSurfaceVariant,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _Tile ─────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:        Icon(icon, color: color, size: 22),
      title:          Text(label, style: AppTextStyles.bodyLg.copyWith(color: color)),
      onTap:          onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape:          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
