package com.btvolumepro.app

import android.bluetooth.*
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.util.Log

class BluetoothVolumeManager(private val context: Context) {

    private val TAG = "BtVolumeManager"
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val btAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    private var a2dpProfile: BluetoothA2dp? = null
    private var headsetProfile: BluetoothHeadset? = null
    private var avrcpControllerProxy: BluetoothProfile? = null

    private val a2dpListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) { a2dpProfile = proxy as BluetoothA2dp }
        override fun onServiceDisconnected(profile: Int) { a2dpProfile = null }
    }

    private val headsetListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) { headsetProfile = proxy as BluetoothHeadset }
        override fun onServiceDisconnected(profile: Int) { headsetProfile = null }
    }

    private val avrcpControllerListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            avrcpControllerProxy = proxy
            Log.d(TAG, "AVRCP Controller profile connected")
        }
        override fun onServiceDisconnected(profile: Int) { avrcpControllerProxy = null }
    }

    init {
        btAdapter?.getProfileProxy(context, a2dpListener, BluetoothProfile.A2DP)
        btAdapter?.getProfileProxy(context, headsetListener, BluetoothProfile.HEADSET)
        try {
            btAdapter?.getProfileProxy(context, avrcpControllerListener, 12) // AVRCP_CONTROLLER
        } catch (e: Exception) {
            Log.w(TAG, "AVRCP Controller not available: ${e.message}")
        }
    }

    fun cleanup() {
        a2dpProfile?.let { btAdapter?.closeProfileProxy(BluetoothProfile.A2DP, it) }
        headsetProfile?.let { btAdapter?.closeProfileProxy(BluetoothProfile.HEADSET, it) }
        avrcpControllerProxy?.let { btAdapter?.closeProfileProxy(12, it) }
    }

    // ── AVRCP PassThrough - simula botones fisicos del dispositivo BT ─────────

    fun sendAvrcpPassThrough(address: String, keyId: Int): Boolean {
        return try {
            val device = btAdapter?.bondedDevices?.find { it.address == address }
                ?: return sendAvrcpFallback(keyId)

            val proxy = avrcpControllerProxy ?: return sendAvrcpFallback(keyId)

            val method = proxy.javaClass.getMethod(
                "sendPassThroughCmd",
                BluetoothDevice::class.java,
                Int::class.java,
                Int::class.java
            )
            method.invoke(proxy, device, keyId, 0) // KEY_DOWN
            Thread.sleep(50)
            method.invoke(proxy, device, keyId, 1) // KEY_UP
            Log.d(TAG, "AVRCP PassThrough 0x${keyId.toString(16)} -> $address")
            true
        } catch (e: Exception) {
            Log.e(TAG, "PassThrough failed: ${e.message}")
            sendAvrcpFallback(keyId)
        }
    }

    private fun sendAvrcpFallback(keyId: Int): Boolean {
        return try {
            val adjust = if (keyId == AVRCP_VOL_UP) AudioManager.ADJUST_RAISE else AudioManager.ADJUST_LOWER
            audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, adjust, 64)
            true
        } catch (e: Exception) { false }
    }

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
            "address"           to device.address,
            "name"              to (device.name ?: "Unknown"),
            "batteryLevel"      to getBatteryLevel(device),
            "avrcpSupported"    to (profile == "A2DP"),
            "absoluteVolumeSupported" to (profile == "A2DP" && absVolEnabled),
            "volumeSynced"      to (profile == "A2DP" && absVolEnabled),
            "androidVolume"     to getAndroidVolume(),
            "maxAndroidVolume"  to getMaxVolume(),
            "profileType"       to profile,
            "isConnected"       to true,
            "independentVolume" to !absVolEnabled
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

    fun getAndroidVolume(): Int = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
    fun getMaxVolume(): Int = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)

    fun setAndroidVolume(level: Int): Boolean {
        return try {
            val clamped = level.coerceIn(0, getMaxVolume())
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, clamped, 64)
            true
        } catch (e: Exception) { false }
    }

    fun getAbsoluteVolumeEnabled(): Boolean {
        return try {
            Settings.Global.getInt(context.contentResolver, "bluetooth_avrc_absolute_vol", 1) == 1
        } catch (e: Exception) { true }
    }

    fun setAbsoluteVolume(enabled: Boolean): Boolean {
        return try {
            Settings.Global.putInt(context.contentResolver, "bluetooth_avrc_absolute_vol", if (enabled) 1 else 0)
            true
        } catch (e: Exception) {
            try {
                val m = audioManager.javaClass.getMethod("setAbsoluteVolumeEnabled", Boolean::class.java)
                m.invoke(audioManager, enabled)
                true
            } catch (e2: Exception) { false }
        }
    }

    fun resyncVolume(): Map<String, Any?> {
        return try {
            val current = getAndroidVolume()
            val max = getMaxVolume()
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, max, 64)
            Thread.sleep(120)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, current, 64)
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
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, getMaxVolume() / 2, 64)
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
