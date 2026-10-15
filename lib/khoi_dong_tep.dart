// (YÊU CẦU MỚI) Bộ chọn thư mục/tệp dùng RIÊNG cho modal "Khi khởi động
// App: Mở tệp..." (xem `modal_khoi_dong.dart`) — màn hình RIÊNG, nhẹ hơn
// `ManHinhThuMuc` (không sửa/xoá/tìm kiếm/nhập zip/chọn nhiều...), chỉ DUYỆT
// cây và CHỌN đúng một thư mục (mode `thuMuc`) hoặc một tệp (mode `tep`),
// dùng CHUNG dữ liệu (`KhoDuLieu`/`KhoDuLieuDamMay`) với màn hình thư mục
// thật — Ngôi nhà chung + ba bộ nhớ hiện đủ, giống hệt cách màn hình thư
// mục thật hiện, để người dùng không thấy lạ.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cai_dat.dart';
import 'kho_du_lieu.dart';
import 'mo_hinh.dart';
import 'thong_bao_giua.dart';

/// (YÊU CẦU MỚI) Quyết định kho + id ghi chú sẽ mở ngay khi app vừa khởi
/// động, theo đúng cài đặt "Khi khởi động App: Mở tệp..." — gọi từ
/// `main.dart`, SAU KHI `khoNoiBo.tai()` VÀ `caiDat.tai()` đã xong.
///
/// [idNoiBoMacDinh] là id mà `khoNoiBo.tai()` tự trả về (ghi chú đang mở
/// lần trước CỦA RIÊNG bộ nhớ nội bộ, hoặc ghi chú đầu tiên/vừa tạo nếu
/// chưa từng mở gì) — dùng làm điểm RƠI VỀ cuối cùng khi mọi lựa chọn
/// khác không áp dụng được (thư mục/tệp đã chọn bị xoá, đổi tài khoản
/// Google, mất mạng mà chưa có cache offline cho ghi chú đám mây...).
Future<(KhoDuLieu, String)> giaiQuyetKhoiDong({
  required KhoDuLieu khoNoiBo,
  required String idNoiBoMacDinh,
  required CaiDat caiDat,
}) async {
  if (caiDat.kieuMoKhiKhoiDong == 'tepTrong') {
    final kq = await _moTepTrong(khoNoiBo: khoNoiBo, caiDat: caiDat);
    if (kq != null) return kq;
  } else if (caiDat.kieuMoKhiKhoiDong == 'tepChiDinh') {
    final kq = await _moTepChiDinh(khoNoiBo: khoNoiBo, caiDat: caiDat);
    if (kq != null) return kq;
  }
  // 'ganDayNhat', hoặc RƠI VỀ từ hai nhánh trên khi không còn áp dụng được
  // (thư mục/tệp đã chọn không còn hợp lệ nữa).
  return _moGanDayNhat(
    khoNoiBo: khoNoiBo,
    idNoiBoMacDinh: idNoiBoMacDinh,
    caiDat: caiDat,
  );
}

/// Trả về kho đám mây đã tải, CHỈ KHI đang đăng nhập ĐÚNG tài khoản yêu
/// cầu (`uidYeuCau`, `null` nghĩa là bất kỳ tài khoản nào cũng được) VÀ
/// tải được (mạng thật, hoặc rơi về cache ngoại tuyến đã có) — `null` ở
/// MỌI trường hợp khác (chưa đăng nhập, đổi tài khoản, mất mạng mà chưa
/// từng có cache). Dùng `authStateChanges().first` (không đọc thẳng
/// `currentUser`) vì ngay sau `Firebase.initializeApp()`, việc khôi phục
/// phiên đăng nhập đã lưu vẫn đang chạy BẤT ĐỒNG BỘ — đọc `currentUser`
/// quá sớm ở đây dễ thấy `null` dù người dùng THẬT SỰ đã đăng nhập.
Future<KhoDuLieuDamMay?> _taiKhoDamMayNeuCoThe({String? uidYeuCau}) async {
  final nguoiDung = await FirebaseAuth.instance.authStateChanges().first;
  if (nguoiDung == null) return null;
  if (uidYeuCau != null && nguoiDung.uid != uidYeuCau) return null;
  final daCo = KhoDuLieuDamMay.dungChung;
  if (daCo != null && daCo.uid == nguoiDung.uid) return daCo;
  try {
    final kho = KhoDuLieuDamMay(nguoiDung.uid);
    await kho.tai();
    KhoDuLieuDamMay.dungChung = kho;
    return kho;
  } catch (_) {
    return null;
  }
}

