// Modal "Thùng rác Bộ nhớ Nội bộ": xem, khôi phục hoặc xoá vĩnh viễn các thư
// mục/ghi chú đã "Chuyển vào thùng rác" — xem các hàm liên quan trong
// `lib/kho_du_lieu.dart` (`mucTrongThungRac`, `khoiPhucThuMuc`,
// `khoiPhucGhiChu`, `xoaThuMuc`, `xoaGhiChu`, `donDepThungRacQuaHan`).

import 'package:flutter/material.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'kho_du_lieu.dart';
import 'mo_hinh.dart';
import 'modal_thong_tin_muc.dart';
import 'ngon_ngu.dart';

typedef _MucThungRac = ({
  bool laThuMuc,
  String id,
  String ten,
  int? mau,
  String chaId,
  DateTime thoiGianXoa,
});

/// Lấp đầy màn hình (`MaterialPageRoute` bên gọi). Trả về
/// `({laThuMuc, id})` khi người dùng bấm "Đến vị trí vừa được khôi phục" —
/// bên gọi (`ManHinhThuMuc`) nhảy thẳng tới đó; trả về `null` nếu chỉ đóng
/// modal bình thường (bấm nút đóng, hoặc chỉ bấm "Đã hiểu").
class ModalThungRac extends StatefulWidget {
  const ModalThungRac({super.key, required this.kho, this.laDamMay = false});

  final KhoDuLieu kho;

  /// (YÊU CẦU MỚI — "Thùng rác Đám mây") `true` khi [kho] là
  /// `KhoDuLieuDamMay` — chỉ đổi chữ nghĩa hiển thị ("Nội bộ" → "Đám mây")
  /// và màu nền; dữ liệu đọc/ghi vẫn luôn là CHÍNH `kho` được truyền vào
  /// (mỗi `KhoDuLieu`/`KhoDuLieuDamMay` tự giữ `thuMuc`/`ghiChu` riêng của
  /// nó, nên thùng rác của 2 bộ nhớ đã tách biệt tự nhiên theo đối tượng,
  /// không cần thêm trường "nguồn" nào).
  final bool laDamMay;

  @override
  State<ModalThungRac> createState() => _ModalThungRacState();
}

class _ModalThungRacState extends State<ModalThungRac> {
  KhoDuLieu get _kho => widget.kho;
  bool get _laDamMay => widget.laDamMay;
  String get _tenBoNho => _laDamMay ? 'Bộ nhớ Đám mây' : 'Bộ nhớ Nội bộ';
  String get _tenThungRac => _laDamMay ? 'Thùng rác Đám mây' : 'Thùng rác Bộ nhớ Nội bộ';

  /// Địa chỉ đầy đủ (người đọc được) của một thư mục, dùng để báo "đã khôi
  /// phục về vị trí ..." — ví dụ "Bộ nhớ Nội bộ / Thư mục A / Thư mục con".
  String _duongDanHienThi(String chaId) {
    final ds = <String>[];
    var hienTai = chaId;
    while (hienTai != thuMucGoc) {
      final t = _kho.timThuMuc(hienTai);
      if (t == null) break;
      ds.add(t.ten);
      hienTai = t.chaId;
    }
    ds.add(_tenBoNho);
    return ds.reversed.join(' / ');
  }

