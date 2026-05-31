# Skill: Flutter Structure — Zcrypt

## Overview
Zcrypt adalah aplikasi Flutter offline-first (zero cloud dependency).
Semua data disimpan lokal. Tidak ada network call ke server eksternal.

## Struktur Folder Wajib
```
lib/
+-- main.dart
+-- app/
¦   +-- app.dart               # MaterialApp + ChangeNotifierProvider root
+-- core/
¦   +-- constants/             # AppColors, AppStrings, AppSizes
¦   +-- utils/                 # helper functions
¦   +-- widgets/               # shared widgets
+-- features/
¦   +-- [feature_name]/
¦       +-- model/
¦       +-- provider/          # ChangeNotifier class
¦       +-- screen/
¦       +-- widget/
+-- services/
    +-- storage_service.dart   # SharedPreferences wrapper
    +-- crypto_service.dart    # enkripsi/dekripsi
```

## Konvensi Penamaan
- File     : snake_case.dart
- Class    : PascalCase
- Variable : camelCase
- Konstanta: kNamaKonstanta

## pubspec.yaml — Dependencies Utama
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  shared_preferences: ^2.3.2
  flutter_secure_storage: ^9.2.2
  encrypt: ^5.0.3
  crypto: ^3.0.3
  pointycastle: ^3.9.1
  local_auth: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

## DO
- Selalu pisahkan logic di Provider, bukan di Screen
- Gunakan `const` constructor sebanyak mungkin
- Extract widget jika sudah > 50 baris

## DON'T
- Jangan taruh business logic di widget build()
- Jangan hardcode string — pakai AppStrings
- Jangan pernah kirim data ke internet
