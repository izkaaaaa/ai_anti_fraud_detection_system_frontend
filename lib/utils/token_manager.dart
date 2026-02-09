// Token 管理工具类
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _tokenTypeKey = 'token_type';
  
  String _token = '';
  String _tokenType = 'bearer';

  /// 获取 Token
  String getToken() {
    return _token;
  }

  /// 获取 Token 类型
  String getTokenType() {
    return _tokenType;
  }

  /// 保存 Token 到内存和本地存储
  Future<void> saveToken(String token, {String tokenType = 'bearer'}) async {
    _token = token;
    _tokenType = tokenType;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_tokenTypeKey, tokenType);
  }

  /// 从本地存储加载 Token
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey) ?? '';
    _tokenType = prefs.getString(_tokenTypeKey) ?? 'bearer';
  }

  /// 清除 Token
  Future<void> clearToken() async {
    _token = '';
    _tokenType = 'bearer';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenTypeKey);
  }

  /// 检查是否已登录
  bool isLoggedIn() {
    return _token.isNotEmpty;
  }
}

// 单例对象
final tokenManager = TokenManager();


