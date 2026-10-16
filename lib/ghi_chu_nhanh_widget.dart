// Bọc kênh `flowrite/widget` (xem `tool/android_widget/MainActivity.kt`) —
// cầu nối Dart↔native cho widget "Ghi nhanh" ở màn hình chính Android.
// CHỈ có ý nghĩa trên Android gốc (`!kIsWeb`); gọi trên web/APK không có
// kênh này sẽ tự `catch` về giá trị an toàn (không ném lỗi ra ngoài).
import 'package:flutter/services.dart';

const _kenh = MethodChannel('flowrite/widget');

/// Lý do Activity này đang được mở — đọc Intent extra lúc khởi động.
/// `null` nghĩa là mở HOÀN TOÀN BÌNH THƯỜNG (bấm icon app, hoặc nút "Mở
/// app" của widget) — luồng khởi động cũ chạy tiếp y như trước, không đụng
/// gì cả.
class YeuCauMoTuWidget {
  YeuCauMoTuWidget({required this.hanhDong, required this.idWidget});

  /// `'config'` (hệ thống tự mở lúc vừa đặt widget lên màn hình chính) hoặc
  /// `'quick'` (người dùng bấm nút "Ghi nhanh" trên widget).
  final String hanhDong;
  final int idWidget;
}

Future<YeuCauMoTuWidget?> docYeuCauMoTuWidget() async {
  try {
    final j = await _kenh.invokeMethod('layYeuCauMo');
    if (j is! Map) return null;
    final hanhDong = j['hanhDong'];
    final idWidget = j['idWidget'];
    if (hanhDong is! String || idWidget is! int) return null;
    return YeuCauMoTuWidget(hanhDong: hanhDong, idWidget: idWidget);
  } catch (_) {
    return null;
  }
}

/// Lưu mục tiêu (ghi chú NỘI BỘ, xem giới hạn ở `ManHinhWidgetCauHinh`) của
/// một widget cụ thể. [ten] chỉ để hiện lại cho người dùng xem ở màn hình
/// cấu hình lần sau (không dùng để tra cứu — tra cứu luôn bằng [ghiChuId]).
Future<void> luuMucTieuWidget({
  required int idWidget,
  required String ghiChuId,
  required String ten,
}) async {
  try {
    await _kenh.invokeMethod('luuMucTieuWidget', {
      'idWidget': idWidget,
      'ghiChuId': ghiChuId,
      'ten': ten,
    });
  } catch (_) {
    // Không có kênh (đang chạy trên web/thiết bị khác) — bỏ qua im lặng.
  }
}

class MucTieuWidget {
  MucTieuWidget({required this.ghiChuId, required this.ten});
  final String ghiChuId;
  final String ten;
}

Future<MucTieuWidget?> docMucTieuWidget(int idWidget) async {
  try {
    final j = await _kenh.invokeMethod('docMucTieuWidget', {'idWidget': idWidget});
    if (j is! Map) return null;
    final ghiChuId = j['ghiChuId'];
    if (ghiChuId is! String) return null;
    return MucTieuWidget(ghiChuId: ghiChuId, ten: (j['ten'] as String?) ?? '');
  } catch (_) {
    return null;
  }
}

/// Báo cho hệ thống Android biết màn hình cấu hình đã xong (BẮT BUỘC, nếu
/// không widget bị huỷ ngay khi rời Activity) và tự đóng Activity lại.
Future<void> hoanTatCauHinhWidget(int idWidget) async {
  try {
    await _kenh.invokeMethod('hoanTatCauHinh', {'idWidget': idWidget});
  } catch (_) {
    // Không có kênh — không có gì để báo, bỏ qua.
  }
}

/// Người dùng bấm Back/huỷ ở bộ chọn ghi chú trong màn hình cấu hình —
/// tự đóng Activity (mặc định RESULT_CANCELED, đúng ý "huỷ đặt widget").
/// `Navigator.pop` ở Dart không tự làm được việc này vì đây là route GỐC
/// của app, không có gì để pop lên.
Future<void> huyCauHinhWidget() async {
  try {
    await _kenh.invokeMethod('huyCauHinh');
  } catch (_) {
    // Không có kênh — bỏ qua.
  }
}
