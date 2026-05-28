# RailTrack

> A Flighty-style real-time train tracking app for iOS — built for frequent intercity rail travellers in Canada and the US.

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## What is RailTrack?

RailTrack fills the gap that Flighty occupies for flights — but for trains. Get real-time position updates, instant delay and platform-change alerts, personal travel stats, and a social layer that lets you see where your friends are on their journeys.

**Initial focus:** VIA Rail, Amtrak, and GO Transit (Canada / US Northeast).

---

## Features (MVP)

| Feature | Status |
|---|---|
| Trip tracking (Home, Detail, Timeline) | ✅ Scaffolded |
| Live map with train position | ✅ Scaffolded (mock position) |
| Delay & platform-change alerts | ✅ Scaffolded |
| Personal stats (km, on-time %, streaks) | ✅ Scaffolded |
| Friends / social feed | ✅ Scaffolded |
| Add trip manually | ✅ Scaffolded |
| Supabase backend + auth | 🔜 Next |
| Real GTFS-RT live data | 🔜 Phase 2 |
| Live Activities / Dynamic Island | 🔜 Phase 2 |
| Email import (forward to parse) | 🔜 Phase 3 |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Backend / DB | Supabase (PostgreSQL, Auth, Realtime) |
| Maps | MapKit (Apple Maps) |
| Real-time data | GTFS / GTFS-RT feeds |
| Notifications | APNs + UserNotifications |
| Package manager | Swift Package Manager |

---

## Project Structure

```
RailTrack/
├── App/                    # Entry point, AppState, ContentView
├── Models/                 # Trip, Station, Alert, TrainService
├── Services/               # SupabaseService, MockDataService, NotificationService
├── Views/
│   ├── Home/               # HomeView, TripCardView, AddTripView
│   ├── TripDetail/         # TripDetailView, LiveMapView, StationTimelineView
│   ├── Stats/              # StatsView
│   ├── Social/             # SocialView
│   ├── Onboarding/         # OnboardingView
│   └── Components/         # StatusBadge, DelayBanner
├── Utilities/              # ColorTheme, DateExtensions
└── Resources/
    └── Assets.xcassets/    # Colour palette, app icon
```

---

## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17+ simulator or device
- (For backend) A [Supabase](https://supabase.com) project

### Running Locally

1. Clone the repo:
   ```bash
   git clone https://github.com/ryanphanna/RailTrack.git
   cd RailTrack
   ```
2. Open `RailTrack.xcodeproj` in Xcode.
3. Select a simulator (iPhone 15 or later recommended).
4. Build & run — the app will launch with mock data, no backend required.

### Configuring Supabase (when ready)

1. Create a project at [supabase.com](https://supabase.com).
2. Apply the schema from `docs/schema.sql` (coming soon).
3. Copy your project URL and anon key into `Config.swift` (gitignored).
4. Add the [Supabase Swift SDK](https://github.com/supabase/supabase-swift) via SPM.

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full plan.

---

## Contributing

This is currently a personal project. Issues and discussion welcome.

---

## License

MIT — see [LICENSE](LICENSE).
