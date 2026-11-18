# Changelog

All notable changes to the OmniCart platform are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1+2] - 2026-11-18

### Added
- Multi-Currency Dynamic FX Engine supporting USD, EUR, GBP, and PKR.
- Local SQLite relational persistence for cached interbank exchange rates (`exchange_rates` table).
- Clean Architecture `FxRepository` with simulated live interbank rate synchronization.
- Seamless currency cycle toggle integrated into the adaptive scaffold and recruiter debug drawer.
- Unit test suite (`fx_repository_test.dart`) covering conversions, entity serialization, and state cycling.

### Changed
- Incremented build and release version to `1.0.1+2`.
- Updated autonomous backlog marking Sprint 28 complete (44 automated quality gate tests passing).

## [1.0.0+1] - 2026-11-15

### Added
- Initial release of OmniCart Enterprise Omni-Channel Fulfillment platform.
- Native POS & micro-fulfillment bridge for Android Kotlin (`MainActivity.kt`) and iOS Swift (`AppDelegate.swift`).
- MethodChannel `com.safeer.omnicart/pos_hardware` (UPC scanning, NFC tap-to-pay, thermal ESC/POS receipts).
- EventChannel `com.safeer.omnicart/inventory_telemetry` (2-second live streaming telemetry).
- Live courier route tracking using OpenStreetMap via `flutter_map` with dynamic bearing markers.
- Relational SQLite offline-first database (`sqflite`) for catalog, cart, orders, and addresses.
- On-device privacy-first AI shopping copilot and spend analytics (`fl_chart`).
- Dual theme support (Obsidian Commerce Dark and Crisp Retail Light) with zero hardcoded colors.
- 360dp landscape ergonomics with compact scrollable NavigationRail and master-detail panes.
