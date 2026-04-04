package com.example.ai_anti_fraud_detection_system_frontend

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SCREEN_CAPTURE_CHANNEL = "com.example.ai_anti_fraud_detection_system_frontend/screen_capture"
    private val AUDIO_RECORDING_CHANNEL = "com.example.ai_anti_fraud_detection_system_frontend/audio_recording"
    private val CALL_DETECTION_CHANNEL = "com.example.ai_anti_fraud_detection_system_frontend/call_detection"
    private val FLOATING_WINDOW_CHANNEL = "com.example.ai_anti_fraud_detection_system_frontend/floating_window"
    private val REQUEST_MEDIA_PROJECTION = 1001

    private var pendingResult: MethodChannel.Result? = null
    private var audioRecordingMethodChannel: MethodChannel? = null
    private var callDetectionMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 屏幕截图 Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CAPTURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCapture" -> {
                    startMediaProjection(result)
                }
                "captureScreen" -> {
                    captureScreen(result)
                }
                "stopCapture" -> {
                    stopCapture()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 音频录制 Channel
        audioRecordingMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_RECORDING_CHANNEL)
        audioRecordingMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    startAudioRecording(result)
                }
                "stopRecording" -> {
                    stopAudioRecording(result)
                }
                "isRecording" -> {
                    result.success(AudioRecordingService.isRecordingActive())
                }
                "getCurrentAudioSource" -> {
                    result.success(AudioRecordingService.getCurrentAudioSource())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 通话检测 Channel
        callDetectionMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_DETECTION_CHANNEL)
        callDetectionMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startAccessibilityService" -> {
                    startAccessibilityService(result)
                }
                "stopAccessibilityService" -> {
                    stopAccessibilityService(result)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 设置音频录制回调
        setupAudioRecordingCallbacks()
        
        // 设置通话检测回调
        setupCallDetectionCallbacks()

        // 悬浮窗 Channel（完全独立，不影响录音逻辑）
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLOATING_WINDOW_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> {
                        val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this) else true
                        result.success(ok)
                    }
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                            )
                        }
                        result.success(null)
                    }
                    "show" -> {
                        try {
                            FloatingWindowService.start(this)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SHOW_FAILED", e.message, null)
                        }
                    }
                    "hide" -> {
                        try {
                            FloatingWindowService.stop(this)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("HIDE_FAILED", e.message, null)
                        }
                    }
                    "updateRiskLevel" -> {
                        try {
                            val level = call.argument<String>("risk_level") ?: "safe"
                            val conf  = call.argument<Double>("confidence") ?: 0.0
                            FloatingWindowService.updateRiskLevel(level, conf)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UPDATE_FAILED", e.message, null)
                        }
                    }
                    "updateScene" -> {
                        // 场景变化时更新悬浮窗
                        try {
                            val scene = call.argument<String>("scene") ?: "未知环境"
                            FloatingWindowService.updateScene(scene)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UPDATE_SCENE_FAILED", e.message, null)
                        }
                    }
                    "showAlertNotification" -> {
                        // medium→系统通知，high→全屏遮罩
                        try {
                            val level   = call.argument<String>("level") ?: "medium"
                            val title   = call.argument<String>("title") ?: "风险提醒"
                            val message = call.argument<String>("message") ?: ""
                            FloatingWindowService.showAlert(this, level, title, message)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ALERT_FAILED", e.message, null)
                        }
                    }
                    "dismissFullScreenWarning" -> {
                        try {
                            FloatingWindowService.dismissFullScreenWarning()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("DISMISS_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    private fun startMediaProjection(result: MethodChannel.Result) {
        if (ScreenCaptureService.isCapturing) {
            result.success(true)
            return
        }
        
        pendingResult = result
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_MEDIA_PROJECTION)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // 启动前台服务来运行 MediaProjection
                ScreenCaptureService.startService(this, resultCode, data)
                pendingResult?.success(true)
            } else {
                pendingResult?.error("PERMISSION_DENIED", "User denied screen capture permission", null)
            }
            pendingResult = null
        }
    }
    
    private fun captureScreen(result: MethodChannel.Result) {
        if (!ScreenCaptureService.isCapturing) {
            result.error("NOT_STARTED", "Screen capture not started", null)
            return
        }
        
        // ✅ 直接从静态 imageReader 获取截图
        val jpegData = ScreenCaptureService.captureScreenStatic()
        
        if (jpegData != null) {
            result.success(jpegData)
        } else {
            result.error("NO_IMAGE", "No image available", null)
        }
    }
    
    private fun stopCapture() {
        ScreenCaptureService.stopService(this)
    }

    private fun startAudioRecording(result: MethodChannel.Result) {
        try {
            AudioRecordingService.startService(this)
            result.success(true)
        } catch (e: Exception) {
            result.error("START_FAILED", "Failed to start audio recording: ${e.message}", null)
        }
    }
    
    private fun stopAudioRecording(result: MethodChannel.Result) {
        try {
            AudioRecordingService.stopService(this)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_FAILED", "Failed to stop audio recording: ${e.message}", null)
        }
    }
    
    private fun setupAudioRecordingCallbacks() {
        // 音频数据回调（必须在主线程执行 Platform Channel 调用）
        AudioRecordingService.onAudioDataReceived = { audioData ->
            try {
                val base64Audio = Base64.encodeToString(audioData, Base64.NO_WRAP)
                // ✅ 在主线程执行 Platform Channel 调用
                runOnUiThread {
                    audioRecordingMethodChannel?.invokeMethod("onAudioData", mapOf(
                        "data" to base64Audio,
                        "size" to audioData.size
                    ))
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error sending audio data: ${e.message}")
            }
        }
        
        // 状态变化回调（必须在主线程执行）
        AudioRecordingService.onStatusChanged = { status ->
            runOnUiThread {
                audioRecordingMethodChannel?.invokeMethod("onStatusChanged", mapOf(
                    "status" to status
                ))
            }
        }
        
        // 错误回调（必须在主线程执行）
        AudioRecordingService.onError = { error ->
            runOnUiThread {
                audioRecordingMethodChannel?.invokeMethod("onError", mapOf(
                    "error" to error
                ))
            }
        }
    }
    
    private fun setupCallDetectionCallbacks() {
        // 通话检测回调
        CallDetectionService.onCallDetected = { appName, callerName ->
            runOnUiThread {
                callDetectionMethodChannel?.invokeMethod("onCallDetected", mapOf(
                    "app" to appName,
                    "caller" to callerName
                ))
            }
        }
        
        // 通话结束回调
        CallDetectionService.onCallEnded = {
            runOnUiThread {
                callDetectionMethodChannel?.invokeMethod("onCallEnded", null)
            }
        }
        
        // 状态变化回调
        CallDetectionService.onStatusChanged = { status ->
            runOnUiThread {
                callDetectionMethodChannel?.invokeMethod("onStatusChanged", mapOf(
                    "status" to status
                ))
            }
        }
    }
    
    private fun startAccessibilityService(result: MethodChannel.Result) {
        try {
            openAccessibilitySettings()
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to open accessibility settings: ${e.message}", null)
        }
    }
    
    private fun stopAccessibilityService(result: MethodChannel.Result) {
        // 用户需要手动在系统设置中关闭无障碍服务
        result.success(true)
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        return try {
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: ""
            
            Log.d("MainActivity", "Enabled services: $enabledServices")
            
            // 检查多种可能的格式
            val packageName = "com.example.ai_anti_fraud_detection_system_frontend"
            val serviceNames = listOf(
                "$packageName/.CallDetectionService",
                "$packageName/com.example.ai_anti_fraud_detection_system_frontend.CallDetectionService",
                "com.example.ai_anti_fraud_detection_system_frontend.CallDetectionService"
            )
            
            val isEnabled = serviceNames.any { enabledServices.contains(it) }
            Log.d("MainActivity", "Accessibility service enabled: $isEnabled")
            
            isEnabled
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking accessibility service: ${e.message}")
            false
        }
    }
    
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopCapture()
        AudioRecordingService.stopService(this)
    }
}
