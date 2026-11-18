# OmniCart Autonomous Engineering Backlog (25-Sprint Roadmap)

This backlog defines the 25 granular engineering sprints executed autonomously by the engineering engine.

## Phase 1: Core Foundation, Hardware Bridges & Architecture
- [x] **Sprint 01: Project Setup & Android SDK 36 Baseline**
  - Direct root layout (`lib/`, `test/`, `android/`, `ios/`, `assets/`, `tool/`).
  - Android Gradle SDK 36 (`compileSdk = 36`, `targetSdk = 36`, `minSdk = 21`).
  - Impeller Vulkan crash defense configuration in `AndroidManifest.xml`.
- [x] **Sprint 02: Native POS & Inventory Hardware Bridges**
  - Implement Kotlin `MethodChannel('com.safeer.omnicart/pos_hardware')` in `MainActivity.kt`.
  - Implement Kotlin `EventChannel('com.safeer.omnicart/inventory_telemetry')` in `MainActivity.kt`.
  - Implement Swift platform channel parity in `AppDelegate.swift`.
- [x] **Sprint 03: Design System, Theming & Iconography**
  - Obsidian Commerce Dark & Crisp Retail Light themes in `AppTheme`.
  - Zero hardcoded colors policy via `Theme.of(context).colorScheme`.
  - Vector icon asset generation and launcher icon configuration.
- [x] **Sprint 04: Local SQLite Persistence & Dependency Injection**
  - Relational `sqflite` database schemas for products, cart, orders, and addresses.
  - Service locator setup with `get_it`.
  - `SharedPreferences` integration for persistent theme and session preferences.
- [x] **Sprint 05: Mock Network Interceptor & Offline Resilience**
  - Configurable latency (400ms-850ms) `Dio` interceptor.
  - Offline network detection with `connectivity_plus`.
  - Automated offline state banner and retry orchestration.

## Phase 2: Catalog Discovery, Search & Category Navigation
- [x] **Sprint 06: Seeded Multi-Category Catalog Engine**
  - 24+ enterprise SKUs across 5 core commerce categories.
  - Product specs, UPC barcodes, cold-zone shelf locations, and review aggregates.
- [x] **Sprint 07: Reactive Catalog Notifier & Search Filter**
  - Riverpod `CatalogNotifier` with immutable state mutations.
  - Instant text query filter and horizontal category pill selector.
- [x] **Sprint 08: Product Cards & Responsive Grid Architecture**
  - Master-detail product cards with explicit `mainAxisExtent`.
  - Wishlist heart toggle with instant SQLite synchronization.
- [x] **Sprint 09: Modal Product Details & Variant Selection**
  - Full-featured detail sheet with image carousel and variant chips.
  - Real-time stock counter and shelf coordinate display.
- [x] **Sprint 10: Product Review System & Form Validation**
  - Interactive rating star selector and validated review submission.
  - Instant list update and local database persistence.

## Phase 3: Smart Cart, Promo Engine & Multi-Vendor Checkout
- [x] **Sprint 11: Cart State Management & Quantity Stepper**
  - Riverpod `CartNotifier` with atomic quantity increment/decrement.
  - Automatic subtotal, tax (8%), and dynamic delivery calculation.
- [x] **Sprint 12: Tiered Free Shipping Progress Bar**
  - Animated progress bar tracking eligibility towards free shipping threshold.
  - Real-time visual feedback upon reaching free shipping milestone.
- [x] **Sprint 13: Promo Code Engine & Discount Validation**
  - Validated promo engine supporting percentage and flat voucher discounts.
  - Immediate subtotal deductions and inline error handling.
- [x] **Sprint 14: Checkout Modal & Address Selector**
  - Delivery address management with default selection.
  - New address form with inline validation and database persistence.
- [x] **Sprint 15: Payment Flow & Order Creation**
  - Support for Credit Card, Apple/Google Pay, Cash on Delivery, and NFC POS Tap.
  - Atomic order generation and cart clearance upon checkout.

## Phase 4: Micro-Fulfillment, Live Courier Tracking & POS Scanner
- [x] **Sprint 16: Live OpenStreetMap Courier Route Tracking**
  - `flutter_map` integration with custom dark and light tile layers.
  - Live animated courier marker with bearing and polyline route visualization.
- [x] **Sprint 17: Fulfillment Status Stepper & ETA Countdown**
  - 5-stage fulfillment status stepper: Placed, Picking, Packed, In Transit, Delivered.
  - Real-time simulated courier progress advancement.
