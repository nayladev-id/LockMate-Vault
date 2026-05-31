# Zcrypt — Claude Project Memory

## Tentang Project
Zcrypt adalah aplikasi Flutter untuk enkripsi data lokal.
**Zero cloud dependency** — semua data tersimpan di device.

## Tech Stack
- Flutter (Dart)
- State Management : Provider (ChangeNotifier)
- Local Storage    : SharedPreferences + FlutterSecureStorage
- Enkripsi         : AES-256-GCM via package `encrypt`
- Target           : Android APK

## Skills Tersedia
Baca file berikut sebelum menulis kode apapun:
- `.claude/skills/flutter-structure.md`  ? struktur folder & dependencies
- `.claude/skills/provider-patterns.md` ? cara pakai Provider
- `.claude/skills/local-storage.md`     ? SharedPreferences & SecureStorage
- `.claude/skills/crypto-security.md`  ? enkripsi & prinsip keamanan
- `.claude/skills/apk-build.md`         ? build & signing APK

## Aturan Utama
1. TIDAK BOLEH ada network call keluar
2. Semua data sensitif harus dienkripsi sebelum disimpan
3. Jangan pernah log plaintext atau key
4. Ikuti struktur folder di flutter-structure.md
