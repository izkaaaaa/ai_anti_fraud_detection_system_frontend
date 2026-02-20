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
  
  // 摄像头控制器
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Timer? _videoFrameTimer;
  bool _isCapturingFrame = false; // 防止并发拍照
  
  // 音频波形数据
  StreamSubscription? _audioLevelSubscription;
  final List<double> _audioWaveformData = List.filled(50, 0.0);
  
  // 连接状态
  bool _isConnected = false;
  String? _callRecordId;
  
  // 回调函数
  Function(Map<String, dynamic>)? onDetectionResult;
  Function(String)? onStatusChange;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(List<double>)? onAudioWaveformUpdate; // 新增：音频波形回调
  
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
  
  /// 处理 WebSocket 消息
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'];
      
      switch (type) {
        case 'audio_result':
          // 音频检测结果
          print('🎵 收到音频检测结果: ${data['result']}');
          onDetectionResult?.call({'audio': data['result']});
          break;
        case 'video_result':
          // 视频检测结果
          print('🎥 收到视频检测结果: ${data['result']}');
          onDetectionResult?.call({'video': data['result']});
          break;
        case 'text_result':
          // 文本检测结果
          print('📝 收到文本检测结果: ${data['result']}');
          onDetectionResult?.call({'text': data['result']});
          break;
        case 'detection_result':
          // 综合检测结果
          onDetectionResult?.call(data['data']);
          break;
        case 'status':
          // 状态更新
          onStatusChange?.call(data['message']);
          break;
        case 'error':
          // 错误消息
          onError?.call(data['message']);
          break;
        case 'heartbeat_ack':
        case 'pong':
          // 心跳响应
          print('💓 心跳响应');
          break;
        case 'ack':
          // 消息确认
          print('✅ 消息已确认: ${data['msg_type']}');
          break;
        default:
          print('❓ 未知消息类型: $type');
      }
    } catch (e) {
      print('❌ 处理 WebSocket 消息失败: $e');
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
      
      // 监听音频音量（用于波形显示）
      _startAudioLevelMonitoring();
      
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
  void _startAudioLevelMonitoring() {
    _audioLevelSubscription?.cancel();
    _audioLevelSubscription = _audioRecorder.onProgress!.listen((event) {
      if (event.decibels != null) {
        // 将分贝值转换为 0-1 的范围
        // 分贝范围通常是 -160 到 0
        final normalizedLevel = (event.decibels! + 160) / 160;
        final clampedLevel = normalizedLevel.clamp(0.0, 1.0);
        
        // 更新波形数据（移除第一个，添加新的到最后）
        _audioWaveformData.removeAt(0);
        _audioWaveformData.add(clampedLevel);
        
        // 通知 UI 更新
        onAudioWaveformUpdate?.call(List.from(_audioWaveformData));
      }
    });
  }
  
  /// 停止录音
  Future<void> _stopAudioRecording() async {
    try {
      _audioStreamTimer?.cancel();
      _audioStreamTimer = null;
      
      _audioLevelSubscription?.cancel();
      _audioLevelSubscription = null;
      
      if (_isRecording) {
        await _audioRecorder.stopRecorder();
        _isRecording = false;
      }
      
      // 关闭录音器
      if (_isRecorderInitialized) {
        await _audioRecorder.closeRecorder();
        _isRecorderInitialized = false;
      }
      
      // 删除临时文件
      if (_currentAudioPath != null) {
        final file = File(_currentAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentAudioPath = null;
      }
      
      print('🎤 录音已停止');
    } catch (e) {
      print('❌ 停止录音失败: $e');
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
        // 暂停录音以读取当前数据
        await _audioRecorder.stopRecorder();
        
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
    
    // 每秒采集 2 帧（根据文档建议 1-5 帧）
    _videoFrameTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (!_isCameraInitialized || !_isConnected || _channel == null) {
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
        // 捕获当前帧
        final image = await _cameraController!.takePicture();
        
        // 读取图像文件
        final bytes = await File(image.path).readAsBytes();
        
        // 压缩图像（减少传输数据量）
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          // 调整大小到 640x480
          final resized = img.copyResize(decodedImage, width: 640, height: 480);
          
          // 转换为 JPEG 格式（压缩）
          final compressed = img.encodeJpg(resized, quality: 70);
          
          // Base64 编码
          final base64Frame = base64Encode(compressed);
          
          // 发送视频帧
          _channel!.sink.add(json.encode({
            'type': 'video',
            'data': base64Frame,
          }));
          
          print('🎥 发送视频帧: ${compressed.length} bytes');
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
      _videoFrameTimer?.cancel();
      _videoFrameTimer = null;
      
      if (_isCameraInitialized && _cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
        _isCameraInitialized = false;
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
}
