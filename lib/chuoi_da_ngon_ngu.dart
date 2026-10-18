// Toàn bộ chuỗi hiển thị đa ngôn ngữ của app — mỗi hàm nhận [nn] (ngôn ngữ
// hiện tại, thường truyền `ngonNguHienTai.value`) trả về đúng chuỗi tương
// ứng. Thêm ngôn ngữ mới: thêm 1 nhánh `case` ở MỖI hàm dưới đây (không cần
// sửa nơi gọi). Chuỗi có biến (ví dụ "Đã xoá N tệp") viết thành hàm nhận
// thêm tham số, không string tĩnh.
//
// PHẠM VI: khung menu chính màn hình soạn thảo + 3 menu thả xuống của nó.
// Các màn hình/modal khác dịch dần ở các lượt sau — xem ghi chú cuối file.

import 'ngon_ngu.dart';

/// Viết tắt cho "chuỗi" — gọi ngắn: `Ch.nutThuMuc(nn)`.
class Ch {
  Ch._();

  // --------------------------------------------------- Nút chính màn hình
  static String nutThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thư mục' : 'Folder';

  static String nutHuongDan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hướng dẫn' : 'Guide';

  static String nutHuongDanDayDu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hướng dẫn sử dụng' : 'User guide';

  static String nutLamViecVoiAi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Làm việc với AI' : 'Work with AI';

  static String nutThemLuaChon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thêm lựa chọn' : 'More options';

  static String nutTaiKhoanCaiDat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tài khoản - Cài đặt' : 'Account - Settings';

  static String tepTruoc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tệp trước' : 'Previous file';

