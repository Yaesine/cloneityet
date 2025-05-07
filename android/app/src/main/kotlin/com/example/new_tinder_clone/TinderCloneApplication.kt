package com.example.new_tinder_clone

import android.app.Application
import android.content.Context
import android.webkit.WebView

class WebViewInitializer {
    companion object {
        fun initialize(context: Context) {
            try {
                // Pre-warm the WebView to avoid initialization issues
                WebView(context).apply {
                    settings.javaScriptEnabled = true
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                        settings.domStorageEnabled = true
                        settings.databaseEnabled = true
                        settings.setGeolocationEnabled(true)
                    }
                    settings.javaScriptCanOpenWindowsAutomatically = true
                }
            } catch (e: Exception) {
                // Just log any error but don't crash
                android.util.Log.e("WebViewInit", "Error initializing WebView: ${e.message}")
            }
        }
    }
}

class TinderCloneApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Initialize WebView early
        WebViewInitializer.initialize(this)

        // Initialize Facebook SDK (the standard way)
        try {
            com.facebook.FacebookSdk.sdkInitialize(applicationContext)
            com.facebook.appevents.AppEventsLogger.activateApp(this)
        } catch (e: Exception) {
            android.util.Log.e("FacebookInit", "Error initializing Facebook SDK: ${e.message}")
        }
    }
}
