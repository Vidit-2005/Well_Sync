# Well Sync

**Team Q** — A telemedicine and patient health management iOS application that connects doctors and patients in a comprehensive digital health ecosystem.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Features](#features)
  - [Authentication & Onboarding](#authentication--onboarding)
  - [Patient Features](#patient-features)
  - [Doctor Features](#doctor-features)
  - [Shared Features](#shared-features)
- [Data Models](#data-models)
- [Database & Backend](#database--backend)
- [Project Structure](#project-structure)

---

## Overview

Well Sync is an iOS application built to bridge the gap between patients and their healthcare providers. It enables real-time health monitoring, therapeutic activity tracking, mood analytics, appointment scheduling, and clinical documentation — all within a single platform.

The app supports two user roles:
- **Patients** — track their own health vitals, complete doctor-assigned activities, log moods, and communicate through session notes.
- **Doctors** — monitor patient progress, assign therapeutic activities, analyze vitals and mood trends, manage appointments, and maintain clinical records.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Platform | iOS 14+ (UIKit) |
| Backend & Auth | Supabase (PostgreSQL + Supabase Auth) |
| File Storage | Supabase Storage |
| Health Data | Apple HealthKit |
| Notifications/Analytics | Firebase |
| Language | Swift |

---

## Architecture

The app uses an **MVC** architecture with a role-based navigation flow:

```
AppDelegate  (Firebase init)
     │
SceneDelegate  (session check → role-based routing)
     ├── Doctor Flow
     │     ├── Doctor Dashboard (Home)
     │     ├── All Patients
     │     ├── Appointments
     │     ├── Activity Status & Assignment
     │     ├── Mood Analysis
     │     ├── Doctor Vitals View
     │     ├── Case History
     │     ├── Session Notes
     │     └── Doctor Profile
     └── Patient Flow
           ├── Patient Dashboard
           ├── Patient Activity
           ├── Patient Vitals
           ├── Journal
           ├── Mood Logging
           └── Patient Profile & Settings
```

**Session State** is managed by `SessionManager` (singleton backed by `UserDefaults`), which persists the logged-in user's role and ID across launches.

**Database access** is centralized in `AccessSupabase` (`Supabase.swift`), a single class that handles all CRUD operations against Supabase tables and storage buckets.

---

## Features

### Authentication & Onboarding

- **Login** (`/Login`): Email/password sign-in via Supabase Auth. After authentication the app resolves the user's role (doctor or patient) and routes to the appropriate dashboard.
- **Doctor Registration** (`/Doctor Registration`): Multi-step form collecting basic details (name, DOB, address, experience) and education/credential details (qualifications, registration number, identity documents with image uploads).
- **Onboarding Screen** (`/onboardingScreen`): First-launch walkthrough for new users.

---

### Patient Features

#### Patient Dashboard (`/Patient DashBoard`)
The main hub for patients. Displays:
- Today's assigned therapeutic activities with circular progress rings
- Mood tracking streak counter
- Next scheduled session date
- Mood log summary
- Quick navigation to journal, vitals, and activity logs

#### Patient Activity (`/Patient Activity`)
- Lists all activities assigned by the doctor, split into **Today** (active) and **Logs** (historical) sections
- Two activity types:
  - **Timer Activities** — Breathing exercises, meditation, walking (timed countdown)
  - **Upload Activities** — Photo or audio submissions
- Marks activities complete and syncs logs to the database

#### Timer Activity Screen (`/Timer Activity Screen`)
- Countdown timer for timed activities
- Audio/visual feedback on completion
- Logs duration and completion timestamp to Supabase

#### Patient Vitals (`/Patient Vitals`)
- Displays health metrics as bar charts:
  - **Sleep data** (synced from Apple HealthKit + manual entries): duration, sleep stages (Deep, REM, Core, Awake)
  - **Step count** (synced from Apple HealthKit)
  - Custom vitals added by the treating doctor
- Date range filtering

#### Journal (`/Journal`)
- Chronological view of all completed activity entries and mood logs
- Tap entries to preview images or play audio from completed activities

#### Mood Logging
- Patients log their daily mood (Very Sad → Very Happy) with associated feelings tags
- Mood logs are stored and surfaced to both the patient (journal) and doctor (mood analysis dashboard)

#### Patient Notes (`/Patient Notes`)
- Displays clinical notes written by the doctor for the patient to read

#### Patient Profile & Settings (`/Patient Menu`)
- View and edit profile information
- App preferences and logout

---

### Doctor Features

#### Doctor Dashboard (`/DoctorFrontPage`)
- Main doctor hub showing all assigned patients categorized by health status (active, at risk, healthy)
- Search and filter patients
- Quick navigation to appointments, profile, and settings

#### Patient Detail View (`/PatientDetailDoctorProfile`)
- Full patient profile visible to the doctor
- Navigate to patient's vitals, mood analysis, activity status, case history, and session notes from one place

#### Doctor Activity Status (`/Doctor Activity Status`)
- Track completion rates per activity and per patient
- Time-series graphs of activity engagement
- View photo/audio submissions from patients
- **Add Activity** sub-module: Create therapeutic activities, define type (timer/upload), frequency, date range, and assign them to specific patients with instructions

#### Doctor Mood Analysis (`/Doctor Mood Analysis`)
- Calendar view of patient mood entries
- Mood distribution charts (pie and bar)
- Mood trend analysis over time
- Mood level legend: Very Sad (0) → Very Happy (4)
- Associated feelings breakdown (e.g., "anxious", "excited")

#### Doctor Vitals (`/Doctor Vitals`)
- Doctor's view of a patient's vitals (sleep analytics, step count trends)
- Compare vitals across time periods
- Identify trends and flag abnormal readings

#### Appointments (`/DoctorFrontPage/Appointment`)
- Schedule appointments with patients
- View appointment history
- Mark appointments as complete or missed
- Clears next session date on the patient record after completion

#### Session Notes (`/Session Notes` & `/Add Session Notes`)
- Doctors create rich session notes during or after appointments
- Support for **text**, **images** (camera/gallery), and **audio recordings**
- Files are uploaded to Supabase Storage
- Patients can view notes from their side

#### Case History (`/CaseHistory`)
- Full patient medical history with a timeline of diagnoses, treatments, and milestones
- Upload and manage medical report documents
- **PDF generation and export** from `PDFGenerator.swift`
- Document preview via `QLPreviewController`

#### Doctor Profile (`/Doctor Profile`)
- Displays doctor's qualifications, credentials, contact info, and patient statistics

#### Patient Notes (Doctor Side)
- Doctors write clinical notes linked to specific patients, visible to patients in their app

---

### Shared Features

#### HealthKit Integration (`AccessHealthKit.swift`)
- Requests authorization for HealthKit data (steps and sleep)
- Reads **step count** samples from Apple Health
- Reads **sleep analysis** samples (stages: Deep, REM, Core, Awake) from Apple Health
- Syncs data to Supabase on launch

#### Firebase (`/firebase`)
- Configured via `GoogleService-Info.plist` for analytics and messaging

---

## Data Models

### Users

| Model | Key Fields |
|---|---|
| `Doctor` | `docID`, `authID`, `name`, `email`, `dob`, `experience`, `qualification`, `registrationNumber`, `contact`, `doctorImage` |
| `Patient` | `patientID`, `docID`, `authID`, `name`, `email`, `dob`, `condition`, `gender`, `nextSessionDate`, `sessionStatus`, `imageURL` |

### Activities

| Model | Key Fields |
|---|---|
| `Activity` | `activityID`, `doctorID`, `name`, `iconName`, `type` (timer/upload) |
| `AssignedActivity` | `assignedID`, `activityID`, `patientID`, `doctorID`, `frequency`, `startDate`, `endDate`, `status` |
| `ActivityLog` | `logID`, `assignedID`, `patientID`, `completedAt`, `duration`, `mediaPath` |

### Health & Mood

| Model | Key Fields |
|---|---|
| `sleepVital` | `id`, `patient_id`, `start_time`, `end_time`, `duration_minutes`, `quality` |
| `StepsVital` | `id`, `patient_id`, `log_date`, `step_count` |
| `MoodLog` | `moodID`, `patientID`, `moodLevel` (0–4), `date`, `note`, `feelings: [Feeling]` |
| `Feeling` | `feelingID`, `label` |

### Clinical

| Model | Key Fields |
|---|---|
| `Appointment` | `appointmentID`, `patientID`, `doctorID`, `date`, `status` |
| `SessionNote` | `noteID`, `patientID`, `doctorID`, `title`, `date`, `text`, `imagePaths`, `audioPaths` |
| `CaseHistory` | `caseID`, `patientID`, `timeline: [Timeline]`, `reports: [Report]` |
| `PatientNote` | `noteID`, `patientID`, `doctorID`, `content`, `date` |

---

## Database & Backend

All backend communication is handled through two main classes:

### `AccessSupabase` (`Supabase.swift`)
Central CRUD layer. Major operation groups:

| Group | Methods |
|---|---|
| Doctor | `saveDoctor`, `fetchDoctor`, `fetchDoctorByAuthID`, `fetchAllDoctors` |
| Patient | `savePatient`, `fetchPatient`, `fetchPatients(doctorID:)`, `updatePatient`, `fetchPatientByAuthID` |
| Activities | `saveActivity`, `fetchActivities`, `assignActivity`, `fetchAssignments` |
| Activity Logs | `saveActivityLog`, `fetchLogs`, `fetchLogsForAssignment` |
| Mood | `saveMoodLog`, `fetchMoodLogs`, `fetchFeelings` |
| Vitals | `saveSleepLogs`, `fetchSleepLogs`, `saveStepsLogs`, `fetchStepsLogs` |
| Appointments | `createAppointment`, `updateAppointment`, `deleteAppointment`, `fetchAppointments`, `updateAppointmentStatus` |
| Case History | `saveCaseHistory`, `saveTimeline`, `saveReport`, `fetchCaseHistories` |
| Session Notes | `saveSessionNote`, `fetchSessionNotes` |
| Patient Notes | `savePatientNote`, `fetchPatientNotes` |
| Storage | `getPublicImageURL`, `getSignedImageURL`, `downloadImage`, `uploadActivityImage` |

### `SupabaseManager` (`SupabaseService.swift`)
Authentication wrapper:
- `signUp`, `signIn`, `signOut`
- `getCurrentAuthUserID` — returns UUID of logged-in user
- `resolveRole` — checks doctors/patients tables to determine user role
- `uploadImage`, `uploadAudio` — upload media to Supabase Storage
- `publicURL` — generate accessible URLs for stored media

### `SessionManager` (`SessionManager.swift`)
Local session state (singleton):
- Persists `currentRole` (doctor/patient/none), `persistedDoctorID`, `persistedPatientID` to `UserDefaults`
- Provides in-memory `currentDoctor` and `currentPatient` objects
- `clearSession()` on logout

---

## Project Structure

```
Well Sync/
└── wellSync/
    ├── AppDelegate.swift              # App entry, Firebase init
    ├── SceneDelegate.swift            # Session check, role-based routing
    ├── AccessHealthKit.swift          # HealthKit steps & sleep sync
    ├── Login/                         # Login screen
    ├── onboardingScreen/              # First-launch onboarding
    ├── Doctor Registration/           # Multi-step doctor sign-up
    ├── DoctorFrontPage/               # Doctor dashboard, patients, appointments
    ├── Doctor Profile/                # Doctor profile view
    ├── Doctor Activity Status/        # Activity tracking & assignment
    ├── Doctor Mood Analysis/          # Patient mood analytics
    ├── Doctor Vitals/                 # Patient vitals (doctor view)
    ├── DoctorAddPatient/              # Add new patient flow
    ├── PatientDetailDoctorProfile/    # Patient detail (doctor view)
    ├── Patient DashBoard/             # Patient main dashboard
    ├── Patient Activity/              # Activity list & completion
    ├── Timer Activity Screen/         # Countdown timer for activities
    ├── Patient Vitals/                # Vitals (patient view)
    ├── Patient vital log/             # Vitals logging
    ├── Journal/                       # Chronological activity/mood journal
    ├── Add Session Notes/             # Create session notes (doctor)
    ├── Session Notes/                 # View session notes
    ├── Patient Notes/                 # Clinical notes (patient view)
    ├── Summarised Report/             # Report summaries
    ├── CaseHistory/                   # Medical case history & PDF export
    ├── Patient Menu/                  # Patient profile & settings
    ├── Database/                      # Supabase CRUD, auth, session manager
    ├── Data/                          # UI data-building helpers
    ├── Data Model/                    # Swift data models (structs/enums)
    └── firebase/                      # Firebase configuration
```
