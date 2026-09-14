// Gọi máy chủ AI để kiểm tra chính tả một đoạn văn bản, và mô hình dữ liệu
// cho một lỗi tìm được (vị trí trong bài + các từ đề xuất thay thế).

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';

/// Một lỗi chính tả AI tìm được: vùng [batDau, ketThuc) trong văn bản, cùng
/// từ đề xuất thay thế. [tu] là từ SAI, giữ lại để lúc người dùng chọn thay
/// thế còn kiểm tra được văn bản ở vị trí đó có còn đúng như lúc tìm ra
/// không — tránh thay nhầm chỗ nếu bài đã đổi trong lúc chờ AI trả lời.
class LoiChinhTa {
  const LoiChinhTa({
    required this.batDau,
    required this.ketThuc,
    required this.tu,
    required this.deXuat,
  });

  final int batDau;
  final int ketThuc;
  final String tu;
  final List<String> deXuat;

  /// Dời cả vùng lỗi đi [lech] ký tự — dùng khi văn bản TRƯỚC vùng lỗi vừa
  /// dài ra hoặc ngắn lại vì người dùng sửa chỗ khác.
  LoiChinhTa dich(int lech) => LoiChinhTa(
        batDau: batDau + lech,
        ketThuc: ketThuc + lech,
        tu: tu,
        deXuat: deXuat,
      );
}

class DichVuKiemTraChinhTa {
  /// Gửi [doan] (chỉ phần văn bản CHƯA từng kiểm tra) lên máy chủ AI, nhận
  /// về danh sách lỗi với vị trí tính TRÊN ĐÚNG [doan] này (chưa cộng dồn vào
  /// vị trí thật trong toàn bài — việc đó do nơi gọi tự cộng thêm).
  Future<List<LoiChinhTa>> kiemTra(String doan) async {
    final phanHoi = await http
        .post(
          Uri.parse(diaChiMayChuAI),
          headers: {
            'content-type': 'application/json',
            'x-flowrite-secret': matKhauMayChuAI,
          },
          body: jsonEncode({'action': 'chinh_ta', 'text': doan}),
        )
        .timeout(const Duration(seconds: 25));

    if (phanHoi.statusCode != 200) {
      throw Exception('Máy chủ AI trả về lỗi ${phanHoi.statusCode}');
    }

    final goc = jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
    final vanBanKetQua = goc['text'] as String?;
    if (vanBanKetQua == null) {
      throw Exception(goc['loi']?.toString() ?? 'Máy chủ AI không trả về nội dung.');
    }

    var sach = vanBanKetQua.trim();
    if (sach.startsWith('```')) {
      sach = sach
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
          .replaceFirst(RegExp(r'```\s*$'), '')
          .trim();
    }

    final ds = jsonDecode(sach) as List<dynamic>;
    final ketQua = <LoiChinhTa>[];
    for (final phanTu in ds) {
      if (phanTu is! Map<String, dynamic>) continue;
      final tu = phanTu['tu'] as String? ?? '';
      if (tu.isEmpty) continue;

      var viTri = phanTu['viTri'] as int? ?? -1;
      final khopViTri = viTri >= 0 &&
          viTri + tu.length <= doan.length &&
          doan.substring(viTri, viTri + tu.length) == tu;
      if (!khopViTri) {
        viTri = doan.indexOf(tu);
        if (viTri < 0) continue; // AI bịa ra từ không có thật trong đoạn.
      }

      final deXuat = ((phanTu['deXuat'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();
      if (deXuat.isEmpty) continue;

      ketQua.add(LoiChinhTa(
        batDau: viTri,
        ketThuc: viTri + tu.length,
        tu: tu,
        deXuat: deXuat,
      ));
    }
    return ketQua;
  }
}
