// Một trong ba kiểu phím tắt người dùng có thể gán cho Micro (vừa nói vừa
// ra chữ) hoặc Ghi âm (ghi âm xong mới ra chữ — tạo thẻ ghi âm): phím Esc
// một mình, phím Tab một mình, hoặc Ctrl + một phím bất kỳ. Dùng chung cho
// cả hai chức năng (`CaiDat.phimTatMicro`/`phimTatGhiAm`), tránh viết trùng
// logic hiển thị/so khớp ở hai nơi.
//
// (TỪNG có lựa chọn thứ tư "phím Windows/Cmd một mình" — bỏ hẳn vì hệ điều
// hành Windows giành phím đó ở tầng hệ thống (mở Start Menu) TRƯỚC KHI trình
// duyệt kịp nhận sự kiện, nên phím tắt không bao giờ hoạt động thật trên
// Windows. Esc không có vấn đề này — trình duyệt luôn nhận được.)

class LuaChonPhimTat {
  const LuaChonPhimTat.esc()
      : loai = 'esc',
        phim = null;
  const LuaChonPhimTat.tab()
      : loai = 'tab',
        phim = null;
  const LuaChonPhimTat.ctrl(String phimBamThem)
      : loai = 'ctrl',
        phim = phimBamThem;

  /// 'esc' | 'tab' | 'ctrl'.
  final String loai;

  /// Chỉ có ý nghĩa khi [loai] == 'ctrl' — phím bấm thêm cùng Ctrl.
  final String? phim;

  /// Đọc lại từ SharedPreferences. [loaiLuu] == 'win' là dữ liệu CŨ (từ hồi
  /// còn lựa chọn "phím Windows/Cmd", nay đã bỏ) — coi là bí danh của 'esc',
  /// đúng vị trí nó từng đóng vai trò mặc định. [phimLuu] rỗng/null khi
  /// [loaiLuu] == 'ctrl' về lý thuyết không xảy ra (luôn lưu kèm nhau),
  /// nhưng lỡ có thì rơi về 'G' cho khỏi vỡ thay vì ném lỗi.
  factory LuaChonPhimTat.tuLuu(String? loaiLuu, String? phimLuu) {
    switch (loaiLuu) {
      case 'tab':
        return const LuaChonPhimTat.tab();
      case 'ctrl':
        return LuaChonPhimTat.ctrl((phimLuu == null || phimLuu.isEmpty) ? 'G' : phimLuu);
      default:
        return const LuaChonPhimTat.esc();
    }
  }

  /// Nhãn hiển thị ngắn gọn, ví dụ 'Esc', 'Tab', 'Ctrl + G'.
  String get nhan {
    switch (loai) {
      case 'tab':
        return 'Tab';
      case 'ctrl':
        return 'Ctrl + ${phim ?? '?'}';
      default:
        return 'Esc';
    }
  }

  /// Khoá so khớp trùng lặp.
  String get khoaSoSanh => switch (loai) {
        'tab' => 'TAB',
        'ctrl' => 'CTRL+${(phim ?? '').toUpperCase()}',
        _ => 'ESC',
      };

  bool coBangVoi(LuaChonPhimTat kia) => khoaSoSanh == kia.khoaSoSanh;
}
