# HealthU

HealthU is a SwiftUI app for student mental-health check-ins and anonymous campus trend insights.

## Current MVP Features
- University email login (`.edu` validation)
- Weekly check-in sliders:
  - Stress
  - Sleep quality
  - Anxiety
  - Academic pressure
- Personal trend charts
- School-level anonymous trend charts (shown only when response threshold is met)

## Tech Stack
- Swift
- SwiftUI
- Charts framework

## Run Locally
1. Open `/Users/kevinpedregosa/Documents/HealthU/HealthU/HealthU.xcodeproj` in Xcode.
2. Select scheme `HealthU`.
3. Select destination `My Mac`.
4. Press `Cmd+R`.

## Project Structure
- `HealthU/ContentView.swift` - App UI flow (login, check-in, trends)
- `HealthU/HealthStore.swift` - App state + seeded demo data
- `HealthU/Models.swift` - Domain models (`CheckIn`, `SchoolWeeklyAggregate`, `Metric`)
- `HealthU/HealthUApp.swift` - App entrypoint

## Privacy Direction
- Individual data should remain student-visible only.
- Campus analytics should be aggregated and threshold-gated to preserve anonymity.
- No personally identifying student data should appear in shared dashboards.

## Next Steps
- Add iOS target (currently runs as macOS app in this project configuration)
- Replace seeded data with backend persistence
- Add university authentication flow
- Add admin dashboard/API for institutional analytics
