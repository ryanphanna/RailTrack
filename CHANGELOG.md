# Changelog

All notable changes to RailTrack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Redesigned `StatsView` with a premium App in the Air-inspired boarding pass profile card and freeform scattered/overlapping passport stamps layout.
- Renamed the "Stats" tab and all associated view/source references to "Profile" (including `ProfileView.swift`), using a `person.crop.circle.fill` tab icon and navigation title.
- Redesigned `AddTripView` with a premium Train Ticket aesthetic, removing the top operator picker block and enabling automatic operator detection via selected stations or train prefix, with an interactive capsule menu to override manually.
- Redesigned `AddTripView` with a premium boarding pass connection line showing the train icon along a horizontal dashed track.
- Reorganized `AddTripView` date and time pickers side-by-side in a 2-column layout, removing redundant text labels.
- Structured the toolbar "Add" button into a well-padded capsule/pill to prevent collapsing into a squished circle.
- Cohesized the train number search and operator lookup into a unified input group with operator-themed find buttons.
- Redesigned `HomeView` with a full-screen interactive Map background showing all active/upcoming trip routes and a sliding bottom drawer panel peeking out for journey lists, mimicking premium travel apps.
- Made `StationMarker` and `TrainPositionMarker` internal to reuse them directly on the new Home screen background map.
- Added Route-to-Train suggestions card in `AddTripView` to present train recommendations when origin and destination stations are selected.
- Added sequential operator failover retry (trying Amtrak, GO, and VIA Rail sequentially) when looking up train schedules in `AddTripView`.
- Refreshed local schedule snapshots for Amtrak and VIA Rail with fresh data, specifically including trains 57 and 60.
- Added a brand-new **Explore** tab featuring an interactive live train map, nearby location-based departures board, searchable station schedule boards, and an active trains directory list.
- Integrated `CoreLocation` support to identify the closest station and display a "Departing Soon Nearby" horizontal carousel of trains departing in the next 3 hours.
- Created a dark LED split-flap style visual departures/arrivals layout for station boards in the Explore tab.

### Fixed
- Fixed a layout bug on `HomeView` where the bottom sliding panel floated in mid-air above the bottom tab bar and revealed a gap of map underneath by ignoring the bottom safe area and increasing list spacer height.
- Fixed strict date filtering in offline/snapshot schedule lookup by falling back to number-based matching when dates do not align.

## [1.0.0] - 2026-05-30

### Added
- GO Transit schedule autocompletes and simulated GTFS-RT live tracking using a local `go_snapshot.json` feed
- Upgraded `StatsView` with a premium Boarding Pass profile header card, travel hours tracking, and Train Passport Stamps collection displaying concentric postmark badges for visited stations
- DatePicker HStack row layout alignment improvements and plain button styling in `AddTripView` resolving system capsule button borders
- Amtrak Live GPS train position and speed tracking using the unofficial `api.amtraker.com/v3/trains` feed
- Real-time Amtrak delay minutes calculation based on arrival offsets at current or departed stations
- Cache for Amtrak live intermediate stops and timeline rendering in `TripDetailView`
- Live Activity stops resolution: Dynamic Island and Lock Screen widgets now show the next unvisited station name dynamically resolved from live stop feeds
- Fixed Amtrak station identifier prefix lookup (`AMT-` prefix alignment) in `AddTripView`
- VIA Rail Live GPS and Delay Tracking integration using `tsimobile.viarail.ca/data/allData.json`
- Amtrak Scheduled Service Timetable Lookup integration using the unofficial `api.amtraker.com/v3/trains` feed
- "Transit Connections" list and detail page (`AgenciesView`) in Settings displaying supported agencies, API features, and live statuses
- Live GPS annotations and segmented stop timelines rendering in `LiveMapView` and `TripDetailView`
- Dynamic schedule lookup pre-population feature in `AddTripView` supporting both VIA Rail and Amtrak trains
- SwiftData support for live coordinates (`liveLatitude`, `liveLongitude`, `liveSpeed`, `liveUpdated`) on `Trip` and `TripRecord`
- Active 30-second polling and scene phase active listeners in `ContentView` for real-time tracking updates
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

### Fixed
- Startup crash in `CloudKitService` when checking account status without valid iCloud entitlements on the simulator
- Overlapping navigation/tab elements by relocating the Home screen `+` (Add Trip) button to the navigation bar trailing and the Settings button to leading
- Form card layouts by adding standard 16pt padding to `FormCard` wrappers
- Text field placeholder legibility by applying custom colored prompts on dark form inputs


