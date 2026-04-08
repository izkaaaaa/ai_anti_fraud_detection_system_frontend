# AI 反诈检测系统 · 前端（Flutter）

> 一款面向普通用户、老年人、儿童家长的 AI 智能通话反诈移动应用，提供实时通话检测、家庭守护、安全报告、案例学习等功能。

---

## 项目概览

| 项目 | 说明 |
|------|------|
| 框架 | Flutter 3.x（Android / iOS / macOS / Windows） |
| 状态管理 | GetX |
| 网络 | Dio + WebSocket |
| 语音合成 | 科大讯飞 TTS WebSocket API |
| 语音识别 | 百度语音识别 |
| 音频录制 | Flutter Sound（VOICE_COMMUNICATION 音频源） |
| 实时通话检测 | 自研 WebSocket 实时流式检测服务 |
| 样式风格 | 赛博朋克（Cyberpunk）：深色背景 + 荧光绿/黄高亮 |
| UI 组件库 | Material Design + Convex Bottom Bar |

---

## 目录结构

```
lib/
├── main.dart                          # 应用入口
├── routes/
│   └── index.dart                     # 路由配置 & 全局 builder（老年人模式）
├── api/
│   ├── auth_api.dart                  # 认证相关接口（登录/注册/用户信息）
│   ├── system_api.dart                # 系统级接口
│   └── 参考文件.dart                  # 接口参考
├── pages/
│   ├── Main/                          # 主页面（含底部导航栏）
│   ├── Login/                         # 登录页
│   ├── Register/                      # 注册页
│   ├── Detection/                     # 🔴 实时通话检测页（核心）
│   ├── SecurityReport/                # 📊 个人安全报告页
│   ├── Family/                        # 👨‍👩‍👧‍👦 家庭守护页（监护人模式）
│   ├── LearningCenter/                # 📚 案例学习中心
│   │   ├── index.dart                 # 案例库 & 标语库
│   │   └── PostDetailPage.dart        # 案例详情页
│   ├── Profile/                       # 👤 个人中心
│   ├── CallRecords/                   # 📞 通话记录页
│   ├── Settings/
│   │   └── PermissionSettings.dart    # 权限设置页
│   ├── UserAgreement/                 # 用户协议页
│   └── AudioRecordingTestPage.dart    # 音频录制测试页
├── services/
│   ├── auth_service.dart              # 认证服务（Token / 用户信息）
│   ├── RealTimeDetectionService.dart  # 🔴 实时检测核心服务（WebSocket）
│   ├── CallDetectionService.dart      # 通话检测服务
│   ├── floating_window_service.dart   # Android 悬浮窗服务
│   ├── alert_popup_service.dart       # App 内预警弹窗服务
│   ├── tts_service.dart               # 科大讯飞 TTS 语音合成服务
│   ├── baidu_speech_service.dart      # 百度语音识别服务
│   ├── AudioRecordingService.dart     # 音频录制服务
│   ├── security_report_service.dart    # 安全报告服务
│   ├── family_service.dart            # 家庭组服务
│   ├── foreground_task_handler.dart    # 前台任务处理器
│   └── local_notification_service.dart# 本地通知服务
├── stores/
│   └── user_store.dart                # 用户状态管理
├── viewmodels/
│   └── login_models.dart              # 登录相关数据模型
├── utils/
│   ├── DioRequest.dart                # Dio 网络请求封装
│   ├── TokenManager.dart              # Token 管理
│   ├── PermissionManager.dart         # 权限管理器
│   ├── LoadingDialog.dart             # 全局加载弹窗
│   ├── ToastUtils.dart                # Toast 提示工具
│   └── report_speech_text.dart        # 报告文本 → TTS 文本转换
├── contants/
│   ├── theme.dart                     # 赛博朋克主题色/字体/阴影/渐变
│   ├── index.dart                     # 全局常量 & API 地址配置
│   ├── index(自用版).dart             # 自用版配置
│   └── index(内网穿透版).dart          # 内网穿透版配置
└── materials/                         # 接口文档 & 开发笔记（参考）
```

---

## 核心功能

### 1. 实时通话检测（DetectionPage）

