package com.example.ai_anti_fraud_detection_system_frontend

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * 无障碍服务 - 自动检测通话
 * 
 * 功能：
 * 1. 监听应用切换事件（TYPE_WINDOW_STATE_CHANGED）
 * 2. 识别 QQ/微信 视频通话
 * 3. 自动触发录音
 * 4. 监听通话邀请文本
 * 
 * 权限：
 * - BIND_ACCESSIBILITY_SERVICE
 * - 需要用户在系统设置中手动启用
 */
class CallDetectionService : AccessibilityService() {
    companion object {
        private const val TAG = "CallDetectionService"
        
        // 通话应用包名
        private const val QQ_PACKAGE = "com.tencent.mobileqq"
        private const val WECHAT_PACKAGE = "com.tencent.mm"
        
        // 通话应用类名（可能的值）
        private val QQ_CALL_ACTIVITIES = listOf(
            "com.tencent.mobileqq.activity.VideoCallActivity",
            "com.tencent.mobileqq.activity.CallActivity",
            "com.tencent.mobileqq.video.VideoActivity",
            "com.tencent.mobileqq.call.CallActivity"
        )
        
        private val WECHAT_CALL_ACTIVITIES = listOf(
            "com.tencent.mm.plugin.voip.ui.VideoActivity",
            "com.tencent.mm.plugin.voip.ui.VoipActivity",
            "com.tencent.mm.ui.voip.VideoCallActivity"
        )
        
        // 状态回调
        var onCallDetected: ((String, String) -> Unit)? = null  // (appName, callerName)
        var onCallEnded: (() -> Unit)? = null
        var onStatusChanged: ((String) -> Unit)? = null
        
        private var isInCall = false
        private var currentCaller = ""
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        try {
            when (event.eventType) {
                // 监听应用切换
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                    handleWindowStateChanged(event)
                }
                
                // 监听文本变化（用于提取通话对方名称）
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                    handleWindowContentChanged(event)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling accessibility event: ${e.message}")
        }
    }
    
    /**
     * 处理应用切换事件
     */
    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: return
        
        Log.d(TAG, "Window changed: $packageName / $className")
        
        // 检测 QQ 视频通话
        if (packageName == QQ_PACKAGE && isQQCallActivity(className)) {
            Log.i(TAG, "✅ Detected QQ video call")
            onStatusChanged?.invoke("检测到 QQ 视频通话")
            
            if (!isInCall) {
                isInCall = true
                currentCaller = "QQ 通话"
                startRecording()
                onCallDetected?.invoke("QQ", currentCaller)
            }
            return
        }
        
        // 检测微信视频通话
        if (packageName == WECHAT_PACKAGE && isWeChatCallActivity(className)) {
            Log.i(TAG, "✅ Detected WeChat video call")
            onStatusChanged?.invoke("检测到微信视频通话")
            
            if (!isInCall) {
                isInCall = true
                currentCaller = "微信通话"
                startRecording()
                onCallDetected?.invoke("WeChat", currentCaller)
            }
            return
        }
        
        // 如果切换到其他应用，可能通话已结束
        if (isInCall && packageName != QQ_PACKAGE && packageName != WECHAT_PACKAGE) {
            Log.i(TAG, "✅ Call ended (switched to other app)")
            onStatusChanged?.invoke("通话已结束")
            
            isInCall = false
            currentCaller = ""
            stopRecording()
            onCallEnded?.invoke()
        }
    }
    
    /**
     * 处理窗口内容变化（提取通话对方名称）
     */
    private fun handleWindowContentChanged(event: AccessibilityEvent) {
        val text = event.text
        if (text == null || text.isEmpty()) return
        
        val content = text.joinToString(" ")
        
        // 检测通话邀请文本
        if (content.contains("邀请你语音通话") || 
            content.contains("邀请你视频通话") ||
            content.contains("正在通话中")) {
            
            Log.d(TAG, "Call text detected: $content")
            
            // 尝试提取对方名称
            val caller = extractCallerName(content)
            if (caller.isNotEmpty() && caller != currentCaller) {
                currentCaller = caller
                Log.i(TAG, "Caller name: $caller")
                onStatusChanged?.invoke("通话对方: $caller")
            }
        }
    }
    
    /**
     * 从文本中提取通话对方名称
     */
    private fun extractCallerName(text: String): String {
        // 匹配 "xxx邀请你" 的模式
        val pattern = "(.+?)邀请你".toRegex()
        val match = pattern.find(text)
        if (match != null) {
            return match.groupValues[1]
        }
        
        // 匹配 "与xxx通话中" 的模式
        val pattern2 = "与(.+?)通话中".toRegex()
        val match2 = pattern2.find(text)
        if (match2 != null) {
            return match2.groupValues[1]
        }
        
        return ""
    }
    
    /**
     * 检查是否是 QQ 通话界面
     */
    private fun isQQCallActivity(className: String): Boolean {
        return QQ_CALL_ACTIVITIES.any { className.contains(it) || it.contains(className) }
    }
    
    /**
     * 检查是否是微信通话界面
     */
    private fun isWeChatCallActivity(className: String): Boolean {
        return WECHAT_CALL_ACTIVITIES.any { className.contains(it) || it.contains(className) }
    }
    
    /**
     * 启动录音
     */
    private fun startRecording() {
        try {
            Log.d(TAG, "Starting audio recording...")
            AudioRecordingService.startService(this)
            
            // 同时启动保活服务
            startKeepAliveService()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting recording: ${e.message}")
        }
    }
    
    /**
     * 停止录音
     */
    private fun stopRecording() {
        try {
            Log.d(TAG, "Stopping audio recording...")
            AudioRecordingService.stopService(this)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording: ${e.message}")
        }
    }
    
    /**
     * 启动保活服务
     */
    private fun startKeepAliveService() {
        try {
            val intent = Intent(this, KeepAliveService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting keep-alive service: ${e.message}")
        }
    }
    
    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted")
        onStatusChanged?.invoke("无障碍服务被中断")
        
        if (isInCall) {
            stopRecording()
            isInCall = false
            currentCaller = ""
            onCallEnded?.invoke()
        }
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(TAG, "✅ Accessibility service connected")
        onStatusChanged?.invoke("无障碍服务已连接")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "Accessibility service destroyed")
        
        if (isInCall) {
            stopRecording()
            isInCall = false
            currentCaller = ""
        }
    }
}

