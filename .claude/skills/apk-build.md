# Skill: APK Build & Release — Zcrypt

## Overview
Konfigurasi build release APK Flutter untuk Zcrypt dengan signing dan obfuscation.

## Build Commands
```bash
# Debug APK
flutter build apk --debug

# Release APK (recommended untuk distribusi)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Split per ABI (ukuran lebih kecil)
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
```

## android/app/build.gradle — Signing Config
```groovy
android {
    signingConfigs {
        release {
            keyAlias     keystoreProperties['keyAlias']
            keyPassword  keystoreProperties['keyPassword']
            storeFile    file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

## key.properties (jangan di-commit ke Git!)
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=zcrypt
storeFile=../zcrypt-release.keystore
```

## proguard-rules.pro
```
-keep class io.flutter.** { *; }
-keep class com.example.zcrypt.** { *; }
-dontwarn io.flutter.embedding.**
```

## .gitignore — Tambahkan ini
```
android/key.properties
*.keystore
*.jks
build/debug-info/
```

## Cara Generate Keystore (sekali saja)
```bash
keytool -genkey -v -keystore zcrypt-release.keystore -alias zcrypt -keyalg RSA -keysize 2048 -validity 10000
```

## DO
- Selalu obfuscate untuk release
- Simpan keystore di tempat aman (bukan repo)
- Test release APK di device nyata sebelum distribusi

## DON'T
- Jangan commit key.properties ke Git
- Jangan distribusi debug APK
