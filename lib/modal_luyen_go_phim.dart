// Modal "Luyện gõ phím bằng 10 ngón tay" — mở từ menu "+ Thêm lựa chọn".
// Nhỏ gọn, giữa màn hình, chỉ mời bấm vào một link duy nhất — bấm xong tới
// thẳng trang kết quả tìm kiếm Google thật, người dùng tự chọn trang web
// nào muốn luyện.

import 'package:flutter/material.dart';

import 'mo_lien_ket_ngoai.dart';

const _mauChinh = Color(0xFF1A73E8);
const _tuKhoaTimKiem = 'luyện gõ phím bằng 10 ngón tay';

void moModalLuyenGoPhim(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Luyện gõ phím bằng 10 ngón tay')),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Đóng',
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
            const Text(
              'Có rất nhiều trang web miễn phí giúp bạn luyện gõ mười ngón '
              'mà không cần nhìn bàn phím. Bấm vào link dưới đây để tìm và '
              'chọn trang web phù hợp với bạn:',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                moLienKetNgoai(
                  'https://www.google.com/search?q=${Uri.encodeQueryComponent(_tuKhoaTimKiem)}',
                );
                Navigator.of(ctx).pop();
              },
              child: const Text(
                _tuKhoaTimKiem,
                style: TextStyle(
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
