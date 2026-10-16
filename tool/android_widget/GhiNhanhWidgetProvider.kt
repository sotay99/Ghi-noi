package com.flowrite.flowrite

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/// Widget "Ghi nhanh" đặt ở màn hình chính Android — KHÔNG có khung nhập
/// liệu thật bên trong (RemoteViews không hỗ trợ EditText, xem thảo luận
/// trước khi làm tính năng này), chỉ hai nút bấm, mỗi nút mở MainActivity
/// với một Intent extra khác nhau:
/// - "Ghi nhanh" → `widgetAction=quick` — Dart hiện màn hình ghi nhanh.
/// - "Mở app" → KHÔNG đặt extra gì cả, y hệt Intent mà launcher Android tự
///   tạo khi bấm icon app — mở app bình thường, không nhảy vào bất kỳ ghi
///   chú/màn hình soạn thảo cụ thể nào (yêu cầu rõ của người dùng).
class GhiNhanhWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        idWidgets: IntArray,
    ) {
        for (idWidget in idWidgets) veLaiMotWidget(context, manager, idWidget)
    }

    companion object {
        fun veLaiMotWidget(context: Context, manager: AppWidgetManager, idWidget: Int) {
            val views = RemoteViews(context.packageName, R.layout.ghi_nhanh_widget)

            val yGhiNhanh = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("widgetAction", "quick")
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, idWidget)
                // Mỗi widget có mục tiêu riêng — action+data khác nhau mới
                // sinh ra PendingIntent KHÁC NHAU cho từng appWidgetId (nếu
                // không, bấm "Ghi nhanh" ở widget B lại chạy nhầm Intent đã
                // cache sẵn của widget A — PendingIntent so khớp theo
                // action+data+extras cơ bản, KHÔNG so theo extras thường).
                data = android.net.Uri.parse("flowrite://widget/$idWidget/quick")
            }
            views.setOnClickPendingIntent(
                R.id.nutGhiNhanh,
                android.app.PendingIntent.getActivity(
                    context,
                    idWidget * 2,
                    yGhiNhanh,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
                ),
            )

            // "Mở app" — Intent launcher CHUẨN, không extra gì, không gắn
            // appWidgetId vào data (không cần phân biệt widget nào, mọi
            // widget đều mở app giống hệt nhau khi bấm nút này).
            val yMoApp = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            yMoApp.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            views.setOnClickPendingIntent(
                R.id.nutMoApp,
                android.app.PendingIntent.getActivity(
                    context,
                    0,
                    yMoApp,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
                ),
            )

            manager.updateAppWidget(idWidget, views)
        }
    }
}
