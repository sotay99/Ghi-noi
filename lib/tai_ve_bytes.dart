// Tải một tệp NHỊ PHÂN (bytes) về máy — dùng cho "Tải file ghi âm về máy"
// ở modal nghe lại (`modal_nghe_lai_ghi_am.dart`). CÓ ĐIỀU KIỆN giống hệt
// `tai_ve_ghi_chu.dart`: mặc định (web) tải thẳng xuống trình duyệt, còn
// khi `dart:io` có sẵn (Android/iOS/desktop) dùng màn hình chia sẻ của máy.
export 'tai_ve_bytes_web.dart' if (dart.library.io) 'tai_ve_bytes_io.dart';
