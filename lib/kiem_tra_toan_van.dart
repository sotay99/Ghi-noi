// Gọi máy chủ AI để soát lại TOÀN BỘ văn bản một lần — khác với kiểm tra
// chính tả tự động theo từng câu (kiem_tra_chinh_ta.dart): ngoài từ/cụm từ
// sai chính tả, còn tìm cả đoạn văn không phù hợp (kèm đề xuất thay thế) và
// đoạn văn nên xoá hẳn.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_cau_hinh.dart';

/// Một từ/cụm từ sai chính tả tìm được trong lần kiểm tra toàn văn — vị trí
/// tính trên TOÀN BỘ văn bản đã gửi, khác với [LoiChinhTa] của bản kiểm tra
/// theo từng câu (vốn tính trên một đoạn ngắn).
class ChinhTaMuc {
  const ChinhTaMuc({required this.tu, required this.viTri, required this.deXuat});
  final String tu;
  final int viTri;
  final List<String> deXuat;
}

/// Một đoạn văn AI cho là không phù hợp, kèm đoạn đề xuất thay thế.
class KhongPhuHopMuc {
  const KhongPhuHopMuc({required this.doan, required this.viTri, required this.deXuat});
  final String doan;
  final int viTri;
  final String deXuat;
}

/// Một đoạn văn AI đề xuất xoá hẳn, không thay bằng gì.
class CanXoaMuc {
  const CanXoaMuc({required this.doan, required this.viTri});
  final String doan;
  final int viTri;
}

class KetQuaKiemTraToanVan {
  const KetQuaKiemTraToanVan({
    required this.chinhTa,
    required this.khongPhuHop,
    required this.canXoa,
  });
  final List<ChinhTaMuc> chinhTa;
  final List<KhongPhuHopMuc> khongPhuHop;
  final List<CanXoaMuc> canXoa;
}

class DichVuKiemTraToanVan {
  Future<KetQuaKiemTraToanVan> kiemTra(String vanBan) async {
    final phanHoi = await http
        .post(
          Uri.parse(diaChiMayChuAI),
          headers: {
            'content-type': 'application/json',
            'x-flowrite-secret': matKhauMayChuAI,
          },
          body: jsonEncode({'action': 'toan_van', 'text': vanBan}),
        )
        .timeout(const Duration(seconds: 60));

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

    final doiTuong = jsonDecode(sach) as Map<String, dynamic>;

    bool khopViTri(int viTri, String doan) =>
        viTri >= 0 && viTri + doan.length <= vanBan.length && vanBan.substring(viTri, viTri + doan.length) == doan;

    final chinhTa = <ChinhTaMuc>[];
    for (final m in (doiTuong['chinhTa'] as List<dynamic>? ?? const [])) {
      if (m is! Map<String, dynamic>) continue;
      final tu = m['tu'] as String? ?? '';
      if (tu.isEmpty) continue;
      var viTri = m['viTri'] as int? ?? -1;
      if (!khopViTri(viTri, tu)) {
        viTri = vanBan.indexOf(tu);
        if (viTri < 0) continue;
      }
      final deXuat = ((m['deXuat'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();
      if (deXuat.isEmpty) continue;
      chinhTa.add(ChinhTaMuc(tu: tu, viTri: viTri, deXuat: deXuat));
    }

    final khongPhuHop = <KhongPhuHopMuc>[];
    for (final m in (doiTuong['khongPhuHop'] as List<dynamic>? ?? const [])) {
      if (m is! Map<String, dynamic>) continue;
      final doan = m['doan'] as String? ?? '';
      final deXuat = m['deXuat'] as String? ?? '';
      if (doan.isEmpty || deXuat.isEmpty) continue;
      var viTri = m['viTri'] as int? ?? -1;
      if (!khopViTri(viTri, doan)) {
        viTri = vanBan.indexOf(doan);
        if (viTri < 0) continue;
      }
      khongPhuHop.add(KhongPhuHopMuc(doan: doan, viTri: viTri, deXuat: deXuat));
    }

    final canXoa = <CanXoaMuc>[];
    for (final m in (doiTuong['canXoa'] as List<dynamic>? ?? const [])) {
      if (m is! Map<String, dynamic>) continue;
      final doan = m['doan'] as String? ?? '';
      if (doan.isEmpty) continue;
      var viTri = m['viTri'] as int? ?? -1;
      if (!khopViTri(viTri, doan)) {
        viTri = vanBan.indexOf(doan);
        if (viTri < 0) continue;
      }
      canXoa.add(CanXoaMuc(doan: doan, viTri: viTri));
    }

    return KetQuaKiemTraToanVan(chinhTa: chinhTa, khongPhuHop: khongPhuHop, canXoa: canXoa);
  }
}
