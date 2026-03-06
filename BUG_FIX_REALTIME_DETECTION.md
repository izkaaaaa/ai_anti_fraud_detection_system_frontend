# 🐛 实时监测 Bug 修复报告

**修复时间：** 2026-02-23  
**修复内容：** 音频波形不显示 + 后端消息格式不匹配

---

## 📊 问题分析

### 问题 1：音频波形不显示 ❌

**现象：**
- 实时监测页面的音频波形区域显示"未监测"
- 前端日志中没有任何音频分贝值的输出
- 应该有类似 `🎤 录音进度: 0s, 分贝: 26.92` 的日志，但完全没有

**原因：**
`flutter_sound` 的 `onProgress` 回调需要先调用 `setSubscriptionDuration()` 才能触发。代码中虽然监听了 `onProgress`，但忘记设置订阅间隔。

**修复：**
在 `_startAudioRecording()` 方法中，`startRecorder()` 之后添加：
```dart
// 设置订阅间隔（必须在 startRecorder 之后调用）
await _audioRecorder.setSubscriptionDuration(Duration(milliseconds: 100));
```

---

### 问题 2：后端消息格式不匹配 ❌

**现象：**
后端返回的检测结果无法被前端识别，日志显示：
```
I/flutter: 📨 收到消息: type=info
I/flutter: ❓ 未知消息类型: info
I/flutter:    完整消息: {type: info, data: {title: 语音检测通过, ...}}
```

**原因：**
- **接口文档定义：** 后端应该返回 `type: detection_result`
- **实际返回：** 后端返回的是 `type: info`
- 前端只处理了 `detection_result`，导致 `info` 消息被忽略

**后端返回的实际格式：**
```json
{
  "type": "info",
  "data": {
    "title": "语音检测通过",
    "message": "当前通话环境安全 (置信度: 0.00)。",
    "risk_level": "safe",
    "confidence": 0.0,
    "call_id": 30,
    "timestamp": "2026-02-23T11:54:25.667957",
    "display_mode": "toast"
  }
}
```

**修复：**
在 `_handleWebSocketMessage()` 中添加 `case 'info'` 处理逻辑，将后端的 `info` 格式转换为前端期望的格式：

```dart
case 'info':
  // 后端实际返回的消息类型（兼容处理）
  final infoData = data['data'] ?? {};
  final title = infoData['title'] ?? '';
  final infoMessage = infoData['message'] ?? '';
  final riskLevel = infoData['risk_level'] ?? 'safe';
  final confidence = (infoData['confidence'] ?? 0.0).toDouble();
  
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
```

---

## ✅ 修复后的效果

### 音频波形显示
修复后，前端日志应该会显示：
```
I/flutter: 🎤 录音进度: 0s, 分贝: 26.92
I/flutter: 🎤 录音进度: 0s, 分贝: 63.95
I/flutter: 🎤 录音进度: 1s, 分贝: 60.03
...
```

界面上的音频波形会实时跳动。

### 检测结果显示
修复后，前端日志应该会显示：
```
I/flutter: 📨 收到消息: type=info
I/flutter: ℹ️ 信息消息:
I/flutter:    标题: 语音检测通过
I/flutter:    消息: 当前通话环境安全 (置信度: 0.00)。
I/flutter:    风险等级: safe
I/flutter:    置信度: 0.0%
I/flutter: 📊 收到检测结果: {detection_type: 语音, is_risk: false, ...}
```

界面上的检测结果会实时更新。

---

## 🔧 修改的文件

### `lib/services/RealTimeDetectionService.dart`

**修改 1：添加订阅间隔设置**
```dart
// 第 367 行附近
_isRecording = true;

// 设置订阅间隔（必须在 startRecorder 之后调用）
await _audioRecorder.setSubscriptionDuration(Duration(milliseconds: 100));

// 监听音频音量（用于波形显示）
_startAudioLevelMonitoring();
```

**修改 2：添加 info 消息处理**
```dart
// 第 290 行附近，在 case 'control' 之后添加
case 'info':
  // 后端实际返回的消息类型（兼容处理）
  final infoData = data['data'] ?? {};
  // ... 转换逻辑
  break;
```

---

## 🧪 测试步骤

1. **重新运行 App**
   ```bash
   flutter run
   ```

2. **进入实时监测页面**
   - 点击"开始监测"
   - 授予权限

3. **观察音频波形**
   - 应该看到波形实时跳动
   - 日志中应该有分贝值输出

4. **观察检测结果**
   - 等待 3 秒后应该收到音频检测结果
   - 界面上的检测结果应该更新
   - 日志中应该有 `ℹ️ 信息消息` 输出

---

## 📝 后续建议

### 给后端团队的建议
后端返回的消息格式与接口文档不一致：
- **文档定义：** `type: detection_result`
- **实际返回：** `type: info`

建议后端统一使用文档定义的格式，或者更新接口文档。

### 前端兼容性
目前前端已经做了兼容处理，同时支持：
- ✅ `type: detection_result`（文档格式）
- ✅ `type: info`（实际格式）

---

## 🎯 验证清单

- [ ] 音频波形实时显示
- [ ] 日志中有分贝值输出
- [ ] 收到后端检测结果
- [ ] 检测结果正确显示在界面上
- [ ] 音频检测结果更新
- [ ] 视频检测结果更新（如果后端返回）

---

**修复完成！** 🎉







