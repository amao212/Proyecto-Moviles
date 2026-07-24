package com.example.app_veterinaria_agenda

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.app_veterinaria_agenda/intent_bridge"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getIntentData" -> {
                    val extras = intent?.extras
                    val data = mutableMapOf<String, Any?>()

                    if (extras != null) {
                        for (key in extras.keySet()) {
                            val value = extras.get(key)
                            // Se filtran solo tipos de datos primitivos compatibles con Flutter
                            if (value is String || value is Number || value is Boolean) {
                                data[key] = value
                            }
                        }
                    }

                    result.success(data)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Escucha tanto ACTION_MAIN como ACTION_SEND para procesar los extras entrantes
        val action = intent?.action
        if (action == Intent.ACTION_MAIN || action == Intent.ACTION_SEND) {
            val extras = intent?.extras
            if (extras != null) {
                val payload = mutableMapOf<String, Any?>()
                for (key in extras.keySet()) {
                    val value = extras.get(key)
                    if (value is String || value is Number || value is Boolean) {
                        payload[key] = value
                    }
                }
            }
        }
    }
}