# Tips Live Coach Simulator Design

## Goal

Refine the Tips tab into a communication-practice simulator based on the Figma prototype. Tips should no longer feel like a shortcut to recording a reflection. It should be its own workflow where the user practices what they want to say, chooses the social context and tone, and receives live AI-style coaching feedback.

The core flow is:

```text
Tips tab -> New Tip setup -> Live Coach simulation -> feedback and reply practice
```

## Product Direction

Tips becomes a place to rehearse real-life conversations. The user can describe a message, add context, choose the scene, set the desired tone, and continue into a chat-style coaching simulation. Circleu acts as a live coach: it suggests phrasing, explains why the phrasing works, simulates the other person replying, and gives better next-response options.

The first version stays local-first. It can use deterministic local coaching logic now and later swap in Apple Intelligence or another model provider.

## Reference Design

Use the earlier Figma/prototype direction from:

```text
/Users/tuanm.nguyen/Downloads/高保真iOS表单设计/
```

Relevant prototype screens:

- `DescribeScreen.tsx`: New Tip setup form.
- `LiveCoachScreen.tsx`: chat-style coach simulation.

Visual cues to carry over:

- Light blue screen background.
- Centered penguin/mascot near the top.
- iOS-style top bar with the title `New Tip` on setup and `Live coach` in the simulation.
- Step label such as `STEP 01 · DESCRIBE`.
- Rounded white message/context cards with light blue borders.
- Scene chips.
- Tone slider.
- Sticky Continue button on setup.
- Chat bubbles and coach cards on simulation.

Adapt the visual system to Circleu's existing `PinguDesign` and `PinguFont` tokens instead of introducing a separate design system.

## User Flow

### Screen 1: New Tip Setup

The Tips tab opens to a setup screen when no simulation is active.

Required sections:

1. **Header**
   - Top title: `New Tip`
   - Penguin image/mascot
   - Step label: `STEP 01 · DESCRIBE`
   - Main headline: `What do you want to say?`
   - Supporting copy: `Tell us the message in your own words.`

2. **Your Message**
   - Multiline text input.
   - Character count, target limit 240 characters.
   - Small mic icon inside the card for voice input.
   - Small image icon inside the card for chat screenshot input.
   - No big `Record` button.

3. **Choose a Scene**
   - Chips for:
     - Workplace
     - Family
     - Friendship
     - Romantic
   - `Add specific` chip can open a lightweight sheet for a custom scene.

4. **Desired Tone**
   - Slider or segmented scale from Soft to Direct to Firm.
   - Current label appears on the right, for example `Diplomatic`.

5. **Situation**
   - Optional multiline text input.
   - Used to give the coach more context.

6. **Continue**
   - Sticky bottom button.
   - Disabled until the message has meaningful text.

### Screen 2: Live Coach Simulation

After Continue, the Tips tab switches into a chat-style simulation.

Required sections:

1. **Top Bar**
   - Back button returns to setup with the current draft preserved.
   - Title: `Live coach`
   - Subtitle/chip: `Practice in real time`

2. **Context Chips**
   - Selected scene.
   - Selected tone.
   - Optional `edit` action returns to setup.

3. **Conversation Thread**
   - User bubble: original message.
   - Coach card: suggested phrasing.
   - Coach explanation: `Why this works`.
   - Action chips: `Copy`, `Try softer`, `More direct`, or `Add context`.
   - Simulated response from the other person.
   - Coach feedback: reading the room.
   - Reply options with labels such as `BOUNDARY`, `TRADE-OFF`, and `REDIRECT`.

4. **Composer**
   - Bottom input where the user can paste/type the other person's reply.
   - Mic icon for voice input.
   - Image icon or plus menu for chat screenshot input.
   - Send arrow.

5. **Next Feedback**
   - When the user submits a reply/context update, append a new coaching response locally.
   - The first version can generate deterministic feedback based on scene, tone, and keywords.

## Input Modes

### Type

Typing is the default and always available. The text field is the source of truth. Voice and image input should fill or append to the same editable text.

### Voice

Voice input is a small mic action, not a full-screen recording workflow.

First implementation should support real inline voice recording where the device allows it:

- Tapping the mic starts listening from inside the setup card or composer.
- Tapping again stops listening.
- Speech recognition appends the transcript into the editable text field.
- If microphone or speech recognition is unavailable, the text field remains available and the UI shows a short inline helper.

This can reuse `VoiceRecorder` if the implementation stays small. If `VoiceRecorder` is too coupled to the full-screen reflection flow, create a smaller speech-only service for the Tips workflow.

### Chat Image

Image input lets the user attach a chat screenshot.

