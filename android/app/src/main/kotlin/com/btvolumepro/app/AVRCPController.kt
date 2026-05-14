package com.btvolumepro.app

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.view.KeyEvent

/**
 * Sends AVRCP volume commands to a connected Bluetooth audio device.
 *
 * Approach:
 *  - dispatchMediaKeyEvent() for VOLUME_UP / VOLUME_DOWN / MUTE (API 19+)
 *  - AudioManager.adjustStreamVolume() as a complementary path
 *  - Burst mode: rapid repeated commands to wake up a silenced BT device
 */
class AVRCPController(private val context: Context) {

    private val TAG = "AVRCPController"
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    // ── Single commands ───────────────────────────────────────────────────────

    fun sendVolumeUp(): Boolean {
        return try {
            dispatchKeyEvent(KeyEvent.KEYCODE_VOLUME_UP)
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                AudioManager.ADJUST_RAISE,
                0
            )
            Log.d(TAG, "VOLUME_UP sent")
            true
        } catch (e: Exception) {
            Log.e(TAG, "sendVolumeUp: ${e.message}")
            false
        }
    }

    fun sendVolumeDown(): Boolean {
        return try {
            dispatchKeyEvent(KeyEvent.KEYCODE_VOLUME_DOWN)
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                AudioManager.ADJUST_LOWER,
                0
            )
            Log.d(TAG, "VOLUME_DOWN sent")
            true
        } catch (e: Exception) {
            Log.e(TAG, "sendVolumeDown: ${e.message}")
            false
        }
    }

    fun sendMute(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_MUTE,
                    0
                )
            } else {
                @Suppress("DEPRECATION")
                audioManager.setStreamMute(AudioManager.STREAM_MUSIC, true)
            }
            Log.d(TAG, "MUTE sent")
            true
        } catch (e: Exception) {
            Log.e(TAG, "sendMute: ${e.message}")
            false
        }
    }

    fun sendUnmute(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_UNMUTE,
                    0
                )
            } else {
                @Suppress("DEPRECATION")
                audioManager.setStreamMute(AudioManager.STREAM_MUSIC, false)
            }
            Log.d(TAG, "UNMUTE sent")
            true
        } catch (e: Exception) {
            Log.e(TAG, "sendUnmute: ${e.message}")
            false
        }
    }

    // ── Recovery: burst of volume-up commands ─────────────────────────────────

    /**
     * Attempts to recover a BT device that is internally muted (volume=0)
     * by sending a burst of AVRCP VOLUME_UP events plus an unmute,
     * then a resync bump.
     *
     * This wakes up BT devices that ignore single commands when muted.
     */
    fun recoverMutedDevice(address: String): Boolean {
        return try {
            // 1. Unmute system stream
            sendUnmute()
            Thread.sleep(100)

            // 2. Raise Android volume to max
            val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, max, 0)
            Thread.sleep(100)

            // 3. Burst of AVRCP volume-up key events
            repeat(8) {
                dispatchKeyEvent(KeyEvent.KEYCODE_VOLUME_UP)
                Thread.sleep(80)
            }

            // 4. Explicit adjust raise
            repeat(4) {
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_RAISE,
                    0
                )
                Thread.sleep(60)
            }

            // 5. Resync bump (max then restore)
            val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, max, 0)
            Thread.sleep(150)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, current, 0)

            Log.d(TAG, "Recovery burst completed for $address")
            true
        } catch (e: Exception) {
            Log.e(TAG, "recoverMutedDevice: ${e.message}")
            false
        }
    }

    // ── Key event helpers ─────────────────────────────────────────────────────

    private fun dispatchKeyEvent(keyCode: Int) {
        val now = SystemClock.uptimeMillis()
        val down = KeyEvent(now, now, KeyEvent.ACTION_DOWN, keyCode, 0)
        val up   = KeyEvent(now, now, KeyEvent.ACTION_UP,   keyCode, 0)
        audioManager.dispatchMediaKeyEvent(down)
        audioManager.dispatchMediaKeyEvent(up)
    }
}
