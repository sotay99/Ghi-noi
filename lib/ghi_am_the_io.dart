import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'ket_qua_ghi_am_the.dart';

/// Đáy ghi âm cho Android/iOS gốc — dùng package `record` (đã chạy tốt
/// trong `ghi_am_ai_io.dart` cũ, nay tái dùng cùng cấu hình encoder cho cơ
/// chế thẻ mới). Ghi ra một tệp tạm mỗi thẻ (record không hỗ trợ đổi tệp
/// giữa lúc đang ghi), đọc bytes rồi xoá tệp tạm ngay.
final AudioRecorder _may = AudioRecorder();
String? _duongDanHienTai;

/// Cùng vai trò với biến cùng tên ở `ghi_am_the_web.dart` (đọc chú thích ở
/// đó) — trên Android/iOS gốc CHƯA từng thấy lỗi "không có dữ liệu" thật
/// nên chỉ ghi vắn tắt, không cần chi tiết như bên web.
String? ghiAmTheChanDoanCuoi;

Future<bool> ghiAmTheKhoiTao() => _may.hasPermission();

Future<void> ghiAmTheBatDauThe() async {
  final thuMuc = await getTemporaryDirectory();
  final duongDan =
      '${thuMuc.path}/the_ghi_am_${DateTime.now().millisecondsSinceEpoch}.m4a';
  _duongDanHienTai = duongDan;
  await _may.start(
    const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 32000,
      sampleRate: 22050,
      numChannels: 1,
    ),
    path: duongDan,
  );
}

Future<KetQuaGhiAmThe?> ghiAmTheKetThucThe() async {
  final duongDanTuStop = await _may.stop();
  final duongDan = duongDanTuStop ?? _duongDanHienTai;
  _duongDanHienTai = null;
  if (duongDan == null) {
    ghiAmTheChanDoanCuoi = 'record.stop() không trả đường dẫn tệp';
    return null;
  }
  final tep = File(duongDan);
  if (!await tep.exists()) {
    ghiAmTheChanDoanCuoi = 'tệp tạm không tồn tại: $duongDan';
    return null;
  }
  final bytes = await tep.readAsBytes();
  await tep.delete().catchError((_) => tep);
  if (bytes.isEmpty) {
    ghiAmTheChanDoanCuoi = 'tệp tạm tồn tại nhưng rỗng (0 byte)';
    return null;
  }
  ghiAmTheChanDoanCuoi = null;
  return KetQuaGhiAmThe(bytes, 'audio/mp4');
}

Future<void> ghiAmTheDongHan() async {
  if (await _may.isRecording()) {
    await _may.stop();
  }
  _duongDanHienTai = null;
}

Future<void> ghiAmTheTamDung() => _may.pause();

Future<void> ghiAmTheTiepTuc() => _may.resume();

/// Mức âm 0..1 để vẽ sóng âm — `record` đã có sẵn qua `onAmplitudeChanged`
/// (nguyên văn nguồn dữ liệu đã dùng ở `ghi_am_ai_io.dart` cũ). dBFS âm rất
/// sâu (~-160 im lặng) tới 0 (to nhất) — ép về 0..1, coi dưới -60dB là 0.
Stream<double> ghiAmTheMucAm() => _may
    .onAmplitudeChanged(const Duration(milliseconds: 200))
    .map((m) => ((m.current + 60) / 60).clamp(0.0, 1.0));
