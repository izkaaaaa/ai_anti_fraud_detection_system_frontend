package com.example.ai_anti_fraud_detection_system_frontend

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SCREEN_CAPTURE_CHANNEL = "com.example.ai_anti_fraud_detection_system_frontend/screen_capture"
    private val AUDIO_RECORDING_CHANNEL = "com.example.ai_anti_fraud_detection_system_frontend/audio_recording"
    private val REQUEST_MEDIA_PROJECTION = 1001
    
    private var pendingResult: MethodChannel.Result? = null
    private var audioRecordingMethodChannel: MethodChannel? = null
    
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
                "getRecentScreenshots" -> {
                    getRecentScreenshots(result)
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
        
        // 设置音频录制回调
        setupAudioRecordingCallbacks()
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
    
    private fun getRecentScreenshots(result: MethodChannel.Result) {
        val screenshots = ScreenCaptureService.getRecentScreenshots()
        result.success(screenshots)
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
                android.util.Log.e("MainActivity", "Error sending audio data: ${e.message}")
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
    
    override fun onDestroy() {
        super.onDestroy()
        stopCapture()
        AudioRecordingService.stopService(this)
    }
}
