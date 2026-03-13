import 'dart:convert';
import 'package:flutter/services.dart';

/// 音频录制服务（Dart 层）
/// 
/// 功能：
/// 1. 通过 Platform Channel 调用 Android 原生的 AudioRecordingService
/// 2. 使用 VOICE_COMMUNICATION 音频源与微信等通话应用共享麦克风
/// 3. 支持智能降级（VOICE_COMMUNICATION → MIC → VOICE_RECOGNITION）
/// 4. 实时接收音频数据并处理
class AudioRecordingServiceDart {
  static const platform = MethodChannel('com.example.ai_anti_fraud_detection_system_frontend/audio_recording');
  
  // 回调函数
  Function(List<int>)? onAudioDataReceived;  // 接收音频数据
  Function(String)? onStatusChanged;         // 状态变化
  Function(String)? onError;                 // 错误回调
  
  // 单例
  static final AudioRecordingServiceDart _instance = AudioRecordingServiceDart._internal();
  
  factory AudioRecordingServiceDart() {
    return _instance;
  }
  
  AudioRecordingServiceDart._internal() {
    _setupMethodCallHandler();
  }
  
  /// 设置方法调用处理器
  void _setupMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAudioData':
          _handleAudioData(call);
          break;
        case 'onStatusChanged':
          _handleStatusChanged(call);
          break;
        case 'onError':
          _handleError(call);
          break;
        default:
          print('⚠️ Unknown method: ${call.method}');
      }
    });
  }
  
  /// 处理音频数据
  void _handleAudioData(MethodCall call) {
    try {
      final data = call.arguments['data'] as String;
      final size = call.arguments['size'] as int;
      
      // Base64 解码
      final audioBytes = base64Decode(data);
      
      print('🎤 Received audio data: $size bytes');
      
      // 调用回调
      onAudioDataReceived?.call(audioBytes);
    } catch (e) {
      print('❌ Error handling audio data: $e');
    }
  }
  
  /// 处理状态变化
  void _handleStatusChanged(MethodCall call) {
    final status = call.arguments['status'] as String;
    print('📊 Audio recording status: $status');
    onStatusChanged?.call(status);
  }
  
  /// 处理错误
  void _handleError(MethodCall call) {
    final error = call.arguments['error'] as String;
    print('❌ Audio recording error: $error');
    onError?.call(error);
  }
  
  /// 启动音频录制
  /// 
  /// 使用 VOICE_COMMUNICATION 音频源，支持与微信等通话应用共享麦克风
  Future<bool> startRecording() async {
    try {
      print('🎤 Starting audio recording with VOICE_COMMUNICATION source...');
      final result = await platform.invokeMethod<bool>('startRecording');
      return result ?? false;
    } catch (e) {
      print('❌ Failed to start audio recording: $e');
      onError?.call('Failed to start audio recording: $e');
      return false;
    }
  }
  
  /// 停止音频录制
  Future<bool> stopRecording() async {
    try {
      print('🎤 Stopping audio recording...');
      final result = await platform.invokeMethod<bool>('stopRecording');
      return result ?? false;
    } catch (e) {
      print('❌ Failed to stop audio recording: $e');
      onError?.call('Failed to stop audio recording: $e');
      return false;
    }
  }
  
  /// 检查是否正在录制
  Future<bool> isRecording() async {
    try {
      final result = await platform.invokeMethod<bool>('isRecording');
      return result ?? false;
    } catch (e) {
      print('❌ Failed to check recording status: $e');
      return false;
    }
  }
  
  /// 获取当前使用的音频源
  /// 
  /// 返回值：
  /// - "VOICE_COMMUNICATION" - 与微信等通话应用共享
  /// - "MIC" - 普通麦克风
  /// - "VOICE_RECOGNITION" - 语音识别源
  /// - "UNKNOWN" - 未知
  Future<String> getCurrentAudioSource() async {
    try {
      final result = await platform.invokeMethod<String>('getCurrentAudioSource');
      return result ?? 'UNKNOWN';
    } catch (e) {
      print('❌ Failed to get audio source: $e');
      return 'UNKNOWN';
    }
  }
}

