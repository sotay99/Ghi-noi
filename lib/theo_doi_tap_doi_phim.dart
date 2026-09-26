// Dò "bấm Ctrl/Shift 2 lần liên tiếp, sạch (không kèm phím khác), trong 1
// giây" — tách riêng thành lớp dùng chung được, vì cả phím tắt TOÀN CỤC
// (mở/đóng trình ghi âm, tắt/mở micro) lẫn phím tắt CỤC BỘ (bên trong bảng
// điều khiển ghi âm) đều cần đúng một cơ chế này, mỗi nơi một trạng thái
// riêng, độc lập với nhau.

import 'package:flutter/services.dart';

class TheoDoiTapDoiPhim {
  TheoDoiTapDoiPhim({required this.khiTapDoi});

  /// Gọi lại với 'ctrlDup' hoặc 'shiftDup' khi vừa dò được đủ 2 lần bấm
  /// sạch trong 1 giây.
  final void Function(String loai) khiTapDoi;

  bool _dangGiuSachCtrl = false;
  bool _dangGiuSachShift = false;
  DateTime? _lanTapSachCtrl;
  DateTime? _lanTapSachShift;
  DateTime? _lucXuongCtrl;
  DateTime? _lucXuongShift;

  static const _nguong = Duration(seconds: 1);

  /// Nhấn-GIỮ một phím (không nhả ra ngay) không được tính là MỘT trong hai
  /// lần "bấm" — người dùng có thể đang giữ Ctrl/Shift chờ bấm tiếp phím
  /// khác để tạo một tổ hợp phím tắt hoàn toàn khác, không phải đang gõ
  /// "bấm 2 lần liên tiếp". Chỉ tính là một lần bấm hợp lệ nếu từ lúc
  /// xuống tới lúc nhả ra KHÔNG QUÁ ngưỡng này.
  static const _nguongBamNgan = Duration(milliseconds: 350);

  /// Gọi ở MỌI sự kiện phím (không lọc trước) — tự lọc bên trong, không
  /// bao giờ chặn phím lan đi tiếp (không phải việc của lớp này).
  void xuLy(KeyEvent event) {
    final laCtrl = event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight;
    final laShift = event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight;

    if (event is KeyDownEvent) {
      if (laCtrl) {
        _dangGiuSachCtrl = true;
        _lucXuongCtrl = DateTime.now();
      } else if (HardwareKeyboard.instance.isControlPressed) {
        _dangGiuSachCtrl = false;
      }
      if (laShift) {
        _dangGiuSachShift = true;
        _lucXuongShift = DateTime.now();
      } else if (HardwareKeyboard.instance.isShiftPressed) {
        _dangGiuSachShift = false;
      }
      return;
    }
    if (event is! KeyUpEvent) return;

    if (laCtrl) {
      final xuong = _lucXuongCtrl;
      final ngan = xuong != null && DateTime.now().difference(xuong) <= _nguongBamNgan;
      final sach = _dangGiuSachCtrl && ngan;
      _dangGiuSachCtrl = false;
      if (!sach) {
        _lanTapSachCtrl = null;
      } else {
        final gio = DateTime.now();
        if (_lanTapSachCtrl != null && gio.difference(_lanTapSachCtrl!) <= _nguong) {
          _lanTapSachCtrl = null;
          khiTapDoi('ctrlDup');
        } else {
          _lanTapSachCtrl = gio;
        }
      }
    }
    if (laShift) {
      final xuong = _lucXuongShift;
      final ngan = xuong != null && DateTime.now().difference(xuong) <= _nguongBamNgan;
      final sach = _dangGiuSachShift && ngan;
      _dangGiuSachShift = false;
      if (!sach) {
        _lanTapSachShift = null;
      } else {
        final gio = DateTime.now();
        if (_lanTapSachShift != null && gio.difference(_lanTapSachShift!) <= _nguong) {
          _lanTapSachShift = null;
          khiTapDoi('shiftDup');
        } else {
          _lanTapSachShift = gio;
        }
      }
    }
  }
}
