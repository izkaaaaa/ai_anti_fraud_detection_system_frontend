// 认证相关的 API 接口

import 'package:ai_anti_fraud_detection_system_frontend/contants/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/viewmodels/login_models.dart';

/// 发送注册验证码 API
/// 
/// 参数:
/// - email: 邮箱
/// 
/// 返回: Map 包含 code, message, data
Future<Map<String, dynamic>> sendRegisterCodeAPI(String email) async {
  try {
    final response = await dioRequest.post(
      '/api/users/send-code',
      data: {'email': email},
    );
    
    return response as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}

/// 发送登录验证码 API
/// 
/// 参数:
/// - email: 邮箱
/// 
/// 返回: Map 包含 code, message, data
Future<Map<String, dynamic>> sendLoginCodeAPI(String email) async {
  try {
    final response = await dioRequest.post(
      '/api/users/send-login-code',
      data: {'email': email},
    );
    
    return response as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}

/// 登录 API - 邮箱 + 验证码
/// 
/// 参数:
/// - email: 邮箱
/// - emailCode: 邮箱验证码
/// 
/// 返回: LoginResponse 对象
Future<LoginResponse> loginWithEmailCodeAPI(String email, String emailCode) async {
  try {
    final requestData = {
      'email': email,
      'email_code': emailCode,
    };
    
    final response = await dioRequest.post(
      '/api/users/login',
      data: requestData,
    );
    
    return LoginResponse.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    rethrow;
  }
}

/// 登录 API - 邮箱 + 密码
/// 
/// 参数:
/// - email: 邮箱
/// - password: 密码
/// 
/// 返回: LoginResponse 对象
Future<LoginResponse> loginWithEmailPasswordAPI(String email, String password) async {
  try {
    final requestData = {
      'email': email,
      'password': password,
    };
    
    final response = await dioRequest.post(
      '/api/users/login',
      data: requestData,
    );
    
    return LoginResponse.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    rethrow;
  }
}

/// 登录 API - 手机号 + 密码
/// 
/// 参数:
/// - phone: 手机号
/// - password: 密码
/// 
/// 返回: LoginResponse 对象
Future<LoginResponse> loginWithPhonePasswordAPI(String phone, String password) async {
  try {
    final requestData = {
      'phone': phone,
      'password': password,
    };
    
    final response = await dioRequest.post(
      '/api/users/login',
      data: requestData,
    );
    
    return LoginResponse.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    rethrow;
  }
}

/// 注册 API
/// 
/// 参数:
/// - phone: 手机号
/// - username: 用户名
/// - name: 姓名
/// - email: 邮箱
/// - emailCode: 邮箱验证码
/// - password: 密码
/// - roleType: 角色类型（可选）
/// - gender: 性别（可选）
/// - profession: 职业（可选）
/// - maritalStatus: 婚姻状况（可选）
/// 
/// 返回: RegisterResponse 对象
Future<RegisterResponse> registerAPI({
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
    final requestData = {
      'phone': phone,
      'username': username,
      'name': name,
      'email': email,
      'email_code': emailCode,
      'password': password,
    };
    
    // 只添加非空的可选字段
    if (roleType != null && roleType.isNotEmpty) {
      requestData['role_type'] = roleType;
    }
    if (gender != null && gender.isNotEmpty) {
      requestData['gender'] = gender;
    }
    if (profession != null && profession.isNotEmpty) {
      requestData['profession'] = profession;
    }
    if (maritalStatus != null && maritalStatus.isNotEmpty) {
      requestData['marital_status'] = maritalStatus;
    }
    
    final response = await dioRequest.post(
      '/api/users/register',
      data: requestData,
    );
    
    return RegisterResponse.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    rethrow;
  }
}

/// 更新用户画像 API
/// 
/// 参数:
/// - roleType: 角色类型（可选）
/// - gender: 性别（可选）
/// - profession: 职业（可选）
/// - maritalStatus: 婚姻状况（可选）
/// 
/// 返回: Map 包含更新后的用户信息
Future<Map<String, dynamic>> updateUserProfileAPI({
  String? roleType,
  String? gender,
  String? profession,
  String? maritalStatus,
}) async {
  try {
    final data = <String, dynamic>{};
    if (roleType != null) data['role_type'] = roleType;
    if (gender != null) data['gender'] = gender;
    if (profession != null) data['profession'] = profession;
    if (maritalStatus != null) data['marital_status'] = maritalStatus;
    
    final response = await dioRequest.put(
      '/api/users/profile',
      data: data,
    );
    
    return response as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}

/// 获取用户信息 API
/// 
/// 返回: User 对象
Future<User> getUserInfoAPI() async {
  try {
    final response = await dioRequest.get('/api/users/me');
    return User.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    rethrow;
  }
}

/// 获取监护人信息 API
/// 
/// 返回: Map 包含监护人列表
Future<Map<String, dynamic>> getGuardianInfoAPI() async {
  try {
    final response = await dioRequest.get('/api/users/guardian');
    return response as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}

/// 解绑家庭组 API
/// 
/// 返回: Map 包含操作结果
Future<Map<String, dynamic>> unbindFamilyAPI() async {
  try {
    final response = await dioRequest.delete('/api/users/family');
    return response as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}


