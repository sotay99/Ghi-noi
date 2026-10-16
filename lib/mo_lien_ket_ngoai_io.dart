import 'package:url_launcher/url_launcher.dart';

/// Trên Android/iOS/desktop gốc — mở [url] bằng trình duyệt/app ngoài của
/// hệ thống (`LaunchMode.externalApplication`). Trước đây tệp này chỉ là
/// bản giữ chỗ (không làm gì cả) vì dải gợi ý "Tải app APK" — nơi gọi hàm
/// này ĐẦU TIÊN — chỉ hiện trên web; giờ nút "Mở link" của gạch chân xanh
/// dương (xem `trang_soan_thao.dart`) cũng gọi đúng hàm này, cần nó THẬT SỰ
/// mở được link trên APK. Mất mạng/không có app xử lý thì `launchUrl` tự
/// trả `false`, lặng lẽ bỏ qua — không ném lỗi làm sập trang.
void moLienKetNgoai(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  launchUrl(uri, mode: LaunchMode.externalApplication);
}
