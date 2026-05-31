import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// GlassCard — card kustom ZeroCrypt dengan efek glassmorphism.
///
/// WAJIB digunakan sebagai pengganti [Card] bawaan Flutter di seluruh app.
///
/// Contoh penggunaan:
/// ```dart
/// GlassCard(
///   child: Text('Hello'),
/// )
///
/// GlassCard(
///   showGlow: true,
///   padding: EdgeInsets.all(20),
///   child: VaultItemRow(item: item),
/// )
/// ```
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24.0,
    this.showGlow = false,
    this.onTap,
    this.onLongPress,
  });

  /// Konten di dalam card
  final Widget child;

  /// Padding internal — default [EdgeInsets.all(16)]
  final EdgeInsetsGeometry padding;

  /// Radius sudut — default 24.0
  final double borderRadius;

  /// Aktifkan glow Cyber Blue — pakai untuk card yang sedang aktif/selected
  final bool showGlow;

  /// Callback tap — jika non-null, card menjadi tappable dengan InkWell
  final VoidCallback? onTap;

  /// Callback long-press
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.kGlassCard,
            borderRadius: radius,
            border: Border.all(
              color: AppColors.kGlassBorder,
              width: 1.0,
            ),
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: AppColors.kCyberGlow,
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    // Wrap dengan InkWell hanya jika ada callback
    if (onTap != null || onLongPress != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: AppColors.kAccentMuted,
          highlightColor: Colors.transparent,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Versi animated GlassCard — glow ber-pulse saat [showGlow] aktif.
/// Gunakan untuk highlight card terpilih atau item penting.
class GlassCardAnimated extends StatefulWidget {
  const GlassCardAnimated({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24.0,
    this.showGlow = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool showGlow;
  final VoidCallback? onTap;

  @override
  State<GlassCardAnimated> createState() => _GlassCardAnimatedState();
}

class _GlassCardAnimatedState extends State<GlassCardAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.showGlow) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GlassCardAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGlow != oldWidget.showGlow) {
      if (widget.showGlow) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => GlassCard(
        padding: widget.padding,
        borderRadius: widget.borderRadius,
        showGlow: widget.showGlow,
        onTap: widget.onTap,
        child: child!,
      ),
      child: widget.child,
    );
  }
}
