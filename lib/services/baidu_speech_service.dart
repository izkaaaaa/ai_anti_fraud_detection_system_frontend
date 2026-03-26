import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

/// 百度实时语音识别服务
/// 
/// 使用百度 WebSocket API 进行实时语音识别
/// 文档：https://ai.baidu.com/ai-doc/SPEECH/Glwyy4zcx
///
/// ⚠️ 重要：本服务不再内部录音，由外部通过 feedAudioData() 喂入 PCM 数据
/// 原因：AudioRecordingService 已在录音，两个录音器同时抢占麦克风会导致其中一个失败
class BaiduSpeechService {
  // ============================================================
  // 🔑 配置信息
  // ============================================================
  static const String APP_ID = '122183674';
  static const String API_KEY = '3V6S9GLhEhLjiIrKSA5qVz71';
  
  // WebSocket 地址
  static const String WS_URL = 'wss://vop.baidu.com/realtime_asr';
  
  // ============================================================
  // 状态管理
  // ============================================================
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  bool _isRecording = false;
  bool _isConnected = false;
  
  // 音频缓冲区（用于积攒 160ms 的数据，由外部喂入 PCM 数据）
  final List<int> _audioBuffer = [];
  static const int FRAME_SIZE = 5120; // 160ms = 5120 bytes (16000Hz * 0.16s * 2bytes)
  
  // 回调函数
  Function(String)? onPartialResult;          // 临时识别结果回调（MID_TEXT）
  Function(String, int, int)? onFinalResult;  // 最终识别结果回调（FIN_TEXT，带时间戳）
  Function(String)? onStatusChange;           // 状态变化回调
  Function(String)? onError;                  // 错误回调
  Function()? onConnected;                    // 连接成功回调
  Function()? onDisconnected;                 // 断开连接回调
  
  // ============================================================
  // 初始化
  // ============================================================
  
  /// 初始化服务（无需录音器，直接返回成功）
  Future<bool> initialize() async {
    try {
      print('🎤 初始化百度语音识别服务...');
      print('✅ 百度语音识别服务初始化成功（使用外部音频流，无需独立录音器）');
      return true;
    } catch (e) {
      print('❌ 初始化失败: $e');
      onError?.call('初始化失败: $e');
      return false;
    }
  }
  
  // ============================================================
  // 开始识别
  // ============================================================
  
  /// 开始实时语音识别
  /// 注意：不再内部录音，由外部通过 feedAudioData() 喂入 PCM 数据
  Future<bool> startRecognition() async {
    try {
      print('🎤 开始语音识别（等待外部喂入音频数据）...');
      
      // 1. 连接 WebSocket
      final connected = await _connectWebSocket();
      if (!connected) {
        onError?.call('连接失败');
        return false;
      }
      
      // 2. 发送开始帧
      await _sendStartFrame();
      
      _isRecording = true;
      _audioBuffer.clear();
      onStatusChange?.call('识别中...');
      print('✅ 百度语音识别已就绪，等待外部喂入音频数据');
      return true;
    } catch (e) {
      print('❌ 启动识别失败: $e');
      onError?.call('启动失败: $e');
      return false;
    }
  }

  /// 外部喂入 PCM 音频数据（由 AudioRecordingService 的回调调用）
  /// [pcmData] 16000Hz 单声道 16bit PCM 原始数据
  void feedAudioData(Uint8List pcmData) {
    if (!_isConnected || _channel == null || !_isRecording) return;
    _audioBuffer.addAll(pcmData);
    while (_audioBuffer.length >= FRAME_SIZE) {
      final frame = Uint8List.fromList(_audioBuffer.sublist(0, FRAME_SIZE));
      _audioBuffer.removeRange(0, FRAME_SIZE);
      _sendAudioFrame(frame);
    }
  }

  // ============================================================
  // WebSocket 管理
  // ============================================================
  
