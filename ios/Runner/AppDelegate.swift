import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var telemetryTimer: Timer?
  private var telemetrySink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OmniCartHardwareBridge")
    let messenger = registrar.messenger()

    let methodChannel = FlutterMethodChannel(
      name: "com.safeer.omnicart/pos_hardware",
      binaryMessenger: messenger
    )

    methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "scanUpcBarcode":
        let sampleUpcs = [
          "079452389101",
          "079452389102",
          "079452389103",
          "079452389104",
          "079452389105",
          "079452389106"
        ]
        let scanned = sampleUpcs.randomElement() ?? "079452389101"
        result([
          "status": "SUCCESS",
          "barcode": scanned,
          "symbology": "UPC-A / EAN-13",
          "timestamp": Int(Date().timeIntervalSince1970 * 1000),
          "hardwareSource": "iOS CoreNFC / Vision Optical Imager"
        ])

      case "initiateNfcTapPayment":
        let args = call.arguments as? [String: Any]
        let amount = args?["amount"] as? Double ?? 0.0
        let currency = args?["currency"] as? String ?? "USD"
        result([
          "status": "APPROVED",
          "transactionId": "TXN-\(UUID().uuidString.prefix(8).uppercased())",
          "terminalId": "NFC-POS-IOS-\(Int.random(in: 1000...9999))",
          "amount": amount,
          "currency": currency,
          "authCode": "AUTH-\(Int.random(in: 100000...999999))",
          "cardNetwork": "Apple Pay / EMV Contactless",
          "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ])

      case "printThermalReceiptPayload":
        let args = call.arguments as? [String: Any]
        let orderId = args?["orderId"] as? String ?? "ORD-0001"
        result([
          "status": "PRINTED",
          "receiptJobId": "THM-\(Int.random(in: 10000...99999))",
          "orderId": orderId,
          "feedMm": 120,
          "cutterState": "PARTIAL_CUT_COMPLETE",
          "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ])

      case "verifyDarkStoreInventory":
        let args = call.arguments as? [String: Any]
        let sku = args?["sku"] as? String ?? "SKU-GENERIC"
        result([
          "status": "IN_STOCK",
          "sku": sku,
          "shelfLocation": "Aisle 3, Shelf B2 (Cold-Zone)",
          "stockCount": Int.random(in: 12...58),
          "lastCycleCountMinutesAgo": Int.random(in: 3...25),
          "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ])

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: "com.safeer.omnicart/inventory_telemetry",
      binaryMessenger: messenger
    )

    eventChannel.setStreamHandler(TelemetryStreamHandler(owner: self))
  }

  func startTelemetry(sink: @escaping FlutterEventSink) {
    telemetrySink = sink
    telemetryTimer?.invalidate()
    telemetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      let payload: [String: Any] = [
        "activePickers": Int.random(in: 6...18),
        "averagePackTimeSeconds": Int.random(in: 38...72),
        "coldZoneTempCelsius": 3.8 + Double.random(in: -0.4...0.4),
        "nfcTerminalReady": true,
        "liveSkuPulse": Int.random(in: 140...260),
        "warehouseZone": "Lahore Central Dark-Store A1",
        "timestamp": Int(Date().timeIntervalSince1970 * 1000)
      ]
      self?.telemetrySink?(payload)
    }
  }

  func stopTelemetry() {
    telemetryTimer?.invalidate()
    telemetryTimer = nil
    telemetrySink = nil
  }
}

class TelemetryStreamHandler: NSObject, FlutterStreamHandler {
  weak var owner: AppDelegate?

  init(owner: AppDelegate) {
    self.owner = owner
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    owner?.startTelemetry(sink: events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    owner?.stopTelemetry()
    return nil
  }
}
