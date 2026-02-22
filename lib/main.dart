import 'package:ai_anti_fraud_detection_system_frontend/routes/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main(List<String> args) async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化前台服务配置（录屏需要）
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'screen_recording_channel',
      channelName: '屏幕录制',
      channelDescription: '正在录制屏幕',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
    ),
  );
  
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