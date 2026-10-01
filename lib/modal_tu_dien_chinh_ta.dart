// Modal "Từ điển sửa lỗi chính tả của bạn" — mở từ menu "Tài khoản của
// bạn", ngay dưới "Cài đặt hiển thị và tự động sửa". Người dùng tự khai các
// cặp (từ hay gõ sai thường gặp / từ thay vào) — app tự quét văn bản, gạch
// vàng lượn sóng những từ khớp (xem `_boDieuKhien.tuDien` trong
// trang_soan_thao.dart), bấm vào để thay/xoá.

import 'dart:async';

import 'package:flutter/material.dart';

import 'cai_dat.dart';

Future<void> moModalTuDienChinhTa(BuildContext context, CaiDat caiDat) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ThanTuDienChinhTa(caiDat: caiDat),
  );
}

class _ThanTuDienChinhTa extends StatefulWidget {
  const _ThanTuDienChinhTa({required this.caiDat});
  final CaiDat caiDat;

  @override
  State<_ThanTuDienChinhTa> createState() => _ThanTuDienChinhTaState();
}

class _ThanTuDienChinhTaState extends State<_ThanTuDienChinhTa> {
  /// Tham chiếu THẬT tới `caiDat.tuDienChinhTa` — thêm/xoá thẳng vào đây là
  /// đã "lưu" cho cả app (trang soạn thảo đọc đúng danh sách này mỗi lần
  /// quét), chỉ cần gọi thêm `luuTuDienChinhTa()` để ghi xuống đĩa.
  late List<CapTuDien> _ds;
  final Map<CapTuDien, TextEditingController> _oLoi = {};
  final Map<CapTuDien, TextEditingController> _oThayThe = {};
  Timer? _henLuu;

  @override
  void initState() {
    super.initState();
    _ds = widget.caiDat.tuDienChinhTa;
    // CHỈ sắp xếp lại đúng lúc MỞ modal (không sắp lại mỗi lần gõ — gõ dở
    // một từ mà hàng tự nhảy chỗ thì rất khó chịu).
    _ds.sort((a, b) => a.loi.trim().toLowerCase().compareTo(b.loi.trim().toLowerCase()));
    for (final c in _ds) {
      _oLoi[c] = TextEditingController(text: c.loi);
      _oThayThe[c] = TextEditingController(text: c.thayThe);
    }
  }

  @override
  void dispose() {
    _henLuu?.cancel();
    for (final o in _oLoi.values) {
      o.dispose();
    }
    for (final o in _oThayThe.values) {
      o.dispose();
    }
    super.dispose();
  }

  /// Tự lưu xuống đĩa 500ms sau lần gõ cuối — không cần nút "Lưu" riêng,
  /// đúng yêu cầu "mỗi lần thao tác thì hệ thống tự động lưu".
  void _datLuu() {
    _henLuu?.cancel();
    _henLuu = Timer(const Duration(milliseconds: 500), () {
      widget.caiDat.luuTuDienChinhTa();
    });
  }

  void _themCap() {
    setState(() {
      final c = CapTuDien(loi: '');
      _ds.add(c);
      _oLoi[c] = TextEditingController();
      _oThayThe[c] = TextEditingController();
    });
  }

  void _xoaCap(CapTuDien c) {
    setState(() {
      _ds.remove(c);
      _oLoi.remove(c)?.dispose();
      _oThayThe.remove(c)?.dispose();
    });
    widget.caiDat.luuTuDienChinhTa();
  }

  Widget _oNhap({
    required String nhan,
    required TextEditingController controller,
    required String goiY,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nhan,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: goiY,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Xoá chữ này',
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final banPhim = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: banPhim),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Từ điển sửa lỗi chính tả của bạn',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 10),
            const Text(
              'App tự quét văn bản — từ nào khớp "Từ bị lỗi chính tả hay '
              'gặp" sẽ được gạch vàng lượn sóng, bấm vào để thay/xoá nhanh. '
              'Để trống "Từ thay thế vào" nghĩa là đề xuất xoá hẳn từ đó.',
              style: TextStyle(height: 1.5, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _themCap,
                icon: const Icon(Icons.add),
                label: const Text('Thêm cặp từ'),
              ),
            ),
            const SizedBox(height: 12),
            for (final c in _ds) ...[
              const Divider(height: 24),
              _oNhap(
                nhan: 'Từ bị lỗi chính tả hay gặp',
                controller: _oLoi[c]!,
                goiY: 'Ví dụ: vd, mik, ...',
                onChanged: (gia) {
                  c.loi = gia;
                  _datLuu();
                },
              ),
              const SizedBox(height: 10),
              _oNhap(
                nhan: 'Từ thay thế vào',
                controller: _oThayThe[c]!,
                goiY: 'Để trống = đề xuất xoá',
                onChanged: (gia) {
                  c.thayThe = gia;
                  _datLuu();
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _xoaCap(c),
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
                  label: Text('Xoá cặp từ', style: TextStyle(color: Colors.red.shade600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
