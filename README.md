# Smart Attendance & Shortage Predictor

**A mini-project prototype for tracking attendance, spotting shortage risk early, and keeping students up to date on schedule changes.**

## Overview

The project brings attendance monitoring and academic notifications together in one student-facing dashboard. It is designed to reduce manual roll calls, make attendance status easier to follow, and help students act before falling below exam eligibility requirements.

## What It Covers

- Automated attendance logging with optional ESP32 or simulated sensor inputs
- Attendance percentage tracking and shortage-risk alerts
- Live timetable, class rescheduling, and exam schedule updates
- Notifications for missed classes and other academic events

> Example: At 74% attendance with a 75% eligibility threshold, the system can warn that attendance is needed in the next three classes.

## Proposed Prototype Stack

| Layer | Options in the project concept |
| --- | --- |
| Interface | HTML, CSS, and JavaScript; or Flutter/React |
| Backend | Python with Flask; Node.js is also considered in the architecture |
| Data | SQLite or Firebase |
| Prediction | XGBoost and LSTM for exploring attendance-risk prediction |
| Attendance input | ESP32 or software-emulated sensor input |

The PDF describes a prototype concept; these technologies are proposed options, not a claim that every component is already implemented.
