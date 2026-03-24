package com.example.ai_anti_fraud_detection_system_frontend

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * 无障碍服务 - 自动检测通话
 *
 * 功能：
 * 1. 监听应用切换事件（TYPE_WINDOW_STATE_CHANGED）
 * 2. 识别 QQ/微信 视频通话
 * 3. 自动触发录音（时序：先1像素Activity → 延迟800ms → 再启动录音）
 * 4. 监听通话邀请文本
 *
 * 关键时序说明：
 * 荣耀/华为系统在 AudioRecord 初始化时判断进程优先级。
 * 必须先通过1像素Activity让系统认定进程为前台，再启动录音，
 * 否则即使App界面可见，AudioRecordingService（后台Service）发起的录音
 * 仍会被系统识别为"后台录音"并静音。
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
        // 注意：QQ 通话类名层级：
        //   VideoInviteActivity = 邀请界面（响铃中，尚未接通）
        //   AVActivity           = 通话已接通（真正的通话界面）
        private val QQ_CALL_ACTIVITIES = listOf(
            "com.tencent.mobileqq.activity.VideoCallActivity",
            "com.tencent.mobileqq.activity.CallActivity",
            "com.tencent.mobileqq.video.VideoActivity",
            "com.tencent.mobileqq.call.CallActivity",
            // 实机日志捕获到的真实类名（荣耀设备）
            "com.tencent.av.ui.VideoInviteActivity",
            "com.tencent.av.ui.AVActivity"
        )

        // AVActivity = 通话真正接通，需要重新触发保活+录音
        private val QQ_CALL_CONNECTED_ACTIVITIES = listOf(
            "com.tencent.av.ui.AVActivity",
            "com.tencent.mobileqq.activity.VideoCallActivity"
        )

        private val WECHAT_CALL_ACTIVITIES = listOf(
            "com.tencent.mm.plugin.voip.ui.VideoActivity",
            "com.tencent.mm.plugin.voip.ui.VoipActivity",
            "com.tencent.mm.ui.voip.VideoCallActivity"
        )

        // 状态回调
        var onCallDetected: ((String, String) -> Unit)? = null
        var onCallEnded: (() -> Unit)? = null
        var onStatusChanged: ((String) -> Unit)? = null

        private var isInCall = false
        private var currentCaller = ""
        // AVActivity 触发 restart 的节流时间戳（避免荣耀设备连续触发多次）
        private var lastRestartRequestTime = 0L
        private const val RESTART_THROTTLE_MS = 5000L

        /** 供 OnePXActivity 判断是否仍在通话中（restart 期间 isRecordingActive 短暂为 false）*/
        fun isCallActive(): Boolean = isInCall

        // 静态实例引用，供 OnePXActivity 调用 performGlobalAction
        var instance: CallDetectionService? = null
    }

    // 主线程 Handler（用于延迟启动录音）
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        try {
            // 荣耀/华为设备保活机制（精准触发版）
            // 只在 QQ/微信通话界面活跃 且 正在录音时，才启动 OnePXActivity 保活
            val brand = Build.BRAND.lowercase()
            if ((brand == "huawei" || brand == "honor") &&
                event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
                AudioRecordingService.isRecordingActive() &&
                isInCall) {
                val packageName = event.packageName?.toString() ?: ""
                // 仅当通话包（QQ/微信）的窗口事件，才启动保活
                if (packageName == QQ_PACKAGE || packageName == WECHAT_PACKAGE) {
                    Log.d(TAG, "[荣耀保活] 通话中窗口事件，启动 OnePXActivity 保活")
                    startOnePxActivity()
                }
            }

            when (event.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> handleWindowStateChanged(event)
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> handleWindowContentChanged(event)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling accessibility event: ${e.message}")
        }
    }

    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: return

        Log.d(TAG, "Window changed: $packageName / $className")

        // 检测 QQ 视频通话
        if (packageName == QQ_PACKAGE && isQQCallActivity(className)) {
            Log.i(TAG, "✅ Detected QQ call activity: $className")
            onStatusChanged?.invoke("检测到 QQ 视频通话")

            // AVActivity = 通话真正接通；VideoInviteActivity = 仅邀请/响铃
            val isCallConnected = isQQCallConnectedActivity(className)

            if (!isInCall) {
                // 首次进入通话相关界面：设置标志，启动录音
                isInCall = true
                currentCaller = "QQ 通话"
                Log.i(TAG, "[QQ] 首次检测到通话界面($className)，启动录音")
                startRecordingWithDelay("QQ")
                onCallDetected?.invoke("QQ", currentCaller)
            } else if (isCallConnected) {
                // 已在通话状态，且切换到了真正接通的界面（AVActivity）
                val brand = Build.BRAND.lowercase()
                if (brand == "huawei" || brand == "honor") {
                    val now = System.currentTimeMillis()
                    if (now - lastRestartRequestTime < RESTART_THROTTLE_MS) {
                        Log.w(TAG, "[QQ] AVActivity restart 节流，跳过 (距上次 ${now - lastRestartRequestTime}ms)")
                        startOnePxActivity()
                    } else if (AudioRecordingService.isRecordingActive()) {
                        // 录音在 AVActivity 前就已运行（先开检测再接电话场景）
                        // QQ 接通后会抢占 VOICE_COMMUNICATION 源导致我们的录音全静音，必须重建
                        lastRestartRequestTime = now
                        Log.i(TAG, "[QQ] 通话接通(AVActivity)，先开检测场景，重建 AudioRecord")
                        startOnePxActivity()
                        mainHandler.postDelayed({
                            Log.i(TAG, "[QQ] 开始重建 AudioRecord")
                            AudioRecordingService.restartAudioRecord()
                        }, 1500)
                    } else {
                        // 先接电话再开检测场景：系统会自动恢复，只补充保活
                        Log.i(TAG, "[QQ] 通话接通(AVActivity)，先接电话场景，不重建 AudioRecord")
                        startOnePxActivity()
                    }
                }
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
                startRecordingWithDelay("WeChat")
                onCallDetected?.invoke("WeChat", currentCaller)
            }
            return
        }

        // 通话结束判断：排除自己的包名和桌面/系统UI，避免误判
        val ownPackage = packageName == applicationContext.packageName
        if (isInCall && !ownPackage && packageName != QQ_PACKAGE && packageName != WECHAT_PACKAGE) {
            val isLauncher = packageName == "com.android.launcher3" ||
                packageName == "com.huawei.android.launcher" ||
                packageName == "com.hihonor.android.launcher" ||
                packageName.contains("launcher") ||
                packageName == "com.android.systemui"
            if (isLauncher) {
                // 桌面/系统UI：可能是小窗切换，不停止录音
                Log.d(TAG, "Switched to launcher/system, keeping recording alive")
                return
            }
            Log.i(TAG, "✅ Call ended (switched to other app: $packageName)")
            onStatusChanged?.invoke("通话已结束")
            isInCall = false
            currentCaller = ""
            mainHandler.removeCallbacksAndMessages(null)
            stopRecording()
            onCallEnded?.invoke()
        }
    }

    /**
     * 先启动1像素Activity，延迟800ms后再启动录音
     *
     * 原因：荣耀/华为系统在 AudioRecord 初始化时判断进程优先级。
     * 1像素Activity启动后系统需要一点时间重新评估进程优先级，
     * 延迟800ms确保系统完成该判断再发起录音，避免被识别为后台录音并静音。
     */
    private fun startRecordingWithDelay(appName: String) {
        val brand = Build.BRAND.lowercase()
        val isHuaweiOrHonor = brand == "huawei" || brand == "honor"

        if (isHuaweiOrHonor) {
            Log.i(TAG, "[$appName] 荣耀/华为设备：先启动1像素Activity，800ms后启动录音")
            // 第一步：先启动1像素Activity，让系统认定进程为前台
            startOnePxActivity()
            // 第二步：延迟800ms，等系统完成进程优先级重新评估
            mainHandler.postDelayed({
                Log.i(TAG, "[$appName] 延迟完成，现在启动录音")
                startRecording()
            }, 800)
        } else {
            // 非荣耀设备直接启动录音
            Log.i(TAG, "[$appName] 非荣耀设备，直接启动录音")
            startRecording()
        }
    }

    /**
     * 启动1像素Activity（荣耀/华为保活）
     */
    private fun startOnePxActivity() {
        try {
            val intent = Intent(this, OnePXActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            startActivity(intent)
            Log.d(TAG, "1像素Activity已启动")
        } catch (e: Exception) {
            Log.e(TAG, "启动1像素Activity失败: ${e.message}")
        }
    }

    private fun startRecording() {
        try {
            Log.d(TAG, "Starting audio recording...")
            AudioRecordingService.startService(this)
            startKeepAliveService()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting recording: ${e.message}")
        }
    }

    private fun stopRecording() {
        try {
            Log.d(TAG, "Stopping audio recording...")
            AudioRecordingService.stopService(this)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording: ${e.message}")
        }
    }

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

    private fun handleWindowContentChanged(event: AccessibilityEvent) {
        val text = event.text
        if (text == null || text.isEmpty()) return

        val content = text.joinToString(" ")

        if (content.contains("邀请你语音通话") ||
            content.contains("邀请你视频通话") ||
            content.contains("正在通话中")) {

            Log.d(TAG, "Call text detected: $content")

            val caller = extractCallerName(content)
            if (caller.isNotEmpty() && caller != currentCaller) {
                currentCaller = caller
                Log.i(TAG, "Caller name: $caller")
                onStatusChanged?.invoke("通话对方: $caller")
            }
        }
    }

    private fun extractCallerName(text: String): String {
        val match = "(.+?)邀请你".toRegex().find(text)
        if (match != null) return match.groupValues[1]
        val match2 = "与(.+?)通话中".toRegex().find(text)
        if (match2 != null) return match2.groupValues[1]
        return ""
    }

    private fun isQQCallActivity(className: String): Boolean {
        return QQ_CALL_ACTIVITIES.any { className.contains(it) || it.contains(className) }
    }

    private fun isQQCallConnectedActivity(className: String): Boolean {
        return QQ_CALL_CONNECTED_ACTIVITIES.any { className.contains(it) || it.contains(className) }
    }

    private fun isWeChatCallActivity(className: String): Boolean {
        return WECHAT_CALL_ACTIVITIES.any { className.contains(it) || it.contains(className) }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted")
        onStatusChanged?.invoke("无障碍服务被中断")
        mainHandler.removeCallbacksAndMessages(null)
        if (isInCall) {
            stopRecording()
            isInCall = false
            currentCaller = ""
            onCallEnded?.invoke()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "✅ Accessibility service connected")
        onStatusChanged?.invoke("无障碍服务已连接")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.i(TAG, "Accessibility service destroyed")
        mainHandler.removeCallbacksAndMessages(null)
        if (isInCall) {
            stopRecording()
            isInCall = false
            currentCaller = ""
        }
    }
}
