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
/// widget ngoài màn hình chính). Chủ ý KHÔNG dựng một FlutterActivity thứ
/// hai: mỗi engine Flutter tốn vài chục MB RAM, và widget trên Android
/// không cho phép gõ trực tiếp vào RemoteViews — phải luôn mở một Activity
/// thật, nên dùng lại đúng Activity (và đúng engine, nếu app đang mở sẵn)
/// là đủ.
///
/// (SỬA LỖI — tiện ích không đặt được, bấm vào lại mở thẳng app) Trước đây
/// đường "config" chỉ nhận ra qua Intent extra `widgetAction` tự đặt —
/// NHƯNG Intent THẬT mà Android tự gửi tới khi vừa thả widget vào màn hình
/// chính (`ACTION_APPWIDGET_CONFIGURE`, kèm `EXTRA_APPWIDGET_ID`) KHÔNG hề
/// có extra đó — chỉ app TỰ TẠO Intent đó mới có (nút "Ghi nhanh" trên
/// widget, xem `GhiNhanhWidgetProvider`). Do đó Dart luôn hiểu lầm lúc hệ
/// thống mở màn hình cấu hình là "mở bình thường", mở thẳng app — và vì
/// màn hình cấu hình không bao giờ chạy, `setResult()`/`finish()` cũng
/// không bao giờ được gọi, Android treo chờ rồi HUỶ việc đặt widget khi
/// người dùng thoát ra. Sửa: nhận "config" bằng đúng `intent.action` thật
/// của hệ thống, không dựa vào extra tự đặt nữa.
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
                    val idWidget = intent?.getIntExtra(
                        AppWidgetManager.EXTRA_APPWIDGET_ID,
                        AppWidgetManager.INVALID_APPWIDGET_ID,
                    ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
                    // "config" đọc từ ACTION thật của hệ thống — KHÔNG phải
                    // extra tự đặt (xem chú thích sửa lỗi ở đầu tệp). "quick"
                    // vẫn đọc extra tự đặt vì Intent đó do CHÍNH app tạo ra
                    // (nút "Ghi nhanh" trên widget), toàn quyền kiểm soát.
                    val hanhDong = when {
                        intent?.action == AppWidgetManager.ACTION_APPWIDGET_CONFIGURE -> "config"
                        intent?.getStringExtra("widgetAction") == "quick" -> "quick"
                        else -> null
                    }
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

                // (SỬA LỖI CÙNG ĐỢT) Người dùng bấm Back/huỷ ở bộ chọn ghi
                // chú trong màn hình cấu hình — PHẢI tự gọi `finish()` ở
                // đây: `Navigator.pop` phía Dart không tự đóng được Activity
                // khi route đó là route DUY NHẤT (route gốc của app), nên
                // trước đây màn hình treo lại, không huỷ được việc đặt
                // widget. Không gọi `setResult` — mặc định là RESULT_CANCELED,
                // đúng hành vi Android mong đợi khi huỷ cấu hình.
                "huyCauHinh" -> {
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
