// Modal "Thùng rác Bộ nhớ Nội bộ": xem, khôi phục hoặc xoá vĩnh viễn các thư
// mục/ghi chú đã "Chuyển vào thùng rác" — xem các hàm liên quan trong
// `lib/kho_du_lieu.dart` (`mucTrongThungRac`, `khoiPhucThuMuc`,
// `khoiPhucGhiChu`, `xoaThuMuc`, `xoaGhiChu`, `donDepThungRacQuaHan`).

import 'package:flutter/material.dart';

import 'kho_du_lieu.dart';
import 'mo_hinh.dart';

/// Lấp đầy màn hình (`MaterialPageRoute` bên gọi). Trả về
/// `({laThuMuc, id})` khi người dùng bấm "Đến vị trí vừa được khôi phục" —
/// bên gọi (`ManHinhThuMuc`) nhảy thẳng tới đó; trả về `null` nếu chỉ đóng
/// modal bình thường (bấm nút đóng, hoặc chỉ bấm "Đã hiểu").
class ModalThungRac extends StatefulWidget {
  const ModalThungRac({super.key, required this.kho});

  final KhoDuLieu kho;

  @override
  State<ModalThungRac> createState() => _ModalThungRacState();
}

class _ModalThungRacState extends State<ModalThungRac> {
  KhoDuLieu get _kho => widget.kho;

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
    ds.add('Bộ nhớ Nội bộ');
    return ds.reversed.join(' / ');
  }

  String _dinhDangThoiGian(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(t.day)}/${pad(t.month)}/${t.year} '
        '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
  }

  Future<void> _moMenuMuc(
    BuildContext context,
    ({bool laThuMuc, String id, String ten, int? mau, DateTime thoiGianXoa})
        muc,
  ) async {
    final hanhDong = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Khôi phục về vị trí cũ'),
              onTap: () => Navigator.of(ctx).pop('khoi_phuc'),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: Colors.red.shade600),
              title: Text('Xoá vĩnh viễn',
                  style: TextStyle(color: Colors.red.shade600)),
              onTap: () => Navigator.of(ctx).pop('xoa_vinh_vien'),
            ),
          ],
        ),
      ),
    );
    if (hanhDong == null || !mounted) return;
    if (hanhDong == 'khoi_phuc') {
      await _khoiPhuc(muc);
    } else {
      await _xoaVinhVien(muc);
    }
  }

  Future<void> _khoiPhuc(
    ({bool laThuMuc, String id, String ten, int? mau, DateTime thoiGianXoa})
        muc,
  ) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restore_outlined, size: 28),
        title: const Text('Khôi phục?'),
        content: Text('Khôi phục "${muc.ten}" về vị trí cũ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Khôi phục'),
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
        title: Text('${muc.laThuMuc ? "Thư mục" : "Tệp"} "${muc.ten}" '
            'đã được khôi phục thành công'),
        content: Text('Ở tại vị trí: $diaChi'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Đã hiểu'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đến vị trí vừa được khôi phục'),
          ),
        ],
      ),
    );
    if (diToiNoiVuaKhoiPhuc == true && mounted) {
      Navigator.of(context).pop((laThuMuc: muc.laThuMuc, id: muc.id));
    }
  }

  Future<void> _xoaVinhVien(
    ({bool laThuMuc, String id, String ten, int? mau, DateTime thoiGianXoa})
        muc,
  ) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, size: 28),
        title: const Text('Xoá vĩnh viễn?'),
        content: Text(
          'Xoá vĩnh viễn "${muc.ten}"'
          '${muc.laThuMuc ? " và toàn bộ nội dung bên trong nó" : ""}. '
          'Không thể khôi phục lại được nữa. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Xoá vĩnh viễn'),
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

  @override
  Widget build(BuildContext context) {
    final ds = _kho.mucTrongThungRac;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác Bộ nhớ Nội bộ'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ds.isEmpty
          ? const Center(
              child: Text(
                'Thùng rác trống',
                style: TextStyle(color: Color(0xFF9AA0A6)),
              ),
            )
          : ListView.builder(
              itemCount: ds.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Mỗi mục chỉ được giữ tối đa 30 ngày trong thùng rác, '
                      'quá hạn sẽ tự xoá vĩnh viễn. Không thể xem nội dung '
                      'bên trong — chỉ có thể khôi phục hoặc xoá vĩnh viễn.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
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
                  subtitle: Text('Đã xoá lúc ${_dinhDangThoiGian(muc.thoiGianXoa)}'),
                  onTap: () => _moMenuMuc(context, muc),
                  trailing: const Icon(Icons.more_vert),
                );
              },
            ),
    );
  }
}
