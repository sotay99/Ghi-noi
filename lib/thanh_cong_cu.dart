// Thanh ngang dưới màn hình soạn thảo: bên trái là hướng dẫn, cài đặt, làm
// việc với AI, bàn phím, thư mục; bên phải là sóng âm rồi micro sát mép phải
// màn hình. Tự nằm khít mép trên bàn phím ảo — việc đó do trang gọi widget
// này lo, ở đây chỉ vẽ giao diện.

import 'dart:async';

import 'package:flutter/material.dart';

import 'quyen_admin.dart';
import 'vong_song_am.dart';

class ThanhCongCu extends StatelessWidget {
  const ThanhCongCu({
    super.key,
    required this.bat,
    required this.dangNghe,
    required this.songAm,
    required this.sanSang,
    this.biKhoaThietBi = false,
    required this.neThanhDieuHuong,
    required this.nhanPhimTat,
    required this.khiBamMicro,
    required this.khiBamCaiDatMicro,
    required this.khiBamCaiDatHienThi,
    required this.khiBamTuDienChinhTa,
    required this.khiBamTuDienNhapLieuNhanh,
    required this.khiBamBoNhoTam,
    required this.khiBamHuongDan,
    required this.khiBamCaiDatKiemTraToanVan,
    required this.khiBamChuyenFileAmThanh,
    required this.khiBamChuyenAnhThanhVanBan,
    required this.khiBamChupAnh,
    required this.khiBamTomTatToanVan,
    required this.khiBamMoRongToanVan,
    required this.khiBamVietLaiToanVan,
    required this.khiBamTroChuyenVeVanBan,
    required this.layDoanVanDangChon,
    required this.coVungChonThatSu,
    required this.epToanVanKhiCoVungChon,
    required this.khiBamDoiCheDoLamViec,
    required this.khoaMenuAI,
    required this.khiBamBanPhim,
    required this.khiBamBoPhimNhanh,
    required this.boPhimNhanhDangMo,
    this.noiBatBoPhimNhanh = false,
    required this.khiBamKiemTraToanVan,
    required this.khiBamKiemTraChinhTaToanVan,
    required this.khiBamKiemTraDauCauToanVan,
    required this.dangGhiAmThe,
    required this.khiBamGhiAmThe,
    required this.khiBamChonTatCa,
    this.dangChonTatCa = false,
    this.gopMicVaGhiAmThanhMotNut = false,
    required this.hienChuThich,
    required this.khiBamChuThich,
    required this.khiBamChepTatCa,
    required this.khiBamChepRoiXoaTatCa,
    required this.khiBamXoaTatCa,
    required this.khiBamChonTatCaTrongMenuThem,
    required this.khiBamDanhSachPhimTat,
    required this.khiBamTimKiem,
    required this.khiBamTroChuyen,
    this.thayNutBangCopyCutPaste = false,
    this.hangCopyCutPaste,
    required this.khiMoMenuCanReset,
    required this.khiDongMenuAI,
    required this.khiBamDangNhapGoogle,
    required this.khiBamKhoiDongTep,
    required this.khiBamDieuKhoan,
    required this.khiBamBaoMat,
    required this.khiBamLuyenGoPhim,
    required this.khiBamCaiDatUngDung,
    required this.khiBamGopY,
    required this.khiBamQuanLyGopY,
    required this.khiBamDanhSachUser,
    this.tenHienThiDaDangNhap,
    this.emailDaDangNhap,
    this.urlAnhDaiDienDaDangNhap,
  });

  /// (SỬA LỖI — vùng chọn văn bản "biến mất" khi mở menu "Làm việc với AI")
  /// Xem chú thích đầy đủ ở `_NutAIMenu.khiDongMenu` — truyền thẳng xuống.
  final VoidCallback khiDongMenuAI;

  /// (YÊU CẦU MỚI) Đăng nhập/đăng xuất Google — xem chú thích đầy đủ ở
  /// `_NutTaiKhoanMenu`, truyền thẳng xuống.
  final VoidCallback khiBamDangNhapGoogle;

  /// (YÊU CẦU MỚI) Mục "Khi khởi động App: Mở tệp..." — truyền thẳng xuống
  /// `_NutTaiKhoanMenu`.
  final VoidCallback khiBamKhoiDongTep;

  /// (YÊU CẦU MỚI) Mục "Điều khoản sử dụng" — truyền thẳng xuống `_NutTaiKhoanMenu`.
  final VoidCallback khiBamDieuKhoan;

  /// (YÊU CẦU MỚI) Mục "Bảo mật và quyền riêng tư" — truyền thẳng xuống `_NutTaiKhoanMenu`.
  final VoidCallback khiBamBaoMat;

  /// (YÊU CẦU MỚI) Mục "Luyện gõ phím bằng 10 ngón tay" — truyền thẳng xuống `_NutThemMenu`.
  final VoidCallback khiBamLuyenGoPhim;

  /// (YÊU CẦU MỚI) Mục "Cài đặt Ứng dụng vào Thiết bị" — truyền thẳng xuống `_NutThemMenu`.
  final VoidCallback khiBamCaiDatUngDung;

  /// (YÊU CẦU MỚI) Mục "Góp ý thêm, báo lỗi về ứng dụng" — truyền thẳng xuống `_NutThemMenu`.
  final VoidCallback khiBamGopY;

  /// (YÊU CẦU MỚI — chỉ admin) Mục "Các ý kiến góp ý, báo lỗi của user" —
  /// truyền thẳng xuống `_NutTaiKhoanMenu`.
  final VoidCallback khiBamQuanLyGopY;

  /// (YÊU CẦU MỚI — chỉ admin) Mục "Các User đã đăng nhập" — truyền thẳng
  /// xuống `_NutTaiKhoanMenu`.
  final VoidCallback khiBamDanhSachUser;

  final String? tenHienThiDaDangNhap;
  final String? emailDaDangNhap;
  final String? urlAnhDaiDienDaDangNhap;

  /// (YÊU CẦU MỚI) Gọi NGAY khi một trong ba menu thả xuống (Làm việc với
  /// AI/Thêm lựa chọn/Tài khoản và Cài đặt) vừa mở — ép màn hình đo lại và
  /// ngăn bàn phím ảo tự bật lên, một trong các nỗ lực chống lỗi "bãi đất
  /// trống", xem `_resetManHinhTruocKhiMoMenu` ở `trang_soan_thao.dart`.
  final VoidCallback khiMoMenuCanReset;

  /// Có vùng chọn thật — tạm thay 4 nút Hướng dẫn/Thêm/Tài khoản-Cài đặt/
  /// Phím nhanh bằng [hangCopyCutPaste], xem chú thích tại `build`. Không
  /// còn phụ thuộc Thu gọn/Mở rộng thanh công cụ phía trên hay Bộ phím
  /// nhanh đang mở/đóng.
  final bool thayNutBangCopyCutPaste;

  /// Hàng 2 nút Copy/Cắt — do `trang_soan_thao.dart` dựng sẵn
  /// (`_hangCopyCutPaste()`) rồi đưa vào đây, chỉ có ý nghĩa khi
  /// [thayNutBangCopyCutPaste] là `true`.
  final Widget? hangCopyCutPaste;

  final bool bat;
  final bool dangNghe;
  final List<double> songAm;
  final bool sanSang;

  /// Thiết bị này KHÔNG dùng được micro (iPhone bản web) — nút vẫn hiện ra
  /// y hệt mọi thiết bị khác (không còn gộp chung với Ghi âm), chỉ đổi màu
  /// (xám, không xanh) và luôn bấm được (để hiện cảnh báo, xem
  /// `khiBamMicro`/`_hienCanhBaoMicIphone`).
  final bool biKhoaThietBi;
  final bool neThanhDieuHuong;

  /// Đang hiện dòng chữ chú thích dọc phía trên từng nút hay không.
  final bool hienChuThich;
  final VoidCallback khiBamChuThich;

  /// Nhãn phím tắt hiện đang cài, ví dụ "Ctrl + F" — hiện lên khi rê chuột
  /// vào nút micro (chỉ có ý nghĩa với thiết bị có chuột/con trỏ thật).
  final String nhanPhimTat;

  final VoidCallback khiBamMicro;

  /// Hai mục đầu của menu "Tài khoản của bạn" — Cài đặt tách làm hai nhóm
  /// (xem `_NutTaiKhoanMenu`, `man_hinh_cai_dat.dart`).
  final VoidCallback khiBamCaiDatMicro;
  final VoidCallback khiBamCaiDatHienThi;

  /// Mục "Cài đặt từ điển sửa lỗi chính tả" — ngay dưới "Cài đặt Hiển thị
  /// và tự động sửa" trong cùng menu — mở `moModalTuDienChinhTa`.
  final VoidCallback khiBamTuDienChinhTa;

  /// (YÊU CẦU MỚI) Mục "Cài đặt Từ điển nhập liệu nhanh" — ngay GIỮA "Cài
  /// đặt từ điển sửa lỗi chính tả" và "Cài đặt Bộ nhớ tạm để dán văn bản" —
  /// mở `moModalTuDienNhapLieuNhanh`.
  final VoidCallback khiBamTuDienNhapLieuNhanh;

  /// (YÊU CẦU MỚI — nhánh thử nghiệm) Mục "Bộ nhớ tạm để dán văn bản" —
  /// ngay dưới "Từ điển sửa lỗi chính tả của bạn" — mở `moModalBoNhoTam`.
  final VoidCallback khiBamBoNhoTam;

  final VoidCallback khiBamHuongDan;

  /// Gắn với mục "Cài đặt nút "Kiểm tra toàn văn"" trong menu "Làm việc với
  /// AI".
  final VoidCallback khiBamCaiDatKiemTraToanVan;
  final VoidCallback khiBamChuyenFileAmThanh;
  final VoidCallback khiBamChuyenAnhThanhVanBan;

  /// Mục "Chụp ảnh (camera)" — mở camera thiết bị, chụp một tấm, rồi chuyển
  /// hoá y hệt luồng "Chuyển hình ảnh thành văn bản" (qua Gemini).
  final VoidCallback khiBamChupAnh;

  /// Mục "Tóm tắt toàn văn" — mở modal "Chọn kiểu tóm tắt" rồi gọi Gemini.
  final VoidCallback khiBamTomTatToanVan;

  /// Mục "Mở rộng toàn văn" — mở modal "Chọn kiểu mở rộng" rồi gọi Gemini.
  final VoidCallback khiBamMoRongToanVan;

  /// Mục "Viết lại cho hay hơn" — modal chỉ có một ô câu lệnh tự do (có
  /// thể để trống) rồi gọi Gemini.
  final VoidCallback khiBamVietLaiToanVan;

  /// Mục "Trò chuyện về văn bản này" trong menu "Làm việc với AI" — mở màn
  /// hình chat toàn màn hình. RIÊNG biệt với [khiBamTroChuyen] bên dưới
  /// (nút "Trò chuyện" ngoài thanh công cụ — "Trò chuyện VỚI MỌI NGƯỜI",
  /// một tính năng khác hẳn, hiện vẫn là chỗ đặt trước).
  final VoidCallback khiBamTroChuyenVeVanBan;

  /// Nội dung vùng chọn hiện có ở trang soạn thảo, hay `null` nếu không có
  /// — gọi lại MỖI LẦN cần biết (không lưu trạng thái). Quyết định các mục
  /// trong menu "Làm việc với AI" (tóm tắt/mở rộng/viết lại/kiểm tra chính
  /// tả/kiểm tra dấu câu/trò chuyện) hiện tên "...toàn văn"/"...văn bản
  /// này" hay "...đoạn văn này"/"...đoạn văn đã chọn".
  final String? Function() layDoanVanDangChon;

