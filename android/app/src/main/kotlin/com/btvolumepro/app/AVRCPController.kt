package com.btvolumepro.app

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.view.KeyEvent

class AVRCPController(private val context: Context) {

    private val TAG = "AVRCPController"
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    // Estos métodos ahora son solo fallback para cuando no hay dirección de dispositivo
    fun sendVolumeUp(): Boolean {
        return try {
            audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_RAISE, 64)
            true
        } catch (e: Exception) { false }
    }

    fun sendVolumeDown(): Boolean {
        return try {
            audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_LOWER, 64)
            true
        } catch (e: Exception) { false }
    }

    fun sendMute(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, 0)
            } else {
                @Suppress("DEPRECATION")
                audioManager.setStreamMute(AudioManager.STREAM_MUSIC, true)
            }
            true
        } catch (e: Exception) { false }
    }

    fun sendUnmute(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_UNMUTE, 0)
            } else {
                @Suppress("DEPRECATION")
                audioManager.setStreamMute(AudioManager.STREAM_MUSIC, false)
            }
            true
        } catch (e: Exception) { false }
    }

    fun recoverMutedDevice(address: String): Boolean {
        return try {
            sendUnmute()
            Thread.sleep(100)

            val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, max, 64)
            Thread.sleep(100)

            repeat(8) {
                audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_RAISE, 64)
                Thread.sleep(80)
            }

            val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, max, 64)
            Thread.sleep(150)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, current, 64)

            Log.d(TAG, "Recovery completed for $address")
            true
        } catch (e: Exception) {
            Log.e(TAG, "recoverMutedDevice: ${e.message}")
            false
        }
    }
}
