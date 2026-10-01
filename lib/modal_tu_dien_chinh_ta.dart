// Trang "Từ điển sửa lỗi chính tả của bạn" — mở từ menu "Tài khoản của
// bạn", ngay dưới "Cài đặt hiển thị và tự động sửa". Người dùng tự khai các
// cặp (từ hay gõ sai thường gặp / từ thay vào) — app tự quét văn bản, gạch
// vàng lượn sóng những từ khớp (xem `_boDieuKhien.tuDien` trong
// trang_soan_thao.dart), bấm vào để thay/xoá.
//
// TOÀN MÀN HÌNH (Navigator.push, có nút X đóng) — ĐÚNG KHUÔN
// `ManHinhTroChuyen` (màn hình chat với AI), không còn là modal đáy màn
// hình nhỏ như bản trước (người dùng chê "xấu quá").

import 'dart:async';

import 'package:flutter/material.dart';

import 'cai_dat.dart';

const _mauChinh = Color(0xFF1A73E8);

Future<void> moModalTuDienChinhTa(BuildContext context, CaiDat caiDat) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _ManHinhTuDienChinhTa(caiDat: caiDat),
    ),
  );
}

class _ManHinhTuDienChinhTa extends StatefulWidget {
  const _ManHinhTuDienChinhTa({required this.caiDat});
  final CaiDat caiDat;

  @override
  State<_ManHinhTuDienChinhTa> createState() => _ManHinhTuDienChinhTaState();
}

class _ManHinhTuDienChinhTaState extends State<_ManHinhTuDienChinhTa> {
  /// Tham chiếu THẬT tới `caiDat.tuDienChinhTa` — thêm/xoá thẳng vào đây là
  /// đã "lưu" cho cả app (trang soạn thảo đọc đúng danh sách này mỗi lần
  /// quét), chỉ cần gọi thêm `luuTuDienChinhTa()` để ghi xuống đĩa.
  late List<CapTuDien> _ds;
  final Map<CapTuDien, TextEditingController> _oLoi = {};
  final Map<CapTuDien, TextEditingController> _oThayThe = {};

  /// Cặp đang hiện cảnh báo "từ thay thế giống hệt từ lỗi" hoặc "từ lỗi bị
  /// trùng với một cặp khác" (mục 5) — vẽ viền đỏ + dòng chữ đỏ ngay dưới ô
  /// liên quan, không chặn gõ (chỉ chặn hoàn thành/rời ô, xem `_oNhap`).
  final Set<CapTuDien> _loiTrungThayThe = {};
  final Set<CapTuDien> _loiTrungTuLoi = {};

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

  /// Mục 4: nút "+ Thêm cặp từ" chỉ hoạt động khi KHÔNG có cặp nào đang
  /// rỗng hoàn toàn (cả từ lỗi lẫn từ thay thế đều trống) — có sẵn một cặp
  /// rỗng rồi thì bắt điền nó trước đã, không cho đẻ thêm cặp rỗng khác.
  bool get _coCapRong => _ds.any((c) => c.loi.trim().isEmpty && c.thayThe.trim().isEmpty);

  void _themCap() {
    if (_coCapRong) return;
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
      _loiTrungThayThe.remove(c);
      _loiTrungTuLoi.remove(c);
    });
    widget.caiDat.luuTuDienChinhTa();
  }

  /// Mục 5: kiểm tra lại TOÀN BỘ danh sách sau mỗi lần gõ — cờ trùng từ lỗi
  /// (so các [CapTuDien.loi] với nhau) và cờ "từ thay thế giống hệt từ lỗi"
  /// của CHÍNH cặp đó. Không xoá chữ người dùng gõ — chỉ đánh dấu cảnh báo,
  /// để họ tự sửa.
  void _kiemTraTrung() {
    _loiTrungThayThe.clear();
    _loiTrungTuLoi.clear();
    final demLoi = <String, int>{};
    for (final c in _ds) {
      final loi = c.loi.trim().toLowerCase();
      if (loi.isEmpty) continue;
      demLoi[loi] = (demLoi[loi] ?? 0) + 1;
    }
    for (final c in _ds) {
      final loi = c.loi.trim().toLowerCase();
      final thayThe = c.thayThe.trim().toLowerCase();
      if (loi.isNotEmpty && thayThe.isNotEmpty && loi == thayThe) {
        _loiTrungThayThe.add(c);
      }
      if (loi.isNotEmpty && (demLoi[loi] ?? 0) > 1) {
        _loiTrungTuLoi.add(c);
      }
    }
  }

  Widget _oNhap({
    required String nhan,
    required TextEditingController controller,
    required String goiY,
    required void Function(String) onChanged,
    String? canhBao,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nhan,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: canhBao != null ? Colors.red.shade400 : const Color(0xFFDADCE0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: canhBao != null ? Colors.red.shade400 : _mauChinh,
                      width: 2,
                    ),
                  ),
                  hintText: goiY,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        if (canhBao != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              canhBao,
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _mauChinh,
        foregroundColor: Colors.white,
        title: const Text('Từ điển sửa lỗi chính tả của bạn'),
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
              'App tự quét văn bản — từ nào khớp "Từ bị lỗi chính tả hay '
              'gặp" sẽ được gạch vàng lượn sóng, bấm vào để thay/xoá nhanh. '
              'Để trống "Từ thay thế vào" nghĩa là đề xuất xoá hẳn từ đó.',
              style: TextStyle(height: 1.5, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _coCapRong ? null : _themCap,
                style: FilledButton.styleFrom(backgroundColor: _mauChinh),
                icon: const Icon(Icons.add),
                label: const Text('Thêm cặp từ'),
              ),
            ),
            const SizedBox(height: 8),
            for (final c in _ds) ...[
              const Divider(height: 28),
              _oNhap(
                nhan: 'Từ bị lỗi chính tả hay gặp',
                controller: _oLoi[c]!,
                goiY: 'Ví dụ: vd, mik, ...',
                canhBao: _loiTrungTuLoi.contains(c)
                    ? 'Từ này đã có trong một cặp khác — các từ bị lỗi không được trùng nhau.'
                    : null,
                onChanged: (gia) {
                  setState(() {
                    c.loi = gia;
                    _kiemTraTrung();
                  });
                  _datLuu();
                },
              ),
              const SizedBox(height: 10),
              _oNhap(
                nhan: 'Từ thay thế vào',
                controller: _oThayThe[c]!,
                goiY: 'Để trống = đề xuất xoá',
                canhBao: _loiTrungThayThe.contains(c)
                    ? 'Từ thay thế không được giống hệt từ bị lỗi ở trên.'
                    : null,
                onChanged: (gia) {
                  setState(() {
                    c.thayThe = gia;
                    _kiemTraTrung();
                  });
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
