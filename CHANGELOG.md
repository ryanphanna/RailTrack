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
- Notification permission also requested on next launch for users who were already onboarded before the feature was added
- Native `ShareLink` share sheet on Trip Detail with formatted trip summary text
- Smart map camera auto-fits to actual great-circle route distance (1.5× padding, 50 km floor)
- `EditTripView` — full edit sheet pre-populated from `TripRecord`; animated status picker with delay-minute stepper; station autocomplete; platform and notes fields; reschedules departure notification on save
- `TripDetailView` now accepts `TripRecord` directly; added edit (pencil) and delete (trash) toolbar actions with confirmation dialog; "Mark Arrived" quick-action button for active trips; "Mark Completed" for upcoming trips; platform chip; notes card
- Persistent `UserProfile` storage (username and display name) backed by `UserDefaults`
- `SettingsView` containing profile adjustments, iCloud sync toggle, real-time CloudKit status monitor, and data clearing actions
- `ICloudBannerView` warning indicator presented at the top of the Home view when the iCloud account status is unavailable
- Real-time schedule-based train coordinate interpolation in `LiveMapView` based on current progress along the route
- Autoconnected 10-second timer to dynamically advance the train position on MapKit
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

### Changed
- `HomeView` ViewModel replaced with `@Query` + pure computed properties (no more `ObservableObject`)
- `HomeView` now iterates over `TripRecord` arrays directly and passes `TripRecord` to `TripDetailView`
- `TripDetailView` accepts `TripRecord` (derives `Trip` internally via `toTrip()`) instead of a `Trip` value type
- `StatsView` no longer depends on `MockDataService`
- Form helper components (`StationPickerField`, `FormCard`, `FormRow`, `FieldLabel`) refactored out of `AddTripView.swift` and moved to a dedicated, shared [FormComponents.swift](file:///Users/ryan/Desktop/Dev/Coding/Long-Term/In%20Development/RailTrack/RailTrack/Views/Components/FormComponents.swift)
- Converted `HomeView` layout from `ScrollView` + `LazyVStack` to a native SwiftUI `List` with clear rows, resolving non-functional `.swipeActions`
- Fixed hardcoded operator title "VIA" inside delay notifications in `NotificationService` to dynamically use the trip's operator name


