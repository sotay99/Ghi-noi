// Kho dữ liệu: cây thư mục và ghi chú, đọc/ghi toàn bộ vào SharedPreferences
// dưới một khoá JSON duy nhất. Đủ cho một app chỉ lưu ghi chú văn bản, không
// cần tới cơ sở dữ liệu thật.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mo_hinh.dart';

/// Độ dài tối đa của tên thư mục/ghi chú.
const doDaiTenToiDa = 50;

/// Ký tự bị cấm trong tên thư mục/ghi chú — đúng bộ ký tự Windows cấm dùng
/// trong tên file, chặt nhất trong các hệ điều hành phổ biến nên áp dụng
/// chung cho chắc chắn, kể cả ký tự điều khiển không nhìn thấy được.
final RegExp kyTuCamTrongTen = RegExp(r'[\\/:*?"<>|\x00-\x1F]');

/// null nghĩa là tên hợp lệ; khác null là lời giải thích vì sao không được,
/// hiển thị thẳng cho người dùng.
String? loiTenKhongHopLe(String tenTho) {
  final ten = tenTho.trim();
  if (ten.isEmpty) return 'Tên không được để trống.';
  if (ten.length > doDaiTenToiDa) {
    return 'Tên không được quá $doDaiTenToiDa ký tự.';
  }
  if (kyTuCamTrongTen.hasMatch(ten)) {
    return 'Tên không được chứa các ký tự \\ / : * ? " < > |';
  }
  return null;
}

class KhoDuLieu {
  static const _khoaDuLieu = 'ghi_noi_cay_du_lieu';
  static const _khoaGhiChuDangMo = 'ghi_noi_ghi_chu_dang_mo';
  // Khoá của bản trước khi có cây thư mục (bản chỉ có một trang duy nhất).
  static const _khoaVanBanCu = 'noi_dung_van_ban';

  final List<ThuMuc> thuMuc = [];
  final List<GhiChuFile> ghiChu = [];

  int _demId = 0;
  String _idMoi() {
    _demId++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_demId';
  }

  /// Nạp cây dữ liệu, trả về id ghi chú nên mở (ghi chú lần trước đang mở,
  /// hoặc ghi chú vừa tạo nếu đây là lần đầu chạy app).
  Future<String> tai() async {
    final kho = await SharedPreferences.getInstance();
    final tho = kho.getString(_khoaDuLieu);

    thuMuc.clear();
    ghiChu.clear();

    if (tho != null) {
      final j = jsonDecode(tho) as Map<String, dynamic>;
      for (final t in (j['thuMuc'] as List<dynamic>? ?? const [])) {
        thuMuc.add(ThuMuc.fromJson(t as Map<String, dynamic>));
      }
      for (final g in (j['ghiChu'] as List<dynamic>? ?? const [])) {
        ghiChu.add(GhiChuFile.fromJson(g as Map<String, dynamic>));
      }
      final dangMo = kho.getString(_khoaGhiChuDangMo);
      if (dangMo != null && timGhiChu(dangMo) != null) return dangMo;
      // Ghi chú lần trước mở đã bị xoá — mở tạm ghi chú đầu tiên tìm thấy,
      // không có cái nào thì tạo mới.
      if (ghiChu.isNotEmpty) return ghiChu.first.id;
      final moi = taoGhiChuMoi(thuMucGoc);
      await luu();
      return moi.id;
    }

    // Chưa từng có cây thư mục. Có bản cũ (trước khi làm tính năng này) thì
    // chuyển nó thành ghi chú đầu tiên, không có thì tạo một ghi chú trống.
    final vanBanCu = kho.getString(_khoaVanBanCu);
    final ghiChuDauTien =
        taoGhiChuMoi(thuMucGoc, noiDungBanDau: vanBanCu ?? '');
    if (vanBanCu != null) await kho.remove(_khoaVanBanCu);
    await luu();
    await datGhiChuDangMo(ghiChuDauTien.id);
    return ghiChuDauTien.id;
  }

  Future<void> luu() async {
    final kho = await SharedPreferences.getInstance();
    final j = {
      'thuMuc': thuMuc.map((t) => t.toJson()).toList(),
      'ghiChu': ghiChu.map((g) => g.toJson()).toList(),
    };
    await kho.setString(_khoaDuLieu, jsonEncode(j));
  }

