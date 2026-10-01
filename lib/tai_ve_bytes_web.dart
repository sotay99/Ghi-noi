import 'dart:html' as html;
import 'dart:typed_data';

/// Tải tệp nhị phân xuống máy — bản web, qua cơ chế tải tệp chuẩn của
/// trình duyệt (Blob + thẻ <a download>), y hệt `tai_ve_ghi_chu_web.dart`
/// nhưng nhận thẳng [bytes] thay vì chuỗi văn bản.
Future<void> taiVeBytes(Uint8List bytes, String tenTep, String mime) async {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', tenTep)
    ..click();
  html.Url.revokeObjectUrl(url);
}
