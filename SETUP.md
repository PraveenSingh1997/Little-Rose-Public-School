# Little Rose Public School — Dev Setup

## 1. Install Flutter

```bash
# macOS — via Homebrew (recommended)
brew install --cask flutter

# Verify
flutter doctor
```

Or download manually from https://docs.flutter.dev/get-started/install/macos

> **Required Flutter version:** 3.22+ (uses `flutter_bootstrap.js` for web)

---

## 2. Fill in Supabase Credentials

Open `lib/config/supabase_config.dart` and replace the placeholders:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

Get these from: https://app.supabase.com → your project → **Settings → API**

---

## 3. Install Dependencies

```bash
cd /Users/prem/Documents/Little-Rose-Public-School/Little-Rose-Public-School
flutter pub get
```

---

## 4. Run on Chrome (Web)

```bash
flutter run -d chrome
```

For a release/optimized web build:

```bash
flutter build web --release
# Output is in build/web/ — open build/web/index.html or serve with:
cd build/web && python3 -m http.server 8080
```

---

## 5. Run on Android

### Option A — Physical device
1. Enable **Developer Options** on the phone: Settings → About Phone → tap Build Number 7 times
2. Enable **USB Debugging** in Developer Options
3. Connect phone via USB and trust the computer when prompted
4. Run:
   ```bash
   flutter devices          # confirm device appears
   flutter run              # auto-selects Android device
   ```

### Option B — Android Emulator
1. Install Android Studio: https://developer.android.com/studio
2. Open Android Studio → **Virtual Device Manager** → create a device (Pixel 7, API 33+)
3. Start the emulator, then:
   ```bash
   flutter run
   ```

### Build a release APK (install without USB)
```bash
flutter build apk --release
# APK is at: build/app/outputs/flutter-apk/app-release.apk
# Transfer to phone and install (enable "Install unknown apps" in settings)
```

---

## 6. flutter doctor — common issues

| Issue | Fix |
|---|---|
| Android toolchain missing | Install Android Studio + SDK via `flutter doctor --android-licenses` |
| Chrome not found | Install Google Chrome |
| No devices | Connect device or start emulator |
| Gradle build failure | Run `flutter clean && flutter pub get` first |

---

## Project notes

- **App ID:** `com.littlerose.school`
- **Min Android SDK:** 21 (Android 5.0) — required by ML Kit OCR
- **OCR feature** (fee receipt scanning) works on Android only; it degrades gracefully on web
- **Supabase config** is gitignored — never commit real credentials
