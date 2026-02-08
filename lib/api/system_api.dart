// 系统相关的 API 接口

import 'package:ai_anti_fraud_detection_system_frontend/contants/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';

/// 健康检查 API
/// 
/// 返回: Map 包含 status 字段
Future<Map<String, dynamic>> healthCheckAPI() async {
  try {
    final response = await dioRequest.get(HttpConstants.HEALTH);
    return response as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}

