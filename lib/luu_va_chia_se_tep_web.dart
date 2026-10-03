import 'dart:html' as html;
import 'dart:typed_data';

/// Bản web — tải thẳng xuống máy qua cơ chế tải tệp chuẩn của trình duyệt
/// (Blob + thẻ <a download>), cùng cơ chế `tai_ve_ghi_chu_web.dart` đã dùng.
Future<void> luuVaChiaSeTep(
  String tenTep,
  Uint8List bytes, {
  String loaiMime = 'application/octet-stream',
}) async {
  final blob = html.Blob([bytes], loaiMime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', tenTep)
    ..click();
  html.Url.revokeObjectUrl(url);
}
