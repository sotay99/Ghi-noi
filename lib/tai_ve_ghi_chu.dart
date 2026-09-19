// Xuất bản CÓ ĐIỀU KIỆN: mặc định (web) tải tệp .txt xuống trình duyệt,
// còn khi `dart:io` có sẵn (Android/iOS/desktop) dùng bản thật đi qua màn
// hình chia sẻ của máy — xem `tai_ve_ghi_chu_web.dart`/`tai_ve_ghi_chu_io.dart`.
export 'tai_ve_ghi_chu_web.dart' if (dart.library.io) 'tai_ve_ghi_chu_io.dart';
