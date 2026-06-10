# Circleu Domain Models

This document explains the core app objects in product language.

## Journal Reflection Entry

`JournalReflectionEntry` is one saved journal check-in.

It stores:

- creation time,
- recording or typed duration,
- transcript,
- engine name,
- selected AI reflection result,
- linked AI session ID,
- editable title and emotion,
- private note,
- tags,
- last edited time.

It is the source of truth for Journal, Home progress, Profile progress, suggested tips, and privacy-safe circle sharing.

## AI Reflection Result

`AIReflectionResult` is the structured insight generated from a transcript.

It stores:

- title,
- emotion,
- summary,
- insight,
- expression moment,
- quote,
- confidence score,
- suggested quest.

The app uses this on the Reflection screen and as the starting point for follow-up tips.

## AI Reflection Session

`AIReflectionSession` records how a reflection was generated.

It stores:

- source, such as recording, typed fallback, regeneration, or QA seed,
- transcript and duration,
- engine name,
- linked journal entry when saved,
- attempts,
- selected attempt,
- merged session IDs.

Journal entries are user-facing saved reflections. AI sessions support QA, model evaluation, and future provider comparison.

## Quest

`Quest` is one small action the user can take after a reflection.

Status values:

- `active`: available to do,
- `completed`: finished by the user,
- `skipped`: dismissed by the user.

Completed quests contribute to XP and progress.

## Circle Space

`CircleSpace` is a private local support space on the user's phone.

It stores name, intention, emoji, member count, joined state, and creation time.

In the current beta, circles are local social-feed style spaces. They organize support notes and privacy-safe reflection shares until shared CloudKit circles are intentionally added.

## Circle Post

`CirclePost` is one note saved inside a circle.

It stores author label, text, likes, liked state, replies, creation time, and an optional source journal entry ID.

It can represent:

- a support note written by the user,
- a privacy-safe share from a saved reflection.

Circle cards derive post count and latest activity from posts.

## Circle Post Reply

`PostReply` is one reply inside a circle post.

It stores author label, text, creation time, likes, and liked state. In future CloudKit work, replies should map to separate records instead of staying embedded inside `CirclePost`.

## Rewards And Activity

`RewardsStore` owns profile reward data.

It stores:

- total points,
- daily quest award state,
- recent point entries,
- profile activity events.

`PointEntry` records one points award. `ActivityEvent` records one profile timeline event, such as reflection, tips practice, community selection, or community join.

## Tips Practice Session

`TipsPracticeSession` stores communication practice history.

It includes the original message, scene, tone, situation, turns, coach output, and attached image count. This is private user data and belongs in the private CloudKit database when sync is enabled.

## Progress Snapshot

`AppProgressSnapshot` is derived by `ProgressEngine`.

It contains entry count, streak, level, XP, most common emotion, completed quest count, and badges. It should not be stored as a separate source of truth.

## Stores And Engines

Stores persist local data:

- `ReflectionJournalStore`: saved reflections.
- `AIReflectionSessionStore`: AI generation sessions.
- `UserProfileStore`: display name and local profile preferences.
- `CircleStore`: private circle spaces and posts.
- `QuestStore`: active, completed, and skipped quests.
- `TipsPracticeStore`: recent tips practice sessions.
- `RewardsStore`: profile points, reward log, daily award state, and activity timeline.

Engines calculate or generate results:

- `ReflectionEngine`: creates AI reflection results from transcripts.
- `TranscriptQuality`: validates reflection input.
- `ProgressEngine`: calculates XP, level, streak, badges, and emotion mix.
