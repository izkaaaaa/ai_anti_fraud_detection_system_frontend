import 'package:ai_anti_fraud_detection_system_frontend/routes/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';

void main(List<String> args) async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化认证服务
  await AuthService().init();
  
  // 启动应用
  runApp(getRootWidget());
}