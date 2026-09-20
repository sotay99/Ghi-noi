// Bảng màu cơ bản dùng chung — tách ra từ danh sách màu của định dạng chữ
// thủ công (`_NutMauDinhDang` trong `trang_soan_thao.dart`) để tên tệp/tên
// thư mục ở màn hình thư mục (`man_hinh_thu_muc.dart`) và tên tệp ở thanh
// công cụ soạn thảo dùng lại được CÙNG một bảng màu, không định nghĩa lại.
//
// KHÔNG có màu trắng và KHÔNG có tuỳ chọn trong suốt/không màu — khác với
// bảng màu định dạng chữ (nơi trắng/trong suốt vẫn có ý nghĩa làm nổi/ẩn
// chữ trên nền màu khác), tên tệp/tên thư mục luôn hiện trên nền trắng cố
// định của giao diện nên trắng coi như vô hình, và luôn phải có một màu để
// hiển thị.

import 'package:flutter/material.dart';

const List<Color> mauCoBanChoTen = [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.purple,
  Colors.black,
];

/// Hiện hộp thoại chọn một màu trong [mauCoBanChoTen] — trả về màu đã chọn,
/// hoặc `null` nếu người dùng bấm ra ngoài/Huỷ (giữ màu hiện tại).
Future<Color?> hienThiChonMauCoBanChoTen(
  BuildContext context, {
  required String tieuDe,
}) {
  return showDialog<Color>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tieuDe),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final m in mauCoBanChoTen)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(m),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: m,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBDBDBD)),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
      ],
    ),
  );
}
