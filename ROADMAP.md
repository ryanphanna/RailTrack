# RailTrack Roadmap

A high-level view of where RailTrack is headed. Items are roughly ordered by priority within each phase.

---

## ✅ Phase 0 — Foundation (Complete)

- [x] Xcode project scaffold (iOS 17+, SwiftUI)
- [x] Core data models: Trip, Station, Stop, Alert, TrainService
- [x] Design system: dark-mode colour palette, typography scale, operator branding
- [x] All core screens with mock data: Home, Trip Detail, Stats, Social, Add Trip, Onboarding
- [x] MapKit integration with animated train position marker
- [x] Git repo + initial commit

---

## 🔜 Phase 1 — Backend & Auth

- [ ] Supabase project setup (PostgreSQL schema)
- [ ] Supabase Swift SDK via SPM
- [ ] Email + password sign-up / sign-in
- [ ] Persist trips to Supabase `trips` table
- [ ] User profile creation on sign-up
- [ ] Row-level security policies
- [ ] Pull real trips from DB on Home screen (replacing mock data)

---

## 🔜 Phase 2 — Live Data

- [ ] GTFS-RT feed integration (VIA Rail, Amtrak)
- [ ] Real-time delay updates via Supabase Realtime subscriptions
- [ ] Actual train position on map (from GTFS-RT `VehiclePosition`)
- [ ] Platform / track change detection
- [ ] Push notifications for delays and platform changes (APNs)
- [ ] Live Activities + Dynamic Island (departure countdown, delay banner)
- [ ] Lock Screen widget (next stop, ETA)

---

## 🔜 Phase 3 — Import & Intelligence

- [ ] Email forwarding parser (VIA Rail / Amtrak confirmation emails → auto trip creation)
- [ ] Calendar integration (import bookings from Apple Calendar)
- [ ] On-time prediction model (historical GTFS data)
- [ ] Auto delay compensation detection + guided claim flow (VIA Rail / EU rail)

---

## 🔜 Phase 4 — Social

- [ ] Friend system (add by username / QR code)
- [ ] Privacy-first trip sharing (public / friends-only / private toggle)
- [ ] Real-time friend location on map (opt-in)
- [ ] Trip sharing sheet ("Find me on VIA 60")
- [ ] Group trips / travel companions

---

## 🔜 Phase 5 — Stats & Gamification

- [ ] Route heatmap (MapKit overlay of all travelled routes)
- [ ] Full stats history and charts
- [ ] Leaderboards (friends, global)
- [ ] Achievements / badges (e.g. "Night Owl" for overnight trains)
- [ ] Year-in-review summary card

---

## 🔜 Phase 6 — Expansion

- [ ] Crowdsourced tracking (phone as sensor when GTFS-RT unavailable)
- [ ] GO Transit GTFS-RT integration
- [ ] VIA Rail Corridor stations map
- [ ] Multi-modal connections (train → subway → bus handoff)
- [ ] Android / cross-platform (future consideration)
- [ ] Freemium model (free core + Pro subscription for Live Activities, social, advanced stats)

---

## 💡 Ideas Backlog (Unscheduled)

- Apple Watch complication
- CarPlay integration
- Siri shortcuts ("When is my next train?")
- iPad optimised layout
- TransitStats.FYI backend integration (shared stats engine)
- Timetable offline mode (GTFS static download)
