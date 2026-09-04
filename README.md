# eatRUN

An intra-workout fueling planner for runners and cyclists — plan *what* and *when* to eat and
drink (carbs, sodium, caffeine per hour) and place each intake on a timeline.

This repository holds **two implementations** of the same app:

| Directory | Stack | Notes |
| --- | --- | --- |
| [`flutter/`](flutter/) | Flutter + Dart, Riverpod, Drift | The original build. Foods + Plans (matching + scoring), offline-first. |
| [`react-native/`](react-native/) | React Native + Expo, TypeScript, Drizzle + Expo SQLite, React Native Paper, Zustand | A re-implementation on a React Native stack. |

Each directory is a self-contained app with its own README and setup instructions.

## Why two?

The Flutter version was built first as the reference implementation. The React Native version
re-implements the same product on a different stack — a focused way to demonstrate the same
architecture (offline-first, layered, reactive local DB) across two ecosystems.

See each app's own README for features, architecture, and how to run it.
