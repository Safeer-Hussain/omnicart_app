# OmniCart Enterprise Product Requirements Document (PRD)

## 1. Executive Summary & Product Vision
OmniCart is a high-performance enterprise omni-channel e-commerce and micro-fulfillment platform developed in Flutter. It seamlessly unifies:
- Instant 15-minute quick-commerce fulfillment powered by hyper-local dark-stores.
- In-store retail point-of-sale (POS) hardware capabilities via native Kotlin (Android) and Swift (iOS) bridges (UPC barcode laser reticle scanning, contactless EMV NFC tap-to-pay, ESC/POS thermal printing, and real-time inventory verification).
- Live courier dispatch and geospatial route tracking using OpenStreetMap via `flutter_map` with dynamic bearing markers, status steppers, and digital receipts.
- Privacy-first on-device AI shopping assistant and merchant copilot with natural language SKU querying, cart automation, and fl_chart spend analytics.
- Zero-cost offline-first resilience powered by `sqflite`, cached catalog sync, and mock network interceptors.

## 2. Key Personas & Use Cases

### 2.1 The Quick-Commerce Shopper
- Desires ultra-low friction discovery, multi-vendor cart consolidation, dynamic tier-based free shipping progress, instant promo application, and live courier tracking down to minute-by-minute ETA.

### 2.2 The In-Store Dark-Store Associate & Cashier
- Uses handheld mobile terminals to scan physical UPC barcodes on shelves, verify live batch stock counts in cold-zones, accept customer NFC tap payments, and print formatted ESC/POS thermal receipts.

### 2.3 The Regional Operations & Merchant Manager
- Analyzes dark-store throughput telemetry, monitor cold-zone temperature telemetry in real time, inspects courier dispatch queues, and utilizes AI copilot insights for predictive restock planning.

## 3. System Architecture & Tech Stack

### 3.1 Core Technologies
- Framework: Flutter 3.47+ / Dart 3.13+
- Target Platforms: Android (API 21 - 36), iOS (14.0+)
- State Management: Riverpod 2.6+ (`NotifierProvider`, `AsyncNotifierProvider`)
- Dependency Injection: `get_it` service locator
- Local Storage: `sqflite` relational SQLite database + `SharedPreferences`
- HTTP Client: `Dio` with custom mock latency and fault-injection interceptor
- Mapping & Geospatial: `flutter_map` with `latlong2`
- Data Visualization: `fl_chart` with adaptive landscape rendering

### 3.2 Data Schema

#### Products Table (`products`)
```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  priceUsd REAL NOT NULL,
  originalPriceUsd REAL,
  rating REAL NOT NULL,
  reviewCount INTEGER NOT NULL,
  imageUrl TEXT NOT NULL,
  description TEXT NOT NULL,
  specs TEXT NOT NULL,
  stockCount INTEGER NOT NULL,
  upcBarcode TEXT NOT NULL UNIQUE,
  shelfLocation TEXT NOT NULL,
  isQuickCommerceEligible INTEGER NOT NULL,
  isWishlisted INTEGER NOT NULL
);
```

#### Cart Items Table (`cart_items`)
```sql
CREATE TABLE cart_items (
  id TEXT PRIMARY KEY,
  productId TEXT NOT NULL,
  productName TEXT NOT NULL,
  unitPriceUsd REAL NOT NULL,
  quantity INTEGER NOT NULL,
  imageUrl TEXT NOT NULL,
  selectedVariant TEXT,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
);
```

#### Orders Table (`orders`)
```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  createdAtMillis INTEGER NOT NULL,
  status TEXT NOT NULL,
  totalAmountUsd REAL NOT NULL,
  deliveryFeeUsd REAL NOT NULL,
  discountAmountUsd REAL NOT NULL,
  itemCount INTEGER NOT NULL,
  courierName TEXT NOT NULL,
  courierPhone TEXT NOT NULL,
  courierLat REAL NOT NULL,
  courierLng REAL NOT NULL,
  courierProgress REAL NOT NULL,
  destinationAddress TEXT NOT NULL,
  estimatedDeliveryMinutes INTEGER NOT NULL
);
```

#### Delivery Addresses Table (`delivery_addresses`)
```sql
CREATE TABLE delivery_addresses (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  streetAddress TEXT NOT NULL,
  city TEXT NOT NULL,
  stateOrRegion TEXT NOT NULL,
  postalCode TEXT NOT NULL,
  isDefault INTEGER NOT NULL
);
```

## 4. Hardware Bridge Specifications

### 4.1 MethodChannel: `com.safeer.omnicart/pos_hardware`
- `scanUpcBarcode`: Triggers native camera/hardware laser engine and returns scanned UPC barcode payload.
- `initiateNfcTapPayment`: Invokes contactless NFC ISO/IEC 14443 EMV transaction flow, returning authorization code, terminal ID, and approval status.
- `printThermalReceiptPayload`: Formats ESC/POS raw bytes for thermal receipt printing including line items, tax breakdown, and barcode footers.
- `verifyDarkStoreInventory`: Verifies real-time SKU stock count, shelf coordinates, and cycle count age.

### 4.2 EventChannel: `com.safeer.omnicart/inventory_telemetry`
- Streams telemetry payloads every 2000ms:
  - `activePickers`: Active picking associates in dark-store.
  - `averagePackTimeSeconds`: Average assembly time per order.
  - `coldZoneTempCelsius`: Temperature sensor telemetry for refrigerated groceries.
  - `nfcTerminalReady`: POS peripheral readiness boolean.
  - `liveSkuPulse`: Real-time stock movement pulse index.
  - `warehouseZone`: Active fulfillment sector ID.

## 5. Non-Functional Requirements & Safety Invariants
- 100% Theme Parity: Support real-time dark/light mode toggling via `Theme.of(context).colorScheme` with zero hardcoded colors.
- 360dp Landscape Safety: Adaptive navigation rail, compressed app bar (36dp), independent scroll controllers, explicit `mainAxisExtent` on grid items, and full-bleed charts.
- Hero Tag Integrity: Every `FloatingActionButton` must have a unique identifier.
- Zero Emojis: Strict vector-based Material Symbols / Cupertino iconography across all presentations.
- Zero TODOs: Every user interaction must produce concrete, verified state mutations.
