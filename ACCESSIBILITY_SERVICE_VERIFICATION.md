# 无障碍服务集成 - 快速验证指南

## ✅ 编译检查清单

在运行应用前，请确保以下文件都已正确创建和更新：

### Android 原生文件
- [ ] `android/app/src/main/kotlin/com/example/ai_anti_fraud_detection_system_frontend/CallDetectionService.kt` - 已创建
- [ ] `android/app/src/main/kotlin/com/example/ai_anti_fraud_detection_system_frontend/KeepAliveService.kt` - 已创建
- [ ] `android/app/src/main/kotlin/com/example/ai_anti_fraud_detection_system_frontend/OnePXActivity.kt` - 已创建
- [ ] `android/app/src/main/kotlin/com/example/ai_anti_fraud_detection_system_frontend/MainActivity.kt` - 已更新
- [ ] `android/app/src/main/AndroidManifest.xml` - 已更新
- [ ] `android/app/src/main/res/xml/accessibility_service_config.xml` - 已创建
- [ ] `android/app/src/main/res/values/strings.xml` - 已创建

### Flutter 文件
- [ ] `lib/services/CallDetectionService.dart` - 已创建
- [ ] `lib/pages/Settings/PermissionSettings.dart` - 已更新
- [ ] `lib/main.dart` - 已更新

---

## 🔨 编译步骤

### 1. 清理项目
```bash
flutter clean
cd android
./gradlew clean
cd ..
```

### 2. 获取依赖
```bash
flutter pub get
```

### 3. 编译应用
```bash
# 调试模式
flutter run

# 或者发布模式
flutter run --release
```

### 4. 如果编译失败

**错误：找不到 CallDetectionService**
```
解决：检查文件路径是否正确
路径应该是：android/app/src/main/kotlin/com/example/ai_anti_fraud_detection_system_frontend/CallDetectionService.kt
```

**错误：AndroidManifest.xml 语法错误**
```
解决：检查 XML 格式是否正确
- 确保所有标签都正确闭合
- 检查属性值是否用引号括起来
```

**错误：MethodChannel 找不到**
```
解决：确保 MainActivity.kt 中的 Channel 名称与 Flutter 中的一致
Android: "com.example.ai_anti_fraud_detection_system_frontend/call_detection"
Flutter: "com.example.ai_anti_fraud_detection_system_frontend/call_detection"
```

---

## 🧪 运行时验证

### 1. 启动应用
```bash
flutter run
```

### 2. 检查日志
打开 Android Studio 的 Logcat，查看以下日志：

```
✅ 正常启动日志：
D/CallDetectionService: Service created
D/KeepAliveService: Service created
D/CallDetectionService: Accessibility service connected

❌ 错误日志：
E/CallDetectionService: Error handling accessibility event
E/MainActivity: Error checking accessibility service
```

### 3. 权限设置页面测试

1. **打开应用** → 进入权限设置
2. **查看无障碍服务卡片**
   - 应该显示"未授权"状态
   - 点击卡片应该打开系统设置

3. **启用无障碍服务**
   - 点击"前往设置"
   - 在系统设置中找到本应用
   - 启用无障碍服务
   - 返回应用

4. **验证状态更新**
   - 刷新权限设置页面
   - 无障碍服务应该显示"已授权"

### 4. 通话检测测试

1. **启用无障碍服务后**
2. **进行 QQ 视频通话**
3. **观察 Logcat 日志**

```
预期日志：
I/CallDetectionService: ✅ Detected QQ video call
I/CallDetectionService: ✅ Recording started
D/AudioRecordingService: Audio reading thread started
```

4. **通话结束**

```
预期日志：
I/CallDetectionService: ✅ Call ended
I/CallDetectionService: ✅ Recording stopped
```

---

## 🐛 常见问题排查

### 问题1：无障碍服务无法启用

**症状**：点击"前往设置"后，系统设置中找不到应用

**排查步骤**：
1. 检查 `AndroidManifest.xml` 中是否正确声明了 `CallDetectionService`
2. 检查 `accessibility_service_config.xml` 是否存在
3. 重新编译应用：`flutter clean && flutter run`

**解决方案**：
```xml
<!-- AndroidManifest.xml 中应该有 -->
<service
    android:name=".CallDetectionService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.accessibilityservice.AccessibilityService" />
    </intent-filter>
    <meta-data
        android:name="android.accessibilityservice"
        android:resource="@xml/accessibility_service_config" />
</service>
```

### 问题2：通话检测不工作

**症状**：进行 QQ/微信 通话，但应用没有反应

**排查步骤**：
1. 检查无障碍服务是否真的启用了
   ```bash
   adb shell settings get secure enabled_accessibility_services
   # 应该包含：com.example.ai_anti_fraud_detection_system_frontend/.CallDetectionService
   ```

