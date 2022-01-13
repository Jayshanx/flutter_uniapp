import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'global.dart';

const MethodChannel _channel = MethodChannel('com.flutter_uniapp.example');

bool isNullOrEmpty(Object? o) => o == null || o == '';

class UniPlugin {
  //下载地址，可以动态传递，本测试项目固定用本地址
  static const String _downloadUrl = "";
  static final UniPlugin instance = UniPlugin._private();

  UniPlugin._private();

  factory UniPlugin() => instance;

  ///打开小程序
  ///appId         appId
  ///extraData     传递给小程序的参数
  ///redirectPath  直达的页面
  ///download      本地小程序不存在是否下载, 默认下载
  Future<bool?> openUniMP({
    required String appId,
    Map<String, dynamic> extraData = const {},
    String? redirectPath,
    bool download = true,
  }) async {
    var existsApp = await isExistsApp(appId: appId);
    if (!existsApp) {
      // _showInSnackBar("本地不存在小程序资源");
      if (!download) {
        return false;
      }

      _showLoadingDialog();

      // 下载远程wgt包
      var downloadSuccess = await _downLoadWgt(appId, progressCallback: (received, total) {
        debugPrint("received: $received,total: $total");
      });

      if (!downloadSuccess) {
        _showInSnackBar("下载失败");
        navigatorKey.currentState!.pop();
        return false;
      }

      //下载后解压
      var releaseSuccess = await releaseUniMP(appId: appId);
      if (!releaseSuccess) {
        _showInSnackBar("解压失败");
        navigatorKey.currentState!.pop();
        //解压失败
        return false;
      }

      navigatorKey.currentState!.pop();
    }

    return await _channel.invokeMethod<bool?>("openUniMP", {
      "appId": appId,
      "extraData": extraData,
      "redirectPath": redirectPath,
    });
  }

  ///下载并解压到运行目录
  Future<bool> releaseUniMP({required String appId}) async {
    var releaseSuccess = await _channel.invokeMethod<bool?>("releaseUniMP", {"appId": appId});
    return releaseSuccess ?? false;
  }

  /// 判断小程序是否已经存在
  /// [appId] is required.      必填
  Future<bool> isExistsApp({required String appId}) async {
    var result = await _channel.invokeMethod<bool>('isExistsApp', {'appId': appId});
    return result ?? false;
  }

  ///dio下载在线wgt文件
  Future<bool> _downLoadWgt(String appId, {ProgressCallback? progressCallback}) async {
    final future = Completer<bool>();
    Dio dio = Dio();

    String savePath = await _getSavePath(appId);

    ///参数一  URL
    ///参数二  本地目录文件
    ///参数三 下载监听
    try {
      await dio.download(_downloadUrl, savePath, onReceiveProgress: (received, total) async {
        if (progressCallback != null) {
          progressCallback(received, total);
        }
        if (total != -1) {
          ///当前下载的百分比例
          var stringAsFixed = (received / total * 100).toDouble();
          if (stringAsFixed == 100.0) {
            future.complete(true);
          }
        } else {
          future.complete(false);
        }
      });
    } catch (e) {
      // debugPrintStack(stackTrace: e.stackTrace);
      debugPrint(e.toString());
      future.complete(false);
    }

    return future.future;
  }

  ///获取app版本信息
  Future<Map<String, dynamic>?> getAppVersionInfo({required String appId}) async {
    return await _channel.invokeMapMethod<String, dynamic>('getAppVersionInfo', {'appId': appId});
  }

  ///关闭所有小程序
  Future<bool> closeAllApp() async {
    return await _channel.invokeMethod('closeAllApp');
  }

  //获取小程序运行地址 android only
  Future<String?> getAppBasePath() async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod("getAppBasePath");
    }
    return null;
  }

  /// 清除本地所有小程序资源
  Future<void> clearAllAppRuntimeDictionary() async {
    await closeAllApp();

    //获取小程序的运行目录
    String? runningPath;
    if (Platform.isAndroid) {
      runningPath = await getAppBasePath();
    } else {
      runningPath = (await getLibraryDirectory()).path + "/Pandora/apps/";
    }

    if (runningPath == null) {
      return;
    }

    Directory appDirectory = Directory(runningPath);
    int count = 0;
    if (appDirectory.existsSync()) {
      List<FileSystemEntity> appHome = appDirectory.listSync();
      for (var app in appHome) {
        app.deleteSync(recursive: true);
        count++;
      }
    }

    if (count > 0) {
      _showInSnackBar("已清理$count个小程序");
    } else {
      _showInSnackBar("本地没有小程序");
    }
  }

  void _showInSnackBar(String message) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  Future<String> _getSavePath(String appId) async {
    var directory = await getTemporaryDirectory();
    return "${directory.path}/apps/$appId.wgt";
  }

  void _showLoadingDialog() {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: Center(
                  child: Theme(
                    data: ThemeData(cupertinoOverrideTheme: const CupertinoThemeData(brightness: Brightness.dark)),
                    child: const CupertinoActivityIndicator(),
                  ),
                ),
              ),
              const Text(
                "下载中...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
