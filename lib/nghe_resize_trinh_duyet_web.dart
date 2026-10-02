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

/// (SỬA LỖI v121 — "bãi đất trống" vẫn kẹt dù đã có HAI lớp nghe sự kiện ở
/// trên) Cả `didChangeMetrics` (Flutter Engine) lẫn `window.onResize` (nghe
/// thẳng trình duyệt) đều là nghe THEO SỰ KIỆN — và đã xác nhận có đường ẩn
/// bàn phím ảo (đặc biệt qua nút Back của Android) không bắn ra MỘT TRONG
/// HAI sự kiện đó, vì trình duyệt coi đây không phải "resize" theo nghĩa
/// của nó. Tư duy mới, cùng gốc với cách đã sửa dứt điểm lỗi kẹt bàn phím
/// ảo ở Copy/Cắt/Dán/All: ĐỪNG tiếp tục tin một sự kiện có thể không bắn
/// ra — chủ động TỰ HỎI trình duyệt "chiều cao thật của viewport bây giờ
/// là bao nhiêu" theo nhịp đều, so với lần hỏi gần nhất, lệch thì mới gọi
/// lại. Gần như luôn KHÔNG lệch (chỉ một phép đọc `visualViewport.height`
/// và so sánh số mỗi 300ms), nên không có `setState` nào xảy ra khi không
/// cần — chỉ khi THẬT SỰ có đổi (đúng lúc "bãi đất trống" xuất hiện) thì
/// mới gọi `goiLai()` để dựng lại đúng kích thước, không cần đợi một nút
/// bấm nào khác tình cờ gọi `setState` mới lộ ra bản mới, và không cần
/// trông chờ một sự kiện có thể không tới.
///
/// `visualViewport` chính xác hơn `window.innerHeight` khi bàn phím ảo
/// đang che một phần màn hình (một số trình duyệt KHÔNG đổi `innerHeight`
/// lúc bàn phím ảo hiện/ẩn, chỉ đổi `visualViewport`) — ưu tiên nó, chỉ
/// lùi về `innerHeight` nếu trình duyệt không hỗ trợ.
Object dangKyThamDoChieuCaoVienPort(void Function() goiLai) {
  double? truoc = _docChieuCaoVienPortThat();
  return Timer.periodic(const Duration(milliseconds: 300), (_) {
    final hienTai = _docChieuCaoVienPortThat();
    if (hienTai != truoc) {
      truoc = hienTai;
      goiLai();
    }
  });
}

double? _docChieuCaoVienPortThat() =>
    html.window.visualViewport?.height ?? html.window.innerHeight?.toDouble();

void huyThamDoChieuCaoVienPort(Object? dangKy) {
  if (dangKy is Timer) dangKy.cancel();
}
