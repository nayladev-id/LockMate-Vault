import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/vault/provider/vault_provider.dart';
import 'services/crypto_service.dart';
import 'services/secure_storage_service.dart';
import 'services/storage_service.dart';

/// Entry point ZeroCrypt.
///
/// Urutan inisialisasi (WAJIB dijaga):
///   1. [WidgetsFlutterBinding.ensureInitialized] — wajib sebelum kode async
///   2. [SharedPreferences.getInstance]           — warm-up sekali
///   3. Instansiasi services (tidak ada async di constructor)
///   4. [MultiProvider]                           — inject ke root widget tree
///   5. [ZeroCryptApp]                            — MaterialApp + routes
///
/// ATURAN MUTLAK:
///   - Tidak ada http / dio / network call di sini atau di seluruh app.
///   - Master password TIDAK boleh ada di variabel manapun di sini.
Future<void> main() async {
  // ── 1. Flutter binding ────────────────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ── 2. SharedPreferences warm-up ──────────────────────────────────────────
  await SharedPreferences.getInstance();

  // ── 3. Instansiasi services ────────────────────────────────────────────────
  // Services tidak menyimpan state — aman diinstansiasi di sini.
  final cryptoService        = CryptoService();
  final secureStorageService = SecureStorageService();
  final storageService       = StorageService();

  // ── 4. Bootstrap app dengan Provider ──────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        // ── AuthProvider — diisi Sesi 2 ─────────────────────────────────────
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            crypto: cryptoService,
            secureStorage: secureStorageService,
            storage: storageService,
          ),
        ),

        // ── VaultProvider — full impl Sesi 3 ────────────────────────────────
        ChangeNotifierProvider<VaultProvider>(
          create: (_) => VaultProvider(
            storage: storageService,
            crypto: cryptoService,
          ),
        ),
      ],
      child: const ZeroCryptApp(),
    ),
  );
}
