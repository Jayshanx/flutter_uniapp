//
//  AppletPlugins.swift
//  Runner
//
//  Created by jayshanx on 2022/1/12.
//

import Foundation

class MyUniInstance {
    var uniAppId: String?;
    var uniMPInstance: DCUniMPInstance?;
}

///小程序插件swift端
public class AppletPlugins: NSObject, FlutterPlugin, DCUniMPSDKEngineDelegate {
    static let instance = AppletPlugins.init();
    var runningInstances = Dictionary<String, MyUniInstance>()
    
    override init() {
        super.init();
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.flutter_uniapp.example", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar,launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        self.register(with: registrar)
        instance.initUniSDK(launchOptions: launchOptions);
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>;
        let appId = args?["appId"] as? String;
        let extraData = args?["extraData"] as? Dictionary<String, Any>;
        let redirectPath = args?["redirectPath"] as? String;

        if (call.method == "openUniMP") {
            print("打开小程序......")
            self.preloadUniMP(appId: appId, arguments: extraData, redirectPath: redirectPath)
            result(true);
        } else if(call.method == "releaseUniMP") {
            print("解压小程序......")
            if(self.releaseUniMP(appId: appId)){
                print("✅ 小程序：\(appId ?? "null")资源部署到运行路径中成功")
                result(true);
            } else {
                print("❌ 小程序: \(appId ?? "null")资源部署到运行路径中失败")
                result(false);
            }
        } else if(call.method == "isExistsApp" ) {
            result(self.appletIsExist(appId: appId))
        } else if(call.method == "closeAllApp") {
            result(self.closeAllApplet())
        } else if(call.method == "getAppVersionInfo") {
            result(self.getAppletVersion(appId: appId))
        } else if(call.method == "getAppBasePath"){
            result(DCUniMPSDKEngine.getAppRunPath(withAppid: ""))
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initUniSDK(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // 初始化小程序SDK
        print("===========初始化小程序SDK===========")
        DCUniMPSDKEngine.initSDKEnvironment(launchOptions: ["debug": true]);
        
        // 注册组件
        WXSDKEngine.registerModule("test", with: Bundle.main.classNamed("TestModule"))
        //配置胶囊
        let item1:DCUniMPMenuActionSheetItem = DCUniMPMenuActionSheetItem.init(title: "隐藏到后台", identifier: "enterBackground");
        let item2:DCUniMPMenuActionSheetItem = DCUniMPMenuActionSheetItem.init(title: "关闭小程序", identifier: "closeUniMP");
        
        // 添加到全局配置
        DCUniMPSDKEngine.setDefaultMenuItems([item1,item2])
        
        // 设置 delegate
        DCUniMPSDKEngine.setDelegate(self)
    }
    
    /// 小程序配置信息
    func getUniMPConfiguration() -> DCUniMPConfiguration {
        /// 初始化小程序的配置信息
        let configuration = DCUniMPConfiguration.init()
        // 开启后台运行
        configuration.enableBackground = true
        // 设置 push 打开方式
        //    configuration.openMode = DCUniMPOpenModePush;
        // 启用侧滑手势关闭小程序
        configuration.enableGestureClose = true
        return configuration;
    }
    
    /// 预加载后打开小程序
    func preloadUniMP(appId: String?,arguments: Dictionary<String, Any>?,redirectPath:String?) {
        if(appId == nil){
            print("预加载小程序出错：appid 或者 checkCode 是空的")
            return;
        }
        
        let configuration:DCUniMPConfiguration = self.getUniMPConfiguration();
        configuration.extraData = arguments;
        configuration.path = redirectPath;
        
        /// 为了兼容旧版, 等待合适时机再去掉
        configuration.redirectPath = redirectPath;
        configuration.arguments = arguments;
        
        DCUniMPSDKEngine.preloadUniMP(appId!, configuration: configuration) { uniMPInstance, error in
            if(uniMPInstance != nil ){
                let myUniInstance = MyUniInstance.init();
                myUniInstance.uniAppId = appId!;
                myUniInstance.uniMPInstance = uniMPInstance;
                uniMPInstance?.show(completion: { result, error in
                    if(result){
                        self.runningInstances[appId!] = myUniInstance;
                        print("当前正在运行的小程序个数: \(self.runningInstances.count)");
                    }
                })
            } else {
                print("预加载小程序出错：\(appId!)")
            }
        }
    }
    
    // 将应用资源部署到运行路径中
    func releaseUniMP(appId: String?) -> Bool {
        if(appId == nil) {
            print("解压并打开小程序出错：appid 是空的")
            return false;
        }
        //获取cache路径
        let libraryCachePath:String? = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        let appResourcePath:String = "\(libraryCachePath ?? "")/apps/\(appId!).wgt"
        print("小程序缓存目录：\(appResourcePath)");
        return DCUniMPSDKEngine.releaseAppResourceToRunPath(withAppid: appId!, resourceFilePath: appResourcePath);
    }
    
    //检查小程序是否在本地存在
    func appletIsExist(appId: String?) -> Bool {
        if(appId == nil){
            print("判断是否存在小程序\( appId ?? "null" )失败")
            return false;
        }
        
        return DCUniMPSDKEngine.isExistsApp(appId!);
    }
    
    func closeAllApplet() -> Bool {
        var result:Bool = true;
        print("关闭所有的小程序，当前正在运行的小程序个数\(self.runningInstances.count)");
        for (_, instance) in self.runningInstances {
            instance.uniMPInstance!.close { success, error in
                if(success){
                    result = result && success;
                } else {
                    print("close 小程序出错：\(error.debugDescription)");
                }
            }
        }
        self.runningInstances.removeAll();
        return result;
    }
    
    func getAppletVersion(appId: String?) -> [AnyHashable : Any]? {
        if(appId == nil) {
            return nil;
        }
        return DCUniMPSDKEngine.getUniMPVersionInfo(withAppid: appId!);
    }
    
    
    ///========DCUniMPSDKEngineDelegate===========
    public func uniMP(onClose appid: String) {
        print("小程序 \(appid) 被关闭了");
        self.runningInstances.removeValue(forKey: appid)
        // 可以在这个时机再次打开小程序
    }
    
    /// DCUniMPMenuActionSheetItem 点击触发回调方法
    public func defaultMenuItemClicked(_ appid: String, identifier: String) {
        print("标识为 \(identifier) 的 item 被点击了", identifier);
        
        // 将小程序隐藏到后台
        if (identifier == "enterBackground"){
            self.runningInstances[appid]?.uniMPInstance?.hide(completion: { success, error in
                if(success){
                    print("小程序 \(appid) 进入后台");
                } else {
                    print("hide 小程序出错：\(error.debugDescription)");
                }
            })
        } else if (identifier == "closeUniMP" ) {
            //关闭小程序
            self.runningInstances[appid]?.uniMPInstance?.close(completion: { success, error in
                if(success){
                    self.runningInstances.removeValue(forKey: appid)
                    print("\(appid)关闭成功, 当前正在运行的小程序个数\(self.runningInstances.count)");
                } else {
                    print("close 小程序出错：\(error.debugDescription)");
                }
            })
        }  else if (identifier == "SendUniMPEvent" ) {
            // 向小程序发送消息
            self.runningInstances[appid]?.uniMPInstance?.sendUniMPEvent("NativeEvent", data: ["msg":"native message"])
        }
    }
    ///========DCUniMPSDKEngineDelegate===========
}