| 功能 | 说明 |
|------|------|
| 通话音频实时录制 | 通过 `VOICE_COMMUNICATION` 音频源捕获通话双方声音 |
| AI 深度伪造检测 | 实时分析音频/视频，检测是否为 AI 合成声音 |
| 三级防御机制 | 低/中/高三级防御提示，支持用户主动挂断 |
| 风险分级展示 | 安全 / 低风险 / 中风险 / 高风险 / 严重风险 五级 |
| 实时波形动画 | 通话期间动态展示音频波形 |
| 前台服务通知 | Android 前台服务通知栏展示检测状态 |
| 悬浮窗显示 | Android 悬浮窗实时显示检测结果 |
| 风险预警弹窗 | 检测到风险时弹出 App 内预警弹窗（支持文字朗读） |
| 多渠道通知 | 检测到风险时同时触发系统通知 + 家庭监护人通知 |
| 老年人模式 | 全局字体放大 1.25×，弹窗进一步放大 |

**实时检测流程：**
```
用户滑动开关 → 创建通话记录（POST）→ 建立 WebSocket 双向连接
    ↓
实时流：音频数据（base64）→ 后端 AI 检测 → 实时返回结果
    ↓
综合风险等级 → UI 更新 / 悬浮窗 / 预警弹窗 / 监护人通知
    ↓
用户滑动停止 → 结束通话记录（PUT）→ 关闭 WebSocket
```

### 2. 家庭守护（FamilyPage）

| 功能 | 说明 |
|------|------|
| 家庭组管理 | 创建 / 加入 / 解散家庭组 |
| 成员角色管理 | 主管理员、副管理员、普通成员三级权限 |
| 家人风险预警 | 监护人实时收到家人的风险预警推送 |
| SOS 求救 | 家人可一键发送紧急求助给监护人 |
| 远程干预 | 监护人可远程强制结束被监护人的通话 |
| 申请审批 | 主/副管理员审批成员加入申请 |

### 3. 个人安全报告（SecurityReportPage）

| 功能 | 说明 |
|------|------|
| 智能报告生成 | 基于用户历史通话记录，AI 生成个性化安全报告 |
| Markdown 渲染 | 美化展示报告内容 |
| 语音朗读 | 科大讯飞 TTS 将报告内容朗读出来 |
| 风险趋势分析 | 展示近期风险数据、薄弱点分析 |
| 个性化建议 | 根据用户角色类型（老人/学生/青壮年）定制防骗建议 |

### 4. 案例学习中心（LearningCenter）

| 功能 | 说明 |
|------|------|
| 诈骗案例库 | 真实诈骗案例展示，含类型、标签、描述 |
| 防骗标语库 | 每日推送精选防骗标语 |
| 个性化推荐 | 根据用户角色类型（role_type）推荐相关内容 |
| 视频学习 | 内嵌防骗教育视频 |
| 案例详情 | Markdown 渲染案例详情页面 |

### 5. 登录与注册

- **登录方式**：邮箱 + 验证码（免密码）
- **注册**：邮箱注册，支持选择角色类型（老人 / 儿童 / 学生 / 青壮年）
- **角色类型**：用于个性化推荐、安全报告定制、老年人模式自动开启

### 6. 权限管理

| 权限 | 用途 |
|------|------|
| 麦克风（音频录制）| 实时通话检测的音频采集 |
| 摄像头（屏幕录制）| 视频通话时的屏幕录制分析 |
| 电话状态 | 检测通话是否正在进行 |
| 悬浮窗 | Android 悬浮窗显示检测状态 |
| 存储 | 截图、报告文件存取 |

---

## 视觉风格

**主题**：赛博朋克（Cyberpunk）深色主题

| 颜色 | 用途 | 色值 |
|------|------|------|
| 荧光黄绿 | 主色调 | `#CDED63` |
| 荧光黄 | 强调色 | `#EFFF86` |
| 深墨绿 | 辅助色 | `#095943` |
| 深灰黑 | 背景色 | `#25282B` |
| 米白色 | 文字色 | `#F6F6EF` |
| 绿色 | 成功色 | `#9DC24F` |
| 荧光黄 | 警告色 | `#EFFF86` |
| 红色 | 危险色 | `#FF6B6B` |

---

## 老年人模式

当用户 `role_type` 为「老人」时，系统自动开启：

- **全局字体放大**：通过 `MaterialApp.builder` 设置 `textScaler = 1.25×`，最大 `1.6×`
- **预警弹窗进一步放大**：弹窗内图标/字号额外乘 `1.35` 系数
- **安全报告语音朗读**：科大讯飞 TTS 朗读报告全文
- **判断依据**：`AuthService.isElderMode`（读取 `role_type` 字段）

---

## 网络与后端

**后端地址**（`lib/contants/index.dart`）：

```dart
// 当前使用内网穿透地址
static String get BASE_URL => "http://shuode.nat100.top";

// WebSocket 实时检测
// ws://shuode.nat100.top/api/detection/ws/{user_id}/{call_id}?token={jwt}
```

