package com.jayshanx.flutter_uniapp.unimodule;

import com.alibaba.fastjson.JSONObject;

import io.dcloud.feature.uniapp.annotation.UniJSMethod;
import io.dcloud.feature.uniapp.bridge.UniJSCallback;
import io.dcloud.feature.uniapp.common.UniModule;

public class MyUniModule extends UniModule {
    private static String tag = "FlutterUniSDK";

    @UniJSMethod(uiThread = true)
    public void test(JSONObject options, UniJSCallback callback) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("code", 0);
        jsonObject.put("message", "success");
        callback.invoke(jsonObject);
    }
}
