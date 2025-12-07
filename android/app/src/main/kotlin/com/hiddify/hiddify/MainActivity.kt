package com.hiddify.hiddify

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
class MainActivity : FlutterFragmentActivity() {
    companion object {
        lateinit var instance: MainActivity
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this
        flutterEngine.plugins.add(PlatformSettingsHandler())
    }
}
