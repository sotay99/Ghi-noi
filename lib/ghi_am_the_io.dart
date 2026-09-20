import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Đáy ghi âm cho Android/iOS gốc — dùng package `record` (đã chạy tốt
/// trong `ghi_am_ai_io.dart` cũ, nay tái dùng cùng cấu hình encoder cho cơ
/// chế thẻ mới). Ghi ra một tệp tạm mỗi thẻ (record không hỗ trợ đổi tệp
/// giữa lúc đang ghi), đọc bytes rồi xoá tệp tạm ngay.
final AudioRecorder _may = AudioRecorder();
String? _duongDanHienTai;

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

Future<(Uint8List, String)?> ghiAmTheKetThucThe() async {
  final duongDanTuStop = await _may.stop();
  final duongDan = duongDanTuStop ?? _duongDanHienTai;
  _duongDanHienTai = null;
  if (duongDan == null) return null;
  final tep = File(duongDan);
  if (!await tep.exists()) return null;
  final bytes = await tep.readAsBytes();
  await tep.delete().catchError((_) => tep);
  return (bytes, 'audio/mp4');
}

Future<void> ghiAmTheDongHan() async {
  if (await _may.isRecording()) {
    await _may.stop();
  }
  _duongDanHienTai = null;
}
