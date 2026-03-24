# 荣耀/华为设备 QQ 视频通话录音问题分析

## 问题描述

在荣耀/华为设备（Android 14，Honor TNA-AN00）上，使用 `AudioRecord` + `VOICE_COMMUNICATION` 音频源录制 QQ 视频通话音频时，无论哪种场景，通话接通后都录不到音。

### 场景一：先接电话，再开始检测
- QQ 响铃阶段（`VideoInviteActivity`）：分贝值正常，约 -65dB 到 -70dB（环境音）
- QQ 通话接通（进入 `AVActivity`）后：分贝立即变为 -100dB（全 0 静音数据）
- **不会自动恢复**

### 场景二：先开始检测，再接 QQ 视频电话
- 检测启动后，QQ 响铃阶段（`VideoInviteActivity`）：分贝值正常，约 -65dB 到 -70dB
- QQ 通话接通（进入 `AVActivity`）后：分贝立即变为 -100dB（全 0 静音数据）
- **不会自动恢复**

### 结论
**两种场景本质相同**：QQ 视频通话在 `VideoInviteActivity`（响铃）阶段不影响我们的录音；一旦进入 `AVActivity`（通话接通），我们的 `AudioRecord` 就被系统静音，数据全为 0。

---

## 关键技术背景

### 应用架构
- Flutter 前端 + Android Native 后端
- 录音通过 `AudioRecordingService`（Android Foreground Service）实现
- 通话检测通过 `CallDetectionService`（AccessibilityService）实现
- 保活机制：`OnePXActivity`（1像素Activity，欺骗系统认为App有前台界面）

### QQ 通话界面切换时序
```
QQ 来电 -> VideoInviteActivity（响铃）-> AVActivity（接通）
```

### 荣耀设备特殊行为
1. AudioRecord 必须在前台状态下初始化，否则被系统静音（后台录音保护）
2. 通过 OnePXActivity 让系统认为 App 在前台，绕过后台录音限制
3. 荣耀设备在判断进程优先级时，需要先有前台 Activity，再延迟 800ms 启动录音
4. **进入 AVActivity 后，系统似乎专门为 QQ 保留 VOICE_COMMUNICATION 源，并将其他 App 的同源录音静音**

---

## 已尝试的方案

### 方案1：AVActivity 出现时重建 AudioRecord（引发崩溃）
- AVActivity 在荣耀设备上会被连续触发多次（3-4次）
- 多次并发重建导致 `F/AudioTrackShared: releaseBuffer: mUnreleased out of range` native 崩溃
- 加了 AtomicBoolean 防抖 + synchronized 锁后崩溃消失
- **但重建后仍然静音（-100dB）**

### 方案2：不重建，等待系统自动恢复
- **系统永远不会自动恢复**，整个通话期间都是 -100dB

### 方案3：区分场景，AVActivity 接通时触发重建
- 重建成功（日志：`Recording restarted: VOICE_COMMUNICATION`）
- `AudioRecord.STATE_INITIALIZED == true`，`startRecording()` 不报错
- 但 `read()` 返回的数据仍然全为 0
- **结论：荣耀系统允许初始化 VOICE_COMMUNICATION 源，但对 read() 数据进行了静音处理**

---

## 当前代码实现

### 音频源优先级（降级策略）
```kotlin
private val AUDIO_SOURCES = listOf(
    MediaRecorder.AudioSource.VOICE_COMMUNICATION,  // source id = 7，优先
    MediaRecorder.AudioSource.MIC,                   // source id = 1，降级
    MediaRecorder.AudioSource.VOICE_RECOGNITION      // source id = 6，最后
)
```

### restartAudioRecord 实现
```kotlin
fun restartAudioRecord() {
    if (!isRestarting.compareAndSet(false, true)) return
    Thread {
        try {
            isRecording.set(false)
            recordingThread?.join(2000)
            synchronized(audioRecordLock) {
                audioRecord?.stop()
                audioRecord?.release()
                audioRecord = null
            }
            Thread.sleep(500)
            isRecording.set(true)
            instanceRef?.startAudioRecordingInternal()  // 从 VOICE_COMMUNICATION 开始尝试
            Thread.sleep(2000)  // 冷却期
        } finally {
            isRestarting.set(false)
        }
    }.start()
}
```

