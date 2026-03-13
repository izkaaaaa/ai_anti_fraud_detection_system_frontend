# VOICE_COMMUNICATION 音频录制实现指南

## 概述

本指南说明如何在你们的 AI 诈骗识别系统中使用新的 `VOICE_COMMUNICATION` 音频录制方案。

## 核心改动

### 1. Android 原生代码

#### 新增文件：`AudioRecordingService.kt`
- 位置：`android/app/src/main/kotlin/com/example/ai_anti_fraud_detection_system_frontend/AudioRecordingService.kt`
- 功能：
  - 使用 `VOICE_COMMUNICATION` 音频源（与微信等通话应用共享麦克风）
  - 支持 `setPrivacySensitive(true)` 以实现优先级对齐（Android 11+）
  - 智能降级策略：`VOICE_COMMUNICATION` → `MIC` → `VOICE_RECOGNITION`
  - 实时读取音频数据并通过 Platform Channel 发送给 Flutter

#### 修改文件：`MainActivity.kt`
- 添加了 `AUDIO_RECORDING_CHANNEL` Platform Channel
- 实现了音频录制的方法调用处理
- 设置了音频数据、状态变化和错误的回调

#### 修改文件：`AndroidManifest.xml`
- 注册了 `AudioRecordingService` 前台服务
- 声明了 `FOREGROUND_SERVICE_MICROPHONE` 权限

### 2. Dart 层代码

#### 新增文件：`lib/services/AudioRecordingService.dart`
- 提供了 `AudioRecordingServiceDart` 类
- 封装了与 Android 原生代码的通信
- 提供了简单的 API：`startRecording()`、`stopRecording()` 等

## 使用方法

### 基础使用

```dart
import 'package:ai_anti_fraud_detection_system_frontend/services/AudioRecordingService.dart';

// 获取单例
final audioService = AudioRecordingServiceDart();

// 设置回调
audioService.onAudioDataReceived = (audioBytes) {
  print('🎤 Received audio data: ${audioBytes.length} bytes');
  // 处理音频数据（如发送给后端、转文字等）
};

audioService.onStatusChanged = (status) {
  print('📊 Status: $status');
};

audioService.onError = (error) {
  print('❌ Error: $error');
};

// 启动录制
final started = await audioService.startRecording();
if (started) {
  print('✅ Audio recording started');
}

// 停止录制
final stopped = await audioService.stopRecording();
if (stopped) {
  print('✅ Audio recording stopped');
}

// 检查状态
final isRecording = await audioService.isRecording();
print('Recording: $isRecording');

// 获取当前音频源
final source = await audioService.getCurrentAudioSource();
print('Audio source: $source');
```

### 集成到 RealTimeDetectionService

在你们的 `RealTimeDetectionService.dart` 中，可以这样集成：

```dart
import 'package:ai_anti_fraud_detection_system_frontend/services/AudioRecordingService.dart';

class RealTimeDetectionService {
  // ... 现有代码 ...
  
  final AudioRecordingServiceDart _audioRecordingService = AudioRecordingServiceDart();
  
  /// 启动实时监测
  Future<bool> startDetection() async {
    try {
      // ... 现有代码 ...
      
      // ✅ 使用新的 VOICE_COMMUNICATION 音频录制
      final audioStarted = await _startVoiceCommunicationRecording();
      if (!audioStarted) {
        print('⚠️ VOICE_COMMUNICATION 音频录制启动失败，仅使用音视频检测');
        // 不阻断流程，继续使用其他检测方式
      }
      
      // ... 现有代码 ...
      return true;
    } catch (e) {
      onError?.call('启动失败: $e');
      return false;
    }
  }
  
  /// 启动 VOICE_COMMUNICATION 音频录制
  Future<bool> _startVoiceCommunicationRecording() async {
    try {
      print('🎤 启动 VOICE_COMMUNICATION 音频录制...');
      
      // 设置音频数据回调
      _audioRecordingService.onAudioDataReceived = (audioBytes) {
        // 处理音频数据
        _handleAudioData(audioBytes);
      };
      
      // 设置状态回调
      _audioRecordingService.onStatusChanged = (status) {
        print('📊 音频录制状态: $status');
        onStatusChange?.call('音频录制: $status');
      };
      
      // 设置错误回调
      _audioRecordingService.onError = (error) {
        print('❌ 音频录制错误: $error');
        onError?.call('音频录制错误: $error');
      };
      
      // 启动录制
      final started = await _audioRecordingService.startRecording();
      
      if (started) {
        final source = await _audioRecordingService.getCurrentAudioSource();
        print('✅ 音频录制已启动，使用音频源: $source');
      }
      
      return started;
    } catch (e) {
      print('❌ 启动音频录制失败: $e');
      return false;
    }
  }
  
  /// 处理音频数据
  void _handleAudioData(List<int> audioBytes) {
    // 这里可以：
    // 1. 发送给后端进行 AI 检测
    // 2. 转换为文字（使用百度语音识别等）
    // 3. 保存为文件
    
    print('🎤 处理音频数据: ${audioBytes.length} bytes');
    
    // 示例：发送给后端
    if (_isConnected && _channel != null) {
      final base64Audio = base64Encode(audioBytes);
      _channel!.sink.add(json.encode({
        'type': 'audio',
        'data': base64Audio,
      }));
    }
  }
  
  /// 停止实时监测
  Future<void> stopDetection() async {
    try {
      // ... 现有代码 ...
      
      // ✅ 停止音频录制
      await _audioRecordingService.stopRecording();
      
      // ... 现有代码 ...
    } catch (e) {
      onError?.call('停止失败: $e');
    }
  }
}
```

