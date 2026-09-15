# CerTime

![Flutter](https://img.shields.io/badge/Flutter-2b2d31?style=flat-square&logo=flutter&logoColor=02569B) ![Dart](https://img.shields.io/badge/Dart-2b2d31?style=flat-square&logo=dart&logoColor=0175C2)<br/>
![SQLite](https://img.shields.io/badge/SQLite-2b2d31?style=flat-square&logo=sqlite&logoColor=07405E) ![Android](https://img.shields.io/badge/Android-2b2d31?style=flat-square&logo=android&logoColor=3DDC84)<br/>
![Linux](https://img.shields.io/badge/Linux-2b2d31?style=flat-square&logo=linux&logoColor=FCC624) ![Material Design 3](https://img.shields.io/badge/Material_Design_3-2b2d31?style=flat-square&logo=materialdesign&logoColor=757575)

Cross-platform training hours tracker and compliance tool built with Flutter, developed as a project for the _Progettazione Applicazioni Mobili_ university course.

---

## Overview

CerTime addresses the tracking of mandatory continuous training hours in regulated environments (healthcare, engineering, finance, workplace safety), replacing fragmented spreadsheets and manual logs with a centralized, offline-first application.

The application supports two roles:

- **Employee**: logs training/meeting events, tracks progress against monthly/annual targets, exports personal history as CSV.
- **Manager**: assigns courses to team members, monitors team-wide compliance, exports aggregated reports.

---

## Status

This is a **demo/prototype** built for academic evaluation. Notable characteristics:

- Fully offline, local-only persistence (SQLite via `sqflite` / `sqflite_common_ffi`).
- No real authentication: login is a simulated user selection (see `SessionService` and the in-app "DEMO" banner), there are no credentials or backend validation.
- No remote backend or API of any kind.
- The database is seeded with a fixed set of demo users, courses and events on first launch (`SeedService`), for demonstration purposes.

---

## Features

### Employee

- Circular progress indicators for monthly (8h) and annual (40h) training targets.
- Assigned course list with anti-anticipation lock (attendance can only be logged from the course's scheduled date onward) and overdue highlighting.
- Event logging with mandatory instructional summary for training entries, used as audit evidence.
- History view with filters (week / month / year / custom range), inline edit, delete with undo.
- CSV export via native share sheet.

### Manager

- Team compliance overview with annual hours and pending course count per employee.
- Course creation with scheduled date, estimated duration, and multi-user assignment.
- Per-employee history drill-down.
- Aggregated CSV export for the entire team.

### General

- Light / dark theme support.
- Configurable hour display format (decimal vs. hours-and-minutes).
- Interactive onboarding on first launch.

---

## Tech Stack

- **Framework**: Flutter / Dart
- **Local database**: `sqflite` (mobile), `sqflite_common_ffi` (Linux/desktop)
- **Design system**: Material Design 3
- **State/preferences**: `shared_preferences`
- **Export/sharing**: `share_plus`, `path_provider`
- **Formatting**: `intl`

---

## Project Structure

```text
CerTime/
├── cer_time/
│   ├── lib/
│   │   ├── database/      # SQLite helper, seed data, change notifier
│   │   ├── models/        # Data models (event, user, course, pending course)
│   │   ├── screens/       # UI screens (employee + manager flows)
│   │   ├── services/      # Session, settings, CSV export
│   │   └── utils/         # Formatting helpers
│   └── pubspec.yaml
└── README.md
```

---

## Getting Started

### Prerequisites

- Flutter SDK (3.12+ recommended)
- Dart SDK (bundled with Flutter)
- Android device/emulator, or a configured Linux desktop environment

### Run

```bash
git clone https://github.com/LeonardoCiscatoPajello/CerTime.git
cd CerTime/cer_time
flutter pub get
flutter run          # Android
flutter run -d linux # Linux desktop
```

---

## Releases

A prebuilt Android APK is available under the repository's [Releases](../../releases) section for direct installation without building from source.

---

## Known Limitations

- No real authentication or credential storage.
- No backend, no multi-device sync.
- Demo dataset is hardcoded and reset on `flutter clean` / fresh install.
- Not intended for production or handling of real personal/compliance data in its current state.

---

## Roadmap

This project was developed to meet the requirements of a university exam and is currently in a stable demo state. Further development, refinement, and feature completion may resume in the future, time permitting.

---

## License

All rights reserved. This repository is public for portfolio/demonstration
purposes only. No permission is granted to use, copy, modify, or distribute
this code without explicit written consent from the author.
