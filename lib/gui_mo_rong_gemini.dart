// Gửi văn bản cho máy chủ trung gian AI để mở rộng — action 'mo_rong' (xem
// cloud-function/index.js, huongDanMoRong()). ĐÚNG KHUÔN
// gui_tom_tat_gemini.dart, chỉ khác action gửi lên và quy ước % (100% =
// giữ nguyên, trên 100% = mở rộng thêm — xem chú thích ở modal "Chọn kiểu
// mở rộng" trong trang_soan_thao.dart).

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';

/// [phanTram] (120-400) và/hoặc [huongDanNguoiDung] — ít nhất một trong hai
/// phải có, nơi gọi (modal chọn kiểu mở rộng) đã chặn gửi lên khi cả hai
/// đều trống/null.
///
/// Trả về văn bản đã mở rộng, hoặc ném lỗi ra ngoài (nơi gọi tự quyết định
/// báo lỗi hay âm thầm thử lại sau).
Future<String> guiMoRongChoGemini(
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
        body: jsonEncode({
          'action': 'mo_rong',
          'text': vanBan,
          if (phanTram != null) 'phanTram': phanTram,
          if (huongDanNguoiDung != null && huongDanNguoiDung.trim().isNotEmpty)
            'huongDanNguoiDung': huongDanNguoiDung.trim(),
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
