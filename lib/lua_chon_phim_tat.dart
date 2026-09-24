// Một trong ba kiểu phím tắt người dùng có thể gán cho Micro (vừa nói vừa
// ra chữ) hoặc Ghi âm (ghi âm xong mới ra chữ — tạo thẻ ghi âm): phím
// Windows/Cmd một mình, phím Tab một mình, hoặc Ctrl + một phím bất kỳ.
// Dùng chung cho cả hai chức năng (`CaiDat.phimTatMicro`/`phimTatGhiAm`),
// tránh viết trùng logic hiển thị/so khớp ở hai nơi.

import 'ten_phim_win.dart';

class LuaChonPhimTat {
  const LuaChonPhimTat.win()
      : loai = 'win',
        phim = null;
  const LuaChonPhimTat.tab()
      : loai = 'tab',
        phim = null;
  const LuaChonPhimTat.ctrl(String phimBamThem)
      : loai = 'ctrl',
        phim = phimBamThem;

  /// 'win' | 'tab' | 'ctrl'.
  final String loai;

  /// Chỉ có ý nghĩa khi [loai] == 'ctrl' — phím bấm thêm cùng Ctrl.
  final String? phim;

  /// Đọc lại từ SharedPreferences. [phimLuu] rỗng/null khi [loaiLuu] ==
  /// 'ctrl' về lý thuyết không xảy ra (luôn lưu kèm nhau), nhưng lỡ có thì
  /// rơi về 'G' cho khỏi vỡ thay vì ném lỗi.
  factory LuaChonPhimTat.tuLuu(String? loaiLuu, String? phimLuu) {
    switch (loaiLuu) {
      case 'tab':
        return const LuaChonPhimTat.tab();
      case 'ctrl':
        return LuaChonPhimTat.ctrl((phimLuu == null || phimLuu.isEmpty) ? 'G' : phimLuu);
      default:
        return const LuaChonPhimTat.win();
    }
  }

  /// Nhãn hiển thị ngắn gọn, ví dụ 'Windows (⊞)', 'Tab', 'Ctrl + G'.
  String get nhan {
    switch (loai) {
      case 'tab':
        return 'Tab';
      case 'ctrl':
        return 'Ctrl + ${phim ?? '?'}';
      default:
        return tenPhimWinTheoNenTang();
    }
  }

  /// Khoá so khớp trùng lặp — KHÔNG phụ thuộc nhãn hiển thị (nhãn phím Win
  /// đổi theo hệ điều hành lúc hiển thị, nhưng bản chất phím tắt thì không).
  String get khoaSoSanh => switch (loai) {
        'tab' => 'TAB',
        'ctrl' => 'CTRL+${(phim ?? '').toUpperCase()}',
        _ => 'WIN',
      };

  bool coBangVoi(LuaChonPhimTat kia) => khoaSoSanh == kia.khoaSoSanh;
}