  /// Có vùng chọn THẬT SỰ hay không (KHÔNG bị ảnh hưởng bởi
  /// [epToanVanKhiCoVungChon] — khác [layDoanVanDangChon]) — quyết định nút
  /// "Làm việc với AI" có sáng nền xanh hay không, và mục "Làm việc với
  /// Toàn bộ văn bản"/"Làm việc với Đoạn văn đang chọn" (vị trí 4, ngay
  /// dưới "Chuyển file âm thanh thành văn bản") có hiện ra hay không.
  final bool Function() coVungChonThatSu;

  /// Trạng thái hiện tại của công tắc "Làm việc với Toàn bộ văn bản"/"Làm
  /// việc với Đoạn văn đang chọn" — `true` nghĩa là đang ÉP mọi mục AI xử
  /// lý toàn văn dù đang có vùng chọn thật.
  final bool epToanVanKhiCoVungChon;

  /// Bấm mục "Làm việc với Toàn bộ văn bản"/"Làm việc với Đoạn văn đang
  /// chọn" — đảo [epToanVanKhiCoVungChon]. PopupMenuButton không tự vẽ lại
  /// nhãn các mục khác trong lúc đang mở, nên nơi gọi phải tự đóng rồi mở
  /// lại menu ngay sau khi đảo (qua [khoaMenuAI]) để thấy đổi ngay.
  final VoidCallback khiBamDoiCheDoLamViec;

  /// Khoá để tự mở lại `PopupMenuButton` bên trong `_NutAIMenu` ngay sau
  /// khi [khiBamDoiCheDoLamViec] đảo trạng thái — xem giải thích ở đó.
  final GlobalKey<PopupMenuButtonState<int>> khoaMenuAI;
  final VoidCallback khiBamBanPhim;

  /// "Bộ phím nhanh cho màn hình cảm ứng" (mục "Bật/Tắt..." trong "+ Thêm
  /// lựa chọn") — [boPhimNhanhDangMo] quyết định tên hiển thị (Bật/Tắt).
  final VoidCallback khiBamBoPhimNhanh;
  final bool boPhimNhanhDangMo;

  /// Thiết bị (tự đoán hoặc chọn tay) là Android/iPhone — truyền tiếp vào
  /// `_NutThemMenu`, xem giải thích ở đó.
  final bool noiBatBoPhimNhanh;

  final VoidCallback khiBamKiemTraToanVan;

  /// Hai mục CHỈ MỘT PHẦN của "Kiểm tra toàn văn" ở trên — CHỈ chính tả /
  /// CHỈ dấu câu.
  final VoidCallback khiBamKiemTraChinhTaToanVan;
  final VoidCallback khiBamKiemTraDauCauToanVan;

  /// Trình ghi âm (thẻ ghi âm) đang mở hay không — đổi icon/màu nút Ghi âm
  /// (ô vuông đỏ = dừng) và, ở thiết bị gộp-một-nút (`gopMicVaGhiAmThanhMotNut`),
  /// cả nút micro/ghi âm chung.
  final bool dangGhiAmThe;
  final VoidCallback khiBamGhiAmThe;

  /// Nút "All" — ĐÚNG logic/hiệu ứng với nút cùng tên ở Bộ phím nhanh
  /// (`_phimAoChonTatCa`/`_phimAllVuaChonTatCa` trong `trang_soan_thao.dart`):
  /// bấm 2-4 lần chọn dần đoạn văn/cụm đoạn văn/tất cả. Luôn hiện cố định ở
  /// đây, sát bên trái nút Ghi âm — không mất đi dù thanh dưới đang hiện
  /// Copy/Cắt (hai khu vực độc lập, không chung chỗ).
  final VoidCallback khiBamChonTatCa;

  /// `true` = vừa đạt "chọn tất cả" — tô nền xanh dương nổi bật, y hệt
  /// [dangGhiAmThe] không liên quan gì, đây là cờ RIÊNG của nút All.
  final bool dangChonTatCa;

  /// CHỈ true trên web + iPhone (xem nơi gọi ở `trang_soan_thao.dart`) —
  /// iPhone không dùng live-dictation qua Web Speech API được (WebKit
  /// không hỗ trợ), nên gộp nút micro và nút Ghi âm thành MỘT nút duy
  /// nhất, luôn đi thẳng vào luồng ghi-âm-tạo-thẻ. Android/iOS gốc và các
  /// bản thiết bị web khác giữ hai nút riêng như cũ.
  final bool gopMicVaGhiAmThanhMotNut;

  /// Ba mục đầu của menu "+ Thêm lựa chọn" — trước đây là ba nút riêng
  /// (Sao chép tất cả/Xoá tất cả trên thanh công cụ trên, cộng thêm mục gộp
  /// mới "Sao chép rồi xoá tất cả"), nay dồn cả vào đây.
  final VoidCallback khiBamChepTatCa;
  final VoidCallback khiBamChepRoiXoaTatCa;
  final VoidCallback khiBamXoaTatCa;

  /// (YÊU CẦU MỚI) Mục "Chọn tất cả" trong menu "+ Thêm lựa chọn" — ngay
  /// dưới "Xoá tất cả" — truyền thẳng xuống `_NutThemMenu`.
  final VoidCallback khiBamChonTatCaTrongMenuThem;

  /// Gắn với mục "Danh sách phím tắt", ngay dưới "Kiểu gõ bàn phím".
  final VoidCallback khiBamDanhSachPhimTat;

  /// Mục 8b: nút "Tìm kiếm" trước đây nằm ở thanh trên cùng (Lùi/Tiến/Lưu)
  /// của trang soạn thảo — nay dời vào menu "+ Thêm lựa chọn" của thanh
  /// này, dưới tên "Tìm kiếm và thay thế".
  final VoidCallback khiBamTimKiem;

  /// Mục 9: nút "Trò chuyện" NGOÀI thanh công cụ — "Trò chuyện VỚI MỌI
  /// NGƯỜI" (xem tooltip ở nơi dùng), một tính năng XÃ HỘI khác hẳn với
  /// "Trò chuyện về văn bản này" (chat với AI, [khiBamTroChuyenVeVanBan] ở
  /// trên) — hiện vẫn là chỗ đặt trước, chỉ hiện thông báo "đang nâng cấp".
  final VoidCallback khiBamTroChuyen;

  /// Ngưỡng bề ngang để các nút bên trái (Hướng dẫn/Làm việc với AI/Thêm
  /// lựa chọn/Tài khoản-Cài đặt/Phím nhanh) giãn ra thành khung có TÊN đầy
  /// đủ, thay vì chỉ icon tròn gọn (`NutNho`).
  ///
  /// ĐÃ SỬA (màn hình hẹp vừa — cỡ cửa sổ trình duyệt thu nhỏ trên máy
  /// tính, ví dụ ~650-750px — tên nút tràn/đè lên cụm All/Ghi âm/Micro bên
  /// phải): ngưỡng cũ 600px chỉ đủ cho MỘT cột điện thoại dọc, không tính
  /// tới việc 5 nút bên trái GIÃN TÊN RA cần cỡ 650-700px chỉ riêng chúng,
  /// trong khi cụm bên phải (All 40 + Ghi âm 40 + sóng âm 34 + Micro 40,
  /// cộng khoảng cách/đệm) chiếm cỡ 190-200px CỐ ĐỊNH không co lại được —
  /// cộng cả hai cần khoảng 850-900px mới thật sự thoải mái. Nâng hẳn lên
  /// 900px: dưới mức đó LUÔN chỉ icon tròn (an toàn, không tràn); từ đó trở
  /// lên mới đủ chỗ hiện tên đầy đủ.
  static const _nguongManHinhRong = 900.0;

  /// (YÊU CẦU MỚI) Ngưỡng bề ngang cho "màn hình RẤT hẹp" — hẹp hơn hẳn mốc
  /// 600px dùng ở các chỗ khác trong app (`_nguongManHinhHep` bên
  /// `trang_soan_thao.dart`, cho những điều chỉnh NHẸ hơn như co nhỏ nút).
  /// Đây là mốc riêng, CHỈ dùng cho đúng việc: ở màn hình điện thoại phổ
  /// biến nhất (bề ngang logic cỡ 360-420px khi dựng đứng — ví dụ máy người
  /// dùng mô tả, khoảng 8 inch đường chéo), hàng nút bên trái cộng cụm
  /// All/Ghi âm/sóng âm/Micro bên phải quá chật — ẨN HẲN nút "Hướng dẫn"
  /// khỏi hàng chính, dồn qua một hàng phụ riêng CHỈ hiện khi đang bật chú
  /// thích (xem `_hangPhuHuongDanKhiRatHep`).
  static const _nguongManHinhRatHep = 420.0;

