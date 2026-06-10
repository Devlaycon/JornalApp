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

## Security Rules Direction

Initial Firestore rules should allow each authenticated user to read/write only their own private data:

```text
users/{uid}/...
```

Shared circle rules come later and must check membership before allowing reads or writes.

## Next Coding Slice

Start with a pure Swift schema contract:

```text
FirebaseCollectionSchema
FirebaseDataModel
```

Then add mapping:

```text
BackendSyncSnapshot -> [FirebaseDocumentPayload]
```

No network calls are needed for the first slice.
