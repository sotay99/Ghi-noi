// (YÊU CẦU MỚI — mục "Chia sẻ ứng dụng") Xuất bản CÓ ĐIỀU KIỆN: bản web gọi
// Web Share API thật qua `dart:js_util` (đúng pattern `dinh_dang_clip_web
// .dart`), bản gốc (Android/iOS/desktop, có `dart:io`) dùng `share_plus`
// (đã có sẵn trong app cho việc chia sẻ tệp) mở màn hình chia sẻ hệ thống
// thật. Cả hai trả `true` khi đã mở được màn hình chia sẻ; bản WEB CHỈ trả
// `false` khi trình duyệt không hỗ trợ `navigator.share` — nơi gọi
// (`trang_soan_thao.dart`) khi đó tự rơi về phương án dự phòng (copy link
// vào bộ nhớ tạm).
export 'chia_se_ung_dung_web.dart' if (dart.library.io) 'chia_se_ung_dung_io.dart';
