// 管理路由
import 'package:ai_anti_fraud_detection_system_frontend/pages/Login/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Main/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Register/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Settings/PermissionSettings.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/SecurityReport/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/UserAgreement/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/AudioRecordingTestPage.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';

// 返回App根级组件
Widget getRootWidget(){
  // 根据登录状态决定初始路由
  final isLoggedIn = AuthService().isLoggedIn;
  
  return MaterialApp(
    // 命名路由
    initialRoute: "/audio-test",  // 临时改为测试页面
    routes: getRootRoutes(),
  );
}

Map<String, Widget Function(BuildContext)> getRootRoutes(){
  return {
    "/": (context) => MainPage(), // 主页路由
    "/login": (context) => LoginPage(), // 登录路由
    "/register": (context) => RegisterPage(), // 注册路由
    "/permission-settings": (context) => PermissionSettingsPage(), // 权限设置路由
    "/security-report": (context) => SecurityReportPage(), // 安全报告路由
    "/user-agreement": (context) => UserAgreementPage(), // 用户协议路由
    "/audio-test": (context) => AudioRecordingTestPage(), // 音频录制 POC 测试路由
  };
}