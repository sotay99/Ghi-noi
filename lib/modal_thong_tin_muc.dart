// Modal "Thông tin chi tiết" cho một thư mục hoặc một ghi chú — xem
// `KhoDuLieu.thongKeTrucTiep`/`thongKeDeQuy` cho phần đếm số lượng.

import 'dart:convert';

import 'package:flutter/material.dart';

import 'kho_du_lieu.dart';

/// "1,2 KB"/"3,4 MB" — dưới 1024 byte thì hiện nguyên byte, không làm tròn
/// số lẻ gây hiểu lầm cho những tệp nhỏ.
String dinhDangKichThuoc(int bytes) {
  if (bytes < 1024) return '$bytes byte';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}

Widget _dongThongTin(String s) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(s),
    );

Widget _tieuDeVaNutDong(BuildContext context) => Row(
      children: [
        const Expanded(
          child: Text('Thông tin chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );

/// "Thông tin thư mục này" — [id] là id thư mục thật HOẶC `thuMucGoc` (gốc
/// Bộ nhớ nội bộ không có `ThuMuc` thật, [ten] truyền sẵn từ bên gọi cho cả
/// hai trường hợp).
void hienThongTinThuMuc(
  BuildContext context,
  KhoDuLieu kho, {
  required String id,
  required String ten,
}) {
  final truc = kho.thongKeTrucTiep(id);
  final sau = kho.thongKeDeQuy(id);
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: _tieuDeVaNutDong(ctx),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dongThongTin('Tên: $ten'),
          _dongThongTin('Kích thước: ${dinhDangKichThuoc(sau.tongByte)}'),
          _dongThongTin(
            'Gồm có ${truc.soThuMuc} thư mục và ${truc.soGhiChu} tệp tin ở trang đầu.',
          ),
          _dongThongTin(
            'Tổng tất cả có ${sau.soThuMuc} thư mục và ${sau.soGhiChu} tệp tin bên trong.',
          ),
          // (CHỦ Ý để trống) — dành cho tên chủ sở hữu khi có bộ nhớ đám
          // mây/đăng nhập Google, chưa có gì để hiện bây giờ.
          _dongThongTin('Chủ sở hữu: '),
        ],
      ),
    ),
  );
}

/// "Thông tin tệp này" — không có dòng đếm số thư mục/tệp con, không phù
/// hợp với một tệp đơn lẻ.
void hienThongTinGhiChu(
  BuildContext context, {
  required String ten,
  required String noiDung,
}) {
  final soByte = utf8.encode(noiDung).length;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: _tieuDeVaNutDong(ctx),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dongThongTin('Tên: $ten'),
          _dongThongTin('Kích thước: ${dinhDangKichThuoc(soByte)}'),
          _dongThongTin('Chủ sở hữu: '),
        ],
      ),
    ),
  );
}