  static String tepSau(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tệp sau' : 'Next file';

  static String luiLai(NgonNgu nn) => nn == NgonNgu.vi ? 'Lùi lại' : 'Undo';

  static String tienToi(NgonNgu nn) => nn == NgonNgu.vi ? 'Tiến tới' : 'Redo';

  // ------------------------------------------------- Menu "Làm việc với AI"
  static String ghiAm(NgonNgu nn) => nn == NgonNgu.vi ? 'Ghi âm' : 'Record audio';

  static String dungGhiAm(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Dừng ghi âm' : 'Stop recording';

  static String kiemTraDoanVanNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm tra đoạn văn này' : 'Check this paragraph';

  static String micro(NgonNgu nn) => nn == NgonNgu.vi ? 'Micro' : 'Microphone';

  static String tomTat(NgonNgu nn) => nn == NgonNgu.vi ? 'Tóm tắt' : 'Summarize';

  static String moRong(NgonNgu nn) => nn == NgonNgu.vi ? 'Mở rộng' : 'Expand';

  static String vietLai(NgonNgu nn) => nn == NgonNgu.vi ? 'Viết lại' : 'Rewrite';

  static String kiemTraToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm tra toàn văn' : 'Check whole text';

  static String troChuyen(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Trò chuyện với AI' : 'Chat with AI';

  // ----------------------------------------------------- Menu "Thêm lựa chọn"
  static String tuDienNhapLieuNhanh(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ điển nhập liệu nhanh' : 'Quick input dictionary';

  static String boNhoTamDanVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bộ nhớ tạm để dán văn bản' : 'Clipboard history';

  static String tuDienChinhTa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ điển sửa lỗi chính tả' : 'Spelling dictionary';

  static String chiaSeUngDung(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chia sẻ ứng dụng này đến với mọi người'
      : 'Share this app with everyone';

  static String caiDatUngDungVaoThietBi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt ứng dụng vào thiết bị'
      : 'Install app on this device';

  static String gopY(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Góp ý, báo lỗi' : 'Feedback, report a bug';

  static String ungHo(NgonNgu nn) => nn == NgonNgu.vi ? 'Ủng hộ' : 'Donate';

  // ----------------------------------------------- Menu "Tài khoản - Cài đặt"
  static String caiDat(NgonNgu nn) => nn == NgonNgu.vi ? 'Cài đặt' : 'Settings';

  static String dangNhap(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đăng nhập' : 'Sign in';

  static String dangXuat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đăng xuất' : 'Sign out';

  static String canhBaoHanMucApi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cảnh báo hạn mức API' : 'API quota warning';

  static String ngonNguLanguage(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ngôn ngữ' : 'Language';

  // -------------------------------------------------- Menu 3 chấm thư mục
  static String taiThuMucVeThietBi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tải Thư mục này về thiết bị'
      : 'Download this folder to device';

  static String thungRacNoiBo(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thùng rác nội bộ' : 'Local trash';

  static String thungRacDamMay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thùng rác Đám mây' : 'Cloud trash';

  static String doiTenThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đổi tên thư mục' : 'Rename folder';

  static String xoaThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá thư mục' : 'Delete folder';

  // -------------------------------------------------------- Menu 3 chấm tệp
  static String taiVe(NgonNgu nn) => nn == NgonNgu.vi ? 'Tải về' : 'Download';

  static String chiaSeTepBangDuongLink(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chia sẻ tệp bằng đường link'
      : 'Share file by link';

  static String chonMauChoTep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn màu cho tệp' : 'Pick a color for this file';

  static String xoaTep(NgonNgu nn) => nn == NgonNgu.vi ? 'Xoá tệp' : 'Delete file';

  // ----------------------------------------------- Cây thư mục (thêm lượt này)
  static String taoThuMucMoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tạo thư mục mới' : 'Create new folder';

  static String nhapZipHoacTxt(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Nhập ZIP hoặc TXT vào đây'
      : 'Import ZIP or TXT here';

  static String chonNhieu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn nhiều' : 'Select multiple';

  static String thongTinThuMucNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thông tin thư mục này' : 'This folder\'s info';

  static String timKiemTrongNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tìm kiếm trong này' : 'Search inside this';

  static String doiTen(NgonNgu nn) => nn == NgonNgu.vi ? 'Đổi tên' : 'Rename';

  static String catDiChuyen(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cắt (di chuyển)' : 'Cut (move)';

  static String saoChep(NgonNgu nn) => nn == NgonNgu.vi ? 'Sao chép' : 'Copy';

  static String chonMauTenThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn màu Tên Thư mục' : 'Pick folder name color';

  static String chonMauTenTep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn màu Tên Tệp' : 'Pick file name color';

  static String thongTinTepNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thông tin tệp này' : 'This file\'s info';

  static String chuyenVaoThungRac(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chuyển vào thùng rác' : 'Move to trash';

  // ------------------------------------------------------------- Chung
  static String dong(NgonNgu nn) => nn == NgonNgu.vi ? 'Đóng' : 'Close';

  static String huy(NgonNgu nn) => nn == NgonNgu.vi ? 'Huỷ' : 'Cancel';

  static String xacNhan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xác nhận' : 'Confirm';

  static String copyLink(NgonNgu nn) => 'Copy Link';

  static String daCopy(NgonNgu nn) => nn == NgonNgu.vi ? 'Đã copy' : 'Copied';

  static String moLink(NgonNgu nn) => nn == NgonNgu.vi ? 'Mở Link' : 'Open Link';

  // ------------------------------------------------- Thanh công cụ (lượt 4)
  static String ghiAmChuThich(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ghi âm (Nói xong mới ra chữ)' : 'Record audio (speak first, transcribe after)';

  static String ghiAmTaoTheGhiAm(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ghi âm (tạo thẻ ghi âm)' : 'Record audio (creates an audio card)';

  static String dangDungMicroTatTruocKhiGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang dùng Micro — tắt Micro trước khi ghi âm'
      : 'Microphone in use — turn it off before recording audio';

  static String hienChuThich(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hiện chú thích' : 'Show tooltips';

  static String microVuaNoiVuaRaChu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Micro Vừa nói vừa ra chữ' : 'Microphone — live speech-to-text';

  // --------------------------------------------- Menu "Tài khoản - Cài đặt"
  static String dieuKhoanSuDung(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Điều khoản sử dụng' : 'Terms of use';

  static String baoMatVaQuyenRiengTu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bảo mật và quyền riêng tư' : 'Privacy policy';

  static String dangNhapBangTaiKhoanGoogle(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đăng nhập bằng tài khoản Google' : 'Sign in with Google';

  // ------------------------------------------------------ Menu "Làm việc với AI"
  static String troChuyenVeDoanVanDaChon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Trò chuyện về đoạn văn đã chọn' : 'Chat about the selected paragraph';

  static String troChuyenVeVanBanNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Trò chuyện về văn bản này' : 'Chat about this text';

  static String tomTatDoanVanNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tóm tắt đoạn văn này' : 'Summarize this paragraph';

  static String tomTatToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tóm tắt toàn văn' : 'Summarize whole text';

  static String moRongDoanVanNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Mở rộng đoạn văn này' : 'Expand this paragraph';

  static String moRongToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Mở rộng toàn văn' : 'Expand whole text';

  static String vietLaiChoHayHon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Viết lại cho hay hơn' : 'Rewrite more fluently';

  static String kiemTraLoiChinhTaDoanVanNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm tra lỗi chính tả đoạn văn này' : 'Check spelling in this paragraph';

  static String kiemTraLoiChinhTaToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm tra lỗi chính tả toàn văn' : 'Check spelling in whole text';

  static String kiemTraDauCauDoanVanNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm tra dấu câu đoạn văn này' : 'Check punctuation in this paragraph';

  static String kiemTraDauCauToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm tra dấu câu toàn văn' : 'Check punctuation in whole text';

  // ------------------------------------------------------- Menu "Thêm lựa chọn"
  static String saoChepTatCa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sao chép tất cả' : 'Copy all';

  static String saoChepRoiXoaTatCa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sao chép rồi xoá tất cả' : 'Copy then delete all';

  static String xoaTatCa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá tất cả' : 'Delete all';

  static String chonTatCa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn tất cả' : 'Select all';

  static String timKiemVaThayThe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tìm kiếm và thay thế' : 'Find and replace';

  static String tatBoPhimNhanh(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tắt Bộ phím nhanh cho màn hình cảm ứng' : 'Turn off quick touch keyboard';

  static String batBoPhimNhanh(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bật Bộ phím nhanh cho màn hình cảm ứng' : 'Turn on quick touch keyboard';

  static String danhSachPhimTat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Danh sách phím tắt' : 'Keyboard shortcuts';

  static String luyenGoPhim10Ngon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Luyện gõ phím bằng 10 ngón tay' : 'Practice 10-finger typing';

  static String gioiThieuLuyenGoPhim(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Có rất nhiều trang web miễn phí giúp bạn luyện gõ mười ngón '
          'mà không cần nhìn bàn phím. Bấm vào link dưới đây để tìm và '
          'chọn trang web phù hợp với bạn:'
      : 'There are many free websites that help you practice touch typing '
          'without looking at the keyboard. Tap the link below to find and '
          'pick the one that suits you:';

  static String caiDatUngDungVaoThietBiNoiBat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt Ứng dụng vào Thiết bị' : 'Install App on this Device';

  static String gopYThemBaoLoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Góp ý thêm, báo lỗi về ứng dụng' : 'Send feedback, report a bug';

  static String donateUngHo(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Donate ủng hộ-cảm ơn tác giả' : 'Donate to support the author';

  // ------------------------------------------------------------ Thùng rác
  static String timKiemTrongThungRac(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tìm kiếm trong thùng rác' : 'Search in trash';

  static String thungRacTrong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thùng rác trống' : 'Trash is empty';

  static String khoiPhucVeViTriCu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Khôi phục về vị trí cũ' : 'Restore to original location';

  static String xoaVinhVien(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá vĩnh viễn' : 'Delete permanently';

  static String thongTinChiTiet(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thông tin chi tiết' : 'Details';

  static String khoiPhucHoi(NgonNgu nn) => nn == NgonNgu.vi ? 'Khôi phục?' : 'Restore?';

  static String khoiPhucVeViTriCuHoi(NgonNgu nn, String ten) => nn == NgonNgu.vi
      ? 'Khôi phục "$ten" về vị trí cũ?'
      : 'Restore "$ten" to its original location?';

  static String khong(NgonNgu nn) => nn == NgonNgu.vi ? 'Không' : 'No';

  static String khoiPhuc(NgonNgu nn) => nn == NgonNgu.vi ? 'Khôi phục' : 'Restore';

  static String daKhoiPhucThanhCong(NgonNgu nn, bool laThuMuc, String ten) {
    if (nn == NgonNgu.vi) {
      return '${laThuMuc ? "Thư mục" : "Tệp"} "$ten" đã được khôi phục thành công';
    }
    return '${laThuMuc ? "Folder" : "File"} "$ten" was restored successfully';
  }

  static String oTaiViTri(NgonNgu nn, String diaChi) =>
      nn == NgonNgu.vi ? 'Ở tại vị trí: $diaChi' : 'Located at: $diaChi';

  static String daHieu(NgonNgu nn) => nn == NgonNgu.vi ? 'Đã hiểu' : 'Got it';

  static String denViTriVuaDuocKhoiPhuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đến vị trí vừa được khôi phục' : 'Go to restored location';

  static String xoaVinhVienHoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá vĩnh viễn?' : 'Delete permanently?';

  static String xoaVinhVienXacNhan(NgonNgu nn, bool laThuMuc, String ten) {
    if (nn == NgonNgu.vi) {
      return 'Xoá vĩnh viễn "$ten"${laThuMuc ? " và toàn bộ nội dung bên trong nó" : ""}. '
          'Không thể khôi phục lại được nữa. Bạn có chắc chắn không?';
    }
    return 'Permanently delete "$ten"${laThuMuc ? " and everything inside it" : ""}. '
        'This cannot be undone. Are you sure?';
  }

  static String daXoaLuc(NgonNgu nn, String thoiGian) =>
      nn == NgonNgu.vi ? 'Đã xoá lúc $thoiGian' : 'Deleted at $thoiGian';

  // ------------------------------------------------- Modal "Chia sẻ tệp bằng link"
  static String ghiChuAiCungXemDuocLink(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bất kỳ ai có đường link này đều có thể xem tệp, không thể sửa, '
          'nội dung tệp được đồng bộ theo thời gian thực khi có sự thay đổi.'
      : 'Anyone with this link can view the file, but cannot edit it — '
          'content updates in real time whenever it changes.';

  static String ngungChiaSeThuHoiLink(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ngừng chia sẻ - Thu hồi Link' : 'Stop sharing - Revoke Link';

  static String ngungChiaSeHoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ngừng chia sẻ?' : 'Stop sharing?';

  static String ngungChiaSeNoiDungHoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Link hiện tại sẽ bị thu hồi vĩnh viễn. Nếu chia sẻ lại tệp này, '
          'một link MỚI sẽ được tạo ra. Bạn có chắc chắn không?'
      : 'The current link will be permanently revoked. Sharing this file '
          'again will generate a NEW link. Are you sure?';

  static String ngungChiaSe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ngừng chia sẻ' : 'Stop sharing';

  static String linkChiaSeDaBiXoa(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Link chia sẻ đã bị xoá, không ai có thể sử dụng lại link đó được nữa'
      : 'The share link has been deleted — no one can use it again.';

  // --------------------------------------------- Snackbar/toast ngắn còn sót
  static String bamAllDeChonVungRongHon(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm "All" 2-4 lần để chọn vùng rộng hơn'
      : 'Tap "All" 2-4 times to select a wider range';

  static String bamEndDeXuongDuoiCungVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm End 2 lần để xuống dưới cùng văn bản'
      : 'Tap End twice to jump to the bottom of the text';

  static String bamHomeDeLenTrenCungVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm Home 2 lần để lên trên cùng văn bản'
      : 'Tap Home twice to jump to the top of the text';

  static String khongXuatDuocTepThuLaiSau(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không xuất được tệp. Thử lại sau.' : 'Couldn\'t export the file. Try again later.';

  static String dangTaiFileTxtVeThietBi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang tải file TXT về thiết bị'
      : 'Downloading TXT file to device';

  static String daGhimThanhCongCuDinhDang(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã Ghim thanh công cụ định dạng' : 'Formatting toolbar pinned';

  static String daChuyenTheGhiAmToiViTriMoi(NgonNgu nn, int soThe) => nn == NgonNgu.vi
      ? 'Đã chuyển thẻ ghi âm #$soThe tới vị trí mới'
      : 'Moved recording card #$soThe to a new position';

  static String daChonTatCa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã chọn tất cả' : 'Selected all';

  static String daCopyVaoBoNhoDem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã copy vào bộ nhớ đệm' : 'Copied to clipboard';

  static String daCatVaLuuVaoBoNhoDem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã cắt và lưu vào bộ nhớ đệm' : 'Cut and saved to clipboard';

  static String daDiChuyenVaoThungRac(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã di chuyển vào Thùng rác' : 'Moved to Trash';

  static String daDanVanBanVaoTuBoNhoDem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã dán văn bản vào từ bộ nhớ đệm' : 'Pasted text from clipboard';

  static String daLuuVaoBoNhoMay(NgonNgu nn, String tenTep) => nn == NgonNgu.vi
      ? 'Đã lưu "$tenTep" vào bộ nhớ máy.'
      : 'Saved "$tenTep" to device storage.';

  static String daMoKhoaBanPhim(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã mở khoá bàn phím' : 'Keyboard unlocked';

  static String dangNhapGoogleThatBai(NgonNgu nn, String loi) => nn == NgonNgu.vi
      ? 'Đăng nhập Google thất bại: $loi'
      : 'Google sign-in failed: $loi';

  static String khongChoNhapTepTxtQua2Mb(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không cho nhập tệp TXT quá 2 MB'
      : 'TXT files over 2 MB aren\'t allowed';

  static String tinhNangDangNangCap(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tính năng đang nâng cấp' : 'This feature is being upgraded';

  static String daNhapTepNenVaoThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã nhập tệp nén vào thư mục' : 'Imported the archive into the folder';

  static String daNhapTepVaoThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã nhập tệp vào thư mục' : 'Imported the file into the folder';

  static String daNhapVaoThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã nhập vào thư mục' : 'Imported into the folder';

  static String chonVungVanBanTruocKhiHoanDoiHoaThuong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chọn vùng văn bản trước khi hoán đổi chữ Hoa chữ thường'
      : 'Select a text range before toggling upper/lowercase';

  static String tepDaVuotQuaKyTuKhongTheNhapThem(NgonNgu nn, int nghinKyTu) =>
      nn == NgonNgu.vi
          ? 'Tệp đã vượt quá $nghinKyTu.000 ký tự - không thể nhập thêm'
          : 'The file already exceeds $nghinKyTu,000 characters - cannot add more';

  static String daDangNhapVaoTaiKhoan(NgonNgu nn, String ten) => nn == NgonNgu.vi
      ? 'Đã đăng nhập vào tài khoản $ten'
      : 'Signed in as $ten';

  static String banPhimBiKhoaDangBatBoPhimNhanh(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bàn phím bị khoá - Đang bật bộ phím nhanh cho màn hình cảm ứng'
      : 'Keyboard locked - turning on the quick touch keyboard';

  static String khongTheThemVaoTuDienNhapLieuNhanhVuotQua1000(NgonNgu nn) =>
      nn == NgonNgu.vi
          ? 'Không thể thêm vào Từ điển nhập liệu nhanh, vì vượt quá 1000 ký tự'
          : 'Can\'t add to the quick-entry dictionary - it exceeds 1000 characters';

  static String khongTheThemVaoTuDienChinhTaVuotQua(NgonNgu nn, int gioiHan) =>
      nn == NgonNgu.vi
          ? 'Không thể thêm vào Từ điển sửa lỗi chính tả, vì vượt quá $gioiHan ký tự'
          : 'Can\'t add to the spelling dictionary - it exceeds $gioiHan characters';

  static String daTamDungGhiAmXinMoiChonViTri(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đã Tạm dừng ghi âm - Xin mời chọn vị trí cho thẻ này'
      : 'Recording paused - please choose a position for this card';

  static String khongTheDatTheGhiAmVaoGiuaMotTheKhac(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không thể đặt thẻ ghi âm vào giữa một thẻ khác'
      : 'Can\'t place a recording card in the middle of another card';

  static String vungChonVuotQua10000KyTu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Vùng chọn vượt quá 10.000 ký tự - không thể sử dụng AI'
      : 'The selection exceeds 10,000 characters - cannot use AI';

  static String toanBoVanBanVuotQua20000KyTu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Toàn bộ văn bản vượt quá 20.000 ký tự - không thể sử dụng AI'
      : 'The whole text exceeds 20,000 characters - cannot use AI';

  static String daDanNoiDungVaoDongNhapLieuNhanhThuocPhim(NgonNgu nn, String chuCai) =>
      nn == NgonNgu.vi
          ? 'Đã Dán nội dung vào dòng nhập liệu nhanh thuộc Phím $chuCai'
          : 'Pasted content into the quick-entry row for key $chuCai';

  static String dangTaiFileNenZipVeThietBi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang tải file nén Zip về thiết bị, hãy giải nén file Zip để có thể '
          'sử dụng ở các thiết bị'
      : 'Downloading the Zip archive to your device - please unzip it to '
          'use it on any device';

  static String khongCoTepHopLeDeNhapTxtQua2Mb(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không có tệp hợp lệ để nhập — tệp TXT quá 2 MB đã bị bỏ qua'
      : 'No valid files to import — TXT files over 2 MB were skipped';
}

// CÒN TỒN ĐỌNG (chưa bọc đa ngôn ngữ, để nguyên tiếng Việt — việc cho lượt
// sau): nội dung đầy đủ modal "Hướng dẫn sử dụng"/"Điều khoản sử dụng"/"Bảo
// mật và quyền riêng tư", mọi snackbar/dialog xác nhận trong
// `trang_soan_thao.dart` và `man_hinh_thu_muc.dart`, màn hình trò chuyện AI,
// màn Cài đặt (nội dung chi tiết từng tuỳ chọn), modal hạn mức AI/cảnh báo
// hạn mức AI, các modal ít dùng (từ điển, phím tắt, donate...). Màn Admin ưu
// tiên thấp nhất — chỉ admin thấy.
