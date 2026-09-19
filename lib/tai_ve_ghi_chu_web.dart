import 'dart:convert';
import 'dart:html' as html;

/// Xuất ghi chú thành tệp .txt — bản web, không có "chia sẻ" hệ điều hành
/// nên tải thẳng xuống máy qua cơ chế tải tệp chuẩn của trình duyệt
/// (Blob + thẻ <a download>).
Future<void> luuVaChiaSeGhiChu(
    String tenTep, String noiDung, String tieuDe) async {
  final bytes = utf8.encode(noiDung);
  final blob = html.Blob([bytes], 'text/plain;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', tenTep)
    ..click();
  html.Url.revokeObjectUrl(url);
}
