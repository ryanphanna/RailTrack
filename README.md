# RailTrack

A premium real-time train tracking app for iOS — built for frequent rail travellers to analyze, track, and visualize personal train travel.

## Problem

Rail travellers have almost no personal tracking tools built for train transit. There is still no simple way to build and explore a detailed record of routes, stops, and travel patterns over time, let alone monitor live train GPS and delays on native Lock Screen and Dynamic Island widgets.

## Features

- **Live GPS Train Tracking**: Real-time position tracking, speed monitoring, and delay calculation for VIA Rail, Amtrak, and simulated GO Transit Lakeshore West routes.
- **Transit Passport Stamps**: A visual statistics logbook calculating total mileage, travel hours, operator breakdowns, and on-time streaks, unlocking concentric postmark cancellation stamps for each unique station visited.
- **Dynamic Island & Lock Screen Live Activities**: Active widgets displaying live countdowns, ETAs, and dynamically resolved next unvisited stations.
- **Offline-First SwiftData Storage**: On-device trip logbook persistence, fully editable with automatic departure alerts and reminders.

## Tech Stack

- **UI**: SwiftUI (iOS 17+)
- **Storage**: SwiftData
- **Live Widgets**: ActivityKit / WidgetKit
- **Maps**: MapKit (Apple Maps)
- **Notifications**: UserNotifications framework for departure reminders

## Getting Started

1. Open `RailTrack.xcodeproj` in Xcode 15+.
2. Select a simulator or target device running iOS 17+.
3. Build and run. No external backend is required.
