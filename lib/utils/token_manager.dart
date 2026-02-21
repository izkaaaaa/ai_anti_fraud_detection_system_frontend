// Token 管理工具

import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _tokenTypeKey = 'token_type';
  
  String? _token;
  String _tokenType = 'Bearer';

  /// 获取 token
  String get token => _token ?? '';

  /// 获取 token 类型
  String get tokenType => _tokenType;

  /// 是否已登录
  bool isLoggedIn() {
    return _token != null && _token!.isNotEmpty;
  }

  /// 保存 token
  Future<void> saveToken(String token, {String tokenType = 'Bearer'}) async {
    _token = token;
    _tokenType = tokenType;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_tokenTypeKey, tokenType);
  }

  /// 加载 token
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _tokenType = prefs.getString(_tokenTypeKey) ?? 'Bearer';
  }

  /// 清除 token
  Future<void> clearToken() async {
    _token = null;
    _tokenType = 'Bearer';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenTypeKey);
  }
}

// 单例对象
final tokenManager = TokenManager();

