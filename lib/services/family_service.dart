import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';

/// 家庭组管理服务
class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;
  FamilyService._internal();

  Future<Map<String, dynamic>?> createFamily(String name) async {
    try {
      final response = await dioRequest.post(
        '/api/family/create',
        params: {'name': name},
      );
      if (response != null && response['code'] == 200) {
        return response['data'];
      }
      return null;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> applyToJoin(int familyId) async {
    try {
      final response = await dioRequest.post(
        '/api/family/$familyId/apply',
      );
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getApplications() async {
    try {
      final response = await dioRequest.get('/api/family/applications');
      if (response != null && response['code'] == 200) {
        final data = response['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map<String, dynamic> && data['items'] is List) {
          return (data['items'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> reviewApplication(int appId, bool isApprove) async {
    try {
      final response = await dioRequest.put(
        '/api/family/applications/$appId',
        params: {
          'is_approve': isApprove,
        },
      );
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMembers({int? familyId}) async {
    try {
      final params = <String, dynamic>{};
      if (familyId != null) {
        params['family_id'] = familyId;
      }
      
      final response = await dioRequest.get(
        '/api/family/members',
        params: params.isNotEmpty ? params : null,
      );

      if (response != null && response['code'] == 200) {
        final data = response['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map<String, dynamic> && data['members'] is List) {
          return (data['members'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getFamilyInfo() async {
    try {
      final response = await dioRequest.get('/api/family/info');
      if (response != null && response['code'] == 200) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> sendSos({
    required int callId,
    String? message,
  }) async {
    try {
      final params = <String, dynamic>{'call_id': callId};
      if (message != null) {
        params['message'] = message;
      }

      final response = await dioRequest.post(
        '/api/family/sos',
        params: params,
      );
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> remoteIntervene({
    required int targetUserId,
    required String action,
    String? message,
  }) async {
    try {
      final params = <String, dynamic>{
        'target_user_id': targetUserId,
        'action': action,
      };
      if (message != null) {
        params['message'] = message;
      }

      final response = await dioRequest.post(
        '/api/family/remote-intervene',
        params: params,
      );
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> setAdminRole({required int userId, required String role}) async {
    try {
      final response = await dioRequest.put(
        '/api/family/members/$userId/admin-role',
        params: {
          'role': role,
        },
      );
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> removeMember(int userId) async {
    try {
      final response = await dioRequest.delete(
        '/api/family/members/$userId',
      );
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyAdminFamilies() async {
    try {
      final response = await dioRequest.get('/api/family/my-admin-families');
      if (response != null && response['code'] == 200) {
        final data = response['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map<String, dynamic> && data['items'] is List) {
          return (data['items'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> leaveFamily() async {
    try {
      final response = await dioRequest.post('/api/family/leave');
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> cancelApplication(int appId) async {
    try {
      final response = await dioRequest.delete('/api/family/applications/$appId');
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  /// 获取用户的待审批申请列表
  Future<List<Map<String, dynamic>>> getPendingApplications() async {
    try {
      print('📋 正在获取待审批申请列表...');
      // 尝试多个可能的端点
      List<String> endpoints = [
        '/api/family/my-applications',
        '/api/family/applications/pending',
        '/api/family/applications',  // 可能返回所有申请（包括用户发出的）
      ];
      
      for (String endpoint in endpoints) {
        try {
          print('🔗 尝试端点: $endpoint');
          final response = await dioRequest.get(endpoint);
          print('📦 响应: $response');
          
          if (response != null && response['code'] == 200) {
            final data = response['data'];
            print('📊 数据: $data');
            
            if (data is List) {
              print('✅ 是列表，共 ${data.length} 个');
              // 过滤出状态为 pending 的申请
              final pending = data.where((app) {
                final status = app['status']?.toString().toLowerCase() ?? '';
                return status == 'pending' || status == 'waiting';
              }).toList();
              return pending.cast<Map<String, dynamic>>();
            }
            if (data is Map<String, dynamic>) {
              if (data['items'] is List) {
                print('✅ 在 items 字段，共 ${(data['items'] as List).length} 个');
                final items = data['items'] as List;
                final pending = items.where((app) {
                  final status = app['status']?.toString().toLowerCase() ?? '';
                  return status == 'pending' || status == 'waiting';
                }).toList();
                return pending.cast<Map<String, dynamic>>();
              }
              if (data['records'] is List) {
                print('✅ 在 records 字段，共 ${(data['records'] as List).length} 个');
                final records = data['records'] as List;
                final pending = records.where((app) {
                  final status = app['status']?.toString().toLowerCase() ?? '';
                  return status == 'pending' || status == 'waiting';
                }).toList();
                return pending.cast<Map<String, dynamic>>();
              }
            }
          }
        } catch (e) {
          print('⚠️ 端点 $endpoint 失败: $e');
          continue;
        }
      }
      
      print('⚠️ 所有端点都失败了');
      return [];
    } catch (e) {
      print('❌ 获取待审批申请失败: $e');
      return [];
    }
  }
}
