# Classmate · Student Attendance

Classmate is a student-only, local-first timetable and attendance tracker. It has no sign-in, backend, teacher tools, or cloud sync. Timetable entries, attendance updates, reminders, and backups are stored in the browser on the device.

## Run and install

The app can be opened directly, but browsers restrict offline installation and system notifications for `file://` pages. For the installable offline app, serve this folder from the device:

1. Install Python if it is not already available.
2. From this folder, run `python -m http.server 8000`.
3. Open `http://localhost:8000/` (which redirects to the app) or `http://localhost:8000/app/index.html`.
4. Install Classmate from the browser menu. Android Chrome can add it to the home screen. On macOS, install it from a desktop browser that supports PWAs, or use Safari's **Add to Dock** on supported macOS versions.
5. After the first load, the service worker caches the app shell for offline use. The local server can be stopped after that.

The app also works from an HTTPS static host. It does not send attendance data to that host; data remains in the browser's local storage. Browser storage is isolated per browser/profile and device, so use **Export backup** and **Import backup** to move data between devices or profiles.

## Mobile downloads

Check [GitHub Releases](https://github.com/Vish-nath/smart-attendance/releases) for published mobile builds. Each release should include the version, supported platform, installation notes, and the matching download asset.

### Android

Download the Android `.apk` asset from the release and open it on your device to install. Android may ask you to allow your browser or file manager to install apps from that source. Only install APKs published from this repository's official Releases.

### iPhone and iPad

A native iOS app is not currently included in this project, so there is no iPhone/iPad build to download from GitHub Releases yet. iPhone and iPad users can use the web app in Safari and choose **Share → Add to Home Screen**. If a native iOS version is published later, its release notes will link to the supported distribution method, such as the App Store or TestFlight.

GitHub Releases are used for Android APK downloads. An iOS `.ipa` is not a generally installable equivalent: iOS apps must be signed and distributed through an Apple-supported method.

## Project Layout & Architecture

- `backend/`: Python Flask REST API server with SQLAlchemy and SQLite database.
- `mobile/`: Flutter cross-platform mobile application (Android APK, iOS, macOS) with Flask API integration and web fallback.
- `app/index.html`: Responsive PWA web app interface.
- `service-worker.js`: Offline caching configuration.

## 1. Flask Backend Setup

The Python Flask backend handles data persistence, timetable records, and attendance sync in a SQLite database (`classmate.db`).

1. Navigate to `backend/`:
   ```bash
   cd backend
   pip install -r requirements.txt
   python app.py
   ```
2. The server will start on `http://localhost:5000` (or `http://0.0.0.0:5000`).

## 2. Mobile App (Flutter)

The Flutter mobile application supports Android, iOS, and macOS, connecting directly to the Flask backend API with offline support.

### Building Android APK

```bash
cd mobile
flutter pub get
flutter build apk --release
```
The generated APK is located at `mobile/build/app/outputs/flutter-apk/app-release.apk`.

### Building iOS / macOS Mobile Build

On macOS with Xcode installed:

```bash
cd mobile
# For iOS:
flutter build ios --release
# Or generate iOS IPA package:
flutter build ipa --release

# For macOS Desktop:
flutter build macos --release
```


## Timetable and attendance

- Add only subject names; class times are fixed to the reference timetable:
  - 08:55–09:50, 09:50–10:45
  - Tea break 10:45–11:05
  - 11:05–12:00, 12:00–13:00
  - Lunch 13:00–14:00
  - 14:00–14:55, 14:55–15:50, 15:50–16:45
- Sundays and the 1st and 3rd Saturdays are recurring holidays. Regular timetable entries are skipped on those dates; extra classes may still be added.
- Mark classes present, absent, or cancelled. Cancelled classes do not contribute to the attended or held totals.
- Add an extra class by selecting a date, an available fixed period, and a subject name. Attendance totals and the 75% eligibility estimate update immediately after an attendance status is recorded.
- The calendar, alerts, subject calculations, and timetable work offline.

## Notifications and limitations

Allow notifications in **Alerts** to receive class-start and class-finish notifications with quick actions where the browser supports notification actions. The app checks class times while it is open or running in the background. Browsers and operating systems do not guarantee scheduled notifications when a fully offline app has been closed or suspended; open the app to see any pending in-app attendance reminders.

All dates and class times use the device's local time zone. The calendar applies the stated Sunday and 1st/3rd Saturday holiday rule throughout the year.
