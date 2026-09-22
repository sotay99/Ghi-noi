// Xuất bản CÓ ĐIỀU KIỆN: mặc định (web) nghe thẳng sự kiện resize của
// trình duyệt (`dart:html`), còn khi `dart:io` có sẵn (Android/iOS/desktop)
// dùng bản giữ chỗ (không làm gì cả — khái niệm "viewport trình duyệt"
// không có ý nghĩa gì trên các nền tảng đó).
export 'nghe_resize_trinh_duyet_web.dart' if (dart.library.io) 'nghe_resize_trinh_duyet_io.dart';
