import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        //自定义插件注册
        self.regisChannel(launchOptions: launchOptions);
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    //注册flutter插件
    func regisChannel(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        //注册小程序插件
        AppletPlugins.register(with: self.registrar(forPlugin: "AppletPlugins")!,launchOptions: launchOptions);
    }
    
    //生命周期
    override func applicationDidBecomeActive(_ application: UIApplication) {
        DCUniMPSDKEngine.applicationDidBecomeActive(application)
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        DCUniMPSDKEngine.applicationWillResignActive(application)
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        DCUniMPSDKEngine.applicationDidEnterBackground(application)
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        DCUniMPSDKEngine.applicationWillEnterForeground(application)
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        DCUniMPSDKEngine.destory()
    }
}
