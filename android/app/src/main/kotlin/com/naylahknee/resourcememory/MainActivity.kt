package com.naylahknee.resourcememory

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Adds the lock-screen bridge for NanyNany's Act side.
 *
 * Android removed lock-screen widgets after 4.4, so the honest equivalent of
 * the iOS lock-screen widget is a persistent low-priority notification: it is
 * what Android shows on the lock screen, it always displays the current
 * "Start here" task, and tapping it deep-links into the app on that task.
 */
class MainActivity : FlutterActivity() {
    private val lockScreenChannel = "com.naylahknee.nanynany/lockscreen"
    private val notificationId = 4101
    private val channelId = "nanynany_current_task"
    private var pendingFocusLink = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            lockScreenChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncCurrentTask" -> {
                    val title = call.argument<String>("title").orEmpty().trim()
                    val dueAtMs = call.argument<Number>("dueAtMs")?.toLong()
                    if (title.isEmpty()) clearTaskNotification()
                    else showTaskNotification(title, dueAtMs)
                    result.success(null)
                }
                "clearCurrentTask" -> {
                    clearTaskNotification()
                    result.success(null)
                }
                "getPendingFocusLink" -> {
                    val pending = pendingFocusLink || intent?.data?.scheme == "resourcememory"
                    pendingFocusLink = false
                    result.success(if (pending) "focus" else null)
                }
                else -> result.notImplemented()
            }
        }
        // Cold start straight from the notification tap.
        if (intent?.data?.scheme == "resourcememory") pendingFocusLink = true
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.data?.scheme == "resourcememory") pendingFocusLink = true
    }

    private fun showTaskNotification(title: String, dueAtMs: Long?) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    "Current task",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
        }
        val openIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("resourcememory://focus")
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val timeSuffix = dueAtMs?.let { " · ${militaryTime(it)}" } ?: ""
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Start here$timeSuffix")
            .setContentText(title)
            .setStyle(NotificationCompat.BigTextStyle().bigText(title))
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        // On Android 13+ without notification permission this is silently
        // dropped by the system; never crash the app over the widget.
        runCatching {
            NotificationManagerCompat.from(this).notify(notificationId, notification)
        }
    }

    /** 24-hour military time, e.g. 14:30. */
    private fun militaryTime(epochMs: Long): String {
        val sdf = java.text.SimpleDateFormat("HH:mm", java.util.Locale.US)
        sdf.timeZone = java.util.TimeZone.getDefault()
        return sdf.format(java.util.Date(epochMs))
    }

    private fun clearTaskNotification() {
        runCatching {
            NotificationManagerCompat.from(this).cancel(notificationId)
        }
    }
}
