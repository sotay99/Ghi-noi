// Chuỗi đa ngôn ngữ cho màn "Trò chuyện về văn bản này" (`man_hinh_tro_chuyen.dart`).
// Pattern giống `Ch`/`ChHuongDan`/`ChPhapLy`/`ChCaiDat`. KHÔNG dịch: token
// đánh dấu thẻ ghi âm chèn vào nội dung văn bản (〔🎙️ ...〕 và regex khớp nó),
// và đoạn văn bản dựng sẵn gửi kèm câu hỏi lên AI (protocol nội bộ, người
// dùng không nhìn thấy) — cả hai vẫn giữ nguyên tiếng Việt dù chọn ngôn ngữ
// nào, để không phá vỡ định dạng ghi chú cũ hay cách AI hiểu ngữ cảnh.

import 'ngon_ngu.dart';

class ChTroChuyen {
  static String xoaTroChuyen(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá trò chuyện' : 'Delete chat';

  // ---------------------------------------------------- Cảnh báo mic iPhone
  static String khongKhaDungTrenIphone(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không khả dụng trên iPhone' : 'Not available on iPhone';

  static String giaiThichMicIphoneKhongKhaDung(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Micro (vừa nói vừa ra chữ) tại điện thoại Iphone không thể khả '
          'dụng trên môi trường Website, chỉ khả dụng trên môi trường app '
          'mobile. Nếu bạn cho rằng thiết bị của bạn không phải Iphone, hãy '
          'bấm vào Cài đặt Micro. Bạn có thể tải app mobile cho Iphone để '
          'sử dụng tính năng này.'
      : 'Mic (speak while typing) isn\'t available on iPhone in the '
          'website version — only in the mobile app. If you believe your '
          'device isn\'t an iPhone, tap Mic Settings. You can download the '
          'mobile app for iPhone to use this feature.';

  static String daHieu(NgonNgu nn) => nn == NgonNgu.vi ? 'Đã hiểu' : 'Got it';

  // --------------------------------------------------------------- Lỗi mic
  static String mayKhongDungDuocMicro(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Máy không dùng được micro. Hãy kiểm tra quyền ghi âm.'
      : 'This device can\'t use the microphone. Please check recording permission.';

  static String microLienTucKhongBatLaiDuoc(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Micro liên tục không bật lại được — đã tắt. Hãy thử bấm lại.'
      : 'The mic repeatedly failed to turn back on — it\'s now off. Please try again.';

  static String khongDungDuocMicroDeGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không dùng được micro để ghi âm. Hãy kiểm tra quyền.'
      : 'Can\'t use the microphone to record. Please check permission.';

  // ---------------------------------------------------------- Giới hạn ký tự
  static String tinNhanVuotQua10000KyTu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tin nhắn vượt quá 10.000 ký tự - không thể gửi'
      : 'Message exceeds 10,000 characters - cannot send';

  static String toanBoVanBanVuotQua20000KyTu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Toàn bộ văn bản vượt quá 20.000 ký tự - không thể sử dụng AI'
      : 'The whole text exceeds 20,000 characters - cannot use AI';

  static String vungChonVuotQua10000KyTu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Vùng chọn vượt quá 10.000 ký tự - không thể sử dụng AI'
      : 'The selection exceeds 10,000 characters - cannot use AI';

  static String tinNhanKhongDuocVuotQua100000KyTu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tin nhắn không được vượt quá 100.000 ký tự'
      : 'Message cannot exceed 100,000 characters';

  // ----------------------------------------------------------- Lỗi AI trả lời
  static String aiTraLoiThatBai(NgonNgu nn, String loi) => nn == NgonNgu.vi
      ? 'AI trả lời thất bại: $loi'
      : 'AI failed to respond: $loi';

  static String biNgatGiuaChung(NgonNgu nn, String loi) => nn == NgonNgu.vi
      ? '\n\n[Bị ngắt giữa chừng: $loi]'
      : '\n\n[Interrupted: $loi]';

  static String aiTraLoiThatBaiKhongCoNoiDung(NgonNgu nn) => nn == NgonNgu.vi
      ? 'AI trả lời thất bại: không có nội dung trả về.'
      : 'AI failed to respond: no content returned.';

  // ------------------------------------------------------------- Xoá trò chuyện
  static String xoaCuocTroChuyenHoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá cuộc trò chuyện?' : 'Delete this chat?';

  static String xoaCuocTroChuyenNoiDungHoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Toàn bộ tin nhắn trong cuộc trò chuyện này (về tệp ghi chú đang '
          'mở) sẽ mất hẳn, không thể lấy lại. Bạn có chắc chắn muốn xoá '
          'không?'
      : 'Every message in this chat (about the currently open note) will '
          'be gone for good. Are you sure you want to delete it?';

  static String khongGiuLai(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không, giữ lại' : 'No, keep it';

  static String xoa(NgonNgu nn) => nn == NgonNgu.vi ? 'Xoá' : 'Delete';

  // ------------------------------------------------------------------ Khung chat
  static String banCoTheHoiTuyYVeVanBanNay(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bạn có thể hỏi tuỳ ý về văn bản này.'
      : 'Feel free to ask anything about this text.';

  static String doanVanDangChon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đoạn văn đang chọn' : 'Selected paragraph';

  static String toanBoVanBanMoiNhat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Toàn bộ văn bản mới nhất' : 'The latest full text';

  static String dangSuaTinNhan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang sửa tin nhắn — gửi lại sẽ xoá các tin nhắn sau đó'
      : 'Editing message — sending again will delete messages after it';

  static String them(NgonNgu nn) => nn == NgonNgu.vi ? 'Thêm' : 'Add';

  static String ghiAmNoiXongMoiRaChu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi âm (nói xong mới ra chữ)'
      : 'Record (transcribe after recording)';

  static String microVuaNoiVuaRaChu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Micro (vừa nói vừa ra chữ)'
      : 'Mic (speak while typing)';

  static String ctrlEnterDeGui(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ctrl + Enter để gửi' : 'Ctrl + Enter to send';

  static String daSaoChep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã sao chép' : 'Copied';

  static String sua(NgonNgu nn) => nn == NgonNgu.vi ? 'Sửa' : 'Edit';

  static String aiDangTraLoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'AI đang trả lời...' : 'AI is responding...';

  // -------------------------------------------------------------- Thẻ ghi âm
  static String theGhiAmChuyenHoaThatBai(NgonNgu nn, int soThe, String loi) =>
      nn == NgonNgu.vi
          ? 'Thẻ ghi âm #$soThe chuyển hoá thất bại: $loi'
          : 'Recording card #$soThe failed to transcribe: $loi';

  static String sapChamGioiHanPhut(NgonNgu nn, int tongPhut) => nn == NgonNgu.vi
      ? 'Sắp chạm giới hạn $tongPhut phút'
      : 'Nearing the $tongPhut-minute limit';

  static String giaiThichSapChamGioiHan(
          NgonNgu nn, int soThe, int soLanLienTiep) =>
      nn == NgonNgu.vi
          ? 'Thẻ ghi âm #$soThe (thẻ tự động thứ $soLanLienTiep '
              'liên tiếp) sắp ghi đủ 60 giây. Nếu không chọn, tới đúng giây thứ 60 '
              'hệ thống sẽ TỰ HOÀN THÀNH và đóng trình ghi âm luôn.'
          : 'Recording card #$soThe (the $soLanLienTiep-th '
              'automatic card in a row) is about to reach 60 seconds. If you '
              'don\'t choose, at exactly second 60 it will AUTOMATICALLY FINISH '
              'and close the recorder.';

  static String tiepTuc(NgonNgu nn) => nn == NgonNgu.vi ? 'Tiếp tục' : 'Continue';

  static String tamDung(NgonNgu nn) => nn == NgonNgu.vi ? 'Tạm dừng' : 'Pause';

  static String hoanThanhVaDongNgay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hoàn thành và Đóng ngay' : 'Finish and Close now';

  static String banGhiAmSo(NgonNgu nn, int soThe) =>
      nn == NgonNgu.vi ? 'Bản Ghi âm số $soThe' : 'Recording #$soThe';

  static String dangChuanBi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đang chuẩn bị…' : 'Preparing…';

  static String dangGhiAm(NgonNgu nn) => nn == NgonNgu.vi ? 'Đang Ghi âm ' : 'Recording ';

  static String phimSo(NgonNgu nn, int so) =>
      nn == NgonNgu.vi ? 'phím $so' : 'key $so';

  static String hoanThanhVaChuyenHoaThanhVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành và Chuyển hoá thành văn bản'
      : 'Finish and Transcribe to text';

  static String hoanThanhVaTaoBanGhiAmMoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành và Tạo bản ghi âm mới'
      : 'Finish and Start a new recording';

  static String xoaBanNayVaDong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá bản này và Đóng' : 'Delete this and Close';
}
