import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// PasswordField — input field khusus untuk password/secret ZeroCrypt.
///
/// Fitur:
/// - Toggle obscureText via eye icon di suffix
/// - Font JetBrains Mono otomatis saat ada teks (via controller listener)
/// - Border Cyber Blue saat focused
/// - Border radius 8 (input field spec)
/// - Suffix icon warna [AppColors.kPrimaryContainer]
///
/// Contoh penggunaan:
/// ```dart
/// PasswordField(
///   label: 'Master Password',
///   controller: _controller,
///   onChanged: (val) => ...,
///   validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
/// )
///
/// // Dengan konfirmasi
/// PasswordField(
///   label: 'Konfirmasi Password',
///   hintText: 'Ulangi password di atas',
///   controller: _confirmController,
/// )
/// ```
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
  });

  /// Label field (floating label)
  final String? label;

  /// Hint teks saat kosong
  final String? hintText;

  /// Controller — opsional, widget bisa digunakan tanpa controller
  final TextEditingController? controller;

  /// Callback setiap perubahan teks
  final ValueChanged<String>? onChanged;

  /// Validator untuk Form validation
  final FormFieldValidator<String>? validator;

  /// Keyboard action (default: done)
  final TextInputAction textInputAction;

  /// Callback saat user submit (tekan done/enter)
  final ValueChanged<String>? onFieldSubmitted;

  /// FocusNode opsional
  final FocusNode? focusNode;

  /// Auto-focus saat widget muncul
  final bool autofocus;

  /// Nonaktifkan field
  final bool enabled;

  /// Icon prefix opsional (contoh: Icons.lock_outline)
  final IconData? prefixIcon;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;
  bool _hasText = false;

  // Internal controller jika tidak ada controller dari luar
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_onTextChanged);
    _hasText = _effectiveController.text.isNotEmpty;
  }

  void _onTextChanged() {
    final hasText = _effectiveController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onTextChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _toggleObscure() {
    setState(() => _obscure = !_obscure);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _effectiveController,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,

      // Selalu gunakan JetBrains Mono untuk field password
      style: _hasText
          ? AppTextStyles.passwordText
          : AppTextStyles.bodyMd.copyWith(
              fontFamily: GoogleFonts.inter().fontFamily,
            ),

      // Kursornya Cyber Blue
      cursorColor: AppColors.kPrimaryContainer,
      cursorWidth: 2.0,

      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText ?? 'Masukkan password',

        // Override labelStyle saat focus (Cyber Blue)
        labelStyle: AppTextStyles.bodyMd,
        floatingLabelStyle:
            AppTextStyles.labelMd.copyWith(color: AppColors.kPrimaryContainer),

        // Prefix icon opsional
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  widget.prefixIcon,
                  color: AppColors.kOnSurfaceVariant,
                  size: 20,
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),

        // Suffix — eye icon toggle
        suffixIcon: _EyeToggleButton(
          obscure: _obscure,
          onToggle: _toggleObscure,
        ),

        // Border styling
        filled: true,
        fillColor: AppColors.kSurfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        // Border radius 8 sesuai spec
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
          borderSide: const BorderSide(
            color: AppColors.kPrimaryContainer,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.kErrorContainer),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.kErrorContainer,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.kSurfaceContainerHigh),
        ),

        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.kDisabled),
        errorStyle: AppTextStyles.bodySm
            .copyWith(color: AppColors.kOnErrorContainer),
        errorMaxLines: 2,
      ),
    );
  }
}

/// Eye toggle button — suffix widget untuk PasswordField.
/// Terpisah agar mudah di-test dan tidak trigger rebuild seluruh field.
class _EyeToggleButton extends StatelessWidget {
  const _EyeToggleButton({
    required this.obscure,
    required this.onToggle,
  });

  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
      splashRadius: 20,
      color: AppColors.kPrimaryContainer,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          key: ValueKey(obscure),
          color: AppColors.kPrimaryContainer,
          size: 20,
        ),
      ),
    );
  }
}
