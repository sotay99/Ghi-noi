// Màn hình "Ghi nhanh" — mở ra khi bấm nút trên widget ngoài màn hình
// chính Android. KHÔNG phải trang soạn thảo đầy đủ: chỉ một ô nhập liệu
// và nút Lưu, NỐI thêm nội dung vào CUỐI ghi chú đã cấu hình sẵn (không mở
// thẳng ghi chú đó ra sửa — widget là để GHI NHANH một ý, không phải để
// đọc lại cả ghi chú dài).
import 'package:flutter/material.dart';

import 'ghi_chu_nhanh_widget.dart';
import 'kho_du_lieu.dart';
import 'mo_hinh.dart';

class ManHinhGoNhanhWidget extends StatefulWidget {
  const ManHinhGoNhanhWidget({super.key, required this.idWidget});
  final int idWidget;

  @override
  State<ManHinhGoNhanhWidget> createState() => _ManHinhGoNhanhWidgetState();
}

enum _TrangThaiGoNhanh { dangNap, khongCoMucTieu, khongTimThayGhiChu, sanSang }

class _ManHinhGoNhanhWidgetState extends State<ManHinhGoNhanhWidget> {
  final _kho = KhoDuLieu();
  final _oGo = TextEditingController();
  _TrangThaiGoNhanh _trangThai = _TrangThaiGoNhanh.dangNap;
  String _tenGhiChu = '';
  GhiChuFile? _ghiChu;
  bool _dangLuu = false;

  @override
  void initState() {
    super.initState();
    _nap();
  }

  Future<void> _nap() async {
    final mucTieu = await docMucTieuWidget(widget.idWidget);
    if (mucTieu == null) {
      if (mounted) setState(() => _trangThai = _TrangThaiGoNhanh.khongCoMucTieu);
      return;
    }
    _tenGhiChu = mucTieu.ten;
    await _kho.tai();
    final ghiChu = _kho.timGhiChu(mucTieu.ghiChuId);
    if (!mounted) return;
    // Ghi chú không còn tồn tại NỮA, hoặc đã bị chuyển vào Thùng rác — cả
    // hai coi như "mục tiêu không còn hợp lệ", không cố đoán gộp vào đâu.
    if (ghiChu == null || ghiChu.thoiGianXoa != null) {
      setState(() => _trangThai = _TrangThaiGoNhanh.khongTimThayGhiChu);
      return;
    }
    setState(() {
      _ghiChu = ghiChu;
      _trangThai = _TrangThaiGoNhanh.sanSang;
    });
  }

  Future<void> _luu() async {
    final ghiChu = _ghiChu;
    final noiDungMoi = _oGo.text.trim();
    if (ghiChu == null || noiDungMoi.isEmpty || _dangLuu) return;
    setState(() => _dangLuu = true);
    final canDau = ghiChu.noiDung.isNotEmpty && !ghiChu.noiDung.endsWith('\n');
    ghiChu.noiDung = '${ghiChu.noiDung}${canDau ? '\n' : ''}$noiDungMoi\n';
    ghiChu.capNhat = DateTime.now();
    await _kho.luu();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _oGo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _noiDungTheoTrangThai(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noiDungTheoTrangThai() {
    switch (_trangThai) {
      case _TrangThaiGoNhanh.dangNap:
        return const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        );
      case _TrangThaiGoNhanh.khongCoMucTieu:
      case _TrangThaiGoNhanh.khongTimThayGhiChu:
        return _loiMucTieu();
      case _TrangThaiGoNhanh.sanSang:
        return _formGoNhanh();
    }
  }

  Widget _loiMucTieu() {
    final chu = _trangThai == _TrangThaiGoNhanh.khongCoMucTieu
        ? 'Widget này chưa được cấu hình đúng — hãy xoá widget rồi đặt lại ở màn hình chính.'
        : 'Ghi chú "$_tenGhiChu" mà widget này trỏ tới không còn nữa (đã xoá hoặc đang ở '
            'Thùng rác) — hãy xoá widget rồi đặt lại, chọn một ghi chú khác.';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Không ghi được', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Text(chu),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Đóng'),
          ),
        ),
      ],
    );
  }

  Widget _formGoNhanh() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note, color: Color(0xFF1A73E8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ghi nhanh vào "$_tenGhiChu"',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _oGo,
          autofocus: true,
          maxLines: 5,
          minLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Nhập ghi chú rồi bấm Lưu...',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Đóng'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _dangLuu ? null : _luu,
              child: const Text('Lưu'),
            ),
          ],
        ),
      ],
    );
  }
}
