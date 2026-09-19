// Bản THAY THẾ cho web của `ghi_am_ai_io.dart` — nút "Ghi âm xong mới ra
// chữ" gốc của app Android dùng `dart:io`/`record`/`path_provider`, ba thứ
// không biên dịch được cho web. Theo đúng kế hoạch hợp nhất (xem thảo luận
// với người dùng): nút này sẽ BỊ BỎ trên web vì web đã có cơ chế ghi âm
// riêng của nó (thẻ ghi âm 〔Ghi âm N 🎙️ mm:ss〕 + gửi Gemini, xem
// `main_web_test.dart`) — bản thân file này chỉ là một chỗ giữ chỗ, chưa
// gắn logic thật, để `trang_soan_thao.dart` biên dịch được trên web trong
// lúc chờ bước ghép mic/ghi âm thật vào.
import 'package:flutter/material.dart';

Future<String?> moBangGhiAmAI(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chưa dùng trên web'),
      content: const Text(
        'Trên web, chức năng ghi âm dùng cơ chế thẻ ghi âm riêng của web '
        '(sẽ được ghép vào đây ở bước sau) thay cho nút này.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đã hiểu'),
        ),
      ],
    ),
  );
}
