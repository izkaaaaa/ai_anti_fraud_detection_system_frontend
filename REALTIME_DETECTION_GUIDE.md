# 实时监测功能实现文档

## 🎯 功能概述

实时监测功能通过 WebSocket 连接后端服务器，实时录制音频并发送到服务器进行 AI 分析，检测通话中的诈骗风险。

## 📦 新增依赖

```yaml
web_socket_channel: ^2.4.0  # WebSocket 通信
record: ^5.0.4              # 音频录制
flutter_sound: ^9.2.13      # 音频处理
```

## 🏗️ 架构设计

### 1. RealTimeDetectionService (服务层)

**位置**: `lib/services/RealTimeDetectionService.dart`

**核心功能**:
- WebSocket 连接管理
- 音频录制和流式传输
- 检测结果接收和处理
- 心跳保活机制
- 通话记录管理

**主要方法**:
```dart
Future<bool> startDetection()  // 启动监测
Future<void> stopDetection()   // 停止监测
void sendText(String text)     // 发送文本检测
void sendVideoFrame(String)    // 发送视频帧检测
```

**回调接口**:
```dart
onDetectionResult  // 检测结果回调
onStatusChange     // 状态变化回调
onError           // 错误回调
onConnected       // 连接成功回调
onDisconnected    // 断开连接回调
```

### 2. DetectionPage (UI层)

**位置**: `lib/pages/Detection/index.dart`

**核心功能**:
- 权限检查和请求
- 监测状态管理
- 实时结果展示
- 风险警告提示
- 音频波形动画

**状态枚举**:
```dart
enum DetectionState {
  idle,        // 空闲
  preparing,   // 准备中
  connecting,  // 连接中
  monitoring,  // 监测中
  warning,     // 警告中
  stopping,    // 停止中
  error,       // 错误
}
```

**风险等级**:
```dart
enum RiskLevel {
  safe,      // 安全
  low,       // 低风险
  medium,    // 中风险
  high,      // 高风险
  critical,  // 严重风险
}
```

## 🔐 权限管理

### 强制权限检查流程

1. **点击"开始监测"按钮**
2. **检查麦克风权限**
   - 已授权 → 继续
   - 未授权 → 显示权限说明对话框
3. **用户选择**
   - 点击"授予权限" → 请求系统权限
   - 点击"取消" → 终止启动
4. **系统权限请求**
   - 用户允许 → 启动监测
   - 用户拒绝 → 显示拒绝提示对话框
5. **拒绝提示对话框**
   - 说明无法使用功能
   - 提供"前往设置"按钮
   - 引导用户手动开启权限

### 权限提示对话框

**首次请求对话框**:
```
⚠️ 需要权限

实时监测功能需要以下权限：
🎤 麦克风权限 - 录制音频进行实时分析

⛔ 不授予权限将无法使用此功能

[取消] [授予权限]
```

**拒绝后提示对话框**:
```
❌ 权限被拒绝

您拒绝了麦克风权限，无法使用实时监测功能。

您可以在以下位置重新授予权限：
• 我的 → 权限设置
• 系统设置 → 应用权限

[知道了] [前往设置]
```

## 🔄 工作流程

### 启动流程

```
用户点击"开始监测"
    ↓
检查麦克风权限
    ↓
[无权限] → 显示权限说明 → 请求权限 → [拒绝] → 显示拒绝提示 → 终止
    ↓                                    ↓
[有权限]                              [允许]
    ↓                                    ↓
状态: 准备中 (500ms)
    ↓
状态: 连接中
    ↓
创建通话记录 (POST /api/call-records/start)
    ↓
连接 WebSocket (ws://8.138.115.75:8000/ws/detection?token=xxx)
    ↓
开始录音 (AudioRecorder)
    ↓
状态: 监测中
    ↓
每3秒发送音频数据到服务器
    ↓
接收检测结果并更新UI
```

### 停止流程

```
用户点击"停止监测"
    ↓
状态: 停止中
    ↓
停止录音
    ↓
断开 WebSocket
    ↓
结束通话记录 (POST /api/call-records/{id}/end)
    ↓
状态: 空闲
    ↓
清空检测结果
```

