package com.airpulse

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AirPulseVolumeManager(private val context: Context) {
    private val channelName = "com.airpulse/volume"
    private var volumeListener: VolumeListener? = null

    fun setupChannel(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVolumeListener" -> {
                    startVolumeListener(channel)
                    result.success(null)
                }
                "stopVolumeListener" -> {
                    stopVolumeListener()
                    result.success(null)
                }
                "setVolume" -> {
                    val volume = call.argument<Double>("volume")?.toFloat() ?: 1f
                    volumeListener?.setVolume(volume)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVolumeListener(channel: MethodChannel) {
        if (volumeListener == null) {
            volumeListener = VolumeListener(context) { volume ->
                channel.invokeMethod("onVolumeChanged", mapOf("volume" to volume.toDouble()))
            }
            volumeListener?.startListening()
        }
    }

    private fun stopVolumeListener() {
        volumeListener?.stopListening()
        volumeListener = null
    }
}
