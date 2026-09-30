// Một dòng trong cuộc "Trò chuyện về văn bản này" — tách khỏi
// man_hinh_tro_chuyen.dart để trang_soan_thao.dart cầm được kiểu này (giữ bộ
// nhớ đệm cuộc trò chuyện theo TỪNG TỆP ghi chú, xem
// `_TrangSoanThaoState._troChuyenTheoTep`) mà không phải import cả màn hình.

/// Loại "thẻ đính kèm" gắn theo một tin nhắn NGƯỜI DÙNG — quyết định app đã
/// gửi kèm gì cho AI cùng câu hỏi đó (xem thẻ "+" cạnh khung nhập ở
/// `man_hinh_tro_chuyen.dart`). Chỉ MỘT thẻ cho mỗi tin nhắn — chọn thẻ mới
/// thì mất thẻ cũ.
enum LoaiDinhKemTroChuyen {
  /// Không đính kèm gì — chỉ mỗi câu hỏi.
  khong,

  /// "Toàn bộ văn bản mới nhất" — nội dung lấy LUÔN LÚC GỬI (không lưu
  /// riêng, vì luôn là bản mới nhất tại đúng thời điểm đó).
  toanVan,

  /// "Đoạn văn đang chọn" — PHẢI lưu riêng nội dung đã chọn tại lúc đính
  /// kèm (xem [TinNhanTroChuyen.noiDungDinhKem]), vì vùng chọn ở trang soạn
  /// thảo có thể đã đổi/mất khi người dùng xem lại tin nhắn cũ.
  doanChon,
}

/// [choAi] khác [choHienThi] ở những lượt có ĐÍNH KÈM toàn văn bản/đoạn chọn
/// (lượt hỏi đầu tiên của một cuộc trò chuyện MỚI luôn kèm toàn văn nếu
/// người dùng không tự chọn thẻ nào khác; các lượt sau chỉ kèm khi người
/// dùng chủ động bấm "+") — lượt đó gửi cho AI kèm nội dung đính kèm, nhưng
/// người dùng trong khung chat chỉ thấy đúng câu họ gõ (cộng thẻ hiện phía
/// trên, nếu có).
class TinNhanTroChuyen {
  TinNhanTroChuyen({
    required this.laNguoiDung,
    required this.choHienThi,
    String? choAi,
    this.dinhKem = LoaiDinhKemTroChuyen.khong,
    this.noiDungDinhKem,
  }) : choAi = choAi ?? choHienThi;

  final bool laNguoiDung;
  final String choHienThi;
  final String choAi;
  final LoaiDinhKemTroChuyen dinhKem;

  /// Chỉ có ý nghĩa khi [dinhKem] == [LoaiDinhKemTroChuyen.doanChon] — nội
  /// dung đoạn văn đã chọn TẠI THỜI ĐIỂM đính kèm, hiện ra khi bấm vào tên
  /// thẻ. Mỗi tin nhắn giữ RIÊNG bản của mình, không lẫn với thẻ cùng tên ở
  /// tin nhắn khác trong cùng cuộc trò chuyện.
  final String? noiDungDinhKem;
}
