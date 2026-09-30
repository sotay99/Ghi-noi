/// Bản giữ chỗ cho Android/iOS/desktop — clipboard giàu định dạng
/// (`text/html`, xem `dinh_dang_clip_web.dart`) chỉ có ý nghĩa trên web, vì
/// `Clipboard` gốc của Flutter trên các nền tảng này không có cách ghi/đọc
/// nhiều kiểu MIME cùng lúc mà không thêm gói phụ thuộc mới. Luôn thất bại
/// một cách an toàn — nơi gọi (`_phimAoCopy`/`_phimAoCut`/`_phimAoPaste`)
/// tự rơi về `Clipboard` chữ thô hệt trước giờ.
Future<bool> ghiClipboardCoDinhDang(String vanBanTho, String htmlNoiDung) async => false;

Future<String?> docHtmlTuClipboard() async => null;
