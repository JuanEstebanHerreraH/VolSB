package com.btvolumepro.app

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent

/**
 * Controlador AVRCP puro.
 *
 * Cuando Absolute Volume (AV) está DESACTIVADO:
 *   - volumeUp / volumeDown envían KeyEvent al subsistema de audio vía
 *     AudioManager.dispatchMediaKeyEvent. Esto llega al stack Bluetooth nativo
 *     como PassThrough AVRCP_VOL_UP/DOWN y NO modifica STREAM_MUSIC.
 *
 * Cuando AV está ACTIVADO:
 *   - adjustStreamVolume con FLAG_SHOW_UI=0 cambia el volumen Android y,
 *     por el stack Bluetooth, sincroniza al dispositivo (comportamiento esperado).
 *
 * El overlay de Android NO aparece en ninguno de los dos caminos porque omitimos
 * AudioManager.FLAG_SHOW_UI (valor 1).
 */
class AVRCPController(private val context: Context) {

    private val TAG = "AVRCPController"
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    // ── Detección de modo ────────────────────────────────────────────────────

    private fun isAbsoluteVolumeEnabled(): Boolean {
        return try {
            Settings.Global.getInt(context.contentResolver, "bluetooth_disable_absolute_volume", 0) == 0
        } catch (e: Exception) { true }
    }

    // ── Volumen BT independiente (AV OFF) ────────────────────────────────────
    //
    // dispatchMediaKeyEvent envía un evento de tecla de medio que el framework
    // procesa y reenvía al perfil AVRCP activo. Con AV desactivado, el stack BT
    // de Android lo convierte en un AVRCP PassThrough command (VOL_UP/VOL_DOWN)
    // y lo envía DIRECTAMENTE al dispositivo BT sin tocar STREAM_MUSIC.
    //
    // Referencia AOSP: AudioService.java → dispatchMediaKeyEvent →
    //   MediaSessionService → BtMediaBrowserService → AVRCP TG PassThrough

    private fun sendMediaKey(keyCode: Int): Boolean {
        return try {
            val down = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
            val up   = KeyEvent(KeyEvent.ACTION_UP,   keyCode)
            audioManager.dispatchMediaKeyEvent(down)
            Thread.sleep(20)
            audioManager.dispatchMediaKeyEvent(up)
            Log.d(TAG, "dispatchMediaKeyEvent keyCode=$keyCode → OK")
            true
        } catch (e: Exception) {
            Log.e(TAG, "dispatchMediaKeyEvent failed: ${e.message}")
            false
        }
    }

    // ── API pública ──────────────────────────────────────────────────────────

    /**
     * Sube el volumen. Si AV está OFF, usa AVRCP PassThrough puro (no toca Android).
     * Si AV está ON, ajusta STREAM_MUSIC sin mostrar overlay (comportamiento esperado).
     */
    fun sendVolumeUp(): Boolean {
        return if (!isAbsoluteVolumeEnabled()) {
            // AV desactivado → AVRCP PassThrough directo al DAC
            sendMediaKey(KeyEvent.KEYCODE_VOLUME_UP)
        } else {
            // AV activado → ajustar Android (se sincroniza al BT por diseño)
            adjustAndroid(AudioManager.ADJUST_RAISE)
        }
    }

    /**
     * Baja el volumen. Mismo criterio que sendVolumeUp.
     */
    fun sendVolumeDown(): Boolean {
        return if (!isAbsoluteVolumeEnabled()) {
            sendMediaKey(KeyEvent.KEYCODE_VOLUME_DOWN)
        } else {
            adjustAndroid(AudioManager.ADJUST_LOWER)
        }
    }

    private fun adjustAndroid(direction: Int): Boolean {
        return try {
            // flags = 0 → sin overlay, sin FLAG_BLUETOOTH_ABS_VOLUME
            audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, direction, 0)
            true
        } catch (e: Exception) { false }
    }

    // ── Mute / Unmute ────────────────────────────────────────────────────────

    fun sendMute(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // flags = 0 → sin overlay
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

    // ── Recuperar dispositivo muteado ────────────────────────────────────────
    //
    // Sube el DAC directamente via PassThrough para desatascarlo si quedó
    // en volumen 0 interno (fenómeno conocido en BTR/DAC con AV deshabilitado).

    fun recoverMutedDevice(address: String): Boolean {
        return try {
            sendUnmute()
            Thread.sleep(100)

            if (!isAbsoluteVolumeEnabled()) {
                // Con AV OFF enviamos PassThrough al DAC
                repeat(12) {
                    sendMediaKey(KeyEvent.KEYCODE_VOLUME_UP)
                    Thread.sleep(80)
                }
            } else {
                // Con AV ON ajustamos STREAM_MUSIC al máximo y sincronizamos
                val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, max, 0)
                Thread.sleep(100)
                repeat(8) {
                    audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_RAISE, 0)
                    Thread.sleep(80)
                }
            }

            Log.d(TAG, "Recovery completed for $address")
            true
        } catch (e: Exception) {
            Log.e(TAG, "recoverMutedDevice: ${e.message}")
            false
        }
    }
}
