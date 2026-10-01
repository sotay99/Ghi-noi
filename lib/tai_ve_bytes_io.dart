import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Tải tệp nhị phân xuống máy — bản Android/iOS/desktop: ghi ra tệp tạm rồi
/// mở màn hình chia sẻ của máy (không có khái niệm "thư mục Tải xuống" dùng
/// chung mọi nền tảng, chia sẻ là đường chắc ăn nhất — y hệt cách
/// `tai_ve_ghi_chu_io.dart` xuất ghi chú .txt).
Future<void> taiVeBytes(Uint8List bytes, String tenTep, String mime) async {
  final thuMucTam = await getTemporaryDirectory();
  final tep = File('${thuMucTam.path}/$tenTep');
  await tep.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(tep.path, mimeType: mime)], subject: tenTep),
  );
}
