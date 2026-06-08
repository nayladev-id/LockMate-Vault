import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/vault_item.dart';
import '../provider/vault_provider.dart';
import '../widget/vault_item_card.dart';

/// VaultScreen — halaman utama vault, desain sesuai referensi Stitch.
///
/// Layout (CustomScrollView + Slivers):
///   - SliverAppBar: "ZeroCrypt" (cyan) + avatar → settings
///   - Search bar pill: "Search your vault..."
///   - Header "All Accounts" + badge counter
///   - SliverList vault items (VaultItemCard)
///   - FAB: tambah item baru
///
/// State:
///   - _visibleIds: Set of item IDs yang sedang ditampilkan password-nya
///   - masterPassword diambil dari route arguments (dikirim dari LoginScreen)
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  /// Tracks item IDs yang sedang ditampilkan password-nya.
  final Set<String> _visibleIds = {};

  final _searchController = TextEditingController();
  String? _masterPassword;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Inisialisasi ──────────────────────────────────────────────────────────

  Future<void> _init() async {
    if (!mounted) return;

    // Ambil master password dari route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    final mp   = args is String ? args : null;

    // Jika tidak ada dari route, tampilkan dialog
    final masterPassword = mp ?? await _askMasterPassword();
    if (!mounted || masterPassword == null) return;

    _masterPassword = masterPassword;

    // Load vault items dari storage (decrypt in-memory)
    final vault = context.read<VaultProvider>();
    if (vault.itemCount == 0) {
      await vault.loadItems(masterPassword);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<String?> _askMasterPassword() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MasterPasswordDialog(controller: ctrl),
    );
  }

  void _showAddSheet() {
    if (_masterPassword == null) {
      _askMasterPassword().then((mp) {
        if (mp == null || !mounted) return;
        _masterPassword = mp;
        _openAddSheet();
      });
    } else {
      _openAddSheet();
    }
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditSheet(masterPassword: _masterPassword!),
    );
  }

  void _showEditSheet(VaultItem item) {
    if (_masterPassword == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditSheet(
        masterPassword: _masterPassword!,
        editItem:       item,
      ),
    );
  }

  void _showDeleteSheet(BuildContext ctx, VaultItem item) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.kSurfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DeleteSheet(
        item: item,
        onConfirm: () {
          Navigator.pop(ctx);
          if (_masterPassword != null) {
            context.read<VaultProvider>().deleteItem(item.id, _masterPassword!);
          }
        },
      ),
    );
  }

  // ── Toggle visibility ─────────────────────────────────────────────────────

  void _toggleVisibility(String id) {
    setState(() {
      if (_visibleIds.contains(id)) {
        _visibleIds.remove(id);
      } else {
        _visibleIds.add(id);
      }
    });
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    context.read<VaultProvider>().clearAll();
    context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ────────────────────────────────────────────────
          SliverAppBar(
            floating:        true,
            snap:            true,
            pinned:          false,
            backgroundColor: const Color(0xFF131313),
            elevation:       0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.lock_outline_rounded,
                  color: Color(0xFF00E5FF)),
              tooltip: 'Lock Vault',
              onPressed: _logout,
            ),
            title: Text(
              'ZeroCrypt',
              style: AppTextStyles.titleLg.copyWith(
                fontFamily:  'HankenGrotesk',
                fontSize:    22,
                fontWeight:  FontWeight.w700,
                color:       const Color(0xFF00E5FF),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A2A2A),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: profile?.displayName != null
                      ? Center(
                          child: Text(
                            profile!.displayName.isNotEmpty
                                ? profile.displayName[0].toUpperCase()
                                : 'U',
                            style: AppTextStyles.titleSm.copyWith(
                              color: const Color(0xFF00E5FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.0,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Color(0xFFBAC9CC),
                          size: 20,
                        ),
                ),
              ),
            ],
          ),

          // ── Search bar pill ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: context.read<VaultProvider>().setSearchQuery,
                style: AppTextStyles.bodyLg.copyWith(
                  color: const Color(0xFFE5E2E1),
                ),
                cursorColor: const Color(0xFF00E5FF),
                decoration: InputDecoration(
                  hintText:  'Search your vault...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: const Color(0xFF849396),
                  ),
                  filled:    true,
                  fillColor: const Color(0xFF1C1B1B),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF849396),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Color(0xFF849396), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<VaultProvider>().setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                        color: Color(0x1AFFFFFF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                        color: Color(0x1AFFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                        color: Color(0xFF00E5FF), width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
          ),

          // ── Header "All Accounts" + badge ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Accounts',
                    style: AppTextStyles.titleLg.copyWith(
                      fontFamily: 'HankenGrotesk',
                      fontSize:   22,
                      fontWeight: FontWeight.w500,
                      color:      const Color(0xFFE5E2E1),
                    ),
                  ),
                  // Badge item count
                  Consumer<VaultProvider>(
                    builder: (context2, v, child) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _ItemBadge(
                        key: ValueKey(v.items.length),
                        count: v.items.length,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
          ),

          // ── Vault list ─────────────────────────────────────────────────
          Consumer<VaultProvider>(
            builder: (ctx, vault, _) {
              // Loading
              if (vault.isLoading) {
                return const SliverFillRemaining(
                  child: _LoadingState(),
                );
              }

              // Empty
              if (vault.filteredItems.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    isSearching: vault.searchQuery.isNotEmpty,
                    onAdd: _showAddSheet,
                  ).animate().fadeIn(delay: 200.ms),
                );
              }

              // List
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (listCtx, i) {
                      final item = vault.filteredItems[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: VaultItemCard(
                          key:              ValueKey(item.id),
                          item:             item,
                          animationIndex:   i,
                          isPasswordVisible: _visibleIds.contains(item.id),
                          onTogglePassword: () => _toggleVisibility(item.id),
                          onCopy:    () => vault.copyPassword(item.id, listCtx),
                          onDelete:  () => _showDeleteSheet(listCtx, item),
                          onEdit:    () => _showEditSheet(item),
                          onTap:     () => _showDetailSheet(listCtx, item),
                        ),
                      );
                    },
                    childCount: vault.filteredItems.length,
                  ),
                ),
              );
            },
          ),

          // Bottom padding untuk FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── FAB ────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: const Color(0xFF00363D),
        onPressed:       _showAddSheet,
        tooltip:         'Add credential',
        child:           const Icon(Icons.add_rounded, size: 36),
      )
          .animate()
          .fadeIn(delay: 600.ms)
          .scale(
            begin: const Offset(0.7, 0.7),
            delay: 600.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  // ── Detail sheet ──────────────────────────────────────────────────────────

  void _showDetailSheet(BuildContext ctx, VaultItem item) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(
        item:   item,
        onCopy: () => context.read<VaultProvider>().copyPassword(item.id, ctx),
      ),
    );
  }
}

