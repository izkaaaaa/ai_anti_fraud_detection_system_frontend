import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 高危告警音频服务
///
/// 负责在高危弹窗弹出时播放告警音效。
/// - App 在前台：通过 flutter_sound 直接播放 assets 中的音频
/// - App 在后台：通过原生 Android MediaPlayer 播放 res/raw 中的音频
///
/// 单例，通过 [AlertAudioService.instance] 访问。
class AlertAudioService {
  AlertAudioService._();
  static final AlertAudioService instance = AlertAudioService._();

  static const _nativeChannel = MethodChannel(
    'com.example.ai_anti_fraud_detection_system_frontend/alert_audio',
  );

  FlutterSoundPlayer? _player;
  bool _isInitialized = false;
  bool _isPlaying = false;

  /// 是否正在播放中
  bool get isPlaying => _isPlaying;

  /// 初始化音频播放器（懒加载，首次播放前调用）
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
    _isInitialized = true;
    print('✅ [AlertAudio] 播放器初始化完成');
  }

  /// 播放高危告警音效
  ///
  /// [level]: "high" 或 "critical" 时播放，medium 不播放
  ///
  /// 会自动判断 App 所处状态：
  /// - 前台（App 可见）→ flutter_sound 播放 assets/高危提示.wav
  /// - 后台（App 不可见）→ 原生 Android MediaPlayer 播放 res/raw/high_risk_alert.wav
  Future<void> playAlertSound(String level) async {
    if (level != 'critical') {
      return; // 只有 critical 才播音
    }

    if (_isPlaying) {
      print('ℹ️ [AlertAudio] 正在播放中，跳过');
      return;
    }

    final isAppInForeground = _checkForeground();

    try {
      if (isAppInForeground) {
        await _playWithFlutterSound();
      } else {
        await _playWithNative();
      }
    } catch (e) {
      print('❌ [AlertAudio] 播放失败: $e');
      // 降级：尝试原生播放
      try {
        await _playWithNative();
      } catch (_) {
        // 忽略二次错误
      }
    }
  }

  /// 通过 flutter_sound 播放 assets 中的音频（前台）
  Future<void> _playWithFlutterSound() async {
    await _ensureInitialized();

    // 从 assets 提取到临时文件（flutter_sound 需要文件路径）
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, 'high_risk_alert.wav'));

    if (!await tempFile.exists()) {
      final data = await rootBundle.load('assets/高危提示.wav');
      await tempFile.writeAsBytes(data.buffer.asUint8List());
    }

    _isPlaying = true;

    await _player!.startPlayer(
      fromURI: tempFile.path,
      codec: Codec.pcm16WAV,
      whenFinished: () {
        _isPlaying = false;
        print('✅ [AlertAudio] flutter_sound 播放完成');
      },
    );

    print('✅ [AlertAudio] flutter_sound 播放中（前台）');
  }

  /// 通过原生 Android MediaPlayer 播放 res/raw 中的音频（后台）
  Future<void> _playWithNative() async {
    _isPlaying = true;

    await _nativeChannel.invokeMethod('playAlertSound', {
      'resourceName': 'high_risk_alert',
    });

    // 等待约 5 秒后自动重置播放状态（保守策略，不依赖原生回调）
    Future.delayed(const Duration(seconds: 5), () {
      _isPlaying = false;
    });

    print('✅ [AlertAudio] 原生 MediaPlayer 播放中（后台）');
  }

  /// 停止播放
  Future<void> stop() async {
    if (!_isPlaying) return;

    try {
      await _player?.stopPlayer();
    } catch (_) {}

    try {
      await _nativeChannel.invokeMethod('stopAlertSound');
    } catch (_) {}

    _isPlaying = false;
    print('ℹ️ [AlertAudio] 播放已停止');
  }

  /// 简单判断 App 是否在前台（通过 app lifecycle state）
  bool _checkForeground() {
    // 如果能获取到 lifecycleState，说明 App 在前台
    // 在后台 Service 中调用时，WidgetsBinding.instance.lifecycleState 为 null
    final state = WidgetsBinding.instance.lifecycleState;
    return state != null && state != AppLifecycleState.paused && state != AppLifecycleState.detached;
  }

  /// 释放资源（在 App 退出时）
  Future<void> dispose() async {
    await stop();
    await _player?.closePlayer();
    _player = null;
    _isInitialized = false;
    print('ℹ️ [AlertAudio] 资源已释放');
  }
}
