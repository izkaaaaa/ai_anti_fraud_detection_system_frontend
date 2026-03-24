package com.example.ai_anti_fraud_detection_system_frontend

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity

/**
 * 1像素Activity - 荣耀/华为系统保活
 *
 * 作用：
 * 1. 缩成1像素，欺骗荣耀系统认为应用有前台界面，保住 VOICE_COMMUNICATION 录音权限
 * 2. 500ms 后执行 performGlobalAction(GLOBAL_ACTION_BACK)，防止主界面抢占前台破坏录音状态
 *
 * 触发时机：
 * - 由 CallDetectionService 在检测到通话时启动
 * - 录音进行中持续通过无障碍服务的返回键维持闭环
 */
class OnePXActivity : Activity() {
    companion object {
        private const val TAG = "OnePXActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "OnePXActivity created, isRecording=${AudioRecordingService.isRecordingActive()}, isCallActive=${CallDetectionService.isCallActive()}")

        // 只要不在通话中且没在录音，才退出
        // 注意：restartAudioRecord() 执行期间 isRecordingActive() 短暂为 false，
        // 此时 isCallActive() 仍为 true，不应退出
        if (!AudioRecordingService.isRecordingActive() && !CallDetectionService.isCallActive()) {
            Log.d(TAG, "Not recording and not in call, finishing immediately")
            finish()
            return
        }

        // 缩成1像素，位于屏幕左上角，让荣耀系统认为 App 有前台界面
        val params = window.attributes
        params.width = 1
        params.height = 1
        params.gravity = Gravity.LEFT or Gravity.TOP
        params.x = 0
        params.y = 0
        window.attributes = params

        Log.d(TAG, "Staying as 1px window, will perform BACK in 500ms")

        // 500ms 后通过无障碍服务执行返回键
        // 作用：防止主界面 Activity 抢占前台，破坏录音所需的进程状态
        Handler(Looper.getMainLooper()).postDelayed({
            val service = CallDetectionService.instance
            // isCallActive() 为 true 说明仍在通话中（即使 restart 期间 isRecordingActive 短暂为 false）
            if (service != null && (AudioRecordingService.isRecordingActive() || CallDetectionService.isCallActive())) {
                Log.d(TAG, "Performing GLOBAL_ACTION_BACK to maintain recording state")
                service.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK)
            } else {
                Log.d(TAG, "Not in call and not recording, finishing")
                finish()
            }
        }, 500)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "OnePXActivity destroyed")
    }
}
