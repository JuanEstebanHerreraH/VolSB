package com.btvolumepro.app

import android.bluetooth.*
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * Manages Bluetooth device discovery, volume control, reconnection,
 * and Absolute Volume toggle for BT Volume Pro.
 */
class BluetoothVolumeManager(private val context: Context) {

    private val TAG = "BtVolumeManager"
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val btAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    // Profiles we keep open for A2DP and HFP
    private var a2dpProfile: BluetoothA2dp? = null
    private var headsetProfile: BluetoothHeadset? = null

    // ── Profile listeners ─────────────────────────────────────────────────────

    private val a2dpListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            a2dpProfile = proxy as BluetoothA2dp
            Log.d(TAG, "A2DP profile connected")
        }
        override fun onServiceDisconnected(profile: Int) {
            a2dpProfile = null
        }
    }

    private val headsetListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            headsetProfile = proxy as BluetoothHeadset
            Log.d(TAG, "Headset profile connected")
        }
        override fun onServiceDisconnected(profile: Int) {
            headsetProfile = null
        }
    }

    init {
        btAdapter?.getProfileProxy(context, a2dpListener, BluetoothProfile.A2DP)
        btAdapter?.getProfileProxy(context, headsetListener, BluetoothProfile.HEADSET)
    }

    fun cleanup() {
        a2dpProfile?.let { btAdapter?.closeProfileProxy(BluetoothProfile.A2DP, it) }
        headsetProfile?.let { btAdapter?.closeProfileProxy(BluetoothProfile.HEADSET, it) }
    }

    // ── Device discovery ──────────────────────────────────────────────────────

    /**
     * Returns a list of connected Bluetooth audio devices with capability info.
     * Each device is a Map<String, Any?> for Flutter.
     */
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

        // Also check all bonded devices that might report a connection state
        if (devices.isEmpty()) {
            btAdapter?.bondedDevices?.forEach { device ->
                if (seen.add(device.address)) {
                    val isConnected = isDeviceConnectedReflection(device)
                    if (isConnected) {
                        devices.add(buildDeviceMap(device, "BONDED"))
                    }
                }
            }
        }

        return devices
    }

    private fun buildDeviceMap(device: BluetoothDevice, profile: String): Map<String, Any?> {
        val battery = getBatteryLevel(device)
        val avrcpOk = profile == "A2DP" // AVRCP is part of A2DP stack
        val absVolEnabled = getAbsoluteVolumeEnabled()

        return mapOf(
            "address"                 to device.address,
            "name"                    to (device.name ?: "Unknown"),
            "batteryLevel"            to battery,
            "avrcpSupported"          to avrcpOk,
            "absoluteVolumeSupported" to (avrcpOk && absVolEnabled),
            "volumeSynced"            to (avrcpOk && absVolEnabled),
            "androidVolume"           to getAndroidVolume(),
            "maxAndroidVolume"        to getMaxVolume(),
            "profileType"             to profile,
            "isConnected"             to true
        )
    }

    // ── Battery ───────────────────────────────────────────────────────────────

    private fun getBatteryLevel(device: BluetoothDevice): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val method = device.javaClass.getMethod("getBatteryLevel")
                (method.invoke(device) as? Int) ?: -1
            } catch (e: Exception) {
                Log.d(TAG, "Battery level not available: ${e.message}")
                -1
            }
        } else -1
    }

    // ── Volume ────────────────────────────────────────────────────────────────

    fun getAndroidVolume(): Int =
        audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)

    fun getMaxVolume(): Int =
        audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)

    fun setAndroidVolume(level: Int): Boolean {
        return try {
            val max = getMaxVolume()
            val clamped = level.coerceIn(0, max)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, clamped, 0)
            Log.d(TAG, "Android volume set to $clamped")
            true
        } catch (e: Exception) {
            Log.e(TAG, "setAndroidVolume failed: ${e.message}")
            false
        }
    }

    // ── Absolute Volume ───────────────────────────────────────────────────────

    /**
     * Reads the global setting that controls AVRCP Absolute Volume.
     * Key: "bluetooth_avrc_absolute_vol" – 1 = enabled, 0 = disabled
     */
    fun getAbsoluteVolumeEnabled(): Boolean {
        return try {
            Settings.Global.getInt(
                context.contentResolver,
                "bluetooth_avrc_absolute_vol",
                1
            ) == 1
        } catch (e: Exception) {
            true
        }
    }

    /**
     * Tries to toggle AVRCP Absolute Volume via Settings.Global.
     * Requires WRITE_SECURE_SETTINGS permission (or root on some devices).
     * Returns true if the write succeeded.
     */
    fun setAbsoluteVolume(enabled: Boolean): Boolean {
        return try {
            Settings.Global.putInt(
                context.contentResolver,
                "bluetooth_avrc_absolute_vol",
                if (enabled) 1 else 0
            )
            Log.d(TAG, "Absolute volume set to $enabled")
            true
        } catch (e: Exception) {
            Log.e(TAG, "setAbsoluteVolume needs WRITE_SECURE_SETTINGS: ${e.message}")
            // Fall back to attempting via reflection
            setAbsoluteVolumeReflection(enabled)
        }
    }

    private fun setAbsoluteVolumeReflection(enabled: Boolean): Boolean {
        return try {
            val method = audioManager.javaClass.getMethod(
                "setAbsoluteVolumeEnabled",
                Boolean::class.java
            )
            method.invoke(audioManager, enabled)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Reflection absolute volume failed: ${e.message}")
            false
        }
    }

    // ── Resync ────────────────────────────────────────────────────────────────

    /**
     * Attempts to resynchronise the Android media volume with the BT device.
     * Strategy:
     * 1. Read current Android volume
     * 2. Momentarily raise to max, then restore – forces a re-notification
     * 3. Send a STREAM_MUSIC setStreamVolume to confirm
     */
    fun resyncVolume(): Map<String, Any?> {
        return try {
            val current = getAndroidVolume()
            val max     = getMaxVolume()

            // Bump to max then restore to force BT stack notification
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, max, 0)
            Thread.sleep(120)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, current, 0)

            Log.d(TAG, "Volume resynced: $current/$max")
            mapOf("success" to true, "message" to "Resincronizado")
        } catch (e: Exception) {
            Log.e(TAG, "resyncVolume failed: ${e.message}")
            mapOf("success" to false, "message" to e.message)
        }
    }

    // ── Reconnect ─────────────────────────────────────────────────────────────

    fun reconnectDevice(address: String): Boolean {
        return try {
            val device = btAdapter?.bondedDevices?.find { it.address == address }
                ?: return false

            // Disconnect A2DP then reconnect
            disconnectA2dp(device)
            Thread.sleep(800)
            connectA2dp(device)

            Log.d(TAG, "Reconnect issued for $address")
            true
        } catch (e: Exception) {
            Log.e(TAG, "reconnectDevice failed: ${e.message}")
            false
        }
    }

    private fun disconnectA2dp(device: BluetoothDevice) {
        try {
            val method = a2dpProfile?.javaClass?.getMethod("disconnect", BluetoothDevice::class.java)
            method?.invoke(a2dpProfile, device)
        } catch (e: Exception) {
            Log.e(TAG, "A2DP disconnect: ${e.message}")
        }
    }

    private fun connectA2dp(device: BluetoothDevice) {
        try {
            val method = a2dpProfile?.javaClass?.getMethod("connect", BluetoothDevice::class.java)
            method?.invoke(a2dpProfile, device)
        } catch (e: Exception) {
            Log.e(TAG, "A2DP connect: ${e.message}")
        }
    }

    // ── Reset BT volume ───────────────────────────────────────────────────────

    /**
     * Resets the Bluetooth audio volume to 50% (midpoint) then resyncs.
     */
    fun resetBluetoothVolume(): Boolean {
        return try {
            val max  = getMaxVolume()
            val mid  = max / 2
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, mid, 0)
            resyncVolume()
            Log.d(TAG, "BT volume reset to $mid")
            true
        } catch (e: Exception) {
            Log.e(TAG, "resetBluetoothVolume: ${e.message}")
            false
        }
    }

    // ── Bluetooth toggle ──────────────────────────────────────────────────────

    fun toggleBluetooth(): Boolean {
        return try {
            if (btAdapter?.isEnabled == true) {
                @Suppress("DEPRECATION")
                btAdapter.disable()
            } else {
                @Suppress("DEPRECATION")
                btAdapter?.enable()
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "toggleBluetooth: ${e.message}")
            false
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun isDeviceConnectedReflection(device: BluetoothDevice): Boolean {
        return try {
            val method = device.javaClass.getMethod("isConnected")
            method.invoke(device) as? Boolean ?: false
        } catch (e: Exception) {
            false
        }
    }
}
