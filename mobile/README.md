# Classmate for Android

This Flutter Android app packages the existing Classmate web interface locally
in a WebView. The bundled app works offline, and timetable and attendance data
remain in the WebView's on-device browser storage. Backup export uses the
Android share sheet, and backup import opens the Android file picker.

## Build a release APK

From this directory, run:

```powershell
flutter pub get
flutter build apk --release
```

The APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. This local release build uses
Flutter's debug signing configuration so it can be installed for testing.
Publishing to Google Play requires signing with your own upload key.
