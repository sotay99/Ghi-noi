import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'nguon_am_thanh_the_ghi_am.dart';

/// Android/iOS gốc — `BytesSource` hoạt động ổn định, không cần Blob URL.
NguonPhatGhiAm taoNguonPhatGhiAm(Uint8List bytes, String mime) {
  return NguonPhatGhiAm(BytesSource(bytes, mimeType: mime), null);
}

void giaiPhongNguonPhatGhiAm(NguonPhatGhiAm nguon) {}