// ── _ItemBadge ────────────────────────────────────────────────────────────────

class _ItemBadge extends StatelessWidget {
  const _ItemBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:        const Color(0xFF201F1F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Text(
        '$count Items',
        style: AppTextStyles.labelMd.copyWith(
          color:      const Color(0xFF00E5FF),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── _LoadingState ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color:       Color(0xFF00E5FF),
        strokeWidth: 2,
      ),
    );
  }
}

// ── _EmptyState ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearching, required this.onAdd});

  final bool         isSearching;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.shield_outlined,
              size:  80,
              color: const Color(0xFF849396),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No results found' : 'Your vault is empty',
              style: AppTextStyles.titleMd.copyWith(
                fontFamily: 'HankenGrotesk',
                fontSize:   20,
                color:      const Color(0xFFBAC9CC),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Tap + to add your first credential',
              style: AppTextStyles.bodyMd.copyWith(
                color: const Color(0xFF849396),
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onAdd,
                icon:  const Icon(Icons.add_rounded),
                label: Text('Add Credential',
                    style: AppTextStyles.buttonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF00363D),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── _MasterPasswordDialog ─────────────────────────────────────────────────────

class _MasterPasswordDialog extends StatefulWidget {
  const _MasterPasswordDialog({required this.controller});

  final TextEditingController controller;

  @override
  State<_MasterPasswordDialog> createState() => _MasterPasswordDialogState();
}

class _MasterPasswordDialogState extends State<_MasterPasswordDialog> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.kSurfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Unlock Vault', style: AppTextStyles.titleMd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Masukkan master password untuk memuat vault',
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: 16),
          TextField(
            controller:  widget.controller,
            obscureText: _obscure,
            autofocus:   true,
            style:       AppTextStyles.passwordText,
            cursorColor: AppColors.kPrimaryContainer,
            decoration: InputDecoration(
              hintText: 'Master password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: AppTextStyles.bodyMd),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kPrimaryContainer,
            foregroundColor: AppColors.kOnPrimary,
          ),
          onPressed: () =>
              Navigator.pop(context, widget.controller.text),
          child: Text('Unlock', style: AppTextStyles.buttonLabel),
        ),
      ],
    );
  }
}

