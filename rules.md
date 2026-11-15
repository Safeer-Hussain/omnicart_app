# OmniCart Engineering Standards & Autonomous Rules

## 1. Zero Hardcoded Colors & Theme Parity
- All color values must be sourced from `Theme.of(context).colorScheme`.
- Support seamless real-time switching between Obsidian Commerce Dark and Crisp Retail Light themes.

## 2. Hero Tag Uniqueness
- Every `FloatingActionButton` must declare a distinct, explicit `heroTag` string to avoid runtime route transition collision.

## 3. Landscape Architecture (360dp Height Safety)
- On landscape viewports:
  - Navigation switches from bottom bar to a scrollable `NavigationRail`.
  - App bars compress to `toolbarHeight: 36`.
  - Grid views enforce `mainAxisExtent` instead of collapsing aspect ratios.
  - Multi-pane master-detail views utilize independent scroll controllers.

## 4. Native Hardware Bridge Parity
- Android Kotlin (`MainActivity.kt`) and iOS Swift (`AppDelegate.swift`) provide parity on:
  - `com.safeer.omnicart/pos_hardware`
  - `com.safeer.omnicart/inventory_telemetry`

## 5. Anti-AI Code Hygiene
- Never use emojis anywhere in code, strings, test outputs, or git commits.
- Never write placeholder comments or tutorial code.
- Always implement complete, working functionality.
