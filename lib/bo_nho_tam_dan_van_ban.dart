// (YÊU CẦU MỚI — nhánh thử nghiệm) Lịch sử 10 dòng gần nhất đã Cắt/Copy —
// tính năng "Bộ nhớ tạm để dán văn bản". Lưu trong BỘ NHỚ (không ghi đĩa,
// không qua SharedPreferences) — mất khi tải lại trang/đóng app, đúng như
// một "clipboard history" tạm thời của riêng app, tách biệt hẳn với bộ nhớ
// đệm THẬT của hệ thống (`Clipboard`/`ghiClipboardCoDinhDang`) mà Cắt/Copy
// vẫn luôn ghi vào như trước — tính năng này chỉ CỘNG THÊM một lớp lịch sử
// nhiều dòng, không thay thế gì cả.
//
// Vòng tròn 10 ô: lần cắt/copy thứ N (tính từ 1) rơi vào ô (N-1) % 10 — ô
// 0..8 hiện "phím 1".."phím 9", ô 9 hiện "phím 0" (giống bàn phím số thật:
// sau phím 9 là phím 0).

class BoNhoTamDanVanBan {
  BoNhoTamDanVanBan._();

  static final List<String?> lichSu = List<String?>.filled(10, null);
  static int _conTro = 0;

  /// Gọi mỗi khi Cắt/Copy thành công — xem `_phimAoCopy`/`_phimAoCut` ở
  /// `trang_soan_thao.dart`. Bỏ qua đoạn rỗng (không có gì để nhớ).
  static void themMoi(String doan) {
    if (doan.isEmpty) return;
    lichSu[_conTro] = doan;
    _conTro = (_conTro + 1) % lichSu.length;
  }

  /// Nhãn "phím N" cho ô [i] (0..9) — ô cuối cùng (9) là "phím 0", giống
  /// đúng thứ tự phím số thật trên bàn phím (1,2,...,9,0).
  static String nhanPhim(int i) => 'phím ${(i + 1) % 10}';
}
