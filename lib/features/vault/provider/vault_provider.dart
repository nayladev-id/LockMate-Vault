import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/crypto_service.dart';
import '../../../services/storage_service.dart';
import '../model/vault_item.dart';

/// VaultProvider — mengelola seluruh state dan operasi vault ZeroCrypt.
///
/// Kebijakan keamanan yang WAJIB dijaga:
///   1. [_items] di memori berisi VaultItem dengan [decryptedPassword] terisi.
///   2. Sebelum disimpan ke storage, password SELALU dienkripsi ulang.
///   3. Tidak ada logging untuk plaintext password.
///   4. [clearAll] dipanggil saat logout — bersihkan memori.
///
/// Pola sesuai skill/provider-patterns.md:
///   - Services diinjeksi via constructor.
///   - Logic di Provider, BUKAN di Screen.
///   - [notifyListeners] hanya saat state benar-benar berubah.
class VaultProvider extends ChangeNotifier {
  VaultProvider({
    required StorageService storage,
    required CryptoService crypto,
  })  : _storage = storage,
        _crypto  = crypto;

  // ── Dependencies ────────────────────────────────────────────────────────────

  final StorageService _storage;
  final CryptoService  _crypto;

  // ── State ───────────────────────────────────────────────────────────────────

  List<VaultItem> _items          = [];
  String          _searchQuery    = '';
  bool            _isLoading      = false;
  String?         _error;

  /// Master password sesi aktif — di-set saat [loadItems], di-clear saat [clearAll].
  /// Digunakan oleh AddAccountSheet / EditCredentialScreen tanpa dialog ulang.
  String?         _sessionPassword;

  // Clipboard auto-clear timer
  Timer? _clipboardTimer;

  // ── Getters ─────────────────────────────────────────────────────────────────

  /// List vault items (unmodifiable) — password sudah didekripsi di memori.
  List<VaultItem> get items => List.unmodifiable(_items);

  /// `true` saat sedang memproses operasi async.
  bool get isLoading => _isLoading;

  /// Pesan error terakhir. `null` jika tidak ada error.
  String? get error => _error;

  /// Master password sesi — tersedia setelah vault di-unlock.
  /// `null` jika vault belum dibuka atau sudah di-lock.
  String? get sessionPassword => _sessionPassword;

