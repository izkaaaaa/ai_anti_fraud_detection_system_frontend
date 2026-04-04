package com.example.ai_anti_fraud_detection_system_frontend

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.app.PendingIntent
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
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * 悬浮窗服务
 *
 * 完全独立，不干扰 AudioRecordingService / CallDetectionService 的任何逻辑。
 * 通过 companion object 静态方法从 MainActivity MethodChannel 调用。
 *
 * 显示内容：当前风险等级（安全/可疑/危险）+ 置信度 + 平台场景
 * 支持拖动，默认固定在右上角
 */
class FloatingWindowService : Service() {

    companion object {
        /** 当前存活的实例（最多一个）*/
        var instance: FloatingWindowService? = null
            private set

        const val ALERT_CHANNEL_ID = "ai_anti_fraud_alert"
        const val ALERT_CHANNEL_NAME = "风险预警"

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

        /** 由 MainActivity MethodChannel 调用，线程安全 - 更新平台场景 */
        fun updateScene(scene: String) {
            instance?.updateSceneDisplay(scene)
        }

        /** 由 MainActivity MethodChannel 调用，触发 Alert（medium=通知，high=全屏遮罩）*/
        fun showAlert(context: Context, level: String, title: String, message: String) {
            instance?.showAlertInternal(level, title, message)
                ?: start(context).also { instance?.showAlertInternal(level, title, message) }
        }

        /** 由 MainActivity MethodChannel 调用，关闭全屏遮罩 */
        fun dismissFullScreenWarning() {
            instance?.dismissFullScreenAlert()
        }
    }

    private var windowManager: WindowManager? = null
    private var rootView: LinearLayout? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    // 子 View 引用（避免每次 updateRisk 重复 findView）
    private var sceneView: TextView? = null  // 平台场景显示
    private var dotView: View? = null
    private var labelView: TextView? = null
    private var riskTextView: TextView? = null
    private var confTextView: TextView? = null

    // ── 全屏遮罩（high 预警）──────────────────────────────
    private var alertWindow: LinearLayout? = null
    private var alertLayoutParams: WindowManager.LayoutParams? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    // ── 生命周期 ────────────────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        buildWindow()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        dismissFullScreenAlert()
        removeWindow()
    }

    // ── 创建通知渠道（Android 8.0+）──────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                ALERT_CHANNEL_ID,
                ALERT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "AI 反诈风险预警通知"
                enableLights(true)
                lightColor = Color.parseColor("#F59E0B")
                enableVibration(true)
            }
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    // ── Alert 入口（按 level 分发）───────────────────────────────

    private fun showAlertInternal(level: String, title: String, message: String) {
        mainHandler.post {
            when (level) {
                "high"   -> showHighAlert(title, message)
                else     -> showMediumAlert(title, message)  // medium / 其他
            }
        }
    }

    // ── Medium: 系统通知栏通知 ───────────────────────────────

    private fun showMediumAlert(title: String, message: String) {
        val ctx = applicationContext

        // 点击通知 → 拉起 App 主界面
        val intent = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            ctx, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = Notification.Builder(ctx, ALERT_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("⚠️ $title")
            .setContentText(message)
            .setPriority(Notification.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setColor(Color.parseColor("#F59E0B"))
            .build()

        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(System.currentTimeMillis().toInt(), notification)
    }

    // ── High: 全屏预警遮罩 ───────────────────────────────────

    private fun showHighAlert(title: String, message: String) {
        // 先关闭已有遮罩，避免重复
        dismissFullScreenAlert()

        val ctx = this

        // 全屏窗口参数
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        alertLayoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        // 半透明背景层（点击不关闭）
        val bg = View(ctx).apply {
            setBackgroundColor(Color.parseColor("#CC000000"))
        }

        // 卡片容器
        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(32), dp(40), dp(32), dp(40))
        }
        card.background = GradientDrawable(
            GradientDrawable.Orientation.TL_BR,
            intArrayOf(Color.parseColor("#3B0000"), Color.parseColor("#270000"))
        ).apply {
            cornerRadius = dp(20).toFloat()
            setStroke(dp(2), Color.parseColor("#EF4444"))
        }

        // 警告图标
        val iconText = TextView(ctx).apply {
            text = "🚨"
            textSize = 60f
            gravity = Gravity.CENTER
        }

        // 风险等级标签
        val levelLabel = TextView(ctx).apply {
            text = "高风险警告"
            textSize = 22f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#EF4444"))
            setPadding(0, dp(16), 0, dp(8))
        }

        // 标题
        val titleView = TextView(ctx).apply {
            text = title
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#FEE2E2"))
            setPadding(0, 0, 0, dp(12))
        }

        // 消息内容
        val msgView = TextView(ctx).apply {
            text = message
            textSize = 15f
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#FCA5A5"))
            setPadding(0, 0, 0, dp(28))
        }

        // 确认按钮
        val btn = Button(ctx).apply {
            text = "我已知晓"
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            setBackgroundColor(Color.parseColor("#EF4444"))
            setTextColor(Color.WHITE)
            setPadding(dp(40), dp(12), dp(40), dp(12))
            // 圆角需要通过 background drawable 实现
            (layoutParams as? LinearLayout.LayoutParams)?.gravity = Gravity.CENTER
            setOnClickListener {
                dismissFullScreenAlert()
            }
        }
        // 圆角按钮
        btn.background = GradientDrawable().apply {
            cornerRadius = dp(10).toFloat()
            setColor(Color.parseColor("#EF4444"))
        }

        card.addView(iconText)
        card.addView(levelLabel)
        card.addView(titleView)
        card.addView(msgView)
        card.addView(btn)

        // 背景覆盖在卡片下方，保证卡片居中
        alertWindow = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
        }
        alertWindow?.addView(bg, WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT
        ).apply { gravity = Gravity.CENTER })
        alertWindow?.addView(card)

        try {
            windowManager?.addView(alertWindow, alertLayoutParams)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ── 关闭全屏遮罩 ───────────────────────────────────────────

    fun dismissFullScreenAlert() {
        mainHandler.post {
            alertWindow?.let {
                try { windowManager?.removeView(it) } catch (_: Exception) {}
                alertWindow = null
            }
        }
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

        // 第一行：平台场景（新增，默认显示"默认检测"）
        sceneView = TextView(this).apply {
            text = "🎯 默认检测"
            textSize = 8.5f
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#9CA3AF"))
            setPadding(0, 0, 0, dp(4))
        }
        card.addView(sceneView)

        // 第二行：圆点 + 状态标签
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

        // 第三行：风险等级大字
        riskTextView = TextView(this).apply {
            text = "安全"
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#4ADE80"))
            setPadding(0, dp(2), 0, 0)
        }
        card.addView(riskTextView)

        // 第四行：置信度（有值才显示）
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

    // ── 平台场景更新 ─────────────────────────────────────────────

    /**
     * 更新平台场景显示
     * 直接显示传入的文本，如后端 description
     */
    fun updateSceneDisplay(scene: String) {
        mainHandler.post {
            // 根据 API 文档：unknown / 未知环境 时显示"默认检测"
            val displayText = when (scene) {
                "未知环境", "unknown", "" -> "🎯 默认检测"
                else -> scene
            }
            sceneView?.text = displayText
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





