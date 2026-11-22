# Classmate

### Your timetable, attendance, and 85% plan — all in one place.

Classmate is an offline-first student planner for building a weekly routine, recording attendance, and seeing how each subject is tracking against an **85% attendance target**. Add subjects yourself or start from a timetable photo, then review the detected entries before applying them.

> **Private by default:** The web app saves timetable and attendance data in this browser on this device. There is no sign-in or automatic cloud sync.

---

## ✨ What you can do

| Feature | What it does |
| --- | --- |
| **Plan your week** | Set subjects against the app’s seven fixed daily class periods. |
| **Import a timetable photo** | Run OCR on a JPG or other image, review and edit the detected subject grid, then apply it to the weekly timetable. |
| **Track attendance live** | Mark classes present, absent, or cancelled; cancelled classes are excluded from totals. |
| **Forecast the 85% target** | See each subject’s attended/held count, current percentage, classes needed to reach 85%, or how many classes can be missed while staying at the target. |
| **Manage one-time classes** | Add extra classes to a date without changing your regular weekly schedule. |
| **Use the calendar and reminders** | Browse class dates, get in-app alerts, and celebrate full-attendance days. |
| **Move your data** | Export a backup and import it in another browser or on another device. |

The timetable photo reader uses Tesseract.js from a CDN, so **OCR needs an internet connection**. The rest of the web app is designed to work offline after its first load. OCR may misread a photo; check the editable preview before applying it.

## 🚀 Run the web app

From the project root, start a local web server:

```bash
python -m http.server 8000
```

Open [http://localhost:8000/app/index.html](http://localhost:8000/app/index.html). The root page at [http://localhost:8000/](http://localhost:8000/) also redirects to the app. After loading once, the service worker caches the app shell for offline use.

To install it, use your browser’s **Install app** or **Add to Home Screen** option. HTTPS hosting is also supported. Browser data is isolated by browser profile and device, so use backups to transfer it.

## 📚 Attendance rules

- The attendance target is **85% per subject**.
- A subject’s percentage is `present classes ÷ (present + absent classes) × 100`.
- Cancelled classes do not count toward attended or held totals.
- The timetable has seven fixed periods: 08:55–09:50, 09:50–10:45, 11:05–12:00, 12:00–13:00, 14:00–14:55, 14:55–15:50, and 15:50–16:45.
- Sundays and the 1st and 3rd Saturdays are recurring holidays for regular classes. Extra classes can still be added on those dates.
- Attendance reminders and notifications work while supported by the browser or app. Operating systems may suspend notifications when the app is closed, especially offline.

## 📱 Mobile app

The Flutter Android app hosts a bundled copy of the web app in a WebView. Its attendance and timetable data stay in that WebView’s on-device browser storage. Backup export uses the Android share sheet; import opens the device file picker.

### Build an Android APK

Install Flutter, then run:

```bash
cd mobile
flutter pub get
flutter build apk --release
```

The APK is created at `mobile/build/app/outputs/flutter-apk/app-release.apk`. The local release build uses Flutter’s debug signing setup for testing; publishing requires signing with your own key. See [mobile/README.md](mobile/README.md).

The repository includes iOS and macOS Flutter project scaffolding, but the documented mobile packaging flow is Android. For iPhone and iPad, use the web app in Safari and choose **Share → Add to Home Screen**. Check [GitHub Releases](https://github.com/Vish-nath/smart-attendance/releases) for published Android builds.

## 🧩 Project map

```text
app/index.html          Web app interface and application logic
app/manifest.webmanifest PWA install metadata
service-worker.js       Offline app-shell cache and notification clicks
assets/                 App icons
mobile/                 Flutter WebView wrapper and platform projects
backend/                Optional Flask + SQLite sync API
```

### Optional Flask backend

The web app’s default storage is local browser storage; it does not require the backend. The separate Flask service provides SQLite-backed timetable and attendance endpoints for API experiments and integrations.

```bash
cd backend
python -m venv .venv
```

Activate the environment, then install and start the service:

```bash
pip install -r requirements.txt
python app.py
```

The API listens on port `5000` by default. See [backend/README.md](backend/README.md) for device and emulator connection notes.

## 🔐 Data and privacy

- Timetable, attendance, and app preferences are stored locally in browser storage.
- The app does not upload attendance data as part of timetable-photo OCR; OCR runs in the browser using the external Tesseract.js library and language data.
- Backups are files that you choose to export and store or share.
- Voluntary bug reports use the configured Formspree form. The report includes the details you enter and an optional reply email, not your timetable or attendance records.

## 🛠️ Built with

Vanilla HTML, CSS, and JavaScript · Service Workers · Tesseract.js OCR · Flutter · Flask · SQLAlchemy · SQLite

---

Made for keeping classes—and attendance goals—on track. 🎓
