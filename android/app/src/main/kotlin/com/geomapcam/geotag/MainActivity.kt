package com.geomapcam.geotag

import android.content.pm.PackageManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CONFIG_CHANNEL = "com.geomapcam.geotag/config"
    private val VOLUME_CHANNEL = "com.geomapcam.geotag/volume"
    
    private var volumeEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONFIG_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getApiKey") {
                try {
                    val appInfo = context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
                    val apiKey = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
                    if (apiKey != null && apiKey.isNotEmpty()) {
                        result.success(apiKey)
                    } else {
                        result.error("UNAVAILABLE", "API key not found in metadata.", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else if (call.method == "getGeocodingApiKey") {
                try {
                    val appInfo = context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
                    val apiKey = appInfo.metaData?.getString("com.google.android.geo.GEOCODING_API_KEY")
                    if (apiKey != null && apiKey.isNotEmpty()) {
                        result.success(apiKey)
                    } else {
                        result.error("UNAVAILABLE", "Geocoding API key not found in metadata.", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else if (call.method == "getStaticMapsApiKey") {
                try {
                    val appInfo = context.packageManager.getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
                    val apiKey = appInfo.metaData?.getString("com.google.android.geo.STATIC_MAPS_API_KEY")
                    if (apiKey != null && apiKey.isNotEmpty()) {
                        result.success(apiKey)
                    } else {
                        result.error("UNAVAILABLE", "Static Maps API key not found in metadata.", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    volumeEventSink = null
                }
            }
        )
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            volumeEventSink?.success(if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down")
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}
