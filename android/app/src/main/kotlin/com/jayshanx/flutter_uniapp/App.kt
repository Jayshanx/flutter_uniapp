package com.jayshanx.flutter_uniapp

import android.app.Application
import android.util.Log
import com.taobao.weex.WXSDKEngine
import com.taobao.weex.common.WXException
import com.jayshanx.flutter_uniapp.unimodule.MyUniModule
import io.dcloud.common.util.RuningAcitvityUtil
import io.dcloud.feature.sdk.DCSDKInitConfig
import io.dcloud.feature.sdk.DCUniMPCapsuleButtonStyle
import io.dcloud.feature.sdk.DCUniMPSDK

class App : Application() {
    private val tag = "FlutterUniSDK"
    override fun onCreate() {
        super.onCreate()
        // 主app初始化
        if ("com.jayshanx.flutter_uniapp" == RuningAcitvityUtil.getAppName(baseContext)) {
            if (!DCUniMPSDK.getInstance().isInitialize) {
                Log.i(tag, "初始化 uni小程序SDK")
                val style = DCUniMPCapsuleButtonStyle()
                style.setBackgroundColor("rgba(0,0,0,0)")
                style.setTextColor("#FFFFFF")
                val config: DCSDKInitConfig = DCSDKInitConfig.Builder()
                        .setCapsule(true)
                        .setMenuDefFontSize("16px")
                        .setMenuDefFontWeight("normal")
                        .setEnableBackground(true)
                        .setCapsuleButtonStyle(style)
                        .build()
                DCUniMPSDK.getInstance().initialize(this, config) { b -> Log.i(tag, "onInitFinished----$b") }
            }
        } else if (RuningAcitvityUtil.getAppName(baseContext).contains("unimp")) {
            try {
                WXSDKEngine.registerModule("test", MyUniModule::class.java)
            } catch (e: WXException) {
                e.printStackTrace()
            }
        }
    }
}