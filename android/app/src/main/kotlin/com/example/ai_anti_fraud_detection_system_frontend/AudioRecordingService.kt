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
 * 1. 使用 MIC 音频源直接采集麦克风（通话时需开启外放）
 * 2. 实时读取音频数据并通过 Platform Channel 发送给 Flutter
 * 3. 不使用 setPrivacySensitive，避免通话时被系统静音
 */
class AudioRecordingService : Service() {
    companion object {
        const val CHANNEL_ID = "audio_recording_channel"
        const val NOTIFICATION_ID = 2002
        
        // 音频配置
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        
        // 音频源：直接使用 MIC，通话时需开启外放
        private val AUDIO_SOURCES = listOf(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,    // 优先：QQ通话期间不被荣耀系统静音（source id=6）
            MediaRecorder.AudioSource.MIC,                   // 降级：普通麦克风
            MediaRecorder.AudioSource.VOICE_COMMUNICATION    // 最后：QQ通话期间荣耀设备会被静音，慎用
        )
        
        // 状态管理
        private var audioRecord: AudioRecord? = null
        private var isRecording = AtomicBoolean(false)
        private var recordingThread: Thread? = null
        private var currentAudioSource = -1
        
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
         * 重建 AudioRecord（通话接通后 QQ 抢占音频焦点场景使用）
         * 停止当前录制后延迟 300ms 重新启动，让系统音频焦点切换完成。
         */
        fun restartAudioRecord() {
            if (!isRecording.get()) return
            isRecording.set(false)
            try {
                recordingThread?.join(1000)
            } catch (_: InterruptedException) {}
            recordingThread = null
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                // 重新尝试每个音频源
                for (source in AUDIO_SOURCES) {
                    val minBuf = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
                    if (minBuf <= 0) continue
                    try {
                        val ar = AudioRecord(source, SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, minBuf * 2)
                        if (ar.state != AudioRecord.STATE_INITIALIZED) { ar.release(); continue }
                        ar.startRecording()
                        audioRecord = ar
                        currentAudioSource = source
                        isRecording.set(true)
                        android.util.Log.i("AudioRecording", "✅ restartAudioRecord: source=$source")
                        onStatusChanged?.invoke("Recording restarted: $source")
                        // 重新启动读取线程（通过发送 Intent 让 Service 自己重启线程较复杂，直接在此启动）
                        _startReadThreadStatic()
                        break
                    } catch (e: Exception) {
                        android.util.Log.e("AudioRecording", "restartAudioRecord failed for $source: ${e.message}")
                    }
                }
            }, 300)
        }

        /** 供 restartAudioRecord 内部使用的读取线程启动（静态上下文版本）*/
        private fun _startReadThreadStatic() {
            recordingThread = kotlin.concurrent.thread(start = true) {
                try {
                    val minBuf = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
                    val buffer = ByteArray(if (minBuf > 0) minBuf else 2560)
                    while (isRecording.get() && audioRecord != null) {
                        val read = audioRecord!!.read(buffer, 0, buffer.size)
                        if (read > 0) onAudioDataReceived?.invoke(buffer.copyOf(read))
                        else if (read < 0) break
                    }
                } catch (e: Exception) {
                    android.util.Log.e("AudioRecording", "_startReadThreadStatic error: ${e.message}")
                }
            }
        }
        
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
     * 启动音频录制
     * 
     * 策略：
     * 1. 优先使用 MIC（通话时需开启外放，通过麦克风采集对方声音）
     * 2. 如果失败，降级到 VOICE_RECOGNITION
     *
     * 注意：不使用 VOICE_COMMUNICATION，该源在通话时会被 QQ/微信抢占，
     * 且 setPrivacySensitive 会触发系统静音保护，导致读到全零数据（-100dB）
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
                        val readSize = audioRecord!!.read(buffer, 0, buffer.size)
                        
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
            
            // 停止并释放 AudioRecord
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
            
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
            .setContentText("正在使用 MIC 源进行录制（请开启外放）")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopAudioRecording()
        // ✅ Service 销毁时清空静态状态，避免下次 startService 时 isRecording 残留为 true
        audioRecord = null
        recordingThread = null
        currentAudioSource = -1
        Log.d("AudioRecording", "Service destroyed")
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
}