  Widget _nut(
    bool rong,
    IconData icon,
    String nhanHep,
    String nhanRong,
    VoidCallback khiBam, {
    Color mau = const Color(0xFF5F6368),
  }) {
    return rong
        ? _NutRong(bieuTuong: icon, nhan: nhanRong, khiBam: khiBam, mau: mau)
        : NutNho(bieuTuong: icon, nhan: nhanHep, khiBam: khiBam, mau: mau);
  }

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        bottom: neThanhDieuHuong,
        child: LayoutBuilder(
          builder: (context, rangBuoc) {
            final rong = rangBuoc.maxWidth >= _nguongManHinhRong;
            final ratHep = rangBuoc.maxWidth < _nguongManHinhRatHep;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Container(
              // Thấp hết mức còn bấm trúng: 48px vẫn đủ vùng chạm theo chuẩn
              // Material, mà nhường gần hết màn hình cho chữ.
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              // Micro đang bật (đỏ) thì đường kẻ ngăn cách với trang soạn
              // thảo cũng đỏ đậm và dày hẳn lên — dấu hiệu dễ thấy dù mắt
              // đang nhìn vào bài, không cần liếc xuống tận nút micro mới
              // biết đang ghi.
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: bat ? Colors.red.shade600 : const Color(0xFFE3E3E3),
                    width: bat ? 3 : 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Bên trái: hướng dẫn sát mép màn hình, rồi cài đặt, rồi
                  // hai nút mới (AI, bàn phím), rồi thư mục — dải này (KHÔNG
                  // gồm nút Ghi âm, sóng âm, micro) tô nền hồng nhạt khi micro
                  // đang bật, đồng bộ với đường kẻ đỏ phía trên. Container chỉ
                  // bọc riêng Expanded này, KHÔNG bọc luôn nút Ghi âm — nền
                  // hồng vì vậy CHẠM tới mép trái nút Ghi âm (liền kề, không
                  // khoảng hở) nhưng dừng lại đúng ở đó, không lấn vào trong
                  // nút. Bản thân các nút (Hướng dẫn/Cài đặt/…) không tự vẽ
                  // nền riêng, chỉ có icon/chữ, nên nền hồng của Container vẫn
                  // hiện được ở khoảng trống quanh chúng mà không "ám" màu
                  // lên icon hay chữ — icon/chữ luôn giữ đúng màu của nó.
                  Expanded(
                    child: Container(
                      color: bat ? Colors.red.shade50 : Colors.transparent,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        // Mặc định ScrollView CẮT mọi thứ tràn ra ngoài khung
                        // nhìn của nó — chú thích dọc của các nút bên trong
                        // đây cố ý vẽ TRÀN LÊN TRÊN nút (Positioned âm), nên
                        // phải tắt hẳn việc cắt này thì chú thích mới hiện ra
                        // được.
                        clipBehavior: Clip.none,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          // Đang Thu gọn thanh công cụ phía trên VÀ có vùng
                          // chọn thật VÀ Bộ phím nhanh KHÔNG mở (nếu nó đang
                          // mở thì bên trong đã có sẵn Copy/Cắt/Dán rồi,
                          // không cần logic này nữa) — tạm ẩn 4 nút
                          // Hướng dẫn/Thêm/Tài khoản-Cài đặt/Phím nhanh,
                          // nhường chỗ cho "Làm việc với AI" (tự sáng nền
                          // xanh sẵn, xem `_NutAIMenu`, không cần cờ riêng)
                          // sát mép trái + hàng Copy/Cắt/Dán ngay bên cạnh.
                          // Bấm 1 trong 3 nút đó thì nơi gọi (`trang_soan_thao.dart`)
                          // tự ẩn hàng đi, 4 nút cũ hiện lại ngay.
                          children: (thayNutBangCopyCutPaste && hangCopyCutPaste != null)
                              ? [
                                  _NutCoChuThich(
                                    hien: hienChuThich,
                                    chu: 'Làm việc với AI',
                                    child: _NutAIMenu(
                                      rong: rong,
                                      khiBamCaiDatKiemTraToanVan: khiBamCaiDatKiemTraToanVan,
                                      khiBamKiemTraToanVan: khiBamKiemTraToanVan,
                                      khiBamKiemTraChinhTaToanVan: khiBamKiemTraChinhTaToanVan,
                                      khiBamKiemTraDauCauToanVan: khiBamKiemTraDauCauToanVan,
                                      khiBamChuyenFileAmThanh: khiBamChuyenFileAmThanh,
                                      khiBamChuyenAnhThanhVanBan: khiBamChuyenAnhThanhVanBan,
                                      khiBamChupAnh: khiBamChupAnh,
                                      khiBamTomTatToanVan: khiBamTomTatToanVan,
                                      khiBamMoRongToanVan: khiBamMoRongToanVan,
                                      khiBamVietLaiToanVan: khiBamVietLaiToanVan,
                                      khiBamTroChuyenVeVanBan: khiBamTroChuyenVeVanBan,
                                      layDoanVanDangChon: layDoanVanDangChon,
                                      coVungChonThatSu: coVungChonThatSu,
                                      epToanVanKhiCoVungChon: epToanVanKhiCoVungChon,
                                      khiBamDoiCheDoLamViec: khiBamDoiCheDoLamViec,
                                      khoaMenuAI: khoaMenuAI,
                                      khiMoMenu: khiMoMenuCanReset,
                                      khiDongMenu: khiDongMenuAI,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  hangCopyCutPaste!,
                                ]
                              : [
                          // Thứ tự mới (mục 10): Hướng dẫn, Làm việc với AI,
                          // Trò chuyện, Thêm lựa chọn, Tài khoản — "Cài đặt"
                          // và "Kiểm tra toàn văn" đã dời vào trong hai menu
                          // (mục 8b/8c). Nút "Thư mục" đã bỏ khỏi đây — trùng
                          // với nút Thư mục ở thanh trên gần tên tệp
                          // (`_nutDieuHuongTep` trong `trang_soan_thao.dart`),
                          // giữ lại đúng một nút duy nhất.
                          // (YÊU CẦU MỚI) Màn hình RẤT hẹp: ẩn hẳn nút này
                          // khỏi hàng chính (hết chật) — dồn qua hàng phụ
                          // riêng, xem `_hangPhuHuongDanKhiRatHep`.
                          if (!ratHep)
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Hướng dẫn sử dụng',
                            child: _nut(rong, Icons.help_outline_rounded,
                                'Hướng dẫn', 'Hướng dẫn', khiBamHuongDan),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Làm việc với AI',
                            child: _NutAIMenu(
                              rong: rong,
                              khiBamCaiDatKiemTraToanVan: khiBamCaiDatKiemTraToanVan,
                              khiBamKiemTraToanVan: khiBamKiemTraToanVan,
                              khiBamKiemTraChinhTaToanVan: khiBamKiemTraChinhTaToanVan,
                              khiBamKiemTraDauCauToanVan: khiBamKiemTraDauCauToanVan,
                              khiBamChuyenFileAmThanh: khiBamChuyenFileAmThanh,
                              khiBamChuyenAnhThanhVanBan: khiBamChuyenAnhThanhVanBan,
                              khiBamChupAnh: khiBamChupAnh,
                              khiBamTomTatToanVan: khiBamTomTatToanVan,
                              khiBamMoRongToanVan: khiBamMoRongToanVan,
                              khiBamVietLaiToanVan: khiBamVietLaiToanVan,
                              khiBamTroChuyenVeVanBan: khiBamTroChuyenVeVanBan,
                              layDoanVanDangChon: layDoanVanDangChon,
                              coVungChonThatSu: coVungChonThatSu,
                              epToanVanKhiCoVungChon: epToanVanKhiCoVungChon,
                              khiBamDoiCheDoLamViec: khiBamDoiCheDoLamViec,
                              khoaMenuAI: khoaMenuAI,
                              khiMoMenu: khiMoMenuCanReset,
                              khiDongMenu: khiDongMenuAI,
                            ),
                          ),
                          // Nhân bản nút "Bật/Tắt Bộ phím nhanh cho màn hình
                          // cảm ứng" (trước đây chỉ có trong menu "+ Thêm lựa
                          // chọn") ra thành một nút riêng ngay ngoài thanh
                          // công cụ — dễ bấm hơn, không cần mở menu. Cả hai
                          // đường (nút riêng này và mục trong menu Thêm) vẫn
                          // cùng gọi một hàm `khiBamBoPhimNhanh` duy nhất, nên
                          // luôn đồng bộ trạng thái với nhau.
                          //
                          // (YÊU CẦU MỚI) Dời nút này ra giữa "Làm việc với
                          // AI" và "Xem thêm lựa chọn" — áp dụng cho mọi loại
                          // màn hình (rộng/hẹp), vì cả hai đều dùng chung
                          // danh sách này.
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Phím nhanh cho màn hình cảm ứng',
                            child: _nut(
                              rong,
                              Icons.keyboard,
                              'Phím nhanh',
                              'Phím nhanh',
                              // Thông báo khi BẬT lên giờ do chính
                              // `khiBamBoPhimNhanh` (_bamNutBoPhimNhanhCamUng
                              // trong trang_soan_thao.dart) tự hiện — gọi
                              // thẳng, không tự hiện thêm toast riêng ở đây
                              // nữa (từng hiện HAI thông báo chồng nhau).
                              khiBamBoPhimNhanh,
                              mau: boPhimNhanhDangMo
                                  ? const Color(0xFF1A73E8)
                                  : const Color(0xFF5F6368),
                            ),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Xem thêm lựa chọn',
                            child: _NutThemMenu(
                              rong: rong,
                              khiBamBanPhim: khiBamBanPhim,
                              khiBamBoPhimNhanh: khiBamBoPhimNhanh,
                              boPhimNhanhDangMo: boPhimNhanhDangMo,
                              noiBatBoPhimNhanh: noiBatBoPhimNhanh,
                              khiBamChepTatCa: khiBamChepTatCa,
                              khiBamChepRoiXoaTatCa: khiBamChepRoiXoaTatCa,
                              khiBamXoaTatCa: khiBamXoaTatCa,
                              khiBamChonTatCaTrongMenuThem: khiBamChonTatCaTrongMenuThem,
                              khiBamDanhSachPhimTat: khiBamDanhSachPhimTat,
                              khiBamTimKiem: khiBamTimKiem,
                              khiMoMenu: khiMoMenuCanReset,
                              khiBamLuyenGoPhim: khiBamLuyenGoPhim,
                              khiBamCaiDatUngDung: khiBamCaiDatUngDung,
                              khiBamGopY: khiBamGopY,
                            ),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Tài khoản và Cài đặt',
                            child: _NutTaiKhoanMenu(
                              rong: rong,
                              khiBamCaiDatMicro: khiBamCaiDatMicro,
                              khiBamCaiDatHienThi: khiBamCaiDatHienThi,
                              khiBamTuDienChinhTa: khiBamTuDienChinhTa,
                              khiBamTuDienNhapLieuNhanh: khiBamTuDienNhapLieuNhanh,
                              khiBamBoNhoTam: khiBamBoNhoTam,
                              khiBamTroChuyen: khiBamTroChuyen,
                              khiMoMenu: khiMoMenuCanReset,
                              khiBamDangNhapGoogle: khiBamDangNhapGoogle,
                              khiBamKhoiDongTep: khiBamKhoiDongTep,
                              khiBamDieuKhoan: khiBamDieuKhoan,
                              khiBamBaoMat: khiBamBaoMat,
                              khiBamQuanLyGopY: khiBamQuanLyGopY,
                              khiBamDanhSachUser: khiBamDanhSachUser,
                              tenHienThiDaDangNhap: tenHienThiDaDangNhap,
                              emailDaDangNhap: emailDaDangNhap,
                              urlAnhDaiDienDaDangNhap: urlAnhDaiDienDaDangNhap,
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Nút "All" — luôn ở đây, sát bên trái nút Ghi âm, cả hai
                  // khu vực (nhóm 4 nút trái/Copy-Cắt và All/Ghi âm/chú
                  // thích/Micro bên phải) độc lập nên nút này không bao giờ
                  // bị Copy/Cắt che mất.
                  _NutCoChuThich(
                    hien: hienChuThich,
                    chu: 'Tạo vùng chọn văn bản',
                    child: _NutAllTron(
                      dangChonTatCa: dangChonTatCa,
                      khiBam: khiBamChonTatCa,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Nút Ghi âm riêng chỉ tồn tại khi KHÔNG gộp chung với
                  // micro (iPhone gộp cả hai thành một nút duy nhất bên
                  // phải, xem dưới) — giờ dùng CHUNG `_NutGhiAmTron` với nút
                  // gộp của iPhone, để cả hai trông giống nhau tuyệt đối: to
                  // bằng nút micro, nền xanh nhạt + viền xanh lá đậm lúc
                  // chưa ghi.
                  if (!gopMicVaGhiAmThanhMotNut)
                    _NutCoChuThich(
                      hien: hienChuThich,
                      chu: 'Ghi âm (Nói xong mới ra chữ)',
                      child: _NutGhiAmTron(
                        dangGhiAm: dangGhiAmThe,
                        khiBam: khiBamGhiAmThe,
                      ),
                    ),

                  // Bên phải: sóng âm (hoặc nút hiện chú thích, cùng vị trí)
                  // rồi micro (hoặc nút gộp) sát mép phải — GIỮ NGUYÊN thứ tự
                  // đó cho mọi thiết bị, TRỪ iPhone bản web: ở đó Ghi âm (nút
                  // gộp micro+ghi âm, iPhone không dùng được micro live) đổi
                  // sang đứng BÊN TRÁI, còn sóng âm/nút hiện chú thích đổi
                  // sang đứng sát mép phải — hai đứa đổi chỗ cho nhau, chỉ
                  // riêng thiết bị này.
                  if (gopMicVaGhiAmThanhMotNut) ...[
                    _NutCoChuThich(
                      hien: hienChuThich,
                      chu: 'Ghi âm (Nói xong mới ra chữ)',
                      child: _NutGhiAmTron(
                        dangGhiAm: dangGhiAmThe,
                        khiBam: khiBamGhiAmThe,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _NutCoChuThich(
                      hien: hienChuThich && !bat,
                      chu: 'Hiện chú thích',
                      vang: true,
                      child: SongAm(
                        muc: songAm,
                        dangNghe: bat && dangNghe,
                        micDangBat: bat,
                        khiBamChuThich: khiBamChuThich,
                      ),
                    ),
                  ] else ...[
                    _NutCoChuThich(
                      hien: hienChuThich && !bat,
                      chu: 'Hiện chú thích',
                      vang: true,
                      child: SongAm(
                        muc: songAm,
                        dangNghe: bat && dangNghe,
                        micDangBat: bat,
                        khiBamChuThich: khiBamChuThich,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _NutCoChuThich(
                      hien: hienChuThich,
                      chu: 'Micro Vừa nói vừa ra chữ',
                      child: _NutMicroTron(
                        bat: bat,
                        sanSang: sanSang,
                        biKhoaThietBi: biKhoaThietBi,
                        mau: mau,
                        nhanPhimTat: nhanPhimTat,
                        khiBam: (sanSang || biKhoaThietBi) ? khiBamMicro : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // (YÊU CẦU MỚI) Màn hình RẤT hẹp mất nút "Hướng dẫn" ở hàng
            // chính (xem trên) — dồn qua đây: một hàng phụ, ngay sát dưới
            // hàng chính, CHỈ hiện trong lúc chú thích đang hiện (bật bằng
            // nút "i"), ẩn lại ngay khi chú thích tắt — đúng yêu cầu, không
            // chiếm thêm chỗ lúc bình thường.
            if (ratHep && hienChuThich) _hangPhuHuongDanKhiRatHep(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Hàng phụ CHỈ chứa nút "Hướng dẫn và mẹo sử dụng" — xem
  /// `_nguongManHinhRatHep`.
  ///
  /// (YÊU CẦU MỚI) KHÔNG bọc `_NutCoChuThich` — nút này LUÔN hiện sẵn tên
  /// đầy đủ ("? Hướng dẫn và mẹo sử dụng", dùng thẳng `_NutRong` chứ không
  /// phải `NutNho`), nên không cần và không được hiện thêm dòng chú thích
  /// dọc phía trên nữa (khác các nút ở hàng chính — những nút đó vẫn luôn
  /// hiện chú thích như cũ, không đổi gì). Bấm nút "i" bật chú thích cũng
  /// KHÔNG ảnh hưởng gì tới riêng nút này.
  Widget _hangPhuHuongDanKhiRatHep() {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE3E3E3), width: 1)),
      ),
      child: _NutRong(
        bieuTuong: Icons.help_outline_rounded,
        nhan: 'Hướng dẫn và mẹo sử dụng',
        khiBam: khiBamHuongDan,
      ),
    );
  }
}

/// Nút Ghi âm tròn — dùng CHUNG cho cả nút Ghi âm riêng (Android/iOS gốc và
/// hầu hết thiết bị web) LẪN nút gộp micro+ghi âm của iPhone
/// (`gopMicVaGhiAmThanhMotNut`, iPhone không có micro riêng vì WebKit không
/// hỗ trợ live-dictation) — cả hai phải trông giống nhau tuyệt đối theo yêu
/// cầu người dùng. To bằng nút micro (`_NutMicroTron`, khung tròn 40x40):
/// nền xanh nhạt (`Colors.blue.shade50`, giữ giống nền micro cho đồng bộ thị
/// giác) + viền xanh LÁ đậm lúc chưa ghi (khác màu viền xanh DƯƠNG của nút
/// micro, để phân biệt hai chức năng) — đỏ đặc (không viền) lúc đang ghi.
class _NutGhiAmTron extends StatelessWidget {
  const _NutGhiAmTron({required this.dangGhiAm, required this.khiBam});

  final bool dangGhiAm;
  final VoidCallback khiBam;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: dangGhiAm ? 'Dừng ghi âm' : 'Ghi âm',
      child: Tooltip(
        message: dangGhiAm ? 'Dừng ghi âm' : 'Ghi âm (tạo thẻ ghi âm)',
        child: Material(
          color: dangGhiAm ? Colors.red.shade600 : Colors.blue.shade50,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            // ĐÃ SỬA (web: phải chạm 2 lần khi con trỏ văn bản đang có tiêu
            // điểm) — bắt sự kiện ngay lúc CHẠM XUỐNG (`onTapDown`) thay vì
            // đợi tới lúc NHẤC LÊN (`onTap`), vì trên web việc chuyển tiêu
            // điểm DOM ra khỏi khung nhập (khi focus rời khỏi input ẩn phía
            // sau) có thể "ăn" mất đúng sự kiện nhấc tay của lượt chạm đầu.
            // `onTap` rỗng chỉ để giữ InkWell ở trạng thái "có thể chạm"
            // (còn hiệu ứng loang màu).
            onTap: () {},
            onTapDown: (_) => khiBam(),
            child: Container(
              width: 40,
              height: 40,
              decoration: dangGhiAm
                  ? null
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade800, width: 2.5),
                    ),
              alignment: Alignment.center,
              child: Icon(
                dangGhiAm ? Icons.stop : Icons.mic_rounded,
                color: dangGhiAm ? Colors.white : Colors.green.shade800,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút "All" tròn — to bằng nút Ghi âm/Micro (40x40), chữ "All" thay icon.
/// Màu: viền xám mặc định, tô nền xanh dương nổi bật khi [dangChonTatCa]
/// (vừa đạt "chọn tất cả") — ĐÚNG màu/tinh thần `noiBat` của `_NutCongCuChu`
/// ở Bộ phím nhanh, chỉ đổi khung tròn cho đồng bộ với các nút khác ở đây.
class _NutAllTron extends StatelessWidget {
  const _NutAllTron({required this.dangChonTatCa, required this.khiBam});

  final bool dangChonTatCa;
  final VoidCallback khiBam;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tạo vùng chọn văn bản',
      child: Tooltip(
        message: 'Tạo vùng chọn văn bản',
        child: Material(
          color: dangChonTatCa ? Colors.blue.shade100 : Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            onTapDown: (_) => khiBam(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: dangChonTatCa ? Colors.blue.shade400 : Colors.grey.shade400,
                  width: 2.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dangChonTatCa ? Colors.blue.shade900 : const Color(0xFF5F6368),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NutMicroTron extends StatelessWidget {
  const _NutMicroTron({
    required this.bat,
    required this.sanSang,
    this.biKhoaThietBi = false,
    required this.mau,
    required this.nhanPhimTat,
    required this.khiBam,
  });

  final bool bat;
  final bool sanSang;
  final bool biKhoaThietBi;
  final ColorScheme mau;
  final String nhanPhimTat;
  final VoidCallback? khiBam;

  @override
  Widget build(BuildContext context) {
    // (VIỆC 5) Nền khi CHƯA hoạt động đổi từ xanh đậm (mau.primary) sang
    // xanh lá nhạt — GIỮ NGUYÊN nhánh đỏ khi đang nghe, không đụng tới.
    // Thiết bị bị khoá (iPhone web) luôn xám, bất kể `sanSang`/`bat`.
    final nen = biKhoaThietBi
        ? Colors.grey.shade300
        : (!sanSang
            ? Colors.grey.shade400
            : (bat ? Colors.red.shade600 : Colors.green.shade100));
    // Chụp vào biến local KHÔNG NULL — `khiBam` là field public nên Dart
    // không tự "promote" kiểu của nó dù đã so sánh `!= null` (lỗi build:
    // "potentially null"), phải gán ra biến riêng mới dùng gọn được.
    final khiBamCu = khiBam;

    return Semantics(
      button: true,
      label: bat ? 'Tắt micro' : 'Bật micro',
      child: Tooltip(
        message: '${bat ? 'Tắt' : 'Bật'} micro ($nhanPhimTat)',
        child: Material(
          color: nen,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            // Xem chú thích "ĐÃ SỬA" ở `_NutMicroHoacGhiAmGop` — cùng lý do.
            onTap: khiBamCu == null ? null : () {},
            onTapDown: khiBamCu == null ? null : (_) => khiBamCu(),
            child: Container(
              width: 40,
              height: 40,
              // (VIỆC 3) Viền xanh dương đậm bao quanh nền — CHỈ ở nhánh
              // CHƯA hoạt động (sanSang && !bat, nền xanh lá nhạt). Nhánh
              // đang nghe (nền đỏ) và nhánh chưa sẵn sàng (nền xám) không có
              // viền này, giữ nguyên như cũ. Thiết bị bị khoá (iPhone web)
              // luôn có viền — xám đậm thay vì xanh dương.
              decoration: biKhoaThietBi
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade700, width: 2.5),
                    )
                  : (sanSang && !bat)
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue.shade900, width: 2.5),
                        )
                      : null,
              // Phần C: đổi icon Material sang emoji 🎤 — giữ NGUYÊN mọi
              // logic/trạng thái (bật/tắt/màu nền), chỉ đổi phần hiển thị.
              // Cùng cách render emoji-làm-icon đã dùng cho nút Ẩn/hiện
              // thanh định dạng ('🔤', xem `_dsNutCongCu` trong
              // trang_soan_thao.dart).
              child: const Center(
                child: Text('🎤', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút biểu tượng cỡ nhỏ. IconButton sẵn có chiếm tối thiểu 48x48, quá cao so
/// với thanh công cụ này, nên tự dựng lấy một cái vừa vặn hơn.
class NutNho extends StatelessWidget {
  const NutNho({
    super.key,
    required this.bieuTuong,
    required this.nhan,
    required this.khiBam,
    this.mau = const Color(0xFF5F6368),
  });

  final IconData bieuTuong;
  final String nhan;
  final VoidCallback khiBam;
  final Color mau;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: nhan,
      child: Tooltip(
        message: nhan,
        child: InkResponse(
          // Xem chú thích "ĐÃ SỬA" ở `_NutMicroHoacGhiAmGop` — cùng lý do.
          onTap: () {},
          onTapDown: (_) => khiBam(),
          radius: 22,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            // Nền trắng RIÊNG của nút — không lấy màu nền của thanh công cụ
            // (thường là trắng, nhưng đổi hồng nhạt lúc micro bật). Trắng
            // trên trắng thì không thấy khác gì, nhưng trên nền hồng thì nút
            // vẫn giữ nguyên trắng, không bị nhuộm theo.
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(bieuTuong, size: 20, color: mau),
          ),
        ),
      ),
    );
  }
}

/// Khung trực quan của một nút "mở rộng": icon sát mép trái bên trong khung
/// viền bo tròn, tên nút liền ngay bên phải icon. Tách riêng phần khung khỏi
/// phần bắt chạm (`_NutRong` bên dưới, hoặc `PopupMenuButton.child` cho nút
/// dấu cộng) vì có chỗ cần InkWell riêng, có chỗ nút cha (PopupMenuButton) đã
/// tự lo việc bắt chạm rồi.
class _KhungNutRong extends StatelessWidget {
  const _KhungNutRong({
    required this.bieuTuong,
    required this.nhan,
    this.mau = const Color(0xFF5F6368),
    this.mauNen = Colors.white,
  });

  final IconData bieuTuong;
  final String nhan;
  final Color mau;

  /// Nền — mặc định trắng như từ trước giờ; "Làm việc với AI" đổi nền
  /// xanh khi trang soạn thảo có vùng chọn (xem `_NutAIMenu`), các nút
  /// khác vẫn giữ nguyên mặc định.
  final Color mauNen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      // Nền trắng riêng, không lấy màu nền của thanh công cụ — xem giải
      // thích ở NutNho.
      decoration: BoxDecoration(
        color: mauNen,
        border: Border.all(color: const Color(0xFFDADCE0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(bieuTuong, size: 16, color: mau),
          const SizedBox(width: 6),
          Text(nhan, style: TextStyle(fontSize: 12, color: mau)),
        ],
      ),
    );
  }
}

/// Nút "mở rộng" dùng cho màn hình rộng: cùng khung với `_KhungNutRong`,
/// nhưng tự lo việc bắt chạm (những nút gọi thẳng một callback, khác với nút
/// dấu cộng vốn đã nằm sẵn trong `PopupMenuButton`).
class _NutRong extends StatelessWidget {
  const _NutRong({
    required this.bieuTuong,
    required this.nhan,
    required this.khiBam,
    this.mau = const Color(0xFF5F6368),
  });

  final IconData bieuTuong;
  final String nhan;
  final VoidCallback khiBam;
  final Color mau;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: nhan,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Xem chú thích "ĐÃ SỬA" ở `_NutMicroHoacGhiAmGop` — cùng lý do.
          onTap: () {},
          onTapDown: (_) => khiBam(),
          borderRadius: BorderRadius.circular(16),
          child: _KhungNutRong(bieuTuong: bieuTuong, nhan: nhan, mau: mau),
        ),
      ),
    );
  }
}

/// Một chấm tròn nhỏ khi im lặng; micro bật lên thì có thêm các vòng tròn
/// đồng tâm bao quanh chấm, âm càng lớn thì vòng càng nhiều và càng đậm.
/// Gọn hơn hẳn dãy vạch cũ — chỉ chiếm đúng bằng cỡ nút micro bên cạnh.
class SongAm extends StatelessWidget {
  const SongAm({
    super.key,
    required this.muc,
    required this.dangNghe,
    required this.micDangBat,
    required this.khiBamChuThich,
  });

  final List<double> muc;
  final bool dangNghe;

  /// Micro lớn (nút sát mép phải) có đang bật hay không — bật thì vẽ sóng
  /// âm như cũ; tắt thì cái chấm tròn này biến thành nút "i" để mở chú
  /// thích, vì lúc này sóng âm chẳng còn gì để vẽ.
  final bool micDangBat;
  final VoidCallback khiBamChuThich;

  @override
  Widget build(BuildContext context) {
    if (!micDangBat) {
      return Semantics(
        button: true,
        label: 'Hiện chú thích',
        child: Tooltip(
          message: 'Hiện chú thích',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: khiBamChuThich,
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.info_outline, size: 22, color: Color(0xFF5F6368)),
            ),
          ),
        ),
      );
    }

    return VongSongAm(
      muc: muc,
      dangNghe: dangNghe,
      mau: Colors.red.shade600,
    );
  }
}

/// Bọc một nút của thanh công cụ, thêm dòng chữ chú thích DỌC ngay phía trên
/// khi `hien` bật — chữ nằm nghiêng 90 độ, đầu ký tự hướng về bên trái, nên
/// đọc từ dưới lên trên chứ không phải trái sang phải như bình thường.
class _NutCoChuThich extends StatelessWidget {
  const _NutCoChuThich({
    required this.hien,
    required this.chu,
    required this.child,
    this.vang = false,
  });

  final bool hien;
  final String chu;
  final Widget child;

  /// Riêng chú thích của nút "i" có nền vàng nhạt để nổi bật hẳn so với các
  /// chú thích khác.
  final bool vang;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        child,
        if (hien)
          Positioned(
            bottom: 42,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              decoration: BoxDecoration(
                color: vang ? const Color(0xFFFFF9C4) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFDADCE0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  chu,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF202124)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// (VIỆC 3) Một dòng BẤM ĐƯỢC bên trong khung cuộn dùng chung của
/// `_mucCuonDanhSach` — thay cho một `PopupMenuItem` riêng lẻ (kiến trúc cũ
/// khiến Flutter tự dựng một `Scrollable` nội bộ không lấy lại được đáng tin
/// cậy, xem `_mucDongMenu`). Bấm vào tự đóng menu và trả về [gia] qua
/// `Navigator.pop`, ĐÚNG cơ chế mà một `PopupMenuItem` bình thường dùng nội
/// bộ — `onSelected` của `PopupMenuButton` vẫn nhận được giá trị y hệt,
/// không đổi gì ở phía gọi.
class _DongMenuCoTheBam extends StatelessWidget {
  const _DongMenuCoTheBam({
    required this.gia,
    required this.child,
    this.height = 34,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.mauNen,
  });

  final int gia;
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  /// (YÊU CẦU MỚI) Tô cả NỀN của dòng — khác [noiBat] của `_mucMenuThem`
  /// (chỉ đổi màu CHỮ) — dùng cho mục cần nổi bật mạnh hơn hẳn mọi mục khác
  /// trong menu, xem `_mucMenuThemNoiBatXanh`.
  final Color? mauNen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop<int>(context, gia),
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        margin: mauNen != null
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
            : EdgeInsets.zero,
        padding: padding,
        alignment: Alignment.centerLeft,
        decoration: mauNen != null
            ? BoxDecoration(color: mauNen, borderRadius: BorderRadius.circular(8))
            : null,
        child: child,
      ),
    );
  }
}

/// (YÊU CẦU MỚI) Mục "Cài đặt Ứng dụng vào Thiết bị" — nền xanh dương đậm,
/// chữ trắng đậm kèm icon, để nổi bật hẳn so với các dòng text thường
/// khác trong menu "+ Thêm lựa chọn", thu hút ánh nhìn người dùng.
Widget _mucMenuThemNoiBatXanh(int gia, String chu) {
  return _DongMenuCoTheBam(
    gia: gia,
    mauNen: const Color(0xFF1A73E8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.install_mobile, size: 17, color: Colors.white),
        const SizedBox(width: 8),
        Text(chu,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    ),
  );
}

/// Một dòng trong menu thả xuống của nút dấu cộng — cao vừa đủ chữ, viền sát
/// chữ, không rộng thùng thình như PopupMenuItem mặc định (cao tối thiểu 48).
/// [noiBat]: chữ đậm + xanh dương — dùng đúng một chỗ, mục "Bật Bộ phím
/// nhanh cho màn hình cảm ứng" khi thiết bị (tự đoán hoặc chọn tay) là
/// Android/iPhone, xem `_NutThemMenu`.
Widget _mucMenuThem(int gia, String chu, {bool noiBat = false, Color? mauChu}) {
  return _DongMenuCoTheBam(
    gia: gia,
    child: Text(
      chu,
      style: TextStyle(
        fontSize: 13,
        fontWeight: noiBat ? FontWeight.bold : null,
        color: mauChu ?? (noiBat ? Colors.blue.shade700 : null),
      ),
    ),
  );
}

/// Màu tím đậm dùng chung cho mọi mục menu AI đang xử lý theo NGỮ CẢNH
/// ĐOẠN VĂN ĐANG CHỌN (khác hẳn màu chữ mặc định khi xử lý cả bài) — xem
/// `_NutAIMenu`.
const _mauTimNguCanhDoanChon = Color(0xFF6A1B9A);

/// Đường kẻ phân cách giữa các nhóm mục — GIỮ NGUYÊN chiều cao/vẻ ngoài của
/// `PopupMenuDivider(height: 8)` trước đây, chỉ đổi sang một `Divider`
/// thường vì các dòng giờ nằm trong một `Column` bên trong khung cuộn, không
/// còn là `PopupMenuEntry` riêng của `PopupMenuButton` nữa.
Widget _dividerMenu() => const Divider(height: 8, thickness: 1);

/// (VIỆC 3) Nút tròn nhỏ dùng chung cho hai nút cuộn (lên đầu/xuống cuối)
/// nằm cạnh nút X trong `_mucDongMenu`. Dùng `GestureDetector` riêng (không
/// phải `IconButton` — kích thước tối thiểu 48 của nó quá to cho hàng cao
/// 28) để bấm vào đây KHÔNG đóng menu: một widget bấm được lồng BÊN TRONG
/// `PopupMenuItem` luôn thắng trong đấu trường cử chỉ (gesture arena) trước
/// `InkWell` mặc định bọc ngoài của `PopupMenuItem` (cái vẫn khiến bấm vào
/// nút X đóng menu, vì X không có `onTap` riêng) — đây là hành vi chuẩn của
/// Flutter với các widget bấm được lồng nhau, không cần tự chặn sự kiện nổi
/// bọt (bubbling) thủ công.
///
/// StatefulWidget (không phải Stateless như trước) để có `dispose()` HUỶ
/// ĐÚNG CÁCH bộ đếm giờ của [onHoverTick] — [onHoverTick] (nếu có) được gọi
/// LIÊN TỤC (~40 lần/giây) trong lúc con trỏ CHUỘT đang rê trên nút, để cuộn
/// dần mà không cần bấm (hữu ích trên tablet/Chromebook/bản thử desktop có
/// chuột; trên cảm ứng thuần như điện thoại Android, `MouseRegion` không bao
/// giờ kích hoạt nên callback này đơn giản không được gọi — không lỗi, không
/// ảnh hưởng gì). Bộ đếm giờ được huỷ ở CẢ `onExit` (rê chuột ra khỏi nút)
/// LẪN `dispose()` (nút bị gỡ khỏi cây — ví dụ menu đóng lại) nên không có
/// đường nào rò rỉ.
class _NutCuonMenu extends StatefulWidget {
  const _NutCuonMenu({required this.icon, required this.onTap, this.onHoverTick});

  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onHoverTick;

  @override
  State<_NutCuonMenu> createState() => _NutCuonMenuState();
}

class _NutCuonMenuState extends State<_NutCuonMenu> {
  Timer? _henCuonLienTuc;

  void _batCuonLienTuc() {
    _henCuonLienTuc?.cancel();
    final tick = widget.onHoverTick;
    if (tick == null) return;
    _henCuonLienTuc = Timer.periodic(const Duration(milliseconds: 24), (_) => tick());
  }

  void _dungCuonLienTuc() {
    _henCuonLienTuc?.cancel();
    _henCuonLienTuc = null;
  }

  @override
  void dispose() {
    _henCuonLienTuc?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duocBam = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => _batCuonLienTuc(),
      onExit: (_) => _dungCuonLienTuc(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: duocBam ? Colors.grey.shade300 : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: 13,
            color: duocBam ? Colors.grey.shade800 : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

/// (VIỆC 3) Mục đầu tiên của cả hai menu (`_NutThemMenu`, `_NutAIMenu`): một
/// hàng gồm hai nút cuộn (lên đầu / xuống cuối) và nút tròn đỏ chữ X đóng
/// menu ngay lập tức. Dùng `value: -1` (không khớp case nào trong
/// `onSelected`) để việc bấm nút X tự đóng menu theo đúng cơ chế mặc định
/// của `PopupMenuItem` — vì đây vẫn là một `PopupMenuItem` bình thường
/// (enabled mặc định) trong cùng danh sách, không phải widget tự vẽ lồng bên
/// trong, nên KHÔNG bị ăn màu mờ và không đẩy các mục khác vào một khung
/// cuộn bó hẹp.
///
/// [controller] là bộ điều khiển cuộn THẬT của khung cuộn ở `_mucCuonDanhSach`
/// — được TẠO Ở NGOÀI, trong `itemBuilder`, và truyền tay vào ĐÂY, KHÔNG còn
/// dò tìm qua `Scrollable.maybeOf(context)` (cách cũ không đáng tin: có thể
/// tìm trúng một `Scrollable` không phải cái mình muốn, hoặc bấm không thấy
/// tác dụng vì thời điểm đo `maxScrollExtent` chưa ổn định). Cùng MỘT
/// `controller` này được gán cho `SingleChildScrollView` ở
/// `_mucCuonDanhSach`, nên hai nút ở đây chắc chắn điều khiển ĐÚNG khung cuộn
/// chứa danh sách lựa chọn.
PopupMenuItem<int> _mucDongMenu(
  ScrollController controller, {
  required String tenMenu,
  required Color mauDamTenMenu,
}) {
  void cuonToi(double dich) {
    if (!controller.hasClients) return;
    controller.animateTo(
      dich,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void nhichLen(double buoc) {
    if (!controller.hasClients) return;
    final vt = controller.position;
    controller.jumpTo((vt.pixels - buoc).clamp(0.0, vt.maxScrollExtent));
  }

  void nhichXuong(double buoc) {
    if (!controller.hasClients) return;
    final vt = controller.position;
    controller.jumpTo((vt.pixels + buoc).clamp(0.0, vt.maxScrollExtent));
  }

  return PopupMenuItem<int>(
    value: -1,
    height: 36,
    padding: EdgeInsets.zero,
    child: Container(
      // (YÊU CẦU MỚI) Tên đầy đủ của menu, cùng dòng với nút X — nền ĐẬM
      // ĐẶC (khác hẳn nền NHẠT của toàn menu, xem các nơi gọi) để phân biệt
      // rõ đây là "thanh tiêu đề", không phải một mục lựa chọn.
      color: mauDamTenMenu,
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            // Bấm vào tên không có tác dụng gì — chặn tại đây bằng
            // `GestureDetector` của chính nó (ĐÚNG mẹo `_NutCuonMenu` đã
            // dùng), không thì rơi xuống hành vi mặc định của
            // `PopupMenuItem` (toàn mục này trả về `value: -1`, tự đóng
            // menu) giống như bấm trúng X.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Text(
                tenMenu,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _NutCuonMenu(
            icon: Icons.vertical_align_top,
            onTap: () => cuonToi(0),
            onHoverTick: () => nhichLen(14),
          ),
          const SizedBox(width: 6),
          _NutCuonMenu(
            icon: Icons.vertical_align_bottom,
            onTap: () => cuonToi(
              controller.hasClients ? controller.position.maxScrollExtent : 0,
            ),
            onHoverTick: () => nhichXuong(14),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

/// (VIỆC 3) Mục thứ hai của cả hai menu: TOÀN BỘ các mục lựa chọn còn lại
/// ([muc], đã gồm cả các đường kẻ phân cách `_dividerMenu()`) gộp vào MỘT
/// `PopupMenuItem` DUY NHẤT — thay cho mỗi mục một `PopupMenuItem` riêng như
/// trước (kiến trúc khiến hai nút cuộn ở `_mucDongMenu` không lấy lại được
/// đúng khung cuộn một cách đáng tin cậy). `enabled: true` (mặc định) +
/// `padding: EdgeInsets.zero` để không bị tô mờ xám như khi dùng
/// `enabled: false`.
///
/// Bọc trong `ConstrainedBox(maxHeight: ...)` + `SingleChildScrollView`
/// (gắn [controller]) thay vì để trần: khung cuộn nội bộ SẴN CÓ của chính
/// `PopupMenuButton` (một `SingleChildScrollView` khác, bọc toàn bộ danh
/// sách mục) cho con của nó chiều cao KHÔNG GIỚI HẠN — lồng thẳng một
/// `SingleChildScrollView` khác vào đó (chiều cuộn giống hệt) sẽ ném lỗi
/// "unbounded height". Giới hạn chiều cao TỐI ĐA ở đây (một tỉ lệ màn hình,
/// có trần) vừa tránh lỗi đó, vừa giữ đúng yêu cầu "không cuộn ép vào khung
/// nhỏ nếu đủ chỗ": `Column` bên trong dùng `mainAxisSize: MainAxisSize.min`
/// nên khung tự co theo đúng chiều cao nội dung khi nội dung NGẮN hơn trần,
/// chỉ thật sự cuộn khi nội dung DÀI hơn.
PopupMenuItem<int> _mucCuonDanhSach(
  BuildContext context,
  ScrollController controller,
  List<Widget> muc,
) {
  final caoManHinh = MediaQuery.sizeOf(context).height;
  final gioiHanCao = (caoManHinh * 0.65).clamp(240.0, 560.0);
  return PopupMenuItem<int>(
    enabled: true,
    padding: EdgeInsets.zero,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: gioiHanCao),
      child: SingleChildScrollView(
        controller: controller,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: muc,
        ),
      ),
    ),
  );
}

/// Nút dấu cộng ở thanh công cụ: mở một menu sổ lên (nằm trên đỉnh nút, vì
/// nút ở sát đáy màn hình — PopupMenuButton tự né mép màn hình nên không cần
/// tự tính toán vị trí). Đa số các mục chưa gắn logic gì, chỉ là chỗ đặt
/// trước cho tính năng sau này.
class _NutThemMenu extends StatelessWidget {
  const _NutThemMenu({
    required this.rong,
    required this.khiBamBanPhim,
    required this.khiBamBoPhimNhanh,
    required this.boPhimNhanhDangMo,
    this.noiBatBoPhimNhanh = false,
    required this.khiBamChepTatCa,
    required this.khiBamChepRoiXoaTatCa,
    required this.khiBamXoaTatCa,
    required this.khiBamChonTatCaTrongMenuThem,
    required this.khiBamDanhSachPhimTat,
    required this.khiBamTimKiem,
    required this.khiMoMenu,
    required this.khiBamLuyenGoPhim,
    required this.khiBamCaiDatUngDung,
    required this.khiBamGopY,
  });

  final bool rong;

  /// Gắn với mục "Kiểu gõ bàn phím" trong danh sách.
  final VoidCallback khiBamBanPhim;

  /// Gắn với mục "Bật/Tắt bộ phím nhanh cho màn hình cảm ứng".
  final VoidCallback khiBamBoPhimNhanh;
  final bool boPhimNhanhDangMo;

  /// Thiết bị (tự đoán hoặc chọn tay) là Android/iPhone — tô đậm+xanh dương
  /// mục này để gợi ý, xem `_mucMenuThem`.
  final bool noiBatBoPhimNhanh;

  final VoidCallback khiBamChepTatCa;
  final VoidCallback khiBamChepRoiXoaTatCa;
  final VoidCallback khiBamXoaTatCa;

  /// (YÊU CẦU MỚI) Mục "Chọn tất cả" — ngay dưới "Xoá tất cả" — tạo vùng
  /// chọn toàn bộ văn bản, dùng LẠI đúng hàm của nút "All" tròn ngoài
  /// thanh công cụ (`_NutAllTron`/`_phimAoChonTatCa`), không viết lại.
  final VoidCallback khiBamChonTatCaTrongMenuThem;

  final VoidCallback khiBamDanhSachPhimTat;

  /// Mục 8b: "Tìm kiếm và thay thế" dời vào đây, đúng vị trí mà "Thêm
  /// ảnh"/"Chụp ảnh (camera)" vừa rời đi (nay ở menu "Làm việc với AI") —
  /// giữ nguyên logic cũ, chỉ đổi chỗ đặt (và đổi tên hiển thị thành "Tìm
  /// kiếm và thay thế"). Mục "Cài đặt" đã dời hẳn sang menu "Tài khoản của
  /// bạn" (tách làm hai: Cài đặt Micro / Cài đặt Hiển thị và tự động sửa —
  /// xem `_NutTaiKhoanMenu`), không còn ở đây nữa.
  final VoidCallback khiBamTimKiem;

  /// Xem `ThanhCongCu.khiMoMenuCanReset`.
  final VoidCallback khiMoMenu;

  /// (YÊU CẦU MỚI) Mục "Luyện gõ phím bằng 10 ngón tay" — mở modal mời bấm
  /// link tìm kiếm Google.
  final VoidCallback khiBamLuyenGoPhim;

  /// (YÊU CẦU MỚI) Mục "Cài đặt Ứng dụng vào Thiết bị" — nổi bật nền xanh
  /// dương đậm, ngay phía trên "Chia sẻ ứng dụng...".
  final VoidCallback khiBamCaiDatUngDung;

  /// (YÊU CẦU MỚI) Mục "Góp ý thêm, báo lỗi về ứng dụng" — mở `moModalGopY`.
  final VoidCallback khiBamGopY;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Thêm',
      child: Tooltip(
        message: 'Thêm',
        child: PopupMenuButton<int>(
          onOpened: khiMoMenu,
          padding: EdgeInsets.zero,
          splashRadius: 20,
          // (YÊU CẦU MỚI) Nền của menu "Thêm lựa chọn" — đỏ NHẠT, phân biệt
          // với hai menu khác (AI: xanh lá nhạt, Tài khoản: vàng nhạt).
          color: Colors.red.shade50,
          child: rong
              ? const _KhungNutRong(
                  bieuTuong: Icons.add_circle_outline,
                  nhan: 'Thêm lựa chọn',
                )
              : Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  // Nền trắng riêng — cùng lý do với NutNho.
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_circle_outline,
                      size: 20, color: Color(0xFF5F6368)),
                ),
          onSelected: (gia) {
            switch (gia) {
              case 3:
                khiBamBoPhimNhanh();
                break;
              case 4:
                khiBamBanPhim();
                break;
              case 23:
                khiBamDanhSachPhimTat();
                break;
              case 20:
                khiBamChepTatCa();
                break;
              case 21:
                khiBamChepRoiXoaTatCa();
                break;
              case 22:
                khiBamXoaTatCa();
                break;
              case 28:
                khiBamChonTatCaTrongMenuThem();
                break;
              case 25:
                khiBamTimKiem();
                break;
              case 5:
                khiBamLuyenGoPhim();
                break;
              case 29:
                khiBamCaiDatUngDung();
                break;
              case 7:
                khiBamGopY();
                break;
            }
          },
          // (VIỆC 3) Một `ScrollController` MỚI mỗi lần menu mở — `itemBuilder`
          // là một closure được GỌI LẠI mỗi lần bấm nút mở menu, nên biến cục
          // bộ này tồn tại đúng trong phạm vi vòng đời của route hiện tại,
          // không lẫn giữa các lần mở menu khác nhau. Dùng CHUNG giữa nút
          // cuộn (`_mucDongMenu`, đọc để `animateTo`/`jumpTo`) và khung cuộn
          // thật (`_mucCuonDanhSach`, gán `controller:`).
          itemBuilder: (ctx) {
            final cuon = ScrollController();
            return [
              // Nút X đỏ đóng menu + hai nút cuộn — luôn ở đầu danh sách,
              // KHÔNG cuộn theo phần còn lại.
              _mucDongMenu(cuon, tenMenu: 'Thêm lựa chọn', mauDamTenMenu: Colors.red.shade200),
              _mucCuonDanhSach(ctx, cuon, [
                // Ba mục đầu — dời từ ba nút riêng trên thanh công cụ trên
                // (Sao chép tất cả/Xoá tất cả) xuống đây, cộng thêm mục gộp
                // mới "Sao chép rồi xoá tất cả".
                _mucMenuThem(20, 'Sao chép tất cả'),
                _mucMenuThem(21, 'Sao chép rồi xoá tất cả'),
                _mucMenuThem(22, 'Xoá tất cả'),
                _mucMenuThem(28, 'Chọn tất cả'),
                _dividerMenu(),
                // "Thêm ảnh"/"Chụp ảnh (camera)" đã dời sang menu "Làm việc
                // với AI" (đổi tên "Chuyển hình ảnh thành văn bản") — "Cài
                // đặt" và "Tìm kiếm và thay thế" (trước đây là hai nút riêng
                // ngoài thanh công cụ) vào thay đúng vị trí này.
                _mucMenuThem(25, 'Tìm kiếm và thay thế'),
                _dividerMenu(),
                _mucMenuThem(
                  3,
                  boPhimNhanhDangMo
                      ? 'Tắt Bộ phím nhanh cho màn hình cảm ứng'
                      : 'Bật Bộ phím nhanh cho màn hình cảm ứng',
                  noiBat: !boPhimNhanhDangMo && noiBatBoPhimNhanh,
                ),
                _mucMenuThem(4, 'Kiểu gõ bàn phím'),
                _mucMenuThem(23, 'Danh sách phím tắt'),
                _mucMenuThem(5, 'Luyện gõ phím bằng 10 ngón tay'),
                _dividerMenu(),
                // (YÊU CẦU MỚI) Nổi bật nền xanh dương đậm — thu hút ánh
                // nhìn, ngay phía TRÊN "Chia sẻ ứng dụng...".
                _mucMenuThemNoiBatXanh(29, 'Cài đặt Ứng dụng vào Thiết bị'),
                _mucMenuThem(6, 'Chia sẻ ứng dụng này đến với mọi người'),
                _mucMenuThem(7, 'Góp ý thêm, báo lỗi về ứng dụng'),
                _mucMenuThem(8, 'Donate ủng hộ-cảm ơn tác giả'),
              ]),
            ];
          },
        ),
      ),
    );
  }
}

/// Menu thả xuống của nút "Tài khoản của bạn" — cùng cơ chế với
/// `_NutThemMenu`/`_NutAIMenu`. "Điều khoản sử dụng"/"Bảo mật và quyền
/// riêng tư" mở `TrangDieuKhoan`/`TrangBaoMat` (toàn màn hình, nội dung
/// chọn/copy được). "Language - Ngôn ngữ" vẫn CHƯA gắn logic, chờ gắn sau.
class _NutTaiKhoanMenu extends StatelessWidget {
  const _NutTaiKhoanMenu({
    required this.rong,
    required this.khiBamCaiDatMicro,
    required this.khiBamCaiDatHienThi,
    required this.khiBamTuDienChinhTa,
    required this.khiBamTuDienNhapLieuNhanh,
    required this.khiBamBoNhoTam,
    required this.khiBamTroChuyen,
    required this.khiMoMenu,
    required this.khiBamDangNhapGoogle,
    required this.khiBamKhoiDongTep,
    required this.khiBamDieuKhoan,
    required this.khiBamBaoMat,
    required this.khiBamQuanLyGopY,
    required this.khiBamDanhSachUser,
    this.tenHienThiDaDangNhap,
    this.emailDaDangNhap,
    this.urlAnhDaiDienDaDangNhap,
  });

  /// Mục "Đăng nhập tài khoản" — khi NÀO đang đăng nhập (xem
  /// [tenHienThiDaDangNhap]) thì tự đổi nhãn/logic thành "Đăng xuất"; nơi
  /// gọi (`trang_soan_thao.dart`) tự quyết đăng nhập hay đăng xuất dựa theo
  /// đúng trạng thái đang có, menu này không tự giữ trạng thái.
  final VoidCallback khiBamDangNhapGoogle;

  /// (YÊU CẦU MỚI) Mục "Khi khởi động App: Mở tệp..." — mở `moModalKhoiDong`.
  final VoidCallback khiBamKhoiDongTep;

  /// (YÊU CẦU MỚI) Mục "Điều khoản sử dụng" — mở `TrangDieuKhoan`.
  final VoidCallback khiBamDieuKhoan;

  /// (YÊU CẦU MỚI) Mục "Bảo mật và quyền riêng tư" — mở `TrangBaoMat`.
  final VoidCallback khiBamBaoMat;

  /// (YÊU CẦU MỚI — chỉ admin) Mục "Các ý kiến góp ý, báo lỗi của user" —
  /// mở `moModalQuanLyGopY`. Chỉ hiện trong danh sách khi
  /// `laAdminEmail(emailDaDangNhap)`, xem [build].
  final VoidCallback khiBamQuanLyGopY;

  /// (YÊU CẦU MỚI — chỉ admin) Mục "Các User đã đăng nhập" — mở
  /// `moModalDanhSachUser`. Cùng điều kiện hiện với [khiBamQuanLyGopY].
  final VoidCallback khiBamDanhSachUser;

  /// Khác `null` nghĩa là ĐANG đăng nhập — tên/avatar hiện thêm ở dòng CUỐI
  /// CÙNG của menu. Cả ba đều `null` cùng lúc khi chưa đăng nhập.
  final String? tenHienThiDaDangNhap;
  final String? emailDaDangNhap;
  final String? urlAnhDaiDienDaDangNhap;

  final bool rong;
  final VoidCallback khiBamCaiDatMicro;
  final VoidCallback khiBamCaiDatHienThi;

  /// Mục "Cài đặt từ điển sửa lỗi chính tả" — mở `moModalTuDienChinhTa`.
  final VoidCallback khiBamTuDienChinhTa;

  /// (YÊU CẦU MỚI) Mục "Cài đặt Từ điển nhập liệu nhanh" — mở
  /// `moModalTuDienNhapLieuNhanh`.
  final VoidCallback khiBamTuDienNhapLieuNhanh;

  /// Mục "Bộ nhớ tạm để dán văn bản" — mở `moModalBoNhoTam`.
  final VoidCallback khiBamBoNhoTam;

  /// Mục "Trò chuyện" — dời vào ĐÂY từ thanh công cụ ngoài (trước kia là
  /// một nút riêng cạnh "Xem thêm lựa chọn"), nằm ngay phía trên "Đăng
  /// nhập tài khoản", gần cuối menu.
  final VoidCallback khiBamTroChuyen;

  /// Xem `ThanhCongCu.khiMoMenuCanReset`.
  final VoidCallback khiMoMenu;

  @override
  Widget build(BuildContext context) {
    // Hai icon (hình người + bánh răng) LUÔN đi sát nhau, ở cả màn hình hẹp
    // lẫn rộng — chỉ khác là màn hình rộng còn thêm tên "Tài khoản-Cài đặt"
    // bên cạnh, màn hình hẹp chỉ có hai icon, không chữ.
    const haiIcon = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_circle, size: 18, color: Color(0xFF5F6368)),
        Icon(Icons.settings, size: 14, color: Color(0xFF5F6368)),
      ],
    );
    return Semantics(
      button: true,
      label: 'Tài khoản và Cài đặt',
      child: Tooltip(
        message: 'Tài khoản và Cài đặt',
        child: PopupMenuButton<int>(
          onOpened: khiMoMenu,
          padding: EdgeInsets.zero,
          splashRadius: 20,
          // (YÊU CẦU MỚI) Nền của menu "Tài khoản và Cài đặt" — vàng NHẠT.
          color: Colors.yellow.shade50,
          // (YÊU CẦU MỚI) Đã đăng nhập — nền nút đổi sang xanh lá nhạt, báo
          // ngay không cần mở menu ra mới biết.
          child: rong
              ? Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: tenHienThiDaDangNhap != null
                        ? const Color(0xFFE6F4EA)
                        : Colors.white,
                    border: Border.all(color: const Color(0xFFDADCE0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      haiIcon,
                      SizedBox(width: 6),
                      Text('Tài khoản-Cài đặt',
                          style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                    ],
                  ),
                )
              : Container(
                  width: 42,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tenHienThiDaDangNhap != null
                        ? const Color(0xFFE6F4EA)
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: haiIcon,
                ),
          onSelected: (gia) {
            switch (gia) {
              case 1:
                khiBamCaiDatMicro();
                break;
              case 2:
                khiBamCaiDatHienThi();
                break;
              case 9:
                khiBamTuDienChinhTa();
                break;
              case 26:
                khiBamTuDienNhapLieuNhanh();
                break;
              case 10:
                khiBamBoNhoTam();
                break;
              case 8:
                khiBamTroChuyen();
                break;
              case 5:
                khiBamDangNhapGoogle();
                break;
              case 27:
                khiBamKhoiDongTep();
                break;
              case 3:
                khiBamDieuKhoan();
                break;
              case 4:
                khiBamBaoMat();
                break;
              case 30:
                khiBamQuanLyGopY();
                break;
              case 31:
                khiBamDanhSachUser();
                break;
            }
          },
          itemBuilder: (ctx) {
            final daDangNhap = tenHienThiDaDangNhap != null;
            final cuon = ScrollController();
            return [
              _mucDongMenu(cuon,
                  tenMenu: 'Tài khoản và Cài đặt',
                  mauDamTenMenu: Colors.yellow.shade200),
              _mucCuonDanhSach(ctx, cuon, [
                // Hai mục mới — CHƯA gắn logic (chờ gắn sau), tạm đặt ở đầu
                // menu, cùng kiểu dòng với "Cài đặt Micro"/"Cài đặt Hiển thị
                // và tự động sửa" bên dưới.
                _mucMenuThem(6, 'Language - Ngôn ngữ'),
                _mucMenuThem(27, 'Khi khởi động App: Mở tệp...'),
                _dividerMenu(),
                _mucMenuThem(1, 'Cài đặt Micro'),
                _mucMenuThem(2, 'Cài đặt Hiển thị và tự động sửa'),
                _mucMenuThem(9, 'Cài đặt từ điển sửa lỗi chính tả'),
                _mucMenuThem(26, 'Cài đặt Từ điển nhập liệu nhanh'),
                _mucMenuThem(10, 'Cài đặt Bộ nhớ tạm để dán văn bản'),
                _dividerMenu(),
                _mucMenuThem(3, 'Điều khoản sử dụng'),
                _mucMenuThem(4, 'Bảo mật và quyền riêng tư'),
                _dividerMenu(),
                // "Trò chuyện" dời từ thanh công cụ ngoài vào đây, ngay
                // phía TRÊN "Đăng nhập tài khoản" — cùng nhóm, không có
                // đường kẻ chia giữa hai mục này.
                _mucMenuThem(8, 'Trò chuyện'),
                _mucMenuThem(5, daDangNhap ? 'Đăng xuất' : 'Đăng nhập bằng tài khoản Google'),
                // (YÊU CẦU MỚI — chỉ admin) Hai mục quản lý, CHỈ hiện khi
                // đang đăng nhập ĐÚNG một trong hai email admin — đây chỉ
                // là lớp ẨN/HIỆN giao diện, quyền THẬT nằm ở luật Firestore
                // (xem `quyen_admin.dart`).
                if (daDangNhap && laAdminEmail(emailDaDangNhap)) ...[
                  _mucMenuThem(30, 'Các ý kiến góp ý, báo lỗi của user'),
                  _mucMenuThem(31, 'Các User đã đăng nhập'),
                ],
                // (YÊU CẦU MỚI) Đang đăng nhập — hiện tên + avatar của tài
                // khoản ở dòng CUỐI CÙNG của menu, không bấm được (chỉ để
                // xem, đăng xuất đã có mục riêng ngay phía trên).
                if (daDangNhap) _dongTaiKhoanDaDangNhap(),
              ]),
            ];
          },
        ),
      ),
    );
  }

  Widget _dongTaiKhoanDaDangNhap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: urlAnhDaiDienDaDangNhap != null
                ? NetworkImage(urlAnhDaiDienDaDangNhap!)
                : null,
            child: urlAnhDaiDienDaDangNhap == null
                ? const Icon(Icons.person, size: 16, color: Color(0xFF9AA0A6))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tenHienThiDaDangNhap ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (emailDaDangNhap != null)
                  Text(
                    emailDaDangNhap!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu thả xuống của nút "Làm việc với AI" — cùng cơ chế với
/// `_NutThemMenu` (PopupMenuButton tự neo ngay phía trên nút vì nút nằm sát
/// đáy màn hình). "Chuyển hình ảnh thành văn bản", "Chụp ảnh (camera)",
/// "Chuyển file âm thanh thành văn bản", "Tóm tắt toàn văn", "Mở rộng toàn
/// văn", "Viết lại cho hay hơn", "Trò chuyện về văn bản này" và "Cài đặt
/// nút "Kiểm tra toàn văn"" đều đã gọi callback thật — mọi mục trong menu
/// này giờ có logic thật, không còn chỗ đặt trước nào nữa.
class _NutAIMenu extends StatelessWidget {
  const _NutAIMenu({
    required this.rong,
    required this.khiBamCaiDatKiemTraToanVan,
    required this.khiBamKiemTraToanVan,
    required this.khiBamKiemTraChinhTaToanVan,
    required this.khiBamKiemTraDauCauToanVan,
    required this.khiBamChuyenFileAmThanh,
    required this.khiBamChuyenAnhThanhVanBan,
    required this.khiBamChupAnh,
    required this.khiBamTomTatToanVan,
    required this.khiBamMoRongToanVan,
    required this.khiBamVietLaiToanVan,
    required this.khiBamTroChuyenVeVanBan,
    required this.layDoanVanDangChon,
    required this.coVungChonThatSu,
    required this.epToanVanKhiCoVungChon,
    required this.khiBamDoiCheDoLamViec,
    required this.khoaMenuAI,
    required this.khiMoMenu,
    required this.khiDongMenu,
  });

  /// Xem `ThanhCongCu.khiMoMenuCanReset`.
  final VoidCallback khiMoMenu;

  /// (SỬA LỖI — vùng chọn văn bản "biến mất" khi mở menu này) Mở menu làm ô
  /// soạn thảo MẤT tiêu điểm, nên Flutter ngừng vẽ màu nổi vùng chọn (vẫn
  /// giữ ĐÚNG vùng chọn trong state, chỉ là KHÔNG VẼ) — gọi lại ngay sau khi
  /// chọn một mục, để tiêu điểm (và màu vẽ vùng chọn) quay lại như cũ. Dùng
  /// lại ĐÚNG hàm `_giuFocusOChuSauKhiBam` đã có sẵn cho Copy/Cắt/Dán/All.
  final VoidCallback khiDongMenu;

  final bool rong;
  final VoidCallback khiBamCaiDatKiemTraToanVan;

  /// Mục 8c: "Kiểm tra toàn văn" dời từ một nút riêng ngoài thanh công cụ
  /// vào đây, giữ nguyên logic thật.
  final VoidCallback khiBamKiemTraToanVan;

  /// Hai mục CHỈ MỘT PHẦN của "Kiểm tra toàn văn" — CHỈ chính tả / CHỈ dấu
  /// câu, đặt ngay TRÊN mục đó trong menu.
  final VoidCallback khiBamKiemTraChinhTaToanVan;
  final VoidCallback khiBamKiemTraDauCauToanVan;

  /// Mục "Chuyển file âm thanh thành văn bản" — mở bộ chọn file, gửi cho
  /// cùng máy chủ/luồng AI đang dùng cho ghi âm trong app (nay chạy qua
  /// Groq), rồi hiện modal kết quả kèm nút Huỷ/Chèn.
  final VoidCallback khiBamChuyenFileAmThanh;

  /// Mục "Chuyển hình ảnh thành văn bản" — ĐÚNG LUỒNG với mục âm thanh ở
  /// trên (chọn tệp, gửi AI, modal kết quả sửa được + Chọn vị trí để chèn),
  /// chỉ khác gửi qua Gemini thay vì Groq.
  final VoidCallback khiBamChuyenAnhThanhVanBan;

  /// Mục "Chụp ảnh (camera)" — mở camera thiết bị rồi chuyển hoá y hệt luồng
  /// "Chuyển hình ảnh thành văn bản" ở trên.
  final VoidCallback khiBamChupAnh;

  /// Mục "Tóm tắt toàn văn" — mở modal "Chọn kiểu tóm tắt" (theo %/theo câu
  /// lệnh tự do/cả hai) rồi gọi Gemini, xong hiện modal kết quả với nút
  /// "Thay thế toàn bộ văn bản".
  final VoidCallback khiBamTomTatToanVan;

  /// Mục "Mở rộng toàn văn" — ĐÚNG KHUÔN "Tóm tắt toàn văn" ở trên, chỉ đảo
  /// ngược ý nghĩa (mở rộng thêm thay vì rút gọn).
  final VoidCallback khiBamMoRongToanVan;

  /// Mục "Viết lại cho hay hơn" — modal chỉ có một ô câu lệnh tự do (có
  /// thể để trống) rồi gọi Gemini, cùng modal kết quả với nút "Thay thế
  /// toàn bộ văn bản" như tóm tắt/mở rộng.
  final VoidCallback khiBamVietLaiToanVan;

  /// Mục "Trò chuyện về văn bản này" — mở màn hình chat toàn màn hình. RIÊNG
  /// biệt với nút "Trò chuyện" ở thanh công cụ dưới (`ThanhCongCu.khiBamTroChuyen`
  /// — nút đó hiện là chỗ đặt trước "đang nâng cấp", KHÔNG liên quan tới
  /// mục này).
  final VoidCallback khiBamTroChuyenVeVanBan;

  /// Có vùng chọn hay không ở trang soạn thảo — quyết định tên hiển thị của
  /// từng mục ("...toàn văn" → "...đoạn văn này"/"...đoạn văn đã chọn").
  final String? Function() layDoanVanDangChon;

  /// Có vùng chọn THẬT SỰ hay không — xem giải thích ở `ThanhCongCu`.
  final bool Function() coVungChonThatSu;
  final bool epToanVanKhiCoVungChon;
  final VoidCallback khiBamDoiCheDoLamViec;
  final GlobalKey<PopupMenuButtonState<int>> khoaMenuAI;

  @override
  Widget build(BuildContext context) {
    final noiBat = coVungChonThatSu();
    return Semantics(
      button: true,
      label: 'Làm việc với AI',
      child: Tooltip(
        message: 'Làm việc với AI',
        child: PopupMenuButton<int>(
          key: khoaMenuAI,
          onOpened: khiMoMenu,
          // (SỬA LỖI — màu tô vùng chọn vẫn mất nếu ĐÓNG menu mà KHÔNG chọn
          // mục nào, ví dụ bấm ra ngoài) `onSelected` chỉ chạy khi có chọn
          // mục; `onCanceled` lo phần còn lại.
          onCanceled: khiDongMenu,
          padding: EdgeInsets.zero,
          splashRadius: 20,
          // (YÊU CẦU MỚI) Nền của menu "Làm việc với AI" — xanh lá NHẠT.
          color: Colors.green.shade50,
          child: rong
              ? _KhungNutRong(
                  bieuTuong: Icons.smart_toy_outlined,
                  nhan: 'Làm việc với AI',
                  mau: noiBat ? Colors.white : const Color(0xFF5F6368),
                  mauNen: noiBat ? const Color(0xFF1A73E8) : Colors.white,
                )
              : Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: noiBat ? const Color(0xFF1A73E8) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.smart_toy_outlined,
                      size: 20, color: noiBat ? Colors.white : const Color(0xFF5F6368)),
                ),
          onSelected: (gia) {
            if (gia == 5) khiBamCaiDatKiemTraToanVan();
            if (gia == 9) khiBamKiemTraToanVan();
            if (gia == 10) khiBamKiemTraChinhTaToanVan();
            if (gia == 11) khiBamKiemTraDauCauToanVan();
            if (gia == 8) khiBamChuyenFileAmThanh();
            if (gia == 6) khiBamChuyenAnhThanhVanBan();
            if (gia == 7) khiBamChupAnh();
            if (gia == 2) khiBamTomTatToanVan();
            if (gia == 3) khiBamMoRongToanVan();
            if (gia == 4) khiBamVietLaiToanVan();
            if (gia == 1) khiBamTroChuyenVeVanBan();
            if (gia == 12) khiBamDoiCheDoLamViec();
            khiDongMenu();
          },
          // (VIỆC 3) Xem chú thích ở `_NutThemMenu` — cùng cơ chế: một
          // `ScrollController` mới mỗi lần menu mở, dùng chung giữa nút cuộn
          // và khung cuộn thật.
          itemBuilder: (ctx) {
            final cuon = ScrollController();
            // Có vùng chọn hay không QUYẾT ĐỊNH NGAY LÚC MỞ MENU tên hiển
            // thị của từng mục ("...toàn văn" → "...đoạn văn này"/"...đoạn
            // văn đã chọn") — đọc MỘT LẦN ở đây, dùng lại cho mọi mục bên
            // dưới, vì vùng chọn không thể đổi trong lúc menu đang mở
            // (người dùng đang bận điều hướng menu, không chạm được vào ô
            // soạn thảo phía sau).
            final coDoanChon = layDoanVanDangChon() != null;
            return [
              // Nút X đỏ đóng menu + hai nút cuộn — luôn ở đầu danh sách,
              // KHÔNG cuộn theo phần còn lại.
              _mucDongMenu(cuon, tenMenu: 'Làm việc với AI', mauDamTenMenu: Colors.green.shade200),
              _mucCuonDanhSach(ctx, cuon, [
                // Ba mục đầu menu — "Chuyển hình ảnh thành văn bản" dời từ
                // menu "+ Thêm lựa chọn" sang đây (đổi tên mục ảnh) — đã gắn
                // logic thật, ĐÚNG LUỒNG với "Chuyển file âm thanh thành văn
                // bản" (xem `_chonVaChuyenAnhThanhVanBan`/
                // `_chonVaChuyenFileAmThanh` trong `trang_soan_thao.dart`).
                // "Chụp ảnh (camera)" cũng đã gắn logic thật — xem
                // `_chupVaChuyenAnhThanhVanBan` (mở camera thay vì bộ chọn
                // tệp, còn lại y hệt). "Tóm tắt toàn văn" đã gắn logic thật
                // — xem `_moModalChonKieuTomTat` (mở modal chọn kiểu trước
                // khi gọi Gemini, kết quả có nút "Thay thế toàn bộ văn
                // bản").
                _mucMenuThem(6, 'Chuyển hình ảnh thành văn bản'),
                _mucMenuThem(7, 'Chụp ảnh (camera)'),
                _mucMenuThem(8, 'Chuyển file âm thanh thành văn bản'),
                // Vị trí 4 — CHỈ hiện khi có vùng chọn THẬT SỰ (không bị ảnh
                // hưởng bởi chính công tắc này — nếu không, bấm ép "toàn
                // bộ văn bản" xong sẽ tự làm mục này biến mất, không bấm
                // lại được để quay về "đoạn văn đang chọn" nữa). Công tắc
                // đảo NGAY [epToanVanKhiCoVungChon], khiến mọi mục bên
                // dưới tự đổi tên theo (dùng `coDoanChon` đã tính ở trên,
                // vốn đã tôn trọng công tắc này).
                if (coVungChonThatSu())
                  _DongMenuCoTheBam(
                    gia: 12,
                    height: 34,
                    child: Text(
                      epToanVanKhiCoVungChon
                          ? 'Làm việc với Đoạn văn đang chọn'
                          : 'Làm việc với Toàn bộ văn bản',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: epToanVanKhiCoVungChon
                            ? _mauTimNguCanhDoanChon
                            : const Color(0xFF0B3D91),
                      ),
                    ),
                  ),
                _dividerMenu(),
                _mucMenuThem(
                  1,
                  coDoanChon ? 'Trò chuyện về đoạn văn đã chọn' : 'Trò chuyện về văn bản này',
                  mauChu: coDoanChon ? _mauTimNguCanhDoanChon : null,
                ),
                _mucMenuThem(
                  2,
                  coDoanChon ? 'Tóm tắt đoạn văn này' : 'Tóm tắt toàn văn',
                  mauChu: coDoanChon ? _mauTimNguCanhDoanChon : null,
                ),
                _mucMenuThem(
                  3,
                  coDoanChon ? 'Mở rộng đoạn văn này' : 'Mở rộng toàn văn',
                  mauChu: coDoanChon ? _mauTimNguCanhDoanChon : null,
                ),
                _mucMenuThem(
                  4,
                  'Viết lại cho hay hơn',
                  mauChu: coDoanChon ? _mauTimNguCanhDoanChon : null,
                ),
                _dividerMenu(),
                // Hai mục CHỈ MỘT PHẦN của "Kiểm tra toàn văn" — ĐÚNG
                // NGUYÊN cơ chế đó (cùng popup, cùng cách vẽ gạch đỏ lượn
                // sóng/tô dấu câu), chỉ khác việc AI CHỈ tìm đúng một loại
                // lỗi. Đặt ngay TRÊN "Kiểm tra toàn văn" theo đúng thứ tự
                // yêu cầu.
                _mucMenuThem(
                  10,
                  coDoanChon ? 'Kiểm tra lỗi chính tả đoạn văn này' : 'Kiểm tra lỗi chính tả toàn văn',
                  mauChu: coDoanChon ? _mauTimNguCanhDoanChon : null,
                ),
                _mucMenuThem(
                  11,
                  coDoanChon ? 'Kiểm tra dấu câu đoạn văn này' : 'Kiểm tra dấu câu toàn văn',
                  mauChu: coDoanChon ? _mauTimNguCanhDoanChon : null,
                ),
                // "Kiểm tra toàn văn" dời từ một nút riêng ngoài thanh công
                // cụ vào ngay TRÊN mục cài đặt của nó — giữ màu xanh lá +
                // icon dấu tích ở đây; mục cài đặt bên dưới không cần tô màu
                // lặp lại nữa.
                _DongMenuCoTheBam(
                  gia: 9,
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.task_alt, size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        coDoanChon ? 'Kiểm tra đoạn văn này' : 'Kiểm tra toàn văn',
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ),
                _DongMenuCoTheBam(
                  gia: 5,
                  height: 34,
                  child: const Text('Cài đặt nút "Kiểm tra toàn văn"'),
                ),
              ]),
            ];
          },
        ),
      ),
    );
  }
}
