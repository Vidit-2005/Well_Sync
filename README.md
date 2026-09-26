# Well Sync

Well Sync is an iOS healthcare companion application that helps patients and doctors stay connected through shared health information, vital tracking, activity monitoring, notes, and care coordination.

The project provides separate patient and doctor experiences in one app, with a focus on making everyday health management easier, more organized, and more collaborative.

## Features

### Patient experience

- Patient onboarding and authentication
- Patient dashboard with health and activity information
- Vital entry and vital history tracking
- Personal health journal and notes
- Doctor discovery and doctor profile viewing
- Patient–doctor communication and care-session notes
- Guided breathing and wellness activities
- Notifications for relevant patient updates

### Doctor experience

- Doctor registration and profile management
- Doctor dashboard and activity status
- Add and manage patients
- View patient profiles and health information
- Review patient vitals, activity, notes, and case history
- Add session notes and care updates
- Patient notification support

### Platform capabilities

- Reusable onboarding flow shown at app launch
- HealthKit integration for accessing supported health data
- Firebase integration for selected app services
- Supabase backend functions for server-side operations
- Apple Push Notification service (APNs) support
- Storyboard-based screens with UIKit view controllers
- Shared data models and database helpers

## Technology Stack

- **Platform:** iOS
- **Language:** Swift
- **UI:** UIKit and Storyboards
- **Health data:** HealthKit
- **Backend services:** Supabase and Firebase
- **Notifications:** Apple Push Notification service (APNs)
- **Project:** Xcode (`Well Sync/wellSync.xcodeproj`)

## Repository Structure

```text
Well_Sync/
├── Well Sync/
│   ├── wellSync.xcodeproj       # Xcode project
│   └── wellSync/                # iOS application source
│       ├── Login/               # Authentication screens
│       ├── Doctor*/             # Doctor registration, dashboard, profiles, and tools
│       ├── Patient*/            # Patient dashboard, vitals, notes, and activity
│       ├── CaseHistory/         # Patient case history
│       ├── Data Model/          # Shared application models
│       ├── Database/            # Database-related code
│       ├── Reusable Onboarding/ # App launch onboarding flow
│       ├── Journal/             # Patient journal functionality
│       ├── Session Notes/       # Session note screens and logic
│       ├── AccessHealthKit.swift
│       ├── AppDelegate.swift
│       └── SceneDelegate.swift
└── supabase/
    └── functions/
        ├── send-patient-push/   # Sends patient push notifications through APNs
        └── send-patient-welcome/ # Sends patient welcome notifications
```

## Requirements

- macOS with Xcode installed
- An Apple Developer account for signing, HealthKit, and push notifications
- An iOS simulator or physical iPhone
- Access to the project's Firebase and Supabase environments
- Appropriate APNs credentials when testing push notifications

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/Vidit-2005/Well_Sync.git
   cd Well_Sync
   ```

2. Open the Xcode project:

   ```bash
   open "Well Sync/wellSync.xcodeproj"
   ```

3. Select the `wellSync` target and configure your Apple Developer team and signing settings.

4. Confirm that the required app configuration files and service credentials are available for your development environment.

5. Select an iOS simulator or connected device and run the app from Xcode.

The app launch flow is wired through `SceneDelegate` and begins with the reusable onboarding experience.

## Backend and Notifications

The Supabase Edge Functions are located in `supabase/functions`.

Deploy the patient push notification function with:

```bash
supabase functions deploy send-patient-push --no-verify-jwt
```

The push function requires APNs secrets. Configure them in your Supabase project before deployment:

```bash
supabase secrets set APNS_KEY_ID=YOUR_KEY_ID
supabase secrets set APNS_TEAM_ID=YOUR_TEAM_ID
supabase secrets set APNS_BUNDLE_ID=com.your.bundleid
supabase secrets set APNS_PRIVATE_KEY="$(cat AuthKey_XXXXXX.p8)"
supabase secrets set APNS_USE_SANDBOX=true
```

Use `APNS_USE_SANDBOX=false` for production or TestFlight builds that use the production APNs environment. Keep private keys and service credentials out of source control.

The notification workflow uses the `device_push_tokens` table to associate active device tokens with patients and doctors. The complete schema and function-specific instructions are available in the README inside `supabase/functions/send-patient-push`.

## HealthKit Configuration

HealthKit access requires configuration in both Xcode and the Apple Developer portal:

1. Enable the HealthKit capability for the app target.
2. Configure the required HealthKit usage descriptions in the app's configuration.
3. Test with a physical iPhone where HealthKit is available.
4. Request only the permissions required by the features being used.

Users must explicitly grant permission before the app can read or write supported health data.

## Security and Privacy

Well Sync handles health-related information. When working on this project:

- Never commit API keys, private certificates, APNs keys, or production credentials.
- Use environment-specific configuration for development, testing, and production.
- Request the minimum permissions needed for HealthKit and notifications.
- Validate authorization and user roles on both the client and backend.
- Avoid logging sensitive patient or doctor information.
- Review database access policies before deploying backend changes.

## Project Status

Well Sync is an actively developed iOS application for patient and doctor care coordination. Features and backend requirements may change as development continues.

## Contributing

1. Create a feature branch from `main`.
2. Make focused changes and keep sensitive configuration out of commits.
3. Test the affected patient and doctor flows in Xcode.
4. Verify that backend and notification changes work in the intended environment.
5. Open a pull request with a clear description of the changes and testing performed.

## License

No license has been specified for this repository yet. Until a license is added, all rights are reserved by the repository owner.
