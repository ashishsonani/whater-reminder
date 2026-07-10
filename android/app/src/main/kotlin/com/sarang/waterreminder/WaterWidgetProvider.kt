package com.sarang.waterreminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget showing today's hydration progress.
 * Data is pushed from Flutter via the home_widget plugin
 * (keys: amount_text, progress_pct).
 */
class WaterWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.water_widget).apply {
                val amount = widgetData.getString("amount_text", "0 / 0 ml") ?: "0 / 0 ml"
                val pct = widgetData.getInt("progress_pct", 0)

                setTextViewText(R.id.widget_amount, amount)
                setTextViewText(R.id.widget_pct, "$pct%")
                setProgressBar(R.id.widget_progress, 100, pct, false)

                // Tap anywhere on the widget opens the app.
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