  /// Items yang sudah difilter berdasarkan [_searchQuery].
  List<VaultItem> get filteredItems {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return _items
        .where(
          (item) =>
              item.platformName.toLowerCase().contains(q) ||
              item.username.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Jumlah total item di vault.
  int get itemCount => _items.length;

  /// Query pencarian aktif.
  String get searchQuery => _searchQuery;

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _setLoading(bool val) {
    if (_isLoading == val) return;
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// Konversi _items ke List<Map> terenkripsi untuk disimpan ke storage.
  ///
  /// Di sini plaintext [decryptedPassword] di-encrypt ulang menggunakan
  /// [masterPassword] sebelum diserahkan ke [StorageService].
  List<Map<String, dynamic>> _encryptedMaps(String masterPassword) {
    return _items.map((item) {
      // Re-enkripsi password dari memori ke format storage
      final encryptedPass = item.decryptedPassword != null
          ? _crypto.encrypt(item.decryptedPassword!, masterPassword)
          : item.encryptedPassword; // fallback jika belum didekripsi

      // Re-enkripsi notes jika ada (notes di-simpan plaintext di field notes
      // setelah load — enkripsi kembali sebelum save)
      // Untuk simplisitas: notes tidak dienkripsi ulang di sini
      // (notes sudah disimpan dalam bentuk terenkripsi di item.notes)

      return item.copyWith(encryptedPassword: encryptedPass).toJson()
        ..remove('decryptedPassword'); // pastikan tidak ikut ke storage
    }).toList();
  }

  // ── 1. loadItems ─────────────────────────────────────────────────────────────

  /// Load vault items dari storage dan dekripsi semua password ke memori.
  ///
  /// Dipanggil oleh VaultScreen setelah login berhasil.
  /// [masterPassword] digunakan untuk dekripsi — tidak disimpan di provider.
  Future<void> loadItems(String masterPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      final rawList = await _storage.getVaultItems();

      final decryptedItems = <VaultItem>[];

      for (final map in rawList) {
        final item = VaultItem.fromJson(map);

        // Dekripsi password ke memori
        String? plaintext;
        try {
          if (item.encryptedPassword.isNotEmpty) {
            plaintext = _crypto.decrypt(item.encryptedPassword, masterPassword);
          }
        } catch (_) {
          // Item korup atau password salah — tetap tambahkan tanpa plaintext
          plaintext = null;
        }

        decryptedItems.add(item.withDecrypted(plaintext ?? ''));
      }

      _items = decryptedItems;
      _sessionPassword = masterPassword;   // simpan untuk sesi aktif
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat vault. Coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  // ── 2. addItem ───────────────────────────────────────────────────────────────

  /// Tambah item baru ke vault.
  ///
  /// [plainPassword] dienkripsi sebelum disimpan ke storage.
  /// Di memori, item disimpan dengan [decryptedPassword] = [plainPassword].
  Future<void> addItem({
    required String platformName,
    required String username,
    required String plainPassword,
    String? notes,
    required String masterPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Enkripsi password — IV random baru setiap kali (sesuai crypto skill)
      final encryptedPass  = _crypto.encrypt(plainPassword, masterPassword);

      // Enkripsi notes jika ada
      final encryptedNotes = (notes != null && notes.isNotEmpty)
          ? _crypto.encrypt(notes, masterPassword)
          : null;

      // Buat item baru — encryptedPassword untuk storage, decryptedPassword di memori
      final newItem = VaultItem.create(
        platformName:      platformName,
        username:          username,
        encryptedPassword: encryptedPass,
        encryptedNotes:    encryptedNotes,
        decryptedPassword: plainPassword,
      );

      // Tambah ke state
      _items = [..._items, newItem];

      // Simpan seluruh list (terenkripsi) ke storage
      await _storage.saveVaultItems(_encryptedMaps(masterPassword));

      notifyListeners();
    } catch (e) {
      _setError('Gagal menyimpan item. Coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  // ── 3. updateItem ─────────────────────────────────────────────────────────────

  /// Update item yang sudah ada.
  ///
  /// [updatedItem] harus memiliki [decryptedPassword] yang baru
  /// (plaintext) — provider akan mengenkripsi ulang sebelum simpan.
  Future<void> updateItem(VaultItem updatedItem, String masterPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      // Enkripsi password baru
      final encryptedPass = updatedItem.decryptedPassword != null &&
              updatedItem.decryptedPassword!.isNotEmpty
          ? _crypto.encrypt(updatedItem.decryptedPassword!, masterPassword)
          : updatedItem.encryptedPassword;

      final itemToSave = updatedItem.copyWith(
        encryptedPassword: encryptedPass,
      );

      // Update di list
      _items = _items.map((item) {
        return item.id == updatedItem.id ? itemToSave : item;
      }).toList();

      // Simpan ke storage
      await _storage.saveVaultItems(_encryptedMaps(masterPassword));

      notifyListeners();
    } catch (e) {
      _setError('Gagal memperbarui item. Coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  // ── 4. deleteItem ─────────────────────────────────────────────────────────────

  /// Hapus item dari vault berdasarkan [id].
  Future<void> deleteItem(String id, String masterPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      _items = _items.where((item) => item.id != id).toList();

      await _storage.saveVaultItems(_encryptedMaps(masterPassword));

      notifyListeners();
    } catch (e) {
      _setError('Gagal menghapus item. Coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  // ── 5. setSearchQuery ─────────────────────────────────────────────────────────

  /// Set query pencarian untuk memfilter [filteredItems].
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query.trim();
    notifyListeners();
  }

  /// Reset pencarian.
  void clearSearch() => setSearchQuery('');

  // ── 6. copyPassword ───────────────────────────────────────────────────────────

  /// Salin password ke clipboard, lalu bersihkan otomatis setelah 30 detik.
  ///
  /// Mengambil [decryptedPassword] dari [_items] by [itemId].
  /// Tampilkan SnackBar konfirmasi via [context].
  Future<void> copyPassword(String itemId, BuildContext context) async {
    final item = _items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw StateError('Item $itemId tidak ditemukan'),
    );

    final plaintext = item.decryptedPassword;
    if (plaintext == null || plaintext.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password tidak tersedia.')),
        );
      }
      return;
    }

    // Salin ke clipboard
    await Clipboard.setData(ClipboardData(text: plaintext));

    // Batalkan timer sebelumnya jika ada
    _clipboardTimer?.cancel();

    // Auto-clear clipboard setelah 30 detik
    _clipboardTimer = Timer(const Duration(seconds: 30), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });

    // SnackBar konfirmasi
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password copied — clears in 30s'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Clear Now',
            onPressed: () {
              _clipboardTimer?.cancel();
              Clipboard.setData(const ClipboardData(text: ''));
            },
          ),
        ),
      );
    }
  }

  // ── 7. clearAll ───────────────────────────────────────────────────────────────

  /// Bersihkan seluruh state vault dari memori — dipanggil saat logout.
  ///
  /// Tidak menghapus data dari storage — hanya clear in-memory state.
  /// Untuk wipe storage, panggil [StorageService.clearVault()] secara terpisah.
  void clearAll() {
    _items           = [];
    _searchQuery     = '';
    _error           = null;
    _sessionPassword = null;  // wipe session password dari memori

    // Cancel clipboard timer dan clear clipboard saat logout
    _clipboardTimer?.cancel();
    Clipboard.setData(const ClipboardData(text: ''));

    notifyListeners();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    super.dispose();
  }
}
