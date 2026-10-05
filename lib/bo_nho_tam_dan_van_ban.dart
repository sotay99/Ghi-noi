// (YÊU CẦU MỚI — nhánh thử nghiệm) Lịch sử 10 dòng gần nhất đã Cắt/Copy —
// tính năng "Bộ nhớ tạm để dán văn bản". Lưu trong BỘ NHỚ (không ghi đĩa,
// không qua SharedPreferences) — mất khi tải lại trang/đóng app, đúng như
// một "clipboard history" tạm thời của riêng app, tách biệt hẳn với bộ nhớ
// đệm THẬT của hệ thống (`Clipboard`/`ghiClipboardCoDinhDang`) mà Cắt/Copy
// vẫn luôn ghi vào như trước — tính năng này chỉ CỘNG THÊM một lớp lịch sử
// nhiều dòng, không thay thế gì cả.
//
// Mỗi ô (0..9) hiện "phím 1".."phím 9", ô cuối (9) hiện "phím 0" (giống
// đúng thứ tự phím số thật trên bàn phím: sau phím 9 là phím 0).
//
// (YÊU CẦU MỚI) GHIM: mỗi ô có thể được ghim — ô đã ghim KHÔNG BAO GIỜ bị
// lịch sử mới đè lên, và không tham gia vào việc xác định "cũ nhất/gần cũ
// nhất" (những ô đó chỉ xét trong các ô CHƯA ghim). Để biết ô nào thật sự
// cũ nhất trong các ô chưa ghim, mỗi ô giữ một "tuổi" — số thứ tự tăng dần
// mỗi lần được ghi — thay cho một con trỏ vòng tròn đơn giản như trước
// (con trỏ đơn không còn đủ, vì ghim có thể làm thứ tự ghi không còn là
// một vòng tròn đều nữa).

class BoNhoTamDanVanBan {
  BoNhoTamDanVanBan._();

  static final List<String?> lichSu = List<String?>.filled(10, null);
  static final List<bool> ghim = List<bool>.filled(10, false);
  static final List<int> _tuoi = List<int>.filled(10, 0);
  static int _denSo = 0;

  /// (YÊU CẦU MỚI) Gói định dạng thủ công (chuỗi base64 do
  /// `_macGoiDinhDangChoClipboard` đóng, xem `trang_soan_thao.dart`) đi kèm
  /// từng dòng — `null` nếu dòng đó không có định dạng gì đáng nhớ. Gói này
  /// tự mang đủ độ dài + mã băm của đoạn văn bản để bên dán tự xác minh lại,
  /// không cần toạ độ tài liệu gốc — an toàn khi tái sử dụng cho một tài
  /// liệu KHÁC (hoặc cùng tài liệu, vị trí khác) với lúc Cắt/Copy.
  static final List<String?> dinhDang = List<String?>.filled(10, null);

  /// Gọi mỗi khi Cắt/Copy thành công — xem `_phimAoCopy`/`_phimAoCut` ở
  /// `trang_soan_thao.dart`. Bỏ qua đoạn rỗng (không có gì để nhớ).
  ///
  /// Ưu tiên ô TRỐNG trước (lúc lịch sử chưa đầy lần đầu); hết ô trống thì
  /// ghi vào ô CŨ NHẤT trong các ô CHƯA ghim. Nếu cả 10 ô đều đã ghim, bỏ
  /// qua — KHÔNG lỗi, chỉ là lịch sử không còn chỗ chứa (bộ nhớ đệm hệ
  /// thống thật vẫn luôn ghi bình thường, Dán bằng Ctrl+V/nút Dán không hề
  /// bị ảnh hưởng).
  /// (YÊU CẦU MỚI) Đoạn dài hơn ngưỡng này thì ÂM THẦM không ghi vào lịch
  /// sử — tránh bộ nhớ tạm quá nặng. Không báo gì cho người dùng (Cắt/
  /// Copy vẫn thành công như thường vào bộ nhớ đệm hệ thống, chỉ riêng
  /// lịch sử 10 dòng này không nhận đoạn đó).
  static const gioiHanKyTu = 10000;

  static void themMoi(String doan, {String? dinhDangGoi}) {
    if (doan.isEmpty || doan.length > gioiHanKyTu) return;
    final rong = lichSu.indexWhere((v) => v == null);
    if (rong != -1) {
      _ghiVaoO(rong, doan, dinhDangGoi);
      return;
    }
    final ungVien = thuTuCuNhatKhongGhim;
    if (ungVien.isEmpty) return;
    _ghiVaoO(ungVien.first, doan, dinhDangGoi);
  }

  static void _ghiVaoO(int i, String doan, String? dinhDangGoi) {
    lichSu[i] = doan;
    dinhDang[i] = dinhDangGoi;
    _tuoi[i] = ++_denSo;
  }

  /// Ghim/bỏ ghim ô [i] — không làm gì nếu ô đang trống (không có gì để
  /// ghim).
  static void doiGhim(int i) {
    if (lichSu[i] == null) return;
    ghim[i] = !ghim[i];
  }

  /// Nhãn "phím N" cho ô [i] (0..9) — ô cuối cùng (9) là "phím 0", giống
  /// đúng thứ tự phím số thật trên bàn phím (1,2,...,9,0).
  static String nhanPhim(int i) => 'phím ${(i + 1) % 10}';

  /// `true` khi cả 10 ô đều đã CÓ (hoặc đang có) lịch sử ít nhất một lần
  /// (không ô nào null) — chỉ khi đó "cũ nhất/gần cũ nhất" mới có ý nghĩa.
  /// Một khi đã `true` thì luôn `true` (ô đã ghi không bao giờ trở lại
  /// trống), bất kể ghim/bỏ ghim sau đó.
  static bool get day => !lichSu.contains(null);

  /// Các ô CHƯA ghim, xếp từ CŨ NHẤT tới MỚI NHẤT (theo [_tuoi]). Cập nhật
  /// lại danh sách này (gọi ở getter, không lưu cache) mỗi lần hỏi — luôn
  /// đúng ngay sau mỗi lần ghim/bỏ ghim/thêm lịch sử mới.
  static List<int> get thuTuCuNhatKhongGhim {
    final ds = [for (var i = 0; i < lichSu.length; i++) if (!ghim[i] && lichSu[i] != null) i];
    ds.sort((a, b) => _tuoi[a].compareTo(_tuoi[b]));
    return ds;
  }

  /// Ô đang giữ lịch sử CŨ NHẤT trong các ô CHƯA ghim — `null` nếu không
  /// còn ô nào chưa ghim (hoặc chưa [day]).
  static int? get oCuNhat {
    final ds = thuTuCuNhatKhongGhim;
    return ds.isNotEmpty ? ds.first : null;
  }

  /// Ô đang giữ lịch sử GẦN CŨ NHẤT trong các ô CHƯA ghim — `null` nếu
  /// không đủ 2 ô chưa ghim.
  static int? get oGanCuNhat {
    final ds = thuTuCuNhatKhongGhim;
    return ds.length > 1 ? ds[1] : null;
  }
}
