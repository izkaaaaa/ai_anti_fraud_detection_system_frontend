import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/baidu_speech_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/foreground_task_handler.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/index.dart';

/// 实时检测服务
class RealTimeDetectionService {
  // WebSocket 连接
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  
  // 音频录制器
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  Timer? _audioStreamTimer;
  String? _currentAudioPath;
  StreamSubscription? _audioLevelSubscription;
  
  // 屏幕截图控制
  static const platform = MethodChannel('com.example.ai_anti_fraud_detection_system_frontend/screen_capture');
  bool _isScreenCaptureActive = false;
  Timer? _videoFrameTimer;
  bool _isCapturingFrame = false; // 防止并发截图
  
  // ✅ 百度语音识别服务（用于文字流检测）
  final BaiduSpeechService _speechService = BaiduSpeechService();
  bool _isSpeechRecognitionActive = false;
  
  // 音频波形数据（使用可变列表）
  final List<double> _audioWaveformData = List.generate(50, (_) => 0.0);
  
  // 连接状态
  bool _isConnected = false;
  String? _callRecordId;
  
  // ✅ 三级防御机制
  int _currentDefenseLevel = 1;  // 当前防御等级（1/2/3）
  double _currentVideoFPS = 1.0;  // 当前视频帧率
  bool _isRecordingCall = false;  // 是否正在录音
  
  // 回调函数
  Function(Map<String, dynamic>)? onDetectionResult;  // 检测结果回调
  Function(String)? onStatusChange;                    // 状态变化回调
  Function(String)? onError;                           // 错误回调
  Function()? onConnected;                             // 连接成功回调
  Function()? onDisconnected;                          // 断开连接回调
  Function(List<double>)? onAudioWaveformUpdate;      // 音频波形回调
  Function(Map<String, dynamic>)? onControlMessage;   // 控制消息回调（防御升级等）
  Function(String, String)? onAckReceived;            // ACK 确认回调
  Function(int)? onDefenseLevelChanged;               // 防御等级变化回调
  
  // WebSocket URL - 动态获取，与 HTTP 地址保持一致
  String get _wsBaseUrl {
    // 将 http:// 替换为 ws://
    return GlobalConstants.BASE_URL.replaceFirst('http://', 'ws://');
  }
  
  /// 开始实时监测
  Future<bool> startDetection() async {
    try {
      // ✅ 1. 初始化并启动前台服务
      final foregroundServiceStarted = await _startForegroundService();
      if (!foregroundServiceStarted) {
        onError?.call('启动前台服务失败');
        return false;
      }
      
      // 2. 创建通话记录
      final recordId = await _createCallRecord();
      if (recordId == null) {
        onError?.call('创建通话记录失败');
        await _stopForegroundService();
        return false;
      }
      _callRecordId = recordId;
      
      // 3. 连接 WebSocket
      final connected = await _connectWebSocket();
      if (!connected) {
        onError?.call('连接服务器失败');
        await _stopForegroundService();
        return false;
      }
      
      // 4. 开始录音
      final recordingStarted = await _startAudioRecording();
      if (!recordingStarted) {
        onError?.call('启动录音失败');
        await _disconnectWebSocket();
        await _stopForegroundService();
        return false;
      }
      
      // 5. 开始屏幕截图
      final screenCaptureStarted = await _startScreenCapture();
      if (!screenCaptureStarted) {
        print('⚠️ 屏幕截图启动失败，仅使用音频检测');
        // 不阻断流程，继续使用音频检测
      }
      
      // ✅ 6. 启动语音识别（用于文字流检测）
      final speechStarted = await _startSpeechRecognition();
      if (!speechStarted) {
        print('⚠️ 语音识别启动失败，仅使用音视频检测');
        // 不阻断流程，继续使用音视频检测
      }
      
      onStatusChange?.call('监测已启动');
      return true;
    } catch (e) {
      onError?.call('启动失败: $e');
      return false;
    }
  }
  
