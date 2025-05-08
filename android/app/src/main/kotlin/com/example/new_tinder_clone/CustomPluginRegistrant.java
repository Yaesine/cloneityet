package com.example.new_tinder_clone;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.Log;

import io.flutter.embedding.engine.FlutterEngine;

/**
 * Custom plugin registrant to selectively register plugins, excluding geocoding and geolocator.
 */
@Keep
public final class CustomPluginRegistrant {
    private static final String TAG = "CustomPluginRegistrant";
    public static void registerWith(@NonNull FlutterEngine flutterEngine) {
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin cloud_firestore", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.functions.FlutterFirebaseFunctionsPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin cloud_functions", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin firebase_auth", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin firebase_core", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin firebase_messaging", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.storage.FlutterFirebaseStoragePlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin firebase_storage", e);
        }
        try {
            flutterEngine.getPlugins().add(new app.meedu.flutter_facebook_auth.FlutterFacebookAuthPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin flutter_facebook_auth", e);
        }
        try {
            flutterEngine.getPlugins().add(new net.jonhanson.flutter_native_splash.FlutterNativeSplashPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin flutter_native_splash", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin flutter_plugin_android_lifecycle", e);
        }
        try {
            flutterEngine.getPlugins().add(new com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin flutter_secure_storage", e);
        }
        // Skip geolocator
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.googlesignin.GoogleSignInPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin google_sign_in_android", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.imagepicker.ImagePickerPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin image_picker_android", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.pathprovider.PathProviderPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin path_provider_android", e);
        }
        try {
            flutterEngine.getPlugins().add(new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin shared_preferences_android", e);
        }
        try {
            flutterEngine.getPlugins().add(new com.tekartik.sqflite.SqflitePlugin());
        } catch (Exception e) {
            Log.e(TAG, "Error registering plugin sqflite_android", e);
        }
    }
}