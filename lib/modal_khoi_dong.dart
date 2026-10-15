// (YÊU CẦU MỚI) Modal "Khi khởi động App: Mở tệp..." — ba lựa chọn (chỉ
// chọn được MỘT): mở tệp đang soạn thảo gần đây nhất (mặc định), mở một
// tệp TRỐNG trong một thư mục chỉ định, hoặc mở đúng một tệp cố định. Áp
// dụng lúc khởi động app — xem `main.dart`/`khoi_dong_tep.dart`.

import 'package:flutter/material.dart';

import 'cai_dat.dart';
import 'khoi_dong_tep.dart';
import 'kho_du_lieu.dart';
import 'mo_hinh.dart';

const _mauChinh = Color(0xFF1A73E8);

Future<void> moModalKhoiDong(
  BuildContext context, {
  required CaiDat caiDat,
  required KhoDuLieu khoNoiBo,
  required KhoDuLieu khoHienTai,
  required GhiChuFile ghiChuHienTai,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _ManHinhCaiDatKhoiDong(
        caiDat: caiDat,
        khoNoiBo: khoNoiBo,
        khoHienTai: khoHienTai,
        ghiChuHienTai: ghiChuHienTai,
      ),
    ),
  );
}

class _ManHinhCaiDatKhoiDong extends StatefulWidget {
  const _ManHinhCaiDatKhoiDong({
    required this.caiDat,
    required this.khoNoiBo,
    required this.khoHienTai,
    required this.ghiChuHienTai,
  });

  final CaiDat caiDat;
  final KhoDuLieu khoNoiBo;
  final KhoDuLieu khoHienTai;
  final GhiChuFile ghiChuHienTai;

  @override
  State<_ManHinhCaiDatKhoiDong> createState() => _ManHinhCaiDatKhoiDongState();
}

class _ManHinhCaiDatKhoiDongState extends State<_ManHinhCaiDatKhoiDong> {
  late String _kieu;

  // Lựa chọn 2 — thư mục chứa tệp trống.
  KhoDuLieu? _thuMucKho;
  String? _thuMucId;

  // Lựa chọn 3 — tệp cố định (dùng chung cho A/B).
  KhoDuLieu? _tepKho;
  String? _tepId;

  @override
  void initState() {
    super.initState();
    final c = widget.caiDat;
    _kieu = c.kieuMoKhiKhoiDong;

    if (c.khoiDongThuMucLoai == 'noiBo') {
      _thuMucKho = widget.khoNoiBo;
      _thuMucId = c.khoiDongThuMucId;
    } else if (c.khoiDongThuMucLoai == 'damMay') {
      final damMay = KhoDuLieuDamMay.dungChung;
      if (damMay != null && damMay.uid == c.khoiDongThuMucUid) {
        _thuMucKho = damMay;
        _thuMucId = c.khoiDongThuMucId;
      }
    }

    if (c.khoiDongTepLoai == 'noiBo') {
      _tepKho = widget.khoNoiBo;
      _tepId = c.khoiDongTepId;
    } else if (c.khoiDongTepLoai == 'damMay') {
      final damMay = KhoDuLieuDamMay.dungChung;
      if (damMay != null && damMay.uid == c.khoiDongTepUid) {
        _tepKho = damMay;
        _tepId = c.khoiDongTepId;
      }
    }
  }

  bool get _tepHienTaiLaDamMay => widget.khoHienTai is KhoDuLieuDamMay;

  /// Lựa chọn 3 đang chỉ đúng tệp ĐANG MỞ ở trang soạn thảo — đây là ranh
  /// giới hiển thị giữa sub-lựa chọn A ("tệp đang soạn thảo") và B ("chọn
  /// tệp trong cây thư mục"); cả hai cùng ghi vào ĐÚNG MỘT chỗ lưu
  /// (`khoiDongTep*`), chỉ khác cách lấy được tệp đó.
  bool get _laSubA {
    if (_tepKho == null || _tepId != widget.ghiChuHienTai.id) return false;
    final tepLaDamMay = _tepKho is KhoDuLieuDamMay;
    return tepLaDamMay == _tepHienTaiLaDamMay;
  }

  Future<void> _luu() async {
    final c = widget.caiDat;
    c.kieuMoKhiKhoiDong = _kieu;
    if (_thuMucKho == null || _thuMucId == null) {
      c.khoiDongThuMucLoai = null;
      c.khoiDongThuMucId = null;
      c.khoiDongThuMucUid = null;
    } else {
      final laDamMay = _thuMucKho is KhoDuLieuDamMay;
      c.khoiDongThuMucLoai = laDamMay ? 'damMay' : 'noiBo';
      c.khoiDongThuMucId = _thuMucId;
      c.khoiDongThuMucUid = laDamMay ? (_thuMucKho as KhoDuLieuDamMay).uid : null;
    }
    if (_tepKho == null || _tepId == null) {
      c.khoiDongTepLoai = null;
      c.khoiDongTepId = null;
      c.khoiDongTepUid = null;
    } else {
      final laDamMay = _tepKho is KhoDuLieuDamMay;
      c.khoiDongTepLoai = laDamMay ? 'damMay' : 'noiBo';
      c.khoiDongTepId = _tepId;
      c.khoiDongTepUid = laDamMay ? (_tepKho as KhoDuLieuDamMay).uid : null;
    }
    await c.luuCaiDatKhoiDong();
  }

