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

  // ------------------------------------------------- Cây thư mục (lượt dịch tiếp)
  static String luu(NgonNgu nn) => nn == NgonNgu.vi ? 'Lưu' : 'Save';

  static String tat(NgonNgu nn) => nn == NgonNgu.vi ? 'Tắt' : 'Turn off';

  static String dan(NgonNgu nn) => nn == NgonNgu.vi ? 'Dán' : 'Paste';

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
}

// CÒN TỒN ĐỌNG (chưa bọc đa ngôn ngữ, để nguyên tiếng Việt — việc cho lượt
// sau): nội dung đầy đủ modal "Hướng dẫn sử dụng"/"Điều khoản sử dụng"/"Bảo
// mật và quyền riêng tư", mọi snackbar/dialog xác nhận trong
// `trang_soan_thao.dart` và `man_hinh_thu_muc.dart`, màn hình trò chuyện AI,
// màn Cài đặt (nội dung chi tiết từng tuỳ chọn), modal hạn mức AI/cảnh báo
// hạn mức AI, các modal ít dùng (từ điển, phím tắt, donate...). Màn Admin ưu
// tiên thấp nhất — chỉ admin thấy.
