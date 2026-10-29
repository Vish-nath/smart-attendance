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

## Project layout and platform support

- `app/index.html` contains the app interface and behavior.
- `app/manifest.webmanifest` configures the installed app.
- `assets/icon.svg` contains the app icon.
- `service-worker.js` configures offline caching.
- `index.html` preserves the simple site-root entry point by redirecting to the app.

This repository provides one responsive, installable web app (PWA), not separate native Android or macOS projects. Install availability and notification behavior depend on the browser and operating-system version.

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
