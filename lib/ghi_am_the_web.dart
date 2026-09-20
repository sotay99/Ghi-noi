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

/// Dòng chẩn đoán kỹ thuật của lần ghi âm GẦN NHẤT kết thúc — chỉ để hiện
/// kèm thông báo lỗi "thất bại (không có dữ liệu)" ở `trang_soan_thao.dart`,
/// KHÔNG phải log ẩn: người dùng đọc được ngay trên màn hình, không cần mở
/// console — vì chưa chắc chắn nguyên nhân thật (đã thử đổi thứ tự định
/// dạng ưu tiên nhưng vẫn còn lỗi), cần dữ liệu THẬT từ máy người dùng thay
/// vì đoán tiếp trong bóng tối.
String? ghiAmTheChanDoanCuoi;

// GHI CHÚ: bản này CHƯA đọc được mức âm thật trên web để vẽ sóng âm nhấp
// nhô — `dart:web_audio` (Web Audio API) đã bị Flutter/Dart gỡ khỏi bộ
// thư viện web (build đỏ ngay khi thử dùng), và thay bằng `package:web`/
// `dart:js_interop` đòi thêm một phụ thuộc mới tôi chưa có cách tự kiểm
// chứng trên trình duyệt thật. Tạm phát mức 0 liên tục — sóng âm phẳng
// nhưng ghi âm thật (MediaRecorder) không hề bị ảnh hưởng, và hiệu ứng nền
// hồng/viền đỏ (không phụ thuộc mức âm) vẫn hoạt động đầy đủ.
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
  //
  // 'audio/webm' đứng ĐẦU, KHÔNG PHẢI 'audio/mp4' — dù Safari cần mp4, để
  // mp4 lên đầu lại làm hỏng ghi âm trên CHROME: nhiều bản Chrome
  // `isTypeSupported('audio/mp4')` trả về true (có hỗ trợ codec) nhưng
  // MediaRecorder ghi ra file mp4 RỖNG hoặc hỏng thật sự (lỗi đã biết của
  // Chromium, không phải lỗi ở đây) — ghi âm trông vẫn chạy bình thường
  // (đồng hồ chạy, không báo lỗi gì) nhưng lúc hoàn thành luôn ra 0 byte.
  // Safari không khai hỗ trợ 'audio/webm' (`isTypeSupported` trả về false)
  // nên vẫn tự rơi xuống đúng 'audio/mp4' như cũ, không mất gì.
  const cacDinhDangUuTien = [
    'audio/webm',
    'audio/mp4',
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
  final trackDau = luong.getAudioTracks().isNotEmpty ? luong.getAudioTracks().first : null;
  var soLanBanTinDoan = 0;
  var soLanDoanRong = 0;
  boGhi.addEventListener('dataavailable', (suKien) {
    soLanBanTinDoan++;
    final doan = (suKien as html.BlobEvent).data;
    if (doan != null && doan.size > 0) {
      _doanHienTai.add(doan);
    } else {
      soLanDoanRong++;
    }
  });
  boGhi.addEventListener('stop', (_) async {
    final loaiThuc = boGhi.mimeType;
    final mime = (loaiThuc == null || loaiThuc.isEmpty) ? 'audio/mp4' : loaiThuc;
    final blob = html.Blob(_doanHienTai, mime);
    final bytes = await _doiBlobSangBytes(blob);
    ghiAmTheChanDoanCuoi = 'định dạng chọn=$dinhDangDung, mime lúc dừng=$loaiThuc, '
        'số bản tin dữ liệu=$soLanBanTinDoan (rỗng=$soLanDoanRong), '
        'số đoạn dùng được=${_doanHienTai.length}, tổng byte=${bytes.length}, '
        'trạng thái track âm thanh=${trackDau?.readyState ?? "không có track"}, '
        'trạng thái bộ ghi lúc dừng=${boGhi.state}';
    // Lưới an toàn cho ĐÚNG lỗi vừa nêu ở trên (định dạng "có hỗ trợ" theo
    // isTypeSupported nhưng ghi ra rỗng thật) — dù đã đổi thứ tự ưu tiên để
    // tránh gặp lại, vẫn coi 0 byte là ghi âm thất bại thay vì gửi lên một
    // file rỗng coi như bình thường.
    _dangChoKetThuc?.complete(bytes.isEmpty ? null : (bytes, mime));
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

Future<void> ghiAmTheTamDung() async => _boGhi?.pause();

Future<void> ghiAmTheTiepTuc() async => _boGhi?.resume();

/// Xem GHI CHÚ ở đầu file — chưa đọc được mức âm thật trên web, phát 0
/// liên tục (sóng âm phẳng, không ảnh hưởng gì tới việc ghi âm thật).
Stream<double> ghiAmTheMucAm() {
  late StreamController<double> bo;
  Timer? gio;
  bo = StreamController<double>.broadcast(
    onListen: () => gio = Timer.periodic(
        const Duration(milliseconds: 200), (_) => bo.add(0)),
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
