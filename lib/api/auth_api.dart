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

