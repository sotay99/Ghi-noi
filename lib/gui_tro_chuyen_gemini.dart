// Gửi CẢ CUỘC HỘI THOẠI cho máy chủ trung gian AI — action 'tro_chuyen'
// (xem cloud-function/index.js, goiGeminiChat()). Khác các file
// gui_*_gemini.dart khác (một lượt, ghép sẵn hướng dẫn + văn bản): ở đây
// KHÔNG có tham số văn bản rời — lượt đầu tiên trong [lichSu] đã do nơi gọi
// (lib/man_hinh_tro_chuyen.dart) tự ghép kèm toàn văn bản đang soạn rồi,
// nên máy chủ không cần biết gì thêm ngoài chính cuộc hội thoại.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';

/// Một lượt trong cuộc hội thoại — [vaiTro] là `'nguoiDung'` hoặc `'ai'`.
class LuotTroChuyen {
  const LuotTroChuyen({required this.vaiTro, required this.noiDung});

  final String vaiTro;
  final String noiDung;

  Map<String, String> toJson() => {'vaiTro': vaiTro, 'noiDung': noiDung};
}

/// Trả về câu trả lời mới nhất của AI, hoặc ném lỗi ra ngoài (nơi gọi tự
/// quyết định báo lỗi hay âm thầm thử lại sau).
Future<String> guiTroChuyenChoGemini(List<LuotTroChuyen> lichSu) async {
  final phanHoi = await http
      .post(
        Uri.parse(diaChiMayChuAI),
        headers: {
          'content-type': 'application/json',
          'x-flowrite-secret': matKhauMayChuAI,
        },
        body: jsonEncode({
          'action': 'tro_chuyen',
          'lichSu': lichSu.map((l) => l.toJson()).toList(),
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
