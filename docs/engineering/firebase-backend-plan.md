# Firebase Backend Plan

Firebase is the primary backend direction for Circleu while the team does not have paid Apple Developer Program access for CloudKit.

CloudKit remains useful as an Apple-first reference, but Firebase is the practical implementation target because it supports iOS apps through Firebase Console and does not require Apple Developer Program membership for the database/auth backend.

## Backend Products

Use these Firebase products first:

- **Firebase Authentication**: account identity.
- **Cloud Firestore**: app data sync and backup.
- **Firebase Storage**: later, only if image/audio assets need cloud storage.
- **Firebase Analytics / Crashlytics**: later, after privacy-safe event rules are agreed.

Do not add Firebase AI, Cloud Functions, or push notifications until the core data model is stable.

## Local-First Rule

Firebase must not replace local mode.

Circleu should still allow:

- recording or typing a reflection offline,
- saving a local journal entry without sign-in,
- using local tips, profile progress, circles, and QA tools,
- reading existing local data if Firebase is unavailable.

Firebase sync should start as upload-only backup before two-way sync.

## Identity Direction

Current `AuthStore` is a local demo account/session system. It stores salted password hashes in `UserDefaults`.

For Firebase:

- use Firebase Authentication UID as the stable backend user ID,
- do not upload local password hashes,
- migrate local `AuthStore.currentAccount` only into safe profile fields such as display name and email,
- keep `LocalUserIdentityProvider.localUserID` for offline/local-only mode,
- keep sign-out behavior from deleting local data by accident.

## Firestore Collections

Use user-owned subcollections for private data:

```text
users/{uid}
users/{uid}/profile/main
users/{uid}/journalEntries/{entryID}
users/{uid}/aiReflectionSessions/{sessionID}
users/{uid}/quests/{questID}
users/{uid}/tipsPracticeSessions/{sessionID}
users/{uid}/rewardState/main
users/{uid}/pointEntries/{pointEntryID}
users/{uid}/activityEvents/{activityEventID}
```

Use top-level collections later for shared circle data:

```text
circles/{circleID}
circles/{circleID}/members/{memberID}
circles/{circleID}/posts/{postID}
circles/{circleID}/posts/{postID}/replies/{replyID}
```

Shared circles should not be enabled until membership rules and security rules are written.

## Documents

| Document | Path | Fields |
| --- | --- | --- |
| User | `users/{uid}` | `uid`, `email`, `displayName`, `createdAt`, `localUserID`, `updatedAt` |
| Profile | `users/{uid}/profile/main` | `displayName`, `promptIndex`, `updatedAt` |
| Journal Entry | `users/{uid}/journalEntries/{entryID}` | `entryID`, `createdAt`, `updatedAt`, `durationSeconds`, `transcript`, `engineName`, `sessionID`, `editableTitle`, `editableEmotion`, `privateNote`, `tags`, `result` |
| AI Reflection Session | `users/{uid}/aiReflectionSessions/{sessionID}` | `sessionID`, `createdAt`, `updatedAt`, `entryID`, `engineName`, `source`, `transcript`, `durationSeconds`, `selectedAttemptID`, `mergedSessionIDs`, `attempts` |
| Quest | `users/{uid}/quests/{questID}` | `questID`, `title`, `detail`, `sourceEntryID`, `createdAt`, `completedAt`, `status` |
| Tips Practice Session | `users/{uid}/tipsPracticeSessions/{sessionID}` | `sessionID`, `createdAt`, `updatedAt`, `originalMessage`, `scene`, `customScene`, `tone`, `situation`, `attachedImageCount`, `turns`, `coachOutput` |
| Reward State | `users/{uid}/rewardState/main` | `points`, `level`, `intoLevel`, `nextLevel`, `questAwards`, `updatedAt` |
| Point Entry | `users/{uid}/pointEntries/{pointEntryID}` | `pointEntryID`, `label`, `points`, `icon`, `createdAt` |
| Activity Event | `users/{uid}/activityEvents/{activityEventID}` | `activityEventID`, `type`, `title`, `keyword`, `refID`, `createdAt` |
| Circle | `circles/{circleID}` | `circleID`, `name`, `intention`, `emoji`, `members`, `createdAt`, `updatedAt` |
| Circle Member | `circles/{circleID}/members/{memberID}` | `memberID`, `circleID`, `uid`, `role`, `status`, `createdAt`, `updatedAt` |
| Circle Post | `circles/{circleID}/posts/{postID}` | `postID`, `circleID`, `uid`, `who`, `text`, `createdAt`, `updatedAt`, `likes`, `sourceEntryID` |
| Circle Reply | `circles/{circleID}/posts/{postID}/replies/{replyID}` | `replyID`, `postID`, `circleID`, `uid`, `who`, `text`, `createdAt`, `likes` |