  /// 连接 WebSocket
  Future<bool> _connectWebSocket() async {
    try {
      final sn = Uuid().v4();
      final wsUrl = Uri.parse('$WS_URL?sn=$sn');
      print('🔌 连接百度语音 WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channelSubscription = _channel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('❌ 百度语音 WebSocket 错误: $error');
          onError?.call('连接错误: $error');
          _isConnected = false;
          onDisconnected?.call();
        },
        onDone: () {
          print('🔌 百度语音 WebSocket 连接关闭');
          _isConnected = false;
          onDisconnected?.call();
        },
      );
      
      _isConnected = true;
      onConnected?.call();
      onStatusChange?.call('已连接');
      print('✅ 百度语音 WebSocket 连接成功');
      return true;
    } catch (e) {
      print('❌ 连接百度语音 WebSocket 失败: $e');
      return false;
    }
  }
  
  /// 发送开始帧
  Future<void> _sendStartFrame() async {
    final startFrame = {
      'type': 'START',
      'data': {
        'appid': int.parse(APP_ID),
        'appkey': API_KEY,
        'dev_pid': 15372,  // 中文普通话 + 加强标点
        'cuid': 'flutter_client_\${DateTime.now().millisecondsSinceEpoch}',
        'format': 'pcm',
        'sample': 16000,
      }
    };
    _channel!.sink.add(json.encode(startFrame));
    print('📤 发送百度语音开始帧: dev_pid=15372 (中文普通话+加强标点)');
  }
  
  /// 发送音频帧（二进制帧）
  void _sendAudioFrame(Uint8List audioData) {
    try {
      _channel!.sink.add(audioData);
    } catch (e) {
      print('❌ 发送音频帧失败: $e');
    }
  }
  
  // ============================================================
  // 停止识别
  // ============================================================
  
  /// 停止语音识别
  Future<void> stopRecognition() async {
    try {
      print('🛑 停止百度语音识别...');
      _isRecording = false;
      
      // 发送剩余缓冲区数据（补齐到 160ms）
      if (_audioBuffer.isNotEmpty && _isConnected && _channel != null) {
        while (_audioBuffer.length < FRAME_SIZE) {
          _audioBuffer.add(0);
        }
        final lastFrame = Uint8List.fromList(_audioBuffer.sublist(0, FRAME_SIZE));
        _sendAudioFrame(lastFrame);
        _audioBuffer.clear();
      }
      
      // 发送结束帧
      await _sendFinishFrame();
      
      // 等待最终结果
      await Future.delayed(Duration(seconds: 2));
      
      // 断开 WebSocket
      await _disconnectWebSocket();
      
      onStatusChange?.call('已停止');
    } catch (e) {
      print('❌ 停止识别失败: $e');
    }
  }
  
  /// 发送结束帧
  Future<void> _sendFinishFrame() async {
    try {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(json.encode({'type': 'FINISH'}));
        print('📤 发送百度语音结束帧');
      }
    } catch (e) {
      print('❌ 发送结束帧失败: $e');
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
  
  // ============================================================
  // 消息处理
  // ============================================================
  
  /// 处理 WebSocket 消息
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'];
      
      switch (type) {
        case 'MID_TEXT':
          final result = data['result'] ?? '';
          if (result.isNotEmpty) {
            print('📝 [语音转文字] 实时识别: $result');
            onPartialResult?.call(result);
          }
          break;
          
        case 'FIN_TEXT':
          final errNo = data['err_no'] ?? 0;
          if (errNo == 0) {
            final result = data['result'] ?? '';
            final startTime = data['start_time'] ?? 0;
            final endTime = data['end_time'] ?? 0;
            if (result.isNotEmpty) {
              print('✅ [语音转文字] 最终识别结果: $result');
              print('   时间段: ${startTime}ms - ${endTime}ms');
              onFinalResult?.call(result, startTime, endTime);
            }
          } else {
            final errMsg = data['err_msg'] ?? '未知错误';
            print('❌ [语音转文字] 识别错误: [$errNo] $errMsg');
            onError?.call('识别错误: $errMsg');
          }
          break;
          
        case 'HEARTBEAT':
          // 心跳帧（忽略）
          break;
          
        default:
          print('❓ [百度语音] 未知消息类型: $type，完整消息: $data');
      }
    } catch (e) {
      print('❌ [百度语音] 处理消息失败: $e，原始消息: $message');
    }
  }
  
  // ============================================================
  // 清理资源
  // ============================================================
  
  /// 清理资源
  Future<void> dispose() async {
    await stopRecognition();
  }
  
  // ============================================================
  // 状态查询
  // ============================================================
  
  /// 是否正在识别
  bool get isRecognizing => _isRecording && _isConnected;
  
  /// 是否已连接
  bool get isConnected => _isConnected;
}
