// Kho dữ liệu: cây thư mục và ghi chú, đọc/ghi toàn bộ vào SharedPreferences
// dưới một khoá JSON duy nhất. Đủ cho một app chỉ lưu ghi chú văn bản, không
// cần tới cơ sở dữ liệu thật.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mo_hinh.dart';

/// Độ dài tối đa của tên thư mục/ghi chú.
const doDaiTenToiDa = 100;

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
      // (THÙNG RÁC) Quét dọn các mục quá hạn 30 ngày ngay lúc nạp — xem chú
      // thích ở `donDepThungRacQuaHan`.
      if (donDepThungRacQuaHan()) await luu();

      final dangMo = kho.getString(_khoaGhiChuDangMo);
      if (dangMo != null && timGhiChu(dangMo)?.thoiGianXoa == null) {
        return dangMo;
      }
      // Ghi chú lần trước mở đã bị xoá/chuyển vào thùng rác — mở tạm ghi chú
      // ĐANG HOẠT ĐỘNG đầu tiên tìm thấy, không có cái nào thì tạo mới.
      final conHoatDong = ghiChu.where((g) => g.thoiGianXoa == null);
      if (conHoatDong.isNotEmpty) return conHoatDong.first.id;
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
    // (THÙNG RÁC) Mục đang nằm trong thùng rác (`thoiGianXoa != null`)
    // KHÔNG hiện ra ở đây dù `chaId` vẫn còn giữ nguyên vị trí cũ.
    final tm = thuMuc
        .where((t) => t.chaId == chaId && t.thoiGianXoa == null)
        .toList()
      ..sort((a, b) => a.ten.toLowerCase().compareTo(b.ten.toLowerCase()));
    final gc = ghiChu
        .where((g) => g.chaId == chaId && g.thoiGianXoa == null)
        .toList()
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
          t.thoiGianXoa == null &&
          t.id != boQuaIdThuMuc &&
          t.ten.toLowerCase() == trung,
    );
    if (tmTrung) return true;
    return ghiChu.any(
      (g) =>
          g.chaId == chaId &&
          g.thoiGianXoa == null &&
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

  /// Tên tự gợi ý cho một ghi chú SẮP tạo — dùng để điền sẵn vào hộp thoại
  /// đặt tên trước khi thật sự tạo.
  String tenGhiChuGoiY(String chaId) => _tenGhiChuTuDong(chaId);

  /// Tên tự gợi ý cho một thư mục SẮP tạo, cùng vai trò với hàm trên.
  String tenThuMucGoiY(String chaId) => _tenThuMucTuDong(chaId);

  /// Kiểm tên trước khi tạo mới (chưa có id để loại trừ, khác với
  /// `doiTenGhiChu`/`doiTenThuMuc` vốn kiểm khi ĐÃ có sẵn một mục) — cùng bộ
  /// quy tắc: không hợp lệ hoặc trùng tên trong cùng thư mục. null là dùng
  /// được.
  String? loiTenTrongThuMuc(String tenTho, String chaId) {
    final loi = loiTenKhongHopLe(tenTho);
    if (loi != null) return loi;
    final ten = tenTho.trim();
    if (_daCoTen(ten, chaId)) {
      return 'Tên "$ten" đã có trong thư mục này.';
    }
    return null;
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

  /// Đổi màu chữ tên ghi chú — `mau` là giá trị ARGB (`Color.value`),
  /// `null` là trả về màu mặc định.
  void datMauGhiChu(String id, int? mau) {
    final g = timGhiChu(id);
    if (g == null) return;
    g.mau = mau;
  }

  /// Cùng vai trò với `datMauGhiChu`, cho thư mục.
  void datMauThuMuc(String id, int? mau) {
    final t = timThuMuc(id);
    if (t == null) return;
    t.mau = mau;
  }

  void suaNoiDungGhiChu(String id, String noiDung) {
    final g = timGhiChu(id);
    if (g == null) return;
    g.noiDung = noiDung;
    g.capNhat = DateTime.now();
  }

  // ------------------------------------------------------------ xoá vĩnh viễn

  /// Xoá THẬT, không qua thùng rác — chỉ dùng cho "Xoá vĩnh viễn" trong
  /// Thùng rác và cho việc tự dọn mục quá hạn 30 ngày.
  void xoaGhiChu(String id) {
    ghiChu.removeWhere((g) => g.id == id);
  }

  /// Xoá THẬT cả thư mục con và ghi chú bên trong, đệ quy — cùng vai trò với
  /// `xoaGhiChu` ở trên, không qua thùng rác.
  void xoaThuMuc(String id) {
    final conThuMuc =
        thuMuc.where((t) => t.chaId == id).map((t) => t.id).toList();
    for (final c in conThuMuc) {
      xoaThuMuc(c);
    }
    ghiChu.removeWhere((g) => g.chaId == id);
    thuMuc.removeWhere((t) => t.id == id);
  }

  // --------------------------------------------------------- thùng rác nội bộ

  /// "Chuyển vào thùng rác" — không hỏi xác nhận, không xoá thật, chỉ đánh
  /// dấu thời điểm. Thư mục con/ghi chú bên trong KHÔNG bị đánh dấu theo —
  /// chúng vẫn giữ nguyên `chaId` cũ, chỉ là không còn đường nào lần tới
  /// (thư mục chứa chúng đang ẩn) cho tới khi thư mục này được khôi phục.
  void chuyenThuMucVaoThungRac(String id) {
    final t = timThuMuc(id);
    if (t == null) return;
    t.thoiGianXoa = DateTime.now();
  }

  void chuyenGhiChuVaoThungRac(String id) {
    final g = timGhiChu(id);
    if (g == null) return;
    g.thoiGianXoa = DateTime.now();
  }

  /// Toàn bộ mục đang nằm trong thùng rác (thư mục lẫn ghi chú), mới xoá
  /// nhất xếp trước — dùng để vẽ modal "Thùng rác Bộ nhớ Nội bộ".
  List<({bool laThuMuc, String id, String ten, int? mau, DateTime thoiGianXoa})>
      get mucTrongThungRac {
    final ds = <({bool laThuMuc, String id, String ten, int? mau, DateTime thoiGianXoa})>[];
    for (final t in thuMuc) {
      if (t.thoiGianXoa != null) {
        ds.add((laThuMuc: true, id: t.id, ten: t.ten, mau: t.mau, thoiGianXoa: t.thoiGianXoa!));
      }
    }
    for (final g in ghiChu) {
      if (g.thoiGianXoa != null) {
        ds.add((laThuMuc: false, id: g.id, ten: g.ten, mau: g.mau, thoiGianXoa: g.thoiGianXoa!));
      }
    }
    ds.sort((a, b) => b.thoiGianXoa.compareTo(a.thoiGianXoa));
    return ds;
  }

  /// true nếu [chaId] còn là một chỗ đứng hợp lệ để khôi phục về — gốc luôn
  /// hợp lệ; một thư mục thật thì phải còn tồn tại VÀ không tự nó cũng đang
  /// nằm trong thùng rác.
  bool _choDungHopLe(String chaId) {
    if (chaId == thuMucGoc) return true;
    final t = timThuMuc(chaId);
    return t != null && t.thoiGianXoa == null;
  }

  /// Khôi phục một thư mục từ thùng rác về đúng vị trí cũ — hết chỗ cũ (đã
  /// bị xoá mất) thì về thẳng gốc Bộ nhớ nội bộ. Đổi tên tự động nếu đụng
  /// trùng tên ngay tại nơi về. Trả về id thư mục cha THẬT SỰ đã về (để màn
  /// hình nhảy tới đúng chỗ).
  String khoiPhucThuMuc(String id) {
    final t = timThuMuc(id)!;
    final noiVe = _choDungHopLe(t.chaId) ? t.chaId : thuMucGoc;
    t.chaId = noiVe;
    t.ten = tenKhongTrung(t.ten, noiVe, boQuaIdThuMuc: id);
    t.thoiGianXoa = null;
    return noiVe;
  }

  String khoiPhucGhiChu(String id) {
    final g = timGhiChu(id)!;
    final noiVe = _choDungHopLe(g.chaId) ? g.chaId : thuMucGoc;
    g.chaId = noiVe;
    g.ten = tenKhongTrung(g.ten, noiVe, boQuaIdGhiChu: id);
    g.thoiGianXoa = null;
    return noiVe;
  }

  /// Số ngày một mục được giữ trong thùng rác trước khi tự xoá vĩnh viễn.
  static const soNgayGiuTrongThungRac = 30;

  /// Quét thùng rác, xoá vĩnh viễn mọi mục quá hạn — gọi một lần mỗi khi
  /// nạp app/trang (xem `tai()`), đủ để thùng rác không phình to mãi mà
  /// không cần quét liên tục tốn tài nguyên lúc app đang chạy. Trả về true
  /// nếu có xoá gì (để `tai()` biết cần `luu()` lại).
  bool donDepThungRacQuaHan() {
    final han = DateTime.now().subtract(const Duration(days: soNgayGiuTrongThungRac));
    var coXoa = false;
    for (final t in thuMuc.where((t) => t.thoiGianXoa != null).toList()) {
      if (t.thoiGianXoa!.isBefore(han)) {
        xoaThuMuc(t.id);
        coXoa = true;
      }
    }
    for (final g in ghiChu.where((g) => g.thoiGianXoa != null).toList()) {
      if (g.thoiGianXoa!.isBefore(han)) {
        xoaGhiChu(g.id);
        coXoa = true;
      }
    }
    return coXoa;
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

  // -------------------------------------------------------------- nhập zip

  /// Tên đọc từ trong một tệp .zip ngoài có thể mang ký tự app này cấm
  /// (`kyTuCamTrongTen`) hoặc dài quá giới hạn — làm sạch trước khi đặt,
  /// cùng bộ quy tắc với `loiTenKhongHopLe`.
  String _tenAnToanTuZip(String tenTho) {
    var s = tenTho.replaceAll(kyTuCamTrongTen, '_').trim();
    if (s.isEmpty) s = 'Không tên';
    if (s.length > doDaiTenToiDa) s = s.substring(0, doDaiTenToiDa);
    return s;
  }

  /// Đưa một cây đã xem trước (`NutZip`, xem `lib/zip_thu_muc.dart` và
  /// `ModalNhapZip`) vào THẬT trong [chaId] — đệ quy, tự đổi tên kiểu
  /// " (N)" nếu trùng tên với mục đang có, CÙNG cơ chế khôi phục từ Thùng
  /// rác (`tenKhongTrung`).
  void nhapCayZip(List<NutZip> cay, String chaId) {
    for (final nut in cay) {
      final tenAnToan = _tenAnToanTuZip(nut.ten);
      if (nut.laThuMuc) {
        final t = taoThuMucMoi(chaId);
        t.ten = tenKhongTrung(tenAnToan, chaId, boQuaIdThuMuc: t.id);
        nhapCayZip(nut.con, t.id);
      } else {
        final g = taoGhiChuMoi(chaId, noiDungBanDau: nut.noiDung ?? '');
        g.ten = tenKhongTrung(tenAnToan, chaId, boQuaIdGhiChu: g.id);
      }
    }
  }
}
