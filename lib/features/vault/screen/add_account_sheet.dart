import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../provider/vault_provider.dart';

/// AddAccountSheet — bottom sheet untuk menambah credential baru.
///
/// Dipanggil via [AddAccountSheet.show]. Tidak menerima masterPassword
/// sebagai parameter — diambil dari [VaultProvider.sessionPassword] yang
/// sudah tersimpan sejak vault di-unlock.
///
/// Layout: DraggableScrollableSheet dengan:
///   - Handle + header row
///   - 3 input field (platform, username, password)
///   - Smart Generator (slider length + toggles)
///   - Tombol Save
class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  /// Tampilkan sheet. Kembalikan `true` jika item berhasil disimpan.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAccountSheet(),
    );
  }

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  // ── Controllers ───────────────────────────────────────────────────────────
  final _platformCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  // ── Generator state ───────────────────────────────────────────────────────
  int  _length     = 16;
  bool _useUpper   = true;
  bool _useNumbers = true;
  bool _useSymbols = false;

  // ── UI state ──────────────────────────────────────────────────────────────
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _platformCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Generate password ─────────────────────────────────────────────────────

  String _generate() {
    const lower   = 'abcdefghijklmnopqrstuvwxyz';
    const upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = r'!@#$%^&*()_+-=[]{}|;:,.<>?';

    final chars = StringBuffer(lower);
    if (_useUpper)   chars.write(upper);
    if (_useNumbers) chars.write(numbers);
    if (_useSymbols) chars.write(symbols);

    final pool = chars.toString();
    final rand = Random.secure();
    return List.generate(_length, (_) => pool[rand.nextInt(pool.length)]).join();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveCredential() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final vault    = context.read<VaultProvider>();
    final masterPw = vault.sessionPassword;

    if (masterPw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault terkunci. Silakan buka kembali.')),
      );
      return;
    }

    await vault.addItem(
      platformName:  _platformCtrl.text.trim(),
      username:      _usernameCtrl.text.trim(),
      plainPassword: _passwordCtrl.text,
      masterPassword: masterPw,
    );

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Credential saved'),
          backgroundColor: AppColors.kSurfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1B1B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0x1AFFFFFF)),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Handle ─────────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF849396),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // ── Header row ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Account', style: AppTextStyles.headlineMd.copyWith(
                      fontFamily:  'HankenGrotesk',
                      fontSize:    24,
                      fontWeight:  FontWeight.w700,
                      color:       const Color(0xFFE5E2E1),
                    )),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Color(0xFFBAC9CC)),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),

              // ── Scrollable form ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Platform Name
                      _InputField(
                        controller: _platformCtrl,
                        label:      'Platform Name',
                        hint:       'e.g. GitHub',
                        prefixIcon: Icons.language_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Nama platform wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Username / Email
                      _InputField(
                        controller:  _usernameCtrl,
                        label:       'Username/Email',
                        hint:        'dev@zerocrypt.io',
                        prefixIcon:  Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Username wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Password
                      _PasswordField(
                        controller:         _passwordCtrl,
                        isVisible:          _isPasswordVisible,
                        onToggleVisibility: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        onGenerate: () {
                          final pw = _generate();
                          _passwordCtrl.text = pw;
                          Clipboard.setData(ClipboardData(text: pw));
                        },
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? 'Password wajib diisi' : null,
                      ),
                      const SizedBox(height: 24),

                      // ── Smart Generator section ─────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.bolt,
                              color: Color(0xFF00E5FF), size: 18),
                          const SizedBox(width: 6),
                          Text('SMART GENERATOR',
                              style: AppTextStyles.labelSm.copyWith(
                                fontFamily:    'JetBrains Mono',
                                fontSize:      12,
                                fontWeight:    FontWeight.w500,
                                color:         const Color(0xFF00E5FF),
                                letterSpacing: 0.08 * 12,
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),

                      GlassCard(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          children: [
                            // Length header + badge
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Password Length',
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: const Color(0xFFE5E2E1),
                                    )),
                                _LengthBadge(length: _length),
                              ],
                            ),

                            // Slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor:
                                    const Color(0xFF00E5FF),
                                inactiveTrackColor:
                                    const Color(0xFF201F1F),
                                thumbColor:    const Color(0xFF00E5FF),
                                overlayColor:  const Color(0x2600E5FF),
                                trackHeight:   2,
                              ),
                              child: Slider(
                                value:     _length.toDouble(),
                                min:       8,
                                max:       32,
                                divisions: 24,
                                onChanged: (v) =>
                                    setState(() => _length = v.toInt()),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Toggles
                            _ToggleRow(
                              label: 'Uppercase',
                              value: _useUpper,
                              onChanged: (v) =>
                                  setState(() => _useUpper = v),
                            ),
                            Divider(
                                color:  const Color(0x1AFFFFFF),
                                height: 1),
                            _ToggleRow(
                              label: 'Numbers',
                              value: _useNumbers,
                              onChanged: (v) =>
                                  setState(() => _useNumbers = v),
                            ),
                            Divider(
                                color:  const Color(0x1AFFFFFF),
                                height: 1),
                            _ToggleRow(
                              label: 'Symbols',
                              value: _useSymbols,
                              onChanged: (v) =>
                                  setState(() => _useSymbols = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Save button ─────────────────────────────────────
                      Consumer<VaultProvider>(
                        builder: (ctx2, vault, child) => SizedBox(
                          width:  double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: const Color(0xFF00363D),
                              elevation:       0,
                              shape: const StadiumBorder(),
                            ),
                            icon: vault.isLoading
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00363D)))
                                : const Icon(Icons.save_outlined, size: 20),
                            label: Text('Save Credential',
                                style: AppTextStyles.buttonLabel.copyWith(
                                  fontFamily:  'HankenGrotesk',
                                  fontSize:    18,
                                  fontWeight:  FontWeight.w700,
                                  color:       const Color(0xFF00363D),
                                )),
                            onPressed:
                                vault.isLoading ? null : _saveCredential,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _InputField ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController        controller;
  final String                       label;
  final String                       hint;
  final IconData?                    prefixIcon;
  final TextInputType?               keyboardType;
  final FormFieldValidator<String>?  validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.bodyLg.copyWith(color: const Color(0xFFE5E2E1)),
      cursorColor: const Color(0xFF00E5FF),
      validator: validator,
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        hintStyle:  AppTextStyles.bodyMd.copyWith(
            color: const Color(0xFF849396)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20,
                color: const Color(0xFF849396))
            : null,
        filled:     true,
        fillColor:  const Color(0xFF201F1F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.kErrorContainer, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.kErrorContainer, width: 1.5),
        ),
        floatingLabelStyle: AppTextStyles.labelSm.copyWith(
            color: const Color(0xFF00E5FF)),
        labelStyle: AppTextStyles.bodyMd.copyWith(
            color: const Color(0xFF849396)),
      ),
    );
  }
}