## Sensitive Fields

Treat these as sensitive:

- `email`,
- `transcript`,
- `privateNote`,
- `tags`,
- `result`,
- `attempts`,
- `originalMessage`,
- `situation`,
- `turns`,
- `coachOutput`,
- `questAwards`,
- circle post `text`,
- circle reply `text`.

Do not send sensitive values to analytics.

## Setup Steps

1. Create a Firebase project in Firebase Console.
2. Register the iOS app with the app bundle ID.
3. Download `GoogleService-Info.plist`.
4. Add Firebase SDK with Swift Package Manager.
5. Add Firebase initialization in the app entry.
6. Add Firebase Auth service behind a protocol.
7. Add Firestore payload mapping tests.
8. Add upload-only backup sync.

Do not commit production Firebase credentials or service account keys. If the team commits `GoogleService-Info.plist`, use a development Firebase project and document that choice.

## Current Repo Setup

Current development Firebase project:

- Firebase project ID: `circleu-45651`
- iOS bundle ID: `com.Pingu.Circleu`
- Config file path: `Circleu/GoogleService-Info.plist`
- Swift Package products linked to the app target: `FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`
- Package lockfile path: `Circleu.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- App initialization: `FirebaseApp.configure()` in `Circleu/App/CircleuApp.swift`
- Auth boundary: `Circleu/Services/FirebaseAuthService.swift`
- Firestore private backup sync/restore boundary: `Circleu/Services/FirebaseFirestoreSyncService.swift`
- App backend session coordinator: `Circleu/Stores/BackendSessionStore.swift`
- Firestore rules: `firestore.rules`
- Firebase CLI config: `firebase.json`

This setup connects the SDK/config, adds a tested Firebase Auth service boundary, adds a tested Firestore private backup boundary for profile, journal, quest, tips practice, reward, point log, activity, and AI reflection session data, and wires onboarding through a backend session coordinator.

The app remains local-first. Onboarding still creates or reads the local `AuthStore` account first, then attempts Firebase Auth. If Firebase Auth fails during onboarding, the error is shown so the team can catch setup problems; existing local data remains readable and the backend error is retained on `BackendSessionStore`.

Firestore private backup restore is attempted once per signed-in Firebase UID before upload. Firestore private backup upload is then triggered from `RootView` on app entry and when private mapped data changes while a Firebase UID exists. Shared circles are intentionally not uploaded until membership and security rules are implemented. Profile > QA tools shows the current Firebase UID, sync status, uploaded document count, and last sync error for phone testing.

## Security Rules Direction

Initial Firestore rules should allow each authenticated user to read/write only their own private data:

```text
users/{uid}/...
```

Shared circle rules come later and must check membership before allowing reads or writes.

Current `firestore.rules` policy:

- authenticated users can read/write only `users/{theirFirebaseUID}` and its private subcollections,
- all `circles/{circleID}` documents and nested shared circle data are denied,
- every other document path is denied by default.

Deploy from the repo root after logging in with Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

After deploy, verify in Firebase Console:

1. Open Firestore Database > Rules and confirm the latest rules match `firestore.rules`.
2. Create/sign in from the app.
3. Save one reflection.
4. Confirm Firestore has `users/{uid}/journalEntries/{entryID}` for that signed-in UID.
5. Confirm there are no writes under `circles/`.
6. Reset local data or reinstall, sign in with the same account, and confirm private journal/reward/tips data restores from `users/{uid}`.

## Next Coding Slice

Start with a pure Swift schema contract:

```text
FirebaseCollectionSchema
FirebaseDataModel
```

Then add auth and mapping:

```text
FirebaseAuthService
BackendSyncSnapshot -> [FirebaseDocumentPayload]
FirebaseUploadOnlySyncer
```

Keep Firebase Auth behind `FirebaseAuthenticating` and Firestore behind a sync protocol so tests can run without real network calls.
