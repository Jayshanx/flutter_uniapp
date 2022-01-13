package com.jayshanx.flutter_uniapp.plugins

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import io.dcloud.feature.sdk.DCUniMPSDK
import io.dcloud.feature.sdk.Interface.IUniMP
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * flutter 跳转到小程序, flutter->native->小程序
 * @author xiao
 * */

@Suppress("UNCHECKED_CAST")
class SmallAppPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private val channelId = "com.flutter_uniapp.example"

    //为了解决并发问题，比如多次点击，异常情况时候容易出问题
    private val wrappers = ConcurrentLinkedQueue<MethodResultWrapper>()
    private lateinit var channel: MethodChannel
    private lateinit var activity: Activity

    private var tag = "FlutterUniSDK"

    /** unimp小程序实例缓存 */
    companion object {
        var mUniMPCaches = ConcurrentHashMap<String, MyUniMPInstance>()
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, channelId)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val wrapper = this.clearAndGetWrapper(MethodResultWrapper(result))
        when (call.method) {
            //启动远程小程序,推荐正式环境使用
            "openUniMP" -> {
                val params = call.arguments as Map<*, *>
                val appId = params["appId"] as String?
                val extraData = JSONObject(params["extraData"] as Map<String?, Any?>)
                val redirectPath = params["redirectPath"] as String?
                Log.i(tag, "openUniMP==== $appId,=== 参数===${params}")

                if (appId == null) {
                    wrapper?.error("-1", "appId is null", null)
                    return
                }

                try {
                    val openUniMP: IUniMP? = DCUniMPSDK.getInstance().openUniMP(activity.applicationContext, appId, null, redirectPath, extraData)
                    if (openUniMP != null) {
                        mUniMPCaches[appId] = MyUniMPInstance(appId, openUniMP)
                        wrapper?.success(true)
                    } else {
                        wrapper?.error("-1", "error", null)
                    }
                } catch (e: Exception) {
                    Log.i(tag, "打开${appId}失败,${e.message}")
                    wrapper?.error("-1", e.message, null)
                }
            }
            "releaseUniMP" -> {
                val params = call.arguments as Map<*, *>
                Log.i(tag, "正在打开远程小程序")
                val appId = params["appId"] as String?
                if (appId == null) {
                    wrapper?.error("-1", "appId is null", null)
                    return
                }

                val cacheDir = "${activity.cacheDir.absolutePath}/apps/${appId}.wgt"
                DCUniMPSDK.getInstance().releaseWgtToRunPathFromPath(appId, cacheDir) { code, pArgs ->
                    Log.i(tag, "code=${code},pArgs=${pArgs},downloadPath=$cacheDir")
                    if (code == 1) {
                        wrapper?.success(true)
                    } else {
                        //释放wgt失败
                        Toast.makeText(activity, "资源释放失败", Toast.LENGTH_SHORT).show()
                        wrapper?.error("-1", "release fail", null)
                    }
                }
            }
            "isExistsApp" -> {
                //判断app是否存在
                val params = call.arguments as Map<*, *>
                val appId = params["appId"] as String?
                if (appId == null) {
                    wrapper?.error("-1", "appId is null", null)
                    return
                }
                wrapper?.success(DCUniMPSDK.getInstance().isExistsApp(appId))
            }
            "getAppVersionInfo" -> {
                //获取小程序的版本信息
                val params = call.arguments as Map<*, *>
                val appId = params["appId"] as String?
                if (appId == null) {
                    wrapper?.error("-1", "appId is null", null)
                    return
                }

                val appletVersion: JSONObject? = DCUniMPSDK.getInstance().getAppVersionInfo(appId)
                if (appletVersion != null) {
                    wrapper?.success(jsonObjectToMap(appletVersion))
                } else {
                    wrapper?.success(null)
                }
            }
            "closeAllApp" -> {
                Log.i(tag, "closeAllApp")
                this.clearAppletTaskActivity()
                wrapper?.success(true)
            }
            "getAppBasePath" -> {
                wrapper?.success(DCUniMPSDK.getInstance().getAppBasePath(activity.applicationContext))
            }


        }
    }

    private fun jsonObjectToMap(jsonObject: JSONObject): MutableMap<String, String> {
        val map: MutableMap<String, String> = HashMap()
        val keys = jsonObject.keys()
        while (keys.hasNext()) {
            val next = keys.next()
            map[next] = jsonObject.getString(next)
        }
        return map
    }


    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        setupUniapp()
    }

    //配置小程序
    private fun setupUniapp() {
        Log.i(tag, "初始化 uni小程序SDK")
        //点击右上角的关闭按钮
        DCUniMPSDK.getInstance().setCapsuleCloseButtonClickCallBack { appid ->
            Log.e(tag, "closeButtonClicked-------------$appid")
            val instance = mUniMPCaches[appid]
            if (instance != null) {
                val uniMP: IUniMP = instance.uniMPInstance
                if (uniMP.isRuning) {
                    Log.e(tag, "${appid}正在运行，将隐藏")
                    uniMP.hideUniMP()
                    Toast.makeText(activity, appid + "隐藏到后台", Toast.LENGTH_SHORT).show()
                } else {
                    Log.e(tag, "${appid}没有运行")
                }
            } else {
                Log.e(tag, "closeButtonClicked-------------失败")
            }
        }

        //设置小程序被关闭事件监听
        DCUniMPSDK.getInstance().setUniMPOnCloseCallBack { appid: String ->
            run {
                Log.i(tag, "$appid 关闭了==>")
                val instance: MyUniMPInstance? = mUniMPCaches[appid]
                if (instance != null) {
                    instance.uniMPInstance.closeUniMP()
                    mUniMPCaches.remove(appid)
                }
            }
        }

        //设置小程序胶囊按钮点击"..."菜单事件监听，设置后原菜单弹窗逻辑将不再执行！交由宿主实现相关逻辑。v3.2.6
        DCUniMPSDK.getInstance().setCapsuleMenuButtonClickCallBack { appid ->
            Log.e(tag, appid + "胶囊点击了菜单按钮")
            Toast.makeText(activity, appid + "胶囊点击了菜单按钮", Toast.LENGTH_SHORT).show()
            //可以通过下面的方式跳转其他activity
//            DCUniMPSDK.getInstance().startActivityForUniMPTask(appid, Intent())
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onDetachedFromActivity() {
        clearAppletTaskActivity()
    }

    private fun clearAppletTaskActivity() {
        mUniMPCaches.forEach { entry ->
            entry.value.uniMPInstance.closeUniMP()
        }
        mUniMPCaches.clear()
    }

    // MethodChannel.Result wrapper that responds on the platform thread.
    private class MethodResultWrapper(private val methodResult: MethodChannel.Result) : MethodChannel.Result {
        private val handler: Handler = Handler(Looper.getMainLooper())
        override fun success(result: Any?) {
            handler.post { methodResult.success(result) }
        }

        override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
            handler.post { methodResult.error(errorCode, errorMessage, errorDetails) }
        }

        override fun notImplemented() {
            handler.post { methodResult.notImplemented() }
        }
    }

    private fun clearAndGetWrapper(wrapper: MethodResultWrapper): MethodResultWrapper? {
        wrappers.clear()
        wrappers.add(wrapper)
        return if (wrappers.isEmpty()) {
            null
        } else wrappers.first()
    }
}