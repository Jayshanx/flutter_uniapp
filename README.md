# flutter_uniapp

flutter + kotlin + swift, 集成uniapp小程序, 只是实例，并不是 package,

flutter: 2.8.0
unisdk: 3.3.5


# 特性
1. flutter 端通过dio下载wgt文件,
2. 运行uni小程序
3. 关闭本地小程序
4. 提供删除本地运行实例

# 开始

 - android 集成教程参考 [uniapp android集成文档](https://nativesupport.dcloud.net.cn/UniMPDocs/UseSdk/android)
 - ios     集成教程参考 [uniapp ios 集成文档](https://nativesupport.dcloud.net.cn/UniMPDocs/UseSdk/ios)


android,sdk已经上传git, 在src同级别libs目录下, 可以简单测试
ios端集成需要参考官方文档

1. 修改 main.dart 中的 appId
2. 修改 uni_plugin.dart 中的 _downloadUrl 为自己的远程 wgt 地址