### startAudioRecordingInternal
```kotlin
fun startAudioRecordingInternal() {
    for (source in AUDIO_SOURCES) {  // 按顺序尝试每个源
        if (tryStartRecording(source)) {
            startAudioReadingThread()
            return
        }
    }
}
```

### tryStartRecording（关键问题在此）
```kotlin
private fun tryStartRecording(audioSource: Int): Boolean {
    val minBufferSize = AudioRecord.getMinBufferSize(16000, CHANNEL_IN_MONO, ENCODING_PCM_16BIT)
    audioRecord = AudioRecord(audioSource, 16000, CHANNEL_IN_MONO, ENCODING_PCM_16BIT, minBufferSize * 2)
    if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
        audioRecord?.release()
        audioRecord = null
        return false
    }
    audioRecord?.startRecording()
    return true
    // 问题：即使返回 true，read() 出来的数据也可能全为 0
    // 没有任何 API 可以检测这种"静音陷阱"
}
```

---

## 核心问题

**在荣耀/华为设备上，QQ 视频通话接通（AVActivity）后：**

1. 系统允许创建 `VOICE_COMMUNICATION` 源的 AudioRecord 并初始化成功
2. `startRecording()` 不报错，`STATE_INITIALIZED == true`
3. 但 `read()` 返回的数据全为 0，没有任何错误码
4. `MIC` 源（id=1）在这种情况下是否可以录到音？**未测试**
5. 有没有办法检测到"静音陷阱"，自动切换到其他 AudioSource？

---

## 具体问题（请 AI 回答）

### 问题1：QQ 视频通话期间，荣耀设备上哪个 AudioSource 可以录到非零数据？
以下 AudioSource 均未充分测试：
- `MIC` (1)：最可能可用，但是否会被同样静音？
- `VOICE_RECOGNITION` (6)：未测试
- `UNPROCESSED` (9)：未测试
- `CAMCORDER` (5)：未测试

### 问题2：如何检测 AudioRecord 正在被静音（数据全0但无错误）？
- 连续 N 帧全为 0 认为是静音陷阱？（但真实环境也可能有短暂静音）
- 是否有系统 API 可以查询 AudioRecord 的 mute 状态？
- `AudioManager.isMicrophoneMute()` 是否相关？

### 问题3：是否可以用 AudioPlaybackCapture 录制 QQ 播放的音频？
- Android 10+ 支持 `AudioPlaybackCaptureConfiguration`
- 可以录制其他 App 播放的声音
- QQ 是否允许被捕获（`ALLOW_CAPTURE_BY_ALL` 或 `ALLOW_CAPTURE_BY_SYSTEM`）？
- 这个方向是否可行？

### 问题4：setPrivacySensitive 是否有影响？
- 目前没有使用 `setPrivacySensitive(true/false)`
- 这个 API 是否会改变系统对我们录音的处理方式？

### 问题5：是否有荣耀/华为特定的解决方案？
- 荣耀/华为是否有白名单机制，允许特定 App 在通话期间录音？
- 是否需要申请特定系统权限？

---

## 设备信息
- 设备：Honor TNA-AN00
- Android：14（API 34）
- 音频框架：基于 AOSP，荣耀定制
- QQ：最新版视频通话

## 日志证据

### AVActivity 接通前（正常）
```
D/CallDetectionService: Window changed: com.tencent.mobileqq / com.tencent.av.ui.VideoInviteActivity
I/flutter: 🎤 分贝值: -66.0 dB, 音量: 0.0%   ← 正常
I/flutter: 🎤 分贝值: -67.5 dB, 音量: 0.0%   ← 正常
```

### AVActivity 接通后（静音）
```
D/CallDetectionService: Window changed: com.tencent.mobileqq / com.tencent.av.ui.AVActivity
I/CallDetectionService: ✅ Detected QQ call activity: com.tencent.av.ui.AVActivity
I/flutter: 🎤 分贝值: -100.0 dB, 音量: 0.0%  ← 静音
I/flutter: 🎤 分贝值: -100.0 dB, 音量: 0.0%  ← 静音（永远不恢复）
```

### 重建后仍然静音
```
I/flutter: 📊 Audio recording status: Recording restarted: VOICE_COMMUNICATION
I/flutter: 🎤 分贝值: -100.0 dB, 音量: 0.0%  ← 重建后仍然静音
```
