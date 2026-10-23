// Modal thông báo "APK chưa ra mắt" — dùng CHUNG cho MỌI điểm trong app
// mời tải file APK (dải gợi ý trên màn soạn thảo, dải "có bản APK mới", nút
// "Tải APK" trong modal "Cài đặt Ứng dụng vào Thiết bị"). Trước đây các điểm
// này mở thẳng link GitHub Releases — nay GitHub Releases chưa có bản công
// khai nào (ngày ra mắt dự kiến 10/11/2026), nên thay bằng modal báo trước,
// tránh người dùng bấm vào rồi gặp trang 404/release rỗng.
//
// `barrierDismissible: false` + không có nút X/bấm-ra-ngoài để đóng — CHỈ
// đóng được bằng nút "Đã hiểu" (`Ch.daHieu`), đúng yêu cầu "người dùng bấm
// vào nút đã hiểu thì mới đóng".
import 'package:flutter/material.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'ngon_ngu.dart';

void hienModalApkChuaRaMat(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Icon(Icons.android, size: 36, color: Color(0xFF3DDC84)),
        content: Text(
          Ch.apkRaMatNgay10Thang11(ngonNguHienTai.value),
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Ch.daHieu(ngonNguHienTai.value)),
          ),
        ],
      ),
    ),
  );
}
