package com.airpulse

import android.content.Context
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import kotlin.math.max

class VolumeListener(private val context: Context, private val onVolumeChange: (Float) -> Unit) {
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val handler = Handler(Looper.getMainLooper())
    private var lastVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toFloat()
    private val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    private var pollingRunnable: Runnable? = null

    fun startListening() {
        pollingRunnable = object : Runnable {
            override fun run() {
                val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toFloat()
                val normalizedVolume = currentVolume / max(1, maxVolume)

                if (kotlin.math.abs(normalizedVolume - lastVolume) > 0.01f) {
                    lastVolume = normalizedVolume
                    onVolumeChange(normalizedVolume)
                }

                handler.postDelayed(this, 100) // Revisar cada 100ms
            }
        }
        handler.post(pollingRunnable!!)
    }

    fun stopListening() {
        pollingRunnable?.let { handler.removeCallbacks(it) }
    }

    fun setVolume(volume: Float) {
        val streamVolume = (volume * maxVolume).toInt()
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, streamVolume, 0)
        lastVolume = volume
    }
}
