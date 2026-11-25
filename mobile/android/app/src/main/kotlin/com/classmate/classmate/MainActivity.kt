package com.classmate.classmate

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Opt into the maximum refresh rate on Android 11+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.attributes.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            val display = display
            if (display != null) {
                val maxRefreshRateMode = display.supportedModes.maxByOrNull { it.refreshRate }
                if (maxRefreshRateMode != null) {
                    val layoutParams = window.attributes
                    layoutParams.preferredDisplayModeId = maxRefreshRateMode.modeId
                    window.attributes = layoutParams
                }
            }
        }
    }
}