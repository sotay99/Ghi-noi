// Xuất một tệp NHỊ PHÂN tuỳ ý (ví dụ .zip) ra ngoài app — CÓ ĐIỀU KIỆN,
// cùng vai trò với `lib/tai_ve_ghi_chu.dart` nhưng nhận bytes thay vì văn
// bản. Web: tải thẳng xuống trình duyệt. APK/iOS: qua màn hình chia sẻ của
// máy.
export 'luu_va_chia_se_tep_web.dart' if (dart.library.io) 'luu_va_chia_se_tep_io.dart';
