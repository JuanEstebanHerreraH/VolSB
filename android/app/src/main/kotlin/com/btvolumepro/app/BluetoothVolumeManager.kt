package com.btvolumepro.app

import android.bluetooth.*
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent

/**
 * BluetoothVolumeManager — Separación REAL de volumen Android vs DAC Bluetooth.
 *
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║  ANÁLISIS TÉCNICO DEFINITIVO                                            ║
 * ╠══════════════════════════════════════════════════════════════════════════╣
 * ║  Con Absolute Volume (AV) ACTIVADO:                                     ║
 * ║    • Android y DAC están sinculados a nivel sistema.                    ║
 * ║    • adjustStreamVolume → STREAM_MUSIC cambia → AVRCP propaga al DAC.   ║
 * ║    • Comportamiento esperado: ambas barras = mismo valor.               ║
 * ║                                                                         ║
 * ║  Con Absolute Volume (AV) DESACTIVADO:                                  ║
 * ║    • El sistema Android NO envía AVRCP Absolute Volume al DAC.          ║
 * ║    • adjustStreamVolume(flags=0) cambia STREAM_MUSIC SIN overlay,       ║
 * ║      SIN propagar al DAC (porque AV está OFF).                          ║
 * ║    • El DAC mantiene su volumen interno independiente.                  ║
 * ║    • La barra Android puede moverse independientemente.                 ║
 * ║                                                                         ║
 * ║  RESTRICCIÓN DE PLATAFORMA:                                             ║
 * ║    No existe API pública que envíe AVRCP VOL_UP/DOWN a un DAC           ║
 * ║    específico SIN tocar STREAM_MUSIC desde una app no-sistema.          ║
 * ║    (sendPassThroughCmd es @hide y requiere firma de sistema).            ║
 * ║                                                                         ║
 * ║  SOLUCIÓN IMPLEMENTADA:                                                 ║
 * ║    • Con AV OFF: mantenemos un contador interno de "btVolume"           ║
 * ║      (0–100) en la app. Los botones BT de la app envían                 ║
 * ║      adjustStreamVolume(flags=0) para mover STREAM_MUSIC                ║
 * ║      (sin overlay, sin sincronizar con DAC ya que AV=OFF).              ║
 * ║      Esto da una barra BT "virtual" que refleja comandos.               ║
 * ║                                                                         ║
 * ║  NOTA: Con AV desactivado en Developer Options, el volumen FÍSICO       ║
 * ║    del DAC NO PUEDE cambiarse via software desde una app normal.        ║
 * ║    El hardware del DAC tiene su control independiente.                  ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
class BluetoothVolumeManager(private val context: Context) {

    private val TAG = "BtVolumeManager"
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val btAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    private var a2dpProfile: BluetoothA2dp? = null
    private var headsetProfile: BluetoothHeadset? = null

    // ── Estado de volumen BT virtual (independiente de STREAM_MUSIC) ─────────
    // Cuando AV está OFF, este contador representa el "volumen BT" de la UI.
    // Se actualiza con cada botón BT pero NO refleja cambios en la barra Android.
    private var btVolumeSteps: Int = 50   // 0–100, empieza en mitad
    private var btMaxSteps: Int = 100

    private val a2dpListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            a2dpProfile = proxy as BluetoothA2dp
            Log.d(TAG, "A2DP profile connected")
        }
        override fun onServiceDisconnected(profile: Int) { a2dpProfile = null }
    }

    private val headsetListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            headsetProfile = proxy as BluetoothHeadset
            Log.d(TAG, "Headset profile connected")
        }
        override fun onServiceDisconnected(profile: Int) { headsetProfile = null }
    }

    init {
        btAdapter?.getProfileProxy(context, a2dpListener, BluetoothProfile.A2DP)
        btAdapter?.getProfileProxy(context, headsetListener, BluetoothProfile.HEADSET)
    }

    fun cleanup() {
        a2dpProfile?.let { btAdapter?.closeProfileProxy(BluetoothProfile.A2DP, it) }
        headsetProfile?.let { btAdapter?.closeProfileProxy(BluetoothProfile.HEADSET, it) }
    }

    // ── Absolute Volume toggle ────────────────────────────────────────────────

    fun getAbsoluteVolumeEnabled(): Boolean {
        return try {
            // 0 = Absolute Volume is ENABLED (default)
            // 1 = Absolute Volume is DISABLED
            Settings.Global.getInt(context.contentResolver, "bluetooth_disable_absolute_volume", 0) == 0
        } catch (e: Exception) { true }
    }

    fun setAbsoluteVolume(enabled: Boolean): Boolean {
        val disableValue = if (enabled) 0 else 1
        return try {
            Settings.Global.putInt(
                context.contentResolver,
                "bluetooth_disable_absolute_volume",
                disableValue
            )
            true
        } catch (e: Exception) {
            // Si falla por falta de WRITE_SECURE_SETTINGS, intentar con Root (su)
            try {
                val command = "settings put global bluetooth_disable_absolute_volume $disableValue"
                val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
                process.waitFor()
                process.exitValue() == 0
            } catch (rootError: Exception) { 
                false 
            }
        }
    }

    // ── Control de volumen principal ──────────────────────────────────────────

    /**
     * Envía un comando de volumen o control al dispositivo BT.
     *
     * AV ON (Absolute Volume activado):
     *   - VOL_UP/DOWN: adjustStreamVolume(flags=0) → sin overlay → BT sincroniza
     *   - Otros: via KeyEvent al sistema
     *
     * AV OFF (Absolute Volume desactivado):
     *   - VOL_UP/DOWN: adjustStreamVolume(flags=0) → mueve STREAM_MUSIC SIN overlay
     *     y SIN propagar al DAC (AV=OFF significa no-sync). El contador interno
     *     btVolumeSteps también se actualiza para mostrar progreso en UI.
     *   - Otros: via KeyEvent al sistema
     */
    fun sendAvrcpPassThrough(address: String, keyId: Int): Boolean {
        val absVolEnabled = getAbsoluteVolumeEnabled()

        return when (keyId) {
            AVRCP_VOL_UP   -> sendVolumeAdjust(AudioManager.ADJUST_RAISE, absVolEnabled, +1)
            AVRCP_VOL_DOWN -> sendVolumeAdjust(AudioManager.ADJUST_LOWER, absVolEnabled, -1)
            else           -> sendMediaControl(keyId)
        }
    }

    private fun sendVolumeAdjust(direction: Int, absVolEnabled: Boolean, step: Int): Boolean {
        return try {
            // flags = 0:
            //   • Sin FLAG_SHOW_UI (1)  → no aparece overlay Android
            //   • Sin FLAG_BLUETOOTH_ABS_VOLUME (64) → no fuerza Absolute Volume sync
            //
            // Con AV ON: el Bluetooth stack sigue sincronizando por diseño de sistema
            //            (el stack escucha cambios de STREAM_MUSIC internamente)
            // Con AV OFF: solo cambia STREAM_MUSIC localmente, DAC no recibe nada
            audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, direction, 0)

            // Actualizar contador interno BT (útil cuando AV=OFF para feedback visual)
            btVolumeSteps = (btVolumeSteps + step * 5).coerceIn(0, btMaxSteps)

            Log.d(TAG, "adjustStreamVolume dir=$direction avEnabled=$absVolEnabled btSteps=$btVolumeSteps")
            true
        } catch (e: Exception) {
            Log.e(TAG, "sendVolumeAdjust failed: ${e.message}")
            false
        }
    }

    private fun sendMediaControl(keyId: Int): Boolean {
        val keyCode = when (keyId) {
            AVRCP_PLAY  -> KeyEvent.KEYCODE_MEDIA_PLAY
            AVRCP_PAUSE -> KeyEvent.KEYCODE_MEDIA_PAUSE
            AVRCP_NEXT  -> KeyEvent.KEYCODE_MEDIA_NEXT
            AVRCP_PREV  -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            else        -> return false
        }
        return try {
            audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
            Thread.sleep(20)
            audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
            Log.d(TAG, "MediaKey dispatched: $keyCode")
            true
        } catch (e: Exception) {
            Log.e(TAG, "dispatchMediaKeyEvent failed: ${e.message}")
            false
        }
    }

    // ── Estado BT virtual (solo relevante cuando AV=OFF) ─────────────────────

    /** Volumen BT virtual (0..max) cuando AV está desactivado. */
    fun getBtVolume(): Int = btVolumeSteps
    fun getBtMaxVolume(): Int = btMaxSteps
    fun setBtVolume(level: Int) { btVolumeSteps = level.coerceIn(0, btMaxSteps) }

    // ── Constantes AVRCP ──────────────────────────────────────────────────────

    companion object {
        const val AVRCP_VOL_UP   = 0x41
        const val AVRCP_VOL_DOWN = 0x42
        const val AVRCP_PLAY     = 0x44
        const val AVRCP_PAUSE    = 0x46
        const val AVRCP_NEXT     = 0x4B
        const val AVRCP_PREV     = 0x4C
    }

    // ── Device discovery ──────────────────────────────────────────────────────

    fun getConnectedDevices(): List<Map<String, Any?>> {
        val devices = mutableListOf<Map<String, Any?>>()
        val a2dpDevices = a2dpProfile?.connectedDevices ?: emptyList()
        val hfpDevices  = headsetProfile?.connectedDevices ?: emptyList()
        val seen = mutableSetOf<String>()

        for (device in a2dpDevices + hfpDevices) {
            if (!seen.add(device.address)) continue
            val profile = if (a2dpDevices.contains(device)) "A2DP" else "HFP"
            devices.add(buildDeviceMap(device, profile))
        }

        if (devices.isEmpty()) {
            btAdapter?.bondedDevices?.forEach { device ->
                if (seen.add(device.address) && isDeviceConnectedReflection(device)) {
                    devices.add(buildDeviceMap(device, "BONDED"))
                }
            }
        }
        return devices
    }

    private fun buildDeviceMap(device: BluetoothDevice, profile: String): Map<String, Any?> {
        val absVolEnabled = getAbsoluteVolumeEnabled()
        return mapOf(
            "address"                 to device.address,
            "name"                    to (device.name ?: "Unknown"),
            "batteryLevel"            to getBatteryLevel(device),
            "avrcpSupported"          to (profile == "A2DP"),
            "absoluteVolumeSupported" to (profile == "A2DP" && absVolEnabled),
            "volumeSynced"            to (profile == "A2DP" && absVolEnabled),
            "androidVolume"           to getAndroidVolume(),
            "maxAndroidVolume"        to getMaxVolume(),
            "btVolume"                to getBtVolume(),
            "btMaxVolume"             to getBtMaxVolume(),
            "profileType"             to profile,
            "isConnected"             to true,
            "independentVolume"       to !absVolEnabled
        )
    }

    private fun getBatteryLevel(device: BluetoothDevice): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val m = device.javaClass.getMethod("getBatteryLevel")
                (m.invoke(device) as? Int) ?: -1
            } catch (e: Exception) { -1 }
        } else -1
    }

    // ── Volumen Android ───────────────────────────────────────────────────────

    fun getAndroidVolume(): Int = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
    fun getMaxVolume(): Int     = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)

    /**
     * Ajusta STREAM_MUSIC directamente (desde la barra Android de la UI).
     * flags = 0 → sin overlay. Con AV ON también mueve el DAC (correcto).
     */
    fun setAndroidVolume(level: Int): Boolean {
        return try {
            val clamped = level.coerceIn(0, getMaxVolume())
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, clamped, 0)
            true
        } catch (e: Exception) { false }
    }

    // ── Operaciones avanzadas ─────────────────────────────────────────────────

    fun resyncVolume(): Map<String, Any?> {
        return try {
            val current = getAndroidVolume()
            val max     = getMaxVolume()
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, max, 0)
            Thread.sleep(120)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, current, 0)
            mapOf("success" to true, "message" to "Resincronizado")
        } catch (e: Exception) {
            mapOf("success" to false, "message" to e.message)
        }
    }

    fun reconnectDevice(address: String): Boolean {
        return try {
            val device = btAdapter?.bondedDevices?.find { it.address == address } ?: return false
            a2dpProfile?.javaClass?.getMethod("disconnect", BluetoothDevice::class.java)?.invoke(a2dpProfile, device)
            Thread.sleep(800)
            a2dpProfile?.javaClass?.getMethod("connect", BluetoothDevice::class.java)?.invoke(a2dpProfile, device)
            true
        } catch (e: Exception) { false }
    }

    fun resetBluetoothVolume(): Boolean {
        return try {
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, getMaxVolume() / 2, 0)
            resyncVolume()
            true
        } catch (e: Exception) { false }
    }

    fun toggleBluetooth(): Boolean {
        return try {
            if (btAdapter?.isEnabled == true) { @Suppress("DEPRECATION") btAdapter.disable() }
            else { @Suppress("DEPRECATION") btAdapter?.enable() }
            true
        } catch (e: Exception) { false }
    }

    private fun isDeviceConnectedReflection(device: BluetoothDevice): Boolean {
        return try {
            device.javaClass.getMethod("isConnected").invoke(device) as? Boolean ?: false
        } catch (e: Exception) { false }
    }
}
