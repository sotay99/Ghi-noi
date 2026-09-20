import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:web_audio' as web_audio;

/// Đáy ghi âm cho web — `MediaRecorder` chuẩn của trình duyệt, nguyên văn
/// cách dò định dạng/khởi tạo đã kiểm chứng trên cả Android, PC/Mac và
/// iPhone ở `main_web_test.dart`. Dùng LẠI một `MediaStream` xin quyền một
/// lần cho nhiều thẻ liên tiếp — chỉ tạo `MediaRecorder` mới mỗi thẻ.
html.MediaStream? _luong;
html.MediaRecorder? _boGhi;
List<html.Blob> _doanHienTai = [];
Completer<(Uint8List, String)?>? _dangChoKetThuc;

// Phân tích mức âm CHỈ để vẽ sóng âm (song song với đường ghi thật của
// MediaRecorder, không đụng gì tới nó) — `MediaRecorder` không có API đọc
// mức âm, nên dùng Web Audio API (`AnalyserNode`) gắn vào ĐÚNG luồng đã xin
// quyền, đọc dữ liệu dạng sóng rồi tính RMS quy về 0..1.
web_audio.AudioContext? _bienDoiAm;
web_audio.AnalyserNode? _phanTichAm;

Future<bool> ghiAmTheKhoiTao() async {
  if (_luong != null) return true;
  final thietBiMedia = html.window.navigator.mediaDevices;
  if (thietBiMedia == null) return false;
  try {
    final luong = await thietBiMedia.getUserMedia({'audio': true});
    _luong = luong;
    try {
      final ctx = web_audio.AudioContext();
      final nguon = ctx.createMediaStreamSource(luong);
      final analyser = ctx.createAnalyser()..fftSize = 256;
      nguon.connectNode(analyser);
      _bienDoiAm = ctx;
      _phanTichAm = analyser;
    } catch (_) {
      // Sóng âm chỉ là hiệu ứng phụ — ghi âm thật vẫn chạy được dù việc
      // này lỗi (ví dụ trình duyệt cũ không có AudioContext).
    }
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
  _phanTichAm = null;
  unawaited(_bienDoiAm?.close());
  _bienDoiAm = null;
}

Future<void> ghiAmTheTamDung() async => _boGhi?.pause();

Future<void> ghiAmTheTiepTuc() async => _boGhi?.resume();

/// Mức âm 0..1 để vẽ sóng âm, lấy mẫu mỗi 200ms từ `AnalyserNode` (xem chú
/// thích tại nơi khai báo `_phanTichAm`). Không có analyser (lỗi lúc khởi
/// tạo) thì phát 0 liên tục — sóng âm phẳng nhưng ghi âm vẫn hoạt động.
Stream<double> ghiAmTheMucAm() {
  late StreamController<double> bo;
  Timer? gio;
  bo = StreamController<double>.broadcast(
    onListen: () {
      gio = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final analyser = _phanTichAm;
        if (analyser == null) {
          bo.add(0);
          return;
        }
        final so = analyser.frequencyBinCount ?? 128;
        final duLieu = Uint8List(so);
        analyser.getByteTimeDomainData(duLieu);
        var tong = 0.0;
        for (final b in duLieu) {
          final d = (b - 128) / 128;
          tong += d * d;
        }
        final rms = math.sqrt(tong / duLieu.length);
        bo.add(rms.clamp(0.0, 1.0));
      });
    },
    onCancel: () => gio?.cancel(),
  );
  return bo.stream;
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
