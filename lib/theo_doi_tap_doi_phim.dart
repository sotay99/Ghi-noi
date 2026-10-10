// Dò "bấm Ctrl/Shift/Alt 2 lần liên tiếp, sạch (không kèm phím khác), trong
// 1 giây" — tách riêng thành lớp dùng chung được, vì cả phím tắt TOÀN CỤC
// (mở/đóng trình ghi âm, tắt/mở micro, ẩn/hiện Từ điển nhập liệu nhanh) lẫn
// phím tắt CỤC BỘ (bên trong bảng điều khiển ghi âm) đều cần đúng một cơ
// chế này, mỗi nơi một trạng thái riêng, độc lập với nhau. Theo dõi CẢ BA
// phím cùng lúc (Ctrl/Shift/Alt) qua một `Map` thay vì viết lặp lại logic 3
// lần — xem [_TrangThaiPhim].
//
// LƯU Ý QUAN TRỌNG rút ra được sau nhiều lần vá (đọc trước khi sửa tiếp):
// một số thiết bị/trình duyệt mô phỏng việc GIỮ một phím bằng cách tự gửi
// LIÊN TỤC các cặp xuống-nhả RỜI RẠC trong lúc phím vẫn đang bị giữ thật
// (không phải một lượt xuống duy nhất rồi giữ nguyên tới khi nhả thật) —
// nghĩa là KHÔNG THỂ tin bất kỳ sự kiện "nhả" đơn lẻ nào cho tới khi đã
// xác minh lại bằng `HardwareKeyboard.instance.isControlPressed`/
// `isShiftPressed`/`isAltPressed` (trạng thái phím THẬT của hệ thống). Và
// mốc "lúc xuống" dùng để tính thời lượng một lần bấm PHẢI là mốc xuống
// ĐẦU TIÊN của cả lượt giữ (không phải mốc xuống của lần "xuống giả" gần
// nhất) — nếu không một lượt giữ dài xen giữa các cặp giả vẫn có thể bị đo
// ra "ngắn" (vì đo từ lần xuống giả cuối cùng, rất sát ngay trước lúc nhả
// thật).

import 'dart:async';

import 'package:flutter/services.dart';

/// Trạng thái dò "bấm 2 lần liên tiếp" của MỘT phím — xem [TheoDoiTapDoiPhim].
class _TrangThaiPhim {
  DateTime? lucXuongThat; // null = hiện KHÔNG trong lượt giữ nào.
  bool sach = false; // trong lượt giữ hiện tại, chưa có phím nào khác chen vào.
  DateTime? lanTapSach;
  Timer? henXacMinh;
  bool khoa = false;
  Timer? henMoKhoa;
}

class TheoDoiTapDoiPhim {
  TheoDoiTapDoiPhim({required this.khiTapDoi});

  /// Gọi lại với 'ctrlDup'/'shiftDup'/'altDup' khi vừa dò được đủ 2 lần
  /// bấm sạch trong 1 giây của đúng phím đó.
  final void Function(String loai) khiTapDoi;

  static const _nguong = Duration(seconds: 1);

  /// Một LƯỢT GIỮ (từ lúc xuống ĐẦU TIÊN tới lúc xác minh đã nhả THẬT) chỉ
  /// tính là một lần "bấm" hợp lệ nếu tổng thời gian đó không quá ngưỡng
  /// này — người dùng có thể đang giữ Ctrl/Shift/Alt chờ bấm tiếp phím khác
  /// để tạo một tổ hợp phím tắt hoàn toàn khác, không phải "bấm 2 lần".
  static const _nguongBamNgan = Duration(milliseconds: 350);

  /// Sau khi thấy một sự kiện NHẢ, chờ nhịp này rồi mới hỏi lại trạng thái
  /// phím THẬT xem có THẬT SỰ đang buông hay không — xem giải thích ở đầu
  /// tệp.
  static const _nguongXacMinhNha = Duration(milliseconds: 80);

  /// Khoá SAU KHI vừa kích hoạt — mọi hoạt động (xuống HAY nhả) của đúng
  /// phím đó trong lúc khoá sẽ TỰ GIA HẠN khoá thêm một nhịp, nên khoá chỉ
  /// tự mở khi phím đó THẬT SỰ im hẳn liên tục trong khoảng lặng này — một
  /// lượt giữ (hay một chuỗi bấm lặp do thiết bị tự mô phỏng) nhờ vậy chỉ
  /// kích hoạt được ĐÚNG MỘT LẦN, dù kéo dài bao lâu.
  static const _nguongImLangSauKichHoat = Duration(milliseconds: 700);

  final Map<String, _TrangThaiPhim> _trangThai = {
    'ctrl': _TrangThaiPhim(),
    'shift': _TrangThaiPhim(),
    'alt': _TrangThaiPhim(),
  };

  bool _daHuy = false;

