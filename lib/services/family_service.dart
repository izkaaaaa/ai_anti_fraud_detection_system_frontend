import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';

/// 家庭组管理服务
class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;
  FamilyService._internal();

  Future<Map<String, dynamic>?> createFamily(String name) async {
    try {
      final encodedName = Uri.encodeComponent(name);
      final response = await dioRequest.post('/api/family/create?name=$encodedName');
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
      final response = await dioRequest.post('/api/family/$familyId/apply');
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
      final response = await dioRequest.put('/api/family/applications/$appId?is_approve=$isApprove');
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMembers({required int familyId}) async {
    try {
      final response = await dioRequest.get(
        '/api/family/members',
        params: {'family_id': familyId},
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

  Future<bool> sendSos({required int callId, required String message}) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);
      final response = await dioRequest.post('/api/family/sos?call_id=$callId&message=$encodedMessage');
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> remoteIntervene({required int targetUserId, required String action}) async {
    try {
      final response = await dioRequest.post('/api/family/remote-intervene?target_user_id=$targetUserId&action=$action');
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> setAdminRole({required int userId, required String role}) async {
    try {
      final response = await dioRequest.put('/api/family/members/$userId/admin-role?role=$role');
      return response != null && response['code'] == 200;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> removeMember(int userId) async {
    try {
      final response = await dioRequest.delete('/api/family/members/$userId');
      return response != null && response['code'] == 200;
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
}
