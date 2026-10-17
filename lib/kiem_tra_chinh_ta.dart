// Gọi máy chủ AI để kiểm tra chính tả một đoạn văn bản, và mô hình dữ liệu
// cho một lỗi tìm được (vị trí trong bài + các từ đề xuất thay thế).

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';
import 'canh_bao_han_muc_ai.dart';

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

/// Một dấu câu AI đề xuất chèn thêm — vị trí tính TRÊN ĐÚNG đoạn văn gửi lên
/// (đã trừ ngữ cảnh), giống [LoiChinhTa.batDau].
class DauCauMoiChinhTa {
  const DauCauMoiChinhTa({required this.dauCau, required this.viTri});
  final String dauCau;
  final int viTri;
}

/// Kết quả một lượt kiểm tra chính tả tự động — có thể gồm lỗi chính tả,
/// dấu câu mới đề xuất chèn, hoặc cả hai, tuỳ theo cờ [layLoiChinhTa]/
/// [chenDauCau] lúc gọi.
class KetQuaKiemTraChinhTaMoi {
  const KetQuaKiemTraChinhTaMoi({required this.loi, required this.dauCauMoi});
  final List<LoiChinhTa> loi;
  final List<DauCauMoiChinhTa> dauCauMoi;
}

class DichVuKiemTraChinhTa {
  /// Gửi [doan] (phần văn bản CHƯA từng kiểm tra) lên máy chủ AI, kèm tối đa
  /// [nguCanh] ký tự văn bản NGAY TRƯỚC đó làm ngữ cảnh — AI đọc để hiểu mạch
  /// văn nhưng không báo lỗi trong phần này, tránh gửi một câu cộc lốc khiến
  /// AI bỏ sót lỗi hoặc đề xuất không hợp ngữ cảnh. [layLoiChinhTa] tắt thì
  /// không hỏi AI tìm lỗi chính tả nữa (chỉ dùng khi "Tự động chèn dấu câu"
  /// bật riêng lẻ); [chenDauCau] bật thì AI còn tìm thêm dấu câu còn thiếu.
  /// Trả về vị trí tính TRÊN ĐÚNG [doan] (đã trừ hết phần ngữ cảnh), chưa
  /// cộng dồn vào vị trí thật trong toàn bài — việc đó do nơi gọi tự cộng
  /// thêm.
  Future<KetQuaKiemTraChinhTaMoi> kiemTra(
    String doan, {
    String nguCanh = '',
    bool layLoiChinhTa = true,
    bool chenDauCau = false,
  }) async {
    final ghep = nguCanh + doan;
    final phanHoi = await http
        .post(
          Uri.parse(diaChiMayChuAI),
          headers: await taoHeaderGoiAi(),
          body: jsonEncode(await ganDinhDanhAi({
            'action': 'chinh_ta',
            'text': ghep,
            'boQuaTruocViTri': nguCanh.length,
            'layLoiChinhTa': layLoiChinhTa,
            'chenDauCau': chenDauCau,
          })),
        )
        .timeout(const Duration(seconds: 25));

    final goc = jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
    if (phanHoi.statusCode != 200) {
      if (goc['hanMucAi'] == true) {
        throw LoiHanMucAi(LoaiHanMucAi.vanBan, goc['loi']?.toString() ?? 'Bạn đã dùng hết hạn mức AI hôm nay.');
      }
      throw Exception(goc['loi']?.toString() ?? 'Máy chủ AI trả về lỗi ${phanHoi.statusCode}.');
    }
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

    final doiTuong = jsonDecode(sach) as Map<String, dynamic>;

    final ketQuaLoi = <LoiChinhTa>[];
    for (final phanTu in (doiTuong['chinhTa'] as List<dynamic>? ?? const [])) {
      if (phanTu is! Map<String, dynamic>) continue;
      final tu = phanTu['tu'] as String? ?? '';
      if (tu.isEmpty) continue;

      // AI được yêu cầu đếm viTri trên TOÀN BỘ [ghep] (ngữ cảnh + đoạn cần
      // soát) — dời về hệ toạ độ của riêng [doan] bằng cách trừ đi độ dài
      // ngữ cảnh. Lỗi rơi vào đúng phần ngữ cảnh (dời xong ra số âm) là AI
      // làm sai yêu cầu, bỏ qua luôn.
      var viTri = (phanTu['viTri'] as int? ?? -1) - nguCanh.length;
      final khopViTri = viTri >= 0 &&
          viTri + tu.length <= doan.length &&
          doan.substring(viTri, viTri + tu.length) == tu;
      if (!khopViTri) {
        viTri = doan.indexOf(tu);
        if (viTri < 0) continue; // AI bịa ra từ không có thật trong đoạn.
      }

      final deXuat = ((phanTu['deXuat'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty && e != tu)
          .take(5)
          .toList();
      if (deXuat.isEmpty) continue;

      ketQuaLoi.add(LoiChinhTa(
        batDau: viTri,
        ketThuc: viTri + tu.length,
        tu: tu,
        deXuat: deXuat,
      ));
    }

    final ketQuaDauCau = <DauCauMoiChinhTa>[];
    for (final phanTu in (doiTuong['dauCauMoi'] as List<dynamic>? ?? const [])) {
      if (phanTu is! Map<String, dynamic>) continue;
      final dauCau = phanTu['dauCau'] as String? ?? '';
      if (dauCau.isEmpty) continue;
      final viTri = (phanTu['viTri'] as int? ?? -1) - nguCanh.length;
      if (viTri < 0 || viTri > doan.length) continue;
      // Dấu câu KHÔNG được nằm trong một vùng lỗi chính tả vừa tìm được —
      // dấu câu bên trong một cụm lỗi phải nằm trong "deXuat" của chính lỗi
      // đó, không tách riêng ra.
      final chongLoi = ketQuaLoi.any((l) => viTri >= l.batDau && viTri <= l.ketThuc);
      if (chongLoi) continue;
      ketQuaDauCau.add(DauCauMoiChinhTa(dauCau: dauCau, viTri: viTri));
    }

    return KetQuaKiemTraChinhTaMoi(loi: ketQuaLoi, dauCauMoi: ketQuaDauCau);
  }
}
