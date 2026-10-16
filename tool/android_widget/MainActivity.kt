package com.flowrite.flowrite

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Thay cho MainActivity.kt mặc định do `flutter create` sinh ra — CHỈ một
/// Activity/một Flutter engine duy nhất cho CẢ app bình thường, màn hình
/// cấu hình widget (ACTION_APPWIDGET_CONFIGURE) VÀ màn hình ghi nhanh (mở từ
/// widget ngoài màn hình chính) — phân biệt bằng Intent extra `widgetAction`
/// mà Dart đọc lại qua kênh `flowrite/widget` (xem `lib/ghi_chu_nhanh_widget.dart`).
/// Chủ ý KHÔNG dựng một FlutterActivity thứ hai: mỗi engine Flutter tốn vài
/// chục MB RAM, và widget trên Android không cho phép gõ trực tiếp vào
/// RemoteViews — phải luôn mở một Activity thật, nên dùng lại đúng Activity
/// (và đúng engine, nếu app đang mở sẵn) là đủ.
class MainActivity : FlutterActivity() {
    private val KENH = "flowrite/widget"
    private var kenh: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        kenh = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KENH)
        kenh?.setMethodCallHandler { call, result ->
            when (call.method) {
                // Dart gọi lúc khởi động để biết Activity này được mở ra vì
                // lý do gì — bấm "Ghi nhanh" (widgetAction=quick), lúc hệ
                // thống tự mở màn hình cấu hình sau khi đặt widget lên màn
                // hình chính (widgetAction=config), hay mở HOÀN TOÀN BÌNH
                // THƯỜNG (bấm icon app, hoặc nút "Mở app" của widget — cả
                // hai không có extra này, kết quả trả `null`).
                "layYeuCauMo" -> {
                    val hanhDong = intent?.getStringExtra("widgetAction")
                    val idWidget = intent?.getIntExtra(
                        AppWidgetManager.EXTRA_APPWIDGET_ID,
                        AppWidgetManager.INVALID_APPWIDGET_ID,
                    ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
                    if (hanhDong == null || idWidget == AppWidgetManager.INVALID_APPWIDGET_ID) {
                        result.success(null)
                    } else {
                        result.success(mapOf("hanhDong" to hanhDong, "idWidget" to idWidget))
                    }
                }

                // Lưu mục tiêu (kho nội bộ + id ghi chú) của MỘT widget cụ
                // thể — khoá riêng theo appWidgetId vì nhà có thể đặt nhiều
                // widget, mỗi cái trỏ tới một ghi chú khác nhau.
                "luuMucTieuWidget" -> {
                    val idWidget = (call.argument<Int>("idWidget"))!!
                    val ghiChuId = call.argument<String>("ghiChuId")!!
                    val ten = call.argument<String>("ten") ?: ""
                    val kho: SharedPreferences = applicationContext.getSharedPreferences(
                        "flowrite_widget", 0,
                    )
                    kho.edit()
                        .putString("ghi_chu_id_$idWidget", ghiChuId)
                        .putString("ten_$idWidget", ten)
                        .apply()
                    result.success(null)
                }

                // Đọc lại mục tiêu đã lưu của widget — `null` nếu widget
                // chưa từng được cấu hình (lẽ ra không xảy ra, hệ thống
                // luôn bắt cấu hình trước khi hiện widget lần đầu, nhưng
                // phòng hờ dữ liệu bị xoá/app bị gỡ cài rồi cài lại).
                "docMucTieuWidget" -> {
                    val idWidget = (call.argument<Int>("idWidget"))!!
                    val kho: SharedPreferences = applicationContext.getSharedPreferences(
                        "flowrite_widget", 0,
                    )
                    val ghiChuId = kho.getString("ghi_chu_id_$idWidget", null)
                    if (ghiChuId == null) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "ghiChuId" to ghiChuId,
                                "ten" to (kho.getString("ten_$idWidget", "") ?: ""),
                            ),
                        )
                    }
                }

                // Gọi SAU KHI Dart đã lưu xong mục tiêu ở màn hình cấu hình —
                // báo cho hệ thống biết cấu hình đã hoàn tất (bắt buộc, nếu
                // không widget sẽ bị huỷ ngay khi người dùng rời Activity
                // này) rồi tự đóng Activity luôn. Cũng chủ động yêu cầu vẽ
                // lại widget ngay (RemoteViews của lần vẽ đầu có thể đã chạy
                // trước khi mục tiêu được lưu).
                "hoanTatCauHinh" -> {
                    val idWidget = (call.argument<Int>("idWidget"))!!
                    val ketQua = Intent()
                    ketQua.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, idWidget)
                    setResult(RESULT_OK, ketQua)
                    val manager = AppWidgetManager.getInstance(applicationContext)
                    GhiNhanhWidgetProvider.veLaiMotWidget(applicationContext, manager, idWidget)
                    finish()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