  /// `true` nếu đổi [_kieu] (hay chọn thư mục/tệp mới) rồi gọi [_luu] ngay
  /// được — lựa chọn 1 luôn hợp lệ; lựa chọn 2/3 cần đã có thư mục/tệp
  /// kèm theo (đúng yêu cầu "bấm vào mà không chọn kèm theo thì không cho
  /// lưu").
  bool _hopLe(String kieu) {
    switch (kieu) {
      case 'tepTrong':
        return _thuMucKho != null && _thuMucId != null;
      case 'tepChiDinh':
        return _tepKho != null && _tepId != null;
      default:
        return true;
    }
  }

  Future<void> _datKieu(String kieu) async {
    setState(() => _kieu = kieu);
    if (_hopLe(kieu)) await _luu();
  }

  Future<void> _chonThuMuc() async {
    final kq = await moChonKhoiDong(
      context,
      khoNoiBo: widget.khoNoiBo,
      mode: ModeChonKhoiDong.thuMuc,
    );
    if (kq == null || !mounted) return;
    setState(() {
      _thuMucKho = kq.kho;
      _thuMucId = kq.id;
    });
    if (_kieu == 'tepTrong') await _luu();
  }

  Future<void> _chonTepTuCay() async {
    final kq = await moChonKhoiDong(
      context,
      khoNoiBo: widget.khoNoiBo,
      mode: ModeChonKhoiDong.tep,
    );
    if (kq == null || !mounted) return;
    setState(() {
      _tepKho = kq.kho;
      _tepId = kq.id;
    });
    if (_kieu == 'tepChiDinh') await _luu();
  }

  /// Tự ghim ĐÚNG tệp đang mở ở trang soạn thảo (sub-lựa chọn A).
  Future<void> _chonTepDangSoanThao() async {
    setState(() {
      _tepKho = widget.khoHienTai;
      _tepId = widget.ghiChuHienTai.id;
    });
    if (_kieu == 'tepChiDinh') await _luu();
  }

  /// Đường dẫn đầy đủ (từ gốc) của thư mục [id] trong [kho] — "Tên gốc" (Bộ
  /// nhớ Nội bộ/Bộ nhớ trên đám mây) rồi tới từng thư mục cha, cách nhau
  /// " / ". `null` nếu [id] không còn tồn tại (đã xoá) hay không rõ.
  String? _duongDanThuMuc(KhoDuLieu kho, String id) {
    final goc = kho is KhoDuLieuDamMay ? 'Bộ nhớ trên đám mây' : 'Bộ nhớ Nội bộ';
    if (id == thuMucGoc) return goc;
    final cac = <String>[];
    var hienTai = kho.timThuMuc(id);
    if (hienTai == null) return null;
    while (hienTai != null) {
      cac.insert(0, hienTai.ten);
      hienTai = hienTai.chaId == thuMucGoc ? null : kho.timThuMuc(hienTai.chaId);
    }
    return '$goc / ${cac.join(' / ')}';
  }

  /// Cùng vai trò với [_duongDanThuMuc], cho một TỆP — thêm tên tệp vào
  /// cuối đường dẫn thư mục cha của nó.
  String? _duongDanTep(KhoDuLieu kho, String id) {
    final g = kho.timGhiChu(id);
    if (g == null) return null;
    final duongDanCha = _duongDanThuMuc(kho, g.chaId);
    if (duongDanCha == null) return null;
    return '$duongDanCha / ${g.ten}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _mauChinh,
        foregroundColor: Colors.white,
        title: const Text('Khi khởi động App: Mở tệp...'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text(
              'Mỗi khi vào lại App, thì sẽ vào trong nội dung soạn thảo của '
              'tệp nào?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'ganDayNhat',
              groupValue: _kieu,
              activeColor: _mauChinh,
              title: const Text('Mở tệp đang soạn thảo gần đây nhất'),
              onChanged: (v) => _datKieu(v!),
            ),
            const Divider(height: 8),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'tepTrong',
              groupValue: _kieu,
              activeColor: _mauChinh,
              title: const Text('Mở tệp trống'),
              onChanged: (v) => _datKieu(v!),
            ),
            if (_kieu == 'tepTrong')
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 8),
                child: _nutChonViTri(
                  nhanKhiChua: 'Chọn thư mục cụ thể cho tệp rỗng',
                  duongDan: _thuMucKho != null && _thuMucId != null
                      ? _duongDanThuMuc(_thuMucKho!, _thuMucId!)
                      : null,
                  onTap: _chonThuMuc,
                ),
              ),
            const Divider(height: 8),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'tepChiDinh',
              groupValue: _kieu,
              activeColor: _mauChinh,
              title: const Text('Mở tệp được chỉ định'),
              onChanged: (v) => _datKieu(v!),
            ),
            if (_kieu == 'tepChiDinh')
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      value: true,
                      groupValue: _laSubA,
                      activeColor: _mauChinh,
                      title: Text('Mở tệp ${widget.ghiChuHienTai.ten} đang soạn thảo'),
                      onChanged: (_) => _chonTepDangSoanThao(),
                    ),
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      value: false,
                      groupValue: _laSubA,
                      activeColor: _mauChinh,
                      title: const Text('Chọn tệp trong cây thư mục'),
                      onChanged: (_) {}, // Chỉ bấm nút "Chọn tệp" bên dưới mới có tác dụng.
                    ),
                    if (!_laSubA)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, bottom: 8),
                        child: _nutChonViTri(
                          nhanKhiChua: 'Chọn tệp',
                          duongDan: _tepKho != null && _tepId != null
                              ? _duongDanTep(_tepKho!, _tepId!)
                              : null,
                          onTap: _chonTepTuCay,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nutChonViTri({
    required String nhanKhiChua,
    required String? duongDan,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(duongDan ?? nhanKhiChua),
    );
  }
}