  bool _laPhim(LogicalKeyboardKey k, String loai) => switch (loai) {
        'ctrl' => k == LogicalKeyboardKey.controlLeft || k == LogicalKeyboardKey.controlRight,
        'shift' => k == LogicalKeyboardKey.shiftLeft || k == LogicalKeyboardKey.shiftRight,
        'alt' => k == LogicalKeyboardKey.altLeft || k == LogicalKeyboardKey.altRight,
        _ => false,
      };

  bool _dangGiuThat(String loai) => switch (loai) {
        'ctrl' => HardwareKeyboard.instance.isControlPressed,
        'shift' => HardwareKeyboard.instance.isShiftPressed,
        'alt' => HardwareKeyboard.instance.isAltPressed,
        _ => false,
      };

  /// Gọi ở MỌI sự kiện phím (không lọc trước) — tự lọc bên trong, không
  /// bao giờ chặn phím lan đi tiếp (không phải việc của lớp này).
  void xuLy(KeyEvent event) {
    for (final loai in _trangThai.keys) {
      final tt = _trangThai[loai]!;
      final laPhimNay = _laPhim(event.logicalKey, loai);

      // Còn đang khoá mà phím đó lại vừa có động tĩnh (xuống hay nhả đều
      // tính) — gia hạn khoá thêm một nhịp, CHƯA cho mở ra.
      if (laPhimNay && tt.khoa) _giaHanKhoa(loai);

      if (event is KeyDownEvent) {
        if (laPhimNay) {
          // CHỈ ghi mốc xuống khi đây là lượt giữ MỚI (chưa có mốc nào
          // đang treo) — một lần "xuống" đến giữa lúc đang treo sẵn chắc
          // chắn là xuống GIẢ do thiết bị tự mô phỏng giữ, không phải một
          // lượt mới.
          if (tt.lucXuongThat == null) {
            tt.lucXuongThat = DateTime.now();
            tt.sach = true;
          }
        } else if (_dangGiuThat(loai)) {
          tt.sach = false; // phím khác chen vào trong lúc đang giữ phím này.
        }
      } else if (event is KeyUpEvent && laPhimNay) {
        _dangCoTheDaNha(loai);
      }
    }
  }

  /// Vừa thấy một sự kiện NHẢ — CHƯA vội tin, chờ [_nguongXacMinhNha] rồi
  /// hỏi lại trạng thái phím THẬT trước khi kết luận.
  void _dangCoTheDaNha(String loai) {
    final tt = _trangThai[loai]!;
    tt.henXacMinh?.cancel();
    tt.henXacMinh = Timer(_nguongXacMinhNha, () => _xacMinhVaKetLuan(loai));
  }

  void _xacMinhVaKetLuan(String loai) {
    if (_daHuy) return;
    final tt = _trangThai[loai]!;
    // Vẫn đang bị giữ thật — "nhả" vừa dò được là giả (thiết bị tự mô
    // phỏng giữ bằng cặp xuống-nhả rời rạc). CHƯA kết thúc lượt giữ: không
    // đụng gì tới mốc xuống ban đầu, cứ để nguyên đó chờ nhả thật.
    if (_dangGiuThat(loai)) return;

    // Đã buông THẬT — kết thúc lượt giữ hiện tại, tính thời lượng từ đúng
    // mốc xuống ĐẦU TIÊN của cả lượt (không phải lần xuống giả gần nhất).
    final xuong = tt.lucXuongThat;
    final sach = tt.sach;
    tt.lucXuongThat = null;
    tt.sach = false;

    if (tt.khoa) {
      tt.lanTapSach = null;
      return;
    }

    final ngan = xuong != null && DateTime.now().difference(xuong) <= _nguongBamNgan;
    if (!sach || !ngan) {
      tt.lanTapSach = null;
      return;
    }

    final gio = DateTime.now();
    final lanTapSach = tt.lanTapSach;
    if (lanTapSach != null && gio.difference(lanTapSach) <= _nguong) {
      tt.lanTapSach = null;
      _khoaLaiSauKichHoat(loai);
      khiTapDoi('${loai}Dup');
    } else {
      tt.lanTapSach = gio;
    }
  }

  void _khoaLaiSauKichHoat(String loai) {
    _trangThai[loai]!.khoa = true;
    _giaHanKhoa(loai);
  }

  void _giaHanKhoa(String loai) {
    final tt = _trangThai[loai]!;
    tt.henMoKhoa?.cancel();
    tt.henMoKhoa = Timer(_nguongImLangSauKichHoat, () => tt.khoa = false);
  }

  /// Huỷ mọi bộ đếm giờ nội bộ — gọi trong `dispose()` của nơi giữ instance
  /// này, tránh callback chạy sau khi widget đã bị huỷ.
  void dispose() {
    _daHuy = true;
    for (final tt in _trangThai.values) {
      tt.henMoKhoa?.cancel();
      tt.henXacMinh?.cancel();
    }
  }
}
