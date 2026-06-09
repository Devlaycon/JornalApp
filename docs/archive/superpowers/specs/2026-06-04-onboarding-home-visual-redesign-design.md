# Onboarding And Home Visual Redesign Design

## Goal

Make Circleu feel more beautiful, premium, and emotionally polished from the first launch through the Home screen, while preserving the working recording and AI reflection flow.

This batch focuses on:

- Onboarding
- Home
- Shared top bar
- Bottom navigation
- Shared card and button polish where those components affect the above screens

## Scope

In scope:

- More immersive onboarding composition.
- Better onboarding name capture and privacy/local AI expectation.
- A more composed Home screen with a stronger hero/mascot moment.
- Beautiful daily prompt and latest reflection surfaces.
- Top bar and bottom navigation visual polish.
- Replacing fake navigation stats with local data-driven values.
- Consistent spacing, typography, color use, and shadows.

Out of scope:

- Recording and Reflection behavior changes.
- Journal/Profile screen redesign, except where shared navigation naturally affects them.
- Backend, login, signup, cloud sync, and cloud AI providers.
- Large asset redesign beyond using existing app assets and system symbols.

## Visual Direction

Circleu should feel calm, friendly, and emotionally warm without becoming a marketing page. The UI should feel like a real iPhone app, not a static Figma export.

Design qualities:

- Soft, airy, high-trust.
- Clear hierarchy with fewer competing text blocks.
- Premium but playful use of the Pingu palette.
- Smooth rounded surfaces, but no nested card-on-card clutter.
- Icons used for actions where they communicate better than text.
- Content should fit iPhone screens without awkward clipping.

## Onboarding Behavior

Onboarding remains a three-page flow:

1. Emotional promise: Circleu helps the user reflect.
2. Voice promise: user can speak or type.
3. Local AI/private journal promise: insights stay local for this MVP.

The final page asks for a display name. The name should feel like part of setup, not an afterthought.

If the user skips or leaves the name empty, Circleu saves `Friend`, not a fake personal name. This avoids placeholder identity.

The onboarding layout should:

- keep the hero image immersive,
- improve readability over the image,
- keep controls reachable near the bottom,
- avoid text crowding on smaller iPhones,
- use clear, short copy.

## Home Behavior

Home becomes the polished daily start screen:

- Greeting uses the local display name.
- The main visual hero feels intentional and branded.
- The primary action is still starting a recording.
- Daily prompt is easy to scan and can be refreshed.
- Local progress is shown with real values.
- Latest reflection card opens the saved entry detail.
- Empty state still feels encouraging when there are no entries.

Home should not contain marketing filler. Every visible element should help the user start, continue, or review reflection.

## Shared Navigation

The top bar and bottom tab bar should feel designed, not default.

Top bar:

- Home shows a real level derived from entry count.
- Journal/Profile show a real streak derived from saved entries.
- Circle avoids fake edit behavior unless the edit action is wired.
- No hard-coded `LV4` or `12 STREAK`.

Bottom navigation:

- Keep the four tabs.
- Improve selected/unselected contrast.
- Use stable dimensions so tab selection does not shift layout.
- Keep labels readable and non-overlapping.

## Data Rules

Use local data only:

- `UserProfileStore.displayName` for greeting and setup.
- `UserProfileStore.dailyPromptIndex` for prompt selection.
- `ReflectionJournalStore.entries.count` for level/progress.
- Saved entry dates for streak.
- Latest saved entry for latest emotion/reflection.

No fake stats may remain in the redesigned onboarding/home/navigation surfaces.

## Architecture

Keep the current SwiftUI architecture.

- `ContentView` continues to inject stores.
- `RootView` owns selected tab and recording presentation.
- `HomeView` reads profile and journal stores.
- `PinguDesign.swift` owns shared navigation and component polish.
- Small computed helpers are acceptable for level, streak, and prompt display.

Avoid introducing a large app-wide state framework.

## Testing

Automated verification:

- Build iPhone 17 Pro simulator.
- Build generic iOS device target.
- Build connected iPhone when available.

Manual phone test:

1. Reset app data or reinstall to see onboarding.
2. Complete onboarding with a name.
3. Confirm Home greeting uses the name.
4. Refresh prompt and confirm it changes.
5. Confirm top bar shows real local level/streak values.
6. Record and save one reflection.
7. Return Home and confirm latest reflection/progress updates.
8. Confirm bottom navigation remains stable on all tabs.

## Success Criteria

This pass succeeds when:

- Onboarding feels polished and complete on an iPhone.
- Home feels like a beautiful daily app screen, not a placeholder.
- Navigation no longer shows fake stats.
- The working recording flow still opens and builds.
- Simulator, generic device, and connected iPhone builds succeed when the phone is available.
