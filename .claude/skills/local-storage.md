# Skill: Local Storage — Zcrypt

## Overview
Zcrypt ZERO cloud. Semua data disimpan di device menggunakan:
- SharedPreferences  ? data non-sensitif (settings, metadata)
- FlutterSecureStorage ? data sensitif (master key, token lokal)

## StorageService Wrapper
```dart
// services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const _keyItems = 'zcrypt_items';

  Future<List<VaultItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyItems);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => VaultItem.fromJson(e)).toList();
  }

  Future<void> saveItem(VaultItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems();
    items.add(item);
    await prefs.setString(_keyItems, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

## SecureStorageService (untuk master key)
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveMasterKey(String key) async =>
      await _storage.write(key: 'master_key', value: key);

  Future<String?> getMasterKey() async =>
      await _storage.read(key: 'master_key');

  Future<void> deleteMasterKey() async =>
      await _storage.delete(key: 'master_key');
}
```

## DO
- Selalu enkripsi sebelum simpan ke SharedPreferences
- Gunakan SecureStorage untuk semua key/credential

## DON'T
- Jangan simpan plaintext password ke SharedPreferences
- Jangan simpan data sensitif di cache folder
