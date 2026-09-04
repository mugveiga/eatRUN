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
- **State:** reactive DB via `useLiveQuery` + local component state. No global store —
  Zustand was removed as unused (YAGNI); re-add (`expo install zustand`) only if a real
  cross-cutting need appears (e.g. a settings store).
- **react-hook-form + zod** — forms/validation (used on the Plan form; Foods uses `useState`).
  Needs `@hookform/resolvers` for `zodResolver`. **i18next** — localization (added with features).

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

## Conventions & gotchas

- **Dark mode needs BOTH themes.** Paper's `PaperProvider theme` only styles Paper
  components; the nav chrome (status-bar area, headers, tab bar, screen backgrounds) is React
  Navigation's. `_layout.tsx` wires a `ThemeProvider` (nav) alongside `PaperProvider`, mapping
  Paper's MD3 colors into the nav theme, both driven by `useColorScheme`. Don't drop it.
- **Keyboard:** form ScrollViews wrap in `KeyboardAvoidingView` (`padding` iOS / `height`
  Android) + `keyboardShouldPersistTaps="handled"` so focused fields stay visible.

## Status

Foundation + **Foods feature (complete)**: repository (`saveFood`/`findFood`/`deleteFood`,
UUIDs + sync stamps), `useFoods` (`useLiveQuery`), list screen (FAB, delete, tap-to-edit) and
add/edit form (photo via camera/gallery, integer nutrition on one row, notes, **salt↔sodium
swap** storing sodium mg, **max caps** via clamp-on-input). Screens live in
`src/features/foods/ui`; route files in `src/app` are thin wrappers. Foods form uses `useState`
(the Plan form will use react-hook-form + zod).

**i18n** is wired: `src/core/i18n` (i18next + react-i18next, device locale via
`expo-localization`, `en.json`, initialized by a side-effect import in `_layout.tsx`). Use
`const { t } = useTranslation()` then `t('foods.name')`; placeholders via
`t('foods.nutrition', { carbs, sodium, caffeine })`. Add a language by dropping in another
resource bundle. (Watch for shadowing: name the `onChangeText` param `text`, not `t`.)

Next: Plans (create → match → score).
