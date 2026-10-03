// Modal xem trước cây thư mục đọc được từ một tệp .zip (chỉ .txt và thư
// mục chứa .txt, xem `lib/zip_thu_muc.dart`) — cho đi dạo thoải mái bên
// trong, KHÔNG cho mở xem nội dung tệp nào, rồi chọn: hủy, đưa thẳng vào
// thư mục đang đứng ở `ManHinhThuMuc`, hoặc để màn hình đó tự đi chọn một
// thư mục khác (xem `KetQuaNhapZip.chonViTriKhac`).

import 'package:flutter/material.dart';

import 'mo_hinh.dart';

enum KetQuaNhapZip { huy, dayVaoHienTai, chonViTriKhac }

class ModalNhapZip extends StatefulWidget {
  const ModalNhapZip({super.key, required this.cayGoc, required this.tenTepZip});

  final List<NutZip> cayGoc;
  final String tenTepZip;

  @override
  State<ModalNhapZip> createState() => _ModalNhapZipState();
}

class _ModalNhapZipState extends State<ModalNhapZip> {
  final List<String> _tenDuongDan = [];
  final List<List<NutZip>> _nganXep = [];
  late List<NutZip> _hienTai;

  @override
  void initState() {
    super.initState();
    _hienTai = widget.cayGoc;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tenDuongDan.isEmpty,
      onPopInvokedWithResult: (daThoat, _) {
        if (!daThoat) _veCha();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tenDuongDan.isEmpty ? widget.tenTepZip : _tenDuongDan.last),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Chỉ hiện các tệp .txt và thư mục có chứa tệp .txt bên trong '
                'tệp vừa chọn — tệp/thư mục khác (nếu tải lên .zip) đã được '
                'ẩn khỏi kết quả.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
            ),
            Expanded(
              child: _hienTai.isEmpty
                  ? const Center(
                      child: Text(
                        'Thư mục trống',
                        style: TextStyle(color: Color(0xFF9AA0A6)),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final n in _hienTai)
                          ListTile(
                            leading: Icon(
                              n.laThuMuc ? Icons.folder : Icons.description_outlined,
                              color: n.laThuMuc ? Colors.amber.shade700 : null,
                            ),
                            title: Text(n.ten),
                            // Chỉ cho đi dạo giữa các thư mục — không có gì
                            // khác để bấm vào trên một tệp.
                            onTap: n.laThuMuc ? () => _vaoThuMuc(n) : null,
                          ),
                      ],
                    ),
            ),
            Material(
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
