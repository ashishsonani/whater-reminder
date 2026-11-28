package com.sarang.waterreminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import kotlin.math.roundToInt

class WaterWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val QUICK_LOG = "com.sarang.waterreminder.WIDGET_QUICK_LOG"
        private const val UNDO_LOG = "com.sarang.waterreminder.WIDGET_UNDO_LOG"
        private const val QUEUE = "quick_log_queue"
        private const val SNAPSHOT = "quick_log_snapshot"
        private const val LIMIT = 1000
    }

    private data class LogEvent(val at: Long, val undo: Long? = null)

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != QUICK_LOG && intent.action != UNDO_LOG) {
            super.onReceive(context, intent)
            return
        }
        val data = HomeWidgetPlugin.getData(context)
        val snapshot = snapshot(data)
        if (!snapshot.optBoolean("ready")) return
        val queue = pending(data, snapshot.optLong("ack"))
        val latest = queue.lastOrNull()
        val isUndo = intent.action == UNDO_LOG
        if (isUndo && (latest == null || latest.undo != null)) return
        if (!isUndo && queue.size >= LIMIT) return
        val timestamp = maxOf(System.currentTimeMillis() * 1000, (latest?.at ?: 0) + 1, snapshot.optLong("ack") + 1)
        queue.add(LogEvent(timestamp, if (isUndo) latest?.at else null))
        val encoded = JSONArray()
        queue.forEach { event ->
            val json = JSONObject().put("at", event.at)
            event.undo?.let { json.put("undo", it) }
            encoded.put(json)
        }
        data.edit().putString(QUEUE, encoded.toString()).apply()

        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(android.content.ComponentName(context, WaterWidgetProvider::class.java))
        onUpdate(context, manager, ids, data)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val snapshot = snapshot(widgetData)
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val start = today.timeInMillis
        today.add(Calendar.DATE, 1)
        val end = today.timeInMillis
        val isMl = snapshot.optBoolean("isMl", true)
        val amount = if (isMl) 250 else 8
        val queue = pending(widgetData, snapshot.optLong("ack"))
        val queued = queue.fold(0) { total, event ->
            val time = (event.undo ?: event.at) / 1000
            total + if (time in start until end) (if (event.undo == null) 1 else -1) else 0
        }
        val canUndo = queue.lastOrNull()?.let { it.undo == null } ?: false
        val goal = snapshot.optInt("goal")
        val base = if (snapshot.optLong("dayStart") == start) snapshot.optInt("current") else 0
        val current = (base + queued * amount).coerceAtLeast(0)
        val percent = if (goal > 0) (100.0 * current / goal).coerceIn(0.0, 100.0).roundToInt() else 0
        val unit = if (isMl) "ml" else "oz"
        val flag = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val quickLog = PendingIntent.getBroadcast(context, 1, Intent(context, WaterWidgetProvider::class.java).setAction(QUICK_LOG), flag)
        val undo = PendingIntent.getBroadcast(context, 2, Intent(context, WaterWidgetProvider::class.java).setAction(UNDO_LOG), flag)
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val open = launch?.let { PendingIntent.getActivity(context, 0, it, flag) }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.water_widget).apply {
                setTextViewText(R.id.widget_amount, "$current / $goal $unit")
                setTextViewText(R.id.widget_pct, "$percent%")
                setProgressBar(R.id.widget_progress, 100, percent, false)
                setViewVisibility(R.id.widget_quick_log, if (snapshot.optBoolean("ready")) View.VISIBLE else View.GONE)
                setTextViewText(R.id.widget_quick_log, context.getString(R.string.widget_quick_log, amount, unit))
                setOnClickPendingIntent(R.id.widget_quick_log, quickLog)
                setViewVisibility(R.id.widget_undo, if (canUndo) View.VISIBLE else View.GONE)
                setOnClickPendingIntent(R.id.widget_undo, undo)
                if (open != null) setOnClickPendingIntent(R.id.widget_root, open)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun snapshot(data: SharedPreferences): JSONObject =
        runCatching { JSONObject(data.getString(SNAPSHOT, "{}") ?: "{}") }.getOrDefault(JSONObject())

    private fun pending(data: SharedPreferences, ack: Long): MutableList<LogEvent> {
        val array = runCatching { JSONArray(data.getString(QUEUE, "[]") ?: "[]") }.getOrDefault(JSONArray())
        return (0 until array.length()).mapNotNull { index ->
            val item = array.optJSONObject(index) ?: return@mapNotNull null
            val at = item.optLong("at")
            if (at <= ack) null else LogEvent(at, item.optLong("undo").takeIf { it > 0 })
        }.toMutableList()
    }
}
