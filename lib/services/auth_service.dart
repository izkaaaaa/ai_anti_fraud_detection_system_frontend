import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'dart:convert';
import 'dart:math';

/// 认证服务 - 统一管理 Token 和用户信息
/// 
/// 功能：
/// 1. Token 管理（存储、获取、清除）
/// 2. 用户信息管理
/// 3. 认证业务逻辑（登录、注册、登出）
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Token 相关
  String _accessToken = '';
  String _tokenType = 'Bearer';
  
  // 用户信息
  Map<String, dynamic>? _userInfo;

  // SharedPreferences 键名
  static const String _tokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _userInfoKey = 'user_info';

  /// 获取当前 Token
  String? get accessToken => _accessToken.isEmpty ? null : _accessToken;
  
  /// 获取 Token（同步方法）
  String getToken() {
    return _accessToken;
  }
  
  /// 获取 Token 类型
  String getTokenType() {
    return _tokenType;
  }

  /// 获取当前用户信息
  Map<String, dynamic>? get userInfo => _userInfo;

  /// 是否已登录
  bool get isLoggedIn => _accessToken.isNotEmpty;

  /// 初始化 - 从本地存储读取 Token 和用户信息
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载 Token
      _accessToken = prefs.getString(_tokenKey) ?? '';
      
      // 加载 Token Type，统一使用 Bearer（首字母大写）
      String savedTokenType = prefs.getString(_tokenTypeKey) ?? 'Bearer';
      _tokenType = savedTokenType.toLowerCase() == 'bearer' ? 'Bearer' : savedTokenType;
      
      // 加载用户信息
      final userInfoStr = prefs.getString(_userInfoKey);
      if (userInfoStr != null && userInfoStr.isNotEmpty) {
        try {
          // 使用 json.decode 解析
          final decoded = jsonDecode(userInfoStr);
          if (decoded is Map<String, dynamic>) {
            _userInfo = decoded;
          }
        } catch (e) {
          print('⚠️ 解析用户信息失败: $e');
          _userInfo = null;
        }
      }
      
      print('🔑 AuthService 初始化完成');
      print('   Token: ${_accessToken.isNotEmpty ? "已加载 (${_accessToken.substring(0, min(_accessToken.length, 20))}...)" : "未登录"}');
      print('   Token Type: $_tokenType');
      print('   用户信息: ${_userInfo != null ? "已加载 (${_userInfo!['username']})" : "无"}');
    } catch (e) {
      print('❌ AuthService 初始化失败: $e');
    }
  }

  /// 登录 - 邮箱 + 验证码
  Future<bool> loginWithEmailCode(String email, String emailCode) async {
    try {
      print('🔐 开始登录（邮箱+验证码）: $email');
      
      final response = await dioRequest.post(
        '/api/users/login',
        data: {
          'email': email,
          'email_code': emailCode,
        },
      );

      if (response != null) {
        _accessToken = response['access_token'] ?? '';
        String backendTokenType = response['token_type'] ?? 'bearer';
        _tokenType = backendTokenType.toLowerCase() == 'bearer' ? 'Bearer' : backendTokenType;
        _userInfo = response['user'];

        await _saveToLocal();

        print('✅ 登录成功');
        print('   用户: ${_userInfo?['username']}');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ 登录失败: $e');
      return false;
    }
  }

  /// 登录 - 邮箱 + 密码
  Future<bool> loginWithEmailPassword(String email, String password) async {
    try {
      print('🔐 开始登录（邮箱+密码）: $email');
      
      final response = await dioRequest.post(
        '/api/users/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response != null) {
        _accessToken = response['access_token'] ?? '';
        String backendTokenType = response['token_type'] ?? 'bearer';
        _tokenType = backendTokenType.toLowerCase() == 'bearer' ? 'Bearer' : backendTokenType;
        _userInfo = response['user'];

        await _saveToLocal();

        print('✅ 登录成功');
        print('   用户: ${_userInfo?['username']}');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ 登录失败: $e');
      return false;
    }
  }

  /// 登录 - 手机号 + 密码
  Future<bool> loginWithPhonePassword(String phone, String password) async {
    try {
      print('🔐 开始登录（手机号+密码）: $phone');
      
      final response = await dioRequest.post(
        '/api/users/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );

      if (response != null) {
        _accessToken = response['access_token'] ?? '';
        String backendTokenType = response['token_type'] ?? 'bearer';
        _tokenType = backendTokenType.toLowerCase() == 'bearer' ? 'Bearer' : backendTokenType;
        _userInfo = response['user'];

        await _saveToLocal();

        print('✅ 登录成功');
        print('   用户: ${_userInfo?['username']}');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ 登录失败: $e');
      return false;
    }
  }

  /// 注册
  Future<bool> register({
    required String phone,
    required String username,
    required String name,
    required String email,
    required String emailCode,
    required String password,
    String? roleType,
    String? gender,
    String? profession,
    String? maritalStatus,
  }) async {
    try {
      print('📝 开始注册: $phone');
      
      final data = {
        'phone': phone,
        'username': username,
        'name': name,
        'email': email,
        'email_code': emailCode,
        'password': password,
      };
      
      // 添加可选字段
      if (roleType != null) data['role_type'] = roleType;
      if (gender != null) data['gender'] = gender;
      if (profession != null) data['profession'] = profession;
      if (maritalStatus != null) data['marital_status'] = maritalStatus;
      
      final response = await dioRequest.post(
        '/api/users/register',
        data: data,
      );

      if (response != null) {
        print('✅ 注册成功');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ 注册失败: $e');
      return false;
    }
  }

  /// 获取当前用户信息
  /// 
  /// [forceRefresh] 是否强制从服务器刷新（默认 false，使用缓存）
  Future<Map<String, dynamic>?> getCurrentUser({bool forceRefresh = false}) async {
    print('👤 getCurrentUser 被调用 (forceRefresh: $forceRefresh)');
    print('   当前 Token: ${_accessToken.isNotEmpty ? _accessToken : "无"}');
    print('   缓存的用户信息: ${_userInfo ?? "无"}');
    
    // 检查是否已登录
    if (_accessToken.isEmpty) {
      print('⚠️ 未登录，无法获取用户信息');
      return null;
    }
    
    // 如果不强制刷新，且有缓存的用户信息，直接返回
    if (!forceRefresh && _userInfo != null && _userInfo!.isNotEmpty && _userInfo!.containsKey('username')) {
      print('✅ 返回缓存的用户信息');
      return _userInfo;
    }

    try {
      print('📡 从服务器获取用户信息');
      
      final response = await dioRequest.get('/api/users/me');

      if (response != null) {
        _userInfo = response;
        await _saveToLocal();
        
        print('✅ 用户信息获取成功: ${_userInfo?['username']}, family_id: ${_userInfo?['family_id']}');
        return _userInfo;
      }

      return null;
    } catch (e) {
      print('❌ 获取用户信息失败: $e');
      
      // 如果是 401，说明 Token 过期
      if (e is DioException && e.response?.statusCode == 401) {
        print('   Token 已过期，清除登录状态');
        await logout();
      }
      
      return null;
    }
  }

  /// 登出
  Future<void> logout() async {
    print('👋 登出');
    
    // 清空内存中的数据
    _accessToken = '';
    _tokenType = 'Bearer';
    _userInfo = null;

    // 清除本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_userInfoKey);
    
    print('✅ 登出成功');
  }

  /// 保存到本地存储
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 保存 Token
      if (_accessToken.isNotEmpty) {
        await prefs.setString(_tokenKey, _accessToken);
        await prefs.setString(_tokenTypeKey, _tokenType);
      }
      
      // 保存用户信息
      if (_userInfo != null && _userInfo!.isNotEmpty) {
        // 使用 json.encode 序列化
        await prefs.setString(_userInfoKey, jsonEncode(_userInfo));
      }
      
      print('💾 数据已保存到本地');
    } catch (e) {
      print('❌ 保存失败: $e');
    }
  }

  /// 创建带 Token 的 Dio 实例（供其他页面使用）
  /// 
  /// ⚠️ 已废弃：建议直接使用 dioRequest，它会自动从 AuthService 获取 token
  @Deprecated('请直接使用 dioRequest')
  Dio createAuthDio() {
    print('⚠️ createAuthDio 已废弃，请直接使用 dioRequest');
    
    final dio = Dio(BaseOptions(
      baseUrl: 'http://172.20.16.1:8000',
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));

    // 添加拦截器，自动添加 Token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken.isNotEmpty) {
          options.headers['Authorization'] = '$_tokenType $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // 如果是 401，自动登出
        if (error.response?.statusCode == 401) {
          print('⚠️ Token 过期，需要重新登录');
          logout();
        }
        return handler.next(error);
      },
    ));

    return dio;
  }
}