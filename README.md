markdown
# Mystery Puzzle & Escape Room Companion

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)

A local mobile app for creating and playing multi-step puzzle missions, tracking teams, and managing escape-room style gameplay entirely offline.

---

## 🚀 Features

- **Build Multi-Step Missions:** Create missions with timed steps, clues, and hints.  
- **Team Tracking:** Track multiple teams, their progress, and statistics.  
- **Hints & Clues:** AI-assisted hint generation when teams get stuck.  
- **Achievements & Leaderboard:** Unlock story chapters, achievements, and local leaderboard history.  
- **Replayable Gameplay:** Missions can be replayed with preserved state.  
- **Offline Persistence:** Uses SQLite for mission and session data and SharedPreferences for app settings.  
- **Notifications & Animations:** Smooth step transitions, local notifications on mission completion.  
- **Export Functionality:** Export completed sessions as JSON for review or sharing.  

---

## 🛠 Technology Stack

- **Flutter:** Single codebase for Android and iOS, Material 3 support, hot reload.  
- **Riverpod:** Robust state management with compile-safe providers and scoped state.  
- **SQLite:** Local database for missions, teams, sessions, clues, and achievements.  
- **SharedPreferences:** Persist app settings like theme, timer defaults, sound, and last active team.  
- **Animations & Notifications:** Custom step animations and local notifications for mission events.  

---

## 🗂 Project Structure

 ⁠

lib/
├─ core/
│  ├─ di/           # Dependency injection providers
│  ├─ theme/        # App theme and colors
│  └─ services/     # Notifications, export
├─ data/
│  ├─ database/     # SQLite helper
│  └─ repositories/ # Repository pattern for CRUD operations
├─ presentation/
│  ├─ providers/    # Riverpod providers
│  └─ screens/      # UI screens and widgets

⁠ `

---

## 💾 Local Database Schema (SQLite)

**Tables:**
- `missions`
- `mission_steps`
- `teams`
- `game_sessions`
- `session_clues`
- `achievements`
- `story_chapters`

**Example Table: `mission_steps`**
 ⁠sql
CREATE TABLE mission_steps (
  id TEXT PRIMARY KEY,
  mission_id TEXT NOT NULL,
  title TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  description TEXT,
  time_limit_seconds INTEGER,
  clue_text TEXT,
  FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
);
⁠ `

---

## 🛠 Installation & Setup

1. Clone the repository:

 ⁠bash
git clone <your-repo-url>
cd mystery-puzzle-companion


⁠ 2. Install dependencies:

 ⁠bash
flutter pub get


⁠ 3. Run the app:

 ⁠bash
flutter run


⁠ 4. Run tests:

 ⁠bash
flutter test


---

## ⚡ Usage

* Open the app → Browse Missions → Select a mission → Play Mission.
* Follow timed steps, track clues/hints, and complete sessions.
* Use **“Export”** to save session data as JSON.
* Settings (theme, timer, sound) persist via SharedPreferences.

---

## 🧪 Testing

* **Unit Tests:** Models (Mission, MissionStep, Team, GameSession) and constants.
* **Widget Tests:** UI components like Home, Missions tab, Quick Start section.
* **Integration Tests:** Full app flows, including mission play and step navigation.

---

## 📄 Documentation

* **README:** Setup, usage, and feature overview.
* **ARCHITECTURE.md:** Project layers, DI, repository pattern, state management, and testing.
* **Inline Documentation:** Doc comments in DatabaseHelper, repositories, and services for maintainability.

---

## 📌 Version Control Guidelines

* Meaningful commit messages: *Add mission CRUD*, *Fix leaderboard query*, *Add clue tracking*.
* Track feature progress and maintain clear commit history on GitHub.
* Branching strategy: Feature branches → Pull Requests → Merge to main.

---

## 👨‍💻 Team

**Team Name:** Puzzlecoders
**Members:** Govardhana Lakshmi Abhinaya Mandela, 
Sathwik

---



---

## 🔗 References

* Flutter documentation: [https://flutter.dev](https://flutter.dev)
* Riverpod documentation: [https://riverpod.dev](https://riverpod.dev)
* SQLite for Flutter: [https://pub.dev/packages/sqflite](https://pub.dev/packages/sqflite)