Future<(KhoDuLieu, String)?> _moTepTrong({
  required KhoDuLieu khoNoiBo,
  required CaiDat caiDat,
}) async {
  final loai = caiDat.khoiDongThuMucLoai;
  final id = caiDat.khoiDongThuMucId;
  if (loai == null || id == null) return null;
  final kho = loai == 'noiBo'
      ? khoNoiBo
      : await _taiKhoDamMayNeuCoThe(uidYeuCau: caiDat.khoiDongThuMucUid);
  if (kho == null) return null;
  if (id != thuMucGoc) {
    final t = kho.timThuMuc(id);
    if (t == null || t.thoiGianXoa != null) return null;
  }
  final noiDung = kho.noiDungThuMuc(id);
  for (final g in noiDung.ghiChuCon) {
    if (g.noiDung.isEmpty) return (kho, g.id);
  }
  final moi = kho.taoGhiChuMoi(id);
  await kho.luu();
  return (kho, moi.id);
}

Future<(KhoDuLieu, String)?> _moTepChiDinh({
  required KhoDuLieu khoNoiBo,
  required CaiDat caiDat,
}) async {
  final loai = caiDat.khoiDongTepLoai;
  final id = caiDat.khoiDongTepId;
  if (loai == null || id == null) return null;
  final kho = loai == 'noiBo'
      ? khoNoiBo
      : await _taiKhoDamMayNeuCoThe(uidYeuCau: caiDat.khoiDongTepUid);
  if (kho == null) return null;
  final g = kho.timGhiChu(id);
  if (g == null || g.thoiGianXoa != null) return null;
  return (kho, id);
}

Future<(KhoDuLieu, String)> _moGanDayNhat({
  required KhoDuLieu khoNoiBo,
  required String idNoiBoMacDinh,
  required CaiDat caiDat,
}) async {
  if (caiDat.ganDayNhatDamMayId != null) {
    final kho =
        await _taiKhoDamMayNeuCoThe(uidYeuCau: caiDat.ganDayNhatDamMayUid);
    if (kho != null) {
      final g = kho.timGhiChu(caiDat.ganDayNhatDamMayId!);
      if (g != null && g.thoiGianXoa == null) return (kho, g.id);
    }
  }
  return (khoNoiBo, idNoiBoMacDinh);
}

enum ModeChonKhoiDong { thuMuc, tep }

/// Kết quả chọn — [kho] là kho CHỨA mục đã chọn (bộ nhớ nội bộ thật hoặc
/// `KhoDuLieuDamMay` đã tải), [id] là id thư mục (mode `thuMuc`) hoặc ghi
/// chú (mode `tep`) đã chọn.
class KetQuaChonKhoiDong {
  KetQuaChonKhoiDong({required this.kho, required this.id});
  final KhoDuLieu kho;
  final String id;
}

Future<KetQuaChonKhoiDong?> moChonKhoiDong(
  BuildContext context, {
  required KhoDuLieu khoNoiBo,
  required ModeChonKhoiDong mode,
}) {
  return Navigator.of(context).push<KetQuaChonKhoiDong>(
    MaterialPageRoute(
      builder: (_) => _ManHinhChonKhoiDong(khoNoiBo: khoNoiBo, mode: mode),
    ),
  );
}

class _ManHinhChonKhoiDong extends StatefulWidget {
  const _ManHinhChonKhoiDong({required this.khoNoiBo, required this.mode});
  final KhoDuLieu khoNoiBo;
  final ModeChonKhoiDong mode;

  @override
  State<_ManHinhChonKhoiDong> createState() => _ManHinhChonKhoiDongState();
}

class _ManHinhChonKhoiDongState extends State<_ManHinhChonKhoiDong> {
  /// `null` = đang ở Ngôi nhà chung (chưa chọn bộ nhớ nào).
  KhoDuLieu? _kho;
  String _thuMucHienTaiId = thuMucGoc;

  /// Ngăn xếp (kho lúc đó, id thư mục cha lúc đó) để Lùi lại từng cấp.
  final List<(KhoDuLieu?, String)> _duongDan = [];

  bool _dangTaiDamMay = false;

  bool get _laNgoiNhaChung => _kho == null;

  void _moThuMuc(KhoDuLieu kho, String id) {
    setState(() {
      _duongDan.add((_kho, _thuMucHienTaiId));
      _kho = kho;
      _thuMucHienTaiId = id;
    });
  }

