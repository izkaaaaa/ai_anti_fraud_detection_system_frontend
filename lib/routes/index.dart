// 管理路由
import 'package:ai_anti_fraud_detection_system_frontend/pages/Login/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Main/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Test/index.dart';
import 'package:flutter/material.dart';

// 返回App根级组件
Widget getRootWidget(){
  return MaterialApp(
    // 命名路由
    initialRoute:"/",
    routes: getRootRoutes(),
  );
}

Map<String, Widget Function(BuildContext)> getRootRoutes(){
  return {
    "/": (context) => LoginPage(), // 主页路由
    "/login": (context) => LoginPage(), // 登录路由
    "/test": (context) => TestPage(), // 测试路由
  };
}