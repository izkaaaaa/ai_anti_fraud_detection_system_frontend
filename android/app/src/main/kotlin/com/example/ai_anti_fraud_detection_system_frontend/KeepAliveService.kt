package com.example.ai_anti_fraud_detection_system_frontend

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * 保活服务 - 确保应用在后台持续运行
 * 
 * 功能：
 * 1. 创建前台通知，提高进程优先级
 * 2. 监听音频模式变化，检测通话状态
 * 3. 定期检查无障碍服务状态
 * 4. 华为系统特殊处理（启动1像素Activity）
 * 
 * 保活策略：
 * - 前台服务 + 通知
 * - 1像素Activity（华为系统）
 * - 定期检查和重启
 */
class KeepAliveService : Service() {
    companion object {
        private const val TAG = "KeepAliveService"
        private const val NOTIFICATION_ID = 2003
        private const val CHANNEL_ID = "keep_alive_channel"
    }
    
    private var audioManager: AudioManager? = null
    private var executor = Executors.newSingleThreadScheduledExecutor()
    private var lastAudioMode = -1
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        
        // 创建前台通知
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // 启动音频模式监听
        startAudioModeMonitoring()
        
        // 华为系统特殊处理
        handleHuaweiDevice()
        
        return START_STICKY
    }
    
    /**
     * 启动音频模式监听
     * 
     * 监听 AudioManager 的模式变化：
     * - MODE_IN_CALL: 通话中
     * - MODE_IN_COMMUNICATION: 通信中
     * - MODE_NORMAL: 正常模式
     */
    private fun startAudioModeMonitoring() {
        executor.scheduleAtFixedRate({
            try {
                val currentMode = audioManager?.mode ?: return@scheduleAtFixedRate
                
                if (currentMode != lastAudioMode) {
                    lastAudioMode = currentMode
                    
                    val modeName = when (currentMode) {
                        AudioManager.MODE_IN_CALL -> "MODE_IN_CALL"
                        AudioManager.MODE_IN_COMMUNICATION -> "MODE_IN_COMMUNICATION"
                        AudioManager.MODE_NORMAL -> "MODE_NORMAL"
                        else -> "UNKNOWN"
                    }
                    
                    Log.d(TAG, "Audio mode changed: $modeName")
                    
                    // 如果进入通话模式，确保录音已启动
                    if (currentMode == AudioManager.MODE_IN_CALL || 
                        currentMode == AudioManager.MODE_IN_COMMUNICATION) {
                        ensureRecordingStarted()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error monitoring audio mode: ${e.message}")
            }
        }, 0, 1, TimeUnit.SECONDS)
    }
    
    /**
     * 确保录音已启动
     * 
     * 荣耀/华为设备必须走完整时序：先1像素Activity保活，再延迟启动录音。
     * 直接调用 startService 会被系统识别为后台录音并静音。
     * 非荣耀设备直接启动录音即可。
     */
    private fun ensureRecordingStarted() {
        if (!AudioRecordingService.isRecordingActive()) {
            Log.d(TAG, "Recording not active, starting via CallDetectionService timing...")
            val brand = Build.BRAND.lowercase()
            if (brand == "huawei" || brand == "honor") {
                // 荣耀/华为：委托给 CallDetectionService 的 startRecordingWithDelay 走完整时序
                // 此处只做保活，录音由 CallDetectionService 负责
                Log.d(TAG, "Honor/Huawei: skipping direct start, recording managed by CallDetectionService")
            } else {
                AudioRecordingService.startService(this)
            }
        }
    }
    
    /**
     * 华为系统特殊处理
     * 
     * 仅在正在录音时才启动1像素Activity，避免非通话时无意义启动。
     */
    private fun handleHuaweiDevice() {
        val brand = Build.BRAND.lowercase()
        if (brand == "huawei" || brand == "honor") {
            Log.d(TAG, "Huawei/Honor device detected")
            // 不在此处主动启动1像素Activity，由 CallDetectionService 负责保活时序
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "通话检测保活服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "保持应用在后台运行以进行通话检测"
                setSound(null, null)  // 无声
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🔍 通话检测中")
            .setContentText("正在监听通话，自动进行诈骗识别")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
        
        executor.shutdown()
        try {
            if (!executor.awaitTermination(2, TimeUnit.SECONDS)) {
                executor.shutdownNow()
            }
        } catch (e: InterruptedException) {
            executor.shutdownNow()
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
}

