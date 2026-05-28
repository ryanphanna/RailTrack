# Changelog

All notable changes to RailTrack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `TripRecord` SwiftData entity for on-device trip persistence (replaces Supabase stub)
- `StationDatabase` service with 30+ VIA Rail, Amtrak, and GO Transit stations including coordinates
- `AddTripView` rewired: live station autocomplete, operator picker with branding, date range validation, SwiftData insert
- `HomeView` rewired: `@Query`-driven dashboard, swipe-to-delete with notification cancellation
- `StatsView` now computes stats dynamically from real `TripRecord` data: total trips, distance (km), unique stations, on-time %, streaks, and favourite operator; includes empty state
- Departure reminders via `UNUserNotificationCenter` — scheduled 30 min before departure on trip add, cancelled on delete
- Notification permission requested automatically when the user completes onboarding
- Native `ShareLink` share sheet on Trip Detail with formatted trip summary text
- Smart map camera auto-fits to actual great-circle route distance (1.5× padding, 50 km floor)

### Changed
- `HomeView` ViewModel replaced with `@Query` + pure computed properties (no more `ObservableObject`)
- `StatsView` no longer depends on `MockDataService`

### Initial Scaffold (included in first commit)
- Xcode project scaffold targeting iOS 17+, SwiftUI
- Core data models: `Trip`, `Station`, `Stop`, `TrainAlert`, `TrainService`
- `AppState` environment object managing onboarding and auth state
- `MockDataService` with realistic VIA Rail, Amtrak, and GO Transit sample data
- `SupabaseService` stub (ready to wire real SDK calls)
- `NotificationService` for departure reminders and delay alerts via `UNUserNotificationCenter`
- Design system: `ColorTheme` (10 named dark-mode colours, operator branding), rounded typography scale, `DateExtensions`
- `HomeView` — active / upcoming / past trip sections with pull-to-refresh and FAB
- `TripCardView` — premium card with operator colour strip, route line, and status badge
- `TripDetailView` — full detail screen with map header, time summary, delay banner, and station timeline
- `LiveMapView` — MapKit map with origin/destination markers, route polyline, and animated pulsing train position dot
- `StationTimelineView` — vertical stop timeline with platform badges and delay indicators
- `StatsView` — hero metric cards, on-time progress bar, streak tracker, operator breakdown
- `SocialView` — friends' active trip feed with operator colours and arrival countdown
- `AddTripView` — operator picker, form fields, and validation sheet
- `OnboardingView` — 4-page animated onboarding with spring entrance animations
- `StatusBadge` and `DelayBanner` reusable components
- Full `Assets.xcassets` dark-mode colour palette (AccentBlue, AccentGreen, AccentAmber, AccentRed, Background, Surface, SurfaceHigh, TextPrimary, TextSecondary, TextTertiary)
