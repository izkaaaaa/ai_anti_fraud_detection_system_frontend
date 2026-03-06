// 认证相关的 API 接口

import 'package:ai_anti_fraud_detection_system_frontend/contants/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/viewmodels/login_models.dart';

/// 登录 API
/// 
/// 参数:
/// - phone: 手机号
/// - password: 密码
/// 
/// 返回: LoginResponse 对象
Future<LoginResponse> loginAPI(String phone, String password) async {
  try {
    final requestData = LoginRequest(
      phone: phone,
      password: password,
    ).toJson();
    
    final response = await dioRequest.post(
      HttpConstants.LOGIN,
      data: requestData,
    );
    
    return LoginResponse.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    rethrow;
  }
}

/// 发送短信验证码 API
/// 
/// 参数:
/// - phone: 手机号
/// 
/// 返回: Map 包含 code, message, data
Future<Map<String, dynamic>> sendSmsCodeAPI(String phone) async {
  try {
    // 方式1：尝试 JSON Body（推荐）
    final response = await dioRequest.post(
      HttpConstants.SEND_SMS_CODE,
      data: {'phone': phone},
    );
    
    return response as Map<String, dynamic>;
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
/// - password: 密码
/// - smsCode: 短信验证码
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
  required String password,
  required String smsCode,
  String? roleType,
  String? gender,
  String? profession,
  String? maritalStatus,
}) async {
  try {
    final requestData = RegisterRequest(
      phone: phone,
      username: username,
      name: name,
      password: password,
      smsCode: smsCode,
      roleType: roleType,
      gender: gender,
      profession: profession,
      maritalStatus: maritalStatus,
    ).toJson();
    
    final response = await dioRequest.post(
      HttpConstants.REGISTER,
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
      HttpConstants.USER_PROFILE,
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
    final response = await dioRequest.get(HttpConstants.USER_PROFILE);
    return User.fromJson(response as Map<String, dynamic>);
  } catch (e) {
    rethrow;
  }
}


