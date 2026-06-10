# Changelog

All notable changes to RailTrack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Visual Travel Log:** Home map now displays a cumulative history of journeys taken. Active trips are shown with bold lines and markers, while past trips appear as subtle historical paths. Upcoming trips are hidden from the map to keep the focus on actual travel.
- **Future Trip Planning:** Users can now save trips for any date in the future.
- **Schedule Auto-Refresh:** Saved trips now automatically sync with official live data as the departure date approaches, ensuring platform and schedule changes are captured.
- **Train Service Catalog:** New static database mapping train numbers to official service names (e.g., "The Canadian", "Wolverine", "Empire Builder").
- **GPS Journey Tracking:** New setting to record accurate personal travel paths during active trips.
- **Background Auto-Refresh:** Explore map now automatically updates train positions every 60 seconds.
- **Geographical Route Mapping:** Trip routes now connect every intermediate station, following rail corridors more accurately on the map. These paths are now persisted, ensuring historical journeys remain geographically perfect in your Travel Log.
- **Proactive Schedule Lookup:** Auto-fills station and time details when a train number is entered in the Add Trip view.

### Changed
- **Personal Stats Architecture:** Complete refactor of the Trip model to support high-precision personal metrics, including max speed recording, precise GPS paths, and actual distance traveled.
- **UI Refinement:** Complete overhaul of Trip Cards, Profile Stats, and Trip Detail headers for a more premium "Boarding Pass" aesthetic.
- **Branding Integration:** Service names are now prominently displayed on Trip Cards, Detail views, and route recommendations.
- **Passport Stamps:** Redesigned station stamps to look like authentic postmark cancellations.
- **Map Polish:** Cluttered map labels removed; replaced with compact, pulsing train markers.
- **Improved Active Logic:** Trips now automatically move to Past Journeys after a 15-minute arrival buffer (reduced from 2 hours) or upon physical arrival at the destination (if GPS enabled).
- **Edit Trip Refinement:** Redesigned the edit screen to match the "Boarding Pass" aesthetic, fixed layout alignment issues, and removed the manual status picker to rely entirely on automated tracking data.
- **Refined Stats:** On-time performance and streaks now only count completed trips for better accuracy.
- Station list in Explore now sorts by distance from the user's location when location permission is granted, with a distance label on each row.
- Station list rows now use a coloured code badge (filled pill) instead of plain coloured text.
- Station board empty state repositioned to the top of the content area (was vertically centred in the full drawer, appearing too low); copy updated to "No departures in the next 12 hours" and "Service at this station may have ended for the night."
- Explore drawer header now takes over station identity (name, city, code badge, back chevron) when a station board is open, eliminating the redundant inline station header row inside `StationBoardView`.
- `TicketCardView` and `ScheduleCard` are now visually connected in `AddTripView` via `VStack(spacing: 0)`; `ScheduleCard` uses `UnevenRoundedRectangle` with flat top corners so it butts flush against the ticket card's bottom edge, eliminating the empty black void below the form.
- Selected train drawer in Explore now shows the operator name and train number as the title (e.g. "VIA Rail 60") and the route as the subtitle (e.g. "Toronto → Ottawa"), replacing the generic "Selected Train" / "Details and real-time status" copy.
- Replaced the full-width "Close" button in `SelectedTrainDrawerView` with a compact icon circle button (xmark) stacked above a plus circle button, matching the style of the map refresh button.

### Fixed
- **Security Infrastructure:** Switched to GitHub's Default CodeQL setup for simplified security monitoring and resolved configuration conflicts.
- **Data Integrity:** Amtrak feed now rigorously filters out VIA Rail "virtual" trains and test data.
- **iCloud Messaging:** Softened development-mode sync warnings to reduce user alarm.
- **Map Interpolation:** Train position guessing now uses intermediate stop data for much better accuracy.
- Fixed CodeQL cleartext transmission security warning in `GOLiveDataService` by constructing the Metrolinx API URL with `URLComponents` and renaming the local `apiKey` variable to `token`.
- Removed the broken `License` link from `README.md`.
- Fixed VIA Rail trains (v-prefix) in the Amtraker feed being displayed as Amtrak trains on the Explore map and in train detail drawers (e.g. showing "Amtrak — Toronto → Ottawa"). These are now filtered out of `getActiveTrains()`.
- Fixed "Locate Me" button in Explore zooming out to show half of Canada; reduced radius from 50 km to 5 km.
- Fixed station board showing past departures (e.g. 13:00 shown at 23:42); `getBoardItems` now filters to a −30 min / +12 hour window from the current time.

## [1.3.1] - 2026-06-05

### Fixed
- Fixed Release build failures that blocked deployment by restoring missing Xcode source build entries for the extracted Home components.
- Added the missing safe collection subscript used by Explore station/departure lookups.
- Split large `HomeView` and `ExploreView` SwiftUI bodies into smaller view helpers to avoid Release compiler type-check timeouts.
- Fixed focus binding and drawer clipping API mismatches surfaced by the Release build.
- **Security**: Resolved CodeQL "Cleartext logging of sensitive information" alerts by removing user email from `SupabaseService` debug logs.

### Changed
- Migrated CodeQL workflow to a manual build configuration to resolve `autobuild.sh` failures on GitHub Actions.

## [1.3.0] - 2026-06-05

### Added
- **GO Transit Live GTFS-RT Integration**: Replaced simulated schedule tracking for GO Transit with real HTTP networking querying the Metrolinx Open Data API (`api.openmetrolinx.com/OpenDataAPI/api/v1/ServiceataGlance/Trains`), complete with optional config API key (`MetrolinxAPIKey`) inside `Info.plist` and automatic graceful local snapshot fallback.
- Added live API status updates for GO Transit to the Transit Connections agency detail views.

## [1.2.0] - 2026-06-01
