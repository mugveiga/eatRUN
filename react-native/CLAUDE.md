# eatRUN — React Native (CLAUDE.md)

React Native re-implementation of the Flutter eatRUN app (see `../flutter`). Same product
(intra-workout fueling planner), different stack — built to mirror the kaizen JD.

## Commands (use Node 20+)

```bash
nvm use 20                       # Expo SDK 57 needs Node 20+ (create-expo-app needs the File global)
npx expo start                   # dev server; scan QR with Expo Go
npx expo start --ios             # iOS simulator
npx expo start --android         # Android emulator
npx tsc --noEmit                 # typecheck
npx drizzle-kit generate         # regenerate SQL migrations after editing schema.ts
npx expo export -p ios           # bundle (catches Metro/Babel errors)
```

## Stack

- **React Native + Expo** (SDK 57, RN 0.86, React 19), **TypeScript** (strict).
- **Expo Router** — file-based routing (`src/app`), tabs + stacks.
- **Drizzle ORM + Expo SQLite** — reactive local DB via `useLiveQuery`; foreign keys ON.
  (Drizzle also targets Postgres, matching the JD's RDS — same ORM device↔backend.)
- **React Native Paper** (Material Design 3) — components + theming + dark mode.
- **Zustand** — light cross-cutting state; DB live-queries drive most screens.
- **react-hook-form + zod** — forms/validation. **i18next** — localization (added with features).

## Architecture (mirrors the Flutter build)

Layered + feature-first, offline-first. Repository is the seam: UI → repository → DB (local
now; remote/sync later without changing the UI).

```
src/
├── app/                    # Expo Router routes (file-based)
│   ├── _layout.tsx         # providers (Paper, SafeArea) + migration gate + root Stack
│   ├── index.tsx           # redirect → /foods
│   └── (tabs)/             # bottom tabs: foods, plans
├── core/
│   ├── db/                 # schema.ts (Drizzle), client.ts (db instance)
│   └── theme/              # Paper MD3 light/dark (deep-orange seed)
└── features/
    ├── foods/{data,ui}     # repository + screens (to build)
    └── plans/{data,ui}
drizzle/                    # generated SQL migrations (committed)
```

## Data model

`foods`, `plans`, `plan_items` — each with the offline-first sync columns (`id` UUID,
`updatedAt`, `deletedAt` soft-delete, `syncStatus`, `userId`). Mirrors the Flutter schema.
`plan_items.planId` cascades on delete.

## Conventions

- **Codegen:** re-run `drizzle-kit generate` after any `schema.ts` change; the `drizzle/`
  folder (SQL + `migrations.js`) is committed and applied at startup via `useMigrations`.
- **Reactivity:** `openDatabaseSync(..., { enableChangeListener: true })` + `useLiveQuery`
  (the analog of Drift's `.watch()` streams).
- **Node:** use 20+ (`nvm use 20`); the machine defaults to 19 which breaks Expo tooling.

## Status

Foundation only: DB layer, theme, tabs shell (Foods/Plans placeholders). Features next —
Foods, then Plans (create → match → score), mirroring the Flutter build order.
