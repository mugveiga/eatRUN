# eatRUN — CLAUDE.md

Intra-workout fueling planner (running & cycling), Flutter. Study project — a native
Android dev learning Flutter. Inspired by EatMyRide.

## Commands

```bash
flutter run                                   # run on a device/emulator
flutter analyze                               # lint (must be clean)
flutter test                                  # unit + widget tests
dart run build_runner build                   # regenerate Drift + Riverpod code
dart run build_runner watch                   # regenerate on save
flutter gen-l10n                               # regenerate AppLocalizations from ARB
dart run flutter_launcher_icons                # regenerate launcher icons from assets/icon
dart run flutter_native_splash:create          # regenerate splash screens
```

Icon/splash source art lives in `assets/icon/` (`app_icon.svg` full, `app_icon_foreground.svg`
for Android adaptive). Edit the SVG → `rsvg-convert -w 1024 -h 1024 x.svg -o x.png` → rerun the
two generators above. Config is in `pubspec.yaml` (`flutter_launcher_icons:` / `flutter_native_splash:`).

Run `build_runner` after touching any Drift table/DAO or any `@riverpod` provider.

## Stack

- **State + DI:** Riverpod 3 (codegen, `@riverpod`). Providers are the DI container.
- **Local DB:** Drift 2 (SQLite, type-safe, reactive `watch` streams). Source of truth.
- **Navigation:** go_router.
- **IDs:** client-generated UUIDs (`uuid`), never autoincrement — must survive sync.

## Architecture — layered, offline-first

```
presentation/  Widgets + Riverpod providers   (UI, screen state)
data/          Repository + DAO                (offline-first seam)
core/database/ Drift AppDatabase, tables, sync (storage)
```

Feature-first: `lib/src/features/<feature>/{data,presentation}`. Shared infra in `lib/src/core`.

**The repository is the offline-first seam.** UI talks to repositories, never the DB or
(future) network directly. Today repos only read/write the local DAO. When the backend
lands, remote read/write + a sync queue live in the repository — the UI above never changes.

### Android mental map
Room → Drift · DAO → DAO · Hilt/Dagger → Riverpod providers · ViewModel → Notifier ·
LiveData/StateFlow → providers + `AsyncValue`/streams · Repository → Repository.

## Offline-first data model (important)

Every entity mixes in `SyncColumns` (`lib/src/core/database/sync.dart`):
- `id` — UUID string, primary key.
- `updatedAt` — for last-write-wins later.
- `deletedAt` — **soft delete**; we sync "deleted", never a vanished row.
- `syncStatus` — `pending` until a backend confirms `synced`.
- `userId` — null until Google login scopes data per user.

Backend (Firestore vs Supabase) is **undecided** — the sync fields are backend-agnostic,
so today's local-only code doesn't depend on the choice.

Tables: `Foods`, `Plans` (distance- or duration-bounded, per-hour targets), `PlanItems`
(one consumption on the 0→end timeline, links a Plan to a Food).

## Styling tokens

No magic numbers for layout. Paddings/gaps use the 8-pt scale in
`core/theme/app_spacing.dart` (`AppSpacing.md` etc.); one-off component dimensions
(avatar radius, icon size) use `core/theme/app_sizes.dart` (`AppSizes.*`). Colors always
come from the `Theme`/`ColorScheme`, never hardcoded.

## Localization

No hardcoded user-facing strings. Uses Flutter's official gen-l10n pipeline:
- Strings live in `lib/l10n/app_en.arb` (add a key, run `flutter gen-l10n`; it also
  regenerates on `flutter run`/build via `generate: true` in pubspec).
- Config in `l10n.yaml`; generated `AppLocalizations` lands in `lib/l10n/`.
- In widgets: `final l10n = AppLocalizations.of(context)!;` then `l10n.myFoods`.
  Placeholders are typed params, e.g. `l10n.foodNutrition(carbs, sodium, caffeine)`.
- Add a language later by dropping in `app_pt.arb` — nothing else changes.

## Conventions & gotchas

- **Codegen ordering:** `build.yaml` forces `drift_dev` before `riverpod_generator`.
- **Drift types + Riverpod codegen don't mix:** a `@riverpod` function can't return a
  Drift-generated part-file type (e.g. `Food`) — the generator throws `InvalidTypeException`.
  Write those providers by hand (`StreamProvider`/`Provider`); see `foods_providers.dart`.
  Hand-written classes (`AppDatabase`, repositories) are fine as `@riverpod` return types.
- **Testing — two patterns:**
  - *Data layer* (`foods_dao_test.dart`): build `AppDatabase(NativeDatabase.memory())`
    directly and drive the repository/DAO. Fast and reliable in plain `test()`.
  - *Widget layer* (`widget_test.dart`): **don't touch the real DB** — `testWidgets` runs
    in fake-async, but Drift streams resolve on the real event loop, so a real DB stream
    never emits under `pump()` and the test hangs. Override the stream provider instead:
    `foodsListProvider.overrideWith((ref) => Stream.value(const <Food>[]))`.
  - The default DB is native/file-based and won't open under `flutter test` at all.
- `custom_lint`/`riverpod_lint` are omitted for now — their analyzer pin conflicts with
  Riverpod 3's `uuid ^4.5.1`. Revisit when that loosens.

## Status

- ✅ Foods feature (list, add/edit with photo, soft delete) — the reference vertical slice.
- ◻ Plans: data layer, list screen, and create-plan form done. A plan now has
  `activityType` (run/bike), `distanceKm` + `durationMinutes` (both stored; pace/speed
  derived), and `planType` is nullable — the intake-tracking mode (distance/time) + interval
  are chosen later at the matching step. The create form uses slider+type-in inputs
  (`_SliderInput`) in two cards (workout / targets). Distance/duration/pace-speed start empty
  and only sync once 2 of the 3 are filled (last-two-touched win; third derived); pace
  shows/masks as m:ss for runs. Save is gated until 2 are filled. UI pending —
  food→timeline matching, plan detail/edit.
- App opens into a bottom-nav shell (`core/router/app_shell.dart`) via
  `StatefulShellRoute.indexedStack` — Foods + Plans branches, each keeping its own stack.
  Food add/edit pushes full-screen over the shell (root navigator key).
- Shared `appDatabaseProvider` lives in `core/database/database_provider.dart` (both features
  depend on core, never on each other).
- ⬜ Google login + backend sync.
- ⬜ Dashboard (carbs/sodium/caffeine per hour across past plans).
