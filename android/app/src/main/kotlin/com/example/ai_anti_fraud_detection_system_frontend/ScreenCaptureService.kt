package com.example.ai_anti_fraud_detection_system_frontend

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.io.ByteArrayOutputStream

class ScreenCaptureService : Service() {
    companion object {
        const val CHANNEL_ID = "screen_capture_channel"
        const val NOTIFICATION_ID = 2001
        
        var mediaProjection: MediaProjection? = null
        var imageReader: ImageReader? = null
        var virtualDisplay: VirtualDisplay? = null
        var isCapturing = false
        
        fun startService(context: Context, resultCode: Int, data: Intent) {
            val intent = Intent(context, ScreenCaptureService::class.java).apply {
                putExtra("resultCode", resultCode)
                putExtra("data", data)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            context.stopService(Intent(context, ScreenCaptureService::class.java))
        }
        
        // ✅ 静态方法：直接从 imageReader 获取截图
        fun captureScreenStatic(): ByteArray? {
            return try {
                val image = imageReader?.acquireLatestImage()
                if (image != null) {
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * image.width
                    
                    val bitmap = Bitmap.createBitmap(
                        image.width + rowPadding / pixelStride,
                        image.height,
                        Bitmap.Config.ARGB_8888
                    )
                    bitmap.copyPixelsFromBuffer(buffer)
                    
                    val croppedBitmap = Bitmap.createBitmap(bitmap, 0, 0, image.width, image.height)
                    
                    val outputStream = ByteArrayOutputStream()
                    croppedBitmap.compress(Bitmap.CompressFormat.JPEG, 80, outputStream)
                    val jpegData = outputStream.toByteArray()
                    
                    image.close()
                    bitmap.recycle()
                    croppedBitmap.recycle()
                    
                    jpegData
                } else {
                    null
                }
            } catch (e: Exception) {
                android.util.Log.e("ScreenCapture", "Capture failed: ${e.message}")
                null
            }
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        intent?.let {
            val resultCode = it.getIntExtra("resultCode", Activity.RESULT_CANCELED)
            val data = it.getParcelableExtra<Intent>("data")
            
            if (resultCode == Activity.RESULT_OK && data != null) {
                setupMediaProjection(resultCode, data)
            }
        }
        
        return START_STICKY
    }
    
    private fun setupMediaProjection(resultCode: Int, data: Intent) {
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, data)
        
        // ✅ Android 14+ 要求：必须先注册回调才能创建 VirtualDisplay
        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                // MediaProjection 停止时的回调
                android.util.Log.d("ScreenCapture", "MediaProjection stopped")
                cleanup()
            }
        }, null)
        
        val metrics = resources.displayMetrics
        val width = 640
        val height = 480
        
        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width,
            height,
            metrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            null
        )
        
        isCapturing = true
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "屏幕截图服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "用于实时检测的屏幕截图"
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("屏幕截图中")
            .setContentText("正在捕获屏幕用于实时检测")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        cleanup()
    }
    
    private fun cleanup() {
        isCapturing = false
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        
        virtualDisplay = null
        imageReader = null
        mediaProjection = null
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
}

