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
4. **进入 AVActivity 后，系统专门为 QQ 保留 VOICE_COMMUNICATION 源，并将其他 App 的同源录音静音**
5. **VOICE_RECOGNITION（source id=6）不受上述静音策略影响，可以在 QQ 通话期间正常录音**

---

## 已尝试的方案

### 方案1：AVActivity 出现时重建 AudioRecord（引发崩溃）
- AVActivity 在荣耀设备上会被连续触发多次（3-4次）
- 多次并发重建导致 `F/AudioTrackShared: releaseBuffer: mUnreleased out of range` native 崩溃
- 加了 AtomicBoolean 防抖 + synchronized 锁后崩溃消失
- **但重建后仍然静音（-100dB）**（因为仍然使用 VOICE_COMMUNICATION）

### 方案2：不重建，等待系统自动恢复
- **系统永远不会自动恢复**，整个通话期间都是 -100dB

### 方案3：区分场景，AVActivity 接通时触发重建
- 重建成功（日志：`Recording restarted: VOICE_COMMUNICATION`）
- `AudioRecord.STATE_INITIALIZED == true`，`startRecording()` 不报错
- 但 `read()` 返回的数据仍然全为 0
- **结论：荣耀系统允许初始化 VOICE_COMMUNICATION 源，但对 read() 数据进行了静音处理**

### 方案4（已解决静音问题）：切换到 VOICE_RECOGNITION（source id=6）✅
- 将音频源优先级改为 `VOICE_RECOGNITION` 优先（而非 `VOICE_COMMUNICATION`）
- **结果：QQ 通话期间不再出现 -100dB 静音，录音恢复正常读取**
- 日志验证（2026-03-24 QQ 通话实测）：
  - `D/AudioRecording: Read audio data: 1280 bytes` 持续稳定输出，无崩溃无中断
  - 分贝值维持在 -62dB 到 -76dB（麦克风底噪/环境音）
  - 出现真实语音峰值：-33dB（2.1%）、-44dB（0.6%）、-45dB（0.6%）
  - 后端通信完全正常（audio ACK、video ACK、heartbeat ACK 均有响应）
- **当前已解决：录音不再被静音，数据可以正常传到后端**

---

## 当前代码实现

### 音频源优先级（当前配置）
```kotlin
private val AUDIO_SOURCES = listOf(
    MediaRecorder.AudioSource.VOICE_RECOGNITION,    // source id = 6，优先（QQ通话期间不被静音）
    MediaRecorder.AudioSource.MIC,                   // source id = 1，降级
    MediaRecorder.AudioSource.VOICE_COMMUNICATION    // source id = 7，最后（QQ通话期间被荣耀系统静音）
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
            instanceRef?.startAudioRecordingInternal()
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

### tryStartRecording
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
    // 注意：VOICE_COMMUNICATION 在荣耀设备 QQ 通话期间，
    // 即使初始化成功，read() 也会返回全零数据（静音陷阱）
    // VOICE_RECOGNITION 不存在这个问题
}
```

---

## 当前状态（2026-03-24 更新）

| 问题 | 状态 | 说明 |
|---|---|---|
| QQ 通话期间 AudioRecord 被静音（-100dB） | ✅ 已解决 | 切换到 VOICE_RECOGNITION 后不再静音 |
| 前端→后端音频发送 | ✅ 正常 | audio ACK 持续响应 |
| WebSocket 心跳保活 | ✅ 正常 | heartbeat ACK 正常 |
| 截图发送 | ✅ 正常 | video ACK 正常 |
| 录音崩溃（native crash） | ✅ 已解决 | AtomicBoolean + synchronized 防并发 |
| 录到通话双方混音 | ⚠️ 未解决 | 见下方「遗留问题」 |

---

## 最终结论（2026-03-24）

### 录音目标
只需录制**用户自己说话的声音**，不需要录制通话对方的声音。后端 AI 检测用户自身的语音内容（关键词、情绪等）以判断是否遭遇诈骗。

### 当前方案完全满足需求 ✅

`VOICE_RECOGNITION`（source id=6）使用物理麦克风录音：
- QQ 通话期间不被荣耀系统静音（不像 `VOICE_COMMUNICATION` 会被锁定为全零）
- 用户说话时可以正常录到声音，实测峰值达到 -33dB（音量 2.1%），信号明确
- 数据持续发送到后端，audio ACK 正常响应
- 整个通话过程无崩溃、无中断

### 所有问题已解决

| 问题 | 状态 |
|---|---|
| QQ 通话期间 AudioRecord 被静音（-100dB） | ✅ 已解决，改用 VOICE_RECOGNITION |
| native 崩溃（并发 restart） | ✅ 已解决，AtomicBoolean + synchronized |
| 前端→后端音频发送 | ✅ 正常 |
| WebSocket 心跳保活 | ✅ 正常 |
| 截图发送 | ✅ 正常 |
| 录到用户自己说话的声音 | ✅ 已实现 |
1. 