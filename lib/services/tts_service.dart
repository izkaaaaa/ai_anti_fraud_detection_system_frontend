import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/report_speech_text.dart';

/// 科大讯飞语音合成（TTS）服务
/// 支持流式 WebSocket 音频接收，实时播放 / 保存 MP3
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  // ── 科大讯飞鉴权参数（请替换为你的实际值）──────────────
  static const String _appId = '05bc1915';
  static const String _apiKey = 'dd738f8dd8358a580ef93b84a00c785c';
  static const String _apiSecret = 'ODU2NGFkOTZlMzc0ZDdjNzI2YjlkMTk4';

  // ── TTS 配置 ────────────────────────────────────────
  /// 发音人（需控制台开通）：xiaoyan-青年女声, aisjiuxu-讯飞小燕, aisxping-讯飞小萍
  static const String _vcn = 'xiaoyan';
  /// 音频格式：lame=MP3（流式）, raw=PCM
  static const String _aue = 'lame';
  /// 语速 0~100
  static const int _speed = 50;
  /// 音量 0~100
  static const int _volume = 50;

  // ── 播放状态 ─────────────────────────────────────────
  static const TtsState idle = TtsState.idle;
  TtsState _state = TtsState.idle;
  TtsState get state => _state;

  // 播放进度回调
  void Function(TtsState state, double progress)? onStateChanged;

  // ── 内部状态 ─────────────────────────────────────────
  WebSocket? _ws;
  bool _isClosing = false;
  String? _tempFilePath;

  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _playerInitialized = false;

  // ── 公开 API ─────────────────────────────────────────

  /// 将报告文本转为语音并播放
  /// 超长文本按讯飞限制（&lt;8000 字节/次）自动切段依次合成后拼接播放。
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      debugPrint('⚠️ TTS: 文本为空，跳过');
      return;
    }

    if (_state == TtsState.playing) {
      await stop();
    }

    try {
      _updateState(TtsState.playing);

      final parts = chunkTextForTts(trimmed);
      debugPrint('🔊 TTS 共 ${parts.length} 段（讯飞单次约 7KB UTF-8 上限）');

      final allBytes = <int>[];
      for (var i = 0; i < parts.length; i++) {
        debugPrint('🔊 合成第 ${i + 1}/${parts.length} 段，${utf8.encode(parts[i]).length} 字节');
        allBytes.addAll(await _synthesize(parts[i]));
      }

      await _initPlayer();
      await _player.startPlayer(
        fromDataBuffer: Uint8List.fromList(allBytes),
        codec: Codec.mp3,
        whenFinished: () {
          _updateState(TtsState.idle);
          _deleteTempFile();
        },
      );
    } catch (e) {
      debugPrint('❌ TTS 播放失败: $e');
      _updateState(TtsState.idle);
      _deleteTempFile();
    }
  }

  /// 停止播放
  Future<void> stop() async {
    if (_isClosing) return;
    _isClosing = true;

    try {
      if (_player.isPlaying) {
        await _player.stopPlayer();
      }
      if (_ws != null) {
        await _ws!.close(1000);
        _ws = null;
      }
    } catch (e) {
      debugPrint('❌ TTS 停止失败: $e');
    } finally {
      _isClosing = false;
      _updateState(TtsState.idle);
      _deleteTempFile();
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();
    if (_playerInitialized) {
      await _player.closePlayer();
      _playerInitialized = false;
    }
  }

  // ── 内部方法 ─────────────────────────────────────────

  /// 初始化播放器
  Future<void> _initPlayer() async {
    if (!_playerInitialized) {
      await _player.openPlayer();
      _playerInitialized = true;
    }
  }

  /// 合成语音（连接讯飞 WebSocket，等待音频数据）
  Future<Uint8List> _synthesize(String text) async {
    final chunks = <int>[];

    final wsUrl = _buildAuthUrl();
    debugPrint('🔊 正在连接讯飞 TTS: $wsUrl');

    final completer = Completer<Uint8List>();

    _ws = await WebSocket.connect(wsUrl);

    _ws!.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final code = json['code'] as int?;

          if (code != null && code != 0) {
            final err = '讯飞 TTS 错误码: $code, ${json['message']}';
            debugPrint('❌ $err');
            if (!completer.isCompleted) completer.completeError(err);
            _ws?.close();
            return;
          }

          final audioBase64 = json['data']?['audio'] as String?;
          final status = json['data']?['status'] as int?;

          if (audioBase64 != null && audioBase64.isNotEmpty) {
            chunks.addAll(base64Decode(audioBase64));
          }

          // status=2 表示合成结束
          if (status == 2) {
            debugPrint('✅ TTS 合成完成，共 ${chunks.length} 字节');
            if (!completer.isCompleted) {
              completer.complete(Uint8List.fromList(chunks));
            }
            _ws?.close();
          }
        } catch (e) {
          debugPrint('❌ 解析 TTS 响应失败: $e');
        }
      },
      onError: (err) {
        debugPrint('❌ WebSocket 错误: $err');
        if (!completer.isCompleted) completer.completeError(err);
      },
      onDone: () {
        if (!completer.isCompleted && chunks.isNotEmpty) {
          completer.complete(Uint8List.fromList(chunks));
        } else if (!completer.isCompleted) {
          completer.completeError('TTS 连接异常关闭');
        }
      },
    );

    // 发送合成请求
    final request = {
      'common': {'app_id': _appId},
      'business': {
        'aue': _aue,
        'sfl': 1, // MP3 流式返回标志
        'vcn': _vcn,
        'speed': _speed,
        'volume': _volume,
        'tte': 'UTF8', // 与中文报告一致，避免编码误判
      },
      'data': {
        'status': 2,
        'text': base64Encode(utf8.encode(text)),
      },
    };

    _ws!.add(jsonEncode(request));

    return completer.future;
  }

  /// 构建讯飞鉴权 URL
  String _buildAuthUrl() {
    const host = 'tts-api.xfyun.cn';
    final date = _formatRfc1123Date(DateTime.now().toUtc());
    final origin = 'host: $host\ndate: $date\nGET /v2/tts HTTP/1.1';

    final signature = base64Encode(
      Hmac(sha256, utf8.encode(_apiSecret)).convert(utf8.encode(origin)).bytes,
    );

    final authOrigin = 'api_key="$_apiKey",algorithm="hmac-sha256",headers="host date request-line",signature="$signature"';
    final authorization = base64Encode(utf8.encode(authOrigin));

    return 'wss://$host/v2/tts'
        '?authorization=${Uri.encodeComponent(authorization)}'
        '&date=${Uri.encodeComponent(date)}'
        '&host=$host';
  }

  /// 格式化为 RFC1123 标准日期（与讯飞文档一致）
  String _formatRfc1123Date(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final wd = weekdays[dt.weekday - 1];
    final mon = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$wd, $day $mon $year $hour:$minute:$second GMT';
  }

  /// 更新状态并通知回调
  void _updateState(TtsState newState) {
    _state = newState;
    onStateChanged?.call(newState, 0);
  }

  /// 删除临时文件
  Future<void> _deleteTempFile() async {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      _tempFilePath = null;
    }
  }
}

/// TTS 播放状态
enum TtsState {
  idle,    // 空闲
  playing, // 播放中
}
