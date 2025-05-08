package com.example.new_tinder_clone

import android.app.Application
import android.content.Context
import android.webkit.WebView



class TinderCloneApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Initialize WebView early

        // Initialize Facebook SDK (the standard way)
        try {
            com.facebook.FacebookSdk.sdkInitialize(applicationContext)
            com.facebook.appevents.AppEventsLogger.activateApp(this)
        } catch (e: Exception) {
            android.util.Log.e("FacebookInit", "Error initializing Facebook SDK: ${e.message}")
        }
    }
}
