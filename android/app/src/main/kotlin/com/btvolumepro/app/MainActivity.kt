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

                    // ── Dispositivos ──────────────────────────────────────────────────

                    "getConnectedDevices" -> {
                        try { result.success(btVolumeManager.getConnectedDevices()) }
                        catch (e: Exception) { result.error("BT_ERROR", e.message, null) }
                    }

                    // ── Volumen Android (barra Android de la UI) ──────────────────────
                    // Siempre toca STREAM_MUSIC.
                    // Con AV ON: también sincroniza al BT.
                    // Con AV OFF: SOLO mueve barra Android, DAC queda independiente.

                    "getAndroidVolume" -> result.success(btVolumeManager.getAndroidVolume())
                    "getMaxVolume"     -> result.success(btVolumeManager.getMaxVolume())
                    "setAndroidVolume" -> {
                        val level = call.argument<Int>("level") ?: 0
                        result.success(btVolumeManager.setAndroidVolume(level))
                    }

                    // ── Volumen BT virtual (cuando AV OFF) ────────────────────────────
                    // getBtVolume / setBtVolume manejan el contador interno 0–100.
                    // Este valor es lo que la barra BT de la UI muestra en modo independiente.

                    "getBtVolume"    -> result.success(btVolumeManager.getBtVolume())
                    "getBtMaxVolume" -> result.success(btVolumeManager.getBtMaxVolume())
                    "setBtVolume" -> {
                        val level = call.argument<Int>("level") ?: 50
                        btVolumeManager.setBtVolume(level)
                        result.success(true)
                    }

                    // ── Botones BT de la app (VOL UP / VOL DOWN) ──────────────────────
                    //
                    // Con AV OFF:
                    //   adjustStreamVolume(flags=0) → sin overlay, sin AVRCP Absolute sync.
                    //   STREAM_MUSIC cambia localmente. El DAC NO recibe el cambio.
                    //   La barra BT virtual se incrementa/decrementa internamente.
                    //
                    // Con AV ON:
                    //   adjustStreamVolume(flags=0) → STREAM_MUSIC + BT sincronizan.

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

                    // ── Controles de reproducción ─────────────────────────────────────

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

                    // ── Mute / Unmute ─────────────────────────────────────────────────

                    "sendMute"   -> result.success(avrcpController.sendMute())
                    "sendUnmute" -> result.success(avrcpController.sendUnmute())

                    // ── Operaciones avanzadas ─────────────────────────────────────────

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

                    // ── Absolute Volume ───────────────────────────────────────────────

                    "setAbsoluteVolume" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        result.success(btVolumeManager.setAbsoluteVolume(enabled))
                    }
                    "getAbsoluteVolumeEnabled" -> result.success(btVolumeManager.getAbsoluteVolumeEnabled())

                    // ── Bluetooth toggle ──────────────────────────────────────────────

                    "toggleBluetooth" -> result.success(btVolumeManager.toggleBluetooth())

                    // ── Developer Options ─────────────────────────────────────────────

                    "openDeveloperOptions" -> {
                        try {
                            val intent = android.content.Intent(android.provider.Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        btVolumeManager.cleanup()
    }
}
