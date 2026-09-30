// Xuất bản CÓ ĐIỀU KIỆN: mặc định (web) đọc/ghi clipboard hệ thống với cả
// `text/html` (không chỉ `text/plain` như `Clipboard` của Flutter), còn khi
// `dart:io` có sẵn (Android/iOS/desktop) dùng bản giữ chỗ luôn trả về
// thất bại/rỗng — những nền tảng đó tiếp tục dán/copy chữ thô hệt trước giờ
// qua `Clipboard` (package:flutter/services.dart), không đổi gì.
//
// CHỈ dùng cho "Copy"/"Cắt"/"Dán" ở hàng công cụ riêng của Flowrite (xem
// `_phimAoCopy`/`_phimAoCut`/`_phimAoPaste` trong `trang_soan_thao.dart`) —
// KHÔNG đụng vào đường dán/copy TỰ NHIÊN của trình duyệt (Ctrl+C/V, menu
// chuột phải) vốn do chính Flutter tự xử lý sẵn, giữ nguyên hành vi cũ.
export 'dinh_dang_clip_web.dart' if (dart.library.io) 'dinh_dang_clip_io.dart';
