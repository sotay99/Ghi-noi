import 'dart:async';
import 'dart:html' as html;

StreamSubscription<html.Event>? _dangKy;

/// Đăng ký (một lần) cảnh báo "rời trang?" của chính trình duyệt khi
/// [conThayDoiChuaLuu] trả `true` lúc người dùng bấm F5/đóng tab/đóng trình
/// duyệt/điều hướng sang địa chỉ khác. KHÔNG tự viết được nội dung câu hỏi —
/// mọi trình duyệt hiện đại (từ ~2016) đều CẤM web đặt chữ tuỳ ý cho hộp
/// thoại này (chặn kiểu lừa/doạ người dùng ở lại trang), luôn hiện đúng câu
/// cố định của chính trình duyệt bất kể `returnValue` được gán gì. Gọi lại
/// hàm này nhiều lần chỉ đăng ký lại (không chồng nhiều người nghe).
void datCanhBaoRoiTrangNeuChuaLuu(bool Function() conThayDoiChuaLuu) {
  _dangKy?.cancel();
  _dangKy = html.window.onBeforeUnload.listen((html.Event e) {
    if (!conThayDoiChuaLuu()) return;
    e.preventDefault();
    if (e is html.BeforeUnloadEvent) e.returnValue = '';
  });
}
