# TestFlight App Store Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create Duolingo-inspired, Circleu-branded TestFlight/App Store listing copy and screenshot frames using real app screenshots.

**Architecture:** Keep source screenshots in `docs/product/snapshots/` and generated App Store-ready frames in `docs/product/snapshots/app-store/`. Use a local HTML/CSS template rendered by headless Chrome so the design is repeatable without adding app runtime dependencies.

**Tech Stack:** Markdown docs, HTML/CSS screenshot template, headless Google Chrome, real iOS simulator screenshots.

---

### Task 1: Capture Missing Product Screens

**Files:**
- Create: `docs/product/snapshots/tips.png`
- Create: `docs/product/snapshots/circle.png`

- [ ] Launch Circleu in simulator with `SNAPSHOT_MODE=1` and `START_TAB=tips`.
- [ ] Capture `docs/product/snapshots/tips.png`.
- [ ] Launch Circleu in simulator with `SNAPSHOT_MODE=1` and `START_TAB=circle`.
- [ ] Capture `docs/product/snapshots/circle.png`.
- [ ] Verify both files are valid PNG screenshots.

### Task 2: Create App Store Screenshot Template

**Files:**
- Create: `docs/product/snapshots/app-store/index.html`
- Create: `docs/product/snapshots/app-store/README.md`
- Create: `docs/product/snapshots/app-store/*.png`

- [ ] Build a Duolingo-inspired but original Circleu visual system: colorful rounded panels, short bold headlines, real app screenshots, and Circleu blue/lavender/yellow accents.
- [ ] Render five 1290 x 2796 PNG cards:
  - `01-reflect-in-your-own-voice.png`
  - `02-turn-check-ins-into-insight.png`
  - `03-save-your-private-journal.png`
  - `04-practice-one-small-step.png`
  - `05-share-support-with-circles.png`
- [ ] Verify all generated files are valid PNGs.

### Task 3: Update Listing Copy And Links

**Files:**
- Modify: `docs/product/testflight-description.md`
- Modify: `docs/product/snapshots/README.md`
- Modify: `README.md`

- [ ] Rewrite the TestFlight/App Store copy into a Duolingo-like structure: hook, why Circleu, feature bullets, what to test, beta notes, and test account.
- [ ] Link App Store-ready screenshots from the root README.
- [ ] Link raw and framed screenshots from snapshot docs.

### Task 4: Verify

**Files:**
- Verify all changed docs and image files.

- [ ] Run `file docs/product/snapshots/*.png docs/product/snapshots/app-store/*.png`.
- [ ] Run `xcodebuild build -quiet -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /private/tmp/circleu-deriveddata-snapshots`.
- [ ] Check git status and report unrelated existing changes separately.
