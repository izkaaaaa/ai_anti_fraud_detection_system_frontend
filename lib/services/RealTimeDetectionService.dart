import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
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
  
  // 摄像头控制器
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Timer? _videoFrameTimer;
  bool _isCapturingFrame = false; // 防止并发拍照
  
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
      // 1. 创建通话记录
      final recordId = await _createCallRecord();
      if (recordId == null) {
        onError?.call('创建通话记录失败');
        return false;
      }
      _callRecordId = recordId;
      
      // 2. 连接 WebSocket
      final connected = await _connectWebSocket();
      if (!connected) {
        onError?.call('连接服务器失败');
        return false;
      }
      
      // 3. 开始录音
      final recordingStarted = await _startAudioRecording();
      if (!recordingStarted) {
        onError?.call('启动录音失败');
        await _disconnectWebSocket();
        return false;
      }
      
      // 4. 开始视频采集
      final cameraStarted = await _startVideoCapture();
      if (!cameraStarted) {
        print('⚠️ 摄像头启动失败，仅使用音频检测');
        // 不阻断流程，继续使用音频检测
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
      
      // 2. 停止视频采集
      await _stopVideoCapture();
      
      // 3. 断开 WebSocket（根据文档，关闭连接即可，无需调用结束接口）
      await _disconnectWebSocket();
      
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
          print('   置信度: ${(confidence * 100).toFixed(1)}%');
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
  
  /// 开始视频采集
  Future<bool> _startVideoCapture() async {
    try {
      // 检查摄像头权限
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          print('❌ 没有摄像头权限');
          return false;
        }
      }
      
      // 获取可用摄像头
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('❌ 没有可用的摄像头');
        return false;
      }
      
      // 使用前置摄像头（视频通话通常使用前置）
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      // 初始化摄像头控制器
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // 中等分辨率，平衡质量和性能
        enableAudio: false, // 不需要音频
      );
      
      await _cameraController!.initialize();
      _isCameraInitialized = true;
      
      // 开始定期采集视频帧
      _startVideoFrameCapture();
      
      print('📹 摄像头已启动');
      return true;
    } catch (e) {
      print('❌ 启动摄像头失败: $e');
      return false;
    }
  }
  
  /// 开始视频帧采集
  void _startVideoFrameCapture() {
    _videoFrameTimer?.cancel();
    
    // ✅ 根据当前防御等级动态调整帧率
    final interval = Duration(milliseconds: (1000 / _currentVideoFPS).round());
    print('📹 视频采集间隔: ${interval.inMilliseconds}ms (${_currentVideoFPS} fps)');
    
    _videoFrameTimer = Timer.periodic(interval, (timer) async {
      // ✅ 增加 _cameraController 空检查
      if (!_isCameraInitialized || !_isConnected || _channel == null || _cameraController == null) {
        timer.cancel();
        return;
      }
      
      // 防止并发拍照
      if (_isCapturingFrame) {
        print('⏭️ 跳过本次采集（上次未完成）');
        return;
      }
      
      _isCapturingFrame = true;
      
      try {
        // ✅ 再次检查 controller 是否还有效
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
          _isCapturingFrame = false;
          timer.cancel();
          return;
        }
        
        // 捕获当前帧
        final image = await _cameraController!.takePicture();
        
        // 读取图像文件
        final bytes = await File(image.path).readAsBytes();
        
        // 压缩图像（减少传输数据量）
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          // 调整大小到 640x480（按照文档建议）
          final resized = img.copyResize(decodedImage, width: 640, height: 480);
          
          // 转换为 JPEG 格式，质量 0.8（按照文档建议 0.7-0.9）
          final compressed = img.encodeJpg(resized, quality: 80);
          
          // Base64 编码
          final base64Frame = base64Encode(compressed);
          
          // 发送视频帧（按照文档格式）
          _channel!.sink.add(json.encode({
            'type': 'video',
            'data': base64Frame,
          }));
          
          print('🎥 发送视频帧: ${compressed.length} bytes (${resized.width}x${resized.height})');
        }
        
        // 删除临时文件
        await File(image.path).delete();
      } catch (e) {
        print('❌ 采集视频帧失败: $e');
      } finally {
        _isCapturingFrame = false;
      }
    });
  }
  
  /// 停止视频采集
  Future<void> _stopVideoCapture() async {
    try {
      // ✅ 先取消定时器，防止在 dispose 后还尝试采集
      _videoFrameTimer?.cancel();
      _videoFrameTimer = null;
      
      // ✅ 等待当前采集完成
      while (_isCapturingFrame) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      if (_isCameraInitialized && _cameraController != null) {
        _isCameraInitialized = false; // ✅ 先设置标志，防止定时器继续执行
        await _cameraController!.dispose();
        _cameraController = null;
      }
      
      print('📹 摄像头已停止');
    } catch (e) {
      print('❌ 停止摄像头失败: $e');
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
    await _stopVideoCapture();
    _stopCallRecording();  // ✅ 停止通话录音（不需要 await，因为是同步方法）
    await _disconnectWebSocket();
  }
  
  /// 获取连接状态
  bool get isConnected => _isConnected;
  
  /// 获取录音状态
  bool get isRecording => _isRecording;
  
  /// 获取摄像头状态
  bool get isCameraActive => _isCameraInitialized;
  
  /// 获取当前通话记录ID
  String? get callRecordId => _callRecordId;
  
  /// 获取摄像头控制器（用于预览）
  CameraController? get cameraController => _cameraController;
  
  /// 获取当前防御等级
  int get currentDefenseLevel => _currentDefenseLevel;
  
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
    if (_isCameraInitialized) {
      _startVideoFrameCapture();
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
      if (_isCameraInitialized) {
        _startVideoFrameCapture();
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
      if (_isCameraInitialized) {
        _startVideoFrameCapture();
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
