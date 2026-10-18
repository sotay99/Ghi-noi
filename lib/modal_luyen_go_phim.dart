// Modal "Luyện gõ phím bằng 10 ngón tay" — mở từ menu "+ Thêm lựa chọn".
// Nhỏ gọn, giữa màn hình, chỉ mời bấm vào một link duy nhất — bấm xong tới
// thẳng trang kết quả tìm kiếm Google thật, người dùng tự chọn trang web
// nào muốn luyện.

import 'package:flutter/material.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'mo_lien_ket_ngoai.dart';
import 'ngon_ngu.dart';

const _mauChinh = Color(0xFF1A73E8);

void moModalLuyenGoPhim(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(Ch.luyenGoPhim10Ngon(ngonNguHienTai.value))),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: Ch.dong(ngonNguHienTai.value),
            onPressed: () => Navigator.of(ctx).pop(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ch.gioiThieuLuyenGoPhim(ngonNguHienTai.value),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                moLienKetNgoai(linkTimKiemLuyenGoPhim(ngonNguHienTai.value));
                Navigator.of(ctx).pop();
              },
              child: Text(
                tuKhoaLuyenGoPhim(ngonNguHienTai.value),
                style: const TextStyle(
                  color: _mauChinh,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: _mauChinh,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
