package com.example.cruci_verba

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.content.Context

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Fix for keyboard issues and improve input handling - prevent screen shrinking
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_PAN)
        
        // Suppress gralloc warnings (cosmetic fix)
        System.setProperty("android.ui.gralloc.debug", "false")
    }

    override fun onPause() {
        super.onPause()
        // Force hide keyboard when app goes to background
        hideKeyboard()
    }

    override fun onStop() {
        super.onStop()
        // Force hide keyboard when app stops
        hideKeyboard()
    }

    private fun hideKeyboard() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val currentFocus = currentFocus
        if (currentFocus != null) {
            imm.hideSoftInputFromWindow(currentFocus.windowToken, 0)
        }
    }
}
