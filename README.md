# Birr Tracker (offline bank-SMS expense tracker)

## Setup
```
flutter create --org com.example --project-name birr_tracker --platforms android .
# then replace pubspec.yaml and lib/ with the files from this zip
flutter pub get
```

## AndroidManifest.xml
Open android/app/src/main/AndroidManifest.xml and add, inside <manifest> (above <application>):
```
<uses-permission android:name="android.permission.READ_SMS"/>
```
Do NOT add INTERNET. Release builds then have no network access at all, so the app is offline by design.

## Small APK
In android/app/build.gradle(.kts) release block enable:
  minifyEnabled true  /  shrinkResources true   (Kotlin DSL: isMinifyEnabled = true, isShrinkResources = true)

Build:
```
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```
Install the arm64-v8a APK for most modern phones (build/app/outputs/flutter-apk/).

## Notes
- First tap on Sync: allow SMS permission, then tick your bank senders (CBE, Awash, Dashen, 127 for telebirr, etc.).
- Sync is safe to repeat; duplicates are ignored.
- READ_SMS is restricted on Google Play, so distribute by direct APK. Android only (iOS cannot read SMS).
- Parser is in lib/parser.dart: keywords for credit/debit and amount/balance regexes. Add words there if a bank uses different wording.
