// Dò "bấm Ctrl/Shift 2 lần liên tiếp, sạch (không kèm phím khác), trong 1
// giây" — tách riêng thành lớp dùng chung được, vì cả phím tắt TOÀN CỤC
// (mở/đóng trình ghi âm, tắt/mở micro) lẫn phím tắt CỤC BỘ (bên trong bảng
// điều khiển ghi âm) đều cần đúng một cơ chế này, mỗi nơi một trạng thái
// riêng, độc lập với nhau.
//
// LƯU Ý QUAN TRỌNG rút ra được sau nhiều lần vá (đọc trước khi sửa tiếp):
// một số thiết bị/trình duyệt mô phỏng việc GIỮ một phím bằng cách tự gửi
// LIÊN TỤC các cặp xuống-nhả RỜI RẠC trong lúc phím vẫn đang bị giữ thật
// (không phải một lượt xuống duy nhất rồi giữ nguyên tới khi nhả thật) —
// nghĩa là KHÔNG THỂ tin bất kỳ sự kiện "nhả" đơn lẻ nào cho tới khi đã
// xác minh lại bằng `HardwareKeyboard.instance.isControlPressed`/
// `isShiftPressed` (trạng thái phím THẬT của hệ thống). Và mốc "lúc xuống"
// dùng để tính thời lượng một lần bấm PHẢI là mốc xuống ĐẦU TIÊN của cả
// lượt giữ (không phải mốc xuống của lần "xuống giả" gần nhất) — nếu không
// một lượt giữ dài xen giữa các cặp giả vẫn có thể bị đo ra "ngắn" (vì đo
// từ lần xuống giả cuối cùng, rất sát ngay trước lúc nhả thật).

import 'dart:async';

import 'package:flutter/services.dart';

class TheoDoiTapDoiPhim {
  TheoDoiTapDoiPhim({required this.khiTapDoi});

  /// Gọi lại với 'ctrlDup' hoặc 'shiftDup' khi vừa dò được đủ 2 lần bấm
  /// sạch trong 1 giây.
  final void Function(String loai) khiTapDoi;

  static const _nguong = Duration(seconds: 1);

  /// Một LƯỢT GIỮ (từ lúc xuống ĐẦU TIÊN tới lúc xác minh đã nhả THẬT) chỉ
  /// tính là một lần "bấm" hợp lệ nếu tổng thời gian đó không quá ngưỡng
  /// này — người dùng có thể đang giữ Ctrl/Shift chờ bấm tiếp phím khác để
  /// tạo một tổ hợp phím tắt hoàn toàn khác, không phải "bấm 2 lần".
  static const _nguongBamNgan = Duration(milliseconds: 350);

  /// Sau khi thấy một sự kiện NHẢ, chờ nhịp này rồi mới hỏi lại
  /// `isControlPressed`/`isShiftPressed` xem phím đó có THẬT SỰ đang buông
  /// hay không — xem giải thích ở đầu tệp.
  static const _nguongXacMinhNha = Duration(milliseconds: 80);

  /// Khoá SAU KHI vừa kích hoạt — mọi hoạt động (xuống HAY nhả) của đúng
  /// phím đó trong lúc khoá sẽ TỰ GIA HẠN khoá thêm một nhịp, nên khoá chỉ
  /// tự mở khi phím đó THẬT SỰ im hẳn liên tục trong khoảng lặng này — một
  /// lượt giữ (hay một chuỗi bấm lặp do thiết bị tự mô phỏng) nhờ vậy chỉ
  /// kích hoạt được ĐÚNG MỘT LẦN, dù kéo dài bao lâu.
  static const _nguongImLangSauKichHoat = Duration(milliseconds: 700);

  // --- Trạng thái riêng cho Ctrl ---
  DateTime? _lucXuongThatCtrl; // null = hiện KHÔNG trong lượt giữ nào.
  bool _sachCtrl = false; // trong lượt giữ hiện tại, chưa có phím nào khác chen vào.
  DateTime? _lanTapSachCtrl;
  Timer? _henXacMinhCtrl;
  bool _khoaCtrl = false;
  Timer? _henMoKhoaCtrl;

  // --- Trạng thái riêng cho Shift (y hệt Ctrl) ---
  DateTime? _lucXuongThatShift;
  bool _sachShift = false;
  DateTime? _lanTapSachShift;
  Timer? _henXacMinhShift;
  bool _khoaShift = false;
  Timer? _henMoKhoaShift;

  bool _daHuy = false;

