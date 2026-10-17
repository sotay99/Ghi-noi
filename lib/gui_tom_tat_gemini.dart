// Gửi văn bản cho máy chủ trung gian AI để tóm tắt — action 'tom_tat' (xem
// cloud-function/index.js, huongDanTomTat()). Cùng khuôn các file
// gui_*_gemini.dart khác, chỉ khác trường dữ liệu: kèm % độ dài mong muốn
// và/hoặc câu lệnh tự do của người dùng (modal "Chọn kiểu tóm tắt").

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';

/// [phanTram] (10-90) và/hoặc [huongDanNguoiDung] — ít nhất một trong hai
/// phải có, nơi gọi (modal chọn kiểu tóm tắt) đã chặn gửi lên khi cả hai
/// đều trống/null.
///
/// Trả về văn bản tóm tắt, hoặc ném lỗi ra ngoài (nơi gọi tự quyết định báo
/// lỗi hay âm thầm thử lại sau).
Future<String> guiTomTatChoGemini(
  String vanBan, {
  int? phanTram,
  String? huongDanNguoiDung,
}) async {
  final phanHoi = await http
      .post(
        Uri.parse(diaChiMayChuAI),
        headers: {
          'content-type': 'application/json',
          'x-flowrite-secret': matKhauMayChuAI,
        },
        body: jsonEncode(await ganDinhDanhAi({
          'action': 'tom_tat',
          'text': vanBan,
          if (phanTram != null) 'phanTram': phanTram,
          if (huongDanNguoiDung != null && huongDanNguoiDung.trim().isNotEmpty)
            'huongDanNguoiDung': huongDanNguoiDung.trim(),
        })),
      )
      .timeout(const Duration(minutes: 3));
  final goc = jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
  if (phanHoi.statusCode != 200) {
    throw Exception(goc['loi']?.toString() ?? 'Máy chủ AI trả về lỗi ${phanHoi.statusCode}.');
  }
  final chu = (goc['text'] as String?)?.trim();
  if (chu == null || chu.isEmpty) {
    throw Exception(goc['loi']?.toString() ?? 'Không có nội dung trả về.');
  }
  return chu;
}