  Future<void> datGhiChuDangMo(String id) async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaGhiChuDangMo, id);
  }

  // ------------------------------------------------------------- truy vấn

  GhiChuFile? timGhiChu(String id) {
    for (final g in ghiChu) {
      if (g.id == id) return g;
    }
    return null;
  }

  ThuMuc? timThuMuc(String id) {
    for (final t in thuMuc) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Danh sách con trực tiếp của một thư mục: thư mục con và ghi chú, mỗi
  /// loại sắp riêng theo tên.
  ({List<ThuMuc> thuMucCon, List<GhiChuFile> ghiChuCon}) noiDungThuMuc(
    String chaId,
  ) {
    final tm = thuMuc.where((t) => t.chaId == chaId).toList()
      ..sort((a, b) => a.ten.toLowerCase().compareTo(b.ten.toLowerCase()));
    final gc = ghiChu.where((g) => g.chaId == chaId).toList()
      ..sort((a, b) => a.ten.toLowerCase().compareTo(b.ten.toLowerCase()));
    return (thuMucCon: tm, ghiChuCon: gc);
  }

  bool _daCoTen(
    String ten,
    String chaId, {
    String? boQuaIdThuMuc,
    String? boQuaIdGhiChu,
  }) {
    final trung = ten.trim().toLowerCase();
    final tmTrung = thuMuc.any(
      (t) =>
          t.chaId == chaId &&
          t.id != boQuaIdThuMuc &&
          t.ten.toLowerCase() == trung,
    );
    if (tmTrung) return true;
    return ghiChu.any(
      (g) =>
          g.chaId == chaId &&
          g.id != boQuaIdGhiChu &&
          g.ten.toLowerCase() == trung,
    );
  }

  /// Tên không trùng với bất cứ thứ gì khác NGAY TRONG thư mục này — thư mục
  /// khác thì trùng vô tư, đó là quy tắc đặt tên của cả app.
  String tenKhongTrung(
    String tenMongMuon,
    String chaId, {
    String? boQuaIdThuMuc,
    String? boQuaIdGhiChu,
  }) {
    // Cắt bớt tên gốc nếu cần, để dù có thêm hậu tố " (n)" vào cũng không
    // bao giờ vượt quá giới hạn độ dài chung của cả app.
    final goc = tenMongMuon.trim().length > doDaiTenToiDa
        ? tenMongMuon.trim().substring(0, doDaiTenToiDa)
        : tenMongMuon.trim();

    if (!_daCoTen(goc, chaId,
        boQuaIdThuMuc: boQuaIdThuMuc, boQuaIdGhiChu: boQuaIdGhiChu)) {
      return goc;
    }
    var n = 2;
    while (true) {
      final hauTo = ' ($n)';
      final gioiHanGoc = doDaiTenToiDa - hauTo.length;
      final coSo = goc.length > gioiHanGoc ? goc.substring(0, gioiHanGoc) : goc;
      final ung = '$coSo$hauTo';
      if (!_daCoTen(ung, chaId,
          boQuaIdThuMuc: boQuaIdThuMuc, boQuaIdGhiChu: boQuaIdGhiChu)) {
        return ung;
      }
      n++;
    }
  }

  String _tenGhiChuTuDong(String chaId) {
    var n = 1;
    while (_daCoTen('Ghi chú $n', chaId)) {
      n++;
    }
    return 'Ghi chú $n';
  }

  String _tenThuMucTuDong(String chaId) {
    var n = 1;
    while (_daCoTen('Thư mục $n', chaId)) {
      n++;
    }
    return 'Thư mục $n';
  }

  // -------------------------------------------------------------- thêm mới

  GhiChuFile taoGhiChuMoi(String chaId, {String noiDungBanDau = ''}) {
    final g = GhiChuFile(
      id: _idMoi(),
      ten: _tenGhiChuTuDong(chaId),
      chaId: chaId,
      noiDung: noiDungBanDau,
      capNhat: DateTime.now(),
    );
    ghiChu.add(g);
    return g;
  }

  ThuMuc taoThuMucMoi(String chaId) {
    final t = ThuMuc(id: _idMoi(), ten: _tenThuMucTuDong(chaId), chaId: chaId);
    thuMuc.add(t);
    return t;
  }

  // ------------------------------------------------------------------ sửa

  /// null nếu đổi được; khác null là lời giải thích vì sao không được (tên
  /// không hợp lệ, hoặc tên trùng trong cùng thư mục).
  String? doiTenGhiChu(String id, String tenMoi) {
    final g = timGhiChu(id);
    if (g == null) return 'Không tìm thấy ghi chú.';
    final loi = loiTenKhongHopLe(tenMoi);
    if (loi != null) return loi;
    final tenSach = tenMoi.trim();
    if (_daCoTen(tenSach, g.chaId, boQuaIdGhiChu: id)) {
      return 'Tên "$tenSach" đã có trong thư mục này.';
    }
    g.ten = tenSach;
    return null;
  }

  String? doiTenThuMuc(String id, String tenMoi) {
    final t = timThuMuc(id);
    if (t == null) return 'Không tìm thấy thư mục.';
    final loi = loiTenKhongHopLe(tenMoi);
    if (loi != null) return loi;
    final tenSach = tenMoi.trim();
    if (_daCoTen(tenSach, t.chaId, boQuaIdThuMuc: id)) {
      return 'Tên "$tenSach" đã có trong thư mục này.';
    }
    t.ten = tenSach;
    return null;
  }

  void suaNoiDungGhiChu(String id, String noiDung) {
    final g = timGhiChu(id);
    if (g == null) return;
    g.noiDung = noiDung;
    g.capNhat = DateTime.now();
  }

  // ------------------------------------------------------------------ xoá

  void xoaGhiChu(String id) {
    ghiChu.removeWhere((g) => g.id == id);
  }

  /// Xoá cả thư mục con và ghi chú bên trong, đệ quy.
  void xoaThuMuc(String id) {
    final conThuMuc =
        thuMuc.where((t) => t.chaId == id).map((t) => t.id).toList();
    for (final c in conThuMuc) {
      xoaThuMuc(c);
    }
    ghiChu.removeWhere((g) => g.chaId == id);
    thuMuc.removeWhere((t) => t.id == id);
  }

  // ------------------------------------------------------------ di chuyển

  bool diChuyenGhiChu(String id, String chaMoiId) {
    final g = timGhiChu(id);
    if (g == null) return false;
    g.ten = tenKhongTrung(g.ten, chaMoiId, boQuaIdGhiChu: id);
    g.chaId = chaMoiId;
    return true;
  }

  /// false nếu không di chuyển được — ví dụ dời một thư mục vào chính con
  /// cháu của nó, một vòng lặp không có lối ra.
  bool diChuyenThuMuc(String id, String chaMoiId) {
    if (id == chaMoiId) return false;
    if (_laToTienCua(chaMoiId, id)) return false;
    final t = timThuMuc(id);
    if (t == null) return false;
    t.ten = tenKhongTrung(t.ten, chaMoiId, boQuaIdThuMuc: id);
    t.chaId = chaMoiId;
    return true;
  }

  /// true nếu [idToTien] là tổ tiên của [idConCham] (đi ngược lên từ
  /// idConCham gặp idToTien trước khi tới gốc).
  bool _laToTienCua(String idConCham, String idToTien) {
    var hienTai = idConCham;
    while (hienTai != thuMucGoc) {
      if (hienTai == idToTien) return true;
      final t = timThuMuc(hienTai);
      if (t == null) break;
      hienTai = t.chaId;
    }
    return false;
  }

  // ---------------------------------------------------------------- chép

  GhiChuFile saoChepGhiChu(String id, String chaMoiId) {
    final g = timGhiChu(id)!;
    final ban = GhiChuFile(
      id: _idMoi(),
      ten: tenKhongTrung(g.ten, chaMoiId),
      chaId: chaMoiId,
      noiDung: g.noiDung,
      capNhat: DateTime.now(),
    );
    ghiChu.add(ban);
    return ban;
  }

  ThuMuc saoChepThuMuc(String id, String chaMoiId) {
    final t = timThuMuc(id)!;
    final ban = ThuMuc(
      id: _idMoi(),
      ten: tenKhongTrung(t.ten, chaMoiId),
      chaId: chaMoiId,
    );
    thuMuc.add(ban);
    // Sao chép đệ quy mọi thứ nằm trong thư mục gốc, rót vào bản sao.
    for (final con in thuMuc.where((x) => x.chaId == id).toList()) {
      saoChepThuMuc(con.id, ban.id);
    }
    for (final con in ghiChu.where((x) => x.chaId == id).toList()) {
      saoChepGhiChu(con.id, ban.id);
    }
    return ban;
  }
}
