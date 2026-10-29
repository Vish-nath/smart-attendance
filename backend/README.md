# Classmate Flask Backend Service

This directory contains the Python Flask REST API backend for Classmate. It handles timetable management, attendance recording, extra classes, and backup import/export stored in a SQLite database (`classmate.db`).

## Features

- **RESTful Endpoints**:
  - `GET /api/health`: Health status check
  - `GET /api/sync`: Full state retrieval for local/remote sync
  - `POST /api/sync`: Bulk data import/sync
  - `GET /api/timetable` & `POST /api/timetable`: Fetch & update weekly timetable
  - `GET /api/attendance` & `POST /api/attendance`: Record & retrieve attendance entries
- **CORS Enabled**: Accepts cross-origin requests from web browsers and Flutter mobile/desktop apps.
- **SQLite Storage**: Zero-configuration local database setup using SQLAlchemy.

## Setup and Running

1. **Create and activate a Python virtual environment** (optional but recommended):
   ```bash
   python -m venv venv
   # On Windows:
   .\venv\Scripts\activate
   # On macOS/Linux:
   source venv/bin/activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Start the Flask server**:
   ```bash
   python app.py
   ```
   The backend runs by default at `http://localhost:5000` (or `http://0.0.0.0:5000`).

## Network Access for Mobile Devices

- **Android Emulator**: Access local Flask server at `http://10.0.2.2:5000`.
- **iOS Simulator / macOS**: Access local Flask server at `http://localhost:5000` or `http://127.0.0.1:5000`.
- **Physical Device (Android/iPhone)**: Connect your device to the same Wi-Fi network as your server, then use your computer's local IP address (e.g., `http://192.168.1.100:5000`).
