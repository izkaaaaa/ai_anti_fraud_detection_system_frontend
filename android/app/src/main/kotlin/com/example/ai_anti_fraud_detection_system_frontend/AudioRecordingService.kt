package com.example.ai_anti_fraud_detection_system_frontend

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * 音频录制服务
 *
 * 功能：
 * 1. 优先使用 VOICE_RECOGNITION 源录音（QQ 通话期间不会被荣耀系统静音）
 * 2. 实时读取音频数据并通过 Platform Channel 发送给 Flutter
 * 3. 支持 restartAudioRecord()，在 AVActivity 出现时安全重建 AudioRecord
 *
 * 音频源优先级：
 *   VOICE_RECOGNITION (6) > MIC (1)
 *   VOICE_COMMUNICATION (7) 完全不用：QQ 通话期间荣耀系统会对其 read() 静音（-100dB）
 */
class AudioRecordingService : Service() {
    companion object {
        const val CHANNEL_ID = "audio_recording_channel"
        const val NOTIFICATION_ID = 2002

        // 音频配置
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT

        // ✅ 音频源优先级：VOICE_RECOGNITION 优先，避免荣耀设备 QQ 通话期间被静音
        private val AUDIO_SOURCES = listOf(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,  // 优先：QQ 通话期间不被静音
            MediaRecorder.AudioSource.MIC                 // 降级：普通麦克风
            // VOICE_COMMUNICATION 不使用：荣耀设备 QQ 通话期间 read() 返回全零
        )

        // 状态管理
        private var audioRecord: AudioRecord? = null
        private val audioRecordLock = Any()              // ✅ 保护 audioRecord 的锁
        private var isRecording = AtomicBoolean(false)
        private val isRestarting = AtomicBoolean(false)  // ✅ 防止并发 restart
        private var recordingThread: Thread? = null
        private var currentAudioSource = -1

        // ✅ 实例引用，供 restartAudioRecord 调用实例方法
        private var instanceRef: AudioRecordingService? = null

        // 回调接口
        var onAudioDataReceived: ((ByteArray) -> Unit)? = null
        var onStatusChanged: ((String) -> Unit)? = null
        var onError: ((String) -> Unit)? = null

        fun startService(context: Context) {
            val intent = Intent(context, AudioRecordingService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            context.stopService(Intent(context, AudioRecordingService::class.java))
        }

        fun isRecordingActive(): Boolean = isRecording.get()

        fun getCurrentAudioSource(): String {
            return when (currentAudioSource) {
                MediaRecorder.AudioSource.VOICE_COMMUNICATION -> "VOICE_COMMUNICATION"
                MediaRecorder.AudioSource.MIC -> "MIC"
                MediaRecorder.AudioSource.VOICE_RECOGNITION -> "VOICE_RECOGNITION"
                else -> "UNKNOWN"
            }
        }

        /**
         * 安全重建 AudioRecord
         *
         * 在 QQ AVActivity（通话接通）出现时由 CallDetectionService 调用。
         * 荣耀/华为设备进入 AVActivity 后会将 VOICE_COMMUNICATION 源静音，
         * 重建后改用 VOICE_RECOGNITION 可绕过该静音策略。
         *
         * 防护：
         * - isRestarting CAS 保证同一时刻只有一个 restart 在执行
         * - synchronized(audioRecordLock) 保护 audioRecord 对象访问
         * - 2000ms 冷却期防止 AVActivity 连续多次触发
         */
        fun restartAudioRecord() {
            // CAS：若已在重建中，直接返回
            if (!isRestarting.compareAndSet(false, true)) {
                Log.w("AudioRecording", "restartAudioRecord: already restarting, skip")
                return
            }

            Thread {
                try {
                    Log.i("AudioRecording", "🔄 restartAudioRecord: begin")

                    // 1. 停止读取循环
                    isRecording.set(false)
                    recordingThread?.join(2000)
                    recordingThread = null

                    // 2. 释放旧 AudioRecord
                    synchronized(audioRecordLock) {
                        try {
                            audioRecord?.stop()
                        } catch (_: Exception) {}
                        audioRecord?.release()
                        audioRecord = null
                    }

                    // 3. 短暂等待，让系统释放资源
                    Thread.sleep(500)

                    // 4. 重新初始化并启动
                    instanceRef?.startAudioRecordingInternal()
                        ?: Log.e("AudioRecording", "restartAudioRecord: instanceRef is null")

                    Log.i("AudioRecording", "✅ restartAudioRecord: done")

                    // 5. 冷却期（防止 AVActivity 重复触发）
                    Thread.sleep(2000)
                } catch (e: Exception) {
                    Log.e("AudioRecording", "restartAudioRecord error: ${e.message}")
                } finally {
                    isRestarting.set(false)
                }
            }.start()
        }
    }

    override fun onCreate() {
        super.onCreate()
        instanceRef = this
        createNotificationChannel()
        Log.d("AudioRecording", "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        startAudioRecording()
        return START_STICKY
    }

    /**
     * 启动音频录制（首次启动入口，防止重复调用）
     */
    private fun startAudioRecording() {
        if (isRecording.get()) {
            Log.w("AudioRecording", "Recording already started")
            return
        }
        startAudioRecordingInternal()
    }

    /**
     * 内部启动：按优先级尝试每个音频源
     * 供 startAudioRecording() 和 restartAudioRecord() 共用
     */
    fun startAudioRecordingInternal() {
        for (source in AUDIO_SOURCES) {
            if (tryStartRecording(source)) {
                currentAudioSource = source
                isRecording.set(true)

                val sourceName = when (source) {
                    MediaRecorder.AudioSource.VOICE_COMMUNICATION -> "VOICE_COMMUNICATION"
                    MediaRecorder.AudioSource.MIC -> "MIC"
                    MediaRecorder.AudioSource.VOICE_RECOGNITION -> "VOICE_RECOGNITION"
                    else -> "UNKNOWN"
                }

                Log.i("AudioRecording", "✅ Recording started with source: $sourceName")
                onStatusChanged?.invoke("Recording started: $sourceName")
                startAudioReadingThread()
                return
            }
        }

        Log.e("AudioRecording", "❌ Failed to start recording with all audio sources")
        onError?.invoke("Failed to start recording with all audio sources")
    }

    /**
     * 尝试使用指定音频源初始化并启动 AudioRecord
     */
    private fun tryStartRecording(audioSource: Int): Boolean {
        return try {
            val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
            if (minBufferSize == AudioRecord.ERROR || minBufferSize == AudioRecord.ERROR_BAD_VALUE) {
                Log.w("AudioRecording", "Invalid buffer size for source: $audioSource")
                return false
            }

            val bufferSize = minBufferSize * 2  // 双倍缓冲区减少卡顿

            val record = AudioRecord(
                audioSource,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )

            if (record.state != AudioRecord.STATE_INITIALIZED) {
                Log.w("AudioRecording", "AudioRecord not initialized for source: $audioSource")
                record.release()
                return false
            }

            synchronized(audioRecordLock) {
                audioRecord = record
            }

            record.startRecording()
            Log.d("AudioRecording", "AudioRecord started for source: $audioSource")
            true
        } catch (e: Exception) {
            Log.e("AudioRecording", "Failed to start recording with source $audioSource: ${e.message}")
            false
        }
    }

    /**
     * 持续读取音频数据并通过回调发送
     */
    private fun startAudioReadingThread() {
        recordingThread = thread(start = true) {
            try {
                val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
                val buffer = ByteArray(minBufferSize)

                Log.d("AudioRecording", "Audio reading thread started, buffer size: $minBufferSize")

                while (isRecording.get()) {
                    val localRecord = synchronized(audioRecordLock) { audioRecord } ?: break

                    try {
                        val readSize = localRecord.read(buffer, 0, buffer.size)

                        when {
                            readSize > 0 -> {
                                val audioData = buffer.copyOf(readSize)
                                onAudioDataReceived?.invoke(audioData)
                                Log.d("AudioRecording", "Read audio data: $readSize bytes")
                            }
                            readSize == AudioRecord.ERROR_INVALID_OPERATION -> {
                                Log.e("AudioRecording", "AudioRecord error: INVALID_OPERATION")
                                break
                            }
                            readSize == AudioRecord.ERROR_BAD_VALUE -> {
                                Log.e("AudioRecording", "AudioRecord error: BAD_VALUE")
                                break
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("AudioRecording", "Error reading audio: ${e.message}")
                        break
                    }
                }

                Log.d("AudioRecording", "Audio reading thread stopped")
            } catch (e: Exception) {
                Log.e("AudioRecording", "Audio reading thread error: ${e.message}")
            }
        }
    }

    /**
     * 停止音频录制
     */
    private fun stopAudioRecording() {
        if (!isRecording.get()) {
            Log.w("AudioRecording", "Recording not started")
            return
        }

        try {
            isRecording.set(false)

            recordingThread?.join(2000)
            recordingThread = null

            synchronized(audioRecordLock) {
                try { audioRecord?.stop() } catch (_: Exception) {}
                audioRecord?.release()
                audioRecord = null
            }

            Log.i("AudioRecording", "✅ Recording stopped")
            onStatusChanged?.invoke("Recording stopped")
        } catch (e: Exception) {
            Log.e("AudioRecording", "Error stopping recording: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "音频录制服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "用于实时检测的音频录制"
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🎤 音频录制中")
            .setContentText("正在使用 VOICE_RECOGNITION 源录制音频")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        instanceRef = null
        stopAudioRecording()
        // 清空静态状态，防止下次 startService 时残留
        currentAudioSource = -1
        Log.d("AudioRecording", "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
