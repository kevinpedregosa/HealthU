# HealthU

HealthU is a SwiftUI app for student mental-health check-ins and anonymous campus trend insights.

## Current MVP Features
- UCI SSO login wiring in app (Authorization Code + PKCE flow through backend)
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

## Auth Setup (UCI + Duo)
1. Create a UCI OIDC app registration and set redirect URI to `healthu://auth/callback`.
2. Add `AUTH_API_BASE_URL` to app Info settings (for example `http://localhost:4000`).
3. Open `/Users/kevinpedregosa/Documents/HealthU/HealthU/backend`.
4. Copy `.env.example` to `.env` and fill in UCI issuer/endpoints/client values.
5. Install backend deps: `npm install`.
6. Run backend: `npm run dev`.
7. In Xcode, run the app and tap `Continue with UCI SSO`.

Backend endpoints included:
- `GET /auth/uci/start`
- `POST /auth/uci/callback`
- `GET /me`
- `GET /health`

## Project Structure
- `HealthU/ContentView.swift` - App UI flow (login, check-in, trends)
- `HealthU/HealthStore.swift` - App state + seeded demo data
- `HealthU/AuthManager.swift` - Web auth session + backend auth exchange
- `HealthU/Models.swift` - Domain models (`CheckIn`, `SchoolWeeklyAggregate`, `Metric`)
- `HealthU/HealthUApp.swift` - App entrypoint
- `backend/src/server.js` - OIDC + session backend starter

## Privacy Direction
- Individual data should remain student-visible only.
- Campus analytics should be aggregated and threshold-gated to preserve anonymity.
- No personally identifying student data should appear in shared dashboards.

## Next Steps
- Add iOS target (currently runs as macOS app in this project configuration)
- Replace seeded data with backend persistence
- Add secure keychain session storage on client
- Add admin dashboard/API for institutional analytics
