// Popup thông báo ngắn ở chính giữa màn hình, có icon tick xanh, tự ẩn sau
// 2 giây — dùng cho những việc chắc chắn thành công (chép, lưu) mà không cần
// người dùng phải bấm gì để đóng lại.

import 'package:flutter/material.dart';

void hienThongBaoGiua(BuildContext context, String chu,
    {Duration thoiGian = const Duration(seconds: 2), bool ganTren = false}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    // [ganTren] — dùng cho Copy/Cắt/Dán/All ở thanh công cụ dưới: thông báo
    // hiện cao hơn giữa màn hình một chút (~15% từ đỉnh, tức ~85% chiều cao
    // tính từ đáy) để không che khuất đúng chỗ người dùng vừa thao tác.
    builder: (_) => Align(
      alignment: ganTren ? const Alignment(0, -0.7) : Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xEE202124),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF34A853), size: 26),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  chu,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(thoiGian, () {
    if (entry.mounted) entry.remove();
  });
}
