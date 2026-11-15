# OmniCart - Gemini AI Assistant Context & Architectural Guide

## Project Summary
OmniCart is an enterprise omni-channel e-commerce, 15-minute quick-commerce fulfillment, native barcode & NFC POS hardware bridge, live courier route tracking (`flutter_map`), and on-device AI shopping copilot platform built in Flutter.

- GitHub Repository: https://github.com/Safeer-Hussain/omnicart
- Architecture: Clean Architecture + Feature-First MVVM + Riverpod (`NotifierProvider`) + `get_it` DI.
- Offline Persistence: Local `sqflite` relational storage with cached catalog, carts, orders, and addresses.
- Native Bridges:
  - Android: `android/app/src/main/kotlin/com/example/omni_cart_app/MainActivity.kt`
  - iOS: `ios/Runner/AppDelegate.swift`

## Quality Gates & Tooling
- Sprint Gatekeeper: `dart run tool/sprint_gate.dart`
- Formatter: `dart format lib test tool`
- Static Analysis: `flutter analyze --no-fatal-infos`
- Test Runner: `flutter test`

## Strict Development Rules
1. Zero Emojis in any source code, UI strings, logs, or commit messages.
2. Zero hardcoded colors: Always use `Theme.of(context).colorScheme`.
3. Unique `heroTag` on all `FloatingActionButton` instances.
4. Android SDK 36: `compileSdk = 36`, `targetSdk = 36`, `minSdk = 21` in `android/app/build.gradle.kts`.
5. Impeller disabled for MediaTek/Mali physical device stability.
6. 6-Phase Autonomous Sprint Engine enforced on every enhancement.
