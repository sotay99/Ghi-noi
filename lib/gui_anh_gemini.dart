// Gửi MỘT tệp ảnh (bytes + mimeType, không quan tâm lấy từ đâu) cho máy chủ
// trung gian AI trích chữ (OCR) — action 'chuyen_anh' (xem
// cloud-function/index.js). Cùng khuôn với `gui_ghi_am_gemini.dart`, chỉ
// khác trường dữ liệu gửi lên (imageBase64 thay audioBase64).

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';
import 'canh_bao_han_muc_ai.dart';

/// Trả về chữ trích xuất được, hoặc ném lỗi ra ngoài (nơi gọi tự quyết định
/// báo lỗi hay âm thầm thử lại sau).
Future<String> guiAnhChoGemini(Uint8List bytes, String mimeType) async {
  final base64 = base64Encode(bytes);
  final phanHoi = await http
      .post(
        Uri.parse(diaChiMayChuAI),
        headers: await taoHeaderGoiAi(),
        body: jsonEncode(await ganDinhDanhAi({
          'action': 'chuyen_anh',
          'imageBase64': base64,
          'mimeType': mimeType.isNotEmpty ? mimeType : 'image/jpeg',
        })),
      )
      .timeout(const Duration(minutes: 3));
  final goc = jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
  if (phanHoi.statusCode != 200) {
    if (goc['hanMucAi'] == true) {
      throw LoiHanMucAi(LoaiHanMucAi.hinhAnh, goc['loi']?.toString() ?? 'Bạn đã dùng hết hạn mức AI hôm nay.');
    }
    throw Exception(goc['loi']?.toString() ?? 'Máy chủ AI trả về lỗi ${phanHoi.statusCode}.');
  }
  final chu = (goc['text'] as String?)?.trim();
  if (chu == null || chu.isEmpty) {
    throw Exception(goc['loi']?.toString() ?? 'Không có nội dung trả về.');
  }
  return chu;
}
