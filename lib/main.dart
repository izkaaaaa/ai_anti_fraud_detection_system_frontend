import 'package:ai_anti_fraud_detection_system_frontend/routes/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(List<String> args) async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化认证服务
  await AuthService().init();
  
  // 检查是否首次启动
  await _checkFirstLaunch();
  
  // 启动应用
  runApp(getRootWidget());
}

/// 检查是否首次启动并请求权限
Future<void> _checkFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
  
  if (isFirstLaunch) {
    // 标记为非首次启动
    await prefs.setBool('is_first_launch', false);
    
    // 首次启动时会在登录后的主页面请求权限
    // 这里只是标记，实际请求在 HomePage 中进行
  }
}