  /// 停止实时监测
  Future<void> stopDetection() async {
    try {
      // 1. 停止录音
      await _stopAudioRecording();
      
      // 2. 停止屏幕截图
      await _stopScreenCapture();
      
      // ✅ 3. 停止语音识别
      await _stopSpeechRecognition();
      
      // 4. 断开 WebSocket（根据文档，关闭连接即可，无需调用结束接口）
      await _disconnectWebSocket();
      
      // ✅ 5. 停止前台服务
      await _stopForegroundService();
      
      onStatusChange?.call('监测已停止');
    } catch (e) {
      onError?.call('停止失败: $e');
    }
  }
  
  /// 创建通话记录
  Future<String?> _createCallRecord() async {
    try {
      final token = AuthService().getToken();
      if (token.isEmpty) {
        print('❌ 创建通话记录失败: 未登录');
        return null;
      }
      
      print('📞 创建通话记录...');
      
      // 使用 POST 请求，参数作为 query parameters
      final response = await dioRequest.post(
        '/api/call-records/start',
        params: {
          'platform': 'android',
          'target_identifier': 'realtime_detection',
        },
      );
      
      // 后端返回的是 call_id，不是 id
      if (response != null && response['call_id'] != null) {
        print('✅ 通话记录创建成功: call_id=${response['call_id']}');
        return response['call_id'].toString();
      }
      
      print('❌ 创建通话记录失败: 响应无效 - $response');
      return null;
    } catch (e) {
      print('❌ 创建通话记录失败: $e');
      return null;
    }
  }
  
