import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/token_manager.dart';

/// 认证服务 - 管理 Token 和用户信息
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Token 和用户信息
  String? _accessToken;
  Map<String, dynamic>? _userInfo;

  /// 获取当前 Token
  String? get accessToken => _accessToken;

  /// 获取当前用户信息
  Map<String, dynamic>? get userInfo => _userInfo;

  /// 是否已登录
  bool get isLoggedIn => _accessToken != null;

  /// 初始化 - 从本地存储读取 Token
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      final userInfoStr = prefs.getString('user_info');
      
      if (userInfoStr != null) {
        _userInfo = Map<String, dynamic>.from(
          // 这里需要 json decode，但为了简单先这样
          {} // TODO: 实际应该用 json.decode
        );
      }
      
      // 同步加载到 TokenManager（重要！）
      await tokenManager.loadToken();
      
      print('🔑 AuthService 初始化');
      print('   Token: ${_accessToken != null ? "已加载" : "未登录"}');
      print('   TokenManager: ${tokenManager.isLoggedIn() ? "已同步" : "未同步"}');
    } catch (e) {
      print('❌ AuthService 初始化失败: $e');
    }
  }

  /// 登录
  Future<bool> login(String account, String password) async {
    try {
      print('🔐 开始登录: $account');
      
      final response = await dioRequest.post(
        '/api/users/login',
        data: {
          'phone': account,
          'password': password,
        },
      );

      if (response != null) {
        _accessToken = response['access_token'];
        _userInfo = response['user'];
        
        // 获取 token_type，默认为 bearer
        final tokenType = response['token_type'] ?? 'bearer';

        // 保存到本地
        await _saveToLocal();
        
        // 同步保存到 TokenManager（重要！）
        await tokenManager.saveToken(_accessToken!, tokenType: tokenType);

        print('✅ 登录成功');
        print('   Token: $_accessToken');
        print('   Token Type: $tokenType');
        print('   用户: ${_userInfo?['username']}');
        print('   已同步到 TokenManager ✅');
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
    String? name,
    required String password,
    required String smsCode,
  }) async {
    try {
      print('📝 开始注册: $phone');
      
      final response = await dioRequest.post(
        '/api/users/register',
        data: {
          'phone': phone,
          'username': username,
          'name': name,
          'password': password,
          'sms_code': smsCode,
        },
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
  Future<Map<String, dynamic>?> getCurrentUser() async {
    print('👤 getCurrentUser 被调用');
    print('   当前 Token: ${_accessToken ?? "无"}');
    print('   缓存的用户信息: ${_userInfo ?? "无"}');
    
    // 如果有缓存的用户信息，直接返回
    if (_userInfo != null) {
      print('✅ 返回缓存的用户信息');
      return _userInfo;
    }
    
    if (_accessToken == null) {
      print('⚠️ 未登录，无法获取用户信息');
      return null;
    }

    try {
      print('📡 从服务器获取用户信息');
      
      final response = await dioRequest.get('/api/users/me');

      if (response != null) {
        _userInfo = response;
        await _saveToLocal();
        
        print('✅ 用户信息获取成功: ${_userInfo?['username']}');
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
    
    _accessToken = null;
    _userInfo = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_info');
    
    // 同步清除 TokenManager（重要！）
    await tokenManager.clearToken();
    
    print('✅ 登出成功');
    print('   TokenManager 已清除 ✅');
  }

  /// 保存到本地存储
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_accessToken != null) {
        await prefs.setString('access_token', _accessToken!);
      }
      
      // TODO: 保存用户信息（需要 json.encode）
      
      print('💾 Token 已保存到本地');
    } catch (e) {
      print('❌ 保存失败: $e');
    }
  }

  /// 创建带 Token 的 Dio 实例（供其他页面使用）
  Dio createAuthDio() {
    // 注意：这个方法已废弃，建议直接使用 dioRequest
    // dioRequest 会自动从 tokenManager 获取 token
    print('⚠️ createAuthDio 已废弃，请直接使用 dioRequest');
    
    final dio = Dio(BaseOptions(
      baseUrl: 'http://172.20.16.1:8000',
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));

    // 添加拦截器，自动添加 Token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
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