// ── _DeleteSheet ──────────────────────────────────────────────────────────────

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.item, required this.onConfirm});

  final VaultItem    item;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
            const SizedBox(height: 24),
            Icon(
              Icons.delete_outline_rounded,
              size: 48,
              color: AppColors.kStrengthWeak,
            ),
            const SizedBox(height: 12),
            Text('Delete "${item.platformName}"?',
                style: AppTextStyles.titleMd, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Item ini akan dihapus secara permanen dari vault.',
              style: AppTextStyles.bodyMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.kOutline),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Text('Cancel', style: AppTextStyles.bodyLg),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kErrorContainer,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Text('Delete', style: AppTextStyles.buttonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _DetailSheet ──────────────────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.item, required this.onCopy});

  final VaultItem    item;
  final VoidCallback onCopy;

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _showPw = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize:     0.4,
      maxChildSize:     0.85,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: AppColors.kSurfaceContainer,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.kGlassBorder, width: 1),
          ),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.kOnSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Avatar + platform
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: item.iconColor.withValues(alpha: 0.25)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.iconInitials,
                    style: AppTextStyles.titleSm.copyWith(
                      color: item.iconColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.platformName, style: AppTextStyles.titleMd),
                      Text(item.username,     style: AppTextStyles.bodyMd),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Password row
            _DetailRow(
              label: 'PASSWORD',
              value: _showPw
                  ? (item.decryptedPassword ?? '••••••••')
                  : '••••••••••••',
              isPassword: true,
              isRevealed: _showPw,
              onToggle: () => setState(() => _showPw = !_showPw),
              onCopy:   widget.onCopy,
            ),
            const SizedBox(height: 10),

            // Username row
            _DetailRow(label: 'USERNAME', value: item.username),

            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DetailRow(label: 'NOTES', value: item.notes!),
            ],

            const SizedBox(height: 16),
            Text('Added ${item.formattedDate}',
                style: AppTextStyles.labelMd),
          ],
        ),
      ),
    );
  }
}

// ── _DetailRow ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isPassword = false,
    this.isRevealed = false,
    this.onToggle,
    this.onCopy,
  });

  final String       label;
  final String       value;
  final bool         isPassword;
  final bool         isRevealed;
  final VoidCallback? onToggle;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: const Color(0xFF00E5FF),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: isPassword
                      ? AppTextStyles.passwordText
                      : AppTextStyles.bodyLg,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isPassword && onToggle != null)
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                isRevealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.kOnSurfaceVariant,
              ),
            ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(
                Icons.copy_outlined,
                size: 18,
                color: Color(0xFF00E5FF),
              ),
            ),
        ],
      ),
    );
  }
}

// ── _AddEditSheet ─────────────────────────────────────────────────────────────

class _AddEditSheet extends StatefulWidget {
  const _AddEditSheet({
    required this.masterPassword,
    this.editItem,
  });

  final String     masterPassword;
  final VaultItem? editItem;

  @override
  State<_AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<_AddEditSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _platformCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();
  bool _obscure       = true;

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.editItem!;
      _platformCtrl.text = e.platformName;
      _usernameCtrl.text = e.username;
      _passwordCtrl.text = e.decryptedPassword ?? '';
      _notesCtrl.text    = e.notes ?? '';
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final vault = context.read<VaultProvider>();
    if (_isEdit) {
      final updated = widget.editItem!.copyWith(
        platformName:      _platformCtrl.text.trim(),
        username:          _usernameCtrl.text.trim(),
        decryptedPassword: _passwordCtrl.text,
        notes:             _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      );
      await vault.updateItem(updated, widget.masterPassword);
    } else {
      await vault.addItem(
        platformName:   _platformCtrl.text.trim(),
        username:       _usernameCtrl.text.trim(),
        plainPassword:  _passwordCtrl.text,
        notes:          _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        masterPassword: widget.masterPassword,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<VaultProvider, bool>((v) => v.isLoading);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.kSurfaceContainer,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border:
              Border(top: BorderSide(color: AppColors.kGlassBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.kOnSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _isEdit ? 'Edit Credential' : 'Add Credential',
                style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.kPrimaryContainer),
              ),
              const SizedBox(height: 20),

              // Platform
              TextFormField(
                controller: _platformCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyLg,
                cursorColor: AppColors.kPrimaryContainer,
                decoration: const InputDecoration(
                  labelText: 'Platform / Website',
                  prefixIcon: Icon(Icons.language_outlined, size: 20),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama platform wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Username
              TextFormField(
                controller: _usernameCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyLg,
                cursorColor: AppColors.kPrimaryContainer,
                decoration: const InputDecoration(
                  labelText: 'Username / Email',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Username wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.passwordText,
                cursorColor: AppColors.kPrimaryContainer,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.kOnSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                style: AppTextStyles.bodyMd,
                cursorColor: AppColors.kPrimaryContainer,
                decoration: const InputDecoration(
                  labelText: 'Notes (opsional)',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00363D)))
                      : Icon(_isEdit
                            ? Icons.save_rounded
                            : Icons.add_rounded),
                  label: Text(
                    _isEdit ? 'Save Changes' : 'Add to Vault',
                    style: AppTextStyles.buttonLabel,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF00363D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
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
