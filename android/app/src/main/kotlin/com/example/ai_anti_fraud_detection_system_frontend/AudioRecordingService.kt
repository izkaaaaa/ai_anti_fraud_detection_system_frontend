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
import java.io.ByteArrayOutputStream
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * 音频录制服务
 * 
 * 功能：
 * 1. 使用 VOICE_COMMUNICATION 音频源（与微信等通话应用共享麦克风）
 * 2. 支持 setPrivacySensitive(true) 以实现优先级对齐（Android 11+）
 * 3. 实时读取音频数据并通过 Platform Channel 发送给 Flutter
 * 4. 支持智能降级（VOICE_COMMUNICATION → MIC → VOICE_RECOGNITION）
 */
class AudioRecordingService : Service() {
    companion object {
        const val CHANNEL_ID = "audio_recording_channel"
        const val NOTIFICATION_ID = 2002
        
        // 音频配置
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        
        // 音频源优先级
        // VOICE_RECOGNITION（6）在荣耀/华为设备 QQ 视频通话（AVActivity）期间可以正常录音
        // VOICE_COMMUNICATION（7）在 AVActivity 接通后会被系统静音（全 0 数据），即使重建也无效
        private val AUDIO_SOURCES = listOf(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,     // 优先：语音识别源，通话期间可录音
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,  // 备用：与通话应用共享
            MediaRecorder.AudioSource.MIC                    // 最后：普通麦克风
        )
        
        // 状态管理
        @Volatile private var audioRecord: AudioRecord? = null
        private var isRecording = AtomicBoolean(false)
        @Volatile private var recordingThread: Thread? = null
        private var currentAudioSource = -1
        // audioRecord 操作锁，防止并发 stop/release 与 read
        private val audioRecordLock = Any()
        
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

        /**
         * 重建 AudioRecord（不停止 Service，Flutter 端无感知）
         * 用于荣耀设备通话接通时系统撤销权限后重新获取麦克风
         */
        // 防抖标志：restart 期间忽略重复调用
        private var isRestarting = AtomicBoolean(false)

        fun restartAudioRecord() {
            // 防止重复调用（包含冷却期）
            if (!isRestarting.compareAndSet(false, true)) {
                Log.w("AudioRecording", "[restartAudioRecord] 已在重建中或冷却期，跳过")
                return
            }
            // 必须在子线程执行：join() 和 sleep() 不能在主线程调用
            Thread {
                try {
                    Log.i("AudioRecording", "[restartAudioRecord] 重建 AudioRecord...")
                    // 停止旧的读取循环
                    isRecording.set(false)
                    recordingThread?.join(2000)
                    recordingThread = null
                    // 加锁保护 audioRecord 的 stop/release，避免与读取线程并发
                    synchronized(audioRecordLock) {
                        try { audioRecord?.stop() } catch (_: Exception) {}
                        try { audioRecord?.release() } catch (_: Exception) {}
                        audioRecord = null
                    }
                    Thread.sleep(500)
                    // 重新初始化
                    isRecording.set(true)
                    instanceRef?.startAudioRecordingInternal()
                    // 冷却期：重建完成后再等 2 秒才允许下一次 restart
                    Thread.sleep(2000)
                } catch (e: Exception) {
                    Log.e("AudioRecording", "restartAudioRecord failed: ${e.message}")
                } finally {
                    isRestarting.set(false)
                }
            }.start()
        }

        // Service 实例引用，供 restartAudioRecord 调用
        var instanceRef: AudioRecordingService? = null

        fun getCurrentAudioSource(): String {
            return when (currentAudioSource) {
                MediaRecorder.AudioSource.VOICE_COMMUNICATION -> "VOICE_COMMUNICATION"
                MediaRecorder.AudioSource.MIC -> "MIC"
                MediaRecorder.AudioSource.VOICE_RECOGNITION -> "VOICE_RECOGNITION"
                else -> "UNKNOWN"
            }
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
        
        // 启动音频录制
        startAudioRecording()
        
        return START_STICKY
    }
    
    /**
     * 供 restartAudioRecord 调用的内部重启方法（不检查 isRecording 标志）
     */
    fun startAudioRecordingInternal() {
        for (source in AUDIO_SOURCES) {
            if (tryStartRecording(source)) {
                currentAudioSource = source
                val sourceName = when (source) {
                    MediaRecorder.AudioSource.VOICE_COMMUNICATION -> "VOICE_COMMUNICATION"
                    MediaRecorder.AudioSource.MIC -> "MIC"
                    MediaRecorder.AudioSource.VOICE_RECOGNITION -> "VOICE_RECOGNITION"
                    else -> "UNKNOWN"
                }
                Log.i("AudioRecording", "✅ [restart] Recording restarted with source: $sourceName")
                onStatusChanged?.invoke("Recording restarted: $sourceName")
                startAudioReadingThread()
                return
            }
        }
        Log.e("AudioRecording", "❌ [restart] Failed to restart recording")
        onError?.invoke("Failed to restart recording")
    }

    /**
     * 启动音频录制
     * 
     * 策略：
     * 1. 优先尝试 VOICE_COMMUNICATION（与微信等通话应用共享）
     * 2. 如果失败，降级到 MIC
     * 3. 如果仍失败，降级到 VOICE_RECOGNITION
     */
    private fun startAudioRecording() {
        if (isRecording.get()) {
            Log.w("AudioRecording", "Recording already started")
            return
        }
        
        // 尝试每个音频源
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
                
                // 启动音频读取线程
                startAudioReadingThread()
                return
            }
        }
        