## 工作原理

### 音频源优先级

```
优先级 1: VOICE_COMMUNICATION
  ↓ (如果失败)
优先级 2: MIC
  ↓ (如果失败)
优先级 3: VOICE_RECOGNITION
```

### setPrivacySensitive(true) 的作用

在 Android 11+ 上，设置 `setPrivacySensitive(true)` 告诉系统：
- 这是一个隐私敏感的应用
- 系统可能会允许多个隐私敏感应用共享音频流
- 这是实现与微信等通话应用共享麦克风的关键

### 数据流

```
微信通话
  ↓
系统麦克风
  ↓
AudioRecordingService (VOICE_COMMUNICATION)
  ↓
Platform Channel
  ↓
AudioRecordingServiceDart (Dart)
  ↓
RealTimeDetectionService
  ↓
后端 AI 检测
```

## 测试步骤

### 1. 编译和运行

```bash
flutter clean
flutter pub get
flutter run
```

### 2. 测试音频录制

在微信通话中：

```dart
final audioService = AudioRecordingServiceDart();

// 启动录制
await audioService.startRecording();

// 检查音频源
final source = await audioService.getCurrentAudioSource();
print('Audio source: $source');  // 应该输出 "VOICE_COMMUNICATION"

// 停止录制
await audioService.stopRecording();
```

### 3. 查看日志

```bash
adb logcat | grep "AudioRecording"
```

预期输出：
```
✅ Recording started with source: VOICE_COMMUNICATION
🎤 Read audio data: 1024 bytes
```

## 常见问题

### Q1: 为什么还是无法获取对方的声音？

**A:** 这取决于以下因素：

1. **设备支持**：某些设备（如三星 Knox 加密机）可能不支持 VOICE_COMMUNICATION
2. **Android 版本**：Android 9 及以下的支持可能有限
3. **系统限制**：某些定制 ROM 可能禁用了这个功能

**解决方案**：
- 检查 logcat 中的 `getCurrentAudioSource()` 输出
- 如果是 "MIC"，说明 VOICE_COMMUNICATION 不可用，已自动降级
- 在 MIC 模式下，需要用户打开免提才能录到对方声音

### Q2: 音频数据如何处理？

**A:** 在 `onAudioDataReceived` 回调中：

```dart
audioService.onAudioDataReceived = (audioBytes) {
  // audioBytes 是 PCM 16-bit 单声道 16kHz 的原始音频数据
  
  // 选项 1: 发送给后端
  sendToBackend(audioBytes);
  
  // 选项 2: 转文字（使用百度语音识别等）
  convertToText(audioBytes);
  
  // 选项 3: 保存为文件
  saveToFile(audioBytes);
};
```

### Q3: 如何确认是否真的在使用 VOICE_COMMUNICATION？

**A:** 

```dart
final source = await audioService.getCurrentAudioSource();
if (source == 'VOICE_COMMUNICATION') {
  print('✅ 使用 VOICE_COMMUNICATION，可以与微信共享麦克风');
} else if (source == 'MIC') {
  print('⚠️ 降级到 MIC，需要用户打开免提');
} else {
  print('❌ 使用其他音频源');
}
```

## 性能考虑

### 音频数据量

- 采样率：16kHz
- 声道：单声道
- 位深：16-bit
- 每秒数据量：16000 × 2 bytes = 32 KB/s
- 每 3 秒数据量：约 96 KB

### 优化建议

1. **缓冲**：在发送前缓冲多个音频帧
2. **压缩**：使用 Opus 或 AAC 编码压缩
3. **采样率**：如果网络有限，可以降低到 8kHz
4. **后台处理**：在独立线程中处理音频数据

## 下一步

1. **验证 POC**：在微信通话中测试是否能获取音频
2. **集成到检测流程**：将音频数据发送给后端进行 AI 检测
3. **优化性能**：根据实际情况调整采样率、缓冲大小等
4. **处理降级**：在 VOICE_COMMUNICATION 不可用时，提示用户打开免提

## 参考资源

- [Android AudioRecord 文档](https://developer.android.com/reference/android/media/AudioRecord)
- [Android 隐私敏感权限](https://developer.android.com/about/versions/11/privacy/permissions)
- [Platform Channel 文档](https://flutter.dev/docs/development/platform-integration/platform-channels)

