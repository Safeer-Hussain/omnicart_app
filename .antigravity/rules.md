# OmniCart Architectural & Autonomous Engineering Rules

## 1. Executive Principles & Anti-AI Hygiene
- ZERO Emojis: Never emit emojis anywhere in the codebase, comments, UI text, error messages, debug output, test descriptions, or git commit messages.
- ZERO Stubs or Placeholders: Never write `// TODO`, `// FIXME`, `/* tutorial */`, or dummy mock callbacks. All buttons, bottom sheets, scanners, cart steppers, route animations, and promo handlers must be 100% functional.
- Zero Hardcoded Colors: All presentation widgets must resolve colors exclusively from `Theme.of(context).colorScheme` or custom theme extensions. Never use `Colors.white`, `Colors.black`, or raw hex `Color(0xFF...)` in UI widgets.

## 2. 6-Phase Autonomous Sprint Engine
Every automated sprint or task execution must sequentially execute and verify the following 6 phases:

### Phase 1: Architecture Invariant Validation & Analysis Gate
- Run `flutter analyze --no-fatal-infos` with zero warnings, zero deprecation failures, and zero errors.
- Enforce Feature-First Clean Architecture (`core/`, `data/`, `domain/`, `presentation/`).
- State management must adhere to Riverpod `NotifierProvider` / `AsyncNotifierProvider` coupled with `get_it` dependency injection.

### Phase 2: Automated Test Matrix Execution & Verification
- Execute `dart run tool/sprint_gate.dart`.
- Maintain a minimum of 25+ automated unit, repository, and widget tests.
- Verify `SharedPreferences.setMockInitialValues({})` in all test fixtures.

### Phase 3: Native Hardware Bridge & Platform Check
- Verify Android (`MainActivity.kt`) and iOS (`AppDelegate.swift`) platform channels:
  - `MethodChannel('com.safeer.omnicart/pos_hardware')`
  - `EventChannel('com.safeer.omnicart/inventory_telemetry')`
- Ensure compileSdk = 36, targetSdk = 36, and minSdk = 21 in `android/app/build.gradle.kts`.
- Validate Impeller disable flags (`io.flutter.embedding.android.EnableImpeller = false`) for GPU stability.

### Phase 4: Responsive & Visual Ergonomics Audit
- Verify Landscape mode compatibility down to 360dp viewport height.
- Ensure all `FloatingActionButton` widgets possess explicit, unique `heroTag` attributes.
- Ensure all modal bottom sheets include `isScrollControlled: true` and keyboard-aware padding.

### Phase 5: Offline-First & Data Sync Integrity Audit
- Verify `sqflite` persistence across catalog, orders, cart items, delivery addresses, and reviews.
- Mock network interceptor latency must remain configurable with simulated offline failovers.

### Phase 6: Git Hygiene, Documentation & Continuous Integration Audit
- Commit messages must follow Conventional Commits format with strictly zero emojis.
- Automated CI pipeline must pass on GitHub Actions (`.github/workflows/ci.yml`).
