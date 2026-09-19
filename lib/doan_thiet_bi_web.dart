import 'dart:html' as html;

import 'loai_thiet_bi.dart';

/// Đoán thiết bị bằng User-Agent — chỉ dùng làm giá trị GỢI Ý ban đầu,
/// người dùng luôn chuyển tay được trong Cài đặt nếu đoán sai. Nguyên văn
/// logic đã kiểm chứng ở `main_web_test.dart` (`_doanThietBi`).
ThietBi doanThietBi() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  // iOS trước Android/mobile: iPad ở chế độ "Desktop site" vẫn có thể lẫn
  // chữ "mobile", nhưng chữ "iphone"/"ipad" luôn xuất hiện trên iOS thật.
  if (ua.contains('iphone') || ua.contains('ipad')) return ThietBi.iphone;
  if (ua.contains('android') || ua.contains('mobile')) return ThietBi.android;
  return ThietBi.pc;
}
