# Changelog

All notable changes to RailTrack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial Xcode project scaffold targeting iOS 17+
- Core data models: `Trip`, `Station`, `TrainAlert`, `TrainService`, `Stop`
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
