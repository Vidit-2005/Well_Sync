# Well_Sync

**Team Q** — A mental health and wellness management iOS application connecting Doctors and Patients.

---

## Overview

Well_Sync is a native iOS application built with Swift and UIKit that bridges the gap between mental health professionals and their patients. Doctors can monitor patient wellbeing, assign therapeutic activities, and manage sessions, while patients can log moods, track health vitals, and maintain journals — all synced in real time via Supabase.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI Framework | UIKit (Storyboard-based) |
| Backend / Database | Supabase (PostgreSQL) |
| Health Integration | Apple HealthKit |
| Architecture | MVC (UIViewController / UICollectionViewController) |

---

## Features

### Doctor Side
- **Patient Dashboard** — View all assigned patients with current mood and session status
- **Patient Management** — Register and add new patients
- **Activity Assignment** — Create and assign therapeutic activities (timer or upload based)
- **Mood Analysis** — Calendar view and charts showing patient mood trends over time
- **Vitals Monitoring** — Review patient health metrics synced from HealthKit
- **Session Scheduling** — Calendar-based appointment management
- **Session Notes** — Create rich session notes with images and voice recordings
- **Doctor Profile** — Manage professional profile and credentials

### Patient Side
- **Dashboard** — Activity rings, upcoming sessions, and mood summary
- **Mood Logging** — Daily mood check-in with 5-level scale and feelings selection
- **Activity Tracking** — Complete assigned activities with timer or file upload
- **Health Vitals** — Apple HealthKit integration (heart rate, steps, SpO2, weight, height, calories burned)
- **Patient Notes** — Personal notes and observations
- **Journal** — Written and audio journal entries
- **Case History** — Timeline of medical history and reports
- **Session Viewer** — View upcoming and past therapy sessions

---

## Project Structure

```
Well Sync/
└── wellSync/
    ├── Login/                          # Authentication screens
    ├── Doctor Registration/            # Doctor sign-up flow
    ├── DoctorFrontPage/                # Doctor main dashboard
    ├── Doctor Profile/                 # Doctor profile management
    ├── Doctor Activity Status/         # Activity assignment and tracking
    ├── Doctor Mood Analysis/           # Patient mood charts and calendar
    ├── Doctor Vitals/                  # Patient vitals view
    ├── DoctorAddPatient/               # Add/register new patients
    ├── Patient DashBoard/              # Patient main dashboard
    ├── Patient Activity/               # Activity completion
    ├── Patient Menu/                   # Patient profile and settings
    ├── Patient Vitals/                 # HealthKit vitals display
    ├── Patient Notes/                  # Personal notes
    ├── Patient vital log/              # Vitals history log
    ├── Session Notes/                  # Session documentation
    ├── Journal/                        # Journal entries
    ├── CaseHistory/                    # Medical history timeline
    ├── PatientDetailDoctorProfile/     # Doctor's detailed patient view
    ├── Summarized Report/              # Summarized patient reports
    ├── Data Model/                     # Swift data structures
    ├── DataBAseConnection/             # Supabase manager and functions
    ├── Data/                           # Mock/seed data
    └── AccessHealthKit.swift           # HealthKit integration
```

---

## Data Models

| Model | Key Fields |
|---|---|
| `Doctor` | docID, name, email, qualification, registrationNumber, experience |
| `Patient` | patientID, docID, name, email, condition, nextSessionDate, mood |
| `SessionNote` | sessionId, patientId, date, title, notes, images, voice |
| `MoodLog` | logId, patientId, mood (1–5), date, moodNote, selectedFeeling |
| `Activity` | activityID, doctorID, name, type (timer/upload), description |
| `AssignedActivity` | assignedID, activityID, patientID, frequency, startDate, endDate |
| `ActivityLog` | logID, assignedID, patientID, date, duration, uploadPath |
| `JournalEntry` | title, summary, type (written/audio), journalImage, audioFile, date |

---

## Supabase Tables

- `doctor`
- `patients`
- `session_notes`
- `mood_logs`
- `activities`
- `activity_logs`

---

## Getting Started

### Prerequisites
- macOS with Xcode installed
- iOS device or simulator (iOS 26.0+)
- Supabase project credentials

### Build & Run
1. Open the Xcode project:
   ```bash
   open "Well Sync/wellSync.xcodeproj"
   ```
2. Select your target device or simulator in Xcode.
3. Press **⌘R** to build and run.

### Demo Login
| Role | Username |
|---|---|
| Doctor | `admin` |
| Patient | `admin1` |

> ⚠️ **Security Notice:** Password validation is currently bypassed for development purposes. This **must** be replaced with proper authentication before any production deployment.

---

## Permissions Required

The app requests the following iOS permissions:
- **HealthKit** — to read heart rate, steps, SpO2, weight, height, and calories
- **Microphone** — for audio journal recordings
- **Photo Library / Camera** — for session note and activity photo uploads

---

## Team

**Team Q**

Built as part of an academic / capstone project focused on digital mental health tooling.

