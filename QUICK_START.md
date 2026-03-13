# 快速开始 - POC 验证

## 5 分钟快速验证

### 步骤 1：编译项目

```bash
cd /e:/wangtiao/ai_anti_fraud_detection_system_frontend
flutter clean
flutter pub get
flutter run
```

### 步骤 2：打开测试页面

在你的应用中添加导航到测试页面。编辑 `lib/main.dart` 或你的路由文件：

```dart
import 'package:ai_anti_fraud_detection_system_frontend/pages/AudioRecordingTestPage.dart';

// 在你的路由表中添加
routes: {
  '/audio-test': (context) => AudioRecordingTestPage(),
  // ... 其他路由
},
```

然后导航到该页面：

```dart
Navigator.pushNamed(context, '/audio-test');
```

### 步骤 3：进行测试

1. **启动录制**
   - 点击"启动录制"按钮
   - 观察日志输出

2. **打开微信通话**
   - 打开微信
   - 进行视频通话
   - 观察是否有 "收到音频数据" 的日志

3. **检查音频源**
   - 查看日志中的 "使用音频源"
   - 如果是 `VOICE_COMMUNICATION`，说明成功！
   - 如果是 `MIC`，说明已降级

4. **停止录制**
   - 点击"停止录制"按钮
   - 查看总共收到的音频帧数和字节数

## 关键指标

| 指标 | 成功 | 降级 | 失败 |
|------|------|------|------|
| 音频源 | VOICE_COMMUNICATION | MIC | UNKNOWN |
| 能否获取音频 | ✅ 是 | ⚠️ 需要免提 | ❌ 否 |
| 日志输出 | 持续增加 | 缓慢增加 | 无输出 |

## 预期输出

### ✅ 成功情况

```
✅ 音频录制已启动
🎤 使用音频源: VOICE_COMMUNICATION
✅ 使用 VOICE_COMMUNICATION - 可以与微信/QQ 共享麦克风
🎤 收到音频数据: 1024 bytes (总计: 1024 bytes)
🎤 收到音频数据: 1024 bytes (总计: 2048 bytes)
🎤 收到音频数据: 1024 bytes (总计: 3072 bytes)
...
📊 总共收到 8 个音频帧，共 8192 bytes
```

### ⚠️ 降级情况

```
✅ 音频录制已启动
🎤 使用音频源: MIC
⚠️ 已降级到 MIC - 只能录本地声音，需要打开免提
🎤 收到音频数据: 512 bytes (总计: 512 bytes)
...
```

### ❌ 失败情况

```
❌ 启动失败
```

## 故障排查

### 问题：应用崩溃

**解决方案：**
1. 检查权限：设置 → 应用 → 权限 → 麦克风
2. 重新编译：`flutter clean && flutter run`

### 问题：无法获取音频数据

**解决方案：**
1. 确保有声音输入（说话或播放音乐）
2. 检查是否已降级到 MIC（需要打开免提）
3. 尝试其他应用（微信、QQ 等）

### 问题：看不到日志

**解决方案：**
1. 打开 Android Studio 的 Logcat
2. 过滤 "AudioRecording"
3. 或者查看测试页面的日志显示

## 下一步

### 如果成功 ✅

1. 集成到 RealTimeDetectionService
2. 处理音频数据（转文字、AI 检测等）
3. 优化性能

### 如果降级 ⚠️

1. 提示用户打开免提
2. 或改变产品设计

### 如果失败 ❌

1. 查看详细日志
2. 检查权限和设备支持
3. 考虑其他方案

## 文件位置

- 测试页面：`lib/pages/AudioRecordingTestPage.dart`
- 音频服务：`lib/services/AudioRecordingService.dart`
- Android 服务：`android/app/src/main/kotlin/.../AudioRecordingService.kt`
- 详细指南：`POC_VERIFICATION_GUIDE.md`
- 使用指南：`VOICE_COMMUNICATION_GUIDE.md`

## 需要帮助？

如果遇到问题，请提供：
1. 手机型号和 Android 版本
2. 完整的日志输出
3. 错误信息
4. 测试场景（微信/QQ/其他）

