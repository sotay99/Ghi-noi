// Cảnh báo trước khi rời trang (F5, đóng tab, đóng trình duyệt, điều hướng
// sang trang khác) khi còn thay đổi CHƯA LƯU — chỉ có ý nghĩa trên web (khái
// niệm "đóng tab" không tồn tại trên Android/iOS gốc). Xuất bản CÓ ĐIỀU
// KIỆN như mọi lớp vỏ riêng nền tảng khác trong app này.
export 'canh_bao_roi_trang_web.dart'
    if (dart.library.io) 'canh_bao_roi_trang_io.dart';
