# Architecture: Mystery Puzzle Companion

This document describes the architectural decisions, patterns, and structure of the app for the graduate requirement and for maintainability.

## 1. Clean Architecture & Separation of Concerns

The project follows a **layered clean architecture** with clear boundaries:

```
lib/
├── main.dart                 # Entry point, ProviderScope, root widget
├── core/                     # Shared infrastructure
│   ├── constants/            # App-wide constants
│   ├── di/                   # Dependency injection (Riverpod providers)
│   └── theme/                # Theming (light/dark)
├── data/                     # Data layer
│   ├── database/             # SQLite (DatabaseHelper)
│   ├── models/               # Domain entities (Mission, MissionStep, Team, GameSession, etc.)
│   ├── preferences/          # SharedPreferences wrapper
│   └── repositories/        # Repository implementations
└── presentation/             # UI layer
    ├── providers/            # Riverpod providers (state)
    ├── screens/              # Full screens
    └── widgets/             # Reusable UI components
```

- **Core**: No business logic; only DI, theme, and constants. Keeps the app config and cross-cutting concerns in one place.
- **Data**: All persistence and data access. Models are plain Dart classes (with Equatable); repositories abstract the database. UI never talks to SQLite or SharedPreferences directly.
- **Presentation**: Screens and widgets only. They watch providers and dispatch actions; they do not contain SQL or file I/O.

This **separation of concerns** makes it easier to test (mock repositories), change storage (e.g. swap SQLite implementation), and onboard new developers.

---

## 2. Dependency Injection (Riverpod)

All injectable dependencies are defined in **`core/di/providers.dart`**:

- **DatabaseHelper**: Singleton, provided once. All repositories depend on it.
- **SharedPreferences / PreferencesService**: For settings (theme, defaults). Provided as `FutureProvider` because initialization is async.
- **Repositories**: `MissionRepository`, `TeamRepository`, `SessionRepository`, `AchievementRepository`. Each is a `Provider` that depends on `databaseHelperProvider`.

Benefits:

- **Testability**: In tests we can override these providers with fakes or mocks (e.g. in-memory DB or mock repositories).
- **Single source of truth**: No global variables or static DB instances; everything is resolved through `ref.read` / `ref.watch`.
- **No BuildContext in business logic**: Riverpod allows reading providers without context, so repositories and services stay pure and testable.

---

## 3. Repository Pattern

Each entity that needs persistence has a **repository** in `data/repositories/`:

- **MissionRepository**: CRUD for missions and mission steps (getAllMissions, getMissionById, createMission, updateMission, deleteMission, getStepsByMissionId, addStep, updateStep, deleteStep, deleteStepsByMissionId).
- **TeamRepository**: CRUD for teams.
- **SessionRepository**: CRUD for game sessions + leaderboard query.
- **AchievementRepository**: Achievements (for future use).

Repositories:

- Encapsulate all SQLite access via `DatabaseHelper`.
- Expose **domain-friendly methods** (e.g. `getMissionById(String id)`) instead of raw queries.
- Return domain models (e.g. `Mission`, `List<MissionStep>`) or simple types. The UI and providers never see `Map` or database rows.

This keeps the **data layer stable** when we change schema or add caching, and keeps the **presentation layer** independent of storage details.

---

## 4. Advanced State Management (Riverpod)

The app uses **Riverpod** for:

- **Global state**: Theme mode (`themeModeProvider`), missions list, mission detail, steps, teams, sessions, leaderboard. All are defined in `presentation/providers/` and `core/di/providers.dart`.
- **Reactive programming**: Screens use `ref.watch(provider)` so the UI rebuilds when data changes (e.g. after create/update/delete). No manual setState for server/DB-backed data.
- **State persistence**: Theme preference is persisted via `PreferencesService` (SharedPreferences). `ThemeModeNotifier` loads on startup and saves on toggle, so the choice survives app restarts.
- **Family providers**: e.g. `missionDetailProvider(missionId)`, `missionStepsProvider(missionId)`, `sessionsByTeamProvider(teamId)` allow scoped state per entity without duplicating logic.

We chose Riverpod over Provider for compile-safe provider references, better testability (override in tests), and no dependency on `BuildContext` for reading state.

---

## 5. Local Data & No Cloud

- **SQLite**: All missions, steps, teams, sessions, and achievements are stored locally via `sqflite` and `DatabaseHelper`. No cloud APIs.
- **SharedPreferences**: User preferences (dark mode, default timer, sound, last active team/session) via `PreferencesService`. Used for state persistence as required for graduate advanced state management.
- **File system**: Used for SQLite DB path (`path_provider`, `path`) and for optional data export (file system operations requirement).

---

## 6. Navigation

- **MainShell** (in `main.dart`): Bottom navigation with three destinations—Home, Missions, Teams—using `NavigationBar` and `IndexedStack` so each tab keeps its state.
- **Push navigation**: From Home and Missions we push to Mission Detail, Mission Builder, Mission Player, and Leaderboard via `Navigator.push(MaterialPageRoute(...))`.
- This satisfies the requirement for “proper navigation flow” and a consistent navigation pattern (bottom nav + stack).

---

## 7. Testing Strategy (Graduate)

- **Unit tests**: Target models (fromMap, toMap, copyWith, equality), `PreferencesService` (with mocked SharedPreferences), and repository logic with a mocked or in-memory database where applicable.
- **Widget tests**: Key screens (e.g. Home, Missions list, Mission detail) are tested for presence of critical widgets and basic interaction (tap buttons, navigate).
- **Integration tests**: One or more end-to-end flows (e.g. open app → go to Missions → open a mission → play) to validate navigation and data flow.

Architecture supports this: repositories can be overridden in tests, and UI only depends on providers, not on concrete DB or prefs implementations.

---

## 8. Advanced Features (Graduate)

- **Custom animations**: Used in the app (e.g. implicit animations for list/card transitions, and explicit animations where appropriate) to improve UX and meet the “custom animations (implicit & explicit)” requirement.
- **Local notifications**: Implemented with `flutter_local_notifications` (e.g. mission completion or step time reminders), fulfilling the “local notifications” requirement.
- **File system operations**: Data export (e.g. missions/sessions to JSON file) uses `path_provider` and `dart:io` / file APIs, fulfilling “file system operations” and optional bonus data export.
- **Background-style processing**: Heavy or long-running work (e.g. export, batch updates) is structured with async/await and, where needed, `compute` or isolates so the UI stays responsive (background processing requirement).

---

## 9. Why These Choices?

| Decision | Reason |
|----------|--------|
| Riverpod over Provider/BLoC | Compile-safe, testable, no context in business logic, good for our app size. |
| Single DatabaseHelper instance | Avoids connection leaks and ensures one DB for the app. |
| Repository per domain aggregate | Clear CRUD boundary, easy to mock and test. |
| PreferencesService wrapper | Single place for SharedPreferences keys and defaults; easy to test with mocks. |
| Theme in Riverpod + SharedPreferences | Global theme state with persistence and simple toggle from UI. |
| Layered folders (core / data / presentation) | Clear separation of concerns and a path to add domain layer later if needed. |

This architecture is designed to satisfy both undergraduate and **graduate** requirements: clean architecture, separation of concerns, dependency injection, repository pattern, advanced state management with Riverpod, state persistence, and support for testing, animations, local notifications, and file system operations.
