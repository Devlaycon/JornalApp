# AI Session And Reflection Workspace Design

## Goal

Make Circleu's AI loop testable, editable, and ready for future backend providers without adding a backend yet.

The app should let a phone tester record or type a reflection, inspect the AI session that produced the result, regenerate the result, edit the saved reflection workspace, and export enough detail to compare Apple Intelligence, the local engine, and future cloud models.

## Scope

This design combines three product steps:

1. AI Lab and evaluation tooling.
2. Editable Journal and Reflection detail workspace.
3. Backend prep through clean provider interfaces.

The implementation should stay local-first. No account system, cloud database, or server API is required for this phase.

## User Outcomes

A tester can:

- see which AI engine generated a reflection,
- see the original transcript, latest transcript, output, confidence, timing, and errors,
- regenerate a reflection and compare attempts,
- save the best version,
- edit saved reflection fields later,
- export an AI/session report for team review,
- keep using the app offline on a real iPhone.

A future developer can:

- plug in OpenAI, Claude, or a backend model provider behind the same analysis contract,
- sync sessions later without rewriting the UI,
- inspect model behavior from local stored data.

## Product Flow

### Recording To Reflection

1. User records or types a transcript.
2. `ReflectionEngine` creates an `AIReflectionResult`.
3. The app also creates an `AIReflectionSession` that records metadata about the attempt.
4. Reflection screen shows the result and a compact session summary.
5. User can regenerate before saving.
6. Saving stores the chosen reflection result and its session history.

### Journal Workspace

1. User opens a saved reflection from Journal.
2. Detail view shows AI result, transcript, private note, tags, related quest, and session history.
3. User can edit title, emotion/tag, transcript note, private note, and quest wording.
4. Sharing to circles uses the latest saved workspace state.
5. Export includes edited fields plus original AI session metadata.

### AI Lab

AI Lab should live under **Profile > QA tools** first. This keeps it available for real phone testing while avoiding a permanent product tab.

AI Lab shows:

- recent AI sessions,
- engine name,
- created time,
- transcript word count,
- confidence score,
- success or failure state,
- regeneration count,
- export/copy controls.

Selecting a session opens a detail sheet with the prompt source, transcript, generated fields, errors, elapsed duration, and saved reflection link when available.

## Data Model Changes

### `AIReflectionSession`

New model in `Circleu/Models`.

Fields:

- `id: UUID`
- `createdAt: Date`
- `updatedAt: Date`
- `entryID: UUID?`
- `engineName: String`
- `source: AIReflectionSource`
- `transcript: String`
- `durationSeconds: Int`
- `attempts: [AIReflectionAttempt]`
- `selectedAttemptID: UUID?`

### `AIReflectionAttempt`

Fields:

- `id: UUID`
- `createdAt: Date`
- `engineName: String`
- `status: AIReflectionAttemptStatus`
- `result: AIReflectionResult?`
- `errorMessage: String?`
- `elapsedMilliseconds: Int?`

### `AIReflectionSource`

Cases:

- `recording`
- `typedFallback`
- `journalRegeneration`
- `qaSeed`

### `AIReflectionAttemptStatus`

Cases:

- `succeeded`
- `failed`
- `cancelled`

### `JournalReflectionEntry`

Extend the existing model with editable workspace fields:

- `sessionID: UUID?`
- `editableTitle: String?`
- `editableEmotion: String?`
- `privateNote: String`
- `tags: [String]`
- `lastEditedAt: Date?`

Computed display values should prefer editable fields and fall back to the AI result.

## Store Changes

### `AIReflectionSessionStore`

New store in `Circleu/Stores`.

Responsibilities:

- persist AI sessions locally,
- append new attempts,
- link a session to a saved journal entry,
- update the selected attempt,
- export session summaries for QA,
- seed deterministic demo sessions for QA tools.

Storage should follow existing local persistence patterns used by the current stores.

### `ReflectionJournalStore`

Add update methods:

- update editable fields,
- attach session IDs,
- replace the AI result when the user chooses a regenerated attempt,
- preserve original transcript and timestamps.

Do not make Journal responsible for AI attempt history. Journal stores user-facing reflection entries; `AIReflectionSessionStore` stores model evaluation history.

## Engine And Provider Boundaries

Keep the existing `ReflectionAnalyzing` protocol for direct analysis.

Add a wrapper layer for session tracking:

`ReflectionSessionRunner`

Responsibilities:

- receive transcript, duration, source, and engine,
- time the analysis,
- capture success or failure into an `AIReflectionAttempt`,
- return both the attempt and session metadata.

Future backend providers should conform to the same reflection analysis contract. Backend prep should add protocols and model boundaries, not live network calls.

Suggested future-facing protocols:

- `ReflectionModelProvider`
- `ReflectionSyncing`
- `UserIdentityProviding`
- `AnalyticsTracking`

For this phase, provide local no-op implementations where needed.

## UI Changes

### Recording View

Add session creation through `ReflectionSessionRunner`.

The existing recording UI should keep:

- permission readiness,
- transcript quality checks,
- typed fallback,
- analysis retry.

When analysis completes, pass both the entry draft and the session to `ReflectionView`.

### Reflection View

Show:

- current AI cards,
- engine name,
- attempt count,
- regenerate action,
- latest error or success message,
- save action.

Regenerate should create a new attempt in the same session. The selected attempt should become the displayed result unless it fails.

### Journal Detail

Refine the detail screen into a workspace with sections:

- reflection summary,
- editable fields,
- transcript,
- private note,
- suggested quest,
- AI session history,
- share/export actions.

Editing should feel lightweight: inline fields or a single edit sheet, not a complex settings form.

### Profile QA Tools

Add an **AI Lab** entry point.

AI Lab actions:

- inspect recent sessions,
- copy latest session report,
- export all AI QA data,
- clear AI session data when local data is reset.

## Error Handling

- If AI analysis fails, keep the transcript and create a failed attempt.
- If regeneration fails, keep the previous selected result.
- If session persistence fails, still allow the user to save the reflection, then show a local warning.
- If a future provider is unavailable, show the engine availability message and use the local engine when configured.

## Testing And QA

Simulator build:

- app compiles on iPhone 17 Pro simulator.

Phone manual tests:

1. Record or type a reflection.
2. Confirm AI session metadata appears.
3. Regenerate and confirm attempt count increases.
4. Save the reflection.
5. Open Journal detail and edit workspace fields.
6. Confirm Home, Profile, Circles, and Journal use edited display values.
7. Open AI Lab and export the session.
8. Reset local data and confirm sessions reset with the rest of local state.

Code checks:

- no placeholder UI states for the new workflow,
- no backend calls,
- no cloud secrets or API keys,
- session history is separate from Journal entry editing.

## Commit Strategy

Use small functional commits:

1. Add AI session models and store.
2. Add session runner around reflection analysis.
3. Connect Recording and Reflection regeneration to sessions.
4. Add AI Lab to QA tools.
5. Add editable Journal workspace fields and store updates.
6. Update circle sharing and exports to use edited values.
7. Add backend-prep protocols with local no-op implementations.
8. Update docs and phone QA checklist.

## Out Of Scope

- User login and signup backend.
- Cloud sync.
- Real OpenAI, Claude, or server model calls.
- Team sharing between devices.
- Production analytics.

These are intentionally deferred until the local AI workflow is testable and stable on a real phone.
