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

**UI pattern — MVVM + UDF + immutable state.** Every screen is a public **Route** + a private
stateless **Screen**:
- *Route* (`FoodsListRoute`, `FoodFormRoute`) owns the `ViewModel` (via lifecycle `viewModel { }`),
  Koin injection, and side effects (image picker). It observes state and passes it down.
- *Screen* is a pure function of an **immutable state** (`data class`, `copy`) plus event
  callbacks out — no DI, no VM, no I/O. Easy to preview/test.
- *ViewModel* exposes `StateFlow` (state down); UI calls VM functions (events up). State is
  always an immutable data class or an immutable list.

**Navigation is type-safe:** `@Serializable` route types (`FoodsList`, `FoodForm(foodId)`) with
`composable<T>` + `entry.toRoute<T>()`, not string paths (needs the kotlin-serialization plugin).
Route types must **not be `private`** — serialization reads a route object's `INSTANCE` field
reflectively, which throws `IllegalAccessException` on a package-private type. Use `internal`.

**Strings** are externalized via **Compose Resources**: `commonMain/composeResources/values/strings.xml`
→ generated `Res` class in package `com.eatrun.resources` (set in `build.gradle.kts`
`compose.resources { publicResClass = true; packageOfResClass = "com.eatrun.resources" }`). Use
`stringResource(Res.string.<id>)`; format args like `nutrition_summary` use `%1$d` positional
specifiers. Add a locale by dropping in `values-<lang>/strings.xml`.

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
4. ✅ **Foods feature complete** — Navigation Compose (`NavHost`, list ↔ `food_form?foodId=`),
   shared `FoodFormViewModel` (`androidx.lifecycle.ViewModel` + `StateFlow`, validation + max
   caps), created by lifecycle's `viewModel { }` with the Koin-injected repository. List rows
   tap-to-edit; FAB opens create; delete lives in the edit toolbar. Light/dark via
   `core/theme/Theme.kt`. **Photo**: FileKit picker → bytes copied into app storage via the
   `ImageStore` seam (androidMain/jvmMain impls, bound in `platformModule`) → path stored in
   `photoUri`, displayed by Coil 3 (`FoodImage`, `okio.Path` model) on the list + form.
5. ✅ **Strings externalized** — Compose Resources (`strings.xml` → `Res.string.*`); screens
   refactored to Route + stateless Screen; type-safe nav routes; list delete removed (edit-only).
   **Salt↔sodium swap** on the form: pure `features/foods/logic/Sodium.kt` (1 g salt ≈ 400 mg
   sodium, `saltToSodiumMg`/`sodiumMgToSalt`/`formatSalt`, MAX 25 g / 10000 mg); VM holds a
   `saltMode` flag, `toggleSalt()` converts the field so stored sodium never changes, save
   normalizes back to mg. Sodium field is decimal in salt mode.
6. Plans — form, timeline, score (same slices as RN).
7. iOS target.
6. **Showcase:** refactor the **food create/edit** screen to *shared logic + native UI* —
   Compose on Android/Desktop, **SwiftUI** on iOS, both bound to the shared ViewModel
   (bridging `StateFlow` → SwiftUI via SKIE or a Flow wrapper). The one screen that demonstrates
   the "shared logic, native UI" KMP model against the fully-shared Compose model everywhere else.

## Status

**Steps 1–4 complete.** Shared Compose `App()` runs on **Desktop** (`:composeApp:run`) and builds
an **Android** APK (`:composeApp:assembleDebug`), both green. Data layer: Room + bundled SQLite +
Koin. **Foods feature done**: reactive list (DAO `Flow` → `collectAsState`), create/edit form via
Navigation Compose + a shared `FoodFormViewModel` (`androidx.lifecycle.ViewModel` + `StateFlow`,
validation), ViewModel built by lifecycle's `viewModel { }` with a Koin-injected repository (no
`koin-compose-viewmodel` needed). Next: Plans (slice 5), then iOS, then the SwiftUI food-form
showcase.

Version note: nav/lifecycle multiplatform are pinned to the **Compose MP 1.7 line** —
navigation-compose `2.8.0-alpha13`, lifecycle-viewmodel-compose `2.8.4`. The newer stable tags
(nav 2.9+, lifecycle 2.11) require Compose MP 1.8+; bump together if CMP is upgraded.

Image stack pinned to the 1.7-safe line to avoid bumping Compose: **FileKit `filekit-compose:0.8.8`**
(picker), **Coil `coil3:coil-compose:3.0.4`** (display). Newer FileKit (0.16) / Coil (3.6) are
Compose-1.8-era. Picked bytes are copied into app storage (`ImageStore`) rather than storing the
raw picker URI, so images survive restart on all platforms.

**Desktop `Main` dispatcher:** `viewModelScope` uses `Dispatchers.Main`, which the JVM lacks by
default → "Module with the Main dispatcher is missing" when a VM coroutine runs (e.g. save). Fixed
by `kotlinx-coroutines-swing` in `jvmMain` (provides Main = Swing EDT).

**Skiko split-version gotcha (Desktop):** the nav/lifecycle alphas drag `skiko-awt` up to 0.8.25
while Compose 1.7.3's desktop **native** runtime stays 0.8.18 → `UnsatisfiedLinkError`
(`RenderNodeContext_nMake`) at `:composeApp:run`. Fixed by forcing every `org.jetbrains.skiko`
artifact to one version via `resolutionStrategy` in `composeApp/build.gradle.kts`. Re-check the
pin if Compose/nav/lifecycle versions change.

**Theme:** light/dark follow the system (`isSystemInDarkTheme()` → `LightColors`/`DarkColors` in
`core/theme/Theme.kt`). This also fixes the Android status bar (was white-on-white when the app was
forced light under a dark system); with `enableEdgeToEdge()` the bar icons auto-match the system,
now consistent with the app theme.

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
