import 'dart:async';
import 'dart:html' as html;

/// (SỬA LỖI "bãi đất trống" kẹt lại sau khi ẩn bàn phím ảo) Nghe THẲNG sự
/// kiện resize của TRÌNH DUYỆT (`window.onResize`) — bỏ qua tầng dịch lại
/// của Flutter Engine (`WidgetsBindingObserver.didChangeMetrics`, đã thử
/// trước đây nhưng không ăn thua: có những đường ẩn bàn phím ảo — đặc biệt
/// qua nút Back của Android — mà Flutter Engine không dịch lại thành sự
/// kiện `didChangeMetrics` cho code Dart, nên nghe qua tầng đó là nghe
/// "hụt"). Đây là một đường nghe ĐỘC LẬP, thẳng từ trình duyệt, không đi
/// qua Flutter Engine.
///
/// Trả về [StreamSubscription] đã đăng ký — giữ lại để huỷ đúng lúc
/// `dispose()` (xem `huyNgheResizeTrinhDuyet`).
Object dangKyNgheResizeTrinhDuyet(void Function() goiLai) {
  return html.window.onResize.listen((_) => goiLai());
}

void huyNgheResizeTrinhDuyet(Object? dangKy) {
  if (dangKy is StreamSubscription) dangKy.cancel();
}
