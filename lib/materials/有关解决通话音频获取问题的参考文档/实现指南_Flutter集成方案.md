# AI诈骗识别应用 - Flutter集成实现指南

## 快速开始

本指南基于通话录音Pro的技术方案，为Flutter应用提供完整的集成步骤。

---

## 第一步：Android原生模块设置

### 1.1 创建Kotlin Service

创建文件：`android/app/src/main/kotlin/com/example/ai_fraud/services/RecordingService.kt`

```kotlin
package com.example.ai_fraud.services

import android.app.Service
import android.content.Intent
import android.media.MediaRecorder
import android.os.IBinder
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class RecordingService : Service() {
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        
        when (action) {
            "START_RECORDING" -> startRecording()
            "STOP_RECORDING" -> stopRecording()
        }
        
        return START_STICKY
    }
    
    private fun startRecording() {
        if (isRecording) return
        
        try {
            val recordDir = File(getExternalFilesDir(null), "recordings")
            if (!recordDir.exists()) recordDir.mkdirs()
            
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val audioFile = File(recordDir, "call_$timestamp.wav")
            
            mediaRecorder = MediaRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
                setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
                setOutputFile(audioFile.absolutePath)
                prepare()
                start()
            }
            
            isRecording = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun stopRecording() {
        if (!isRecording) return
        
        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null
            isRecording = false
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    override fun onDestroy() {
        stopRecording()
        super.onDestroy()
    }
}
```

### 1.2 创建AccessibilityService

创建文件：`android/app/src/main/kotlin/com/example/ai_fraud/services/CallDetectionService.kt`

```kotlin
package com.example.ai_fraud.services

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Intent
import android.text.TextUtils
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

class CallDetectionService : AccessibilityService() {
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // 监听应用切换
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val componentName = ComponentName(
                event.packageName.toString(),
                event.className.toString()
            )
            
            // 检测QQ视频通话
            if (isQQVideoCall(componentName)) {
                startRecording()
                showNotification("检测到QQ视频通话，开始录音")
            }
            
            // 检测微信视频通话
            if (isWeChatVideoCall(componentName)) {
                startRecording()
                showNotification("检测到微信视频通话，开始录音")
            }
        }
        
        // 监听通话邀请文本
        val text = event.text
        if (text != null && text.isNotEmpty()) {
            val content = text.joinToString()
            if (content.contains("邀请你语音通话") || 
                content.contains("邀请你视频通话")) {
                startRecording()
            }
        }
    }
    
    override fun onInterrupt() {
        stopRecording()
    }
    
    private fun isQQVideoCall(componentName: ComponentName): Boolean {
        return componentName.packageName == "com.tencent.mobileqq" &&
               (componentName.className.contains("VideoActivity") ||
                componentName.className.contains("CallActivity"))
    }
    
    private fun isWeChatVideoCall(componentName: ComponentName): Boolean {
        return componentName.packageName == "com.tencent.mm" &&
               componentName.className.contains("VideoActivity")
    }
    
    private fun startRecording() {
        val intent = Intent(this, RecordingService::class.java)
        intent.action = "START_RECORDING"
        startService(intent)
    }
    
    private fun stopRecording() {
        val intent = Intent(this, RecordingService::class.java)
        intent.action = "STOP_RECORDING"
        startService(intent)
    }
    
    private fun showNotification(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }
}
```

### 1.3 创建MethodChannel处理器

创建文件：`android/app/src/main/kotlin/com/example/ai_fraud/MainActivity.kt`

```kotlin
package com.example.ai_fraud

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.ai_fraud/recording"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAccessibilityService" -> {
                        startAccessibilityService()
                        result.success(true)
                    }
                    "stopAccessibilityService" -> {
                        stopAccessibilityService()
                        result.success(true)
                    }
                    "startRecording" -> {
                        startRecording()
                        result.success(true)
                    }
                    "stopRecording" -> {
                        stopRecording()
                        result.success(true)
                    }
                    "isAccessibilityServiceEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    private fun startAccessibilityService() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
    
    private fun stopAccessibilityService() {
        // 用户需要手动在设置中关闭
    }
    
    private fun startRecording() {
        val intent = Intent(this, com.example.ai_fraud.services.RecordingService::class.java)
        intent.action = "START_RECORDING"
        startService(intent)
    }
    
    private fun stopRecording() {
        val intent = Intent(this, com.example.ai_fraud.services.RecordingService::class.java)
        intent.action = "STOP_RECORDING"
        startService(intent)
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        // 检查无障碍服务是否启用
        return try {
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: ""
            enabledServices.contains("com.example.ai_fraud/.services.CallDetectionService")
        } catch (e: Exception) {
            false
        }
    }
}
```

---

## 第二步：AndroidManifest.xml配置

编辑文件：`android/app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.ai_fraud">

    <!-- 权限声明 -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <application>
        <!-- 主Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- 录音服务 -->
        <service
            android:name=".services.RecordingService"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback" />

        <!-- 无障碍服务 -->
        <service
            android:name=".services.CallDetectionService"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>
    </application>
</manifest>
```

---

## 第三步：无障碍服务配置

创建文件：`android/app/src/main/res/xml/accessibility_service_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault"
    android:canRetrieveWindowContent="true"
    android:description="@string/accessibility_service_description"
    android:notificationTimeout="100" />
```

创建文件：`android/app/src/main/res/values/strings.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">AI诈骗识别</string>
    <string name="accessibility_service_description">
        用于检测通话并进行AI诈骗识别分析
    </string>
</resources>
```

---

## 第四步：Flutter端实现

### 4.1 创建Recording Service

创建文件：`lib/services/recording_service.dart`

