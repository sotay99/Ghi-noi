import 'dart:html' as html;

/// Tên hiển thị cho "phím Windows" tuỳ hệ điều hành đang chạy trình duyệt —
/// macOS gọi phím này là Cmd (⌘), các hệ khác gọi là phím Windows (⊞). Chỉ
/// đoán được trên web (đọc User-Agent, giống `doanThietBi()`).
String tenPhimWinTheoNenTang() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  if (ua.contains('mac')) return 'Cmd (⌘)';
  return 'Windows (⊞)';
}
