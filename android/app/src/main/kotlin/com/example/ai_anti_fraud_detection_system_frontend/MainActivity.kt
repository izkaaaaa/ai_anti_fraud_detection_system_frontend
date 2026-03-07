package com.example.ai_anti_fraud_detection_system_frontend

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ai_anti_fraud_detection_system_frontend/screen_capture"
    private val REQUEST_MEDIA_PROJECTION = 1001
    
    private var pendingResult: MethodChannel.Result? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
    
    override fun onDestroy() {
        super.onDestroy()
        stopCapture()
    }
}
