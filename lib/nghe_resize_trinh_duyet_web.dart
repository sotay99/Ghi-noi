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

/// (SỬA LỖI v121, CẬP NHẬT v123 — "bãi đất trống" đỡ hẳn nhưng vẫn còn,
/// người dùng xác nhận: trước đây phải bấm RẤT NHIỀU nút hoặc tải lại
/// trang mới hết; sau v121 chỉ cần bấm MỘT nút bất kỳ là hết ngay) Bản v121
/// so sánh `visualViewport.height`/`innerHeight` giữa hai lần đo, chỉ gọi
/// lại khi THẤY LỆCH — nhưng việc "chỉ cần bấm một nút là hết" (bất kỳ nút
/// nào, vì hầu hết đều gọi `setState`) cho thấy rõ: `MediaQuery` nội bộ của
/// Flutter vẫn đã CÓ giá trị `viewInsets.bottom` MỚI, ĐÚNG — chỉ là KHÔNG
/// có gì kích `setState` để Flutter vẽ lại theo giá trị đó. Tức là chính
/// phép đo JS hai lớp cũ (`didChangeMetrics` lẫn so sánh chiều cao) đã
/// "đo hụt" — số đo JS không hề đổi trong đúng tình huống này (có thể do
/// trình duyệt không cập nhật `visualViewport`/`innerHeight` cho đường ẩn
/// bàn phím ảo qua nút Back, dù Flutter Engine vẫn tự biết `viewInsets`
/// mới qua đường khác). Bỏ hẳn việc SO SÁNH một số đo có thể "đứng im sai"
/// — thay bằng một "nhịp tim" ép `setState` ĐỀU ĐẶN, không điều kiện, mỗi
/// 300ms, đúng những việc một nút bấm tình cờ làm được. Chấp nhận đổi lấy
/// một lượt build rỗng mỗi 300ms (rẻ — Flutter tự bỏ qua phần không đổi)
/// để không còn phụ thuộc vào BẤT KỲ tín hiệu nào về việc viewport đã đổi.
Object dangKyThamDoChieuCaoVienPort(void Function() goiLai) {
  return Timer.periodic(const Duration(milliseconds: 300), (_) => goiLai());
}

void huyThamDoChieuCaoVienPort(Object? dangKy) {
  if (dangKy is Timer) dangKy.cancel();
}
