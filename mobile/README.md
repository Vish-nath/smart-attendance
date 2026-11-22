# Classmate Mobile

The Flutter app packages the Classmate web experience locally in a WebView.
Timetables and attendance stay in local WebView storage; backup export and
import use the platform share sheet and file picker. The Android build targets
Android 6.0 (API 23) and later. Flutter's macOS runner is available for desktop
builds when compiled on macOS with Xcode.

## Build a release APK

From this directory, run:

```powershell
flutter pub get
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. The
current local release configuration uses debug signing for installable test
builds. Sign with a private upload key before publishing to Google Play.

## macOS desktop build

On macOS with Xcode installed:

```sh
flutter pub get
flutter build macos --release
```
