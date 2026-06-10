# CloudKit Data Model

CloudKit is the preferred Apple-first database layer for Circleu. The app remains local-first: local stores keep working without sign-in, network, or CloudKit availability.

This document is the guide for the next coding step. Update this doc before changing CloudKit schema constants, payload mapping, or real sync code.

## Database Ownership

Use the private CloudKit database first:

- `UserProfileRecord`: profile and preferences.
- `JournalEntryRecord`: reflection journal history.
- `AIReflectionSessionRecord`: AI reflection attempts and selected output.
- `QuestRecord`: quest/tip progress.
- `TipsPracticeSessionRecord`: communication practice history.
- `RewardStateRecord`: profile reward total and daily quest award state.
- `PointEntryRecord`: recent reward log entries.
- `ActivityEventRecord`: profile activity timeline.

Use the shared CloudKit database later:

- `CircleRecord`: circle metadata.
- `CircleMemberRecord`: membership, role, and invitation state.
- `CirclePostRecord`: posts inside a circle.
- `CirclePostReplyRecord`: replies inside a circle post.

Do not store private journal text in public records. Do not build public database records for the current beta.

## Record Types

| Record type | Scope | Fields |
| --- | --- | --- |
| `UserProfileRecord` | private | `localUserID`, `displayName`, `promptIndex`, `updatedAt` |
| `JournalEntryRecord` | private | `entryID`, `createdAt`, `updatedAt`, `durationSeconds`, `transcript`, `engineName`, `sessionID`, `editableTitle`, `editableEmotion`, `privateNote`, `tags`, `resultJSON` |
| `AIReflectionSessionRecord` | private | `sessionID`, `createdAt`, `updatedAt`, `entryID`, `engineName`, `source`, `transcript`, `durationSeconds`, `selectedAttemptID`, `mergedSessionIDs`, `attemptsJSON` |
| `QuestRecord` | private | `questID`, `title`, `detail`, `sourceEntryID`, `createdAt`, `completedAt`, `status` |
| `TipsPracticeSessionRecord` | private | `sessionID`, `createdAt`, `updatedAt`, `originalMessage`, `scene`, `customScene`, `tone`, `situation`, `attachedImageCount`, `turnsJSON`, `coachOutputJSON` |
| `RewardStateRecord` | private | `localUserID`, `points`, `level`, `intoLevel`, `nextLevel`, `questAwardsJSON`, `updatedAt` |
| `PointEntryRecord` | private | `pointEntryID`, `label`, `points`, `icon`, `createdAt` |
| `ActivityEventRecord` | private | `activityEventID`, `type`, `title`, `keyword`, `refID`, `createdAt` |
| `CircleRecord` | shared later | `circleID`, `name`, `intention`, `emoji`, `members`, `joined`, `createdAt`, `updatedAt` |
| `CircleMemberRecord` | shared later | `memberID`, `circleID`, `userID`, `role`, `status`, `createdAt`, `updatedAt` |
| `CirclePostRecord` | shared later | `postID`, `circleID`, `who`, `text`, `createdAt`, `updatedAt`, `likes`, `liked`, `sourceEntryID` |
| `CirclePostReplyRecord` | shared later | `replyID`, `postID`, `circleID`, `who`, `text`, `createdAt`, `likes`, `liked` |

## Current Model Alignment

Current local models changed after the demo UI work:

- `CircleSpace` now includes `emoji`, `members`, and `joined`.
- `CirclePost` now includes `who`, `text`, `likes`, `liked`, `replies`, and `sourceEntryID`.
- `PostReply` is a nested local reply model.
- `RewardsStore` owns `points`, `pointsLog`, `questAwards`, and `activity`.
- `PointEntry` and `ActivityEvent` are `Codable` reward/profile timeline models.

CloudKit code must reflect those current model names. Do not reintroduce the old `CirclePost.title` or `CirclePost.body` fields.

## Record IDs

Use deterministic CloudKit record names so upload-only backup can overwrite the same logical record:

- `profile_<localUserID>`
- `journal_<entryID>`
- `aiSession_<sessionID>`
- `quest_<questID>`
- `tipsPractice_<sessionID>`
- `rewardState_<localUserID>`
- `pointEntry_<pointEntryID>`
- `activityEvent_<activityEventID>`
- `circle_<circleID>`
- `circleMember_<memberID>`
- `circlePost_<postID>`
- `circlePostReply_<replyID>`

## Sync Phases

### Phase 1: Payload Mapping Only

Create pure Swift payload mapping:

```text
BackendSyncSnapshot -> [CloudKitRecordPayload]
```

No CloudKit entitlements, containers, network calls, or iCloud account checks yet.

This phase should map:

- journal entries,
- AI sessions,
- quests,
- tips practice sessions,
- circles,
- circle posts,
- circle post replies,
- rewards state,
- point entries,
- activity events.

### Phase 2: Upload-Only Private Backup

Upload private records only:

- profile,
- journal entries,
- AI sessions,
- quests,
- tips practice sessions,
- rewards state,
- point entries,
- activity events.

This must never delete local data when CloudKit is unavailable.

### Phase 3: Shared Circles

Add shared database records only after identity and membership rules are clear:

- circles,
- circle members,
- circle posts,
- circle post replies.

Until then, circles remain local demo/social-feed data.

### Phase 4: Two-Way Sync

Add download and merge only after conflict rules are defined.

## Conflict Rules To Define Later

Two-way sync must define rules for:

- edited journal title, emotion, note, and tags,
- deleted journal entries,
- quest status changes,
- merged AI sessions,
- reward point conflicts,
- daily quest award deduplication,
- activity timeline ordering,
- circle membership changes,
- circle post edits and deletes,
- circle reply edits and deletes,
- like count reconciliation.

## Privacy Rules

Sensitive fields include transcripts, journal content, private notes, tags, circle post text, circle reply text, practice messages, and AI attempts.

These fields may go to the user's private CloudKit database only after backend sync is intentionally enabled. Shared circle text may go to the shared database only after the user intentionally joins or creates shared circles.

Analytics must not include sensitive field values. External AI providers must not read directly from CloudKit.

## Code Contract

`Circleu/Services/CloudKitDataModel.swift` should mirror this schema with stable record types, scopes, field names, sensitive-field flags, and deterministic record-name prefixes.

Before coding:

1. Update this guide.
2. Update `CloudKitSchemaTests`.
3. Update `CloudKitDataModel.swift`.
4. Add payload mapping tests.
5. Implement payload mapping.

Do not add real CloudKit sync until payload mapping tests pass.
