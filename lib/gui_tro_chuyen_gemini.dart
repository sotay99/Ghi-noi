// Gửi CẢ CUỘC HỘI THOẠI cho máy chủ trung gian AI — action 'tro_chuyen'
// (xem cloud-function/index.js, goiGeminiChatStream()). Khác các file
// gui_*_gemini.dart khác (một lượt, ghép sẵn hướng dẫn + văn bản): ở đây
// KHÔNG có tham số văn bản rời — lượt đầu tiên trong [lichSu] đã do nơi gọi
// (lib/man_hinh_tro_chuyen.dart) tự ghép kèm toàn văn bản đang soạn rồi,
// nên máy chủ không cần biết gì thêm ngoài chính cuộc hội thoại.
//
// STREAMING: máy chủ đẩy chữ ra dần dần (plain text thô, không phải JSON
// một lần) — trả về một Stream<String>, mỗi phần tử là MỘT ĐOẠN chữ mới
// nhận được (không phải toàn bộ câu trả lời tích luỹ), để nơi gọi tự nối
// vào cuối tin nhắn đang hiển thị, tạo hiệu ứng chữ chạy ra liên tục.

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

/// Trả về từng đoạn chữ AI vừa sinh thêm (nối các đoạn lại theo đúng thứ tự
/// stream trả về là được toàn bộ câu trả lời), hoặc ném lỗi ra ngoài (nơi
/// gọi tự quyết định giữ lại phần đã nhận được tới đó hay báo lỗi hẳn).
Stream<String> guiTroChuyenChoGeminiStream(List<LuotTroChuyen> lichSu) async* {
  final client = http.Client();
  try {
    final yeuCau = http.Request('POST', Uri.parse(diaChiMayChuAI))
      ..headers['content-type'] = 'application/json'
      ..headers['x-flowrite-secret'] = matKhauMayChuAI
      ..body = jsonEncode(await ganDinhDanhAi({
        'action': 'tro_chuyen',
        'lichSu': lichSu.map((l) => l.toJson()).toList(),
      }));
    final phanHoi = await client.send(yeuCau).timeout(const Duration(minutes: 3));
    if (phanHoi.statusCode != 200) {
      final noiDungLoi = await phanHoi.stream.bytesToString();
      String thongDiep = 'Máy chủ AI trả về lỗi ${phanHoi.statusCode}: $noiDungLoi';
      try {
        final goc = jsonDecode(noiDungLoi) as Map<String, dynamic>;
        if (goc['loi'] is String) thongDiep = goc['loi'] as String;
      } catch (_) {}
      throw Exception(thongDiep);
    }
    var coChu = false;
    await for (final doan in phanHoi.stream.transform(utf8.decoder)) {
      if (doan.isEmpty) continue;
      coChu = true;
      yield doan;
    }
    if (!coChu) {
      throw Exception('Không có nội dung trả về.');
    }
  } finally {
    client.close();
  }
}
