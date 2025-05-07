package com.example.new_tinder_clone

import android.content.Context
import android.webkit.WebView
import io.flutter.app.FlutterApplication
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger

class WebViewInitializer {
    companion object {
        fun initialize(context: Context) {
            try {
                // Pre-warm the WebView to avoid initialization issues
                WebView(context).apply {
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    settings.databaseEnabled = true
                    settings.setGeolocationEnabled(true)
                    settings.javaScriptCanOpenWindowsAutomatically = true
                }
            } catch (e: Exception) {
                // Just log any error but don't crash
                android.util.Log.e("WebViewInit", "Error initializing WebView: ${e.message}")
            }
        }
    }
}

class TinderCloneApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        // Initialize WebView early
        WebViewInitializer.initialize(this)

        // Initialize Facebook SDK
        try {
            FacebookSdk.sdkInitialize(applicationContext)
            AppEventsLogger.activateApp(this)
        } catch (e: Exception) {
            android.util.Log.e("FacebookInit", "Error initializing Facebook SDK: ${e.message}")
        }
    }
}