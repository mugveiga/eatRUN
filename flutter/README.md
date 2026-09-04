# eatRUN

**An intra-workout fueling planner for runners and cyclists.**

Manage your gels and other items you usually consume on a race or bike.

Plan exactly *what* and *when* to eat and drink during a run or ride — carbs, sodium, and
caffeine per hour — and place each intake on a timeline so you know what to reach for at
km 15 or minute 90. Inspired by apps like EatMyRide.

> This is also a learning project: a hands-on tour of modern Flutter for a developer coming
> from native Android. The architecture notes below double as a study guide.

---

## Features

**Foods** — a personal library of gels, drinks, and snacks.
- Name, photo (camera or gallery), carbs (g), sodium (mg), caffeine (mg), notes.
- Enter sodium as **salt (g)** instead if that's what the label lists — it's converted and
  always stored as sodium (`sodium_mg = salt_g × 400`).

**Plans** — a fueling strategy for a specific workout.
- Run or bike; set any two of **distance / duration / pace‑speed** and the third is computed
  (pace shows as `m:ss` for runs). Per‑hour targets for carbs, sodium, and caffeine.
- **Approximate intake tracking**: choose to space intakes by distance (every N km) or time
  (every N min); this seeds a suggested timeline.
- **Timeline matching**: drop foods onto intake points along `0 → distance/duration`,
  fine‑tune each point's position and servings, add or remove points.
- **Scoring**: live roll‑up of the placed foods into *actual* carbs/sodium/caffeine **per
  hour** versus your targets.

**App‑wide** — bottom‑navigation shell, light/dark theme, full localization (English today,
ready for more), custom launcher icon + splash, and an **offline‑first** local database.

---

## Tech stack

| Concern | Choice |
| --- | --- |
| Language / SDK | Dart `^3.13`, Flutter `3.47` |
| State management + DI | [Riverpod](https://riverpod.dev) 3 (`flutter_riverpod`, `riverpod_annotation` + codegen) |
| Local database | [Drift](https://drift.simonbinder.eu) 2 (`drift`, `drift_flutter`) — reactive SQLite |
| Navigation | [go_router](https://pub.dev/packages/go_router) 18 (`StatefulShellRoute`) |
| Localization | `flutter_localizations` + `gen-l10n` (ARB files) |
| Misc | `uuid`, `intl`, `image_picker`, `path`/`path_provider` |
| Tooling | `build_runner`, `riverpod_generator`, `drift_dev`, `flutter_launcher_icons`, `flutter_native_splash` |

---

## Architecture

**Layered + feature‑first, offline‑first.** This mirrors the recommended Android app
architecture, which makes it a comfortable bridge from native.

```
UI (widgets + Riverpod providers)   →  Data (repositories + DAOs)  →  Sources (local DB now)
```

The **repository** is the offline‑first seam: the UI asks a repository, never the database or
(future) network directly. Today repositories only read/write the local Drift DAO; when a
backend arrives, remote read/write and a sync queue live inside the repository and **the UI
does not change**.

### Coming from Android?

| Android native | This project (Flutter) |
| --- | --- |
| Room (`@Entity`, DAO, Flow queries) | Drift (tables, DAO, `watch()` streams) |
| ViewModel | Riverpod `Notifier` / providers |
| LiveData / StateFlow | Riverpod providers + `AsyncValue` / streams |
| Hilt / Dagger | Riverpod providers *are* the DI |
| Repository pattern | Repository pattern (same idea) |
| Navigation Component | go_router |

### Project layout

```
lib/
├── main.dart                     # ProviderScope + app entry
├── l10n/                         # app_en.arb (source) → AppLocalizations (generated)
└── src/
    ├── app.dart                  # MaterialApp.router: theme, dark mode, l10n, router
    ├── core/
    │   ├── database/             # tables, SyncColumns mixin, AppDatabase, DB provider
    │   ├── router/               # go_router config + bottom-nav shell (AppShell)
    │   ├── theme/                # AppSpacing (8-pt scale), AppSizes
    │   └── widgets/              # shared widgets (SliderInput)
    └── features/
        ├── foods/{data,presentation}
        └── plans/{data,presentation}
test/                             # DAO tests (in-memory DB) + a widget smoke test
```

**Dependency direction:** `features → core`, never the reverse; features avoid depending on
each other. The one deliberate exception is a *one‑way* `Plans → Foods` domain dependency (a
plan is made of foods).

### Data model (offline‑first)

Every entity mixes in `SyncColumns`, so sync is possible later without a migration:

- `id` — client‑generated **UUID** (globally unique; survives sync).
- `updatedAt` — for last‑write‑wins conflict handling.
- `deletedAt` — **soft delete** (we sync "deleted", never a vanished row).
- `syncStatus` — `pending` until a backend confirms `synced`.
- `userId` — null until Google login scopes data per user.

Tables: **Foods**, **Plans** (`activityType`, `distanceKm` + `durationMinutes`, per‑hour
targets, nullable `planType`/`intakeInterval` chosen at matching), and **PlanItems** (a food
placed at an `offsetLength` on the timeline, with a `quantity`). `PlanItems.planId` cascades
on delete; foreign keys are enforced (`PRAGMA foreign_keys = ON`).

---

## Getting started

**Prerequisites:** Flutter `3.47`+ (Dart `3.13`+) and an Android/iOS device or emulator.

```bash
flutter pub get
dart run build_runner build        # generate Drift + Riverpod code (required)
flutter run
```

`gen-l10n` runs automatically on build (via `generate: true` in `pubspec.yaml`). While
developing, keep codegen live with:

```bash
dart run build_runner watch
```

Re‑run `build_runner` after changing any Drift table/DAO or any `@riverpod` provider.

### Tests

```bash
flutter test
```

Data‑layer tests use an in‑memory Drift database; the widget test stubs providers (a real
Drift stream never emits under `flutter test`'s fake‑async clock).

### Regenerating the icon / splash

Source art lives in `assets/icon/`. Edit the SVG, then:

```bash
rsvg-convert -w 1024 -h 1024 assets/icon/app_icon.svg -o assets/icon/app_icon.png
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Conventions

- **No magic values.** Strings live in ARB files (`AppLocalizations`); spacing/sizes come from
  `AppSpacing` / `AppSizes`; colors come from the `Theme`/`ColorScheme`.
- **Generated code is committed** (`*.g.dart`) and marked `linguist-generated` so a clone
  builds without a codegen step; the auto‑regenerated `AppLocalizations` files are gitignored.
- **Edge‑to‑edge:** screens pushed over the bottom‑nav shell wrap their scroll body (and bottom
  sheets their content) in `SafeArea`.
- **Riverpod + Drift codegen gotcha:** a `@riverpod` function can't return a Drift‑generated
  part‑file type (e.g. `Food`) — those providers are written by hand; DI providers use codegen.

More detail for contributors (and AI assistants) lives in [`CLAUDE.md`](CLAUDE.md).

---

## Roadmap

- [ ] **Google login + backend sync** — the sync metadata is already in place; add auth and a
  sync engine, then choose the backend (**Firestore** vs. **Supabase**).
- [ ] **Dashboard** — carbs/sodium/caffeine per hour trends across past plans.
- [ ] **Wider test coverage** — the stateful screens (fill‑2 solver, pace mask, salt
  conversion, scoring math) still need widget/unit tests.
- [ ] Nice‑to‑haves — multiple foods per intake point, plan duplication, export/share.

---

## Status

Local‑only, single‑user, offline‑first. The full **Foods** and **Plans** (create → match →
score) flows are implemented. Backend sync and the dashboard are next.