- [x] **Sprint 18: Digital Receipt & ESC/POS Thermal Printing**
  - Printable customer digital receipt modal with itemized ledger.
  - Hardware bridge call for thermal ESC/POS receipt generation.
- [x] **Sprint 19: Hardware Barcode Scanner & Laser Reticle View**
  - Fullscreen laser scanning reticle with animated pulse sweep.
  - Hardware UPC barcode lookup matching physical inventory.
- [x] **Sprint 20: Real-Time Dark-Store Telemetry Strip**
  - Live telemetry dashboard consuming `inventory_telemetry` EventChannel.
  - Active pickers count, cold-zone temp, and NFC terminal status indicators.

## Phase 5: On-Device AI Copilot, Analytics & Enterprise Release
- [x] **Sprint 21: Privacy-First AI Shopping Assistant Engine**
  - Local rule-based NLP intent parser for search, restock, and budget queries.
  - Token streaming simulation with guaranteed `finally` state cleanup.
- [x] **Sprint 22: Visual Spend & Savings Analytics**
  - Edge-to-edge bar chart visualization using `fl_chart`.
  - Adaptive layout with zero clipping on 360dp landscape viewports.
- [x] **Sprint 23: Recruiter Debug Drawer & Hardware Simulation**
  - Long-press activated diagnostic drawer with latency and error toggles.
  - Manual telemetry pulse injection and database purge utilities.
- [x] **Sprint 24: Comprehensive Automated Test Suite**
  - 27+ unit and widget tests covering all notifiers, bridges, and viewport modes.
  - Zero duplicate Hero tag verification across multi-tab shell.
- [x] **Sprint 25: CI/CD Pipeline & Enterprise Release Verification**
  - Automated GitHub Actions workflow (`.github/workflows/ci.yml`).
  - Sprint gatekeeper script (`tool/sprint_gate.dart`) enforcement.
  - Zero analyzer issues (`flutter analyze --no-fatal-infos`).

## Phase 6: Enterprise Expansion & Omni-Channel Telemetry (Sprints 26-30)
- [x] **Sprint 26: Multi-Store Dark-Store Route Geofencing & Dynamic Delivery ETA Prediction**
  - City-wide dark store network (`DarkStoreHub.networkHubs`) supporting Gulberg Central A1, DHA Phase 6 B2, and Johar Town C3.
  - Geodesic Haversine nearest-hub optimization algorithm (`HaversineUtil.findNearestDarkStore`).
  - Dynamic route bearing calculation (`HaversineUtil.bearingBetween`) with live courier navigation heading.
  - Integration into `OrderTrackerState` and `courier_map_view.dart` with origin hub badging and marker positioning.
  - Automated unit test suite (`test/unit/haversine_test.dart`) bringing test matrix to 33 automated tests.
- [x] **Sprint 27: Cold-Chain Telemetry Logging & Temperature Deviation Alerts**
  - Historical temperature logging in SQLite (`cold_chain_logs` table) for refrigerated perishables.
  - Automated alert trigger when cold-zone exceeds safety threshold (1.0°C - 4.0°C).
  - Visual deviation indicator and warning alert pill embedded in POS hardware `TelemetryStrip`.
  - Clean Architecture `ColdChainRepository` pattern registered in `get_it` DI and mocked for tests.
  - Automated test suite (`test/unit/cold_chain_repository_test.dart`) expanding automated matrix to 37 tests.
- [x] **Sprint 28: Multi-Currency Dynamic FX Sync & Offline Exchange Caching**
  - Dynamic currency conversion engine with cached offline FX rates for 4 global currencies (USD, EUR, GBP, PKR).
  - Relational `exchange_rates` SQLite storage schema and `FxRepository` Clean Architecture pattern registered in `get_it`.
  - Multi-currency cycle switcher integrated into `adaptive_scaffold.dart` and `recruiter_debug_drawer.dart`.
  - Automated test suite (`test/unit/fx_repository_test.dart`) expanding automated matrix to 44 tests.
- [ ] **Sprint 29: In-Store Self-Checkout Barcode Batch Cart Mode**
  - Bulk scanning queue in POS scanner for fast queue-busting in physical stores.
- [ ] **Sprint 30: End-to-End Enterprise Stress Testing & Offline Simulation**
  - Stress testing with 500+ simulated SKUs and synthetic network drops.