**核心接口**：

| 接口 | 方法 | 路径 |
|------|------|------|
| 登录 | POST | `/api/users/login` |
| 注册 | POST | `/api/users/register` |
| 发送验证码 | POST | `/api/users/send-code` |
| 用户信息 | GET/PUT | `/api/users/profile` |
| 创建通话记录 | POST | `/api/call-records/start` |
| 结束通话记录 | PUT | `/api/call-records/end` |
| 实时检测 WebSocket | WS | `/api/detection/ws/{user_id}/{call_id}` |
| 安全报告生成 | GET | `/api/report/personal/{user_id}` |
| 家庭组管理 | - | `/api/family/...` |
| 案例学习推荐 | GET | `/api/education/recommendations/profile/{user_id}` |

---

## 主要依赖

| 包 | 用途 |
|----|------|
| `get: ^4.7.3` | 状态管理 & 路由 |
| `dio: ^5.9.1` | HTTP 网络请求 |
| `web_socket_channel: ^2.4.0` | WebSocket（实时检测）|
| `flutter_sound: ^9.2.13` | 音频播放 & 录制 |
| `flutter_foreground_task: ^9.2.0` | Android 前台服务 |
| `flutter_local_notifications: ^17.2.3` | 本地通知 |
| `permission_handler: ^12.0.1` | 权限管理 |
| `screenshot: ^3.0.0` | 屏幕截图 |
| `fl_chart: ^0.68.0` | 图表（安全报告）|
| `flutter_markdown: ^0.7.4` | Markdown 渲染 |
| `convex_bottom_bar: ^3.2.0` | 底部导航栏 |
| `action_slider: ^0.7.0` | 滑动确认控件 |
| `step_progress_indicator: ^1.0.2` | 步骤进度条 |
| `table_calendar: ^3.2.0` | 日历组件 |
| `video_player: ^2.8.0` | 视频播放 |
| `carousel_slider: ^5.1.2` | 轮播图 |
| `uuid: ^4.5.1` | UUID 生成 |
| `path_provider: ^2.1.5` | 文件路径 |
| `file_picker: ^8.1.6` | 文件选择 |
| `camera: ^0.10.5` | 摄像头 |

---

## 开发说明

### 运行项目

```bash
# 安装依赖
flutter pub get

# 运行（调试模式）
flutter run

# 构建 APK
flutter build apk --release

# 构建 APK（内网穿透版）
flutter build apk --release -t lib/main.dart
```

### 修改后端地址

编辑 `lib/contants/index.dart` 中的 `BASE_URL`：

```dart
// 本地模拟器测试
static String get BASE_URL => "http://10.0.2.2:8000";

// 真机 WiFi 测试
static String get BASE_URL => "http://192.168.x.x:8000";

// 内网穿透（生产）
static String get BASE_URL => "http://shuode.nat100.top";
```

### 修改讯飞 TTS 参数

编辑 `lib/services/tts_service.dart`：

```dart
static const String _appId    = 'your_app_id';
static const String _apiKey   = 'your_api_key';
static const String _apiSecret = 'your_api_secret';
static const String _vcn = 'xiaoyan';  // 发音人
static const int _speed = 50;           // 语速 0~100
```

### 老年人模式测试

1. 注册时选择角色类型为「老人」，或
2. 在 `lib/services/auth_service.dart` 临时修改 `isElderMode` 返回 `true` 进行测试

---

## 项目亮点

1. **实时性**：通话音频实时流式传输 + WebSocket 低延迟响应
2. **多模态检测**：支持音频伪造检测、视频深度伪造检测、文本风险分析
3. **三级防御**：从低到高的渐进式风险提示，尊重用户自主判断
4. **家庭守护**：监护人可实时掌握家人通话安全状况
5. **老年人友好**：自动检测角色类型并开启大字体模式
6. **语音播报**：科大讯飞 TTS 为视力障碍用户提供报告朗读功能
7. **赛博朋克 UI**：深色科技感主题，荧光绿/黄高亮，视觉效果突出
8. **前台服务**：Android 后台持续检测，悬浮窗实时展示状态
9. **权限自适应**：支持 Android 不同版本权限模型，动态请求

---

## 待完善功能

- [ ] iOS 悬浮窗支持
- [ ] 实时检测期间弹窗语音朗读（TTS）
- [ ] 多语言支持
- [ ] 深色模式切换
- [ ] 通知点击跳转
- [ ] 数据统计可视化仪表盘
