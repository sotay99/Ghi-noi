// Bảng "Ghi âm xong mới ra chữ" của app Android dùng `dart:io`/`record`/
// `path_provider` — ba thứ không có trên web. Xuất bản CÓ ĐIỀU KIỆN: mặc
// định (web) dùng bản giữ chỗ `ghi_am_ai_web.dart`, còn khi `dart:io` có
// sẵn (Android/iOS/desktop) tự động dùng bản thật `ghi_am_ai_io.dart` —
// không đổi hành vi của app Android.
export 'ghi_am_ai_web.dart' if (dart.library.io) 'ghi_am_ai_io.dart';
