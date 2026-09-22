// Xuất bản CÓ ĐIỀU KIỆN: mặc định (web) mở tab mới bằng `dart:html`, còn
// khi `dart:io` có sẵn (Android/iOS/desktop) dùng bản giữ chỗ (không làm
// gì cả — nơi gọi hàm này chỉ có ý nghĩa trên web, xem `_daiGoiYTaiApk`).
export 'mo_lien_ket_ngoai_web.dart' if (dart.library.io) 'mo_lien_ket_ngoai_io.dart';
