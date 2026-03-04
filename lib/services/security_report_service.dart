import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';

/// 安全报告服务
/// 
/// 功能：
/// 1. 生成用户安全监测报告（调用大模型）
class SecurityReportService {
  static final SecurityReportService _instance = SecurityReportService._internal();
  factory SecurityReportService() => _instance;
  SecurityReportService._internal();

  /// 生成用户安全监测报告
  /// 
  /// [userId] 用户ID
  /// 
  /// 返回：
  /// ```json
  /// {
  ///   "user_id": 1,
  ///   "username": "zhangsan",
  ///   "report_generated_at": "2026-03-03T14:30:00",
  ///   "report_content": "## 个人反诈安全监测报告\n\n..."
  /// }
  /// ```
  Future<Map<String, dynamic>?> generateSecurityReport(int userId) async {
    try {
      print('📊 生成安全报告: 用户ID=$userId');
      
      final response = await dioRequest.get(
        '/api/users/$userId/security-report',
      );

      if (response != null) {
        print('✅ 安全报告生成成功');
        print('   用户: ${response['username']}');
        print('   生成时间: ${response['report_generated_at']}');
        print('   报告长度: ${response['report_content']?.length ?? 0} 字符');
        return response;
      }

      return null;
    } catch (e) {
      print('❌ 生成安全报告失败: $e');
      rethrow;
    }
  }

  /// 获取当前用户的安全报告
  /// 
  /// 需要先从 AuthService 获取当前用户ID
  Future<Map<String, dynamic>?> getCurrentUserReport() async {
    try {
      // 从 AuthService 获取当前用户信息
      final userInfo = AuthService().userInfo;
      
      if (userInfo == null) {
        print('⚠️ 未登录，无法获取报告');
        return null;
      }

      final userId = userInfo['user_id'] as int;
      return await generateSecurityReport(userId);
    } catch (e) {
      print('❌ 获取当前用户报告失败: $e');
      return null;
    }
  }
}

