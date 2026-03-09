# 屏幕录制功能实现指南

## 已完成的修改

### 1. 代码修改
- ✅ 替换了摄像头采集为屏幕录制
- ✅ 使用 `flutter_screen_recording` 插件
- ✅ 实现了定期截图并发送给后端
- ✅ 更新了所有相关的状态管理

### 2. 主要变化

#### 导入变化
```dart
// 移除
import 'package:camera/camera.dart';

// 添加
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
```

#### 状态变量变化
```dart
// 移除
CameraController? _cameraController;
bool _isCameraInitialized = false;

// 添加
bool _isScreenRecording = false;
String? _currentScreenshotPath;
```

#### 方法变化
- `_startVideoCapture()` → `_startScreenRecording()`
- `_startVideoFrameCapture()` → `_startScreenshotCapture()`
- `_stopVideoCapture()` → `_stopScreenRecording()`

## 工作原理

### 屏幕录制流程

1. **启动录制**
   - 调用 `FlutterScreenRecording.startRecordScreen()`
   - 系统会弹出权限请求对话框
   - 用户授权后开始录制

2. **定期截图**
   - 每隔 `1/_currentVideoFPS` 秒执行一次
   - 停止录制获取视频文件
   - 提取第一帧作为截图
   - 压缩并发送给后端
   - 重新开始录制

3. **停止录制**
   - 取消定时器
   - 停止屏幕录制
   - 删除临时文件

## 测试步骤

### 1. 首次运行测试

```bash
flutter clean
flutter pub get
flutter run
```

### 2. 功能测试

1. **启动监测**
   - 点击"开始监测"按钮
   - 系统会弹出屏幕录制权限请求
   - 点击"立即开始"授权

2. **验证截图**
   - 查看日志，应该看到：
     ```
     📱 开始屏幕录制...
     ✅ 屏幕录制已启动
     📸 截图采集间隔: 1000ms (1.0 fps)
     📸 发送屏幕截图: XXXXX bytes (640x480)
     ```

3. **后台测试**
   - 按 Home 键让 App 进入后台
   - 打开其他应用（如拨号界面）
   - 等待 30 秒
   - 重新打开 App
   - 停止监测
   - 查看后端日志，确认收到了视频帧

4. **停止监测**
   - 点击"停止监测"按钮
   - 应该看到：
     ```
     📱 屏幕录制已停止
     ```

## 注意事项

### 1. 权限问题
- 首次使用需要用户授权屏幕录制
- 如果用户拒绝，功能会失败但不影响音频检测
- 可以在系统设置中重新授权

### 2. 性能考虑
- 默认帧率为 1 fps（每秒1帧）
- 防御等级升级时会提高帧率
- 截图会压缩到 640x480，质量 80%

### 3. 已知限制
- `flutter_screen_recording` 返回的是视频文件，不是单帧
- 当前实现是停止-截图-重启的循环
- 可能会有短暂的录制中断

## 可能的改进

### 方案 1：使用原生 MediaProjection API
如果当前方案性能不佳，可以考虑：
- 创建原生 Android 代码
- 直接使用 MediaProjection API
- 实现真正的实时截图

### 方案 2：使用 screenshot 插件
- 使用 `screenshot` 插件捕获 Widget
- 但这只能捕获 App 内容，不能捕获系统界面

## 故障排查

### 问题 1：屏幕录制启动失败
**原因：** 用户拒绝权限或系统不支持
**解决：** 
- 检查 Android 版本（需要 Android 5.0+）
- 在系统设置中授权
- 查看日志中的错误信息

### 问题 2：截图无法解码
**原因：** 视频文件格式不支持
**解决：**
- 这是当前实现的限制
- 需要改用原生 API

### 问题 3：后台录制停止
**原因：** 系统限制或电池优化
**解决：**
- 前台服务应该能保持运行
- 检查电池优化设置
- 查看前台服务通知是否显示

## 下一步

1. ✅ 测试屏幕录制功能
2. ⬜ 根据测试结果优化性能
3. ⬜ 如果需要，实现原生 MediaProjection API
4. ⬜ 修复停止时的 Null 错误
5. ⬜ 在不同手机上测试兼容性


