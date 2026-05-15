package com.btvolumepro.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.btvolumepro/bluetooth"
    private lateinit var btVolumeManager: BluetoothVolumeManager
    private lateinit var avrcpController: AVRCPController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        btVolumeManager = BluetoothVolumeManager(this)
        avrcpController = AVRCPController(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "getConnectedDevices" -> {
                        try { result.success(btVolumeManager.getConnectedDevices()) }
                        catch (e: Exception) { result.error("BT_ERROR", e.message, null) }
                    }

                    "getAndroidVolume" -> result.success(btVolumeManager.getAndroidVolume())
                    "getMaxVolume"     -> result.success(btVolumeManager.getMaxVolume())
                    "setAndroidVolume" -> {
                        val level = call.argument<Int>("level") ?: 0
                        result.success(btVolumeManager.setAndroidVolume(level))
                    }

                    // Botones de volumen - ahora usan AVRCP PassThrough cuando hay address
                    // Simula exactamente presionar el botón físico del dispositivo BT
                    "sendVolumeUp" -> {
                        val address = call.argument<String>("address")
                        val ok = if (!address.isNullOrEmpty()) {
                            btVolumeManager.sendAvrcpPassThrough(address, BluetoothVolumeManager.AVRCP_VOL_UP)
                        } else {
                            avrcpController.sendVolumeUp()
                        }
                        result.success(ok)
                    }
                    "sendVolumeDown" -> {
                        val address = call.argument<String>("address")
                        val ok = if (!address.isNullOrEmpty()) {
                            btVolumeManager.sendAvrcpPassThrough(address, BluetoothVolumeManager.AVRCP_VOL_DOWN)
                        } else {
                            avrcpController.sendVolumeDown()
                        }
                        result.success(ok)
                    }

                    // Controles de reproducción via AVRCP PassThrough
                    "sendPlay" -> {
                        val address = call.argument<String>("address") ?: ""
                        result.success(btVolumeManager.sendAvrcpPassThrough(address, BluetoothVolumeManager.AVRCP_PLAY))
                    }
                    "sendPause" -> {
                        val address = call.argument<String>("address") ?: ""
                        result.success(btVolumeManager.sendAvrcpPassThrough(address, BluetoothVolumeManager.AVRCP_PAUSE))
                    }
                    "sendNext" -> {
                        val address = call.argument<String>("address") ?: ""
                        result.success(btVolumeManager.sendAvrcpPassThrough(address, BluetoothVolumeManager.AVRCP_NEXT))
                    }
                    "sendPrev" -> {
                        val address = call.argument<String>("address") ?: ""
                        result.success(btVolumeManager.sendAvrcpPassThrough(address, BluetoothVolumeManager.AVRCP_PREV))
                    }

                    "sendMute"   -> result.success(avrcpController.sendMute())
                    "sendUnmute" -> result.success(avrcpController.sendUnmute())

                    "resyncVolume" -> result.success(btVolumeManager.resyncVolume())
                    "reconnectDevice" -> {
                        val address = call.argument<String>("address") ?: ""
                        result.success(btVolumeManager.reconnectDevice(address))
                    }
                    "resetBluetoothVolume" -> result.success(btVolumeManager.resetBluetoothVolume())
                    "recoverMutedDevice" -> {
                        val address = call.argument<String>("address") ?: ""
                        result.success(avrcpController.recoverMutedDevice(address))
                    }

                    "setAbsoluteVolume" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        result.success(btVolumeManager.setAbsoluteVolume(enabled))
                    }
                    "getAbsoluteVolumeEnabled" -> result.success(btVolumeManager.getAbsoluteVolumeEnabled())

                    "toggleBluetooth" -> result.success(btVolumeManager.toggleBluetooth())

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        btVolumeManager.cleanup()
    }
}
