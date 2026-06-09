# Circleu Domain Models

This document explains the app's core business objects in product language.

## Reflection

`JournalReflectionEntry` is one saved journal check-in.

It contains:

- when the reflection was created,
- how long the recording or typed check-in lasted,
- the transcript,
- which reflection engine created the result,
- the AI reflection result.

This is the main source of truth for Journal, Home progress, Profile progress, and reflection sharing.

## AI Reflection Result

`AIReflectionResult` is the structured insight produced from a transcript.

It contains:

- title,
- emotion,
- summary,
- insight,
- expression moment,
- quote,
- confidence score,
- suggested quest.

The app uses this to show the Reflection screen and to create a follow-up quest after saving.

## AI Reflection Session

`AIReflectionSession` is the local record of how a reflection was generated.

It contains:

- source, such as recording, typed fallback, regeneration, or QA seed,
- transcript and duration,
- engine name,
- linked journal entry when saved,
- one or more attempts,
- selected successful attempt.

Journal entries are for the user's saved reflection. AI sessions are for model evaluation and QA.

## Quest

`Quest` is one small action the user can take after a reflection.

Quest status can be:

- `active`: still available to do,
- `completed`: user finished it,
- `skipped`: user dismissed it.

Completed quests add to progress and XP.

## Circle Space

`CircleSpace` is a private local support space on the user's phone.

For the current MVP, a circle is not a live multi-user group. It is a place to organize support notes and reflection shares until backend community features exist.

## Circle Post

`CirclePost` is one note saved inside a circle.

It can be:

- a support note written by the user,
- a saved share from the latest reflection.

Circle cards show real post count and last activity from these posts.

## Progress Snapshot

`AppProgressSnapshot` is calculated from saved reflections and quests.

It contains:

- entry count,
- streak,
- level,
- XP,
- most common emotion,
- completed quest count,
- badges.

It is derived by `ProgressEngine`, so it does not need its own database storage.

## Stores And Engines

Stores persist local data:

- `ReflectionJournalStore`: saved reflections.
- `UserProfileStore`: display name and local profile preferences.
- `CircleStore`: private circle spaces and posts.
- `QuestStore`: active, completed, and skipped quests.

Engines calculate or generate results:

- `ReflectionEngine`: creates AI reflection results from transcripts.
- `ProgressEngine`: calculates XP, level, streak, badges, and emotion mix.
