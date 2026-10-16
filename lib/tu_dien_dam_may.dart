// (ĐỒNG BỘ TÀI KHOẢN GOOGLE — YÊU CẦU MỚI) Bộ nhớ ĐÁM MÂY, SỐNG (ghi thẳng
// lên Firestore ngay mỗi lần đổi, không chờ "nạp đầy lúc trống" như
// `CaiDatDamMay`), cho hai từ điển: "Từ điển nhập liệu nhanh" và "Từ điển
// sửa lỗi chính tả". Mỗi tài khoản có MỘT bản riêng, hoàn toàn TÁCH BIỆT với
// bộ nhớ NỘI BỘ (`CaiDat.tuDienNhapLieuNhanh`/`tuDienChinhTa`) — hai nơi lưu
// khác hẳn nhau, chỉ giống hình dạng dữ liệu. Cùng khuôn cache ngoại tuyến
// với `KhoDuLieuDamMay`/`CaiDatDamMay`: mất mạng thì bỏ qua lặng lẽ việc ghi
// lên Firestore (không giữ hàng đợi riêng — lần ghi KẾ TIẾP khi có mạng tự
// mang đúng giá trị mới nhất lên), nhưng vẫn cập nhật cache đĩa để đọc lại
// được lúc offline.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cai_dat.dart';

/// Từ điển nhập liệu nhanh của TÀI KHOẢN — 26 dòng (A-Z) + định dạng từng
/// dòng (giống hệt hình dạng của bản nội bộ) + công tắc bật/tắt RIÊNG của
/// bộ nhớ này.
class TuDienNhapLieuNhanhDamMay {
  TuDienNhapLieuNhanhDamMay(this.uid);
  final String uid;
  final _db = FirebaseFirestore.instance;

  /// Bản đã tải CHO ĐÚNG TÀI KHOẢN ĐANG ĐĂNG NHẬP, dùng CHUNG xuyên suốt
  /// phiên app — tránh mỗi lần mở modal "Từ điển nhập liệu nhanh" lại gọi
  /// Firestore một lần nữa. Gán lúc đăng nhập (`_dongBoTuDienKhiDangNhapThat`
  /// ở `trang_soan_thao.dart`), xoá lúc đăng xuất.
  static TuDienNhapLieuNhanhDamMay? dungChung;

  DocumentReference<Map<String, dynamic>> get _vanBan =>
      _db.collection('users').doc(uid).collection('tuDienDamMay').doc('nhapLieuNhanh');

  List<String> dong = List<String>.filled(26, '');
  List<String?> dinhDang = List<String?>.filled(26, null);
  bool bat = false;

  /// `true` sau khi `tai()` chạy xong lần đầu (dù lấy được từ Firestore hay
  /// chỉ từ cache) — nơi gọi dùng để biết đã có dữ liệu thật để hiển thị,
  /// chưa gọi `tai()` thì vẫn là 26 dòng trống/tắt mặc định.
  bool daTai = false;

  /// `true` nếu cả 26 dòng đều trống (bỏ khoảng trắng) — dùng để quyết định
  /// lúc đăng nhập có tự bật bộ nhớ Đám mây hay không (xem yêu cầu: tài
  /// khoản có ÍT NHẤT một dòng không trống thì tự bật, tắt bộ nhớ Nội bộ).
  bool get trong => dong.every((d) => d.trim().isEmpty);

  static const _tienToKhoaCache = 'ghi_noi_cache_tu_dien_nhanh_dam_may_';
  String get _khoaCache => '$_tienToKhoaCache$uid';

  Future<void> tai() async {
    try {
      final snap = await _vanBan.get();
      _ganTu(snap.data());
      unawaited(_ghiCacheDia());
    } catch (_) {
      final kho = await SharedPreferences.getInstance();
      final tho = kho.getString(_khoaCache);
      if (tho != null) _ganTu(jsonDecode(tho) as Map<String, dynamic>);
    }
    daTai = true;
  }

  void _ganTu(Map<String, dynamic>? j) {
    if (j == null) return;
    final d = (j['dong'] as List<dynamic>?) ?? const [];
    for (var i = 0; i < 26 && i < d.length; i++) {
      dong[i] = d[i] as String? ?? '';
    }
    final df = (j['dinhDang'] as List<dynamic>?) ?? const [];
    for (var i = 0; i < 26 && i < df.length; i++) {
      dinhDang[i] = df[i] as String?;
    }
    bat = j['bat'] as bool? ?? false;
  }

