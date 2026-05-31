# Skill: Crypto & Security — Zcrypt

## Overview
Zcrypt menggunakan enkripsi lokal AES-256-GCM.
Zero network call. Semua enkripsi/dekripsi terjadi di device.

## CryptoService
```dart
// services/crypto_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class CryptoService {
  /// Derive key dari master password menggunakan SHA-256
  Key deriveKey(String masterPassword) {
    final bytes = utf8.encode(masterPassword);
    final digest = sha256.convert(bytes);
    return Key(Uint8List.fromList(digest.bytes));
  }

  /// Enkripsi plaintext ? returns "iv:ciphertext" (base64)
  String encrypt(String plaintext, String masterPassword) {
    final key = deriveKey(masterPassword);
    final iv  = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Dekripsi "iv:ciphertext" ? plaintext
  String decrypt(String payload, String masterPassword) {
    final parts = payload.split(':');
    if (parts.length != 2) throw Exception('Invalid payload format');
    final key = deriveKey(masterPassword);
    final iv  = IV.fromBase64(parts[0]);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt64(parts[1], iv: iv);
  }
}
```

## Prinsip Keamanan Zcrypt
1. Master password TIDAK pernah disimpan — hanya derived key-nya
2. Setiap item dienkripsi secara individual
3. IV selalu random baru tiap enkripsi
4. Tidak ada logging untuk data sensitif

## DO
- Selalu gunakan IV random baru setiap encrypt()
- Hapus sensitive variable dari memori setelah digunakan
- Validasi input sebelum enkripsi

## DON'T
- Jangan log plaintext, key, atau IV
- Jangan gunakan ECB mode
- Jangan hardcode IV atau key
- Jangan kirim apapun ke network
