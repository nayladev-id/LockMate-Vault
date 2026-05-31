import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// CyberButton — tombol utama ZeroCrypt dengan efek Cyber Blue glow.
///
/// Spesifikasi:
/// - Background: [AppColors.kPrimaryContainer] (Cyber Blue)
/// - Teks: [AppColors.kOnPrimary] (dark teal)
/// - Shape: pill (borderRadius 999)
/// - Height: 52px
/// - Glow: [AppColors.kCyberGlow] blurRadius 15 (idle) → 25 (pressed)
///
/// Contoh penggunaan:
/// ```dart
/// // Full-width dengan icon
/// CyberButton(
///   label: 'Buka Vault',
///   icon: Icons.lock_open_rounded,
///   isFullWidth: true,
///   onPressed: () => ...,
/// )
///
/// // Compact tanpa icon
/// CyberButton(
///   label: 'Simpan',
///   onPressed: () => ...,
/// )
/// ```
class CyberButton extends StatefulWidget {
  const CyberButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isFullWidth = false,
    this.icon,
    this.isLoading = false,
  });

  /// Teks label tombol
  final String label;

  /// Callback saat tombol ditekan. Set null untuk disabled state.
  final VoidCallback? onPressed;

  /// Jika true, tombol mengisi lebar penuh parent
  final bool isFullWidth;

  /// Opsional icon di sisi kiri label
  final IconData? icon;

  /// Tampilkan loading spinner, nonaktifkan tombol
  final bool isLoading;

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _glowAnim = Tween<double>(begin: 15.0, end: 28.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isEnabled) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    if (!_isEnabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _isEnabled;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: isEnabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 52,
              width: widget.isFullWidth ? double.infinity : null,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.kPrimaryContainer
                    : AppColors.kSurfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: AppColors.kCyberGlow,
                          blurRadius: _glowAnim.value,
                          spreadRadius: 0,
                          offset: Offset.zero,
                        ),
                      ]
                    : null,
              ),
              child: _buildContent(isEnabled),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isEnabled) {
    if (widget.isLoading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.kOnPrimary),
          ),
        ),
      );
    }

    final labelColor =
        isEnabled ? AppColors.kOnPrimary : AppColors.kDisabled;
    final iconColor = isEnabled ? AppColors.kOnPrimary : AppColors.kDisabled;

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:
            widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(widget.icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: AppTextStyles.buttonLabel.copyWith(color: labelColor),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        widget.label,
        style: AppTextStyles.buttonLabel.copyWith(color: labelColor),
      ),
    );
  }
}

/// CyberButtonOutlined — varian outline/ghost dari CyberButton.
///
/// Digunakan untuk aksi sekunder (contoh: "Batal", "Lewati").
class CyberButtonOutlined extends StatelessWidget {
  const CyberButtonOutlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.isFullWidth = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kPrimaryContainer,
          side: const BorderSide(
              color: AppColors.kPrimaryContainer, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          textStyle: AppTextStyles.buttonLabel
              .copyWith(color: AppColors.kPrimaryContainer),
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}
