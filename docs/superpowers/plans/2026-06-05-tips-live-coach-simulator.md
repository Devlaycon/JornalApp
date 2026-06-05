# Tips Live Coach Simulator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the primary Tips tab with a local-first Live Coach speaking-practice simulator based on the approved Figma direction.

**Architecture:** Add Tips practice models, a local `CommunicationCoachEngine`, a persisted `TipsPracticeStore`, and a focused `TipsPracticeViewModel`. Keep existing reflection `QuestStore` data intact by moving quest history into a compact secondary section instead of using it as the primary Tips experience.

**Tech Stack:** SwiftUI, PhotosUI for chat screenshot attachment, Speech/AVFoundation for inline voice transcription, UserDefaults persistence, existing `PinguDesign`/`PinguFont`, Xcode iOS Simulator build verification.

---

## Task 1: Domain And Engine

**Files:**
- Create: `Circleu/Models/TipsPracticeModels.swift`
- Create: `Circleu/Engines/CommunicationCoachEngine.swift`

- [ ] Add `TipsPracticeScene`, `TipsPracticeTone`, `TipsPracticeRole`, `TipsPracticeTurn`, `TipsCoachReplyOption`, `TipsCoachOutput`, and `TipsPracticeSession`.
- [ ] Add `CommunicationCoachEngine` with deterministic local methods:
  - `startSession(message:scene:customScene:tone:situation:) -> TipsPracticeSession`
  - `continueSession(_ session:withReply:extraContext:) -> TipsPracticeSession`
- [ ] Ensure output includes suggested phrasing, why it works, simulated reply, room-reading feedback, and three reply options.

## Task 2: Store And Inline Speech

**Files:**
- Create: `Circleu/Stores/TipsPracticeStore.swift`
- Create: `Circleu/Services/TipsSpeechRecognizer.swift`
- Modify: `Circleu/App/ContentView.swift`
- Modify: `Circleu/App/RootView.swift`

- [ ] Add `TipsPracticeStore` with current draft/session and recent session persistence in `UserDefaults`.
- [ ] Add `TipsSpeechRecognizer` for inline mic transcription with safe fallback to typed input.
- [ ] Inject `TipsPracticeStore` from `ContentView`.
- [ ] Remove Tips' `onStartRecording` dependency from `RootView` and pass only journal-entry opening.

## Task 3: ViewModel And UI

**Files:**
- Create: `Circleu/Features/Tips/TipsPracticeViewModel.swift`
- Replace: `Circleu/Features/Tips/TipsView.swift`
- Create: `Circleu/Features/Tips/TipsSetupView.swift`
- Create: `Circleu/Features/Tips/TipsLiveCoachView.swift`
- Create: `Circleu/Features/Tips/TipsPracticeComponents.swift`

- [ ] Add `TipsPracticeViewModel` to coordinate draft message, scene, tone, situation, image attachments, inline voice state, current session, and coach actions.
- [ ] Implement `TipsSetupView` with:
  - New Tip header, penguin image, step label, headline.
  - message card with type field, mic icon, image picker, preview, and character count.
  - scene chips and custom-scene sheet.
  - tone slider.
  - optional situation field.
  - sticky Continue button.
- [ ] Implement `TipsLiveCoachView` with:
  - context chips.
  - user bubble.
  - coach suggested phrasing card.
  - simulated reply.
  - coach feedback with three reply options.
  - composer with type, mic, image, and send.
- [ ] Preserve quest history in a compact `Reflection tips` section.
- [ ] Remove the big `Record` / `Create from reflection` CTA from Tips.

## Task 4: Verification And Commit

**Files:**
- Verify all files touched above.

- [ ] Run:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected:

```text
** BUILD SUCCEEDED **
```

- [ ] Inspect git diff and confirm only Tips simulator files, store/model/engine/service additions, and environment injection changed.
- [ ] Commit:

```bash
git add Circleu docs/superpowers/plans/2026-06-05-tips-live-coach-simulator.md
git commit -m "feat: add tips live coach simulator"
```
