//
//  TestModule.m
//  TestModule 小程序调用原生方法模块
//
//  Created by jayshanx on 2022/1/12.
//
//

#import "TestModule.h"
#import "Runner-Swift.h"

@implementation TestModule
@synthesize weexInstance;

// 通过宏 WX_EXPORT_METHOD 将异步方法暴露给 js 端
WX_EXPORT_METHOD(@selector(test:callback:))

///  开启定位
/// 异步方法（注：异步方法会在主线程（UI线程）执行）
/// @param options js 端调用方法时传递的参数
/// @param callback 回调方法，回传参数给 js 端
- (void)test:(NSDictionary *)options callback:(WXModuleKeepAliveCallback)callback {
    // options 为 js 端调用此方法时传递的参数
    // 回调方法，传递参数给 js 端 注：只支持返回 String 或 NSDictionary (map) 类型
    if (callback) {
        // 第一个参数为回传给js端的数据，第二个参数为标识，表示该回调方法是否支持多次调用，如果原生端需要多次回调js端则第二个参数传 YES;
        callback(@"success",NO);
    }
}
@end
