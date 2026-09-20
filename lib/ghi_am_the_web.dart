import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Đáy ghi âm cho web — `MediaRecorder` chuẩn của trình duyệt, nguyên văn
/// cách dò định dạng/khởi tạo đã kiểm chứng trên cả Android, PC/Mac và
/// iPhone ở `main_web_test.dart`. Dùng LẠI một `MediaStream` xin quyền một
/// lần cho nhiều thẻ liên tiếp — chỉ tạo `MediaRecorder` mới mỗi thẻ.
html.MediaStream? _luong;
html.MediaRecorder? _boGhi;
List<html.Blob> _doanHienTai = [];
Completer<(Uint8List, String)?>? _dangChoKetThuc;

Future<bool> ghiAmTheKhoiTao() async {
  if (_luong != null) return true;
  final thietBiMedia = html.window.navigator.mediaDevices;
  if (thietBiMedia == null) return false;
  try {
    _luong = await thietBiMedia.getUserMedia({'audio': true});
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> ghiAmTheBatDauThe() async {
  final luong = _luong;
  if (luong == null) return;
  // Safari/WebKit KHÔNG hỗ trợ 'audio/webm' (mặc định của Chrome) — dò định
  // dạng trình duyệt THỰC SỰ hỗ trợ trước khi ghi, không ép cứng một loại.
  const cacDinhDangUuTien = [
    'audio/mp4',
    'audio/webm',
    'audio/ogg',
    'audio/wav',
  ];
  String? dinhDangDung;
  for (final dd in cacDinhDangUuTien) {
    if (html.MediaRecorder.isTypeSupported(dd)) {
      dinhDangDung = dd;
      break;
    }
  }
  final boGhi = dinhDangDung == null
      ? html.MediaRecorder(luong)
      : html.MediaRecorder(luong, {'mimeType': dinhDangDung});
  _doanHienTai = [];
  _boGhi = boGhi;
  boGhi.addEventListener('dataavailable', (suKien) {
    final doan = (suKien as html.BlobEvent).data;
    if (doan != null && doan.size > 0) _doanHienTai.add(doan);
  });
  boGhi.addEventListener('stop', (_) async {
    final loaiThuc = boGhi.mimeType;
    final mime = (loaiThuc == null || loaiThuc.isEmpty) ? 'audio/mp4' : loaiThuc;
    final blob = html.Blob(_doanHienTai, mime);
    final bytes = await _doiBlobSangBytes(blob);
    _dangChoKetThuc?.complete((bytes, mime));
    _dangChoKetThuc = null;
  });
  boGhi.start();
}

Future<(Uint8List, String)?> ghiAmTheKetThucThe() async {
  final boGhi = _boGhi;
  if (boGhi == null) return null;
  final cho = Completer<(Uint8List, String)?>();
  _dangChoKetThuc = cho;
  boGhi.stop();
  _boGhi = null;
  return cho.future;
}

Future<void> ghiAmTheDongHan() async {
  _boGhi?.stop();
  _boGhi = null;
  for (final track in _luong?.getTracks() ?? const []) {
    track.stop();
  }
  _luong = null;
}

Future<Uint8List> _doiBlobSangBytes(html.Blob blob) {
  final doc = html.FileReader();
  final xong = Completer<Uint8List>();
  doc.onLoadEnd.listen((_) {
    final ketQua = doc.result as ByteBuffer;
    xong.complete(ketQua.asUint8List());
  });
  doc.onError.listen((e) => xong.completeError(e));
  doc.readAsArrayBuffer(blob);
  return xong.future;
}
