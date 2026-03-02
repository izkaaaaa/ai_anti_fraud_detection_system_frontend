import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// 百度实时语音识别服务
/// 
/// 使用百度 WebSocket API 进行实时语音识别
/// 文档：https://ai.baidu.com/ai-doc/SPEECH/Glwyy4zcx
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
  FlutterSoundRecorder? _recorder;
  StreamSubscription? _recorderSubscription;
  StreamController<Uint8List>? _audioStreamController;
  bool _isRecording = false;
  bool _isConnected = false;
  
  // 音频缓冲区（用于积攒 160ms 的数据）
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
  
  /// 初始化服务
  Future<bool> initialize() async {
    try {
      print('🎤 初始化百度语音识别服务...');
      
      // 1. 检查麦克风权限
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        print('❌ 没有麦克风权限');
        onError?.call('需要麦克风权限');
        return false;
      }
      
      // 2. 初始化录音器
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      
      print('✅ 百度语音识别服务初始化成功');
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
  Future<bool> startRecognition() async {
    try {
      print('🎤 开始语音识别...');
      
      // 1. 连接 WebSocket
      final connected = await _connectWebSocket();
      if (!connected) {
        onError?.call('连接失败');
        return false;
      }
      
      // 2. 发送开始帧
      await _sendStartFrame();
      
      // 3. 开始录音
      final recordingStarted = await _startRecording();
      if (!recordingStarted) {
        onError?.call('启动录音失败');
        await _disconnectWebSocket();
        return false;
      }
      
      onStatusChange?.call('识别中...');
      return true;
    } catch (e) {
      print('❌ 启动识别失败: $e');
      onError?.call('启动失败: $e');
      return false;
    }
  }
  
  /// 连接 WebSocket
  Future<bool> _connectWebSocket() async {
    try {
      // 生成唯一的 sn（session number）
      final sn = Uuid().v4();
      
      // 构建 WebSocket URL
      final wsUrl = Uri.parse('$WS_URL?sn=$sn');
      
      print('🔌 连接 WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(wsUrl);
      
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
      onStatusChange?.call('已连接');
      
      print('✅ WebSocket 连接成功');
      return true;
    } catch (e) {
      print('❌ 连接 WebSocket 失败: $e');
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
        'cuid': 'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
        'format': 'pcm',
        'sample': 16000,
      }
    };
    
    _channel!.sink.add(json.encode(startFrame));
    print('📤 发送开始帧: dev_pid=15372 (中文普通话+加强标点)');
  }
  
  /// 开始录音
  Future<bool> _startRecording() async {
    try {
      print('🎤 开始录音...');
      print('   格式: PCM 16bit');
      print('   采样率: 16000 Hz');
      print('   声道: 单声道');
      
      // 清空缓冲区
      _audioBuffer.clear();
      
      // 创建一个 StreamController 来接收音频数据
      _audioStreamController = StreamController<Uint8List>();
      
      // 监听音频流
      _recorderSubscription = _audioStreamController!.stream.listen((audioData) {
        // 直接接收 Uint8List 数据
        if (audioData.isNotEmpty) {
          _onAudioData(audioData);
        }
      });
      
      // 开始录音（PCM 格式，16000Hz，单声道）
      await _recorder!.startRecorder(
        toStream: _audioStreamController!.sink,  // 使用流式录音
        codec: Codec.pcm16,                      // PCM 16bit
        sampleRate: 16000,                       // 16kHz
        numChannels: 1,                          // 单声道
      );
      
      _isRecording = true;
      print('✅ 录音已启动');
      return true;
    } catch (e) {
      print('❌ 启动录音失败: $e');
      return false;
    }
  }
  
  /// 音频数据回调
  void _onAudioData(Uint8List data) {
    if (!_isConnected || _channel == null) {
      return;
    }
    
    // 将数据添加到缓冲区
    _audioBuffer.addAll(data);
    
    // 当缓冲区达到 160ms（5120 bytes）时，发送一帧
    while (_audioBuffer.length >= FRAME_SIZE) {
      // 取出一帧数据
      final frame = Uint8List.fromList(_audioBuffer.sublist(0, FRAME_SIZE));
      _audioBuffer.removeRange(0, FRAME_SIZE);
      
      // 发送音频帧
      _sendAudioFrame(frame);
    }
  }
  
  /// 发送音频帧（二进制帧）
  void _sendAudioFrame(Uint8List audioData) {
    try {
      // 直接发送二进制数据（Opcode 0x2）
      _channel!.sink.add(audioData);
      // print('📤 发送音频帧: ${audioData.length} bytes');
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
      print('🛑 停止语音识别...');
      
      // 1. 停止录音
      await _stopRecording();
      
      // 2. 发送剩余缓冲区数据
      if (_audioBuffer.isNotEmpty) {
        // 补齐到 160ms（不足的部分填充 0）
        while (_audioBuffer.length < FRAME_SIZE) {
          _audioBuffer.add(0);
        }
        final lastFrame = Uint8List.fromList(_audioBuffer);
        _sendAudioFrame(lastFrame);
        _audioBuffer.clear();
      }
      
      // 3. 发送结束帧
      await _sendFinishFrame();
      
      // 4. 等待最终结果（最多等待 2 秒）
      await Future.delayed(Duration(seconds: 2));
      
      // 5. 断开 WebSocket
      await _disconnectWebSocket();
      
      onStatusChange?.call('已停止');
    } catch (e) {
      print('❌ 停止识别失败: $e');
    }
  }
  
  /// 停止录音
  Future<void> _stopRecording() async {
    try {
      if (_isRecording && _recorder != null) {
        await _recorderSubscription?.cancel();
        await _recorder!.stopRecorder();
        await _audioStreamController?.close();
        _isRecording = false;
        print('✅ 录音已停止');
      }
    } catch (e) {
      print('❌ 停止录音失败: $e');
    }
  }
  
  /// 发送结束帧
  Future<void> _sendFinishFrame() async {
    try {
      if (_isConnected && _channel != null) {
        final finishFrame = {
          'type': 'FINISH',
        };
        
        _channel!.sink.add(json.encode(finishFrame));
        print('📤 发送结束帧');
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
      // 百度返回的是 JSON 文本
      final data = json.decode(message);
      final type = data['type'];
      
      switch (type) {
        case 'MID_TEXT':
          // 临时识别结果（实时）
          final result = data['result'] ?? '';
          if (result.isNotEmpty) {
            print('🎤 临时结果: $result');
            onPartialResult?.call(result);
          }
          break;
          
        case 'FIN_TEXT':
          // 最终识别结果
          final errNo = data['err_no'] ?? 0;
          
          if (errNo == 0) {
            // 识别成功
            final result = data['result'] ?? '';
            final startTime = data['start_time'] ?? 0;
            final endTime = data['end_time'] ?? 0;
            
            if (result.isNotEmpty) {
              print('✅ 最终结果: $result');
              print('   时间: ${startTime}ms - ${endTime}ms');
              onFinalResult?.call(result, startTime, endTime);
            }
          } else {
            // 识别错误
            final errMsg = data['err_msg'] ?? '未知错误';
            print('❌ 识别错误: [$errNo] $errMsg');
            onError?.call('识别错误: $errMsg');
          }
          break;
          
        case 'HEARTBEAT':
          // 心跳帧（忽略）
          // print('💓 收到心跳');
          break;
          
        default:
          print('❓ 未知消息类型: $type');
          print('   完整消息: $data');
      }
    } catch (e) {
      print('❌ 处理消息失败: $e');
      print('   原始消息: $message');
    }
  }
  
  // ============================================================
  // 清理资源
  // ============================================================
  
  /// 清理资源
  Future<void> dispose() async {
    await stopRecognition();
    
    if (_recorder != null) {
      await _recorder!.closeRecorder();
      _recorder = null;
    }
  }
  
  // ============================================================
  // 状态查询
  // ============================================================
  
  /// 是否正在识别
  bool get isRecognizing => _isRecording && _isConnected;
  
  /// 是否已连接
  bool get isConnected => _isConnected;
}
