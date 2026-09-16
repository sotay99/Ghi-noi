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

/// Một dấu câu AI đề xuất chèn thêm vào giữa bài (mục 3 — "Tự động chèn dấu
/// câu vào giữa các đoạn văn bằng AI"), vị trí tính trên văn bản GỐC gửi lên.
class DauCauMoiToanVanMuc {
  const DauCauMoiToanVanMuc({required this.dauCau, required this.viTri});
  final String dauCau;
  final int viTri;
}

/// Một khoảng [batDau, ketThuc) đã được đánh dấu ở lượt kiểm tra trước —
/// gửi kèm lên AI để nó coi là NGỮ CẢNH THAM KHẢO đã xử lý xong, không can
/// thiệp lại (mục 1).
class VungDaXuLy {
  const VungDaXuLy(this.batDau, this.ketThuc);
  final int batDau;
  final int ketThuc;

  Map<String, int> toJson() => {'batDau': batDau, 'ketThuc': ketThuc};
}

class KetQuaKiemTraToanVan {
  const KetQuaKiemTraToanVan({
    required this.chinhTa,
    required this.khongPhuHop,
    required this.canXoa,
    this.dauCauMoi = const [],
  });
  final List<ChinhTaMuc> chinhTa;
  final List<KhongPhuHopMuc> khongPhuHop;
  final List<CanXoaMuc> canXoa;
  final List<DauCauMoiToanVanMuc> dauCauMoi;
}

class DichVuKiemTraToanVan {
  /// [vungDaXuLy]: các khoảng đã đánh dấu ở (những) lượt kiểm tra trước —
  /// gửi kèm để AI không đụng lại vào đó (mục 1). [chenDauCau]: có nhờ AI
  /// tìm thêm dấu câu còn thiếu hay không (mục 3). [khoangKyTu]: khoảng ký
  /// tự tham khảo cho đoạn đề xuất (mục 5). [cauLenhTuyChinh]: câu lệnh
  /// riêng của người dùng, gửi kèm chỉ dẫn hệ thống (mục 5).
  Future<KetQuaKiemTraToanVan> kiemTra(
    String vanBan, {
    List<VungDaXuLy> vungDaXuLy = const [],
    bool chenDauCau = false,
    (int, int)? khoangKyTu,
    String cauLenhTuyChinh = '',
  }) async {
    final phanHoi = await http
        .post(
          Uri.parse(diaChiMayChuAI),
          headers: {
            'content-type': 'application/json',
            'x-flowrite-secret': matKhauMayChuAI,
          },
          body: jsonEncode({
            'action': 'toan_van',
            'text': vanBan,
            'vungDaXuLy': vungDaXuLy.map((v) => v.toJson()).toList(),
            'chenDauCau': chenDauCau,
            if (khoangKyTu != null) 'doDaiMin': khoangKyTu.$1,
            if (khoangKyTu != null) 'doDaiMax': khoangKyTu.$2,
            'cauLenhTuyChinh': cauLenhTuyChinh,
          }),
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

    // Không cho phép bất kỳ mục mới nào (kể cả dấu câu) chồng lấn lên vùng
    // ĐÃ XỬ LÝ gửi kèm — lưới bảo vệ phía app, đề phòng AI lỡ không tuân
    // theo chỉ dẫn trong prompt (mục 1).
    bool chongLenVungDaXuLy(int batDau, int ketThuc) =>
        vungDaXuLy.any((v) => batDau < v.ketThuc && ketThuc > v.batDau);

    chinhTa.removeWhere((c) => chongLenVungDaXuLy(c.viTri, c.viTri + c.tu.length));
    khongPhuHop.removeWhere((k) => chongLenVungDaXuLy(k.viTri, k.viTri + k.doan.length));
    canXoa.removeWhere((x) => chongLenVungDaXuLy(x.viTri, x.viTri + x.doan.length));

    final dauCauMoi = <DauCauMoiToanVanMuc>[];
    if (chenDauCau) {
      for (final m in (doiTuong['dauCauMoi'] as List<dynamic>? ?? const [])) {
        if (m is! Map<String, dynamic>) continue;
        final dauCau = m['dauCau'] as String? ?? '';
        if (dauCau.isEmpty) continue;
        final viTri = m['viTri'] as int? ?? -1;
        if (viTri < 0 || viTri > vanBan.length) continue;
        if (chongLenVungDaXuLy(viTri, viTri)) continue;
        // Không được rơi vào trong một cụm "chinhTa" vừa tìm được — dấu câu
        // bên trong cụm lỗi phải nằm trong đề xuất sửa của chính cụm đó.
        final chongLoi = chinhTa.any((c) => viTri >= c.viTri && viTri <= c.viTri + c.tu.length);
        if (chongLoi) continue;
        dauCauMoi.add(DauCauMoiToanVanMuc(dauCau: dauCau, viTri: viTri));
      }
    }

    return KetQuaKiemTraToanVan(
      chinhTa: chinhTa,
      khongPhuHop: khongPhuHop,
      canXoa: canXoa,
      dauCauMoi: dauCauMoi,
    );
  }
}
