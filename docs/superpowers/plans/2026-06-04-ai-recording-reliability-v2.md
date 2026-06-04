# AI Recording Reliability v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve Circleu's real-phone AI recording loop with clearer permission state, transcript quality checks, analysis retry, and reflection regeneration.

**Architecture:** `VoiceRecorder` exposes permission state, `TranscriptQuality` centralizes readiness rules, `RecordingView` gates finish/analyze based on quality, and `ReflectionView` regenerates unsaved entries through `ReflectionAnalyzing`.

**Tech Stack:** SwiftUI, AVFoundation, Speech, local `ReflectionAnalyzing` engines, Xcode simulator and device builds.

---

### Task 1: Documentation Checkpoint

**Files:**
- Create: `docs/superpowers/specs/2026-06-04-ai-recording-reliability-v2-design.md`
- Create: `docs/superpowers/plans/2026-06-04-ai-recording-reliability-v2.md`

- [ ] Add the design and plan.
- [ ] Commit as `docs: plan ai recording reliability`.

### Task 2: Transcript Quality Rules

**Files:**
- Create: `Circleu/Engines/TranscriptQuality.swift`
- Modify: `Circleu/Features/Recording/RecordingView.swift`

- [ ] Add `TranscriptQuality.evaluate(_:)` with `isReady`, `wordCount`, and `guidance`.
- [ ] Use the quality result in `RecordingView.canFinish`.
- [ ] Show quality guidance in the transcript panel.
- [ ] Build simulator.
- [ ] Commit as `feat: add transcript quality checks`.

### Task 3: Permission Readiness UI

**Files:**
- Modify: `Circleu/Services/VoiceRecorder.swift`
- Modify: `Circleu/Features/Recording/RecordingView.swift`

- [ ] Add a `VoicePermissionState` enum for microphone and speech readiness.
- [ ] Update permission states during request and fallback paths.
- [ ] Show a compact permission readiness card in Recording.
- [ ] Build simulator.
- [ ] Commit as `feat: improve recording permission states`.

### Task 4: Reflection Regeneration

**Files:**
- Modify: `Circleu/Features/Reflection/ReflectionView.swift`
- Modify: `Circleu/Features/Recording/RecordingView.swift`

- [ ] Let `ReflectionView` keep a mutable unsaved draft entry.
- [ ] Add a regenerate action that reruns the reflection engine for the current transcript.
- [ ] Disable regenerate after save.
- [ ] Keep save behavior tied to the current draft entry.
- [ ] Build simulator.
- [ ] Commit as `feat: add reflection regeneration`.

### Task 5: QA Docs And Final Verification

**Files:**
- Modify: `docs/phone-test-checklist.md`
- Modify: `docs/release-readiness.md`

- [ ] Add phone QA checks for short transcript guidance, permission fallback, retry, and regenerate.
- [ ] Run placeholder scan.
- [ ] Run iPhone 17 Pro simulator build.
- [ ] Run connected iPhone build.
- [ ] Commit as `docs: update ai reliability qa`.
- [ ] Push `dev/mike`.
