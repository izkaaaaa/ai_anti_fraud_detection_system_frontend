import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 通话检测服务 - 控制无障碍服务
/// 
/// 功能：
/// 1. 启动/停止无障碍服务
/// 2. 检查无障碍服务状态
/// 3. 监听通话事件
/// 4. 自动触发录音
class CallDetectionService extends GetxService {
  static const platform = MethodChannel('com.example.ai_anti_fraud_detection_system_frontend/call_detection');
  
  // 状态
  final isAccessibilityEnabled = false.obs;
  final currentCall = Rxn<CallInfo>();
  final callHistory = <CallInfo>[].obs;
  final statusMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    _setupMethodChannelListeners();
    _checkAccessibilityServiceStatus();
  }
  
  /// 设置 MethodChannel 监听器
  void _setupMethodChannelListeners() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCallDetected':
          _handleCallDetected(call.arguments);
          break;
        case 'onCallEnded':
          _handleCallEnded();
          break;
        case 'onStatusChanged':
          _handleStatusChanged(call.arguments);
          break;
      }
    });
  }
  
  /// 处理通话检测事件
  void _handleCallDetected(Map<dynamic, dynamic> args) {
    final app = args['app'] as String? ?? 'Unknown';
    final caller = args['caller'] as String? ?? 'Unknown';
    
    final callInfo = CallInfo(
      app: app,
      caller: caller,
      startTime: DateTime.now(),
    );
    
    currentCall.value = callInfo;
    callHistory.add(callInfo);
    
    print('📞 Call detected: $app - $caller');
  }
  
  /// 处理通话结束事件
  void _handleCallEnded() {
    if (currentCall.value != null) {
      currentCall.value!.endTime = DateTime.now();
      print('📞 Call ended');
    }
    currentCall.value = null;
  }
  
  /// 处理状态变化
  void _handleStatusChanged(Map<dynamic, dynamic> args) {
    final status = args['status'] as String? ?? '';
    statusMessage.value = status;
    print('📞 Status: $status');
  }
  
  /// 启动无障碍服务
  Future<bool> startAccessibilityService() async {
    try {
      final result = await platform.invokeMethod<bool>('startAccessibilityService');
      
      // 延迟检查，因为用户需要手动启用
      await Future.delayed(const Duration(seconds: 2));
      await _checkAccessibilityServiceStatus();
      
      return result ?? false;
    } catch (e) {
      print('Error starting accessibility service: $e');
      return false;
    }
  }
  
  /// 停止无障碍服务
  Future<bool> stopAccessibilityService() async {
    try {
      final result = await platform.invokeMethod<bool>('stopAccessibilityService');
      await _checkAccessibilityServiceStatus();
      return result ?? false;
    } catch (e) {
      print('Error stopping accessibility service: $e');
      return false;
    }
  }
  
  /// 检查无障碍服务状态
  Future<void> _checkAccessibilityServiceStatus() async {
    try {
      final result = await platform.invokeMethod<bool>('isAccessibilityServiceEnabled');
      isAccessibilityEnabled.value = result ?? false;
      print('Accessibility service enabled: ${isAccessibilityEnabled.value}');
    } catch (e) {
      print('Error checking accessibility service: $e');
      isAccessibilityEnabled.value = false;
    }
  }
  
  /// 刷新无障碍服务状态（用户从系统设置返回后调用）
  Future<void> refreshAccessibilityServiceStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkAccessibilityServiceStatus();
  }
  
  /// 打开无障碍服务设置
  Future<void> openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('Error opening accessibility settings: $e');
    }
  }
  
  /// 获取通话历史
  List<CallInfo> getCallHistory() {
    return callHistory.toList();
  }
  
  /// 清空通话历史
  void clearCallHistory() {
    callHistory.clear();
  }
}

/// 通话信息
class CallInfo {
  final String app;
  final String caller;
  final DateTime startTime;
  DateTime? endTime;
  
  CallInfo({
    required this.app,
    required this.caller,
    required this.startTime,
    this.endTime,
  });
  
  /// 获取通话时长
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  /// 获取格式化的通话时长
  String get formattedDuration {
    final d = duration;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  String toString() => 'CallInfo(app: $app, caller: $caller, duration: $formattedDuration)';
}

