// Gửi MỘT đoạn ghi âm (bytes + mimeType, không quan tâm lấy từ đâu) cho máy
// chủ trung gian AI phiên âm — dùng chung cho cả Android/iOS gốc và web,
// action 'ghi_am' đã có sẵn (xem cloud-function/index.js), nguyên văn cách
// gọi đã kiểm chứng ở cả `ghi_am_ai_io.dart` (app cũ) và `main_web_test.dart`
// (web-test). Không đụng dart:io/dart:html — thuần http + dart:convert nên
// dùng được ở cả hai nền tảng.

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';

/// [locHallucination]: CHỈ truyền `true` cho luồng THẺ GHI ÂM trong app —
/// bật cơ chế lọc "hallucination" phía máy chủ (kèm prompt ngữ cảnh +
/// verbose_json, xem `goiGroqAmThanh` trong cloud-function/index.js).
/// KHÔNG bật cho "Chuyển file âm thanh thành văn bản" (mặc định `false`):
/// tệp người dùng tự tải lên có thể là nhạc/podcast, ranh giới "im lặng =
/// hallucination" không đáng tin như với một lượt ghi âm giọng nói ngắn.
///
/// Trả về chữ phiên âm được, hoặc ném lỗi ra ngoài (nơi gọi tự quyết định
/// báo lỗi hay âm thầm thử lại sau).
Future<String> guiGhiAmChoGemini(
  Uint8List bytes,
  String mimeType, {
  bool locHallucination = false,
}) async {
  final base64 = base64Encode(bytes);
  final phanHoi = await http
      .post(
        Uri.parse(diaChiMayChuAI),
        headers: {
          'content-type': 'application/json',
          'x-flowrite-secret': matKhauMayChuAI,
        },
        body: jsonEncode({
          'action': 'ghi_am',
          'audioBase64': base64,
          'mimeType': mimeType.isNotEmpty ? mimeType : 'audio/mp4',
          if (locHallucination) 'locHallucination': true,
        }),
      )
      .timeout(const Duration(minutes: 3));
  if (phanHoi.statusCode != 200) {
    throw Exception('Máy chủ AI trả về lỗi ${phanHoi.statusCode}: ${phanHoi.body}');
  }
  final goc = jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
  final chu = (goc['text'] as String?)?.trim();
  if (chu == null || chu.isEmpty) {
    throw Exception(goc['loi']?.toString() ?? 'Không có nội dung trả về.');
  }
  return chu;
}
