# RailTrack Roadmap

A high-level view of where RailTrack is headed. Items are roughly ordered by priority within each section.

---

## ✅ Foundation (Complete)

- [x] Xcode project scaffold (iOS 17+, SwiftUI)
- [x] Core data models: Trip, Station, Stop, Alert, TrainService
- [x] Design system: dark-mode colour palette, typography scale, operator branding
- [x] All core screens with mock data: Home, Trip Detail, Stats, Social, Add Trip, Onboarding
- [x] MapKit integration with animated train position marker
- [x] Git repo + initial commit

---

## ✅ Local Persistence & Core UX (Complete)

- [x] SwiftData `TripRecord` entity for on-device trip storage
- [x] `StationDatabase` with VIA Rail, Amtrak, and GO Transit station catalogue
- [x] `AddTripView` — operator picker, live station autocomplete, date validation, SwiftData insert
- [x] `HomeView` — `@Query` dashboard with active / upcoming / past sections and swipe-to-delete
- [x] `StatsView` — dynamic stats from real records (distance, streaks, on-time %, carrier breakdown)
- [x] Departure reminders via `UNUserNotificationCenter` — scheduled on add, cancelled on delete
- [x] `ShareLink` share sheet on Trip Detail with formatted trip summary
- [x] Smart map camera auto-fits to actual route distance with padding
- [x] `EditTripView` — full edit sheet with status picker (incl. delay minutes), station autocomplete, platform & notes
- [x] `TripDetailView` — edit, delete, and "Mark Arrived" actions; platform chip; notes section
- [x] Notification permission requested on first launch for existing users via `.task`

---

## 🔜 Cloud Sync & Auth

- [x] Enable iCloud sync compatibility (CloudKit-friendly SwiftData properties & defaults)
- [x] iCloud account state monitoring (`CloudKitService` status checking)
- [x] User profile settings dashboard (`SettingsView`) & local profile storage
- [ ] Store user profile details in CloudKit private database
- [ ] Test and validate CloudKit schema sync on physical device
- [ ] Optional: Supabase Auth for social features (friend graph only — private data stays in CloudKit)

---

## 🔜 Live Data

- [x] Schedule-based train position interpolation on MapKit (dynamic timer-driven updates)
- [ ] GTFS-RT feed integration (VIA Rail, Amtrak)
- [ ] Actual train position on map (from GTFS-RT `VehiclePosition` feed data)
- [ ] Real-time delay updates and platform change detection
- [ ] Push notifications for delays and platform changes (APNs)
- [ ] Live Activities + Dynamic Island (departure countdown, delay banner)
- [ ] Lock Screen widget (next stop, ETA)

---

## 🔜 Import & Intelligence

- [ ] Email forwarding parser (VIA Rail / Amtrak confirmation emails → auto trip creation)
- [ ] Calendar integration (import bookings from Apple Calendar)
- [ ] On-time prediction model (historical GTFS data)
- [ ] Auto delay compensation detection + guided claim flow (VIA Rail / EU rail)

---

## 🔜 Social

- [ ] Friend system (add by username / QR code)
- [ ] Privacy-first trip sharing (public / friends-only / private toggle)
- [ ] Real-time friend location on map (opt-in)
- [ ] Trip sharing sheet ("Find me on VIA 60")
- [ ] Group trips / travel companions

---

## 🔜 Stats & Gamification

- [ ] Route heatmap (MapKit overlay of all travelled routes)
- [ ] Full stats history and charts
- [ ] Leaderboards (friends, global)
- [ ] Achievements / badges (e.g. "Night Owl" for overnight trains)
- [ ] Year-in-review summary card

---

## 🔜 Expansion

- [ ] Crowdsourced tracking (phone as sensor when GTFS-RT unavailable)
- [ ] GO Transit GTFS-RT integration
- [ ] VIA Rail Corridor stations map
- [ ] Multi-modal connections (train → subway → bus handoff)
- [ ] Android / cross-platform (future consideration)
- [ ] Freemium model (free core + Pro subscription for Live Activities, social, advanced stats)
- [ ] Adopt iOS 26 Liquid Glass `.glassEffect()` for custom surfaces (tab bar & nav bar are automatic)

---

## 💡 Ideas Backlog (Unscheduled)

- Apple Watch complication
- CarPlay integration
- Siri shortcuts ("When is my next train?")
- iPad optimised layout
- TransitStats.FYI backend integration (shared stats engine)
- Timetable offline mode (GTFS static download)
- Bump minimum deployment target to iOS 26 once adoption reaches ~80%+