  String _dinhDangThoiGian(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(t.day)}/${pad(t.month)}/${t.year} '
        '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
  }

  // (YÊU CẦU MỚI) Thông tin chi tiết — y chang modal bên ngoài thùng rác,
  // cộng thêm dòng "Vị trí: ..." làm dòng ĐẦU TIÊN.
  void _xemThongTinChiTiet(_MucThungRac muc) {
    final diaChi = _duongDanHienThi(muc.chaId);
    if (muc.laThuMuc) {
      hienThongTinThuMuc(context, _kho, id: muc.id, ten: muc.ten, viTri: diaChi);
    } else {
      final g = _kho.timGhiChu(muc.id);
      hienThongTinGhiChu(
        context,
        ten: muc.ten,
        noiDung: g?.noiDung ?? '',
        viTri: diaChi,
      );
    }
  }

  Future<void> _moMenuMuc(BuildContext context, _MucThungRac muc) async {
    final hanhDong = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: Text(Ch.khoiPhucVeViTriCu(ngonNguHienTai.value)),
              onTap: () => Navigator.of(ctx).pop('khoi_phuc'),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: Colors.red.shade600),
              title: Text(Ch.xoaVinhVien(ngonNguHienTai.value),
                  style: TextStyle(color: Colors.red.shade600)),
              onTap: () => Navigator.of(ctx).pop('xoa_vinh_vien'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(Ch.thongTinChiTiet(ngonNguHienTai.value)),
              onTap: () => Navigator.of(ctx).pop('thong_tin'),
            ),
          ],
        ),
      ),
    );
    if (hanhDong == null || !mounted) return;
    if (hanhDong == 'khoi_phuc') {
      await _khoiPhuc(muc);
    } else if (hanhDong == 'xoa_vinh_vien') {
      await _xoaVinhVien(muc);
    } else {
      _xemThongTinChiTiet(muc);
    }
  }

  Future<void> _khoiPhuc(_MucThungRac muc) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restore_outlined, size: 28),
        title: Text(Ch.khoiPhucHoi(ngonNguHienTai.value)),
        content: Text(Ch.khoiPhucVeViTriCuHoi(ngonNguHienTai.value, muc.ten)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(Ch.khong(ngonNguHienTai.value)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(Ch.khoiPhuc(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) return;

    final noiVe = muc.laThuMuc
        ? _kho.khoiPhucThuMuc(muc.id)
        : _kho.khoiPhucGhiChu(muc.id);
    await _kho.luu();
    if (!mounted) return;
    setState(() {});

    final diaChi = _duongDanHienThi(noiVe);
    final diToiNoiVuaKhoiPhuc = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
        title: Text(Ch.daKhoiPhucThanhCong(ngonNguHienTai.value, muc.laThuMuc, muc.ten)),
        content: Text(Ch.oTaiViTri(ngonNguHienTai.value, diaChi)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(Ch.daHieu(ngonNguHienTai.value)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(Ch.denViTriVuaDuocKhoiPhuc(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
    if (diToiNoiVuaKhoiPhuc == true && mounted) {
      Navigator.of(context).pop((laThuMuc: muc.laThuMuc, id: muc.id));
    }
  }

  Future<void> _xoaVinhVien(_MucThungRac muc) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, size: 28),
        title: Text(Ch.xoaVinhVienHoi(ngonNguHienTai.value)),
        content: Text(
          Ch.xoaVinhVienXacNhan(ngonNguHienTai.value, muc.laThuMuc, muc.ten),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(Ch.khong(ngonNguHienTai.value)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: Text(Ch.xoaVinhVien(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) return;
    setState(() {
      if (muc.laThuMuc) {
        _kho.xoaThuMuc(muc.id);
      } else {
        _kho.xoaGhiChu(muc.id);
      }
    });
    await _kho.luu();
  }

  // (YÊU CẦU MỚI) "Tìm kiếm trong Thùng rác bộ nhớ nội bộ" — y chang UI/
  // logic tìm kiếm ở ngoài cây thư mục, chỉ khác tiêu đề và menu 3 lựa chọn
  // khi bấm vào kết quả (dùng lại đúng `_moMenuMuc` ở trên).
  Future<void> _moTimKiemThungRac() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _ManHinhTimKiemThungRac(
        kho: _kho,
        onMoMenu: _moMenuMuc,
        dinhDangThoiGian: _dinhDangThoiGian,
        tenThungRac: _tenThungRac,
        laDamMay: _laDamMay,
      ),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ds = _kho.mucTrongThungRac;
    return Scaffold(
      backgroundColor: _laDamMay ? const Color(0xFFE6F4EA) : null,
      appBar: AppBar(
        backgroundColor: _laDamMay ? const Color(0xFFE6F4EA) : null,
        title: Text(_tenThungRac),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: Ch.dong(ngonNguHienTai.value),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // (YÊU CẦU MỚI) Nút tìm kiếm — sát mép phải, cùng dòng với tiêu đề.
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: Ch.timKiemTrongThungRac(ngonNguHienTai.value),
            onPressed: _moTimKiemThungRac,
          ),
        ],
      ),
      body: ds.isEmpty
          ? Center(
              child: Text(
                Ch.thungRacTrong(ngonNguHienTai.value),
                style: const TextStyle(color: Color(0xFF9AA0A6)),
              ),
            )
          : ListView.builder(
              itemCount: ds.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      Ch.giaiThichThungRacGiuToiDa30Ngay(ngonNguHienTai.value),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                    ),
                  );
                }
                final muc = ds[i - 1];
                return ListTile(
                  leading: Icon(
                    muc.laThuMuc ? Icons.folder : Icons.description_outlined,
                    color: muc.laThuMuc ? Colors.amber.shade700 : null,
                  ),
                  title: Text(
                    muc.ten,
                    style: muc.mau != null ? TextStyle(color: Color(muc.mau!)) : null,
                  ),
                  subtitle: Text(Ch.daXoaLuc(ngonNguHienTai.value, _dinhDangThoiGian(muc.thoiGianXoa))),
                  onTap: () => _moMenuMuc(context, muc),
                  trailing: const Icon(Icons.more_vert),
                );
              },
            ),
    );
  }
}