First implementation should support selecting a local image, showing a small preview, and keeping the message field editable. If OCR is not available yet, the user can type or edit the message manually after attaching the screenshot.

Later implementation can add Vision OCR or Apple Intelligence extraction.

## Local Coach Engine

Add a simple local engine for this workflow:

```text
CommunicationCoachEngine
```

Responsibilities:

- Generate suggested phrasing from:
  - message
  - scene
  - desired tone
  - optional situation
- Generate `why this works`.
- Generate a simulated reply from the other person.
- Generate 2-3 next reply options.
- Keep copy concise and app-ready.

The first implementation can be deterministic and rule-based. It does not need network calls or backend state.

Example local behavior:

- Workplace + Firm: emphasize boundaries, capacity, and a next step.
- Family + Soft: emphasize warmth, reassurance, and clarity.
- Friendship: emphasize honesty and mutual care.
- Romantic: emphasize emotional clarity and direct kindness.

## Models

Add a small domain model for practice sessions:

```swift
struct TipsPracticeSession: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var updatedAt: Date
    var originalMessage: String
    var scene: TipsPracticeScene
    var customScene: String?
    var tone: TipsPracticeTone
    var situation: String
    var turns: [TipsPracticeTurn]
}
```

Supporting models:

```swift
enum TipsPracticeScene: String, Codable, CaseIterable {
    case workplace
    case family
    case friendship
    case romantic
    case custom
}

enum TipsPracticeTone: String, Codable, CaseIterable {
    case soft
    case diplomatic
    case firm
}

struct TipsPracticeTurn: Identifiable, Codable, Equatable {
    let id: UUID
    var role: TipsPracticeRole
    var label: String
    var text: String
    var createdAt: Date
}

enum TipsPracticeRole: String, Codable {
    case user
    case coach
    case simulatedPerson
}
```

Use existing `Quest` data for reflection-derived tips later. This simulator should not depend on active quests to work.

## Store

Add a small store for this workflow:

```text
TipsPracticeStore
```

Initial responsibilities:

- Hold current draft.
- Hold current active session.
- Persist recent sessions in `UserDefaults`.
- Reset current session.
- Preserve the draft when the user moves between setup and live coach.
- Keep practice state separate from `QuestStore`.

## View Structure

Keep feature-first organization:

```text
Circleu/Features/Tips/
  TipsView.swift
  TipsSetupView.swift
  TipsLiveCoachView.swift
  TipsPracticeComponents.swift
```

Add:

```text
Circleu/Features/Tips/TipsPracticeViewModel.swift
```

For this feature, a ViewModel is useful because the screen has real state transitions: draft input, scene selection, tone, image state, voice recording/transcription state, generated coach output, and conversation turns.

## Relationship To Existing Tips/Quest System

The current Tips tab shows active/completed/skipped `Quest` items from reflections. That is still useful, but it should no longer be the primary first screen.

Recommended first version:

- Make the simulator the primary Tips experience.
- Move quest history into a compact lower section or a secondary sheet called `Reflection tips`.
- Remove the `Record` / `Create from reflection` CTA from the main Tips path.
- Keep completed/skipped quest data intact.

This respects the old data while making the tab match the Figma direction.

## Error Handling

- Empty message: Continue disabled and helper text says `Add the message you want to practice.`
- Voice unavailable: show inline helper and keep typing available.
- Image selected but no OCR: show preview and helper text `Image attached. Add or edit the message above.`
- Coach generation failure: use local fallback copy and let the user continue.

## Testing Plan

Verification should include:

- Xcode build for iPhone 17 Pro simulator.
- Manual setup flow:
  - Type a message.
  - Select scene.
  - Adjust tone.
  - Add optional situation.
  - Continue to Live Coach.
- Manual simulation flow:
  - Confirm suggested phrasing appears.
  - Confirm `Why this works` appears.
  - Submit a reply/context update.
  - Confirm a new coach response appears.
- Regression check:
  - Existing quest data still appears somewhere or remains preserved in `QuestStore`.
  - No `Record` button appears as the primary Tips action.

## Success Criteria

- Tips tab clearly reads as a speaking-practice simulator.
- User can choose type, voice, or chat-image input.
- The first screen visually resembles the Figma New Tip setup.
- The second screen resembles the Figma Live Coach conversation.
- No backend is required.
- Existing reflection quest data is not deleted.
- App builds and runs on iPhone 17 Pro simulator.

## Non-Goals

- Do not implement backend login or sync.
- Do not require real OCR in the first pass.
- Do not use the reflection recording screen as the Tips voice interaction.
- Do not remove `QuestStore` or historical reflection tips.
- Do not redesign unrelated tabs.
