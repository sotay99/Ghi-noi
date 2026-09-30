// Một dòng trong cuộc "Trò chuyện về văn bản này" — tách khỏi
// man_hinh_tro_chuyen.dart để trang_soan_thao.dart cầm được kiểu này (giữ bộ
// nhớ đệm cuộc trò chuyện theo TỪNG TỆP ghi chú, xem
// `_TrangSoanThaoState._troChuyenTheoTep`) mà không phải import cả màn hình.

/// [choAi] khác [choHienThi] ở những lượt có ĐÍNH KÈM toàn văn bản (lượt hỏi
/// đầu tiên luôn kèm, các lượt sau chỉ kèm khi người dùng chủ động bấm "+" →
/// "Đính kèm lại toàn bộ văn bản mới nhất") — lượt đó gửi cho AI kèm toàn
/// văn, nhưng người dùng trong khung chat chỉ thấy đúng câu họ gõ.
class TinNhanTroChuyen {
  TinNhanTroChuyen({
    required this.laNguoiDung,
    required this.choHienThi,
    String? choAi,
  }) : choAi = choAi ?? choHienThi;

  final bool laNguoiDung;
  final String choHienThi;
  final String choAi;
}
