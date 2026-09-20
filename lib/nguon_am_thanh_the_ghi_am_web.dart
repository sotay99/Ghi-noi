import 'dart:html' as html;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'nguon_am_thanh_the_ghi_am.dart';

/// Xem giải thích ở `nguon_am_thanh_the_ghi_am.dart` — Blob URL thật, KHÔNG
/// dùng `BytesSource`/`setSourceBytes` trên web.
NguonPhatGhiAm taoNguonPhatGhiAm(Uint8List bytes, String mime) {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  return NguonPhatGhiAm(UrlSource(url), url);
}

void giaiPhongNguonPhatGhiAm(NguonPhatGhiAm nguon) {
  final url = nguon.urlDaTao;
  if (url != null) html.Url.revokeObjectUrl(url);
}
