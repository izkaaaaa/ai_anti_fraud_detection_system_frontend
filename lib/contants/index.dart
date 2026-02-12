// 定义常量数据，基础地址，超时时间，业务状态，请求地址
import 'dart:io';
import 'package:flutter/foundation.dart';

// 全局的常量
class GlobalConstants {
  // 根据平台自动切换 API 地址
  static String get BASE_URL {
    // 打印平台信息（调试用）
    print('🔍 平台检测:');
    print('   kIsWeb: $kIsWeb');
    if (!kIsWeb) {
      print('   Platform.isAndroid: ${Platform.isAndroid}');
      print('   Platform.isIOS: ${Platform.isIOS}');
    }
    
    if (kIsWeb) {
      // Web 平台使用 localhost
      print('   ✅ 使用 Web 配置');
      return "http://localhost:8000";
    } else if (!kIsWeb && Platform.isAndroid) {
      // Android 使用后端电脑的局域网 IP
      print('   ✅ 使用 Android 配置');
      return "http://172.20.16.1:8000";
    } else if (!kIsWeb && Platform.isIOS) {
      // iOS 使用后端电脑的局域网 IP
      print('   ✅ 使用 iOS 配置');
      return "http://172.20.16.1:8000";
    } else {
      // 其他平台默认使用 localhost
      print('   ⚠️ 使用默认配置');
      return "http://localhost:8000";
    }
  }
  
  static const int TIME_OUT = 10; // 超时时间（秒）
  static const String TOKEN_KEY = "auth_token"; // token 键名
}

// 存放请求地址接口的常量
class HttpConstants {
  // 认证相关接口
  static const String LOGIN = "/api/users/login"; // 登录请求地址
  static const String REGISTER = "/api/users/register"; // 注册请求地址
  static const String SEND_SMS_CODE = "/api/users/send-code"; // 发送验证码地址
  static const String USER_PROFILE = "/api/users/profile"; // 用户信息接口地址
  
  // 系统接口
  static const String HEALTH = "/health"; // 健康检查接口
  
  // 其他接口可以在这里添加
  // static const String DETECTION = "/api/detection"; // 检测接口
}