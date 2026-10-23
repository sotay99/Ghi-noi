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
      nn == NgonNgu.vi ? 'Trò chuyện với AI' : 'Chat';

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

  // ------------------------------------------------- Cây thư mục (lượt dịch tiếp)
  static String luu(NgonNgu nn) => nn == NgonNgu.vi ? 'Lưu' : 'Save';

  static String tat(NgonNgu nn) => nn == NgonNgu.vi ? 'Tắt' : 'Turn off';

  static String dan(NgonNgu nn) => nn == NgonNgu.vi ? 'Dán' : 'Paste';

  /// Tiêu đề modal kết quả AI từ tệp — [loai] là 'amThanh'/'hinhAnh'/'anhChup'.
  static String tieuDeModalKetQuaFile(String loai, NgonNgu nn) {
    if (nn == NgonNgu.vi) {
      return switch (loai) {
        'hinhAnh' => 'Văn bản từ hình ảnh',
        'anhChup' => 'Văn bản từ ảnh chụp',
        _ => 'Văn bản từ tệp âm thanh',
      };
    }
    return switch (loai) {
      'hinhAnh' => 'Text from image',
      'anhChup' => 'Text from photo',
      _ => 'Text from audio file',
    };
  }

  static String huyChonNhieu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hủy chọn nhiều' : 'Cancel multi-select';

  static String chonMauChoTen(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn màu cho tên' : 'Choose a name color';

  static String boNhoNoiBo(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bộ nhớ Nội bộ' : 'Local storage';

  static String boNhoTrenDamMay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bộ nhớ trên đám mây' : 'Cloud storage';

  static String boNhoDuocChiaSeVoiBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bộ nhớ được chia sẻ với bạn'
      : 'Storage shared with you';

  static String quayLaiTrangSoanThao(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Quay lại Trang soạn thảo' : 'Back to the editor';

  static String viTriTepDangSoanThao(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Vị trí Tệp đang soạn thảo'
      : 'Location of the file being edited';

  static String sapXepATrenZ(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sắp xếp A → Z' : 'Sort A → Z';

  static String sapXepZTrenA(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sắp xếp Z → A' : 'Sort Z → A';

  static String tabGanDayRong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Gần đây - Phím 1' : 'Recent - Key 1';
  static String tabGanDayHep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Gần đây (1)' : 'Recent (1)';
  static String tabHangPhimRong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sắp xếp Q → M - Phím 2' : 'Sort Q → M - Key 2';
  static String tabBangChuCaiRong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sắp xếp A → Z - Phím 3' : 'Sort A → Z - Key 3';


  static String duaVaoChoNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đưa vào chỗ này' : 'Move here';

  // ------------------------------------------- Dialog/toast trang_soan_thao.dart
  static String xacNhanThayThe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xác nhận thay thế' : 'Confirm replace';
  static String chapNhan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chấp nhận' : 'Accept';
  static String caiDatTimKiemVaThayThe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt tìm kiếm và hướng dẫn thay thế'
      : 'Find & replace settings and guide';
  static String thayChoNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thay chỗ này' : 'Replace here';
  static String tatCaVienBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tất cả' : 'All';
  static String chuaCoVungChon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chưa có vùng chọn' : 'No selection yet';
  static String vietHoaChuDauMoiTu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Viết Hoa chữ đầu tiên ở tất cả các từ'
      : 'Capitalize first letter of every word';
  static String vietHoaTatCaKyTu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Viết Hoa tất cả các ký tự' : 'Capitalize all characters';
  static String vietThuongTatCaKyTu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Viết thường tất cả các ký tự' : 'Lowercase all characters';
  static String vietHoaChuDauCau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Viết Hoa chữ đầu tiên của từ đầu tiên'
      : 'Capitalize first letter of the first word';
  static String xacNhanDangXuat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bạn có chắc chắn muốn đăng xuất không?'
      : 'Are you sure you want to sign out?';
  static String taoTepVanBanMoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tạo tệp văn bản mới' : 'Create new text file';
  static String tao(NgonNgu nn) => nn == NgonNgu.vi ? 'Tạo' : 'Create';
  static String dongBang(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đóng bảng' : 'Close panel';
  static String tuDongChuyenHoaVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tự động chuyển hoá văn bản' : 'Auto-transcribe text';
  static String tuDongChuyenHoa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tự động chuyển hoá' : 'Auto-transcribe';
  static String caiDatTuDongMoBangGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt chế độ tự động Mở bảng điều khiển trình ghi âm'
      : 'Auto-open recorder panel settings';
  static String taoBanGhiAmMoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tạo bản ghi âm mới' : 'Create new recording';
  static String hoanThanhDoanVaChuyenVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành đoạn này và chuyển thành văn bản'
      : 'Finish this segment and transcribe it';
  static String hoanThanhDoanVaPhatLai(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành đoạn này và phát lại để nghe'
      : 'Finish this segment and play it back';
  static String hoanThanhDoanVaDongTrinhGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành đoạn này và đóng trình ghi âm'
      : 'Finish this segment and close the recorder';
  static String xoaBanGhiAmDangDoDang(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Xoá bản ghi âm đang dở dang?'
      : 'Delete the unfinished recording?';
  static String khongGiuLai(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không, giữ lại' : 'No, keep it';
  static String chuyenHoaTatCaTheGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chuyển hoá TẤT CẢ thẻ ghi âm'
      : 'Transcribe ALL recording cards';
  static String chiChuyenHoaTheNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chỉ chuyển hoá thẻ này' : 'Transcribe only this card';
  static String ngheBanGhiAmNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Nghe bản ghi âm này' : 'Listen to this recording';
  static String thayDoiViTriTheNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thay đổi vị trí của thẻ này' : 'Move this card';
  static String khongConBanGhiAm(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không còn bản ghi âm' : 'No recording left';
  static String xoaTheGhiAm(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá thẻ ghi âm?' : 'Delete the recording card?';
  static String khongKhaDungTrenIphone(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không khả dụng trên iPhone' : 'Not available on iPhone';
  static String dayKhongPhaiLaLink(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đây không phải là link' : 'This is not a link';
  static String chapNhanTatCaDeXuatTuDien(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chấp nhận tất cả đề xuất của từ điển'
      : 'Accept all dictionary suggestions';
  static String chapNhanDeXuatLienQuan(NgonNgu nn, String tu) => nn == NgonNgu.vi
      ? 'Chấp nhận các đề xuất liên quan đến "$tu"'
      : 'Accept the suggestions related to "$tu"';
  static String dungNgayLapTuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Dừng ngay lập tức' : 'Stop immediately';
  static String aiDaTraVeKetQua(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'AI đã trả về kết quả' : 'AI has returned a result';
  static String dungDeXuatNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Dùng đề xuất này' : 'Use this suggestion';
  static String boDeXuatNayTraLaiNhuCu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bỏ đề xuất này và trả lại như cũ'
      : 'Discard this suggestion and revert';
  static String chapNhanXoaDoanVanNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chấp nhận xoá đoạn văn này' : 'Accept deleting this paragraph';
  static String khoiPhucDoanVanNayKhongXoa(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khôi phục đoạn văn này — không xoá'
      : "Restore this paragraph — don't delete";
  static String dangChuyenTepAmThanhThanhVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang chuyển tệp âm thanh thành văn bản...'
      : 'Converting audio file to text...';
  static String dangChuyenHinhAnhThanhVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang chuyển hình ảnh thành văn bản...'
      : 'Converting image to text...';
  static String xoaTatCaCauLenh(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá tất cả câu lệnh?' : 'Delete all prompts?';
  static String noiDungCauLenhSeBiXoaSach(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Toàn bộ nội dung đang ghi trong ô câu lệnh sẽ bị xoá sạch. Bạn chắc chứ?'
      : 'All content in the prompt box will be cleared. Are you sure?';
  static String tomTatTheoPhanTram(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tóm tắt theo phần trăm' : 'Summarize by percentage';
  static String rutGonTheoYeuCau(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Rút gọn theo yêu cầu của bạn' : 'Shorten as you request';
  static String guiChoAiXuLy(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Gửi cho AI xử lý' : 'Send to AI';
  static String dangTomTatToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đang tóm tắt toàn văn...' : 'Summarizing whole text...';
  static String moRongTheoPhanTram(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Mở rộng theo phần trăm' : 'Expand by percentage';
  static String moRongTheoYeuCau(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Mở rộng theo yêu cầu của bạn' : 'Expand as you request';
  static String dangMoRongToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đang mở rộng toàn văn...' : 'Expanding whole text...';
  static String dangVietLaiToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đang viết lại toàn văn...' : 'Rewriting whole text...';
  static String troChuyenDangNangCapTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Trò chuyện' : 'Chat';
  static String huyKetQuaNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Huỷ kết quả này?' : 'Discard this result?';
  static String chonViTriDeChenVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn vị trí để chèn văn bản' : 'Choose where to insert the text';
  static String chenVaoVanBanDangSoan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chèn vào văn bản đang soạn' : 'Insert into the text being edited';
  static String huyKetQuaTuAi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Huỷ kết quả từ AI?' : 'Discard the AI result?';
  static String khongApDungDuocChuTren(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không áp dụng được chữ trên' : "Can't apply superscript";
  static String doiTenTep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đổi tên tệp' : 'Rename file';
  static String huyQuayLai(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Huỷ - quay lại' : 'Cancel - go back';
  static String luuThayDoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Lưu thay đổi' : 'Save changes';
  static String taiApk(NgonNgu nn) => nn == NgonNgu.vi ? 'Tải APK' : 'Download APK';
  static String taiBanMoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tải bản mới' : 'Download update';
  static String chonMau(NgonNgu nn) => nn == NgonNgu.vi ? 'Chọn màu' : 'Choose color';
  static String huongDanBoNhoTam(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hướng dẫn sử dụng bảng Bộ nhớ tạm' : 'How to use the Clipboard panel';
  static String boNhoTamDeDanVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bộ nhớ tạm để dán văn bản' : 'Clipboard for pasting text';
  static String huongDanTuDienNhapLieuNhanh(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hướng dẫn sử dụng Từ điển nhập liệu nhanh'
      : 'How to use the Quick-entry Dictionary';
  static String thayTheNoiDungDongNay(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thay thế nội dung đã có trong dòng này?'
      : 'Replace the existing content in this line?';
  static String coXacNhanThayThe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Có - Xác nhận thay thế' : 'Yes - confirm replace';
  static String themNhanhVaoTuDien(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thêm nhanh vào từ điển nhập liệu nhanh'
      : 'Quickly add to the quick-entry dictionary';

  // ------------------------------------------- Dialog/toast trang_soan_thao.dart (lượt 2)
  static String timHieuThem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tìm hiểu thêm' : 'Learn more';
  static String kyTuDacBiet(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ký tự đặc biệt' : 'Special characters';
  static String nguongHaiChamDau(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ngưỡng:' : 'Threshold:';
  static String soGiay(NgonNgu nn, int giay) =>
      nn == NgonNgu.vi ? '$giay giây' : '$giay sec';
  static String sapChamGioiHan60Giay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sắp chạm giới hạn 60 giây' : 'Approaching the 60-second limit';
  static String xoa(NgonNgu nn) => nn == NgonNgu.vi ? 'Xoá' : 'Delete';
  static String xoaTheGhiAmNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá thẻ ghi âm này' : 'Delete this recording card';
  static String theDangGuiPhienAmXoaSeBo(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thẻ này ĐANG được gửi đi phiên âm — xoá sẽ bỏ luôn kết quả sắp về, '
          'không thể phục hồi lại được. Bạn có chắc chắn muốn xoá không?'
      : "This card is currently being transcribed — deleting it discards the "
          "incoming result and can't be undone. Are you sure you want to delete it?";
  static String theGhiAmSeBiXoaVinhVien(NgonNgu nn, int soThe) => nn == NgonNgu.vi
      ? 'Thẻ ghi âm #$soThe sẽ bị xoá VĨNH VIỄN, không thể phục hồi lại được. '
          'Bạn có chắc chắn muốn xoá không?'
      : 'Recording card #$soThe will be PERMANENTLY deleted and cannot be '
          'recovered. Are you sure you want to delete it?';
  static String huyDeXuat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Huỷ đề xuất' : 'Dismiss suggestion';
  static String deXuatXoa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đề xuất Xoá' : 'Suggested: Delete';
  static String xoaTatCaDam(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá tất cả' : 'Delete all';
  static String tamDungCoDauCach(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tạm dừng ' : 'Paused ';
  static String banGhiAmSoCoDauCach(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bản Ghi âm số ' : 'Recording No. ';

  // ------------------------------------------- Tooltip/hintText trang_soan_thao.dart
  static String ketQuaTruoc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kết quả trước' : 'Previous result';
  static String ketQuaTiepTheo(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kết quả tiếp theo' : 'Next result';
  static String xoaNoiDungTim(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá nội dung tìm' : 'Clear search text';
  static String thayTheKyTuTrenBangGi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thay thế những ký tự trên bằng ký tự gì?' : 'Replace the text above with what?';
  static String timTrongVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tìm trong văn bản...' : 'Search in text...';
  static String xoaNoiDungThayThe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá nội dung thay thế' : 'Clear replacement text';
  static String xoaDinhDangVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá định dạng văn bản (Ctrl+Q)' : 'Clear text formatting (Ctrl+Q)';
  static String damTooltip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đậm (Ctrl+B)' : 'Bold (Ctrl+B)';
  static String nghiengTooltip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Nghiêng (Ctrl+I)' : 'Italic (Ctrl+I)';
  static String gachChanTooltip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Gạch chân (Ctrl+U)' : 'Underline (Ctrl+U)';
  static String gachNgangTooltip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Gạch ngang thân (Ctrl+Shift+X)' : 'Strikethrough (Ctrl+Shift+X)';
  static String treMuTooltip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chữ trên (Ctrl+Shift+=)' : 'Superscript (Ctrl+Shift+=)';
  static String treChanTooltip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chữ dưới (Ctrl+=)' : 'Subscript (Ctrl+=)';
  static String mauChuTooltip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Màu chữ (Ctrl+Shift+C)' : 'Text color (Ctrl+Shift+C)';
  static String mauNenChuTooltip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Màu nền chữ (Ctrl+Shift+H)' : 'Highlight color (Ctrl+Shift+H)';
  static String hoanDoiHoaThuong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hoán đổi chữ Hoa chữ thường' : 'Swap uppercase/lowercase';
  static String chonKieuHoaThuong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn kiểu Hoa/thường' : 'Choose a case style';
  static String tichChonCheckbox(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tích chọn — chèn ô 🔲 đầu đoạn văn, gạch ngang cả đoạn khi bấm chuyển thành ✅'
      : 'Checkbox — inserts a 🔲 at the start of the paragraph, strikes through '
          'the paragraph when tapped to turn into ✅';
  static String viDuChiGiuYChinh(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ví dụ: chỉ giữ lại các ý chính về...' : 'E.g.: keep only the main ideas about...';
  static String viDuThemViDuMinhHoa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ví dụ: thêm ví dụ minh hoạ cho...' : 'E.g.: add an illustrative example for...';
  static String viDuVietGiongTrangTrong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ví dụ: viết theo giọng trang trọng hơn...' : 'E.g.: write in a more formal tone...';
  static String cuonLenDauVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cuộn lên đầu văn bản' : 'Scroll to the top of the text';
  static String cuonXuongCuoiVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cuộn xuống cuối văn bản' : 'Scroll to the bottom of the text';
  static String luiLaiCoPhimTat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Lùi lại (Ctrl + Z)' : 'Undo (Ctrl + Z)';
  static String tienToiCoPhimTat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tiến tới (Ctrl + Shift + Z)' : 'Redo (Ctrl + Shift + Z)';
  static String thuGonAnThanhCongCu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thu gọn — ẩn hết thanh công cụ phía trên'
      : 'Collapse — hide all toolbars above';
  static String chonMauKhac(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn màu khác' : 'Choose another color';
  static String themNoiDungVaoDongNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thêm nội dung vào dòng này' : 'Add content to this line';
  static String boNhoTamCoPhimTat(NgonNgu nn, String phimTat) => nn == NgonNgu.vi
      ? 'Bộ nhớ tạm để dán văn bản ($phimTat)'
      : 'Clipboard for pasting text ($phimTat)';

  /// Nhãn trạng thái của thẻ ghi âm vừa chốt (không còn ghi âm thật nữa) —
  /// xem `LoaiTrangThaiGheDe`/`TrangThaiGheDe` ở `trang_soan_thao.dart`.
  static String trangThaiGheDe(LoaiTrangThaiGheDe loai, int soThe, NgonNgu nn) {
    switch (loai) {
      case LoaiTrangThaiGheDe.dangChuyen:
        return nn == NgonNgu.vi ? 'Đang chuyển #$soThe' : 'Converting #$soThe';
      case LoaiTrangThaiGheDe.daChuyenXong:
        return nn == NgonNgu.vi ? 'Đã chuyển xong #$soThe' : 'Converted #$soThe';
      case LoaiTrangThaiGheDe.loiKhiChuyen:
        return nn == NgonNgu.vi
            ? 'Lỗi khi chuyển #$soThe — thử lại sau'
            : 'Error converting #$soThe — try again later';
      case LoaiTrangThaiGheDe.daGhiXongChuaChuyen:
        return nn == NgonNgu.vi
            ? 'Đã ghi xong #$soThe — chưa chuyển hoá'
            : 'Recording #$soThe done — not converted yet';
    }
  }

  static String dongTrinhGhiAm(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đóng trình ghi âm' : 'Close voice recorder';
  static String xoaBanNayVaDongTrinhGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Xoá bản này và Đóng trình ghi âm'
      : 'Delete this recording and close';
  static String xoaBanNayDongTrinhGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Xoá bản này-Đóng trình ghi âm'
      : 'Delete this recording-Close';

  // ------------------------- Dialog "Cài đặt tự động Mở bảng điều khiển"
  static String moiLanGhiAmTuDongPrefix(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mỗi lần ghi âm: Tự động '
      : 'Each time you record: Automatically ';
  static String chuHoaHien(NgonNgu nn) => nn == NgonNgu.vi ? 'HIỆN' : 'SHOW';
  static String chuHoaAn(NgonNgu nn) => nn == NgonNgu.vi ? 'ẨN' : 'HIDE';
  static String bangDieuKhienNaySuffix(NgonNgu nn) =>
      nn == NgonNgu.vi ? ' bảng điều khiển này.' : ' this control panel.';

  // ------------------------- Thanh ghim nổi khi đang ghi âm (dạng "A-B")
  static String hienBangDieuKhien(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hiện bảng điều khiển' : 'Show control panel';
  static String hoanThanhChuyenThanhVanBanGach(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành-Chuyển thành văn bản'
      : 'Finish-Transcribe to text';
  static String hoanThanhTaoBanGhiAmMoiGach(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành-Tạo bản ghi âm mới'
      : 'Finish-Create new recording';
  static String hoanThanhPhatDeNgheLaiGach(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành-Phát để nghe lại'
      : 'Finish-Play to listen back';
  static String hoanThanhDongTrinhGhiAmGach(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành-Đóng trình ghi âm'
      : 'Finish-Close the recorder';

  // ------------------------- Bảng "Recording No. N" (dạng "A và B")
  static String hoanThanhVaChuyenHoaThanhVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành và Chuyển hoá thành văn bản'
      : 'Finish and transcribe to text';
  static String hoanThanhVaTaoBanGhiAmMoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành và Tạo bản ghi âm mới'
      : 'Finish and create new recording';
  static String hoanThanhVaPhatDeNgheLai(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành và Phát để nghe lại'
      : 'Finish and play to listen back';
  static String hoanThanhVaDongTrinhGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hoàn thành và Đóng trình ghi âm'
      : 'Finish and close the recorder';
  static String anBangDieuKhienTiepTucGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ẩn bảng điều khiển-tiếp tục Ghi âm'
      : 'Hide panel-keep recording';
  static String caiDatCheDoTuDongChuyenHoaVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt chế độ Tự động chuyển hoá văn bản'
      : 'Auto-transcribe mode settings';
  static String caiDatTuDongMoBangDieuKhienNay(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt tự động Mở bảng điều khiển này'
      : 'Auto-open this panel settings';

  // ------------------------- Thanh công cụ có vùng chọn (Copy/Cắt/Xoá)
  static String cat(NgonNgu nn) => nn == NgonNgu.vi ? 'Cắt' : 'Cut';
  static String xoaDoanDangChon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá đoạn đang chọn' : 'Delete selected text';

  // ------------------------- Menu Tài khoản-Cài đặt: nhãn "Ngôn ngữ"
  // Quy tắc: vi -> 'Ngôn ngữ - Language' (giữ y như cũ); en -> CHỈ
  // 'Language' (không lặp 'Language - Language'); ngôn ngữ MỚI thêm sau
  // này (nếu có) -> '<"Ngôn ngữ" dịch sang ngôn ngữ đó> - Language', phần
  // ' - Language' LUÔN giữ nguyên tiếng Anh, không dịch tiếp.
  static String nhanMenuNgonNgu(NgonNgu nn) {
    switch (nn) {
      case NgonNgu.vi:
        return 'Ngôn ngữ - Language';
      case NgonNgu.en:
        return 'Language';
    }
  }

  // ---------------------------------------------- Snackbar/thông báo nhanh
  static String khongKiemTraDuoc(NgonNgu nn, String loi) =>
      nn == NgonNgu.vi ? 'Không kiểm tra được: $loi' : 'Could not check: $loi';
  static String daXoaDoanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã xoá đoạn văn.' : 'Paragraph deleted.';
  static String khongTheHoanTacKhiConTheChuaXuLy(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không thể hoàn tác thêm khi còn thẻ ghi âm chưa xử lý xong.'
      : 'Cannot undo further while a recording card is still being processed.';
  static String khongTheLamLaiKhiConTheChuaXuLy(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không thể làm lại thêm khi còn thẻ ghi âm chưa xử lý xong.'
      : 'Cannot redo further while a recording card is still being processed.';
  static String chuaCoChuNaoDeChep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chưa có chữ nào để chép.' : 'There is no text to copy yet.';
  static String daSaoChepTatCaToast(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã sao chép tất cả' : 'Copied all';
  static String trangDangTrongKhongCoGiDeXoa(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Trang đang trống, không có gì để xoá.'
      : 'The page is empty — nothing to delete.';
  static String daXoaTatCaToast(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã xoá tất cả' : 'Deleted all';
  static String daSaoChepTatCaVaXoa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã sao chép tất cả và xoá' : 'Copied all and deleted';
  static String khongMoDuocHopThoaiChonTep(NgonNgu nn, String e) => nn == NgonNgu.vi
      ? 'Không mở được hộp thoại chọn tệp: $e'
      : 'Could not open the file picker: $e';
  static String khongDocDuocNoiDungTepVuaChon(NgonNgu nn, String e) => nn == NgonNgu.vi
      ? 'Không đọc được nội dung tệp vừa chọn: $e'
      : 'Could not read the selected file: $e';
  static String chuyenTepThatBai(NgonNgu nn, String loi) => nn == NgonNgu.vi
      ? 'Chuyển tệp thất bại: $loi'
      : 'File conversion failed: $loi';
  static String khongMoDuocHopThoaiChonAnh(NgonNgu nn, String e) => nn == NgonNgu.vi
      ? 'Không mở được hộp thoại chọn ảnh: $e'
      : 'Could not open the image picker: $e';
  static String khongDocDuocNoiDungAnhVuaChon(NgonNgu nn, String e) => nn == NgonNgu.vi
      ? 'Không đọc được nội dung ảnh vừa chọn: $e'
      : 'Could not read the selected image: $e';
  static String chuyenAnhThatBai(NgonNgu nn, String loi) => nn == NgonNgu.vi
      ? 'Chuyển ảnh thất bại: $loi'
      : 'Image conversion failed: $loi';
  static String tomTatThatBai(NgonNgu nn, String loi) => nn == NgonNgu.vi
      ? 'Tóm tắt thất bại: $loi'
      : 'Summarizing failed: $loi';
  static String moRongThatBai(NgonNgu nn, String loi) => nn == NgonNgu.vi
      ? 'Mở rộng thất bại: $loi'
      : 'Expanding failed: $loi';
  static String vietLaiThatBai(NgonNgu nn, String loi) => nn == NgonNgu.vi
      ? 'Viết lại thất bại: $loi'
      : 'Rewriting failed: $loi';
  static String daSaoChepToast(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã sao chép.' : 'Copied.';
  static String daThayTheToanBoVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đã thay thế toàn bộ văn bản.'
      : 'The whole text has been replaced.';
  static String doanVanBanGocDaThayDoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đoạn văn bản gốc đã thay đổi, không thể thay thế. Vui lòng thử lại.'
      : 'The original text has changed, so it cannot be replaced. Please try again.';
  static String daThayTheDoanVanBanDaChon(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đã thay thế đoạn văn bản đã chọn.'
      : 'The selected paragraph has been replaced.';
  static String khongMoDuocCamera(NgonNgu nn, String e) =>
      nn == NgonNgu.vi ? 'Không mở được camera: $e' : 'Could not open the camera: $e';
  static String khongDocDuocAnhVuaChup(NgonNgu nn, String e) => nn == NgonNgu.vi
      ? 'Không đọc được ảnh vừa chụp: $e'
      : 'Could not read the captured photo: $e';
  static String anhVuaChupNangQuaMB(NgonNgu nn, String soMB) => nn == NgonNgu.vi
      ? 'Ảnh vừa chụp nặng ${soMB}MB, vượt quá 15MB cho phép.'
      : 'The captured photo is ${soMB}MB, over the 15MB limit.';
  static String dangMoTrinhGhiAmHayDongTruocKhiTimKiem(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang mở trình ghi âm — hãy đóng trình ghi âm trước khi tìm kiếm.'
      : 'The voice recorder is open — close it before searching.';
  static String ghiChuDangMoDaBiXoaDaTaoMoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi chú đang mở đã bị xoá, đã tạo ghi chú mới.'
      : 'The open note was deleted — a new note has been created.';
  static String dangMoTimKiemHayDongTruocKhiGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang mở tìm kiếm — hãy đóng tìm kiếm trước khi ghi âm.'
      : 'Search is open — close it before recording audio.';
  static String khongXinDuocQuyenMicroDeGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không xin được quyền micro để ghi âm.'
      : 'Could not get microphone permission to record audio.';
  static String theGhiAmLoiGui(NgonNgu nn, int soThe, String e) => nn == NgonNgu.vi
      ? 'Thẻ ghi âm #$soThe: lỗi gửi — $e'
      : 'Recording card #$soThe: send error — $e';
  static String khongCoTheGhiAmNaoDeGui(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không có thẻ ghi âm nào trong văn bản để gửi.'
      : 'There is no recording card in the text to send.';
  static String theGhiAmDaBiXoaVinhVien(NgonNgu nn, int soThe) => nn == NgonNgu.vi
      ? 'Thẻ ghi âm #$soThe: dữ liệu đã bị xoá vĩnh viễn trước đó, không thể chuyển hoá được nữa.'
      : 'Recording card #$soThe: its data was permanently deleted earlier and can no longer be converted.';
  static String dangDungMicroTatTruocKhiGhiAmChamCham(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang dùng Micro — tắt Micro trước khi ghi âm.'
      : 'Microphone in use — turn it off before recording audio.';

  // --------------------------------------------- Modal "Cài đặt tìm kiếm"
  static String caiDatCheDoTimKiem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt chế độ tìm kiếm' : 'Search settings';
  static String khopCaHoaThuong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khớp cả chữ Hoa và chữ thường'
      : 'Match both uppercase and lowercase';
  static String khopCaHoaThuongGiaiThich(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tìm "h" sẽ ra cả "h" và "H" — không phân biệt chữ Hoa/thường khi so khớp.'
      : 'Searching "h" matches both "h" and "H" — case-insensitive.';
  static String hoaThuongLuonKhacNhau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chữ Hoa và chữ thường luôn khác nhau'
      : 'Uppercase and lowercase are always different';
  static String hoaThuongLuonKhacNhauGiaiThich(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tìm "h" chỉ ra đúng "h", không ra "H" — phân biệt chính xác chữ Hoa/thường.'
      : 'Searching "h" only matches "h", not "H" — exact case match.';
  static String khopCaDauKhongDau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khớp cả chữ không dấu và chữ có dấu'
      : 'Match both accented and unaccented letters';
  static String khopCaDauKhongDauGiaiThich(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tìm "thang" sẽ ra cả "thắng", "thằng", "tháng"... — không phân biệt dấu thanh khi so khớp.'
      : 'Searching "thang" matches "thắng", "thằng", "tháng"... — ignores tone marks.';
  static String dauKhongDauLuonKhacNhau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chữ không dấu và chữ có dấu luôn khác nhau'
      : 'Accented and unaccented letters are always different';
  static String dauKhongDauLuonKhacNhauGiaiThich(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tìm đúng chính xác dấu đã gõ — gõ "thang" chỉ ra "thang", không ra các từ có dấu khác.'
      : 'Matches the exact tone marks typed — typing "thang" only matches "thang", not accented variants.';
  static String huongDanThayThe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hướng dẫn thay thế' : 'Replace guide';
  static String chonKieuTomTat(NgonNgu nn, bool coDoanChon) => nn == NgonNgu.vi
      ? (coDoanChon ? 'Chọn kiểu tóm tắt (đoạn đang chọn)' : 'Chọn kiểu tóm tắt')
      : (coDoanChon ? 'Choose summary style (selected paragraph)' : 'Choose summary style');
  static String chonKieuMoRong(NgonNgu nn, bool coDoanChon) => nn == NgonNgu.vi
      ? (coDoanChon ? 'Chọn kiểu mở rộng (đoạn đang chọn)' : 'Chọn kiểu mở rộng')
      : (coDoanChon ? 'Choose expansion style (selected paragraph)' : 'Choose expansion style');
  static String doanDangChonTrongKhongCoGiDeKiemTra(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đoạn đang chọn trống, không có gì để kiểm tra.'
      : 'The selected paragraph is empty — nothing to check.';
  static String chuaCoVanBanNaoDeKiemTra(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chưa có văn bản nào để kiểm tra.'
      : 'There is no text to check yet.';
  static String doanDangChonTrongKhongCoGiDeTomTat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đoạn đang chọn trống, không có gì để tóm tắt.'
      : 'The selected paragraph is empty — nothing to summarize.';
  static String trangDangTrongKhongCoGiDeTomTat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Trang đang trống, không có gì để tóm tắt.'
      : 'The page is empty — nothing to summarize.';
  static String rutGonConPhanTramVanBanGoc(NgonNgu nn, int phanTram) => nn == NgonNgu.vi
      ? 'Rút gọn còn $phanTram% văn bản gốc'
      : 'Shorten to $phanTram% of the original text';
  static String ketQuaTomTat(NgonNgu nn, bool coDoanChon) => nn == NgonNgu.vi
      ? (coDoanChon ? 'Kết quả tóm tắt (đoạn đã chọn)' : 'Kết quả tóm tắt')
      : (coDoanChon ? 'Summary result (selected paragraph)' : 'Summary result');
  static String doanDangChonTrongKhongCoGiDeMoRong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đoạn đang chọn trống, không có gì để mở rộng.'
      : 'The selected paragraph is empty — nothing to expand.';
  static String trangDangTrongKhongCoGiDeMoRong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Trang đang trống, không có gì để mở rộng.'
      : 'The page is empty — nothing to expand.';
  static String moRongThanhPhanTramVanBanGoc(NgonNgu nn, int phanTram) => nn == NgonNgu.vi
      ? 'Mở rộng thành $phanTram% văn bản gốc'
      : 'Expand to $phanTram% of the original text';
  static String ketQuaMoRong(NgonNgu nn, bool coDoanChon) => nn == NgonNgu.vi
      ? (coDoanChon ? 'Kết quả mở rộng (đoạn đã chọn)' : 'Kết quả mở rộng')
      : (coDoanChon ? 'Expansion result (selected paragraph)' : 'Expansion result');
  static String doanDangChonTrongKhongCoGiDeVietLai(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đoạn đang chọn trống, không có gì để viết lại.'
      : 'The selected paragraph is empty — nothing to rewrite.';
  static String trangDangTrongKhongCoGiDeVietLai(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Trang đang trống, không có gì để viết lại.'
      : 'The page is empty — nothing to rewrite.';
  static String ketQuaVietLai(NgonNgu nn, bool coDoanChon) => nn == NgonNgu.vi
      ? (coDoanChon ? 'Kết quả viết lại (đoạn đã chọn)' : 'Kết quả viết lại')
      : (coDoanChon ? 'Rewrite result (selected paragraph)' : 'Rewrite result');
  static String troChuyenDangNangCapNoiDung(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tính năng này giúp bạn trò chuyện với mọi người... Tính năng này hiện đang nâng cấp.'
      : 'This feature lets you chat with everyone... It is currently being upgraded.';
  static String banCoTheBamOBenDuoiDeSuaTruocKhiThayThe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bạn có thể bấm vào ô bên dưới để sửa lại chữ tuỳ ý trước khi thay thế.'
      : 'You can tap the box below to edit the text before replacing it.';
  static String thayTheDoanDaChon(NgonNgu nn, bool coDoanChon) => nn == NgonNgu.vi
      ? (coDoanChon ? 'Thay thế đoạn đã chọn' : 'Thay thế toàn bộ văn bản')
      : (coDoanChon ? 'Replace selected paragraph' : 'Replace whole text');
  static String vanBanAiSapMatKhiHuy(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Văn bản AI vừa trả về (kể cả phần bạn đã sửa, nếu có) sẽ mất hẳn, không thể lấy lại. Bạn có chắc chắn muốn huỷ không?'
      : 'The text the AI just returned (including any edits you made) will be lost for good. Are you sure you want to cancel?';
  static String banCoTheBamOBenDuoiDeSuaTruocKhiChen(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bạn có thể bấm vào ô bên dưới để sửa lại chữ tuỳ ý trước khi chèn.'
      : 'You can tap the box below to edit the text before inserting it.';
  static String vietLaiChoHayHonTieuDe(NgonNgu nn, bool coDoanChon) => nn == NgonNgu.vi
      ? (coDoanChon ? 'Viết lại cho hay hơn (đoạn đang chọn)' : 'Viết lại cho hay hơn')
      : (coDoanChon ? 'Rewrite more fluently (selected paragraph)' : 'Rewrite more fluently');
  static String noiDungHuongDanThayThe(NgonNgu nn) => nn == NgonNgu.vi
      ? '• "Thay chỗ này": chỉ thay đúng kết quả đang chọn (số thứ tự đang hiện, ví dụ 3/5).\n\n'
          '• "Tất cả": thay hết mọi kết quả cùng lúc, có hỏi xác nhận trước khi làm.\n\n'
          '• Để trống ô Thay thế rồi bấm một trong hai nút: kết quả tìm kiếm đó bị XOÁ, không cần gõ gì để thay vào chỗ trống.'
      : '• "Replace here": replaces only the currently selected result (the number shown, e.g. 3/5).\n\n'
          '• "All": replaces every result at once, with a confirmation first.\n\n'
          '• Leave the Replace box empty and tap either button: that search result is DELETED, no need to type anything to replace it with.';

  // --------------------------------------------- Modal "Danh sách phím tắt"
  static String microVaGhiAm(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Micro và Ghi âm' : 'Microphone and Recording';

  static String dieuHuong(NgonNgu nn) => nn == NgonNgu.vi ? 'Điều hướng' : 'Navigation';

  static String chung(NgonNgu nn) => nn == NgonNgu.vi ? 'Chung' : 'General';

  static String dinhDangVanBanDeMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Định dạng văn bản' : 'Text formatting';

  static String moTaThemBamNhanhLienTiep(NgonNgu nn, String phim) => nn == NgonNgu.vi
      ? ' (bấm $phim rồi buông ra, bấm lại lần nữa trong 1 giây)'
      : ' (press $phim and release, then press it again within 1 second)';

  static String batTatMicro(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bật/tắt Micro (vừa nói vừa ra chữ)'
      : 'Turn Microphone on/off (speak and type at once)';

  static String moDongTrinhGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mở/đóng trình Ghi âm (ghi âm xong mới ra chữ)'
      : 'Open/close the Recorder (record first, transcribe after)';

  static String anHienBoNhoTamDanVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ẩn/hiện Bộ nhớ tạm để dán văn bản'
      : 'Show/hide the clipboard history panel';

  static String anHienTuDienNhapLieuNhanh(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ẩn/hiện Từ điển nhập liệu nhanh'
      : 'Show/hide the quick-dictionary panel';

  static String danChuTho(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Dán chữ thô, không kèm định dạng văn bản'
      : 'Paste as plain text, without formatting';

  static String xoaDinhDangKemMoTa(NgonNgu nn, String moTaPhim) => nn == NgonNgu.vi
      ? '$moTaPhim — đưa văn bản về trạng thái ban đầu (không áp dụng cho các đoạn AI đang đề xuất)'
      : '$moTaPhim — reverts the text to its original state (doesn\'t apply to pending AI suggestions)';

  static String huongDanBamPhimTat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Để sử dụng phím tắt: Một ngón tay bấm và giữ im phím Ctrl, '
          'sau đó ngón tay thứ hai bấm phím còn lại.'
      : 'To use a shortcut: hold Ctrl down with one finger, then press the other key with a second finger.';

  static String tepAmThanhVuotQuaGioiHan(NgonNgu nn, String tenTep, String soMB) => nn == NgonNgu.vi
      ? 'Tệp "$tenTep" nặng ${soMB}MB, vượt quá 25MB cho phép. Hãy nén '
          'hoặc cắt ngắn tệp âm thanh bằng công cụ bên ngoài rồi thử lại.'
      : 'File "$tenTep" is ${soMB}MB, over the 25MB limit. Please compress '
          'or trim the audio file with an external tool and try again.';

  static String anhVuotQuaGioiHan(NgonNgu nn, String tenTep, String soMB) => nn == NgonNgu.vi
      ? 'Ảnh "$tenTep" nặng ${soMB}MB, vượt quá 15MB cho phép. Hãy nén '
          'ảnh bằng công cụ bên ngoài rồi thử lại.'
      : 'Image "$tenTep" is ${soMB}MB, over the 15MB limit. Please compress '
          'the image with an external tool and try again.';

  // ----------------------------------------------------- Modal "Donate"
  static String donateUngHoCamOnTacGia(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Donate ủng hộ - cảm ơn tác giả' : 'Donate - thank the author';

  static String noiDungDonate(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Flowrite vẫn đang trong quá trình xây dựng và hoàn thiện. '
          'Donate của bạn giúp tác giả có thêm kinh phí trả cho bộ nhớ '
          'đám mây, các API xử lý văn bản/hình ảnh/âm thanh, duy trì '
          'app, đưa app lên các chợ ứng dụng, và phát triển thêm những '
          'app mới trong tương lai.\n\n'
          'Donate là nguồn động lực để tác giả tiếp tục, giúp Flowrite '
          'luôn luôn miễn phí cho mọi người. Nhiều hay ít đều quý giá — '
          'cảm ơn bạn rất nhiều!'
      : 'Flowrite is still being built and improved. '
          'Your donation helps the author cover cloud storage, text/image/'
          'audio processing APIs, app maintenance, publishing to app '
          'stores, and building new apps in the future.\n\n'
          'Donations are motivation for the author to keep going, and keep '
          'Flowrite free for everyone. Every amount matters — thank you so much!';

  static String donateQuaPaypal(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Donate qua Paypal' : 'Donate via Paypal';

  static String quetMaHoacBamLinkPaypal(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Quét mã hoặc bấm link dưới để mở trang nhận donate trên Paypal.'
      : 'Scan the code or tap the link below to open the Paypal donation page.';

  static String linkPaypal(NgonNgu nn) => nn == NgonNgu.vi ? 'Link Paypal' : 'Paypal link';

  static String email(NgonNgu nn) => nn == NgonNgu.vi ? 'Email' : 'Email';

  static String ten(NgonNgu nn) => nn == NgonNgu.vi ? 'Tên' : 'Name';

  static String donateQuaMomo(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Donate qua Momo' : 'Donate via Momo';

  static String moAppMomoQuetMa(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mở app Momo rồi quét mã này, hoặc chuyển trực tiếp tới số điện thoại dưới đây.'
      : 'Open the Momo app and scan this code, or transfer directly to the phone number below.';

  static String soDienThoai(NgonNgu nn) => nn == NgonNgu.vi ? 'Số điện thoại' : 'Phone number';

  static String donateQuaNganHangTPBank(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Donate qua Ngân hàng TPBank (Việt Nam)'
      : 'Donate via TPBank (Vietnam)';

  static String donateQuaNganHangTPBankNgan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Donate qua Ngân hàng TPBank' : 'Donate via TPBank';

  static String moAppNganHangVietQr(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mở app ngân hàng bất kỳ (hỗ trợ VietQR) rồi quét mã này.'
      : 'Open any banking app that supports VietQR and scan this code.';

  static String nganHang(NgonNgu nn) => nn == NgonNgu.vi ? 'Ngân hàng' : 'Bank';

  static String soTaiKhoan(NgonNgu nn) => nn == NgonNgu.vi ? 'Số tài khoản' : 'Account number';

  static String khongTaiDuocMaQr(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không tải được mã QR — kiểm tra lại mạng.' : 'Could not load the QR code — check your connection.';

  static String khuyenKhichGhiNoiDungChuyenKhoan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khuyến khích ghi thêm nội dung chuyển khoản: "Donate app Flowrite" — '
          'để tác giả biết được nguồn donate.'
      : 'Please add a transfer note: "Donate app Flowrite" — so the author knows where the donation is from.';

  static String chep(NgonNgu nn) => nn == NgonNgu.vi ? 'Chép' : 'Copy';

  static String daChepTen(NgonNgu nn, String ten) =>
      nn == NgonNgu.vi ? 'Đã chép "$ten"' : 'Copied "$ten"';

  // ------------------------------------------- Trang "Góp ý thêm, báo lỗi"
  static String guiKhongThanhCongKiemTraLaiMang(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Gửi không thành công — kiểm tra lại mạng rồi thử lại.'
      : 'Failed to send — check your connection and try again.';

  static String camOnBanDaGopYBaoLoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cảm ơn bạn đã góp ý, báo lỗi về ứng dụng!' : 'Thanks for your feedback and bug report!';

  static String adminSeTiepThuSomNhatCoThe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Admin sẽ tiếp thu và triển khai sớm nhất có thể.'
      : 'The admin will review it and roll out changes as soon as possible.';

  static String moiBanGopYThemHoacBaoLoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mời bạn góp ý thêm hoặc báo lỗi về ứng dụng — mọi ý kiến đều được '
          'ghi nhận và sẽ giúp Flowrite tốt hơn.'
      : 'Feel free to share more feedback or report a bug — every comment '
          'is noted and helps make Flowrite better.';

  static String nhapGopYHoacMoTaLoi(NgonNgu nn, int gioiHanDuoi) => nn == NgonNgu.vi
      ? 'Nhập góp ý hoặc mô tả lỗi bạn gặp phải (tối thiểu $gioiHanDuoi ký tự)...'
      : 'Enter your feedback or describe the bug you encountered (at least $gioiHanDuoi characters)...';

  static String emailCuaBanKhongBatBuoc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Email của bạn (không bắt buộc)' : 'Your email (optional)';

  static String deAdminPhanHoiLaiNeuCan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Để admin phản hồi lại nếu cần' : 'So the admin can reply if needed';

  static String nutGui(NgonNgu nn) => nn == NgonNgu.vi ? 'Gửi' : 'Send';

  static String coThacMacGopYBaoLoiLienHe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Có thắc mắc, góp ý, báo lỗi, vui lòng liên hệ qua một trong các cách sau:'
      : 'For questions, feedback, or bug reports, please contact us via one of the following:';

  static String lienHeEmailKhac(NgonNgu nn, String email) =>
      '**${nn == NgonNgu.vi ? 'Email khác' : 'Other email'}:** $email';

  static String lienHeDienThoai(NgonNgu nn, String soDienThoai) =>
      '**${nn == NgonNgu.vi ? 'Điện thoại' : 'Phone'}:** $soDienThoai';

  // --------------------------------- Modal "Bộ nhớ tạm để dán văn bản"
  static String hayBamChonMotPhimTruocKhiLuu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hãy bấm chọn một phím trước khi lưu.'
      : 'Please press a key before saving.';

  static String phimTatDangTrungVoiChucNang(NgonNgu nn, String tenChucNang, String nhanPhim) =>
      nn == NgonNgu.vi
          ? 'Phím tắt này đang trùng với chức năng "$tenChucNang" '
              '($nhanPhim) — chọn phím khác nhé.'
          : 'This shortcut conflicts with "$tenChucNang" '
              '($nhanPhim) — please choose another key.';

  static String micoVuaNoiVuaRaChuTen(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Micro (vừa nói vừa ra chữ)' : 'Mic (speak and type at once)';

  static String ghiAmXongMoiRaChuTen(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ghi âm (Ghi âm xong mới ra chữ)' : 'Record (record first, then transcribe)';

  static String daChonPhimTatChoBoNhoTam(NgonNgu nn, String nhanPhim, String doanTuDong) =>
      nn == NgonNgu.vi
          ? 'Đã chọn phím tắt $nhanPhim cho Bộ nhớ tạm để dán văn bản, '
              'tự động $doanTuDong'
          : 'Shortcut $nhanPhim set for the clipboard-paste history, '
              'automatically $doanTuDong';

  static String chonPhimTatChoNut(NgonNgu nn, String nhanPhim, bool laMicro) {
    final tenNut = laMicro
        ? (nn == NgonNgu.vi ? 'nút micro vừa nói vừa ra chữ' : 'the mic (speak-and-type) button')
        : (nn == NgonNgu.vi ? 'nút ghi âm' : 'the record button');
    return nn == NgonNgu.vi
        ? 'chọn phím tắt $nhanPhim cho $tenNut'
        : 'set shortcut $nhanPhim for $tenNut';
  }

  static String boNhoTamDanVanBanTen(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bộ nhớ tạm để dán văn bản' : 'Clipboard paste history';

  static String batBoNhoTamDanVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bật Bộ nhớ tạm để dán văn bản' : 'Enable clipboard paste history';

  static String phimTatAnHienBoNhoTamNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Phím tắt ẩn hiện bộ nhớ tạm này' : 'Shortcut to show/hide this history';

  static String gioiThieuBoNhoTamDanVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bộ nhớ tạm để dán văn bản là một bảng NHỚ RIÊNG của app, giữ '
          'lại tối đa 10 đoạn văn bản gần nhất bạn đã Cắt hoặc Copy — '
          'khác với bộ nhớ đệm thường của máy (chỉ nhớ được ĐÚNG MỘT '
          'đoạn gần nhất). Khi BẬT: mỗi lần Cắt/Copy, đoạn văn bản tự '
          'được thêm vào bảng; bấm nút hoặc dùng phím tắt ở trên để mở '
          'bảng, rồi bấm vào một dòng (hoặc gõ đúng phím số của dòng '
          'đó) để dán ngay vào vị trí con trỏ. Khi TẮT: Cắt/Copy vẫn '
          'hoạt động bình thường với bộ nhớ đệm của máy như trước, chỉ '
          'không ghi thêm vào bảng 10 dòng này nữa, và nút/phím tắt mở '
          'bảng cũng ẩn đi.'
      : 'The clipboard paste history is the app\'s OWN memory, keeping '
          'up to the last 10 pieces of text you Cut or Copied — unlike '
          'the device\'s regular clipboard (which only remembers the '
          'ONE most recent piece). When ON: every Cut/Copy is '
          'automatically added to the list; use the button or the '
          'shortcut above to open it, then tap a row (or type its '
          'number key) to paste it right at the cursor. When OFF: '
          'Cut/Copy still work normally with the device\'s regular '
          'clipboard as before, it just stops adding to this 10-row '
          'list, and the button/shortcut to open it is hidden too.';

  static String nhanMotPhim(NgonNgu nn) => nn == NgonNgu.vi ? 'Nhấn một phím' : 'Press a key';

  static String hayNhanMotPhimBatKyTrenBanPhim(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hãy nhấn một phím bất kỳ trên bàn phím...'
      : 'Press any key on your keyboard...';

  static String phimTatChoBoNhoTamDanVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Phím tắt cho Bộ nhớ tạm để dán văn bản' : 'Shortcut for the clipboard paste history';

  static String tenTab(NgonNgu nn) => nn == NgonNgu.vi ? 'Tab' : 'Tab';

  static String giaiThichTab(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Phím Tab — hình mũi tên hai chiều (⇥). Nằm '
          'ở góc trên bên trái bàn phím, ngay phía trên phím '
          'Caps Lock, bên trái chữ Q.'
      : 'The Tab key — the two-way arrow icon (⇥). Located '
          'at the top-left of the keyboard, right above '
          'Caps Lock, to the left of the Q key.';

  static String tenCtrlCongThem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ctrl + ...' : 'Ctrl + ...';

  static String giaiThichCtrlCongThem(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Giữ phím Ctrl (góc dưới cùng bên trái bàn '
          'phím) rồi bấm thêm một phím khác — ví dụ Ctrl + G.'
      : 'Hold the Ctrl key (bottom-left corner of the '
          'keyboard) and press another key — e.g. Ctrl + G.';

  static String tenBamCtrl2Lan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bấm Ctrl 2 lần liên tiếp' : 'Press Ctrl twice in a row';

  static String giaiThichBamCtrl2Lan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm phím Ctrl rồi BUÔNG RA NGAY (không giữ), '
          'sau đó bấm Ctrl thêm một lần nữa trong vòng 1 giây '
          '— giống bấm đúp chuột nhưng bằng phím Ctrl.'
      : 'Press Ctrl and RELEASE it right away (don\'t hold), '
          'then press Ctrl again within 1 second '
          '— like a double-click, but with the Ctrl key.';

  static String tenBamShift2Lan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bấm Shift 2 lần liên tiếp' : 'Press Shift twice in a row';

  static String giaiThichBamShift2Lan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm phím Shift rồi buông ra ngay, bấm Shift '
          'thêm một lần nữa trong vòng 1 giây. Lưu ý: nếu gõ '
          'chữ hoa rất nhanh, đôi khi có thể vô tình kích hoạt.'
      : 'Press Shift and release it right away, then press '
          'Shift again within 1 second. Note: typing capital '
          'letters very fast may sometimes trigger this by accident.';

  static String bamDeChonPhim(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bấm để chọn phím' : 'Tap to choose a key';

  // --------------------------------- Modal "Từ điển nhập liệu nhanh"
  static String vuiLongDangNhapTaiKhoanGoogleTruoc(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Vui lòng đăng nhập tài khoản Google trước.'
      : 'Please sign in with a Google account first.';

  static String phimVaDayDuNoiDung(NgonNgu nn, String chuCai) =>
      nn == NgonNgu.vi ? 'Phím $chuCai — đầy đủ nội dung' : 'Key $chuCai — full content';

  static String xoaNoiDungDongPhim(NgonNgu nn, String chuCai) =>
      nn == NgonNgu.vi ? 'Xoá nội dung dòng Phím $chuCai?' : 'Clear the content of key $chuCai?';

  static String khongTheHoanTacBanCoChacChan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không thể hoàn tác lại được. Bạn có chắc chắn không?'
      : 'This cannot be undone. Are you sure?';

  static String phimTatChoTuDienNhapLieuNhanh(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Phím tắt cho Từ điển nhập liệu nhanh' : 'Shortcut for the quick-text dictionary';

  static String tenBamAlt2Lan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bấm Alt 2 lần liên tiếp' : 'Press Alt twice in a row';

  static String giaiThichBamAlt2Lan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm phím Alt, buông ra, rồi bấm lại lần '
          'nữa trong khoảng 1 giây (mặc định).'
      : 'Press Alt, release it, then press it again '
          'within about 1 second (default).';

  static String tenAltShift(NgonNgu nn) => nn == NgonNgu.vi ? 'Alt + Shift' : 'Alt + Shift';

  static String giaiThichAltShift(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Giữ phím Alt và Shift cùng lúc.' : 'Hold the Alt and Shift keys together.';

  static String giaiThichCtrlCongThemTuDien(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Giữ phím Ctrl rồi bấm thêm một phím khác — ví dụ Ctrl + G.'
      : 'Hold Ctrl and press another key — e.g. Ctrl + G.';

  static String chonThuTuGiuaCacPhimTatChuCai(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chọn thứ tự giữa các phím tắt chữ cái'
      : 'Choose the order of the letter shortcuts';

  static String sapXepTheoCacHangChuCaiTrenBanPhim(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Sắp xếp theo các hàng chữ cái trên bàn phím'
      : 'Sort by keyboard letter rows';

  static String giaiThichSapXepTheoHang(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Sắp xếp theo hàng phím của bàn phím vật lý.'
      : 'Sort by the physical keyboard\'s key rows.';

  static String sapXepTheoBangChuCaiAZ(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sắp xếp theo Bảng chữ cái A → Z' : 'Sort alphabetically A → Z';

  static String giaiThichSapXepTheoBangChuCai(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Sắp xếp theo tiêu chuẩn bảng chữ cái quốc tế '
          'alphabet, tức là từ A đến Z.'
      : 'Sort by the standard international alphabet, '
          'from A to Z.';

  static String trongNgoacDon(NgonNgu nn) => nn == NgonNgu.vi ? '(trống)' : '(empty)';

  static String phimChuCai(NgonNgu nn, String chuCai) =>
      nn == NgonNgu.vi ? 'Phím $chuCai' : 'Key $chuCai';

  static String huyKhongLuuThayDoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Huỷ - Không lưu thay đổi' : 'Cancel - Don\'t save changes';

  static String bamVaGiuTungDongKeoThaDeThayDoiViTri(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm và giữ từng dòng, sau đó kéo và thả để thay đổi vị trí cho '
          'từng dòng.'
      : 'Press and hold a row, then drag and drop it to change its position.';

  static String boNhoDamMayTen(NgonNgu nn) => nn == NgonNgu.vi ? 'Bộ nhớ Đám mây' : 'Cloud storage';

  static String tuDienDamMayLauDaiTrenInternet(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Từ điển này trong Bộ nhớ Đám mây lâu dài trên internet của tài khoản đang đăng nhập vào'
      : 'This dictionary is stored permanently online, in the Cloud storage of the signed-in account';

  static String tuDienNoiBoLauDaiCuaThietBi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Từ điển này trong Bộ nhớ nội bộ lâu dài của thiết bị (hoặc của trình duyệt)'
      : 'This dictionary is stored permanently in the device\'s (or browser\'s) local storage';

  static String batTuDienNhapLieuNhanh(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bật Từ điển nhập liệu nhanh' : 'Enable the quick-text dictionary';

  static String phimTatAnHienBangTuDienNhapLieuNhanh(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Phím tắt ẩn hiện bảng Từ điển nhập liệu nhanh'
      : 'Shortcut to show/hide the quick-text dictionary';

  static String thayDoiThuTuGiuaCacDong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thay đổi thứ tự giữa các dòng' : 'Change the order of the rows';

  static String gioiThieuTuDienNhapLieuNhanh(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mỗi dòng ứng với một phím chữ cái trên bàn phím vật lý — gõ '
          'sẵn đoạn văn bản muốn dán nhanh vào dòng tương ứng. Mở bảng '
          'bằng nút trên thanh công cụ hoặc phím tắt ở trên, rồi bấm vào '
          'một dòng (hoặc gõ đúng phím chữ cái của dòng đó) để dán ngay '
          'vào vị trí con trỏ. Để trống dòng nào cũng được. Mỗi lần sửa '
          'tự lưu lại ngay, không cần bấm nút Lưu.'
      : 'Each row corresponds to a letter key on your physical keyboard — '
          'type in the text you want to quickly paste for that row. Open '
          'the list with the toolbar button or the shortcut above, then '
          'tap a row (or type its letter key) to paste it right at the '
          'cursor. Any row can be left empty. Every edit is saved '
          'instantly, no Save button needed.';

  static String xemDayDuNoiDungCuaDongNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xem đầy đủ nội dung của dòng này' : 'View this row\'s full content';

  static String daDan(NgonNgu nn) => nn == NgonNgu.vi ? 'Đã dán' : 'Pasted';

  static String tuDienNhapLieuNhanhTen(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ điển nhập liệu nhanh' : 'Quick-text dictionary';

  // ------------------------------------- Modal "Từ điển sửa lỗi chính tả"
  static String tuThayTheVaoThuNhat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ thay thế vào thứ nhất' : 'First replacement word';

  static String tuThayTheVaoThuHai(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ thay thế vào thứ hai' : 'Second replacement word';

  static String tuThayTheVaoThuBa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ thay thế vào thứ ba' : 'Third replacement word';

  static String xoaHangNay(NgonNgu nn) => nn == NgonNgu.vi ? 'Xoá hàng này' : 'Delete this row';

  static String xoaChuNay(NgonNgu nn) => nn == NgonNgu.vi ? 'Xoá chữ này' : 'Clear this text';

  static String batHoatDongTuDienChinhTa(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bật hoạt động của từ điển sửa lỗi chính tả'
      : 'Enable the spelling-correction dictionary';

  static String tuDienNayTrenDamMay(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Từ điển này trong Bộ nhớ Đám mây lâu dài trên internet của tài khoản đang đăng nhập vào'
      : 'This dictionary lives permanently online, in the Cloud Storage of the signed-in account';

  static String tuDienNayNoiBo(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Từ điển này trong Bộ nhớ nội bộ lâu dài của thiết bị (hoặc của trình duyệt)'
      : 'This dictionary lives permanently in this device\'s (or browser\'s) local storage';

  static String tuDienSuaLoiChinhTaCuaBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ điển sửa lỗi chính tả của bạn' : 'Your spelling-correction dictionary';

  static String timTrongTuDien(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tìm trong từ điển' : 'Search the dictionary';

  static String nutThem(NgonNgu nn) => nn == NgonNgu.vi ? 'Thêm' : 'Add';

  static String nutThemCapTu(NgonNgu nn) => nn == NgonNgu.vi ? 'Thêm cặp từ' : 'Add a word pair';

  static String gioiThieuTuDienChinhTa(NgonNgu nn) => nn == NgonNgu.vi
      ? 'App tự quét văn bản — từ nào khớp "Từ bị lỗi chính tả hay gặp" sẽ '
          'được gạch vàng lượn sóng, bấm vào để thay/xoá nhanh. Để trống "Từ '
          'thay thế vào thứ nhất" (và không thêm từ thay thế nào khác) nghĩa '
          'là đề xuất xoá hẳn từ đó. Có thể thêm tối đa 3 từ thay thế cho mỗi '
          'cặp — tất cả đều hiện trong đề xuất, còn "Chấp nhận tất cả đề xuất '
          'của từ điển" chỉ áp dụng từ thay thế thứ nhất.'
      : 'The app scans your text automatically — any word matching your '
          '"Common misspelled word" gets a yellow wavy underline; tap it to '
          'replace or delete it quickly. Leaving the "First replacement word" '
          'empty (and adding no other replacement) proposes deleting that '
          'word outright. You can add up to 3 replacements per pair — all of '
          'them show up in the suggestion, while "Accept all dictionary '
          'suggestions" only applies the first replacement.';

  static String tuBiLoiChinhTaHayGap(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ bị lỗi chính tả hay gặp' : 'Common misspelled word';

  static String viDuVdMik(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ví dụ: vd, mik, ...' : 'E.g.: thx, u, ...';

  static String tuNayDaCoTrongMotCapKhac(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Từ này đã có trong một cặp khác — các từ bị lỗi không được trùng nhau.'
      : 'This word already exists in another pair — misspelled words can\'t repeat.';

  static String deTrongDeXuatXoa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Để trống = đề xuất xoá' : 'Empty = suggest deleting';

  static String tuThayTheThem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Từ thay thế thêm' : 'Extra replacement word';

  static String tuThayTheThuNhatKhongDuocGiongHet(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Từ thay thế thứ nhất không được giống hệt từ bị lỗi ở trên.'
      : 'The first replacement word can\'t be identical to the misspelled word above.';

  static String themTuThayThe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thêm Từ thay thế' : 'Add replacement word';

  static String xoaCapTu(NgonNgu nn) => nn == NgonNgu.vi ? 'Xoá cặp từ' : 'Delete word pair';

  static String timTrongTuDienHintText(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tìm trong từ điển...' : 'Search the dictionary...';

  // ---------------------------------- Modal "Cài đặt nút Kiểm tra toàn văn"
  static String kiemToanVanMoPhong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm toàn văn' : 'Full-text check';

  static String giaiThichDoDaiDeXuat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đây là độ dài THAM KHẢO cho từng đoạn mà AI đề xuất khi bấm "Kiểm tra '
          'toàn văn" — không phải giới hạn cứng nhắc, AI vẫn có thể vượt ra ngoài '
          'khoảng này nếu ngữ cảnh đòi hỏi.\n\n'
          'Đoạn đề xuất càng NGẮN thì càng bám sát nguyên văn của bạn, ít khả năng '
          'lệch ý hơn, nhưng có thể chưa đủ mượt vì AI phải sửa từng mẩu nhỏ.\n\n'
          'Đoạn đề xuất càng DÀI thì AI càng có chỗ để viết lại cho gọn gàng, súc '
          'tích hơn, nhưng cũng dễ lệch khỏi ý gốc của bạn hơn vì AI phải diễn đạt '
          'lại nhiều hơn.\n\n'
          'Khoảng ký tự tham khảo cho từng mức:\n'
          'Rất ngắn: khoảng 4–8 ký tự\n'
          'Ngắn: khoảng 8–14 ký tự\n'
          'Trung bình: khoảng 12–20 ký tự\n'
          'Dài: khoảng 20–34 ký tự\n'
          'Rất dài: khoảng 34–56 ký tự'
      : 'This is a REFERENCE length for each paragraph the AI suggests when you '
          'tap "Full-text check" — not a hard limit, the AI may still go beyond '
          'it if context calls for it.\n\n'
          'A SHORTER suggested paragraph stays closer to your original wording, '
          'with less risk of drifting from your meaning, but may feel less '
          'polished since the AI has to fix small pieces at a time.\n\n'
          'A LONGER suggested paragraph gives the AI more room to rewrite '
          'smoothly and concisely, but is more likely to drift from your '
          'original intent since the AI has to rephrase more.\n\n'
          'Reference character ranges per level:\n'
          'Very short: about 4–8 characters\n'
          'Short: about 8–14 characters\n'
          'Medium: about 12–20 characters\n'
          'Long: about 20–34 characters\n'
          'Very long: about 34–56 characters';

  static String giaiThichCauLenhTuyChinh(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đây là câu lệnh RIÊNG của bạn, gửi kèm theo chỉ dẫn gốc của hệ thống mỗi '
          'lần bấm "Kiểm tra toàn văn". Nếu ý bạn viết ở đây xung đột với chỉ dẫn '
          'gốc, AI sẽ ưu tiên làm theo ý của bạn trước.\n\n'
          'Ví dụ: bạn có thể dặn AI giữ nguyên văn phong thân mật, tránh dùng từ Hán '
          'Việt, hoặc luôn viết hoa một tên riêng nào đó.'
      : 'This is YOUR OWN instruction, sent along with the system\'s original '
          'guidance every time you tap "Full-text check". If what you write here '
          'conflicts with the original guidance, the AI will prioritize your '
          'instruction.\n\n'
          'Example: you can ask the AI to keep a casual tone, avoid certain '
          'words, or always capitalize a specific proper name.';

  static String cauLenhRiengCuaBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Câu lệnh riêng của bạn' : 'Your own instruction';

  static String viDuGiuVanPhongThanMat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ví dụ: giữ văn phong thân mật, tránh từ Hán Việt...'
      : 'Example: keep a casual tone, avoid certain words...';

  static String cauLenhGuiKemChiDanGoc(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Câu lệnh này được gửi kèm theo chỉ dẫn gốc của hệ thống mỗi '
          'lần bấm "Kiểm tra toàn văn", và được ưu tiên hơn nếu có xung '
          'đột.'
      : 'This instruction is sent along with the system\'s original guidance '
          'every time you tap "Full-text check", and takes priority if there '
          'is a conflict.';

  static String caiDatNutKiemTraToanVanTieuDe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt nút "Kiểm tra toàn văn"'
      : 'Settings for the "Full-text check" button';

  static String deSuDungChucNangKiemTraToanVan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Để sử dụng chức năng kiểm tra toàn văn bằng AI, vui lòng bấm nút '
          '"Làm việc với AI" ở thanh công cụ rồi chọn mục '
      : 'To use the AI full-text check feature, tap the '
          '"Work with AI" button on the toolbar, then choose ';

  static String dayLaBuocQuanTrongSauMoiLanSoanXong(NgonNgu nn) =>
      nn == NgonNgu.vi
          ? 'Đây là bước quan trọng sau mỗi lần soạn xong 1 bài văn bản.'
          : 'This is an important step after finishing writing a document.';

  static String caiDatTinhNangNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'CÀI ĐẶT TÍNH NĂNG NÀY' : 'SETTINGS FOR THIS FEATURE';

  static String doDaiTungDoanVanDuocDeXuat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Độ dài của từng đoạn văn được đề xuất'
      : 'Length of each suggested paragraph';

  static String tenMucDoDaiDeXuat(int mucDo, NgonNgu nn) {
    const vi = ['Rất ngắn', 'Ngắn', 'Trung bình', 'Dài', 'Rất dài'];
    const en = ['Very short', 'Short', 'Medium', 'Long', 'Very long'];
    return (nn == NgonNgu.vi ? vi : en)[mucDo];
  }

  static String tuyChinhCauLenhChoAiLamViec(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tùy chỉnh câu lệnh để cho AI làm việc'
      : 'Customize the instruction for the AI';

  static String cauLenhRiengDangTrong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Câu lệnh riêng của bạn đang trống'
      : 'Your own instruction is empty';

  static String cauLenhDangChuaSoTu(NgonNgu nn, int soTu) => nn == NgonNgu.vi
      ? 'Câu lệnh của bạn đang chứa $soTu từ'
      : 'Your instruction currently has $soTu word${soTu == 1 ? '' : 's'}';

  // -------------------------------- Trang "Cài đặt Ứng dụng vào Thiết bị"
  static String caiDatBangChrome(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt bằng trình duyệt Chrome (PC, điện thoại, máy tính bảng)'
      : 'Install via Chrome browser (PC, phone, tablet)';

  static String moTaCaiDatChrome(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mở trang web này bằng trình duyệt Chrome (hoặc Edge, Brave — cùng '
          'nền Chromium). Nhìn lên thanh địa chỉ phía trên, bấm vào nút "Cài '
          'đặt" (hình máy tính có mũi tên, hoặc hình dấu "+"). App sẽ hiện ra '
          'ngay ở màn hình chính thiết bị của bạn, giống một app thật — không '
          'cần CH Play hay App Store, mở lên là chạy, không còn thanh địa chỉ '
          'của trình duyệt nữa.'
      : 'Open this website in Chrome (or Edge, Brave — same Chromium base). '
          'Look at the address bar above and tap the "Install" button (a '
          'computer icon with an arrow, or a "+" icon). The app will appear '
          'right on your device\'s home screen, just like a real app — no '
          'Play Store or App Store needed, it just opens and runs, with no '
          'browser address bar anymore.';

  static String caiDatChoIphoneIpad(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt cho iPhone, iPad' : 'Install for iPhone, iPad';

  static String moTaCaiDatIphone(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bản app riêng cho iPhone/iPad sẽ không bị kẹt bàn phím ảo như bản '
          'web, và "Micro vừa nói vừa ra chữ" hoạt động đầy đủ (bản web trên '
          'iPhone hiện phải tắt tính năng này).'
      : 'A dedicated iPhone/iPad app won\'t get stuck with the on-screen '
          'keyboard like the web version, and "real-time speech-to-text '
          'Mic" works fully (the web version on iPhone currently has to turn '
          'this feature off).';

  static String thongBaoIphoneDangXayDung(NgonNgu nn) => nn == NgonNgu.vi
      ? 'App cho iPhone/iPad đang trong quá trình xây dựng — hiện kinh phí '
          'còn eo hẹp nên chưa thể triển khai ngay. Khi có bản chính thức, '
          'Flowrite sẽ thông báo tới bạn. Cảm ơn bạn đã quan tâm!'
      : 'The iPhone/iPad app is still being built — funding is currently '
          'tight so it can\'t be released right away. Flowrite will let you '
          'know once the official version is ready. Thank you for your '
          'interest!';

  static String caiDatChoAndroid(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt cho điện thoại, máy tính bảng Android'
      : 'Install for Android phone, tablet';

  static String moTaCaiDatAndroid(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bản APK không bị kẹt bàn phím ảo như bản web, và có thêm Widget '
          '"Ghi nhanh" đặt ngay ở màn hình chính (màn hình chủ) của điện '
          'thoại, máy tính bảng — ghi nhanh một ý mà không cần mở hẳn app.'
      : 'The APK version won\'t get stuck with the on-screen keyboard like '
          'the web version, and also adds a "Quick note" Widget right on '
          'your phone or tablet\'s home screen — jot down an idea without '
          'fully opening the app.';

  static String caiDatChoAndroidNut(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt cho Android' : 'Install for Android';

  static String thongBaoAndroidChuaLenChPlay(NgonNgu nn) => nn == NgonNgu.vi
      ? 'App chưa đưa lên CH Play — hiện chỉ tải file APK trực tiếp. Sau khi '
          'bấm nút dưới đây, máy sẽ tải file APK về; mở file đó lên để cài. '
          'Máy sẽ hỏi quyền "Cài đặt từ nguồn không xác định" — chọn Cho phép, '
          'rồi tiếp tục theo các bước của trình cài đặt gói Android là xong.'
      : 'The app isn\'t on the Play Store yet — the APK file is downloaded '
          'directly instead. After tapping the button below, your device '
          'will download the APK file; open it to install. Your device will '
          'ask for permission to "Install from unknown sources" — choose '
          'Allow, then follow the Android installer\'s steps to finish.';

  static String taiFileApkVeMayVaCaiDat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tải file APK về máy và cài đặt'
      : 'Download the APK file and install it';

  // ---------------------------------------------- Modal nhập ZIP/TXT
  static String cacTepTinVaThuMucChuanBiNhapVaoApp(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Các tệp tin và thư mục chuẩn bị nhập vào app'
      : 'Files and folders ready to import into the app';

  static String tepTxtRiengLe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tệp TXT riêng lẻ' : 'Standalone TXT files';

  static String khongCoTepTxtHopLeNaoTrongTepNenNay(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không có tệp .txt hợp lệ nào trong tệp nén này.'
      : 'No valid .txt files found inside this archive.';

  static String chiHienCacTepTxtGhiChu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chỉ hiện các tệp .txt (tối đa 2 MB mỗi tệp) và thư mục '
          'có chứa .txt bên trong tệp vừa chọn — tệp/thư mục khác '
          'đã được ẩn khỏi kết quả.'
      : 'Only .txt files (up to 2 MB each) and folders containing .txt files '
          'inside the file you just chose are shown — other files/folders '
          'have been hidden from the result.';

  static String coTepTxtNangHonBiBoQua(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Có ít nhất 1 tệp .txt nặng hơn 2 MB đã bị bỏ qua vì '
          'dễ làm app giật/lag khi mở.'
      : 'At least 1 .txt file larger than 2 MB was skipped because it could '
          'make the app stutter/lag when opened.';

  static String thuMucTrong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thư mục trống' : 'Empty folder';

  static String huyKetQuaNayNhapZip(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hủy kết quả này' : 'Discard this result';

  static String chonViTriKhac(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn vị trí khác' : 'Choose another location';

  static String dayVaoThuMucHienTai(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đưa vào thư mục hiện tại' : 'Import into current folder';

  // --------------------------------------- Modal "Khi khởi động App"
  static String khiKhoiDongAppMoTep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Khi khởi động App: Mở tệp...' : 'On app startup: Open file...';

  static String moiKhiVaoLaiAppSeVaoNoiDungTepNao(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mỗi khi vào lại App, thì sẽ vào trong nội dung soạn thảo của '
          'tệp nào?'
      : 'Every time you return to the App, which file\'s content should it '
          'open?';

  static String moTepDangSoanThaoGanDayNhat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Mở tệp đang soạn thảo gần đây nhất' : 'Open the most recently edited file';

  static String moTepTrong(NgonNgu nn) => nn == NgonNgu.vi ? 'Mở tệp trống' : 'Open a blank file';

  static String chonThuMucCuTheChoTepRong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chọn thư mục cụ thể cho tệp rỗng'
      : 'Choose a specific folder for the blank file';

  static String moTepDuocChiDinh(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Mở tệp được chỉ định' : 'Open a specified file';

  static String moTepTenDangSoanThao(NgonNgu nn, String tenTep) => nn == NgonNgu.vi
      ? 'Mở tệp $tenTep đang soạn thảo'
      : 'Open the file $tenTep currently being edited';

  static String chonTepTrongCayThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn tệp trong cây thư mục' : 'Choose a file from the folder tree';

  static String chonTep(NgonNgu nn) => nn == NgonNgu.vi ? 'Chọn tệp' : 'Choose file';

  // -------------------------------------- Modal "Thông tin chi tiết"
  static String viTriLa(NgonNgu nn, String viTri) =>
      nn == NgonNgu.vi ? 'Vị trí: $viTri' : 'Location: $viTri';

  static String tenLa(NgonNgu nn, String ten) =>
      nn == NgonNgu.vi ? 'Tên: $ten' : 'Name: $ten';

  static String kichThuocLa(NgonNgu nn, String kichThuoc) =>
      nn == NgonNgu.vi ? 'Kích thước: $kichThuoc' : 'Size: $kichThuoc';

  static String gomCoThuMucVaTepOTrangDau(NgonNgu nn, int soThuMuc, int soGhiChu) => nn == NgonNgu.vi
      ? 'Gồm có $soThuMuc thư mục và $soGhiChu tệp tin ở trang đầu.'
      : 'Contains $soThuMuc folder${soThuMuc == 1 ? '' : 's'} and $soGhiChu file${soGhiChu == 1 ? '' : 's'} on this page.';

  static String tongTatCaCoThuMucVaTepBenTrong(NgonNgu nn, int soThuMuc, int soGhiChu) => nn == NgonNgu.vi
      ? 'Tổng tất cả có $soThuMuc thư mục và $soGhiChu tệp tin bên trong.'
      : 'In total there are $soThuMuc folder${soThuMuc == 1 ? '' : 's'} and $soGhiChu file${soGhiChu == 1 ? '' : 's'} inside.';

  static String chuSoHuuLa(NgonNgu nn) => nn == NgonNgu.vi ? 'Chủ sở hữu: ' : 'Owner: ';

  // --------------------------------------------- Màn hình "Ghi nhanh" widget
  static String widgetChuaDuocCauHinhDung(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Widget này chưa được cấu hình đúng — hãy xoá widget rồi đặt lại ở màn hình chính.'
      : 'This widget isn\'t configured correctly — please remove it and set it up again on the home screen.';

  static String ghiChuMaWidgetTroToiKhongConNua(NgonNgu nn, String tenGhiChu) => nn == NgonNgu.vi
      ? 'Ghi chú "$tenGhiChu" mà widget này trỏ tới không còn nữa (đã xoá hoặc đang ở '
          'Thùng rác) — hãy xoá widget rồi đặt lại, chọn một ghi chú khác.'
      : 'The note "$tenGhiChu" that this widget points to no longer exists (it was '
          'deleted or is in the Trash) — please remove the widget and set it up '
          'again, choosing a different note.';

  static String khongGhiDuoc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không ghi được' : 'Couldn\'t save';

  static String ghiNhanhVaoTen(NgonNgu nn, String tenGhiChu) =>
      nn == NgonNgu.vi ? 'Ghi nhanh vào "$tenGhiChu"' : 'Quick note into "$tenGhiChu"';

  static String nhapGhiChuRoiBamLuu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Nhập ghi chú rồi bấm Lưu...' : 'Type your note then tap Save...';

  // -------------------------------------- Modal "Nghe bản ghi âm này"
  static String taiFileGhiAmVeMay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tải file ghi âm về máy' : 'Download the recording';

  static String chuyenHoaTheGhiAmNayThanhVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chuyển hoá thẻ ghi âm này thành văn bản' : 'Transcribe this recording card to text';

  // -------------------------------------- Màn "Chọn thư mục/tệp" khi khởi động
  static String canDangNhapGoogleTruoc(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cần đăng nhập Google trước (menu "Tài khoản và Cài đặt" ở trang soạn thảo).'
      : 'You need to sign in with Google first (see the "Account and Settings" menu on the editor screen).';

  static String vuiLongKetNoiInternet(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Vui lòng kết nối internet.' : 'Please connect to the internet.';

  static String khongMoDuocBoNhoDamMay(NgonNgu nn, Object e) => nn == NgonNgu.vi
      ? 'Không mở được Bộ nhớ trên đám mây: $e'
      : 'Could not open Cloud storage: $e';

  static String thuMucMoiTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thư mục mới' : 'New folder';

  static String ghiChuMoiTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ghi chú mới' : 'New note';

  static String chonThuMucTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn thư mục' : 'Choose folder';

  static String giaiThichChonThuMucKhoiDong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mỗi khi khởi động lại App, sẽ vào tệp trống (không có ký tự) trong '
          'thư mục được chọn, nếu không có tệp nào trống thì App sẽ tự động '
          'tạo tệp trống.'
      : 'Every time the app restarts, it opens an empty note (no characters) '
          'inside the chosen folder; if there is no empty note, the app will '
          'automatically create one.';

  static String chonThuMucNayNut(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn thư mục này' : 'Choose this folder';

  static String khongConThuMucConNaoNua(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Trong này không còn thư mục con nào nữa'
      : 'There are no more subfolders in here';

  static String cuonLenDauDanhSach(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cuộn lên đầu danh sách' : 'Scroll to top of list';

  static String cuonXuongCuoiDanhSach(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cuộn xuống cuối danh sách' : 'Scroll to bottom of list';

  static String themGhiChu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thêm ghi chú' : 'Add note';

  static String them(NgonNgu nn) => nn == NgonNgu.vi ? 'Thêm' : 'Add';

  static String nhapTenTepHoacThuMuc(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Nhập tên tệp hoặc thư mục...'
      : 'Enter file or folder name...';

  // ------------------------------------------------------- man_hinh_thu_muc.dart (tiếp)
  static String tenBoNhoNoiBoTrinhDuyet(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bộ nhớ nội bộ trong Trình duyệt web của thiết bị'
      : 'Local storage in this device\'s web browser';

  static String tenBoNhoNoiBoThietBi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bộ nhớ nội bộ trong thiết bị'
      : 'Local storage on this device';

  static String chonNoiLuuTru(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn nơi lưu trữ' : 'Choose a storage location';

  static String ghiChuDangMoNamTrongThuMucVuaChuyenVaoThungRac(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi chú đang mở nằm trong thư mục vừa chuyển vào thùng rác.'
      : 'The note you have open is inside a folder that was just moved to trash.';

  static String ghiChuTen(NgonNgu nn) => nn == NgonNgu.vi ? 'Ghi chú' : 'Note';

  static String ghiChuDangMoVuaChuyenVaoThungRac(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi chú đang mở vừa chuyển vào thùng rác.'
      : 'The note you have open was just moved to trash.';

  static String khongTaoDuocTepNenThuLaiSau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không tạo được tệp nén. Thử lại sau.'
      : 'Could not create the zip file. Try again later.';

  static String khongDocDuocTep(String ten, Object loi, NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không đọc được "$ten": $loi'
      : 'Could not read "$ten": $loi';

  static String tepKhongPhaiZipHopLe(String ten, NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tệp "$ten" không phải .zip hợp lệ, đã bỏ qua.'
      : '"$ten" is not a valid .zip file, skipped.';

  static String khongTheDanODayHayVaoBoNhoTruoc(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không thể dán ở đây — hãy vào một bộ nhớ trước.'
      : 'Cannot paste here — open a storage location first.';

  static String khongTheChuyenVaoChinhNo(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không thể chuyển vào chính nó.' : 'Cannot move into itself.';

  static String khongTheChuyenThuMucVaoChinhConChau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không thể chuyển thư mục vào chính con cháu của nó.'
      : 'Cannot move a folder into its own descendant.';

  static String motMuc(NgonNgu nn) => nn == NgonNgu.vi ? '1 mục' : '1 item';

  static String soMuc(int tong, NgonNgu nn) =>
      nn == NgonNgu.vi ? '$tong mục' : '$tong items';

  static String ghiChuDangMoNamTrongMucVuaChuyenVaoThungRac(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi chú đang mở nằm trong mục vừa chuyển vào thùng rác.'
      : 'The note you have open is inside an item that was just moved to trash.';

  static String damMay(NgonNgu nn) => nn == NgonNgu.vi ? 'Đám mây' : 'Cloud';

  static String noiBo(NgonNgu nn) => nn == NgonNgu.vi ? 'Nội bộ' : 'Local';

  static String giaiThichBoNhoDamMay(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bộ nhớ này lưu trên máy chủ đám mây, có thể truy cập bộ nhớ này '
          'ở bất cứ thiết bị nào nếu có internet và đăng nhập bằng tài '
          'khoản này, App tự động lưu file lên bộ nhớ đám mây khi soạn thảo'
      : 'This storage is kept on the cloud server — you can reach it from '
          'any device with internet access while signed in to this account. '
          'The app automatically saves files to cloud storage while you edit';

  static String giaiThichBoNhoNoiBoWeb(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bộ nhớ nội bộ này lưu tại trình duyệt web này của thiết bị, '
          'riêng tư tuyệt đối, nếu xoá Tệp và dữ liệu trang web thì bộ '
          'nhớ nội bộ này sẽ bị xoá theo. App tự động lưu file mỗi khi '
          'có sự thay đổi mà không cần bấm nút lưu file.'
      : 'This local storage lives in this device\'s web browser only — '
          'completely private, but clearing the site\'s data and files will '
          'erase it too. The app saves files automatically on every change, '
          'no save button needed.';

  static String giaiThichBoNhoNoiBoThietBi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bộ nhớ nội bộ này lưu tại thiết bị, riêng tư và an toàn. App '
          'tự động lưu file mỗi khi có sự thay đổi mà không cần bấm '
          'nút lưu file.'
      : 'This local storage lives on this device — private and safe. The '
          'app saves files automatically on every change, no save button '
          'needed.';

  static String timKiemTrongThuMuc(String ten, NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tìm kiếm trong "$ten"'
      : 'Search inside "$ten"';

  static String nhapKyTuDeTimKiem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Nhập ký tự để tìm kiếm' : 'Type to search';

  static String khongTimThayKetQua(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không tìm thấy kết quả' : 'No results found';

  static String dangXemBanNgoaiTuyen(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang xem bản ngoại tuyến — sẽ đồng bộ khi có mạng.'
      : 'Viewing the offline version — will sync once you\'re back online.';

  static String dangGiuChoDan(String ten, NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang giữ "$ten" — dán vào đây?'
      : 'Holding "$ten" — paste it here?';

  static String dangChoNhapTepNen(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang chờ nhập tệp nén — đưa vào đây?'
      : 'Waiting to import a zip file — drop it here?';

  static String daXoa(NgonNgu nn) => nn == NgonNgu.vi ? 'Đã xoá' : 'Deleted';

  static String moThuMuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Mở thư mục' : 'Open folder';

  static String tatTuDong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tắt tự động' : 'Turn off auto';

  static String batTuDong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bật tự động' : 'Turn on auto';

  static String giayTamNhan(NgonNgu nn, int giayTam) =>
      nn == NgonNgu.vi ? '$giayTam giây' : '$giayTam sec';

  static String tiepTuc(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tiếp tục' : 'Continue';

  static String tamDung(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tạm dừng' : 'Pause';

  static String hienThanhDinhDang(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hiện thanh định dạng' : 'Show formatting bar';

  static String anThanhDinhDang(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ẩn thanh định dạng' : 'Hide formatting bar';

  static String dongBoPhimNhanhChoManHinhCamUng(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đóng bộ phím nhanh cho màn hình cảm ứng'
      : 'Close quick touch keyboard';

  static String phimNhanhChoManHinhCamUng(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Phím nhanh cho màn hình cảm ứng'
      : 'Quick touch keyboard';

  static String phimNhanhNhanGon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Phím nhanh' : 'Quick keys';

  static String quayLaiKetQuaAi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Quay lại kết quả AI' : 'Back to AI result';

  static String chuyenToiDay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chuyển tới đây' : 'Move here';

  static String chenVaoViTriNay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chèn vào vị trí này' : 'Insert at this position';

  // ------------------------------------------------- Khối văn bản dài nối nhiều dòng
  // (phát hiện khi người dùng báo còn sót nhiều chuỗi tiếng Việt sau khi đã
  // "rà sạch" theo các script quét trước — nguyên nhân: chuỗi literal Dart
  // nối nhiều dòng liền kề `'...' 'dòng 2'` không khớp regex quét 1 dòng.)

  static String giaiThichTuDongChuyenHoaTheGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi bật, mỗi thẻ ghi âm tích đủ số giây bên dưới sẽ tự động được '
          'gửi đi chuyển thành văn bản, không cần bạn tự bấm. Tắt đi thì mọi '
          'thẻ đều chờ bạn tự bấm chuyển hoá.'
      : 'When on, each recording card that reaches the number of seconds '
          'below is automatically sent to be converted to text — no need to '
          'tap yourself. When off, every card waits for you to tap convert.';

  static String giaiThichTuMoBangDieuKhien(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mỗi lần bấm nút ghi âm (hoặc dùng phím tắt) để bắt đầu ghi âm một '
          'thẻ mới, chọn xem Bảng điều khiển này có tự mở ra ngay không, hay '
          'chỉ hiện dải thanh công cụ ghim ở đầu màn hình.'
      : 'Each time you tap the record button (or use the shortcut) to start '
          'recording a new card, choose whether this control panel opens '
          'right away, or only the pinned toolbar strip shows at the top of '
          'the screen.';

  static String sapChamGioiHanTieuDePrefix(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Sắp chạm giới hạn ' : 'Approaching the limit ';

  static String theGhiAmSoDangSapGhiDu60Giay(int? soThe, int soLan, NgonNgu nn) =>
      nn == NgonNgu.vi
          ? 'Thẻ ghi âm #$soThe (thẻ tự động thứ $soLan liên tiếp) sắp ghi đủ '
              '60 giây, tổng cộng sắp chạm '
          : 'Recording card #$soThe (the $soLan-th automatic card in a row) '
              'is about to reach 60 seconds, bringing the total close to ';

  static String khongAiBamGi(NgonNgu nn) =>
      nn == NgonNgu.vi ? ' không ai bấm gì. ' : ' with no one tapping anything. ';

  static String neuKhongChonTuNgungGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Nếu không chọn, tới đúng giây thứ 60 hệ thống sẽ TỰ NGỪNG ghi âm '
          'luôn, KHÔNG tạo thêm thẻ mới nữa'
      : "If you don't choose, right at second 60 the system will "
          'AUTOMATICALLY STOP recording, WITHOUT creating a new card';

  static String deTranhTonTokenVaPinBanMuonLamGi(NgonNgu nn) => nn == NgonNgu.vi
      ? ' (để tránh tốn token AI và pin máy vô ích). Bạn muốn làm gì bây giờ?'
      : ' (to avoid wasting AI tokens and battery). What would you like to '
          'do now?';

  static String theGhiAmSoSapGhiDu60Giay(int? soThe, NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thẻ ghi âm #$soThe sắp ghi đủ 60 giây. '
      : 'Recording card #$soThe is about to reach 60 seconds. ';

  static String banCoTheKhongCanLamGiBayGio(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bạn có thể không cần làm gì bây giờ cả'
      : "You don't need to do anything right now";

  static String toiDungGiay60TuDongChot(NgonNgu nn) => nn == NgonNgu.vi
      ? ' — tới đúng giây thứ 60 nó sẽ tự động chốt và ghi tiếp bằng một thẻ '
          'mới. Bạn muốn làm gì bây giờ?'
      : ' — right at second 60 it will automatically finalize and continue '
          'recording with a new card. What would you like to do now?';

  static String banGhiAmDangDoDangDaGhiDuoc(String thoiLuong, NgonNgu nn) =>
      nn == NgonNgu.vi
          ? 'Bản ghi âm đang dở dang này đã ghi được $thoiLuong. Xoá đi sẽ '
              'mất VĨNH VIỄN, không thể phục hồi lại được (khác với thẻ ghi '
              'âm đã chốt — không lưu tạm bất cứ gì để hoàn tác). Bạn có '
              'chắc chắn muốn xoá không?'
          : 'This in-progress recording has recorded $thoiLuong. Deleting it '
              'will be lost PERMANENTLY and cannot be recovered (unlike a '
              'finalized recording card — nothing is kept to undo). Are you '
              'sure you want to delete it?';

  static String theDaChuyenHoaRoiKhongConBanGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cái thẻ này đã được chuyển hoá rồi nên không còn bản ghi âm nào '
          'nữa. Bạn chỉ có thể bấm nút Chuyển hoá thì có thể xem toàn bộ văn '
          'bản.'
      : 'This card has already been converted, so there is no recording '
          'left. You can only tap the Convert button to see the full text.';

  static String vungChonChuaNhieuTheXoaSeHuyLuon(int soLuongThe, NgonNgu nn) =>
      nn == NgonNgu.vi
          ? 'Vùng chọn này chứa $soLuongThe thẻ ghi âm — xoá sẽ HUỶ LUÔN '
              'những thẻ đó, không thể phục hồi lại được. Bạn có chắc chắn '
              'muốn xoá không?'
          : 'This selection contains $soLuongThe recording cards — deleting '
              'will CANCEL those cards for good, they cannot be recovered. '
              'Are you sure you want to delete them?';

  static String theDangGhiAmXoaSeHuyLuonBanGhiDangThu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thẻ này ĐANG GHI ÂM — xoá sẽ HUỶ LUÔN bản ghi đang thu, không thể '
          'phục hồi lại được. Bạn có chắc chắn muốn xoá không?'
      : 'This card is CURRENTLY RECORDING — deleting will CANCEL the '
          'in-progress recording for good, it cannot be recovered. Are you '
          'sure you want to delete it?';

  static String theDangGuiPhienAmXoaSeBoLuonKetQua(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thẻ này ĐANG được gửi đi phiên âm — xoá sẽ bỏ luôn kết quả sắp về, '
          'không thể phục hồi lại được. Bạn có chắc chắn muốn xoá không?'
      : 'This card is CURRENTLY being transcribed — deleting will discard '
          'the incoming result for good, it cannot be recovered. Are you '
          'sure you want to delete it?';

  static String theGhiAmSeBiXoaVinhVienChung(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thẻ ghi âm này sẽ bị xoá VĨNH VIỄN, không thể phục hồi lại được. '
          'Bạn có chắc chắn muốn xoá không?'
      : 'This recording card will be deleted PERMANENTLY, it cannot be '
          'recovered. Are you sure you want to delete it?';

  static String microIphoneKhongKhaDungTrenWebsite(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Micro (vừa nói vừa ra chữ) tại điện thoại Iphone không thể khả '
          'dụng trên môi trường Website, chỉ khả dụng trên môi trường app '
          'mobile. Nếu bạn cho rằng thiết bị của bạn không phải Iphone, hãy '
          'bấm vào Cài đặt Micro. Bạn có thể tải app mobile cho Iphone để '
          'sử dụng tính năng này.'
      : 'The microphone (speak while typing) on an iPhone browser cannot '
          'work on the Website — it only works in the mobile app. If you '
          "believe your device isn't an iPhone, tap Microphone Settings. "
          'You can download the mobile app for iPhone to use this feature.';

  static String hauToODoanDangChon(NgonNgu nn) =>
      nn == NgonNgu.vi ? ' ở đoạn đang chọn' : ' in the selected paragraph';

  static String hauToToanVan(NgonNgu nn) =>
      nn == NgonNgu.vi ? ' toàn văn' : ' in the whole text';

  static String moTaDangXuLyKiemTra(String? loaiKiemTra, String hauTo, NgonNgu nn) {
    if (nn == NgonNgu.vi) {
      return switch (loaiKiemTra) {
        'chinh_ta' =>
          'AI đang kiểm tra lỗi chính tả$hauTo, tìm từ/cụm từ sai để đề xuất sửa.',
        'dau_cau' =>
          'AI đang kiểm tra dấu câu$hauTo, tìm chỗ còn thiếu để đề xuất chèn thêm.',
        _ =>
          'AI đang kiểm tra lại$hauTo để soát lỗi chính tả - ngữ pháp, và đề '
              'xuất cách sửa đổi. Đây là bước quan trọng trước khi hoàn '
              'thiện văn bản.',
      };
    }
    return switch (loaiKiemTra) {
      'chinh_ta' =>
        'AI is checking spelling$hauTo, looking for misspelled words/phrases to suggest fixes.',
      'dau_cau' =>
        'AI is checking punctuation$hauTo, looking for missing marks to suggest adding.',
      _ =>
        'AI is reviewing$hauTo for spelling and grammar issues, and '
            'suggesting edits. This is an important step before finishing '
            'the document.',
    };
  }

  static String diChuyenConTroToiViTriDatThe(int soThe, NgonNgu nn) => nn == NgonNgu.vi
      ? 'Di chuyển con trỏ tới vị trí muốn đặt thẻ ghi âm #$soThe này, rồi '
          'bấm "Chuyển tới đây".'
      : 'Move the cursor to where you want to place recording card #$soThe, '
          'then tap "Move here".';

  static String diChuyenConTroToiViTriChenVanBanAi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Di chuyển con trỏ tới vị trí muốn chèn văn bản từ AI, rồi bấm '
          '"Chèn vào vị trí này". Có vùng đang chọn thì văn bản mới sẽ thay '
          'thế đúng vùng đó.'
      : 'Move the cursor to where you want to insert the text from AI, then '
          'tap "Insert at this position". If text is selected, the new text '
          'will replace exactly that selection.';

  static String ghiChuBoNhoTamDan1(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Dán: bấm vào một dòng, hoặc gõ đúng phím số của dòng đó (bàn '
          'phím rời, 1-9 rồi 0) để dán ngay vào vị trí con trỏ.'
      : '• Paste: tap a row, or type the row\'s exact number key (external '
          'keyboard, 1-9 then 0) to paste right at the cursor.';

  static String ghiChuBoNhoTamDan2(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Tự ghi: mỗi lần Cắt/Copy, đoạn văn bản tự thêm vào dòng trống '
          'đầu tiên; hết dòng trống thì đè lên dòng CŨ NHẤT trong các dòng '
          'chưa ghim.'
      : '• Auto-record: every time you Cut/Copy, the text is added to the '
          'first empty row; once no empty row is left, it overwrites the '
          'OLDEST row among the unpinned ones.';

  static String ghiChuBoNhoTamDan3(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Màu nền đỏ nhạt = dòng cũ nhất, vàng nhạt = dòng gần cũ nhất '
          'trong các dòng CHƯA ghim — đây là 2 dòng sắp bị đè tiếp theo, '
          'chỉ hiện khi lịch sử đã đủ 10 dòng.'
      : '• Light red background = the oldest row, light yellow = the '
          'second-oldest among the UNPINNED rows — these are the next 2 rows '
          'about to be overwritten, shown only once the history has 10 rows.';

  static String ghiChuBoNhoTamDan4(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Ghim (nút 📌): dòng đã ghim (nền xanh lá) không bao giờ bị đè, '
          'và không tính vào việc xác định dòng cũ/gần cũ nhất. Bấm lại để '
          'bỏ ghim. Ghim đủ cả 10 dòng thì lịch sử tạm hết chỗ ghi thêm — '
          'vẫn bình thường, Dán bằng Ctrl+V/nút Dán không hề bị ảnh hưởng.'
      : '• Pin (📌 button): a pinned row (green background) is never '
          "overwritten, and doesn't count toward determining the "
          'oldest/second-oldest row. Tap again to unpin. Pinning all 10 rows '
          "means the history temporarily has no room left to record — "
          "that's normal, Paste via Ctrl+V/the Paste button is unaffected.";

  static String ghiChuBoNhoTamDan5(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Đoạn nào dài hơn 10.000 ký tự sẽ KHÔNG được ghi vào bảng này '
          '(âm thầm, không báo) — tránh bộ nhớ tạm quá nặng. Cắt/Copy vẫn '
          'thành công như thường vào bộ nhớ đệm của máy.'
      : "• Text longer than 10,000 characters will NOT be recorded in this "
          "table (silently, no notice) — to avoid an overly heavy history. "
          "Cut/Copy still succeeds as usual into the device's clipboard.";

  static String tuDienNayLuuTaiBoNhoLauDaiCuaApp(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Từ điển này được lưu tại bộ nhớ lâu dài của app'
      : "This dictionary is saved in the app's long-term storage";

  static String ghiChuTuDienNhapLieu1(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Dán nhanh: bấm vào một dòng (hoặc gõ đúng phím chữ cái của dòng '
          'đó trên bàn phím vật lý) để dán ngay vào vị trí con trỏ trong '
          'khung soạn thảo. Dòng trống thì không bấm/gõ được gì.'
      : '• Quick paste: tap a row (or type its exact letter key on a '
          'physical keyboard) to paste right at the cursor in the editor. '
          'An empty row does nothing when tapped/typed.';

  static String ghiChuTuDienNhapLieu2(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Ẩn/hiện bảng này: bấm nút 📖 ở thanh công cụ, hoặc dùng phím tắt '
          'đã chọn (xem/đổi ở mục "Phím tắt" trong Cài đặt) — mặc định là '
          'bấm Alt 2 lần liên tiếp.'
      : '• Show/hide this panel: tap the 📖 button on the toolbar, or use '
          'the chosen shortcut (view/change it under "Shortcuts" in '
          'Settings) — default is pressing Alt twice in a row.';

  static String ghiChuTuDienNhapLieu3(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Ba tab: "Gần đây", "Q→M" (theo hàng phím vật lý) và "A→Z" (bảng '
          'chữ cái). Đổi tab bằng cách bấm chuột vào tab, hoặc bấm phím '
          '1/2/3, hoặc phím mũi tên trái/phải — app tự nhớ tab đang mở cho '
          'lần sau.'
      : '• Three tabs: "Recent", "Q→M" (by physical keyboard row) and "A→Z" '
          '(alphabetical). Switch tabs by clicking a tab, pressing 1/2/3, or '
          'the left/right arrow keys — the app remembers the open tab for '
          'next time.';

  static String ghiChuTuDienNhapLieu4(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Cuộn xem hết 26 dòng trong một tab: vuốt tay, lăn chuột, kéo '
          'thanh cuộn, hoặc phím mũi tên lên/xuống để nhảy thẳng lên '
          'đầu/xuống cuối. Phím cách cuộn xen kẽ: đang ở đâu đó thì cuộn '
          'xuống cuối, đã ở cuối rồi thì cuộn lên đầu.'
      : '• Scroll through all 26 rows in a tab: swipe, scroll the wheel, '
          'drag the scrollbar, or use the up/down arrow keys to jump '
          'straight to the top/bottom. The spacebar toggles: from anywhere '
          'it scrolls to the bottom, from the bottom it scrolls to the top.';

  static String ghiChuTuDienNhapLieu5(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Soạn nội dung cho từng dòng: bấm "Cài đặt" (ngay bên cạnh nút '
          'Hướng dẫn này) để gõ tay hoặc dán văn bản (giữ cả định dạng '
          'đậm/nghiêng/màu...) vào từng ô, đổi thứ tự giữa các dòng, hoặc '
          'đổi phím tắt ẩn/hiện bảng.'
      : '• Edit the content of each row: tap "Settings" (right next to this '
          'Guide button) to type or paste text (keeping '
          'bold/italic/color... formatting) into each box, reorder the '
          'rows, or change the show/hide shortcut.';

  static String ghiChuTuDienNhapLieu6(NgonNgu nn) => nn == NgonNgu.vi
      ? '• Hai cách đưa thẳng một đoạn có sẵn vào từ điển, không cần gõ '
          'lại: (1) bôi đen một đoạn trong khung soạn thảo rồi bấm nút 📖 '
          'vừa hiện ra cạnh nút Xoá; (2) mở bảng "Bộ nhớ tạm để dán văn '
          'bản", bấm nút 📖 ở dòng lịch sử muốn đưa vào. Cả hai cùng mở một '
          'modal cho chọn dòng (trống hay đã có chữ đều được, có cảnh báo '
          'trước khi thay nội dung cũ) và giữ nguyên định dạng nếu đoạn gốc '
          'có.'
      : '• Two ways to send an existing passage straight into the '
          "dictionary without retyping: (1) select a passage in the editor "
          'then tap the 📖 button that appears next to the Delete button; '
          '(2) open the "Clipboard history" panel, tap the 📖 button on the '
          'row you want to send. Both open a modal to pick a row (empty or '
          'already filled, with a warning before replacing old content) and '
          'keep the original formatting if the source had any.';

  static String chuThichTabGanDayTuDien(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Các dòng vừa được sử dụng gần đây, trong đó: Các màu xanh đậm là '
          'gần đây nhất, các màu xanh nhạt là cũ hơn'
      : 'Rows recently used, where: darker blue shades are the most recent, '
          'lighter blue shades are older';

  static String chuThichTabHangTuDien(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Sắp xếp theo các hàng nút chữ cái trên bàn phím vật lý, từ trái '
          'qua phải, từ trên xuống dưới, Phím nào có gạch chân là ở bên phải'
      : 'Sorted by the letter-key rows on a physical keyboard, left to '
          'right, top to bottom — an underlined key is on the right side';

  static String chuThichTabAZTuDien(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Các phím tắt chữ cái Sắp xếp theo Bảng chữ cái Alphabet quốc tế '
          'từ A đến Z'
      : 'Letter shortcuts sorted by the international alphabet, from A to Z';

  static String dongPhimKyTuDaCoNoiDungSeMat(String chuCai, NgonNgu nn) =>
      nn == NgonNgu.vi
          ? 'Dòng Phím $chuCai này đã có nội dung — nội dung cũ sẽ bị mất, '
              'thay bằng đoạn vừa chọn. Bạn có chắc chắn không?'
          : 'Row $chuCai already has content — the old content will be '
              'lost, replaced by what you just selected. Are you sure?';

  static String banCoTheGhiCauLenhRiengChoCachVietLai(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bạn có thể ghi câu lệnh riêng cho cách viết lại, hoặc để trống để '
          'AI tự do viết lại theo ý nó.'
      : 'You can write your own instruction for how to rewrite, or leave it '
          'blank to let AI rewrite freely.';

  static String vanBanAiVuaPhienAmSeMatNeuHuy(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Văn bản AI vừa phiên âm (kể cả phần bạn đã sửa, nếu có) sẽ mất '
          'hẳn, không thể lấy lại. Bạn có chắc chắn muốn huỷ không?'
      : "The text AI just transcribed (including any edits you've made) "
          'will be lost for good and cannot be recovered. Are you sure you '
          'want to cancel?';

  static String dinhDangChuTrenChiApDungChoSoVaChuThuong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Định dạng chữ trên (superscript) chỉ áp dụng cho con số và chữ '
          'cái (chữ thường) trong bảng chữ cái Quốc tế.'
      : 'Superscript formatting only applies to numbers and lowercase '
          'letters in the international alphabet.';

  static String giaiThichThungRacGiuToiDa30Ngay(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mỗi mục chỉ được giữ tối đa 30 ngày trong thùng rác, quá hạn sẽ tự '
          'xoá vĩnh viễn. Không thể xem nội dung bên trong — chỉ có thể '
          'khôi phục hoặc xoá vĩnh viễn.'
      : "Each item is kept for at most 30 days in the trash — once it "
          "expires it's permanently deleted. You cannot view the content "
          'inside — you can only restore it or delete it permanently.';

  // ------------------------------------- Nhãn/tooltip còn sót ở thanh công cụ
  // (phát hiện khi dò qua chu:/label:/message:/tooltip: nhiều dòng — regex
  // quét 1 dòng trước đây không bắt được các ternary/field nhiều dòng này)

  static String xemThemLuaChon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xem thêm lựa chọn' : 'See more options';

  static String taiKhoanVaCaiDat(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tài khoản và Cài đặt' : 'Account and Settings';

  static String taoVungChonVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tạo vùng chọn văn bản' : 'Create a text selection';

  static String tatMicro(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tắt micro' : 'Turn off microphone';

  static String batMicro(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bật micro' : 'Turn on microphone';

  static String tatBatMicroVoiPhimTat(bool bat, String phimTat, NgonNgu nn) =>
      nn == NgonNgu.vi
          ? '${bat ? 'Tắt' : 'Bật'} micro ($phimTat)'
          : '${bat ? 'Turn off' : 'Turn on'} microphone ($phimTat)';

  static String hienChuThichNut(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hiện chú thích' : 'Show label';


  static String xoaTuKhoa(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Xoá từ khoá' : 'Clear search';

  static String tuDienNhapLieuNhanhVoiPhimTat(String phimTat, NgonNgu nn) =>
      nn == NgonNgu.vi
          ? 'Từ điển nhập liệu nhanh ($phimTat)'
          : 'Quick dictionary ($phimTat)';

  static String boGhimThanhCongCuDinhDang(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bỏ ghim thanh công cụ định dạng' : 'Unpin formatting toolbar';

  static String ghimThanhCongCuDinhDang(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ghim thanh công cụ định dạng' : 'Pin formatting toolbar';

  static String tatBanPhimAo(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tắt bàn phím ảo' : 'Turn off on-screen keyboard';

  static String hienBanPhimAoCungBoPhimNhanh(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hiện bàn phím ảo cùng Bộ phím nhanh'
      : 'Show on-screen keyboard with Quick keys';

  static String boGhimChoPhepLichSuMoiDeLenLai(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bỏ ghim (cho phép lịch sử mới đè lên lại)'
      : 'Unpin (allow new history to overwrite again)';

  static String ghimDongNayKhongBaoGioBiThayThe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghim dòng này (không bao giờ bị thay thế)'
      : 'Pin this row (never overwritten)';

  static String dangGhiAmPrefixLabel(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đang Ghi âm ' : 'Recording ';

  static String chuyenHinhAnhThanhVanBanMenu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chuyển hình ảnh thành văn bản' : 'Convert image to text';

  static String chupAnhCamera(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chụp ảnh (camera)' : 'Take a photo (camera)';

  static String chuyenFileAmThanhThanhVanBanMenu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chuyển file âm thanh thành văn bản'
      : 'Convert audio file to text';

  static String lamViecVoiDoanVanDangChon(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Làm việc với Đoạn văn đang chọn' : 'Work with the Selected Paragraph';

  static String lamViecVoiToanBoVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Làm việc với Toàn bộ văn bản' : 'Work with the Whole Text';

  static String caiDatNutKiemTraToanVan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt nút "Kiểm tra toàn văn"'
      : 'Settings for the "Full-text check" button';

  static String caiDatMicroMenu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt Micro' : 'Microphone settings';

  static String caiDatHienThiVaTuDongSuaMenu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt Hiển thị và tự động sửa' : 'Display and auto-correct settings';

  static String caiDatTuDienSuaLoiChinhTaMenu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt từ điển sửa lỗi chính tả' : 'Spell-check dictionary settings';

  static String caiDatTuDienNhapLieuNhanhMenu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt Từ điển nhập liệu nhanh' : 'Quick dictionary settings';

  static String caiDatBoNhoTamDeDanVanBanMenu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt Bộ nhớ tạm để dán văn bản'
      : 'Clipboard history settings';

  static String banCoChacChanXoaCacKyTu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bạn có chắc chắn xoá các ký tự ' : 'Are you sure you want to delete the characters ';

  static String banCoChacChanThayDoiCacKyTu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bạn có chắc chắn thay đổi các ký tự '
      : 'Are you sure you want to change the characters ';

  static String thanh(NgonNgu nn) => nn == NgonNgu.vi ? ' thành ' : ' to ';

  static String oKetQuaTimKiemKhong(NgonNgu nn) =>
      nn == NgonNgu.vi ? ' ở ' : ' in ';

  static String ketQuaTimKiemKhongHoi(NgonNgu nn) =>
      nn == NgonNgu.vi ? ' kết quả tìm kiếm không?' : ' search results?';

  static String soTuDong(int soTu, NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Số từ: $soTu' : 'Words: $soTu';

  static String kyTuCoDauCachDong(int so, NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ký tự (có dấu cách): $so'
      : 'Characters (with spaces): $so';

  static String kyTuKhongDauCachDong(int so, NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ký tự (không dấu cách): $so'
      : 'Characters (no spaces): $so';

  static String soDoanDong(int so, NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Số đoạn: $so' : 'Paragraphs: $so';

  static String themNhanhVaoDongTrongGanNhat(String? phim, NgonNgu nn) {
    if (nn == NgonNgu.vi) {
      return phim == null
          ? 'Thêm nhanh vào Dòng trống gần nhất'
          : 'Thêm nhanh vào Dòng trống gần nhất (Phím $phim)';
    }
    return phim == null
        ? 'Quick-add to the nearest empty row'
        : 'Quick-add to the nearest empty row (Key $phim)';
  }

  // ------------------------------------------- Chữ gợi ý khi bài còn trống
  static String goiYTrongDongGoChu(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Gõ chữ và bấm Micro để nói...' : 'Type and tap Mic to speak...';

  static String goiYTrongDongSongSong(NgonNgu nn) =>
      nn == NgonNgu.vi
          ? 'Thực hiện song song hai việc trên cùng lúc.'
          : 'Do both at the same time.';

  static String goiYTrongDongHuongDan(bool ratHep, NgonNgu nn) {
    if (nn == NgonNgu.vi) {
      return ratHep
          ? 'Vui lòng đọc hướng dẫn và mẹo sử dụng App (nút '
          : 'Vui lòng đọc hướng dẫn và mẹo sử dụng App (Nút ';
    }
    return ratHep
        ? 'Please read the guide and tips for using the App (the '
        : 'Please read the guide and tips for using the App (the ';
  }

  static String goiYTrongDongMicroTrucTrac(NgonNgu nn) => nn == NgonNgu.vi
      ? '\nNếu Micro trục trặc, hãy vào Cài đặt Micro\n'
      : '\nIf the Mic has issues, go to Mic Settings\n';

  static String goiYTrongDongDangDungBoMicro(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đang sử dụng bộ Micro của Thiết bị '
      : "Currently using the device's Mic set ";

  static String goiYTrongDongPhienBanWeb(String phienBan, NgonNgu nn) =>
      nn == NgonNgu.vi
          ? '\n@Flowrite web (phiên bản $phienBan)\n'
          : '\n@Flowrite web (version $phienBan)\n';

  static String goiYTrongDongDungChrome(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Truy cập Web bằng trình duyệt Chrome để sử dụng tốt nhất!'
      : 'For the best experience, access the Web via Chrome!';

  static String goiYTrongDongTuDongLuu(NgonNgu nn) => nn == NgonNgu.vi
      ? '\nApp luôn tự động lưu nội dung soạn thảo'
      : '\nThe App always auto-saves your writing';
}

// CÒN TỒN ĐỌNG (chưa bọc đa ngôn ngữ, để nguyên tiếng Việt — việc cho lượt
// sau): nội dung đầy đủ modal "Hướng dẫn sử dụng"/"Điều khoản sử dụng"/"Bảo
// mật và quyền riêng tư", mọi snackbar/dialog xác nhận trong
// `trang_soan_thao.dart` và `man_hinh_thu_muc.dart`, màn hình trò chuyện AI,
// màn Cài đặt (nội dung chi tiết từng tuỳ chọn), modal hạn mức AI/cảnh báo
// hạn mức AI, các modal ít dùng (từ điển, phím tắt, donate...). Màn Admin ưu
// tiên thấp nhất — chỉ admin thấy.
