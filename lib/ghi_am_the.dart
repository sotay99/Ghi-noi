// Đáy ghi âm cho cơ chế thẻ — xuất bản CÓ ĐIỀU KIỆN: mặc định (web) dùng
// MediaRecorder qua dart:html (đã kiểm chứng trên cả Android/PC/iPhone-web
// ở main_web_test.dart); khi dart:io có sẵn (Android/iOS gốc) dùng package
// `record` (đã kiểm chứng ở ghi_am_ai_io.dart cũ). Cả hai bên cùng expose 4
// hàm giống nhau — xem chữ ký ở ghi_am_the_web.dart/ghi_am_the_io.dart:
//   Future<bool> ghiAmTheKhoiTao()
//   Future<void> ghiAmTheBatDauThe()
//   Future<(Uint8List, String)?> ghiAmTheKetThucThe()
//   Future<void> ghiAmTheDongHan()
export 'ghi_am_the_web.dart' if (dart.library.io) 'ghi_am_the_io.dart';