  /// 连接 WebSocket
  Future<bool> _connectWebSocket() async {
    try {
      final token = AuthService().getToken();
      if (token.isEmpty) {
        print('❌ WebSocket 连接失败: 未登录');
        return false;
      }
      
      // 获取用户信息
      final userInfo = await AuthService().getCurrentUser();
      if (userInfo == null || userInfo['user_id'] == null) {
        print('❌ WebSocket 连接失败: 无法获取用户ID');
        print('   用户信息: $userInfo');
        return false;
      }
      
      final userId = userInfo['user_id'];
      
      // 按照文档格式构建 WebSocket URL
      // ws://172.20.16.1:8000/api/detection/ws/{user_id}/{call_id}?token={jwt_token}
      final wsUrl = '$_wsBaseUrl/api/detection/ws/$userId/$_callRecordId?token=$token';
      print('🔌 连接 WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // 监听消息
      _channelSubscription = _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket 错误: $error');
          onError?.call('连接错误: $error');
          _isConnected = false;
          onDisconnected?.call();
        },
        onDone: () {
          print('🔌 WebSocket 连接关闭');
          _isConnected = false;
          onDisconnected?.call();
        },
      );
      
      _isConnected = true;
      onConnected?.call();
      onStatusChange?.call('已连接到服务器');
      
      print('✅ WebSocket 连接成功');
      
      // 发送心跳
      _startHeartbeat();
      
      return true;
    } catch (e) {
      print('❌ 连接 WebSocket 失败: $e');
      return false;
    }
  }
  
  /// 断开 WebSocket
  Future<void> _disconnectWebSocket() async {
    await _channelSubscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _channelSubscription = null;
    _isConnected = false;
  }
  
  /// 处理 WebSocket 消息（按照接口文档格式）
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'];
      
      print('📨 收到消息: type=$type');
      
      switch (type) {
        case 'ack':
          // ACK 确认消息
          final msgType = data['msg_type'] ?? 'unknown';
          final status = data['status'] ?? '';
          final timestamp = data['timestamp'] ?? '';
          
          if (status == 'ready') {
            print('✅ ACK: $msgType (缓冲区已满，已投递检测任务)');
          } else if (status == 'buffering') {
            print('✅ ACK: $msgType (正在积攒帧...)');
          } else {
            print('✅ ACK: $msgType');
          }
          
          onAckReceived?.call(msgType, status);
          break;
          
        case 'heartbeat_ack':
          // 心跳响应
          print('💓 心跳响应');
          break;
          
        case 'detection_result':
          // 检测结果消息（按照文档格式）
          final detectionType = data['detection_type'] ?? '未知';
          final isRisk = data['is_risk'] ?? false;
          final confidence = data['confidence'] ?? 0.0;
          final message = data['message'] ?? '';
          final timestamp = data['timestamp'] ?? '';
          
          print('🔍 检测结果:');
          print('   类型: $detectionType');
          print('   风险: ${isRisk ? "是" : "否"}');
          print('   置信度: ${(confidence * 100).toStringAsFixed(1)}%');
          print('   消息: $message');
          print('   时间: $timestamp');
          
          // 回调给 UI
          onDetectionResult?.call({
            'detection_type': detectionType,
            'is_risk': isRisk,
            'confidence': confidence,
            'message': message,
            'timestamp': timestamp,
          });
          break;
          
        case 'control':
          // 控制消息（防御升级等）
          final action = data['action'] ?? '';
          
          if (action == 'upgrade_level') {
            final targetLevel = data['target_level'] ?? 1;
            final reason = data['reason'] ?? '';
            final config = data['config'] ?? {};
            
            print('⚠️ 防御升级:');
            print('   目标等级: Level $targetLevel');
            print('   原因: $reason');
            print('   配置: $config');
            
            // ✅ 应用防御等级（只升不降）
            _applyDefenseLevel(targetLevel, config);
            
            // 回调给 UI 处理
            onControlMessage?.call({
              'action': action,
              'target_level': targetLevel,
              'reason': reason,
              'config': config,
            });
          } else {
            print('❓ 未知控制动作: $action');
          }
          break;
          
        case 'info':
          // 后端实际返回的消息类型（兼容处理）
          final infoData = data['data'] ?? {};
          final title = infoData['title'] ?? '';
          final infoMessage = infoData['message'] ?? '';
          final riskLevel = infoData['risk_level'] ?? 'safe';
          final confidence = (infoData['confidence'] ?? 0.0).toDouble();
          final timestamp = infoData['timestamp'] ?? '';
          
          print('ℹ️ 信息消息:');
          print('   标题: $title');
          print('   消息: $infoMessage');
          print('   风险等级: $riskLevel');
          print('   置信度: ${(confidence * 100).toStringAsFixed(1)}%');
          
          // 转换为标准格式回调给 UI
          final isRisk = riskLevel != 'safe';
          final detectionType = title.contains('语音') || title.contains('音频') 
              ? '语音' 
              : title.contains('视频') 
                  ? '视频' 
                  : '文本';
          
          onDetectionResult?.call({
            'detection_type': detectionType,
            'is_risk': isRisk,
            'confidence': confidence,
            'message': infoMessage,
            'timestamp': timestamp,
          });
          break;
          
        case 'error':
          // 错误消息
          final errorMsg = data['message'] ?? '未知错误';
          print('❌ 服务器错误: $errorMsg');
          onError?.call(errorMsg);
          break;
          
        case 'status':
          // 状态更新
          final statusMsg = data['message'] ?? '';
          print('📊 状态更新: $statusMsg');
          onStatusChange?.call(statusMsg);
          break;
          
        default:
          print('❓ 未知消息类型: $type');
          print('   完整消息: $data');
      }
    } catch (e) {
      print('❌ 处理 WebSocket 消息失败: $e');
      print('   原始消息: $message');
    }
  }
  
  /// 开始心跳
  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(json.encode({'type': 'heartbeat'}));
        print('💓 发送心跳');
      }
    });
  }
  
  /// 开始录音（带实时音量监测）
  Future<bool> _startAudioRecording() async {
    try {
      // 检查权限
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        print('❌ 没有录音权限');
        return false;
      }
      
      // 初始化录音器
      if (!_isRecorderInitialized) {
        await _audioRecorder.openRecorder();
        _isRecorderInitialized = true;
      }
      
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      _currentAudioPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      // 开始录音（启用音量监测）
      await _audioRecorder.startRecorder(
        toFile: _currentAudioPath,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );
      
      _isRecording = true;
      
      // 设置订阅间隔（必须在 startRecorder 之后调用）
      await _audioRecorder.setSubscriptionDuration(Duration(milliseconds: 100));
      
      // 监听音频音量（用于波形显示）
      await _startAudioLevelMonitoring();
      
      // 定期发送音频数据
      _startAudioStreaming();
      
      print('🎤 录音已启动');
      return true;
    } catch (e) {
      print('❌ 开始录音失败: $e');
      return false;
    }
  }
  
  /// 监听音频音量（用于实时波形）
  Future<void> _startAudioLevelMonitoring() async {
    _audioLevelSubscription?.cancel();
    
    // ✅ 重新设置订阅间隔（关键！）
    try {
      await _audioRecorder.setSubscriptionDuration(Duration(milliseconds: 100));
    } catch (e) {
      print('⚠️ 设置订阅间隔失败: $e');
    }
    
    _audioLevelSubscription = _audioRecorder.onProgress!.listen((event) {
      if (event.decibels != null) {
        print('🎤 分贝值: ${event.decibels}');
        
        // ✅ 修复：flutter_sound 返回的分贝值范围是 0-120
        // 将其归一化到 0-1 范围
        final normalizedLevel = (event.decibels!.clamp(0.0, 120.0)) / 120.0;
        
        // 更新波形数据（移除第一个，添加新的到最后）
        _audioWaveformData.removeAt(0);
        _audioWaveformData.add(normalizedLevel);
        
        // 通知 UI 更新
        onAudioWaveformUpdate?.call(List.from(_audioWaveformData));
      }
    });
  }
  
  /// 停止录音
  Future<void> _stopAudioRecording() async {
    try {
      // ✅ 先取消定时器，防止在停止过程中重启录音
      _audioStreamTimer?.cancel();
      _audioStreamTimer = null;
      
      _audioLevelSubscription?.cancel();
      _audioLevelSubscription = null;
      
      if (_isRecording) {
        try {
          // ✅ 增加容错：如果录音时间太短，stopRecorder 可能失败
          await _audioRecorder.stopRecorder();
          print('✅ 录音器正常停止');
        } catch (stopError) {
          print('⚠️ stopRecorder 失败 (可能录音时间太短): $stopError');
          // 即使停止失败，也继续清理流程
        }
        _isRecording = false;
      }
      
      // 关闭录音器
      if (_isRecorderInitialized) {
        try {
          await _audioRecorder.closeRecorder();
          print('✅ 录音器已关闭');
        } catch (closeError) {
          print('⚠️ closeRecorder 失败: $closeError');
          // 继续清理流程
        }
        _isRecorderInitialized = false;
      }
      
      // 删除临时文件
      if (_currentAudioPath != null) {
        try {
          final file = File(_currentAudioPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (deleteError) {
          print('⚠️ 删除临时文件失败: $deleteError');
        }
        _currentAudioPath = null;
      }
      
      print('🎤 录音已停止');
    } catch (e) {
      print('❌ 停止录音失败: $e');
      // 确保状态被重置
      _isRecording = false;
      _isRecorderInitialized = false;
    }
  }
  
  /// 开始音频流传输
  void _startAudioStreaming() {
    _audioStreamTimer?.cancel();
    
    // 每3秒发送一次音频数据
    _audioStreamTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!_isRecording || !_isConnected || _channel == null) {
        timer.cancel();
        return;
      }
      
      try {
        // ✅ 增加容错：停止录音可能失败（录音时间太短）
        try {
          await _audioRecorder.stopRecorder();
        } catch (stopError) {
          print('⚠️ 定时器中 stopRecorder 失败: $stopError');
          // 如果停止失败，跳过本次发送，继续下一轮
          return;
        }
        
        if (_currentAudioPath != null) {
          final file = File(_currentAudioPath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final base64Audio = base64Encode(bytes);
            
            // 发送音频数据
            _channel!.sink.add(json.encode({
              'type': 'audio',
              'data': base64Audio,
            }));
            
            print('🎵 发送音频数据: ${bytes.length} bytes');
            
            // 删除临时文件
            await file.delete();
          }
        }
        
        // 重新开始录音
        final tempDir = await getTemporaryDirectory();
        _currentAudioPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        await _audioRecorder.startRecorder(
          toFile: _currentAudioPath,
          codec: Codec.aacADTS,
          bitRate: 128000,
          sampleRate: 44100,
        );
        
        // ✅ 重新启动音频音量监听（关键修复！）
        await _startAudioLevelMonitoring();
      } catch (e) {
        print('❌ 发送音频数据失败: $e');
      }
    });
  }
  
  /// 开始屏幕截图
  Future<bool> _startScreenCapture() async {
    try {
      print('📱 开始屏幕截图...');
      
      // 1. 请求屏幕截图权限
      final result = await platform.invokeMethod('startCapture');
      
      if (result != true) {
        print('❌ 屏幕截图权限获取失败');
        return false;
      }
      
      _isScreenCaptureActive = true;
      
      // 2. 开始定期截图
      _startScreenshotCapture();
      
      print('✅ 屏幕截图已启动');
      return true;
    } catch (e) {
      print('❌ 启动屏幕截图失败: $e');
      return false;
    }
  }
  
  /// 开始截图采集
  void _startScreenshotCapture() {
    _videoFrameTimer?.cancel();
    
    // ✅ 根据当前防御等级动态调整帧率
    final interval = Duration(milliseconds: (1000 / _currentVideoFPS).round());
    print('📸 截图采集间隔: ${interval.inMilliseconds}ms ($_currentVideoFPS fps)');
    
    _videoFrameTimer = Timer.periodic(interval, (timer) async {
      if (!_isScreenCaptureActive || !_isConnected || _channel == null) {
        timer.cancel();
        return;
      }
      
      // 防止并发截图
      if (_isCapturingFrame) {
        print('⏭️ 跳过本次采集（上次未完成）');
        return;
      }
      
      _isCapturingFrame = true;
      
      try {
        // 调用原生方法截图
        final Uint8List? jpegData = await platform.invokeMethod('captureScreen');
        
        if (jpegData != null && jpegData.isNotEmpty) {
          // Base64 编码
          final base64Frame = base64Encode(jpegData);
          
          // 发送视频帧
          _channel!.sink.add(json.encode({
            'type': 'video',
            'data': base64Frame,
          }));
          
          print('📸 发送屏幕截图: ${jpegData.length} bytes');
        }
      } catch (e) {
        print('❌ 截图失败: $e');
      } finally {
        _isCapturingFrame = false;
      }
    });
  }
  
  /// 停止屏幕截图
  Future<void> _stopScreenCapture() async {
    try {
      // 先取消定时器
      _videoFrameTimer?.cancel();
      _videoFrameTimer = null;
      
      // 等待当前采集完成
      while (_isCapturingFrame) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      if (_isScreenCaptureActive) {
        _isScreenCaptureActive = false;
        
        // 停止屏幕截图
        await platform.invokeMethod('stopCapture');
        
        print('📱 屏幕截图已停止');
      }
    } catch (e) {
      print('❌ 停止屏幕截图失败: $e');
    }
  }
  
  // ============================================================
  // ✅ 语音识别（文字流检测）
  // ============================================================
  
  /// 启动语音识别（用于文字流检测）
  Future<bool> _startSpeechRecognition() async {
    try {
      print('🎤 启动语音识别（文字流检测）...');
      
      // 1. 初始化语音识别服务
      final initialized = await _speechService.initialize();
      if (!initialized) {
        print('❌ 语音识别初始化失败');
        return false;
      }
      
      // 2. 设置回调函数
      _setupSpeechRecognitionCallbacks();
      
      // 3. 开始识别
      final started = await _speechService.startRecognition();
      if (!started) {
        print('❌ 语音识别启动失败');
        return false;
      }
      
      _isSpeechRecognitionActive = true;
      print('✅ 语音识别已启动');
      return true;
    } catch (e) {
      print('❌ 启动语音识别失败: $e');
      return false;
    }
  }
  
  /// 设置语音识别回调
  void _setupSpeechRecognitionCallbacks() {
    // 临时识别结果（实时显示，不发送给后端）
    _speechService.onPartialResult = (text) {
      print('🎤 临时识别: $text');
      // 可以在这里更新 UI 显示实时识别结果
    };
    
    // ✅ 最终识别结果（发送给后端进行文本检测）
    _speechService.onFinalResult = (text, startTime, endTime) {
      print('✅ 最终识别: $text (${startTime}ms - ${endTime}ms)');
      
      // 将识别的文本发送给后端进行检测
      if (text.isNotEmpty && _isConnected && _channel != null) {
        sendText(text);
      }
    };
    
    // 状态变化
    _speechService.onStatusChange = (status) {
      print('🎤 语音识别状态: $status');
    };
    
    // 错误处理
    _speechService.onError = (error) {
      print('❌ 语音识别错误: $error');
      // 不影响主流程，继续监测
    };
    
    // 连接状态
    _speechService.onConnected = () {
      print('✅ 语音识别已连接');
    };
    
    _speechService.onDisconnected = () {
      print('🔌 语音识别已断开');
    };
  }
  
  /// 停止语音识别
  Future<void> _stopSpeechRecognition() async {
    try {
      if (_isSpeechRecognitionActive) {
        await _speechService.stopRecognition();
        _isSpeechRecognitionActive = false;
        print('🎤 语音识别已停止');
      }
    } catch (e) {
      print('❌ 停止语音识别失败: $e');
    }
  }
  
  /// 发送文本数据（用于文本检测）
  void sendText(String text) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(json.encode({
        'type': 'text',
        'data': text,
      }));
      print('📝 发送文本数据: $text');
    } else {
      print('⚠️ 无法发送文本: WebSocket 未连接');
    }
  }
  
  /// 发送视频帧（用于视频检测）
  void sendVideoFrame(String base64Frame) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(json.encode({
        'type': 'video',
        'data': base64Frame,
      }));
    }
  }
  
  /// 清理资源
  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _audioStreamTimer?.cancel();
    _videoFrameTimer?.cancel();
    _audioLevelSubscription?.cancel();
    await _stopAudioRecording();
    await _stopScreenCapture();  // ✅ 停止屏幕截图
    await _stopSpeechRecognition();  // ✅ 停止语音识别
    _stopCallRecording();  // ✅ 停止通话录音（不需要 await，因为是同步方法）
    await _disconnectWebSocket();
    await _speechService.dispose();  // ✅ 清理语音识别服务
    await _stopForegroundService();  // ✅ 停止前台服务
  }
  
  // ============================================================
  // ✅ 前台服务管理
  // ============================================================
  
  /// 初始化前台服务
  Future<void> _initForegroundService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'realtime_detection_channel',
        channelName: '实时监测服务',
        channelDescription: '保持实时监测功能在后台运行',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // 每 5 秒触发一次
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
  
  /// 启动前台服务
  Future<bool> _startForegroundService() async {
    try {
      print('🚀 启动前台服务...');
      
      // 1. 初始化前台服务
      await _initForegroundService();
      
      // 2. 检查并请求通知权限（Android 13+）
      if (await FlutterForegroundTask.isIgnoringBatteryOptimizations == false) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
      
      // 3. 启动前台服务（只使用 microphone 类型）
      // ⚠️ 注意：mediaProjection 类型需要在获取权限后才能使用
      final serviceResult = await FlutterForegroundTask.startService(
        notificationTitle: '🛡️ 实时监测中',
        notificationText: '正在保护您的通话安全',
        callback: startCallback,
        // ✅ 暂时只使用 microphone 类型启动服务
        // mediaProjection 会在用户授权后自动生效
      );
      
      // ✅ 使用模式匹配检查结果
      if (serviceResult is ServiceRequestSuccess) {
        print('✅ 前台服务启动成功');
        return true;
      } else {
        print('❌ 前台服务启动失败');
        return false;
      }
    } catch (e) {
      print('❌ 启动前台服务失败: $e');
      return false;
    }
  }
  
  /// 停止前台服务
  Future<void> _stopForegroundService() async {
    try {
      print('🛑 停止前台服务...');
      await FlutterForegroundTask.stopService();
      print('✅ 前台服务已停止');
    } catch (e) {
      print('❌ 停止前台服务失败: $e');
    }
  }
  
  /// 更新前台服务通知
  Future<void> _updateForegroundServiceNotification({
    String? title,
    String? text,
  }) async {
    // ✅ isRunningService 是一个 getter，返回 bool
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    }
  }
  
  /// 获取连接状态
  bool get isConnected => _isConnected;
  
  /// 获取录音状态
  bool get isRecording => _isRecording;
  
  /// 获取屏幕截图状态
  bool get isScreenCaptureActive => _isScreenCaptureActive;
  
  /// 获取当前通话记录ID
  String? get callRecordId => _callRecordId;
  
  /// 获取当前防御等级
  int get currentDefenseLevel => _currentDefenseLevel;
  
  /// 是否正在进行语音识别
  bool get isSpeechRecognitionActive => _isSpeechRecognitionActive;
  
  /// 应用防御等级（只升不降）
  void _applyDefenseLevel(int targetLevel, Map<String, dynamic> config) {
    // ✅ 防御等级只升不降
    if (targetLevel <= _currentDefenseLevel) {
      print('⚠️ 忽略降级指令: Level $_currentDefenseLevel → Level $targetLevel');
      return;
    }
    
    print('🛡️ 防御升级: Level $_currentDefenseLevel → Level $targetLevel');
    _currentDefenseLevel = targetLevel;
    
    // 通知 UI 防御等级变化
    onDefenseLevelChanged?.call(targetLevel);
    
    // 根据等级应用不同策略
    switch (targetLevel) {
      case 1:
        _applyLevel1(config);
        break;
      case 2:
        _applyLevel2(config);
        break;
      case 3:
        _applyLevel3(config);
        break;
    }
  }
  
  /// Level 1: 正常模式（绿色）
  void _applyLevel1(Map<String, dynamic> config) {
    print('✅ 切换到正常模式');
    
    // 恢复正常检测频率
    _currentVideoFPS = 1.0;
    
    // 重启视频采集（应用新帧率）
    if (_isScreenCaptureActive) {
      _startScreenshotCapture();
    }
    
    onStatusChange?.call('正常监测中');
  }
  
  /// Level 2: 警惕模式（黄色）
  void _applyLevel2(Map<String, dynamic> config) {
    print('⚠️ 切换到警惕模式');
    
    // 提高检测频率
    final videoFps = config['video_fps'];
    if (videoFps != null) {
      _currentVideoFPS = (videoFps is int) ? videoFps.toDouble() : videoFps;
      print('📹 提高视频帧率: $_currentVideoFPS fps');
      
      // 重启视频采集（应用新帧率）
      if (_isScreenCaptureActive) {
        _startScreenshotCapture();
      }
    }
    
    // 开启录音（如果配置要求）
    final enableRecording = config['enable_call_recording'];
    if (enableRecording == true && !_isRecordingCall) {
      _startCallRecording();
    }
    
    onStatusChange?.call('警惕模式 - 已提高检测频率');
  }
  
  /// Level 3: 危险模式（红色）
  void _applyLevel3(Map<String, dynamic> config) {
    print('🚨 切换到危险模式');
    
    // 最高检测频率
    final videoFps = config['video_fps'];
    if (videoFps != null) {
      _currentVideoFPS = (videoFps is int) ? videoFps.toDouble() : videoFps;
      print('📹 最高视频帧率: $_currentVideoFPS fps');
      
      // 重启视频采集（应用新帧率）
      if (_isScreenCaptureActive) {
        _startScreenshotCapture();
      }
    }
    
    // 强制开启录音
    if (!_isRecordingCall) {
      _startCallRecording();
    }
    
    onStatusChange?.call('危险模式 - 强烈建议挂断');
  }
  
  /// 开始通话录音（保存证据）
  void _startCallRecording() {
    if (_isRecordingCall) return;
    
    try {
      print('🎙️ 开始通话录音（保存证据）');
      _isRecordingCall = true;
      // 注意：这里的录音是为了保存证据，与实时检测的录音是分开的
      // 实际实现可能需要另一个录音器实例
    } catch (e) {
      print('❌ 开始通话录音失败: $e');
    }
  }
  
  /// 停止通话录音
  void _stopCallRecording() {
    if (!_isRecordingCall) return;
    
    try {
      print('🎙️ 停止通话录音');
      _isRecordingCall = false;
    } catch (e) {
      print('❌ 停止通话录音失败: $e');
    }
  }
}

// ============================================================
// ✅ 前台服务回调函数（必须是顶层函数）
// ============================================================

/// 前台服务启动回调
/// 
/// 这个函数会在前台服务启动时被调用
/// 注意：这个函数必须是顶层函数，不能是类的成员方法
@pragma('vm:entry-point')
void startCallback() {
  // 初始化前台任务处理器
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}
