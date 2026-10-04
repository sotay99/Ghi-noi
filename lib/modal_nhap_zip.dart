// Modal xem trước các "nguồn" đọc được từ .zip/.txt vừa chọn (xem
// `lib/zip_thu_muc.dart`, `NguonNhap` trong `lib/mo_hinh.dart`) — cho đi
// dạo thoải mái bên trong (KHÔNG cho mở xem nội dung tệp nào), rồi chọn:
// hủy, đưa thẳng vào thư mục đang đứng ở `ManHinhThuMuc`, hoặc để màn
// hình đó tự đi chọn một thư mục khác (`KetQuaNhapZip.chonViTriKhac`).
//
// Nền TÍM NHẠT (tiêu đề + nội dung) — chỉ để phân biệt với các màn hình
// khác, không mang ý nghĩa gì khác.

import 'package:flutter/material.dart';

import 'mo_hinh.dart';

enum KetQuaNhapZip { huy, dayVaoHienTai, chonViTriKhac }

/// Nền/tiêu đề tím nhạt dùng chung cho cả modal này.
const _mauTimNhat = Color(0xFFF3E8FD);
const _mauTimDam = Color(0xFF6B21A8);

class ModalNhapZip extends StatefulWidget {
  const ModalNhapZip({
    super.key,
    required this.nguon,
    this.coTepQuaNang = false,
  });

  final List<NguonNhap> nguon;

  /// true nếu có ít nhất 1 tệp .txt (rời hoặc trong .zip) đã bị bỏ qua vì
  /// nặng hơn `gioiHanTxtByte` — hiện thêm một dòng chú thích.
  final bool coTepQuaNang;

  @override
  State<ModalNhapZip> createState() => _ModalNhapZipState();
}

class _ModalNhapZipState extends State<ModalNhapZip> {
  final List<String> _tenDuongDan = [];
  // `null` ở cuối ngăn xếp nghĩa là "quay lại màn hình gốc" (danh sách
  // gộp nhiều nguồn) — không thể gói trực tiếp một `List<NutZip>` cho
  // trường hợp đó vì màn gốc không phải một cây duy nhất.
  final List<List<NutZip>?> _nganXep = [];
  List<NutZip>? _hienTai; // null = đang ở màn gốc.

  bool get _oGoc => _hienTai == null;

  String get _tieuDeGoc {
    if (widget.nguon.length == 1 && widget.nguon.single.laZip) {
      return widget.nguon.single.tenNguon;
    }
    return 'Các tệp tin và thư mục chuẩn bị nhập vào app';
  }

  void _vaoThuMuc(NutZip n) {
    setState(() {
      _nganXep.add(_hienTai);
      _tenDuongDan.add(n.ten);
      _hienTai = n.con;
    });
  }

  bool _veCha() {
    if (_nganXep.isEmpty) return false;
    setState(() {
      _hienTai = _nganXep.removeLast();
      _tenDuongDan.removeLast();
    });
    return true;
  }

  Widget _dongMuc(NutZip n) {
    return ListTile(
      leading: Icon(
        n.laThuMuc ? Icons.folder : Icons.description_outlined,
        color: n.laThuMuc ? Colors.amber.shade700 : null,
      ),
      title: Text(n.ten),
      // Chỉ cho đi dạo giữa các thư mục — không có gì khác để bấm vào
      // trên một tệp.
      onTap: n.laThuMuc ? () => _vaoThuMuc(n) : null,
    );
  }

  Widget _danhSachGoc() {
    final tepTxtRieng = <NutZip>[];
    final nhomZip = <NguonNhap>[];
    for (final ng in widget.nguon) {
      if (ng.laZip) {
        nhomZip.add(ng);
      } else {
        tepTxtRieng.addAll(ng.goc);
      }
    }

    return ListView(
      children: [
        if (tepTxtRieng.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Tệp TXT riêng lẻ',
              style: TextStyle(fontWeight: FontWeight.bold, color: _mauTimDam),
            ),
          ),
          for (final n in tepTxtRieng) _dongMuc(n),
          const Divider(height: 1),
        ],
        for (final nhom in nhomZip) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              nhom.tenNguon,
              style: const TextStyle(fontWeight: FontWeight.bold, color: _mauTimDam),
            ),
          ),
          if (nhom.goc.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Không có tệp .txt hợp lệ nào trong tệp nén này.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6)),
              ),
            )
          else
            for (final n in nhom.goc) _dongMuc(n),
          const Divider(height: 1),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tenDuongDan.isEmpty,
      onPopInvokedWithResult: (daThoat, _) {
        if (!daThoat) _veCha();
      },
      child: Scaffold(
        backgroundColor: _mauTimNhat,
        appBar: AppBar(
          backgroundColor: _mauTimNhat,
          foregroundColor: _mauTimDam,
          title: Text(_oGoc ? _tieuDeGoc : _tenDuongDan.last),
          leading: _tenDuongDan.isEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(KetQuaNhapZip.huy),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _veCha,
                ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chỉ hiện các tệp .txt (tối đa 2 MB mỗi tệp) và thư mục '
                    'có chứa .txt bên trong tệp vừa chọn — tệp/thư mục khác '
                    'đã được ẩn khỏi kết quả.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                  ),
                  if (widget.coTepQuaNang)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Có ít nhất 1 tệp .txt nặng hơn 2 MB đã bị bỏ qua vì '
                        'dễ làm app giật/lag khi mở.',
                        style: TextStyle(fontSize: 12, color: _mauTimDam),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _oGoc
                  ? _danhSachGoc()
                  : _hienTai!.isEmpty
                      ? const Center(
                          child: Text(
                            'Thư mục trống',
                            style: TextStyle(color: Color(0xFF9AA0A6)),
                          ),
                        )
                      : ListView(
                          children: [for (final n in _hienTai!) _dongMuc(n)],
                        ),
            ),
            Material(
              color: _mauTimNhat,
              elevation: 4,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(KetQuaNhapZip.huy),
                        child: const Text('Hủy kết quả này'),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(KetQuaNhapZip.chonViTriKhac),
                        child: const Text('Chọn vị trí khác'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(KetQuaNhapZip.dayVaoHienTai),
                        child: const Text('Đưa vào thư mục hiện tại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
