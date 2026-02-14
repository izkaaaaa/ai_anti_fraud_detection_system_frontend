# 权限管理系统使用说明

## 📋 已实现的功能

### 1. 权限配置
- ✅ AndroidManifest.xml 已配置必需权限：
  - 麦克风权限 (RECORD_AUDIO)
  - 录屏权限 (FOREGROUND_SERVICE_MEDIA_PROJECTION)
  - 前台服务权限 (FOREGROUND_SERVICE)
  - 网络权限 (INTERNET)
  - 通知权限 (POST_NOTIFICATIONS)

### 2. 权限管理器 (PermissionManager)
- ✅ 单例模式，全局可用
- ✅ 实时权限状态监控 (使用 GetX Rx)
- ✅ 首次启动时自动弹窗申请权限
- ✅ 权限被拒绝时显示友好提示
- ✅ 永久拒绝时引导用户前往设置

### 3. 权限设置页面 (PermissionSettingsPage)
- ✅ 可视化权限状态展示
- ✅ 一键授权所有权限
- ✅ 快速跳转系统设置
- ✅ 下拉刷新权限状态
- ✅ 隐私承诺说明

### 4. 集成到应用
- ✅ 首次启动时在主页面弹窗申请权限
- ✅ 实时监测页面启动前检查权限
- ✅ 个人中心添加权限设置入口

## 🎯 使用方式

### 用户首次使用流程
1. 打开应用 → 登录成功
2. 自动弹出权限说明对话框
3. 点击"同意并继续" → 系统弹窗请求麦克风权限
4. 授权后即可使用实时监测功能

### 查看和管理权限
1. 进入"我的"页面
2. 点击"权限设置"
3. 查看所有权限状态
4. 可一键授权或前往系统设置

### 实时监测时的权限检查
1. 点击"开始监测"按钮
2. 自动检查麦克风权限
3. 如未授权，弹窗请求权限
4. 授权后才能开始监测

## 📱 权限说明

| 权限 | 用途 | 何时请求 |
|------|------|---------|
| 麦克风 | 录制音频进行实时分析 | 首次启动 / 开始监测时 |
| 录屏 | 捕获屏幕内容检测诈骗 | 实际使用时动态请求 |
| 前台服务 | 保持监测服务运行 | Android 9+ 自动授予 |
| 通知 | 显示风险警告 | Android 13+ 首次启动时 |

## 🔧 开发者接口

### 检查权限
```dart
final permissionManager = PermissionManager();
await permissionManager.checkAllPermissions();

if (permissionManager.hasMicrophonePermission.value) {
  // 有麦克风权限
}
```

### 请求权限
```dart
// 请求单个权限
final granted = await permissionManager.requestMicrophonePermission(context);

// 请求所有权限
final allGranted = await permissionManager.requestAllPermissions(context);
```

### 打开设置
```dart
await permissionManager.openSettings();
```

### 获取权限摘要
```dart
final summary = permissionManager.getPermissionsSummary();
// {'麦克风权限': true, '录屏权限': true, '前台服务权限': true}
```

## 📝 注意事项

1. **首次启动标记**：使用 SharedPreferences 存储 `is_first_launch` 标记
2. **权限状态响应式**：使用 GetX Rx 实现权限状态实时更新
3. **友好的用户体验**：权限被拒绝时提供清晰的说明和引导
4. **录屏权限特殊处理**：需要在实际使用时通过 MediaProjection API 动态请求

## 🚀 测试建议

1. 卸载应用重新安装，测试首次启动权限申请流程
2. 拒绝权限后，测试提示信息和引导逻辑
3. 在系统设置中关闭权限，测试权限检查和重新请求
4. 测试权限设置页面的刷新和状态显示