## 📡 WebSocket 通信协议

### 客户端发送消息

**音频数据**:
```json
{
  "type": "audio",
  "data": "base64_encoded_audio",
  "call_record_id": "123"
}
```

**文本数据**:
```json
{
  "type": "text",
  "data": "通话文本内容",
  "call_record_id": "123"
}
```

**视频帧**:
```json
{
  "type": "video",
  "data": "base64_encoded_frame",
  "call_record_id": "123"
}
```

**心跳**:
```json
{
  "type": "ping"
}
```

### 服务器返回消息

**检测结果**:
```json
{
  "type": "detection_result",
  "data": {
    "audio": {
      "confidence": 0.95,
      "is_fake": false
    },
    "video": {
      "confidence": 0.88,
      "is_deepfake": false
    },
    "text": {
      "risk_level": "safe",
      "keywords": []
    }
  }
}
```

**状态更新**:
```json
{
  "type": "status",
  "message": "连接成功"
}
```

**错误消息**:
```json
{
  "type": "error",
  "message": "错误描述"
}
```

**心跳响应**:
```json
{
  "type": "pong"
}
```

## 🎨 UI 组件

### 1. 状态卡片
- 显示当前监测状态
- 动态图标和颜色
- 状态消息提示

### 2. 音频波形
- 实时动画效果
- 监测中显示波形
- 未监测时显示提示

### 3. 检测结果面板
- 音频检测结果（置信度 + 状态）
- 视频检测结果（置信度 + 状态）
- 文本检测结果（置信度 + 状态）
- 进度条可视化

### 4. 风险警告横幅
- 高风险/严重风险时显示
- 红色背景 + 警告图标
- 醒目提示用户

### 5. 控制按钮
- 开始监测 / 停止监测
- 处理中显示加载动画
- 禁用状态防止重复点击

### 6. 权限提示
- 蓝色信息框
- 说明权限用途
- 快速跳转权限设置

## 🔧 配置说明

### 服务器地址
```dart
static const String WS_BASE_URL = 'ws://8.138.115.75:8000';
```

### 音频录制配置
```dart
RecordConfig(
  encoder: AudioEncoder.aacLc,  // AAC 编码
  bitRate: 128000,              // 128kbps
  sampleRate: 44100,            // 44.1kHz
)
```

### 音频流传输间隔
```dart
Timer.periodic(Duration(seconds: 3), ...)  // 每3秒发送一次
```

### 心跳间隔
```dart
Timer.periodic(Duration(seconds: 30), ...)  // 每30秒发送一次
```

## 🚀 使用方法

### 1. 安装依赖
```bash
flutter pub get
```

### 2. 运行应用
```bash
flutter run
```

### 3. 测试流程
1. 登录应用
2. 进入"实时监测"页面
3. 点击"开始监测"
4. 首次使用会弹出权限请求
5. 授予麦克风权限
6. 等待连接成功
7. 开始实时监测
8. 查看检测结果
9. 点击"停止监测"结束

## ⚠️ 注意事项

1. **权限必需**: 没有麦克风权限无法启动监测
2. **网络连接**: 需要连接到后端服务器
3. **后台运行**: 需要前台服务权限保持运行
4. **资源清理**: 停止监测时会自动清理资源
5. **错误处理**: 连接失败会自动提示用户

## 🐛 常见问题

### Q: 点击开始监测没有反应？
A: 检查是否授予了麦克风权限，可在"我的 → 权限设置"中查看。

### Q: 连接失败怎么办？
A: 检查网络连接和服务器地址是否正确。

### Q: 录音失败？
A: 确保设备有麦克风且权限已授予。

### Q: WebSocket 断开？
A: 检查网络稳定性，服务会自动尝试重连。

## 📝 后续优化

- [ ] 添加断线重连机制
- [ ] 支持视频流实时传输
- [ ] 优化音频压缩算法
- [ ] 添加本地缓存机制
- [ ] 支持离线检测
- [ ] 添加检测历史记录
- [ ] 优化电池消耗
- [ ] 添加更多风险提示

