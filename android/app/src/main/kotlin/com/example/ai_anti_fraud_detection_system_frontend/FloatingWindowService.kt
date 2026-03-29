package com.example.ai_anti_fraud_detection_system_frontend

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.graphics.Typeface
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

/**
 * 悬浮窗服务
 *
 * 完全独立，不干扰 AudioRecordingService / CallDetectionService 的任何逻辑。
 * 通过 companion object 静态方法从 MainActivity MethodChannel 调用。
 *
 * 显示内容：当前风险等级（安全/可疑/危险）+ 置信度
 * 支持拖动，默认固定在右上角
 */
class FloatingWindowService : Service() {

    companion object {
        /** 当前存活的实例（最多一个）*/
        var instance: FloatingWindowService? = null
            private set

        fun start(context: Context) {
            context.startService(Intent(context, FloatingWindowService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, FloatingWindowService::class.java))
        }

        /** 由 MainActivity MethodChannel 调用，线程安全 */
        fun updateRiskLevel(riskLevel: String, confidence: Double) {
            instance?.updateRisk(riskLevel, confidence)
        }
    }

    private var windowManager: WindowManager? = null
    private var rootView: LinearLayout? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    // 子 View 引用（避免每次 updateRisk 重复 findView）
    private var dotView: View? = null
    private var labelView: TextView? = null
    private var riskTextView: TextView? = null
    private var confTextView: TextView? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    // ── 生命周期 ────────────────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        buildWindow()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        removeWindow()
    }

    // ── 构建悬浮窗 ──────────────────────────────────────────────

    private fun buildWindow() {
        // 最外层容器（承载卡片，用于拖动）
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
        }

        // 卡片本体
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(14), dp(10), dp(14), dp(10))
        }
        applyCardBg(card, "safe")

        // 第一行：圆点 + 状态标签
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        dotView = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(8), dp(8)).also {
                it.marginEnd = dp(5)
            }
        }
        applyDotColor(dotView!!, "safe")
        row.addView(dotView)

        labelView = TextView(this).apply {
            text = "监测中"
            textSize = 10.5f
            setTextColor(Color.parseColor("#D4FAE6"))
            typeface = Typeface.DEFAULT_BOLD
        }
        row.addView(labelView)
        card.addView(row)

        // 第二行：风险等级大字
        riskTextView = TextView(this).apply {
            text = "安全"
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#4ADE80"))
            setPadding(0, dp(2), 0, 0)
        }
        card.addView(riskTextView)

        // 第三行：置信度（有值才显示）
        confTextView = TextView(this).apply {
            text = ""
            textSize = 9f
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#86EFAC"))
        }
        card.addView(confTextView)

        container.addView(card)
        rootView = container

        // WindowManager.LayoutParams
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = dp(10)
            y = dp(80)
        }

        enableDrag(container)

        try {
            windowManager?.addView(container, layoutParams)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ── 拖动 ────────────────────────────────────────────────────

    private fun enableDrag(view: View) {
        var ix = 0; var iy = 0
        var tx = 0f; var ty = 0f
        var dragging = false

        view.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> {
                    ix = layoutParams?.x ?: 0
                    iy = layoutParams?.y ?: 0
                    tx = ev.rawX; ty = ev.rawY
                    dragging = false; true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (ev.rawX - tx).toInt()
                    val dy = (ev.rawY - ty).toInt()
                    if (Math.abs(dx) > 4 || Math.abs(dy) > 4) dragging = true
                    if (dragging) {
                        layoutParams?.x = ix - dx
                        layoutParams?.y = iy + dy
                        windowManager?.updateViewLayout(view, layoutParams)
                    }
                    true
                }
                else -> false
            }
        }
    }

    // ── 风险等级更新 ─────────────────────────────────────────────

    fun updateRisk(riskLevel: String, confidence: Double) {
        mainHandler.post {
            val card = rootView?.getChildAt(0) as? LinearLayout ?: return@post
            applyCardBg(card, riskLevel)
            applyDotColor(dotView ?: return@post, riskLevel)

            when (riskLevel) {
                "suspicious" -> {
                    labelView?.text = "注意！"
                    labelView?.setTextColor(Color.parseColor("#FEF3C7"))
                    riskTextView?.text = "可疑"
                    riskTextView?.setTextColor(Color.parseColor("#FCD34D"))
                    confTextView?.setTextColor(Color.parseColor("#FDE68A"))
                }
                "danger" -> {
                    labelView?.text = "警告！"
                    labelView?.setTextColor(Color.parseColor("#FFE4E4"))
                    riskTextView?.text = "危险"
                    riskTextView?.setTextColor(Color.parseColor("#F87171"))
                    confTextView?.setTextColor(Color.parseColor("#FCA5A5"))
                }
                else -> {
                    labelView?.text = "监测中"
                    labelView?.setTextColor(Color.parseColor("#D4FAE6"))
                    riskTextView?.text = "安全"
                    riskTextView?.setTextColor(Color.parseColor("#4ADE80"))
                    confTextView?.setTextColor(Color.parseColor("#86EFAC"))
                }
            }

            confTextView?.text = if (confidence > 0.0)
                "${(confidence * 100).toInt()}%" else ""

            try {
                windowManager?.updateViewLayout(rootView, layoutParams)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    // ── 移除窗口 ─────────────────────────────────────────────────

    private fun removeWindow() {
        try {
            rootView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        rootView = null
    }

    // ── 卡片背景 ─────────────────────────────────────────────────

    private fun applyCardBg(view: LinearLayout, level: String) {
        val (c1, c2, stroke) = when (level) {
            "suspicious" -> Triple("#271A00", "#3B2500", "#F59E0B")
            "danger"     -> Triple("#270000", "#3B0000", "#EF4444")
            else         -> Triple("#001A0D", "#002E18", "#22C55E")
        }
        view.background = GradientDrawable(
            GradientDrawable.Orientation.TL_BR,
            intArrayOf(Color.parseColor(c1), Color.parseColor(c2))
        ).apply {
            cornerRadius = dp(12).toFloat()
            setStroke(dp(1), Color.parseColor(stroke))
        }
    }

    private fun applyDotColor(view: View, level: String) {
        val color = when (level) {
            "suspicious" -> "#F59E0B"
            "danger"     -> "#EF4444"
            else         -> "#22C55E"
        }
        view.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor(color))
        }
    }

    // ── 工具 ─────────────────────────────────────────────────────

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density + 0.5f).toInt()
}





