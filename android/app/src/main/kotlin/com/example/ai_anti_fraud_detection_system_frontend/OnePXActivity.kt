package com.example.ai_anti_fraud_detection_system_frontend

import android.app.Activity
import android.os.Bundle
import android.util.Log
import android.view.WindowManager

/**
 * 1像素Activity - 华为系统保活
 * 
 * 原理：
 * 华为系统对后台应用的限制更严格。通过启动一个1像素大小的透明Activity，
 * 可以欺骗系统认为应用有前台Activity在运行，从而提高进程优先级，
 * 防止应用被系统杀死。
 * 
 * 特点：
 * - 1像素大小，用户几乎看不到
 * - 透明背景
 * - 不影响用户体验
 * - 仅在华为/荣耀设备上使用
 */
class OnePXActivity : Activity() {
    companion object {
        private const val TAG = "OnePXActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "1px Activity created")
        
        // 设置窗口属性
        val window = window
        window.setGravity(android.view.Gravity.LEFT or android.view.Gravity.TOP)
        
        val params = window.attributes
        params.x = 0
        params.y = 0
        params.width = 1
        params.height = 1
        window.attributes = params
        
        // 设置透明背景
        window.setBackgroundDrawableResource(android.R.color.transparent)
        
        // 防止被系统杀死
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "1px Activity destroyed")
    }
}