2. 检查日志中是否有错误
   ```bash
   adb logcat | grep CallDetectionService
   ```

3. 检查应用包名是否正确
   ```bash
   # 在 CallDetectionService.kt 中
   private const val QQ_PACKAGE = "com.tencent.mobileqq"
   private const val WECHAT_PACKAGE = "com.tencent.mm"
   ```

**解决方案**：
- 重启设备
- 重新启用无障碍服务
- 清除应用缓存：`adb shell pm clear com.example.ai_anti_fraud_detection_system_frontend`

### 问题3：录音文件为空

**症状**：通话结束后，录音文件大小为 0

**排查步骤**：
1. 检查麦克风权限是否已授予
2. 检查设备是否设置为外放
3. 检查存储空间是否充足

**解决方案**：
```bash
# 检查权限
adb shell pm list permissions | grep RECORD_AUDIO

# 检查存储空间
adb shell df /sdcard

# 检查录音文件
adb shell ls -la /sdcard/Android/data/com.example.ai_anti_fraud_detection_system_frontend/files/recordings/
```

### 问题4：应用在后台被杀死

**症状**：进行通话时，应用被系统杀死

**排查步骤**：
1. 检查前台服务是否正常启动
2. 检查保活机制是否工作

**解决方案**：
```bash
# 检查前台服务
adb shell dumpsys activity services | grep KeepAliveService

# 检查进程
adb shell ps | grep ai_anti_fraud
```

---

## 📊 验证清单

### 编译阶段
- [ ] 项目编译成功，无错误
- [ ] 所有 Kotlin 文件都被识别
- [ ] AndroidManifest.xml 验证通过

### 运行阶段
- [ ] 应用正常启动
- [ ] 权限设置页面可以打开
- [ ] 无障碍服务卡片显示正确

### 功能阶段
- [ ] 可以启用无障碍服务
- [ ] 无障碍服务状态正确显示
- [ ] 进行通话时应用有反应
- [ ] 日志中显示正确的事件

### 性能阶段
- [ ] 应用不会频繁崩溃
- [ ] 后台保活正常工作
- [ ] 录音文件正确保存
- [ ] 电池消耗在可接受范围内

---

## 🔍 调试技巧

### 1. 查看实时日志
```bash
adb logcat | grep -E "CallDetectionService|KeepAliveService|AudioRecordingService"
```

### 2. 检查无障碍服务状态
```bash
adb shell settings get secure enabled_accessibility_services
```

### 3. 查看应用进程
```bash
adb shell ps | grep ai_anti_fraud
```

### 4. 查看前台服务
```bash
adb shell dumpsys activity services | grep -A 5 "KeepAliveService"
```

### 5. 查看录音文件
```bash
adb shell ls -la /sdcard/Android/data/com.example.ai_anti_fraud_detection_system_frontend/files/recordings/
```

### 6. 清除应用数据
```bash
adb shell pm clear com.example.ai_anti_fraud_detection_system_frontend
```

---

## 📱 测试设备建议

### 推荐设备
- ✅ 荣耀手机（测试华为系统特殊处理）
- ✅ 小米手机（测试 MIUI 系统）
- ✅ 三星手机（测试 OneUI 系统）
- ✅ 原生 Android 设备（测试基础功能）

### 推荐 Android 版本
- ✅ Android 6.0（最低支持）
- ✅ Android 10（中等版本）
- ✅ Android 12+（最新版本）

---

## 🎯 验证成功标志

当你看到以下现象时，说明集成成功：

1. ✅ 应用正常启动，无崩溃
2. ✅ 权限设置页面显示无障碍服务卡片
3. ✅ 可以启用无障碍服务
4. ✅ 进行 QQ/微信 通话时，应用自动启动录音
5. ✅ 通话结束时，应用自动停止录音
6. ✅ 日志中显示正确的事件信息
7. ✅ 应用在后台持续运行，不被系统杀死

---

## 📞 获取帮助

如果遇到问题，请检查：

1. **文件是否正确创建**
   - 检查文件路径
   - 检查文件内容是否完整

2. **配置是否正确**
   - 检查 AndroidManifest.xml
   - 检查 accessibility_service_config.xml

3. **代码是否有语法错误**
   - 检查 Kotlin 代码
   - 检查 Dart 代码

4. **权限是否正确声明**
   - 检查 AndroidManifest.xml 中的权限
   - 检查运行时权限是否已授予

5. **日志是否有错误信息**
   - 查看 Logcat 输出
   - 查看 Flutter 控制台输出

---

## ✨ 下一步

验证成功后，你可以：

1. 测试更多通话应用（钉钉、企业微信等）
2. 优化音频质量
3. 集成 AI 诈骗检测算法
4. 实现通话历史管理
5. 添加用户反馈机制

祝你测试顺利！🚀

