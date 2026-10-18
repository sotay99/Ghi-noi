// (YÊU CẦU MỚI) Modal "Chia sẻ tệp bằng đường link" — CHỈ dùng cho tệp trên
// Bộ nhớ đám mây. Sinh (hoặc lấy lại, nếu đã từng chia sẻ) một mã ngẫu nhiên
// gắn với tệp, hiện link `https://flowrite.pro/<mã>`, cho Copy/Mở link. Nội
// dung thật của tệp được đồng bộ sang collection công khai `chiaSeTep/<mã>`
// mỗi lần tệp được lưu — xem `KhoDuLieuDamMay._dayLenFirestore` ở
// `kho_du_lieu.dart`. Trang xem công khai (HTML tĩnh, không phải Flutter) ở
// `flowrite.pro/<mã>` đọc đúng collection đó.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kho_du_lieu.dart';
import 'mo_hinh.dart';
import 'mo_lien_ket_ngoai.dart';

const _bangChuMaChiaSe =
    'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String _sinhMaChiaSe() {
  final ngauNhien = Random.secure();
  return List.generate(
    10,
    (_) => _bangChuMaChiaSe[ngauNhien.nextInt(_bangChuMaChiaSe.length)],
  ).join();
}

Future<void> hienModalChiaSeTep(
  BuildContext context, {
  required GhiChuFile ghiChu,
  required KhoDuLieuDamMay kho,
}) async {
  if (ghiChu.maChiaSe == null) {
    ghiChu.maChiaSe = _sinhMaChiaSe();
    await kho.luu();
  }
  final link = 'https://flowrite.pro/${ghiChu.maChiaSe}';
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => _HopThoaiChiaSeTep(link: link),
  );
}

class _HopThoaiChiaSeTep extends StatefulWidget {
  const _HopThoaiChiaSeTep({required this.link});
  final String link;

  @override
  State<_HopThoaiChiaSeTep> createState() => _HopThoaiChiaSeTepState();
}

class _HopThoaiChiaSeTepState extends State<_HopThoaiChiaSeTep> {
  bool _daCopy = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.link));
    setState(() => _daCopy = true);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _daCopy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chia sẻ tệp bằng đường link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.link,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A73E8)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bất kỳ ai có đường link này đều có thể xem tệp, không thể sửa, '
            'nội dung tệp được đồng bộ theo thời gian thực khi có sự thay '
            'đổi.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _daCopy ? null : _copy,
                  icon: Icon(
                    _daCopy ? Icons.check : Icons.copy,
                    size: 18,
                    color: _daCopy ? Colors.green : null,
                  ),
                  label: Text(
                    _daCopy ? 'Đã copy' : 'Copy Link',
                    style: _daCopy
                        ? const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => moLienKetNgoai(widget.link),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Mở Link'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
