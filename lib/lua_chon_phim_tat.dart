// Một trong bốn kiểu phím tắt người dùng có thể gán cho Micro (vừa nói vừa
// ra chữ) hoặc Ghi âm (ghi âm xong mới ra chữ — tạo thẻ ghi âm): phím Tab
// một mình, Ctrl + một phím bất kỳ, bấm Ctrl 2 lần liên tiếp, hoặc bấm Shift
// 2 lần liên tiếp. Dùng chung cho cả hai chức năng (`CaiDat.phimTatMicro`/
// `phimTatGhiAm`), tránh viết trùng logic hiển thị/so khớp ở hai nơi.
//
// (TỪNG có lựa chọn "phím Windows/Cmd một mình" rồi "phím Esc một mình" —
// bỏ CẢ HAI: Windows giành phím Win ở tầng hệ thống (mở Start Menu) trước
// khi trình duyệt kịp nhận; còn Esc thì trình duyệt/Flutter tự hiểu thành
// "lùi trang" dù đã vá. Hai phím "bấm 2 lần liên tiếp" không đụng phải vấn
// đề nào trong hai vấn đề trên — không phải tổ hợp/phím nào bị hệ thống
// hay trình duyệt can thiệp sẵn.)

/// Ba chức năng dùng CHUNG bốn kiểu phím tắt ở `LuaChonPhimTat`, không bao
/// giờ được phép trùng nhau — xem
/// `CaiDat.datPhimTatTinhNangVaTuHoanDoiNeuTrung`.
enum TinhNangPhimTat { micro, ghiAm, boNhoTam }

class LuaChonPhimTat {
  const LuaChonPhimTat.tab()
      : loai = 'tab',
        phim = null;
  const LuaChonPhimTat.ctrl(String phimBamThem)
      : loai = 'ctrl',
        phim = phimBamThem;
  const LuaChonPhimTat.ctrlDup()
      : loai = 'ctrlDup',
        phim = null;
  const LuaChonPhimTat.shiftDup()
      : loai = 'shiftDup',
        phim = null;

  /// (YÊU CẦU MỚI) Alt + Shift cùng lúc — CHỈ dùng cho "Từ điển nhập liệu
  /// nhanh", KHÔNG tham gia vòng tự đổi hộ 3 chiều của Micro/Ghi âm/Bộ nhớ
  /// tạm (xem `CaiDat._vongTuDoiPhimTat`) vì đó là một họ tổ hợp hoàn toàn
  /// khác, không bao giờ trùng nhau.
  const LuaChonPhimTat.altShift()
      : loai = 'altShift',
        phim = null;

  /// (YÊU CẦU MỚI) Bấm Alt 2 lần liên tiếp — MẶC ĐỊNH của "Từ điển nhập
  /// liệu nhanh", dò qua `TheoDoiTapDoiPhim` y hệt `ctrlDup`/`shiftDup`
  /// (chỉ khác phím theo dõi là Alt). Cũng đứng NGOÀI vòng tự đổi hộ 3
  /// chiều — xem giải thích ở `.altShift()`.
  const LuaChonPhimTat.altDup()
      : loai = 'altDup',
        phim = null;

  /// 'tab' | 'ctrl' | 'ctrlDup' | 'shiftDup' | 'altShift' | 'altDup'.
  final String loai;

  /// Chỉ có ý nghĩa khi [loai] == 'ctrl' — phím bấm thêm cùng Ctrl.
  final String? phim;

  /// Đọc lại từ SharedPreferences. [loaiLuu] == 'win'/'esc' là dữ liệu CŨ
  /// (từ hồi còn hai lựa chọn đã bỏ) — coi là bí danh của 'ctrlDup', đúng
  /// vị trí nó từng đóng vai trò MẶC ĐỊNH của Micro. [phimLuu] rỗng/null
  /// khi [loaiLuu] == 'ctrl' về lý thuyết không xảy ra (luôn lưu kèm
  /// nhau), nhưng lỡ có thì rơi về 'G' cho khỏi vỡ thay vì ném lỗi.
  factory LuaChonPhimTat.tuLuu(String? loaiLuu, String? phimLuu) {
    switch (loaiLuu) {
      case 'tab':
        return const LuaChonPhimTat.tab();
      case 'ctrl':
        return LuaChonPhimTat.ctrl((phimLuu == null || phimLuu.isEmpty) ? 'G' : phimLuu);
      case 'shiftDup':
        return const LuaChonPhimTat.shiftDup();
      case 'altShift':
        return const LuaChonPhimTat.altShift();
      case 'altDup':
        return const LuaChonPhimTat.altDup();
      default:
        return const LuaChonPhimTat.ctrlDup();
    }
  }

  /// Nhãn hiển thị ngắn gọn, ví dụ 'Tab', 'Ctrl + G', 'Bấm Ctrl 2 lần'.
  String get nhan {
    switch (loai) {
      case 'tab':
        return 'Tab';
      case 'ctrl':
        return 'Ctrl + ${phim ?? '?'}';
      case 'shiftDup':
        return 'Bấm Shift 2 lần';
      case 'altShift':
        return 'Alt + Shift';
      case 'altDup':
        return 'Bấm Alt 2 lần';
      default:
        return 'Bấm Ctrl 2 lần';
    }
  }

  /// Khoá so khớp trùng lặp.
  String get khoaSoSanh => switch (loai) {
        'tab' => 'TAB',
        'ctrl' => 'CTRL+${(phim ?? '').toUpperCase()}',
        'shiftDup' => 'SHIFTDUP',
        'altShift' => 'ALTSHIFT',
        'altDup' => 'ALTDUP',
        _ => 'CTRLDUP',
      };

  bool coBangVoi(LuaChonPhimTat kia) => khoaSoSanh == kia.khoaSoSanh;
}
