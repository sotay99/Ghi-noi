// Gửi văn bản cho máy chủ trung gian AI để viết lại cho hay hơn — action
// 'got_dua' (xem cloud-function/index.js, huongDanVietLai()). ĐÚNG KHUÔN
// gui_tom_tat_gemini.dart, chỉ khác: [huongDanNguoiDung] là tham số DUY
// NHẤT (không có %), và CÓ THỂ để trống/null — để trống thì AI tự do chọn
// cách viết lại.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';
import 'canh_bao_han_muc_ai.dart';

/// Trả về văn bản đã viết lại, hoặc ném lỗi ra ngoài (nơi gọi tự quyết định
/// báo lỗi hay âm thầm thử lại sau).
Future<String> guiVietLaiChoGemini(
  String vanBan, {
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
          'action': 'got_dua',
          'text': vanBan,
          if (huongDanNguoiDung != null && huongDanNguoiDung.trim().isNotEmpty)
            'huongDanNguoiDung': huongDanNguoiDung.trim(),
        })),
      )
      .timeout(const Duration(minutes: 3));
  final goc = jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
  if (phanHoi.statusCode != 200) {
    if (goc['hanMucAi'] == true) {
      throw LoiHanMucAi(LoaiHanMucAi.vanBan, goc['loi']?.toString() ?? 'Bạn đã dùng hết hạn mức AI hôm nay.');
    }
    throw Exception(goc['loi']?.toString() ?? 'Máy chủ AI trả về lỗi ${phanHoi.statusCode}.');
  }
  final chu = (goc['text'] as String?)?.trim();
  if (chu == null || chu.isEmpty) {
    throw Exception(goc['loi']?.toString() ?? 'Không có nội dung trả về.');
  }
  return chu;
}
