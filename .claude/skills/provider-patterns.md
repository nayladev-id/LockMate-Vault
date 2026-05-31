# Skill: Provider Patterns — Zcrypt

## Overview
State management Zcrypt menggunakan Provider (ChangeNotifier).

## Struktur Provider Standar
```dart
// features/vault/provider/vault_provider.dart
import 'package:flutter/foundation.dart';
import '../model/vault_item.dart';
import '../../../services/storage_service.dart';
import '../../../services/crypto_service.dart';

class VaultProvider extends ChangeNotifier {
  final StorageService _storage;
  final CryptoService _crypto;

  VaultProvider(this._storage, this._crypto);

  List<VaultItem> _items = [];
  List<VaultItem> get items => List.unmodifiable(_items);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    _items = await _storage.getItems();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(VaultItem item) async {
    await _storage.saveItem(item);
    _items.add(item);
    notifyListeners();
  }
}
```

## Setup Root Provider (main.dart)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  final crypto  = CryptoService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VaultProvider(storage, crypto)),
        ChangeNotifierProvider(create: (_) => AuthProvider(storage, crypto)),
      ],
      child: const ZcryptApp(),
    ),
  );
}
```

## Cara Consume di Widget
```dart
// Read + listen
final vault = context.watch<VaultProvider>();

// Read only (tidak rebuild)
final vault = context.read<VaultProvider>();

// Select (rebuild hanya kalau field ini berubah)
final isLoading = context.select<VaultProvider, bool>((v) => v.isLoading);
```

## DO
- Satu Provider per feature
- Inject service via constructor, bukan langsung instansiasi

## DON'T
- Jangan panggil notifyListeners() berlebihan
- Jangan akses context di dalam Provider
