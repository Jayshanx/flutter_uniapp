import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'global.dart';
import 'uni_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter uniapp example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'flutter uniapp example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String appId = "__UNI__659E79A";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: () async {
                var exist = await UniPlugin.instance.isExistsApp(appId: appId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    "本地${exist ? "存在" : "不存在"}小程序",
                  ),
                  duration: const Duration(seconds: 1),
                ));
              },
              child: Text("检查本地是否存在小程序  ($appId)"),
            ),
            TextButton(
              onPressed: () {
                UniPlugin.instance.openUniMP(appId: appId);
              },
              child: Text("打开远程小程序 ($appId)"),
            ),
            TextButton(
              onPressed: () async {
                var appVersionInfo = await UniPlugin.instance.getAppVersionInfo(appId: appId);
                String alertText = appVersionInfo?.toString() ?? "本地没有小程序或者获取失败";
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(alertText),
                  duration: const Duration(seconds: 1),
                ));
              },
              child: Text("获取当前版本  ($appId)"),
            ),
            TextButton(
              onPressed: () async {
                await UniPlugin.instance.clearAllAppRuntimeDictionary();
              },
              child: const Text("清除本地所有小程序"),
            )
          ],
        ),
      ),
    );
  }
}
