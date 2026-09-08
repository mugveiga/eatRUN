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
2. Android target (needs Android SDK — Studio is installed; confirm `~/Library/Android/sdk`).
3. Room schema + driver (`expect`/`actual`) + Koin + a reactive Foods list.
4. Foods feature (list + form), then Plans (form, timeline, score) — same slices as RN.
5. iOS target.
6. **Showcase:** refactor the **food create/edit** screen to *shared logic + native UI* —
   Compose on Android/Desktop, **SwiftUI** on iOS, both bound to the shared ViewModel
   (bridging `StateFlow` → SwiftUI via SKIE or a Flow wrapper). The one screen that demonstrates
   the "shared logic, native UI" KMP model against the fully-shared Compose model everywhere else.

## Status

**Step 1 complete:** Desktop Compose shell compiles and runs. No DB/nav/DI yet — those are the
next slices. Gradle wrapper committed; `build/`, `.gradle/`, `.kotlin/`, `local.properties`
git-ignored.
