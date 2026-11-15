# OmniCart

[![OmniCart Enterprise CI/CD Pipeline](https://github.com/Safeer-Hussain/omnicart/actions/workflows/ci.yml/badge.svg)](https://github.com/Safeer-Hussain/omnicart/actions/workflows/ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart)](https://dart.dev)
[![Android Target](https://img.shields.io/badge/Android%20SDK-36-3DDC84?logo=android)](https://developer.android.com)
[![Platform Support](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

OmniCart is an enterprise omni-channel e-commerce and micro-fulfillment platform developed in Flutter. It unifies hyper-local 15-minute dark-store fulfillment, native in-store point-of-sale (POS) hardware integration via Kotlin and Swift platform channels, real-time courier route tracking (`flutter_map`), and an on-device AI shopping assistant and merchant copilot.

---

## Architecture Overview

OmniCart is structured around Feature-First Clean Architecture combined with Model-View-ViewModel (MVVM) and Riverpod state management. Each functional domain is strictly decoupled into independent layers:

```mermaid
graph TD
    subgraph Presentation_Layer [Presentation Layer: MVVM + Riverpod]
        UI[Views & Widgets]
        NOTIFIER[Riverpod Notifiers]
        STATE[Immutable State Models]
        UI -->|Events / Intents| NOTIFIER
        NOTIFIER -->|Emits New State| STATE
        STATE -->|Rebuilds| UI
    end

    subgraph Domain_Layer [Domain Layer: Pure Dart & Business Rules]
        USECASE[Use Cases / Facades]
        REPO_INTERFACE[Repository Interfaces]
        ENTITY[Entities]
        NOTIFIER --> REPO_INTERFACE
        USECASE --> REPO_INTERFACE
    end

    subgraph Data_Layer [Data Layer: Persistence & Network]
        REPO_IMPL[Repository Implementations]
        LOCAL_DB[SQLite Database Helper]
        INTERCEPTOR[Dio Mock Network Interceptor]
        REPO_INTERFACE -.->|Implemented By| REPO_IMPL
        REPO_IMPL --> LOCAL_DB
        REPO_IMPL --> INTERCEPTOR
    end

    subgraph Hardware_Bridge [Platform Channels: Native POS Hardware]
        METHOD_CHAN[MethodChannel: pos_hardware]
        EVENT_CHAN[EventChannel: inventory_telemetry]
        NATIVE_ANDROID[Android Kotlin MainActivity]
        NATIVE_IOS[iOS Swift AppDelegate]
        REPO_IMPL --> METHOD_CHAN
        NOTIFIER --> EVENT_CHAN
        METHOD_CHAN --> NATIVE_ANDROID
        METHOD_CHAN --> NATIVE_IOS
        EVENT_CHAN --> NATIVE_ANDROID
        EVENT_CHAN --> NATIVE_IOS
    end
```

---

## Riverpod State Flow & Persistence Cycle

```mermaid
sequenceDiagram
    autonumber
    actor User as Shopper / Cashier
    participant View as Presentation View
    participant Notifier as Riverpod Notifier
    participant Database as Local SQLite (sqflite)
    participant Platform as Native Platform Channel

    User->>View: Add Item to Cart / Scan Barcode
    alt Physical Barcode Scan
        View->>Notifier: scanUpcBarcode()
        Notifier->>Platform: invokeMethod('scanUpcBarcode')
        Platform-->>Notifier: UPC Barcode Payload
        Notifier->>Database: Query Product by UPC
        Database-->>Notifier: Matched Product Entity
    else In-App UI Mutation
        View->>Notifier: incrementQuantity(itemId)
    end
    Notifier->>Database: Upsert Item / Order State
    Database-->>Notifier: DB Success Confirmation
    Notifier->>View: State = State.copyWith(...) (Triggers Instant Rebuild)
    View-->>User: Updated UI (Badge, Subtotal, Feedback SnackBar)
```

---

## Native Retail POS Hardware Bridge

OmniCart communicates directly with Android (`MainActivity.kt`) and iOS (`AppDelegate.swift`) through dedicated platform channels without reliance on paid third-party SDKs.

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter Presentation Layer
    participant Bridge as PosHardwareBridge
    participant Android as Android Kotlin Engine
    participant iOS as iOS Swift Engine

    Note over App,iOS: 1. Native UPC Barcode Scanning
    App->>Bridge: scanUpcBarcode()
    alt Android
        Bridge->>Android: MethodChannel: scanUpcBarcode
        Android-->>Bridge: {status: SUCCESS, barcode: 079452389101, format: EAN_13}
    else iOS
        Bridge->>iOS: MethodChannel: scanUpcBarcode
        iOS-->>Bridge: {status: SUCCESS, barcode: 079452389101, format: EAN_13}
    end
    Bridge-->>App: Barcode Result Payload

    Note over App,iOS: 2. Contactless NFC Tap-to-Pay (ISO/IEC 14443 EMV)
    App->>Bridge: initiateNfcTapPayment(amount, currency)
    alt Android
        Bridge->>Android: MethodChannel: initiateNfcTapPayment
        Android-->>Bridge: {status: APPROVED, authCode: AUTH-882140, cardNetwork: Visa}
    else iOS
        Bridge->>iOS: MethodChannel: initiateNfcTapPayment
        iOS-->>Bridge: {status: APPROVED, authCode: AUTH-882140, cardNetwork: Visa}
    end
    Bridge-->>App: Authorization Confirmation

    Note over App,iOS: 3. Continuous Dark-Store Fulfillment Telemetry
    Android-->>Bridge: EventChannel: {activePickers: 14, tempC: 3.7, packTimeSec: 48}
    iOS-->>Bridge: EventChannel: {activePickers: 14, tempC: 3.7, packTimeSec: 48}
    Bridge-->>App: StreamSubscription updates UI Telemetry Strip every 2000ms
```

---

## Feature Matrix

| Capability | OmniCart Platform | Standard E-Commerce Apps |
| :--- | :--- | :--- |
| **Catalog Discovery** | 24+ SKUs across 5 core categories with real-time stock and cold-zone coordinates | Static remote catalog without shelf indexing |
| **Micro-Fulfillment** | 15-minute quick-commerce delivery simulation with dynamic ETA stepper | Standard 3-5 business day shipping estimates |
| **POS Barcode Scanner** | Native camera/hardware reticle with laser pulse and UPC matching | None or third-party paid camera wrapper |
| **Contactless NFC POS** | EMV contactless simulation via native Kotlin and Swift bridges | Web-redirect payment gateways only |
| **Thermal Receipts** | ESC/POS printable raw byte payload generation for thermal receipt printers | Email receipts only |
| **Dark-Store Telemetry** | 2-second streaming telemetry for pickers, pack times, and cold-zone temperature | Static warehouse inventory synchronization |
| **Live Route Tracking** | Interactive OpenStreetMap (`flutter_map`) with polyline bearing and live courier marker | Static map snapshot or external map app redirect |
| **On-Device AI Copilot** | Natural language intent processor for catalog search and restock queries | Remote chatbot requiring recurring paid subscriptions |
| **Data Analytics** | Responsive edge-to-edge `fl_chart` for spend and savings trends | External dashboard or basic text summary |
| **Offline First** | Full `sqflite` persistence across catalog, orders, cart items, and reviews | Screen freezes or displays blank error states |
| **Landscape Ergonomics** | 360dp height adaptive layout with scrollable navigation rail and compressed app bar | Bottom navigation overflow stripes and cut-off content |
| **Theme Engine** | Obsidian Commerce Dark and Crisp Retail Light with zero hardcoded colors | Fixed single theme or partial dark mode support |

---

## Viewport Safety & Landscape Ergonomics (360dp Height Safe)

OmniCart provides robust responsiveness down to a 360dp height viewport (standard mobile landscape):
- **Adaptive Navigation Rail**: On landscape mode, the bottom navigation bar is replaced with a compact, vertically scrollable `NavigationRail` wrapped in an `IntrinsicHeight` container to prevent vertical overflows.
- **Compressed App Bar**: Top app bar height dynamically reduces to `toolbarHeight: 36` with micro-typography.
- **Explicit Grid Extents**: All catalog and cart grids enforce explicit `mainAxisExtent` (e.g. `145dp`) rather than collapsing aspect ratios, eliminating `RenderFlex` overflow errors.
- **Independent Panes**: Master-detail layouts utilize independent scroll controllers for left and right viewports.

---

## Clean-Room Engineering & NDA Compliance Notice

All business logic, platform bridge implementations, schema models, and mock datasets within OmniCart have been authored under strict clean-room engineering principles. No proprietary APIs, production trade secrets, or copyrighted third-party assets are utilized. All brand representations and product entities are synthetic demonstrations designed to illustrate enterprise architectural competencies.
