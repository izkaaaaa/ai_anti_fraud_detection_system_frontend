# Git 回退前项目进度备份

> 生成时间：2026-03-24  
> 用途：git 回退后，按此文档手动恢复所有修改

---

## 当前阶段目标

在荣耀设备上实现 QQ/微信通话录音，核心方案参考通话录音Pro逆向分析结论：
- 使用 `AudioSource.VOICE_COMMUNICATION`（值=6）作为录音源
- 配合无障碍服务 + 前台服务 + 1像素Activity 三重保活
- 无障碍服务检测到通话后，先启动 OnePXActivity，延迟 800ms 再启动录音

---

## 需要恢复的文件（共4个）

### 文件1：`android/app/src/main/AndroidManifest.xml`

**改动说明：**
- `OnePXActivity` 的 `launchMode` 改为 `singleInstance`（原为 `singleTask`）
- `OnePXActivity` 的 `taskAffinity` 改为 `com.example.ai_anti_fraud_detection_system_frontend.keepalive`（原为主包名）
- 原因：让系统把 OnePXActivity 识别为独立前台任务，荣耀系统前台感知更可靠

**只需修改这一段（`OnePXActivity` 的 activity 声明）：**

```xml
<!-- 1像素Activity - 华为系统保活 -->
<activity
    android:name=".OnePXActivity"
    android:exported="false"
    android:launchMode="singleInstance"
    android:taskAffinity="com.example.ai_anti_fraud_detection_system_frontend.keepalive"
    android:excludeFromRecents="true"
    android:theme="@style/OnePxActivityStyle" />
```

---

### 文件2：`android/app/src/main/kotlin/.../CallDetectionService.kt`

**改动说明：**
1. `startRecordingWithDelay` 方法中延迟从 `300ms` 改为 `800ms`
2. `handleWindowStateChanged` 中通话结束判断新增排除逻辑（排除自己包名、桌面Launcher）

**改动1：找到以下代码并替换**

旧代码：
```kotlin
mainHandler.postDelayed({
    Log.i(TAG, "[$appName] 延迟完成，现在启动录音")
    startRecording()
}, 300)
```

新代码：
```kotlin
mainHandler.postDelayed({
    Log.i(TAG, "[$appName] 延迟完成，现在启动录音")
    startRecording()
}, 800)
```

**改动2：找到 `handleWindowStateChanged` 中通话结束的判断，替换为：**

```kotlin
// 通话结束判断：排除自己的包名和桌面/系统UI
val ownPackage = packageName == applicationContext.packageName
if (isInCall && !ownPackage && packageName != QQ_PACKAGE && packageName != WECHAT_PACKAGE) {
    val isLauncher = packageName == "com.android.launcher3" ||
        packageName == "com.huawei.android.launcher" ||
        packageName == "com.hihonor.android.launcher" ||
        packageName.contains("launcher") ||
        packageName == "com.android.systemui"
    if (isLauncher) {
        Log.d(TAG, "Switched to launcher/system, keeping recording alive")
        return
    }
    Log.i(TAG, "✅ Call ended (switched to other app: $packageName)")
    onStatusChanged?.invoke("通话已结束")
    isInCall = false
    currentCaller = ""
    mainHandler.removeCallbacksAndMessages(null)
    stopRecording()
    onCallEnded?.invoke()
}
```

---

### 文件3：`android/app/src/main/kotlin/.../OnePXActivity.kt`

**改动说明：**
- 原版只在 `onCreate` 判断一次录音状态，判断完直接返回
- 新版改为每 500ms 轮询录音状态，录音真正停止后才 `finish()`
- 原因：防止录音进行中 OnePXActivity 被系统意外回收

**完整替换为以下内容：**

```kotlin
package com.example.ai_anti_fraud_detection_system_frontend

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity

/**
 * 1像素Activity - 荣耀/华为系统保活
 *
 * 作用：让系统认为 App 有前台界面，保住 VOICE_COMMUNICATION 录音权限。
 *
 * 关键改动：
 * - 使用独立 taskAffinity（singleInstance），不与 MainActivity 共享任务栈
 * - 录音进行中时持续存在，通过轮询检测录音结束后才 finish()
 * - 不模拟返回键，不干扰用户界面切换
 */
class OnePXActivity : Activity() {
    companion object {
        private const val TAG = "OnePXActivity"
        private const val POLL_INTERVAL_MS = 500L
    }

    private val handler = Handler(Looper.getMainLooper())
    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!AudioRecordingService.isRecordingActive()) {
                Log.d(TAG, "Recording stopped, finishing OnePXActivity")
                finish()
            } else {
                handler.postDelayed(this, POLL_INTERVAL_MS)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "OnePXActivity created, isRecording=${AudioRecordingService.isRecordingActive()}")

        if (!AudioRecordingService.isRecordingActive()) {
            Log.d(TAG, "Not recording, finishing immediately")
            finish()
            return
        }

        // 缩成1像素，位于屏幕左上角
        window.setGravity(Gravity.LEFT or Gravity.TOP)
        window.setLayout(1, 1)
        val params = window.attributes
        params.x = 0
        params.y = 0
        window.attributes = params

        Log.d(TAG, "Recording active, staying as 1px window for keep-alive")

        // 启动轮询，录音结束后自动 finish
        handler.postDelayed(pollRunnable, POLL_INTERVAL_MS)
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(pollRunnable)
        Log.d(TAG, "OnePXActivity destroyed")
    }
}
```

---

### 文件4：`E:/flutter/flutter/packages/flutter_tools/gradle/settings.gradle.kts`

**改动说明：**
- 这是 Flutter SDK 内部文件（不在项目目录里）
- 在 `repositories` 里加了阿里云镜像，解决国内无法访问 `dl.google.com` 的问题
- **注意：git 回退不会影响这个文件，但记录在此以防 Flutter SDK 更新时丢失**

**完整替换为以下内容：**

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        google()
        mavenCentral()
    }
}
```

---

## 当前未解决的问题

1. **通话录音仍无法采集到声音** - 上述修改在逻辑上是正确的，但尚未完成测试验证（因构建环境网络问题阻塞）
2. **构建网络问题** - `dl.google.com` 在当前环境无法访问，已修改 Flutter SDK 内部 `settings.gradle.kts` 加入阿里云镜像，但测试时仍失败（VPN 未对 Gradle JVM 进程生效）

## 下一步计划

- 解决构建网络问题后，重新安装 APK 到荣耀真机
- 用 Logcat 验证以下关键日志是否出现：
  - `OnePXActivity created`
  - `延迟完成，现在启动录音`（应在前一条约 800ms 后出现）
  - `Recording started with source: VOICE_COMMUNICATION`
  - `Read audio data: XXXX bytes`（readSize > 0 才说明真正采集到声音）
