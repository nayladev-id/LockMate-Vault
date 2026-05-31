import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../model/vault_item.dart';
import '../provider/vault_provider.dart';

/// EditCredentialScreen — layar edit credential existing.
///
/// Menerima [VaultItem] via `Navigator.pushNamed(context, '/edit', arguments: item)`.
/// Master password diambil dari [VaultProvider.sessionPassword].
///
/// Layout:
///   - AppBar dengan X button + avatar
///   - Icon besar 96px + glow radial + camera badge
///   - GlassCard: Platform Name, Username, Password (+ GENERATE), Notes
///   - Info card peringatan
///   - Save + Discard buttons
class EditCredentialScreen extends StatefulWidget {
  const EditCredentialScreen({super.key});

  @override
  State<EditCredentialScreen> createState() => _EditCredentialScreenState();
}

class _EditCredentialScreenState extends State<EditCredentialScreen> {
  final _platformCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();

  bool       _isPasswordVisible = false;
  VaultItem? _item;
  bool       _initialized       = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _item = ModalRoute.of(context)?.settings.arguments as VaultItem?;
      if (_item != null) {
        _platformCtrl.text = _item!.platformName;
        _usernameCtrl.text = _item!.username;
        _passwordCtrl.text = _item!.decryptedPassword ?? '';
        _notesCtrl.text    = _item!.notes ?? '';
      }
    }
  }

  @override
  void dispose() {
    _platformCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Generate password ─────────────────────────────────────────────────────

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    _passwordCtrl.text =
        List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ── Confirm discard ───────────────────────────────────────────────────────

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kSurfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Text('Discard Changes?',
            style: AppTextStyles.titleMd),
        content: Text('Perubahan yang belum disimpan akan hilang.',
            style: AppTextStyles.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.bodyMd),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kErrorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard', style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) {
      Navigator.pop(context);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (_item == null) return;
    FocusScope.of(context).unfocus();

    final vault    = context.read<VaultProvider>();
    final masterPw = vault.sessionPassword;

    if (masterPw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vault terkunci. Silakan buka kembali.')),
      );
      return;
    }

    final updated = _item!.copyWith(
      platformName:      _platformCtrl.text.trim(),
      username:          _usernameCtrl.text.trim(),
      decryptedPassword: _passwordCtrl.text,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
    );

    await vault.updateItem(updated, masterPw);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Changes saved'),
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
    if (_item == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF131313),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131313),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFE5E2E1)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text('Item tidak ditemukan',
              style: AppTextStyles.bodyLg),
        ),
      );
    }

    final item     = _item!;
    final isLoading =
        context.select<VaultProvider, bool>((v) => v.isLoading);

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131313),
        elevation:       0,
        surfaceTintColor: Colors.transparent,
        // X button
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFE5E2E1)),
          onPressed: _confirmDiscard,
          tooltip: 'Tutup',
        ),
        title: Text('Edit Credential',
            style: AppTextStyles.titleMd.copyWith(
              fontFamily:  'HankenGrotesk',
              fontSize:    20,
              fontWeight:  FontWeight.w500,
              color:       const Color(0xFFE5E2E1),
            )),
        actions: [
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
                      ? item.iconInitials[0] : '?',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Icon + glow + camera badge ──────────────────────────────
            _IconHero(item: item),
            const SizedBox(height: 28),

            // ── Platform Name card ──────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform Name',
                      style: AppTextStyles.labelSm.copyWith(
                        fontFamily:    'JetBrains Mono',
                        fontSize:      11,
                        color:         const Color(0xFFBAC9CC),
                        letterSpacing: 0.05 * 11,
                      )),
                  TextField(
                    controller: _platformCtrl,
                    style: AppTextStyles.headlineMd.copyWith(
                      fontFamily:  'HankenGrotesk',
                      fontSize:    22,
                      fontWeight:  FontWeight.w700,
                      color:       const Color(0xFF00E5FF),
                    ),
                    cursorColor: const Color(0xFF00E5FF),
                    decoration: const InputDecoration(
                      border:   InputBorder.none,
                      hintText: 'Platform name',
                      hintStyle: TextStyle(
                          color: Color(0xFF849396)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Username card ───────────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username/Email',
                      style: AppTextStyles.labelSm.copyWith(
                        fontFamily:    'JetBrains Mono',
                        fontSize:      11,
                        color:         const Color(0xFFBAC9CC),
                        letterSpacing: 0.05 * 11,
                      )),
                  Row(
                    children: [
                      const Icon(Icons.alternate_email,
                          color: Color(0xFF849396), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller:  _usernameCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.bodyLg.copyWith(
                              color: const Color(0xFFE5E2E1)),
                          cursorColor: const Color(0xFF00E5FF),
                          decoration:
                              const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Password card ───────────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Password',
                      style: AppTextStyles.labelSm.copyWith(
                        fontFamily:    'JetBrains Mono',
                        fontSize:      11,
                        color:         const Color(0xFFBAC9CC),
                        letterSpacing: 0.05 * 11,
                      )),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: Color(0xFF849396), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller:  _passwordCtrl,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.passwordText.copyWith(
                            fontSize: 15,
                            color:    const Color(0xFFE5E2E1),
                          ),
                          cursorColor: const Color(0xFF00E5FF),
                          decoration:
                              const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                      // Eye
                      IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFFBAC9CC),
                          size: 18,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                        padding: const EdgeInsets.all(6),
                      ),
                      // GENERATE pill
                      GestureDetector(
                        onTap: () =>
                            setState(() => _generatePassword()),
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: const Color(0xFF00E5FF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.vpn_key_outlined,
                                  color: Color(0xFF00E5FF), size: 12),
                              const SizedBox(width: 4),
                              Text('GENERATE',
                                  style: AppTextStyles.labelSm.copyWith(
                                    fontFamily:    'JetBrains Mono',
                                    fontSize:      10,
                                    color:         const Color(0xFF00E5FF),
                                    fontWeight:    FontWeight.w500,
                                    letterSpacing: 0.08 * 10,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Notes card ──────────────────────────────────────────────
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes & Recovery Codes',
                      style: AppTextStyles.labelSm.copyWith(
                        fontFamily:    'JetBrains Mono',
                        fontSize:      11,
                        color:         const Color(0xFFBAC9CC),
                        letterSpacing: 0.05 * 11,
                      )),
                  TextField(
                    controller: _notesCtrl,
                    maxLines:   4,
                    minLines:   2,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: const Color(0xFFE5E2E1)),
                    cursorColor: const Color(0xFF00E5FF),
                    decoration: const InputDecoration(
                      border:   InputBorder.none,
                      hintText: 'Recovery codes, notes...',
                      hintStyle: TextStyle(color: Color(0xFF849396)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Info card ───────────────────────────────────────────────
            _InfoCard(),
            const SizedBox(height: 20),

            // ── Save button ─────────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF00363D),
                  elevation:       0,
                  shape: const StadiumBorder(),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00363D)))
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text('Save Changes',
                    style: AppTextStyles.buttonLabel.copyWith(
                      fontFamily:  'HankenGrotesk',
                      fontSize:    18,
                      fontWeight:  FontWeight.w700,
                      color:       const Color(0xFF00363D),
                    )),
                onPressed: isLoading ? null : _saveChanges,
              ),
            ),
            const SizedBox(height: 12),

            // ── Discard button ──────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Discard Changes',
                    style: AppTextStyles.labelSm.copyWith(
                      fontFamily:    'JetBrains Mono',
                      fontSize:      12,
                      color:         const Color(0xFF849396),
                      letterSpacing: 0.05 * 12,
                    )),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── _IconHero ─────────────────────────────────────────────────────────────────

/// Stack: radial glow + icon box 96px + camera badge.
class _IconHero extends StatelessWidget {
  const _IconHero({required this.item});

  final VaultItem item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radial glow
            Container(
              width: 160, height: 100,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x3300E5FF), Colors.transparent],
                  radius: 1.0,
                ),
              ),
            ),
            // Icon container 96px
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color:        item.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.iconColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
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
            // Camera badge — pojok kanan bawah
            Positioned(
              bottom: 4,
              right:  4,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x4000E5FF),
                        blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF00363D), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _InfoCard ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        const Color(0xFF201F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF849396), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Changes to this credential will be saved to your '
              'encrypted vault immediately. Ensure your local backup '
              'is up to date before saving significant changes.',
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 13,
                color:    const Color(0xFFBAC9CC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
