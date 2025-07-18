package com.example.ip_address_checker

import android.content.Context
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "proxy_helper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSystemProxy" -> {
                    try {
                        val proxyInfo = getSystemProxySettings()
                        result.success(proxyInfo)
                    } catch (e: Exception) {
                        result.error("PROXY_ERROR", "Failed to get proxy settings", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getSystemProxySettings(): Map<String, Any>? {
        try {
            // Get proxy settings for Android 4.0 and later
            val httpProxy = Settings.Global.getString(contentResolver, Settings.Global.HTTP_PROXY)
            
            if (httpProxy != null && httpProxy.isNotEmpty() && httpProxy != ":0") {
                val parts = httpProxy.split(":")
                if (parts.size >= 2) {
                    val host = parts[0]
                    val port = parts[1].toIntOrNull() ?: 0
                    
                    if (host.isNotEmpty() && port > 0) {
                        return mapOf(
                            "host" to host,
                            "port" to port
                        )
                    }
                }
            }

            // Fallback: proxy settings for legacy API
            @Suppress("DEPRECATION")
            val legacyHost = Settings.Secure.getString(contentResolver, Settings.Secure.HTTP_PROXY)
            if (legacyHost != null && legacyHost.isNotEmpty()) {
                val parts = legacyHost.split(":")
                if (parts.size >= 2) {
                    val host = parts[0]
                    val port = parts[1].toIntOrNull() ?: 0
                    
                    if (host.isNotEmpty() && port > 0) {
                        return mapOf(
                            "host" to host,
                            "port" to port
                        )
                    }
                }
            }
        } catch (e: Exception) {
            // Return null if an error occurs
            return null
        }
        
        return null
    }
}
