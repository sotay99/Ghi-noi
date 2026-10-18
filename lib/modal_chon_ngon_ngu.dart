// Modal bắt chọn ngôn ngữ lúc mở app lần đầu — cũng mở lại được sau đó từ
// màn Cài đặt (mục "Ngôn ngữ - Language"), lúc đó có tiền chọn theo ngôn ngữ
// hiện tại thay vì bắt chọn lại từ đầu.

import 'package:flutter/material.dart';

import 'ngon_ngu.dart';

/// [batBuocChon] — true khi gọi lúc khởi động (modal không tự đóng được khi
/// chưa chọn gì); false khi mở lại từ Cài đặt (có thể đóng bằng nút X mà
/// không đổi gì).
Future<void> moModalChonNgonNgu(
  BuildContext context, {
  bool batBuocChon = false,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: !batBuocChon,
    builder: (context) => PopScope(
      canPop: !batBuocChon,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dòng tiêu đề viết cứng cả 2 thứ tiếng — KHÔNG bọc qua `Ch`
                // vì lúc này app chưa biết người dùng sẽ chọn ngôn ngữ nào.
                const Text(
                  'Chọn ngôn ngữ / Select language',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // "Language" là từ quốc tế — viết cứng, không bọc đa ngôn ngữ.
                const Text(
                  'Language',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await datNgonNgu(NgonNgu.vi);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Tiếng Việt', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await datNgonNgu(NgonNgu.en);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('English', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
