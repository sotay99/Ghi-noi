import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Xuất ghi chú thành tệp .txt tạm rồi mở màn hình chia sẻ của máy — bản
/// Android/iOS/desktop, dùng `dart:io` thật.
Future<void> luuVaChiaSeGhiChu(
    String tenTep, String noiDung, String tieuDe) async {
  final thuMucTam = await getTemporaryDirectory();
  final tep = File('${thuMucTam.path}/$tenTep');
  await tep.writeAsString(noiDung, encoding: utf8);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(tep.path)], subject: tieuDe),
  );
}