  Map<String, dynamic> _toJson() => {'dong': dong, 'dinhDang': dinhDang, 'bat': bat};

  Future<void> _ghiLenTaiKhoanVaCache() async {
    try {
      await _vanBan.set(_toJson());
    } catch (_) {
      // Mất mạng — bỏ qua lặng lẽ, xem giải thích ở đầu tệp.
    }
    await _ghiCacheDia();
  }

  Future<void> _ghiCacheDia() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaCache, jsonEncode(_toJson()));
  }

  Future<void> ghiDong(int i, String gia) async {
    dong[i] = gia;
    await _ghiLenTaiKhoanVaCache();
  }

  Future<void> ghiDinhDang(int i, String? gia) async {
    dinhDang[i] = gia;
    await _ghiLenTaiKhoanVaCache();
  }

  Future<void> ghiBat(bool gia) async {
    bat = gia;
    await _ghiLenTaiKhoanVaCache();
  }

  /// Ghi lại CẢ 26 dòng + định dạng cùng lúc — dùng cho "Thay đổi thứ tự
  /// giữa các dòng" (đổi nhiều dòng một lượt, tránh ghi Firestore 26 lần).
  Future<void> ghiToanBo(List<String> dongMoi, List<String?> dinhDangMoi) async {
    dong = List<String>.of(dongMoi);
    dinhDang = List<String?>.of(dinhDangMoi);
    await _ghiLenTaiKhoanVaCache();
  }

  static Future<void> xoaCacheOffline(String uid) async {
    final kho = await SharedPreferences.getInstance();
    await kho.remove('$_tienToKhoaCache$uid');
  }
}

/// Từ điển sửa lỗi chính tả của TÀI KHOẢN — danh sách `CapTuDien` + công tắc
/// bật/tắt RIÊNG của bộ nhớ này.
class TuDienChinhTaDamMay {
  TuDienChinhTaDamMay(this.uid);
  final String uid;
  final _db = FirebaseFirestore.instance;

  /// Xem giải thích ở `TuDienNhapLieuNhanhDamMay.dungChung`.
  static TuDienChinhTaDamMay? dungChung;

  DocumentReference<Map<String, dynamic>> get _vanBan =>
      _db.collection('users').doc(uid).collection('tuDienDamMay').doc('chinhTa');

  List<CapTuDien> ds = [];
  bool bat = true;
  bool daTai = false;

  static const _tienToKhoaCache = 'ghi_noi_cache_tu_dien_chinh_ta_dam_may_';
  String get _khoaCache => '$_tienToKhoaCache$uid';

  Future<void> tai() async {
    try {
      final snap = await _vanBan.get();
      _ganTu(snap.data());
      unawaited(_ghiCacheDia());
    } catch (_) {
      final kho = await SharedPreferences.getInstance();
      final tho = kho.getString(_khoaCache);
      if (tho != null) _ganTu(jsonDecode(tho) as Map<String, dynamic>);
    }
    daTai = true;
  }

  void _ganTu(Map<String, dynamic>? j) {
    if (j == null) return;
    final raw = (j['ds'] as List<dynamic>?) ?? const [];
    ds = raw.map(CapTuDien.tuJson).whereType<CapTuDien>().toList();
    bat = j['bat'] as bool? ?? true;
  }

  Map<String, dynamic> _toJson() => {
        'ds': ds.map((c) => c.toJson()).toList(),
        'bat': bat,
      };

  Future<void> _ghiLenTaiKhoanVaCache() async {
    try {
      await _vanBan.set(_toJson());
    } catch (_) {
      // Mất mạng — bỏ qua lặng lẽ, xem giải thích ở đầu tệp.
    }
    await _ghiCacheDia();
  }

  Future<void> _ghiCacheDia() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaCache, jsonEncode(_toJson()));
  }

  Future<void> ghiDs(List<CapTuDien> moi) async {
    ds = moi;
    await _ghiLenTaiKhoanVaCache();
  }

  Future<void> ghiBat(bool gia) async {
    bat = gia;
    await _ghiLenTaiKhoanVaCache();
  }

  static Future<void> xoaCacheOffline(String uid) async {
    final kho = await SharedPreferences.getInstance();
    await kho.remove('$_tienToKhoaCache$uid');
  }
}
