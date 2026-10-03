import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Bản Android/iOS/desktop — lưu tạm rồi mở màn hình chia sẻ của máy, cùng
/// cơ chế `tai_ve_ghi_chu_io.dart` đã dùng.
Future<void> luuVaChiaSeTep(
  String tenTep,
  Uint8List bytes, {
  String loaiMime = 'application/octet-stream',
}) async {
  final thuMucTam = await getTemporaryDirectory();
  final tep = File('${thuMucTam.path}/$tenTep');
  await tep.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(tep.path)], subject: tenTep),
  );
}
