package com.jayshanx.flutter_uniapp

import android.os.Bundle
import android.util.Log
import com.jayshanx.flutter_uniapp.plugins.SmallAppPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val tag = "FlutterUniSDK"
    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i(tag, "MainActivity  onCreate")
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        //添加小程序引擎
        flutterEngine.plugins.add(SmallAppPlugin())
        super.configureFlutterEngine(flutterEngine)
    }
}
