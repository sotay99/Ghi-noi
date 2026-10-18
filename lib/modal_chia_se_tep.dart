// (YÊU CẦU MỚI) Modal "Chia sẻ tệp bằng đường link" — CHỈ dùng cho tệp trên
// Bộ nhớ đám mây. Sinh (hoặc lấy lại, nếu đã từng chia sẻ) một mã ngẫu nhiên
// gắn với tệp, hiện link `https://flowrite.pro/<mã>`, cho Copy/Mở link, và
// "Ngừng chia sẻ - Thu hồi Link" (xoá hẳn, link cũ không sống lại). Nội dung
// thật của tệp được đồng bộ sang collection công khai `chiaSeTep/<mã>` mỗi
// lần tệp được lưu — xem `KhoDuLieuDamMay._dayLenFirestore` ở
// `kho_du_lieu.dart`. Trang xem công khai (HTML tĩnh, không phải Flutter) ở
// `flowrite.pro/<mã>` đọc đúng collection đó.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'kho_du_lieu.dart';
import 'mo_hinh.dart';
import 'mo_lien_ket_ngoai.dart';
import 'ngon_ngu.dart';
import 'thong_bao_giua.dart';

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
  if (!context.mounted) return;

  final daThuHoi = await showDialog<bool>(
    context: context,
    builder: (ctx) => _HopThoaiChiaSeTep(ten: ghiChu.ten, ghiChu: ghiChu, kho: kho),
  );
  if (daThuHoi == true && context.mounted) {
    hienThongBaoGiua(
      context,
      Ch.linkChiaSeDaBiXoa(ngonNguHienTai.value),
    );
  }
}

class _HopThoaiChiaSeTep extends StatefulWidget {
  const _HopThoaiChiaSeTep({
    required this.ten,
    required this.ghiChu,
    required this.kho,
  });

  final String ten;
  final GhiChuFile ghiChu;
  final KhoDuLieuDamMay kho;

  @override
  State<_HopThoaiChiaSeTep> createState() => _HopThoaiChiaSeTepState();
}

class _HopThoaiChiaSeTepState extends State<_HopThoaiChiaSeTep> {
  bool _daCopy = false;

  String get _link => 'https://flowrite.pro/${widget.ghiChu.maChiaSe}';

  void _copy() {
    Clipboard.setData(ClipboardData(text: _link));
    setState(() => _daCopy = true);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _daCopy = false);
    });
  }

  Future<void> _thuHoi() async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.link_off, size: 28, color: Colors.red),
        title: Text(Ch.ngungChiaSeHoi(ngonNguHienTai.value)),
        content: Text(Ch.ngungChiaSeNoiDungHoi(ngonNguHienTai.value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(Ch.khong(ngonNguHienTai.value)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: Text(Ch.ngungChiaSe(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) return;
    await widget.kho.ngungChiaSeTep(widget.ghiChu);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Ch.chiaSeTepBangDuongLink(ngonNguHienTai.value)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.ten,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _link,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A73E8)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Ch.ghiChuAiCungXemDuocLink(ngonNguHienTai.value),
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6368)),
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
                  onPressed: () => moLienKetNgoai(_link),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(Ch.moLink(ngonNguHienTai.value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _thuHoi,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade600),
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(Ch.ngungChiaSeThuHoiLink(ngonNguHienTai.value)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(Ch.dong(ngonNguHienTai.value)),
        ),
      ],
    );
  }
}
