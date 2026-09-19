// Xuất bản CÓ ĐIỀU KIỆN: mặc định (web) đọc User-Agent bằng `dart:html`,
// còn khi `dart:io` có sẵn (Android/iOS/desktop) dùng bản giữ chỗ (giá trị
// trả về không được đọc ở đâu trên các nền tảng đó).
export 'doan_thiet_bi_web.dart' if (dart.library.io) 'doan_thiet_bi_io.dart';