```dart
import 'package:flutter/services.dart';

class RecordingService {
  static const platform = MethodChannel('com.example.ai_fraud/recording');
  
  /// 启动无障碍服务
  static Future<bool> startAccessibilityService() async {
    try {
      final result = await platform.invokeMethod<bool>('startAccessibilityService');
      return result ?? false;
    } catch (e) {
      print('Error starting accessibility service: $e');
      return false;
    }
  }
  
  /// 停止无障碍服务
  static Future<bool> stopAccessibilityService() async {
    try {
      final result = await platform.invokeMethod<bool>('stopAccessibilityService');
      return result ?? false;
    } catch (e) {
      print('Error stopping accessibility service: $e');
      return false;
    }
  }
  
  /// 开始录音
  static Future<bool> startRecording() async {
    try {
      final result = await platform.invokeMethod<bool>('startRecording');
      return result ?? false;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }
  
  /// 停止录音
  static Future<bool> stopRecording() async {
    try {
      final result = await platform.invokeMethod<bool>('stopRecording');
      return result ?? false;
    } catch (e) {
      print('Error stopping recording: $e');
      return false;
    }
  }
  
  /// 检查无障碍服务是否启用
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await platform.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (e) {
      print('Error checking accessibility service: $e');
      return false;
    }
  }
}
```

### 4.2 创建UI页面

创建文件：`lib/screens/recording_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/recording_service.dart';

class RecordingScreen extends StatefulWidget {
  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool isAccessibilityEnabled = false;
  bool isRecording = false;
  
  @override
  void initState() {
    super.initState();
    _checkAccessibilityService();
  }
  
  Future<void> _checkAccessibilityService() async {
    final enabled = await RecordingService.isAccessibilityServiceEnabled();
    setState(() {
      isAccessibilityEnabled = enabled;
    });
  }
  
  Future<void> _enableAccessibilityService() async {
    await RecordingService.startAccessibilityService();
    // 延迟检查，因为用户需要手动启用
    await Future.delayed(Duration(seconds: 2));
    _checkAccessibilityService();
  }
  
  Future<void> _toggleRecording() async {
    if (!isAccessibilityEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先启用无障碍服务')),
      );
      return;
    }
    
    if (isRecording) {
      await RecordingService.stopRecording();
    } else {
      await RecordingService.startRecording();
    }
    
    setState(() {
      isRecording = !isRecording;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI诈骗识别'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 无障碍服务状态
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAccessibilityEnabled ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '无障碍服务状态',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    isAccessibilityEnabled ? '已启用' : '未启用',
                    style: TextStyle(
                      fontSize: 14,
                      color: isAccessibilityEnabled ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            
            // 启用按钮
            if (!isAccessibilityEnabled)
              ElevatedButton(
                onPressed: _enableAccessibilityService,
                child: Text('启用无障碍服务'),
              ),
            
            SizedBox(height: 32),
            
            // 录音状态
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red : Colors.grey,
              ),
              child: Center(
                child: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            Text(
              isRecording ? '正在录音...' : '未录音',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            SizedBox(height: 32),
            
            // 录音按钮
            ElevatedButton(
              onPressed: isAccessibilityEnabled ? _toggleRecording : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecording ? Colors.red : Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                isRecording ? '停止录音' : '开始录音',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 第五步：权限处理

创建文件：`lib/utils/permission_helper.dart`

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// 请求必要的权限
  static Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.storage,
    ].request();
    
    return statuses[Permission.microphone]?.isGranted ?? false;
  }
  
  /// 检查权限状态
  static Future<bool> checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    final storageStatus = await Permission.storage.status;
    
    return micStatus.isGranted && storageStatus.isGranted;
  }
}
```

---

## 第六步：主应用入口

编辑文件：`lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'screens/recording_screen.dart';
import 'utils/permission_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 请求权限
  await PermissionHelper.requestPermissions();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI诈骗识别',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: RecordingScreen(),
    );
  }
}
```

---

## 第七步：pubspec.yaml配置

编辑文件：`pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  permission_handler: ^11.4.3
  path_provider: ^2.0.15
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

---

## 测试步骤

1. **安装应用**
   ```bash
   flutter run
   ```

2. **启用无障碍服务**
   - 点击"启用无障碍服务"按钮
   - 在系统设置中找到应用
   - 启用无障碍服务

3. **测试录音**
   - 启用无障碍服务后，点击"开始录音"
   - 进行QQ/微信视频通话
   - 应用应自动检测并开始录音

4. **验证录音文件**
   - 录音文件保存在 `/sdcard/Android/data/com.example.ai_fraud/files/recordings/`
   - 可以通过文件管理器查看

---

## 常见问题

### Q1: 无障碍服务无法启用？
**A**: 某些设备可能限制无障碍服务。尝试：
- 重启设备
- 清除应用缓存
- 在开发者选项中检查相关设置

### Q2: 录音文件为空？
**A**: 检查：
- 麦克风权限是否已授予
- 设备是否设置为外放
- 是否有足够的存储空间

### Q3: 应用在后台被杀死？
**A**: 添加前台服务通知：
```kotlin
private fun startForegroundService() {
    val notification = NotificationCompat.Builder(this, "recording")
        .setContentTitle("AI诈骗识别")
        .setContentText("正在监听通话...")
        .setSmallIcon(R.drawable.ic_launcher_foreground)
        .build()
    
    startForeground(1, notification)
}
```

---

## 总结

这个实现方案提供了：
- ✅ 自动通话检测
- ✅ 后台录音
- ✅ 无障碍服务集成
- ✅ Flutter UI界面
- ✅ 权限管理

下一步可以添加：
- 音频处理和AI分析
- 云端上传
- 诈骗检测算法
- 用户界面优化

