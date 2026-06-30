package com.example.task_management

import android.content.Intent
import android.os.Bundle
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "app.channel.notifications"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"areNotificationsEnabled" -> {
					val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
					result.success(enabled)
				}
				"openNotificationSettings" -> {
					try {
						val intent = Intent()
						intent.action = "android.settings.APP_NOTIFICATION_SETTINGS"
						intent.putExtra("android.provider.extra.APP_PACKAGE", packageName)
						startActivity(intent)
						result.success(true)
					} catch (e: Exception) {
						result.error("UNAVAILABLE", "Could not open settings", null)
					}
				}
				"getLocalTimezone" -> {
					try {
						val tz = java.util.TimeZone.getDefault().id
						result.success(tz)
					} catch (e: Exception) {
						result.error("UNAVAILABLE", "Could not get timezone", null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