/// Bỏ dấu tiếng Việt + hạ chữ thường — dùng cho tìm kiếm trong thùng rác
/// khớp cả khi gõ không dấu (y chang bản gốc ở `man_hinh_thu_muc.dart`,
/// nhân bản ở đây vì `_` là riêng theo từng tệp trong Dart).
String _boDauTiengVietThungRac(String s) {
  const banDo = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
  };
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    buf.write(banDo[ch] ?? ch);
  }
  return buf.toString();
}

/// "Tìm kiếm trong Thùng rác bộ nhớ nội bộ" — y chang UI/logic "Tìm kiếm
/// trong này" ở ngoài cây thư mục; chỉ khác là bấm vào kết quả mở đúng
/// menu 3 lựa chọn của thùng rác (Khôi phục/Xoá vĩnh viễn/Thông tin chi
/// tiết), qua [onMoMenu].
class _ManHinhTimKiemThungRac extends StatefulWidget {
  const _ManHinhTimKiemThungRac({
    required this.kho,
    required this.onMoMenu,
    required this.dinhDangThoiGian,
    required this.tenThungRac,
    required this.laDamMay,
  });

  final KhoDuLieu kho;
  final void Function(BuildContext, _MucThungRac) onMoMenu;
  final String Function(DateTime) dinhDangThoiGian;
  final String tenThungRac;
  final bool laDamMay;

  @override
  State<_ManHinhTimKiemThungRac> createState() => _ManHinhTimKiemThungRacState();
}

class _ManHinhTimKiemThungRacState extends State<_ManHinhTimKiemThungRac> {
  final _oTimKiem = TextEditingController();

  @override
  void dispose() {
    _oTimKiem.dispose();
    super.dispose();
  }

  List<_MucThungRac> _ketQua() {
    final tuKhoa = _oTimKiem.text.trim();
    if (tuKhoa.isEmpty) return const [];
    final tuKhoaThuong = tuKhoa.toLowerCase();
    final tuKhoaKhongDau = _boDauTiengVietThungRac(tuKhoa);
    final coDau = <_MucThungRac>[];
    final khongDau = <_MucThungRac>[];
    for (final muc in widget.kho.mucTrongThungRac) {
      if (muc.ten.toLowerCase().contains(tuKhoaThuong)) {
        coDau.add(muc);
      } else if (_boDauTiengVietThungRac(muc.ten).contains(tuKhoaKhongDau)) {
        khongDau.add(muc);
      }
    }
    int soTen(_MucThungRac a, _MucThungRac b) =>
        a.ten.toLowerCase().compareTo(b.ten.toLowerCase());
    coDau.sort(soTen);
    khongDau.sort(soTen);
    return [...coDau, ...khongDau];
  }

  @override
  Widget build(BuildContext context) {
    final coGoTim = _oTimKiem.text.trim().isNotEmpty;
    final ketQua = _ketQua();
    return Scaffold(
      backgroundColor: widget.laDamMay ? const Color(0xFFE6F4EA) : null,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: const Color(0xFFF1F3F4),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Tìm kiếm trong "${widget.tenThungRac}"',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Material(
              color: const Color(0xFFF1F3F4),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _oTimKiem,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: Ch.nhapTenTepHoacThuMuc(ngonNguHienTai.value),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: Ch.xoaTuKhoa(ngonNguHienTai.value),
                      onPressed: () => setState(() => _oTimKiem.clear()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
                      child: const Text('Tắt'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: !coGoTim
                  ? const Center(
                      child: Text(
                        'Nhập ký tự để tìm kiếm',
                        style: TextStyle(color: Color(0xFF9AA0A6)),
                      ),
                    )
                  : ketQua.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy kết quả',
                            style: TextStyle(color: Color(0xFF9AA0A6)),
                          ),
                        )
                      : ListView(
                          children: [
                            for (final muc in ketQua)
                              ListTile(
                                leading: Icon(
                                  muc.laThuMuc
                                      ? Icons.folder
                                      : Icons.description_outlined,
                                  color: muc.laThuMuc ? Colors.amber.shade700 : null,
                                ),
                                title: Text(
                                  muc.ten,
                                  style: muc.mau != null
                                      ? TextStyle(color: Color(muc.mau!))
                                      : null,
                                ),
                                subtitle: Text(
                                  Ch.daXoaLuc(ngonNguHienTai.value, widget.dinhDangThoiGian(muc.thoiGianXoa)),
                                ),
                                onTap: () => widget.onMoMenu(context, muc),
                                trailing: const Icon(Icons.more_vert),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
