# eatRUN — Kotlin Multiplatform (CLAUDE.md)

Third implementation of eatRUN (see `../flutter` and `../react-native`), on **Kotlin
Multiplatform + Compose Multiplatform**. Same product (intra-workout fueling planner), same
offline-first layered architecture — one Kotlin codebase across Desktop, Android and iOS.

## Commands

Gradle is installed via SDKMAN; the committed wrapper (`./gradlew`) is the source of truth.
Java 17 (Temurin) is on PATH.

```bash
./gradlew :composeApp:run                 # launch the Desktop (JVM) app — a window
./gradlew :composeApp:compileKotlinJvm    # compile shared + JVM (fast check, no window)
./gradlew build                           # full build (all configured targets)
```

Desktop is the fast dev loop: no Android SDK, no simulator. Android/iOS targets are added in
later steps.

## Stack

- **Kotlin Multiplatform** + **Compose Multiplatform** (`1.7.3`, Kotlin `2.1.21`) — shared UI.
- **Material 3** (Compose) — components + theming (deep-orange `#FF5722` seed).
- **Room (KMP)** + KSP + bundled SQLite driver — reactive local DB via DAOs returning `Flow`.
  Chosen over SQLDelight because it's the *same* library used in native Android, so the KMP
  story is "one Room definition, three platforms." *(not wired yet)*
- **Jetpack Navigation Compose** (multiplatform) — routing. *(not wired yet)*
- **Koin** — DI (Hilt is Android-only, so it can't be used here). *(not wired yet)*
- **ViewModel + StateFlow** (`androidx.lifecycle`, multiplatform) — screen state. *(not wired)*
- **Coroutines + Flow**, **kotlinx-datetime**, **`kotlin.uuid.Uuid`** — async, dates, ids.
- **Compose Resources** (`compose.components.resources`) — localization. *(not wired yet)*

## Architecture (mirrors the Flutter / RN builds)

Layered, feature-first, offline-first. Repository is the seam: UI → repository → DB (local now;
remote/sync later). Business logic (pace⇄duration, timeline seeding, scoring) lives in pure
Kotlin in `commonMain`, framework-free and testable.

```
kmp/
├── composeApp/
│   └── src/
│       ├── commonMain/kotlin/com/eatrun/   # shared UI + logic + data (the bulk)
│       ├── jvmMain/kotlin/com/eatrun/       # Desktop entry (main.kt)
│       ├── androidMain/                     # Android Activity + Room driver (actual) — later
│       └── iosMain/                         # iOS Room driver (actual) + bits — later
├── iosApp/                                  # Xcode shell hosting shared Compose — later
├── gradle/libs.versions.toml               # version catalog
└── gradlew                                  # committed wrapper (Gradle 8.11.1)
```

**KMP-specific concept:** `expect`/`actual` — declare a common API (e.g.
`expect fun createRoomDatabase(): AppDatabase`) with a per-platform `actual`. This is the seam
where shared code meets platform code (SQLite driver, etc.).

## Plan (small steps)

Build order **Desktop → Android → iOS**, features mirroring the RN app.

1. ✅ **Runnable Desktop shell** — `App()` composable, JVM entry, Material 3, eatRUN branding.
2. ✅ **Android target** — `androidTarget()`, `MainActivity` hosting the same `App()`, manifest,
   `local.properties` → `/Users/murilo/dev/sdk`. `assembleDebug` produces a debug APK.
3. ✅ **Data layer** — Room (`FoodEntity`/`FoodDao` with `Flow`, `AppDatabase` + generated
   `AppDatabaseConstructor` via KSP), bundled SQLite driver, **Koin** with the `expect`/`actual`
   `platformModule()` seam (Android supplies the builder with a `Context`, Desktop with a file
   path), `FoodsRepository`, and a reactive Foods list screen (temporary "add sample" FAB).
   Sync columns are shared via **`@Embedded val sync: SyncColumns`** (Room flattens them into each
   table — the base-entity equivalent of the Flutter mixin / RN spread) plus a `Syncable`
   interface for generic sync logic. `@PrimaryKey` on an embedded field → declare it as
   `@Entity(primaryKeys = ["id"])`; the `sync` property needs `override` (satisfies `Syncable`).
4. Foods form (ViewModel + validation, replaces the sample FAB), then Plans — same slices as RN.
5. iOS target.
6. **Showcase:** refactor the **food create/edit** screen to *shared logic + native UI* —
   Compose on Android/Desktop, **SwiftUI** on iOS, both bound to the shared ViewModel
   (bridging `StateFlow` → SwiftUI via SKIE or a Flow wrapper). The one screen that demonstrates
   the "shared logic, native UI" KMP model against the fully-shared Compose model everywhere else.

## Status

**Steps 1–3 complete.** Shared Compose `App()` runs on **Desktop** (`:composeApp:run`) and builds
an **Android** APK (`:composeApp:assembleDebug`), both green. The **data layer** is wired: Room +
bundled SQLite + Koin, with a reactive Foods list (DAO `Flow` → `collectAsState`) and a temporary
"add sample" FAB proving the round-trip. Next: the real Foods form (slice 4), then Plans, then iOS,
then the SwiftUI food-form showcase.

Gotchas learned: `android.useAndroidX=true` is required (Compose pulls in AndroidX);
`-Xexpect-actual-classes` compiler flag silences the Beta warning on the `expect object`
constructor; Room KSP configs in a KMP module are `kspAndroid`/`kspJvm` (per-target). Gradle
wrapper committed; `build/`, `.gradle/`, `.kotlin/`, `local.properties` git-ignored; `schemas/`
committed.

## Commands (Android)

```bash
export ANDROID_HOME=/Users/murilo/dev/sdk    # not exported to non-interactive shells
./gradlew :composeApp:assembleDebug          # build debug APK
./gradlew :composeApp:installDebug           # install to a running emulator/device
```