  void _lui() {
    if (_duongDan.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final (khoCu, idCu) = _duongDan.removeLast();
    setState(() {
      _kho = khoCu;
      _thuMucHienTaiId = idCu;
    });
  }

  Future<void> _vaoBoNhoDamMay() async {
    final daCo = KhoDuLieuDamMay.dungChung;
    if (daCo != null) {
      _moThuMuc(daCo, thuMucGoc);
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      hienThongBaoGiua(
        context,
        'Cần đăng nhập Google trước (menu "Tài khoản và Cài đặt" ở trang soạn thảo).',
      );
      return;
    }
    setState(() => _dangTaiDamMay = true);
    try {
      final khoDamMay = KhoDuLieuDamMay(uid);
      await khoDamMay.tai();
      if (!mounted) return;
      KhoDuLieuDamMay.dungChung = khoDamMay;
      setState(() => _dangTaiDamMay = false);
      _moThuMuc(khoDamMay, thuMucGoc);
    } on ChuaCoMangVaChuaCoCacheOffline {
      if (!mounted) return;
      setState(() => _dangTaiDamMay = false);
      hienThongBaoGiua(context, 'Vui lòng kết nối internet.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangTaiDamMay = false);
      hienThongBaoGiua(context, 'Không mở được Bộ nhớ trên đám mây: $e');
    }
  }

  void _baoDangNangCap() {
    hienThongBaoGiua(context, 'Tính năng đang nâng cấp');
  }

  Future<void> _taoThuMucMoi() async {
    final kho = _kho!;
    kho.taoThuMucMoi(_thuMucHienTaiId);
    await kho.luu();
    if (mounted) setState(() {});
  }

  Future<void> _taoTepMoi() async {
    final kho = _kho!;
    kho.taoGhiChuMoi(_thuMucHienTaiId);
    await kho.luu();
    if (mounted) setState(() {});
  }

  void _chonThuMucNay() {
    Navigator.of(context)
        .pop(KetQuaChonKhoiDong(kho: _kho!, id: _thuMucHienTaiId));
  }

  void _chonTep(GhiChuFile g) {
    Navigator.of(context).pop(KetQuaChonKhoiDong(kho: _kho!, id: g.id));
  }

  @override
  Widget build(BuildContext context) {
    final laChonThuMuc = widget.mode == ModeChonKhoiDong.thuMuc;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _lui,
        ),
        title: Text(laChonThuMuc ? 'Chọn thư mục' : 'Chọn tệp'),
        actions: [
          if (!_laNgoiNhaChung)
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'Tạo thư mục mới',
              onPressed: _taoThuMucMoi,
            ),
          if (!_laNgoiNhaChung && !laChonThuMuc)
            IconButton(
              icon: const Icon(Icons.note_add_outlined),
              tooltip: 'Tạo tệp văn bản mới',
              onPressed: _taoTepMoi,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _laNgoiNhaChung ? _xayNgoiNhaChung() : _xayDanhSach(),
          ),
          // (YÊU CẦU MỚI) Chỉ ở mode chọn THƯ MỤC mới có thanh chú thích +
          // nút "Chọn thư mục này" ghim ở đáy — mode chọn TỆP thì bấm thẳng
          // vào dòng tệp là xong, không cần nút riêng.
          if (laChonThuMuc && !_laNgoiNhaChung)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF1F3F4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Mỗi khi khởi động lại App, sẽ vào tệp trống (không có '
                    'ký tự) trong thư mục được chọn, nếu không có tệp nào '
                    'trống thì App sẽ tự động tạo tệp trống.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _chonThuMucNay,
                    child: const Text('Chọn thư mục này'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _xayNgoiNhaChung() {
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.smartphone, color: Colors.blue.shade700),
          title: const Text('Bộ nhớ Nội bộ'),
          onTap: () => _moThuMuc(widget.khoNoiBo, thuMucGoc),
        ),
        ListTile(
          leading: _dangTaiDamMay
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.cloud_outlined, color: Colors.lightBlue.shade400),
          title: const Text('Bộ nhớ trên đám mây'),
          onTap: _dangTaiDamMay ? null : _vaoBoNhoDamMay,
        ),
        ListTile(
          leading: Icon(Icons.folder_shared_outlined, color: Colors.green.shade600),
          title: const Text('Bộ nhớ được chia sẻ với bạn'),
          onTap: _baoDangNangCap,
        ),
      ],
    );
  }

  Widget _xayDanhSach() {
    final kho = _kho!;
    final noiDung = kho.noiDungThuMuc(_thuMucHienTaiId);
    final laChonTep = widget.mode == ModeChonKhoiDong.tep;
    final rong = noiDung.thuMucCon.isEmpty &&
        (!laChonTep || noiDung.ghiChuCon.isEmpty);
    if (rong) {
      return const Center(
        child: Text('Thư mục trống', style: TextStyle(color: Color(0xFF9AA0A6))),
      );
    }
    return ListView(
      children: [
        for (final t in noiDung.thuMucCon)
          ListTile(
            leading: const Icon(Icons.folder, color: Color(0xFFFBBC04)),
            title: Text(t.ten),
            onTap: () => _moThuMuc(kho, t.id),
          ),
        if (laChonTep)
          for (final g in noiDung.ghiChuCon)
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Color(0xFF5F6368)),
              title: Text(g.ten),
              onTap: () => _chonTep(g),
            ),
      ],
    );
  }
}
