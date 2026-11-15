package com.example.omni_cart_app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import kotlin.random.Random

class MainActivity : FlutterActivity() {
    private val posChannelName = "com.safeer.omnicart/pos_hardware"
    private val telemetryChannelName = "com.safeer.omnicart/inventory_telemetry"

    private var telemetryEventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private var telemetryRunnable: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, posChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanUpcBarcode" -> {
                    val sampleUpcs = listOf(
                        "079452389101",
                        "079452389102",
                        "079452389103",
                        "079452389104",
                        "079452389105",
                        "079452389106"
                    )
                    val scannedUpc = sampleUpcs[Random.nextInt(sampleUpcs.size)]
                    val payload = mapOf(
                        "status" to "SUCCESS",
                        "barcode" to scannedUpc,
                        "symbology" to "UPC-A / EAN-13",
                        "timestamp" to System.currentTimeMillis(),
                        "hardwareSource" to "OmniCart Optical Laser Imager"
                    )
                    result.success(payload)
                }
                "initiateNfcTapPayment" -> {
                    val amount = call.argument<Double>("amount") ?: 0.0
                    val currency = call.argument<String>("currency") ?: "USD"
                    val terminalId = "NFC-POS-TER-" + Random.nextInt(1000, 9999)
                    val txnId = "TXN-" + UUID.randomUUID().toString().substring(0, 8).uppercase()
                    val response = mapOf(
                        "status" to "APPROVED",
                        "transactionId" to txnId,
                        "terminalId" to terminalId,
                        "amount" to amount,
                        "currency" to currency,
                        "authCode" to "AUTH-" + Random.nextInt(100000, 999999),
                        "cardNetwork" to "Visa OmniTap Contactless EMV",
                        "timestamp" to System.currentTimeMillis()
                    )
                    result.success(response)
                }
                "printThermalReceiptPayload" -> {
                    val orderId = call.argument<String>("orderId") ?: "ORD-0001"
                    val printResult = mapOf(
                        "status" to "PRINTED",
                        "receiptJobId" to "THM-" + Random.nextInt(10000, 99999),
                        "orderId" to orderId,
                        "feedMm" to 120,
                        "cutterState" to "PARTIAL_CUT_COMPLETE",
                        "timestamp" to System.currentTimeMillis()
                    )
                    result.success(printResult)
                }
                "verifyDarkStoreInventory" -> {
                    val sku = call.argument<String>("sku") ?: "SKU-GENERIC"
                    val verification = mapOf(
                        "status" to "IN_STOCK",
                        "sku" to sku,
                        "shelfLocation" to "Aisle 3, Shelf B2 (Cold-Zone)",
                        "stockCount" to Random.nextInt(12, 58),
                        "lastCycleCountMinutesAgo" to Random.nextInt(3, 25),
                        "timestamp" to System.currentTimeMillis()
                    )
                    result.success(verification)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, telemetryChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    telemetryEventSink = events
                    startTelemetryStream()
                }

                override fun onCancel(arguments: Any?) {
                    stopTelemetryStream()
                    telemetryEventSink = null
                }
            }
        )
    }

    private fun startTelemetryStream() {
        telemetryRunnable = object : Runnable {
            override fun run() {
                val telemetryData = mapOf(
                    "activePickers" to Random.nextInt(6, 18),
                    "averagePackTimeSeconds" to Random.nextInt(38, 72),
                    "coldZoneTempCelsius" to (3.8 + (Random.nextDouble() * 0.8 - 0.4)),
                    "nfcTerminalReady" to true,
                    "liveSkuPulse" to Random.nextInt(140, 260),
                    "warehouseZone" to "Lahore Central Dark-Store A1",
                    "timestamp" to System.currentTimeMillis()
                )
                telemetryEventSink?.success(telemetryData)
                handler.postDelayed(this, 2000)
            }
        }
        handler.post(telemetryRunnable!!)
    }

    private fun stopTelemetryStream() {
        telemetryRunnable?.let { handler.removeCallbacks(it) }
        telemetryRunnable = null
    }

    override fun onDestroy() {
        stopTelemetryStream()
        super.onDestroy()
    }
}
