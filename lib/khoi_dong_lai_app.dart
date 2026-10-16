// (YÊU CẦU MỚI) "Khởi động lại app tại chỗ" — huỷ sạch TOÀN BỘ cây giao
// diện hiện tại (bất kể đang lồng bao nhiêu lớp `TrangSoanThao`/
// `ManHinhThuMuc`, đang ở màn nào) rồi dựng lại từ đầu, chạy lại đúng
// luồng khởi động bình thường (`giaiQuyetKhoiDong`). Dùng cho nút "Đăng
// xuất" — ĐÃ đăng xuất xong trước khi gọi, nên luồng khởi động tự rơi về
// đúng ghi chú NỘI BỘ gần nhất (hoặc tự tạo ghi chú mới nếu nội bộ trống),
// không còn cách nào sót lại ghi chú/cây thư mục đám mây của tài khoản
// vừa đăng xuất — không cần viết thêm logic "tự chọn/tạo tệp" riêng, vì
// luồng khởi động sẵn có đã làm đúng việc đó.
//
// Kỹ thuật: đổi `Key` của `KeyedSubtree` bọc quanh app — Flutter coi đó là
// một widget "khác hẳn" so với lần trước, tự huỷ (dispose) toàn bộ State
// cũ và dựng State mới hoàn toàn, y hệt app vừa được mở lại từ đầu. Không
// cần thêm gói ngoài, áp dụng đồng nhất cho cả Web lẫn APK.
import 'package:flutter/material.dart';

class KhoiDongLaiApp extends StatefulWidget {
  const KhoiDongLaiApp({super.key, required this.child});
  final Widget child;

  /// Gọi từ bất kỳ đâu bên trong cây (ví dụ sau khi đăng xuất xong) để
  /// khởi động lại toàn bộ app. Không tìm thấy (lẽ ra không xảy ra — app
  /// luôn bọc trong `KhoiDongLaiApp` ở `main.dart`/`main_web_full.dart`)
  /// thì bỏ qua im lặng, không ném lỗi.
  static void goiLai(BuildContext context) {
    context.findAncestorStateOfType<_KhoiDongLaiAppState>()?._goiLai();
  }

  @override
  State<KhoiDongLaiApp> createState() => _KhoiDongLaiAppState();
}

class _KhoiDongLaiAppState extends State<KhoiDongLaiApp> {
  Key _khoa = UniqueKey();

  void _goiLai() => setState(() => _khoa = UniqueKey());

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _khoa, child: widget.child);
  }
}