        // 所有音频源都失败
        Log.e("AudioRecording", "❌ Failed to start recording with all audio sources")
        onError?.invoke("Failed to start recording with all audio sources")
    }
    
    /**
     * 尝试使用指定的音频源启动录制
     */
    private fun tryStartRecording(audioSource: Int): Boolean {
        return try {
            val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
            if (minBufferSize == AudioRecord.ERROR || minBufferSize == AudioRecord.ERROR_BAD_VALUE) {
                Log.w("AudioRecording", "Invalid buffer size for source: $audioSource")
                return false
            }
            
            val bufferSize = minBufferSize * 2  // 双倍缓冲区减少卡顿
            
            // 构建 AudioRecord
            // 所有 Android 版本统一使用基础构造方式，不设置 setPrivacySensitive
            // 原因：setPrivacySensitive(true) 会触发系统隐私静音保护，导致录到静音数据
            audioRecord = AudioRecord(
                audioSource,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )
            
            // 检查初始化状态
            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.w("AudioRecording", "AudioRecord not initialized for source: $audioSource")
                audioRecord?.release()
                audioRecord = null
                return false
            }
            
            // 启动录制
            audioRecord?.startRecording()
            Log.d("AudioRecording", "AudioRecord started for source: $audioSource")
            true
        } catch (e: Exception) {
            Log.e("AudioRecording", "Failed to start recording with source $audioSource: ${e.message}")
            audioRecord?.release()
            audioRecord = null
            false
        }
    }
    
    /**
     * 启动音频读取线程
     * 
     * 持续读取音频数据并通过回调发送
     */
    private fun startAudioReadingThread() {
        recordingThread = thread(start = true) {
            try {
                val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
                val buffer = ByteArray(minBufferSize)
                
                Log.d("AudioRecording", "Audio reading thread started, buffer size: $minBufferSize")
                
                while (isRecording.get() && audioRecord != null) {
                    try {
                        val readSize: Int
                        synchronized(audioRecordLock) {
                            val ar = audioRecord
                            readSize = if (ar != null && isRecording.get()) {
                                ar.read(buffer, 0, buffer.size)
                            } else {
                                -1
                            }
                        }
                        
                        if (readSize > 0) {
                            // 发送音频数据
                            val audioData = buffer.copyOf(readSize)
                            onAudioDataReceived?.invoke(audioData)
                            
                            Log.d("AudioRecording", "Read audio data: $readSize bytes")
                        } else if (readSize == AudioRecord.ERROR_INVALID_OPERATION) {
                            Log.e("AudioRecording", "AudioRecord error: INVALID_OPERATION")
                            break
                        } else if (readSize == AudioRecord.ERROR_BAD_VALUE) {
                            Log.e("AudioRecording", "AudioRecord error: BAD_VALUE")
                            break
                        } else if (readSize == -1) {
                            // audioRecord 已被释放，退出循环
                            break
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
            
            // 等待读取线程结束
            recordingThread?.join(2000)
            recordingThread = null
            
            // 停止并释放 AudioRecord（加锁防止与读取线程并发）
            synchronized(audioRecordLock) {
                try { audioRecord?.stop() } catch (_: Exception) {}
                try { audioRecord?.release() } catch (_: Exception) {}
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
            .setContentText("正在使用 VOICE_COMMUNICATION 源进行录制")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instanceRef = null
        stopAudioRecording()
        // ✅ Service 销毁时清空静态状态，避免下次 startService 时 isRecording 残留为 true
        audioRecord = null
        recordingThread = null
        currentAudioSource = -1
        Log.d("AudioRecording", "Service destroyed")
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
}