// ── _PasswordField ────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.onGenerate,
    this.validator,
  });

  final TextEditingController        controller;
  final bool                         isVisible;
  final VoidCallback                 onToggleVisibility;
  final VoidCallback                 onGenerate;
  final FormFieldValidator<String>?  validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:     controller,
      obscureText:    !isVisible,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.passwordText.copyWith(
          color: const Color(0xFFE5E2E1)),
      cursorColor: const Color(0xFF00E5FF),
      validator: validator,
      decoration: InputDecoration(
        labelText:  'Password',
        hintText:   '••••••••',
        hintStyle:  AppTextStyles.bodyMd.copyWith(
            color: const Color(0xFF849396)),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 20, color: Color(0xFF849396)),
        filled:     true,
        fillColor:  const Color(0xFF201F1F),
        // Suffix: eye + generate pill
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFFBAC9CC),
              ),
              onPressed: onToggleVisibility,
            ),
            GestureDetector(
              onTap: onGenerate,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: const Color(0xFF00E5FF)),
                ),
                child: Text('GENERATE',
                    style: AppTextStyles.labelSm.copyWith(
                      fontFamily:    'JetBrains Mono',
                      fontSize:      10,
                      color:         const Color(0xFF00E5FF),
                      fontWeight:    FontWeight.w500,
                      letterSpacing: 0.08 * 10,
                    )),
              ),
            ),
          ],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF00E5FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.kErrorContainer),
        ),
        floatingLabelStyle: AppTextStyles.labelSm.copyWith(
            color: const Color(0xFF00E5FF)),
        labelStyle: AppTextStyles.bodyMd.copyWith(
            color: const Color(0xFF849396)),
      ),
    );
  }
}

// ── _LengthBadge ──────────────────────────────────────────────────────────────

class _LengthBadge extends StatelessWidget {
  const _LengthBadge({required this.length});

  final int length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        const Color(0xFF00E5FF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
      ),
      child: Text(
        '$length',
        style: AppTextStyles.labelSm.copyWith(
          fontFamily:  'JetBrains Mono',
          fontSize:    12,
          fontWeight:  FontWeight.w500,
          color:       const Color(0xFF00E5FF),
        ),
      ),
    );
  }
}

// ── _ToggleRow ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String           label;
  final bool             value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMd.copyWith(
              color: const Color(0xFFE5E2E1),
            )),
        Switch(
          value:               value,
          onChanged:           onChanged,
          activeThumbColor:    const Color(0xFF00363D),
          activeTrackColor:    const Color(0xFF00E5FF),
          inactiveThumbColor:  const Color(0xFF849396),
          inactiveTrackColor:  const Color(0xFF2A2A2A),
          trackOutlineColor:
              WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }
}
