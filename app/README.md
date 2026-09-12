# SAFE//SPIT

**Tactical Trajectory System**

SAFE//SPIT is a high-performance, offline-first tactical HUD simulation built in Flutter. It transforms your device into an advanced targeting system, projecting deterministic physics-based impact calculations directly onto your camera feed in real-time.

---

## 🎯 Features

*   **Deterministic Physics Engine:** Real-time trajectory calculation combining device pitch, roll, heading, and simulated car speed to predict precise impact locations.
*   **Tactical AR HUD:** Custom painters project dynamic targeting reticles and telemetry directly over a live 60fps camera feed.
*   **Sensor Fusion:** Fully integrated with device accelerometers, gyroscopes, magnetometers, and GPS to simulate a high-speed vehicle environment.
*   **Offline-First Supabase Architecture:** Built to survive connection drops. Game scores are stored locally in SharedPreferences and lazily synced to Supabase when a connection is established using Anonymous Authentication.
*   **Zero-Latency Haptics & Audio:** Tightly coupled feedback loops ensure sensory confirmation precisely at the moment of lock-on and launch.

## 🚀 Getting Started

To run SAFE//SPIT, you will need a Supabase project for the backend telemetry sync.

1.  **Clone the repository** and ensure you have Flutter installed.
2.  **Database Setup:** Create a new project in Supabase. In the SQL Editor, execute the `backend/migrations/002_profiles.sql` script to create the `players` table and configure Row-Level Security (RLS).
3.  **Authentication:** In your Supabase Dashboard, navigate to **Authentication > Providers** and enable **Anonymous Sign-ins**.
4.  **Environment Setup:** Create a `.env` file in the root of the `app` directory with the following variables:
    ```
    SUPABASE_URL=https://your-project-url.supabase.co
    SUPABASE_ANON_KEY=your-anon-key
    ```
5.  **Run the App:** 
    We pass the environment variables directly to the dart compiler to avoid embedding secrets in source code:
    ```bash
    # Windows PowerShell Example
    $env1 = (Get-Content .env)[0]; $env2 = (Get-Content .env)[1]; flutter run --dart-define="$env1" --dart-define="$env2"
    ```

## 🧠 Architecture Highlights

SAFE//SPIT adheres to strict architectural rules to maintain performance and modularity:
*   **Rule 1 (State Management):** Only `GameState` reads `NormalizedTelemetry`. No raw sensor imports in UI widgets.
*   **Rule 2 (Determinism):** The simulation engine operates entirely on `ScenarioInput`. Given the exact same inputs (speed, pitch, roll), it produces the exact same `SimulationResult` every time.
*   **Rule 4 (No Cloud Dependency in Critical Path):** The core game logic will never block on a network call. The simulation runs offline; telemetry syncs silently in the background.

## 🏆 Hackathon Notes
SAFE//SPIT was built with a focus on polished UI, robust error handling (e.g., degraded sensor fallback, camera failure states), and buttery smooth animations, making it immediately ready for demonstration.

_Disclaimer: REF BUILD v1.0 — SIMULATION ONLY. NO REAL SPITTING AT PERSONS OR PROPERTY._
