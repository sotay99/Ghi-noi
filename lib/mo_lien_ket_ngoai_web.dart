import 'dart:html' as html;

/// Mở [url] ở một tab mới của trình duyệt — dùng cho dải gợi ý "Tải app
/// APK" (chỉ có ý nghĩa trên web).
void moLienKetNgoai(String url) {
  html.window.open(url, '_blank');
}