  /// Gọi ở MỌI sự kiện phím (không lọc trước) — tự lọc bên trong, không
  /// bao giờ chặn phím lan đi tiếp (không phải việc của lớp này).
  void xuLy(KeyEvent event) {
    final laCtrl = event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight;
    final laShift = event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight;

    // Còn đang khoá mà phím đó lại vừa có động tĩnh (xuống hay nhả đều
    // tính) — gia hạn khoá thêm một nhịp, CHƯA cho mở ra.
    if (laCtrl && _khoaCtrl) _giaHanKhoa(laCtrl: true);
    if (laShift && _khoaShift) _giaHanKhoa(laCtrl: false);

    if (event is KeyDownEvent) {
      if (laCtrl) {
        // CHỈ ghi mốc xuống khi đây là lượt giữ MỚI (chưa có mốc nào đang
        // treo) — một lần "xuống" đến giữa lúc đang treo sẵn chắc chắn là
        // xuống GIẢ do thiết bị tự mô phỏng giữ, không phải một lượt mới.
        if (_lucXuongThatCtrl == null) {
          _lucXuongThatCtrl = DateTime.now();
          _sachCtrl = true;
        }
      } else if (HardwareKeyboard.instance.isControlPressed) {
        _sachCtrl = false; // phím khác chen vào trong lúc đang giữ Ctrl.
      }
      if (laShift) {
        if (_lucXuongThatShift == null) {
          _lucXuongThatShift = DateTime.now();
          _sachShift = true;
        }
      } else if (HardwareKeyboard.instance.isShiftPressed) {
        _sachShift = false;
      }
      return;
    }
    if (event is! KeyUpEvent) return;

    if (laCtrl) _dangCoTheDaNha(laCtrl: true);
    if (laShift) _dangCoTheDaNha(laCtrl: false);
  }

  /// Vừa thấy một sự kiện NHẢ — CHƯA vội tin, chờ [_nguongXacMinhNha] rồi
  /// hỏi lại trạng thái phím THẬT của hệ thống trước khi kết luận.
  void _dangCoTheDaNha({required bool laCtrl}) {
    void datHen(Timer Function() tao) {
      if (laCtrl) {
        _henXacMinhCtrl?.cancel();
        _henXacMinhCtrl = tao();
      } else {
        _henXacMinhShift?.cancel();
        _henXacMinhShift = tao();
      }
    }

    datHen(() => Timer(_nguongXacMinhNha, () => _xacMinhVaKetLuan(laCtrl: laCtrl)));
  }

  void _xacMinhVaKetLuan({required bool laCtrl}) {
    if (_daHuy) return;
    final dangGiuThat = laCtrl
        ? HardwareKeyboard.instance.isControlPressed
        : HardwareKeyboard.instance.isShiftPressed;
    // Vẫn đang bị giữ thật — "nhả" vừa dò được là giả (thiết bị tự mô
    // phỏng giữ bằng cặp xuống-nhả rời rạc). CHƯA kết thúc lượt giữ: không
    // đụng gì tới mốc xuống ban đầu, cứ để nguyên đó chờ nhả thật.
    if (dangGiuThat) return;

    // Đã buông THẬT — kết thúc lượt giữ hiện tại, tính thời lượng từ đúng
    // mốc xuống ĐẦU TIÊN của cả lượt (không phải lần xuống giả gần nhất).
    final xuong = laCtrl ? _lucXuongThatCtrl : _lucXuongThatShift;
    final sach = laCtrl ? _sachCtrl : _sachShift;
    if (laCtrl) {
      _lucXuongThatCtrl = null;
      _sachCtrl = false;
    } else {
      _lucXuongThatShift = null;
      _sachShift = false;
    }

    final lanTapSach = laCtrl ? _lanTapSachCtrl : _lanTapSachShift;
    final khoa = laCtrl ? _khoaCtrl : _khoaShift;

    if (khoa) {
      _datLanTapSach(laCtrl: laCtrl, gia: null);
      return;
    }

    final ngan = xuong != null && DateTime.now().difference(xuong) <= _nguongBamNgan;
    if (!sach || !ngan) {
      _datLanTapSach(laCtrl: laCtrl, gia: null);
      return;
    }

    final gio = DateTime.now();
    if (lanTapSach != null && gio.difference(lanTapSach) <= _nguong) {
      _datLanTapSach(laCtrl: laCtrl, gia: null);
      _khoaLaiSauKichHoat(laCtrl: laCtrl);
      khiTapDoi(laCtrl ? 'ctrlDup' : 'shiftDup');
    } else {
      _datLanTapSach(laCtrl: laCtrl, gia: gio);
    }
  }

  void _datLanTapSach({required bool laCtrl, required DateTime? gia}) {
    if (laCtrl) {
      _lanTapSachCtrl = gia;
    } else {
      _lanTapSachShift = gia;
    }
  }

  void _khoaLaiSauKichHoat({required bool laCtrl}) {
    if (laCtrl) {
      _khoaCtrl = true;
    } else {
      _khoaShift = true;
    }
    _giaHanKhoa(laCtrl: laCtrl);
  }

  void _giaHanKhoa({required bool laCtrl}) {
    if (laCtrl) {
      _henMoKhoaCtrl?.cancel();
      _henMoKhoaCtrl = Timer(_nguongImLangSauKichHoat, () => _khoaCtrl = false);
    } else {
      _henMoKhoaShift?.cancel();
      _henMoKhoaShift = Timer(_nguongImLangSauKichHoat, () => _khoaShift = false);
    }
  }

  /// Huỷ mọi bộ đếm giờ nội bộ — gọi trong `dispose()` của nơi giữ instance
  /// này, tránh callback chạy sau khi widget đã bị huỷ.
  void dispose() {
    _daHuy = true;
    _henMoKhoaCtrl?.cancel();
    _henMoKhoaShift?.cancel();
    _henXacMinhCtrl?.cancel();
    _henXacMinhShift?.cancel();
  }
}
