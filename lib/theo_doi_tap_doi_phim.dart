// Dò "bấm Ctrl/Shift 2 lần liên tiếp, sạch (không kèm phím khác), trong 1
// giây" — tách riêng thành lớp dùng chung được, vì cả phím tắt TOÀN CỤC
// (mở/đóng trình ghi âm, tắt/mở micro) lẫn phím tắt CỤC BỘ (bên trong bảng
// điều khiển ghi âm) đều cần đúng một cơ chế này, mỗi nơi một trạng thái
// riêng, độc lập với nhau.

import 'dart:async';

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
  ///
  /// KHÔNG ĐỦ một mình: một số thiết bị/trình duyệt mô phỏng việc GIỮ một
  /// phím bằng cách tự gửi hàng loạt cặp xuống-nhả RỜI RẠC lặp lại đều đặn
  /// (mỗi cặp rất ngắn, chỉ khác nhau ở NHỊP LẶP, không phải một lượt xuống
  /// rồi giữ nguyên tới khi nhả thật) — mỗi cặp riêng lẻ vẫn "ngắn" nên qua
  /// được ngưỡng trên, và hai cặp liên tiếp lại lọt đúng vào cửa sổ 1 giây
  /// nên bị hiểu nhầm là "bấm 2 lần", kích hoạt lặp đi lặp lại suốt lúc giữ.
  /// Xem `_khoaCtrl`/`_khoaShift` bên dưới — chốt chặn thứ hai xử lý đúng
  /// trường hợp này.
  static const _nguongBamNgan = Duration(milliseconds: 350);

  /// Khoá SAU KHI vừa kích hoạt — mọi hoạt động (xuống HAY nhả) của đúng
  /// phím đó trong lúc khoá sẽ TỰ GIA HẠN khoá thêm một nhịp, nên khoá chỉ
  /// tự mở khi phím đó THẬT SỰ im hẳn (không còn xuống/nhả gì nữa) liên tục
  /// trong khoảng lặng này — một lượt giữ (hay một chuỗi bấm lặp do thiết
  /// bị tự mô phỏng, xem giải thích ở `_nguongBamNgan`) nhờ vậy chỉ kích
  /// hoạt được ĐÚNG MỘT LẦN, dù kéo dài bao lâu.
  static const _nguongImLangSauKichHoat = Duration(milliseconds: 700);
  bool _khoaCtrl = false;
  bool _khoaShift = false;
  Timer? _henMoKhoaCtrl;
  Timer? _henMoKhoaShift;

  /// Chốt chặn thứ BA (quyết định nhất): ngay cả khi vừa dò đủ "2 lần bấm
  /// sạch, ngắn" — CHỜ một nhịp ngắn rồi kiểm tra lại phím đó có THẬT SỰ
  /// đang được nhả ra hay không, qua `HardwareKeyboard.instance.isXxxPressed`
  /// (trạng thái phím THẬT của hệ thống, không phải suy từ chuỗi sự kiện đã
  /// nhận). Nếu lúc kiểm tra phím đó VẪN đang bị giữ thật, chứng tỏ cặp
  /// "nhả-xuống" vừa dò được chỉ là thiết bị/trình duyệt tự mô phỏng việc
  /// GIỮ (một số nơi làm vậy: gửi liên tục cặp xuống-nhả rời rạc thay vì
  /// một lượt xuống rồi giữ nguyên) — huỷ kích hoạt, không phải một cú bấm
  /// 2 lần thật của người dùng.
  static const _nguongXacMinhNha = Duration(milliseconds: 80);
  Timer? _henXacMinhCtrl;
  Timer? _henXacMinhShift;
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
      if (_khoaCtrl || !sach) {
        _lanTapSachCtrl = null;
      } else {
        final gio = DateTime.now();
        if (_lanTapSachCtrl != null && gio.difference(_lanTapSachCtrl!) <= _nguong) {
          _lanTapSachCtrl = null;
          _xacMinhRoiKichHoat(laCtrl: true);
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
      if (_khoaShift || !sach) {
        _lanTapSachShift = null;
      } else {
        final gio = DateTime.now();
        if (_lanTapSachShift != null && gio.difference(_lanTapSachShift!) <= _nguong) {
          _lanTapSachShift = null;
          _xacMinhRoiKichHoat(laCtrl: false);
        } else {
          _lanTapSachShift = gio;
        }
      }
    }
  }

  /// Đã dò đủ "2 lần bấm sạch, ngắn" — nhưng chưa vội tin, chờ một nhịp rồi
  /// hỏi lại hệ thống xem phím đó có thật sự đang buông ra hay không (xem
  /// giải thích ở `_nguongXacMinhNha`) trước khi gọi [khiTapDoi].
  void _xacMinhRoiKichHoat({required bool laCtrl}) {
    void chay() {
      if (_daHuy) return;
      final dangGiuThat = laCtrl
          ? HardwareKeyboard.instance.isControlPressed
          : HardwareKeyboard.instance.isShiftPressed;
      if (dangGiuThat) return; // "nhả" vừa dò được là giả — bỏ qua, không kích hoạt.
      _khoaLaiSauKichHoat(laCtrl: laCtrl);
      khiTapDoi(laCtrl ? 'ctrlDup' : 'shiftDup');
    }

    if (laCtrl) {
      _henXacMinhCtrl?.cancel();
      _henXacMinhCtrl = Timer(_nguongXacMinhNha, chay);
    } else {
      _henXacMinhShift?.cancel();
      _henXacMinhShift = Timer(_nguongXacMinhNha, chay);
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

  /// Huỷ hai bộ đếm giờ nội bộ — gọi trong `dispose()` của nơi giữ instance
  /// này, tránh callback chạy sau khi widget đã bị huỷ.
  void dispose() {
    _daHuy = true;
    _henMoKhoaCtrl?.cancel();
    _henMoKhoaShift?.cancel();
    _henXacMinhCtrl?.cancel();
    _henXacMinhShift?.cancel();
  }
}
