// 用户状态管理

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_anti_fraud_detection_system_frontend/viewmodels/login_models.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/token_manager.dart';
import 'dart:convert';

class UserStore {
  static const String _userInfoKey = 'user_info';
  
  User? _currentUser;
  bool _isLoggedIn = false;

  /// 获取当前用户
  User? get currentUser => _currentUser;

  /// 是否已登录
  bool get isLoggedIn => _isLoggedIn;

  /// 登录成功后保存用户信息和 token
  Future<void> login(LoginResponse loginResponse) async {
    // 保存 token
    await tokenManager.saveToken(
      loginResponse.accessToken,
      tokenType: loginResponse.tokenType,
    );
    
    // 保存用户信息
    _currentUser = loginResponse.user;
    _isLoggedIn = true;
    
    // 持久化用户信息到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInfoKey, jsonEncode(loginResponse.user.toJson()));
  }

  /// 从本地加载用户信息
  Future<void> loadUserInfo() async {
    // 加载 token
    await tokenManager.loadToken();
    
    // 加载用户信息
    final prefs = await SharedPreferences.getInstance();
    final userInfoStr = prefs.getString(_userInfoKey);
    
    if (userInfoStr != null && userInfoStr.isNotEmpty) {
      try {
        final userJson = jsonDecode(userInfoStr) as Map<String, dynamic>;
        _currentUser = User.fromJson(userJson);
        _isLoggedIn = tokenManager.isLoggedIn();
      } catch (e) {
        // 解析失败，清除数据
        await logout();
      }
    }
  }

  /// 更新用户信息
  Future<void> updateUserInfo(User user) async {
    _currentUser = user;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInfoKey, jsonEncode(user.toJson()));
  }

  /// 登出
  Future<void> logout() async {
    // 清除 token
    await tokenManager.clearToken();
    
    // 清除用户信息
    _currentUser = null;
    _isLoggedIn = false;
    
    // 清除本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userInfoKey);
  }

  /// 检查登录状态
  bool checkLoginStatus() {
    return tokenManager.isLoggedIn() && _currentUser != null;
  }
}

// 单例对象
final userStore = UserStore();

