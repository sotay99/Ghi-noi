// Trang soạn thảo — một trang văn bản trắng, gõ phím và nói bằng micro cùng
// lúc. Mọi chữ — dù đến từ bàn phím hay từ micro — đều rơi vào đúng vị trí
// con trỏ. Micro không tắt khi người dùng gõ phím; ngược lại, gõ phím ngắt
// hẳn micro trong một giây rồi tự bật lại.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb, ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'bo_nho_tam_dan_van_ban.dart';
import 'cai_dat.dart';
import 'dang_nhap_google.dart';
import 'doan_thiet_bi.dart';
import 'mo_lien_ket_ngoai.dart';
import 'nghe_resize_trinh_duyet.dart';
import 'dinh_dang_clip.dart';
import 'ghi_am_the.dart';
import 'the_tich_chon.dart';
import 'gui_ghi_am_gemini.dart';
import 'gui_anh_gemini.dart';
import 'gui_mo_rong_gemini.dart';
import 'gui_tom_tat_gemini.dart';
import 'gui_viet_lai_gemini.dart';
import 'man_hinh_tro_chuyen.dart';
import 'tin_nhan_tro_chuyen.dart';
import 'canh_bao_roi_trang.dart';
import 'kho_du_lieu.dart';
import 'khoi_dong_lai_app.dart';
import 'kiem_tra_cap_nhat.dart';
import 'canh_bao_han_muc_ai.dart';
import 'modal_bao_mat.dart';
import 'modal_cai_dat_ung_dung.dart';
import 'modal_canh_bao_api.dart';
import 'modal_danh_sach_user.dart';
import 'modal_donate.dart';
import 'modal_gop_y.dart';
import 'modal_quan_ly_gop_y.dart';
import 'quyen_admin.dart';
import 'modal_dieu_khoan.dart';
import 'modal_luyen_go_phim.dart';
import 'tu_dien_dam_may.dart';
import 'theo_doi_tap_doi_phim.dart';
import 'vong_song_am.dart';
import 'mau_co_ban.dart';
import 'kiem_tra_chinh_ta.dart';
import 'kiem_tra_toan_van.dart';
import 'loai_thiet_bi.dart';
import 'lua_chon_phim_tat.dart';
import 'luu_va_chia_se_tep.dart';
import 'modal_chia_se_tep.dart';
import 'modal_thong_tin_muc.dart';
import 'tai_ve_ghi_chu.dart';
import 'dinh_dang_doan_van_tu_dien.dart';
import 'man_hinh_cai_dat.dart';
import 'man_hinh_thu_muc.dart';
import 'mau_phim_tu_dien_nhap_lieu_nhanh.dart';
import 'modal_bo_nho_tam.dart';
import 'modal_cai_dat_kiem_tra_toan_van.dart';
import 'modal_khoi_dong.dart';
import 'modal_tu_dien_chinh_ta.dart';
import 'modal_tu_dien_nhap_lieu_nhanh.dart';
import 'modal_nghe_lai_ghi_am.dart';
import 'mo_hinh.dart';
import 'ngon_ngu.dart';
import 'chuoi_da_ngon_ngu.dart';
import 'phien_ban_web_day_du.dart';
import 'the_ghi_am.dart';
import 'thanh_cong_cu.dart';
import 'thong_bao_giua.dart';
import 'trang_huong_dan.dart';

/// Một từ khớp "Từ điển sửa lỗi chính tả của bạn" tìm được trong bài —
/// [thayThe] CHÍNH LÀ `CapTuDien.thayThe` tại lúc quét (rỗng nghĩa là "đề
/// xuất xoá", không phải thay bằng chữ nào khác — xem `CapTuDien`). Giữ lại
/// [tu] (chữ THẬT tại vị trí này) để còn kiểm tra văn bản có đổi từ lúc quét
/// tới lúc bấm hay không, giống `LoiChinhTa.tu`.
class _LoiTuDien {
  _LoiTuDien({
    required this.batDau,
    required this.ketThuc,
    required this.tu,
    required this.dsThayThe,
  });

  final int batDau;
  final int ketThuc;
  final String tu;

  /// Tối đa 3 đề xuất thay thế ("thứ nhất/hai/ba", đúng thứ tự khai trong
  /// `CapTuDien.dsThayThe`) — RỖNG nghĩa là "đề xuất xoá".
  final List<String> dsThayThe;

  /// Đề xuất THỨ NHẤT — dùng cho "Chấp nhận tất cả đề xuất của từ điển"
  /// (luôn chỉ áp dụng đề xuất đầu tiên) và mọi chỗ cũ chỉ cần MỘT đề xuất.
  String get thayThe => dsThayThe.isEmpty ? '' : dsThayThe.first;
}

/// (YÊU CẦU MỚI) Một đoạn TRÔNG NHƯ LINK tìm được trong bài — [tu] là chữ
/// THẬT tại vị trí này lúc quét (để so khi áp dụng, giống `_LoiTuDien.tu`).
class _VungLienKet {
  _VungLienKet({required this.batDau, required this.ketThuc, required this.tu});
  final int batDau;
  final int ketThuc;
  final String tu;
}

/// Một vùng chữ AI cho là "không phù hợp" (câu từ lủng củng, lạc đề, thừa ý,
/// lặp lại, quá nhiều lỗi chính tả, hoặc nên thay bằng đoạn khác hay hơn).
/// Đoạn GỐC [batDauGoc, ketThucGoc) và đoạn ĐỀ XUẤT [batDauDeXuat,
/// ketThucDeXuat) đều là chữ THẬT nằm trong văn bản — đoạn đề xuất được chèn
/// ngay sau đoạn gốc lúc áp dụng kết quả AI, "nằm cạnh nhau" đúng như yêu cầu.
class _VungKhongPhuHop {
  _VungKhongPhuHop({
    required this.batDauGoc,
    required this.ketThucGoc,
    required this.batDauDeXuat,
    required this.ketThucDeXuat,
  });

  int batDauGoc;
  int ketThucGoc;
  int batDauDeXuat;
  int ketThucDeXuat;

  /// null = còn chờ người dùng quyết định (gốc đỏ gạch giữa, đề xuất xanh
  /// gạch chân, đề xuất bấm được). 'xanh'/'do' = đã quyết định, đang nhấp
  /// nháy giữa màu đó và màu chữ thường trong 4 giây trước khi hoá chữ đen.
  String? nhapNhayMau;
  bool sangMau = true;
  Timer? henNhapNhay;
}

/// Một vùng chữ AI đề xuất xoá hẳn.
class _VungCanXoa {
  _VungCanXoa({required this.batDau, required this.ketThuc});

  int batDau;
  int ketThuc;
  bool dangNhapNhay = false;
  bool sangMau = true;
  Timer? henNhapNhay;
}

/// Một vùng dấu câu AI vừa tự chèn thêm (mục 3) — nhấp nháy NỀN xanh dương
/// trong đúng 4 giây rồi tự hoá bình thường, không cần lưu trạng thái lâu
/// dài (chỉ là hiệu ứng thị giác tạm thời ngay sau khi AI trả lời).
class _VungDauCauMoi {
  _VungDauCauMoi({required this.batDau, required this.ketThuc});
  int batDau;
  int ketThuc;
  bool sangMau = true;
  Timer? henNhapNhay;
}

/// (VIỆC 4) Một vùng đang chạy hiệu ứng nhấp nháy nền gradient đỏ→vàng ĐÚNG
/// 1 GIÂY cho "Thay chỗ này"/"Tất cả" trong thanh Thay thế — TÁI DÙNG hệt
/// pattern `Timer.periodic` đã có ở `_VungCanXoa`/`_VungDauCauMoi` phía trên,
/// chỉ đổi thời lượng và màu/vị trí vẽ (xem `_VeHieuUngThayThe`). `laXoa`
/// phân biệt hai luồng (VIỆC 4a/4b): `false` = đang thay (chữ MỚI đã hiện
/// ngay, [batDau, ketThuc) là vùng chữ mới); `true` = đang xoá (chữ CŨ còn
/// nguyên trong lúc chờ, [batDau, ketThuc) là vùng chữ cũ sắp mất).
class _VungHieuUngThayThe {
  _VungHieuUngThayThe({required this.batDau, required this.ketThuc, required this.laXoa});
  int batDau;
  int ketThuc;
  final bool laXoa;
  bool sangMau = true;
  Timer? henNhapNhay;
}

/// Một khoảng chữ cần vẽ với kiểu riêng — bước trung gian để gộp cả ba nguồn
/// (lỗi chính tả, đoạn không phù hợp, đoạn cần xoá) thành một danh sách duy
/// nhất trước khi dựng TextSpan.
/// true nếu ký tự [kyTu] (đúng MỘT ký tự) hợp lệ cho "chữ trên" (treMu):
/// chữ cái La-tinh thường a-z (0x61-0x7A), số 0-9 (0x30-0x39), hoặc dấu cách
/// (0x20 — dấu cách không có glyph superscript riêng nên không bị ảnh hưởng
/// bởi giới hạn font, LUÔN được coi là hợp lệ để không ngắt vùng treMu một
/// cách vô lý mỗi khi gõ khoảng trắng).
/// `FontFeature.enable('sups')` chỉ được font hệ thống (Roboto Android) hỗ
/// trợ tốt với đúng tập này — chữ HOA, tiếng Việt có dấu, ký tự đặc biệt đều
/// KHÔNG có glyph superscript thay thế, nên treMu bị CHẶN HẲN với chúng
/// (không còn phương án dự phòng "co nhỏ" như trước) — xem các điểm chặn ở
/// `_baoLoiTreMu` và nơi gọi nó.
///
/// ĐÂY LÀ ĐỊNH NGHĨA DUY NHẤT — mọi điểm kiểm tra ký tự hợp lệ cho treMu
/// trong toàn bộ tệp phải gọi hàm này, không tự viết lại điều kiện tương tự.
bool _kyTuHopLeChoTreMu(String kyTu) {
  if (kyTu.isEmpty) return false;
  if (kyTu == ' ') return true; // Dấu cách luôn hợp lệ.
  final donVi = kyTu.codeUnitAt(0);
  return (donVi >= 0x30 && donVi <= 0x39) || // 0-9
      (donVi >= 0x61 && donVi <= 0x7A); // a-z
}

/// Chữ "Đang ghi" lượn sóng liên hồi — mỗi ký tự tự bay lên/xuống theo sóng
/// sin, lệch pha nhau theo thứ tự, tạo hiệu ứng sóng chạy trái→phải. Dùng
/// cho dòng trạng thái ghi âm (xem `_xayAppBarTrinhGhiAmThe`) — chỉ có ý
/// nghĩa lúc ĐANG ghi (không dùng cho lúc tạm dừng, đứng yên).
class _ChuLuonSong extends StatefulWidget {
  const _ChuLuonSong({
    required this.chu,
    required this.mau,
    this.coChu = 12,
    this.motLan = false,
    this.khiXong,
  });
  final String chu;
  final Color mau;

  /// Cỡ chữ — mặc định 12 (nhãn nhỏ cũ). Bảng nút trình ghi âm mới dùng cỡ
  /// to hơn hẳn cho dòng "Đang Ghi âm mm:ss" (dễ nhìn hơn, theo yêu cầu).
  final double coChu;

  /// (YÊU CẦU MỚI) `true` = chỉ lượn sóng MỘT LẦN (trái qua phải) rồi đứng
  /// yên hẳn — dùng cho tên tệp khi chuyển tệp/quay lại trang soạn thảo.
  /// `false` (mặc định, như cũ) = lặp lại liên tục (dòng "Đang Ghi âm").
  final bool motLan;

  /// Gọi đúng một lần khi hết lượt lượn sóng — chỉ có ý nghĩa khi [motLan].
  final VoidCallback? khiXong;

  @override
  State<_ChuLuonSong> createState() => _ChuLuonSongState();
}

class _ChuLuonSongState extends State<_ChuLuonSong>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dieuKhien;

  @override
  void initState() {
    super.initState();
    _dieuKhien = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.motLan ? 700 : 2400),
    );
    if (widget.motLan) {
      _dieuKhien.forward().whenComplete(widget.khiXong ?? () {});
    } else {
      _dieuKhien.repeat();
    }
  }

  @override
  void dispose() {
    _dieuKhien.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: widget.mau,
      fontWeight: FontWeight.bold,
      fontSize: widget.coChu,
    );
    return AnimatedBuilder(
      animation: _dieuKhien,
      builder: (context, _) {
        final soKyTu = widget.chu.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < soKyTu; i++)
              Transform.translate(
                offset: Offset(
                  0,
                  -3 *
                      math.sin(2 * math.pi * (_dieuKhien.value - i / soKyTu)),
                ),
                child: Text(widget.chu[i], style: style),
              ),
          ],
        );
      },
    );
  }
}

/// Nút "X" xoá nội dung ô nhập (tìm kiếm/thay thế) — bấm xong tự đổi thành
/// chữ "Đã xoá" trong 1,5 giây rồi quay lại thành nút X, xác nhận trực quan
/// là đã xoá thật (không đổi gì về logic xoá, chỉ thêm hiệu ứng hiển thị).
class _NutXoaCoThongBao extends StatefulWidget {
  const _NutXoaCoThongBao({required this.tooltip, required this.onXoa, this.nho = false});
  final String tooltip;
  final VoidCallback onXoa;

  /// Màn hình hẹp: bó nhỏ lại (bỏ đệm 48x48 mặc định của IconButton) để các
  /// nút cạnh nhau trên thanh tìm kiếm/thay thế sát vào nhau hơn.
  final bool nho;

  @override
  State<_NutXoaCoThongBao> createState() => _NutXoaCoThongBaoState();
}

class _NutXoaCoThongBaoState extends State<_NutXoaCoThongBao> {
  bool _vuaXoa = false;
  Timer? _hen;

  @override
  void dispose() {
    _hen?.cancel();
    super.dispose();
  }

  void _bam() {
    widget.onXoa();
    setState(() => _vuaXoa = true);
    _hen?.cancel();
    _hen = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _vuaXoa = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_vuaXoa) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.nho ? 6 : 12),
        child: Text(
          'Đã xoá',
          style: TextStyle(
              color: Colors.green.shade700, fontWeight: FontWeight.w600),
        ),
      );
    }
    return IconButton(
      icon: Icon(Icons.close, color: Colors.green.shade700),
      tooltip: widget.tooltip,
      onPressed: _bam,
      visualDensity: widget.nho ? VisualDensity.compact : VisualDensity.standard,
      constraints: widget.nho ? const BoxConstraints.tightFor(width: 36, height: 36) : null,
      padding: widget.nho ? EdgeInsets.zero : const EdgeInsets.all(8),
    );
  }
}

/// Một phím ảo trong hàng phím thay thế bàn phím hệ thống ở "Bộ phím
/// nhanh cho màn hình cảm ứng" — chấm/phẩy/cách/xuống dòng/xoá. Nguyên văn
/// từ `main_web_test.dart` (`_NutPhimAo`).
class _NutPhimAo extends StatefulWidget {
  const _NutPhimAo({
    required this.nhan,
    required this.onTap,
    this.moTa,
    this.mauNen,
    this.mauVien,
    this.rong = 48,
    this.icon,
    this.lapLai = false,
  });

  final String nhan;
  final String? moTa;
  final VoidCallback onTap;
  final Color? mauNen;
  final Color? mauVien;

  /// Chiều rộng nút — mặc định 48, màn hình hẹp truyền hẹp hơn (xem nơi
  /// gọi ở `_xayHangPhimNhanhCamUng`) để 5 nút cùng lọt vào khung nhìn.
  final double rong;

  /// Vẽ icon thay chữ [nhan] khi có — dùng cho 4 nút mũi tên điều hướng
  /// (`_xayHangDieuHuongConTro`), [nhan] vẫn giữ để làm nhãn Semantics/mặc
  /// định cho [moTa].
  final IconData? icon;

  /// Bấm-GIỮ thì [onTap] tự lặp lại liên tục (400ms trễ ban đầu rồi mỗi
  /// 60ms một lần) cho tới khi thả tay — dùng cho 4 nút điều hướng và nút
  /// Xoá ký tự. Việc dừng đúng lúc "không thể đi tiếp được nữa" không cần
  /// logic riêng: gọi thêm vài lần khi con trỏ đã ở biên chỉ là no-op.
  final bool lapLai;

  @override
  State<_NutPhimAo> createState() => _NutPhimAoState();
}

class _NutPhimAoState extends State<_NutPhimAo> {
  Timer? _henTre;
  Timer? _henLap;

  void _batDau() {
    widget.onTap();
    if (!widget.lapLai) return;
    _henTre = Timer(const Duration(milliseconds: 400), () {
      _henLap = Timer.periodic(const Duration(milliseconds: 60), (_) => widget.onTap());
    });
  }

  void _dung() {
    _henTre?.cancel();
    _henLap?.cancel();
    _henTre = null;
    _henLap = null;
  }

  @override
  void dispose() {
    _dung();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final khung = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      onTapDown: (_) => _batDau(),
      onTapUp: (_) => _dung(),
      onTapCancel: _dung,
      child: Container(
        width: widget.rong,
        height: 40,
        decoration: BoxDecoration(
          color: widget.mauNen ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.mauVien ?? Colors.grey.shade400),
        ),
        alignment: Alignment.center,
        child: widget.icon != null
            ? Icon(widget.icon, size: 20)
            : Text(widget.nhan, style: const TextStyle(fontSize: 18)),
      ),
    );
    // (SỬA LỖI ở màn hình cảm ứng, bấm-GIỮ nút để kích hoạt lặp lại lại bị
    // `Tooltip` giành mất cử chỉ — nó cũng nghe bấm-giữ để hiện dòng chữ chú
    // thích, thắng trong đấu trường cử chỉ trước `onTapDown` của `InkWell`
    // nên lặp lại không chạy, chỉ thấy mỗi dòng chữ chú thích hiện lên) Nút
    // có `lapLai` thì bỏ hẳn `Tooltip`, dùng `Semantics` thay để vẫn có nhãn
    // cho trình đọc màn hình mà không tranh cử chỉ.
    if (widget.lapLai) {
      return Semantics(button: true, label: widget.moTa ?? widget.nhan, child: khung);
    }
    return Tooltip(message: widget.moTa ?? widget.nhan, child: khung);
  }
}

/// Nút nổi tự thở — dùng cho "Mở rộng" (trả lại thanh công cụ sau khi "Thu
/// gọn", xem `_thuGonThanhCongCu`). Nổi TRÊN chữ đang soạn (không chiếm
/// đất), độ rõ tự thở tuần hoàn: 20% → 100% (5 giây) → đứng im (1 giây) →
/// 100% → 20% (5 giây) → đứng im (1 giây) → lặp lại mãi mãi — vẫn LUÔN bấm
/// được dù đang mờ tới đâu, giống mọi nút `Opacity` khác trong tệp này.
class _NutNoiTuTho extends StatefulWidget {
  const _NutNoiTuTho({
    required this.chu,
    required this.mau,
    required this.moTa,
    required this.onTap,
  });

  /// Chữ/emoji hiện trong nút — dùng `Text` thay `Icon` Material để tránh
  /// rủi ro icon bị "tree-shake" mất (xem `_NutAnHienDieuHuongConTro`).
  final String chu;
  final Color mau;
  final String moTa;
  final VoidCallback onTap;

  @override
  State<_NutNoiTuTho> createState() => _NutNoiTuThoState();
}

class _NutNoiTuThoState extends State<_NutNoiTuTho> with SingleTickerProviderStateMixin {
  static const _chuKy = Duration(seconds: 12);
  late final AnimationController _dk;

  @override
  void initState() {
    super.initState();
    _dk = AnimationController(vsync: this, duration: _chuKy)..repeat();
  }

  @override
  void dispose() {
    _dk.dispose();
    super.dispose();
  }

  double _doRoTaiThoiDiem(double gia) {
    final t = gia * 12;
    if (t < 5) return 0.2 + 0.8 * (t / 5);
    if (t < 6) return 1.0;
    if (t < 11) return 1.0 - 0.8 * ((t - 6) / 5);
    return 0.2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dk,
      builder: (context, _) {
        return Opacity(
          opacity: _doRoTaiThoiDiem(_dk.value),
          child: Tooltip(
            message: widget.moTa,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {},
              onTapDown: (_) => widget.onTap(),
              // Đệm theo NỘI DUNG thay vì khoá cứng 40x40: một emoji đơn thì
              // tự ra hình tròn nhỏ gọn (chữ "Hiện" 4 ký tự nếu khoá cứng
              // 40x40 sẽ vỡ chữ), chữ dài hơn thì tự ra hình viên thuốc bo
              // tròn — cả hai đều đạt chiều cao tối thiểu 40 nhờ `constraints`.
              child: Container(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: widget.mau, borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.center,
                child: Text(widget.chu, style: const TextStyle(fontSize: 15, color: Colors.white)),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// (YÊU CẦU MỚI v123) Nút "Dán" nổi góc trên-TRÁI, chỉ hiện khi đã "Thu
/// gọn thanh công cụ" (nút Dán cố định ở thanh trên — `_nutDanCongCu` —
/// cũng biến mất theo lúc đó, không còn cách nào Dán nhanh nữa) — cùng độ
/// cao với nút nổi "Mở rộng" ở góc trên-phải (`_NutNoiTuTho`), nhưng KHÔNG
/// dùng lại chính widget đó vì nhịp thở khác hẳn: độ rõ dao động liên tục
/// giữa 50% và 10%, mỗi chiều đúng 5 giây, KHÔNG có đoạn đứng im — một
/// sóng tam giác tuần hoàn 10 giây, thay vì nhịp 20%→100%→(đứng im)→20%
/// của `_NutNoiTuTho`. Logic bấm vào y hệt nút "Dán" cố định cũ
/// (`_phimAoPasteCoLiet`, cùng cờ liệt `_phimPasteDangLiet` chống dán
/// trùng khi bấm nhanh hai lần).
class _NutDanNoiKhiThuGon extends StatefulWidget {
  const _NutDanNoiKhiThuGon({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NutDanNoiKhiThuGon> createState() => _NutDanNoiKhiThuGonState();
}

class _NutDanNoiKhiThuGonState extends State<_NutDanNoiKhiThuGon>
    with SingleTickerProviderStateMixin {
  static const _chuKy = Duration(seconds: 10);
  late final AnimationController _dk;

  @override
  void initState() {
    super.initState();
    _dk = AnimationController(vsync: this, duration: _chuKy)..repeat();
  }

  @override
  void dispose() {
    _dk.dispose();
    super.dispose();
  }

  /// Sóng tam giác tuần hoàn 10 giây: 0,5 → 0,1 (5 giây đầu) → 0,5 (5 giây
  /// sau), tuyến tính cả hai chiều, không có đoạn đứng im.
  double _doRoNutTaiThoiDiem(double gia) {
    final t = gia * 10;
    if (t < 5) return 0.5 - 0.08 * t;
    return 0.1 + 0.08 * (t - 5);
  }

  /// (YÊU CẦU MỚI) Chữ "Dán" màu xanh dương, độ rõ ĐỘC LẬP với độ rõ của
  /// cả nút (nền xám) — luôn cao hơn đúng 0,2 (20 điểm phần trăm): nút
  /// 50% ↔ chữ 70%, nút 10% ↔ chữ 30%, cùng tăng/giảm đồng bộ ở giữa. Vì
  /// vậy KHÔNG dùng một `Opacity` DUY NHẤT bọc cả nút (sẽ nhân chung một
  /// độ rõ cho cả nền lẫn chữ) — gán độ rõ riêng cho từng màu qua
  /// `withOpacity`.
  double _doRoChuTaiThoiDiem(double doRoNut) => doRoNut + 0.2;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dk,
      builder: (context, _) {
        final doRoNut = _doRoNutTaiThoiDiem(_dk.value);
        return Tooltip(
          message: Ch.dan(ngonNguHienTai.value),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            onTapDown: (_) => widget.onTap(),
            child: Container(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF5F6368).withOpacity(doRoNut),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                Ch.dan(ngonNguHienTai.value),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.withOpacity(_doRoChuTaiThoiDiem(doRoNut)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Nút chữ (Copy/Cut/Paste/All/Home/End) của hàng công cụ trên hàng phím
/// nhanh cảm ứng — CÙNG kiểu dáng `_NutPhimAo` nhưng rộng theo chữ (đệm
/// ngang) thay vì cỡ vuông cố định 48px, vì nhãn ở đây là CỤM CHỮ tiếng
/// Anh (giữ nguyên văn theo yêu cầu), không phải MỘT ký tự/icon đơn.
class _NutCongCuChu extends StatelessWidget {
  const _NutCongCuChu({
    required this.nhan,
    required this.onTap,
    this.moTa,
    this.tyLeThuHep,
    this.bLiet = false,
    this.noiBat = false,
    this.mauChu,
  });

  final String nhan;
  final String? moTa;
  final VoidCallback onTap;

  /// Màu chữ riêng, ghi đè màu mặc định — CHỈ áp dụng khi [bLiet]/[noiBat]
  /// đều không bật (hai cờ đó đã tự quyết màu riêng của chúng, ưu tiên hơn).
  /// Dùng cho Copy/Cắt/Dán khi hiện ở hàng thay nút điều hướng tệp/nổi góc
  /// trên-trái (xem `_hangCopyCutPaste`), cố ý tô xanh dương để nổi bật
  /// đúng NGỮ CẢNH "đang ở phía trên", khác hẳn ba nút cùng tên ở Bộ phím
  /// nhanh (màu chữ mặc định, không đổi).
  final Color? mauChu;

  /// Vừa DIM màu (báo mắt thấy đang tạm khoá) VỪA chặn cứng mọi cử chỉ
  /// chạm bằng `IgnorePointer` (xem `build`) — không chỉ dừng ở việc để
  /// [onTap] tự bỏ qua như trước: bấm RẤT NHANH nhiều lần liên tiếp trong
  /// lúc đang liệt có thể khiến một cử chỉ "lọt" qua trước khi cờ liệt
  /// (`setState`) kịp áp dụng, hoặc va chạm với việc giành lại tiêu điểm ô
  /// chữ — chặn ngay ở tầng cử chỉ loại bỏ hẳn khả năng đó, không phụ
  /// thuộc vào việc hàm gọi có tự kiểm tra đúng hay không.
  final bool bLiet;

  /// NGƯỢC LẠI [bLiet] — tô màu xanh dương NỔI BẬT (không disable gì cả,
  /// vẫn bấm được bình thường) — báo hiệu nút đang ở "chế độ nhanh": bấm
  /// vào lúc này sẽ cho kết quả cố định, không theo logic bấm nhiều lần
  /// thường ngày. Dùng cho nút "All" ngay sau khi vừa đạt "chọn tất cả"
  /// (xem `_phimAllVuaChonTatCa`) — vùng chọn "chọn tất cả" rất dễ mất chỉ
  /// bằng một cú chạm ra vùng văn bản (hành vi CHUẨN của mọi ô nhập, không
  /// phải lỗi) nên cần một cách bấm lại NHANH, chắc chắn ra lại "chọn tất
  /// cả" ngay, không phải bấm 2-4 lần đếm lại từ đầu.
  final bool noiBat;

  /// Nhân thêm vào bề rộng TỰ NHIÊN của nút (ví dụ 0.85 = hẹp bớt 15%) —
  /// dùng cho Home/Paste khi hàng đã chật chỗ ngang. Chữ bên trong có thể
  /// tràn ra ngoài viền nút (`overflow: visible`, không cắt) — chấp nhận
  /// được, đã được yêu cầu rõ ràng.
  final double? tyLeThuHep;

  static const _kieuChu = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    Widget khung = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: noiBat
            ? Colors.blue.shade100
            : (bLiet ? Colors.grey.shade200 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: noiBat
              ? Colors.blue.shade400
              : (bLiet ? Colors.grey.shade300 : Colors.grey.shade400),
        ),
      ),
      alignment: Alignment.center,
      child: Text(nhan,
          style: noiBat
              ? _kieuChu.copyWith(color: Colors.blue.shade900)
              : (bLiet
                  ? _kieuChu.copyWith(color: Colors.grey.shade400)
                  : _kieuChu.copyWith(color: mauChu)),
          overflow: TextOverflow.visible,
          softWrap: false),
    );
    final tyLe = tyLeThuHep;
    if (tyLe != null) {
      final tp = TextPainter(
        text: TextSpan(text: nhan, style: _kieuChu),
        textDirection: Directionality.of(context),
      )..layout();
      khung = SizedBox(width: (tp.width + 24) * tyLe, child: khung);
    }
    return Tooltip(
      message: moTa ?? nhan,
      child: IgnorePointer(
        ignoring: bLiet,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          onTapDown: (_) => onTap(),
          child: khung,
        ),
      ),
    );
  }
}

class _VungVe {
  _VungVe({required this.batDau, required this.ketThuc, this.style, this.recognizer});
  final int batDau;
  final int ketThuc;
  final TextStyle? style;
  final GestureRecognizer? recognizer;
}

/// Một mục kết quả "Kiểm tra toàn văn", gắn kèm vị trí gốc để sắp xếp và áp
/// dụng lần lượt theo đúng thứ tự xuất hiện trong bài.
sealed class _MucToanVan {
  const _MucToanVan(this.viTri);
  final int viTri;
}

class _MucChinhTaToanVan extends _MucToanVan {
  _MucChinhTaToanVan(this.goc) : super(goc.viTri);
  final ChinhTaMuc goc;
}

class _MucKhongPhuHopToanVan extends _MucToanVan {
  _MucKhongPhuHopToanVan(this.goc) : super(goc.viTri);
  final KhongPhuHopMuc goc;
}

class _MucCanXoaToanVan extends _MucToanVan {
  _MucCanXoaToanVan(this.goc) : super(goc.viTri);
  final CanXoaMuc goc;
}

class _MucDauCauMoiToanVan extends _MucToanVan {
  _MucDauCauMoiToanVan(this.goc) : super(goc.viTri);
  final DauCauMoiToanVanMuc goc;
}

/// Màu/độ đậm của mỗi loại gạch đánh dấu AI — tất cả vẽ ở một CustomPainter
/// riêng (`_veDanhDauAi` trong TrangSoanThao), không gắn qua
/// TextStyle.decoration, để chữ (kể cả nét đi xuống của g, ệ, ụ, q, y...)
/// luôn vẽ ĐÈ LÊN các gạch này chứ không phải ngược lại.
const _mauGachChanLoi = Colors.red; // Lượn sóng, dưới từ/cụm từ sai chính tả — đậm.
const _damGachChanLoi = 4.0;
const _mauGachChanDeXuat = Colors.green; // Lượn sóng, dưới đoạn ĐỀ XUẤT thay thế — mảnh.
const _mauGachChanCanXoa = Colors.green; // Lượn sóng, dưới đoạn AI đề xuất xoá — mảnh.
const _damGachChanCanXoa = 2.0;
const _mauGachGiuaThan = Color(0xFFFF8F00); // Thẳng, giữa thân — vàng đậm (Colors.amber.shade800).
const _mauGachChanTuDien = Colors.amber;
// (YÊU CẦU MỚI) Lượn sóng, dưới đoạn TRÔNG NHƯ LINK — xanh dương đậm, cùng
// độ đậm với gạch đỏ (dễ thấy, không mảnh như đề xuất xanh lá).
const _mauGachChanLienKet = Color(0xFF0D47A1); // Colors.blue.shade900.

/// Số "phút:giây" của một thẻ đang ghi — đổi màu TÍM từ giây thứ 45 (việc
/// NHẤP NHÁY của cả dòng do `_NhapNhayGioiHanGhiAm` bên ngoài lo, xem đó).
class _SoPhutGiayGhiAm extends StatelessWidget {
  const _SoPhutGiayGhiAm({required this.thoiLuong, required this.style});

  final Duration thoiLuong;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final giay = thoiLuong.inSeconds;
    final chu = dinhDangMmSs(thoiLuong);
    if (giay < 45) return Text(chu, style: style);
    return Text(chu, style: style.copyWith(color: Colors.purple.shade700));
  }
}

/// Bọc CẢ DÒNG trạng thái ghi âm ("Đang Ghi âm"/"Tạm dừng" + mm:ss) để
/// nhấp nháy khi sắp chạm hạn 60 giây/thẻ — THAY cho hộp thoại cảnh báo cũ
/// (từng làm người dùng rối mắt). Từ giây 45: đã nhấp nháy (chu kỳ 500ms).
/// Từ giây 55: tốc độ nhấp nháy TĂNG GẤP ĐÔI (chu kỳ 250ms), biểu thị sự
/// gấp gáp. Trước giây 45: hiện bình thường, không nhấp nháy. Dùng chung
/// cho cả AppBar của trình ghi âm lẫn bảng điều khiển.
class _NhapNhayGioiHanGhiAm extends StatefulWidget {
  const _NhapNhayGioiHanGhiAm({required this.giay, required this.child});

  final int giay;
  final Widget child;

  @override
  State<_NhapNhayGioiHanGhiAm> createState() => _NhapNhayGioiHanGhiAmState();
}

class _NhapNhayGioiHanGhiAmState extends State<_NhapNhayGioiHanGhiAm> {
  Timer? _hen;
  bool _an = false;

  /// "Vùng tốc độ" hiện tại: 0 = chưa nhấp nháy, 1 = giây 45-54, 2 = giây
  /// 55 trở đi — chỉ đặt lại hẹn giờ khi CHUYỂN vùng, không phải mỗi giây.
  int _vung(int g) => g < 45 ? 0 : (g < 55 ? 1 : 2);

  void _datHen() {
    _hen?.cancel();
    if (widget.giay < 45) {
      _an = false;
      return;
    }
    final chuKy = widget.giay >= 55
        ? const Duration(milliseconds: 250)
        : const Duration(milliseconds: 500);
    _hen = Timer.periodic(chuKy, (_) {
      if (!mounted) return;
      setState(() => _an = !_an);
    });
  }

  @override
  void initState() {
    super.initState();
    _datHen();
  }

  @override
  void didUpdateWidget(covariant _NhapNhayGioiHanGhiAm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_vung(oldWidget.giay) != _vung(widget.giay)) _datHen();
  }

  @override
  void dispose() {
    _hen?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.giay < 45) return widget.child;
    return Opacity(opacity: _an ? 0.2 : 1.0, child: widget.child);
  }
} // Lượn sóng, dưới từ khớp "Từ điển sửa lỗi chính tả của bạn" — vàng.

/// Một vùng [batDau, batDau+dai) cần vẽ đánh dấu AI, cùng màu/độ đậm/kiểu
/// riêng — CHỈ giữ TOẠ ĐỘ VĂN BẢN (không phải toạ độ điểm ảnh) vì đây là dữ
/// liệu "logic", dựng lúc BUILD; toạ độ điểm ảnh thật được đo lúc PAINT (xem
/// `_VeDanhDauAi.paint`), để không bao giờ dùng nhầm một khung hình bố cục
/// (layout) đã cũ — xem giải thích đầy đủ ở đó.
class _VungDanhDauAi {
  const _VungDanhDauAi({
    required this.batDau,
    required this.ketThuc,
    required this.mau,
    required this.day,
    this.lienSong = true,
    this.giuaThan = false,
  });
  final int batDau;
  final int ketThuc;
  final Color mau;
  final double day;
  final bool lienSong;
  final bool giuaThan;
}

/// Một vùng [batDau, ketThuc) mang định dạng THỦ CÔNG của người dùng (đậm,
/// nghiêng, gạch chân, gạch ngang thân, chữ trên, chữ dưới, màu chữ, màu
/// nền) — khác hẳn `_VungDanhDauAi` (chỉ AI mới tạo ra, chỉ vẽ overlay).
/// Định dạng thủ công là style THẬT của ký tự, ghép trực tiếp vào
/// `TextStyle` của từng `TextSpan` trong `_BoDieuKhienChinhTa.buildTextSpan`
/// (xem giải thích ở đó) — không phải overlay.
///
/// `mauChu`/`mauNen` null nghĩa là "không đặt" (giữ màu mặc định); một Color
/// (kể cả trong suốt, alpha 0) nghĩa là người dùng đã chủ động đặt.
class _VungDinhDangThuCong {
  _VungDinhDangThuCong({
    required this.batDau,
    required this.ketThuc,
    this.dam = false,
    this.nghieng = false,
    this.gachChan = false,
    this.gachNgang = false,
    this.treMu = false,
    this.treChan = false,
    this.mauChu,
    this.mauNen,
  });

  int batDau;
  int ketThuc;
  bool dam;
  bool nghieng;
  bool gachChan;
  bool gachNgang;
  bool treMu;
  bool treChan;
  Color? mauChu;
  Color? mauNen;

  bool get rong =>
      !dam && !nghieng && !gachChan && !gachNgang && !treMu && !treChan && mauChu == null && mauNen == null;

  /// - "Chữ dưới" (treChan): đơn giản, áp dụng ĐỒNG ĐỀU cho mọi ký tự — chỉ
  ///   co nhỏ `fontSize` còn 0.7 lần, không dùng `FontFeature`.
  /// - "Chữ trên" (treMu): dùng `FontFeature.enable('sups')`, KHÔNG giảm
  ///   `fontSize` — font (Roboto trên Android) tự thay glyph superscript
  ///   chuẩn của nó, đã được thiết kế nhỏ và đẩy lên khỏi đường cơ sở theo
  ///   đúng tỷ lệ riêng; nhân thêm 0.7 sẽ THU NHỎ KÉP. treMu chỉ được đặt
  ///   `true` cho ký tự hợp lệ theo [_kyTuHopLeChoTreMu] — việc chặn xảy ra
  ///   TRƯỚC khi gán, ở nơi gọi (`_baoLoiTreMu` và các điểm kiểm tra), nên
  ///   tới đây không cần kiểm tra lại ký tự.
  TextStyle apDungLen(TextStyle style) {
    TextDecoration? decoration;
    if (gachChan && gachNgang) {
      decoration = TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]);
    } else if (gachChan) {
      decoration = TextDecoration.underline;
    } else if (gachNgang) {
      decoration = TextDecoration.lineThrough;
    }
    return style.copyWith(
      fontWeight: dam ? FontWeight.bold : null,
      fontStyle: nghieng ? FontStyle.italic : null,
      decoration: decoration,
      color: mauChu,
      backgroundColor: mauNen,
      fontSize: treChan ? (style.fontSize ?? 17) * 0.7 : null,
      fontFeatures: treMu ? const [FontFeature.enable('sups')] : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'vt': batDau,
        'kt': ketThuc,
        if (dam) 'dam': true,
        if (nghieng) 'ngh': true,
        if (gachChan) 'gc': true,
        if (gachNgang) 'gn': true,
        if (treMu) 'tm': true,
        if (treChan) 'tc': true,
        if (mauChu != null) 'mc': mauChu!.toARGB32(),
        if (mauNen != null) 'mn': mauNen!.toARGB32(),
      };

  static _VungDinhDangThuCong? fromJson(Map<String, dynamic> j, int doDaiVanBan) {
    final batDau = j['vt'];
    final ketThuc = j['kt'];
    if (batDau is! int || ketThuc is! int) return null;
    if (batDau < 0 || ketThuc > doDaiVanBan || batDau >= ketThuc) return null;
    final mc = j['mc'];
    final mn = j['mn'];
    return _VungDinhDangThuCong(
      batDau: batDau,
      ketThuc: ketThuc,
      dam: j['dam'] == true,
      nghieng: j['ngh'] == true,
      gachChan: j['gc'] == true,
      gachNgang: j['gn'] == true,
      treMu: j['tm'] == true,
      treChan: j['tc'] == true,
      mauChu: mc is int ? Color(mc) : null,
      mauNen: mn is int ? Color(mn) : null,
    );
  }
}

/// (VIỆC 2) Bản ghi 8 giá trị định dạng — kiểu trả về của `_dinhDangHopTaiViTri`
/// (dùng chung cho CẢ việc tô sáng nút toolbar LẪN "hợp 2 bên" mặc định của
/// ký tự mới chèn), và CŨNG là kiểu của bộ nhớ đệm `_boNhoDem` (YÊU CẦU 2 —
/// một biến state thuần tuý, không phải vùng `_VungDinhDangThuCong` gắn
/// offset). Hai nguồn này KHÔNG BAO GIỜ trộn lẫn giữa chừng: nơi cần định
/// dạng của ký tự mới chèn luôn chọn ĐÚNG MỘT trong hai bằng if/else tường
/// minh (`_boNhoDemDangHoatDong ? _boNhoDem! : _dinhDangHopTaiViTri(...)`),
/// không bao giờ hợp (OR) cả hai lại với nhau.
typedef _HopDinhDang = ({
  bool dam,
  bool nghieng,
  bool gachChan,
  bool gachNgang,
  bool treMu,
  bool treChan,
  Color? mauChu,
  Color? mauNen,
});

/// Vẽ nhiều đường đánh dấu AI — mỗi đường ứng với một dòng của một vùng (một
/// cụm dài bị ngắt xuống nhiều dòng thì có nhiều đường, mỗi dòng một đường
/// riêng, có thể khác màu/độ đậm/kiểu nếu thuộc loại khác nhau).
///
/// ĐO TOẠ ĐỘ ĐIỂM ẢNH NGAY TRONG `paint()`, không đo trước lúc dựng widget —
/// đây chính là chỗ sửa lỗi "gạch chân/gạch giữa thân lâu lâu nhảy khỏi
/// đúng chữ của nó" khi bàn phím ảo bật/tắt: Flutter dựng lại WIDGET (build)
/// trước khi tính lại BỐ CỤC (layout) của khung mới trong cùng một khung
/// hình. Đo toạ độ ngay lúc build (bản trước) đôi khi đọc trúng bố cục CŨ
/// (trước khi bàn phím đổi chiều cao) — gạch vẽ ra bị lệch một khung hình so
/// với chữ thật. `paint()` luôn chạy SAU KHI bố cục của khung hình đó đã
/// xong hẳn, nên đo trong `paint()` luôn cho toạ độ đúng của ĐÚNG khung hình
/// đang vẽ, không bao giờ lệch nữa.
class _VeDanhDauAi extends CustomPainter {
  _VeDanhDauAi({required this.re, required this.khungBox, required this.dsVung});
  final RenderEditable re;
  final RenderBox khungBox;
  final List<_VungDanhDauAi> dsVung;

  @override
  void paint(Canvas canvas, Size size) {
    if (!re.hasSize || !khungBox.hasSize) return;
    const buocSong = 6.0;
    const bienDo = 2.5;
    for (final v in dsVung) {
      List<TextBox> hops;
      try {
        // LỖI 2: `RenderEditable.getBoxesForSelection` KHÔNG nhận tham số
        // `boxHeightStyle`/`boxWidthStyle` — hai style đó là THUỘC TÍNH của
        // chính RenderEditable (`selectionHeightStyle`/`selectionWidthStyle`,
        // do EditableText/TextField/SelectableText truyền vào lúc dựng), hàm
        // này chỉ nhận đúng một tham số `TextSelection`. Style `tight` vốn đã
        // là mặc định của RenderEditable nên không cần (và không thể) truyền
        // lại ở đây.
        hops = re.getBoxesForSelection(
          TextSelection(baseOffset: v.batDau, extentOffset: v.ketThuc),
        );
      } catch (_) {
        continue;
      }
      final ve = Paint()
        ..color = v.mau
        ..strokeWidth = v.day
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final tb in hops) {
        Rect h;
        try {
          h = Rect.fromPoints(
            re.localToGlobal(Offset(tb.left, tb.top), ancestor: khungBox),
            re.localToGlobal(Offset(tb.right, tb.bottom), ancestor: khungBox),
          );
        } catch (_) {
          continue;
        }
        final y = v.giuaThan ? (h.top + h.bottom) / 2 : h.bottom - 1;
        if (!v.lienSong) {
          canvas.drawLine(Offset(h.left, y), Offset(h.right, y), ve);
          continue;
        }
        final net = Path()..moveTo(h.left, y);
        var x = h.left;
        var xuong = true;
        while (x < h.right) {
          final xTiep = (x + buocSong).clamp(h.left, h.right);
          net.quadraticBezierTo(
            x + (xTiep - x) / 2,
            y + (xuong ? bienDo : -bienDo),
            xTiep,
            y,
          );
          x = xTiep;
          xuong = !xuong;
        }
        canvas.drawPath(net, ve);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VeDanhDauAi cu) => true;
}

/// Chấm tròn tím cuối văn bản — cùng lý do đo trong `paint()` như
/// `_VeDanhDauAi` ở trên, để không bao giờ lệch khỏi ký tự cuối khi bàn
/// phím ảo bật/tắt làm khung soạn thảo đổi cao liên tục.
/// Hai vòng tròn đồng tâm đánh dấu cuối văn bản: vòng NGOÀI (viền, đúng kích
/// cỡ chấm tròn cũ) đứng yên, vòng TRONG (đặc ruột, nhỏ hơn) nhấp nháy mượt
/// theo [moTrong] — 0 = ẩn hẳn, 1 = hiện rõ, do `AnimationController` bên
/// ngoài (`_ChamCuoiVanBan`) điều khiển và truyền vào qua `repaint`, nên
/// painter tự vẽ lại MỖI TICK mà không cần `setState`/dựng lại cây widget.
class _VeChamCuoiVanBan extends CustomPainter {
  _VeChamCuoiVanBan({
    required this.re,
    required this.khungBox,
    required this.viTri,
    required this.duongKinhNgoai,
    required this.duongKinhTrong,
    required this.mau,
    required this.moTrong,
  }) : super(repaint: moTrong);

  final RenderEditable re;
  final RenderBox khungBox;
  final int viTri;
  final double duongKinhNgoai;
  final double duongKinhTrong;
  final Color mau;
  final Animation<double> moTrong;

  @override
  void paint(Canvas canvas, Size size) {
    if (!re.hasSize || !khungBox.hasSize) return;
    Rect goc;
    Offset diem;
    try {
      goc = re.getLocalRectForCaret(TextPosition(offset: viTri));
      diem = re.localToGlobal(goc.topLeft, ancestor: khungBox);
    } catch (_) {
      return;
    }
    final tam = Offset(
      diem.dx + 2 + duongKinhNgoai / 2,
      diem.dy + goc.height / 2,
    );
    // Vòng NGOÀI — viền, đứng yên, đúng kích cỡ chấm tròn cũ.
    canvas.drawCircle(
      tam,
      duongKinhNgoai / 2,
      Paint()
        ..color = mau
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Vòng TRONG — đặc ruột, nhấp nháy mượt.
    canvas.drawCircle(
      tam,
      duongKinhTrong / 2,
      Paint()..color = mau.withValues(alpha: moTrong.value),
    );
  }

  @override
  bool shouldRepaint(covariant _VeChamCuoiVanBan cu) => true;
}

/// Bọc `_VeChamCuoiVanBan` cùng `AnimationController` riêng (5 giây một
/// chiều, lặp lại vô tận, tự đảo chiều — `repeat(reverse: true)`) cho vòng
/// tròn TRONG nhấp nháy mượt mà. Tách thành widget riêng (thay vì nhét
/// thẳng vào `_TrangSoanThaoState`, vốn không có `vsync`) để không phải
/// thêm `TickerProviderStateMixin` cho cả màn hình soạn thảo khổng lồ chỉ
/// vì một hiệu ứng nhỏ.
class _ChamCuoiVanBan extends StatefulWidget {
  const _ChamCuoiVanBan({
    required this.re,
    required this.khungBox,
    required this.viTri,
    required this.duongKinhNgoai,
    required this.duongKinhTrong,
    required this.mau,
  });

  final RenderEditable re;
  final RenderBox khungBox;
  final int viTri;
  final double duongKinhNgoai;
  final double duongKinhTrong;
  final Color mau;

  @override
  State<_ChamCuoiVanBan> createState() => _ChamCuoiVanBanState();
}

class _ChamCuoiVanBanState extends State<_ChamCuoiVanBan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dk;

  @override
  void initState() {
    super.initState();
    _dk = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _VeChamCuoiVanBan(
          re: widget.re,
          khungBox: widget.khungBox,
          viTri: widget.viTri,
          duongKinhNgoai: widget.duongKinhNgoai,
          duongKinhTrong: widget.duongKinhTrong,
          mau: widget.mau,
          moTrong: _dk,
        ),
      ),
    );
  }
}

/// (VIỆC 2) Con trỏ nháy TỰ VẼ, đè lên TRÊN CÙNG mọi lớp khác — kể cả
/// `backgroundColor` của một `TextSpan` (màu nền định dạng thủ công). Caret
/// GỐC của `TextField`/`EditableText` vẽ CÙNG lớp với chữ (dưới nền của
/// span), nên khi đứng trên/cạnh ký tự có `mauNen`, caret gốc bị nền che kín
/// hoàn toàn — không phải chuyện màu sắc trùng nhau (đã thử đổi màu, vẫn bị
/// che), mà là thứ tự vẽ. Đây là painter RIÊNG, đặt Ở CUỐI danh sách con của
/// `Stack` bọc `TextField` (xem `build`) nên luôn vẽ SAU CÙNG, không gì che
/// được nữa — `showCursor: false` tắt hẳn caret gốc để tránh hai con trỏ
/// chồng nhau.
class _VeConTro extends CustomPainter {
  _VeConTro({
    required this.re,
    required this.khungBox,
    required this.viTri,
    required this.mau,
    required this.hienThi,
  });
  final RenderEditable re;
  final RenderBox khungBox;
  final int viTri;
  final Color mau;

  /// Pha nhấp nháy hiện tại — `false` thì `paint()` không vẽ gì cả (giả lập
  /// nhịp tắt của caret chuẩn).
  final bool hienThi;

  @override
  void paint(Canvas canvas, Size size) {
    if (!hienThi) return;
    if (!re.hasSize || !khungBox.hasSize) return;
    Rect goc;
    Offset diem;
    try {
      goc = re.getLocalRectForCaret(TextPosition(offset: viTri));
      diem = re.localToGlobal(goc.topLeft, ancestor: khungBox);
    } catch (_) {
      return;
    }
    final vach = Rect.fromLTWH(diem.dx, diem.dy, 2.0, goc.height);
    canvas.drawRect(vach, Paint()..color = mau);
  }

  @override
  bool shouldRepaint(covariant _VeConTro cu) =>
      cu.viTri != viTri || cu.hienThi != hienThi || cu.mau != mau;
}

/// (VIỆC 5c) Vẽ đường kẻ chia văn bản tại mỗi dòng rỗng/toàn dấu cách đang
/// ghi nhận trong `_cacViTriDuongKeChia` — ĐO TOẠ ĐỘ THẬT ngay trong
/// `paint()` (dùng `RenderEditable.getLocalRectForCaret` cho đầu và cuối
/// dòng), cùng lý do/pattern với `_VeDanhDauAi`/`_VeConTro`: toạ độ luôn
/// đúng theo layout MỚI NHẤT, tự "bám đúng dòng" qua mọi lần xoay màn
/// hình/đổi kích thước mà không cần lưu toạ độ cứng ở đâu cả.
///
/// ĐƠN GIẢN HOÁ so với đặc tả gốc ("chấm tròn nối nhau"): vẽ MỘT ĐƯỜNG
/// THẲNG ngang qua bề rộng dòng — cùng màu tím mờ 35%, cùng độ dày với gạch
/// giữa thân vàng đậm (`_damGachChanLoi`) để nhất quán về độ dày trực quan.
/// Việc này tránh rủi ro tính sai khoảng cách/kích thước từng chấm khi
/// không compile-test được, mà vẫn đạt đúng ý chính: có một đường kẻ chia
/// rõ ràng, luôn bám đúng dòng.
class _VeDuongKeChia extends CustomPainter {
  _VeDuongKeChia({
    required this.re,
    required this.khungBox,
    required this.dsViTri,
    required this.mau,
  });
  final RenderEditable re;
  final RenderBox khungBox;
  final List<int> dsViTri;

  /// Màu ĐÃ áp opacity theo Cài đặt (`mauDuongKeChia`/`phanTramMoDuongKeChia`)
  /// — tính sẵn ở nơi gọi (`_veDuongKeChia`), painter chỉ vẽ, không tự đọc
  /// Cài đặt.
  final Color mau;

  @override
  void paint(Canvas canvas, Size size) {
    if (!re.hasSize || !khungBox.hasSize) return;
    // Chỉ có SỐ LƯỢNG NHỎ offset tại một thời điểm (thường vài dòng) —
    // không quét toàn văn bản, an toàn về hiệu năng dù chạy mỗi khung hình.
    for (final vt in dsViTri) {
      Rect goc;
      Offset diem;
      try {
        goc = re.getLocalRectForCaret(TextPosition(offset: vt));
        diem = re.localToGlobal(goc.topLeft, ancestor: khungBox);
      } catch (_) {
        continue;
      }
      final y = diem.dy + goc.height / 2;
      final trai = diem.dx;
      final phai = khungBox.size.width - 4;
      if (phai <= trai) continue;
      canvas.drawLine(
        Offset(trai, y),
        Offset(phai, y),
        Paint()
          ..color = mau
          ..strokeWidth = _damGachChanLoi
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VeDuongKeChia cu) => true;
}

// ------------------------------------------- mã hoá định dạng AI vào file

/// Điểm bắt đầu khối định dạng AI (lỗi chính tả / đoạn không phù hợp / đoạn
/// cần xoá) được mã hoá gắn ở CUỐI nội dung ghi chú lúc lưu — xem
/// `_macDinhDangAi`/`_apDungDinhDangAi` trong `_TrangSoanThaoState`. Nhờ vậy
/// những đánh dấu AI người dùng chưa quyết định vẫn còn nguyên khi thoát app
/// rồi mở lại — kể cả một năm sau. Chuỗi cố ý lạ, khó lòng xuất hiện tình cờ
/// trong một ghi chú bình thường.
const _diemBatDauKhoiDinhDang = '\n§FLOWRITE-DINHDANG-V1§';

/// Y hệt [_diemBatDauKhoiDinhDang] nhưng cho khối định dạng THỦ CÔNG (đậm,
/// nghiêng, gạch chân...) — một khối MÃ HOÁ RIÊNG, ghép SAU khối AI (nếu có)
/// khi lưu, để một ghi chú sạch (không định dạng thủ công) không phình thêm
/// byte nào. Tách khối riêng thay vì gộp chung với khối AI để không phải
/// đụng vào định dạng lưu trữ đã ổn định của AI, và để hai cơ chế không bao
/// giờ giẫm chân nhau khi đọc/ghi.
const _diemBatDauDinhDangThuCong = '\n§FLOWRITE-DINHDANGTHUCONG-V1§';

/// Đoạn văn bản dài hơn ngần này thì đổi từ "chép nguyên văn" (chắc chắn
/// tuyệt đối nhưng nặng dần theo độ dài) sang "mã băm" (nhẹ — độ dài cố
/// định dù đoạn gốc dài bao nhiêu — và xác suất trùng giả gần như bằng
/// không) khi lưu vào khối định dạng.
const _nguongMaBamDinhDang = 20;

/// Băm FNV-1a 32-bit — chỉ để XÁC MINH một đoạn văn bản còn nguyên vẹn hay
/// không (không phải mục đích bảo mật), nên một thuật toán đơn giản, tự viết
/// vài dòng, không cần thêm gói phụ thuộc nào là đủ.
String _bamFnv1a(String chu) {
  const soNguyenTo = 16777619;
  const mat32Bit = 0xFFFFFFFF;
  var h = 2166136261;
  for (final donVi in chu.codeUnits) {
    h = ((h ^ donVi) * soNguyenTo) & mat32Bit;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// Đóng gói một vùng [batDau, batDau+dai) của [vanBan] thành một mục để lưu
/// vào khối định dạng — chép nguyên văn nếu ngắn, băm nếu dài (xem
/// `_nguongMaBamDinhDang`).
Map<String, dynamic> _macVungDinhDang(String vanBan, int batDau, int dai) {
  final chu = vanBan.substring(batDau, batDau + dai);
  final m = <String, dynamic>{'vt': batDau, 'dai': dai};
  if (dai <= _nguongMaBamDinhDang) {
    m['chu'] = chu;
  } else {
    m['ham'] = _bamFnv1a(chu);
  }
  return m;
}

/// Xác minh một mục đã lưu còn ĐÚNG Y HỆT với [vanBan] hiện tại không — sai
/// khuôn, lệch vị trí, hay nội dung khác đi dù chỉ một ký tự đều coi là
/// KHÔNG khớp. Thà bỏ một định dạng còn hơn hiển thị sai chỗ.
bool _khopVungDinhDang(String vanBan, Map<String, dynamic>? m) {
  if (m == null) return false;
  final batDau = m['vt'];
  final dai = m['dai'];
  if (batDau is! int || dai is! int) return false;
  if (batDau < 0 || dai < 0 || batDau + dai > vanBan.length) return false;
  final chuThat = vanBan.substring(batDau, batDau + dai);
  final chuLuu = m['chu'];
  if (chuLuu is String) return chuThat == chuLuu;
  final hamLuu = m['ham'];
  if (hamLuu is String) return _bamFnv1a(chuThat) == hamLuu;
  return false;
}

/// Bộ điều khiển ô văn bản riêng — vẽ mọi đánh dấu AI ngay trong văn bản:
/// gạch đỏ dưới từ/cụm sai chính tả, đoạn không phù hợp (đỏ, gạch giữa thân)
/// cạnh đoạn đề xuất thay thế (xanh, gạch chân), và đoạn đề xuất xoá (đỏ,
/// gạch giữa thân). Việc vẽ diễn ra ngay trong `buildTextSpan` — cách duy
/// nhất chèn định dạng riêng cho từng đoạn vào một `TextField` đang gõ được.
class _BoDieuKhienChinhTa extends TextEditingController {
  _BoDieuKhienChinhTa({super.text});

  /// Ba danh sách dưới đây là NGUỒN DUY NHẤT của sự thật — trang soạn thảo
  /// sửa trực tiếp rồi gọi `notifyListeners()` để vẽ lại, không giữ bản sao.
  final List<LoiChinhTa> loi = [];
  final List<_VungKhongPhuHop> khongPhuHop = [];
  final List<_VungCanXoa> canXoa = [];

  /// Các từ khớp "Từ điển sửa lỗi chính tả của bạn" (`CaiDat.tuDienChinhTa`)
  /// tìm được trong bài — CŨNG là nguồn duy nhất của sự thật, quét lại mỗi
  /// lần văn bản đổi (xem `_quetTuDienChinhTa` ở `_TrangSoanThaoState`).
  final List<_LoiTuDien> tuDien = [];

  /// (YÊU CẦU MỚI) Các đoạn TRÔNG NHƯ LINK tìm được trong bài — CŨNG là
  /// nguồn duy nhất của sự thật, quét lại mỗi lần văn bản đổi (xem
  /// `_quetLienKet` ở `_TrangSoanThaoState`).
  final List<_VungLienKet> lienKet = [];

  /// Dấu câu AI vừa tự chèn (mục 3) — chỉ tồn tại trong 4 giây hiệu ứng nhấp
  /// nháy, không phải "nguồn duy nhất của sự thật" như ba danh sách trên,
  /// vì hết hiệu ứng thì chữ đã ở trong [text] rồi, không cần theo dõi nữa.
  final List<_VungDauCauMoi> dauCauMoi = [];

  /// (YÊU CẦU MỚI) Vùng vừa được dán từ "Bộ nhớ tạm để dán văn bản" hoặc
  /// "Từ điển nhập liệu nhanh" — nhấp nháy NỀN 3 giây để người dùng dễ thấy
  /// đoạn vừa chèn vào. TÁI DÙNG đúng kiểu [_VungDauCauMoi] (cùng khuôn
  /// batDau/ketThuc/sangMau/henNhapNhay) vì không cần thêm trường gì khác —
  /// tách DANH SÁCH riêng (không gộp chung vào [dauCauMoi]) để không lẫn
  /// với hiệu ứng dấu câu AI, dù lớp dữ liệu dùng chung được.
  final List<_VungDauCauMoi> vungVuaDanTu = [];

  /// (VIỆC 4) Vùng đang chạy hiệu ứng nhấp nháy 1 giây của "Thay chỗ này"/
  /// "Tất cả" — cùng kiểu "hiệu ứng tạm thời" như `dauCauMoi` ở trên, không
  /// phải nguồn sự thật lâu dài.
  final List<_VungHieuUngThayThe> hieuUngThayThe = [];

  /// Định dạng thủ công (đậm/nghiêng/gạch chân/…) — CŨNG là nguồn duy nhất
  /// của sự thật, giống ba danh sách trên. Không bao giờ chồng lên vùng AI
  /// (xem B7 trong `_TrangSoanThaoState._giaoVoiVungAi`), nên khi ghép vào
  /// `vung` ở `buildTextSpan` không cần lo tranh chấp thứ tự với các vùng AI.
  final List<_VungDinhDangThuCong> dinhDang = [];

  /// Kết quả tìm kiếm hiện tại (mục 3) — chỉ để BIẾT vùng nào đang được
  /// painter tìm kiếm (`_VeTimKiem`, vẽ ở lớp DƯỚI ô soạn thảo thật) tô
  /// gradient đỏ→vàng, để tạm bỏ `backgroundColor` của định dạng thủ công
  /// (`mauNen`) tại đúng những ký tự đó — `backgroundColor` là thuộc tính
  /// của chính `TextSpan` (lớp chữ thật, luôn vẽ TRÊN mọi painter khác
  /// trong `Stack`), nên không có cách "vẽ chồng lên sau" nào khác ngoài
  /// việc không đặt nó ở những ký tự này trong lúc tìm kiếm.
  List<int> viTriTimKiem = [];
  int doDaiTimKiem = 0;

  void Function(LoiChinhTa loi, Offset viTriManHinh)? khiBamTuSai;
  void Function(_LoiTuDien loi, Offset viTriManHinh)? khiBamTuDien;
  void Function(_VungLienKet vung, Offset viTriManHinh)? khiBamLienKet;
  void Function(_VungKhongPhuHop vung, Offset viTriManHinh)? khiBamDoanKhongPhuHop;
  void Function(_VungCanXoa vung, Offset viTriManHinh)? khiBamDoanCanXoa;
  void Function(int soThe, Offset viTriManHinh)? khiBamTheGhiAmHoanChinh;
  void Function(int soThe, Offset viTriManHinh)? khiBamTheDangChuyen;
  void Function(int batDau, int ketThuc)? khiBamTheTichChon;

  /// Số thẻ đang ở trạng thái "lỗi tạm thời" (gửi thất bại, chờ gửi lại) —
  /// chữ vẫn là `〔Ghi âm N 🎙️ mm:ss〕` như thẻ xong bình thường, chỉ khác
  /// MÀU (cam đậm thay vì xanh lá) để phân biệt bằng mắt.
  final Set<int> theGhiAmLoiTamThoi = {};

  /// `notifyListeners()` được đánh dấu @protected trong ChangeNotifier — bọc
  /// lại một hàm công khai để trang soạn thảo gọi vẽ lại sau khi tự tay sửa
  /// trực tiếp `loi`/`khongPhuHop`/`canXoa` mà không đi qua đường đổi `text`.
  void veLai() => notifyListeners();

  @override
  void dispose() {
    for (final k in khongPhuHop) {
      k.henNhapNhay?.cancel();
    }
    for (final x in canXoa) {
      x.henNhapNhay?.cancel();
    }
    for (final d in dauCauMoi) {
      d.henNhapNhay?.cancel();
    }
    for (final d in vungVuaDanTu) {
      d.henNhapNhay?.cancel();
    }
    for (final v in hieuUngThayThe) {
      v.henNhapNhay?.cancel();
    }
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final vb = text;
    if (vb.isEmpty) return TextSpan(style: style, text: vb);

    final vung = <_VungVe>[];

    // Thẻ ghi âm — xong (xanh lá) hay đang ghi dở (đỏ). Không chồng lấn với
    // bất kỳ vùng nào khác trong `vung` NHỜ được chặn ngay từ nguồn
    // (`_giaoVoiVungAi` từ chối mọi định dạng thủ công/AI đụng vào thẻ),
    // nên thêm vào đây không cần lo tranh chấp thứ tự.
    for (final m in reTheGhiAmHoanChinh.allMatches(vb)) {
      final soThe = int.parse(m.group(1)!);
      final loi = theGhiAmLoiTamThoi.contains(soThe);
      vung.add(_VungVe(
        batDau: m.start,
        ketThuc: m.end,
        style: TextStyle(
          color: loi ? Colors.orange.shade800 : Colors.green.shade700,
          fontWeight: FontWeight.bold,
        ),
        recognizer: TapGestureRecognizer()
          ..onTapDown = (ct) => khiBamTheGhiAmHoanChinh?.call(soThe, ct.globalPosition),
      ));
    }
    // Thẻ ĐANG được gửi cho Gemini — "Đang chuyển N" cam đậm, mm:ss giữ
    // màu thường (hai vùng tách riêng của CÙNG một thẻ).
    for (final m in reTheDangChuyen.allMatches(vb)) {
      final soThe = int.parse(m.group(1)!);
      // `Match`/`RegExpMatch` không có start(group)/end(group) — tự tính vị
      // trí của nhóm mm:ss bằng cách tìm lại nó trong chuỗi khớp toàn phần.
      final mmSs = m.group(2)!;
      final gioBatDau = m.start + m[0]!.lastIndexOf(mmSs);
      final gioKetThuc = gioBatDau + mmSs.length;
      void Function(TapDownDetails) chamTapDown() =>
          (ct) => khiBamTheDangChuyen?.call(soThe, ct.globalPosition);
      vung.add(_VungVe(
        batDau: m.start,
        ketThuc: gioBatDau,
        style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
        recognizer: TapGestureRecognizer()..onTapDown = chamTapDown(),
      ));
      vung.add(_VungVe(
        batDau: gioBatDau,
        ketThuc: gioKetThuc,
        recognizer: TapGestureRecognizer()..onTapDown = chamTapDown(),
      ));
      vung.add(_VungVe(
        batDau: gioKetThuc,
        ketThuc: m.end,
        recognizer: TapGestureRecognizer()..onTapDown = chamTapDown(),
      ));
    }
    {
      var timTu = 0;
      while (true) {
        final i = vb.indexOf(tenTokenDangGhiAm, timTu);
        if (i < 0) break;
        vung.add(_VungVe(
          batDau: i,
          ketThuc: i + tenTokenDangGhiAm.length,
          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
        ));
        timTu = i + tenTokenDangGhiAm.length;
      }
    }

    // Thẻ Tích chọn ` (🔲) `/` (✅) ` — bấm vào là đổi biểu tượng ngay (xem
    // `_khiBamTheTichChon`). Không chồng lấn vùng nào khác nhờ `_giaoVoiVungAi`
    // đã chặn định dạng/AI đụng vào nó ngay từ nguồn (y hệt thẻ ghi âm).
    for (final m in reTheTichChon.allMatches(vb)) {
      final batDauKhop = m.start, ketThucKhop = m.end;
      vung.add(_VungVe(
        batDau: batDauKhop,
        ketThuc: ketThucKhop,
        style: const TextStyle(fontWeight: FontWeight.bold),
        recognizer: TapGestureRecognizer()
          ..onTapDown = (_) => khiBamTheTichChon?.call(batDauKhop, ketThucKhop),
      ));
    }

    for (final l in loi) {
      if (l.batDau < 0 || l.ketThuc > vb.length || l.batDau >= l.ketThuc) continue;
      // KHÔNG gắn kiểu gạch chân ở đây nữa — gạch chân đỏ giờ được vẽ ở một
      // lớp RIÊNG, nằm DƯỚI lớp chữ (xem `_veGachChanLoiChinhTa` ở
      // TrangSoanThao), để những nét đi xuống của chữ (g, ệ, ụ, q, y...) đè
      // lên được gạch chân thay vì bị gạch chân che mất. Ở đây chỉ còn giữ
      // vùng bắt chạm để mở menu đề xuất.
      vung.add(_VungVe(
        batDau: l.batDau,
        ketThuc: l.ketThuc,
        recognizer: TapGestureRecognizer()
          ..onTapDown = (ct) => khiBamTuSai?.call(l, ct.globalPosition),
      ));
    }

    for (final t in tuDien) {
      if (t.batDau < 0 || t.ketThuc > vb.length || t.batDau >= t.ketThuc) continue;
      // Gạch vàng lượn sóng vẽ ở lớp riêng (`_veDanhDauAi`) — ở đây chỉ giữ
      // vùng bắt chạm để mở menu, giống `loi` ở trên.
      vung.add(_VungVe(
        batDau: t.batDau,
        ketThuc: t.ketThuc,
        recognizer: TapGestureRecognizer()
          ..onTapDown = (ct) => khiBamTuDien?.call(t, ct.globalPosition),
      ));
    }

    for (final k in lienKet) {
      if (k.batDau < 0 || k.ketThuc > vb.length || k.batDau >= k.ketThuc) continue;
      // Gạch xanh dương lượn sóng vẽ ở lớp riêng (`_veDanhDauAi`) — ở đây
      // chỉ giữ vùng bắt chạm để mở menu, giống `tuDien` ở trên.
      vung.add(_VungVe(
        batDau: k.batDau,
        ketThuc: k.ketThuc,
        recognizer: TapGestureRecognizer()
          ..onTapDown = (ct) => khiBamLienKet?.call(k, ct.globalPosition),
      ));
    }

    for (final k in khongPhuHop) {
      if (k.batDauGoc < 0 || k.ketThucDeXuat > vb.length) continue;
      if (k.nhapNhayMau == null) {
        if (k.batDauGoc < k.ketThucGoc) {
          // Đoạn CẦN THAY THẾ: chữ đỏ. Gạch giữa thân màu VÀNG đậm KHÔNG còn
          // gắn qua TextStyle.decoration nữa — vẽ ở lớp riêng NẰM DƯỚI chữ
          // (xem `_veDanhDauAi`), để chữ đỏ luôn đè lên gạch vàng, không bị
          // gạch che mất (layer chồng layer, đúng yêu cầu).
          vung.add(_VungVe(
            batDau: k.batDauGoc,
            ketThuc: k.ketThucGoc,
            style: TextStyle(color: Colors.red.shade700),
          ));
        }
        if (k.batDauDeXuat < k.ketThucDeXuat) {
          // Đoạn ĐỀ XUẤT THAY THẾ: chữ xanh dương. Gạch chân lượn sóng màu
          // XANH LÁ CÂY không còn gắn qua TextStyle.decoration nữa — chuyển
          // xuống lớp riêng nằm DƯỚI chữ (xem `_veDanhDauAi`), để chữ xanh
          // dương luôn đè lên gạch xanh lá, cùng cách với các đánh dấu khác.
          vung.add(_VungVe(
            batDau: k.batDauDeXuat,
            ketThuc: k.ketThucDeXuat,
            style: TextStyle(color: Colors.blue.shade700),
            recognizer: TapGestureRecognizer()
              ..onTapDown = (ct) => khiBamDoanKhongPhuHop?.call(k, ct.globalPosition),
          ));
        }
      } else if (k.sangMau) {
        final laXanh = k.nhapNhayMau == 'xanh';
        final batDau = laXanh ? k.batDauDeXuat : k.batDauGoc;
        final ketThuc = laXanh ? k.ketThucDeXuat : k.ketThucGoc;
        if (batDau < ketThuc && ketThuc <= vb.length) {
          vung.add(_VungVe(
            batDau: batDau,
            ketThuc: ketThuc,
            style: TextStyle(color: laXanh ? Colors.blue.shade700 : Colors.red.shade700),
          ));
        }
      }
      // sangMau == false trong lúc nhấp nháy: không thêm gì, chữ hiện màu mặc định.
    }

    for (final x in canXoa) {
      if (x.batDau < 0 || x.ketThuc > vb.length || x.batDau >= x.ketThuc) continue;
      if (!x.dangNhapNhay) {
        // Đoạn CẦN XOÁ: cùng chữ đỏ như đoạn CẦN THAY THẾ. Cả gạch giữa thân
        // vàng đậm LẪN gạch chân lượn sóng đỏ mảnh đều vẽ ở lớp riêng nằm
        // dưới chữ (xem `_veDanhDauAi`) — TextStyle chỉ vẽ được một kiểu
        // gạch mỗi lúc nên không ghép chung hai gạch khác kiểu vào một
        // TextStyle được, phải tách lớp.
        vung.add(_VungVe(
          batDau: x.batDau,
          ketThuc: x.ketThuc,
          style: TextStyle(color: Colors.red.shade700),
          recognizer: TapGestureRecognizer()
            ..onTapDown = (ct) => khiBamDoanCanXoa?.call(x, ct.globalPosition),
        ));
      } else if (x.sangMau) {
        vung.add(_VungVe(
          batDau: x.batDau,
          ketThuc: x.ketThuc,
          style: TextStyle(color: Colors.red.shade700),
        ));
      }
    }

    for (final d in dauCauMoi) {
      if (d.batDau < 0 || d.ketThuc > vb.length || d.batDau >= d.ketThuc) continue;
      if (!d.sangMau) continue; // Đang ở nửa chu kỳ "tắt" — không tô nền.
      vung.add(_VungVe(
        batDau: d.batDau,
        ketThuc: d.ketThuc,
        style: TextStyle(backgroundColor: Colors.blue.shade200),
      ));
    }

    // (YÊU CẦU MỚI) Vùng vừa dán từ Bộ nhớ tạm/Từ điển nhập liệu nhanh —
    // nhấp nháy nền vàng đậm 3 giây, cùng cách vẽ với `dauCauMoi` ở trên.
    for (final d in vungVuaDanTu) {
      if (d.batDau < 0 || d.ketThuc > vb.length || d.batDau >= d.ketThuc) continue;
      if (!d.sangMau) continue;
      vung.add(_VungVe(
        batDau: d.batDau,
        ketThuc: d.ketThuc,
        style: TextStyle(backgroundColor: Colors.amber.shade400),
      ));
    }

    // Định dạng thủ công — các vùng trong `dinhDang` được PHÉP chồng lấn
    // nhau (ví dụ đậm và nghiêng phủ hai khoảng khác nhau nhưng giao nhau ở
    // giữa), khác hẳn các vùng AI vốn không bao giờ chồng lấn theo thiết kế.
    // Gộp (OR từng cờ, màu sau ghi đè màu trước) thành các đoạn liền không
    // chồng lấn TRƯỚC khi thêm vào `vung`, để vòng ghép cuối (vốn giả định
    // không chồng lấn) không vô tình bỏ sót vùng nào.
    if (dinhDang.isNotEmpty) {
      final diem = <int>{};
      for (final d in dinhDang) {
        if (d.batDau < 0 || d.ketThuc > vb.length || d.batDau >= d.ketThuc) continue;
        diem.add(d.batDau);
        diem.add(d.ketThuc);
      }
      // Thêm biên các kết quả tìm kiếm vào mốc chia đoạn, để đoạn nào giao
      // với một kết quả tìm kiếm được tách riêng ra (xem suy luận `laVungTimKiem` dưới).
      if (doDaiTimKiem > 0) {
        for (final vt in viTriTimKiem) {
          final kt = vt + doDaiTimKiem;
          if (vt < 0 || kt > vb.length) continue;
          diem.add(vt);
          diem.add(kt);
        }
      }
      // LỖI 3: thêm biên của vùng CHỌN hiện tại (nếu có) làm mốc chia đoạn,
      // để đoạn nào giao với vùng chọn được tách riêng ra — nhờ vậy có thể
      // làm nhạt `mauNen` (backgroundColor định dạng thủ công) CHỈ ở phần
      // giao với selection, không đụng phần còn lại. Cùng pattern với biên
      // kết quả tìm kiếm ở trên, không viết cơ chế tách đoạn thứ hai.
      final coVungChon = selection.isValid && !selection.isCollapsed;
      if (coVungChon) {
        final sBatDau = selection.start.clamp(0, vb.length);
        final sKetThuc = selection.end.clamp(0, vb.length);
        if (sBatDau < sKetThuc) {
          diem.add(sBatDau);
          diem.add(sKetThuc);
        }
      }
      final moc = diem.toList()..sort();
      for (var i = 0; i < moc.length - 1; i++) {
        final a = moc[i], b = moc[i + 1];
        if (a >= b) continue;
        var dam = false, nghieng = false, gachChan = false, gachNgang = false, treMu = false, treChan = false;
        Color? mauChu;
        Color? mauNen;
        for (final d in dinhDang) {
          if (d.batDau <= a && d.ketThuc >= b) {
            dam = dam || d.dam;
            nghieng = nghieng || d.nghieng;
            gachChan = gachChan || d.gachChan;
            gachNgang = gachNgang || d.gachNgang;
            treMu = treMu || d.treMu;
            treChan = treChan || d.treChan;
            mauChu = d.mauChu ?? mauChu;
            mauNen = d.mauNen ?? mauNen;
          }
        }
        // Đoạn [a,b) nằm trọn trong một kết quả tìm kiếm — bỏ nền thủ công để
        // gradient của painter tìm kiếm (vẽ dưới) không bị che.
        if (mauNen != null && doDaiTimKiem > 0) {
          for (final vt in viTriTimKiem) {
            final kt = vt + doDaiTimKiem;
            if (a >= vt && b <= kt) {
              mauNen = null;
              break;
            }
          }
        }
        // LỖI 3: đoạn [a,b) nằm trọn trong vùng đang được bôi CHỌN — làm
        // NHẠT `mauNen` đi (giảm alpha cố định) để vùng tô CHỌN (do
        // `RenderEditable` tự vẽ, nằm DƯỚI lớp chữ/nền của TextSpan) không
        // bị màu nền thủ công che mất hoàn toàn, nhưng vẫn còn phảng phất
        // sắc màu nền gốc — đúng ý "vùng chọn thắng nhưng vẫn thấy mờ mờ".
        //
        // Đây là phương án ĐƠN GIẢN (giảm alpha cố định) thay vì trộn chính
        // xác với `selectionColor` của theme: không có nơi nào trong app đặt
        // `selectionColor`/`TextSelectionThemeData` tường minh (nó tới từ
        // theme mặc định, có thể đổi theo `ColorScheme`/nền sáng-tối), nên
        // trộn màu chính xác dễ sai và không kiểm chứng được vì môi trường
        // không compile/run Flutter được. Alpha cố định an toàn hơn, không
        // phụ thuộc giá trị màu chọn thật của theme.
        if (mauNen != null && coVungChon) {
          final sBatDau = selection.start.clamp(0, vb.length);
          final sKetThuc = selection.end.clamp(0, vb.length);
          if (a >= sBatDau && b <= sKetThuc) {
            mauNen = mauNen.withValues(alpha: 0.35);
          }
        }
        final gop = _VungDinhDangThuCong(
          batDau: a,
          ketThuc: b,
          dam: dam,
          nghieng: nghieng,
          gachChan: gachChan,
          gachNgang: gachNgang,
          treMu: treMu,
          treChan: treChan,
          mauChu: mauChu,
          mauNen: mauNen,
        );
        if (gop.rong) continue;
        vung.add(_VungVe(batDau: a, ketThuc: b, style: gop.apDungLen(const TextStyle())));
      }
    }

    vung.sort((a, b) => a.batDau.compareTo(b.batDau));

    final children = <InlineSpan>[];
    var vt = 0;
    for (final v in vung) {
      if (v.batDau < vt) continue; // Chồng lấn với vùng đã vẽ trước — bỏ qua.
      if (v.batDau > vt) children.add(TextSpan(text: vb.substring(vt, v.batDau)));
      children.add(TextSpan(text: vb.substring(v.batDau, v.ketThuc), style: v.style, recognizer: v.recognizer));
      vt = v.ketThuc;
    }
    if (vt < vb.length) children.add(TextSpan(text: vb.substring(vt)));

    return TextSpan(style: style, children: children);
  }
}

/// Ý định "Lùi lại"/"Tiến tới" cho Ctrl+Z / Ctrl+Shift+Z — xem giải thích ở
/// nơi dùng (`Shortcuts`/`Actions` bọc quanh ô soạn thảo trong `build`).
class _YDinhLuiLai extends Intent {
  const _YDinhLuiLai();
}

class _YDinhToi extends Intent {
  const _YDinhToi();
}

/// Ý định Copy/Cắt/Dán cho Ctrl+C/Ctrl+X/Ctrl+V — CỐ Ý không dùng
/// `CopySelectionTextIntent`/`PasteTextIntent` có sẵn của Flutter (thử rồi,
/// không ăn: Action mặc định của EditableText xử lý xong NGAY TẠI chỗ, không
/// "nhường" ra ngoài cho Action khai báo ở `Actions` bên ngoài như tưởng).
/// Đi đúng khuôn [_YDinhLuiLai]/[_YDinhToi] đã chạy tốt: tự định nghĩa Intent
/// RIÊNG, bắt bằng `SingleActivator` ở `Shortcuts` NGAY TRÊN ô soạn thảo
/// (gần tiêu điểm nhất luôn thắng, bất kể ô văn bản tự xử lý gì bên trong).
class _YDinhCopy extends Intent {
  const _YDinhCopy();
}

class _YDinhCut extends Intent {
  const _YDinhCut();
}

class _YDinhPaste extends Intent {
  const _YDinhPaste();
}

/// Ý định "Tìm kiếm" cho Ctrl+F — mở/đóng thanh tìm kiếm trong văn bản, cùng
/// cách khai báo với `_YDinhLuiLai`/`_YDinhToi` ở trên.
class _YDinhTimKiem extends Intent {
  const _YDinhTimKiem();
}

/// Ý định định dạng thủ công (đậm/nghiêng/gạch chân/…) — dùng chung một lớp
/// Intent mang theo loại thao tác, đỡ phải khai một lớp riêng cho mỗi phím
/// tắt định dạng (Ctrl+B, Ctrl+I, …).
class _YDinhDinhDang extends Intent {
  const _YDinhDinhDang(this.loai);
  final String loai; // 'dam' | 'nghieng' | 'gachChan' | 'gachNgang' | 'treMu' | 'treChan' | 'mauChu' | 'mauNen' | 'xoaDinhDang'
}

/// Vẽ nền gradient đỏ→vàng cho mỗi kết quả tìm kiếm trong văn bản — cùng
/// pattern đo toạ độ NGAY TRONG `paint()` như `_VeDanhDauAi`/`_VeChamCuoiVanBan`
/// (xem giải thích đầy đủ ở `_VeDanhDauAi`), để không bao giờ lệch khung hình
/// khi cuộn hay khi bàn phím ảo bật/tắt.
class _VeTimKiem extends CustomPainter {
  _VeTimKiem({
    required this.re,
    required this.khungBox,
    required this.ketQua,
    required this.doDaiTuKhoa,
    required this.chiSoHienTai,
  });
  final RenderEditable re;
  final RenderBox khungBox;
  final List<int> ketQua;
  final int doDaiTuKhoa;
  final int chiSoHienTai;

  @override
  void paint(Canvas canvas, Size size) {
    if (!re.hasSize || !khungBox.hasSize || doDaiTuKhoa <= 0) return;
    for (var i = 0; i < ketQua.length; i++) {
      final batDau = ketQua[i];
      final ketThuc = batDau + doDaiTuKhoa;
      List<TextBox> hops;
      try {
        // Cùng lý do với `_VeDanhDauAi` — xem chú thích ở đó.
        hops = re.getBoxesForSelection(
          TextSelection(baseOffset: batDau, extentOffset: ketThuc),
        );
      } catch (_) {
        continue;
      }
      final laHienTai = i == chiSoHienTai;
      for (final tb in hops) {
        Rect h;
        try {
          h = Rect.fromPoints(
            re.localToGlobal(Offset(tb.left, tb.top), ancestor: khungBox),
            re.localToGlobal(Offset(tb.right, tb.bottom), ancestor: khungBox),
          );
        } catch (_) {
          continue;
        }
        final nen = Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: laHienTai
                ? const [Color(0xFFD32F2F), Color(0xFFFFEB3B)]
                : [const Color(0xFFD32F2F).withValues(alpha: 0.45), const Color(0xFFFFEB3B).withValues(alpha: 0.45)],
          ).createShader(h);
        canvas.drawRect(h, nen);
        if (laHienTai) {
          canvas.drawRect(
            h,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFF6A1B9A),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VeTimKiem cu) => true;
}

/// (VIỆC 4) Vẽ nền gradient đỏ→vàng NHẤP NHÁY (ẩn/hiện theo `sangMau`) cho
/// mỗi vùng trong `_BoDieuKhienChinhTa.hieuUngThayThe` — cùng cách đo toạ độ
/// NGAY TRONG `paint()` như `_VeTimKiem` ở trên, chỉ khác là bỏ qua hẳn việc
/// vẽ khi `sangMau == false` để tạo hiệu ứng nhấp nháy.
class _VeHieuUngThayThe extends CustomPainter {
  _VeHieuUngThayThe({required this.re, required this.khungBox, required this.vungs});
  final RenderEditable re;
  final RenderBox khungBox;
  final List<_VungHieuUngThayThe> vungs;

  @override
  void paint(Canvas canvas, Size size) {
    if (!re.hasSize || !khungBox.hasSize) return;
    for (final v in vungs) {
      if (!v.sangMau) continue; // Nửa chu kỳ "tắt" của nhấp nháy — bỏ qua.
      if (v.batDau < 0 || v.ketThuc <= v.batDau) continue;
      List<TextBox> hops;
      try {
        hops = re.getBoxesForSelection(
          TextSelection(baseOffset: v.batDau, extentOffset: v.ketThuc),
        );
      } catch (_) {
        continue;
      }
      for (final tb in hops) {
        Rect h;
        try {
          h = Rect.fromPoints(
            re.localToGlobal(Offset(tb.left, tb.top), ancestor: khungBox),
            re.localToGlobal(Offset(tb.right, tb.bottom), ancestor: khungBox),
          );
        } catch (_) {
          continue;
        }
        canvas.drawRect(
          h,
          Paint()
            ..style = PaintingStyle.fill
            ..shader = const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFFD32F2F), Color(0xFFFFEB3B)],
            ).createShader(h),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VeHieuUngThayThe cu) => true;
}

/// Dán văn bản qua đường CHUỘT PHẢI (menu chọn văn bản gốc của hệ thống —
/// không đi qua `_phimAoPaste`, xem chú thích khai báo hàm đó) khi đang bật
/// "Tự động thụt đầu dòng mỗi khi xuống hàng": xoá hết dấu cách đứng đầu
/// đoạn vừa dán vào, để đoạn dán luôn bắt đầu bằng ký tự khác dấu cách.
///
/// Chỉ coi [newValue] là một lượt DÁN (không phải gõ tay) khi phần chữ mới
/// chèn dài HƠN 1 ký tự — gõ tay luôn chèn đúng 1 ký tự một lượt, dán gần
/// như luôn nhiều hơn 1 (trường hợp dán đúng 1 ký tự bỏ qua, không đáng kể).
class _XoaCachDauKhiDanLucThutDauDong extends TextInputFormatter {
  _XoaCachDauKhiDanLucThutDauDong({required this.dangBatTuDongThut});

  final bool Function() dangBatTuDongThut;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!dangBatTuDongThut()) return newValue;
    final cu = oldValue.text;
    final moi = newValue.text;
    if (moi.length <= cu.length + 1) return newValue;

    // So khác biệt 2 đầu — ĐÚNG thuật toán đã dùng ở `_apDungChinhSuaNguoiDung`
    // — tìm đúng đoạn [dau, ketThucChen) vừa được chèn vào.
    final gioiHan = cu.length < moi.length ? cu.length : moi.length;
    var dau = 0;
    while (dau < gioiHan && cu[dau] == moi[dau]) {
      dau++;
    }
    var duoi = 0;
    final gioiHanDuoi = gioiHan - dau;
    while (duoi < gioiHanDuoi && cu[cu.length - 1 - duoi] == moi[moi.length - 1 - duoi]) {
      duoi++;
    }
    final ketThucChen = moi.length - duoi;
    if (dau >= ketThucChen) return newValue;
    // CHỈ áp dụng khi ký tự NGAY TRƯỚC chỗ vừa chèn (trong văn bản CŨ) ĐÃ
    // LÀ dấu cách — xem giải thích ở `_phimAoPaste`, cùng quy tắc.
    if (dau == 0 || cu[dau - 1] != ' ') return newValue;

    var batDauThat = dau;
    while (batDauThat < ketThucChen && moi[batDauThat] == ' ') {
      batDauThat++;
    }
    if (batDauThat == dau) return newValue; // Không có dấu cách đứng đầu.

    final moiSauKhiXoa = moi.substring(0, dau) + moi.substring(batDauThat);
    final lech = batDauThat - dau;
    int dichOffset(int off) {
      if (off <= dau) return off;
      return (off - lech).clamp(dau, moiSauKhiXoa.length);
    }

    return TextEditingValue(
      text: moiSauKhiXoa,
      selection: TextSelection(
        baseOffset: dichOffset(newValue.selection.baseOffset),
        extentOffset: dichOffset(newValue.selection.extentOffset),
      ),
    );
  }
}

class TrangSoanThao extends StatefulWidget {
  const TrangSoanThao({
    super.key,
    required this.kho,
    required this.khoNoiBo,
    required this.caiDat,
    required this.ghiChuId,
  });

  /// Kho của GHI CHÚ ĐANG MỞ ở trang này — nội bộ hoặc đám mây.
  final KhoDuLieu kho;

  /// (YÊU CẦU MỚI) LUÔN là kho nội bộ thật của app (một instance DUY NHẤT,
  /// xuyên suốt cả phiên — xem `main.dart`) — khác [kho] khi trang này đang
  /// mở một ghi chú ĐÁM MÂY. Cần truyền riêng để màn hình cây thư mục
  /// (`ManHinhThuMuc`) luôn có đường quay lại ĐÚNG cây nội bộ thật, dù
  /// đang đứng ở ghi chú đám mây nào — xem `ManHinhThuMuc.khoNoiBo`.
  final KhoDuLieu khoNoiBo;

  final CaiDat caiDat;
  final String ghiChuId;

  @override
  State<TrangSoanThao> createState() => _TrangSoanThaoState();
}

class _TrangSoanThaoState extends State<TrangSoanThao>
    with WidgetsBindingObserver {
  final _boDieuKhien = _BoDieuKhienChinhTa();
  final _oChu = FocusNode();
  final _cuonVanBan = ScrollController();

  /// (YÊU CẦU MỚI) Vị trí CUỘN (không phải vị trí con trỏ) mà người dùng
  /// vừa rời đi của MỖI tệp — CHỈ trong phiên này (không ghi đĩa, F5/mở lại
  /// app là mất, mặc định về 0 cho mọi tệp). Giới hạn 20 tệp gần nhất
  /// (`Map` giữ đúng thứ tự thêm vào — xoá-rồi-thêm-lại mỗi lần ghi để mục
  /// vừa dùng luôn nổi lên CUỐI, nên mục bị đẩy ra khi đầy luôn là mục ÍT
  /// DÙNG GẦN ĐÂY NHẤT — xem `_ghiNhoViTriCuon`/`_phucHoiViTriCuon`).
  static const _gioiHanTepNhoViTriCuon = 20;
  final Map<String, double> _viTriCuonTheoTep = {};

  /// Gọi NGAY TRƯỚC KHI rời khỏi [_ghiChuHienTai] (chuyển sang tệp khác) —
  /// chụp lại vị trí cuộn hiện tại để lần quay lại tệp này còn nhớ.
  void _ghiNhoViTriCuon() {
    if (!_cuonVanBan.hasClients) return;
    final id = _ghiChuHienTai.id;
    _viTriCuonTheoTep.remove(id);
    _viTriCuonTheoTep[id] = _cuonVanBan.offset;
    while (_viTriCuonTheoTep.length > _gioiHanTepNhoViTriCuon) {
      _viTriCuonTheoTep.remove(_viTriCuonTheoTep.keys.first);
    }
  }

  /// Gọi NGAY SAU KHI mở một tệp — cuộn tới đúng vị trí đã nhớ của tệp đó
  /// (nếu phiên này đã từng ghé qua), hoặc lên ĐẦU (0) nếu chưa — đợi một
  /// khung hình để `ScrollController` biết chiều cao nội dung MỚI (nội
  /// dung tệp cũ có thể dài/ngắn khác hẳn), tránh `jumpTo` tới một offset
  /// vượt quá `maxScrollExtent` hiện có.
  void _phucHoiViTriCuon(String id) {
    final viTri = _viTriCuonTheoTep[id] ?? 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_cuonVanBan.hasClients) return;
      _cuonVanBan.jumpTo(viTri.clamp(0.0, _cuonVanBan.position.maxScrollExtent));
    });
  }
  final _micro = SpeechToText();

  /// (YÊU CẦU MỚI) Số hiệu Release mới nhất, chỉ khi CAO HƠN bản đang chạy —
  /// `null` nghĩa là chưa kiểm xong hoặc đang là bản mới nhất rồi. Xem
  /// `lib/kiem_tra_cap_nhat.dart`.
  int? _banApkMoiPhatHien;

  // -------------------------------------------------------------- tìm kiếm

  bool _hienThanhTimKiem = false;
  final _oTimKiem = TextEditingController();
  final _focusTimKiem = FocusNode();
  List<int> _ketQuaTimKiem = [];
  int _chiSoTimKiemHienTai = -1;

  /// Ô "Thay thế" — chỉ hiện khi có ít nhất một kết quả tìm kiếm.
  final _oThayThe = TextEditingController();
  final _focusThayThe = FocusNode();

  /// Bộ nhớ đệm RIÊNG cho từng ô, sống trong bộ nhớ (không lưu đĩa) — tự mất
  /// khi đóng app, điền lại mỗi lần MỞ thanh tìm kiếm. Cập nhật NGAY mỗi lần
  /// người dùng gõ, không đợi đóng thanh mới lưu.
  String _boNhoTimKiemGanNhat = '';
  String _boNhoThayTheGanNhat = '';

  void _khiOTimKiemDoi() => _boNhoTimKiemGanNhat = _oTimKiem.text;
  void _khiOThayTheDoi() => _boNhoThayTheGanNhat = _oThayThe.text;

  void _moTimKiem() {
    if (_trinhGhiAmMo) {
      _bao(Ch.dangMoTrinhGhiAmHayDongTruocKhiTimKiem(ngonNguHienTai.value));
      return;
    }
    _oTimKiem.text = _boNhoTimKiemGanNhat;
    _oThayThe.text = _boNhoThayTheGanNhat;
    setState(() => _hienThanhTimKiem = true);
    _capNhatKetQuaTimKiem();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusTimKiem.requestFocus());
  }

  void _dongTimKiem() {
    // Chụp lại nội dung TRƯỚC khi clear() — clear() cũng bắn listener, sẽ ghi
    // đè bộ nhớ đệm thành chuỗi rỗng nếu không chụp trước.
    final tuKhoaVuaTim = _oTimKiem.text;
    final thayTheVuaTim = _oThayThe.text;
    setState(() {
      _hienThanhTimKiem = false;
      _oTimKiem.clear();
      _oThayThe.clear();
      _ketQuaTimKiem = [];
      _chiSoTimKiemHienTai = -1;
    });
    _boNhoTimKiemGanNhat = tuKhoaVuaTim;
    _boNhoThayTheGanNhat = thayTheVuaTim;
    _boDieuKhien.viTriTimKiem = [];
    _boDieuKhien.doDaiTimKiem = 0;
    _boDieuKhien.veLai();
    _oChu.requestFocus();
  }

  /// Chặn đệ quy: `_capNhatKetQuaTimKiem()` kết thúc bằng việc gọi
  /// `_boDieuKhien.veLai()` (để painter tô lại kết quả) — nhưng
  /// `_boDieuKhien` cũng có `_capNhatTimKiemNeuDangMo` là MỘT LISTENER của
  /// chính nó (đăng ký trong `initState`), và listener đó lại gọi thẳng
  /// `_capNhatKetQuaTimKiem()` mỗi khi thanh tìm kiếm đang mở. Không có cờ
  /// chặn này, một lần gọi sẽ tự gọi lại chính nó ĐỒNG BỘ, vô hạn, ngay
  /// trong cùng một khung ngăn xếp — đúng nguyên nhân app đứng hình rồi bị
  /// Android báo ANR khi bấm nút tìm kiếm/Ctrl+F: mỗi lần đệ quy còn làm lại
  /// nguyên phép tìm kiếm O(n) trên toàn văn bản, hàng nghìn lần đệ quy dồn
  /// lại thành hàng giây nghẽn cứng luồng UI trước khi ngăn xếp tràn.
  bool _dangCapNhatTimKiem = false;

  /// (VIỆC 4) Trong lúc hiệu ứng nhấp nháy 1 giây của "Thay chỗ này"/"Tất
  /// cả" đang chạy, CHẶN việc `_capNhatTimKiemNeuDangMo` tự tính lại danh
  /// sách kết quả ngay khi văn bản vừa đổi (trường hợp THAY, VIỆC 4a) — kết
  /// quả chỉ thật sự bị loại khỏi danh sách SAU KHI hiệu ứng kết thúc, việc
  /// gọi `_capNhatKetQuaTimKiem()` khi đó do chính hàm bắt hiệu ứng đảm nhận.
  bool _treHoanCapNhatTimKiem = false;

  /// (VIỆC 3) Chuẩn hoá một chuỗi để so khớp trong tìm kiếm/thay thế, theo
  /// đúng hai cài đặt `CaiDat.timKiemPhanBietHoaThuong`/`timKiemPhanBietDauThanh`.
  /// Áp dụng ĐỘC LẬP hai phép biến đổi (hạ chữ thường nếu không phân biệt
  /// hoa/thường, bỏ dấu nếu không phân biệt dấu) — dùng CHUNG một hàm cho cả
  /// từ khoá lẫn văn bản để đảm bảo hai bên luôn được chuẩn hoá y hệt nhau.
  String _chuanHoaTimKiem(String s) {
    var ketQua = s;
    if (!widget.caiDat.timKiemPhanBietHoaThuong) ketQua = ketQua.toLowerCase();
    if (!widget.caiDat.timKiemPhanBietDauThanh) ketQua = _boDauTiengViet(ketQua);
    return ketQua;
  }

  void _capNhatKetQuaTimKiem() {
    if (_dangCapNhatTimKiem) return;
    _dangCapNhatTimKiem = true;
    try {
      final tuKhoa = _oTimKiem.text;
      final vb = _boDieuKhien.text;
      final ds = <int>[];
      if (tuKhoa.isNotEmpty) {
        final vbHa = _chuanHoaTimKiem(vb);
        final tkHa = _chuanHoaTimKiem(tuKhoa);
        // Không cho tìm kiếm/thay thế đụng vào bên trong thẻ ghi âm — thay
        // thế một phần ký tự trong thẻ sẽ làm thẻ lập tức bị lỗi.
        final vungThe = timCacVungTheGhiAm(vb);
        var vt = 0;
        while (true) {
          final i = vbHa.indexOf(tkHa, vt);
          if (i < 0) break;
          if (!viTriNamGiuaThe(i, vungThe) &&
              !viTriNamGiuaThe(i + tkHa.length, vungThe) &&
              !vungThe.any((v) => i < v.$2 && i + tkHa.length > v.$1)) {
            ds.add(i);
          }
          vt = i + tkHa.length;
        }
      }
      setState(() {
        _ketQuaTimKiem = ds;
        if (ds.isEmpty) {
          _chiSoTimKiemHienTai = -1;
        } else if (_chiSoTimKiemHienTai < 0 || _chiSoTimKiemHienTai >= ds.length) {
          _chiSoTimKiemHienTai = 0;
          _cuonToiKetQuaHienTai();
        }
      });
      _boDieuKhien.viTriTimKiem = ds;
      _boDieuKhien.doDaiTimKiem = tuKhoa.length;
      _boDieuKhien.veLai();
    } finally {
      _dangCapNhatTimKiem = false;
    }
  }

  /// Văn bản đổi (gõ tay hay do nói) trong lúc thanh tìm kiếm đang mở thì
  /// tính lại danh sách kết quả ngay — chỉ đọc lại vị trí, không tự nhảy tới
  /// kết quả nào (giữ nguyên chỉ số đang chọn nếu còn hợp lệ). Cờ
  /// `_dangCapNhatTimKiem` (xem trên) chặn vòng gọi lại chính nó khi hàm này
  /// tự kích hoạt thông qua `_boDieuKhien.veLai()` ở cuối
  /// `_capNhatKetQuaTimKiem()`.
  void _capNhatTimKiemNeuDangMo() {
    if (_treHoanCapNhatTimKiem) return;
    if (_hienThanhTimKiem) _capNhatKetQuaTimKiem();
  }

  void _dieuHuongTimKiem(int buoc) {
    if (_ketQuaTimKiem.isEmpty) return;
    setState(() {
      _chiSoTimKiemHienTai =
          (_chiSoTimKiemHienTai + buoc) % _ketQuaTimKiem.length;
      if (_chiSoTimKiemHienTai < 0) _chiSoTimKiemHienTai += _ketQuaTimKiem.length;
    });
    _cuonToiKetQuaHienTai();
  }

  /// Cuộn ô soạn thảo tới đúng vị trí kết quả đang chọn — dùng
  /// `RenderEditable.getLocalRectForCaret` để đo toạ độ NỘI DUNG (không phải
  /// toạ độ đã trừ cuộn) của vị trí đó, rồi nhắm `_cuonVanBan` (scroll
  /// controller của chính TextField) tới đó, canh giữa khung nhìn.
  void _cuonToiKetQuaHienTai() {
    if (_chiSoTimKiemHienTai < 0 || _chiSoTimKiemHienTai >= _ketQuaTimKiem.length) return;
    final viTri = _ketQuaTimKiem[_chiSoTimKiemHienTai];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
      if (hopVanBan == null || !_cuonVanBan.hasClients) return;
      final re = _timRenderEditable(hopVanBan);
      if (re == null || !re.hasSize) return;
      Rect goc;
      try {
        goc = re.getLocalRectForCaret(TextPosition(offset: viTri));
      } catch (_) {
        return;
      }
      final vpCao = _cuonVanBan.position.viewportDimension;
      final dich = (goc.top - vpCao / 2 + goc.height / 2)
          .clamp(0.0, _cuonVanBan.position.maxScrollExtent);
      _cuonVanBan.animateTo(dich, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  // ------------------------------------------------------ thay thế (search)

  /// Thay MỘT kết quả (tại [chiSo] trong `_ketQuaTimKiem`) bằng nội dung ô
  /// Thay thế — ô rỗng nghĩa là XOÁ kết quả đó. Không tự tính lại danh sách
  /// kết quả (gọi `_capNhatKetQuaTimKiem()` sau khi xong, việc đó tự lo).
  void _thayMotKetQua(int chiSo) {
    if (chiSo < 0 || chiSo >= _ketQuaTimKiem.length) return;
    final batDau = _ketQuaTimKiem[chiSo];
    final doDai = _oTimKiem.text.length;
    final ketThuc = batDau + doDai;
    final cu = _boDieuKhien.text;
    if (ketThuc > cu.length) return;
    final chenVao = _oThayThe.text;
    final moi = cu.replaceRange(batDau, ketThuc, chenVao);
    _dieuChinhLoiChinhTaSauKhiSua(batDau, doDai, chenVao.length);
    _dieuChinhVungToanVanSauKhiSua(batDau, doDai, chenVao.length);
    // `_ghiVaoO` — con đường DUY NHẤT ghi văn bản do máy thực hiện (đặt
    // `_tuSua` trước khi ghi, để `_khiNguoiDungSua` không hiểu nhầm đây là
    // người dùng tự gõ) — dùng lại y hệt `_thayVungTamBangGiongNoi`.
    _ghiVaoO(moi, batDau + chenVao.length);
  }

  /// "Thay chỗ này" — chỉ thay đúng kết quả đang chọn (số thứ tự hiện tại).
  /// (VIỆC 4) Không xử lý ngay lập tức nữa — điều phối sang đúng một trong
  /// hai luồng 4a (thay)/4b (xoá) tuỳ ô Thay thế có nội dung hay không.
  void _thayChoNay() {
    if (_chiSoTimKiemHienTai < 0 || _chiSoTimKiemHienTai >= _ketQuaTimKiem.length) return;
    // (VIỆC 5) Một mốc Lùi lại cho đúng MỘT lần bấm "Thay chỗ này" — TÁI
    // DÙNG cơ chế lịch sử đã có (`_luuDiemMoc`), chụp trạng thái TRƯỚC khi
    // văn bản bị sửa bên dưới (trong `_thayMotKetQua`).
    _luuDiemMoc();
    if (_oThayThe.text.isEmpty) {
      _batHieuUngXoaMotKetQua(_chiSoTimKiemHienTai);
    } else {
      _batHieuUngThayMotKetQua(_chiSoTimKiemHienTai);
    }
  }

  /// "Thay tất cả" — (VIỆC 4) cũng điều phối sang 4a/4b, KHÔNG còn xử lý
  /// ngay lập tức. Vẫn giữ nguyên tắc TỪ CUỐI VỀ ĐẦU để toạ độ các kết quả
  /// đứng trước không bị lệch khi độ dài văn bản đổi (đúng nguyên tắc dịch
  /// offset đã dùng ở `_dieuChinhLoiChinhTaSauKhiSua`/
  /// `_dieuChinhVungToanVanSauKhiSua` trong toàn bộ tệp này) — chỉ khác là
  /// việc xử lý THẬT SỰ giờ có thể đến sau 1 giây hiệu ứng.
  void _thayTatCa() {
    if (_ketQuaTimKiem.isEmpty) return;
    // (VIỆC 5) MỘT mốc Lùi lại DUY NHẤT cho toàn bộ "Tất cả" (dù thay/xoá N
    // kết quả cùng lúc) — chụp TRƯỚC khi bắt đầu xử lý, y hệt `_thayChoNay`.
    // Việc thay/xoá thật sự trong `_batHieuUngThay...`/`_batHieuUngXoa...`
    // bên dưới không gọi thêm `_luuDiemMoc` nào khác, nên Ctrl+Z một lần là
    // hoàn tác đúng cả N kết quả.
    _luuDiemMoc();
    if (_oThayThe.text.isEmpty) {
      _batHieuUngXoaTatCa();
    } else {
      _batHieuUngThayTatCa();
    }
  }

  /// (VIỆC 4) Bắt đầu — và tự dọn khi xong — hiệu ứng nhấp nháy nền gradient
  /// đỏ→vàng ĐÚNG 1 GIÂY tại [v], rồi gọi [xongHieuUng]. TÁI DÙNG hệt pattern
  /// `Timer.periodic` đã dùng ở `_batNhapNhayCanXoa`/`_batNhapNhayDauCauMoi`
  /// phía dưới, chỉ đổi thời lượng: 8 nhịp × 125ms = đúng 1000ms.
  void _batHieuUngThayThe(_VungHieuUngThayThe v, VoidCallback xongHieuUng) {
    _boDieuKhien.hieuUngThayThe.add(v);
    v.sangMau = true;
    var dem = 0;
    v.henNhapNhay = Timer.periodic(const Duration(milliseconds: 125), (t) {
      dem++;
      v.sangMau = !v.sangMau;
      if (dem >= 8) {
        t.cancel();
        _boDieuKhien.hieuUngThayThe.remove(v);
        xongHieuUng();
        return;
      }
      if (mounted) _boDieuKhien.veLai();
    });
    _boDieuKhien.veLai();
  }

  /// (VIỆC 4a) MỘT kết quả, khi ô Thay thế CÓ nội dung: thay chữ NGAY, rồi
  /// nhấp nháy nền gradient trên đoạn chữ MỚI 1 giây — chỉ SAU đó mới coi
  /// đây không còn là "kết quả tìm kiếm" nữa (tính lại danh sách, số lượng
  /// giảm, thanh tìm kiếm tự nhảy kết quả kế, đúng logic cũ).
  void _batHieuUngThayMotKetQua(int chiSo) {
    if (chiSo < 0 || chiSo >= _ketQuaTimKiem.length) return;
    final chenVao = _oThayThe.text;
    final batDauCu = _ketQuaTimKiem[chiSo];
    _treHoanCapNhatTimKiem = true;
    _thayMotKetQua(chiSo);
    _luuVanBan();
    final v = _VungHieuUngThayThe(
      batDau: batDauCu,
      ketThuc: batDauCu + chenVao.length,
      laXoa: false,
    );
    _batHieuUngThayThe(v, () {
      _treHoanCapNhatTimKiem = false;
      if (mounted) _capNhatKetQuaTimKiem();
    });
  }

  /// (VIỆC 4a) "Tất cả" khi ô Thay thế CÓ nội dung: thay hết NGAY (từ cuối
  /// văn bản về đầu, y hệt `_thayTatCa` cũ), mỗi kết quả nhấp nháy nền
  /// gradient TRÊN CHỮ MỚI riêng 1 giây, TẤT CẢ ĐỒNG THỜI — vì mỗi kết quả
  /// độc lập về mặt hiển thị, chỉ tính lại danh sách kết quả tìm kiếm ĐÚNG
  /// MỘT LẦN, sau khi hiệu ứng cuối cùng cũng kết thúc (đợi đủ [soLuong] lần
  /// hoàn tất bằng bộ đếm [conLai]).
  void _batHieuUngThayTatCa() {
    final chenVao = _oThayThe.text;
    final soLuong = _ketQuaTimKiem.length;
    if (soLuong == 0) return;
    _treHoanCapNhatTimKiem = true;
    var conLai = soLuong;
    for (var i = soLuong - 1; i >= 0; i--) {
      final batDauCu = _ketQuaTimKiem[i];
      _thayMotKetQua(i);
      final v = _VungHieuUngThayThe(
        batDau: batDauCu,
        ketThuc: batDauCu + chenVao.length,
        laXoa: false,
      );
      _batHieuUngThayThe(v, () {
        conLai--;
        if (conLai <= 0) {
          _treHoanCapNhatTimKiem = false;
          if (mounted) _capNhatKetQuaTimKiem();
        }
      });
    }
    _luuVanBan();
  }

  /// (VIỆC 4b) MỘT kết quả, khi ô Thay thế RỖNG: chữ CŨ giữ nguyên, CHƯA xoá
  /// gì cả — chỉ nhấp nháy nền gradient trên đoạn chữ CŨ 1 giây. Xoá THẬT SỰ
  /// chỉ xảy ra SAU 1 giây, cùng lúc với việc nền biến mất.
  void _batHieuUngXoaMotKetQua(int chiSo) {
    if (chiSo < 0 || chiSo >= _ketQuaTimKiem.length) return;
    final batDau = _ketQuaTimKiem[chiSo];
    final doDai = _oTimKiem.text.length;
    final v = _VungHieuUngThayThe(batDau: batDau, ketThuc: batDau + doDai, laXoa: true);
    _batHieuUngThayThe(v, () => _thucHienXoaSauHieuUng([v]));
  }

  /// (VIỆC 4b) "Tất cả" khi ô Thay thế RỖNG: TẤT CẢ chữ cũ giữ nguyên, mỗi
  /// kết quả nhấp nháy nền gradient trên đoạn chữ CŨ của nó, ĐỒNG THỜI, trong
  /// 1 giây — văn bản không đổi trong lúc chờ nên toạ độ mọi kết quả vẫn
  /// đúng nguyên. Xoá thật sự TẤT CẢ (từ cuối về đầu) chỉ diễn ra sau khi
  /// hiệu ứng cuối cùng cũng kết thúc.
  void _batHieuUngXoaTatCa() {
    final soLuong = _ketQuaTimKiem.length;
    if (soLuong == 0) return;
    final doDai = _oTimKiem.text.length;
    final vungs = [
      for (final batDau in _ketQuaTimKiem)
        _VungHieuUngThayThe(batDau: batDau, ketThuc: batDau + doDai, laXoa: true),
    ];
    var conLai = vungs.length;
    for (final v in vungs) {
      _batHieuUngThayThe(v, () {
        conLai--;
        if (conLai <= 0) _thucHienXoaSauHieuUng(vungs);
      });
    }
  }

  /// (VIỆC 4b) Xoá THẬT SỰ mọi vùng đã nhấp nháy xong — từ cuối văn bản về
  /// đầu (đúng nguyên tắc dịch offset dùng trong toàn bộ tệp này). Trong lúc
  /// chờ 1 giây, người dùng có thể đã gõ/tìm khác làm văn bản đổi — kiểm tra
  /// lại từng vị trí còn hợp lệ trước khi xoá, bỏ qua an toàn nếu không còn
  /// đúng nữa thay vì lỗi/lệch offset.
  void _thucHienXoaSauHieuUng(List<_VungHieuUngThayThe> vungs) {
    final ds = List<_VungHieuUngThayThe>.of(vungs)
      ..sort((a, b) => b.batDau.compareTo(a.batDau));
    for (final v in ds) {
      final cu = _boDieuKhien.text;
      if (v.batDau < 0 || v.ketThuc > cu.length || v.batDau >= v.ketThuc) continue;
      final moi = cu.replaceRange(v.batDau, v.ketThuc, '');
      _dieuChinhLoiChinhTaSauKhiSua(v.batDau, v.ketThuc - v.batDau, 0);
      _dieuChinhVungToanVanSauKhiSua(v.batDau, v.ketThuc - v.batDau, 0);
      _ghiVaoO(moi, v.batDau);
    }
    _luuVanBan();
    _capNhatKetQuaTimKiem();
  }

  Future<void> _xacNhanThayTatCa() async {
    final tuKhoa = _oTimKiem.text;
    final thayThe = _oThayThe.text;
    final soLuong = _ketQuaTimKiem.length;
    if (soLuong == 0) return;
    final laXoa = thayThe.isEmpty;
    final dongY = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Ch.xacNhanThayThe(ngonNguHienTai.value)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            children: [
              TextSpan(
                text: laXoa
                    ? Ch.banCoChacChanXoaCacKyTu(ngonNguHienTai.value)
                    : Ch.banCoChacChanThayDoiCacKyTu(ngonNguHienTai.value),
              ),
              _oanTuHopThoai(tuKhoa),
              if (!laXoa) ...[
                TextSpan(text: Ch.thanh(ngonNguHienTai.value)),
                _oanTuHopThoai(thayThe),
              ],
              TextSpan(text: Ch.oKetQuaTimKiemKhong(ngonNguHienTai.value)),
              _oanTuHopThoaiXanh('$soLuong'),
              TextSpan(text: Ch.ketQuaTimKiemKhongHoi(ngonNguHienTai.value)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Ch.huy(ngonNguHienTai.value)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Ch.chapNhan(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
    if (dongY == true) _thayTatCa();
  }

  /// (VIỆC 2) Số lượng kết quả N trong hộp thoại xác nhận — đóng khung viền
  /// y hệt `_oanTuHopThoai` bên dưới (đồng bộ phong cách), nhưng dùng màu
  /// XANH DƯƠNG để phân biệt với khung đỏ của X/Y (từ khoá tìm/thay) — và
  /// tách hẳn với xanh LÁ đã dùng cho nút "Kiểm tra toàn văn", tránh nhầm ý
  /// nghĩa màu sắc trong app.
  WidgetSpan _oanTuHopThoaiXanh(String chu) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            chu,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );

  /// Một đoạn chữ được đóng khung viền để nổi bật trong hộp thoại xác nhận.
  WidgetSpan _oanTuHopThoai(String chu) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '"$chu"',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );

  /// (VIỆC 3) Một dòng cài đặt dạng công tắc bật/tắt trong modal, cùng
  /// pattern Row + Switch đã dùng ở các dòng cài đặt trong
  /// `man_hinh_cai_dat.dart` (`_dong3TuDongChen`, `_dong4AI`, ...).
  Widget _dongCongTacTimKiem(
    String nhan,
    bool bat,
    ValueChanged<bool> khiDoi, {
    VoidCallback? khiBamTimHieuThem,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nhan,
                  style: TextStyle(
                    color: bat ? const Color(0xFF1A73E8) : const Color(0xFF5F6368),
                    fontSize: 13,
                  ),
                ),
              ),
              Switch(value: bat, onChanged: khiDoi),
            ],
          ),
          // (VIỆC 2) Nút "Tìm hiểu thêm" ngay dưới dòng công tắc — cùng
          // pattern giải thích ngắn/dài dùng ở `man_hinh_cai_dat.dart`, chỉ
          // đơn giản hơn (một đoạn văn ngắn, không tách "ngắn/chi tiết").
          if (khiBamTimHieuThem != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: khiBamTimHieuThem,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(Ch.timHieuThem(ngonNguHienTai.value), style: const TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  /// (VIỆC 2) Modal giải thích ngắn gọn cho từng dòng công tắc của "Cài đặt
  /// tìm kiếm" — cùng khung `AlertDialog` với `_hienGiaiThich` của
  /// `man_hinh_cai_dat.dart`, nhưng chỉ MỘT đoạn (yêu cầu "súc tích"), không
  /// tách ngắn/chi tiết.
  void _hienGiaiThichTimKiem(String tieuDe, String noiDung) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        // (YÊU CẦU MỚI) Bỏ nút "Đóng" ở `actions` — thay bằng nút X đỏ gọn
        // gàng ở góc trên bên phải.
        title: Row(
          children: [
            Expanded(child: Text(tieuDe)),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: Ch.dong(ngonNguHienTai.value),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: Text(noiDung, style: const TextStyle(fontSize: 14, height: 1.4)),
      ),
    );
  }

  /// (VIỆC 3) Modal "Cài đặt tìm kiếm và hướng dẫn thay thế" — Phần 1 gồm 4
  /// công tắc (2 cặp đối nghịch: hoa/thường, có dấu/không dấu) tác động thật
  /// vào `_capNhatKetQuaTimKiem()`; Phần 2 giữ NGUYÊN 100% nội dung hướng
  /// dẫn Thay thế cũ, chỉ dời xuống dưới Phần 1.
  void _moCaiDatTimKiemVaHuongDanThayThe() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          final phanBietHoaThuong = widget.caiDat.timKiemPhanBietHoaThuong;
          final phanBietDauThanh = widget.caiDat.timKiemPhanBietDauThanh;

          Future<void> datHoaThuong(bool moiPhanBiet) async {
            await widget.caiDat.datTimKiemPhanBietHoaThuong(moiPhanBiet);
            setStateModal(() {});
            _capNhatKetQuaTimKiem();
          }

          Future<void> datDauThanh(bool moiPhanBiet) async {
            await widget.caiDat.datTimKiemPhanBietDauThanh(moiPhanBiet);
            setStateModal(() {});
            _capNhatKetQuaTimKiem();
          }

          return AlertDialog(
            title: Text(Ch.caiDatTimKiemVaThayThe(ngonNguHienTai.value)),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Ch.caiDatCheDoTimKiem(ngonNguHienTai.value),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    _dongCongTacTimKiem(
                      Ch.khopCaHoaThuong(ngonNguHienTai.value),
                      !phanBietHoaThuong,
                      (bat) => datHoaThuong(!bat),
                      khiBamTimHieuThem: () => _hienGiaiThichTimKiem(
                        Ch.khopCaHoaThuong(ngonNguHienTai.value),
                        Ch.khopCaHoaThuongGiaiThich(ngonNguHienTai.value),
                      ),
                    ),
                    _dongCongTacTimKiem(
                      Ch.hoaThuongLuonKhacNhau(ngonNguHienTai.value),
                      phanBietHoaThuong,
                      (bat) => datHoaThuong(bat),
                      khiBamTimHieuThem: () => _hienGiaiThichTimKiem(
                        Ch.hoaThuongLuonKhacNhau(ngonNguHienTai.value),
                        Ch.hoaThuongLuonKhacNhauGiaiThich(ngonNguHienTai.value),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _dongCongTacTimKiem(
                      Ch.khopCaDauKhongDau(ngonNguHienTai.value),
                      !phanBietDauThanh,
                      (bat) => datDauThanh(!bat),
                      khiBamTimHieuThem: () => _hienGiaiThichTimKiem(
                        Ch.khopCaDauKhongDau(ngonNguHienTai.value),
                        Ch.khopCaDauKhongDauGiaiThich(ngonNguHienTai.value),
                      ),
                    ),
                    _dongCongTacTimKiem(
                      Ch.dauKhongDauLuonKhacNhau(ngonNguHienTai.value),
                      phanBietDauThanh,
                      (bat) => datDauThanh(bat),
                      khiBamTimHieuThem: () => _hienGiaiThichTimKiem(
                        Ch.dauKhongDauLuonKhacNhau(ngonNguHienTai.value),
                        Ch.dauKhongDauLuonKhacNhauGiaiThich(ngonNguHienTai.value),
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      Ch.huongDanThayThe(ngonNguHienTai.value),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Ch.noiDungHuongDanThayThe(ngonNguHienTai.value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Ch.daHieu(ngonNguHienTai.value)),
              ),
            ],
          );
        },
      ),
    );
  }

  late GhiChuFile _ghiChuHienTai;
  late final TextEditingController _tenController;
  final _oTen = FocusNode();

  /// Người dùng ĐANG MUỐN micro bật hay không. Khác với việc bộ nhận dạng có
  /// thực sự đang nghe hay không: Android tự ngắt sau vài giây im lặng, ta
  /// bật lại ngay, nhưng ý muốn của người dùng thì không đổi.
  bool _muonNghe = false;
  bool _dangNghe = false;
  bool _sanSang = false;
  String _loi = '';

  /// Chỉ có ý nghĩa trên WEB — thiết bị dùng để quyết định nút micro có
  /// dùng được hay không (xem `loai_thiet_bi.dart`/`man_hinh_cai_dat.dart`).
  /// Lấy lựa chọn thủ công của người dùng nếu có, không thì tự đoán qua
  /// User-Agent. Trên Android/iOS gốc, giá trị này không ảnh hưởng gì (chỉ
  /// đọc ở những chỗ đã tự bọc `kIsWeb`).
  late ThietBi _thietBiHienTai;

  /// CHỈ dùng cho web + Android — xem chú thích chi tiết tại nơi dùng trong
  /// `_khiCoChu`. Reset về rỗng mỗi khi một PHIÊN nghe mới thật sự bắt đầu
  /// (`_batMicro()`) — bộ nhận dạng của trình duyệt tạo lại từ đầu lúc đó.
  String _rawTichLuyChromeAndroid = '';

  /// Đang hiện dòng chữ chú thích dọc bên trên từng nút của thanh công cụ
  /// hay không — bật bằng nút "i" (chỉ xuất hiện khi micro tắt), hoặc tự bật
  /// khi vừa mở một ghi chú còn trống trơn. Tắt bằng bất kỳ thao tác nào:
  /// chạm màn hình ở bất cứ đâu, hoặc gõ bất kỳ phím nào trên bàn phím rời.
  bool _hienChuThich = false;

  /// Chụp lại trạng thái NGAY TRƯỚC khi bị `_tatChuThich()` tắt đi — nút "i"
  /// cần biết trạng thái này để đảo (toggle) đúng, vì bản thân cú chạm vào
  /// nút "i" cũng đi qua `_tatChuThich()` trước (Listener bọc quanh `body`
  /// bắt sự kiện chạm xuống trước khi onTap của nút kịp chạy).
  bool _hienChuThichTruocKhiTat = false;

  void _tatChuThich() {
    if (_hienChuThich) {
      _hienChuThichTruocKhiTat = true;
      if (mounted) setState(() => _hienChuThich = false);
    } else {
      _hienChuThichTruocKhiTat = false;
    }
  }

  /// Bấm nút "i" thì ĐẢO trạng thái chú thích — đang tắt thì bật lên, đang
  /// hiện thì tắt đi (đúng như mọi thao tác khác trên màn hình).
  void _khiBamChuThich() {
    setState(() => _hienChuThich = !_hienChuThichTruocKhiTat);
  }

  /// Micro đang bật mà im lặng quá lâu (không thêm được chữ nào, dù do nói
  /// hay do gõ tay) thì tự tắt HẲN — không tự bật lại như các cơ chế khác,
  /// người dùng phải tự bấm nút hoặc phím tắt mới nghe lại. Số phút lấy từ
  /// Cài đặt (widget.caiDat.thoiGianTuTatMicroGiay).
  Timer? _henTuTatMicroImLang;

  /// Chấm tròn tím cuối văn bản mờ đi còn 35% trong lúc CÒN ĐANG có ký tự
  /// mới xuất hiện (gõ tay hay do nói ra đều tính) — im hẳn 4 giây không
  /// thêm ký tự nào nữa thì mới sáng rõ 100% trở lại. Mỗi ký tự mới xuất
  /// hiện thì hẹn giờ này lại được đặt lại từ đầu.
  bool _chamCuoiMoDam = false;
  Timer? _henMoDamChamCuoi;

  void _batDauMoDamChamCuoi() {
    if (!_chamCuoiMoDam && mounted) setState(() => _chamCuoiMoDam = true);
    _henMoDamChamCuoi?.cancel();
    _henMoDamChamCuoi = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _chamCuoiMoDam = false);
    });
  }

  /// (VIỆC 2) Pha nhấp nháy của con trỏ tự vẽ (`_VeConTro`) — `true` là đang
  /// "hiện". Đổi bằng `Timer.periodic` (tái dùng đúng cách `_henMoDamChamCuoi`
  /// đã làm trong file này, không thêm `AnimationController`/`vsync` mới cho
  /// một việc đơn giản là đảo một bool theo nhịp cố định) — chỉ chạy trong
  /// lúc `_oChu` đang giữ tiêu điểm, xem `_khiFocusConTroDoi`.
  // ĐÃ SỬA (lỗi phải chạm hai lần mới bấm được nút trong lúc con trỏ đang
  // nhấp nháy): nhịp nhấp nháy trước đây gọi `setState` toàn màn hình mỗi
  // 500ms — bất kỳ cử chỉ chạm nào rơi đúng lúc một trong các lượt vẽ lại
  // đó xảy ra (giữa "chạm xuống" và "nhấc lên") có thể mất luôn cử chỉ đó
  // (Flutter huỷ recognizer đang chờ nếu cây widget bị dựng lại giữa
  // chừng), buộc phải chạm lần hai mới trúng. Đổi hẳn sang `ValueNotifier`
  // riêng, gộp vào ĐÚNG `Listenable.merge` mà overlay con trỏ đang nghe
  // (xem `_veConTro`/nơi dùng ở `build`) — chỉ overlay con trỏ vẽ lại,
  // không đụng gì tới toàn bộ cây widget (nút bấm ở AppBar không còn bị
  // dựng lại theo nhịp này nữa).
  final ValueNotifier<bool> _conTroDangHien = ValueNotifier<bool>(true);
  Timer? _henNhapNhayConTro;

  void _khiFocusConTroDoi() {
    if (_oChu.hasFocus) {
      if (_henNhapNhayConTro != null) return;
      // (SỬA LỖI — nhánh thử nghiệm) `_henNhapNhayConTro == null` ở đây
      // nghĩa là MỖI lần tiêu điểm vừa chuyển từ MẤT sang CÓ LẠI (không chỉ
      // riêng do Copy/Cắt/Dán/All — kể cả chạm ra khoảng trống rồi chạm lại
      // vào ô, một đường Flutter tự xử lý tiêu điểm/kết nối bàn phím, chưa
      // hề đi qua `_giuTieuDiemKhongBatBanPhimAo`). Trên thiết bị có bàn
      // phím vật lý, dọn trước một lệnh `TextInput.clearClient` — rẻ,
      // không gây trễ/nháy gì thấy được (Flutter đằng nào cũng sắp tự thiết
      // lập một kết nối mới ngay sau đây) — đề phòng kết nối CŨ (nếu đang
      // "liệt" từ trước) bị giữ lại nhầm thay vì dựng một kết nối sạch.
      if (_coBanPhimVatLy) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.clearClient');
      }
      _conTroDangHien.value = true;
      _henNhapNhayConTro = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _conTroDangHien.value = !_conTroDangHien.value;
      });
    } else {
      _henNhapNhayConTro?.cancel();
      _henNhapNhayConTro = null;
      _conTroDangHien.value = false;
    }
  }

  /// Có vùng chọn (khác rỗng) hay không TẠI LẦN BUILD GẦN NHẤT — chỉ để so
  /// sánh trong `_khiVungChonCoTheDoi`, không tự tin cậy giá trị này ở nơi
  /// khác (đọc thẳng `_layDoanVanDangChon()`/`_vungDangChonHopLe()` mới
  /// đúng lúc dùng thật).
  bool _coVungChonGanNhat = false;

  /// Nút "Làm việc với AI" tự sáng nền xanh khi trang soạn thảo có vùng
  /// chọn — `_boDieuKhien` đổi cả trăm lần khi gõ phím bình thường (mỗi ký
  /// tự một lần), nên CHỈ setState khi tình trạng "có/không vùng chọn"
  /// THẬT SỰ đổi (true→false hoặc ngược lại), không phải mỗi lần gọi. Đọc
  /// [_vungChonThatSu] (KHÔNG phải [_layDoanVanDangChon]) vì highlight này
  /// phải phản ánh đúng có bôi đen hay không, bất kể công tắc
  /// [_epToanVanKhiCoVungChon] đang ép chế độ nào.
  void _khiVungChonCoTheDoi() {
    final co = _vungChonThatSu() != null;
    if (co == _coVungChonGanNhat) return;
    _coVungChonGanNhat = co;
    // MỘT vùng chọn MỚI vừa xuất hiện (không phải vùng chọn cũ mở rộng
    // thêm) — luôn quay về ngữ cảnh "đoạn văn đang chọn", bỏ công tắc ép
    // toàn văn của lần chọn trước, dù người dùng có bấm đổi ngữ cảnh thế
    // nào trước đó. Bôi đen bằng chuột luôn đi qua một khoảnh khắc con trỏ
    // rỗng (bấm xuống trước khi kéo), nên đúng lúc này bắt được mọi lần bắt
    // đầu chọn mới.
    if (co) {
      _epToanVanKhiCoVungChon = false;
      // Vùng chọn MỚI cũng tự mở lại hàng Copy/Cắt/Dán nếu người dùng vừa
      // bấm một trong ba nút đó ở lần chọn trước (xem [_anHangCopyCutPaste]).
      _anHangCopyCutPaste = false;
    }
    setState(() {});
  }

  /// Cờ MỘT LẦN: bật ngay khi bấm Copy/Cắt/Dán ở hàng thay 4 nút điều hướng
  /// tệp (xem [_hienHangCopyCutPaste]/`_nutDieuHuongTep`) — ẩn hàng đó ngay
  /// sau khi kích hoạt logic bên trong, đúng yêu cầu "bấm vào 1 trong 3 nút
  /// thì cả 3 nút mất đi ngay". Tự tắt lại (mở hàng ra lần sau) khi có vùng
  /// chọn MỚI xuất hiện — xem `_khiVungChonCoTheDoi`.
  bool _anHangCopyCutPaste = false;

  /// Hàng Copy/Cắt/Dán (thay 4 nút điều hướng tệp, hoặc hiện nổi ở góc trên-
  /// trái khi đã Thu gọn thanh công cụ — xem `_nutDieuHuongTep`/`build`) chỉ
  /// hiện khi CÓ vùng chọn thật, CHƯA bị ẩn tạm sau một lần bấm, VÀ không
  /// đang bật trình ghi âm/thanh tìm kiếm-thay thế/chế độ chọn vị trí chèn
  /// tệp (ba chế độ đó đã có luồng/AppBar riêng, chen vào sẽ đụng chỗ).
  bool _hienHangCopyCutPaste() =>
      _coVungChonGanNhat &&
      !_anHangCopyCutPaste &&
      !_trinhGhiAmMo &&
      !_hienThanhTimKiem &&
      !_dangChonViTriChenFile;

  /// Bấm một trong ba nút Copy/Cắt/Dán ở hàng thay nút điều hướng tệp — ẩn
  /// hàng ngay (xem [_anHangCopyCutPaste]) rồi mới kích hoạt logic thật.
  void _bamCopyCutPasteOHangThayNav(void Function() hanhDong) {
    setState(() => _anHangCopyCutPaste = true);
    hanhDong();
  }

  /// Công tắc "Làm việc với Toàn bộ văn bản"/"Làm việc với Đoạn văn đang
  /// chọn" (mục thứ 4 trong menu AI) — `true` nghĩa là đang ÉP mọi mục AI xử
  /// lý toàn văn dù đang có vùng chọn thật. Chỉ có ý nghĩa khi
  /// [_vungChonThatSu] khác `null`; hết vùng chọn thì công tắc coi như tắt
  /// (không cần tự reset vì [_vungDangChonHopLe] chỉ đọc nó KHI có vùng
  /// chọn thật).
  bool _epToanVanKhiCoVungChon = false;

  /// Khoá để tự đóng-rồi-mở lại `PopupMenuButton` của menu AI ngay sau khi
  /// đảo [_epToanVanKhiCoVungChon] — `PopupMenuButton` không tự vẽ lại nhãn
  /// các mục bên trong trong lúc đang mở, nên phải đóng/mở lại để thấy nhãn
  /// mới ngay (đã hỏi ý người dùng, được chọn cách an toàn hơn thay vì tự
  /// dựng menu riêng để có hiệu ứng chớp nháy tại chỗ).
  final _khoaMenuAI = GlobalKey<PopupMenuButtonState<int>>();

  /// Bấm mục "Làm việc với Toàn bộ văn bản"/"Làm việc với Đoạn văn đang
  /// chọn" — đảo [_epToanVanKhiCoVungChon] rồi mở lại menu AI ngay sau khi
  /// khung hình hiện tại vẽ xong, để nhãn các mục khác cập nhật theo.
  void _doiCheDoLamViecVoiVungChon() {
    setState(() => _epToanVanKhiCoVungChon = !_epToanVanKhiCoVungChon);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _khoaMenuAI.currentState?.showButtonMenu();
    });
  }

  /// Con trỏ tự vẽ — chỉ hiện khi Ô CHỮ đang có tiêu điểm VÀ vùng chọn RỖNG
  /// (con trỏ, không phải đang bôi chọn) — hệt hành vi caret chuẩn.
  Widget _veConTro() {
    if (!_oChu.hasFocus) return const SizedBox.shrink();
    final chon = _boDieuKhien.selection;
    if (!chon.isValid || !chon.isCollapsed) return const SizedBox.shrink();

    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    final khungBox = _khungVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null || khungBox is! RenderBox) {
      return const SizedBox.shrink();
    }
    final re = _timRenderEditable(hopVanBan);
    if (re == null) return const SizedBox.shrink();

    // (VIỆC 4) Con trỏ "chìm" vào nền đỏ khi đứng cạnh ký tự có mauNen gần
    // đỏ — tính màu con trỏ Ở TẦNG STATE (không phải trong painter): tại đây
    // đã có sẵn `_dinhDangHopTaiViTri`, hàm DUY NHẤT tra cứu "hợp 2 bên"
    // (đã dùng cho việc tô sáng nút toolbar và định dạng ký tự mới chèn) —
    // gọi lại ĐÚNG hàm đó với (vt, vt, doDai) là đúng cách tra mauNen tại vị
    // trí con trỏ đang đứng (bên trái: ký tự ngay trước; bên phải: ký tự
    // ngay tại đó), không viết logic tra cứu mới. An toàn hơn hẳn so với để
    // painter tự tra cứu state phức tạp (painter chỉ nhận sẵn một Color).
    final hop = _dinhDangHopTaiViTri(
      chon.baseOffset,
      chon.baseOffset,
      _boDieuKhien.text.length,
    );
    final mauNenTaiConTro = hop.mauNen;
    final mauConTro = (mauNenTaiConTro != null && _mauGanDo(mauNenTaiConTro))
        ? Colors.blue.shade700
        : const Color(0xFFE91E63);

    return SizedBox.expand(
      child: CustomPaint(
        painter: _VeConTro(
          re: re,
          khungBox: khungBox,
          viTri: chon.baseOffset,
          mau: mauConTro,
          hienThi: _conTroDangHien.value,
        ),
      ),
    );
  }

  /// (VIỆC 4) Màu có "gần đỏ" hay không — so với ĐÚNG giá trị đỏ trong bảng
  /// màu nền cơ bản `_NutMauDinhDang._bangMauCoBan` (`Colors.red`, tức
  /// 0xFFF44336) và cả `Colors.red` thuần (0xFFFF0000, trường hợp người
  /// dùng từng đặt qua đường khác) — so bằng khoảng cách từng kênh màu, đơn
  /// giản, O(1), không vòng lặp.
  static bool _mauGanDo(Color mau) {
    bool ganMau(Color goc, {int nguong = 40}) {
      final dr = (mau.r - goc.r).abs() * 255;
      final dg = (mau.g - goc.g).abs() * 255;
      final db = (mau.b - goc.b).abs() * 255;
      return dr <= nguong && dg <= nguong && db <= nguong;
    }

    return ganMau(Colors.red) || ganMau(const Color(0xFFFF0000));
  }

  /// (VIỆC 5c) Overlay các đường kẻ chia văn bản — cùng cách dựng RenderBox
  /// với `_veConTro()`/`_veDanhDauAi()` ở trên.
  Widget _veDuongKeChia() {
    // (SỬA LỖI đường kẻ chia "bóng ma" — LỚP BẢO VỆ THỨ HAI) Văn bản rỗng
    // hoặc chỉ toàn khoảng trắng thì TUYỆT ĐỐI không vẽ đường kẻ nào, dù
    // `_cacViTriDuongKeChia` có lỡ sót offset chưa dọn sạch ở đâu đó.
    // (VIỆC 3) LỚP BẢO VỆ ĐƠN GIẢN NHẤT: tính năng đang TẮT thì KHÔNG vẽ gì
    // cả, dù `_cacViTriDuongKeChia` có chứa gì (kể cả offset còn sót lại từ
    // trước khi tắt) — đảm bảo tắt cài đặt là ẩn NGAY LẬP TỨC ở mọi ghi chú.
    if (!widget.caiDat.tuDongThemDuongKeChia ||
        _cacViTriDuongKeChia.isEmpty ||
        _boDieuKhien.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    final khungBox = _khungVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null || khungBox is! RenderBox) {
      return const SizedBox.shrink();
    }
    final re = _timRenderEditable(hopVanBan);
    if (re == null) return const SizedBox.shrink();

    return SizedBox.expand(
      child: CustomPaint(
        painter: _VeDuongKeChia(
          re: re,
          khungBox: khungBox,
          dsViTri: List<int>.of(_cacViTriDuongKeChia),
          mau: Color(widget.caiDat.mauDuongKeChia)
              .withValues(alpha: widget.caiDat.phanTramMoDuongKeChia / 100),
        ),
      ),
    );
  }

  /// Mấy mức âm gần nhất, để vẽ sóng. Mới nhất nằm ở cuối.
  final List<double> _songAm = List<double>.filled(16, 0);

  /// Chỉ để BÁO có sóng âm mới cho `ValueListenableBuilder` bọc riêng
  /// `ThanhCongCu` — KHÔNG dùng `setState` trần ở `_khiDoiMucAm` (chạy tới
  /// 5 lần/giây suốt lúc ghi âm/nghe) vì đó CHÍNH LÀ nguyên nhân lỗi "web
  /// phải chạm 2 lần" ở các nút trình ghi âm: `setState` trần dựng lại
  /// TOÀN BỘ cây, kể cả AppBar trình ghi âm phía trên — trên web, dựng lại
  /// một `InkWell` đúng lúc ngón tay đang chạm xuống có thể làm gesture
  /// arena của nó bị "reset" giữa chừng, khiến lượt chạm đầu bị nuốt mất
  /// (không xảy ra trên Android vì không có input DOM nào để tranh tiêu
  /// điểm). Y hệt lý do đã sửa cho con trỏ nhấp nháy và đồng hồ đếm giờ
  /// trước đây — lần này tới lượt sóng âm, phần duy nhất còn sót.
  final ValueNotifier<int> _songAmTick = ValueNotifier<int>(0);

  /// Vị trí bắt đầu của câu đang đọc dở, và ĐÚNG đoạn chữ tạm đã chèn ở đó.
  ///
  /// Giữ nguyên văn đoạn chữ chứ không chỉ giữ độ dài: trước mỗi lần ghi, ta
  /// đọc lại trong bài xem đoạn đó còn nguyên ở chỗ cũ không. Còn thì đè lên,
  /// không còn thì coi như câu mới. Nhờ vậy mốc có lệch cũng không lặp chữ.
  int _neo = 0;
  String _chuTam = '';

  /// Các TỪ đã được CHỐT CỨNG trong phiên nghe hiện tại (tách theo khoảng
  /// trắng, giữ nguyên dấu câu dính liền từ) — tính từ `_neo`. Đây là phần
  /// "văn bản thật" của đoạn đang đọc dở: một khi đã vào danh sách này,
  /// giọng nói không được phép tự sửa lại nữa (nguyên tắc 3). Phần CÒN LẠI
  /// của kết quả nhận dạng (sau các từ này) vẫn là "vùng tạm", có thể bị ghi
  /// đè bởi cập nhật kế tiếp.
  ///
  /// Reset về rỗng mỗi khi một phiên/đoạn MỚI bắt đầu — xem `_chotCauDangDoc`
  /// (chốt xong một đoạn dở là mở đường cho đoạn kế) và mọi chỗ gán lại
  /// `_chuTam = ''` để "nhả" hẳn đoạn đang nhảy (gõ phím, dời con trỏ, mở ghi
  /// chú khác, Lùi/Tiến, xoá tất cả...).
  List<String> _tuDaChotTrongPhien = [];

  /// Đúng danh sách TỪ của kết quả PARTIAL gần nhất (dù được chấp nhận hay
  /// không) — dùng để so ĐỘ DÀI TIỀN TỐ CHUNG với partial mới, làm cơ sở
  /// "chốt dần theo độ ổn định" (xem `_khiCoChu`): hai lần cập nhật liên tiếp
  /// cùng chung một tiền tố thì tiền tố đó coi như đã ổn định, chốt cứng
  /// luôn, không cần đợi đồng hồ thời gian nào cả.
  List<String> _partialTruocDo = [];

  /// (RACE CONDITION KHI CHUYỂN PHIÊN — LỚP 2) Bản sao NGẮN HẠN của
  /// `_tuDaChotTrongPhien` (tối đa 20 từ cuối), chụp lại NGAY TRƯỚC khi
  /// `_tuDaChotTrongPhien` bị xoá rỗng lúc chuyển phiên (Android tự ngắt rồi
  /// tự mở lại, bấm phím tắt cắt nhanh, gõ phím). Mục đích DUY NHẤT: phát
  /// hiện một PARTIAL của phiên MỚI lặp lại (một phần hay toàn bộ) nội dung
  /// đã chốt của phiên VỪA đóng — bộ nhớ đệm chốt-dần của phiên mới lúc đó
  /// đang RỖNG nên tự nó không thể nhận ra chuyện này. KHÔNG BAO GIỜ dùng để
  /// sửa/xoá chữ ĐÃ NẰM trong tài liệu — chỉ ảnh hưởng tới việc phiên mới sắp
  /// chèn thêm gì. Xem `_luuBoDemRanhGioiPhien` và nhánh LỚP 2 trong
  /// `_khiCoChu`.
  List<String> _tuVuaChotGanRanhGioiPhien = [];

  /// Hẹn giờ tự dọn `_tuVuaChotGanRanhGioiPhien` — sống rất ngắn (chỉ để bắt
  /// đúng khoảnh khắc chuyển phiên), không giữ vô thời hạn. Cũng bị xoá sớm
  /// hơn ngay khi phiên mới xử lý AN TOÀN xong PARTIAL đầu tiên của nó (xem
  /// `_khiCoChu`), không cần đợi hết giờ.
  Timer? _henHetHanRanhGioiPhien;

  /// (VIỆC 3) Bảng ánh xạ MỖI ký tự tiếng Việt có dấu → đúng MỘT ký tự không
  /// dấu tương ứng (giữ nguyên độ dài chuỗi sau khi thay, để chỉ số vị trí
  /// tìm kiếm trong `_capNhatKetQuaTimKiem` không bị lệch so với văn bản
  /// gốc). Liệt kê THỦ CÔNG, không dùng chuẩn hoá Unicode (NFD) của thư viện
  /// ngoài — an toàn, không phụ thuộc API lạ.
  static const Map<String, String> _bangBoDauTiengViet = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'À': 'A', 'Á': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
    'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
    'Â': 'A', 'Ầ': 'A', 'Ấ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'È': 'E', 'É': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
    'Ê': 'E', 'Ề': 'E', 'Ế': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'Ì': 'I', 'Í': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'Ò': 'O', 'Ó': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
    'Ô': 'O', 'Ồ': 'O', 'Ố': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
    'Ơ': 'O', 'Ờ': 'O', 'Ớ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'Ù': 'U', 'Ú': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
    'Ư': 'U', 'Ừ': 'U', 'Ứ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'Ỳ': 'Y', 'Ý': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
    'đ': 'd', 'Đ': 'D',
  };

  /// (VIỆC 3) Bỏ dấu thanh/dấu phụ tiếng Việt, giữ nguyên số ký tự (mỗi ký
  /// tự trong chuỗi gốc ứng với đúng một ký tự trong kết quả) để không làm
  /// lệch chỉ số vị trí dùng trong tìm kiếm.
  static String _boDauTiengViet(String s) {
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final kyTu = s[i];
      buf.write(_bangBoDauTiengViet[kyTu] ?? kyTu);
    }
    return buf.toString();
  }

  static bool _laKhoangTrang(String kyTu) =>
      kyTu == ' ' || kyTu == '\n' || kyTu == '\t';

  /// Các dấu câu tự động "nhảy" qua trước một dấu cách có sẵn khi gõ tay —
  /// xem chỗ dùng trong `_apDungChinhSuaNguoiDung`.
  static const _kyTuDacBiet = {'.', ',', ';', '?', '!', ':'};

  /// Bảy ký tự "Chuẩn hoá các cặp dấu đóng-mở ngoặc" theo dõi — xem
  /// `_chuanHoaNgoacSauKhiGo`.
  static const _kyTuNgoacCanChuanHoa = {'(', ')', '{', '}', '[', ']', '"'};

  /// (Tính năng "Chuẩn hoá các cặp dấu đóng-mở ngoặc" — xem Cài đặt) Gọi
  /// SAU MỖI lần gõ tay đúng một ký tự thuộc `_kyTuNgoacCanChuanHoa`, tại
  /// vị trí [vt] trong văn bản hiện tại (`_boDieuKhien.text` đã bao gồm ký
  /// tự vừa gõ) — xoá dấu cách thừa ngay SAU dấu mở / ngay TRƯỚC dấu đóng
  /// của ĐÚNG MỘT cặp mà ký tự vừa gõ này hoàn thành.
  ///
  /// (),{},[]: quét ngăn xếp riêng cho ĐÚNG loại vừa gõ, TOÀN VĂN BẢN — an
  /// toàn để làm vậy vì hình dạng ký tự tự phân biệt mở/đóng, nên các cặp
  /// ĐÃ chuẩn hoá từ trước không đổi vai trò dù gõ thêm ký tự khác ở chỗ
  /// khác (quét lại chỉ là xác nhận lại, không có gì để xoá thêm ở đó, nên
  /// vô hại). Chỉ ký tự ĐÓNG mới có việc để làm (ghép với dấu mở GẦN NHẤT
  /// còn "mồ côi"); dấu mở vừa gõ chưa có gì để chuẩn hoá, bỏ qua.
  ///
  /// Ngoặc kép "": KHÔNG có hình dạng riêng để phân biệt mở/đóng như ba
  /// loại trên, nên KHÔNG được áp dụng kiểu "quét lại toàn bộ" như trên.
  ///
  /// (YÊU CẦU MỚI — thuật toán "láng giềng gần nhất") Mỗi lần gõ một dấu
  /// nháy MỚI (tại [vt]), CHỈ xét quan hệ của nó với các dấu nháy GẦN NÓ
  /// NHẤT — không đụng gì tới các cặp khác đã ổn định ở xa hơn trong bài:
  ///
  /// 1. Tìm 2 dấu nháy GẦN NHẤT ở PHÍA TRƯỚC [vt] (nếu có).
  ///    - Không có dấu nào phía trước: dấu mới vẫn "cô đơn" — qua bước 2.
  ///    - Chỉ có ĐÚNG 1 dấu phía trước: tự động ghép cặp với dấu đó, xong.
  ///    - Có ĐỦ 2 dấu: xét xem HAI dấu đó (không phải dấu mới) đã là một
  ///      cặp HỢP LỆ chưa (bên phải dấu xa hơn + bên trái dấu gần hơn đều
  ///      không có dấu cách). Hợp lệ rồi thì để yên, không đụng — dấu mới
  ///      vẫn cô đơn, qua bước 2. CHƯA hợp lệ thì dấu GẦN hơn (trong 2 dấu
  ///      đó) bị coi là đang cô đơn — ghép cặp nó với dấu mới, xong.
  /// 2. (CHỈ chạy khi dấu mới vẫn cô đơn sau bước 1) Làm Y HỆT bước 1 nhưng
  ///    xét 2 dấu nháy gần nhất ở PHÍA SAU [vt] thay vì phía trước.
  ///
  /// Ghép cặp xong thì áp dụng đúng [chuanHoaMotCap] (xoá dấu cách thừa
  /// ngay sau dấu mở/ngay trước dấu đóng) như ba loại ngoặc khác.
  void _chuanHoaNgoacSauKhiGo(String kyTuVuaGo, int vt) {
    if (!widget.caiDat.tuDongChuanHoaNgoac) return;
    if (!_kyTuNgoacCanChuanHoa.contains(kyTuVuaGo)) return;
    final vb = _boDieuKhien.text;
    if (vt < 0 || vt >= vb.length || vb[vt] != kyTuVuaGo) return;

    final canXoa = <int>{};
    void chuanHoaMotCap(int moTai, int dongTai) {
      if (moTai + 1 < dongTai && vb[moTai + 1] == ' ') canXoa.add(moTai + 1);
      if (dongTai - 1 > moTai && vb[dongTai - 1] == ' ') canXoa.add(dongTai - 1);
    }

    if (kyTuVuaGo == '"') {
      // [a] luôn ở vị trí SỚM HƠN [b] trong văn bản (a = dấu "mở" của cặp
      // đang xét, b = dấu "đóng") — hợp lệ khi không có dấu cách ngay sau
      // [a] và ngay trước [b].
      bool laCapHopLe(int a, int b) =>
          !(a + 1 < b && vb[a + 1] == ' ') && !(b - 1 > a && vb[b - 1] == ' ');

      final viTriTatCa = <int>[
        for (var i = 0; i < vb.length; i++) if (vb[i] == '"') i,
      ];
      final viTriNew = viTriTatCa.indexOf(vt);
      final truoc = viTriTatCa.sublist(0, viTriNew);
      final sau = viTriTatCa.sublist(viTriNew + 1);

      int? banKetCap;
      if (truoc.isNotEmpty) {
        final ganNhat = truoc.last;
        if (truoc.length == 1) {
          banKetCap = ganNhat;
        } else {
          final xaHon = truoc[truoc.length - 2];
          if (!laCapHopLe(xaHon, ganNhat)) banKetCap = ganNhat;
        }
      }
      if (banKetCap == null && sau.isNotEmpty) {
        final ganNhat = sau.first;
        if (sau.length == 1) {
          banKetCap = ganNhat;
        } else {
          final xaHon = sau[1];
          if (!laCapHopLe(ganNhat, xaHon)) banKetCap = ganNhat;
        }
      }
      if (banKetCap != null) {
        chuanHoaMotCap(
          banKetCap < vt ? banKetCap : vt,
          banKetCap < vt ? vt : banKetCap,
        );
      }
    } else {
      const laMoNgoac = {'(', '{', '['};
      if (laMoNgoac.contains(kyTuVuaGo)) return; // dấu mở: chưa có gì để làm.
      const moUngVoiDong = {')': '(', '}': '{', ']': '['};
      final moNgoac = moUngVoiDong[kyTuVuaGo]!;
      // Hình dạng tự phân biệt mở/đóng nên quét TOÀN VĂN BẢN cho đúng loại
      // này là AN TOÀN — các cặp đã chuẩn hoá từ trước không đổi vai trò gì
      // cả, quét lại chỉ xác nhận lại (không có gì để xoá thêm ở đó).
      final ngan = <int>[];
      for (var i = 0; i <= vt; i++) {
        if (vb[i] == moNgoac) {
          ngan.add(i);
        } else if (vb[i] == kyTuVuaGo && ngan.isNotEmpty) {
          final moTai = ngan.removeLast();
          if (i == vt) chuanHoaMotCap(moTai, i);
        }
      }
    }

    if (canXoa.isEmpty) return;
    final ds = canXoa.toList()..sort((a, b) => b.compareTo(a));
    var moi = vb;
    var neoMoi = _neo;
    for (final v in ds) {
      moi = moi.replaceRange(v, v + 1, '');
      _dieuChinhLoiChinhTaSauKhiSua(v, 1, 0);
      _dieuChinhVungToanVanSauKhiSua(v, 1, 0);
      if (neoMoi > v) neoMoi--;
    }
    _neo = neoMoi;
    _ghiVaoO(moi, _neo);
  }

  /// Kiểu chữ của ô soạn thảo — dùng chung cho cả TextField thật lẫn
  /// TextPainter đo vị trí ký tự cuối (`_chamCuoiVanBan`).
  ///
  /// `inherit: false` KHÔNG PHẢI để trang trí — nếu để mặc định (`true`),
  /// Material tự trộn thêm kiểu chữ của theme (ví dụ letterSpacing) vào
  /// TextField lúc vẽ THẬT, nhưng TextPainter đo ở `_chamCuoiVanBan` không hề
  /// biết chuyện trộn đó nên đo theo đúng mỗi `_kieuVanBan` trần trụi — hai
  /// bên ra hai độ rộng chữ khác nhau, càng lệch dần theo từng ký tự, khiến
  /// chấm tròn trôi dần ra khỏi vị trí thật khi câu càng dài. Khoá cứng bằng
  /// `inherit: false` (kèm đủ màu chữ, vì lúc đó không còn gì để kế thừa)
  /// thì TextField dùng ĐÚNG y hệt kiểu chữ này, không trộn thêm gì — khớp
  /// tuyệt đối với TextPainter.
  static const _kieuVanBan = TextStyle(
    fontSize: 17,
    height: 1.5,
    color: Color(0xFF1F1F1F),
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    inherit: false,
  );

  /// Khoá của chính TextField và của Stack bọc ngoài nó — `_chamCuoiVanBan`
  /// dùng hai khoá này để tìm thẳng `RenderEditable` THẬT đang vẽ ô soạn
  /// thảo, thay vì tự đo lại bằng một `TextPainter` riêng.
  /// (SỬA LỖI v120) KHÔNG còn `final` — xem `_lamMoiOVanBanDeThoatKetBanPhimAo`.
  GlobalKey _oVanBanKey = GlobalKey();
  final _khungVanBanKey = GlobalKey();

  /// Dò xuống cây RenderObject tìm `RenderEditable` — chính là render object
  /// mà `TextField` dùng để vẽ chữ và đặt con trỏ thật. `visitChildren` không
  /// có cách dừng giữa chừng nên vẫn duyệt hết, nhưng `??=` đảm bảo chỉ giữ
  /// kết quả tìm thấy ĐẦU TIÊN.
  RenderEditable? _timRenderEditable(RenderObject o) {
    if (o is RenderEditable) return o;
    RenderEditable? ket;
    o.visitChildren((con) => ket ??= _timRenderEditable(con));
    return ket;
  }

  /// Chữ gợi ý hiện khi bài còn trống trơn — thay cho `InputDecoration
  /// .hintText` (chỉ nhận chuỗi trần) vì cần chèn một icon "?" tròn NGAY
  /// GIỮA câu, y hệt icon nút Hướng dẫn ở thanh công cụ ngang
  /// (`Icons.help_outline_rounded`), không phải ký tự Unicode giả icon.
  Widget _goiYTrong() {
    if (_boDieuKhien.text.isNotEmpty) return const SizedBox.shrink();
    const mauChuMo = Color(0xFF9E9E9E);
    // (YÊU CẦU MỚI) Màn hình RẤT hẹp ẩn hẳn nút "? Hướng dẫn" khỏi thanh
    // công cụ (xem `_nguongManHinhRatHep` ở `thanh_cong_cu.dart`) — câu gợi
    // ý này phải chỉ đúng đường, đổi sang nhắc nút "i" (bấm nút "i" mới
    // hiện lại nút Hướng dẫn ở hàng phụ) kèm icon tròn có chữ "i", không
    // còn icon "?" nữa. CHỈ đổi ở màn hình rất hẹp — màn hình thường vẫn
    // giữ nguyên câu + icon "?" như cũ.
    final ratHep = MediaQuery.sizeOf(context).width < 420;
    final cacDong = <InlineSpan>[
      TextSpan(
        text: '${Ch.goiYTrongDongGoChu(ngonNguHienTai.value)}\n'
            '${Ch.goiYTrongDongSongSong(ngonNguHienTai.value)}\n'
            '${Ch.goiYTrongDongHuongDan(ratHep, ngonNguHienTai.value)}',
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(
          ratHep ? Icons.info_outline : Icons.help_outline_rounded,
          size: 16,
          color: mauChuMo,
        ),
      ),
      const TextSpan(text: ')'),
    ];
    // Riêng bản WEB (không đụng bản Android/iOS gốc): thêm dòng chỉ đường
    // khi micro trục trặc + tên thiết bị đang dùng (đoán/chọn tay, xem
    // `_thietBiHienTai`) + số phiên bản web + gợi ý dùng Chrome.
    if (kIsWeb) {
      cacDong.addAll([
        TextSpan(
          text: Ch.goiYTrongDongMicroTrucTrac(ngonNguHienTai.value),
        ),
        TextSpan(
          text: Ch.goiYTrongDongDangDungBoMicro(ngonNguHienTai.value),
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
        TextSpan(
          text: _thietBiHienTai.ten,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            color: Color(0xFFD32F2F),
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(
          text: Ch.goiYTrongDongPhienBanWeb(phienBanWebDayDu, ngonNguHienTai.value) +
              Ch.goiYTrongDongDungChrome(ngonNguHienTai.value),
        ),
      ]);
    }
    // (YÊU CẦU MỚI) Dòng cuối cùng của chữ gợi ý — áp dụng cho cả web và
    // Android/iOS gốc.
    cacDong.add(
      TextSpan(text: Ch.goiYTrongDongTuDongLuu(ngonNguHienTai.value)),
    );
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 17, height: 1.5, color: mauChuMo),
        children: cacDong,
      ),
    );
  }

  /// Chấm tròn tím báo hiệu cuối văn bản, luôn bám sát ngay sau ký tự cuối
  /// cùng.
  ///
  /// Trước đây tự đo toạ độ (bằng `RenderEditable.getLocalRectForCaret`)
  /// NGAY TRONG hàm này — tức là ngay lúc DỰNG WIDGET (build). Khi bàn phím
  /// ảo bật/tắt, Flutter dựng lại widget TRƯỚC khi kịp tính lại bố cục của
  /// khung mới trong cùng khung hình — đo lúc đó có lúc trúng bố cục CŨ,
  /// chấm tròn vẽ ra lệch khỏi ký tự cuối một khung hình. Sửa bằng cách dời
  /// việc đo toạ độ vào `_VeChamCuoiVanBan.paint()` — hàm đó chỉ chạy SAU
  /// KHI bố cục khung hình đã xong hẳn, nên luôn đo đúng. Ở đây chỉ còn tìm
  /// `re`/`khungBox` (rẻ, không đọc bố cục) rồi giao painter tự đo lúc vẽ.
  Widget _chamCuoiVanBan() {
    if (!widget.caiDat.chamCuoiVanBanBat) return const SizedBox.shrink();
    final chu = _boDieuKhien.text;
    if (chu.isEmpty) return const SizedBox.shrink();

    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    final khungBox = _khungVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null || khungBox is! RenderBox) {
      return const SizedBox.shrink();
    }
    final re = _timRenderEditable(hopVanBan);
    if (re == null) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _chamCuoiMoDam ? 0.35 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: _ChamCuoiVanBan(
        re: re,
        khungBox: khungBox,
        viTri: chu.length,
        duongKinhNgoai: 17.0,
        duongKinhTrong: 8.0,
        mau: Color(widget.caiDat.mauChamCuoiVanBan),
      ),
    );
  }

  /// Mọi gạch của các đánh dấu AI — gạch chân lượn sóng (lỗi chính tả: đỏ
  /// đậm; đoạn đề xuất thay thế: xanh lá mảnh; đoạn cần xoá: xanh lá mảnh)
  /// VÀ gạch giữa thân thẳng, vàng đậm (đoạn cần thay thế, đoạn cần xoá) —
  /// vẽ chung ở một lớp RIÊNG nằm DƯỚI chữ (xem giải thích ở nơi ghép layer
  /// trong `build`), thay vì gắn qua TextStyle.decoration, để chữ luôn luôn
  /// nổi trên mọi gạch, không bao giờ bị che (layer chồng layer).
  ///
  /// Chỉ dựng danh sách vùng LOGIC ở đây (build) — không đo toạ độ điểm ảnh;
  /// việc đo dời hẳn vào `_VeDanhDauAi.paint()` để tránh lệch khung hình lúc
  /// bàn phím ảo bật/tắt (xem giải thích ở đó).
  Widget _veDanhDauAi() {
    if (_boDieuKhien.loi.isEmpty &&
        _boDieuKhien.khongPhuHop.isEmpty &&
        _boDieuKhien.canXoa.isEmpty &&
        _boDieuKhien.tuDien.isEmpty &&
        _boDieuKhien.lienKet.isEmpty) {
      return const SizedBox.shrink();
    }

    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    final khungBox = _khungVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null || khungBox is! RenderBox) {
      return const SizedBox.shrink();
    }
    final re = _timRenderEditable(hopVanBan);
    if (re == null) return const SizedBox.shrink();

    final vb = _boDieuKhien.text;
    final dsVung = <_VungDanhDauAi>[];

    void themVung(
      int batDau,
      int ketThuc,
      Color mau,
      double day, {
      bool lienSong = true,
      bool giuaThan = false,
    }) {
      if (batDau < 0 || ketThuc > vb.length || batDau >= ketThuc) return;
      dsVung.add(_VungDanhDauAi(
        batDau: batDau,
        ketThuc: ketThuc,
        mau: mau,
        day: day,
        lienSong: lienSong,
        giuaThan: giuaThan,
      ));
    }

    for (final l in _boDieuKhien.loi) {
      themVung(l.batDau, l.ketThuc, _mauGachChanLoi, _damGachChanLoi);
    }
    for (final t in _boDieuKhien.tuDien) {
      themVung(t.batDau, t.ketThuc, _mauGachChanTuDien, _damGachChanLoi);
    }
    for (final k in _boDieuKhien.lienKet) {
      themVung(k.batDau, k.ketThuc, _mauGachChanLienKet, _damGachChanLoi);
    }
    for (final k in _boDieuKhien.khongPhuHop) {
      if (k.nhapNhayMau != null) continue; // Đang nhấp nháy — không vẽ gạch.
      themVung(k.batDauGoc, k.ketThucGoc, _mauGachGiuaThan, _damGachChanLoi,
          lienSong: false, giuaThan: true);
      themVung(k.batDauDeXuat, k.ketThucDeXuat, _mauGachChanDeXuat, _damGachChanCanXoa);
    }
    for (final x in _boDieuKhien.canXoa) {
      if (x.dangNhapNhay) continue; // Đang nhấp nháy — không vẽ gạch.
      themVung(x.batDau, x.ketThuc, _mauGachChanCanXoa, _damGachChanCanXoa);
      themVung(x.batDau, x.ketThuc, _mauGachGiuaThan, _damGachChanLoi,
          lienSong: false, giuaThan: true);
    }
    if (dsVung.isEmpty) return const SizedBox.shrink();

    return SizedBox.expand(
      child: CustomPaint(painter: _VeDanhDauAi(re: re, khungBox: khungBox, dsVung: dsVung)),
    );
  }

  /// Nền gradient đỏ→vàng của mọi kết quả tìm kiếm — cùng cách đo toạ độ
  /// NGAY TRONG `paint()` như `_veDanhDauAi()` ở trên (xem giải thích đầy đủ
  /// tại `_VeDanhDauAi`), để không lệch khung hình khi cuộn/bàn phím ảo.
  Widget _veTimKiem() {
    if (_ketQuaTimKiem.isEmpty || _oTimKiem.text.isEmpty) return const SizedBox.shrink();

    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    final khungBox = _khungVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null || khungBox is! RenderBox) return const SizedBox.shrink();
    final re = _timRenderEditable(hopVanBan);
    if (re == null) return const SizedBox.shrink();

    return SizedBox.expand(
      child: CustomPaint(
        painter: _VeTimKiem(
          re: re,
          khungBox: khungBox,
          ketQua: _ketQuaTimKiem,
          doDaiTuKhoa: _oTimKiem.text.length,
          chiSoHienTai: _chiSoTimKiemHienTai,
        ),
      ),
    );
  }

  /// (VIỆC 4) Nền gradient đỏ→vàng NHẤP NHÁY 1 giây của "Thay chỗ này"/
  /// "Tất cả" — cùng cách đo toạ độ và cùng lớp "dưới chữ" như `_veTimKiem()`
  /// ở trên, nhưng đọc từ `_boDieuKhien.hieuUngThayThe` (danh sách hiệu ứng
  /// tạm thời) thay vì `_ketQuaTimKiem`.
  Widget _veHieuUngThayThe() {
    if (_boDieuKhien.hieuUngThayThe.isEmpty) return const SizedBox.shrink();

    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    final khungBox = _khungVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null || khungBox is! RenderBox) return const SizedBox.shrink();
    final re = _timRenderEditable(hopVanBan);
    if (re == null) return const SizedBox.shrink();

    return SizedBox.expand(
      child: CustomPaint(
        painter: _VeHieuUngThayThe(
          re: re,
          khungBox: khungBox,
          vungs: _boDieuKhien.hieuUngThayThe,
        ),
      ),
    );
  }

  /// Ctrl+F LUÔN THẮNG để đóng thanh tìm kiếm, kể cả khi con trỏ đang nhấp
  /// nháy TRONG ô Tìm kiếm/ô Thay thế — `EditableText` của chính ô đó có thể
  /// "nuốt" tổ hợp phím trước khi nó lan lên `Shortcuts` ở tầng cha. Bọc
  /// riêng một `Focus.onKeyEvent` quanh MỖI ô để tự bắt Ctrl+F và đóng thẳng,
  /// không trông chờ `Shortcuts` ở tầng trên nhận được sự kiện.
  KeyEventResult _khiPhimTrongOTimKiem(FocusNode node, KeyEvent su) {
    if (su is! KeyDownEvent) return KeyEventResult.ignored;
    if (su.logicalKey == LogicalKeyboardKey.keyF &&
        HardwareKeyboard.instance.isControlPressed) {
      _dongTimKiem();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Thanh tìm kiếm nổi lên trên cùng khung soạn thảo — ô nhập, số kết quả,
  /// mũi tên lên/xuống, nút xoá và nút "Tắt" (đóng hẳn).
  Widget _thanhTimKiem() {
    // Màn hình hẹp: bó sát các nút bên phải lại với nhau (bỏ đệm 48x48 mặc
    // định của IconButton, khoảng cách giữa các nút về 0) để khung nhập
    // "Tìm trong văn bản..." được giãn rộng ra tối đa — màn hình hẹp vốn đã
    // ít chỗ ngang, chữ trong khung dễ bị khuất nếu không nhường thêm.
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;
    const kichThuocNutNho = BoxConstraints.tightFor(width: 36, height: 36);
    return Container(
      key: const ValueKey('thanhTimKiem'),
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onKeyEvent: _khiPhimTrongOTimKiem,
              child: TextField(
                controller: _oTimKiem,
                focusNode: _focusTimKiem,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: Ch.timTrongVanBan(ngonNguHienTai.value),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _dieuHuongTimKiem(1),
              ),
            ),
          ),
          SizedBox(width: manHinhHep ? 4 : 8),
          Text(
            _ketQuaTimKiem.isEmpty
                ? '0/0'
                : '${_chiSoTimKiemHienTai + 1}/${_ketQuaTimKiem.length}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: Ch.ketQuaTruoc(ngonNguHienTai.value),
            onPressed: _ketQuaTimKiem.isEmpty ? null : () => _dieuHuongTimKiem(-1),
            visualDensity: manHinhHep ? VisualDensity.compact : VisualDensity.standard,
            constraints: manHinhHep ? kichThuocNutNho : null,
            padding: manHinhHep ? EdgeInsets.zero : const EdgeInsets.all(8),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: Ch.ketQuaTiepTheo(ngonNguHienTai.value),
            onPressed: _ketQuaTimKiem.isEmpty ? null : () => _dieuHuongTimKiem(1),
            visualDensity: manHinhHep ? VisualDensity.compact : VisualDensity.standard,
            constraints: manHinhHep ? kichThuocNutNho : null,
            padding: manHinhHep ? EdgeInsets.zero : const EdgeInsets.all(8),
          ),
          _NutXoaCoThongBao(
            tooltip: Ch.xoaNoiDungTim(ngonNguHienTai.value),
            onXoa: () => _oTimKiem.clear(),
            nho: manHinhHep,
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: manHinhHep
                  ? const EdgeInsets.symmetric(horizontal: 8)
                  : const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: manHinhHep ? const Size(0, 36) : null,
            ),
            onPressed: _dongTimKiem,
            child: Text(Ch.tat(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
  }

  /// Thanh "Thay thế" — nằm NGAY DƯỚI thanh tìm kiếm, chỉ hiện khi có ít
  /// nhất một kết quả tìm kiếm (`_ketQuaTimKiem.isNotEmpty`), tự ẩn ngay khi
  /// về 0 (B6).
  Widget _thanhThayThe() {
    // Xem giải thích ở `_thanhTimKiem` — cùng lý do, cùng cách bó nhỏ trên
    // màn hình hẹp.
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;
    const kichThuocNutNho = BoxConstraints.tightFor(width: 36, height: 36);
    final demNutChuHep = manHinhHep
        ? const EdgeInsets.symmetric(horizontal: 6)
        : const EdgeInsets.symmetric(horizontal: 16);
    return Container(
      key: const ValueKey('thanhThayThe'),
      width: double.infinity,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onKeyEvent: _khiPhimTrongOTimKiem,
              child: TextField(
                controller: _oThayThe,
                focusNode: _focusThayThe,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: Ch.thayTheKyTuTrenBangGi(ngonNguHienTai.value),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          SizedBox(width: manHinhHep ? 4 : 8),
          TextButton(
            style: TextButton.styleFrom(
              padding: demNutChuHep,
              minimumSize: manHinhHep ? const Size(0, 36) : null,
            ),
            onPressed: _ketQuaTimKiem.isEmpty ? null : _thayChoNay,
            child: Text(Ch.thayChoNay(ngonNguHienTai.value)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: demNutChuHep,
              minimumSize: manHinhHep ? const Size(0, 36) : null,
            ),
            onPressed: _ketQuaTimKiem.isEmpty ? null : _xacNhanThayTatCa,
            child: Text(Ch.tatCaVienBan(ngonNguHienTai.value)),
          ),
          _NutXoaCoThongBao(
            tooltip: Ch.xoaNoiDungThayThe(ngonNguHienTai.value),
            onXoa: () => _oThayThe.clear(),
            nho: manHinhHep,
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            tooltip: Ch.caiDatTimKiemVaThayThe(ngonNguHienTai.value),
            onPressed: _moCaiDatTimKiemVaHuongDanThayThe,
            visualDensity: manHinhHep ? VisualDensity.compact : VisualDensity.standard,
            constraints: manHinhHep ? kichThuocNutNho : null,
            padding: manHinhHep ? EdgeInsets.zero : const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  /// Thanh công cụ định dạng thủ công — một dòng ngang dưới thanh Lùi/Tiến/
  /// Lưu/Tìm kiếm, chỉ hiện khi ô soạn thảo có/từng có nội dung (luôn hiện,
  /// đơn giản hơn ẩn/hiện theo điều kiện).
  Widget _thanhDinhDangThuCong() {
    // Mục 7: chiều cao mỗi nút giảm hết mức còn bấm trúng — bỏ padding mặc
    // định 8px mọi phía của IconButton (VisualDensity.compact + constraints
    // riêng), giữ đúng 36px mỗi chiều (vẫn ~ ngưỡng chạm tối thiểu chuẩn).
    const kichThuocNut = BoxConstraints.tightFor(width: 36, height: 36);
    const matDoNut = VisualDensity.compact;

    Widget nut(IconData icon, bool bat, String loai, String nhan) {
      return IconButton(
        iconSize: 20,
        tooltip: nhan,
        icon: Icon(icon),
        visualDensity: matDoNut,
        constraints: kichThuocNut,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: bat ? const Color(0xFFE3F2FD) : null,
          foregroundColor: bat ? const Color(0xFF1565C0) : const Color(0xFF5F6368),
        ),
        onPressed: () => _apDungDinhDang(loai),
      );
    }

    Widget nutChu(String chu, bool bat, String loai, String nhan) {
      return IconButton(
        iconSize: 20,
        tooltip: nhan,
        icon: Text(chu, style: const TextStyle(fontWeight: FontWeight.bold)),
        visualDensity: matDoNut,
        constraints: kichThuocNut,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: bat ? const Color(0xFFE3F2FD) : null,
          foregroundColor: bat ? const Color(0xFF1565C0) : const Color(0xFF5F6368),
        ),
        onPressed: () => _apDungDinhDang(loai),
      );
    }

    // Mục 12: `Wrap` thay cho `Row` trong `SingleChildScrollView` — màn
    // hình hẹp không đủ chỗ ngang cho hết các nút thì tự động xuống dòng,
    // không cuộn ngang (dễ bỏ sót nút nằm ngoài khung nhìn hơn xuống dòng).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          nut(Icons.format_bold, _damDangCho, 'dam', Ch.damTooltip(ngonNguHienTai.value)),
          nut(Icons.format_italic, _nghiengDangCho, 'nghieng', Ch.nghiengTooltip(ngonNguHienTai.value)),
          nut(Icons.format_underlined, _gachChanDangCho, 'gachChan', Ch.gachChanTooltip(ngonNguHienTai.value)),
          nut(Icons.strikethrough_s, _gachNganDangCho, 'gachNgang', Ch.gachNgangTooltip(ngonNguHienTai.value)),
          nutChu('x²', _treMuDangCho, 'treMu', Ch.treMuTooltip(ngonNguHienTai.value)),
          nutChu('x₂', _treChanDangCho, 'treChan', Ch.treChanTooltip(ngonNguHienTai.value)),
          _NutMauDinhDang(
            nhan: Ch.mauChuTooltip(ngonNguHienTai.value),
            bat: _mauChuDangCho != null,
            mauHienThi: widget.caiDat.mauChuGanNhat,
            khiBam: () => _apDungDinhDang('mauChu'),
            khiChonMau: (m) {
              widget.caiDat.datMauChuGanNhat(m);
              setState(() {});
              _apDungDinhDang('mauChu', mau: m);
            },
            choPhepTrongSuot: false,
          ),
          _NutMauDinhDang(
            nhan: Ch.mauNenChuTooltip(ngonNguHienTai.value),
            bat: _mauNenDangCho != null,
            mauHienThi: widget.caiDat.mauNenGanNhat,
            khiBam: () => _apDungDinhDang('mauNen'),
            khiChonMau: (m) {
              widget.caiDat.datMauNenGanNhat(m);
              setState(() {});
              _apDungDinhDang('mauNen', mau: m);
            },
            choPhepTrongSuot: true,
            laMauNen: true,
          ),
          IconButton(
            iconSize: 20,
            tooltip: Ch.xoaDinhDangVanBan(ngonNguHienTai.value),
            icon: const Icon(Icons.format_clear),
            visualDensity: matDoNut,
            constraints: kichThuocNut,
            padding: EdgeInsets.zero,
            onPressed: () => _apDungDinhDang('xoaDinhDang'),
          ),
          IconButton(
            iconSize: 20,
            tooltip: Ch.tichChonCheckbox(ngonNguHienTai.value),
            icon: const Text('✅', style: TextStyle(fontSize: 16)),
            visualDensity: matDoNut,
            constraints: kichThuocNut,
            padding: EdgeInsets.zero,
            onPressed: _bamNutTichChon,
          ),
          // (YÊU CẦU MỚI) "Aa" — Hoán đổi chữ Hoa/chữ thường của vùng chọn,
          // xem `_apDungHoanDoiChuHoaThuong`.
          IconButton(
            iconSize: 20,
            tooltip: Ch.hoanDoiHoaThuong(ngonNguHienTai.value),
            icon: const Text('Aa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            visualDensity: matDoNut,
            constraints: kichThuocNut,
            padding: EdgeInsets.zero,
            onPressed: () => _apDungHoanDoiChuHoaThuong(),
          ),
          PopupMenuButton<int>(
            tooltip: Ch.chonKieuHoaThuong(ngonNguHienTai.value),
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            padding: EdgeInsets.zero,
            onSelected: (kieu) => _apDungHoanDoiChuHoaThuong(kieuCoDinh: kieu),
            // (SỬA LỖI — màu tô vùng chọn vẫn mất nếu ĐÓNG menu mà KHÔNG
            // chọn mục nào, ví dụ bấm ra ngoài) `onSelected` chỉ chạy khi có
            // chọn mục; thêm `onCanceled` để trả tiêu điểm lại ngay cả khi
            // đóng menu theo cách khác.
            onCanceled: _giuFocusOChuSauKhiBam,
            itemBuilder: (ctx) {
              final chon = _boDieuKhien.selection;
              if (!chon.isValid || chon.isCollapsed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                  if (mounted) {
                    hienThongBaoGiua(
                      context,
                      Ch.chonVungVanBanTruocKhiHoanDoiHoaThuong(ngonNguHienTai.value),
                    );
                  }
                });
                return [
                  PopupMenuItem<int>(enabled: false, child: Text(Ch.chuaCoVungChon(ngonNguHienTai.value))),
                ];
              }
              return [
                PopupMenuItem(value: 0, child: Text(Ch.vietHoaChuDauMoiTu(ngonNguHienTai.value))),
                PopupMenuItem(value: 1, child: Text(Ch.vietHoaTatCaKyTu(ngonNguHienTai.value))),
                PopupMenuItem(value: 2, child: Text(Ch.vietThuongTatCaKyTu(ngonNguHienTai.value))),
                PopupMenuItem(value: 3, child: Text(Ch.vietHoaChuDauCau(ngonNguHienTai.value))),
              ];
            },
          ),
          // Nút Ghim — luôn ở CUỐI. Ghim thì thanh này hết tự ẩn sau mỗi lần
          // bấm nút định dạng (xem `_dongThanhDinhDangNeuChuaGhim`). Bấm
          // chính nút Ghim thì KHÔNG tự ẩn thanh (khác các nút định dạng
          // khác) — người dùng cần thấy ngay trạng thái ghim vừa đổi.
          IconButton(
            iconSize: 20,
            tooltip: widget.caiDat.ghimThanhDinhDang
                ? Ch.boGhimThanhCongCuDinhDang(ngonNguHienTai.value)
                : Ch.ghimThanhCongCuDinhDang(ngonNguHienTai.value),
            icon: const Icon(Icons.push_pin),
            visualDensity: matDoNut,
            constraints: kichThuocNut,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor:
                  widget.caiDat.ghimThanhDinhDang ? const Color(0xFFE3F2FD) : null,
              foregroundColor: widget.caiDat.ghimThanhDinhDang
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF5F6368),
            ),
            onPressed: () async {
              final ghimMoi = !widget.caiDat.ghimThanhDinhDang;
              await widget.caiDat.datGhimThanhDinhDang(ghimMoi);
              unawaited(_dayCaiDatDongBoTaiKhoan({'ghimThanhDinhDang': ghimMoi}));
              if (!mounted) return;
              setState(() {});
              if (ghimMoi) {
                hienThongBaoGiua(context, Ch.daGhimThanhCongCuDinhDang(ngonNguHienTai.value));
              }
            },
          ),
        ],
      ),
    );
  }

  /// Lịch sử Lùi lại/Tiến tới. Mỗi điểm mốc là trạng thái TRỌN VẸN của bài
  /// (chữ + vị trí con trỏ) tại một ranh giới có ý nghĩa — KHÔNG phải từng
  /// ký tự một. Ranh giới đó là: bắt đầu một đợt gõ tay mới
  /// (_apDungChinhSuaNguoiDung, chỉ lần đầu của đợt), hoặc bắt đầu một lượt
  /// micro mới (_batMicro). Nhờ đặt mốc đúng hai chỗ này, mỗi lần Lùi lại
  /// luôn lùi vừa đúng một đợt gõ hoặc một lượt nói trọn vẹn — không cắt
  /// ngang giữa chừng, và tự nhiên phân biệt được đợt đó là gõ tay hay nói,
  /// vì hai đợt hai nguồn không bao giờ trộn chung một điểm mốc.
  /// (NÂNG CẤP bộ nhớ đệm theo từng tệp) Mỗi tệp ghi chú có RIÊNG một cặp
  /// danh sách Lùi lại/Tiến tới, khoá theo `id` — không còn dùng chung một
  /// cặp cho mọi tệp (trước đây `.clear()` khi chuyển tệp làm mất sạch mốc
  /// của tệp cũ, quay lại tệp đó là mất luôn). `_lichSuLui`/`_lichSuToi` bên
  /// dưới là getter trỏ đúng vào cặp của `_ghiChuHienTai.id` — mọi chỗ gọi
  /// `.add`/`.clear`/`.removeAt`/... ở khắp file vẫn viết y hệt như cũ,
  /// không cần sửa gì thêm, vì List trả về là THAM CHIẾU thật nằm trong Map.
  final Map<String, List<_TrangThaiVanBan>> _lichSuLuiTheoTep = {};
  final Map<String, List<_TrangThaiVanBan>> _lichSuToiTheoTep = {};
  List<_TrangThaiVanBan> get _lichSuLui =>
      _lichSuLuiTheoTep.putIfAbsent(_ghiChuHienTai.id, () => []);
  List<_TrangThaiVanBan> get _lichSuToi =>
      _lichSuToiTheoTep.putIfAbsent(_ghiChuHienTai.id, () => []);
  static const _soLuongLichSuToiDa = 50;

  /// (YÊU CẦU MỚI — bớt hại RAM khi có NHIỀU tệp) Mốc 50/tệp ở trên chỉ
  /// chặn MỘT tệp phình to — nhưng `_lichSuLuiTheoTep`/`_lichSuToiTheoTep`
  /// giữ NGUYÊN lịch sử của MỌI tệp đã từng mở trong phiên (cố ý, để quay
  /// lại tệp cũ vẫn Lùi/Tiến được) — mở càng nhiều tệp, có văn bản lớn,
  /// thì CẢ HAI Map này cứ phình to mãi suốt phiên làm việc, không tệp nào
  /// tự nhường chỗ. Mỗi mốc là bản chụp TRỌN VẸN cả văn bản (xem
  /// `_TrangThaiVanBan`), nên tệp dài + nhiều mốc + nhiều tệp cùng lúc là
  /// đúng công thức hại RAM người dùng mô tả.
  ///
  /// Sửa bằng LRU (Least Recently Used) ở cấp ĐỘ TỆP: chỉ giữ lịch sử của
  /// `_soLuongTepGiuLichSuToiDa` tệp đã mở GẦN NHẤT — mở thêm một tệp mới
  /// vượt mốc đó thì tệp ÍT GẦN ĐÂY NHẤT bị xoá sạch lịch sử (Lùi lại về
  /// tệp đó vẫn mở được bài, chỉ mất mốc Lùi/Tiến riêng của lần sửa trước
  /// — chấp nhận được, vì đằng nào người dùng cũng đã rời khỏi tệp đó một
  /// lúc lâu, cỡ chục tệp khác đã mở xen giữa). "Đã dùng gần đây" được
  /// tính lại mỗi lần MỞ một tệp (`_moGhiChu`) — đủ, không cần tính theo
  /// mỗi lần gõ chữ bên trong (quá tốn để làm vậy, mà cũng không cần thiết
  /// — việc cần chặn là SỐ TỆP đồng thời giữ lịch sử, không phải tốc độ
  /// gõ bên trong một tệp).
  static const _soLuongTepGiuLichSuToiDa = 12;
  final List<String> _thuTuMoTepGanDay = [];

  void _ganDauDaMoTepChoLichSu(String id) {
    _thuTuMoTepGanDay.remove(id);
    _thuTuMoTepGanDay.add(id);
    while (_thuTuMoTepGanDay.length > _soLuongTepGiuLichSuToiDa) {
      final idCu = _thuTuMoTepGanDay.removeAt(0);
      _lichSuLuiTheoTep.remove(idCu);
      _lichSuToiTheoTep.remove(idCu);
    }
  }

  /// Bỏ qua mọi kết quả còn lại của câu nói đang dở.
  ///
  /// Bật lên khi người dùng chạm vào bàn phím giữa chừng: đoạn chữ đã hiện ra
  /// phải CHẾT CỨNG tại đó, không được tự sửa nữa. Nếu không bỏ qua, bộ nhận
  /// dạng sẽ trả nốt cả câu và đổ nguyên câu ấy ra lần thứ hai.
  bool _boQuaCauNay = false;
  bool _dangCatCau = false;

  /// Số phiên nghe — tăng mỗi lần `_batMicro()` chạy, dùng để loại kết quả
  /// trễ của một phiên nghe đã đóng. Xem giải thích đầy đủ trong `_batMicro`.
  int _phienNgheHienTai = 0;

  /// Micro đang tắt vì người dùng gõ phím, chứ không phải vì họ bấm nút tắt.
  /// Phân biệt hai chuyện này mới biết có được tự bật lại hay không.
  bool _microNgungDeGo = false;

  /// Đang ở giữa một "đợt gõ tay" cho mục đích Lùi lại/Tiến tới hay không —
  /// độc lập hẳn với việc micro có tự bật lại hay không (người dùng có thể
  /// chọn "Không tự động bật lại Micro" mà vẫn cần ranh giới riêng cho gõ
  /// tay). Một đợt kết thúc sau 5 giây liên tục không gõ thêm gì.
  bool _dangTrongDotGoTay = false;
  Timer? _henRanhGioiGoTay;
  static const _thoiGianRanhGioiGoTay = Duration(seconds: 5);

  /// Bật lên khi chính ta đang sửa nội dung, để phân biệt với người gõ phím.
  /// Chỉ là lớp chắn thứ nhất: bộ gõ báo ngược trạng thái về một cách bất
  /// đồng bộ, lúc đó cờ này đã tắt rồi — nên còn hai lớp chắn nữa bên dưới.
  bool _tuSua = false;

  /// (YÊU CẦU MỚI — giới hạn ký tự một tệp) Bật lên trong lúc NẠP một ghi
  /// chú có sẵn (`initState`/`_moGhiChu`) — tệp đó có thể đã dài hơn
  /// `gioiHanKyTuMotTep` từ trước khi có giới hạn này (hoặc import từ nơi
  /// khác); `_ghiVaoO` đọc cờ này để biết KHÔNG được chặn/cắt bớt trong
  /// lúc nạp, chỉ chặn khi người dùng tự gõ/dán thêm.
  bool _dangTrongLucMoGhiChu = false;

  Timer? _henCanhBaoGioiHanKyTuMotTep;

  /// Thông báo "đã chạm trần N ký tự một tệp" — gộp lại, tối đa một lần
  /// mỗi 2 giây (gõ liên tục khi đã chạm trần dễ gọi hàm này mỗi phím bấm,
  /// dồn thông báo dày đặc gây rối mắt không cần thiết).
  void _baoVuotGioiHanKyTuMotTep() {
    if (_henCanhBaoGioiHanKyTuMotTep != null) return;
    hienThongBaoGiua(
      context,
      Ch.tepDaVuotQuaKyTuKhongTheNhapThem(ngonNguHienTai.value, gioiHanKyTuMotTep ~/ 1000),
    );
    _henCanhBaoGioiHanKyTuMotTep = Timer(const Duration(seconds: 2), () {
      _henCanhBaoGioiHanKyTuMotTep = null;
    });
  }

  /// Nội dung, vị trí con trỏ và thời điểm của lần ghi gần nhất do chính ta
  /// thực hiện. Dùng để nhận ra đâu là trạng thái bộ gõ báo ngược về.
  String _chuGanNhat = '';
  int _viTriGanNhat = -1;
  DateTime _lucGhi = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _hen;
  Timer? _henLuuTru;
  Timer? _henGoXong;
  String? _maNgonNgu;


  /// Vị trí trong bài mà AI đã kiểm tra chính tả tới đó rồi. Mỗi lần kiểm
  /// tra chỉ gửi phần văn bản TỪ đây trở đi, không gửi lại phần đã kiểm tra.
  int _viTriDaKiemTraChinhTa = 0;
  Timer? _henChinhTa;
  final _dichVuChinhTa = DichVuKiemTraChinhTa();

  /// Từ/cụm từ người dùng đã tự tay xử lý xong (chấp nhận đề xuất, xoá, hoặc
  /// huỷ đề xuất) — AI không được báo lỗi lại những từ này nữa, dù có tìm
  /// thấy y hệt ở một đoạn khác hoặc ở lượt kiểm tra sau.
  final Set<String> _tuChinhTaDaXuLy = {};

  /// Từ/cụm từ đã từng bị "Huỷ đề xuất" ở TỪ ĐIỂN sửa lỗi chính tả của bạn
  /// (gạch VÀNG, xem `_khiBamTuDien`) — một khi đã huỷ, `_quetTuDienChinhTa`
  /// không bao giờ gạch vàng lại từ này nữa, VÀ (mục 6: gạch đỏ/gạch vàng
  /// không dẫm chân lên nhau) AI cũng không được gạch đỏ đè lên nó — xem bộ
  /// lọc ở `_kiemTraChinhTaMoi`/`_apDungKetQuaToanVan`.
  final Set<String> _tuTuDienDaHuy = {};

  /// Đang có một lượt "Kiểm tra toàn văn bằng AI" chạy dở hay không — chặn
  /// bấm nút này thêm lần nữa trong lúc đang chờ.
  bool _dangKiemTraToanVan = false;
  final _dichVuToanVan = DichVuKiemTraToanVan();

  /// Đăng ký nghe resize trình duyệt (xem `nghe_resize_trinh_duyet.dart`)
  /// — `null` trên Android/iOS/desktop gốc (không có ý nghĩa gì ở đó).
  Object? _dangKyNgheResizeTrinhDuyet;

  /// (SỬA LỖI v121) Lớp CHỦ ĐỘNG thăm dò, bổ sung — xem
  /// `dangKyThamDoChieuCaoVienPort`.
  Object? _dangKyThamDoChieuCaoVienPort;

  // ------------------------------------------------- báo "Đoạn số" khi cuộn

  /// Khoảng cách (pixel) từ ĐÁY khung nhìn ô soạn thảo tới "mốc CHÍNH" ảo
  /// đứng yên — đoạn văn nào lướt ngang qua mốc này khi người dùng cuộn thì
  /// được báo là "đang ở đó" trong nhãn "Đoạn số: N". Không vẽ mốc ra màn
  /// hình (không cần thiết, người dùng chỉ cần thấy con số), chỉ dùng để
  /// tính toạ độ dò.
  static const _khoangCachMocBaoDoanTuDay = 28.0;

  /// Vị trí 5 "mốc phụ" dọc mép trái trên MÀN HÌNH RỘNG — TỈ LỆ theo chiều
  /// cao khung nhìn ô soạn thảo (0.0 = sát đỉnh khung nhìn, 1.0 = sát đáy) —
  /// rải đều, tự co giãn đúng theo MỌI chiều cao màn hình (không cần chia
  /// riêng theo bề rộng màn hình, vì các mốc canh theo chiều DỌC).
  static const _tiLeMocTraiDoanSoRong = [0.12, 0.31, 0.50, 0.69, 0.88];

  /// Màn hình HẸP (< `_nguongManHinhHep`) chỉ còn 2 mốc phụ — 5 mốc quá dày
  /// đặc trên bề ngang hẹp, dễ đè lên nội dung.
  static const _tiLeMocTraiDoanSoHep = [0.30, 0.70];

  /// Danh sách tỉ lệ đang dùng — tuỳ bề rộng màn hình hiện tại (đọc lại mỗi
  /// lần cuộn/vẽ, không lưu cố định, để tự đổi ngay khi xoay màn hình hoặc
  /// đổi kích thước cửa sổ web).
  List<double> get _tiLeMocTraiDoanSo => MediaQuery.sizeOf(context).width < _nguongManHinhHep
      ? _tiLeMocTraiDoanSoHep
      : _tiLeMocTraiDoanSoRong;

  /// Số đoạn (1-based, đoạn = văn bản giữa hai dấu `\n` liên tiếp) đang hiện
  /// ở nhãn "Đoạn số: N" (mốc CHÍNH, đáy màn hình) — `null` = đang ẩn (chưa
  /// cuộn, hoặc đã hết 1 giây kể từ lần cuộn cuối).
  int? _doanSoDangHien;

  /// Số đoạn đang hiện ở từng mốc PHỤ (mép trái, cùng thứ tự với
  /// `_tiLeMocTraiDoanSo`) — phần tử `null` = mốc đó đang ẩn. Luôn cấp phát
  /// đúng độ dài của danh sách RỘNG (tối đa có thể) — màn hình hẹp chỉ dùng
  /// 2 phần tử đầu (xem `_tiLeMocTraiDoanSo`), phần còn lại đơn giản không
  /// bao giờ được đọc tới, không cần cấp phát lại mỗi khi đổi kích thước.
  List<int?> _doanSoMocTrai =
      List<int?>.filled(_tiLeMocTraiDoanSoRong.length, null);

  Timer? _henAnDoanSo;

  /// Đếm số đoạn TRƯỚC (không tính) vị trí ký tự [viTri] rồi +1 — "đoạn" ở
  /// đây định nghĩa đúng như người dùng yêu cầu: mỗi dấu `\n` là một ranh
  /// giới đoạn mới, không liên quan gì tới dòng HIỂN THỊ (word-wrap).
  int _demSoDoanTaiViTri(String vanBan, int viTri) {
    var soDoan = 1;
    final gioiHan = viTri.clamp(0, vanBan.length);
    for (var i = 0; i < gioiHan; i++) {
      if (vanBan.codeUnitAt(i) == 0x0A) soDoan++;
    }
    return soDoan;
  }

  /// Màu chữ số theo mốc BỘI SỐ — xét từ mốc CAO xuống THẤP nên mỗi số chỉ
  /// khớp ĐÚNG MỘT màu (100 chia hết cho cả 50/10/5 nhưng chỉ lấy màu của
  /// 100). `null` = số bình thường (không chia hết cho 5), không tô riêng.
  Color? _mauChuSoTheoMocDoan(int n) {
    if (n % 1000 == 0) return const Color(0xFFFF3D9A);
    if (n % 100 == 0) return const Color(0xFFFF6B35);
    if (n % 50 == 0) return const Color(0xFFFFD60A);
    if (n % 10 == 0) return const Color(0xFF64D2FF);
    if (n % 5 == 0) return const Color(0xFF32D74B);
    return null;
  }

  /// Mốc 1000 — đậm hơn hẳn các mốc còn lại, cho thật nổi bật.
  bool _damChuSoTheoMocDoan(int n) => n % 1000 == 0;

  /// Gọi mỗi lần `_cuonVanBan` đổi offset (người dùng vuốt/kéo cuộn ô soạn
  /// thảo) — dò xem đoạn văn nào đang nằm đúng tại mốc CHÍNH gần đáy khung
  /// nhìn (xem `_khoangCachMocBaoDoanTuDay`) VÀ 5 mốc PHỤ rải đều theo
  /// chiều cao khung nhìn (xem `_tiLeMocTraiDoanSo`), rồi hiện các con số
  /// đó trong 1 giây. Dùng lại đúng cách dò toạ độ ↔ vị trí ký tự đã có sẵn
  /// cho việc Lên/Xuống theo dòng hiển thị (`_viTriTheoDongHienThi`) —
  /// `getPositionForPoint` nhận toạ độ TOÀN CỤC, còn toạ độ CỤC BỘ của
  /// `RenderEditable` vốn đã tính theo "không gian nội dung" (không đổi khi
  /// cuộn, xem `_cuonToiKetQuaHienTai`), nên cứ cộng thẳng `_cuonVanBan.offset`
  /// vào là ra đúng điểm cần dò, không cần quan tâm cuộn đã đi bao xa.
  ///
  /// CHỈ dùng `RenderEditable` để tìm SỐ ĐOẠN — không còn dùng để tính VỊ
  /// TRÍ hiển thị của mốc phụ nữa (hai lần thử trước, cả hai đường quy đổi
  /// toạ độ qua `RenderEditable` — toàn cục lẫn có `ancestor:` — đều bị lỗi
  /// mốc phía trên biến mất dần khi cuộn sâu, người dùng xác nhận cả hai
  /// lần). Vị trí một mốc phụ vốn là một điểm CỐ ĐỊNH theo TỈ LỆ chiều cao
  /// khung nhìn, không phụ thuộc nội dung hay đã cuộn bao xa — tính thẳng
  /// bằng `vpCao * tỉ lệ` (xem `_veMocPhuDoanSo`), không cần quy đổi gì cả.
  void _khiCuonVanBanBaoDoanSo() {
    if (!mounted || !_cuonVanBan.hasClients) return;
    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null) return;
    final re = _timRenderEditable(hopVanBan);
    if (re == null || !re.hasSize) return;

    final vpCao = _cuonVanBan.position.viewportDimension;

    int? doTaiY(double yTrongKhungNhin) {
      final diemNham = Offset(re.size.width / 2, _cuonVanBan.offset + yTrongKhungNhin);
      try {
        final vt = re.getPositionForPoint(re.localToGlobal(diemNham));
        return _demSoDoanTaiViTri(_boDieuKhien.text, vt.offset);
      } catch (_) {
        return null;
      }
    }

    final yDay = (vpCao - _khoangCachMocBaoDoanTuDay).clamp(0.0, vpCao);
    final soDoanDay = doTaiY(yDay);

    var doiGi = false;
    if (soDoanDay != null && soDoanDay != _doanSoDangHien) {
      _doanSoDangHien = soDoanDay;
      doiGi = true;
    }

    // YÊU CẦU MỚI: 5 (hoặc 2, màn hẹp) mốc PHỤ chỉ hoạt động khi tệp có TỪ
    // 50 đoạn văn trở lên — tệp ngắn thì chúng chỉ thêm rối mắt, không có
    // mấy ý nghĩa định vị. Mốc CHÍNH ("Đoạn số: N" ở đáy màn hình) KHÔNG
    // nằm trong điều kiện này, luôn hoạt động bất kể tệp dài ngắn.
    final coDuMocPhu = _demSoDoanTaiViTri(_boDieuKhien.text, _boDieuKhien.text.length) >= 50;
    if (coDuMocPhu) {
      for (var i = 0; i < _tiLeMocTraiDoanSo.length; i++) {
        final soDoan = doTaiY(vpCao * _tiLeMocTraiDoanSo[i]);
        if (soDoan == null) continue;
        if (soDoan != _doanSoMocTrai[i]) {
          _doanSoMocTrai[i] = soDoan;
          doiGi = true;
        }
      }
    } else if (_doanSoMocTrai.any((v) => v != null)) {
      _doanSoMocTrai = List<int?>.filled(_tiLeMocTraiDoanSoRong.length, null);
      doiGi = true;
    }

    if (!doiGi) return;
    setState(() {});
    _henAnDoanSo?.cancel();
    _henAnDoanSo = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _doanSoDangHien = null;
        _doanSoMocTrai = List<int?>.filled(_tiLeMocTraiDoanSoRong.length, null);
      });
    });
  }

  /// 5 nhãn PHỤ báo "Đoạn số" chỉ hiện mỗi số "N" (đổi màu TOÀN BỘ chữ theo
  /// mốc), rải dọc mép trái ô soạn thảo — vẽ NGAY TRONG Stack bọc ô chữ
  /// (`_khungVanBanKey`, cùng lớp với con trỏ/đường kẻ chia). Vị trí tính
  /// THẲNG bằng `vpCao * tỉ lệ` — một mốc phụ là điểm CỐ ĐỊNH theo tỉ lệ
  /// chiều cao khung nhìn, không phụ thuộc nội dung hay đã cuộn bao xa,
  /// nên KHÔNG cần quy đổi gì qua `RenderEditable` cả (hai lần thử trước
  /// đều quy đổi qua đó và đều lỗi mốc trên biến mất dần khi cuộn sâu).
  Widget _veMocPhuDoanSo() {
    final vpCao = _cuonVanBan.hasClients ? _cuonVanBan.position.viewportDimension : null;
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            for (var i = 0; i < _tiLeMocTraiDoanSo.length; i++)
              if (_doanSoMocTrai[i] != null && vpCao != null)
                Positioned(
                  // (YÊU CẦU MỚI) Dời sang mép PHẢI — chỉ nhãn CHÍNH
                  // ("Đoạn số: N" ở đáy màn hình, `_nhanDoanSo`) còn giữ
                  // mép trái như cũ.
                  right: 12,
                  top: vpCao * _tiLeMocTraiDoanSo[i] - 13,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_doanSoMocTrai[i]}',
                      style: TextStyle(
                        color: _mauChuSoTheoMocDoan(_doanSoMocTrai[i]!) ?? Colors.white,
                        fontWeight: _damChuSoTheoMocDoan(_doanSoMocTrai[i]!)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  /// Nhãn CHÍNH "Đoạn số: N" — sát mép trái, gần đáy màn hình, tự ẩn sau 1
  /// giây (xem `_khiCuonVanBanBaoDoanSo`). Luôn có mặt trong app, không có
  /// cài đặt bật/tắt. Chữ "Đoạn số: " luôn trắng bình thường, CHỈ riêng số
  /// N đổi màu theo mốc (tách bằng `Text.rich`).
  Widget _nhanDoanSo(double caoBanPhim) {
    return Positioned(
      left: 12,
      bottom: caoBanPhim + 12,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _doanSoDangHien == null ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                children: [
                  const TextSpan(text: 'Đoạn số: '),
                  TextSpan(
                    text: '${_doanSoDangHien ?? 1}',
                    style: TextStyle(
                      color: _mauChuSoTheoMocDoan(_doanSoDangHien ?? 1),
                      fontWeight: _damChuSoTheoMocDoan(_doanSoDangHien ?? 1)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _khiDoiNgonNgu() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // (ĐA NGÔN NGỮ) Vẽ lại toàn trang khi người dùng đổi ngôn ngữ ở modal
    // Cài đặt — không bọc `ValueListenableBuilder` quanh cả cây widget (file
    // này quá lớn, rủi ro cao), chỉ nghe trực tiếp rồi `setState` rỗng.
    ngonNguHienTai.addListener(_khiDoiNgonNgu);
    _ghiChuHienTai = widget.kho.timGhiChu(widget.ghiChuId)!;
    _ganDauDaMoTepChoLichSu(widget.ghiChuId);
    _ghiNhoGanDayNhatChoKhoiDong();
    _thietBiHienTai = widget.caiDat.thietBiChonTay ?? doanThietBi();
    _thuGonThanhCongCu = widget.caiDat.thuGonThanhCongCu;
    // Chỉ có tác dụng trên web (no-op ở Android/iOS gốc) — hiện đúng cảnh
    // báo CỦA CHÍNH TRÌNH DUYỆT (không tự đặt chữ được) khi bấm F5/đóng
    // tab/đóng trình duyệt lúc còn thay đổi CHƯA kịp tự động lưu.
    datCanhBaoRoiTrangNeuChuaLuu(() => _coThayDoiChuaLuu);
    _tenController = TextEditingController(text: _ghiChuHienTai.ten);
    _oTen.addListener(_khiOTenMatFocus);
    // (VIỆC 2) Bật/tắt nhấp nháy con trỏ tự vẽ theo đúng lúc `_oChu` được/mất
    // tiêu điểm. KHÔNG gọi `_khiFocusConTroDoi()` ngay tại đây: nó gọi
    // `setState` ở nhánh "mất tiêu điểm", mà State chưa build lần nào thì
    // chưa được phép gọi `setState`. `autofocus: true` giành tiêu điểm cho
    // `_oChu` NGAY SAU khung hình đầu tiên — khi đó `_oChu` tự phát sự kiện
    // đổi focus, gọi listener này đúng lúc (đã an toàn, không còn trong
    // initState nữa) để bắt đầu nháy.
    _oChu.addListener(_khiFocusConTroDoi);
    // Nút "Làm việc với AI" tự sáng nền xanh khi có vùng chọn (xem
    // `_khiVungChonCoTheDoi`) — chỉ setState khi tình trạng "có/không vùng
    // chọn" THẬT SỰ đổi (không phải mỗi lần con trỏ nhích một ký tự), để
    // không rebuild thừa mỗi lần gõ phím.
    _boDieuKhien.addListener(_khiVungChonCoTheDoi);

    WidgetsBinding.instance.addObserver(this);
    // (SỬA LỖI "bãi đất trống" kẹt lại sau khi ẩn bàn phím ảo) Xem giải
    // thích đầy đủ ở `nghe_resize_trinh_duyet_web.dart` — nghe THẲNG sự
    // kiện resize của trình duyệt, độc lập với `didChangeMetrics` (đã thử
    // trước, không đủ vì có đường ẩn bàn phím ảo Flutter Engine không dịch
    // lại được).
    _dangKyNgheResizeTrinhDuyet = dangKyNgheResizeTrinhDuyet(() {
      if (mounted) setState(() {});
    });
    _dangKyThamDoChieuCaoVienPort = dangKyThamDoChieuCaoVienPort(() {
      if (mounted) setState(() {});
    });
    _boDieuKhien.addListener(_khiNguoiDungSua);
    _boDieuKhien.addListener(_capNhatTimKiemNeuDangMo);
    // (YÊU CẦU MỚI) Dải "Có bản APK mới" — chỉ gọi mạng trên bản APK thật,
    // KHÔNG trên web (web không có khái niệm "bản cũ cài trên máy").
    if (!kIsWeb) {
      kiemTraBanApkMoiHon().then((banMoi) {
        if (mounted && banMoi != null) setState(() => _banApkMoiPhatHien = banMoi);
      });
    }
    // (YÊU CẦU MỚI) Đăng nhập Google — nghe thay đổi trạng thái để vẽ lại
    // menu "Tài khoản và Cài đặt" (tên/avatar + đổi nhãn nút).
    _nguoiDungDangNhap = DichVuDangNhapGoogle.instance.nguoiDungHienTai;
    _capNhatDangKyCanhBaoApi();
    // (YÊU CẦU MỚI) Báo "Đã đăng nhập vào tài khoản..." mỗi lần CHUYỂN từ
    // chưa đăng nhập sang đã đăng nhập — bắt đúng cả hai trường hợp bằng
    // MỘT nơi duy nhất (không cần tự báo riêng ở `_bamDangNhapGoogle`):
    // 1) Bấm "Đăng nhập tài khoản" thật trong phiên này (mọi nền tảng).
    // 2) Riêng bản WEB: vừa tải lại/mở lại trang mà trình duyệt đã nhớ sẵn
    //    phiên đăng nhập từ trước — `authStateChanges()` luôn bắn NGAY sự
    //    kiện đầu tiên là trạng thái hiện có lúc vừa subscribe, dùng cờ
    //    [laLanDauNgheDangNhap] để nhận ra đây là lần đầu (khôi phục) chứ
    //    không phải một lượt đăng nhập mới. Android/iOS CỐ Ý bỏ qua lần đầu
    //    (không nên nhắc mỗi lần mở app nếu đã đăng nhập sẵn).
    var laLanDauNgheDangNhap = true;
    _dangKyDoiTrangThaiDangNhap =
        DichVuDangNhapGoogle.instance.doiTrangThai.listen((nguoiDung) {
      if (!mounted) return;
      final laLanDau = laLanDauNgheDangNhap;
      laLanDauNgheDangNhap = false;
      setState(() => _nguoiDungDangNhap = nguoiDung);
      _capNhatDangKyCanhBaoApi();
      _thoatKhoiDamMayNeuCanThiet(nguoiDung);
      if (nguoiDung == null) return;
      unawaited(_dongBoCaiDatTuTaiKhoanKhiDangNhap(nguoiDung.uid));
      unawaited(dongBoNgonNguKhiDangNhap(nguoiDung.uid));
      // (YÊU CẦU MỚI — 2 bộ nhớ từ điển) Tải hai bộ từ điển ĐÁM MÂY của tài
      // khoản MỌI LẦN phát hiện có đăng nhập (kể cả phiên cũ tự khôi phục —
      // khác với auto bật/tắt ngay dưới đây) — cần có sẵn SẴN SÀNG để quét
      // chính tả/mở modal/mở bảng 26 dòng dùng được ngay, không phải đợi.
      unawaited(_taiTuDienDamMayLucDangNhap(nguoiDung.uid));
      // Auto bật/tắt "Từ điển nhập liệu nhanh" theo tài khoản — CHỈ áp dụng
      // đúng MỘT LẦN lúc đăng nhập THẬT, KHÔNG áp dụng lúc phiên cũ tự khôi
      // phục (dùng ĐÚNG cùng điều kiện phân biệt hai trường hợp này mà đoạn
      // hiện toast dưới đây đang dùng — web không phân biệt được "vừa bấm
      // đăng nhập" khỏi "tải lại trang với phiên cũ", nên coi cả hai là
      // "đăng nhập thật" trên web, y hệt cách toast đang xử lý).
      if (!(laLanDau && !kIsWeb)) {
        unawaited(_apDungAutoBatTuDienNhapLieuNhanhKhiDangNhapThat(nguoiDung.uid));
      }
      if (laLanDau && !kIsWeb) return;
      final ten = nguoiDung.displayName ?? nguoiDung.email ?? 'Google';
      hienThongBaoGiua(
        context,
        Ch.daDangNhapVaoTaiKhoan(ngonNguHienTai.value, ten),
        thoiGian: const Duration(seconds: 5),
        ganTren: true,
      );
    });
    // TextField (Material) không có tham số `onSelectionChanged` — đó là
    // API của EditableText, không lộ ra ở TextField. Vì
    // `_tinhTrangThaiDinhDangHienTai` vốn đã an toàn gọi mỗi lần selection
    // đổi, KỂ CẢ mỗi lần gõ phím (xem chú thích ngay tại khai báo hàm),
    // đăng ký nó như một listener bình thường ở đây là đủ và không lặp lại
    // lỗi ANR cũ (hàm chỉ làm việc O(k) nhỏ, không quét toàn văn bản).
    _boDieuKhien.addListener(_tinhTrangThaiDinhDangHienTai);
    _boDieuKhien.khiBamTuSai = _khiBamTuSai;
    _boDieuKhien.khiBamTuDien = _khiBamTuDien;
    _boDieuKhien.khiBamLienKet = _khiBamLienKet;
    _boDieuKhien.khiBamDoanKhongPhuHop = _khiBamDoanKhongPhuHop;
    _boDieuKhien.khiBamDoanCanXoa = _khiBamDoanCanXoa;
    _boDieuKhien.khiBamTheGhiAmHoanChinh = _khiBamTheGhiAmHoanChinh;
    _boDieuKhien.khiBamTheDangChuyen = _khiBamTheDangChuyen;
    _boDieuKhien.khiBamTheTichChon = _khiBamTheTichChon;
    _oTimKiem.addListener(_capNhatKetQuaTimKiem);
    _oTimKiem.addListener(_khiOTimKiemDoi);
    _oThayThe.addListener(_khiOThayTheDoi);
    _cuonVanBan.addListener(_khiCuonVanBanBaoDoanSo);

    // Nội dung lưu trữ có thể mang thêm một khối định dạng AI mã hoá ở cuối
    // (xem `_macDinhDangAi`/`_apDungDinhDangAi`) — tách nó ra TRƯỚC khi đưa
    // vào ô soạn thảo, để `_boDieuKhien.text` chỉ chứa đúng văn bản THẬT,
    // không lộ khối mã hoá ra màn hình.
    final rawNoiDung = _ghiChuHienTai.noiDung;
    final (banDau, khoiDinhDang, khoiDinhDangThuCong) = _tachCacKhoiDinhDang(rawNoiDung);

    // (YÊU CẦU MỚI) Mặc định con trỏ ở ĐẦU tệp (0), không phải cuối văn bản
    // như trước — xem giải thích đầy đủ ở `_moGhiChu`.
    //
    // (YÊU CẦU MỚI — giới hạn ký tự một tệp) Nạp một ghi chú ĐÃ CÓ SẴN có
    // thể dài hơn `gioiHanKyTuMotTep` (tệp cũ từ trước khi có giới hạn này,
    // hoặc import từ nơi khác) — `_ghiVaoO` không được chặn/cắt bớt trong
    // trường hợp NẠP, chỉ chặn khi NGƯỜI DÙNG tự gõ/dán thêm.
    _dangTrongLucMoGhiChu = true;
    if (banDau.isNotEmpty) {
      _ghiVaoO(banDau, 0);
    } else {
      // Ghi chú vừa tạo, chưa từng có ký tự nào — tự hiện chú thích ngay từ
      // đầu, y hệt như vừa bấm nút "i", để người dùng lần đầu biết mỗi nút
      // dùng để làm gì.
      _hienChuThich = true;
    }
    _dangTrongLucMoGhiChu = false;
    _neo = 0;
    _viTriDaKiemTraChinhTa = banDau.length;
    if (khoiDinhDang != null) _apDungDinhDangAi(khoiDinhDang);
    if (khoiDinhDangThuCong != null) _apDungDinhDangThuCong(khoiDinhDangThuCong);

    _khoiTaoMicro();
    // (YÊU CẦU MỚI) Màn hình RỘNG cả về chiều ngang LẪN chiều cao (máy tính
    // bảng 12 inch trở lên, hoặc PC) — tự hiện VÀ ghim sẵn thanh định dạng
    // ngay từ lúc vào app, không cần tự bấm nút ghim mỗi lần. Đợi khung
    // hình đầu tiên vì `MediaQuery` lúc `initState` chưa chắc đã có kích
    // thước MÀN HÌNH THẬT cuối cùng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tuGhimThanhDinhDangNeuManHinhLon();
    });
    // Lắng nghe TOÀN CỤC (không phụ thuộc widget nào đang giữ tiêu điểm) —
    // phím tắt phải hoạt động kể cả đang gõ dở trong ô văn bản.
    HardwareKeyboard.instance.addHandler(_khiPhimTatMicro);
    HardwareKeyboard.instance.addHandler(_khiPhimTatGhiAm);
    HardwareKeyboard.instance.addHandler(_khiPhimTatBoNhoTam);
    HardwareKeyboard.instance.addHandler(_khiPhimTatTuDienNhapLieuNhanh);
    HardwareKeyboard.instance.addHandler(_khiPhimTatTapDoi);
    HardwareKeyboard.instance.addHandler(_khiPhimTatLuiTien);
    HardwareKeyboard.instance.addHandler(_khiGoPhimBatKyTatChuThich);
  }

  /// Gõ BẤT KỲ phím nào trên bàn phím rời cũng tắt chú thích — không riêng gì
  /// chạm màn hình. Chỉ quan sát (luôn trả về false), không chặn phím đi
  /// tiếp xuống ô văn bản hay các phím tắt khác.
  bool _khiGoPhimBatKyTatChuThich(KeyEvent event) {
    if (event is KeyDownEvent) {
      _tatChuThich();
      // (SỬA LỖI — nhánh thử nghiệm) Có sự kiện phím RỜI (xem chú thích ở
      // trên — đúng giả định này đã dùng sẵn cho việc tắt chú thích) nghĩa
      // là thiết bị đang gắn bàn phím vật lý. Ghi nhớ lại, dùng ở
      // `_giuTieuDiemKhongBatBanPhimAo` để KHÔNG dựng lại ô soạn thảo sau
      // Copy/Cắt/Dán/All trên thiết bị này nữa.
      _coBanPhimVatLy = true;
    }
    return false;
  }

  /// true nếu thiết bị này đã từng gõ qua bàn phím RỜI (vật lý) — xem
  /// `_khiGoPhimBatKyTatChuThich`. Trên thiết bị như vậy, bàn phím ảo trên
  /// màn hình hầu như luôn ẨN (không cần tới) bất kể người dùng có đang gõ
  /// hay không, nên `viewInsets.bottom > 0` không còn là dấu hiệu đáng tin
  /// để biết "người dùng có đang gõ" — và lỗi mà `_lamMoiOVanBanDeThoatKet-
  /// BanPhimAo` sinh ra để né (bàn phím ảo bị kẹt) KHÔNG THỂ xảy ra trên
  /// thiết bị không hề triệu hồi bàn phím ảo — nên bỏ hẳn việc dựng lại đó
  /// khi cờ này đã lên, thay vì chỉ rút ngắn thời gian chờ.
  bool _coBanPhimVatLy = false;

  /// (YÊU CẦU MỚI) Tài khoản Google đang đăng nhập — `null` là chưa đăng
  /// nhập. Xem `_bamDangNhapGoogle`/`DichVuDangNhapGoogle`.
  User? _nguoiDungDangNhap;
  StreamSubscription<User?>? _dangKyDoiTrangThaiDangNhap;

  /// (YÊU CẦU MỚI) Mục "Cảnh báo hạn mức API" trong menu "Tài khoản-Cài
  /// đặt" — CHỈ hiện khi collection `canhBaoApi` (xem `modal_canh_bao_api.dart`)
  /// THẬT SỰ có ít nhất một dòng cần báo cáo, không hiện suông cho admin
  /// xem "chưa có gì". Nghe trực tiếp Firestore (không phải chỉ đọc một
  /// lần) để tự ẩn/hiện ngay khi có cảnh báo mới, không cần mở/đóng app lại.
  bool _coCanhBaoApiCanBaoCao = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dangKyCanhBaoApi;

  void _capNhatDangKyCanhBaoApi() {
    _dangKyCanhBaoApi?.cancel();
    _dangKyCanhBaoApi = null;
    if (!laAdminEmail(_nguoiDungDangNhap?.email)) {
      if (mounted) setState(() => _coCanhBaoApiCanBaoCao = false);
      return;
    }
    _dangKyCanhBaoApi = FirebaseFirestore.instance
        .collection('canhBaoApi')
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _coCanhBaoApiCanBaoCao = snap.docs.isNotEmpty);
    });
  }

  /// (ĐỒNG BỘ TÀI KHOẢN GOOGLE — YÊU CẦU MỚI) Ghim/bỏ ghim thanh định dạng
  /// và mở rộng/thu gọn thanh công cụ phía trên: lưu vào bộ nhớ lâu dài của
  /// tài khoản NGAY mỗi lần đổi, nếu đang đăng nhập — không làm gì nếu
  /// chưa đăng nhập (lúc đó `datGhimThanhDinhDang`/`datThuGonThanhCongCu` ở
  /// nơi gọi đã lo xong phần lưu ở máy rồi). Mất mạng thì `CaiDatDamMay.luu`
  /// tự bỏ qua lặng lẽ (xem giải thích ở lớp đó) — không chặn UI, không báo
  /// lỗi gì ở đây.
  Future<void> _dayCaiDatDongBoTaiKhoan(Map<String, dynamic> thayDoi) async {
    final uid = _nguoiDungDangNhap?.uid;
    if (uid == null) return;
    await CaiDatDamMay(uid).luu(thayDoi);
  }

  /// (ĐỒNG BỘ TÀI KHOẢN GOOGLE — YÊU CẦU MỚI) Gọi mỗi lần phát hiện tài
  /// khoản [uid] đang đăng nhập (đăng nhập thành công MỚI, hoặc app vừa mở
  /// lại mà phiên đăng nhập cũ còn hiệu lực) — đúng lúc trong
  /// `_dangKyDoiTrangThaiDangNhap` ở `initState`.
  ///
  /// Thứ tự hai bước CỐ Ý tách biệt, không gộp:
  /// 1. Chụp ảnh giá trị HIỆN TẠI của app (trước khi áp bất cứ gì từ tài
  ///    khoản) — dùng để nạp đầy đúng những ô tài khoản ĐANG TRỐNG. Mục đã
  ///    có trên tài khoản thì không đụng tới (giữ nguyên yêu cầu "mục nào
  ///    đã nhớ thì không tiếp nhận gì cả").
  /// 2. Áp mọi giá trị tài khoản ĐÃ có vào app + lưu lại ở máy — tài khoản
  ///    luôn thắng máy, đúng yêu cầu ưu tiên.
  /// Hai bước không đụng cùng field nào (tập khoá rời nhau: "trống" vs "đã
  /// có"), nên làm theo thứ tự nào cũng ra cùng kết quả — nhưng chụp ảnh
  /// TRƯỚC vẫn an toàn hơn, tránh mọi khả năng lấy nhầm giá trị vừa áp từ
  /// tài khoản để rồi "nạp đầy" ngược lại chính tài khoản đó.
  Future<void> _dongBoCaiDatTuTaiKhoanKhiDangNhap(String uid) async {
    final kho = CaiDatDamMay(uid);
    final daCo = await kho.tai();
    final hienTaiCuaMay = widget.caiDat.toJsonDongBoTaiKhoan();

    final canNapDay = <String, dynamic>{};
    for (final e in hienTaiCuaMay.entries) {
      if (!daCo.containsKey(e.key)) canNapDay[e.key] = e.value;
    }

    if (daCo.isNotEmpty) {
      await widget.caiDat.apDungCaiDatDongBo(daCo);
      if (mounted) setState(() {});
    }

    if (canNapDay.isNotEmpty) await kho.luu(canNapDay);
  }

  /// (YÊU CẦU MỚI — 2 bộ nhớ từ điển) Tải hai bộ từ điển ĐÁM MÂY của tài
  /// khoản [uid] vào `TuDienNhapLieuNhanhDamMay.dungChung`/
  /// `TuDienChinhTaDamMay.dungChung` — gọi MỖI LẦN phát hiện có đăng nhập
  /// (phiên mới hay phiên cũ khôi phục đều gọi), để modal/bảng 26 dòng/quét
  /// chính tả luôn có dữ liệu sẵn sàng. KHÔNG tự bật/tắt gì cả — xem
  /// `_apDungAutoBatTuDienNhapLieuNhanhKhiDangNhapThat` cho phần đó.
  Future<void> _taiTuDienDamMayLucDangNhap(String uid) async {
    final nhapLieuNhanh = TuDienNhapLieuNhanhDamMay(uid);
    final chinhTa = TuDienChinhTaDamMay(uid);
    await Future.wait([nhapLieuNhanh.tai(), chinhTa.tai()]);
    TuDienNhapLieuNhanhDamMay.dungChung = nhapLieuNhanh;
    TuDienChinhTaDamMay.dungChung = chinhTa;
    if (mounted) {
      setState(() {});
      _quetTuDienChinhTa();
    }
  }

  /// (YÊU CẦU MỚI — 2 bộ nhớ từ điển) Gọi đúng MỘT LẦN lúc đăng nhập THẬT
  /// (xem nơi gọi, SAU KHI `_taiTuDienDamMayLucDangNhap` đã tải xong) — nếu
  /// tài khoản đó có ÍT NHẤT một trong 26 dòng "Từ điển nhập liệu nhanh"
  /// không trống, tự BẬT bộ nhớ Đám mây và TẮT bộ nhớ Nội bộ. Tài khoản còn
  /// trống hết 26 dòng thì KHÔNG đụng gì tới hiện trạng Nội bộ (giữ y như
  /// lúc chưa đăng nhập).
  Future<void> _apDungAutoBatTuDienNhapLieuNhanhKhiDangNhapThat(String uid) async {
    final kho = TuDienNhapLieuNhanhDamMay.dungChung;
    if (kho == null || kho.uid != uid) return;
    if (!kho.trong && !kho.bat) {
      await kho.ghiBat(true);
      await widget.caiDat.datTuDienNhapLieuNhanhBat(false);
    }
    if (mounted) setState(() {});
  }

  /// (SỬA LỖI NGHIÊM TRỌNG — đăng xuất/đổi tài khoản vẫn còn thấy ghi chú
  /// và cây thư mục đám mây của tài khoản CŨ) Gọi mỗi lần trạng thái đăng
  /// nhập đổi, trên TẤT CẢ các `TrangSoanThao` đang sống (kể cả cái đang
  /// bị `ManHinhThuMuc`/`TrangSoanThao` khác mở CHỒNG lên che mất — xem
  /// `ManHinhThuMuc._moGhiChuDuocChon`: đổi sang kho KHÁC thì mở hẳn một
  /// `TrangSoanThao` MỚI thay vì thay thế cái cũ, nên Navigator có thể
  /// xếp chồng nhiều lớp local/đám mây xen kẽ — mỗi lớp tự biết lúc nào
  /// PHẢI tự rút khỏi ngăn xếp, không ai khác làm hộ được).
  ///
  /// Trang này vốn CHỈ biết đúng MỘT kho cố định (`widget.kho`) suốt
  /// vòng đời — không tự "biết" phải ngừng hiển thị khi tài khoản chủ
  /// của kho đó vừa đăng xuất hoặc đổi sang tài khoản khác.
  void _thoatKhoiDamMayNeuCanThiet(User? nguoiDungMoi) {
    // Dọn biến tĩnh TRƯỚC — object kho đám mây cũ không còn ai nên giữ
    // sống nữa một khi chủ của nó đã đăng xuất/đổi tài khoản, bất kể
    // trang NÀY có đang hiển thị kho đó hay không.
    final dungChung = KhoDuLieuDamMay.dungChung;
    if (dungChung != null &&
        (nguoiDungMoi == null || nguoiDungMoi.uid != dungChung.uid)) {
      KhoDuLieuDamMay.dungChung = null;
    }

    final kho = widget.kho;
    if (kho is! KhoDuLieuDamMay) return; // Trang này vốn đã là nội bộ.
    if (nguoiDungMoi != null && nguoiDungMoi.uid == kho.uid) return; // Vẫn đúng chủ.

    if (!Navigator.of(context).canPop()) {
      // (GIỚI HẠN ĐÃ BIẾT) Trang này là GỐC — ví dụ cài đặt "Khi khởi
      // động App: Mở tệp..." đặt sẵn một ghi chú đám mây. Không pop được
      // (không có gì bên dưới để lộ ra). Lần khởi động KẾ TIẾP sẽ tự rơi
      // về nội bộ đúng (xem `giaiQuyetKhoiDong`), nhưng TRONG PHIÊN NÀY
      // màn hình vẫn tạm hiện ghi chú đám mây cũ cho tới khi người dùng
      // tự khởi động lại app — chấp nhận, trường hợp hiếm.
      return;
    }
    // Rút khỏi ngăn xếp: đóng MỌI route xếp CHỒNG lên trang này (ví dụ
    // một `ManHinhThuMuc` đang mở dở) rồi đóng luôn chính trang này —
    // lộ ra đúng trang bên dưới (local, hoặc một lớp đám mây khác mà
    // listener CỦA NÓ sẽ tự xử lý tiếp nếu cũng không còn hợp lệ).
    final route = ModalRoute.of(context);
    final nav = Navigator.of(context);
    nav.popUntil((r) => r == route);
    nav.pop();
  }

  /// Nút "Đăng nhập tài khoản"/"Đăng xuất" ở menu "Tài khoản và Cài đặt" —
  /// tự quyết đăng nhập hay đăng xuất dựa theo [_nguoiDungDangNhap] HIỆN
  /// TẠI lúc bấm (menu chỉ gọi đúng MỘT callback, không tách hai nút).
  Future<void> _bamDangNhapGoogle() async {
    try {
      if (_nguoiDungDangNhap == null) {
        await DichVuDangNhapGoogle.instance.dangNhap();
      } else {
        // (YÊU CẦU MỚI) Hỏi lại trước khi đăng xuất thật.
        final chac = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(Ch.dangXuat(ngonNguHienTai.value)),
            content: Text(Ch.xacNhanDangXuat(ngonNguHienTai.value)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(Ch.huy(ngonNguHienTai.value)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(Ch.dangXuat(ngonNguHienTai.value)),
              ),
            ],
          ),
        );
        if (chac != true) return;
        // (YÊU CẦU MỚI — xem/soạn offline) Xoá hẳn bản cache ngoại tuyến
        // của tài khoản VỪA đăng xuất — máy dùng chung không được để lộ
        // ghi chú đám mây của người này cho người đăng nhập kế tiếp. Lấy
        // `uid` TRƯỚC khi đăng xuất — sau khi đăng xuất `currentUser` về
        // `null`, không còn biết xoá đúng khoá nào nữa.
        final uidVuaDangXuat = _nguoiDungDangNhap?.uid;
        await DichVuDangNhapGoogle.instance.dangXuat();
        if (uidVuaDangXuat != null) {
          unawaited(KhoDuLieuDamMay.xoaCacheOffline(uidVuaDangXuat));
          unawaited(CaiDatDamMay.xoaCacheOffline(uidVuaDangXuat));
          unawaited(TuDienNhapLieuNhanhDamMay.xoaCacheOffline(uidVuaDangXuat));
          unawaited(TuDienChinhTaDamMay.xoaCacheOffline(uidVuaDangXuat));
          TuDienNhapLieuNhanhDamMay.dungChung = null;
          TuDienChinhTaDamMay.dungChung = null;
        }
        // (YÊU CẦU MỚI — SỬA LỖI vẫn còn thấy ghi chú/cây thư mục đám mây
        // sau khi đăng xuất) Đã đăng xuất Firebase Auth xong ở trên — chủ
        // động khởi động lại TOÀN BỘ app tại chỗ (`KhoiDongLaiApp`), huỷ
        // sạch mọi màn hình đang mở (kể cả khi trang GỐC đang soạn thảo
        // TRỰC TIẾP một ghi chú đám mây — trường hợp `_thoatKhoiDamMayNeuCanThiet`
        // không tự xử lý được vì không có gì để `pop()` lùi về). Luồng
        // khởi động bình thường (`giaiQuyetKhoiDong`) chạy lại từ đầu, tự
        // rơi về đúng ghi chú NỘI BỘ gần nhất (hoặc tự tạo ghi chú mới nếu
        // nội bộ trống) vì lúc này Auth đã đăng xuất — không cần viết
        // thêm logic "tự chọn/tạo tệp" riêng ở đây.
        if (mounted) KhoiDongLaiApp.goiLai(context);
      }
    } catch (e) {
      if (!mounted) return;
      hienThongBaoGiua(context, Ch.dangNhapGoogleThatBai(ngonNguHienTai.value, '$e'));
    }
  }

  @override
  void dispose() {
    ngonNguHienTai.removeListener(_khiDoiNgonNgu);
    HardwareKeyboard.instance.removeHandler(_khiPhimTatMicro);
    HardwareKeyboard.instance.removeHandler(_khiPhimTatGhiAm);
    HardwareKeyboard.instance.removeHandler(_khiPhimTatBoNhoTam);
    HardwareKeyboard.instance.removeHandler(_khiPhimTatTuDienNhapLieuNhanh);
    HardwareKeyboard.instance.removeHandler(_khiPhimTatTapDoi);
    HardwareKeyboard.instance.removeHandler(_khiPhimTatLuiTien);
    HardwareKeyboard.instance.removeHandler(_khiGoPhimBatKyTatChuThich);
    WidgetsBinding.instance.removeObserver(this);
    _dangKyDoiTrangThaiDangNhap?.cancel();
    _dangKyCanhBaoApi?.cancel();
    huyNgheResizeTrinhDuyet(_dangKyNgheResizeTrinhDuyet);
    huyThamDoChieuCaoVienPort(_dangKyThamDoChieuCaoVienPort);
    _hen?.cancel();
    _henLuuTru?.cancel();
    _henGoXong?.cancel();
    _henChinhTa?.cancel();
    _henRanhGioiGoTay?.cancel();
    _henTuTatMicroImLang?.cancel();
    _henMoDamChamCuoi?.cancel();
    _henHetHanRanhGioiPhien?.cancel();
    _henNhapNhayConTro?.cancel();
    _henEpConTro?.cancel();
    _henAnDoanSo?.cancel();
    _henHetLietPastePhimAo?.cancel();
    _henHetCheDoNhanhChonTatCa?.cancel();
    _henLamMoiOVanBanDeThoatKet?.cancel();
    _dangXuLyEntry?.remove();
    _oKetQuaFileAmThanh?.dispose();
    _oKetQuaToanVan?.dispose();
    _theoDoiTapDoi.dispose();
    _cuonVanBan.removeListener(_khiCuonVanBanBaoDoanSo);
    _conTroDangHien.dispose();
    _oChu.removeListener(_khiFocusConTroDoi);
    _boDieuKhien.removeListener(_khiVungChonCoTheDoi);
    _bomDongHoTheGhiAm?.cancel();
    _dangKyMucAmTheGhiAm?.cancel();
    _henCanhBaoGioiHanKyTuMotTep?.cancel();
    _thoiLuongTheGhiAmDangGhi.dispose();
    _nhanTrangThaiGhiAmGheDe.dispose();
    _soTheChoBangDieuKhien.dispose();
    _songAmTick.dispose();
    if (_trinhGhiAmMo) unawaited(ghiAmTheDongHan());
    _micro.cancel();
    _boDieuKhien.dispose();
    _oChu.dispose();
    _cuonVanBan.dispose();
    _tenController.dispose();
    _oTen.dispose();
    _oTimKiem.dispose();
    _focusTimKiem.dispose();
    _oThayThe.dispose();
    _focusThayThe.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState trangThai) {
    if (trangThai != AppLifecycleState.resumed) {
      _luuVanBan();
      if (_muonNghe) _tatMicro();
    }
  }

  /// (SỬA LỖI "bãi đất trống" kẹt lại sau khi bàn phím ảo ẩn đi — đặc biệt
  /// hay gặp khi ẩn bằng nút Back của thiết bị/trình duyệt thay vì tự blur
  /// ô soạn thảo) `build()` tự đo chiều cao bàn phím
  /// (`MediaQuery.viewInsetsOf(context).bottom`, xem `caoBanPhim`) rồi tự
  /// chừa đúng khoảng đó ở cuối trang thay vì để `Scaffold` tự lo
  /// (`resizeToAvoidBottomInset: false`) — về lý thuyết Flutter tự dựng lại
  /// đúng lúc viewport đổi, nhưng có những đường ẩn bàn phím (nhất là qua
  /// nút Back trên web) không kích lại kịp, khiến `caoBanPhim` đọc phải giá
  /// trị CŨ, để lại một khoảng trống không ai lấp. Lớp này đã tự đăng ký
  /// `WidgetsBindingObserver` sẵn rồi (cho `didChangeAppLifecycleState`) —
  /// `didChangeMetrics` mới là đúng chỗ Flutter báo "viewport vừa đổi kích
  /// thước" (bàn phím ảo ẩn/hiện là một dạng đổi viewport); ép dựng lại
  /// ngay tại đó để luôn đọc đúng chiều cao bàn phím MỚI NHẤT, không phải
  /// đợi một nút bấm nào khác tình cờ gọi `setState` mới lộ ra bản mới.
  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------- lưu trữ

  /// `true` = có thay đổi CHƯA kịp tự động lưu — chỉ web mới dùng tới (xem
  /// `canh_bao_roi_trang.dart`), nhưng đặt ở đây cho MỌI nền tảng cho đơn
  /// giản, không cần bọc `kIsWeb` quanh một biến bool vô hại.
  bool _coThayDoiChuaLuu = false;

  /// (YÊU CẦU MỚI) Chuỗi đã bị bấm "Đây không phải là link" — nhớ CHỈ trong
  /// RAM của phiên soạn thảo tệp này, KHÔNG lưu xuống đĩa (mất khi đóng/mở
  /// lại tệp) — cùng mức ghi nhớ với `_tuTuDienDaHuy`/`_tuChinhTaDaXuLy`, so
  /// khớp theo ĐÚNG chuỗi (phân biệt hoa/thường, khác `_tuTuDienDaHuy`: một
  /// link là một địa chỉ cụ thể, không có khái niệm "viết hoa/thường khác
  /// nhau vẫn là một link giống nhau" như một từ tiếng Việt).
  final Set<String> _linkDaHuy = {};

  /// (YÊU CẦU MỚI) Bắt HẸP — chỉ `http://`, `https://`, `www.` theo sau bởi
  /// ký tự không phải khoảng trắng. Không bắt domain trơn (ví dụ gõ thẳng
  /// "abc.com") để tránh nhận nhầm tên tệp/số thập phân/viết tắt.
  static final _reLienKet = RegExp(r'(?:https?://|www\.)\S+', caseSensitive: false);

  /// Dấu câu cuối câu thường đi dính liền sau link khi gõ trong một câu
  /// (ví dụ "...xem ở https://abc.com/xyz."). Cắt bỏ các dấu này ở cuối
  /// chuỗi khớp — không thuộc về link.
  static const _dauCauCuoiLink = '.,;:!?)]}\'"”’';

  String _catDauCauCuoiLink(String tu) {
    var ketThuc = tu.length;
    while (ketThuc > 0 && _dauCauCuoiLink.contains(tu[ketThuc - 1])) {
      ketThuc--;
    }
    return tu.substring(0, ketThuc);
  }

  /// Quét lại TOÀN BỘ bài tìm đoạn TRÔNG NHƯ LINK — gọi TRƯỚC
  /// `_quetTuDienChinhTa` (xem nơi gọi) để từ điển biết đường bỏ qua đúng
  /// những vùng đã là link. Bỏ qua vùng ĐANG gạch đỏ (AI)/gạch vàng (từ
  /// điển) đã chiếm trước — một chữ chỉ thuộc đúng một loại gạch chân.
  void _quetLienKet() {
    final ketQua = <_VungLienKet>[];
    final vb = _boDieuKhien.text;
    for (final m in _reLienKet.allMatches(vb)) {
      final khopGoc = m.group(0)!;
      final khop = _catDauCauCuoiLink(khopGoc);
      if (khop.isEmpty) continue;
      final batDau = m.start;
      final ketThuc = batDau + khop.length;
      final tuThat = vb.substring(batDau, ketThuc);
      if (_linkDaHuy.contains(tuThat)) continue;
      final dungCho = _boDieuKhien.loi.any((l) => l.batDau < ketThuc && l.ketThuc > batDau) ||
          _boDieuKhien.tuDien.any((t) => t.batDau < ketThuc && t.ketThuc > batDau) ||
          _boDieuKhien.khongPhuHop.any((k) =>
              (k.batDauGoc < ketThuc && k.ketThucGoc > batDau) ||
              (k.batDauDeXuat < ketThuc && k.ketThucDeXuat > batDau)) ||
          _boDieuKhien.canXoa.any((x) => x.batDau < ketThuc && x.ketThuc > batDau);
      if (dungCho) continue;
      ketQua.add(_VungLienKet(batDau: batDau, ketThuc: ketThuc, tu: tuThat));
    }
    _boDieuKhien.lienKet
      ..clear()
      ..addAll(ketQua);
    // (YÊU CẦU MỚI) Một đoạn đã là link thì KHÔNG được AI đề xuất xoá/thay
    // thế — các đề xuất AI (`loi`/`khongPhuHop`/`canXoa`) được thêm vào từ
    // nhiều nơi khác nhau (kiểm tra chính tả/toàn văn, chat sửa bài...),
    // không chặn được ngay lúc thêm mà không sửa từng nơi — dọn lại ở đây,
    // ngay sau mỗi lần quét link, để đề xuất nào lỡ dẫm vào vùng link cũng
    // biến mất khỏi màn hình.
    _boDieuKhien.loi.removeWhere(
        (l) => _boDieuKhien.lienKet.any((k) => l.batDau < k.ketThuc && l.ketThuc > k.batDau));
    _boDieuKhien.khongPhuHop.removeWhere((kp) => _boDieuKhien.lienKet.any((k) =>
        (kp.batDauGoc < k.ketThuc && kp.ketThucGoc > k.batDau) ||
        (kp.batDauDeXuat < k.ketThuc && kp.ketThucDeXuat > k.batDau)));
    _boDieuKhien.canXoa.removeWhere(
        (x) => _boDieuKhien.lienKet.any((k) => x.batDau < k.ketThuc && x.ketThuc > k.batDau));
  }

  /// Quét lại TOÀN BỘ bài theo "Từ điển sửa lỗi chính tả của bạn"
  /// (`widget.caiDat.tuDienChinhTa`) — dựng lại hẳn `_boDieuKhien.tuDien` từ
  /// đầu mỗi lần gọi (đơn giản, rẻ với từ điển/bài cỡ thường, không cần cơ
  /// chế dời offset riêng như `loi` của AI). Gọi lại sau mỗi lần lưu (xem
  /// `_henLuu`/`_luuVanBan`) và mỗi khi mở một ghi chú (`_moGhiChu`), hoặc
  /// ngay sau khi đóng modal "Từ điển..." (từ điển có thể vừa đổi).
  void _quetTuDienChinhTa() {
    // (YÊU CẦU MỚI — gạch chân link xanh dương) Quét link TRƯỚC — từ điển
    // phải biết vùng nào đã là link (xem `dungDoAi` dưới đây, đã gộp thêm
    // kiểm tra `_boDieuKhien.lienKet`) để không gạch vàng đè lên.
    _quetLienKet();
    final ketQua = <_LoiTuDien>[];
    // (YÊU CẦU MỚI — 2 bộ nhớ từ điển) Giờ có HAI công tắc riêng — Nội bộ
    // (`widget.caiDat.tuDienChinhTaBatHoatDong`) và Đám mây
    // (`TuDienChinhTaDamMay.dungChung?.bat`, chỉ có ý nghĩa lúc đã đăng
    // nhập) — bật cả hai, chỉ một, hay tắt cả hai đều hợp lệ. Gộp CHUNG một
    // bản đồ "từ lỗi (chữ thường) → các đề xuất thay thế" TRƯỚC khi quét, để
    // một từ có mặt ở CẢ HAI từ điển chỉ sinh ra ĐÚNG MỘT `_LoiTuDien` với
    // đề xuất Đám mây đứng TRƯỚC, đề xuất Nội bộ đứng SAU (đúng yêu cầu thứ
    // tự hiện trong menu bấm vào) — không cần đụng gì tới nơi dựng menu, nó
    // đã tự hiện đúng từng mục trong `dsThayThe` theo thứ tự có sẵn.
    final tuDienDamMay = TuDienChinhTaDamMay.dungChung;
    final capDamMay =
        (tuDienDamMay != null && tuDienDamMay.bat) ? tuDienDamMay.ds : const <CapTuDien>[];
    final capNoiBo =
        widget.caiDat.tuDienChinhTaBatHoatDong ? widget.caiDat.tuDienChinhTa : const <CapTuDien>[];
    if (capDamMay.isEmpty && capNoiBo.isEmpty) {
      _boDieuKhien.tuDien
        ..clear()
        ..addAll(ketQua);
      _boDieuKhien.veLai();
      return;
    }
    final vb = _boDieuKhien.text;
    // Khớp KHÔNG phân biệt hoa/thường (ví dụ khai "con chó" thì "con ChÓ"
    // trong bài cũng được gạch vàng) — tìm trên bản chữ thường của cả bài và
    // cả từ lỗi, nhưng [tu]/vị trí vẫn lấy nguyên văn CHỮ THẬT trong bài.
    final vbThuong = vb.toLowerCase();
    // Mục 5: hai cặp cùng "Từ bị lỗi chính tả hay gặp" trong CÙNG MỘT từ
    // điển (so không phân biệt hoa/thường) là trạng thái KHÔNG HỢP LỆ (modal
    // đã cảnh báo tại chỗ) — chỉ cặp XUẤT HIỆN ĐẦU TIÊN của từ điển đó được
    // dùng. Hai từ điển KHÁC NHAU cùng khai một từ lỗi thì KHÔNG phải trùng
    // lặp — đó chính là trường hợp cần gộp đề xuất (xem [deXuatGop]).
    final deXuatGop = <String, List<String>>{};
    void gopTu(List<CapTuDien> cap) {
      final loiDaDung = <String>{};
      for (final c in cap) {
        final loi = c.loi.trim();
        if (loi.isEmpty) continue;
        final loiThuong = loi.toLowerCase();
        if (!loiDaDung.add(loiThuong)) continue;
        // Mục 5: "Từ thay thế thứ nhất" giống hệt "Từ bị lỗi" (so không phân
        // biệt hoa/thường) là trạng thái KHÔNG HỢP LỆ — modal đã cảnh báo
        // tại chỗ, ở đây coi như chưa khai xong, không dùng để quét.
        if (c.thayThe.trim().toLowerCase() == loiThuong) continue;
        deXuatGop[loiThuong] = [...(deXuatGop[loiThuong] ?? []), ...c.dsThayThe];
      }
    }

    // Đám mây TRƯỚC, Nội bộ SAU — đúng thứ tự ưu tiên hiện trong menu.
    gopTu(capDamMay);
    gopTu(capNoiBo);

    // So KHÔNG phân biệt hoa/thường với "đã Huỷ đề xuất"/"đã do AI xử lý" —
    // giữ ĐÚNG hành vi cũ: huỷ một từ là huỷ CẢ TỪ đó (mọi lần xuất hiện,
    // mọi cách viết hoa/thường), không chỉ riêng đúng một lần xuất hiện.
    final daHuyThuong = _tuTuDienDaHuy.map((s) => s.toLowerCase()).toSet();
    final daXuLyThuong = _tuChinhTaDaXuLy.map((s) => s.toLowerCase()).toSet();

    for (final entry in deXuatGop.entries) {
      final loiThuong = entry.key;
      if (daHuyThuong.contains(loiThuong) || daXuLyThuong.contains(loiThuong)) continue;
      final dsThayThe = entry.value;
      var tu = 0;
      while (true) {
        final i = vbThuong.indexOf(loiThuong, tu);
        if (i < 0) break;
        final ketThuc = i + loiThuong.length;
        // Không gạch vàng đè lên vùng ĐANG gạch đỏ của AI, hay vùng ĐANG
        // gạch xanh dương của link.
        final dungDoAi = _boDieuKhien.loi.any((l) => l.batDau < ketThuc && l.ketThuc > i) ||
            _boDieuKhien.lienKet.any((k) => k.batDau < ketThuc && k.ketThuc > i);
        if (!dungDoAi) {
          ketQua.add(_LoiTuDien(
            batDau: i,
            ketThuc: ketThuc,
            tu: vb.substring(i, ketThuc),
            dsThayThe: dsThayThe,
          ));
        }
        tu = ketThuc;
      }
    }
    // YÊU CẦU MỚI: hai (hay nhiều) đề xuất từ điển có thể DẪM CHÂN lên nhau
    // trong cùng một cụm từ (ví dụ "con tr" và "trọ" cùng khớp trong "con
    // trọ") — chỉ giữ lại ĐÚNG MỘT đề xuất cho mỗi vùng chồng lấn: ưu tiên
    // đề xuất gạch NHIỀU KÝ TỰ NHẤT; bằng nhau thì ưu tiên đề xuất đứng
    // TRƯỚC (bên trái) hơn. Thuật toán tham lam chuẩn cho "chọn khoảng
    // không chồng lấn theo trọng số": xét theo đúng thứ tự ưu tiên đó, chỉ
    // nhận một đề xuất nếu nó CHƯA chồng lấn đề xuất nào đã nhận trước.
    final uuTien = List<_LoiTuDien>.of(ketQua)
      ..sort((a, b) {
        final doDaiA = a.ketThuc - a.batDau, doDaiB = b.ketThuc - b.batDau;
        if (doDaiA != doDaiB) return doDaiB.compareTo(doDaiA); // dài hơn trước
        return a.batDau.compareTo(b.batDau); // bằng nhau thì bên trái trước
      });
    final daNhan = <_LoiTuDien>[];
    for (final c in uuTien) {
      final chongLan =
          daNhan.any((d) => c.batDau < d.ketThuc && c.ketThuc > d.batDau);
      if (!chongLan) daNhan.add(c);
    }
    daNhan.sort((a, b) => a.batDau.compareTo(b.batDau));
    _boDieuKhien.tuDien
      ..clear()
      ..addAll(daNhan);
    _boDieuKhien.veLai();
  }

  Future<void> _luuVanBan() async {
    // (SỬA LỖI — "đi qua lại giữa các tệp đám mây bị lag") Trước đây hàm
    // này LUÔN gọi `suaNoiDungGhiChu` (tự đặt `capNhat = DateTime.now()`,
    // xem `kho_du_lieu.dart`) rồi `await widget.kho.luu()`, BẤT KỂ có gì
    // thật sự thay đổi hay không — mỗi lần bấm "Tệp trước/sau" đều gọi hàm
    // này một lượt. Với bộ nhớ NỘI BỘ, `luu()` chỉ ghi SharedPreferences,
    // gần như tức thì, không ai để ý. Với bộ nhớ ĐÁM MÂY
    // (`KhoDuLieuDamMay.luu()`), đổi `capNhat` khiến "ảnh chụp" JSON của
    // ghi chú LUÔN khác bản cũ — `luu()` tưởng nhầm nội dung thật đã đổi,
    // tự `await batch.commit()` lên Firestore (một lượt round-trip mạng
    // thật) dù người dùng chỉ lướt qua xem, không gõ gì cả — đúng cảm giác
    // "lag" mỗi lần chuyển tệp. `_coThayDoiChuaLuu` (đặt `true` ở `_henLuu`,
    // đúng mỗi lần có gõ/sửa định dạng thật) đã sẵn có để biết CHÍNH XÁC có
    // gì cần lưu hay không — không có gì mới thì khỏi đụng gì tới `kho`
    // luôn, tự thoát ngay tại đây.
    if (!_coThayDoiChuaLuu) return;
    _quetTuDienChinhTa();
    final khoiDinhDang = _macDinhDangAi();
    final khoiDinhDangThuCong = _macDinhDangThuCong();
    var noiDungLuu = _boDieuKhien.text;
    if (khoiDinhDang != null) noiDungLuu += _diemBatDauKhoiDinhDang + khoiDinhDang;
    if (khoiDinhDangThuCong != null) {
      noiDungLuu += _diemBatDauDinhDangThuCong + khoiDinhDangThuCong;
    }
    widget.kho.suaNoiDungGhiChu(_ghiChuHienTai.id, noiDungLuu);
    await widget.kho.luu();
    _coThayDoiChuaLuu = false;
  }

  /// Tách chuỗi lưu trữ thành (văn bản THẬT, khối AI mã hoá?, khối định dạng
  /// thủ công mã hoá?) — chịu được cả hai thứ tự khối lỡ xuất hiện, dù khi
  /// lưu luôn ghi khối AI trước rồi mới tới khối thủ công.
  (String, String?, String?) _tachCacKhoiDinhDang(String raw) {
    final viTriAi = raw.indexOf(_diemBatDauKhoiDinhDang);
    final viTriTc = raw.indexOf(_diemBatDauDinhDangThuCong);
    if (viTriAi < 0 && viTriTc < 0) return (raw, null, null);

    final viTriSom = (viTriAi >= 0 && (viTriTc < 0 || viTriAi < viTriTc)) ? viTriAi : viTriTc;
    final banDau = raw.substring(0, viTriSom);

    String? khoiAi;
    if (viTriAi >= 0) {
      final ketThucAi = (viTriTc > viTriAi) ? viTriTc : raw.length;
      khoiAi = raw.substring(viTriAi + _diemBatDauKhoiDinhDang.length, ketThucAi);
    }
    String? khoiTc;
    if (viTriTc >= 0) {
      khoiTc = raw.substring(viTriTc + _diemBatDauDinhDangThuCong.length);
    }
    return (banDau, khoiAi, khoiTc);
  }

  /// Đóng gói mọi vùng định dạng thủ công thành chuỗi base64 — null nếu
  /// không có vùng nào (ghi chú sạch không phình byte). Xem
  /// [_diemBatDauDinhDangThuCong].
  String? _macDinhDangThuCong() {
    final ds = _boDieuKhien.dinhDang.where((d) => !d.rong).map((d) => d.toJson()).toList();
    if (ds.isEmpty) return null;
    return base64Encode(utf8.encode(jsonEncode(ds)));
  }

  /// Ngược lại [_macDinhDangThuCong] — hỏng khuôn ở đâu thì bỏ qua đúng chỗ
  /// đó (từng mục được kiểm biên độc lập trong `_VungDinhDangThuCong.fromJson`),
  /// không làm hỏng cả ghi chú.
  void _apDungDinhDangThuCong(String maHoa) {
    try {
      final ds = jsonDecode(utf8.decode(base64Decode(maHoa)));
      if (ds is! List) return;
      final vb = _boDieuKhien.text;
      for (final j in ds) {
        if (j is Map) {
          final v = _VungDinhDangThuCong.fromJson(Map<String, dynamic>.from(j), vb.length);
          if (v != null) _boDieuKhien.dinhDang.add(v);
        }
      }
    } catch (_) {
      // Khối hỏng (dữ liệu cũ, lỗi mã hoá...) — bỏ qua toàn bộ, mất định
      // dạng còn hơn app không mở được ghi chú.
    }
  }

  /// Đóng gói mọi đánh dấu AI CÒN ĐANG CHỜ quyết định (lỗi chính tả, đoạn
  /// không phù hợp, đoạn cần xoá) thành một chuỗi mã hoá base64 — trả về
  /// null nếu không có gì để lưu, để một ghi chú sạch không phình thêm byte
  /// nào cả. Mục đang nhấp nháy (vừa quyết định xong, hiệu ứng thoáng qua 4
  /// giây) không được lưu — không còn ý nghĩa gì để giữ qua một lần mở lại.
  String? _macDinhDangAi() {
    final vb = _boDieuKhien.text;

    final loiDs = _boDieuKhien.loi
        .where((l) => l.batDau >= 0 && l.ketThuc <= vb.length && l.batDau < l.ketThuc)
        .map((l) => {
              ..._macVungDinhDang(vb, l.batDau, l.ketThuc - l.batDau),
              'dx': l.deXuat,
            })
        .toList();

    final kphDs = _boDieuKhien.khongPhuHop
        .where((k) =>
            k.nhapNhayMau == null &&
            k.batDauGoc >= 0 &&
            k.ketThucDeXuat <= vb.length &&
            k.batDauGoc <= k.ketThucGoc &&
            k.batDauDeXuat <= k.ketThucDeXuat)
        .map((k) => {
              'g': _macVungDinhDang(vb, k.batDauGoc, k.ketThucGoc - k.batDauGoc),
              'd': _macVungDinhDang(vb, k.batDauDeXuat, k.ketThucDeXuat - k.batDauDeXuat),
            })
        .toList();

    final cxDs = _boDieuKhien.canXoa
        .where((x) =>
            !x.dangNhapNhay && x.batDau >= 0 && x.ketThuc <= vb.length && x.batDau < x.ketThuc)
        .map((x) => _macVungDinhDang(vb, x.batDau, x.ketThuc - x.batDau))
        .toList();

    if (loiDs.isEmpty && kphDs.isEmpty && cxDs.isEmpty) return null;

    final goi = <String, dynamic>{};
    if (loiDs.isNotEmpty) goi['loi'] = loiDs;
    if (kphDs.isNotEmpty) goi['kph'] = kphDs;
    if (cxDs.isNotEmpty) goi['cx'] = cxDs;

    return base64Encode(utf8.encode(jsonEncode(goi)));
  }

  /// Ngược lại `_macDinhDangAi` — đọc lại khối mã hoá, XÁC MINH từng mục còn
  /// khớp với văn bản hiện tại không, mục nào không khớp thì ÂM THẦM bỏ qua.
  /// Không được để lỗi thoát ra ngoài — một khối hỏng (do app khác sửa file,
  /// hay bất cứ lý do gì) không bao giờ được phép chặn việc mở ghi chú.
  void _apDungDinhDangAi(String maHoa) {
    try {
      final goi = jsonDecode(utf8.decode(base64Decode(maHoa))) as Map<String, dynamic>;
      final vb = _boDieuKhien.text;

      for (final m in (goi['loi'] as List<dynamic>? ?? const [])) {
        if (m is! Map<String, dynamic> || !_khopVungDinhDang(vb, m)) continue;
        final batDau = m['vt'] as int;
        final dai = m['dai'] as int;
        final dx = ((m['dx'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
        if (dx.isEmpty) continue;
        _boDieuKhien.loi.add(LoiChinhTa(
          batDau: batDau,
          ketThuc: batDau + dai,
          tu: vb.substring(batDau, batDau + dai),
          deXuat: dx,
        ));
      }

      for (final m in (goi['kph'] as List<dynamic>? ?? const [])) {
        if (m is! Map<String, dynamic>) continue;
        final g = m['g'];
        final d = m['d'];
        if (g is! Map<String, dynamic> || d is! Map<String, dynamic>) continue;
        if (!_khopVungDinhDang(vb, g) || !_khopVungDinhDang(vb, d)) continue;
        final gVt = g['vt'] as int;
        final gDai = g['dai'] as int;
        final dVt = d['vt'] as int;
        final dDai = d['dai'] as int;
        _boDieuKhien.khongPhuHop.add(_VungKhongPhuHop(
          batDauGoc: gVt,
          ketThucGoc: gVt + gDai,
          batDauDeXuat: dVt,
          ketThucDeXuat: dVt + dDai,
        ));
      }

      for (final m in (goi['cx'] as List<dynamic>? ?? const [])) {
        if (m is! Map<String, dynamic> || !_khopVungDinhDang(vb, m)) continue;
        final batDau = m['vt'] as int;
        final dai = m['dai'] as int;
        _boDieuKhien.canXoa.add(_VungCanXoa(batDau: batDau, ketThuc: batDau + dai));
      }
    } catch (_) {
      // Khối định dạng hỏng hoặc sai khuôn — bỏ hẳn, ghi chú vẫn mở bình
      // thường với đúng phần văn bản thật, chỉ là không còn đánh dấu AI nào.
    }
  }

  void _henLuu() {
    _coThayDoiChuaLuu = true;
    _henLuuTru?.cancel();
    _henLuuTru = Timer(const Duration(milliseconds: 600), _luuVanBan);
  }

  Future<void> _bamNutLuu() async {
    await _luuVanBan();
    if (mounted) {
      hienThongBaoGiua(context, Ch.daLuuVaoBoNhoMay(ngonNguHienTai.value, _ghiChuHienTai.ten));
    }
  }

  // -------------------------------------------------------------- tên file

  void _khiOTenMatFocus() {
    if (_oTen.hasFocus) return;
    _xacNhanDoiTen();
  }

  void _xacNhanDoiTen() {
    final tenMoi = _tenController.text.trim();
    if (tenMoi.isEmpty) {
      _tenController.text = _ghiChuHienTai.ten;
      return;
    }
    if (tenMoi == _ghiChuHienTai.ten) return;
    final loi = widget.kho.doiTenGhiChu(_ghiChuHienTai.id, tenMoi);
    if (loi != null) {
      _tenController.text = _ghiChuHienTai.ten;
      _bao(loi);
      return;
    }
    widget.kho.luu();
  }

  // ---------------------------------------------------------------- cài đặt

  Future<void> _moCaiDat(NhomCaiDat nhom) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManHinhCaiDat(
          caiDat: widget.caiDat,
          nhom: nhom,
          // Người dùng vừa tắt "kiểm tra chính tả bằng AI": xoá hết gạch đỏ
          // đang hiển thị ngay, vì đó là dữ liệu riêng của trang soạn thảo,
          // màn Cài đặt không cầm được.
          khiTatKiemTraChinhTa: () {
            _boDieuKhien.loi.clear();
            _boDieuKhien.veLai();
          },
          khiKiemTraLaiMicro: _khoiTaoMicro,
          // (VIỆC 3) Người dùng vừa đổi cài đặt đường kẻ chia ngay trong màn
          // Cài đặt — cập nhật NGAY cho ghi chú đang mở, không cần đợi mở lại
          // ghi chú: BẬT thì quét lại toàn văn bản, TẮT thì xoá sạch danh
          // sách (painter cũng đã tự chặn vẽ khi tắt, đây chỉ là dọn dẹp cho
          // gọn). `setState` để buộc vẽ lại overlay ngay lập tức.
          khiDoiTuDongThemDuongKeChia: () {
            setState(() {
              _cacViTriDuongKeChia.clear();
              if (widget.caiDat.tuDongThemDuongKeChia) {
                _quetVaXayDungDuongKeChia();
              }
            });
          },
        ),
      ),
    );
    // Phím tắt (và trên web: thiết bị chọn tay) có thể vừa đổi trong màn
    // Cài đặt — vẽ lại nhãn/gate nút micro cho khớp giá trị mới nhất.
    if (mounted) {
      setState(() {
        _thietBiHienTai = widget.caiDat.thietBiChonTay ?? doanThietBi();
      });
    }
  }

  // --------------------------------------------------------------- thư mục

  Future<void> _moManHinhThuMuc() async {
    await _ngungMicroVaGhiAmTheNeuDangBat();
    if (!mounted) return;
    final idChon = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ManHinhThuMuc(
          kho: widget.kho,
          khoNoiBo: widget.khoNoiBo,
          idGhiChuDangMo: _ghiChuHienTai.id,
          caiDat: widget.caiDat,
        ),
      ),
    );
    if (!mounted) return;
    // (YÊU CẦU MỚI) Mỗi lần quay lại trang soạn thảo từ cây thư mục, tên
    // tệp lượn sóng một lần — bất kể có đổi sang tệp khác hay không.
    _kichHoatLuonSongTen();

    if (idChon != null && idChon != _ghiChuHienTai.id) {
      _moGhiChu(idChon);
      return;
    }

    // Không chọn gì — nhưng có thể ghi chú đang mở đã bị xoá hoặc đổi tên
    // trong lúc dạo thư mục.
    final vanConDo = widget.kho.timGhiChu(_ghiChuHienTai.id);
    if (vanConDo == null) {
      final moi = widget.kho.taoGhiChuMoi(thuMucGoc);
      await widget.kho.luu();
      _moGhiChu(moi.id);
      _bao(Ch.ghiChuDangMoDaBiXoaDaTaoMoi(ngonNguHienTai.value));
    } else {
      setState(() => _tenController.text = vanConDo.ten);
    }
  }

  /// (VIỆC 6b) Danh sách ghi chú trong CÙNG thư mục với ghi chú đang mở,
  /// đúng THỨ TỰ hiển thị của `ManHinhThuMuc` — TÁI DÙNG đúng
  /// `KhoDuLieu.noiDungThuMuc` (nguồn thứ tự DUY NHẤT, sắp theo tên không
  /// phân biệt hoa/thường), không tự bịa thứ tự khác.
  List<GhiChuFile> _dsGhiChuCungThuMuc() => widget.kho
      .noiDungThuMuc(
        _ghiChuHienTai.chaId,
        nguoc: widget.caiDat.sapXepNguoc(_ghiChuHienTai.chaId),
      )
      .ghiChuCon;

  /// (VIỆC 6b) "Tệp trước"/[buoc] = -1, "Tệp sau"/[buoc] = 1. (YÊU CẦU MỚI)
  /// KHÔNG còn dừng ở đầu/cuối — đi "vòng tròn khép kín": từ tệp đầu bấm
  /// "Tệp trước" nhảy tới tệp CUỐI, từ tệp cuối bấm "Tệp sau" nhảy về tệp
  /// ĐẦU (xem `_nutDieuHuongTep`, tô nền đỏ nhạt đúng nút đang ở biên đó).
  /// Chỉ liệt hẳn khi thư mục CHỈ CÓ một tệp (không có gì khác để nhảy tới).
  Future<void> _chuyenTepTrongThuMuc(int buoc) async {
    final ds = _dsGhiChuCungThuMuc();
    if (ds.length <= 1) return;
    final viTriHienTai = ds.indexWhere((g) => g.id == _ghiChuHienTai.id);
    if (viTriHienTai < 0) return;
    final viTriMoi = (viTriHienTai + buoc) % ds.length;
    final tepMoi = ds[viTriMoi];

    // Lưu ghi chú đang mở TRƯỚC KHI chuyển — đúng luồng `_moManHinhThuMuc`
    // đã dùng khi rời trang (tắt micro nếu đang nghe, rồi lưu).
    await _ngungMicroVaGhiAmTheNeuDangBat();
    if (!mounted) return;
    await _luuVanBan();
    if (!mounted) return;

    _moGhiChu(tepMoi.id);
    // (YÊU CẦU MỚI) Chuyển sang tệp khác bằng nút Tệp trước/sau — tên tệp
    // lượn sóng một lần.
    _kichHoatLuonSongTen();
    _baoDangOTrongTep(tepMoi.ten);
  }

  /// Nút "Mở rộng" ở thanh công cụ tên tệp — "Tạo Tệp văn bản mới": hỏi tên
  /// (gợi ý sẵn, sửa được) TRƯỚC khi tạo, giống hệt cách màn hình thư mục
  /// làm (`_hoiTenMoiTao` trong `man_hinh_thu_muc.dart`) — không đi vòng qua
  /// màn hình thư mục, tạo và chuyển thẳng tại đây.
  Future<void> _taoTepMoiTuThanhCongCu() async {
    if (_muonNghe) await _tatMicro();
    if (!mounted) return;
    await _luuVanBan();
    if (!mounted) return;

    final chaId = _ghiChuHienTai.chaId;
    final goiY = widget.kho.tenGhiChuGoiY(chaId);
    final ten = await _hoiTenTepMoi(goiY: goiY, chaId: chaId);
    if (ten == null || !mounted) return;

    final moi = widget.kho.taoGhiChuMoi(chaId);
    widget.kho.doiTenGhiChu(moi.id, ten); // đã kiểm hợp lệ trong hộp thoại.
    await widget.kho.luu();
    if (!mounted) return;
    _moGhiChu(moi.id);
    // (YÊU CẦU MỚI) Thêm tệp mới rồi nhảy sang nó — tên tệp lượn sóng một
    // lần, cùng hiệu ứng với Tệp trước/sau và xoá tệp.
    _kichHoatLuonSongTen();
    _baoDangOTrongTep(moi.ten);
  }

  /// Y hệt `_hoiTenMoiTao` của màn hình thư mục — kiểm tên ngay khi bấm Lưu,
  /// sai thì báo lỗi tại chỗ, không đóng hộp thoại.
  Future<String?> _hoiTenTepMoi({required String goiY, required String chaId}) {
    final bo = TextEditingController(text: goiY)
      ..selection = TextSelection(baseOffset: 0, extentOffset: goiY.length);
    String? loi;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhat) {
          return AlertDialog(
            title: Text(Ch.taoTepVanBanMoi(ngonNguHienTai.value)),
            content: TextField(
              controller: bo,
              autofocus: true,
              maxLength: doDaiTenToiDa,
              inputFormatters: [FilteringTextInputFormatter.deny(kyTuCamTrongTen)],
              decoration: InputDecoration(errorText: loi),
              onSubmitted: (_) {
                final k = widget.kho.loiTenTrongThuMuc(bo.text, chaId);
                if (k != null) {
                  capNhat(() => loi = k);
                  return;
                }
                Navigator.of(ctx).pop(bo.text.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(Ch.huy(ngonNguHienTai.value)),
              ),
              FilledButton(
                onPressed: () {
                  final k = widget.kho.loiTenTrongThuMuc(bo.text, chaId);
                  if (k != null) {
                    capNhat(() => loi = k);
                    return;
                  }
                  Navigator.of(ctx).pop(bo.text.trim());
                },
                child: Text(Ch.tao(ngonNguHienTai.value)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "Chuyển vào thùng rác" — KHÔNG hỏi xác nhận (khôi phục được trong 30
  /// ngày qua Thùng rác Nội bộ ở cây thư mục, xem `lib/modal_thung_rac.dart`
  /// và `lib/kho_du_lieu.dart`), xong nhảy sang tệp NGAY SAU tệp vừa xoá
  /// (YÊU CẦU MỚI — trước đây luôn nhảy về tệp ĐẦU danh sách); không còn
  /// tệp sau (vừa xoá đúng tệp cuối) thì lùi về tệp NGAY TRƯỚC nó; không
  /// còn tệp nào trong thư mục nữa (vừa xoá tệp duy nhất) thì tự tạo
  /// "Ghi chú N" (hệt tên tự gợi ý mặc định) — rồi làm việc ngay ở tệp đó,
  /// kèm thông báo giữa màn hình VÀ hiệu ứng lượn sóng tên tệp một lần
  /// (YÊU CẦU MỚI, xem `_kichHoatLuonSongTen`).
  Future<void> _xoaTepHienTaiTuThanhCongCu() async {
    final chaId = _ghiChuHienTai.chaId;
    final idVuaXoa = _ghiChuHienTai.id;
    final viTriVuaXoa =
        widget.kho.noiDungThuMuc(chaId).ghiChuCon.indexWhere((g) => g.id == idVuaXoa);
    widget.kho.chuyenGhiChuVaoThungRac(idVuaXoa);
    // Dọn luôn bộ nhớ đệm Lùi lại/Tiến tới của tệp vừa xoá — tệp không còn
    // hiện ra ở cây thư mục nữa thì giữ lại mốc cũ trong Map chỉ tổ chiếm
    // bộ nhớ vô ích.
    _lichSuLuiTheoTep.remove(idVuaXoa);
    _lichSuToiTheoTep.remove(idVuaXoa);
    _thuTuMoTepGanDay.remove(idVuaXoa);

    final conLai = widget.kho.noiDungThuMuc(chaId).ghiChuCon;
    final laTuDongTao = conLai.isEmpty;
    // Mọi phần tử đứng SAU tệp vừa xoá đã tự dồn lên đúng một bậc — tệp ở
    // ĐÚNG [viTriVuaXoa] trong danh sách MỚI (nếu còn tồn tại) chính là tệp
    // từng nằm NGAY SAU tệp vừa xoá. Hết tệp sau (vừa xoá đúng tệp cuối,
    // [viTriVuaXoa] đã vượt khỏi danh sách mới) thì lùi về tệp liền trước.
    final GhiChuFile ke;
    if (laTuDongTao) {
      ke = widget.kho.taoGhiChuMoi(chaId);
    } else if (viTriVuaXoa >= 0 && viTriVuaXoa < conLai.length) {
      ke = conLai[viTriVuaXoa];
    } else {
      ke = conLai[(viTriVuaXoa - 1).clamp(0, conLai.length - 1)];
    }
    await widget.kho.luu();
    if (!mounted) return;
    hienThongBaoGiua(context, Ch.daDiChuyenVaoThungRac(ngonNguHienTai.value), ganTren: true);
    _moGhiChu(ke.id);
    _kichHoatLuonSongTen();
    if (laTuDongTao) {
      _bao('Đã chuyển vào thùng rác — đang ở trong tệp "${ke.ten}" do hệ'
          'thống tự tạo.');
    } else {
      _baoDangOTrongTep(ke.ten);
    }
  }

  /// "Chọn màu Tên Tệp" ở nút "Mở rộng" — CÙNG bảng màu và CÙNG cách lưu với
  /// menu ba chấm của màn hình thư mục (`mau_co_ban.dart`), chỉ khác chỗ mở
  /// ra (từ thanh công cụ, cho tệp ĐANG MỞ) — tên tệp ở thanh công cụ tự
  /// động lấy đúng màu này vì `_oTenField()` đọc `_ghiChuHienTai.mau` mỗi
  /// lần dựng lại, không cần đồng bộ tay.
  Future<void> _chonMauTenTepHienTai() async {
    final mau = await hienThiChonMauCoBanChoTen(
      context,
      tieuDe: Ch.chonMauTenTep(ngonNguHienTai.value),
    );
    if (mau == null || !mounted) return;
    widget.kho.datMauGhiChu(_ghiChuHienTai.id, mau.value);
    setState(() {});
    await widget.kho.luu();
  }

  /// (YÊU CẦU MỚI — "Khi khởi động App: Mở tệp...") Ghi lại tệp đang soạn
  /// thảo gần đây nhất, bất kể kho nào — chỉ dùng cho lựa chọn "Mở tệp
  /// đang soạn thảo gần đây nhất" lúc khởi động app tiếp theo (xem
  /// `khoi_dong_tep.dart`). Gọi mỗi lần MỞ (kể cả lần đầu ở `initState`)
  /// hay CHUYỂN ghi chú — `widget.kho` ở đây LUÔN đúng kho của
  /// `_ghiChuHienTai` (hai field cùng đổi trong cùng `_moGhiChu`/
  /// `initState`, không bao giờ lệch pha).
  void _ghiNhoGanDayNhatChoKhoiDong() {
    final laDamMay = widget.kho is KhoDuLieuDamMay;
    unawaited(widget.caiDat.ghiNhoGanDayNhat(
      laDamMay: laDamMay,
      id: laDamMay ? _ghiChuHienTai.id : null,
      uid: laDamMay ? (widget.kho as KhoDuLieuDamMay).uid : null,
    ));
  }

  void _moGhiChu(String id) {
    final g = widget.kho.timGhiChu(id);
    if (g == null) return;
    _ganDauDaMoTepChoLichSu(id);
    // (YÊU CẦU MỚI) Nhớ vị trí cuộn của tệp SẮP RỜI ĐI trước khi đổi — xem
    // `_ghiNhoViTriCuon`. Gọi `_phucHoiViTriCuon` cho tệp MỚI ở cuối hàm.
    _ghiNhoViTriCuon();

    setState(() {
      _ghiChuHienTai = g;
      _tenController.text = g.ten;
    });
    _ghiNhoGanDayNhatChoKhoiDong();

    // (SỬA LỖI định dạng/khối mã hoá "dính" từ tệp cũ sang tệp mới) Trước
    // đây hàm này ghi thẳng `g.noiDung` — có thể còn mang khối AI/định dạng
    // thủ công mã hoá ở cuối (xem `_tachCacKhoiDinhDang`) — vào ô soạn thảo,
    // và không xoá `_boDieuKhien.dinhDang` (vùng đậm/màu) của ghi chú VỪA
    // RỜI ĐI. Kết quả: chuỗi mã hoá lộ ra thành text thấy được, rồi mỗi lần
    // lưu lại bị mã hoá thêm một lớp mới chồng lên (phình dần); còn các vùng
    // đậm/màu cũ thì áp nhầm offset lên văn bản ghi chú MỚI. Phải xử lý y
    // hệt `initState`: tách khối trước, xoá sạch định dạng cũ, rồi mới áp
    // định dạng của đúng ghi chú đang mở.
    _boDieuKhien.dinhDang.clear();
    final (banDau, khoiDinhDang, khoiDinhDangThuCong) = _tachCacKhoiDinhDang(g.noiDung);

    // (YÊU CẦU MỚI — giới hạn ký tự một tệp) Y hệt `initState`: đây là NẠP
    // một ghi chú có sẵn (có thể dài hơn giới hạn từ trước khi có nó), không
    // phải người dùng gõ/dán thêm — đừng để `_ghiVaoO` chặn/cắt bớt.
    _dangTrongLucMoGhiChu = true;
    if (banDau.isEmpty) {
      _ghiVaoO('', 0);
    } else {
      _ghiVaoO(banDau, banDau.length);
    }
    _dangTrongLucMoGhiChu = false;
    if (khoiDinhDang != null) _apDungDinhDangAi(khoiDinhDang);
    if (khoiDinhDangThuCong != null) _apDungDinhDangThuCong(khoiDinhDangThuCong);
    _neo = banDau.length;
    _chuTam = '';
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    _viTriDaKiemTraChinhTa = banDau.length;
    // (Bộ nhớ đệm Lùi lại/Tiến tới giờ tách riêng theo từng tệp — xem getter
    // `_lichSuLui`/`_lichSuToi` — không cần xoá gì ở đây nữa: `_ghiChuHienTai`
    // vừa đổi ở trên tự khiến getter trỏ sang đúng cặp danh sách của tệp mới,
    // còn cặp của tệp vừa rời vẫn giữ nguyên mốc trong Map để quay lại vẫn
    // thấy.)
    // (SỬA LỖI đường kẻ chia "bóng ma") Ghi chú KHÁC có thể mang toạ độ
    // đường kẻ chia hoàn toàn không liên quan tới ghi chú vừa mở — không xoá
    // thì offset cũ (ví dụ 0) vẫn "hợp lệ" trên văn bản mới (kể cả văn bản
    // rỗng) và painter cứ thế vẽ nhầm ngay từ dòng đầu tiên.
    _cacViTriDuongKeChia.clear();
    // (VIỆC 3) Quét lại TOÀN BỘ văn bản của ghi chú vừa mở để dựng lại các
    // đường kẻ chia đã có TRƯỚC ĐÓ (không dựa vào bộ nhớ tạm vừa bị xoá ở
    // trên) — chỉ quét khi tính năng đang BẬT, để tránh làm việc thừa (và để
    // painter luôn có một lớp bảo vệ kép: dù lỡ quét, cũng KHÔNG vẽ khi cài
    // đặt đang tắt — xem `_veDuongKeChia`).
    if (widget.caiDat.tuDongThemDuongKeChia) {
      _quetVaXayDungDuongKeChia();
    }
    _quetTuDienChinhTa();
    _viTriChoVietHoa = null;

    widget.kho.datGhiChuDangMo(id);
    _phucHoiViTriCuon(id);
  }

  // ----------------------------------------------------------------- micro

  Future<void> _khoiTaoMicro() async {
    final duoc = await _micro.initialize(
      onStatus: _khiDoiTrangThai,
      onError: (loi) {
        // 'error_no_match' và 'error_speech_timeout' chỉ nghĩa là người dùng
        // im lặng — không phải hỏng, đừng làm phiền họ. 'error_client' xảy ra
        // rất thường xuyên vì app tự bật lại micro liên tục (kể cả lúc không
        // nghe thấy gì) — Android thỉnh thoảng từ chối một lượt bật lại quá
        // nhanh, tự hết ngay ở lượt kế tiếp, không phải sự cố đáng báo.
        // 'error_busy' (micro đang bị ứng dụng khác chiếm) cũng thuộc loại
        // này: xảy ra thoáng qua trong lúc ghi âm, không hề chặn việc nhận
        // diện giọng nói/chèn chữ (app tự bật lại ngay ở lượt kế tiếp — xem
        // `_henBatLai()` bên dưới, vẫn luôn được gọi dù không hiển thị lỗi),
        // và tự hết khi ứng dụng kia nhả micro ra. Hiển thị nó chỉ gây rối
        // mắt không cần thiết; các lỗi micro nghiêm trọng khác (mất quyền,
        // không có micro, mất mạng...) vẫn hiển thị bình thường qua nhánh
        // else bên dưới.
        // 'error_aborted'/'aborted' CHỈ bỏ qua trên WEB: Web Speech API bắn
        // lỗi này hầu như mỗi lần app tự dừng/bật lại micro (chuyện xảy ra
        // liên tục, xem `_henBatLai()`), dù micro vẫn đang nghe/nhận chữ
        // hoàn toàn bình thường — không phải sự cố thật, không đáng làm
        // phiền người dùng bằng dòng "Micro gặp trục trặc". Android/iOS gốc
        // không dùng Web Speech API nên KHÔNG áp dụng ngoại lệ này, giữ
        // nguyên hiển thị nếu có xảy ra (chưa từng thấy xảy ra thật).
        //
        // (SỬA LỖI thông báo vẫn lọt qua) Lần trước chỉ loại `'error_aborted'`
        // — nhưng dòng thông báo người dùng gửi lại đọc đúng nguyên văn
        // "(aborted)" không có tiền tố "error_", nghĩa là chuỗi lỗi THẬT sự
        // trình duyệt trả về (qua speech_to_text) là `'aborted'`, không khớp
        // điều kiện cũ nên lọt qua thành thông báo hiển thị. Thêm cả hai dạng
        // để chắc chắn khớp bất kể phiên bản/trình duyệt nào trả về dạng nào.
        final nhe = loi.errorMsg == 'error_no_match' ||
            loi.errorMsg == 'error_speech_timeout' ||
            loi.errorMsg == 'error_client' ||
            loi.errorMsg == 'error_busy' ||
            (kIsWeb &&
                (loi.errorMsg == 'error_aborted' || loi.errorMsg == 'aborted'));
        if (!nhe && mounted) {
          setState(() => _loi = _dichLoi(loi.errorMsg));
        }
        _henBatLai();
      },
      debugLogging: false,
    );
    if (!mounted) return;
    if (duoc) {
      _maNgonNgu = await _chonTiengViet();
    }
    setState(() {
      _sanSang = duoc;
      if (!duoc) {
        _loi = 'Máy không dùng được micro. Hãy kiểm tra quyền ghi âm và '
            'ứng dụng Google trên máy.';
      }
    });
  }

  /// Ưu tiên tiếng Việt nếu máy có; không có thì để máy tự chọn.
  Future<String?> _chonTiengViet() async {
    try {
      final ds = await _micro.locales();
      for (final l in ds) {
        if (l.localeId.replaceAll('-', '_').toLowerCase().startsWith('vi')) {
          return l.localeId;
        }
      }
    } catch (_) {
      // Không lấy được danh sách thì cứ để mặc định.
    }
    return null;
  }

  void _khiDoiTrangThai(String trangThai) {
    final dangChay = trangThai == SpeechToText.listeningStatus;
    if (mounted && _dangNghe != dangChay) {
      setState(() => _dangNghe = dangChay);
    }
    if (!dangChay) {
      // (RACE CONDITION KHI CHUYỂN PHIÊN — LỚP 1) Tăng session-ID NGAY TẠI
      // ĐÂY, đồng bộ, không đợi `stop()`/`cancel()` xong hay hẹn giờ
      // `_henBatLai` chạy — để mọi callback `onResult` của phiên vừa chết bị
      // vứt NGAY LẬP TỨC, kể cả khi một sự kiện chuyển phiên KHÁC (bấm phím
      // tắt cắt nhanh) đang xảy ra gần như cùng lúc.
      _phienNgheHienTai++;
      _henBatLai();
    }
  }

  /// Android tự ngắt nhận dạng sau vài giây im lặng. Ta bật lại ngay để người
  /// dùng thấy micro như luôn bật. Khe hở ngắn này là giới hạn của hệ điều
  /// hành, không phải lỗi của ứng dụng.
  void _henBatLai() {
    if (!_muonNghe) return;
    _hen?.cancel();
    _hen = Timer(const Duration(milliseconds: 200), () {
      if (_muonNghe && !_micro.isListening) _batMicro();
    });
  }

  Future<void> _batMicro() async {
    if (!_sanSang) return;
    _rawTichLuyChromeAndroid = '';
    // (RACE CONDITION KHI CHUYỂN PHIÊN — LỚP 2) Chụp lại đệm chống nhân đôi
    // TRƯỚC khi `_chotCauDangDoc()` xoá rỗng `_tuDaChotTrongPhien` ngay dưới
    // đây — đây là điểm MỘT phiên nghe MỚI thật sự sắp bắt đầu.
    _luuBoDemRanhGioiPhien();
    _chotCauDangDoc();
    _luuDiemMoc(); // Mỗi lượt micro mới là một điểm có thể Lùi lại về.
    _boQuaCauNay = false;
    _dangCatCau = false;

    // Đánh số PHIÊN nghe — mỗi lần _batMicro() chạy (kể cả tự bật lại sau
    // khi hệ điều hành tự ngắt vì im lặng) là một phiên MỚI. `onResult` chỉ
    // nhận đúng phiên vừa đăng ký (so `idPhien` chụp lúc này với
    // `_phienNgheHienTai` tại thời điểm callback chạy); phiên cũ đóng rồi mà
    // vẫn có kết quả trễ bay về (bộ nhận dạng đôi khi trả thêm một kết quả
    // chốt cuối cùng sau khi đã coi như đã ngắt) thì bị vứt thẳng, không cho
    // nhập lại vào bài — đây chính là nguồn gốc lỗi thỉnh thoảng nhân đôi cả
    // một câu vừa nói xong: phiên mới đã coi đoạn đó là chữ THẬT rồi, kết
    // quả trễ của phiên cũ lại chèn thêm một lần nữa.
    final idPhien = ++_phienNgheHienTai;
    try {
      await _micro.listen(
        onResult: (ketQua) {
          if (idPhien != _phienNgheHienTai) return;
          _khiCoChu(ketQua, idPhien);
        },
        localeId: _maNgonNgu,
        onSoundLevelChange: _khiDoiMucAm,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          autoPunctuation: true,
        ),
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 8),
      );
    } catch (_) {
      _henBatLai();
    }
  }

  Future<void> _tatMicro() async {
    // (LỚP 1) Tăng session-ID ngay, đồng bộ — phiên đang nghe coi như chết
    // từ đây, không đợi cancel() xong.
    _phienNgheHienTai++;
    _muonNghe = false;
    _henTuTatMicroImLang?.cancel();
    _hen?.cancel();
    // Chặn NGAY mọi kết quả còn đang trên đường về, trước khi ra lệnh tắt —
    // nếu không, một câu đang nói dở sẽ trả về kết quả chốt SAU KHI đã bấm
    // tắt, đổ thêm một lần chữ nữa đè lên trên chữ vừa hiện.
    _boQuaCauNay = true;
    _chotCauDangDoc(); // Chữ đã hiện ra đứng im tại đó, không sửa thêm.
    // cancel() vứt bỏ hẳn phiên nghe, không như stop() còn cố trả về một kết
    // quả chốt cuối cùng — chính kết quả chốt đó là nguồn gốc của lỗi nhân
    // đôi câu nói khi bấm tắt micro.
    await _micro.cancel();
    if (mounted) {
      setState(() {
        _dangNghe = false;
        _songAm.fillRange(0, _songAm.length, 0);
      });
    }
  }

  /// (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Gọi ở ĐẦU mọi nút/menu
  /// NGOÀI vùng soạn thảo chính (thư mục, hướng dẫn, từ điển nhập liệu
  /// nhanh, bộ nhớ tạm, ba menu thả xuống Làm việc với AI/Thêm lựa chọn/
  /// Tài khoản-Cài đặt, menu ba chấm cạnh nút thư mục, Tệp trước/sau, sửa
  /// tên tệp, Lùi lại/Tiến tới) — NGƯNG HẲN Ghi âm/Micro đang hoạt động,
  /// KHÔNG để tự bật lại. Ghi âm dùng ĐÚNG lối thoát "Hoàn thành-Đóng trình
  /// ghi âm" (`_dongTrinhGhiAmThe`, chốt thẻ đang ghi trước khi đóng) —
  /// KHÔNG phải huỷ bỏ dở dang.
  Future<void> _ngungMicroVaGhiAmTheNeuDangBat() async {
    if (_trinhGhiAmMo) await _dongTrinhGhiAmThe();
    if (!mounted) return;
    if (_muonNghe) await _tatMicro();
  }

  // ---------------------------------- bộ phím nhanh cho màn hình cảm ứng

  /// Chặn bàn phím ảo bật lên + hiện hàng phím thay thế (chấm/phẩy/cách/
  /// xuống dòng/xoá) ngay trên thanh công cụ dưới. Nguyên văn ý tưởng đã
  /// kiểm chứng ở `main_web_test.dart` (`_chanBanPhimAo`), chỉ đổi cách
  /// chèn ký tự để đi ĐÚNG con đường "như đang gõ tay thật" của trang này
  /// (gán trực tiếp `_boDieuKhien.value` để `_khiNguoiDungSua` tự nhận ra
  /// và xử lý y hệt một lượt gõ tay — auto viết hoa/tự chèn cách/điểm lùi
  /// lại đều áp dụng đầy đủ), KHÔNG dùng đường `_ghiVaoO` (dành cho chữ do
  /// máy/AI tự ghi).
  bool _boPhimNhanhCamUngMo = false;

  /// (YÊU CẦU MỚI) Bấm một trong bốn nút "Làm việc với AI"/"Thêm lựa
  /// chọn"/"Tài khoản và Cài đặt"/"Bật bộ phím nhanh" (CHỈ lúc BẬT, không
  /// áp dụng cho "Tắt bộ phím nhanh") coi như một cơ hội để tự dọn lỗi "bãi
  /// đất trống" — KHOÁ HẲN bàn phím ảo không cho hiện lên (không chỉ gọi
  /// 'TextInput.hide' một lần — chạm/focus rơi lại vào ô soạn thảo ngay
  /// trong lúc menu/Bộ phím nhanh đang mở ra vẫn có thể kéo bàn phím ảo
  /// bật lên lại; mượn đúng cờ `readOnly` tạm thời `_epAnBanPhimAoKhiGiuFocus`
  /// đã dùng cho Copy/Cắt/Dán/All để KHOÁ thật trong một khoảng ngắn) và
  /// đổi khoá (`GlobalKey`) của ô soạn thảo để ép Flutter đo lại khung hình
  /// từ đầu, ĐÚNG mẹo đã dùng cho lỗi kẹt bàn phím ảo ở Copy/Cắt/Dán/All.
  ///
  /// (SỬA LỖI — "bấm 4 nút này lại làm 'bãi đất trống' DỄ hiện ra hơn, chứ
  /// không reset được gì") Người dùng xác nhận: hoàn toàn không sao khi bàn
  /// phím ảo ĐANG ẨN từ trước; chỉ hỏng khi bàn phím ảo ĐANG HIỆN — chính
  /// việc TA chủ động ép ẩn nó đi (`TextInput.hide`) là THỨ TẠO RA tiền đề
  /// của lỗi (y hệt lúc người dùng tự ẩn bàn phím ảo bằng nút Back, xem
  /// CLAUDE.md), rồi bỏ đó chờ "nhịp tim" 300ms (`dangKyThamDoChieuCaoVienPort`)
  /// tự dọn — có khoảng hở nhìn thấy được trước khi nhịp tim kịp chạy. Sửa:
  /// 1. KHÔNG làm gì cả (bỏ hẳn hàm này) nếu bàn phím ảo đang ẨN sẵn — không
  ///    có gì để "ẩn" thì cũng không có gì để tạo ra khoảng hở, đừng tự tạo
  ///    việc.
  /// 2. Đang HIỆN thì vẫn phải ẩn (menu/Bộ phím nhanh cần full màn hình),
  ///    nhưng ngay sau đó tự ép `setState` NGAY (không đợi nhịp tim) LIÊN
  ///    TỤC trong gần 2 giây — dọn sạch khoảng hở trước khi mắt người dùng
  ///    kịp thấy, đúng việc nhịp tim vẫn làm nhưng chủ động làm NGAY hơn là
  ///    bị động chờ.
  ///
  /// (SỬA LỖI — "phải bấm lần 2/3 mới hết") Bản vá đầu chỉ ép `setState` vài
  /// lần rải trong 400ms đầu — không đủ: khoá bàn phím ảo trên thiết bị
  /// thật có lúc mất hơn 400ms để thật sự "nhả" khoảng không đã chiếm (hệ
  /// điều hành chạy hiệu ứng trượt xuống chứ không biến mất ngay tức khắc).
  /// Bấm lần 2/3 "vô tình" hết vì nó rơi đúng lúc hiệu ứng đã xong, không
  /// phải vì bản thân việc bấm lại có tác dụng gì đặc biệt. Kéo dài cửa sổ
  /// ép `setState` ra gần 2 giây, dày hơn (mỗi 50ms) để chắc chắn bắt kịp
  /// bất kể hiệu ứng ẩn bàn phím ảo chạy chậm tới đâu. Cũng bỏ hẳn việc đổi
  /// `GlobalKey` ở đây — mẹo đó dùng cho lỗi KHÁC (bàn phím ảo "liệt" không
  /// bật lại được, xem Copy/Cắt/Dán/All), không liên quan tới việc ĐO LẠI
  /// kích thước sau khi ẩn, mà việc dựng lại cả `TextField` từ đầu (dù chỉ
  /// một khung hình) cũng tự nó là một nguồn gây giật/hở hình, phản tác
  /// dụng ở đúng tình huống này.
  /// (YÊU CẦU MỚI — LUÔN áp dụng, không chỉ lúc bàn phím ảo đang hiện)
  /// Màn hình không tự biết được nó có đang dính lỗi "bãi đất trống" hay
  /// không — nên cửa sổ ép `setState` liên tục gần 2 giây này giờ LUÔN
  /// chạy mỗi lần bấm 1 trong 4 nút, bất kể bàn phím ảo lúc đó đang hiện
  /// hay đang ẩn. Phần ẨN BÀN PHÍM ẢO THẬT (`TextInput.hide` + khoá tạm
  /// `_epAnBanPhimAoKhiGiuFocus`) vẫn CHỈ làm khi bàn phím ảo đang hiện —
  /// gọi 'TextInput.hide' lúc nó đã ẩn sẵn không có tác dụng gì, chỉ thêm
  /// việc.
  void _resetManHinhTruocKhiMoMenu() {
    if (!mounted) return;
    // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Mở một trong ba menu
    // thả xuống (Làm việc với AI/Thêm lựa chọn/Tài khoản-Cài đặt) coi như
    // "bấm nút ngoài vùng soạn thảo" — ngưng hẳn Ghi âm/Micro, không tự bật
    // lại. Mọi mục BÊN TRONG các menu này đều phải mở menu trước, nên chặn
    // đúng một chỗ này là đủ cho toàn bộ ba menu.
    unawaited(_ngungMicroVaGhiAmTheNeuDangBat());
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      setState(() => _epAnBanPhimAoKhiGiuFocus = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _epAnBanPhimAoKhiGiuFocus = false);
      });
    }
    for (var tre = 30; tre <= 1800; tre += 50) {
      Future.delayed(Duration(milliseconds: tre), () {
        if (mounted) setState(() {});
      });
    }
  }

  void _bamNutBoPhimNhanhCamUng() {
    // Bấm nút này (bật/tắt Bộ phím nhanh) mà micro đang nghe thì tạm tắt-bật
    // lại y hệt lúc gõ tay một ký tự bất kỳ (chữ đã hiện đứng yên, chữ chưa
    // hiện bị chặn), tránh micro nghe nhầm lúc tay đang bận bấm nút.
    _nguoiDungVuaGo();
    final dangBat = !_boPhimNhanhCamUngMo;
    // (YÊU CẦU MỚI) Bấm BẬT (không áp dụng cho TẮT) coi như một trong các
    // nút "reset màn hình", xem `_resetManHinhTruocKhiMoMenu`.
    if (dangBat) _resetManHinhTruocKhiMoMenu();
    setState(() {
      _boPhimNhanhCamUngMo = dangBat;
      if (!dangBat) {
        _epHienBanPhimAoTrongBoPhimNhanh = false;
        _thuGonTruocKhiEpBanPhimAo = null;
      }
      // Bật Bộ phím nhanh lên thì tự ẩn luôn thanh định dạng thủ công (nếu
      // đang hiện) — nhường tối đa chỗ ngang cho các hàng công cụ mới của
      // Bộ phím nhanh; muốn xem lại thì tự bấm nút "abc" cạnh nút Lưu.
      if (dangBat) _anThanhDinhDang = true;
    });
    if (dangBat) {
      _batConTroNgay();
      _epConTroHienRaMatThuong();
      if (mounted) {
        hienThongBaoGiua(
          context,
          Ch.banPhimBiKhoaDangBatBoPhimNhanh(ngonNguHienTai.value),
        );
      }
    }
  }

  /// (SỬA LỖI con trỏ nháy có lúc "biến mất" khi vừa bật/hiện lại Bộ phím
  /// nhanh) Bật/hiện các thanh công cụ của Bộ phím nhanh KHÔNG hề đổi tiêu
  /// điểm của `_oChu` (đã giữ sẵn từ trước) nên nhịp nhấp nháy 500ms
  /// (`_khiFocusConTroDoi`) không hề reset — nếu đúng lúc đó nhịp đang ở
  /// pha "ẩn", con trỏ biến mất khỏi mắt người dùng ngay khi vừa bật, có
  /// cảm giác như lỗi. Khởi động lại hẳn timer từ đầu, LUÔN bắt đầu ở pha
  /// "hiện", để người dùng thấy được con trỏ ngay tại vị trí nó đang đứng.
  void _batConTroNgay() {
    _henNhapNhayConTro?.cancel();
    _conTroDangHien.value = true;
    _henNhapNhayConTro = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _conTroDangHien.value = !_conTroDangHien.value;
    });
  }

  /// Hẹn giờ của `_epConTroHienRaMatThuong` — huỷ/gán lại mỗi lần gọi (Ẩn
  /// rồi Hiện lại liên tiếp nhanh tay không được để hai mẹo chồng nhau).
  Timer? _henEpConTro;

  /// (SỬA LỖI TRIỆT ĐỂ con trỏ vẫn không hiện — `_batConTroNgay` một mình
  /// không đủ) Bấm hộ nút "Trái" rồi "Phải" của hàng điều hướng
  /// (`_diChuyenConTro`) — hai nút đó tự quan sát được là LUÔN ép con trỏ
  /// nháy hiện ra ngay khi bấm. Đứng ở vị trí ĐẦU văn bản thì chỉ bấm hộ
  /// đúng một nút "Trái" (không bấm tiếp "Phải") — bấm "Trái" lúc đó vốn đã
  /// là no-op vị trí (không lùi được nữa) nên tự nó đủ để ép con trỏ hiện
  /// ra rồi, bấm thêm "Phải" chỉ khiến con trỏ dịch sai đi 1 ký tự.
  ///
  /// (BỎ mẹo chèn+xoá dấu cách) Mẹo cũ nhờ hộ nút dấu cách/Xoá — vẫn có rủi
  /// ro XOÁ MẤT vùng đang được chọn (gõ đè lên selection) trước khi tự xoá
  /// lại. Nút điều hướng Trái/Phải chỉ ĐỔI VỊ TRÍ con trỏ, không đụng nội
  /// dung, nên an toàn tuyệt đối với vùng đang chọn.
  ///
  /// Vẫn giữ trì hoãn 300ms trước khi "bấm" — bàn phím ảo bật/tắt kèm đổi
  /// `readOnly` kéo theo một nhịp layout/resize riêng của hệ điều hành/
  /// trình duyệt đến sau khung hình kế tiếp; trì hoãn để cặp bấm-hộ này
  /// luôn là sự kiện cuối cùng, chạy sau khi màn hình đã ổn định hẳn.
  void _epConTroHienRaMatThuong() {
    _henEpConTro?.cancel();
    _henEpConTro = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final oDauVanBan = _boDieuKhien.selection.baseOffset <= 0;
      _diChuyenConTro(dx: -1);
      if (oDauVanBan) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _diChuyenConTro(dx: 1);
      });
    });
  }

  /// Nút "bàn phím" (cạnh End, `_xayHangDieuHuongConTro`) — cho phép bàn
  /// phím ảo hệ thống hiện SONG SONG với các thanh công cụ của Bộ phím
  /// nhanh (giữ nguyên mọi thanh công cụ đang hiện, chỉ CHO PHÉP THÊM bàn
  /// phím ảo hệ thống hiện song song để gõ tay ngay cạnh các nút bấm sẵn).
  /// `readOnly` của ô soạn thảo (xem `build`) phải trừ thêm cờ này ra thì
  /// bàn phím ảo mới thật sự hiện được.
  bool _epHienBanPhimAoTrongBoPhimNhanh = false;

  /// Giá trị `_thuGonThanhCongCu` NGAY TRƯỚC lúc bấm nút bàn phím lần 1 —
  /// bấm lần 2 (tắt bàn phím ảo) phải trả về ĐÚNG giá trị này (đang thu gọn
  /// thì tiếp tục thu gọn, đang hiện thì tiếp tục hiện), không phải luôn
  /// luôn mở thanh công cụ ra lại.
  bool? _thuGonTruocKhiEpBanPhimAo;

  void _bamNutBanPhimAoTrongBoPhimNhanh() {
    // Xem giải thích ở `_bamNutBoPhimNhanhCamUng` — cùng lý do, áp dụng cho
    // cả hai lần bấm (hiện lẫn tắt bàn phím ảo).
    _nguoiDungVuaGo();
    if (_epHienBanPhimAoTrongBoPhimNhanh) {
      // Lần 2: tắt bàn phím ảo lại, trả `_thuGonThanhCongCu` về đúng giá
      // trị trước khi bấm lần 1 — mọi thanh công cụ của Bộ phím nhanh vẫn
      // giữ nguyên như cũ suốt từ đầu, không đụng vào.
      setState(() {
        _epHienBanPhimAoTrongBoPhimNhanh = false;
        _thuGonThanhCongCu = _thuGonTruocKhiEpBanPhimAo ?? _thuGonThanhCongCu;
        _thuGonTruocKhiEpBanPhimAo = null;
      });
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      // Y hệt mẹo ép con trỏ hiện ra dùng khi bật/hiện Bộ phím nhanh — tắt
      // bàn phím ảo đi cũng làm cả trang dựng lại (readOnly đổi), có cùng
      // rủi ro con trỏ "biến mất" khỏi mắt người dùng.
      _epConTroHienRaMatThuong();
      return;
    }
    // Lần 1: nhớ lại trạng thái Thu gọn hiện tại trước khi ép nó bật lên
    // (nhường chỗ cho bàn phím ảo) — chỉ ép khi CHƯA thu gọn sẵn.
    _thuGonTruocKhiEpBanPhimAo = _thuGonThanhCongCu;
    setState(() {
      _epHienBanPhimAoTrongBoPhimNhanh = true;
      _thuGonThanhCongCu = true;
    });
    hienThongBaoGiua(context, Ch.daMoKhoaBanPhim(ngonNguHienTai.value), ganTren: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _oChu.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
    _batConTroNgay();
    // (YÊU CẦU MỚI) Bấm nút này nhiều lần dồn dập có thể làm trình duyệt
    // "liệt" khả năng tự bật lại bàn phím ảo — ĐÚNG HỌ với lỗi kẹt bàn
    // phím ảo ở Copy/Cắt/Dán/All đã sửa dứt điểm bằng cách đổi khoá
    // (`GlobalKey`) của ô soạn thảo, xem `_lamMoiOVanBanDeThoatKetBanPhimAo`.
    // Áp dụng đúng mẹo đó: sau 1,5 giây, nếu bàn phím ảo VẪN chưa hiện
    // (đọc lại `viewInsets.bottom` tại thời điểm hẹn giờ chạy) thì đổi khoá
    // rồi xin focus + show lại.
    _henLamMoiOVanBanDeThoatKet?.cancel();
    _henLamMoiOVanBanDeThoatKet = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || !_epHienBanPhimAoTrongBoPhimNhanh) return;
      if (MediaQuery.of(context).viewInsets.bottom > 0) return;
      _lamMoiOVanBanDeThoatKetBanPhimAo();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      });
    });
  }

  /// Danh sách ký tự trong bảng "*" (`_moBangKyTuDacBiet`) — đúng nguyên
  /// văn bộ ký tự đã yêu cầu, giữ nguyên thứ tự.
  static const _dsKyTuDacBiet = [
    '.', ',', '_', '~', '`', '|', '•', '√', 'π', '÷', '×', '¶', '∆', '@', '#',
    '\$', '%', '&', '-', '+', '(', ')', '/', '*', '"', "'", ':', ';', '!', '?',
    '£', '¢', '€', '¥', '^', '°', '=', '{', '}', '…', '\\', '©', '®', '™',
    '℅', '[', ']', '<', '>',
  ];

  /// Bảng ký tự đặc biệt mở từ nút "*" cạnh nút bàn phím — mỗi ô một ký tự,
  /// bấm vào là chèn NGAY vào vị trí con trỏ/thay vùng đang chọn (đi qua
  /// đúng `_chenKyTuTuPhimAo`, y hệt các nút của hàng phím ảo).
  ///
  /// "Tự động đóng bảng" (`caiDat.tuDongDongBangKyTuDacBiet`, mặc định BẬT,
  /// lưu lại giữa các lần mở app) quyết định bấm MỘT ký tự có đóng bảng lại
  /// ngay hay không — bật thì đóng ngay sau đúng một lần chèn, tắt thì cứ
  /// chèn liên tục nhiều ký tự tuỳ ý, tự bấm "Đóng bảng" (hoặc nút X đỏ góc
  /// trên-phải, cùng logic) khi xong. Dòng chữ trạng thái + nút Bật/Tắt tự
  /// động đổi ngay khi bấm (dùng `StatefulBuilder` — dialog vốn không tự
  /// dựng lại theo `setState` của trang chính).
  void _moBangKyTuDacBiet() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, dungLai) {
          final tuDong = widget.caiDat.tuDongDongBangKyTuDacBiet;
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(Ch.kyTuDacBiet(ngonNguHienTai.value), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: Ch.dongBang(ngonNguHienTai.value),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final kt in _dsKyTuDacBiet)
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {},
                              onTapDown: (_) {
                                _chenKyTuTuPhimAo(kt);
                                if (widget.caiDat.tuDongDongBangKyTuDacBiet) {
                                  Navigator.of(ctx).pop();
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: Text(kt, style: const TextStyle(fontSize: 17)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tuDong ? 'Đang BẬT tự động Đóng bảng' : 'Đang TẮT tự động đóng bảng',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tuDong ? Colors.red.shade600 : Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await widget.caiDat.datTuDongDongBangKyTuDacBiet(!tuDong);
                            dungLai(() {});
                          },
                          child: Text(tuDong
                              ? Ch.tatTuDong(ngonNguHienTai.value)
                              : Ch.batTuDong(ngonNguHienTai.value)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(Ch.dongBang(ngonNguHienTai.value)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// [batDau, ketThuc) sắp bị gõ/xoá đè lên có chồng lấn MỘT PHẦN thẻ ghi
  /// âm nào không (chồng lấn nhưng không phủ trọn) — dùng để quyết định có
  /// cần hỏi xác nhận trước khi xoá thẻ hay không, y hệt logic đã có trong
  /// `ChanSuaGiuaThe`. Trả về (batDau, ketThuc) của thẻ đó, hoặc null.
  (int, int)? _theGhiAmChongLanMotPhan(int batDau, int ketThuc) {
    for (final (tb, tk) in timCacVungTheGhiAm(_boDieuKhien.text)) {
      final chongLan = batDau < tk && ketThuc > tb;
      final phuTron = batDau <= tb && ketThuc >= tk;
      if (chongLan && !phuTron) return (tb, tk);
    }
    return null;
  }

  /// Chèn một ký tự (hoặc cụm ký tự cố định như dấu cách/xuống dòng) từ
  /// hàng phím ảo, tại vị trí con trỏ/thay cho vùng đang chọn — CHẠY QUA
  /// ĐÚNG con đường một lượt gõ tay thật đi qua (xem chú thích khai báo
  /// `_boPhimNhanhCamUngMo`).
  void _chenKyTuTuPhimAo(String kyTu) {
    final vb = _boDieuKhien.text;
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) return;
    final batDau = chon.start;
    final ketThuc = chon.end;
    final theChongLan = _theGhiAmChongLanMotPhan(batDau, ketThuc);
    if (theChongLan != null) {
      _khiCanXoaTheTuBanPhim(theChongLan.$1, theChongLan.$2);
      return;
    }
    final moi = vb.replaceRange(batDau, ketThuc, kyTu);
    _boDieuKhien.value = TextEditingValue(
      text: moi,
      selection: TextSelection.collapsed(offset: batDau + kyTu.length),
    );
    // ĐÃ SỬA (màn hình không cuộn theo con trỏ khi bấm nút Bộ phím nhanh):
    // trước đây chỉ mũi tên Lên/Xuống/Trái/Phải (`_diChuyenConTro`) gọi
    // hàm cuộn này — mọi nút khác (chấm, phẩy, cách, xuống dòng ở đây) đều
    // thiếu, khiến con trỏ có thể trôi ra ngoài khung nhìn mà màn hình
    // không theo, nhất là văn bản dài.
    _cuonToiConTroNeuCan();
    // (SỬA LỖI con trỏ nháy biến mất) Nút hàng phím ảo cũng là một widget
    // nhận focus được — bấm vào nó cướp mất tiêu điểm của `_oChu` NGAY SAU
    // `onPressed`, làm `_veConTro()` (chỉ vẽ khi `_oChu.hasFocus`) ẩn con
    // trỏ dù logic vẫn đúng. Cùng kỹ thuật đã dùng cho thanh định dạng thủ
    // công (`_apDungDinhDang`): hoãn `requestFocus()` sang cuối khung hình
    // để thắng focus của nút.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
    });
  }

  /// Phím "Xoá" (backspace) của hàng phím ảo — xoá vùng đang chọn, hoặc
  /// một ký tự ngay trước con trỏ nếu không có vùng chọn.
  void _xoaKyTuTuPhimAo() {
    final vb = _boDieuKhien.text;
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) return;
    int batDau, ketThuc;
    if (!chon.isCollapsed) {
      batDau = chon.start;
      ketThuc = chon.end;
    } else {
      if (chon.start <= 0) return;
      batDau = chon.start - 1;
      ketThuc = chon.start;
    }
    final theChongLan = _theGhiAmChongLanMotPhan(batDau, ketThuc);
    if (theChongLan != null) {
      _khiCanXoaTheTuBanPhim(theChongLan.$1, theChongLan.$2);
      return;
    }
    final moi = vb.replaceRange(batDau, ketThuc, '');
    _boDieuKhien.value =
        TextEditingValue(text: moi, selection: TextSelection.collapsed(offset: batDau));
    _cuonToiConTroNeuCan();
    // Xem giải thích ở `_chenKyTuTuPhimAo` — cùng lý do, cùng cách sửa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
    });
  }

  /// (YÊU CẦU MỚI) Nút "Xoá" ở hàng Copy/Cắt (`_hangCopyCutPaste`) dùng LẠI
  /// đúng `_xoaKyTuTuPhimAo` (không viết logic xoá mới) nhưng CẦN thêm đúng
  /// quy tắc giữ trạng thái bàn phím ảo mà Copy/Cắt đang có (`_phimAoCopy`/
  /// `_phimAoCut` đều tự gọi `_giuFocusOChuSauKhiBam()` ở cuối) — bàn phím
  /// ảo đang hiện thì tiếp tục hiện, đang ẩn thì tiếp tục ẩn. KHÔNG sửa
  /// thẳng vào `_xoaKyTuTuPhimAo` vì hàm đó còn dùng chung cho nút ⌫ của Bộ
  /// phím nhanh — nơi đó có quy tắc `readOnly` RIÊNG của chính nó
  /// (`_epHienBanPhimAoTrongBoPhimNhanh`), gọi thêm `_giuFocusOChuSauKhiBam()`
  /// vào đó sẽ đụng nhau.
  void _xoaChonOHangCopyCutPaste() {
    _xoaKyTuTuPhimAo();
    _giuFocusOChuSauKhiBam();
  }

  /// `true` = tạm ép `_oChu` thành `readOnly` CHỈ để xin focus mà không cho
  /// bàn phím ảo hệ thống bật lên — xem `_giuTieuDiemKhongBatBanPhimAo`.
  /// Không liên quan gì tới `readOnly` do Bộ phím nhanh gây ra (đã có cờ
  /// riêng, không đụng vào), chỉ cộng thêm một điều kiện `readOnly` nữa ở
  /// `build`.
  bool _epAnBanPhimAoKhiGiuFocus = false;

  /// Đếm phiên cho `_giuTieuDiemKhongBatBanPhimAo` — xem giải thích ở đó.
  int _phienAnBanPhimAo = 0;

  /// Giành lại tiêu điểm cho ô soạn thảo sau khi bấm một trong 4 nút
  /// Copy/Cắt/Dán/All ở thanh công cụ dưới hoặc Bộ phím nhanh — xem giải
  /// thích gốc ở `_chenKyTuTuPhimAo`.
  ///
  /// YÊU CẦU: bàn phím ảo hệ thống đang HIỆN thì bấm 4 nút này KHÔNG được
  /// làm nó tự ẩn đi; đang ẨN thì KHÔNG được làm nó tự bật ra. Flutter
  /// không có cách hỏi thẳng "bàn phím ảo lúc này có đang hiện hay không"
  /// — tín hiệu đáng tin nhất hiện có là `viewInsets.bottom` (khác 0 nghĩa
  /// là có thứ gì đó đang chiếm đáy màn hình, tức bàn phím đang hiện thật).
  /// Giá trị NÀY CÓ THỂ "kẹt" ở 0 (dù bàn phím vừa bị ẩn) khi người dùng ẩn
  /// bàn phím bằng phím Back của hệ thống — lỗi đã biết, xem CLAUDE.md "Lỗi
  /// tồn đọng" — nên KHÔNG phân biệt được "đang ẩn thật" với "đang hiện
  /// nhưng tín hiệu kẹt sai thành ẩn". Theo đúng yêu cầu: KHÔNG CHẮC thì
  /// coi như ĐANG ẨN (an toàn hơn — lỡ không tự bật lại dù đáng ra phải bật
  /// còn hơn tự bật bàn phím lên ngoài ý muốn người dùng).
  void _giuFocusOChuSauKhiBam() {
    final banPhimDangHienThat = MediaQuery.of(context).viewInsets.bottom > 0;
    if (!banPhimDangHienThat) {
      _giuTieuDiemKhongBatBanPhimAo();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
    });
  }

  /// Xin lại tiêu điểm cho `_oChu` nhưng CHẶN bàn phím ảo hệ thống bật lên —
  /// dùng lại đúng mẹo đã chứng minh hoạt động ở Bộ phím nhanh: một ô
  /// `readOnly` vẫn nhận focus được, nhưng hệ thống không tự bật bàn phím
  /// cho nó. Trả `readOnly` về lại bình thường ngay ở khung hình kế tiếp —
  /// chỉ cần đủ lâu để vượt qua đúng nhịp hệ thống QUYẾT ĐỊNH có bật bàn
  /// phím hay không lúc field nhận focus, không ảnh hưởng gì tới việc gõ
  /// tay sau đó.
  ///
  /// (SỬA LỖI v119) Bấm liên tiếp quá nhanh vào Copy/Cắt/All lúc bàn phím ảo
  /// đang ẨN trước đây làm hàm này chạy chồng nhiều lần cùng lúc — mỗi lần
  /// gọi đều tự bật rồi tự tắt `readOnly` qua một cặp `addPostFrameCallback`
  /// riêng, không lần nào biết tới lần khác. Bật/tắt thuộc tính `readOnly`
  /// của ô nhập liên tục, dồn dập như vậy có lúc làm trình duyệt (web) đánh
  /// mất hẳn khả năng tự bật lại bàn phím ảo cho ô đó, phải tải lại trang
  /// mới hết. Sửa bằng một mã phiên tăng dần (`_phienAnBanPhimAo`): mỗi lần
  /// gọi hàm này đều lấy một số phiên mới; chỉ lần gọi GẦN NHẤT mới còn giữ
  /// đúng số phiên hiện tại ở hai mốc kiểm tra bên dưới, nên `readOnly` chỉ
  /// thật sự bật lên MỘT lần (nếu đang tắt) rồi giữ nguyên suốt các lần bấm
  /// dồn dập, và chỉ tắt lại đúng MỘT lần, sau khi lần bấm cuối cùng đã yên —
  /// không còn cảnh bật/tắt xen nhau liên tục nữa.
  void _giuTieuDiemKhongBatBanPhimAo() {
    // (SỬA LỖI — thảo luận với người dùng, "4 lần dọn ống đều không ăn,
    // nghi ngờ chính cơ chế readOnly/clearClient/GlobalKey mới là NGUYÊN
    // NHÂN, không phải cách chữa") Toàn bộ phần dưới (đổi `readOnly` tạm
    // thời, `clearClient`, hẹn giờ đổi `GlobalKey`) CHỈ tồn tại để chống
    // bàn phím ẢO tự bật/kẹt — thứ bàn phím VẬT LÝ không hề đụng tới. Cờ
    // `_coBanPhimVatLy` đã có từ lâu để nhận biết đúng điều đó (xem chú
    // thích gốc ở nơi khai báo), nhưng trước đây hàm này vẫn LỠ áp dụng
    // một phần cơ chế đó (bật `_epAnBanPhimAoKhiGiuFocus` ngay từ đầu hàm,
    // trước cả khi kiểm tra cờ) cho MỌI thiết bị — tức là bàn phím vật lý
    // vẫn bị đổi `readOnly` qua lại mỗi lần bấm Copy/Cắt/Dán/All/Micro,
    // dù hoàn toàn không cần. Rất có thể chính việc đổi `readOnly` liên
    // tục đó mới là thứ làm "liệt" kết nối bàn phím vật lý — 4 lần dọn
    // ống trước đây đều chữa ở hạ nguồn, không chặn đúng hành động gây
    // ra lỗi. Kiểm tra cờ này NGAY ĐẦU hàm — có bàn phím vật lý thì CHỈ
    // xin lại tiêu điểm, không đụng gì khác (không `readOnly`, không
    // `clearClient`, không đổi `GlobalKey`) — trả lại đúng hành vi của
    // trang TRƯỚC KHI có các nút Copy/Cắt/Dán/All/Micro "nâng cao" này.
    if (_coBanPhimVatLy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _oChu.requestFocus();
      });
      return;
    }
    if (_boPhimNhanhCamUngMo) {
      // Bộ phím nhanh đang mở đã tự lo đúng `readOnly` theo quy tắc riêng
      // của nó rồi (`_epHienBanPhimAoTrongBoPhimNhanh`) — không đụng vào,
      // chỉ xin focus bình thường.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _oChu.requestFocus();
      });
      return;
    }
    final phien = ++_phienAnBanPhimAo;
    if (!_epAnBanPhimAoKhiGiuFocus) {
      setState(() => _epAnBanPhimAoKhiGiuFocus = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || phien != _phienAnBanPhimAo) return;
      _oChu.requestFocus();
    });

    // (SỬA LỖI v120 — "cứng đầu", vẫn còn kẹt sau v119, cả ở Dán) Bật/tắt
    // `readOnly` liên tục, dồn dập có lúc làm trình duyệt (web) đánh mất
    // hẳn khả năng tự bật lại bàn phím ảo cho ĐÚNG phần tử DOM ẩn mà
    // Flutter Web dùng để đồng bộ — mỗi lần F5 lại "sống" được vì trang tải
    // lại dựng phần tử DOM đó từ đầu. Giả lập ĐÚNG hiệu ứng "dựng lại từ
    // đầu" đó nhưng CHỈ cho riêng ô soạn thảo, không mất chữ: đổi
    // `_oVanBanKey` sang một `GlobalKey` MỚI khiến Flutter coi `TextField`
    // là một widget HOÀN TOÀN KHÁC ở lần build kế tiếp — huỷ hẳn
    // Element/RenderEditable/kết nối bàn phím ảo CŨ (đang nghi bị "liệt")
    // rồi dựng lại một kết nối MỚI từ đầu, trong khi `_boDieuKhien` (nội
    // dung) và `_oChu` (FocusNode) vẫn giữ nguyên nên không mất chữ/không
    // mất tiêu điểm. Xem thêm bước dọn kết nối cấp thấp ở
    // `_lamMoiOVanBanDeThoatKetBanPhimAo`.
    //
    // (SỬA LỖI — nhánh thử nghiệm, phát hiện thêm) `readOnly` ở trên tắt
    // lại sau đúng 60ms kể từ MỖI lần bấm — nếu người dùng bấm liên tiếp
    // cách nhau CHẬM hơn 60ms nhưng vẫn khá nhanh (vài trăm ms, kiểu bấm
    // dồn dập bằng tay), `readOnly` sẽ kịp tắt rồi bật lại NHIỀU LẦN, mỗi
    // lần là một chu kỳ bật/tắt THẬT — đúng kiểu hành vi mà chính ghi chú
    // v119/v120 ở trên đã cảnh báo có thể làm trình duyệt liệt. Sửa: gộp
    // việc tắt `readOnly` vào ĐÚNG hẹn giờ yên [_treDungLaiOVanBanMs] bên
    // dưới — trong suốt một đợt bấm dồn dập, `readOnly` chỉ bật lên MỘT
    // lần ở đầu đợt, giữ nguyên `true` liên tục, và chỉ tắt lại khi hẹn
    // giờ đó thật sự chạy (nghĩa là người dùng đã yên tay đủ lâu) — không
    // còn nháy giữa chừng nữa.
    //
    // Chỉ làm việc này SAU một khoảng yên (không phải ngay lập tức — tránh
    // dựng lại giữa lúc người dùng còn đang bấm dồn dập các nút khác), và
    // CHỈ khi lúc đó bàn phím ảo VẪN đang ẩn thật (đọc lại `viewInsets.bottom`
    // ngay tại thời điểm hẹn giờ chạy, không dùng giá trị cũ) — nếu người
    // dùng đã tự chạm vào ô và bàn phím đã hiện lên bình thường trong lúc
    // chờ, đừng đụng vào gì nữa. Mã phiên `_phienAnBanPhimAo` (dùng lại y
    // hệt ở trên) đảm bảo chỉ lần bấm GẦN NHẤT mới thật sự kích hoạt.
    //
    // (SỬA LỖI — nhánh thử nghiệm) Khoảng yên này hạ từ 1,5 giây xuống
    // [_treDungLaiOVanBanMs] — vẫn đủ dài hơn hẳn một lần bấm đôi tự nhiên
    // của ngón tay (tránh dựng lại giữa lúc bấm dồn dập), nhưng đỡ cảm giác
    // "khựng" hơn hẳn. KHÔNG liên quan gì tới cơ chế chống kẹt bàn phím ảo
    // (mã phiên `_phienAnBanPhimAo` ở trên lo việc đó) — số này chỉ là thời
    // gian CHỜ trước khi áp dụng cách chữa, không phải một mốc phần cứng.
    //
    // Trong lúc chờ, hiện "Đang xử lý" ở giữa màn hình — y hệt khung thông
    // báo "Đã copy/cắt/dán..." (cao 85%, `ganTren: true`) nhưng vẽ TRÒN
    // GIỮA màn hình nên không chồng lên nhau, và chỉ ẩn đi khi hẹn giờ này
    // thật sự chạy (xem `_dangXuLyEntry`) — không phải một con số ghi cứng
    // riêng, luôn khớp đúng thời gian chờ thật.
    _dangXuLyEntry?.remove();
    _dangXuLyEntry = hienThongBaoDangXuLyGiua(context, 'Đang xử lý');
    _henLamMoiOVanBanDeThoatKet?.cancel();
    _henLamMoiOVanBanDeThoatKet = Timer(const Duration(milliseconds: _treDungLaiOVanBanMs), () {
      _dangXuLyEntry?.remove();
      _dangXuLyEntry = null;
      if (!mounted || phien != _phienAnBanPhimAo) return;
      if (mounted) setState(() => _epAnBanPhimAoKhiGiuFocus = false);
      if (MediaQuery.of(context).viewInsets.bottom > 0) return;
      _lamMoiOVanBanDeThoatKetBanPhimAo();
      // (SỬA LỖI — thảo luận với người dùng, "liệt bàn phím ảo sau khi bàn
      // phím đã ẩn từ trước") Đã dọn xong kết nối (`clearClient` + đổi
      // `GlobalKey` ở trên) nhưng KHÔNG tự gọi `TextInput.show()` ngay tại
      // đây — lệnh đó chạy trong `Timer`, không đi kèm một cử chỉ chạm thật
      // nào của người dùng, nên trình duyệt có thể lặng lẽ chặn không cho
      // tự bật bàn phím ảo lên (đúng lý do mẹo tay của người dùng luôn cần
      // một lần CHẠM LẠI vào ô sau khi bật nút "bàn phím" của Bộ phím
      // nhanh). Bật cờ này — lần `onTap` KẾ TIẾP vào ô soạn thảo (xem
      // `TextField` chính ở `build`) sẽ tự gọi `TextInput.show()` NGAY
      // trong đúng lượt chạm đó, mượn cử chỉ thật của người dùng, rồi tự
      // tắt cờ.
      _choChamLaiDeBatBanPhimAo = true;
    });
  }

  /// Xem chú thích ở nơi được bật, trong `_giuTieuDiemKhongBatBanPhimAo`.
  bool _choChamLaiDeBatBanPhimAo = false;

  /// Khoảng yên trước khi dựng lại ô soạn thảo để thoát kẹt bàn phím ảo —
  /// xem giải thích ở `_giuTieuDiemKhongBatBanPhimAo`.
  static const _treDungLaiOVanBanMs = 450;

  Timer? _henLamMoiOVanBanDeThoatKet;

  /// Thông báo "Đang xử lý" đang hiện (nếu có) trong lúc chờ hẹn giờ ở
  /// trên — `null` khi không có gì đang chờ.
  OverlayEntry? _dangXuLyEntry;

  /// (SỬA LỖI — nhánh thử nghiệm) Đổi `_oVanBanKey` ở trên huỷ hẳn
  /// `Scrollable` cũ của ô soạn thảo rồi dựng một cái MỚI, gắn lại đúng
  /// `_cuonVanBan` (cùng một instance) — nhưng `ScrollPosition` cũ (đang giữ
  /// độ cuộn hiện tại) đã mất theo widget cũ, nên `ScrollPosition` MỚI luôn
  /// khởi đầu ở 0 (đầu trang), bất kể đang cuộn ở đâu lúc dựng lại. Đó là
  /// gốc rễ màn hình tự "nhảy" lên đầu ~1,5 giây sau khi bấm Copy/Cắt/Dán/
  /// All (mọi nút đều đi qua `_giuFocusOChuSauKhiBam` →
  /// `_giuTieuDiemKhongBatBanPhimAo`, cùng cơ chế này). Ghi lại độ cuộn
  /// NGAY TRƯỚC khi đổi key, rồi trả lại đúng chỗ đó ở khung hình kế tiếp
  /// (sau khi `Scrollable` mới đã gắn xong) — không đụng gì tới mục đích
  /// ban đầu của việc đổi key (thoát kẹt kết nối bàn phím ảo).
  ///
  /// (SỬA LỖI — nhánh thử nghiệm, "mức 2") Đổi `GlobalKey` chỉ dọn lại
  /// Element/RenderEditable ở tầng Flutter — nếu chỗ "liệt" thật ra nằm sâu
  /// hơn, ở tầng kết nối giữa engine và bàn phím ảo của hệ thống (cái mà
  /// `SystemChannels.textInput` quản lý), đổi key không chắc chạm tới
  /// được. Gọi thẳng `TextInput.clearClient` TRƯỚC khi đổi key — lệnh cấp
  /// thấp này buộc engine "quên" hẳn mọi client đang gắn (kể cả một client
  /// cũ đang nghi bị liệt), cho `TextField` mới dựng lên một kết nối HOÀN
  /// TOÀN MỚI thay vì có thể lỡ thừa hưởng lại đúng cái đang hỏng. Không
  /// mất chữ/tiêu điểm — đây là lệnh dọn đường ống, không đụng gì tới nội
  /// dung hay `FocusNode`.
  void _lamMoiOVanBanDeThoatKetBanPhimAo() {
    if (!mounted) return;
    final cuonCu = _cuonVanBan.hasClients ? _cuonVanBan.offset : null;
    SystemChannels.textInput.invokeMethod<void>('TextInput.clearClient');
    setState(() => _oVanBanKey = GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _oChu.requestFocus();
      if (cuonCu != null && _cuonVanBan.hasClients) {
        final toiDa = _cuonVanBan.position.maxScrollExtent;
        _cuonVanBan.jumpTo(cuonCu.clamp(0.0, toiDa));
      }
    });
  }

  /// Lần bấm GẦN NHẤT của Home/End — dùng để nhận biết "bấm 2 lần liên tiếp
  /// trong 1 giây" (nhảy lên/xuống hẳn đầu/cuối văn bản) khác với "bấm 1
  /// lần" (chỉ nhảy tới đầu/cuối DÒNG hiện tại của con trỏ).
  DateTime? _lanBamHomeTruoc;
  DateTime? _lanBamEndTruoc;
  static const _nguongBamHaiLan = Duration(seconds: 1);

  /// (RIÊNG cho nút "All") không còn là bấm-2-lần nhị phân như Home/End nữa
  /// mà là ĐẾM tới 3 lần, nên cần một bộ đếm thật (`_demBamAll`) thay vì chỉ
  /// một mốc thời gian — và ngưỡng thời gian giữa hai lần bấm liên tiếp cũng
  /// riêng, 1,5 giây thay vì 1 giây như các nút khác.
  DateTime? _lanBamAllTruoc;
  int _demBamAll = 0;
  static const _nguongBamAll = Duration(seconds: 2);

  // ---------------------------------- copy/cắt/dán GIỮ ĐỊNH DẠNG (chỉ web)

  /// Đánh dấu ở ĐẦU chuỗi `text/html` ghi kèm lúc Copy/Cắt — bọc một gói
  /// JSON (base64, ĐÚNG khuôn `_macDinhDangThuCong`/`_apDungDinhDangThuCong`
  /// đã dùng để lưu/đọc tệp) trong một COMMENT HTML, nên mọi trình duyệt/ứng
  /// dụng khác đọc `text/html` này đều bỏ qua vô hại — chỉ Flowrite (đọc lại
  /// ở [_tachGoiDinhDangTuHtml]) hiểu và khôi phục ĐÚNG TUYỆT ĐỐI. Phần HTML
  /// còn lại (thẻ `<b>/<i>/span style=...`) mới là thứ Google Docs/Excel...
  /// thật sự đọc khi dán, xem [_dinhDangThuCongSangHtml].
  static const _danhDauGoiDinhDangClip = 'FLOWRITE-CLIP-V1';
  static final _reGoiDinhDangClip = RegExp('<!--$_danhDauGoiDinhDangClip:([A-Za-z0-9+/=]+)-->');

  /// Đóng gói các vùng định dạng thủ công GIAO với [batDau, ketThuc) thành
  /// base64 — offset dịch về 0 tại [batDau] (toạ độ TƯƠNG ĐỐI trong đoạn vừa
  /// copy, vì nơi dán có thể ở một tệp khác, offset tuyệt đối vô nghĩa).
  /// Kèm độ dài + mã băm của đoạn văn bản gốc để bên dán XÁC MINH lại đúng
  /// đoạn chữ đó còn nguyên trước khi tin theo định dạng — lệch một ký tự
  /// cũng bỏ qua toàn bộ, thà mất định dạng còn hơn gán sai chỗ. `null` nếu
  /// đoạn không có định dạng thủ công nào (không đáng ghi rich clipboard).
  String? _macGoiDinhDangChoClipboard(String doan, int batDau, int ketThuc) {
    final ds = <Map<String, dynamic>>[];
    for (final d in _boDieuKhien.dinhDang) {
      if (d.rong) continue;
      final a = d.batDau < batDau ? batDau : d.batDau;
      final b = d.ketThuc > ketThuc ? ketThuc : d.ketThuc;
      if (a >= b) continue;
      ds.add(_VungDinhDangThuCong(
        batDau: a - batDau,
        ketThuc: b - batDau,
        dam: d.dam,
        nghieng: d.nghieng,
        gachChan: d.gachChan,
        gachNgang: d.gachNgang,
        treMu: d.treMu,
        treChan: d.treChan,
        mauChu: d.mauChu,
        mauNen: d.mauNen,
      ).toJson());
    }
    if (ds.isEmpty) return null;
    final goi = {'len': doan.length, 'ham': _bamFnv1a(doan), 'sp': ds};
    return base64Encode(utf8.encode(jsonEncode(goi)));
  }

  /// Ngược lại [_macGoiDinhDangChoClipboard] — decode, XÁC MINH [vanBanDaDan]
  /// khớp đúng độ dài/mã băm đã ghi lúc copy, rồi thêm các vùng định dạng
  /// (dịch theo [batDauChen], vị trí đoạn vừa dán trong văn bản hiện tại)
  /// vào `_boDieuKhien.dinhDang`. Hỏng khuôn/không khớp ở bất kỳ đâu thì bỏ
  /// qua ÊM RU — dán vẫn thành công, chỉ mất định dạng, KHÔNG BAO GIỜ gán
  /// định dạng sai chỗ.
  /// [vanBanDaDan] PHẢI là đoạn chữ ĐẦY ĐỦ như lúc copy (dùng xác minh độ
  /// dài/mã băm) — KỂ CẢ khi đoạn thật sự chèn vào văn bản đã bị cắt bớt
  /// [boQuaDau] ký tự ở đầu (xem [_themVungDinhDangTuDs]).
  void _apDungGoiDinhDangTuClipboard(String maHoa, String vanBanDaDan, int batDauChen,
      {int boQuaDau = 0}) {
    try {
      final goi = jsonDecode(utf8.decode(base64Decode(maHoa)));
      if (goi is! Map) return;
      if (goi['len'] != vanBanDaDan.length) return;
      if (goi['ham'] != _bamFnv1a(vanBanDaDan)) return;
      final sp = goi['sp'];
      if (sp is! List) return;
      _themVungDinhDangTuDs(sp, batDauChen, boQuaDau: boQuaDau);
    } catch (_) {
      // Bỏ qua toàn bộ — xem chú thích khai báo hàm.
    }
  }

  /// Thêm các vùng định dạng mã hoá kiểu `_VungDinhDangThuCong.toJson()`
  /// trong [ds] vào `_boDieuKhien.dinhDang`, dịch toạ độ theo [batDauChen] —
  /// dùng chung cho cả gói JSON riêng của Flowrite ([_apDungGoiDinhDangTuClipboard])
  /// lẫn kết quả rút từ HTML nguồn ngoài ([_dinhDangTuHtmlNgoai]).
  ///
  /// [boQuaDau]: số ký tự đã bị cắt khỏi ĐẦU đoạn chữ thật sự chèn vào (tính
  /// năng tự động thụt đầu dòng xoá bớt dấu cách đầu — xem
  /// `coTheXoaCachDau` ở `_phimAoPaste`/`_danTuBoNhoTam`), nhưng [ds] vẫn
  /// đánh toạ độ theo đoạn chữ GỐC ĐẦY ĐỦ (chưa cắt) — mỗi vùng phải lùi về
  /// đúng [boQuaDau] để khớp lại với đoạn đã cắt. Vùng rơi HẲN vào phần bị
  /// cắt (kết thúc không vượt qua điểm cắt) thì bỏ hẳn; vùng chỉ cắt một
  /// phần ở đầu thì giữ lại phần còn lại, bắt đầu từ 0.
  void _themVungDinhDangTuDs(List<dynamic> ds, int batDauChen, {int boQuaDau = 0}) {
    final vb = _boDieuKhien.text;
    for (final j in ds) {
      if (j is! Map) continue;
      final m = Map<String, dynamic>.from(j);
      final vt = m['vt'];
      final kt = m['kt'];
      if (vt is! int || kt is! int) continue;
      final ktMoi = kt - boQuaDau;
      if (ktMoi <= 0) continue;
      final vtMoi = vt - boQuaDau;
      m['vt'] = (vtMoi < 0 ? 0 : vtMoi) + batDauChen;
      m['kt'] = ktMoi + batDauChen;
      final v = _VungDinhDangThuCong.fromJson(m, vb.length);
      if (v != null) _boDieuKhien.dinhDang.add(v);
    }
  }

  /// Tách gói JSON riêng của Flowrite (nếu có) khỏi chuỗi `text/html` vừa
  /// đọc được từ clipboard — `null` nếu không có (clipboard trống, hoặc đến
  /// từ nguồn khác không phải Flowrite).
  String? _tachGoiDinhDangTuHtml(String? htmlClipboard) {
    if (htmlClipboard == null) return null;
    return _reGoiDinhDangClip.firstMatch(htmlClipboard)?.group(1);
  }

  /// Bốn thực thể HTML cơ bản nhất — đủ dùng cho chữ thường trong đoạn dán,
  /// không cần bộ giải mã thực thể đầy đủ.
  String _giaiMaThucTheHtml(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&'); // LUÔN giải mã & sau cùng — tránh giải mã
  // "&amp;lt;" thành "&lt;" rồi lại thành "<" oan (giải mã kép).

  /// Rút chữ thô + BA kiểu định dạng cơ bản nhất (đậm/nghiêng/gạch chân) từ
  /// một chuỗi `text/html` TỪ NGUỒN NGOÀI (Google Docs/Word/trang web...,
  /// KHÔNG mang đánh dấu riêng của Flowrite — xem [_tachGoiDinhDangTuHtml]
  /// cho trường hợp chính Flowrite). CHỦ Ý chỉ nhận 3 thẻ `<b>/<strong>`,
  /// `<i>/<em>`, `<u>` — bỏ qua mọi thẻ/kiểu khác (bảng, tiêu đề, cỡ chữ,
  /// màu...), đúng tinh thần "cố gắng tốt nhất", không cầu toàn.
  ///
  /// Trả về `null` nếu có bất kỳ trục trặc nào, HOẶC nếu chữ rút ra từ HTML
  /// không khớp Y HỆT [vanBanThoDaDoc] (đọc từ `text/plain` riêng của cùng
  /// clipboard) — khác biệt cách trình duyệt dựng `text/plain` so với cách
  /// hàm này rút chữ từ thẻ HTML (ví dụ xuống dòng quanh khối `<p>/<div>`)
  /// là chuyện bình thường, và khi đó THÀ bỏ qua định dạng còn hơn gán sai
  /// chỗ hoặc dán nhầm chữ.
  /// (SỬA LỖI) Trước đây CHỈ nhận 3 thẻ ngữ nghĩa `<b>/<i>/<u>` — Google
  /// Docs (và nhiều nguồn khác) KHÔNG dùng các thẻ đó, mà bọc mọi định dạng
  /// trong `style="font-weight:700;font-style:italic;..."` của thẻ
  /// `<span>` — nên trước đây dán từ Google Docs vào luôn rơi về "không có
  /// định dạng nào" (chữ đã khớp, nhưng `ds` luôn rỗng). Giờ đọc THÊM các
  /// thuộc tính CSS: `font-weight`, `font-style`, `text-decoration(-line)`,
  /// `vertical-align`, `color`, `background(-color)` — đúng các thuộc tính
  /// mà CHÍNH Flowrite cũng xuất ra lúc Copy (xem `_dinhDangThuCongSangHtml`),
  /// nên hai chiều dán qua lại giữa Flowrite ↔ Google Docs/Word đều ra đúng
  /// định dạng. Dùng NGĂN XẾP để khôi phục đúng trạng thái lúc gặp thẻ đóng
  /// (thay cho 3 cờ phẳng cũ, chỉ đúng khi các thẻ không lồng nhau) — bắt
  /// buộc phải vậy vì HTML thật luôn lồng `<span>` trong `<span>` nhiều lớp.
  List<Map<String, dynamic>>? _dinhDangTuHtmlNgoai(String htmlGoc, String vanBanThoDaDoc) {
    try {
      var html = htmlGoc.replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '');
      html = html.replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '');
      final buf = StringBuffer();
      final runs = <(int, int, bool, bool, bool, bool, bool, bool, Color?, Color?)>[];

      var dam = false, nghieng = false, gachChan = false, gachNgang = false;
      var treMu = false, treChan = false;
      Color? mauChu, mauNen;
      final nganXep = <(bool, bool, bool, bool, bool, bool, Color?, Color?)>[];

      const theTuDong = {
        'br', 'img', 'hr', 'meta', 'link', 'input', 'col', 'area', 'base', 'embed', 'source', 'track', 'wbr',
      };

      for (final m in RegExp(r'<[^>]*>|[^<]+', dotAll: true).allMatches(html)) {
        final tok = m[0]!;
        if (tok.startsWith('<')) {
          final te = tok.toLowerCase();
          final tenThe = RegExp(r'^<\s*/?\s*([a-zA-Z0-9]+)').firstMatch(te)?.group(1) ?? '';
          if (tenThe == 'br') {
            final bd = buf.length;
            buf.write('\n');
            runs.add((bd, buf.length, dam, nghieng, gachChan, gachNgang, treMu, treChan, mauChu, mauNen));
            continue;
          }
          if (theTuDong.contains(tenThe)) continue;

          if (te.startsWith('</')) {
            if (nganXep.isNotEmpty) {
              final tt = nganXep.removeLast();
              dam = tt.$1;
              nghieng = tt.$2;
              gachChan = tt.$3;
              gachNgang = tt.$4;
              treMu = tt.$5;
              treChan = tt.$6;
              mauChu = tt.$7;
              mauNen = tt.$8;
            }
            continue;
          }

          // Thẻ MỞ — lưu trạng thái hiện tại để khôi phục đúng lúc gặp thẻ
          // đóng tương ứng, rồi áp thêm định dạng của riêng thẻ này.
          nganXep.add((dam, nghieng, gachChan, gachNgang, treMu, treChan, mauChu, mauNen));
          if (RegExp(r'^<\s*(b|strong)\b').hasMatch(te)) dam = true;
          if (RegExp(r'^<\s*(i|em)\b').hasMatch(te)) nghieng = true;
          if (RegExp(r'^<\s*u\b').hasMatch(te)) gachChan = true;
          if (RegExp(r'^<\s*(s|strike|del)\b').hasMatch(te)) gachNgang = true;
          if (RegExp(r'^<\s*sup\b').hasMatch(te)) treMu = true;
          if (RegExp(r'^<\s*sub\b').hasMatch(te)) treChan = true;

          final kieu =
              RegExp(r'''style\s*=\s*["']([^"']*)["']''', caseSensitive: false).firstMatch(tok)?.group(1);
          if (kieu != null) {
            final k = kieu.toLowerCase();
            final fw = RegExp(r'font-weight\s*:\s*([a-z0-9]+)').firstMatch(k)?.group(1);
            if (fw != null) {
              final so = int.tryParse(fw);
              if (fw == 'bold' || (so != null && so >= 600)) dam = true;
              if (fw == 'normal' || (so != null && so < 600)) dam = false;
            }
            if (RegExp(r'font-style\s*:\s*italic').hasMatch(k)) nghieng = true;
            if (RegExp(r'font-style\s*:\s*normal').hasMatch(k)) nghieng = false;
            final td = RegExp(r'text-decoration(?:-line)?\s*:\s*([a-z \-]+)').firstMatch(k)?.group(1) ?? '';
            if (td.contains('underline')) gachChan = true;
            if (td.contains('line-through')) gachNgang = true;
            if (td.contains('none')) {
              gachChan = false;
              gachNgang = false;
            }
            final va = RegExp(r'vertical-align\s*:\s*([a-z]+)').firstMatch(k)?.group(1);
            if (va == 'super') treMu = true;
            if (va == 'sub') treChan = true;
            final mcMoi = _mauTuCss(RegExp(r'(?<![\w-])color\s*:\s*([^;]+)').firstMatch(k)?.group(1));
            if (mcMoi != null) mauChu = mcMoi;
            final mnMoi = _mauTuCss(RegExp(r'background(?:-color)?\s*:\s*([^;]+)').firstMatch(k)?.group(1));
            if (mnMoi != null) mauNen = mnMoi;
          }
          continue;
        }
        final chu = _giaiMaThucTheHtml(tok);
        if (chu.isEmpty) continue;
        final bd = buf.length;
        buf.write(chu);
        runs.add((bd, buf.length, dam, nghieng, gachChan, gachNgang, treMu, treChan, mauChu, mauNen));
      }
      if (buf.toString() != vanBanThoDaDoc) return null;

      final ds = <Map<String, dynamic>>[];
      var i = 0;
      while (i < runs.length) {
        final r0 = runs[i];
        var kt = r0.$2;
        var j = i + 1;
        while (j < runs.length &&
            runs[j].$3 == r0.$3 &&
            runs[j].$4 == r0.$4 &&
            runs[j].$5 == r0.$5 &&
            runs[j].$6 == r0.$6 &&
            runs[j].$7 == r0.$7 &&
            runs[j].$8 == r0.$8 &&
            runs[j].$9 == r0.$9 &&
            runs[j].$10 == r0.$10 &&
            runs[j].$1 == kt) {
          kt = runs[j].$2;
          j++;
        }
        if (r0.$3 || r0.$4 || r0.$5 || r0.$6 || r0.$7 || r0.$8 || r0.$9 != null || r0.$10 != null) {
          ds.add(_VungDinhDangThuCong(
            batDau: r0.$1,
            ketThuc: kt,
            dam: r0.$3,
            nghieng: r0.$4,
            gachChan: r0.$5,
            gachNgang: r0.$6,
            treMu: r0.$7,
            treChan: r0.$8,
            mauChu: r0.$9,
            mauNen: r0.$10,
          ).toJson());
        }
        i = j;
      }
      return ds.isEmpty ? null : ds;
    } catch (_) {
      return null;
    }
  }

  /// `rgb(...)`/`rgba(...)`/`#rrggbb`/`#rgb` → `Color` — `null` nếu không
  /// nhận diện được hoặc là `transparent`/`inherit`/`initial` (không đáng
  /// gán màu cụ thể nào). Dùng để đọc `color`/`background-color` từ CSS
  /// của HTML dán vào từ nguồn ngoài (xem [_dinhDangTuHtmlNgoai]).
  Color? _mauTuCss(String? gt) {
    if (gt == null) return null;
    final s = gt.trim();
    if (s.isEmpty || s == 'transparent' || s == 'inherit' || s == 'initial') return null;
    final rgba = RegExp(r'rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)')
        .firstMatch(s);
    if (rgba != null) {
      final r = (double.tryParse(rgba.group(1)!) ?? 0).round().clamp(0, 255);
      final g = (double.tryParse(rgba.group(2)!) ?? 0).round().clamp(0, 255);
      final b = (double.tryParse(rgba.group(3)!) ?? 0).round().clamp(0, 255);
      final a = rgba.group(4) != null ? (double.tryParse(rgba.group(4)!) ?? 1.0) : 1.0;
      return Color.fromARGB((a * 255).round().clamp(0, 255), r, g, b);
    }
    final hex = RegExp(r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$').firstMatch(s);
    if (hex != null) {
      var h = hex.group(1)!;
      if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
      return Color(0xFF000000 | int.parse(h, radix: 16));
    }
    return null;
  }

  /// Ba ký tự HTML tối thiểu cần thoát trong một đoạn chữ thường trước khi
  /// chèn vào giữa các thẻ — `"`/`'` không cần vì chữ không nằm trong thuộc
  /// tính nào ở đây.
  String _thoatHtml(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  /// `rgba(...)` từ một `Color` — dùng `toARGB32()` (đã dùng sẵn ở
  /// `_VungDinhDangThuCong.toJson`), không phụ thuộc getter `.value` cũ.
  String _mauCssTuColor(Color c) {
    final v = c.toARGB32();
    final a = (v >> 24) & 0xFF, r = (v >> 16) & 0xFF, g = (v >> 8) & 0xFF, b = v & 0xFF;
    return 'rgba($r,$g,$b,${(a / 255).toStringAsFixed(3)})';
  }

  /// Dựng phần HTML thật (thẻ/`style` chuẩn — thứ Google Docs/Excel/Word...
  /// đọc khi dán) cho đoạn [batDau, ketThuc) — ĐÚNG thuật toán "gộp các vùng
  /// định dạng chồng lấn thành từng đoạn liền không chồng lấn" đã dùng để vẽ
  /// trong `buildTextSpan` (giản lược, bỏ phần tô vùng tìm kiếm/vùng chọn —
  /// không liên quan tới việc xuất clipboard), để HTML xuất ra ĐÚNG Y HỆT
  /// những gì người dùng đang nhìn thấy trên trang.
  String _dinhDangThuCongSangHtml(String doan, int batDauGoc, int ketThucGoc) {
    if (doan.isEmpty) return '';
    final trongVung = <_VungDinhDangThuCong>[];
    final diem = <int>{0, doan.length};
    for (final d in _boDieuKhien.dinhDang) {
      if (d.rong) continue;
      final a = (d.batDau < batDauGoc ? batDauGoc : d.batDau) - batDauGoc;
      final b = (d.ketThuc > ketThucGoc ? ketThucGoc : d.ketThuc) - batDauGoc;
      if (a >= b) continue;
      diem.add(a);
      diem.add(b);
      trongVung.add(_VungDinhDangThuCong(
        batDau: a,
        ketThuc: b,
        dam: d.dam,
        nghieng: d.nghieng,
        gachChan: d.gachChan,
        gachNgang: d.gachNgang,
        treMu: d.treMu,
        treChan: d.treChan,
        mauChu: d.mauChu,
        mauNen: d.mauNen,
      ));
    }
    final moc = diem.toList()..sort();
    final buf = StringBuffer();
    for (var i = 0; i < moc.length - 1; i++) {
      final a = moc[i], b = moc[i + 1];
      if (a >= b) continue;
      var dam = false, nghieng = false, gachChan = false, gachNgang = false, treMu = false, treChan = false;
      Color? mauChu, mauNen;
      for (final d in trongVung) {
        if (d.batDau <= a && d.ketThuc >= b) {
          dam = dam || d.dam;
          nghieng = nghieng || d.nghieng;
          gachChan = gachChan || d.gachChan;
          gachNgang = gachNgang || d.gachNgang;
          treMu = treMu || d.treMu;
          treChan = treChan || d.treChan;
          mauChu = d.mauChu ?? mauChu;
          mauNen = d.mauNen ?? mauNen;
        }
      }
      final chuThoat = _thoatHtml(doan.substring(a, b)).replaceAll('\n', '<br>');
      final css = StringBuffer();
      if (dam) css.write('font-weight:bold;');
      if (nghieng) css.write('font-style:italic;');
      if (gachChan && gachNgang) {
        css.write('text-decoration:underline line-through;');
      } else if (gachChan) {
        css.write('text-decoration:underline;');
      } else if (gachNgang) {
        css.write('text-decoration:line-through;');
      }
      if (treChan) css.write('font-size:70%;vertical-align:sub;');
      if (treMu) css.write('vertical-align:super;');
      if (mauChu != null) css.write('color:${_mauCssTuColor(mauChu)};');
      if (mauNen != null) css.write('background-color:${_mauCssTuColor(mauNen)};');
      buf.write(css.isEmpty ? chuThoat : '<span style="$css">$chuThoat</span>');
    }
    return buf.toString();
  }

  /// Dựng cả chuỗi `text/html` hoàn chỉnh (gói riêng của Flowrite + HTML
  /// thật) cho đoạn [batDau, ketThuc) — `null` nếu đoạn không có định dạng
  /// thủ công nào (không đáng ghi rich clipboard, nơi gọi tự rơi về
  /// `Clipboard.setData` chữ thô như trước giờ).
  String? _dungHtmlChoClipboard(String doan, int batDau, int ketThuc) {
    final maHoaGoi = _macGoiDinhDangChoClipboard(doan, batDau, ketThuc);
    if (maHoaGoi == null) return null;
    final than = _dinhDangThuCongSangHtml(doan, batDau, ketThuc);
    return '<!--$_danhDauGoiDinhDangClip:$maHoaGoi--><span>$than</span>';
  }

  /// "Copy" — chỉ làm gì đó khi ĐANG CÓ vùng chọn (không collapsed); vùng
  /// chọn rỗng thì không có gì để chép, im lặng bỏ qua.
  Future<void> _phimAoCopy() async {
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    if (!chon.isValid || chon.isCollapsed) return;
    final doan = _boDieuKhien.text.substring(chon.start, chon.end);
    if (doan.isEmpty) return;
    // (Web) đoạn có định dạng thủ công thì thử ghi kèm `text/html` giữ
    // nguyên định dạng đó — thất bại/không có gì đáng ghi thì rơi về
    // `Clipboard.setData` chữ thô hệt trước giờ, KHÔNG MẤT GÌ so với trước.
    final htmlClip = _dungHtmlChoClipboard(doan, chon.start, chon.end);
    final daGhiGiauDinhDang =
        htmlClip != null && await ghiClipboardCoDinhDang(doan, htmlClip);
    if (!daGhiGiauDinhDang) {
      await Clipboard.setData(ClipboardData(text: doan));
    }
    // (YÊU CẦU MỚI — nhánh thử nghiệm) "Bộ nhớ tạm để dán văn bản" — thêm
    // vào lịch sử 10 dòng, KHÔNG thay thế gì ở trên (bộ nhớ đệm hệ thống
    // vẫn luôn được ghi như cũ).
    // (YÊU CẦU MỚI) Lưu luôn gói định dạng (nếu có) kèm theo dòng lịch sử —
    // tái sử dụng chính gói vừa đóng cho `text/html` ở trên (tách lại từ
    // [htmlClip] qua `_tachGoiDinhDangTuHtml`, không tính toán lại từ đầu).
    if (widget.caiDat.boNhoTamDanVanBanBat) {
      BoNhoTamDanVanBan.themMoi(doan, dinhDangGoi: _tachGoiDinhDangTuHtml(htmlClip));
    }
    if (mounted) hienThongBaoGiua(context, Ch.daCopyVaoBoNhoDem(ngonNguHienTai.value), ganTren: true);
  }

  /// "Cut" — y hệt Copy rồi xoá vùng vừa chép, ĐI QUA đúng con đường gõ tay
  /// thật (xem giải thích ở `_chenKyTuTuPhimAo`) để mọi cơ chế đi kèm (lùi
  /// lại, dời vùng định dạng/đường kẻ chia...) tự áp dụng đúng.
  Future<void> _phimAoCut() async {
    final vb = _boDieuKhien.text;
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    if (!chon.isValid || chon.isCollapsed) return;
    final batDau = chon.start, ketThuc = chon.end;
    final doan = vb.substring(batDau, ketThuc);
    if (doan.isEmpty) return;
    final theChongLan = _theGhiAmChongLanMotPhan(batDau, ketThuc);
    if (theChongLan != null) {
      _khiCanXoaTheTuBanPhim(theChongLan.$1, theChongLan.$2);
      return;
    }
    // (Web) đoạn có định dạng thủ công thì thử ghi kèm `text/html` — xem
    // giải thích ở `_phimAoCopy`, cùng cơ chế.
    final htmlClip = _dungHtmlChoClipboard(doan, batDau, ketThuc);
    final daGhiGiauDinhDang =
        htmlClip != null && await ghiClipboardCoDinhDang(doan, htmlClip);
    if (!daGhiGiauDinhDang) {
      await Clipboard.setData(ClipboardData(text: doan));
    }
    // (YÊU CẦU MỚI) Xem giải thích ở `_phimAoCopy`, cùng cơ chế.
    if (widget.caiDat.boNhoTamDanVanBanBat) {
      BoNhoTamDanVanBan.themMoi(doan, dinhDangGoi: _tachGoiDinhDangTuHtml(htmlClip));
    }
    // Cắt LUÔN phải là một mốc Lùi lại/Tiến tới RIÊNG của chính nó — không
    // được gộp chung vào đợt gõ tay đang dở (nếu vừa gõ gì đó trong 5 giây
    // trước). Kết thúc đợt gõ hiện tại TRƯỚC khi áp dụng thay đổi: lượt sửa
    // sắp tới (đi qua `_khiNguoiDungSua` → `_apDungChinhSuaNguoiDung` như
    // mọi lượt sửa khác, xem giải thích ở trên) sẽ tự thấy đây là "lần gõ
    // đầu tiên của một đợt mới" và tự lưu mốc — không cần gọi `_luuDiemMoc`
    // tay ở đây, tránh trùng cơ chế.
    _henRanhGioiGoTay?.cancel();
    _dangTrongDotGoTay = false;
    final moi = vb.replaceRange(batDau, ketThuc, '');
    _boDieuKhien.value =
        TextEditingValue(text: moi, selection: TextSelection.collapsed(offset: batDau));
    _cuonToiConTroNeuCan();
    if (mounted) hienThongBaoGiua(context, Ch.daCatVaLuuVaoBoNhoDem(ngonNguHienTai.value), ganTren: true);
  }

  /// (YÊU CẦU MỚI) Nút 📖 "Thêm vào Từ điển nhập liệu nhanh" ở hàng Copy/Cắt
  /// khi đang có vùng chọn thật — mở ĐÚNG modal "Thêm nhanh vào từ điển
  /// nhập liệu nhanh" (`_HopThoaiThemNhanhTuDien`), y hệt luồng từ nút 📖 ở
  /// bảng 10 dòng lịch sử Bộ nhớ tạm, chỉ khác nguồn nội dung là vùng chọn
  /// hiện tại thay vì một dòng lịch sử.
  void _themVungChonVaoTuDienNhapLieuNhanh() {
    final chon = _boDieuKhien.selection;
    if (!chon.isValid || chon.isCollapsed) return;
    final doan = _boDieuKhien.text.substring(chon.start, chon.end);
    if (doan.isEmpty) return;
    if (doan.length > CaiDat.gioiHanTuDienNhapLieuNhanh) {
      hienThongBaoGiua(
        context,
        Ch.khongTheThemVaoTuDienNhapLieuNhanhVuotQua1000(ngonNguHienTai.value),
      );
      return;
    }
    final goi = _macGoiDinhDangChoClipboard(doan, chon.start, chon.end);
    showDialog<void>(
      context: context,
      builder: (_) => _HopThoaiThemNhanhTuDien(
        doanNguon: doan,
        goiDinhDangNguon: goi,
        caiDat: widget.caiDat,
        nguon: _NguonTuDienNhanh.hienHanh(widget.caiDat),
      ),
    );
  }

  /// (YÊU CẦU MỚI) Nút 📒 "Thêm vào Từ điển sửa lỗi chính tả" ở hàng Copy/Cắt
  /// khi đang có vùng chọn thật — mở modal "Cài đặt từ điển sửa lỗi chính
  /// tả" với [noiDungCanDua] đã có sẵn, modal đó tự tìm/tạo cặp rỗng, điền
  /// vào dòng 1 và nhấp nháy nhắc chú ý (xem `moModalTuDienChinhTa`).
  void _themVungChonVaoTuDienChinhTa() {
    final chon = _boDieuKhien.selection;
    if (!chon.isValid || chon.isCollapsed) return;
    final doan = _boDieuKhien.text.substring(chon.start, chon.end);
    if (doan.isEmpty) return;
    if (doan.length > gioiHanTuDienChinhTa) {
      hienThongBaoGiua(
        context,
        Ch.khongTheThemVaoTuDienChinhTaVuotQua(ngonNguHienTai.value, gioiHanTuDienChinhTa),
      );
      return;
    }
    moModalTuDienChinhTa(context, widget.caiDat, noiDungCanDua: doan);
  }

  /// Bấm liên tiếp quá nhanh vào "Paste" dễ dán trùng lặp (chạm hai lần
  /// trong lúc ngón tay chưa kịp rời màn hình cảm ứng) — sau mỗi lần bấm,
  /// tự "liệt" nút 1,5 giây (chỉ để mắt thấy, xem `_NutCongCuChu.bLiet`) rồi
  /// mới bấm lại được. Logic dán bên trong vẫn y hệt `_phimAoPaste`, không
  /// đổi gì — chỉ bọc thêm lớp khoá tạm này ở ngoài.
  bool _phimPasteDangLiet = false;
  Timer? _henHetLietPastePhimAo;

  Future<void> _phimAoPasteCoLiet() async {
    if (_phimPasteDangLiet) return;
    await _phimAoPaste();
    if (!mounted) return;
    setState(() => _phimPasteDangLiet = true);
    _henHetLietPastePhimAo?.cancel();
    _henHetLietPastePhimAo = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _phimPasteDangLiet = false);
    });
  }

  /// "Paste" — rỗng bộ nhớ đệm hoặc không đọc được thì im lặng bỏ qua.
  ///
  /// Khi "Tự động thụt đầu dòng mỗi khi xuống hàng" đang bật: (1) xoá hết
  /// dấu cách đứng đầu đoạn SẮP dán (bao nhiêu cũng xoá, để đoạn dán luôn
  /// bắt đầu bằng ký tự khác dấu cách — tránh cộng dồn với dấu cách tự thụt
  /// của app), và (2) tạm tắt hẳn tính năng tự thụt trong lúc dán (qua
  /// [_tamNgungTuDongThutDauDong], xem `_thutDauDongNeuCan`), mở lại ngay
  /// sau khi dán xong. Việc (2) hiện không có tác dụng quan sát được qua
  /// đường "Dán" này (hàm tự thụt chỉ chạy cho đúng MỘT ký tự chèn đơn, một
  /// đoạn dán nhiều ký tự không bao giờ khớp điều kiện đó) — giữ lại cho an
  /// toàn/đúng y văn, đề phòng dán đúng 1 ký tự hoặc hành vi thay đổi sau
  /// này. Đường dán CHUỘT PHẢI (menu chọn văn bản gốc của hệ thống, không đi
  /// qua hàm này) có `_XoaCachDauKhiDanLucThutDauDong` (một
  /// `TextInputFormatter` gắn ở `TextField`) lo riêng việc (1).
  Future<void> _phimAoPaste() async {
    final data = await Clipboard.getData('text/plain');
    var chen = data?.text;
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    if (chen == null || chen.isEmpty) return;
    if (!chon.isValid) return;
    final vb = _boDieuKhien.text;
    final batDau = chon.start, ketThuc = chon.end;
    final theChongLan = _theGhiAmChongLanMotPhan(batDau, ketThuc);
    if (theChongLan != null) {
      _khiCanXoaTheTuBanPhim(theChongLan.$1, theChongLan.$2);
      return;
    }
    // (Web) thử lấy thêm gói định dạng đi kèm trong clipboard — KHÔNG ảnh
    // hưởng gì tới việc dán chữ ở trên nếu thất bại/không có (native, hay
    // clipboard không có `text/html`): [chen] đã đọc xong từ đường
    // `Clipboard.getData('text/plain')` riêng, không phụ thuộc biến này.
    final htmlClipboard = await docHtmlTuClipboard();
    final maHoaGoi = _tachGoiDinhDangTuHtml(htmlClipboard);

    final dangBatTuDongThut = widget.caiDat.tuDongThutDauDong;
    // CHỈ xoá dấu cách đứng đầu đoạn dán khi ký tự NGAY TRƯỚC con trỏ (nơi
    // sắp dán vào) ĐÃ LÀ dấu cách — ký tự khác hoặc không có ký tự gì ở đó
    // thì giữ nguyên đoạn dán, không đụng gì (xem thêm ở
    // `_XoaCachDauKhiDanLucThutDauDong`, cùng quy tắc này).
    final coTheXoaCachDau = dangBatTuDongThut && batDau > 0 && vb[batDau - 1] == ' ';
    final chenGoc = chen;
    if (coTheXoaCachDau) {
      chen = chen.replaceFirst(RegExp(r'^ +'), '');
      if (chen.isEmpty) return;
    }
    // Số ký tự (dấu cách) đã bị cắt khỏi ĐẦU đoạn dán — [chenGoc] vẫn giữ
    // NGUYÊN để xác minh/rút định dạng (gói định dạng và `text/html` của
    // clipboard đều đánh toạ độ theo đoạn ĐẦY ĐỦ chưa cắt); vùng định dạng
    // rút ra được sẽ tự lùi lại đúng số này ở `_themVungDinhDangTuDs` —
    // KHÔNG bỏ qua hẳn định dạng như trước (mất định dạng chỉ vì có dấu
    // cách đầu dòng là lỗi, không phải cố ý).
    final soCachBiXoa = chenGoc.length - chen.length;

    // Dán LUÔN phải là một mốc Lùi lại/Tiến tới RIÊNG — xem giải thích ở
    // `_phimAoCut`, cùng cơ chế.
    _henRanhGioiGoTay?.cancel();
    _dangTrongDotGoTay = false;
    if (dangBatTuDongThut) _tamNgungTuDongThutDauDong = true;
    final moi = vb.replaceRange(batDau, ketThuc, chen);
    _boDieuKhien.value = TextEditingValue(
      text: moi,
      selection: TextSelection.collapsed(offset: batDau + chen.length),
    );
    if (dangBatTuDongThut) _tamNgungTuDongThutDauDong = false;
    // Đợi `.value =` ở trên chạy XONG toàn bộ dây chuyền sửa văn bản thường
    // (qua `_khiNguoiDungSua` → `_apDungChinhSuaNguoiDung`, đã tự dời mọi
    // vùng định dạng CŨ theo đúng phép chèn) rồi mới THÊM các vùng định dạng
    // MỚI của đoạn vừa dán — không đụng gì vào dây chuyền dời/co giãn đã có,
    // chỉ cộng thêm sau cùng.
    if (maHoaGoi != null) {
      setState(
          () => _apDungGoiDinhDangTuClipboard(maHoaGoi, chenGoc, batDau, boQuaDau: soCachBiXoa));
    } else if (htmlClipboard != null) {
      // Không mang đánh dấu riêng của Flowrite — thử "cố gắng tốt nhất" rút
      // định dạng từ HTML nguồn ngoài (Google Docs/Word/trang web...), kể
      // cả định dạng khai qua CSS trong `style="..."` (chứ không chỉ thẻ
      // ngữ nghĩa `<b>/<i>/<u>`) — xem giải thích đầy đủ ở
      // `_dinhDangTuHtmlNgoai`. Tự trả về `null` nếu chữ rút ra không khớp
      // y hệt [chenGoc] — an toàn, không dán sai chữ.
      final ds = _dinhDangTuHtmlNgoai(htmlClipboard, chenGoc);
      if (ds != null) setState(() => _themVungDinhDangTuDs(ds, batDau, boQuaDau: soCachBiXoa));
    }
    _cuonToiConTroNeuCan();
    if (mounted) hienThongBaoGiua(context, Ch.daDanVanBanVaoTuBoNhoDem(ngonNguHienTai.value), ganTren: true);
  }

  /// "All" — 4 mức, đếm số lần bấm liên tiếp trong 2 giây (riêng nút này,
  /// các nút khác vẫn 1 giây):
  /// - 1 lần: chọn TỪ chứa con trỏ (xem `_tinhVungTu`).
  /// - 2 lần: chọn ĐOẠN VĂN chứa con trỏ (ranh giới là dấu xuống dòng gần
  ///   nhất trước/sau con trỏ).
  /// - 3 lần: chọn CỤM ĐOẠN VĂN chứa con trỏ (xem `_tinhVungCumDoanVan`).
  /// - 4 lần: chọn toàn bộ văn bản.
  /// Nếu một trong các mức 2/3 mà vùng chọn đã trùng luôn toàn bộ văn bản
  /// thì coi như đã xong, không cần bấm thêm lần nào nữa — và thông báo
  /// "Đã chọn tất cả" (được bấm SAU nên OverlayEntry của nó luôn chèn SAU,
  /// tự động đè lên trên mọi thông báo gợi ý còn đang hiện từ lần bấm
  /// trước, không cần logic ưu tiên riêng). Chỉ đổi vùng chọn, không đụng
  /// nội dung.
  /// Nút "All" tự tô màu xanh dương NỔI BẬT (xem `_NutCongCuChu.noiBat`)
  /// trong 1 giây NGAY LÚC vừa chọn xong TOÀN BỘ văn bản — đây là "chế độ
  /// nhanh": bấm vào lúc màu xanh còn hiện, bất kể 1 lần hay bấm liên tục
  /// nhiều lần, LUÔN LUÔN trả về "đã chọn tất cả" ngay, không đếm lại từ
  /// đầu (khác hẳn với logic đếm 1-4 lần thường ngày).
  ///
  /// Lý do cần "chế độ nhanh" này: vùng chọn "chọn tất cả" rất dễ mất chỉ
  /// bằng một cú chạm bất kỳ vào vùng văn bản (hành vi CHUẨN của MỌI ô
  /// nhập văn bản, không phải lỗi riêng của app này) — "chế độ nhanh" là
  /// cách bấm lại một lần chắc chắn quay về "chọn tất cả" ngay, không cần
  /// làm lại đúng 2-4 lần đếm từ đầu. (Từng thử một hướng khác — LIỆT/
  /// khoá cứng nút trong 1 giây — nhưng đó là chẩn đoán SAI: mất vùng chọn
  /// không phải do bấm lại đúng nút này, mà do bấm ra CHỖ KHÁC bất kỳ; đã
  /// bỏ hướng đó.)
  bool _phimAllVuaChonTatCa = false;
  Timer? _henHetCheDoNhanhChonTatCa;

  void _batCheDoNhanhChonTatCa() {
    if (!mounted) return;
    setState(() => _phimAllVuaChonTatCa = true);
    _henHetCheDoNhanhChonTatCa?.cancel();
    _henHetCheDoNhanhChonTatCa = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _phimAllVuaChonTatCa = false);
    });
  }

  void _phimAoChonTatCa() {
    final vb = _boDieuKhien.text;
    _giuFocusOChuSauKhiBam();

    if (_phimAllVuaChonTatCa) {
      _boDieuKhien.selection = TextSelection(baseOffset: 0, extentOffset: vb.length);
      _cuonToiConTroNeuCan();
      if (mounted) hienThongBaoGiua(context, Ch.daChonTatCa(ngonNguHienTai.value), ganTren: true);
      _batCheDoNhanhChonTatCa(); // gia hạn thêm 1 giây nữa, tính từ lần bấm này.
      return;
    }

    final chon = _boDieuKhien.selection;
    final bay = DateTime.now();
    final conTrongNguong =
        _lanBamAllTruoc != null && bay.difference(_lanBamAllTruoc!) <= _nguongBamAll;
    _demBamAll = conTrongNguong ? _demBamAll + 1 : 1;
    _lanBamAllTruoc = bay;

    if (_demBamAll >= 4) {
      _demBamAll = 0;
      _lanBamAllTruoc = null;
      _boDieuKhien.selection = TextSelection(baseOffset: 0, extentOffset: vb.length);
      _cuonToiConTroNeuCan();
      if (mounted) hienThongBaoGiua(context, Ch.daChonTatCa(ngonNguHienTai.value), ganTren: true);
      _batCheDoNhanhChonTatCa();
      return;
    }

    if (!chon.isValid) return;
    final vt = chon.extentOffset;

    final vung = switch (_demBamAll) {
      1 => _tinhVungTu(vb, vt) ?? _tinhVungDoanVan(vb, vt),
      2 => _tinhVungDoanVan(vb, vt),
      _ => _tinhVungCumDoanVan(vb, vt), // 3
    };
    _boDieuKhien.selection = TextSelection(baseOffset: vung.$1, extentOffset: vung.$2);
    _cuonToiConTroNeuCan();

    if (_demBamAll >= 2 && vung.$1 == 0 && vung.$2 == vb.length) {
      _demBamAll = 0;
      _lanBamAllTruoc = null;
      if (mounted) hienThongBaoGiua(context, Ch.daChonTatCa(ngonNguHienTai.value), ganTren: true);
      _batCheDoNhanhChonTatCa();
    } else if (mounted) {
      hienThongBaoGiua(context, Ch.bamAllDeChonVungRongHon(ngonNguHienTai.value), ganTren: true);
    }
  }

  /// Mục "Chọn tất cả" trong menu "+ Thêm lựa chọn" — KHÁC nút "All" gần nút
  /// ghi âm: nút All phải bấm liên tục (chọn từ → đoạn văn → cụm đoạn văn →
  /// toàn bộ) vì nó còn dùng để chọn các vùng hẹp hơn. Mục trong menu này chỉ
  /// có đúng một việc là chọn toàn bộ văn bản, nên chọn thẳng một lần, không
  /// đi qua bộ đếm/trạng thái của `_phimAoChonTatCa`.
  void _chonTatCaTrucTiepTuMenu() {
    final vb = _boDieuKhien.text;
    _giuFocusOChuSauKhiBam();
    _boDieuKhien.selection = TextSelection(baseOffset: 0, extentOffset: vb.length);
    _cuonToiConTroNeuCan();
    _demBamAll = 0;
    _lanBamAllTruoc = null;
    if (mounted) hienThongBaoGiua(context, Ch.daChonTatCa(ngonNguHienTai.value), ganTren: true);
    _batCheDoNhanhChonTatCa();
  }

  /// Vùng ĐOẠN VĂN chứa vị trí [vt] — ranh giới là dấu xuống dòng gần nhất
  /// trước/sau con trỏ (hoặc đầu/cuối văn bản nếu không có).
  (int, int) _tinhVungDoanVan(String vb, int vt) {
    final batDauDoan = vt <= 0 ? 0 : vb.lastIndexOf('\n', vt - 1) + 1;
    final ketThucDongTho = vb.indexOf('\n', vt);
    final ketThucDoan = ketThucDongTho == -1 ? vb.length : ketThucDongTho;
    return (batDauDoan, ketThucDoan);
  }

  /// Vùng TỪ chứa vị trí [vt] trong văn bản [vb]. "Từ" chỉ tách nhau bởi
  /// dấu CÁCH (không tách qua dấu xuống dòng — từ không bao giờ trải dài
  /// qua 2 dòng), nên chỉ xét trong DÒNG chứa con trỏ.
  ///
  /// - Con trỏ ngay trước ký tự đầu, ngay sau ký tự cuối, hoặc giữa một từ:
  ///   chọn từ đó.
  /// - Con trỏ ở các dấu cách trước từ đầu tiên của dòng: chọn từ đầu tiên.
  /// - Con trỏ ở các dấu cách sau từ cuối cùng của dòng: chọn từ cuối cùng.
  /// - Con trỏ ở giữa các dấu cách nằm giữa 2 từ: chọn cả 2 từ đó và các
  ///   dấu cách ở giữa.
  ///
  /// Trả về null nếu dòng đó không có từ nào (rỗng hoặc toàn dấu cách).
  (int, int)? _tinhVungTu(String vb, int vt) {
    final dauDong = vt <= 0 ? 0 : vb.lastIndexOf('\n', vt - 1) + 1;
    final ketThucDongTho = vb.indexOf('\n', vt);
    final ketThucDong = ketThucDongTho == -1 ? vb.length : ketThucDongTho;
    final dong = vb.substring(dauDong, ketThucDong);
    final vtTrongDong = vt - dauDong;

    final cacTu = RegExp(r'[^ ]+').allMatches(dong).toList();
    if (cacTu.isEmpty) return null;

    for (final tu in cacTu) {
      if (vtTrongDong >= tu.start && vtTrongDong <= tu.end) {
        return (dauDong + tu.start, dauDong + tu.end);
      }
    }

    RegExpMatch? truoc;
    RegExpMatch? sau;
    for (final tu in cacTu) {
      if (tu.end < vtTrongDong) truoc = tu;
      if (tu.start > vtTrongDong) {
        sau = tu;
        break;
      }
    }
    if (truoc != null && sau != null) return (dauDong + truoc.start, dauDong + sau.end);
    if (sau != null) return (dauDong + sau.start, dauDong + sau.end);
    if (truoc != null) return (dauDong + truoc.start, dauDong + truoc.end);
    return null;
  }

  /// Tính vùng CỤM ĐOẠN VĂN chứa vị trí [vt] trong văn bản [vb]. "Cụm đoạn
  /// văn" là một hoặc nhiều đoạn văn liên tiếp, ngăn cách nhau với cụm khác
  /// bởi TỪ 2 DÒNG TRỐNG LIÊN TIẾP TRỞ LÊN — "dòng trống" dùng ĐÚNG định
  /// nghĩa như đường kẻ chia đoạn văn (`_quetVaXayDungDuongKeChia`): không
  /// có ký tự gì, hoặc chỉ toàn dấu cách. Luôn có ít nhất 1 cụm nếu văn bản
  /// có ít nhất 1 ký tự.
  ///
  /// Nếu con trỏ đang nằm TRONG một dải "phân cách" (≥2 dòng trống liên
  /// tiếp) giữa hai cụm, chọn cả dải trống đó CỘNG cả hai cụm liền kề (một
  /// trong hai phía có thể không tồn tại nếu dải đó nằm ở đầu/cuối văn
  /// bản — khi đó chỉ cộng cụm còn lại). Nếu con trỏ nằm trong một cụm (kể
  /// cả dòng trống lẻ, đơn — không đủ 2 dòng trống liên tiếp nên không tách
  /// cụm), chọn nguyên cụm đó.
  (int, int) _tinhVungCumDoanVan(String vb, int vt) {
    final cacDong = vb.split('\n');
    final soDong = cacDong.length;
    final laDongTrong = List<bool>.generate(soDong, (i) => cacDong[i].trim().isEmpty);
    final dauDong = List<int>.filled(soDong, 0);
    var acc = 0;
    for (var i = 0; i < soDong; i++) {
      dauDong[i] = acc;
      acc += cacDong[i].length + 1;
    }
    int cuoiDong(int i) => dauDong[i] + cacDong[i].length;

    // Các dải "phân cách" — dòng trống liên tiếp, dài từ 2 dòng trở lên.
    final dsPhanCach = <List<int>>[];
    var i = 0;
    while (i < soDong) {
      if (laDongTrong[i]) {
        var j = i;
        while (j < soDong && laDongTrong[j]) {
          j++;
        }
        if (j - i >= 2) dsPhanCach.add([i, j - 1]);
        i = j;
      } else {
        i++;
      }
    }

    // Các cụm đoạn văn — phần bù của các dải phân cách.
    final dsCum = <List<int>>[];
    var dau = 0;
    for (final pc in dsPhanCach) {
      if (pc[0] > dau) dsCum.add([dau, pc[0] - 1]);
      dau = pc[1] + 1;
    }
    if (dau < soDong) dsCum.add([dau, soDong - 1]);

    // Dòng chứa vị trí con trỏ.
    var dongCT = soDong - 1;
    for (var k = 0; k < soDong; k++) {
      if (vt <= cuoiDong(k)) {
        dongCT = k;
        break;
      }
    }

    List<int>? phanCachChuaCT;
    for (final pc in dsPhanCach) {
      if (dongCT >= pc[0] && dongCT <= pc[1]) {
        phanCachChuaCT = pc;
        break;
      }
    }

    List<int> phamViDong;
    if (phanCachChuaCT != null) {
      final cumTruoc = dsCum.where((g) => g[1] == phanCachChuaCT![0] - 1).firstOrNull;
      final cumSau = dsCum.where((g) => g[0] == phanCachChuaCT![1] + 1).firstOrNull;
      if (cumTruoc != null && cumSau != null) {
        phamViDong = [cumTruoc[0], cumSau[1]];
      } else if (cumTruoc != null) {
        phamViDong = [cumTruoc[0], phanCachChuaCT[1]];
      } else if (cumSau != null) {
        phamViDong = [phanCachChuaCT[0], cumSau[1]];
      } else {
        phamViDong = phanCachChuaCT;
      }
    } else {
      final cum = dsCum.where((g) => dongCT >= g[0] && dongCT <= g[1]).firstOrNull;
      phamViDong = cum ?? [0, soDong - 1];
    }

    return (dauDong[phamViDong[0]], cuoiDong(phamViDong[1]));
  }

  /// "Home" — bấm 1 lần: đầu DÒNG hiện tại của con trỏ. Bấm 2 lần liên tiếp
  /// trong 1 giây: đầu văn bản.
  void _phimAoHome() {
    final vb = _boDieuKhien.text;
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    if (!chon.isValid) return;
    final vt = chon.extentOffset;
    final bay = DateTime.now();
    final laLanHai = _lanBamHomeTruoc != null &&
        bay.difference(_lanBamHomeTruoc!) <= _nguongBamHaiLan;
    _lanBamHomeTruoc = laLanHai ? null : bay;
    if (laLanHai) {
      _boDieuKhien.selection = const TextSelection.collapsed(offset: 0);
      _cuonToiDauVanBan();
      return;
    }
    final batDauDong = vt <= 0 ? 0 : vb.lastIndexOf('\n', vt - 1) + 1;
    _boDieuKhien.selection = TextSelection.collapsed(offset: batDauDong);
    _cuonToiConTroNeuCan();
    if (mounted) {
      hienThongBaoGiua(context, Ch.bamHomeDeLenTrenCungVanBan(ngonNguHienTai.value));
    }
  }

  /// "End" — bấm 1 lần: cuối DÒNG hiện tại của con trỏ. Bấm 2 lần liên tiếp
  /// trong 1 giây: cuối văn bản.
  void _phimAoEnd() {
    final vb = _boDieuKhien.text;
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    if (!chon.isValid) return;
    final vt = chon.extentOffset;
    final bay = DateTime.now();
    final laLanHai = _lanBamEndTruoc != null &&
        bay.difference(_lanBamEndTruoc!) <= _nguongBamHaiLan;
    _lanBamEndTruoc = laLanHai ? null : bay;
    if (laLanHai) {
      _boDieuKhien.selection = TextSelection.collapsed(offset: vb.length);
      _cuonXuongDuoi();
      return;
    }
    final ketThucDongTho = vb.indexOf('\n', vt);
    final vtMoi = ketThucDongTho == -1 ? vb.length : ketThucDongTho;
    _boDieuKhien.selection = TextSelection.collapsed(offset: vtMoi);
    _cuonToiConTroNeuCan();
    if (mounted) {
      hienThongBaoGiua(context, Ch.bamEndDeXuongDuoiCungVanBan(ngonNguHienTai.value));
    }
  }

  /// Trái/Phải: [dx] = ±1 ký tự. Lên/Xuống: [dy] = ±1 DÒNG HIỂN THỊ (không
  /// phải dòng logic/đoạn văn) — một đoạn văn dài tự động xuống dòng nhiều
  /// lần khi bị 2 bên màn hình ép lại (đặc biệt rõ ở màn hình hẹp), Lên/
  /// Xuống phải đi từng dòng NHÌN THẤY một, giống mọi trình soạn thảo khác,
  /// không nhảy vọt qua nguyên một đoạn văn. Đo bằng PIXEL qua
  /// `RenderEditable` (chính xác con trỏ đang ở toạ độ nào), không đếm dấu
  /// `\n` — đây là cách DUY NHẤT biết được ranh giới dòng hiển thị, vì bản
  /// thân văn bản không hề có ký tự nào đánh dấu chỗ tự động xuống dòng.
  void _diChuyenConTro({int dx = 0, int dy = 0}) {
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    if (!chon.isValid) return;
    final vb = _boDieuKhien.text;
    var vt = chon.extentOffset;
    if (dx != 0) {
      vt = (vt + dx).clamp(0, vb.length);
    } else if (dy != 0) {
      vt = _viTriTheoDongHienThi(vt, dy) ?? vt;
    }
    _boDieuKhien.selection = TextSelection.collapsed(offset: vt);
    _cuonToiConTroNeuCan();
  }

  /// Vị trí mới sau khi di chuyển [dy] DÒNG HIỂN THỊ (±1) kể từ [vt], giữ
  /// nguyên toạ độ ngang (x) của con trỏ hiện tại — y hệt cách Lên/Xuống
  /// hoạt động trong mọi ô soạn thảo khác. `null` nếu không tìm được
  /// `RenderEditable` (chưa kịp dựng xong khung nhìn) — gọi lại vô hại.
  int? _viTriTheoDongHienThi(int vt, int dy) {
    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null) return null;
    final re = _timRenderEditable(hopVanBan);
    if (re == null || !re.hasSize) return null;
    Rect goc;
    try {
      goc = re.getLocalRectForCaret(TextPosition(offset: vt));
    } catch (_) {
      return null;
    }
    final caoDong = re.preferredLineHeight;
    final diemNham = Offset(goc.left, goc.top + caoDong * (dy < 0 ? -0.5 : 1.5));
    final vtMoi = re.getPositionForPoint(re.localToGlobal(diemNham)).offset;
    return vtMoi.clamp(0, _boDieuKhien.text.length);
  }

  /// Cuộn khung soạn thảo tới đúng con trỏ NẾU nó đang nằm ngoài khung
  /// nhìn — canh GIỮA màn hình khi cuộn (đơn giản và chắc chắn hơn hẳn
  /// cách "nhích tối thiểu" cũ). Gọi sau MỌI thao tác ở Bộ phím nhanh có
  /// thể đổi vị trí con trỏ (chèn ký tự, xoá, Home/End, All, Cut/Paste,
  /// mũi tên Lên/Xuống/Trái/Phải).
  ///
  /// ĐÃ SỬA (không cuộn hoặc cuộn sai, kể cả mũi tên — vốn đã gọi hàm này
  /// từ trước): bản cũ so trực tiếp `RenderEditable.getLocalRectForCaret`
  /// (toạ độ CỤC BỘ của chính RenderEditable) với `_cuonVanBan.offset` (độ
  /// cuộn NỘI DUNG) — đúng loại lỗi TRỘN LẪN hai hệ toạ độ khác nhau đã
  /// từng gây lỗi 5 mốc phụ "Đoạn số" (xem lịch sử sửa lỗi đó, cùng bài
  /// học). Sửa: quy hết mọi phép so sánh về toạ độ TOÀN CỤC màn hình thật
  /// (`localToGlobal` không tham số — kỹ thuật đã dùng đúng và ổn định
  /// cho `_veConTro()`), so trực tiếp với khung nhìn thật (vị trí +
  /// chiều cao thật của `_oVanBanKey` trên màn hình) — không còn giả định
  /// gì về ý nghĩa toạ độ cục bộ của RenderEditable nữa.
  ///
  /// Kiểm tra 2 lượt cách nhau đúng 1 khung hình: lượt đầu ngay sau khung
  /// hình vừa đổi vị trí con trỏ; lượt hai đợi thêm 1 khung hình rồi kiểm
  /// tra lại — để THẮNG được cơ chế tự-cuộn-tới-con-trỏ RIÊNG của chính
  /// `EditableText`/`TextField` gốc (chạy độc lập, có thể tự cuộn sai dưới
  /// bố cục `expands: true` VÀ chạy SAU lượt cuộn đầu của mình, ghi đè mất
  /// nếu chỉ kiểm tra đúng một lượt).
  void _cuonToiConTroNeuCan() {
    void kiemTraVaCuon() {
      if (!mounted || !_cuonVanBan.hasClients) return;
      final hopVanBanObj = _oVanBanKey.currentContext?.findRenderObject();
      if (hopVanBanObj is! RenderBox || !hopVanBanObj.hasSize) return;
      final re = _timRenderEditable(hopVanBanObj);
      if (re == null || !re.hasSize) return;
      final vt = _boDieuKhien.selection.extentOffset;
      if (vt < 0) return;
      Rect gocCucBo;
      try {
        gocCucBo = re.getLocalRectForCaret(TextPosition(offset: vt));
      } catch (_) {
        return;
      }
      final caretTrenGlobal = re.localToGlobal(gocCucBo.topLeft).dy;
      final caretDuoiGlobal = re.localToGlobal(gocCucBo.bottomLeft).dy;
      final khungTren = hopVanBanObj.localToGlobal(Offset.zero).dy;
      final khungCao = hopVanBanObj.size.height;
      final khungDuoi = khungTren + khungCao;

      // Đã thấy trọn vẹn rồi — không cuộn, tránh giật màn hình vô ích lúc
      // gõ/di chuyển bình thường trong tầm nhìn.
      if (caretTrenGlobal >= khungTren && caretDuoiGlobal <= khungDuoi) return;

      final caretGiua = (caretTrenGlobal + caretDuoiGlobal) / 2;
      final khungGiua = khungTren + khungCao / 2;
      final dich = (_cuonVanBan.offset + (caretGiua - khungGiua))
          .clamp(0.0, _cuonVanBan.position.maxScrollExtent);
      _cuonVanBan.animateTo(dich, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      kiemTraVaCuon();
      WidgetsBinding.instance.addPostFrameCallback((_) => kiemTraVaCuon());
    });
  }

  // ------------------------------------------------------------- thẻ ghi âm

  /// Trình ghi âm đang mở (4 nút nhỏ hiện, thanh công cụ trên ẩn) — dùng
  /// chung một cờ cho cả việc hiện overlay VÀ việc có một thẻ đang ghi hay
  /// không, vì theo thiết kế đã chốt, mở trình ghi âm là lập tức ghi luôn.
  bool _trinhGhiAmMo = false;

  /// AppBar của trình ghi âm (`_xayAppBarTrinhGhiAmThe`) tự đo chiều cao
  /// THẬT của lưới nút sau mỗi khung hình, rồi dùng đúng số đo đó làm
  /// `toolbarHeight` — không còn đoán một số cố định dư ra ("bãi đất
  /// trống" phía dưới các nút) hay thiếu (phải cuộn) nữa. `null` = chưa đo
  /// được lần nào (khung hình đầu tiên), dùng tạm số ước lượng cũ.
  final _khoaLuoiTrinhGhiAmThe = GlobalKey();
  double? _caoLuoiTrinhGhiAmThe;

  void _doLaiCaoLuoiTrinhGhiAmThe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hop = _khoaLuoiTrinhGhiAmThe.currentContext?.findRenderObject() as RenderBox?;
      final cao = hop?.size.height;
      if (cao == null || cao <= 0) return;
      if (_caoLuoiTrinhGhiAmThe != null && (_caoLuoiTrinhGhiAmThe! - cao).abs() < 0.5) return;
      setState(() => _caoLuoiTrinhGhiAmThe = cao);
    });
  }
  int _soThuTuTheGhiAmTiepTheo = 1;
  int? _soTheGhiAmDangGhi;

  /// Vị trí ký tự của token "đang ghi âm" hiện tại trong văn bản — được
  /// `_dieuChinhLoiChinhTaSauKhiSua` tự dời theo mỗi khi có sửa đổi ở TRƯỚC
  /// nó (gõ tay ở chỗ khác trong lúc vẫn đang ghi thẻ này), y hệt cách các
  /// vị trí/vùng khác trong file này được theo dõi. `null` = không có thẻ
  /// nào đang ghi dở.
  int? _viTriTokenDangGhiThe;

  /// Đếm giờ hiển thị RIÊNG bằng `ValueNotifier` (không dùng `setState`) —
  /// y hệt lý do đã sửa ở `_conTroDangHien`: tránh dựng lại toàn cây mỗi
  /// giây trong lúc trình ghi âm mở, để không lặp lại lỗi "phải chạm hai
  /// lần" cho chính các nút của trình ghi âm.
  final ValueNotifier<Duration> _thoiLuongTheGhiAmDangGhi =
      ValueNotifier<Duration>(Duration.zero);
  Timer? _bomDongHoTheGhiAm;
  bool _theGhiAmDangTamDung = false;
  StreamSubscription<double>? _dangKyMucAmTheGhiAm;
  final Map<int, Duration> _thoiLuongTheoTheGhiAm = {};
  final Map<int, KetQuaGhiAmThe> _duLieuTheoTheGhiAm = {};
  final Set<int> _theGhiAmDangGui = {};

  /// Đè nhãn trạng thái to ở AppBar/bảng điều khiển trình ghi âm (thay cho
  /// "Đang Ghi âm mm:ss") — `null` = đang ghi thật, hiện đồng hồ lượn sóng
  /// như cũ; khác `null` = thẻ vừa chốt đang được gửi cho AI ("Đang chuyển
  /// #N") hoặc đã có kết quả ("Đã chuyển xong #N"/lỗi) — không lượn sóng vì
  /// không còn ghi âm thật nữa. `ValueNotifier` (không phải field thường)
  /// để bảng điều khiển (`_BangDieuKhienGhiAm`, một route riêng dựng MỘT
  /// LẦN qua `showGeneralDialog`, không tự rebuild theo `setState` của
  /// trang) vẫn thấy cập nhật khi đang mở — xem `_hoanThanhChuyenThanhVanBan`.
  final ValueNotifier<TrangThaiGheDe?> _nhanTrangThaiGhiAmGheDe = ValueNotifier(null);

  /// Còn gì để "Xoá bản này" ở nút Xoá không — chỉ đúng khi thẻ vừa chốt ĐÃ
  /// chuyển hoá xong hẳn (thành công), không còn gì đang ghi/đang gửi/lỗi
  /// chờ gửi lại để xoá nữa. Dùng đổi nhãn nút "Xoá bản này-Đóng trình ghi
  /// âm" thành chỉ "Đóng trình ghi âm" khi không còn gì để xoá.
  bool get _khongCoGiDeXoaTrongTrinhGhiAm =>
      _nhanTrangThaiGhiAmGheDe.value?.loai == LoaiTrangThaiGheDe.daChuyenXong;

  /// Bộ nhớ đệm văn bản AI đã trả về, theo số thẻ — sống suốt phiên làm
  /// việc, KHÔNG mất khi thẻ bị xoá khỏi văn bản (khác với 3 map/set ở
  /// trên, chỉ giữ dữ liệu cho tới khi thẻ CHUYỂN HOÁ XONG hoặc bị xoá).
  /// Nhờ vậy: hoàn tác (Ctrl+Z) đưa một thẻ ĐÃ chuyển hoá xong về lại dạng
  /// "Ghi âm N", rồi bấm chuyển hoá lại, thì trả ngay văn bản cũ — không gọi
  /// AI lần hai. Cũng là căn cứ để biết một thẻ "đã an toàn" (xoá không cần
  /// hỏi, vì hoàn tác vẫn cứu được) hay "chưa an toàn" (xoá phải hỏi, vì mất
  /// là mất luôn — xem `_hoiXoaTheGhiAm`/`_khiCanXoaTheTuBanPhim`). Chỉ ghi
  /// vào đây văn bản, không ghi âm thanh/thời lượng — một khi đã có văn bản
  /// thì không bao giờ cần gửi lại âm thanh nữa, xem `_guiVaXuLyMotThe`.
  final Map<int, String> _vanBanDaTraVeTheoTheGhiAm = {};
  bool _daCanhBaoGioiHanTheGhiAm = false;
  bool _hopThoaiCanhBaoTheGhiAmDangMo = false;

  /// (SIẾT LẠI mỗi thẻ tối đa 60 giây, trước đây 5 phút — thẻ ngắn giúp
  /// người dùng nói có tổ chức hơn, đỡ lan man, và né hẳn nhu cầu phải cắt
  /// một file ghi âm dài sẵn có — mỗi thẻ mới luôn là MỘT LƯỢT GHI TỪ ĐẦU.)
  static const _gioiHanMoiTheGhiAm = Duration(seconds: 60);

  /// Cảnh báo ở giây 45 cho các thẻ THƯỜNG (còn được tự nối tiếp) — sớm hơn
  /// tỉ lệ cũ một chút (cũ: cảnh báo trước đúng 1 phút so với hạn 5 phút)
  /// để người dùng vẫn kịp phản ứng dù hạn giờ đã ngắn đi nhiều.
  static const _canhBaoGioiHanTheGhiAm = Duration(seconds: 45);

  /// Cảnh báo SỚM HƠN (giây 30) riêng cho thẻ tự động CUỐI CÙNG còn được
  /// phép (xem `_laTheTuDongCuoiCung`) — hậu quả nặng hơn hẳn (tự NGỪNG hẳn
  /// trình ghi âm, không phải chỉ chuyển thẻ), nên cho thêm thời gian phản
  /// ứng.
  static const _canhBaoGioiHanTheGhiAmCuoiCung = Duration(seconds: 30);

  /// Đếm số thẻ đã được TỰ ĐỘNG nối tiếp nhau (do hết giờ 60 giây mà KHÔNG
  /// ai bấm gì) — reset về 0 mỗi khi có một hành động bấm tay THẬT (bấm
  /// "Tạo bản ghi âm mới" ở dialog, "Hoàn thành-Tạo bản ghi âm mới" ở
  /// AppBar/bảng điều khiển, hay mở trình ghi âm mới từ đầu). Mục đích:
  /// chặn trường hợp người dùng bỏ máy đó ghi âm mãi không ai đụng vào
  /// (tốn token AI + pin máy), mà KHÔNG phạt người dùng thật đang chủ động
  /// bấm tay để ghi âm liên tục dài — bấm tay luôn reset về 0, không bao
  /// giờ bị chặn. Xem `_chotTheGhiAmVaBatDauTheMoiDoQuaGioiHan`.
  int _soLanTuDongTaoTheLienTiep = 0;

  /// Cho phép tối đa 5 thẻ tự động nối tiếp nhau (không ai bấm gì) — tới
  /// thẻ THỨ NĂM này, nếu vẫn không ai bấm gì thì tự NGỪNG hẳn (đóng trình
  /// ghi âm), không tạo thẻ thứ sáu. 60 giây × 5 thẻ = đúng 5 phút tổng
  /// cộng không ai bấm gì thì tự ngừng hẳn.
  static const _soLanToiDaTuDongTaoTheLienTiep = 5;

  /// Ghi âm và micro-vừa-nói-vừa-ra-chữ không được cùng chạy — cả hai đều
  /// cần độc chiếm microphone của máy. Áp dụng cho MỌI nền tảng (kể cả
  /// Android/iOS gốc), không riêng web.
  bool get _ghiAmTheDangKhoaMicro => _trinhGhiAmMo;

  /// Nút "phím 7" trong Bảng điều khiển gọi hàm này — mở modal cài đặt
  /// (bật/tắt + số giây). Modal mở ra thì tạm dừng bản đang ghi (nếu đang
  /// ghi thật), đóng modal thì trả lại ĐÚNG trạng thái trước đó — y hệt
  /// nút "Xoá bản ghi âm" và "phím 8": trước đây hàm này LUÔN ép tiếp tục
  /// khi đóng, nên nếu người dùng đã chủ động tạm dừng RỒI mới mở modal
  /// này, đóng modal lại vô tình tự ghi tiếp — sai, đã sửa.
  Future<void> _moModalCaiDatTuDongChuyenHoa() async {
    final dangGhiTruocDo = _soTheGhiAmDangGhi != null && !_theGhiAmDangTamDung;
    if (dangGhiTruocDo) await _tamDungTheGhiAmHienTai();

    var batTam = widget.caiDat.tuDongGuiNgamTheGhiAm;
    var giayTam = widget.caiDat.nguongTuDongGuiTheGhiAmGiay;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhatModal) => AlertDialog(
          // (YÊU CẦU MỚI) Bỏ nút "Đóng" ở `actions` — thay bằng nút X đỏ
          // gọn gàng ở góc trên bên phải.
          title: Row(
            children: [
              Expanded(child: Text(Ch.tuDongChuyenHoaVanBan(ngonNguHienTai.value))),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: Ch.dong(ngonNguHienTai.value),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Ch.giaiThichTuDongChuyenHoaTheGhiAm(ngonNguHienTai.value),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(Ch.tuDongChuyenHoa(ngonNguHienTai.value)),
                  value: batTam,
                  onChanged: (v) async {
                    capNhatModal(() => batTam = v);
                    await widget.caiDat.datTuDongGuiNgamTheGhiAm(v);
                    if (mounted) setState(() {});
                  },
                ),
                if (batTam) ...[
                  Row(
                    children: [
                      Text(Ch.nguongHaiChamDau(ngonNguHienTai.value), style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(Ch.soGiay(ngonNguHienTai.value, giayTam),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: giayTam.toDouble(),
                    min: CaiDat.gioiHanDuoiNguongTuDongGuiTheGhiAm.toDouble(),
                    max: CaiDat.gioiHanTrenNguongTuDongGuiTheGhiAm.toDouble(),
                    divisions: CaiDat.gioiHanTrenNguongTuDongGuiTheGhiAm -
                        CaiDat.gioiHanDuoiNguongTuDongGuiTheGhiAm,
                    label: Ch.giayTamNhan(ngonNguHienTai.value, giayTam),
                    onChanged: (v) async {
                      capNhatModal(() => giayTam = v.round());
                      await widget.caiDat.datNguongTuDongGuiTheGhiAmGiay(v.round());
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (dangGhiTruocDo && _soTheGhiAmDangGhi != null && _theGhiAmDangTamDung) {
      await _tiepTucTheGhiAmHienTai();
    }
  }

  /// Nút "phím 8" trong Bảng điều khiển — mở modal cài đặt HIỆN/ẨN tự động
  /// bảng đó mỗi lần ghi âm mới. Mở modal thì tạm dừng bản đang ghi (nếu
  /// đang ghi), đóng modal thì trả lại ĐÚNG trạng thái trước đó — giống
  /// nút "Xoá bản ghi âm", KHÁC nút "Cài đặt Tự động chuyển hoá văn bản"
  /// (nơi luôn ép tiếp tục khi đóng, không nhớ trạng thái cũ).
  Future<void> _moModalCaiDatTuDongMoBangDieuKhien() async {
    final dangGhiTruocDo = _soTheGhiAmDangGhi != null && !_theGhiAmDangTamDung;
    if (dangGhiTruocDo) await _tamDungTheGhiAmHienTai();

    var chonTam = widget.caiDat.tuDongMoBangDieuKhienGhiAm ??
        (_thietBiHienTai == ThietBi.pc);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhatModal) => AlertDialog(
          title: Text(Ch.caiDatTuDongMoBangGhiAm(ngonNguHienTai.value)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Ch.giaiThichTuMoBangDieuKhien(ngonNguHienTai.value),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  groupValue: chonTam,
                  onChanged: (v) => capNhatModal(() => chonTam = true),
                  title: RichText(
                    text: TextSpan(
                      // Kiểu chữ THƯỜNG, khai rõ ràng — không lấy
                      // `DefaultTextStyle.of(ctx)` nữa: modal này mở từ bên
                      // trong trang soạn thảo nên nó vô tình thừa hưởng đúng
                      // kiểu định dạng (đỏ/đậm/gạch dưới...) đang áp cho văn
                      // bản ghi chú tại vị trí con trỏ, chứ không phải lỗi cố ý.
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                        decoration: TextDecoration.none,
                      ),
                      children: [
                        TextSpan(
                            text: Ch.moiLanGhiAmTuDongPrefix(
                                ngonNguHienTai.value)),
                        TextSpan(
                          text: Ch.chuHoaHien(ngonNguHienTai.value),
                          style: TextStyle(
                            backgroundColor: Colors.green.shade200,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                            text: Ch.bangDieuKhienNaySuffix(
                                ngonNguHienTai.value)),
                      ],
                    ),
                  ),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  groupValue: chonTam,
                  onChanged: (v) => capNhatModal(() => chonTam = false),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                        decoration: TextDecoration.none,
                      ),
                      children: [
                        TextSpan(
                            text: Ch.moiLanGhiAmTuDongPrefix(
                                ngonNguHienTai.value)),
                        TextSpan(
                          text: Ch.chuHoaAn(ngonNguHienTai.value),
                          style: TextStyle(
                            backgroundColor: Colors.orange.shade200,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                            text: Ch.bangDieuKhienNaySuffix(
                                ngonNguHienTai.value)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(Ch.huy(ngonNguHienTai.value))),
            FilledButton(
              onPressed: () async {
                await widget.caiDat.datTuDongMoBangDieuKhienGhiAm(chonTam);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(Ch.luu(ngonNguHienTai.value)),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (dangGhiTruocDo && _soTheGhiAmDangGhi != null && _theGhiAmDangTamDung) {
      await _tiepTucTheGhiAmHienTai();
    }
  }

  String _nhanTheGhiAmHoanChinh(int soThe) =>
      nhanTheHoanChinh(soThe, _thoiLuongTheoTheGhiAm[soThe] ?? Duration.zero);

  Future<void> _bamNutGhiAmThe() async {
    if (_trinhGhiAmMo) {
      await _dongTrinhGhiAmThe();
      return;
    }
    if (_hienThanhTimKiem) {
      _bao(Ch.dangMoTimKiemHayDongTruocKhiGhiAm(ngonNguHienTai.value));
      return;
    }
    // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Nút bấm tay đã bị khoá
    // xám lúc Micro đang bật (`khoaNutGhiAmThe`) nên không lọt vào đây được
    // qua chạm thường — chốt an toàn này chỉ còn cần cho đường vào khác
    // (phím tắt Ghi âm bấm trong lúc Micro đang nghe).
    if (_muonNghe) {
      _bao(Ch.dangDungMicroTatTruocKhiGhiAmChamCham(ngonNguHienTai.value));
      return;
    }
    final ok = await ghiAmTheKhoiTao();
    if (!mounted) return;
    if (!ok) {
      _bao(Ch.khongXinDuocQuyenMicroDeGhiAm(ngonNguHienTai.value));
      return;
    }
    setState(() => _trinhGhiAmMo = true);
    // Mở trình ghi âm mới từ đầu — bắt đầu lại vòng đếm thẻ tự động.
    _soLanTuDongTaoTheLienTiep = 0;
    await _batDauMotTheGhiAmMoi();
    if (!mounted) return;
    final tuMoBang = widget.caiDat.tuDongMoBangDieuKhienGhiAm ??
        (_thietBiHienTai == ThietBi.pc);
    if (tuMoBang) _bamNutHienBangDieuKhienGhiAm();
  }

  Future<void> _batDauMotTheGhiAmMoi() async {
    await ghiAmTheBatDauThe();
    if (!mounted) return;
    final soThe = _soThuTuTheGhiAmTiepTheo++;
    _soTheGhiAmDangGhi = soThe;
    _theGhiAmDangTamDung = false;
    _thoiLuongTheGhiAmDangGhi.value = Duration.zero;
    _daCanhBaoGioiHanTheGhiAm = false;
    // Thẻ MỚI bắt đầu ghi — bỏ hẳn nhãn "Đang chuyển/Đã chuyển xong" của
    // thẻ trước (nếu có), trả lại đồng hồ ghi âm bình thường.
    _nhanTrangThaiGhiAmGheDe.value = null;
    // Số thẻ cho Bảng điều khiển — SỐNG LÂU HƠN `_soTheGhiAmDangGhi` (cái
    // đó về null ngay khi chốt xong) để nút "Hiện bảng điều khiển" luôn mở
    // được, kể cả khi thẻ đã chốt và đang ở trạng thái đang chuyển/đã
    // chuyển xong — xem `_bamNutHienBangDieuKhienGhiAm`. Đổi giá trị ở đây
    // (bắt đầu ghi thẻ MỚI) cũng chính là lúc `_DongBanGhiAmSoNhapNhay`
    // nhận ra số đổi và tự nhấp nháy.
    _soTheChoBangDieuKhien.value = soThe;
    _chenTokenDangGhiTheVaoVanBan();
    _batDauTheoDoiMucAmGhiAm();
    _bomDongHoTheGhiAm?.cancel();
    _bomDongHoTheGhiAm = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _theGhiAmDangTamDung) return;
      final moi = _thoiLuongTheGhiAmDangGhi.value + const Duration(seconds: 1);
      _thoiLuongTheGhiAmDangGhi.value = moi;
      if (moi >= _gioiHanMoiTheGhiAm) {
        _dongHopThoaiCanhBaoTheGhiAmNeuMo();
        // Đã đạt hạn mức thẻ tự động liên tiếp (không ai bấm gì suốt) — tự
        // NGỪNG hẳn, không tạo thêm thẻ mới nữa.
        if (_soLanTuDongTaoTheLienTiep >= _soLanToiDaTuDongTaoTheLienTiep - 1) {
          _dongTrinhGhiAmThe();
        } else {
          _chotTheGhiAmVaBatDauTheMoiDoQuaGioiHan(tuDong: true);
        }
      } else if (moi >=
          (_laTheTuDongCuoiCung
              ? _canhBaoGioiHanTheGhiAmCuoiCung
              : _canhBaoGioiHanTheGhiAm)) {
        _hienCanhBaoGioiHanTheGhiAmNeuChua();
      }
    });
  }

  /// Sóng âm cạnh nút micro hoạt động y hệt lúc micro-vừa-nói-vừa-ra-chữ
  /// đang nghe — dùng lại ĐÚNG `_songAm`/`_khiDoiMucAm` (chỉ đổi nguồn dữ
  /// liệu: mức âm của ĐÁY GHI ÂM đang dùng thay vì của `speech_to_text`).
  void _batDauTheoDoiMucAmGhiAm() {
    _dangKyMucAmTheGhiAm?.cancel();
    _dangKyMucAmTheGhiAm = ghiAmTheMucAm().listen(_khiDoiMucAm);
  }

  void _dungTheoDoiMucAmGhiAm() {
    _dangKyMucAmTheGhiAm?.cancel();
    _dangKyMucAmTheGhiAm = null;
    _songAm.fillRange(0, _songAm.length, 0);
    if (mounted) _songAmTick.value++;
  }

  Future<void> _tamDungTheGhiAmHienTai() async {
    if (_soTheGhiAmDangGhi == null || _theGhiAmDangTamDung) return;
    await ghiAmTheTamDung();
    if (!mounted) return;
    setState(() => _theGhiAmDangTamDung = true);
    _dungTheoDoiMucAmGhiAm();
  }

  Future<void> _tiepTucTheGhiAmHienTai() async {
    if (_soTheGhiAmDangGhi == null || !_theGhiAmDangTamDung) return;
    await ghiAmTheTiepTuc();
    if (!mounted) return;
    setState(() => _theGhiAmDangTamDung = false);
    _batDauTheoDoiMucAmGhiAm();
  }

  void _chenTokenDangGhiTheVaoVanBan() {
    final vb = _boDieuKhien.text;
    var viTri = _boDieuKhien.selection.baseOffset;
    if (viTri < 0 || viTri > vb.length) viTri = vb.length;
    var chen = tenTokenDangGhiAm;
    var lechDauChen = 0;
    if (viTri > 0 && !_laKhoangTrang(vb[viTri - 1])) {
      chen = ' $chen';
      lechDauChen = 1;
    }
    if (viTri < vb.length && !_laKhoangTrang(vb[viTri])) chen = '$chen ';

    final moi = vb.replaceRange(viTri, viTri, chen);
    _dieuChinhVungToanVanSauKhiSua(viTri, 0, chen.length);
    // (SỬA LỖI đường kẻ chia không biến mất khi chèn thẻ ghi âm vào dòng
    // trống) Thiếu `vanBanCu`/`vanBanMoi` thì khối "kiểm tra lại nội dung
    // dòng, bỏ khỏi danh sách nếu không còn rỗng" bên trong hàm này không
    // chạy — dòng trống đang có đường kẻ chia mà vừa nhận token ghi âm vẫn
    // bị coi là còn trống, đường kẻ ở lại sai chỗ.
    _dieuChinhLoiChinhTaSauKhiSua(viTri, 0, chen.length, vanBanCu: vb, vanBanMoi: moi);
    _gioiHanTreMuSauKhiChen(viTri, chen.length, moi);
    _viTriTokenDangGhiThe = viTri + lechDauChen;
    final viTriConTro = viTri + chen.length;
    _neo = viTriConTro;
    _ghiVaoO(moi, viTriConTro);
  }

  /// Dừng ghi thẻ HIỆN TẠI (đáy nền tảng), thay token "đang ghi" bằng nhãn
  /// hoàn chỉnh tại đúng vị trí đã theo dõi. Trả về số thẻ vừa chốt, hoặc
  /// null nếu không có thẻ nào đang ghi hoặc token đã bị xoá giữa chừng
  /// (ví dụ người dùng chọn hết bài rồi xoá) — trường hợp đó âm thầm bỏ dữ
  /// liệu ghi âm vừa thu được, không có chỗ nào để chèn nhãn vào nữa.
  Future<int?> _chotTheGhiAmHienTaiThanhHoanChinh() async {
    final soThe = _soTheGhiAmDangGhi;
    final viTriToken = _viTriTokenDangGhiThe;
    _bomDongHoTheGhiAm?.cancel();
    _bomDongHoTheGhiAm = null;
    _dungTheoDoiMucAmGhiAm();
    if (soThe == null) return null;
    _thoiLuongTheoTheGhiAm[soThe] = _thoiLuongTheGhiAmDangGhi.value;
    // Đáy ghi âm dừng được cả khi đang TẠM DỪNG (record/MediaRecorder cho
    // phép stop() ngay từ trạng thái pause) — không cần tự resume trước.
    final ketQua = await ghiAmTheKetThucThe();
    _soTheGhiAmDangGhi = null;
    _viTriTokenDangGhiThe = null;
    _theGhiAmDangTamDung = false;
    if (!mounted) return soThe;

    if (ketQua == null) {
      // Ghi âm thất bại — KHÔNG CÓ dữ liệu gì để chuyển hoá. Trước đây vẫn
      // chốt thành thẻ "Ghi âm N" như bình thường dù rỗng ruột — tạo ra một
      // thẻ trông giống mọi thẻ khác nhưng bấm chuyển hoá luôn báo "đã bị
      // xoá vĩnh viễn" (sai — nó chưa từng có gì để xoá). Sửa: bỏ hẳn token
      // "đang ghi" khỏi văn bản, không tạo thẻ ma, báo rõ lý do.
      _thoiLuongTheoTheGhiAm.remove(soThe);
      if (viTriToken != null) {
        final vb = _boDieuKhien.text;
        final ketThucToken = viTriToken + tenTokenDangGhiAm.length;
        if (ketThucToken <= vb.length &&
            vb.substring(viTriToken, ketThucToken) == tenTokenDangGhiAm) {
          final moi = vb.replaceRange(viTriToken, ketThucToken, '');
          _dieuChinhVungToanVanSauKhiSua(viTriToken, tenTokenDangGhiAm.length, 0);
          _dieuChinhLoiChinhTaSauKhiSua(viTriToken, tenTokenDangGhiAm.length, 0,
              vanBanCu: vb, vanBanMoi: moi);
          _ghiVaoO(moi, viTriToken);
          _henLuu();
        }
      }
      // Chưa chắc chắn nguyên nhân thật trên mọi máy/trình duyệt — kèm luôn
      // dòng chẩn đoán kỹ thuật (xem `ghi_am_the_web.dart`) ngay trong
      // thông báo, để nếu còn xảy ra thì có dữ liệu THẬT để sửa tiếp, không
      // phải đoán mò lần nữa.
      final chanDoan = ghiAmTheChanDoanCuoi;
      _bao('Ghi âm #$soThe thất bại (không có dữ liệu) — đã bỏ thẻ này.'
          '${chanDoan != null ? '\nChẩn đoán: $chanDoan' : ''}');
      return soThe;
    }
    _duLieuTheoTheGhiAm[soThe] = ketQua;

    if (viTriToken == null) {
      _ghiLog2(
          'Thẻ ghi âm #$soThe: token đã bị xoá giữa chừng — bỏ dữ liệu ghi âm vừa thu.');
      return soThe;
    }
    final vb = _boDieuKhien.text;
    final ketThucToken = viTriToken + tenTokenDangGhiAm.length;
    if (ketThucToken > vb.length ||
        vb.substring(viTriToken, ketThucToken) != tenTokenDangGhiAm) {
      // Lưới an toàn — về lý thuyết không xảy ra vì ChanSuaGiuaThe chặn mọi
      // sửa một-phần, và trường hợp xoá TRỌN token đã được `_dieuChinhLoiChinhTaSauKhiSua`
      // phát hiện và null hoá `_viTriTokenDangGhiThe` ở trên rồi.
      return soThe;
    }
    final nhan = _nhanTheGhiAmHoanChinh(soThe);
    final moi = vb.replaceRange(viTriToken, ketThucToken, nhan);
    _dieuChinhVungToanVanSauKhiSua(viTriToken, tenTokenDangGhiAm.length, nhan.length);
    _dieuChinhLoiChinhTaSauKhiSua(viTriToken, tenTokenDangGhiAm.length, nhan.length,
        vanBanCu: vb, vanBanMoi: moi);
    final viTriConTro = viTriToken + nhan.length;
    _neo = viTriConTro;
    _ghiVaoO(moi, viTriConTro);
    _henLuu();
    _kiemTraVaGuiNgamTheGhiAmNeuDu();
    return soThe;
  }

  /// [tuDong]: true = do hết giờ mà KHÔNG ai bấm gì (timer tự gọi) — tăng
  /// vòng đếm `_soLanTuDongTaoTheLienTiep`. false = do bấm tay thật (nút
  /// "Tạo bản ghi âm mới" ở dialog cảnh báo) — reset vòng đếm về 0, vì bấm
  /// tay là bằng chứng người dùng vẫn đang ở đó.
  void _chotTheGhiAmVaBatDauTheMoiDoQuaGioiHan({required bool tuDong}) {
    if (_soTheGhiAmDangGhi == null) return;
    _soLanTuDongTaoTheLienTiep = tuDong ? _soLanTuDongTaoTheLienTiep + 1 : 0;
    _chotTheGhiAmHienTaiThanhHoanChinh().then((_) {
      if (mounted && _trinhGhiAmMo) _batDauMotTheGhiAmMoi();
    });
  }

  void _dongHopThoaiCanhBaoTheGhiAmNeuMo() {
    if (_hopThoaiCanhBaoTheGhiAmDangMo && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Đây là thẻ CUỐI CÙNG còn được phép tự động nối tiếp — nếu vẫn không ai
  /// bấm gì, tới hạn thẻ này sẽ KHÔNG tạo thẻ tiếp theo nữa mà tự ngừng hẳn
  /// (xem nhánh trong `_batDauMotTheGhiAmMoi`). Dùng để chọn đúng nội dung
  /// cảnh báo — "sắp chạm 60 giây" (còn tự nối tiếp được) hay "sắp chạm tổng
  /// N phút của M thẻ liên tiếp, sẽ tự NGỪNG" (hết hạn mức).
  bool get _laTheTuDongCuoiCung =>
      _soLanTuDongTaoTheLienTiep >= _soLanToiDaTuDongTaoTheLienTiep - 1;

  void _hienCanhBaoGioiHanTheGhiAmNeuChua() {
    if (_daCanhBaoGioiHanTheGhiAm || !mounted) return;
    // Cảnh báo hộp thoại "sắp chạm 60 giây" của TỪNG thẻ thường đã bỏ hẳn —
    // thay bằng hiệu ứng đổi màu/nhấp nháy ngay trên số phút:giây (xem
    // `_SoPhutGiayGhiAm`). CHỈ còn hộp thoại cho thẻ tự động CUỐI CÙNG
    // (`_laTheTuDongCuoiCung`) — cảnh báo sắp chạm giới hạn TỔNG 5 phút,
    // giữ nguyên y như cũ, không đổi gì.
    if (!_laTheTuDongCuoiCung) return;
    _daCanhBaoGioiHanTheGhiAm = true;
    _hopThoaiCanhBaoTheGhiAmDangMo = true;
    final soThe = _soTheGhiAmDangGhi;
    final laCuoi = _laTheTuDongCuoiCung;
    final tongPhut =
        (_gioiHanMoiTheGhiAm.inSeconds * _soLanToiDaTuDongTaoTheLienTiep) ~/ 60;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, capNhat) {
          // Nút "Tạm dừng"/"Tiếp tục" — KHÔNG đóng dialog, chỉ tạm dừng/tiếp
          // tục bản ghi hiện tại rồi tự đổi tên nút (nghịch đảo nhau).
          // Tạm dừng thì bộ đếm giờ (`_bomDongHoTheGhiAm`) tự đứng yên luôn
          // (xem điều kiện `_theGhiAmDangTamDung` trong đó), nên hạn 60 giây
          // cũng dừng trôi theo, không cần thêm logic riêng ở đây.
          Future<void> bamTamDungTiepTuc() async {
            if (_theGhiAmDangTamDung) {
              await _tiepTucTheGhiAmHienTai();
            } else {
              await _tamDungTheGhiAmHienTai();
            }
            capNhat(() {});
          }

          // Cỡ chữ THƯỜNG, cố định tường minh (không thừa hưởng cỡ tiêu đề
          // to/đậm mặc định của AlertDialog — đó là nguyên nhân chữ bự quá
          // trước đây). Không dùng "tô sáng" (nền màu) nữa — chỉ đậm/đỏ cho
          // đúng những chữ cần nổi bật, đủ rõ mà không rối mắt.
          const kieuTieuDe = TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          );
          const kieuChuThuong = TextStyle(fontSize: 14, color: Colors.black87);
          const kieuNoiBat = TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          );
          const kieuDo = TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          );
          return AlertDialog(
            title: laCuoi
                ? RichText(
                    text: TextSpan(
                      style: kieuTieuDe,
                      children: [
                        TextSpan(text: Ch.sapChamGioiHanTieuDePrefix(ngonNguHienTai.value)),
                        TextSpan(text: '$tongPhut phút', style: kieuDo),
                      ],
                    ),
                  )
                : Text(Ch.sapChamGioiHan60Giay(ngonNguHienTai.value), style: kieuTieuDe),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DemGiayCanhBaoTheGhiAm(
                  thoiLuong: _thoiLuongTheGhiAmDangGhi,
                  gioiHan: _gioiHanMoiTheGhiAm,
                ),
                const SizedBox(height: 10),
                if (laCuoi)
                  RichText(
                    text: TextSpan(
                      style: kieuChuThuong,
                      children: [
                        TextSpan(
                          text: Ch.theGhiAmSoDangSapGhiDu60Giay(
                              soThe, _soLanToiDaTuDongTaoTheLienTiep, ngonNguHienTai.value),
                        ),
                        TextSpan(text: '$tongPhut phút', style: kieuDo),
                        TextSpan(text: Ch.khongAiBamGi(ngonNguHienTai.value)),
                        TextSpan(
                          text: Ch.neuKhongChonTuNgungGhiAm(ngonNguHienTai.value),
                          style: kieuNoiBat,
                        ),
                        TextSpan(
                          text: Ch.deTranhTonTokenVaPinBanMuonLamGi(ngonNguHienTai.value),
                        ),
                      ],
                    ),
                  )
                else
                  RichText(
                    text: TextSpan(
                      style: kieuChuThuong,
                      children: [
                        TextSpan(
                          text: Ch.theGhiAmSoSapGhiDu60Giay(soThe, ngonNguHienTai.value),
                        ),
                        TextSpan(
                          text: Ch.banCoTheKhongCanLamGiBayGio(ngonNguHienTai.value),
                          style: kieuDo,
                        ),
                        TextSpan(
                          text: Ch.toiDungGiay60TuDongChot(ngonNguHienTai.value),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // 5 lựa chọn — nút Tạm dừng/Tiếp tục luôn đứng ĐẦU, rồi tới 4 nút
            // "Hoàn thành..."/"Tạo bản ghi âm mới" như cũ, dùng lại đúng các
            // hàm đã có sẵn cho AppBar/bảng điều khiển trình ghi âm.
            actions: [
              TextButton(
                onPressed: bamTamDungTiepTuc,
                child: Text(_theGhiAmDangTamDung
                    ? Ch.tiepTuc(ngonNguHienTai.value)
                    : Ch.tamDung(ngonNguHienTai.value)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _chotTheGhiAmVaBatDauTheMoiDoQuaGioiHan(tuDong: false);
                },
                child: Text(Ch.taoBanGhiAmMoi(ngonNguHienTai.value)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _hoanThanhChuyenThanhVanBan();
                },
                child: Text(Ch.hoanThanhDoanVaChuyenVanBan(ngonNguHienTai.value)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _hoanThanhPhatDeNgheLai();
                },
                child: Text(Ch.hoanThanhDoanVaPhatLai(ngonNguHienTai.value)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _dongTrinhGhiAmThe();
                },
                child: Text(Ch.hoanThanhDoanVaDongTrinhGhiAm(ngonNguHienTai.value)),
              ),
            ],
          );
        },
      ),
    ).then((_) => _hopThoaiCanhBaoTheGhiAmDangMo = false);
  }

  /// Nút "Tạo phiên ghi âm mới": chốt thẻ hiện tại, chèn 2 dấu xuống dòng
  /// tại vị trí con trỏ hiện tại (đúng nơi thẻ vừa chốt để lại con trỏ),
  /// rồi bắt đầu một thẻ mới.
  Future<void> _taoPhienGhiAmMoiThe() async {
    if (!_trinhGhiAmMo) return;
    await _chotTheGhiAmHienTaiThanhHoanChinh();
    if (!mounted || !_trinhGhiAmMo) return;
    final vb = _boDieuKhien.text;
    final viTri = _boDieuKhien.selection.baseOffset.clamp(0, vb.length);
    _dieuChinhVungToanVanSauKhiSua(viTri, 0, 2);
    _dieuChinhLoiChinhTaSauKhiSua(viTri, 0, 2);
    final moi = vb.replaceRange(viTri, viTri, '\n\n');
    _ghiVaoO(moi, viTri + 2);
    // Bấm tay thật (không phải hết giờ tự động) — reset vòng đếm thẻ tự
    // động liên tiếp.
    _soLanTuDongTaoTheLienTiep = 0;
    await _batDauMotTheGhiAmMoi();
  }

  /// Nút "Dừng và hoàn thành ghi âm": chốt thẻ đang ghi (dù đang ghi hay
  /// đang tạm dừng) thành thẻ ghi âm XONG, nhưng KHÔNG tạo thẻ mới nào —
  /// trình ghi âm vẫn mở (người dùng có thể "Tạo phiên ghi âm mới" sau nếu
  /// muốn ghi tiếp, hoặc "Đóng trình ghi âm" luôn).
  /// Nút "Đóng trình ghi âm": chốt thẻ đang ghi (nếu có) rồi đóng hẳn —
  /// giải phóng micro, ẩn 4 nút nhỏ, thanh công cụ trên hiện lại.
  Future<void> _dongTrinhGhiAmThe() async {
    if (!_trinhGhiAmMo) return;
    await _chotTheGhiAmHienTaiThanhHoanChinh();
    await ghiAmTheDongHan();
    _dongBangDieuKhienGhiAmNeuMo();
    if (mounted) setState(() => _trinhGhiAmMo = false);
  }

  /// Số thẻ nên tác động khi bấm "Hoàn thành-Chuyển thành văn bản"/"Hoàn
  /// thành-Phát để nghe lại" mà KHÔNG có bản ghi âm nào đang chạy để chốt
  /// (`_chotTheGhiAmHienTaiThanhHoanChinh` trả `null`) — trường hợp cụ
  /// thể: vừa "Phát để nghe lại" rồi bấm Đóng (không bấm Chuyển hoá), thẻ
  /// đã chốt từ trước, `_soTheGhiAmDangGhi` đã về `null`, nhưng thẻ đó vẫn
  /// còn nguyên ở đó, chưa gửi AI — hai nút này vẫn phải hoạt động được
  /// trên đúng thẻ đó. Nhận diện qua `_soTheChoBangDieuKhien` (số thẻ GẦN
  /// NHẤT, không bị null hoá như `_soTheGhiAmDangGhi`) còn dữ liệu âm
  /// thanh gốc (`_duLieuTheoTheGhiAm`, nghĩa là chưa gửi/xoá) mà chưa có
  /// văn bản AI (`_vanBanDaTraVeTheoTheGhiAm`, nghĩa là chưa chuyển hoá
  /// xong). `null` = không có gì để làm (ví dụ mới mở trình ghi âm, chưa
  /// ghi được gì).
  int? get _soTheChoHoanThanh {
    final dangGhi = _soTheGhiAmDangGhi;
    if (dangGhi != null) return dangGhi;
    final gan = _soTheChoBangDieuKhien.value;
    if (gan == 0) return null;
    if (!_duLieuTheoTheGhiAm.containsKey(gan)) return null;
    if (_vanBanDaTraVeTheoTheGhiAm.containsKey(gan)) return null;
    return gan;
  }

  /// Nút "Hoàn thành-Chuyển thành văn bản": chốt thẻ đang ghi thành thẻ
  /// hoàn chỉnh, ĐÓNG NGAY cả bảng điều khiển (nếu đang mở) và AppBar
  /// trình ghi âm — KHÔNG đợi gửi AI xong mới đóng như trước (người dùng
  /// không muốn "đứng chờ" nhìn màn hình) — rồi mới gửi cho AI chuyển hoá
  /// Ở NỀN (không `await` từ đây nữa, xem `unawaited` bên dưới): đóng
  /// trước, chuyển sau.
  ///
  /// ĐÁNH ĐỔI đã được người dùng xác nhận: nhãn "Đang chuyển #N"/"Đã
  /// chuyển xong #N" (`_nhanTrangThaiGhiAmGheDe`) từ giờ không còn ai nhìn
  /// thấy được nữa qua nút này (AppBar/bảng điều khiển đã đóng trước khi
  /// nhãn kịp đổi) — vẫn gán nhãn như cũ, không hại gì, chỉ là vô hình.
  ///
  /// LƯU Ý — CHƯA SỬA, cố ý bỏ qua vì không còn ai xem nhãn này nữa (xem
  /// thảo luận với người dùng): dòng gán nhãn "Lỗi khi chuyển" dưới đây có
  /// thể BÁO SAI (báo lỗi giả) nếu đúng lúc `_chotTheGhiAmHienTaiThanhHoanChinh`
  /// gọi `_kiemTraVaGuiNgamTheGhiAmNeuDu()` ở cuối đã tự gửi ngầm CHÍNH thẻ
  /// này trước — `_guiVaXuLyMotThe` gặp cờ "đang gửi" (`_theGhiAmDangGui`)
  /// thì bỏ qua ngay (return sớm) chứ không đợi đúng lượt gửi thật xong,
  /// nên `_vanBanDaTraVeTheoTheGhiAm.containsKey(soThe)` kiểm ngay sau đó
  /// có thể vẫn là false dù AI sau đó vẫn trả về đúng. Nếu sau này có chỗ
  /// nào khác đọc lại nhãn này để hiển thị, PHẢI sửa cái này trước — cách
  /// sửa đúng: cho `_guiVaXuLyMotThe` CHIA SẺ/CHỜ đúng Future đang chạy cho
  /// cùng một số thẻ, thay vì bỏ qua im lặng.
  Future<void> _hoanThanhChuyenThanhVanBan() async {
    var soThe = await _chotTheGhiAmHienTaiThanhHoanChinh();
    // ĐÃ SỬA: không còn ghi âm nào đang chạy để "chốt" (ví dụ vừa nghe lại
    // xong rồi bấm Đóng, không bấm Chuyển hoá — thẻ đã chốt từ trước) thì
    // vẫn còn tác động được lên đúng thẻ đó — xem `_soTheChoHoanThanh`.
    soThe ??= _soTheChoHoanThanh;
    await ghiAmTheDongHan();
    _dongBangDieuKhienGhiAmNeuMo();
    if (mounted) setState(() => _trinhGhiAmMo = false);
    if (soThe == null) return;
    final soTheKhongNull = soThe;
    _nhanTrangThaiGhiAmGheDe.value = TrangThaiGheDe(LoaiTrangThaiGheDe.dangChuyen, soTheKhongNull);
    unawaited(_guiVaXuLyMotThe(soTheKhongNull, baoLoi: true).then((_) {
      if (!mounted) return;
      _nhanTrangThaiGhiAmGheDe.value = TrangThaiGheDe(
          _vanBanDaTraVeTheoTheGhiAm.containsKey(soTheKhongNull)
              ? LoaiTrangThaiGheDe.daChuyenXong
              : LoaiTrangThaiGheDe.loiKhiChuyen,
          soTheKhongNull,
        );
    }));
  }

  /// Nút "Hoàn thành-Phát để nghe lại": chốt thẻ đang ghi thành thẻ hoàn
  /// chỉnh rồi mở NGAY modal nghe lại — y hệt bấm "Nghe bản ghi âm này" ở
  /// menu bấm-vào-thẻ-đã-xong, gộp hai bước thành một.
  Future<void> _hoanThanhPhatDeNgheLai() async {
    // Bật cờ chặn gửi ngầm NGAY TỪ TRƯỚC bước chốt — `_chotTheGhiAmHienTaiThanhHoanChinh`
    // tự gọi `_kiemTraVaGuiNgamTheGhiAmNeuDu()` ở cuối, có thể tự gửi luôn
    // chính thẻ vừa chốt này TRƯỚC KHI modal nghe lại kịp mở ra — xem
    // `_dangMoModalNgheLaiGhiAm`. `_ngheLaiGhiAmThe` tự tắt cờ này lại
    // (trong `finally`) khi xong; nếu chốt thất bại (soThe null) thì tự
    // tắt luôn ở đây, không gọi tới `_ngheLaiGhiAmThe`.
    _dangMoModalNgheLaiGhiAm = true;
    var soThe = await _chotTheGhiAmHienTaiThanhHoanChinh();
    // ĐÃ SỬA: xem chú thích ở `_hoanThanhChuyenThanhVanBan` — cùng lý do,
    // cho phép nghe lại THÊM lần nữa một thẻ vừa nghe lại xong.
    soThe ??= _soTheChoHoanThanh;
    if (soThe == null || !mounted) {
      _dangMoModalNgheLaiGhiAm = false;
      _kiemTraVaGuiNgamTheGhiAmNeuDu();
      return;
    }
    await _ngheLaiGhiAmThe(soThe);
  }

  /// Nút "Hiện bảng điều khiển" — mở modal riêng, có bộ phím tắt CỤC BỘ
  /// của chính nó (Tab/phím tắt Ghi âm hiện tại cho Tạm dừng-Tiếp tục,
  /// phím 1-7 cho 7 nút còn lại), chỉ hoạt động khi modal này đang mở.
  ///
  /// ĐÃ SỬA (nút này bị "chết" khi thẻ đang ở trạng thái đang chuyển/đã
  /// chuyển xong): điều kiện cũ bắt buộc `_soTheGhiAmDangGhi != null` — mà
  /// giá trị đó LUÔN null ngay sau khi một thẻ được chốt xong, kể cả khi
  /// trình ghi âm vẫn còn mở (`_trinhGhiAmMo`). Giờ chỉ cần trình ghi âm
  /// còn mở là mở được bảng — số thẻ hiển thị lấy từ `_soTheChoBangDieuKhien`
  /// (sống lâu hơn, giữ đúng số thẻ gần nhất, xem field đó).
  void _bamNutHienBangDieuKhienGhiAm() {
    if (!_trinhGhiAmMo) return;
    _bangDieuKhienGhiAmDangMo = true;
    showGeneralDialog<void>(
      context: context,
      // ĐÃ SỬA (bảng điều khiển bị đóng dễ dàng khi bấm lệch ra ngoài):
      // false — chỉ còn cách đóng chủ động (phím 6 "Ẩn bảng điều khiển",
      // hay các nút "Hoàn thành-..."/"Xoá bản này" tự đóng theo đúng ý
      // nghĩa của chúng), không còn đóng "vô tình" nữa.
      barrierDismissible: false,
      barrierLabel: 'Đóng bảng điều khiển',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, anim1, anim2) => PopScope(
        // Chặn luôn cả nút Back (Android)/vuốt lùi (web) — cùng lý do với
        // `barrierDismissible: false` ở trên: bảng này không được đóng
        // ngoài ý muốn bằng BẤT KỲ cách nào ngoài các nút chủ động của nó.
        canPop: false,
        child: _BangDieuKhienGhiAm(
          soThe: _soTheChoBangDieuKhien,
          thoiLuong: _thoiLuongTheGhiAmDangGhi,
          trangThaiGheDe: _nhanTrangThaiGhiAmGheDe,
          songAmTick: _songAmTick,
          songAm: _songAm,
          dangTamDungBanDau: _theGhiAmDangTamDung,
          phimTatGhiAm: widget.caiDat.phimTatGhiAm,
          khiTamDung: _tamDungTheGhiAmHienTai,
          khiTiepTuc: _tiepTucTheGhiAmHienTai,
          khiChuyenThanhVanBan: _hoanThanhChuyenThanhVanBan,
          khiTaoBanMoi: _taoPhienGhiAmMoiThe,
          khiPhatLai: _hoanThanhPhatDeNgheLai,
          khiDong: _dongTrinhGhiAmThe,
          khiXoaVaDong: _huyBanGhiAmDangDoDangVaDong,
          khiCaiDatTuDongChuyenHoa: _moModalCaiDatTuDongChuyenHoa,
          khiCaiDatTuDongMoBang: _moModalCaiDatTuDongMoBangDieuKhien,
          khiDoiViTri: _batDauDoiViTriTheDangGhi,
        ),
      ),
    ).then((_) {
      _bangDieuKhienGhiAmDangMo = false;
    });
  }

  /// Nút "Xoá bản này-Đóng trình ghi âm": HUỶ THẲNG bản ghi âm đang dở
  /// dang — không chốt thành thẻ, không lưu bất cứ gì (khác hẳn 4 nút
  /// "Hoàn thành-..." ở trên, luôn chốt trước khi hành động). Dưới 1 phút
  /// thì huỷ ngay không hỏi (ghi dở vài giây, hỏi lại chỉ gây phiền); từ 1
  /// phút trở lên thì hỏi xác nhận giữa màn hình — mất công ghi khá lâu
  /// rồi, lỡ tay bấm nhầm nút mất trắng sẽ rất khó chịu.
  Future<void> _huyBanGhiAmDangDoDangVaDong() async {
    if (!_trinhGhiAmMo) return;
    if (_soTheGhiAmDangGhi != null &&
        _thoiLuongTheGhiAmDangGhi.value >= const Duration(minutes: 1)) {
      // Hiện hộp thoại xác nhận thì tự tạm dừng bản đang ghi luôn (đỡ tốn
      // dung lượng ghi vô ích trong lúc người dùng còn đang cân nhắc) —
      // NHƯNG nếu trước đó đã tự tạm dừng sẵn rồi thì giữ nguyên, không
      // đụng vào (`_tamDungTheGhiAmHienTai` đã tự no-op khi đã tạm dừng).
      // Đóng hộp thoại lại mà KHÔNG xoá thì trả lại ĐÚNG trạng thái trước
      // đó (đang ghi thì ghi tiếp; đang tạm dừng thì vẫn tạm dừng) — khác
      // hẳn modal Cài đặt Tự động chuyển hoá (luôn ép tiếp tục khi đóng).
      final dangGhiTruocDo = !_theGhiAmDangTamDung;
      if (dangGhiTruocDo) await _tamDungTheGhiAmHienTai();

      final dongY = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Ch.xoaBanGhiAmDangDoDang(ngonNguHienTai.value)),
          content: Text(
            Ch.banGhiAmDangDoDangDaGhiDuoc(
                dinhDangMmSs(_thoiLuongTheGhiAmDangGhi.value), ngonNguHienTai.value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(Ch.khongGiuLai(ngonNguHienTai.value)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(Ch.xoa(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
            ),
          ],
        ),
      );
      if (dongY != true) {
        if (mounted && dangGhiTruocDo && _soTheGhiAmDangGhi != null) {
          await _tiepTucTheGhiAmHienTai();
        }
        return;
      }
      if (!mounted) return;
    }
    // MỚI: thẻ vừa chốt đang được GỬI CHO AI ("Đang chuyển #N" — không còn
    // ghi âm thật để mà hỏi "giữ lại bản ghi dở dang" ở nhánh trên nữa) —
    // ngắt luôn, KHÔNG hỏi (đúng yêu cầu: khác nhánh trên, ở đây không có gì
    // để "tiếp tục ghi" nếu đổi ý). Xoá thẳng token "Đang chuyển N..." khỏi
    // văn bản NGAY — khi request AI trả lời sau đó (thành công hay lỗi),
    // `_guiVaXuLyMotThe` tìm token bằng `indexOf` sẽ không thấy nữa nên tự
    // bỏ qua mọi việc chèn/gắn lại nhãn (xem `if (viTri >= 0)` ở đó), không
    // cần thêm cờ "đã huỷ" riêng.
    final gheDe = _nhanTrangThaiGhiAmGheDe.value;
    if (gheDe != null && gheDe.loai == LoaiTrangThaiGheDe.dangChuyen) {
      _xoaTokenDangChuyenKhoiVanBanNeuCon(gheDe.soThe);
    }
    _nhanTrangThaiGhiAmGheDe.value = null;
    await _huyThangBanGhiDangDoDang();
    await ghiAmTheDongHan();
    _dongBangDieuKhienGhiAmNeuMo();
    if (mounted) setState(() => _trinhGhiAmMo = false);
    // (YÊU CẦU MỚI) Lưới an toàn — bấm quá nhanh có lúc khiến vị trí token
    // "đang ghi âm" (`_viTriTokenDangGhiThe`) đọc được ở trên không còn
    // khớp đúng văn bản thật nữa (lệch vài ký tự vì một chỉnh sửa khác xảy
    // ra gần như đồng thời), nên nhánh xoá trong `_huyThangBanGhiDangDoDang`
    // bỏ qua, để sót lại thẻ "đang ghi âm" ma. Rà soát lại TOÀN VĂN BẢN sau
    // 1 giây, độc lập hẳn với toạ độ đã lưu — còn sót thẻ nào thì xoá nốt.
    Future.delayed(const Duration(seconds: 1), _raSoatVaXoaTheDangGhiAmConSot);
  }

  /// Xem giải thích ở nơi gọi — quét `tenTokenDangGhiAm` còn sót lại trong
  /// văn bản (không dựa vào toạ độ đã lưu) rồi xoá, CHỈ khi trình ghi âm
  /// THẬT SỰ đã đóng (`!_trinhGhiAmMo`) — tránh xoá nhầm một token đang ghi
  /// THẬT nếu người dùng vừa mở ghi âm mới lại trong đúng 1 giây đó.
  void _raSoatVaXoaTheDangGhiAmConSot() {
    if (!mounted || _trinhGhiAmMo) return;
    final vb = _boDieuKhien.text;
    final vt = vb.indexOf(tenTokenDangGhiAm);
    if (vt < 0) return;
    final kt = vt + tenTokenDangGhiAm.length;
    final moi = vb.replaceRange(vt, kt, '');
    _dieuChinhVungToanVanSauKhiSua(vt, tenTokenDangGhiAm.length, 0);
    _dieuChinhLoiChinhTaSauKhiSua(vt, tenTokenDangGhiAm.length, 0, vanBanCu: vb, vanBanMoi: moi);
    _ghiVaoO(moi, vt.clamp(0, moi.length));
    _henLuu();
  }

  /// Xoá token "〔Đang chuyển N 🎙️ mm:ss〕" của đúng thẻ [soThe] khỏi văn bản
  /// (nếu còn) — dùng khi người dùng bấm "Xoá bản này" ngay lúc thẻ đang
  /// được gửi cho AI, để ngắt hẳn: request vẫn chạy tới cùng ở tầng dưới,
  /// nhưng khi trả lời về thì không còn token nào để chèn/gắn lại nhãn nữa
  /// (xem `_guiVaXuLyMotThe`).
  void _xoaTokenDangChuyenKhoiVanBanNeuCon(int soThe) {
    final vb = _boDieuKhien.text;
    for (final m in reTheDangChuyen.allMatches(vb)) {
      if (int.parse(m.group(1)!) != soThe) continue;
      final batDau = m.start, ketThuc = m.end;
      final moi = vb.replaceRange(batDau, ketThuc, '');
      _dieuChinhVungToanVanSauKhiSua(batDau, ketThuc - batDau, 0);
      _dieuChinhLoiChinhTaSauKhiSua(batDau, ketThuc - batDau, 0,
          vanBanCu: vb, vanBanMoi: moi);
      _ghiVaoO(moi, batDau.clamp(0, moi.length));
      _henLuu();
      _duLieuTheoTheGhiAm.remove(soThe);
      _thoiLuongTheoTheGhiAm.remove(soThe);
      _boDieuKhien.theGhiAmLoiTamThoi.remove(soThe);
      return; // chỉ có đúng 1 token "đang chuyển" cho mỗi số thẻ tại một lúc.
    }
  }

  /// Dừng đáy ghi âm nhưng KHÔNG dùng gì tới dữ liệu trả về, rồi gỡ token
  /// "đang ghi âm N" khỏi văn bản — gần như sao y nhánh "ghi âm thất bại"
  /// của `_chotTheGhiAmHienTaiThanhHoanChinh` (nơi ĐÃ có sẵn đúng logic
  /// "bỏ token, không tạo thẻ ma"), chỉ khác là chủ động huỷ thay vì do lỗi.
  Future<void> _huyThangBanGhiDangDoDang() async {
    final soThe = _soTheGhiAmDangGhi;
    final viTriToken = _viTriTokenDangGhiThe;
    _bomDongHoTheGhiAm?.cancel();
    _bomDongHoTheGhiAm = null;
    _dungTheoDoiMucAmGhiAm();
    if (soThe == null) return;
    await ghiAmTheKetThucThe();
    _soTheGhiAmDangGhi = null;
    _viTriTokenDangGhiThe = null;
    _theGhiAmDangTamDung = false;
    _thoiLuongTheoTheGhiAm.remove(soThe);
    if (!mounted || viTriToken == null) return;
    final vb = _boDieuKhien.text;
    final ketThucToken = viTriToken + tenTokenDangGhiAm.length;
    if (ketThucToken <= vb.length &&
        vb.substring(viTriToken, ketThucToken) == tenTokenDangGhiAm) {
      final moi = vb.replaceRange(viTriToken, ketThucToken, '');
      _dieuChinhVungToanVanSauKhiSua(viTriToken, tenTokenDangGhiAm.length, 0);
      _dieuChinhLoiChinhTaSauKhiSua(viTriToken, tenTokenDangGhiAm.length, 0,
          vanBanCu: vb, vanBanMoi: moi);
      _ghiVaoO(moi, viTriToken);
      _henLuu();
    }
  }

  /// Ghi tạm — dùng `_bao` (thông báo giữa màn hình) thay cho nhật ký
  /// riêng, vì trang này (khác web-test) không có sẵn khung nhật ký hiển
  /// thị liên tục; chỉ log khi thật sự đáng chú ý (lưới an toàn hiếm gặp).
  void _ghiLog2(String s) {
    // ignore: avoid_print
    print(s);
  }

  /// Kiểm tra điều kiện gửi ngầm — gọi mỗi khi một thẻ vừa được chốt xong.
  /// Nếu đủ điều kiện, gửi NGẦM (không chờ, không khoá giao diện) tất cả
  /// các thẻ đã ghi xong mà chưa gửi, trong lúc thẻ mới vẫn đang ghi tiếp.
  /// [boQuaSoThe]: loại trừ đúng MỘT thẻ khỏi lượt quét này — dùng khi vừa
  /// đóng modal "nghe lại" (`_ngheLaiGhiAmThe`): thẻ VỪA đóng modal đó vẫn
  /// là "Ghi âm N" chưa gửi trong văn bản, nên nếu không loại trừ, lượt
  /// quét "bắt kịp cho các thẻ KHÁC" ngay sau khi đóng modal sẽ vô tình
  /// bắt luôn CHÍNH thẻ đó — trong khi người dùng chỉ đang muốn NGHE, chưa
  /// hề bấm nút chuyển hoá nào.
  void _kiemTraVaGuiNgamTheGhiAmNeuDu({int? boQuaSoThe}) {
    // Đang mở modal "nghe lại" — tạm ngưng hẳn, kể cả cho các thẻ KHÁC
    // thẻ đang nghe (đơn giản và an toàn hơn lọc riêng đúng một thẻ) — xem
    // `_dangMoModalNgheLaiGhiAm`.
    if (_dangMoModalNgheLaiGhiAm) return;
    if (!widget.caiDat.tuDongGuiNgamTheGhiAm) return;
    final vanBan = _boDieuKhien.text;
    final soTheChuaGui = <int>[];
    for (final m in reTheGhiAmHoanChinh.allMatches(vanBan)) {
      final soThe = int.parse(m.group(1)!);
      if (soThe == boQuaSoThe) continue;
      if (_theGhiAmDangGui.contains(soThe)) continue;
      if (!_duLieuTheoTheGhiAm.containsKey(soThe)) continue;
      soTheChuaGui.add(soThe);
    }
    if (soTheChuaGui.isEmpty) return;
    final tongThoiLuong = soTheChuaGui.fold<Duration>(
      Duration.zero,
      (tong, soThe) => tong + (_thoiLuongTheoTheGhiAm[soThe] ?? Duration.zero),
    );
    if (tongThoiLuong < Duration(seconds: widget.caiDat.nguongTuDongGuiTheGhiAmGiay)) return;
    for (final soThe in soTheChuaGui) {
      _guiVaXuLyMotThe(soThe, baoLoi: false);
    }
  }

  /// Đổi nhãn của MỘT thẻ tại [viTri] (đang là [doDaiCu] ký tự) thành
  /// [nhanMoi] — dùng cho hai bước "đổi tên thành Đang chuyển N lúc bắt đầu
  /// gửi" và "đổi lại thành Ghi âm N lúc gửi lỗi". KHÔNG có hiệu ứng nhấp
  /// nháy (khác `_thayTheGhiAmBangChuAiTaiViTri`, dành riêng cho lúc thay
  /// bằng chữ AI thật).
  void _doiNhanTheGhiAm(int viTri, int doDaiCu, String nhanMoi) {
    final vb = _boDieuKhien.text;
    _dieuChinhVungToanVanSauKhiSua(viTri, doDaiCu, nhanMoi.length);
    _dieuChinhLoiChinhTaSauKhiSua(viTri, doDaiCu, nhanMoi.length);
    final moi = vb.replaceRange(viTri, viTri + doDaiCu, nhanMoi);
    _ghiVaoO(moi, viTri + nhanMoi.length);
    _henLuu();
  }

  /// Thay [doDaiCu] ký tự tại [viTri] (đúng một token thẻ ghi âm) bằng chữ
  /// AI [chu], rồi cho đoạn mới nhấp nháy 4 giây — dùng lại đúng cơ chế của
  /// `_chenVanBanVoiNhapNhay`/vùng "không phù hợp", chỉ khác là THAY một
  /// đoạn có sẵn (token) thay vì chèn tại điểm rỗng.
  void _thayTheGhiAmBangChuAiTaiViTri(int viTri, int doDaiCu, String chu) {
    final vb = _boDieuKhien.text;
    _dieuChinhVungToanVanSauKhiSua(viTri, doDaiCu, chu.length);
    _dieuChinhLoiChinhTaSauKhiSua(viTri, doDaiCu, chu.length);
    final moi = vb.replaceRange(viTri, viTri + doDaiCu, chu);
    _gioiHanTreMuSauKhiChen(viTri, chu.length, moi);
    final viTriConTro = viTri + chu.length;
    _ghiVaoO(moi, viTriConTro);
    _henLuu();
    final v = _VungKhongPhuHop(
      batDauGoc: viTri,
      ketThucGoc: viTri,
      batDauDeXuat: viTri,
      ketThucDeXuat: viTriConTro,
    );
    _boDieuKhien.khongPhuHop.add(v);
    _batNhapNhayKhongPhuHop(v, 'xanh');
  }

  /// Con đường DUY NHẤT gửi một thẻ cho Gemini — dùng chung cho CẢ BA
  /// đường (tay "chỉ thẻ này"/"tất cả", và tự động gửi ngầm), đúng yêu cầu
  /// "áp dụng bất kể trường hợp nào". Ngay khi bắt đầu gửi, đổi nhãn thành
  /// "Đang chuyển N" (cam đậm); xong thì thay bằng chữ AI (nhấp nháy 4
  /// giây); lỗi thì trả lại nhãn "Ghi âm N" gốc, tô cam đậm (khác màu xanh
  /// lá của thẻ xong bình thường) — âm thầm chờ lượt gửi sau, [baoLoi]
  /// quyết định có hiện thông báo lỗi ngay hay không (đường tự động ngầm
  /// luôn im lặng, đường tay luôn báo).
  Future<void> _guiVaXuLyMotThe(int soThe, {required bool baoLoi}) async {
    if (_theGhiAmDangGui.contains(soThe)) return;

    final nhanGoc = _nhanTheGhiAmHoanChinh(soThe);

    // Đã có sẵn trong bộ nhớ đệm (thẻ này từng chuyển hoá xong, rồi bị hoàn
    // tác về lại dạng thẻ) — trả ngay, không gọi AI lần hai.
    final chuCoSan = _vanBanDaTraVeTheoTheGhiAm[soThe];
    if (chuCoSan != null) {
      final viTri = _boDieuKhien.text.indexOf(nhanGoc);
      if (viTri >= 0) {
        _thayTheGhiAmBangChuAiTaiViTri(viTri, nhanGoc.length, chuCoSan);
      }
      return;
    }

    final duLieu = _duLieuTheoTheGhiAm[soThe];
    if (duLieu == null) {
      // Không còn dữ liệu (đã bị xoá vĩnh viễn từ trước) — báo rõ lý do,
      // đừng im lặng làm người dùng tưởng app bị treo.
      if (baoLoi) {
        _bao(Ch.theGhiAmDaBiXoaVinhVien(ngonNguHienTai.value, soThe));
      }
      return;
    }

    // (YÊU CẦU MỚI) Đã biết trước hôm nay chạm trần hạn mức âm thanh — chặn
    // ngay từ đây, không đổi nhãn "Đang chuyển" rồi phải lùi lại ngay sau đó.
    final daChamHanMucAmThanh = await doanDaChamHanMucAiHomNay(LoaiHanMucAi.amThanh);
    if (daChamHanMucAmThanh != null) {
      if (baoLoi && mounted) await hienHopThoaiHanMucAi(context, daChamHanMucAmThanh);
      return;
    }

    final viTriGoc = _boDieuKhien.text.indexOf(nhanGoc);
    if (viTriGoc < 0) return; // đã bị xoá/đổi — không có gì để gửi.

    _theGhiAmDangGui.add(soThe);
    final nhanDangChuyen = nhanTheDangChuyen(
        soThe, _thoiLuongTheoTheGhiAm[soThe] ?? Duration.zero);
    _doiNhanTheGhiAm(viTriGoc, nhanGoc.length, nhanDangChuyen);
    if (_boDieuKhien.theGhiAmLoiTamThoi.remove(soThe)) _boDieuKhien.veLai();

    try {
      final chu = await guiGhiAmChoGemini(
        duLieu.bytes,
        duLieu.mime,
        locHallucination: true,
        maNgonNgu: maNgonNguGhiAmChoAi(ngonNguGhiAmHienTai.value, ngonNguHienTai.value),
      );
      if (!mounted) return;
      final viTri = _boDieuKhien.text.indexOf(nhanDangChuyen);
      if (viTri >= 0) {
        _thayTheGhiAmBangChuAiTaiViTri(viTri, nhanDangChuyen.length, chu);
        // Đã có chữ thật — lưu bộ nhớ đệm, và âm thanh/thời lượng từ giờ
        // không cần giữ nữa (không bao giờ phải gửi lại âm thanh cho thẻ
        // này nữa, mọi lần chuyển hoá sau đều lấy từ bộ nhớ đệm).
        _vanBanDaTraVeTheoTheGhiAm[soThe] = chu;
        _duLieuTheoTheGhiAm.remove(soThe);
        _thoiLuongTheoTheGhiAm.remove(soThe);
      }
    } catch (e) {
      if (e is LoiHanMucAi) await ghiNhoDaChamHanMucAi(e.loai, e.thongDiep);
      if (mounted) {
        final viTri = _boDieuKhien.text.indexOf(nhanDangChuyen);
        if (viTri >= 0) {
          _doiNhanTheGhiAm(viTri, nhanDangChuyen.length, nhanGoc);
          _boDieuKhien.theGhiAmLoiTamThoi.add(soThe);
          _boDieuKhien.veLai();
        }
      }
      if (e is LoiHanMucAi) {
        if (baoLoi && mounted) await hienHopThoaiHanMucAi(context, e.thongDiep);
      } else if (baoLoi) {
        _bao(Ch.theGhiAmLoiGui(ngonNguHienTai.value, soThe, '$e'));
      }
    } finally {
      _theGhiAmDangGui.remove(soThe);
    }
  }

  /// Nút "Tạo văn bản" (thủ công) trong trình ghi âm — gửi TẤT CẢ thẻ đã
  /// ghi xong mà chưa gửi (bỏ qua thẻ đang được gửi ngầm xử lý), thay từ
  /// CUỐI VĂN BẢN VỀ ĐẦU để vị trí các thẻ chưa xử lý luôn còn đúng.
  Future<void> _taoVanBanTuTatCaTheGhiAm() async {
    final vanBan = _boDieuKhien.text;
    final cacKhop = reTheGhiAmHoanChinh.allMatches(vanBan).toList();
    if (cacKhop.isEmpty) {
      _bao(Ch.khongCoTheGhiAmNaoDeGui(ngonNguHienTai.value));
      return;
    }
    for (final khop in cacKhop.reversed) {
      final soThe = int.parse(khop.group(1)!);
      await _guiVaXuLyMotThe(soThe, baoLoi: true);
    }
  }

  /// Bấm vào một thẻ ghi âm ĐÃ XONG (hoặc đang lỗi tạm thời) — menu 3 lựa
  /// chọn, y hệt cơ chế menu của lỗi chính tả (`_khiBamTuSai`).
  Future<void> _khiBamTheGhiAmHoanChinh(int soThe, Offset viTriManHinh) async {
    final chon = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'tatCa',
          child: Row(children: [
            Icon(Icons.transcribe, size: 18, color: Color(0xFF5F6368)),
            SizedBox(width: 10),
            Text(Ch.chuyenHoaTatCaTheGhiAm(ngonNguHienTai.value)),
          ]),
        ),
        PopupMenuItem(
          value: 'moiThe',
          child: Row(children: [
            Icon(Icons.graphic_eq, size: 18, color: Color(0xFF5F6368)),
            SizedBox(width: 10),
            Text(Ch.chiChuyenHoaTheNay(ngonNguHienTai.value)),
          ]),
        ),
        PopupMenuItem(
          value: 'nghe',
          child: Row(children: [
            Icon(Icons.play_circle_outline, size: 18, color: Color(0xFF5F6368)),
            SizedBox(width: 10),
            Text(Ch.ngheBanGhiAmNay(ngonNguHienTai.value)),
          ]),
        ),
        PopupMenuItem(
          value: 'xoa',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
            const SizedBox(width: 10),
            Text(Ch.xoaTheGhiAmNay(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
          ]),
        ),
        PopupMenuItem(
          value: 'doiViTri',
          child: Row(children: [
            Icon(Icons.swap_vert, size: 18, color: Color(0xFF5F6368)),
            SizedBox(width: 10),
            Text(Ch.thayDoiViTriTheNay(ngonNguHienTai.value)),
          ]),
        ),
      ],
    );
    if (chon == null || !mounted) return;
    switch (chon) {
      case 'tatCa':
        await _taoVanBanTuTatCaTheGhiAm();
      case 'moiThe':
        await _guiVaXuLyMotThe(soThe, baoLoi: true);
      case 'nghe':
        await _ngheLaiGhiAmThe(soThe);
      case 'xoa':
        await _hoiXoaTheGhiAm(soThe);
      case 'doiViTri':
        _batDauDoiViTriTheGhiAm(soThe);
    }
  }

  // --------------------- chọn vị trí mới cho một thẻ ghi âm đã có

  /// Khác `null` nghĩa là đang ở chế độ "Thay đổi vị trí của thẻ này" cho
  /// đúng thẻ số N đó — tái dùng chung cờ ẩn-hết-thanh-công-cụ
  /// [_dangChonViTriChenFile] với luồng "chèn kết quả AI" (cùng bản chất:
  /// chỉ còn khung soạn thảo để di chuyển con trỏ + một thanh riêng ở đáy),
  /// chỉ khác phần NỘI DUNG/HÀNH ĐỘNG của thanh đó — xem
  /// `_xayThanhChonViTriChenFile`.
  int? _soTheDangDoiViTri;

  /// Nhớ lại đúng trạng thái ghi âm (đang ghi tiếp, hay đang tạm dừng)
  /// NGAY TRƯỚC khi "Phím 9" ép tạm dừng để chọn vị trí cho thẻ đang ghi dở
  /// — xong hoặc huỷ thì trả lại ĐÚNG trạng thái cũ đó (xem
  /// `_batDauDoiViTriTheDangGhi`/`_ketThucCheDoDoiViTriThe`). `null` = lần
  /// "Thay đổi vị trí" này KHÔNG áp dụng cho thẻ đang ghi (áp dụng cho một
  /// thẻ đã ghi xong từ lâu, không cần khôi phục gì).
  bool? _dangGhiTruocKhiDoiViTri;

  /// Mục "Thay đổi vị trí của thẻ này" bấm từ MENU của một thẻ đã ghi
  /// xong — không đụng gì tới trạng thái ghi âm (thẻ đó không còn "đang
  /// ghi" nữa).
  void _batDauDoiViTriTheGhiAm(int soThe) {
    setState(() {
      _soTheDangDoiViTri = soThe;
      _dangGhiTruocKhiDoiViTri = null;
      _dangChonViTriChenFile = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
    });
  }

  /// "Phím 9" trong bảng điều khiển — CHO THẺ ĐANG GHI DỞ. Nếu thẻ còn đang
  /// ghi thật (chưa tạm dừng), tự tạm dừng trước rồi mới vào chế độ chọn vị
  /// trí (báo nhanh giữa màn hình để người dùng biết vì sao đột nhiên ngừng
  /// ghi) — nhớ lại đúng trạng thái đó để khôi phục khi xong/huỷ. Thẻ đã
  /// đang tạm dừng sẵn thì không cần làm gì thêm, cứ vào thẳng.
  Future<void> _batDauDoiViTriTheDangGhi() async {
    final soThe = _soTheGhiAmDangGhi;
    if (soThe == null) return;
    final dangGhiThat = !_theGhiAmDangTamDung;
    if (dangGhiThat) {
      await _tamDungTheGhiAmHienTai();
      if (!mounted) return;
      hienThongBaoGiua(
          context, Ch.daTamDungGhiAmXinMoiChonViTri(ngonNguHienTai.value));
    }
    setState(() {
      _soTheDangDoiViTri = soThe;
      _dangGhiTruocKhiDoiViTri = dangGhiThat;
      _dangChonViTriChenFile = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
    });
  }

  /// Dọn trạng thái chế độ "Thay đổi vị trí" — dùng chung cho cả hai lối ra
  /// (xong hay huỷ): tắt cờ, và nếu đang áp dụng cho thẻ ĐANG GHI mà trước
  /// đó đã bị ép tạm dừng, tự ghi tiếp lại đúng như cũ.
  Future<void> _ketThucCheDoDoiViTriThe() async {
    final dangDoiTheDangGhi = _dangGhiTruocKhiDoiViTri != null;
    final canTiepTucGhi = _dangGhiTruocKhiDoiViTri == true;
    setState(() {
      _soTheDangDoiViTri = null;
      _dangGhiTruocKhiDoiViTri = null;
      _dangChonViTriChenFile = false;
    });
    if (canTiepTucGhi && _soTheGhiAmDangGhi != null && _theGhiAmDangTamDung) {
      await _tiepTucTheGhiAmHienTai();
    }
    // "Phím 9" (trong bảng điều khiển ghi âm) đã TỰ ĐÓNG bảng điều khiển
    // trước khi vào chế độ chọn vị trí — người dùng đang ghi dở thì bảng
    // điều khiển đó phải tự hiện lại, xong hay huỷ cũng vậy.
    if (dangDoiTheDangGhi && mounted && _trinhGhiAmMo) {
      _bamNutHienBangDieuKhienGhiAm();
    }
  }

  /// Bấm "Huỷ — Quay lại" ở thanh chọn vị trí (chế độ đổi vị trí thẻ) —
  /// không đụng gì tới văn bản, thẻ vẫn y nguyên chỗ cũ.
  Future<void> _huyDoiViTriThe() => _ketThucCheDoDoiViTriThe();

  /// Bấm "Chuyển tới đây" — tìm lại thẻ hoàn chỉnh mang đúng số
  /// [_soTheDangDoiViTri] (tìm lại TỪ ĐẦU bằng regex thay vì dùng toạ độ đã
  /// chụp sẵn — chắc ăn hơn hẳn nếu có sửa chữ khác xen giữa lúc đang chọn
  /// vị trí), xoá khỏi chỗ cũ rồi chèn lại nguyên văn tại vị trí con trỏ
  /// hiện tại. Con trỏ đang nằm GIỮA một thẻ ghi âm bất kỳ (kể cả chính nó)
  /// thì từ chối, báo lý do — không cho lồng thẻ vào nhau.
  Future<void> _xacNhanDoiViTriThe() async {
    final soThe = _soTheDangDoiViTri;
    if (soThe == null) return;
    final vb = _boDieuKhien.text;
    final dangDoiTheDangGhi = _dangGhiTruocKhiDoiViTri != null;
    int batDau, ketThuc;
    String tokenText;
    if (dangDoiTheDangGhi) {
      // Thẻ đang ghi dở mang token GIỮ CHỖ chung (không đánh số), không
      // khớp được với `reTheGhiAmHoanChinh` (chỉ bắt thẻ đã ghi XONG) —
      // tìm thẳng token giữ chỗ đó.
      final vt = vb.indexOf(tenTokenDangGhiAm);
      if (vt == -1) {
        await _ketThucCheDoDoiViTriThe();
        return;
      }
      batDau = vt;
      ketThuc = vt + tenTokenDangGhiAm.length;
      tokenText = tenTokenDangGhiAm;
    } else {
      Match? khop;
      for (final m in reTheGhiAmHoanChinh.allMatches(vb)) {
        if (m.group(1) == soThe.toString()) {
          khop = m;
          break;
        }
      }
      if (khop == null) {
        // Thẻ không còn tồn tại nữa (đã bị xoá/chuyển hoá trong lúc đang
        // chọn vị trí) — không còn gì để chuyển, thoát chế độ luôn.
        await _ketThucCheDoDoiViTriThe();
        return;
      }
      batDau = khop.start;
      ketThuc = khop.end;
      tokenText = vb.substring(batDau, ketThuc);
    }
    final sel = _boDieuKhien.selection;
    final vt = sel.isValid ? sel.start : vb.length;

    if (viTriNamGiuaThe(vt, timCacVungTheGhiAm(vb))) {
      hienThongBaoGiua(
          context, Ch.khongTheDatTheGhiAmVaoGiuaMotTheKhac(ngonNguHienTai.value));
      return;
    }

    _luuDiemMoc();
    var vbMoi = vb.replaceRange(batDau, ketThuc, '');
    _dieuChinhLoiChinhTaSauKhiSua(batDau, ketThuc - batDau, 0);
    _dieuChinhVungToanVanSauKhiSua(batDau, ketThuc - batDau, 0);
    final vtSauXoa =
        vt > ketThuc ? vt - (ketThuc - batDau) : (vt >= batDau ? batDau : vt);

    vbMoi = vbMoi.replaceRange(vtSauXoa, vtSauXoa, tokenText);
    _dieuChinhLoiChinhTaSauKhiSua(vtSauXoa, 0, tokenText.length);
    _dieuChinhVungToanVanSauKhiSua(vtSauXoa, 0, tokenText.length);
    if (dangDoiTheDangGhi) {
      // `_dieuChinhVungToanVanSauKhiSua` ở bước XOÁ phía trên đã null hoá
      // `_viTriTokenDangGhiThe` (xoá trọn token là một trong hai trường hợp
      // nó tự ngừng theo dõi) — nhưng ở đây token KHÔNG mất, chỉ dời sang vị
      // trí mới, nên phải tự gán lại, nếu không "Hoàn thành & Chuyển hoá"
      // sau đó sẽ không tìm thấy token nữa (tưởng thẻ đã mất, đứng im mãi).
      _viTriTokenDangGhiThe = vtSauXoa;
    }
    _ghiVaoO(vbMoi, vtSauXoa + tokenText.length);
    _henLuu();

    await _ketThucCheDoDoiViTriThe();
    if (mounted) {
      hienThongBaoGiua(context, Ch.daChuyenTheGhiAmToiViTriMoi(ngonNguHienTai.value, soThe));
    }
  }

  /// Bấm "Nghe bản ghi âm này" — thẻ đã chuyển hoá rồi (đã trả về văn bản,
  /// theo cơ chế giữ trí nhớ: `_vanBanDaTraVeTheoTheGhiAm` và
  /// `_duLieuTheoTheGhiAm` LOẠI TRỪ NHAU, xem `_guiVaXuLyMotThe`) thì bytes
  /// gốc đã bị giải phóng — không còn gì để phát, báo cho người dùng biết
  /// thay vì mở modal trống/lỗi.
  Future<void> _ngheLaiGhiAmThe(int soThe) async {
    // Chặn hẳn tự động gửi ngầm trong suốt lúc modal nghe lại còn mở (kể cả
    // trong lúc còn CHỜ mở, ví dụ nếu nơi gọi đã tự bật cờ này từ trước —
    // xem `_hoanThanhPhatDeNgheLai`) — `finally` đảm bảo luôn tắt lại đúng
    // đắn dù thoát bằng đường nào (return sớm, lỗi, hay chạy hết bình
    // thường), rồi quét lại một lượt cho các thẻ KHÁC có thể đã đủ ngưỡng.
    _dangMoModalNgheLaiGhiAm = true;
    try {
      if (_vanBanDaTraVeTheoTheGhiAm.containsKey(soThe)) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(Ch.khongConBanGhiAm(ngonNguHienTai.value)),
            content: Text(Ch.theDaChuyenHoaRoiKhongConBanGhiAm(ngonNguHienTai.value)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Ch.daHieu(ngonNguHienTai.value)),
              ),
            ],
          ),
        );
        return;
      }
      final duLieu = _duLieuTheoTheGhiAm[soThe];
      if (duLieu == null || !mounted) return;
      final chuyenHoa = await hienModalNgheLaiGhiAm(
        context,
        bytes: duLieu.bytes,
        mime: duLieu.mime,
      );
      if (!mounted) return;
      if (!chuyenHoa) {
        // Đóng modal nghe lại mà KHÔNG bấm "Chuyển hoá..." — thẻ vẫn là
        // "Ghi âm N" y hệt một thẻ đã ghi xong bình thường, chưa gửi AI.
        // ĐÃ SỬA: trước đây không gán gì ở đây nên nhãn to ở AppBar/bảng
        // điều khiển rơi vào nhánh "Đang chuẩn bị…" (chỉ đúng nghĩa trong
        // khoảnh khắc BẮT ĐẦU một thẻ MỚI, không đúng cho trạng thái này)
        // — giờ gán đúng nghĩa: đã ghi xong, còn chờ chuyển hoá tay.
        setState(() => _nhanTrangThaiGhiAmGheDe.value =
            TrangThaiGheDe(LoaiTrangThaiGheDe.daGhiXongChuaChuyen, soThe));
        return;
      }
      // Bấm "Chuyển hoá..." ngay trong modal nghe lại — đóng NGAY cả bảng
      // điều khiển (nếu đang mở) VÀ AppBar trình ghi âm, không đợi gửi AI
      // xong mới đóng — y hệt `_hoanThanhChuyenThanhVanBan` (đóng trước,
      // chuyển ở nền sau).
      _dongBangDieuKhienGhiAmNeuMo();
      if (mounted) setState(() => _trinhGhiAmMo = false);
      _nhanTrangThaiGhiAmGheDe.value = TrangThaiGheDe(LoaiTrangThaiGheDe.dangChuyen, soThe);
      unawaited(_guiVaXuLyMotThe(soThe, baoLoi: true).then((_) {
        if (!mounted) return;
        _nhanTrangThaiGhiAmGheDe.value = TrangThaiGheDe(
            _vanBanDaTraVeTheoTheGhiAm.containsKey(soThe)
                ? LoaiTrangThaiGheDe.daChuyenXong
                : LoaiTrangThaiGheDe.loiKhiChuyen,
            soThe,
          );
      }));
    } finally {
      _dangMoModalNgheLaiGhiAm = false;
      _kiemTraVaGuiNgamTheGhiAmNeuDu(boQuaSoThe: soThe);
    }
  }

  /// Đang có modal "nghe lại" ghi âm mở hay không — trong lúc này TẠM
  /// NGƯNG hẳn việc tự động gửi ngầm cho AI (`_kiemTraVaGuiNgamTheGhiAmNeuDu`),
  /// kể cả cho CHÍNH thẻ đang nghe: người dùng chỉ đang muốn NGHE, không có
  /// nghĩa là cũng muốn nó tự chuyển hoá luôn giữa lúc đang nghe — muốn
  /// chuyển thì tự bấm tay (nút "Chuyển hoá..." ngay trong modal nghe lại,
  /// hoặc bấm sau khi đóng modal). Đóng modal lại thì tự gọi lại
  /// `_kiemTraVaGuiNgamTheGhiAmNeuDu()` một lần để không bỏ sót các thẻ
  /// KHÁC (không phải thẻ đang nghe) đã đủ ngưỡng trong lúc đó.
  bool _dangMoModalNgheLaiGhiAm = false;

  /// Bảng điều khiển ghi âm đang mở hay không — chỉ để nút "Chuyển hoá..."
  /// trong modal nghe lại (mở từ TRONG bảng điều khiển, qua phím 3) biết có
  /// cần đóng thêm route nào bên dưới hay không.
  bool _bangDieuKhienGhiAmDangMo = false;

  /// Số thẻ hiển thị ở đầu Bảng điều khiển ("Bản Ghi âm số N") — CỐ Ý sống
  /// lâu hơn `_soTheGhiAmDangGhi` (cái đó về `null` ngay khi chốt xong):
  /// nút "Hiện bảng điều khiển" phải luôn mở được, kể cả lúc thẻ đã chốt
  /// và đang ở trạng thái đang chuyển/đã chuyển xong/lỗi — xem
  /// `_bamNutHienBangDieuKhienGhiAm`. Cập nhật đúng MỘT chỗ — mỗi lần một
  /// thẻ MỚI bắt đầu ghi (`_batDauMotTheGhiAmMoi`) — cũng chính là lúc
  /// `_DongBanGhiAmSoNhapNhay` trong bảng điều khiển (nếu đang mở) tự nhấp
  /// nháy.
  final ValueNotifier<int> _soTheChoBangDieuKhien = ValueNotifier(0);

  /// Đóng NGAY route dialog của Bảng điều khiển ghi âm nếu đang mở — dùng ở
  /// mọi nơi "đóng hẳn trình ghi âm" (nút tay "Đóng trình ghi âm"/"Xoá bản
  /// này", hay tự động đóng khi chạm giới hạn 10 phút không ai bấm gì) để
  /// không bao giờ để bảng điều khiển bị "mồ côi" — vẫn hiện trên màn hình
  /// dù AppBar trình ghi âm phía sau đã tắt.
  void _dongBangDieuKhienGhiAmNeuMo() {
    if (_bangDieuKhienGhiAmDangMo && mounted) {
      Navigator.of(context).pop();
      _bangDieuKhienGhiAmDangMo = false;
    }
  }

  /// Bấm vào một thẻ ĐANG GỬI ("Đang chuyển N") — chỉ còn một lựa chọn duy
  /// nhất: xoá (có hỏi xác nhận). Yêu cầu gửi đang bay tới Gemini vẫn chạy
  /// tiếp bình thường; khi nó trả lời (thành công hay lỗi), `_guiVaXuLyMotThe`
  /// tìm lại nhãn "Đang chuyển N" không thấy nữa (đã xoá) thì tự bỏ qua —
  /// không cần huỷ tay ở đây.
  Future<void> _khiBamTheDangChuyen(int soThe, Offset viTriManHinh) async {
    final chon = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'nghe',
          child: Row(children: [
            Icon(Icons.play_circle_outline, size: 18, color: Color(0xFF5F6368)),
            SizedBox(width: 10),
            Text(Ch.ngheBanGhiAmNay(ngonNguHienTai.value)),
          ]),
        ),
        PopupMenuItem(
          value: 'xoa',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
            const SizedBox(width: 10),
            Text(Ch.xoaTheGhiAmNay(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
          ]),
        ),
      ],
    );
    if (chon == null || !mounted) return;
    if (chon == 'nghe') {
      await _ngheLaiGhiAmThe(soThe);
      return;
    }
    if (chon != 'xoa' || !mounted) return;
    final dongY = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Ch.xoaTheGhiAm(ngonNguHienTai.value)),
        content: Text(Ch.theDangGuiPhienAmXoaSeBo(ngonNguHienTai.value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Ch.khongGiuLai(ngonNguHienTai.value)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Ch.xoa(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) return;
    final nhan = nhanTheDangChuyen(
        soThe, _thoiLuongTheoTheGhiAm[soThe] ?? Duration.zero);
    final vb = _boDieuKhien.text;
    final viTri = vb.indexOf(nhan);
    if (viTri < 0) return;
    _dieuChinhVungToanVanSauKhiSua(viTri, nhan.length, 0);
    _dieuChinhLoiChinhTaSauKhiSua(viTri, nhan.length, 0);
    final moi = vb.replaceRange(viTri, viTri + nhan.length, '');
    _ghiVaoO(moi, viTri);
    _henLuu();
    _duLieuTheoTheGhiAm.remove(soThe);
    _thoiLuongTheoTheGhiAm.remove(soThe);
    if (_boDieuKhien.theGhiAmLoiTamThoi.remove(soThe)) _boDieuKhien.veLai();
  }

  /// Bấm Backspace/Delete/Xoá chạm vào MỘT HAY NHIỀU thẻ (vùng chọn có thể
  /// phủ chữ thường xen lẫn nhiều thẻ ghi âm cùng lúc) — `ChanSuaGiuaThe` đã
  /// CHẶN lại (không tự xoá) và báo về đây bằng đúng [batDau, ketThuc) đã
  /// GỘP đủ mọi thẻ chồng lấn. Hỏi xác nhận MỘT LẦN cho cả cụm (y hệt cách
  /// xoá qua menu bấm-vào-thẻ khi chỉ có một thẻ), rồi xoá TOÀN BỘ khoảng
  /// đó (chữ thường lẫn mọi thẻ) trong MỘT lần nếu đồng ý — không còn phải
  /// bấm nhiều lần mới xoá hết từng thẻ một.
  Future<void> _khiCanXoaTheTuBanPhim(int batDau, int ketThuc) async {
    if (!mounted) return;
    final vb = _boDieuKhien.text;
    if (ketThuc > vb.length) return;
    final doan = vb.substring(batDau, ketThuc);
    final dsHoanChinh = reTheGhiAmHoanChinh.allMatches(doan).toList();
    final dsDangChuyen = reTheDangChuyen.allMatches(doan).toList();
    final coDangGhi = doan.contains(tenTokenDangGhiAm);
    final soLuongThe = dsHoanChinh.length + dsDangChuyen.length + (coDangGhi ? 1 : 0);
    if (soLuongThe == 0) return; // đã đổi khác đi trong lúc chờ, bỏ qua.

    // "Đang chuyển"/"đang ghi" thì chưa bao giờ có trong bộ nhớ đệm (mất là
    // mất thật) — có bất kỳ thẻ nào thuộc hai loại đó, hoặc một thẻ "Ghi âm
    // N" hoàn chỉnh nhưng CHƯA có cache, là phải hỏi. Toàn bộ thẻ trong
    // khoảng đều đã có cache thì xoá thẳng, không hỏi.
    var coCanHoi = coDangGhi || dsDangChuyen.isNotEmpty;
    if (!coCanHoi) {
      for (final m in dsHoanChinh) {
        if (!_vanBanDaTraVeTheoTheGhiAm.containsKey(int.parse(m.group(1)!))) {
          coCanHoi = true;
          break;
        }
      }
    }

    var dongY = true;
    if (coCanHoi) {
      dongY = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(Ch.xoaTheGhiAm(ngonNguHienTai.value)),
              content: Text(soLuongThe > 1
                  ? Ch.vungChonChuaNhieuTheXoaSeHuyLuon(soLuongThe, ngonNguHienTai.value)
                  : coDangGhi
                      ? Ch.theDangGhiAmXoaSeHuyLuonBanGhiDangThu(ngonNguHienTai.value)
                      : dsDangChuyen.isNotEmpty
                          ? Ch.theDangGuiPhienAmXoaSeBoLuonKetQua(ngonNguHienTai.value)
                          : Ch.theGhiAmSeBiXoaVinhVienChung(ngonNguHienTai.value)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(Ch.khongGiuLai(ngonNguHienTai.value)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(Ch.xoa(ngonNguHienTai.value),
                      style: TextStyle(color: Colors.red.shade600)),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!dongY || !mounted) return;

    if (coDangGhi) {
      // Thẻ đang ghi dở — huỷ luôn bản ghi (không chốt thành thẻ xong).
      _bomDongHoTheGhiAm?.cancel();
      _bomDongHoTheGhiAm = null;
      _dungTheoDoiMucAmGhiAm();
      await ghiAmTheKetThucThe(); // dừng đáy ghi âm, bỏ luôn dữ liệu trả về.
      _soTheGhiAmDangGhi = null;
      _viTriTokenDangGhiThe = null;
      _theGhiAmDangTamDung = false;
      if (!mounted) return;
    }

    final vbHienTai = _boDieuKhien.text;
    if (ketThuc > vbHienTai.length || vbHienTai.substring(batDau, ketThuc) != doan) {
      return; // văn bản đã đổi trong lúc chờ hỏi — đừng xoá nhầm chỗ khác.
    }
    _dieuChinhVungToanVanSauKhiSua(batDau, doan.length, 0);
    _dieuChinhLoiChinhTaSauKhiSua(batDau, doan.length, 0);
    final moi = vbHienTai.replaceRange(batDau, ketThuc, '');
    _ghiVaoO(moi, batDau);
    _henLuu();

    for (final m in dsHoanChinh) {
      final soThe = int.parse(m.group(1)!);
      if (!_vanBanDaTraVeTheoTheGhiAm.containsKey(soThe)) {
        _duLieuTheoTheGhiAm.remove(soThe);
        _thoiLuongTheoTheGhiAm.remove(soThe);
        _theGhiAmDangGui.remove(soThe);
      }
      _boDieuKhien.theGhiAmLoiTamThoi.remove(soThe);
    }
    for (final m in dsDangChuyen) {
      final soThe = int.parse(m.group(1)!);
      _duLieuTheoTheGhiAm.remove(soThe);
      _thoiLuongTheoTheGhiAm.remove(soThe);
      _boDieuKhien.theGhiAmLoiTamThoi.remove(soThe);
      // KHÔNG xoá khỏi `_theGhiAmDangGui` — yêu cầu Gemini có thể vẫn đang
      // bay; để nó tự no-op khi về (không còn tìm thấy nhãn "Đang chuyển").
    }
    _boDieuKhien.veLai();
    if (mounted && _trinhGhiAmMo) setState(() {});
  }

  Future<void> _hoiXoaTheGhiAm(int soThe) async {
    // Đã có trong bộ nhớ đệm (đã chuyển hoá xong) — xoá là mất chữ trên màn
    // hình nhưng hoàn tác (Ctrl+Z) vẫn lấy lại được, nên xoá luôn, không cần
    // hỏi. Chưa có gì trong bộ nhớ đệm — mất là mất thật, phải hỏi trước.
    final coCache = _vanBanDaTraVeTheoTheGhiAm.containsKey(soThe);
    if (!coCache) {
      final dongY = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Ch.xoaTheGhiAm(ngonNguHienTai.value)),
          content: Text(Ch.theGhiAmSeBiXoaVinhVien(ngonNguHienTai.value, soThe)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(Ch.khongGiuLai(ngonNguHienTai.value)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(Ch.xoa(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
            ),
          ],
        ),
      );
      if (dongY != true || !mounted) return;
    }
    final theCanTim = _nhanTheGhiAmHoanChinh(soThe);
    final vb = _boDieuKhien.text;
    final viTri = vb.indexOf(theCanTim);
    if (viTri < 0) return;
    _dieuChinhVungToanVanSauKhiSua(viTri, theCanTim.length, 0);
    _dieuChinhLoiChinhTaSauKhiSua(viTri, theCanTim.length, 0);
    final moi = vb.replaceRange(viTri, viTri + theCanTim.length, '');
    _ghiVaoO(moi, viTri);
    _henLuu();
    if (!coCache) {
      _duLieuTheoTheGhiAm.remove(soThe);
      _thoiLuongTheoTheGhiAm.remove(soThe);
      _theGhiAmDangGui.remove(soThe);
      if (_boDieuKhien.theGhiAmLoiTamThoi.remove(soThe)) _boDieuKhien.veLai();
    }
  }

  bool get _microDungDuocTrenThietBiNay =>
      !(kIsWeb && _thietBiHienTai == ThietBi.iphone);

  /// Thông báo CHẶN GIỮA MÀN HÌNH (không tự mất) khi bấm nút Micro ở iPhone
  /// bản web — y hệt dòng cảnh báo bắt buộc trong kênh chat
  /// (`_hienCanhBaoMicIphoneChat` ở `man_hinh_tro_chuyen.dart`).
  void _hienCanhBaoMicIphone() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(Ch.khongKhaDungTrenIphone(ngonNguHienTai.value)),
        content: Text(Ch.microIphoneKhongKhaDungTrenWebsite(ngonNguHienTai.value)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Ch.daHieu(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
  }

  void _bamNutMicro() {
    if (!_microDungDuocTrenThietBiNay) {
      _hienCanhBaoMicIphone();
      return;
    }
    if (_ghiAmTheDangKhoaMicro) return;
    // Người dùng tự bấm thì ý họ là quyết định cuối cùng — bỏ mọi kế hoạch
    // tự bật lại đang chờ.
    _microNgungDeGo = false;
    _henGoXong?.cancel();

    if (_muonNghe) {
      _tatMicro();
    } else {
      setState(() {
        _muonNghe = true;
        _loi = '';
      });
      _datLaiHenTuTatMicroImLang();
      // Cố ý gọi _batMicro() TRƯỚC: nó chạy đồng bộ tới tận await đầu tiên,
      // chốt xong đoạn tạm còn sót (nếu có) từ lượt nghe trước — rồi mới cho
      // _datNeoTaiConTro() đặt neo/vùng-tạm THẬT cho lượt nghe này. Gọi
      // ngược lại thì _chotCauDangDoc() bên trong _batMicro() sẽ xoá mất
      // ngay vùng đang chọn mà _datNeoTaiConTro() vừa chuẩn bị để đè lên.
      _batMicro();
      _datNeoTaiConTro();
    }
    // (YÊU CẦU MỚI) Bấm nút Micro áp dụng ĐÚNG quy tắc đã dùng cho 4 nút
    // Copy/Cắt/Dán/All: bàn phím ảo đang hiện thì tiếp tục hiện, đang ẩn thì
    // tiếp tục ẩn — không tự bật/tắt ngoài ý muốn — kèm cơ chế tự reset nếu
    // trình duyệt lỡ "liệt" khả năng bật lại bàn phím ảo.
    _giuFocusOChuSauKhiBam();
  }

  /// Bàn phím vật lý bấm đúng phím tắt đang cài (Tab một mình hoặc Ctrl +
  /// một phím — HAI kiểu còn lại, bấm Ctrl/Shift 2 lần liên tiếp, được dò
  /// riêng ở `_khiPhimTatTapDoi` vì cần theo dõi cả lúc BUÔNG phím, không
  /// khớp được ngay lúc bấm xuống) cho MỘT trong hai chức năng (Micro/Ghi
  /// âm) — dùng chung cho cả `_khiPhimTatMicro` và `_khiPhimTatGhiAm`. Trả
  /// về true để chặn phím này lan xuống ô văn bản/trình duyệt.
  bool _khopPhimTat(LuaChonPhimTat lc, KeyEvent event) {
    switch (lc.loai) {
      case 'tab':
        return event.logicalKey == LogicalKeyboardKey.tab &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            !HardwareKeyboard.instance.isShiftPressed &&
            !HardwareKeyboard.instance.isMetaPressed;
      case 'ctrl':
        return HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            event.logicalKey.keyLabel.toUpperCase() == (lc.phim ?? '').toUpperCase();
      // (YÊU CẦU MỚI) Alt + Shift cùng lúc — CHỈ dùng cho "Từ điển nhập
      // liệu nhanh". Phải CHÍNH phím vừa bấm xuống là Alt hoặc Shift (không
      // phải bất kỳ phím nào khác trong lúc đang giữ sẵn cả hai) — tránh
      // kích hoạt lặp lại mỗi khi gõ phím khác trong lúc tình cờ giữ cả Alt
      // và Shift (hiếm nhưng không phải không thể, ví dụ phím tắt khác của
      // hệ điều hành). Khớp đúng lúc phím THỨ HAI trong cặp được bấm xuống,
      // trong khi phím còn lại đã đang được giữ.
      case 'altShift':
        final phim = event.logicalKey;
        final laAltHoacShift = phim == LogicalKeyboardKey.altLeft ||
            phim == LogicalKeyboardKey.altRight ||
            phim == LogicalKeyboardKey.shiftLeft ||
            phim == LogicalKeyboardKey.shiftRight;
        return laAltHoacShift &&
            HardwareKeyboard.instance.isAltPressed &&
            HardwareKeyboard.instance.isShiftPressed &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isMetaPressed;
      default:
        return false;
    }
  }

  /// Bàn phím vật lý bấm đúng phím tắt Micro (Tab/Ctrl+phím — xem
  /// `_khopPhimTat`; kiểu "bấm 2 lần liên tiếp" dò riêng ở
  /// `_khiPhimTatTapDoi`): tắt/mở micro, y hệt bấm nút.
  bool _khiPhimTatMicro(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;

    // Đang có màn hình khác đè lên (Cài đặt, Thư mục, Hướng dẫn...) thì
    // không xử lý ở đây — kẻo đang gõ thử phím tắt trong màn Cài đặt lại vô
    // tình tắt/mở luôn micro của trang soạn thảo bên dưới.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    if (!_khopPhimTat(widget.caiDat.phimTatMicro, event)) return false;
    _bamNutMicro();
    return true;
  }

  /// Bàn phím vật lý bấm đúng phím tắt Ghi âm (mặc định phím Tab một mình):
  /// mở/đóng trình ghi âm, y hệt bấm nút.
  bool _khiPhimTatGhiAm(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    if (!_khopPhimTat(widget.caiDat.phimTatGhiAm, event)) return false;
    unawaited(_bamNutGhiAmThe());
    return true;
  }

  /// (YÊU CẦU MỚI — nhánh thử nghiệm) Bàn phím vật lý bấm đúng phím tắt
  /// "Bộ nhớ tạm để dán văn bản" (mặc định bấm Shift 2 lần — dò riêng ở
  /// `_khiHoanTatTapDoiPhimTat`, y hệt Micro/Ghi âm): ẩn/hiện modal lịch
  /// sử. Không làm gì khi công tắc tổng đang TẮT.
  bool _khiPhimTatBoNhoTam(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;
    if (!widget.caiDat.boNhoTamDanVanBanBat) return false;

    // (SỬA LỖI — nhánh thử nghiệm) Modal lịch sử CHÍNH NÓ đang mở cũng làm
    // "route không phải route hiện tại" (nó nằm trên cùng) — nếu áp dụng
    // điều kiện chặn như mọi phím tắt khác thì bấm phím tắt LẦN HAI (để
    // đóng lại) sẽ bị chặn luôn, phím tắt chỉ mở được mà không đóng được.
    // Bỏ qua điều kiện chặn CHỈ khi chính modal này đang mở — vẫn chặn
    // đúng khi một màn khác (Cài đặt, Thư mục...) đang đè lên.
    if (!_boNhoTamDangMo) {
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return false;
    }

    if (!_khopPhimTat(widget.caiDat.phimTatBoNhoTam, event)) return false;
    _bamPhimTatBoNhoTam();
    return true;
  }

  /// Ẩn/hiện modal lịch sử "Bộ nhớ tạm" — dùng chung cho cả phím tắt (Tab/
  /// Ctrl+phím ở trên, và "bấm 2 lần" ở `_khiHoanTatTapDoiPhimTat`) và nút
  /// toolbar (`_moHopThoaiLichSuBoNhoTam`, bấm nút thì luôn MỞ — chỉ phím
  /// tắt mới cần "ẩn LẠI nếu đang mở").
  void _bamPhimTatBoNhoTam() {
    if (_boNhoTamDangMo) {
      Navigator.of(context).pop();
    } else {
      _moHopThoaiLichSuBoNhoTam();
    }
  }

  /// `true` trong lúc modal lịch sử "Bộ nhớ tạm" đang hiện — xem
  /// `_bamPhimTatBoNhoTam`/`_moHopThoaiLichSuBoNhoTam`.
  bool _boNhoTamDangMo = false;

  Future<void> _moHopThoaiLichSuBoNhoTam() async {
    if (!widget.caiDat.boNhoTamDanVanBanBat || _boNhoTamDangMo) return;
    _boNhoTamDangMo = true;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => _HopThoaiLichSuBoNhoTam(
        caiDat: widget.caiDat,
        khiChonDong: (i) {
          final doan = BoNhoTamDanVanBan.lichSu[i];
          if (doan == null) return;
          final goi = BoNhoTamDanVanBan.dinhDang[i];
          Navigator.of(dialogCtx).pop();
          _danTuBoNhoTam(doan, dinhDangGoi: goi);
        },
      ),
    );
    _boNhoTamDangMo = false;
  }

  /// Dán một dòng từ "Bộ nhớ tạm để dán văn bản" (hoặc, dùng lại nguyên
  /// văn cho "Từ điển nhập liệu nhanh" — chỉ khác [thongBao]) vào đúng vị
  /// trí con trỏ — y hệt lõi của `_phimAoPaste`, bỏ phần đọc/khôi phục định
  /// dạng HTML vì cả hai nguồn đều chỉ lưu CHUỖI THÔ (không kèm gói định
  /// dạng).
  void _danTuBoNhoTam(
    String chenGoc, {
    String thongBao = 'Đã dán văn bản từ Bộ nhớ tạm',
    String? dinhDangGoi,
  }) {
    var chen = chenGoc;
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) return;
    final vb = _boDieuKhien.text;
    final batDau = chon.start, ketThuc = chon.end;
    final theChongLan = _theGhiAmChongLanMotPhan(batDau, ketThuc);
    if (theChongLan != null) {
      _khiCanXoaTheTuBanPhim(theChongLan.$1, theChongLan.$2);
      return;
    }
    final dangBatTuDongThut = widget.caiDat.tuDongThutDauDong;
    final coTheXoaCachDau = dangBatTuDongThut && batDau > 0 && vb[batDau - 1] == ' ';
    if (coTheXoaCachDau) {
      chen = chen.replaceFirst(RegExp(r'^ +'), '');
      if (chen.isEmpty) return;
    }
    // Số ký tự (dấu cách) đã bị cắt khỏi ĐẦU đoạn dán — [chenGoc] vẫn giữ
    // NGUYÊN để xác minh gói định dạng (đóng gói theo đúng đoạn ĐẦY ĐỦ chưa
    // cắt); vùng định dạng rút ra được sẽ tự lùi lại đúng số này ở
    // `_themVungDinhDangTuDs` — xem giải thích đầy đủ ở `_phimAoPaste`.
    final soCachBiXoa = chenGoc.length - chen.length;
    _henRanhGioiGoTay?.cancel();
    _dangTrongDotGoTay = false;
    if (dangBatTuDongThut) _tamNgungTuDongThutDauDong = true;
    final moi = vb.replaceRange(batDau, ketThuc, chen);
    _boDieuKhien.value = TextEditingValue(
      text: moi,
      selection: TextSelection.collapsed(offset: batDau + chen.length),
    );
    if (dangBatTuDongThut) _tamNgungTuDongThutDauDong = false;
    if (dinhDangGoi != null) {
      setState(() =>
          _apDungGoiDinhDangTuClipboard(dinhDangGoi, chenGoc, batDau, boQuaDau: soCachBiXoa));
    }
    _giuFocusOChuSauKhiBam();
    _cuonToiConTroNeuCan();
    // (YÊU CẦU MỚI) Nhấp nháy nền 3 giây đúng đoạn vừa dán — giúp người
    // dùng dễ thấy đoạn nào vừa được chèn vào.
    _batNhapNhayVungVuaDanTu(batDau, batDau + chen.length);
    if (mounted) hienThongBaoGiua(context, thongBao, ganTren: true);
  }

  // ------------------------------------------- "Từ điển nhập liệu nhanh"

  /// Bàn phím vật lý bấm đúng phím tắt "Từ điển nhập liệu nhanh" (mặc định
  /// Alt + Shift) — ẩn/hiện bảng 26 dòng, y hệt `_khiPhimTatBoNhoTam`.
  bool _khiPhimTatTuDienNhapLieuNhanh(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;
    if (!_tuDienNhapLieuNhanhBatKyNguon) return false;

    // Xem giải thích ở `_khiPhimTatBoNhoTam` — cùng lý do, cùng cách sửa
    // (modal CHÍNH NÓ đang mở không bị tính là "route khác đè lên").
    if (!_tuDienNhapLieuNhanhDangMo) {
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return false;
    }

    if (!_khopPhimTat(widget.caiDat.phimTatTuDienNhapLieuNhanh, event)) return false;
    _bamPhimTatTuDienNhapLieuNhanh();
    return true;
  }

  /// Ẩn/hiện bảng "Từ điển nhập liệu nhanh" — dùng chung cho cả phím tắt và
  /// nút toolbar (`_moHopThoaiTuDienNhapLieuNhanh`, bấm nút thì luôn MỞ —
  /// chỉ phím tắt mới cần "ẩn LẠI nếu đang mở").
  void _bamPhimTatTuDienNhapLieuNhanh() {
    if (_tuDienNhapLieuNhanhDangMo) {
      Navigator.of(context).pop();
    } else {
      _moHopThoaiTuDienNhapLieuNhanh();
    }
  }

  /// `true` trong lúc bảng "Từ điển nhập liệu nhanh" đang hiện.
  bool _tuDienNhapLieuNhanhDangMo = false;

  /// (YÊU CẦU MỚI — 2 bộ nhớ từ điển) Bật theo BẤT KỲ bộ nhớ nào (Nội bộ
  /// HOẶC Đám mây) — nút toolbar/phím tắt chỉ cần BIẾT có hiện/dùng được
  /// bảng 26 dòng hay không, không cần biết đang dùng đúng bộ nào (xem
  /// `_NguonTuDienNhanh` cho phần đọc/ghi đúng bộ).
  bool get _tuDienNhapLieuNhanhBatKyNguon =>
      widget.caiDat.tuDienNhapLieuNhanhBat || (TuDienNhapLieuNhanhDamMay.dungChung?.bat ?? false);

  Future<void> _moHopThoaiTuDienNhapLieuNhanh() async {
    if (!_tuDienNhapLieuNhanhBatKyNguon || _tuDienNhapLieuNhanhDangMo) return;
    _tuDienNhapLieuNhanhDangMo = true;
    final nguon = _NguonTuDienNhanh.hienHanh(widget.caiDat);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => _HopThoaiTuDienNhapLieuNhanh(
        caiDat: widget.caiDat,
        nguon: nguon,
        khiChonDong: (i) {
          final doan = nguon.dong(i);
          Navigator.of(dialogCtx).pop();
          if (doan.trim().isEmpty) return;
          widget.caiDat.ghiNhanGanDayTuDienNhapLieuNhanh(i);
          // (YÊU CẦU MỚI) Dán kèm định dạng (nếu dòng này có) — y hệt cách
          // "Bộ nhớ tạm để dán văn bản" đang làm, đóng gói lại qua
          // `macGoiDinhDang` (CÙNG khuôn `_apDungGoiDinhDangTuClipboard` bên
          // dưới `_danTuBoNhoTam` đang đọc).
          final vung = nguon.dinhDang(i);
          final goi = vung.isEmpty ? null : macGoiDinhDang(doan, vung);
          _danTuBoNhoTam(
            doan,
            thongBao: 'Đã dán văn bản từ Từ điển nhập liệu nhanh',
            dinhDangGoi: goi,
          );
        },
      ),
    );
    _tuDienNhapLieuNhanhDangMo = false;
  }

  // ---------------------------------------- phím tắt "bấm 2 lần liên tiếp"

  /// Bộ dò dùng chung (xem `TheoDoiTapDoiPhim`) — trạng thái riêng của
  /// hai phím tắt TOÀN CỤC (Micro/Ghi âm), độc lập với bộ dò cục bộ bên
  /// trong bảng điều khiển ghi âm (`_BangDieuKhienGhiAm` tự có bộ riêng).
  late final _theoDoiTapDoi = TheoDoiTapDoiPhim(khiTapDoi: _khiHoanTatTapDoiPhimTat);

  /// Bọc `_theoDoiTapDoi.xuLy` — thêm điều kiện "không có màn hình khác đè
  /// lên" (Cài đặt, bảng điều khiển ghi âm...) trước khi thật sự kích hoạt,
  /// y hệt hai hàm `_khiPhimTat...` kia. Không chặn phím nào (luôn trả về
  /// false) — chỉ quan sát.
  bool _khiPhimTatTapDoi(KeyEvent event) {
    if (!mounted) return false;
    _theoDoiTapDoi.xuLy(event);
    return false;
  }

  /// Vừa hoàn tất một lượt "bấm 2 lần liên tiếp" đúng [loai] ('ctrlDup' hoặc
  /// 'shiftDup') — xem chức năng nào (Micro/Ghi âm) đang cài đúng kiểu này
  /// thì kích hoạt, y hệt bấm nút. Bỏ qua nếu đang có màn hình khác đè lên
  /// (Cài đặt, bảng điều khiển ghi âm...) — lý do y hệt `_khiPhimTatMicro`/
  /// `_khiPhimTatGhiAm`.
  void _khiHoanTatTapDoiPhimTat(String loai) {
    if (!mounted) return;
    // (SỬA LỖI — nhánh thử nghiệm) Bỏ qua điều kiện chặn khi CHÍNH modal
    // lịch sử "Bộ nhớ tạm" HOẶC bảng "Từ điển nhập liệu nhanh" đang mở —
    // xem giải thích đầy đủ ở `_khiPhimTatBoNhoTam`. Micro/Ghi âm vẫn phải
    // chặn riêng bên dưới (chỉ 2 nhánh đó được bỏ qua, để bấm lại đúng tổ
    // hợp của CHÍNH nó còn tự ẩn/đóng được).
    if (!_boNhoTamDangMo && !_tuDienNhapLieuNhanhDangMo) {
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
    }

    if (widget.caiDat.boNhoTamDanVanBanBat && widget.caiDat.phimTatBoNhoTam.loai == loai) {
      _bamPhimTatBoNhoTam();
    } else if (_tuDienNhapLieuNhanhBatKyNguon &&
        widget.caiDat.phimTatTuDienNhapLieuNhanh.loai == loai) {
      _bamPhimTatTuDienNhapLieuNhanh();
    } else if (!_boNhoTamDangMo &&
        !_tuDienNhapLieuNhanhDangMo &&
        widget.caiDat.phimTatMicro.loai == loai) {
      _bamNutMicro();
    } else if (!_boNhoTamDangMo &&
        !_tuDienNhapLieuNhanhDangMo &&
        widget.caiDat.phimTatGhiAm.loai == loai) {
      unawaited(_bamNutGhiAmThe());
    }
  }

  /// Ctrl + Z (Lùi lại) và Ctrl + Shift + Z (Tiến tới) — cố định, không cho
  /// người dùng đổi (khác phím tắt micro, có thể tuỳ chỉnh trong Cài đặt).
  ///
  /// Chỉ còn lo trường hợp Ô SOẠN THẢO KHÔNG giữ tiêu điểm (bấm ra ngoài, hay
  /// đang ở ô tên bài) — lúc ô văn bản GIỮ tiêu điểm, một `Shortcuts` khai
  /// báo ngay trên nó (xem `build`) đã chiếm chắc chắn tổ hợp phím này rồi,
  /// tầng nghe toàn cục ở đây phải nhường, không thì có thể gọi trùng
  /// `_lui()`/`_toi()` hai lần cho cùng một lần bấm phím.
  bool _khiPhimTatLuiTien(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;
    if (_oChu.hasFocus) return false;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    if (!HardwareKeyboard.instance.isControlPressed) return false;
    if (event.logicalKey != LogicalKeyboardKey.keyZ) return false;

    if (HardwareKeyboard.instance.isShiftPressed) {
      if (_lichSuToi.isNotEmpty) _toi();
    } else {
      if (_lichSuLui.isNotEmpty) _lui();
    }
    return true;
  }

  void _khiDoiMucAm(double muc) {
    if (!mounted) return;
    // Mức âm Android trả về nằm khoảng -2 đến 10. Ép về 0..1 cho dễ vẽ.
    final chuan = ((muc + 2) / 12).clamp(0.0, 1.0);
    for (var i = 0; i < _songAm.length - 1; i++) {
      _songAm[i] = _songAm[i + 1];
    }
    _songAm[_songAm.length - 1] = chuan;
    _songAmTick.value++; // chỉ báo riêng ThanhCongCu vẽ lại, xem chú thích.
  }

  // ------------------------------------------------------- chèn chữ vào chỗ

  void _datNeoTaiConTro() {
    final chon = _boDieuKhien.selection;
    if (chon.isValid && !chon.isCollapsed) {
      // Đang chọn (tô đậm) một vùng — để giọng nói ĐÈ LÊN đúng vùng đó, y
      // hệt cách gõ tay đè lên vùng đang chọn. Đặt neo ở đầu vùng và coi
      // nguyên đoạn đang chọn là "vùng tạm" — lần nói đầu tiên sẽ tự động
      // thay thế nó qua đúng con đường `_thayVungTamBangGiongNoi` vẫn dùng.
      _neo = chon.start;
      _chuTam = _boDieuKhien.text.substring(chon.start, chon.end);
    } else {
      _neo = chon.isValid ? chon.end : _boDieuKhien.text.length;
      _chuTam = '';
    }
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];
  }

  /// Coi phần chữ tạm hiện tại là đã xong, và dời neo ra sau nó — đồng thời
  /// mở đường cho một đoạn nói MỚI (rỗng bộ đệm chốt-dần của phiên).
  void _chotCauDangDoc() {
    _neo += _chuTam.length;
    _chuTam = '';
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];
  }

  /// Đoạn chữ tạm có còn nguyên vẹn ở đúng chỗ cũ không?
  ///
  /// Đây là lớp chắn quan trọng nhất chống lặp chữ: nếu đoạn cũ không còn ở
  /// đó (người dùng vừa xoá, vừa gõ chèn, hoặc mốc bị lệch vì bộ gõ báo ngược
  /// trạng thái về), ta KHÔNG đè bừa mà đặt lại mốc tại con trỏ.
  bool _vungTamConNguyen(String cu) {
    if (_chuTam.isEmpty) return false;
    if (_neo < 0) return false;
    final het = _neo + _chuTam.length;
    if (het > cu.length) return false;
    return cu.substring(_neo, het) == _chuTam;
  }

  /// Thay đoạn [_neo, _neo + _chuTam.length) bằng [chenVao] — dùng cho MỌI
  /// lần giọng nói chèn hoặc sửa chữ tạm.
  void _thayVungTamBangGiongNoi(String chenVao) {
    final cu = _boDieuKhien.text;
    final het = _neo + _chuTam.length;
    final moi = cu.replaceRange(_neo, het, chenVao);

    // Hợp (OR) định dạng của ký tự NGAY TRƯỚC neo và ký tự NGAY SAU vùng tạm
    // cũ — tính TRƯỚC khi `_dieuChinhLoiChinhTaSauKhiSua` dời/nới các vùng
    // `dinhDang`, vì hàm đó đọc theo toạ độ CŨ. Đây là nguồn MẶC ĐỊNH quyết
    // định định dạng của chữ vừa được giọng nói chèn.
    //
    // YÊU CẦU 2b (đường GIỌNG NÓI — y hệt đường gõ tay ở
    // `_apDungChinhSuaNguoiDung`): bộ nhớ đệm đang hoạt động thì thay hẳn
    // "hợp 2 bên".
    final hopMoi = _boNhoDemDangHoatDong
        ? _chuanHoaXungDotTreMuTreChan(_boNhoDem!)
        : _dinhDangHopTaiViTri(_neo, het, cu.length);

    _dieuChinhLoiChinhTaSauKhiSua(
      _neo,
      het - _neo,
      chenVao.length,
      vanBanCu: cu,
      vanBanMoi: moi,
    );
    _dieuChinhVungToanVanSauKhiSua(_neo, het - _neo, chenVao.length);
    if (chenVao.isNotEmpty) {
      _apDinhDangHopChoDoanMoiChen(_neo, _neo + chenVao.length, hopMoi);
      // YÊU CẦU 2c (cờ một lần) — y hệt đường gõ tay: `_ghiVaoO` bên dưới sẽ
      // tự dịch con trỏ theo chữ vừa chèn, không phải người dùng chủ động
      // di chuyển.
      if (_boNhoDemDangHoatDong) _vuaChenKyTuBangBoNhoDem = true;
    }
    // (VIỆC 2, điểm iii/v — đường GIỌNG NÓI) Y hệt đường gõ tay: chữ vừa
    // được giọng nói chèn có thể vừa bị vùng treMu "nuốt" vào — lọc ngay.
    _gioiHanTreMuSauKhiChen(_neo, chenVao.length, moi);

    final viTri = _neo + chenVao.length;
    _ghiVaoO(moi, viTri);
    _chuTam = chenVao;
    _chuGanNhat = moi; // Để lần _khiNguoiDungSua tiếp theo không hiểu nhầm.
    _batDauMoDamChamCuoi();
  }

  /// Tách một chuỗi thành danh sách từ theo khoảng trắng, bỏ khoảng trắng
  /// thừa hai đầu — dùng cho toàn bộ cơ chế chốt-dần/tìm-điểm-nối bên dưới.
  static List<String> _tachTu(String s) {
    final t = s.trim();
    if (t.isEmpty) return const [];
    return t.split(RegExp(r'\s+'));
  }

  /// Chuẩn hoá MỘT từ để so khớp NỚI LỎNG: chữ thường, bỏ dấu câu cơ bản
  /// dính ở cuối từ. Dùng riêng cho bước "tìm điểm nối" (mục D) — không dùng
  /// cho bước so tiền tố ổn định (mục C), vốn cần khớp CHÍNH XÁC.
  static String _chuanHoaSoKhopTho(String tu) =>
      tu.toLowerCase().replaceAll(RegExp(r'[.,!?;:]+$'), '');

  static bool _tuKhopTho(String a, String b) =>
      _chuanHoaSoKhopTho(a) == _chuanHoaSoKhopTho(b);

  /// Độ dài tiền tố chung (khớp CHÍNH XÁC từng từ) giữa hai danh sách từ —
  /// dùng để phát hiện phần nào của partial mới đã "ổn định" qua hai lần cập
  /// nhật liên tiếp (mục C).
  static int _doDaiTienToChung(List<String> a, List<String> b) {
    final n = a.length < b.length ? a.length : b.length;
    var i = 0;
    while (i < n && a[i] == b[i]) {
      i++;
    }
    return i;
  }

  /// [partialMoi] có bắt đầu bằng ĐÚNG (nới lỏng) toàn bộ [_tuDaChotTrongPhien]
  /// hay không — đây là điều kiện để coi partial mới là "cộng dồn bình
  /// thường" từ đầu phiên như mọi khi (mục C), thay vì một lượt bộ nhận dạng
  /// "quên" ngữ cảnh và chỉ trả phần mới (mục D).
  static bool _batDauBangPhanDaChot(
    List<String> partialMoi,
    List<String> daChot,
  ) {
    if (partialMoi.length < daChot.length) return false;
    for (var i = 0; i < daChot.length; i++) {
      if (!_tuKhopTho(partialMoi[i], daChot[i])) return false;
    }
    return true;
  }

  /// Thuật toán "tìm điểm nối" (mục D): thử N = 6..1 từ CUỐI CÙNG của
  /// [_tuDaChotTrongPhien], xem [partialMoi] có BẮT ĐẦU đúng bằng N từ đó hay
  /// không (so khớp nới lỏng). Thử N LỚN NHẤT trước (thay vì tăng dần từ 1)
  /// để ưu tiên điểm nối CHẮC CHẮN nhất — một từ đơn lẻ trùng ngẫu nhiên (ví
  /// dụ "và", "là") dễ khớp giả ở N=1, nhưng khó khớp giả hơn nhiều khi phải
  /// khớp liền một mạch 4-6 từ.
  ///
  /// Trả về:
  /// - `null`  : không tìm được điểm nối nào — coi `partialMoi` là nội dung
  ///             MỚI hoàn toàn, không liên quan phần đã chốt (D.5).
  /// - `[]`    : `partialMoi` đúng NGUYÊN VĂN là N từ cuối đã chốt, không có
  ///             gì thêm — nhân đôi thuần tuý, phải bỏ qua hoàn toàn (D.4).
  /// - khác    : phần từ MỚI thực sự nằm SAU điểm nối (D.3).
  ///
  /// Nhận [daChot] làm THAM SỐ (thay vì luôn đọc thẳng `_tuDaChotTrongPhien`)
  /// để một chỗ logic này dùng được cho CẢ hai việc: tìm điểm nối BÊN TRONG
  /// một phiên (gọi qua `_timDiemNoi` bên dưới, truyền `_tuDaChotTrongPhien`)
  /// VÀ tìm điểm nối QUA RANH GIỚI PHIÊN ở LỚP 2 của `_khiCoChu` (truyền
  /// `_tuVuaChotGanRanhGioiPhien`) — tránh viết một bản sao thứ hai dễ lệch.
  static List<String>? _timDiemNoiTrong(
    List<String> daChot,
    List<String> partialMoi,
  ) {
    final soDaChot = daChot.length;
    final maxN = soDaChot < 6 ? soDaChot : 6;
    for (var n = maxN; n >= 1; n--) {
      if (partialMoi.length < n) continue;
      final duoiDaChot = daChot.sublist(soDaChot - n);
      var khop = true;
      for (var i = 0; i < n; i++) {
        if (!_tuKhopTho(partialMoi[i], duoiDaChot[i])) {
          khop = false;
          break;
        }
      }
      if (khop) {
        if (partialMoi.length == n) return const [];
        return partialMoi.sublist(n);
      }
    }
    return null;
  }

  List<String>? _timDiemNoi(List<String> partialMoi) =>
      _timDiemNoiTrong(_tuDaChotTrongPhien, partialMoi);

  /// (RACE CONDITION KHI CHUYỂN PHIÊN — LỚP 2) Chụp lại tối đa 20 từ CUỐI
  /// CÙNG của `_tuDaChotTrongPhien` NGAY TRƯỚC KHI nó bị xoá rỗng lúc chuyển
  /// phiên, và cho bản chụp đó sống tối đa 4 giây. Gọi ở MỌI điểm thật sự bắt
  /// đầu/kết thúc một phiên nghe (không gọi ở những chỗ `_tuDaChotTrongPhien`
  /// chỉ đơn thuần được CHỐT xong trong lúc phiên vẫn tiếp tục).
  void _luuBoDemRanhGioiPhien() {
    if (_tuDaChotTrongPhien.isEmpty) return;
    final n = _tuDaChotTrongPhien.length;
    _tuVuaChotGanRanhGioiPhien =
        List<String>.from(n <= 20 ? _tuDaChotTrongPhien : _tuDaChotTrongPhien.sublist(n - 20));
    _henHetHanRanhGioiPhien?.cancel();
    _henHetHanRanhGioiPhien = Timer(const Duration(seconds: 4), () {
      if (_tuVuaChotGanRanhGioiPhien.isEmpty) return;
      _tuVuaChotGanRanhGioiPhien = [];
    });
  }

  void _khiCoChu(dynamic ketQua, int idPhien) {
    var noi = (ketQua.recognizedWords as String? ?? '').trim();
    final xong = ketQua.finalResult as bool? ?? false;

    // Người dùng vừa gõ phím giữa chừng: chữ đã hiện ra phải nằm im. Nuốt hết
    // phần còn lại của câu này, chờ câu mới.
    if (_boQuaCauNay) {
      if (xong) _boQuaCauNay = false;
      return;
    }
    if (noi.isEmpty) return;

    // Chrome trên Android (web) không gửi `recognizedWords` là "toàn bộ
    // utterance tính từ đầu, sạch sẽ" như speech_to_text NATIVE vẫn làm —
    // nó CỘNG DỒN vô hạn, ghép thêm nội dung mới vào đuôi của TOÀN BỘ raw
    // đã gửi ở lần gọi trước (kể cả những đoạn đã lặp/im ắng), nên chuỗi cứ
    // phình to dần qua mỗi lần callback (không có mốc chữ hoa hay dấu hiệu
    // gì cố định để nhận ra — quan sát thực tế cho thấy raw LUÔN bắt đầu
    // đúng bằng raw của lần gọi ngay trước, chỉ có phần ĐUÔI đổi). Cách sửa
    // đúng: TRỪ ĐI phần raw đã thấy ở lần gọi trước, chỉ giữ lại đúng phần
    // ĐUÔI MỚI — rồi đưa ĐÚNG phần đuôi đó (không phải raw đầy đủ) vào
    // thuật toán "chốt dần + tìm điểm nối" bên dưới, y hệt như no đang xử
    // lý một partial bình thường. Phần đuôi mới tự nó cũng tăng dần một
    // cách sạch (xem log thực tế), nên thuật toán sẵn có xử lý đúng mà
    // không cần sửa gì thêm. CHỈ áp dụng cho web + Android — PC không có
    // lỗi này, Android/iOS gốc không đụng Web Speech API nên cũng không có.
    if (kIsWeb && _thietBiHienTai == ThietBi.android) {
      final raw = noi;
      if (raw.startsWith(_rawTichLuyChromeAndroid)) {
        noi = raw.substring(_rawTichLuyChromeAndroid.length).trim();
      }
      // else: raw không còn khớp tiền tố đã theo dõi (ví dụ trình duyệt vừa
      // âm thầm khởi động lại bộ đệm) — coi nguyên `noi` hiện tại là nội
      // dung mới, an toàn hơn là cố trừ nhầm.
      _rawTichLuyChromeAndroid = raw;
      if (noi.isEmpty) return;
    }

    final cu = _boDieuKhien.text;

    // Không tin vào mốc suông. Đoạn tạm không còn nguyên thì bắt đầu lại từ
    // chỗ con trỏ, coi như đây là câu mới — rỗng luôn bộ đệm chốt-dần, vì nó
    // gắn với đúng đoạn văn bản vừa mất hiệu lực này.
    if (!_vungTamConNguyen(cu)) {
      final chon = _boDieuKhien.selection;
      _neo = chon.isValid ? chon.end : cu.length;
      if (_neo > cu.length) _neo = cu.length;
      if (_neo < 0) _neo = 0;
      _chuTam = '';
      _tuDaChotTrongPhien = [];
      _partialTruocDo = [];
    }

    var tuMoi = _tachTu(noi);
    if (tuMoi.isEmpty) return;

    // (RACE CONDITION KHI CHUYỂN PHIÊN — LỚP 2) Đây là PARTIAL ĐẦU TIÊN của
    // một đoạn nói mới (`_tuDaChotTrongPhien` đang rỗng) VÀ vẫn còn "đệm
    // chống nhân đôi" của phiên vừa đóng — so partial này với đuôi đệm đó,
    // dùng LẠI ĐÚNG thuật toán tìm-điểm-nối (`_timDiemNoiTrong`), coi đệm như
    // một "đã chốt ảo". Chỉ ảnh hưởng nội dung SẮP chèn cho phiên mới, KHÔNG
    // đụng gì tới chữ đã nằm sẵn trong tài liệu của phiên trước.
    if (_tuDaChotTrongPhien.isEmpty && _tuVuaChotGanRanhGioiPhien.isNotEmpty) {
      final ketQuaNoiRanhGioi = _timDiemNoiTrong(_tuVuaChotGanRanhGioiPhien, tuMoi);
      if (ketQuaNoiRanhGioi == null) {
        // PARTIAL không trùng đệm ranh giới phiên, coi là nội dung thật.
      } else if (ketQuaNoiRanhGioi.isEmpty) {
        // PARTIAL trùng NGUYÊN VĂN đuôi đã chốt của phiên trước — nhân đôi
        // qua ranh giới phiên, bỏ qua hoàn toàn.
        _henHetHanRanhGioiPhien?.cancel();
        _tuVuaChotGanRanhGioiPhien = [];
        _partialTruocDo = tuMoi;
        return;
      } else {
        // Cắt phần trùng đệm ranh giới phiên, chỉ giữ phần mới.
        tuMoi = ketQuaNoiRanhGioi;
      }
      // Dù khớp hay không, một PARTIAL THẬT (không rỗng) đã được xử lý AN
      // TOÀN qua đúng một lượt so khớp — đệm hết nhiệm vụ, dọn ngay, không
      // đợi hết giờ.
      _henHetHanRanhGioiPhien?.cancel();
      _tuVuaChotGanRanhGioiPhien = [];
      if (tuMoi.isEmpty) return;
    }

    // BƯỚC C/D: xác định danh sách từ sẽ hiển thị (đã chốt + phần mới), theo
    // đúng thiết kế "chốt dần theo độ ổn định" + "tìm điểm nối" — KHÔNG còn
    // đồng hồ thời gian nào can thiệp.
    List<String> hienThi;
    if (_batDauBangPhanDaChot(tuMoi, _tuDaChotTrongPhien)) {
      // Đường bình thường: bộ nhận dạng vẫn cộng dồn đúng từ đầu phiên như
      // mọi khi. So với partial TRƯỚC ĐÓ để tìm tiền tố đã ổn định qua hai
      // lần cập nhật liên tiếp — dài hơn phần đã chốt thì chốt thêm.
      final tienToChung = _doDaiTienToChung(tuMoi, _partialTruocDo);
      if (tienToChung > _tuDaChotTrongPhien.length) {
        _tuDaChotTrongPhien = tuMoi.sublist(0, tienToChung);
      }
      hienThi = tuMoi;
    } else {
      // Bộ nhận dạng có vẻ đang "viết lại" phần đã chốt (ví dụ quên ngữ cảnh
      // sau một khoảng ngập ngừng) — tìm điểm nối với đuôi đã chốt.
      final ketQuaNoi = _timDiemNoi(tuMoi);
      if (ketQuaNoi == null) {
        // D.5: mơ hồ, không tìm được điểm nối nào — chấp nhận rủi ro nhỏ,
        // coi toàn bộ là nội dung MỚI, nối tiếp SAU phần đã chốt (không bao
        // giờ đè/xoá phần đã chốt).
        hienThi = [..._tuDaChotTrongPhien, ...tuMoi];
      } else if (ketQuaNoi.isEmpty) {
        // D.4: nhân đôi thuần tuý — không có gì mới, bỏ qua hoàn toàn, không
        // ghi gì cả (chặn nhân đôi từ gốc).
        _partialTruocDo = tuMoi;
        return;
      } else {
        // D.3: phần thật sự mới nằm sau điểm nối.
        hienThi = [..._tuDaChotTrongPhien, ...ketQuaNoi];
      }
    }

    _partialTruocDo = tuMoi;

    var chen = hienThi.join(' ');
    // Nếu ngay trước neo đã có chữ mà chưa có dấu cách, thêm một dấu cách
    // cho câu mới không dính vào câu cũ.
    if (_neo > 0) {
      final truoc = cu[_neo - 1];
      if (!_laKhoangTrang(truoc)) chen = ' $chen';
    }

    // Luôn giữ NGAY SAU CON TRỎ là một khoảng trắng trong suốt lúc câu còn
    // đang đọc dở — không đợi tới lúc câu chốt xong mới chèn.
    //
    // Đây là cách DUY NHẤT thực sự chặn được lỗi bộ gõ tiếng Việt gộp ngược
    // ('Thành' + phím 's' → 'Thánh'): ứng dụng chỉ biết được người dùng vừa
    // gõ phím gì SAU KHI bàn phím đã xử lý xong. Nếu người dùng gõ phím tạo
    // dấu (Telex: s, f, r, x, j...) NGAY TRONG LÚC câu còn dở — tức là chưa
    // kịp chốt để chèn dấu cách — bộ gõ vẫn nhìn thấy nguyên âm trần ngay
    // trước con trỏ và gộp ngược y hệt. Chèn dấu cách theo TỪNG lần nghe rõ
    // thêm (không đợi chốt) thì tại BẤT KỲ thời điểm nào người dùng gõ phím
    // xen vào, trước con trỏ luôn sẵn một dấu cách, không phải nguyên âm.
    if (chen.isNotEmpty &&
        widget.caiDat.tuDongChenKhoangCach &&
        !_laKhoangTrang(chen[chen.length - 1])) {
      chen = '$chen ';
    }

    // (RACE CONDITION KHI CHUYỂN PHIÊN — LỚP 1) Soát LẠI session-ID NGAY
    // TRƯỚC khi thực sự GHI, không chỉ lúc callback bắt đầu chạy: từ lúc
    // callback này khởi động tới đây có thể đã có một sự kiện CHUYỂN PHIÊN
    // khác chen vào (Android tự ngắt trùng lúc người dùng bấm phím tắt...)
    // và tăng `_phienNgheHienTai` lên rồi. Lệch thì huỷ ghi, không viết gì.
    if (idPhien != _phienNgheHienTai) {
      return;
    }

    if (chen != _chuTam) {
      // _chuTam rỗng nghĩa là đây là mẩu đầu tiên của một đoạn nói MỚI (đoạn
      // trước, nếu có, đã chốt xong và xoá _chuTam ở _chotCauDangDoc) — đúng
      // ranh giới cần lưu một điểm mốc Lùi lại riêng, để một bài dài nói
      // nhiều lần vẫn lùi được từng đoạn một, không gộp chung cả bài thành
      // một bước.
      if (_chuTam.isEmpty) {
        _luuDiemMoc(vanBan: cu, viTriConTro: _neo);
        // (SỬA LỖI thụt đầu dòng không áp dụng cho giọng nói) Y hệt đường gõ
        // tay (`_apDungChinhSuaNguoiDung`): nếu đây là mẩu ĐẦU TIÊN của một
        // đoạn nói mới, VÀ nó đang bắt đầu một dòng còn trống (toàn văn bản
        // rỗng, hoặc ngay sau một dấu xuống dòng) — chèn thẳng số dấu cách
        // thụt đầu dòng vào đúng vị trí con trỏ TRƯỚC khi chèn chữ giọng nói,
        // rồi dời `_neo` qua khỏi nó — để vùng tạm `_chuTam` theo dõi ĐÚNG
        // phần chữ do giọng nói tạo ra, không lẫn với khoảng thụt cố định.
        final vbHienTai = _boDieuKhien.text;
        final thut = _thutDauDongNeuCan(vbHienTai, _neo);
        if (thut.isNotEmpty) {
          final vbVoiThut = vbHienTai.replaceRange(_neo, _neo, thut);
          _dieuChinhLoiChinhTaSauKhiSua(
            _neo,
            0,
            thut.length,
            vanBanCu: vbHienTai,
            vanBanMoi: vbVoiThut,
          );
          _dieuChinhVungToanVanSauKhiSua(_neo, 0, thut.length);
          _neo += thut.length;
          _ghiVaoO(vbVoiThut, _neo);
        }
      }
      _thayVungTamBangGiongNoi(chen);
    }

    // BƯỚC E: một kết quả FINAL coi TOÀN BỘ nội dung hiện có là chốt cứng
    // luôn, không còn "vùng tạm" nào nữa cho tới khi có âm thanh mới. KHÔNG
    // chủ động dừng/mở lại phiên nghe ở đây nữa — phiên nghe được giữ liên
    // tục, chỉ kết thúc bởi Android tự ngắt (`_henBatLai`), người dùng gõ
    // phím, hoặc người dùng dời con trỏ (`_dongBangDoanDangNhay`).
    if (xong) {
      // (Việc 2) Chụp lại đúng vùng vừa chốt TRƯỚC khi `_chotCauDangDoc()`
      // dời `_neo`/xoá `_chuTam` — dùng để dọn cụm từ lặp CHỈ trong đoạn này,
      // không đụng gì tới phần còn lại của bài.
      final batDauDoanVuaChot = _neo;
      final doDaiDoanVuaChot = _chuTam.length;
      _chotCauDangDoc();
      _donCumTuLapLienTiepSauKhiChot(batDauDoanVuaChot, doDaiDoanVuaChot);
      _luuVanBan();
      _lenLichKiemTraChinhTa();
    }
  }

  /// (VIỆC 2 — lớp an toàn) Sau khi một đoạn giọng nói vừa được CHỐT CỨNG,
  /// dọn MỘT cụm từ (≥2 từ) bị lặp lại NGAY LIỀN NHAU, cách nhau chỉ đúng một
  /// khoảng trắng, nếu có — ví dụ "chào các bạn chào các bạn" → "chào các
  /// bạn". CHỈ quét đúng [batDau, batDau+doDai) — đoạn VỪA chốt của phiên
  /// hiện tại — không quét toàn bộ tài liệu, để nhẹ và không đụng những chỗ
  /// khác trong bài (kể cả lặp hợp lệ do người dùng cố ý gõ/nói).
  ///
  /// KHÔNG đụng tới thuật toán chốt-dần/tìm-điểm-nối ở `_khiCoChu` — đây là
  /// một bước "dọn dẹp" CHẠY SAU, trên văn bản ĐÃ ghi vào tài liệu chính,
  /// dùng lại đúng `_dieuChinhLoiChinhTaSauKhiSua`/`_dieuChinhVungToanVanSauKhiSua`
  /// (như mọi chỗ xoá văn bản khác trong tệp này) để dời/nới đúng các vùng
  /// khác bị ảnh hưởng bởi phép xoá.
  static final RegExp _mauCumTuLapLienTiep =
      RegExp(r'(\S+(?: \S+)+?) \1(?=\s|$)');

  void _donCumTuLapLienTiepSauKhiChot(int batDau, int doDai) {
    if (doDai <= 0) return;
    final vb = _boDieuKhien.text;
    final ketThuc = batDau + doDai;
    if (batDau < 0 || ketThuc > vb.length) return;
    final doan = vb.substring(batDau, ketThuc);
    final khop = _mauCumTuLapLienTiep.firstMatch(doan);
    if (khop == null) return;

    final cum = khop.group(1)!;
    // Bản lặp thứ hai (kể cả dấu cách nối nó với bản đầu) nằm ngay sau bản
    // đầu — xoá đúng phần đó, giữ lại đúng MỘT bản.
    final xoaBatDau = batDau + khop.start + cum.length;
    final xoaDoDai = (khop.end - khop.start) - cum.length;
    if (xoaDoDai <= 0 || xoaBatDau < 0 || xoaBatDau + xoaDoDai > vb.length) {
      return;
    }

    final vbMoi = vb.replaceRange(xoaBatDau, xoaBatDau + xoaDoDai, '');
    _dieuChinhLoiChinhTaSauKhiSua(xoaBatDau, xoaDoDai, 0);
    _dieuChinhVungToanVanSauKhiSua(xoaBatDau, xoaDoDai, 0);
    // `_neo` luôn nằm ở đúng cuối đoạn vừa chốt (== batDau + doDai, tức
    // == ketThuc) ngay sau `_chotCauDangDoc()` — nằm SAU vùng vừa xoá, nên
    // dời lùi đúng bằng độ dài đã xoá.
    if (_neo >= xoaBatDau + xoaDoDai) {
      _neo -= xoaDoDai;
    } else if (_neo > xoaBatDau) {
      _neo = xoaBatDau;
    }
    _ghiVaoO(vbMoi, _neo);
  }

  /// Mọi lần ghi do máy thực hiện đều đi qua đây, để ghi nhớ nội dung, vị trí
  /// con trỏ và thời điểm — ba thứ dùng để nhận ra trạng thái bộ gõ báo về.
  void _ghiVaoO(String chu, int viTri) {
    // (YÊU CẦU MỚI — giới hạn ký tự một tệp) Chặn ở ĐÚNG MỘT nơi duy nhất —
    // mọi đường ghi chữ vào ô soạn thảo (gõ tay, dán, micro, AI áp kết
    // quả, từ điển sửa lỗi, Lùi lại/Tiến tới...) đều đi qua hàm này, nên
    // chặn tại đây là chặn được HẾT, không cần rải điều kiện ra nhiều nơi.
    // Bỏ qua hẳn lúc đang NẠP một ghi chú có sẵn (`_dangTrongLucMoGhiChu`)
    // — tệp cũ có thể đã dài hơn giới hạn từ trước, không được cắt mất chữ
    // của người dùng chỉ vì mở lại tệp. Chỉ chặn khi chữ MỚI dài hơn chữ
    // CŨ (`_chuGanNhat`, mốc trước lượt ghi này) — xoá bớt dù tệp vẫn còn
    // đang vượt trần vẫn luôn được phép.
    if (!_dangTrongLucMoGhiChu &&
        chu.length > gioiHanKyTuMotTep &&
        chu.length > _chuGanNhat.length) {
      chu = _chuGanNhat.length >= gioiHanKyTuMotTep
          // Đã ở/qua trần từ trước rồi mà vẫn cố thêm nữa — chặn đứng,
          // giữ nguyên y như cũ.
          ? _chuGanNhat
          // Lượt này mới vượt qua trần (ví dụ dán một đoạn dài) — cắt đúng
          // ngay tại trần, giữ phần đầu.
          : chu.substring(0, gioiHanKyTuMotTep);
      viTri = viTri.clamp(0, chu.length);
      _baoVuotGioiHanKyTuMotTep();
    }
    // Nếu văn bản và vị trí con trỏ ĐÃ ĐÚNG NGUYÊN như bộ điều khiển đang giữ
    // (trường hợp phổ biến nhất: gõ tay chèn một ký tự, không có hoán đổi
    // dấu câu, không đụng vùng khoá) thì bỏ qua việc ghi lại `.value` —
    // KHÔNG đẩy thêm một lượt `setEditingState` xuống bàn phím hệ điều hành.
    // Gõ tay thật đã tự cập nhật đúng cả chữ lẫn con trỏ trong bộ điều khiển
    // rồi (chính là nguồn của [chu]/[viTri] ở hầu hết lời gọi), nên việc ghi
    // đè lại y hệt chỉ là một vòng lặp thừa Dart→gốc→Dart — gõ càng nhanh,
    // vòng lặp thừa này càng dễ tranh chấp với bộ đệm gõ dồn của bàn phím
    // (Gboard...), gây gộp/rớt phím. Bỏ vòng thừa này không đổi hành vi gì
    // (chữ và con trỏ vốn đã đúng), chỉ bớt một lần ghi không cần thiết.
    final dungRoi = _boDieuKhien.text == chu &&
        _boDieuKhien.selection == TextSelection.collapsed(offset: viTri);
    if (!dungRoi) {
      _tuSua = true;
      _boDieuKhien.value = TextEditingValue(
        text: chu,
        selection: TextSelection.collapsed(offset: viTri),
      );
      _tuSua = false;
    }
    _chuGanNhat = chu;
    _viTriGanNhat = viTri;
    _lucGhi = DateTime.now();

    // Vừa có thêm chữ (dù do nói hay gõ tay, mọi lần ghi đều qua đây) — huỷ
    // đếm ngược tự tắt micro vì im lặng, đặt lại từ đầu.
    if (_muonNghe) _datLaiHenTuTatMicroImLang();

    // Chữ vừa thêm vào cuối bài thì kéo màn hình xuống theo, để dòng mới nhất
    // luôn nằm trong tầm mắt.
    if (viTri >= chu.length) _cuonXuongDuoi();
  }

  /// Đặt lại (hoặc bắt đầu) đếm ngược tự tắt hẳn micro nếu không có thêm chữ
  /// nào — gọi mỗi khi có chữ mới VÀ mỗi khi micro vừa bật, để khoảng lặng
  /// được tính từ đúng lúc bật micro, không phải chờ có chữ đầu tiên mới bắt
  /// đầu đếm.
  void _datLaiHenTuTatMicroImLang() {
    _henTuTatMicroImLang?.cancel();
    _henTuTatMicroImLang = Timer(
      Duration(seconds: widget.caiDat.thoiGianTuTatMicroGiay),
      () {
        if (_muonNghe) _tatMicro();
      },
    );
  }

  /// Kéo ô văn bản xuống hết cỡ, sau khi khung hình đã dựng lại xong — lúc đó
  /// chiều cao mới của bài mới được tính ra.
  ///
  /// Chỉ gọi khi chữ vừa thêm vào CUỐI bài. Người dùng chèn chữ vào giữa mà
  /// nhảy xuống đáy thì họ mất chỗ đang làm. Ngoài những lúc đó, họ cuộn lên
  /// xuống xem lại bài hoàn toàn tự do.
  void _cuonXuongDuoi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cuonVanBan.hasClients) return;
      final day = _cuonVanBan.position.maxScrollExtent;
      if ((_cuonVanBan.offset - day).abs() < 1) return;
      _cuonVanBan.jumpTo(day);
    });
  }

  /// Bấm "Home" 2 lần liên tiếp (về đầu TOÀN VĂN BẢN) — cuộn khung nhìn lên
  /// hẳn đầu theo, cùng kỹ thuật `_cuonXuongDuoi` (đợi khung hình kế tiếp để
  /// `selection` mới đã áp xong, tránh cuộn hụt vì layout chưa cập nhật).
  void _cuonToiDauVanBan() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cuonVanBan.hasClients) return;
      if (_cuonVanBan.offset.abs() < 1) return;
      _cuonVanBan.jumpTo(0);
    });
  }

  /// Người dùng vừa GÕ PHÍM. Cắt sạch mọi thứ đang chạy của micro.
  ///
  /// Chữ nào đã lỡ ra màn hình thì chết tại đó. Phần câu nói còn dở trong máy
  /// bị vứt bỏ hẳn — dùng cancel() chứ không phải stop(), vì stop() còn trả về
  /// một kết quả chốt, mà kết quả đó sẽ đổ nguyên câu ra lần nữa ở chỗ con trỏ
  /// mới. Nút micro tắt luôn, không được nghe gì nữa.
  ///
  /// Sau khi người dùng ngừng gõ đủ một giây thì micro tự bật lại như cũ.
  void _nguoiDungVuaGo() {
    _chuTam = ''; // Nhả đoạn đang nhảy ra: không gì đè lên nó được nữa.
    // (LỚP 2) Chụp lại đệm chống nhân đôi TRƯỚC khi xoá rỗng bên dưới.
    _luuBoDemRanhGioiPhien();
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];

    if (_muonNghe || _micro.isListening) {
      // (LỚP 1) Tăng session-ID ngay, đồng bộ — phiên đang nghe (nếu có) coi
      // như chết từ đây, không đợi cancel() xong.
      _phienNgheHienTai++;
      _boQuaCauNay = true;
      _microNgungDeGo = true;
      _muonNghe = false; // Ngăn _henBatLai() lén bật lại.
      _hen?.cancel();
      _micro.cancel();
      if (mounted) {
        setState(() {
          _dangNghe = false;
          _songAm.fillRange(0, _songAm.length, 0);
        });
      }
    }

    // Người dùng chọn "Không tự động bật lại Micro" trong Cài đặt: micro cứ
    // tắt vậy luôn, đợi tự tay bấm nút micro mới nghe lại — không hẹn giờ gì.
    _henGoXong?.cancel();
    if (widget.caiDat.thoiGianBatLaiGiay < 0) return;

    // Đồng hồ đếm lại từ đầu sau MỖI phím, nên nó chỉ điểm khi người dùng đã
    // thật sự ngừng tay.
    if (_microNgungDeGo) {
      _henGoXong = Timer(
        Duration(
          milliseconds: (widget.caiDat.thoiGianBatLaiGiay * 1000).round(),
        ),
        _batLaiSauKhiGoXong,
      );
    }
  }

  void _batLaiSauKhiGoXong() {
    if (!_microNgungDeGo || !mounted) return;
    _microNgungDeGo = false;
    _boQuaCauNay = false;
    setState(() => _muonNghe = true);
    _datLaiHenTuTatMicroImLang();
    _batMicro(); // Xem giải thích thứ tự gọi trong _bamNutMicro().
    _datNeoTaiConTro();
  }

  /// Người dùng chạm để dời con trỏ, chứ không gõ chữ. Nhẹ tay hơn: chỉ đóng
  /// băng đoạn đang nhảy và cắt câu đang dở, micro vẫn nghe tiếp.
  void _dongBangDoanDangNhay() {
    final dangVietDo = _chuTam.isNotEmpty;
    _chuTam = '';
    // (LỚP 2) Chụp lại đệm chống nhân đôi TRƯỚC khi xoá rỗng bên dưới.
    _luuBoDemRanhGioiPhien();
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];
    if (!dangVietDo) return;
    if (!_muonNghe || _dangCatCau || !_micro.isListening) return;
    // (LỚP 1) Tăng session-ID NGAY tại thời điểm QUYẾT ĐỊNH cắt phiên, không
    // đợi `stop()` hoàn tất — đây chính là điểm mấu chốt của ca "mất chữ":
    // nếu Android CŨNG đang tự ngắt gần như cùng lúc, tăng sớm ở đây đảm bảo
    // một trong hai sự kiện luôn thắng và id không bị hai nơi ghi đè lẫn
    // nhau một cách mơ hồ.
    _phienNgheHienTai++;
    _boQuaCauNay = true;
    _dangCatCau = true;
    _micro.stop().whenComplete(() {
      _dangCatCau = false;
      _henBatLai();
    });
  }

  /// Người dùng gõ phím hoặc bấm để dời con trỏ. So khác biệt giữa chữ cũ
  /// (_chuGanNhat) và chữ mới để biết đúng vùng vừa đổi — cách này gộp được
  /// cả gõ chèn, xoá, và autocorrect của bàn phím thay nguyên một cụm chữ,
  /// vào cùng một logic duy nhất.
  void _khiNguoiDungSua() {
    if (_tuSua) return;

    final chuMoi = _boDieuKhien.text;

    if (chuMoi != _chuGanNhat) {
      _apDungChinhSuaNguoiDung(chuMoi);
      return;
    }

    // Chữ y nguyên, chỉ con trỏ đổi. Có hai khả năng, và phải phân biệt cho
    // đúng — nhầm chỗ này là chữ lặp lại y như bản trước.
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) return;

    // (a) Bộ gõ báo ngược lại đúng trạng thái ta vừa đặt. Con trỏ trùng khít
    //     chỗ ta vừa đặt nó, hoặc chuyện xảy ra ngay sau khi ta ghi.
    final trungKhit = chon.end == _viTriGanNhat && chon.isCollapsed;
    final vuaGhiXong = DateTime.now().difference(_lucGhi) <
        const Duration(milliseconds: 600);
    if (trungKhit || vuaGhiXong) return;

    // (b0) Con trỏ (không phải vùng chọn) vừa đáp xuống NGAY TRONG một đoạn
    // bị khoá (đoạn CẦN THAY THẾ hay CẦN XOÁ — chữ đỏ) — đẩy nó ra biên gần
    // nhất. Hai đoạn này không cho gõ/xoá/chèn bên trong, chỉ bấm được để mở
    // menu (xem `_dungVaoVungKhoa`); không đẩy con trỏ ra thì người dùng vẫn
    // gõ được ngay giữa chữ đỏ dù đã chặn ở tầng sửa văn bản.
    if (chon.isCollapsed) {
      final viTriMoi = _diemNgoaiVungKhoa(chon.end);
      if (viTriMoi != chon.end) {
        _boDieuKhien.selection = TextSelection.collapsed(offset: viTriMoi);
        return;
      }
    }

    // (b) Người dùng thật sự chạm màn hình để dời con trỏ — hoặc TÔ ĐẬM một
    // vùng trong lúc micro vẫn đang nghe. Trường hợp sau phải đặt neo/vùng
    // tạm lên đúng vùng vừa chọn (giống hệt lúc bấm micro với sẵn vùng đã
    // chọn) thì câu nói tiếp theo mới đè lên được — trước đây chỉ có
    // `_bamNutMicro()`/`_batLaiSauKhiGoXong()` gọi `_datNeoTaiConTro()`, nên
    // chọn vùng khi micro ĐÃ bật sẵn (không qua hai hàm đó) bị bỏ sót.
    if (_muonNghe && !chon.isCollapsed) {
      _dongBangDoanDangNhay();
      _datNeoTaiConTro();
      return;
    }
    // (VIỆC 4) Người dùng chủ động dời con trỏ đi nơi khác — bỏ dở từ đang
    // chờ viết hoa, tránh áp dụng viết hoa sai chỗ nếu họ quay lại gõ ở một
    // vị trí khác.
    _viTriChoVietHoa = null;
    _neo = chon.end;
    _dongBangDoanDangNhay();
  }

  /// (VIỆC 5c) Danh sách offset "đường kẻ chia văn bản" — mỗi phần tử là vị
  /// trí BẮT ĐẦU của một dòng đang rỗng/toàn dấu cách, gắn với một đường kẻ
  /// chia đang hiển thị tại đó. Đây LÀ MỘT VỊ TRÍ TRONG VĂN BẢN (như các
  /// vùng AI/định dạng khác), được dời/xoá theo mỗi phép sửa ở
  /// `_dieuChinhLoiChinhTaSauKhiSua` — KHÔNG phải ký tự thật, chỉ dùng để vẽ
  /// overlay (`_VeDuongKeChia`).
  final List<int> _cacViTriDuongKeChia = [];

  /// (VIỆC 4) Vị trí BẮT ĐẦU của từ đang chờ viết hoa chữ cái đầu tiên, hoặc
  /// `null` nếu không có từ nào đang chờ. Chỉ áp dụng MỘT LẦN cho mỗi từ —
  /// xoá ngay sau khi xử lý (viết hoa hay bỏ qua), và huỷ khi người dùng chủ
  /// động di chuyển con trỏ đi nơi khác (xem `_khiNguoiDungSua`, nhánh (b)),
  /// hoặc khi mở ghi chú khác/xoá tất cả (đánh dấu của ghi chú cũ không còn
  /// nghĩa gì với ghi chú mới).
  int? _viTriChoVietHoa;

  /// (VIỆC 4) Một chữ cái, kể cả chữ cái tiếng Việt có dấu.
  static final RegExp _laChuCai = RegExp(r'[a-zA-ZÀ-ỹ]');

  /// (VIỆC 4) Các dấu câu coi là mốc kết thúc câu, để từ tiếp theo được viết
  /// hoa chữ đầu. KHÔNG có dấu phẩy (,) — dấu phẩy chỉ ngăn cách trong câu,
  /// không kết thúc câu, nên không kích hoạt viết hoa.
  static const Set<String> _kyTuKetCauChoVietHoa = {'.', ':', '!', '?'};

  /// (VIỆC 4) Tổng quát hoá của `_viTriChenXuongDongDon`: [chuMoi] có đúng
  /// là [cu] vừa được chèn thêm MỘT ký tự đơn giản ở đâu đó (bất kỳ ký tự
  /// nào, không riêng `'\n'`) hay không — trả về vị trí chèn nếu khớp, hoặc
  /// null nếu không (xoá kèm gõ, dán nhiều ký tự, autocorrect đổi cả cụm...).
  int? _viTriChenMotKyTuDon(String cu, String chuMoi) {
    if (chuMoi.length != cu.length + 1) return null;
    var dau = 0;
    while (dau < cu.length && cu[dau] == chuMoi[dau]) {
      dau++;
    }
    if (cu.substring(dau) != chuMoi.substring(dau + 1)) return null;
    return dau;
  }

  /// (VIỆC 4) Ngay TRƯỚC KHI chèn một ký tự mới tại [viTriChen] vào
  /// [vanBan] (văn bản đã có ký tự đó): nếu ký tự ngay trước [viTriChen] là
  /// dấu cách, và ký tự ngay trước dãy dấu cách đó là một trong các ký tự kết
  /// câu — đánh dấu [viTriChen] là điểm bắt đầu của một từ mới cần viết hoa
  /// chữ đầu (sau khi từ đó gõ xong).
  void _kiemTraDanhDauVietHoa(String vanBan, int viTriChen) {
    if (viTriChen <= 0 || viTriChen > vanBan.length) return;
    if (vanBan[viTriChen - 1] != ' ') return;
    var i = viTriChen - 1;
    while (i > 0 && vanBan[i - 1] == ' ') {
      i--;
    }
    if (i == 0) return; // Không có gì trước dãy dấu cách này.
    if (_kyTuKetCauChoVietHoa.contains(vanBan[i - 1])) {
      _viTriChoVietHoa = viTriChen;
    }
  }

  /// (VIỆC 4) Nếu đang có một từ chờ viết hoa (`_viTriChoVietHoa`) VÀ ký tự
  /// vừa gõ [ktChen] là dấu cách hoặc xuống dòng (dấu hiệu từ đó đã gõ
  /// xong) — trả về (vị trí, ký tự đã viết hoa) cần thay vào [vanBan], hoặc
  /// `null` nếu không có gì phải làm. LUÔN xoá đánh dấu sau khi gọi (chỉ áp
  /// dụng một lần cho mỗi từ), bất kể có viết hoa được hay không.
  (int, String)? _ketQuaVietHoaChoTuVuaGoXong(String vanBan, String ktChen) {
    final vt = _viTriChoVietHoa;
    _viTriChoVietHoa = null;
    if (vt == null) return null;
    if (ktChen != ' ' && ktChen != '\n') return null;
    if (vt < 0 || vt >= vanBan.length) return null;
    final kt = vanBan[vt];
    if (!_laChuCai.hasMatch(kt)) return null;
    return (vt, kt.toUpperCase());
  }

  /// (VIỆC 5b) Có đúng là "Enter đơn giản" hay không: [chuMoi] dài hơn [cu]
  /// đúng 1 ký tự, ký tự thêm đó là `'\n'`, và không có gì khác bị xoá/đổi ở
  /// đâu cả (mọi ký tự trước/sau vị trí chèn khớp y nguyên). Trả về vị trí
  /// chèn, hoặc null nếu không khớp mẫu này (autocorrect, dán nhiều ký tự,
  /// xoá kèm gõ... đều bị loại, để tính năng chỉ chạy đúng lúc người dùng
  /// bấm Enter thật sự).
  ///
  /// (SỬA LỖI "nhảy qua" các dấu xuống dòng có sẵn ngay sau con trỏ) Vòng
  /// lặp so KHỚP TIỀN TỐ dài nhất bên dưới là nguồn gốc lỗi: nếu ngay sau vị
  /// trí Enter thật sự có SẴN một hay nhiều dấu `\n` khác (ví dụ con trỏ
  /// đứng ngay trước một dòng trống), dấu `\n` MỚI chèn vào trùng y hệt các
  /// dấu `\n` đã có ngay sau nó — vòng lặp "khớp dài nhất có thể" cứ thế lấn
  /// qua HẾT các dấu `\n` cũ rồi mới dừng, trả về vị trí chèn nằm SAU chúng
  /// thay vì đúng tại con trỏ. `[goiY]` (vị trí con trỏ THẬT trước khi gõ,
  /// truyền từ `_neo`) phá vỡ sự mập mờ này — kiểm tra và ưu tiên nó TRƯỚC,
  /// chỉ rơi về vòng lặp khớp-dài-nhất khi gợi ý không hợp lệ (phòng hờ, ví
  /// dụ gợi ý bị lệch vì một lý do nào khác).
  int? _viTriChenXuongDongDon(String cu, String chuMoi, {int? goiY}) {
    if (chuMoi.length != cu.length + 1) return null;
    if (goiY != null && goiY >= 0 && goiY <= cu.length && chuMoi[goiY] == '\n') {
      if (cu.substring(0, goiY) == chuMoi.substring(0, goiY) &&
          cu.substring(goiY) == chuMoi.substring(goiY + 1)) {
        return goiY;
      }
    }
    var dau = 0;
    while (dau < cu.length && cu[dau] == chuMoi[dau]) {
      dau++;
    }
    if (dau >= chuMoi.length || chuMoi[dau] != '\n') return null;
    if (cu.substring(dau) != chuMoi.substring(dau + 1)) return null;
    return dau;
  }

  /// (VIỆC 5c) Thêm một offset đường kẻ chia mới, tránh trùng lặp.
  void _themViTriDuongKeChia(int viTri) {
    if (!_cacViTriDuongKeChia.contains(viTri)) {
      _cacViTriDuongKeChia.add(viTri);
    }
  }

  /// (VIỆC 3) Quét TOÀN BỘ nội dung hiện tại của `_boDieuKhien` để dựng lại
  /// `_cacViTriDuongKeChia` từ đầu — dùng khi MỞ một ghi chú (kể cả quay lại
  /// một ghi chú đã mở trước đó), vì danh sách này chỉ là bộ nhớ TẠM (RAM),
  /// được xây dần theo từng lần bấm Enter, nên bị mất khi chuyển sang ghi chú
  /// khác rồi quay lại.
  ///
  /// Tách văn bản theo `\n` thành từng dòng, DUYỆT MỌI dòng NGOẠI TRỪ dòng
  /// ĐẦU TIÊN và dòng CUỐI CÙNG (ràng buộc cứng: hai dòng này không bao giờ
  /// có đường kẻ chia dù rỗng/toàn dấu cách) — dòng nào rỗng hoặc chỉ toàn
  /// dấu cách thì offset BẮT ĐẦU của dòng đó được thêm vào danh sách.
  ///
  /// KHÔNG tự xoá `_cacViTriDuongKeChia` trước khi quét — người gọi (bên
  /// `_moGhiChu`) đã tự lo việc đó, để giữ đúng thứ tự "xoá cũ trước, quét
  /// mới sau" như đã có.
  void _quetVaXayDungDuongKeChia() {
    final vanBan = _boDieuKhien.text;
    if (vanBan.isEmpty) return;
    final cacDong = vanBan.split('\n');
    if (cacDong.length <= 2) return; // Chỉ có dòng đầu và/hoặc dòng cuối.
    var offset = cacDong[0].length + 1; // Bỏ qua dòng đầu tiên.
    for (var i = 1; i < cacDong.length - 1; i++) {
      final dong = cacDong[i];
      if (dong.trim().isEmpty) {
        _themViTriDuongKeChia(offset);
      }
      offset += dong.length + 1;
    }
  }

  /// (LỖI 2 mở rộng) "Tự động thụt đầu dòng" phải áp dụng ở MỌI chỗ một dòng
  /// mới BẮT ĐẦU nhận ký tự đầu tiên của nó — không riêng gì lúc vừa bấm
  /// Enter (VIỆC 5b/5c tự chèn thụt ngay sau `\n` nó tạo ra) hay lúc văn bản
  /// còn HOÀN TOÀN RỖNG. Cụ thể: nếu [vanBan] rỗng, HOẶC ký tự ngay TRƯỚC
  /// [viTri] là `\n` (dòng đó đã có sẵn nhưng còn để trống — ví dụ do người
  /// dùng tự tạo dòng trống, hoặc dời con trỏ tay tới đó) — trả về đúng số
  /// dấu cách cần chèn NGAY TRƯỚC nội dung sắp tới, để dòng luôn được thụt
  /// đầu dòng bất kể nội dung đó tới từ gõ tay hay giọng nói. Trả về chuỗi
  /// rỗng nếu không rơi vào trường hợp nào hoặc tính năng đang tắt.
  /// Cờ MỘT LẦN: bật ngay trước khi `_phimAoPaste` chèn chữ vừa dán vào, tắt
  /// lại ngay sau — chặn `_thutDauDongNeuCan` không cho tự thêm dấu cách
  /// trong lúc dán, dù qua phím tắt (Ctrl+V) hay nút "Dán" của Bộ phím
  /// nhanh. Xem chú thích khai báo `_phimAoPaste`.
  bool _tamNgungTuDongThutDauDong = false;

  String _thutDauDongNeuCan(String vanBan, int viTri) {
    if (_tamNgungTuDongThutDauDong) return '';
    if (!widget.caiDat.tuDongThutDauDong) return '';
    final rong = vanBan.isEmpty;
    final ngayTruocLaXuongDong =
        !rong && viTri > 0 && viTri <= vanBan.length && vanBan[viTri - 1] == '\n';
    if (!rong && !ngayTruocLaXuongDong) return '';
    return ' ' * widget.caiDat.soDauCachThutDauDong;
  }

  void _apDungChinhSuaNguoiDung(String chuMoi) {
    final cu = _chuGanNhat;

    // (VIỆC 1) Vị trí con trỏ CUỐI CÙNG override — dùng chung cho MỌI phép
    // biến đổi [chuMoi] xảy ra TRƯỚC khi diff chính chạy bên dưới (chèn dấu
    // cách ở LỖI 2 ngay dưới đây, hoặc chèn "\n" + chấm câu + thụt đầu dòng ở
    // VIỆC 5b/5c xa hơn) — vì Flutter's `TextEditingValue.selection` (đọc ở
    // cuối hàm) được tính trên [chuMoi] GỐC (TRƯỚC biến đổi), không hề biết gì
    // về các ký tự vừa được chèn thêm, nên phải tự tính tay và ghi đè vào đây.
    int? viTriConTroXuongDongTuDong;

    // (LỖI 2) Gõ ký tự ĐẦU TIÊN của một văn bản đang HOÀN TOÀN RỖNG, HOẶC gõ
    // đúng MỘT ký tự đơn giản ngay sau một dấu xuống dòng (dòng mới còn trống
    // — xem `_thutDauDongNeuCan`): chèn số dấu cách đã cấu hình vào TRƯỚC ký
    // tự đó — cùng kỹ thuật "biến đổi [chuMoi] trước khi diff chính chạy" như
    // VIỆC 5b bên dưới đã làm cho trường hợp Enter.
    if (cu.isEmpty) {
      final thut = _thutDauDongNeuCan(cu, 0);
      if (thut.isNotEmpty && chuMoi.isNotEmpty) {
        chuMoi = '$thut$chuMoi';
        viTriConTroXuongDongTuDong = chuMoi.length;
      }
    } else {
      final viTriChenDon0 = _viTriChenMotKyTuDon(cu, chuMoi);
      // `!= '\n'`: phím Enter cũng là một phép "chèn đúng một ký tự đơn
      // giản" khớp `_viTriChenMotKyTuDon` — nhưng Enter đã có logic thụt đầu
      // dòng RIÊNG của nó ở VIỆC 5b/5c bên dưới (thụt vào SAU dấu `\n` vừa
      // tạo ra, không phải TRƯỚC nó) — phải loại trừ ở đây, không thì thụt
      // nhầm vào trước cả dấu xuống dòng.
      if (viTriChenDon0 != null && chuMoi[viTriChenDon0] != '\n') {
        final thut = _thutDauDongNeuCan(cu, viTriChenDon0);
        if (thut.isNotEmpty) {
          chuMoi = chuMoi.substring(0, viTriChenDon0) +
              thut +
              chuMoi.substring(viTriChenDon0);
          viTriConTroXuongDongTuDong = viTriChenDon0 + thut.length + 1;
        }
      }
    }

    // (VIỆC 4) Viết hoa đầu câu — CHẠY TRƯỚC MỌI thứ khác trong hàm này
    // (đúng thứ tự ưu tiên: viết hoa từ vừa gõ xong trước, rồi mới tới logic
    // Enter/chấm câu/thụt đầu dòng bên dưới). Chỉ áp dụng khi đây đúng là
    // MỘT lần chèn đúng một ký tự đơn giản (gõ tay bình thường) — không đụng
    // tới các trường hợp phức tạp hơn (dán nhiều ký tự, autocorrect đổi cả
    // cụm, hay trường hợp LỖI 2 vừa chèn 5 dấu cách ở trên).
    //
    // `cuChoEnter`: bản `cu` đã áp CÙNG phép viết hoa (nếu có) — dùng RIÊNG
    // cho phát hiện "Enter đơn giản" ngay bên dưới, để phép so khác biệt đó
    // (giả định chỉ có ĐÚNG một khác biệt là ký tự vừa chèn) không bị lệch
    // vì thêm một khác biệt viết hoa nằm ở một vị trí khác.
    var cuChoEnter = cu;
    if (widget.caiDat.tuDongVietHoaDauCau) {
      final viTriChenDon = _viTriChenMotKyTuDon(cu, chuMoi);
      if (viTriChenDon != null) {
        final ktChen = chuMoi[viTriChenDon];
        final ketQua = _ketQuaVietHoaChoTuVuaGoXong(chuMoi, ktChen);
        if (ketQua != null) {
          final (vt, ktHoa) = ketQua;
          chuMoi = chuMoi.substring(0, vt) + ktHoa + chuMoi.substring(vt + 1);
          cuChoEnter = cu.substring(0, vt) + ktHoa + cu.substring(vt + 1);
        }
        _kiemTraDanhDauVietHoa(chuMoi, viTriChenDon);
      }
    }

    // (VIỆC 5b/5c) Phát hiện "Enter đơn giản" (chèn ĐÚNG một ký tự '\n',
    // không xoá gì khác) — TRƯỚC khi diff chính chạy, biến đổi [chuMoi]
    // (nếu "Tự động thêm dấu chấm"/"Tự động thụt đầu dòng" đang bật) rồi để
    // TOÀN BỘ diff/dời-offset bên dưới (đã có sẵn, không viết lại) tự lo
    // phần còn lại — coi cả cụm (chấm + \n + thụt) là MỘT phép chèn duy
    // nhất, y hệt cách các phép sửa khác trong hàm này vẫn làm.
    int? ungCuVienDuongKeChia;
    final dauXuongDongDon = _viTriChenXuongDongDon(cuChoEnter, chuMoi, goiY: _neo);
    if (dauXuongDongDon != null) {
      // (VIỆC 2) Đã có sẵn dấu chấm ngay trước con trỏ rồi (kể cả có một dấu
      // cách xen giữa) — không thêm/thay chấm nữa, tránh thừa 2 dấu chấm liền
      // nhau. Kiểm tra đúng HAI hình dạng: "...chấm|" (chấm ngay sát) và
      // "...chấm cách|" (chấm rồi một dấu cách rồi mới tới con trỏ).
      final ktNgayTruoc =
          dauXuongDongDon > 0 ? cuChoEnter[dauXuongDongDon - 1] : null;
      final daCoChamRoi = ktNgayTruoc == '.' ||
          (ktNgayTruoc == ' ' &&
              dauXuongDongDon >= 2 &&
              cuChoEnter[dauXuongDongDon - 2] == '.');

      // (VIỆC 3) Hai dấu cách liên tiếp NGAY TRƯỚC con trỏ là dấu hiệu đây
      // là một dòng trống do "Tự động thụt đầu dòng" tự tạo (5 dấu cách),
      // không phải văn bản thật — bỏ qua HOÀN TOÀN logic thêm dấu chấm, chỉ
      // xuống dòng bình thường, để không phá mất dòng trống mà "đường kẻ
      // chia văn bản" cần nhận diện. Chỉ kiểm tra khi CHƯA rơi vào trường hợp
      // "đã có chấm rồi" ở trên (hai điều kiện độc lập, không xung đột).
      final haiCachLienTiep = !daCoChamRoi &&
          dauXuongDongDon >= 2 &&
          cuChoEnter[dauXuongDongDon - 1] == ' ' &&
          cuChoEnter[dauXuongDongDon - 2] == ' ';
      // (VIỆC THÊM) Sáu trường hợp KHÔNG được thêm dấu chấm — chỉ xuống dòng
      // ngay: (1) không có ký tự nào trước con trỏ, (2) ký tự trước con trỏ
      // là xuống dòng, (3) ký tự trước con trỏ là dấu cách và trước dấu cách
      // đó là xuống dòng, (4) ký tự trước con trỏ là dấu cách và trước dấu
      // cách đó không có ký tự gì (dấu cách là ký tự đầu văn bản), (5) ký tự
      // trước con trỏ là một ký tự đặc biệt, (6) ký tự trước con trỏ là dấu
      // cách và trước dấu cách đó là một ký tự đặc biệt — riêng trường hợp 6
      // còn phải XOÁ LUÔN dấu cách thừa đó trước khi xuống dòng. Danh sách
      // ký tự đặc biệt CHỈ dùng riêng ở đây (không đụng gì tới
      // `_kyTuDacBiet` cấp lớp — bộ ký tự "nhảy qua dấu cách" của tính năng
      // khác) — đúng nguyên văn bộ ký tự đã yêu cầu.
      const kyTuDacBiet = {
        ';', '.', ',', '/', ')', '(', '"', "'", '*', ':', '!', '?', '•',
      };
      final ktTruocNua =
          dauXuongDongDon >= 2 ? cuChoEnter[dauXuongDongDon - 2] : null;
      final laTruongHop6 = ktNgayTruoc == ' ' &&
          ktTruocNua != null &&
          kyTuDacBiet.contains(ktTruocNua);
      final khongThemDauChamThem = ktNgayTruoc == null ||
          ktNgayTruoc == '\n' ||
          (ktNgayTruoc == ' ' && ktTruocNua == '\n') ||
          (ktNgayTruoc == ' ' && ktTruocNua == null) ||
          kyTuDacBiet.contains(ktNgayTruoc) ||
          laTruongHop6;

      final themCham = widget.caiDat.tuDongThemDauCham &&
          !daCoChamRoi &&
          !haiCachLienTiep &&
          !khongThemDauChamThem;
      final thut = widget.caiDat.tuDongThutDauDong
          ? ' ' * widget.caiDat.soDauCachThutDauDong
          : '';
      var moiDau = dauXuongDongDon;
      String chenVao;
      if (themCham) {
        if (dauXuongDongDon > 0 && cuChoEnter[dauXuongDongDon - 1] == ' ') {
          moiDau = dauXuongDongDon - 1;
        }
        chenVao = '.\n$thut';
      } else {
        if (laTruongHop6) {
          moiDau = dauXuongDongDon - 1;
        }
        chenVao = '\n$thut';
      }
      if (themCham || thut.isNotEmpty || laTruongHop6) {
        chuMoi = cuChoEnter.substring(0, moiDau) + chenVao + cuChoEnter.substring(dauXuongDongDon);
        viTriConTroXuongDongTuDong = moiDau + chenVao.length;
      }

      // YÊU CẦU MỚI: ngay sau khi xuống dòng xong (đã chèn thụt nếu có), nếu
      // ký tự NGAY TRƯỚC con trỏ VÀ ký tự NGAY SAU con trỏ đều là dấu cách
      // (bất kể dấu cách TỰ NHIÊN hay do chính thụt đầu dòng vừa chèn), xoá
      // HẾT các dấu cách liên tiếp NGAY SAU con trỏ — chỉ áp dụng khi đang
      // bật "Tự động thụt đầu dòng mỗi khi xuống hàng". Dùng
      // [viTriConTroXuongDongTuDong] (mặc định bằng [dauXuongDongDon] khi
      // không có gì được chèn thêm ở trên) làm vị trí con trỏ THẬT sau cùng.
      if (widget.caiDat.tuDongThutDauDong) {
        final vt = viTriConTroXuongDongTuDong ?? dauXuongDongDon;
        final coCachTruoc = vt > 0 && chuMoi[vt - 1] == ' ';
        final coCachSau = vt < chuMoi.length && chuMoi[vt] == ' ';
        if (coCachTruoc && coCachSau) {
          var cuoiCach = vt;
          while (cuoiCach < chuMoi.length && chuMoi[cuoiCach] == ' ') {
            cuoiCach++;
          }
          chuMoi = chuMoi.substring(0, vt) + chuMoi.substring(cuoiCach);
        }
      }

      // (VIỆC 5c) Dòng NGAY TRÊN vị trí con trỏ mới — tính trên văn bản
      // CUỐI CÙNG (đã áp cả dấu chấm, nếu có) — rỗng/toàn dấu cách thì ghi
      // nhận một đường kẻ chia mới (thêm vào danh sách SAU KHI offset của
      // các đường kẻ cũ đã được dời, xem bên dưới, để khỏi bị dời chồng lần
      // hai).
      // (SỬA LỖI đường kẻ chia "bóng ma") `cu.isNotEmpty`: nếu văn bản GỐC
      // (trước khi gõ Enter này) đang HOÀN TOÀN RỖNG thì KHÔNG CÓ dòng nào ở
      // trên cả — không được coi "không có gì" là một dòng trống hợp lệ để
      // tạo đường kẻ chia ngay tại dòng đầu tiên của trang.
      if (widget.caiDat.tuDongThemDuongKeChia && cu.isNotEmpty) {
        final viTriNewline = moiDau + (themCham ? 1 : 0);
        final dongTrenBatDau = viTriNewline <= 0
            ? 0
            : chuMoi.lastIndexOf('\n', viTriNewline - 1) + 1;
        if (chuMoi.substring(dongTrenBatDau, viTriNewline).trim().isEmpty) {
          ungCuVienDuongKeChia = dongTrenBatDau;
        }
      }
    }

    // So khác biệt: phần đầu giống nhau dài bao nhiêu, phần đuôi giống nhau
    // dài bao nhiêu. Khoảng giữa còn lại chính là chỗ vừa bị đổi.
    final gioiHan = cu.length < chuMoi.length ? cu.length : chuMoi.length;
    var dau = 0;
    while (dau < gioiHan && cu[dau] == chuMoi[dau]) {
      dau++;
    }
    var duoi = 0;
    final gioiHanDuoi = gioiHan - dau;
    while (duoi < gioiHanDuoi &&
        cu[cu.length - 1 - duoi] == chuMoi[chuMoi.length - 1 - duoi]) {
      duoi++;
    }

    final doDaiChenVao = chuMoi.length - dau - duoi;
    final soLuongXoa = cu.length - dau - duoi;

    // Đoạn CẦN THAY THẾ / CẦN XOÁ (chữ đỏ) KHÔNG cho gõ/xoá/chèn bên trong —
    // chỉ bấm được để mở menu. Chỗ vừa đổi đè vào một trong hai thì HUỶ
    // THẲNG thay đổi, trả nguyên văn bản cũ, đặt lại con trỏ ở biên gần nhất
    // — coi như chưa có gì xảy ra, không lưu mốc Lùi lại, không tính là một
    // lần gõ.
    if (_dungVaoVungKhoa(dau, dau + soLuongXoa)) {
      _ghiVaoO(cu, _diemNgoaiVungKhoa(dau));
      return;
    }

    // Gõ tay chèn ký tự cũng phải tắt chú thích, y hệt bấm phím rời hay chạm
    // màn hình — bắt ngay tại đây (chữ THẬT SỰ đổi) thay vì chỉ trông chờ
    // bắt được sự kiện bàn phím vật lý, vì trường hợp CHỮ ĐẦU TIÊN của một
    // ghi chú vừa tạo còn trống trơn có lúc không đi qua đúng đường bắt phím
    // đó (autofocus + khung còn đang dựng dở lúc gõ quá nhanh).
    _tatChuThich();
    _batDauMoDamChamCuoi();

    // Chỉ lưu điểm mốc vào LẦN GÕ ĐẦU TIÊN của một đợt — một đợt kết thúc
    // sau 5 giây liên tục không gõ thêm gì (xem _dangTrongDotGoTay). Độc lập
    // hẳn với việc micro có tự bật lại hay không.
    //
    // Truyền tay _chuGanNhat (chữ CŨ) và _neo (vị trí con trỏ CŨ): bộ điều
    // khiển tại đây đã mang chữ MỚI rồi, tự đọc _boDieuKhien.text sẽ chụp
    // nhầm đúng cái vừa gõ, không lùi được.
    if (!_dangTrongDotGoTay) {
      _luuDiemMoc(vanBan: _chuGanNhat, viTriConTro: _neo);
      _dangTrongDotGoTay = true;
    }
    _henRanhGioiGoTay?.cancel();
    _henRanhGioiGoTay = Timer(_thoiGianRanhGioiGoTay, () {
      _dangTrongDotGoTay = false;
    });

    // Hợp (OR) định dạng của ký tự NGAY TRƯỚC [dau] và ký tự NGAY SAU đoạn bị
    // xoá (đầu cũ tại [dau + soLuongXoa]) — tính TRƯỚC khi
    // `_dieuChinhLoiChinhTaSauKhiSua` dời/nới các vùng `dinhDang`, vì hàm đó
    // đọc theo toạ độ CŨ. Đây là nguồn MẶC ĐỊNH quyết định định dạng của ký
    // tự vừa gõ, và cùng một hàm này cũng quyết định nút nào sáng trên
    // thanh công cụ (xem `_tinhTrangThaiDinhDangHienTai`).
    //
    // YÊU CẦU 2b: NHƯNG nếu bộ nhớ đệm (YÊU CẦU 2) đang hoạt động, nó THAY
    // THẾ HẲN "hợp 2 bên" — if/else đơn giản, không đụng gì tới offset/
    // `_VungDinhDangThuCong` phía dưới. `_chuanHoaXungDotTreMuTreChan` là
    // chốt chặn dự phòng cho YÊU CẦU 1 (xem khai báo hàm).
    final hopMoi = _boNhoDemDangHoatDong
        ? _chuanHoaXungDotTreMuTreChan(_boNhoDem!)
        : _dinhDangHopTaiViTri(dau, dau + soLuongXoa, cu.length);

    _dieuChinhLoiChinhTaSauKhiSua(
      dau,
      soLuongXoa,
      doDaiChenVao,
      vanBanCu: cu,
      vanBanMoi: chuMoi,
    );
    // (VIỆC 5c) Ghi nhận đường kẻ chia MỚI (nếu Enter vừa rồi tạo ra) SAU
    // KHI các offset CŨ trong `_cacViTriDuongKeChia` đã được dời ở trên —
    // offset mới này vốn đã tính sẵn theo toạ độ văn bản CUỐI CÙNG (chuMoi),
    // dời thêm lần nữa sẽ sai.
    if (ungCuVienDuongKeChia != null) _themViTriDuongKeChia(ungCuVienDuongKeChia);
    _dieuChinhVungToanVanSauKhiSua(dau, soLuongXoa, doDaiChenVao);
    if (doDaiChenVao > 0) {
      _apDinhDangHopChoDoanMoiChen(dau, dau + doDaiChenVao, hopMoi);
      // YÊU CẦU 2c (cờ một lần): con trỏ SẮP tự dịch theo ký tự vừa chèn khi
      // `_ghiVaoO` bên dưới cập nhật `selection` — đó KHÔNG phải người dùng
      // chủ động di chuyển con trỏ, nên đừng để `_tinhTrangThaiDinhDangHienTai`
      // (chạy trong cùng lượt, do là listener của `_boDieuKhien`) huỷ bộ nhớ
      // đệm oan. Chỉ đặt cờ khi bộ nhớ đệm đang thật sự hoạt động — không có
      // gì để giữ thì khỏi đặt cờ.
      if (_boNhoDemDangHoatDong) _vuaChenKyTuBangBoNhoDem = true;
    }
    // (VIỆC 2, điểm iii/v) Ký tự vừa chèn (gõ tay hoặc giọng nói) có thể vừa
    // được gán treMu (chữ trên) qua `_apDinhDangHopChoDoanMoiChen` ở trên nếu
    // một trong hai bên đang mang treMu. Lọc ngay ký tự không hợp lệ ra khỏi
    // treMu tại đây.
    _gioiHanTreMuSauKhiChen(dau, doDaiChenVao, chuMoi);

    // Gõ đúng MỘT ký tự đặc biệt (. , ; ? !) ngay sau một dấu cách có sẵn —
    // hoán đổi hai ký tự đó cho nhau, để dấu câu nằm sát vào chữ trước nó
    // thay vì kẹt sau dấu cách: "abc |" gõ "." thành "abc. |", con trỏ vẫn
    // đứng nguyên vị trí (chỉ đổi chỗ hai ký tự liền kề, độ dài không đổi).
    var chuMoiCuoi = chuMoi;
    if (soLuongXoa == 0 &&
        doDaiChenVao == 1 &&
        dau > 0 &&
        cu[dau - 1] == ' ' &&
        _kyTuDacBiet.contains(chuMoi[dau])) {
      chuMoiCuoi = chuMoi.substring(0, dau - 1) + chuMoi[dau] + ' ' + chuMoi.substring(dau + 1);
      // (VIỆC 5) Ký tự đặc biệt vừa "nhảy" ra TRƯỚC dấu cách (không còn nằm
      // ở vị trí con trỏ [dau] nữa, mà ở [dau - 1]) — về ngữ nghĩa đây CHÍNH
      // XÁC là tình huống "dấu câu + dấu cách", nên phải kiểm tra đánh dấu
      // viết hoa lại TRÊN [chuMoiCuoi] (văn bản SAU khi nhảy), không phải
      // trên [chuMoi] gốc (lần gọi `_kiemTraDanhDauVietHoa` ở khối VIỆC 4 bên
      // trên đã chạy trên [chuMoi] TRƯỚC khi nhảy nên kiểm tra sai chỗ, không
      // bắt được tình huống này). Vị trí cần đánh dấu là `dau + 1`: trong
      // [chuMoiCuoi], ký tự đặc biệt nằm ở `dau - 1`, dấu cách nằm ở `dau`,
      // nên từ kế tiếp sẽ bắt đầu ngay tại `dau + 1`.
      if (widget.caiDat.tuDongVietHoaDauCau) {
        _kiemTraDanhDauVietHoa(chuMoiCuoi, dau + 1);
      }
    }

    final chon = _boDieuKhien.selection;
    final viTriConTro = viTriConTroXuongDongTuDong ??
        (chon.isValid ? chon.end : chuMoiCuoi.length);

    _neo = viTriConTro;
    _nguoiDungVuaGo();
    _ghiVaoO(chuMoiCuoi, viTriConTro);
    // (Tính năng "Chuẩn hoá các cặp dấu đóng-mở ngoặc") Chỉ áp dụng cho
    // ĐÚNG một ký tự đơn giản vừa gõ tay (không áp dụng khi dán nhiều ký
    // tự/autocorrect đổi cả cụm) — `dau` là vị trí ký tự đó trong [chuMoiCuoi].
    if (soLuongXoa == 0 && doDaiChenVao == 1) {
      _chuanHoaNgoacSauKhiGo(chuMoiCuoi[dau], dau);
    }
    // (SỬA LỖI đường kẻ chia thỉnh thoảng không hiện đúng chỗ quanh một lần
    // Enter) Việc dời/thêm offset theo từng bước ở trên (VIỆC 5c) đôi khi
    // vẫn lệch trong các trường hợp biên hiếm — ví dụ nhiều dòng trống liên
    // tiếp cùng lúc đổi. Enter là lúc DUY NHẤT có thể sinh ra một dòng
    // trống mới, nên quét lại TOÀN BỘ ngay sau mỗi lần Enter là đủ rẻ (chỉ
    // chạy đúng lúc người dùng xuống dòng, không chạy mỗi ký tự) mà chắc
    // chắn đúng — cùng kỹ thuật đã dùng cho Lùi lại/Tiến tới.
    if (dauXuongDongDon != null && widget.caiDat.tuDongThemDuongKeChia) {
      _cacViTriDuongKeChia.clear();
      _quetVaXayDungDuongKeChia();
    }
    // Thẻ Tích chọn ở đoạn vừa sửa có thể vừa trở thành rỗng (xoá hết chữ
    // xung quanh) — tự dọn ngay, xem `_donDepTheTichChonRongQuanhViTri`.
    _donDepTheTichChonRongQuanhViTri(dau, dau + doDaiChenVao);
    _henLuu();
    _lenLichKiemTraChinhTa();
  }

  // --------------------------------------------------- kiểm tra chính tả AI

  /// Vùng [vitri, vitri + soXoa) trong bài vừa bị thay bằng [soChen] ký tự
  /// mới. Dời mọi lỗi nằm SAU vùng đó theo đúng độ lệch; lỗi nào NẰM TRONG
  /// (hoặc đè lên) vùng vừa đổi thì coi như không còn đáng tin và bỏ luôn —
  /// văn bản ở đó đã khác, gạch đỏ cũ không còn ý nghĩa gì nữa.
  void _dieuChinhLoiChinhTaSauKhiSua(
    int vitri,
    int soXoa,
    int soChen, {
    String? vanBanCu,
    String? vanBanMoi,
  }) {
    if (soXoa == 0 && soChen == 0) return;
    final ketThucXoa = vitri + soXoa;
    final lech = soChen - soXoa;

    _boDieuKhien.loi.removeWhere((l) => l.batDau < ketThucXoa && l.ketThuc > vitri);
    for (var i = 0; i < _boDieuKhien.loi.length; i++) {
      final l = _boDieuKhien.loi[i];
      if (l.batDau >= ketThucXoa) _boDieuKhien.loi[i] = l.dich(lech);
    }

    for (final d in List<_VungDauCauMoi>.of(_boDieuKhien.dauCauMoi)) {
      if (d.batDau >= ketThucXoa) {
        d.batDau += lech;
        d.ketThuc += lech;
      } else if (d.ketThuc > vitri) {
        d.henNhapNhay?.cancel();
        _boDieuKhien.dauCauMoi.remove(d);
      }
    }

    if (_viTriDaKiemTraChinhTa > ketThucXoa) {
      _viTriDaKiemTraChinhTa += lech;
    } else if (_viTriDaKiemTraChinhTa > vitri) {
      // Đoạn đã kiểm tra bị sửa giữa chừng — coi như chưa kiểm tra từ đó.
      _viTriDaKiemTraChinhTa = vitri;
    }

    // Dời vị trí token "đang ghi âm" (nếu có thẻ nào đang ghi dở) theo cùng
    // phép biến đổi — gõ tay ở chỗ KHÁC trong lúc vẫn ghi thẻ không được
    // làm sai lệch vị trí thật của token. `ChanSuaGiuaThe` đã chặn mọi sửa
    // MỘT PHẦN token, nên ở đây chỉ còn hai khả năng: sửa nằm hẳn trước nó
    // (dời theo [lech]) hoặc phủ trọn xoá nó luôn (select-all rồi xoá...)
    // — mất token thì ngừng theo dõi, `_chotTheGhiAmHienTaiThanhHoanChinh`
    // sẽ tự phát hiện và âm thầm bỏ dữ liệu ghi âm dở đó khi thẻ được chốt.
    final tvt = _viTriTokenDangGhiThe;
    if (tvt != null) {
      final ktToken = tvt + tenTokenDangGhiAm.length;
      if (vitri <= tvt && ketThucXoa >= ktToken) {
        _viTriTokenDangGhiThe = null;
      } else if (tvt >= ketThucXoa) {
        _viTriTokenDangGhiThe = tvt + lech;
      }
    }

    // Dời/co giãn các vùng định dạng thủ công theo cùng phép biến đổi —
    // gõ thêm chữ NGAY TRONG một vùng thì vùng đó tự nới rộng ra (chữ mới
    // mang định dạng cũ), xoá bớt thì vùng co lại, còn vùng nằm hẳn SAU chỗ
    // sửa thì chỉ dời nguyên khối theo [lech].
    //
    // BUG ĐÃ SỬA (định dạng "nhảy lan" sang dòng khác): [vitri, ketThucXoa)
    // không phải luôn luôn là đúng-y-hệt phần bị đổi — nó chỉ là kết quả của
    // phép so khác biệt "chung tiền tố + chung hậu tố" trong
    // `_apDungChinhSuaNguoiDung`, một phép so 2 ĐẦU. Khi bàn phím/bộ gõ báo
    // về MỘT LẦN thay đổi ở HAI chỗ rời rạc (ví dụ tự viết hoa đầu câu ở xa
    // ĐỒNG THỜI với tự sửa lỗi ngay tại con trỏ), phép so 2 đầu không tách
    // được hai chỗ đó — nó coi nguyên khoảng RỘNG giữa hai chỗ là "đã đổi
    // hết", dù phần lớn khoảng đó (kể cả một vùng định dạng thủ công nằm
    // trong đó) thực ra không hề đổi. Nhánh "kẹp về [vitri]" bên dưới, áp
    // dụng y hệt cho MỌI thứ rơi vào khoảng đó, biến một vùng đậm ở dòng 10
    // thành bắt đầu lại từ dòng 8 — nội dung không liên quan ở giữa (dòng 9)
    // bị cuốn theo, hiện đậm oan.
    //
    // Sửa: trước khi kẹp một đầu (đầu rơi vào khoảng KHÔNG chắc chắn), thử
    // XÁC MINH lại bằng chính nội dung CŨ/MỚI (nếu có) — nếu đoạn ký tự đó,
    // suy theo phép DỜI THUẦN (không kẹp), vẫn khớp y nguyên ở cả hai bên,
    // thì đoạn đó rõ ràng KHÔNG bị đổi thật, chỉ bị cuốn oan vào khoảng rộng
    // của phép so 2 đầu — dùng phép dời thuần cho đúng, đừng kẹp.
    for (final d in List<_VungDinhDangThuCong>.of(_boDieuKhien.dinhDang)) {
      var batDauMoi = d.batDau <= vitri
          ? d.batDau
          : (d.batDau >= ketThucXoa ? d.batDau + lech : vitri);
      var ketThucMoi = d.ketThuc <= vitri
          ? d.ketThuc
          : (d.ketThuc >= ketThucXoa ? d.ketThuc + lech : vitri);
      // CHỈ xác minh lại bằng nội dung khi vùng [d.batDau, d.ketThuc) THẬT SỰ
      // giao với khoảng [vitri, ketThucXoa) vừa bị so 2 đầu coi là "vùng
      // không chắc" (tức có ít nhất một đầu bị KẸP về [vitri] ở trên) — nếu
      // vùng nằm HẲN TRƯỚC (d.ketThuc <= vitri) hay HẲN SAU (d.batDau >=
      // ketThucXoa) thì batDauMoi/ketThucMoi ở trên đã CHẮC CHẮN đúng theo vị
      // trí rồi, không có gì mơ hồ để "xác minh" cả.
      //
      // BUG ĐÃ SỬA (mất định dạng khi gõ nhanh nhiều ký tự GIỐNG NHAU liên
      // tiếp, ví dụ "aaaaa" hay dấu cách lặp lại): thiếu điều kiện giao nhau
      // này, phép xác minh bằng nội dung so `vanBanCu.substring(d.batDau,
      // d.ketThuc)` với `vanBanMoi.substring(d.batDau+lech, d.ketThuc+lech)`
      // — với một dãy ký tự GIỐNG HỆT NHAU (chuỗi con toàn 'a' hay toàn dấu
      // cách), phép so này LUÔN khớp bất kể dịch đi bao xa, nên nó ghi đè cả
      // những vùng đã đúng theo vị trí (HẲN TRƯỚC chỗ sửa, không nên dịch
      // chút nào) bằng toạ độ dịch +lech sai — vùng bị "kéo" ra khỏi đúng chỗ
      // của nó, để lại một khoảng trống không còn vùng định dạng nào che phủ
      // ngay tại đầu dãy ký tự vừa gõ.
      if (d.ketThuc > vitri &&
          d.batDau < ketThucXoa &&
          vanBanCu != null &&
          vanBanMoi != null &&
          d.batDau >= 0 &&
          d.ketThuc <= vanBanCu.length &&
          d.batDau < d.ketThuc) {
        final batDauDoiChieu = d.batDau + lech;
        final ketThucDoiChieu = d.ketThuc + lech;
        if (batDauDoiChieu >= 0 &&
            ketThucDoiChieu <= vanBanMoi.length &&
            vanBanCu.substring(d.batDau, d.ketThuc) ==
                vanBanMoi.substring(batDauDoiChieu, ketThucDoiChieu)) {
          batDauMoi = batDauDoiChieu;
          ketThucMoi = ketThucDoiChieu;
        }
      }
      if (batDauMoi >= ketThucMoi) {
        _boDieuKhien.dinhDang.remove(d);
      } else {
        d.batDau = batDauMoi;
        d.ketThuc = ketThucMoi;
      }
    }
    // (VIỆC 5c) Dời/xoá offset đường kẻ chia — CÙNG PHÉP DỜI ĐƠN GIẢN đã
    // dùng cho `_boDieuKhien.loi` ở trên: offset rơi HẲN VÀO vùng vừa bị
    // xoá/đổi thì coi như dòng đó không còn giữ nguyên nữa, bỏ khỏi danh
    // sách; offset nằm SAU vùng đó thì dịch theo [lech]; offset nằm TRƯỚC
    // giữ nguyên.
    // (SỬA LỖI "đường kẻ nhường chỗ từ từ") CHỈ coi offset là "nằm sau vùng
    // sửa" khi nó THẬT SỰ lớn hơn [vitri] — không chỉ `>=`. Khi gõ/nói ĐÚNG
    // TẠI vị trí bắt đầu dòng đang có đường kẻ (chèn thuần, `soXoa == 0` nên
    // `ketThucXoa == vitri`), offset đó trước đây bị hiểu lầm là "nằm sau",
    // bị dịch tới +lech theo TỪNG ký tự vừa gõ — trông như đường kẻ "nhường
    // chỗ" dần cho chữ mới. Giữ offset ĐỨNG YÊN ở đúng [vitri] cho đúng
    // trường hợp biên này (khớp quy ước `d.batDau <= vitri` đã dùng cho vùng
    // định dạng thủ công ở trên) — khối "kiểm tra lại" ngay dưới sẽ tự đọc
    // đúng nội dung dòng đó (giờ không còn rỗng) và bỏ nó khỏi danh sách.
    _cacViTriDuongKeChia.removeWhere((v) => v > vitri && v < ketThucXoa);
    for (var i = 0; i < _cacViTriDuongKeChia.length; i++) {
      final v = _cacViTriDuongKeChia[i];
      if (v > vitri && v >= ketThucXoa) {
        _cacViTriDuongKeChia[i] = v + lech;
      }
    }
    // Kiểm tra lại các offset GẦN vị trí vừa sửa (không quét toàn danh
    // sách/toàn văn bản) — dòng đó không còn rỗng/toàn dấu cách nữa (người
    // dùng vừa gõ chữ vào) thì bỏ khỏi danh sách. Chỉ chạy khi có đủ văn bản
    // mới để tra cứu (không phải mọi lượt gọi `_dieuChinhLoiChinhTaSauKhiSua`
    // đều truyền `vanBanMoi`).
    if (vanBanMoi != null && _cacViTriDuongKeChia.isNotEmpty) {
      const phamViKiemTra = 200;
      final moc = vitri + lech;
      _cacViTriDuongKeChia.removeWhere((v) {
        if ((v - vitri).abs() > phamViKiemTra && (v - moc).abs() > phamViKiemTra) {
          return false;
        }
        if (v < 0 || v > vanBanMoi.length) return true;
        final ketThucDong = vanBanMoi.indexOf('\n', v);
        final dong = vanBanMoi.substring(v, ketThucDong == -1 ? vanBanMoi.length : ketThucDong);
        return dong.trim().isNotEmpty;
      });
    }

    // (SỬA LỖI đường kẻ không hiện lại) Khối trên chỉ XOÁ offset cũ khi dòng
    // không còn rỗng — chưa từng THÊM LẠI khi người dùng xoá ký tự làm một
    // dòng trở về rỗng/toàn dấu cách. Chỉ xét đúng dòng chứa vị trí vừa sửa
    // xong ([moc]) — đủ cho mọi lần xoá ký tự thực tế (Backspace/Delete
    // từng ký tự hay chọn+xoá trong một dòng) — và vẫn giữ đúng ràng buộc
    // dòng ĐẦU/CUỐI văn bản không bao giờ có đường kẻ (xem `_quetVaXayDungDuongKeChia`).
    if (widget.caiDat.tuDongThemDuongKeChia && vanBanMoi != null) {
      final moc = vitri + lech;
      if (moc >= 0 && moc <= vanBanMoi.length) {
        final batDauDong = moc <= 0 ? 0 : vanBanMoi.lastIndexOf('\n', moc - 1) + 1;
        final ketThucDong0 = vanBanMoi.indexOf('\n', batDauDong);
        final dong0 = vanBanMoi.substring(
            batDauDong, ketThucDong0 == -1 ? vanBanMoi.length : ketThucDong0);
        final laDongDauTien = batDauDong == 0;
        final laDongCuoiCung = ketThucDong0 == -1;
        if (dong0.trim().isEmpty && !laDongDauTien && !laDongCuoiCung) {
          _themViTriDuongKeChia(batDauDong);
        }
      }
    }

    // scheduleMicrotask, KHÔNG gọi notifyListeners() ngay tại đây: hàm này
    // chạy ngay bên trong _khiNguoiDungSua — chính nó là một listener của
    // _boDieuKhien. Gọi notifyListeners() đồng bộ ở đây sẽ gọi lại ngay lập
    // tức _khiNguoiDungSua một lần nữa trong khi lần gọi trước còn dang dở
    // (chuMoi lúc đó vẫn khác _chuGanNhat vì _ghiVaoO() chưa kịp chạy), tạo
    // vòng lặp đệ quy vô hạn — đúng nguyên nhân app đơ cứng khi gõ tay. Dời
    // việc thông báo ra một microtask thì nó chạy SAU KHI toàn bộ lệnh gọi
    // hiện tại (kể cả _ghiVaoO cập nhật _chuGanNhat) đã xong.
    scheduleMicrotask(_boDieuKhien.veLai);
  }

  /// (VIỆC 2, điểm iii/v) Gọi ngay SAU khi các vùng `dinhDang` đã được
  /// dời/nới theo phép chèn/xoá ở trên — [batDauChen, batDauChen+soChen) là
  /// đúng khoảng ký tự VỪA CHÈN trong văn bản mới [vanBanMoi]. Khoảng này có
  /// thể vừa được `_apDinhDangHopChoDoanMoiChen` gán treMu (nếu một trong
  /// hai bên "hợp 2 bên" đang mang treMu) — lọc ngay ký tự không hợp lệ ra
  /// khỏi treMu tại đây.
  ///
  /// Với mỗi vùng treMu giao với khoảng vừa chèn: ký tự nào không hợp lệ
  /// theo [_kyTuHopLeChoTreMu] bị TÁCH RA khỏi vùng treMu (tắt treMu CHỈ cho
  /// đúng ký tự đó, giữ nguyên các cờ định dạng khác nếu có) — không phải
  /// fallback co nhỏ, mà chặn hẳn treMu cho ký tự đó.
  ///
  /// O(số vùng treMu giao khoảng vừa chèn × độ dài khoảng đó) — khoảng vừa
  /// chèn thường chỉ 1 ký tự (gõ tay) hoặc một câu ngắn (giọng nói), không
  /// lặp lồng thêm vòng nào khác, không gọi trong buildTextSpan/paint.
  void _gioiHanTreMuSauKhiChen(int batDauChen, int soChen, String vanBanMoi) {
    if (soChen <= 0) return;
    final ketThucChen = batDauChen + soChen;
    if (ketThucChen > vanBanMoi.length) return;
    var coCanBao = false;
    for (final d in List<_VungDinhDangThuCong>.of(_boDieuKhien.dinhDang)) {
      if (!d.treMu) continue;
      final a = d.batDau < batDauChen ? batDauChen : d.batDau;
      final b = d.ketThuc > ketThucChen ? ketThucChen : d.ketThuc;
      if (a >= b) continue;
      var coKyTuXau = false;
      for (var i = a; i < b; i++) {
        if (!_kyTuHopLeChoTreMu(vanBanMoi[i])) {
          coKyTuXau = true;
          break;
        }
      }
      if (!coKyTuXau) continue;
      coCanBao = true;
      // Tách [d.batDau, d.ketThuc) thành: phần ngoài [a, b) giữ nguyên, và
      // bên trong [a, b) chia thành các đoạn con liên tục CÙNG trạng thái
      // hợp lệ — đoạn hợp lệ giữ treMu, đoạn không hợp lệ tắt treMu.
      _boDieuKhien.dinhDang.remove(d);
      if (d.batDau < a) {
        _boDieuKhien.dinhDang.add(_VungDinhDangThuCong(
          batDau: d.batDau,
          ketThuc: a,
          dam: d.dam,
          nghieng: d.nghieng,
          gachChan: d.gachChan,
          gachNgang: d.gachNgang,
          treMu: d.treMu,
          treChan: d.treChan,
          mauChu: d.mauChu,
          mauNen: d.mauNen,
        ));
      }
      var i = a;
      while (i < b) {
        final hopLe = _kyTuHopLeChoTreMu(vanBanMoi[i]);
        var j = i + 1;
        while (j < b && _kyTuHopLeChoTreMu(vanBanMoi[j]) == hopLe) {
          j++;
        }
        final vung = _VungDinhDangThuCong(
          batDau: i,
          ketThuc: j,
          dam: d.dam,
          nghieng: d.nghieng,
          gachChan: d.gachChan,
          gachNgang: d.gachNgang,
          treMu: hopLe,
          treChan: d.treChan,
          mauChu: d.mauChu,
          mauNen: d.mauNen,
        );
        if (!vung.rong) _boDieuKhien.dinhDang.add(vung);
        i = j;
      }
      if (d.ketThuc > b) {
        _boDieuKhien.dinhDang.add(_VungDinhDangThuCong(
          batDau: b,
          ketThuc: d.ketThuc,
          dam: d.dam,
          nghieng: d.nghieng,
          gachChan: d.gachChan,
          gachNgang: d.gachNgang,
          treMu: d.treMu,
          treChan: d.treChan,
          mauChu: d.mauChu,
          mauNen: d.mauNen,
        ));
      }
    }
    if (coCanBao) _baoLoiTreMu();
  }

  /// Đoạn CẦN THAY THẾ (đỏ, thuộc một `_VungKhongPhuHop` còn chờ quyết định)
  /// hoặc đoạn CẦN XOÁ (đỏ, một `_VungCanXoa` còn chờ) có đè vào khoảng
  /// [batDau, ketThuc) này không — hai loại đoạn này KHOÁ CỨNG, không cho
  /// gõ/xoá/chèn ký tự bên trong, chỉ bấm được để mở menu chấp nhận/huỷ.
  /// Đoạn ĐỀ XUẤT THAY THẾ (xanh) không nằm trong danh sách khoá — vẫn sửa
  /// tay thoải mái như đã thiết kế riêng.
  bool _dungVaoVungKhoa(int batDau, int ketThuc) {
    for (final k in _boDieuKhien.khongPhuHop) {
      if (k.nhapNhayMau != null) continue;
      if (batDau < k.ketThucGoc && ketThuc > k.batDauGoc) return true;
    }
    for (final x in _boDieuKhien.canXoa) {
      if (x.dangNhapNhay) continue;
      if (batDau < x.ketThuc && ketThuc > x.batDau) return true;
    }
    return false;
  }

  /// ĐIỀU CẤM KỴ của định dạng thủ công (mục B7): [batDau, ketThuc) có giao
  /// (dù chỉ một phần) với BẤT KỲ vùng AI nào không — lỗi chính tả, đoạn cần
  /// thay thế, đoạn đề xuất thay thế, hay đoạn cần xoá. Có giao thì cả thao
  /// tác định dạng bị BỎ QUA TOÀN BỘ (không áp phần nào), đơn giản và an toàn
  /// hơn hẳn so với cắt riêng phần nằm ngoài vùng AI.
  ///
  /// [boQuaTheTichChon]: bỏ qua kiểm tra vùng thẻ Tích chọn — dùng khi CHÍNH
  /// thao tác đang xét là bấm nút Tích chọn lên một đoạn ĐANG CÓ SẴN thẻ đó
  /// (`_bamNutTichChon`) — nếu không bỏ qua, đoạn nào có thẻ sẽ luôn tự coi
  /// là "bị khoá bởi chính thẻ của nó", không bao giờ toggle xoá được nữa.
  bool _giaoVoiVungAi(int batDau, int ketThuc, {bool boQuaTheTichChon = false}) {
    for (final l in _boDieuKhien.loi) {
      if (batDau < l.ketThuc && ketThuc > l.batDau) return true;
    }
    for (final k in _boDieuKhien.khongPhuHop) {
      if (batDau < k.ketThucGoc && ketThuc > k.batDauGoc) return true;
      if (batDau < k.ketThucDeXuat && ketThuc > k.batDauDeXuat) return true;
    }
    for (final x in _boDieuKhien.canXoa) {
      if (batDau < x.ketThuc && ketThuc > x.batDau) return true;
    }
    // Thẻ ghi âm cũng là một "vùng khoá" ngang hàng với vùng AI — định dạng
    // thủ công không được chồng lên nó (xem thảo luận về xung đột màu sắc
    // giữa thẻ ghi âm và định dạng văn bản).
    for (final (tb, tk) in timCacVungTheGhiAm(_boDieuKhien.text)) {
      if (batDau < tk && ketThuc > tb) return true;
    }
    // Thẻ Tích chọn cũng vậy — y hệt lý do trên (trừ khi [boQuaTheTichChon]).
    if (!boQuaTheTichChon) {
      for (final (tb, tk) in timCacVungTheTichChon(_boDieuKhien.text)) {
        if (batDau < tk && ketThuc > tb) return true;
      }
    }
    return false;
  }

  /// [viTri] đang nằm NGAY TRONG một đoạn bị khoá thì trả về biên GẦN NHẤT
  /// (đầu hoặc cuối đoạn đó) để đẩy con trỏ ra ngoài; không thì trả về
  /// nguyên [viTri].
  int _diemNgoaiVungKhoa(int viTri) {
    for (final k in _boDieuKhien.khongPhuHop) {
      if (k.nhapNhayMau != null) continue;
      if (viTri > k.batDauGoc && viTri < k.ketThucGoc) {
        return (viTri - k.batDauGoc) <= (k.ketThucGoc - viTri) ? k.batDauGoc : k.ketThucGoc;
      }
    }
    for (final x in _boDieuKhien.canXoa) {
      if (x.dangNhapNhay) continue;
      if (viTri > x.batDau && viTri < x.ketThuc) {
        return (viTri - x.batDau) <= (x.ketThuc - viTri) ? x.batDau : x.ketThuc;
      }
    }
    for (final (tb, tk) in timCacVungTheGhiAm(_boDieuKhien.text)) {
      if (viTri > tb && viTri < tk) {
        return (viTri - tb) <= (tk - viTri) ? tb : tk;
      }
    }
    return viTri;
  }

  /// Y hệt [_dieuChinhLoiChinhTaSauKhiSua] nhưng cho hai danh sách của lượt
  /// "Kiểm tra toàn văn": dời vùng nằm sau, bỏ vùng chồng lấn vào chỗ vừa
  /// sửa. [boQua] dùng khi CHÍNH thao tác đang xử lý một vùng gây ra sự thay
  /// đổi này (ví dụ chèn/xoá chữ của chính nó) — đừng tự bỏ nó khỏi danh
  /// sách của chính nó.
  void _dieuChinhVungToanVanSauKhiSua(int vitri, int soXoa, int soChen, {Object? boQua}) {
    if (soXoa == 0 && soChen == 0) return;
    final ketThucXoa = vitri + soXoa;
    final lech = soChen - soXoa;

    for (final k in List<_VungKhongPhuHop>.of(_boDieuKhien.khongPhuHop)) {
      if (identical(k, boQua)) continue;
      var bo = false;
      if (k.batDauGoc >= ketThucXoa) {
        k.batDauGoc += lech;
        k.ketThucGoc += lech;
      } else if (k.ketThucGoc > vitri) {
        bo = true;
      }
      if (!bo) {
        if (k.batDauDeXuat >= ketThucXoa) {
          k.batDauDeXuat += lech;
          k.ketThucDeXuat += lech;
        } else if (vitri >= k.batDauDeXuat &&
            ketThucXoa <= k.ketThucDeXuat &&
            k.nhapNhayMau == null) {
          // Sửa NẰM TRỌN bên trong đoạn đề xuất (xanh) — người dùng đang tự
          // tay chỉnh sửa đề xuất của AI (gõ tay/nói/xoá bớt sau khi bấm vào
          // đoạn xanh, xem `_khiBamDoanKhongPhuHop`). GIÃN đoạn đề xuất theo
          // đúng phần vừa thêm/bớt thay vì bỏ cả mục — để lúc bấm "Dùng đề
          // xuất này", đúng bản đã sửa (không phải bản AI trả về ban đầu) là
          // cái được giữ lại.
          k.ketThucDeXuat += lech;
          // Xoá sạch — không còn gì để thay thế nữa. Bỏ hẳn cả mục, đoạn CẦN
          // THAY THẾ (đỏ/vàng) bên cạnh trả về trạng thái bình thường, không
          // còn bị khoá — coi như AI chưa từng đề xuất gì ở đây.
          if (k.ketThucDeXuat <= k.batDauDeXuat) bo = true;
        } else if (k.ketThucDeXuat > vitri) {
          bo = true;
        }
      }
      if (bo) {
        k.henNhapNhay?.cancel();
        _boDieuKhien.khongPhuHop.remove(k);
      }
    }

    for (final x in List<_VungCanXoa>.of(_boDieuKhien.canXoa)) {
      if (identical(x, boQua)) continue;
      if (x.batDau >= ketThucXoa) {
        x.batDau += lech;
        x.ketThuc += lech;
      } else if (x.ketThuc > vitri) {
        x.henNhapNhay?.cancel();
        _boDieuKhien.canXoa.remove(x);
      }
    }

    scheduleMicrotask(_boDieuKhien.veLai);
  }

  /// Hẹn giờ gọi AI kiểm tra chính tả, dồn nhiều thay đổi liên tiếp (gõ từng
  /// phím, hay từng phần câu nói dội về) lại thành một lần gọi duy nhất khi
  /// mọi thứ đã tạm lắng — đúng lúc "vừa ra xong một câu văn mới".
  /// Lên lịch nếu MỘT TRONG HAI cài đặt AI (chính tả hoặc chèn dấu câu) đang
  /// bật — mục 3c: hai cài đặt này có thể bật độc lập nhau.
  void _lenLichKiemTraChinhTa() {
    if (!widget.caiDat.kiemTraChinhTaBangAI && !widget.caiDat.tuDongChenDauCauBangAI) return;
    _henChinhTa?.cancel();
    _henChinhTa = Timer(const Duration(milliseconds: 900), _kiemTraChinhTaMoi);
  }

  /// Số ký tự văn bản NGAY TRƯỚC đoạn mới, gửi kèm làm ngữ cảnh cho AI — đủ
  /// dài để bao được vài đoạn văn trước đó (không phải một câu cộc lốc, cũng
  /// không phải toàn bộ bài).
  static const _doDaiNguCanhChinhTa = 800;

  Future<void> _kiemTraChinhTaMoi() async {
    final layLoiChinhTa = widget.caiDat.kiemTraChinhTaBangAI;
    final chenDauCau = widget.caiDat.tuDongChenDauCauBangAI;
    if ((!layLoiChinhTa && !chenDauCau) || !mounted) return;

    final vanBan = _boDieuKhien.text;
    final tuViTri = _viTriDaKiemTraChinhTa.clamp(0, vanBan.length);
    if (tuViTri >= vanBan.length) return;

    final doan = vanBan.substring(tuViTri);
    if (doan.trim().isEmpty) {
      _viTriDaKiemTraChinhTa = vanBan.length;
      return;
    }
    final dauNguCanh = (tuViTri - _doDaiNguCanhChinhTa).clamp(0, tuViTri);
    final nguCanh = vanBan.substring(dauNguCanh, tuViTri);

    // (YÊU CẦU MỚI) Đã biết trước hôm nay chạm trần văn bản — im lặng bỏ
    // qua, KHÔNG gọi mạng (hộp thoại đã hiện đúng một lần lúc vừa chạm, xem
    // nhánh `LoiHanMucAi` dưới) — chạy ngầm lúc gõ nên không hiện lại mỗi câu.
    if (await doanDaChamHanMucAiHomNay(LoaiHanMucAi.vanBan) != null) return;

    KetQuaKiemTraChinhTaMoi ketQua;
    try {
      ketQua = await _dichVuChinhTa.kiemTra(
        doan,
        nguCanh: nguCanh,
        layLoiChinhTa: layLoiChinhTa,
        chenDauCau: chenDauCau,
      );
    } catch (e) {
      if (e is LoiHanMucAi) {
        await ghiNhoDaChamHanMucAi(e.loai, e.thongDiep);
        final daBaoRoi = await danhDauDaBaoTuDongHomNay(e.loai);
        if (!daBaoRoi && mounted) await hienHopThoaiHanMucAi(context, e.thongDiep);
      }
      return; // Mất mạng hay máy chủ lỗi — im lặng bỏ qua, lần sau thử lại.
    }
    if (!mounted) return;

    // Bài có thể đã đổi trong lúc chờ AI trả lời — chỉ áp dụng kết quả nếu
    // đúng nguyên đoạn vừa gửi vẫn còn ở đúng chỗ cũ.
    var vbHienTai = _boDieuKhien.text;
    if (tuViTri + doan.length > vbHienTai.length ||
        vbHienTai.substring(tuViTri, tuViTri + doan.length) != doan) {
      return;
    }

    // Từ/cụm từ người dùng đã tự tay xử lý (chấp nhận đề xuất, xoá, hoặc huỷ
    // đề xuất) trước đó thì không báo lỗi lại nữa, dù AI có tìm thấy y hệt —
    // cộng thêm từ đã từng bị "Huỷ đề xuất" ở TỪ ĐIỂN (mục 6: gạch đỏ/gạch
    // vàng không dẫm chân lên nhau, kể cả những từ đã từng có gạch rồi và
    // huỷ đề xuất rồi).
    final loiChuaXuLy = ketQua.loi
        .where((l) => !_tuChinhTaDaXuLy.contains(l.tu) && !_tuTuDienDaHuy.contains(l.tu))
        .toList();
    final loiDich = loiChuaXuLy
        .map((l) => l.dich(tuViTri))
        // Không gạch đỏ đè lên vùng ĐANG gạch vàng (từ điển) hiện có.
        .where((l) =>
            !_boDieuKhien.tuDien.any((d) => d.batDau < l.ketThuc && d.ketThuc > l.batDau))
        .toList();
    _boDieuKhien.loi.addAll(loiDich);

    // Dấu câu mới (mục 3d): chèn thẳng vào bài, không chờ người dùng quyết
    // định gì cả, rồi nhấp nháy nền xanh dương 4 giây. Dấu câu KHÔNG được
    // rơi vào một vùng chính tả vừa thêm ở trên (đã lọc từ phía máy chủ,
    // lọc lại lần nữa ở đây cho chắc — lưới bảo vệ hai lớp).
    if (ketQua.dauCauMoi.isNotEmpty) {
      // Từ cuối bài lên đầu để vị trí các mục chèn trước đó không bị lệch.
      final dsDich = ketQua.dauCauMoi
          .map((d) => (dauCau: d.dauCau, viTri: d.viTri + tuViTri))
          .toList()
        ..sort((a, b) => b.viTri.compareTo(a.viTri));
      for (final d in dsDich) {
        final chongLoi = loiDich.any((l) => d.viTri >= l.batDau && d.viTri <= l.ketThuc);
        if (chongLoi) continue;
        vbHienTai = _boDieuKhien.text;
        if (d.viTri < 0 || d.viTri > vbHienTai.length) continue;
        _dieuChinhLoiChinhTaSauKhiSua(d.viTri, 0, d.dauCau.length);
        _dieuChinhVungToanVanSauKhiSua(d.viTri, 0, d.dauCau.length);
        final moi = vbHienTai.replaceRange(d.viTri, d.viTri, d.dauCau);
        // (VIỆC 2, điểm vi) Dấu câu AI tự chèn không thể hợp lệ cho treMu —
        // lọc ngay nếu lỡ rơi vào một vùng treMu có sẵn.
        _gioiHanTreMuSauKhiChen(d.viTri, d.dauCau.length, moi);
        _ghiVaoO(moi, d.viTri + d.dauCau.length);
        final v = _VungDauCauMoi(batDau: d.viTri, ketThuc: d.viTri + d.dauCau.length);
        _boDieuKhien.dauCauMoi.add(v);
        _batNhapNhayDauCauMoi(v);
      }
    }

    _viTriDaKiemTraChinhTa = tuViTri + doan.length;
    _boDieuKhien.veLai();
    _henLuu();
  }

  /// Người dùng vừa bấm đúng vào một từ đang bị gạch đỏ — mở menu đề xuất.
  Future<void> _khiBamTuSai(LoiChinhTa loi, Offset viTriManHinh) async {
    final chon = await showMenu<(String, String?)>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: [
        for (final tu in loi.deXuat)
          PopupMenuItem(value: ('thay', tu), child: Text(tu)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ('xoa', null),
          child: Text(Ch.xoa(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
        ),
        PopupMenuItem(
          value: ('huy', null),
          child: Text(Ch.huyDeXuat(ngonNguHienTai.value), style: TextStyle(color: Colors.green.shade700)),
        ),
      ],
    );
    if (chon == null || !mounted) return;
    _luuDiemMoc();

    // Đã tự tay xử lý (chọn thay, xoá, hay huỷ) — đánh dấu để AI không báo
    // lại đúng từ/cụm từ này ở những lượt kiểm tra sau.
    _tuChinhTaDaXuLy.add(loi.tu);

    switch (chon.$1) {
      case 'thay':
        _apDungThayTheChinhTa(loi, chon.$2!);
      case 'xoa':
        _apDungThayTheChinhTa(loi, '');
      default: // 'huy'
        _boDieuKhien.loi.remove(loi);
        _boDieuKhien.veLai();
    }
  }

  /// Thay đúng vùng [loi.batDau, loi.ketThuc) bằng [thayBang] — dùng chung
  /// cho cả "chọn từ AI đề xuất" (thayBang là từ mới) và "Xoá" (thayBang
  /// rỗng).
  void _apDungThayTheChinhTa(LoiChinhTa loi, String thayBang) {
    final vb = _boDieuKhien.text;
    final conKhop = loi.ketThuc <= vb.length &&
        vb.substring(loi.batDau, loi.ketThuc) == loi.tu;
    if (!conKhop) {
      // Bài đã đổi từ lúc gạch đỏ này xuất hiện — bỏ đề xuất, không đụng gì
      // vào bài nữa vì không còn chắc đúng chỗ.
      _boDieuKhien.loi.remove(loi);
      _boDieuKhien.veLai();
      return;
    }

    final moi = vb.replaceRange(loi.batDau, loi.ketThuc, thayBang);
    _boDieuKhien.loi.remove(loi);
    _dieuChinhLoiChinhTaSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, thayBang.length);
    _dieuChinhVungToanVanSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, thayBang.length);
    // (VIỆC 2, điểm vi) Từ AI đề xuất thay chính tả có thể lọt vào vùng
    // treMu có sẵn — lọc ngay.
    _gioiHanTreMuSauKhiChen(loi.batDau, thayBang.length, moi);

    final viTri = loi.batDau + thayBang.length;
    _neo = viTri;
    _ghiVaoO(moi, viTri);
    _henLuu();
  }

  /// Menu của một từ gạch vàng lượn sóng (khớp "Từ điển sửa lỗi chính tả
  /// của bạn") — ĐÚNG KHUÔN `_khiBamTuSai` ở trên, chỉ khác mục đầu tiên:
  /// nếu [loi.thayThe] có chữ thì hiện đúng chữ đó, RỖNG thì hiện "Đề xuất
  /// Xoá" màu đỏ — cả hai trường hợp menu LUÔN có đúng 4 mục.
  /// (YÊU CẦU MỚI) Menu của một đoạn gạch chân xanh dương (trông như link)
  /// — hai mục: "Mở link" (tab mới trên web, trình duyệt ngoài trên APK —
  /// tự thêm `https://` phía trước nếu đoạn chỉ bắt đầu bằng `www.`) và
  /// "Đây không phải là link" (xoá gạch chân, nhớ KHÔNG gạch lại đoạn này
  /// nữa trong phiên soạn thảo tệp này — xem `_linkDaHuy`).
  Future<void> _khiBamLienKet(_VungLienKet vung, Offset viTriManHinh) async {
    final chon = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: [
        PopupMenuItem(value: 'mo', child: Text(Ch.moLink(ngonNguHienTai.value))),
        PopupMenuItem(
          value: 'khongPhaiLink',
          child: Text(Ch.dayKhongPhaiLaLink(ngonNguHienTai.value)),
        ),
      ],
    );
    if (chon == null || !mounted) return;
    switch (chon) {
      case 'mo':
        final url = vung.tu.toLowerCase().startsWith('http') ? vung.tu : 'https://${vung.tu}';
        moLienKetNgoai(url);
      default: // 'khongPhaiLink'
        _linkDaHuy.add(vung.tu);
        _boDieuKhien.lienKet.remove(vung);
        _boDieuKhien.veLai();
    }
  }

  Future<void> _khiBamTuDien(_LoiTuDien loi, Offset viTriManHinh) async {
    final coThayThe = loi.dsThayThe.isNotEmpty;
    // Mỗi đề xuất ("thứ nhất/hai/ba") thành MỘT mục riêng, LUÔN đứng ĐẦU
    // danh sách — giá trị mang theo chỉ số (0/1/2) để biết chọn đúng đề
    // xuất nào.
    final chon = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: [
        if (coThayThe)
          for (var i = 0; i < loi.dsThayThe.length; i++)
            PopupMenuItem(
              value: 'thay$i',
              child: Row(children: [
                const Icon(Icons.spellcheck, size: 18, color: Color(0xFF5F6368)),
                const SizedBox(width: 10),
                Text(loi.dsThayThe[i]),
              ]),
            )
        else
          PopupMenuItem(
            value: 'thay0',
            child: Row(children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
              const SizedBox(width: 10),
              Text(Ch.deXuatXoa(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
            ]),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'xoa',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
            const SizedBox(width: 10),
            Text(Ch.xoa(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
          ]),
        ),
        PopupMenuItem(
          value: 'huy',
          child: Row(children: [
            Icon(Icons.undo, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 10),
            Text(Ch.huyDeXuat(ngonNguHienTai.value), style: TextStyle(color: Colors.green.shade700)),
          ]),
        ),
        PopupMenuItem(
          value: 'chapNhanTatCa',
          child: Row(children: [
            Icon(Icons.done_all, size: 18, color: Color(0xFF5F6368)),
            SizedBox(width: 10),
            Text(Ch.chapNhanTatCaDeXuatTuDien(ngonNguHienTai.value)),
          ]),
        ),
        PopupMenuItem(
          value: 'chapNhanLienQuan',
          child: Row(children: [
            const Icon(Icons.done, size: 18, color: Color(0xFF5F6368)),
            const SizedBox(width: 10),
            Expanded(child: Text(Ch.chapNhanDeXuatLienQuan(ngonNguHienTai.value, loi.tu))),
          ]),
        ),
      ],
    );
    if (chon == null || !mounted) return;

    if (chon.startsWith('thay')) {
      final chiSo = int.parse(chon.substring(4));
      final thayBang = chiSo < loi.dsThayThe.length ? loi.dsThayThe[chiSo] : '';
      _luuDiemMoc();
      _apDungThayTheTuDien(loi, thayBang);
      return;
    }
    switch (chon) {
      case 'xoa':
        _luuDiemMoc();
        _apDungThayTheTuDien(loi, '');
      case 'chapNhanTatCa':
        _chapNhanTatCaDeXuatTuDien();
      case 'chapNhanLienQuan':
        _chapNhanDeXuatTuDienLienQuan(loi.tu);
      default: // 'huy'
        // Ghi nhớ CHỮ (không phải vị trí) đã huỷ — xem `_tuTuDienDaHuy`.
        _tuTuDienDaHuy.add(loi.tu);
        _boDieuKhien.tuDien.remove(loi);
        _boDieuKhien.veLai();
    }
  }

  /// Thay đúng vùng [loi.batDau, loi.ketThuc) bằng [thayBang] — ĐÚNG KHUÔN
  /// `_apDungThayTheChinhTa`, chỉ khác quét lại hẳn `_boDieuKhien.tuDien` từ
  /// đầu sau khi sửa (xem `_quetTuDienChinhTa`) thay vì tự dời offset —
  /// đơn giản hơn, và đúng vì các từ điển khác trong bài không hề di chuyển
  /// (không như `LoiChinhTa`, chỉ MỘT lượt AI trả về nên không có sẵn cách
  /// quét lại rẻ như vậy).
  void _apDungThayTheTuDien(_LoiTuDien loi, String thayBang) {
    final vb = _boDieuKhien.text;
    final conKhop =
        loi.ketThuc <= vb.length && vb.substring(loi.batDau, loi.ketThuc) == loi.tu;
    if (!conKhop) {
      _boDieuKhien.tuDien.remove(loi);
      _boDieuKhien.veLai();
      return;
    }

    final moi = vb.replaceRange(loi.batDau, loi.ketThuc, thayBang);
    _dieuChinhLoiChinhTaSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, thayBang.length);
    _dieuChinhVungToanVanSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, thayBang.length);
    _gioiHanTreMuSauKhiChen(loi.batDau, thayBang.length, moi);

    final viTri = loi.batDau + thayBang.length;
    _neo = viTri;
    _ghiVaoO(moi, viTri);
    _henLuu();
    _quetTuDienChinhTa();
  }

  /// Mục "Chấp nhận tất cả đề xuất của từ điển" — ép MỌI từ gạch vàng lượn
  /// sóng hiện có chọn ngay mục đầu tiên của chính nó (thay bằng
  /// [_LoiTuDien.thayThe], hoặc xoá hẳn nếu rỗng). Áp từ PHẢI sang TRÁI để
  /// toạ độ các đề xuất còn lại (nằm bên trái) không bị lệch khi một đề xuất
  /// bên phải được áp trước.
  void _chapNhanTatCaDeXuatTuDien() {
    if (_boDieuKhien.tuDien.isEmpty) return;
    _luuDiemMoc();
    final ds = List<_LoiTuDien>.of(_boDieuKhien.tuDien)
      ..sort((a, b) => b.batDau.compareTo(a.batDau));
    for (final loi in ds) {
      final vb = _boDieuKhien.text;
      if (loi.ketThuc > vb.length || vb.substring(loi.batDau, loi.ketThuc) != loi.tu) {
        continue;
      }
      final moi = vb.replaceRange(loi.batDau, loi.ketThuc, loi.thayThe);
      _dieuChinhLoiChinhTaSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, loi.thayThe.length);
      _dieuChinhVungToanVanSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, loi.thayThe.length);
      _gioiHanTreMuSauKhiChen(loi.batDau, loi.thayThe.length, moi);
      _ghiVaoO(moi, loi.batDau + loi.thayThe.length);
    }
    _henLuu();
    _quetTuDienChinhTa();
  }

  /// Mục "Chấp nhận các đề xuất liên quan đến "X"" — ĐÚNG KHUÔN
  /// `_chapNhanTatCaDeXuatTuDien`, chỉ khác giới hạn lại đúng những từ gạch
  /// vàng mang CHÍNH XÁC chữ [tuMucTieu] (nguyên văn, kể cả hoa/thường —
  /// đây là chữ THẬT đã khớp trong bài tại lúc bấm, không phải từ khai
  /// trong từ điển).
  void _chapNhanDeXuatTuDienLienQuan(String tuMucTieu) {
    final lienQuan =
        _boDieuKhien.tuDien.where((l) => l.tu == tuMucTieu).toList();
    if (lienQuan.isEmpty) return;
    _luuDiemMoc();
    final ds = List<_LoiTuDien>.of(lienQuan)
      ..sort((a, b) => b.batDau.compareTo(a.batDau));
    for (final loi in ds) {
      final vb = _boDieuKhien.text;
      if (loi.ketThuc > vb.length || vb.substring(loi.batDau, loi.ketThuc) != loi.tu) {
        continue;
      }
      final moi = vb.replaceRange(loi.batDau, loi.ketThuc, loi.thayThe);
      _dieuChinhLoiChinhTaSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, loi.thayThe.length);
      _dieuChinhVungToanVanSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, loi.thayThe.length);
      _gioiHanTreMuSauKhiChen(loi.batDau, loi.thayThe.length, moi);
      _ghiVaoO(moi, loi.batDau + loi.thayThe.length);
    }
    _henLuu();
    _quetTuDienChinhTa();
  }

  // ---------------------------------------------------- chèn chữ AI có nhấp nháy

  /// Chèn văn bản mới vào đúng vị trí con trỏ, rồi cho nó nhấp nháy xanh/đen
  /// 4 giây trước khi hoá đen như chữ thường — dùng lại nguyên cơ chế nhấp
  /// nháy của "đoạn không phù hợp" (coi như đoạn GỐC rỗng, chỉ có đoạn ĐỀ
  /// XUẤT, và nhảy thẳng vào trạng thái "đã chọn dùng đề xuất"). Dùng cho
  /// mọi chỗ chèn chữ AI thẳng vào bài (trước đây riêng cho "Ghi âm xong mới
  /// ra chữ", giờ dùng chung với cả thẻ ghi âm).
  void _chenVanBanVoiNhapNhay(String vanBanMoi) {
    _luuDiemMoc();

    final vb = _boDieuKhien.text;
    final chon = _boDieuKhien.selection;
    final viTri = (chon.isValid ? chon.end : vb.length).clamp(0, vb.length);

    var chen = vanBanMoi;
    if (viTri > 0 && !_laKhoangTrang(vb[viTri - 1])) chen = ' $chen';
    if (viTri < vb.length && !_laKhoangTrang(vb[viTri])) chen = '$chen ';

    _dieuChinhVungToanVanSauKhiSua(viTri, 0, chen.length);
    _dieuChinhLoiChinhTaSauKhiSua(viTri, 0, chen.length);

    final moi = vb.replaceRange(viTri, viTri, chen);
    // (VIỆC 2, điểm vi) Văn bản ghi âm AI chèn thẳng vào bài có thể lọt vào
    // vùng treMu có sẵn ngay tại con trỏ — lọc ngay.
    _gioiHanTreMuSauKhiChen(viTri, chen.length, moi);
    final viTriConTro = viTri + chen.length;
    _neo = viTriConTro;
    _ghiVaoO(moi, viTriConTro);
    _henLuu();

    final v = _VungKhongPhuHop(
      batDauGoc: viTri,
      ketThucGoc: viTri,
      batDauDeXuat: viTri,
      ketThucDeXuat: viTriConTro,
    );
    _boDieuKhien.khongPhuHop.add(v);
    _batNhapNhayKhongPhuHop(v, 'xanh');
  }

  // ------------------------------------------------- kiểm tra toàn văn bằng AI

  /// Bấm nút "Kiểm tra toàn văn bằng AI": gửi TOÀN BỘ văn bản hiện có lên
  /// máy chủ AI soát lại một lượt, trong lúc chờ hiện popup có thể bấm "Dừng
  /// ngay lập tức" để huỷ (kết quả về trễ vẫn bị vứt, không áp dụng gì cả).
  ///
  /// [loaiKiemTra]: `null` (mặc định) là bản ĐẦY ĐỦ như cũ. `'chinh_ta'`/
  /// `'dau_cau'` là hai mục riêng phía TRÊN mục này trong menu "Làm việc
  /// với AI" — ĐÚNG NGUYÊN cơ chế này (cùng popup "đang xử lý", cùng
  /// `_apDungKetQuaToanVan` vẽ gạch đỏ lượn sóng/tô dấu câu), chỉ khác
  /// dòng mô tả và việc CHỈ hỏi/nhận đúng một loại kết quả — xem
  /// `huongDanChiChinhTaToanVan`/`huongDanChiDauCauToanVan` trong
  /// cloud-function/index.js.
  Future<void> _khiBamKiemTraToanVan({String? loaiKiemTra}) async {
    if (_dangKiemTraToanVan) return;
    final vungChon = _vungDangChonHopLe();
    final vanBan = vungChon != null ? vungChon.textInside(_boDieuKhien.text) : _boDieuKhien.text;
    if (vanBan.trim().isEmpty) {
      _bao(vungChon != null
          ? Ch.doanDangChonTrongKhongCoGiDeKiemTra(ngonNguHienTai.value)
          : Ch.chuaCoVanBanNaoDeKiemTra(ngonNguHienTai.value));
      return;
    }
    if (!_coTheDungAIVoiVanBan(vanBan, coVungChon: vungChon != null)) return;
    if (await chanNeuDaChamHanMucAi(context, LoaiHanMucAi.vanBan)) return;

    final daHuy = ValueNotifier<bool>(false);
    setState(() => _dangKiemTraToanVan = true);

    final hauTo = vungChon != null
        ? Ch.hauToODoanDangChon(ngonNguHienTai.value)
        : Ch.hauToToanVan(ngonNguHienTai.value);
    final moTaDangXuLy =
        Ch.moTaDangXuLyKiemTra(loaiKiemTra, hauTo, ngonNguHienTai.value);

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              moTaDangXuLy,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () {
                daHuy.value = true;
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
              child: Text(Ch.dungNgayLapTuc(ngonNguHienTai.value)),
            ),
          ),
        ],
      ),
    ));

    KetQuaKiemTraToanVan? ketQua;
    Object? loiXayRa;
    try {
      ketQua = await _dichVuToanVan.kiemTra(
        vanBan,
        // Đang kiểm tra một ĐOẠN CHỌN (toạ độ cục bộ, bắt đầu từ 0) thì
        // "vùng đã xử lý" (toạ độ toàn văn của các lượt trước) không còn ý
        // nghĩa gì để so khớp — bỏ qua hẳn, không gửi lên.
        vungDaXuLy: vungChon != null ? const [] : _vungToanVanDaXuLy(),
        // "Chỉ dấu câu" LUÔN cần chenDauCau=true để nhánh phân tích
        // dauCauMoi ở `DichVuKiemTraToanVan.kiemTra` chạy — không phụ
        // thuộc cài đặt "Tự động chèn dấu câu" của người dùng.
        chenDauCau: loaiKiemTra == 'dau_cau'
            ? true
            : widget.caiDat.tuDongChenDauCauBangAI,
        khoangKyTu: widget.caiDat.khoangKyTuDeXuatHienTai(),
        cauLenhTuyChinh: widget.caiDat.cauLenhTuyChinhKiemTraToanVan,
        loaiKiemTra: loaiKiemTra,
      );
    } catch (e) {
      loiXayRa = e;
    }

    if (daHuy.value || !mounted) {
      if (mounted) setState(() => _dangKiemTraToanVan = false);
      return;
    }

    // Popup "đang kiểm tra" vẫn còn hiện (người dùng không bấm Dừng) — đóng
    // nó lại trước khi báo kết quả.
    Navigator.of(context, rootNavigator: true).pop();
    setState(() => _dangKiemTraToanVan = false);

    if (loiXayRa is LoiHanMucAi) {
      await ghiNhoDaChamHanMucAi(loiXayRa.loai, loiXayRa.thongDiep);
      if (mounted) await hienHopThoaiHanMucAi(context, loiXayRa.thongDiep);
      return;
    }
    if (loiXayRa != null || ketQua == null) {
      _bao(Ch.khongKiemTraDuoc(ngonNguHienTai.value, '$loiXayRa'));
      return;
    }

    _apDungKetQuaToanVan(
      vungChon != null ? _dichKetQuaToanVan(ketQua, vungChon.start) : ketQua,
    );
    _henLuu();
    _hienPopupXongTamThoi();
  }

  void _hienPopupXongTamThoi() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text(Ch.aiDaTraVeKetQua(ngonNguHienTai.value)),
            ],
          ),
        );
      },
    );
  }

  /// Mọi khoảng đã được đánh dấu bởi một lượt "Kiểm tra toàn văn" TRƯỚC ĐÓ
  /// (còn đang hiển thị: gạch đỏ chính tả, đoạn không phù hợp, đoạn cần
  /// xoá) — gửi kèm lên AI ở lượt kiểm tra tiếp theo để nó coi là NGỮ CẢNH
  /// THAM KHẢO đã xong việc, không đụng vào lại (mục 1). Không tính lỗi
  /// chính tả tự động lúc gõ (`_boDieuKhien.loi` ngoài phạm vi này, vì đó là
  /// một luồng riêng, cứ 900ms một lần, đã tự tránh gửi lại đoạn cũ bằng
  /// `_viTriDaKiemTraChinhTa`).
  List<VungDaXuLy> _vungToanVanDaXuLy() {
    final ds = <VungDaXuLy>[];
    for (final k in _boDieuKhien.khongPhuHop) {
      final batDau = k.batDauGoc < k.batDauDeXuat ? k.batDauGoc : k.batDauDeXuat;
      final ketThuc = k.ketThucGoc > k.ketThucDeXuat ? k.ketThucGoc : k.ketThucDeXuat;
      if (batDau < ketThuc) ds.add(VungDaXuLy(batDau, ketThuc));
    }
    for (final x in _boDieuKhien.canXoa) {
      ds.add(VungDaXuLy(x.batDau, x.ketThuc));
    }
    return ds;
  }

  /// Đưa kết quả AI vào văn bản thật: từ/cụm sai chính tả gạch đỏ như bình
  /// thường; đoạn "không phù hợp" thì CHÈN đoạn đề xuất ngay sau đoạn gốc
  /// (một chữ thật nằm trong bài, không phải chữ ảo vẽ đè lên); đoạn "cần
  /// xoá" chỉ đánh dấu, chưa xoá gì. Xử lý theo đúng thứ tự vị trí gốc (từ
  /// đầu bài tới cuối), cộng dồn độ lệch mỗi lần chèn thêm chữ — không thì
  /// các mục đứng sau sẽ trỏ nhầm chỗ.
  void _apDungKetQuaToanVan(KetQuaKiemTraToanVan kq) {
    // Một điểm mốc DUY NHẤT trước khi áp cả loạt kết quả — Lùi lại một lần
    // là xoá sạch mọi đề xuất AI vừa thêm, trả bài về y như trước khi bấm
    // "Kiểm tra toàn văn bằng AI".
    _luuDiemMoc();

    final tatCa = <_MucToanVan>[
      for (final c in kq.chinhTa) _MucChinhTaToanVan(c),
      for (final k in kq.khongPhuHop) _MucKhongPhuHopToanVan(k),
      for (final x in kq.canXoa) _MucCanXoaToanVan(x),
      for (final d in kq.dauCauMoi) _MucDauCauMoiToanVan(d),
    ]..sort((a, b) => a.viTri.compareTo(b.viTri));

    // Lưới bảo vệ phía app (mục 1): dù prompt đã dặn AI không đụng vào vùng
    // đã xử lý, nếu nó vẫn lỡ trả về một vùng mới chồng lên vùng CŨ đang
    // hiển thị, bỏ qua hẳn phần chồng lấn đó — giữ nguyên vùng cũ, không
    // merge/đè lên nhau. So khớp trên toạ độ văn bản GỐC (trước khi áp lượt
    // này), vì các vùng cũ không bị dời trong vòng lặp dưới đây.
    final vungCam = _vungToanVanDaXuLy();
    bool chongLenVungCam(int batDau, int ketThuc) =>
        vungCam.any((v) => batDau < v.ketThuc && ketThuc > v.batDau);

    var lech = 0;
    for (final muc in tatCa) {
      final vb = _boDieuKhien.text;
      final viTriThuc = muc.viTri + lech;
      if (viTriThuc < 0 || viTriThuc > vb.length) continue;

      switch (muc) {
        case _MucChinhTaToanVan(:final goc):
          final ketThuc = viTriThuc + goc.tu.length;
          if (ketThuc > vb.length || vb.substring(viTriThuc, ketThuc) != goc.tu) continue;
          if (chongLenVungCam(viTriThuc, ketThuc)) continue;
          // Gạch đỏ/gạch vàng không dẫm chân lên nhau (mục 6): bỏ qua nếu từ
          // này đang/đã từng gạch vàng (từ điển) VÀ bỏ qua nếu đang chồng lấn
          // một vùng gạch vàng hiện có.
          if (_tuChinhTaDaXuLy.contains(goc.tu) || _tuTuDienDaHuy.contains(goc.tu)) continue;
          if (_boDieuKhien.tuDien.any((d) => d.batDau < ketThuc && d.ketThuc > viTriThuc)) {
            continue;
          }
          _boDieuKhien.loi.add(LoiChinhTa(
            batDau: viTriThuc,
            ketThuc: ketThuc,
            tu: goc.tu,
            deXuat: goc.deXuat,
          ));

        case _MucKhongPhuHopToanVan(:final goc):
          final ketThucGoc = viTriThuc + goc.doan.length;
          if (ketThucGoc > vb.length || vb.substring(viTriThuc, ketThucGoc) != goc.doan) continue;
          if (chongLenVungCam(viTriThuc, ketThucGoc)) continue;
          final moi = vb.replaceRange(ketThucGoc, ketThucGoc, goc.deXuat);
          final viTriConTro = ketThucGoc + goc.deXuat.length;
          _ghiVaoO(moi, viTriConTro);
          _boDieuKhien.khongPhuHop.add(_VungKhongPhuHop(
            batDauGoc: viTriThuc,
            ketThucGoc: ketThucGoc,
            batDauDeXuat: ketThucGoc,
            ketThucDeXuat: viTriConTro,
          ));
          lech += goc.deXuat.length;

        case _MucCanXoaToanVan(:final goc):
          final ketThuc = viTriThuc + goc.doan.length;
          if (ketThuc > vb.length || vb.substring(viTriThuc, ketThuc) != goc.doan) continue;
          if (chongLenVungCam(viTriThuc, ketThuc)) continue;
          _boDieuKhien.canXoa.add(_VungCanXoa(batDau: viTriThuc, ketThuc: ketThuc));

        case _MucDauCauMoiToanVan(:final goc):
          if (chongLenVungCam(viTriThuc, viTriThuc)) continue;
          final moi = vb.replaceRange(viTriThuc, viTriThuc, goc.dauCau);
          final ketThuc = viTriThuc + goc.dauCau.length;
          _ghiVaoO(moi, ketThuc);
          final d = _VungDauCauMoi(batDau: viTriThuc, ketThuc: ketThuc);
          _boDieuKhien.dauCauMoi.add(d);
          _batNhapNhayDauCauMoi(d);
          lech += goc.dauCau.length;
      }
    }

    _boDieuKhien.veLai();
  }

  /// Bắt đầu nhấp nháy 4 giây (đổi giữa [mau] và màu chữ thường, mỗi 250ms)
  /// rồi tự hoá chữ đen như bình thường, xoá luôn khỏi danh sách.
  void _batNhapNhayKhongPhuHop(_VungKhongPhuHop v, String mau) {
    v.nhapNhayMau = mau;
    v.sangMau = true;
    v.henNhapNhay?.cancel();
    var dem = 0;
    v.henNhapNhay = Timer.periodic(const Duration(milliseconds: 250), (t) {
      dem++;
      v.sangMau = !v.sangMau;
      if (dem >= 16) {
        t.cancel();
        _boDieuKhien.khongPhuHop.remove(v);
      }
      if (mounted) _boDieuKhien.veLai();
    });
    _boDieuKhien.veLai();
  }

  void _batNhapNhayCanXoa(_VungCanXoa x) {
    x.dangNhapNhay = true;
    x.sangMau = true;
    x.henNhapNhay?.cancel();
    var dem = 0;
    x.henNhapNhay = Timer.periodic(const Duration(milliseconds: 250), (t) {
      dem++;
      x.sangMau = !x.sangMau;
      if (dem >= 16) {
        t.cancel();
        _boDieuKhien.canXoa.remove(x);
      }
      if (mounted) _boDieuKhien.veLai();
    });
    _boDieuKhien.veLai();
  }

  /// Bắt đầu hiệu ứng nền xanh dương nhấp nháy 4 giây (mục 3d) rồi tự dọn —
  /// hết hiệu ứng, chữ trở về bình thường, không còn "vùng đánh dấu" nào cả.
  void _batNhapNhayDauCauMoi(_VungDauCauMoi d) {
    d.sangMau = true;
    d.henNhapNhay?.cancel();
    var dem = 0;
    d.henNhapNhay = Timer.periodic(const Duration(milliseconds: 350), (t) {
      dem++;
      d.sangMau = !d.sangMau;
      if (dem >= 11) {
        // 11 * 350ms ≈ 3.85s — vòng cuối luôn tắt lại trước khi xoá hẳn.
        t.cancel();
        _boDieuKhien.dauCauMoi.remove(d);
      }
      if (mounted) _boDieuKhien.veLai();
    });
    _boDieuKhien.veLai();
  }

  /// (YÊU CẦU MỚI) Hiệu ứng nhấp nháy NỀN đoạn [batDau, ketThuc) vừa dán từ
  /// Bộ nhớ tạm/Từ điển nhập liệu nhanh — "mất đi hiện ra" nhanh, liên tục
  /// đúng 3 giây (15 nhịp × 200ms) rồi tự dọn, cùng khuôn
  /// `_batNhapNhayDauCauMoi` ở trên.
  void _batNhapNhayVungVuaDanTu(int batDau, int ketThuc) {
    if (batDau >= ketThuc) return;
    final d = _VungDauCauMoi(batDau: batDau, ketThuc: ketThuc);
    _boDieuKhien.vungVuaDanTu.add(d);
    d.sangMau = true;
    var dem = 0;
    d.henNhapNhay = Timer.periodic(const Duration(milliseconds: 200), (t) {
      dem++;
      d.sangMau = !d.sangMau;
      if (dem >= 15) {
        t.cancel();
        _boDieuKhien.vungVuaDanTu.remove(d);
      }
      if (mounted) _boDieuKhien.veLai();
    });
    _boDieuKhien.veLai();
  }

  /// Người dùng bấm vào đoạn ĐỀ XUẤT (xanh) cạnh một đoạn "không phù hợp".
  /// Đổi toạ độ MÀN HÌNH (nơi ngón tay vừa chạm) thành đúng vị trí ký tự
  /// trong bài, rồi đặt con trỏ ngay đó — dùng `RenderEditable
  /// .getPositionForPoint` (nhận thẳng toạ độ toàn cục, không cần tự quy
  /// đổi hệ trục). Chỉ áp dụng cho đoạn ĐỀ XUẤT THAY THẾ (xanh dương): người
  /// dùng bấm vào để mở menu, NHƯNG cũng có thể bấm xong rồi tự tay gõ/nói
  /// thêm để sửa lại đúng đề xuất đó trước khi quyết định — con trỏ phải
  /// nằm sẵn đúng chỗ thì mới gõ/nói chèn đúng vào đó được.
  void _datConTroTaiDiemCham(Offset viTriManHinh) {
    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null) return;
    final re = _timRenderEditable(hopVanBan);
    if (re == null || !re.hasSize) return;
    try {
      final viTri = re.getPositionForPoint(viTriManHinh);
      if (!_oChu.hasFocus) _oChu.requestFocus();
      _boDieuKhien.selection = TextSelection.collapsed(offset: viTri.offset);
    } catch (_) {
      // Render object chưa ổn định (đổi kích thước giữa chừng) — bỏ qua,
      // không chặn việc mở menu bên dưới.
    }
  }

  Future<void> _khiBamDoanKhongPhuHop(_VungKhongPhuHop v, Offset viTriManHinh) async {
    _datConTroTaiDiemCham(viTriManHinh);
    final chon = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: [
        PopupMenuItem(value: 'dung', child: Text(Ch.dungDeXuatNay(ngonNguHienTai.value))),
        PopupMenuItem(value: 'bo', child: Text(Ch.boDeXuatNayTraLaiNhuCu(ngonNguHienTai.value))),
      ],
    );
    if (chon == null || !mounted) return;
    if (!_boDieuKhien.khongPhuHop.contains(v)) return; // Văn bản đổi trong lúc mở menu.

    final vb = _boDieuKhien.text;
    if (v.ketThucDeXuat > vb.length) {
      _boDieuKhien.khongPhuHop.remove(v);
      _boDieuKhien.veLai();
      return;
    }

    _luuDiemMoc();

    if (chon == 'dung') {
      // Mục 6c: đoạn GỐC sắp bị xoá có đồng nhất định dạng thủ công không —
      // nếu có, đoạn ĐỀ XUẤT (giữ lại) kế thừa đúng tổ hợp đó. Phải đọc TRƯỚC
      // khi xoá đoạn gốc (đọc xong `_dinhDangDongNhatTrongVung` mới sửa
      // `dinhDang`), vì `_dieuChinhLoiChinhTaSauKhiSua` ngay sau đây sẽ tự
      // xoá/co các vùng định dạng đang giao với đoạn gốc.
      final dinhDangKeThua = _dinhDangDongNhatTrongVung(v.batDauGoc, v.ketThucGoc);
      // Xoá đoạn GỐC, giữ đoạn ĐỀ XUẤT — cho đoạn đề xuất nhấp nháy xanh/đen.
      final doDaiGoc = v.ketThucGoc - v.batDauGoc;
      final moi = vb.replaceRange(v.batDauGoc, v.ketThucGoc, '');
      _dieuChinhLoiChinhTaSauKhiSua(v.batDauGoc, doDaiGoc, 0);
      _dieuChinhVungToanVanSauKhiSua(v.batDauGoc, doDaiGoc, 0, boQua: v);
      v.ketThucGoc = v.batDauGoc;
      v.batDauDeXuat -= doDaiGoc;
      v.ketThucDeXuat -= doDaiGoc;
      if (dinhDangKeThua != null && v.batDauDeXuat < v.ketThucDeXuat) {
        _boDieuKhien.dinhDang.add(_VungDinhDangThuCong(
          batDau: v.batDauDeXuat,
          ketThuc: v.ketThucDeXuat,
          dam: dinhDangKeThua.dam,
          nghieng: dinhDangKeThua.nghieng,
          gachChan: dinhDangKeThua.gachChan,
          gachNgang: dinhDangKeThua.gachNgang,
          treMu: dinhDangKeThua.treMu,
          treChan: dinhDangKeThua.treChan,
          mauChu: dinhDangKeThua.mauChu,
          mauNen: dinhDangKeThua.mauNen,
        ));
        // (VIỆC 1) Đoạn ĐỀ XUẤT kế thừa treMu từ đoạn GỐC nhưng có thể mang
        // ký tự khác đoạn gốc (AI đề xuất thay bằng chữ khác) — khác với gõ
        // tay (nơi `_gioiHanTreMuSauKhiChen` tự TÁCH ký tự xấu ra khỏi vùng
        // treMu), đây là hành vi HỆ THỐNG tự động, không phải người dùng chủ
        // động bấm nút định dạng, nên CHO PHÉP lỗi hiển thị xảy ra (không
        // tách/xoá treMu khỏi ký tự không hợp lệ) — chỉ PHÁT HIỆN và cảnh báo
        // một lần bằng đúng dialog `_baoLoiTreMu()` (dùng chung cờ chống spam
        // `_dangHienLoiTreMu`), không quét liên tục sau đó.
        if (dinhDangKeThua.treMu) {
          var coKyTuXauKeThua = false;
          for (var i = v.batDauDeXuat; i < v.ketThucDeXuat; i++) {
            if (!_kyTuHopLeChoTreMu(moi[i])) {
              coKyTuXauKeThua = true;
              break;
            }
          }
          if (coKyTuXauKeThua) _baoLoiTreMu();
        }
      }
      _ghiVaoO(moi, v.ketThucDeXuat);
      _henLuu();
      _batNhapNhayKhongPhuHop(v, 'xanh');
    } else {
      // Xoá đoạn ĐỀ XUẤT, giữ đoạn GỐC — cho đoạn gốc nhấp nháy đỏ/đen.
      final doDaiDeXuat = v.ketThucDeXuat - v.batDauDeXuat;
      final moi = vb.replaceRange(v.batDauDeXuat, v.ketThucDeXuat, '');
      _dieuChinhLoiChinhTaSauKhiSua(v.batDauDeXuat, doDaiDeXuat, 0);
      _dieuChinhVungToanVanSauKhiSua(v.batDauDeXuat, doDaiDeXuat, 0, boQua: v);
      v.batDauDeXuat = v.ketThucDeXuat = v.ketThucGoc;
      _ghiVaoO(moi, v.ketThucGoc);
      _henLuu();
      _batNhapNhayKhongPhuHop(v, 'do');
    }
  }

  /// Người dùng bấm vào một đoạn AI đề xuất xoá.
  Future<void> _khiBamDoanCanXoa(_VungCanXoa x, Offset viTriManHinh) async {
    final chon = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'xoa',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: Color(0xFF5F6368)),
            SizedBox(width: 10),
            Text(Ch.chapNhanXoaDoanVanNay(ngonNguHienTai.value)),
          ]),
        ),
        PopupMenuItem(
          value: 'khoiphuc',
          child: Row(children: [
            Icon(Icons.restore, size: 18, color: Color(0xFF5F6368)),
            SizedBox(width: 10),
            Text(Ch.khoiPhucDoanVanNayKhongXoa(ngonNguHienTai.value)),
          ]),
        ),
      ],
    );
    if (chon == null || !mounted) return;
    if (!_boDieuKhien.canXoa.contains(x)) return;

    _luuDiemMoc();

    if (chon == 'xoa') {
      final vb = _boDieuKhien.text;
      if (x.ketThuc > vb.length) {
        _boDieuKhien.canXoa.remove(x);
        _boDieuKhien.veLai();
        return;
      }
      final doDai = x.ketThuc - x.batDau;
      final moi = vb.replaceRange(x.batDau, x.ketThuc, '');
      _dieuChinhLoiChinhTaSauKhiSua(x.batDau, doDai, 0);
      _dieuChinhVungToanVanSauKhiSua(x.batDau, doDai, 0, boQua: x);
      _boDieuKhien.canXoa.remove(x);
      _ghiVaoO(moi, x.batDau);
      _henLuu();
      _bao(Ch.daXoaDoanVan(ngonNguHienTai.value));
    } else {
      _batNhapNhayCanXoa(x);
    }
  }

  // ---------------------------------------------------- định dạng thủ công

  /// Trạng thái SÁNG/TẮT của 8 nút định dạng trên thanh công cụ — thuần tuý
  /// để VẼ nút, không phải "bộ nhớ đệm"/override nào cả. Luôn được ghi bởi
  /// `_tinhTrangThaiDinhDangHienTai`: khi vùng chọn rỗng, giá trị là HỢP (OR)
  /// định dạng của ký tự ngay TRƯỚC và ngay SAU con trỏ (xem
  /// `_dinhDangHopTaiViTri`); khi có vùng chọn, giá trị là "toàn vùng chọn
  /// đồng nhất định dạng đó hay không" (D1, không đổi). Bấm nút khi vùng
  /// chọn rỗng KHÔNG ghi vào các biến này — xem `_apDungDinhDang`.
  bool _damDangCho = false;
  bool _nghiengDangCho = false;
  bool _gachChanDangCho = false;
  bool _gachNganDangCho = false;
  bool _treMuDangCho = false;
  bool _treChanDangCho = false;

  // ------------------------------------------- bộ nhớ đệm định dạng (YÊU CẦU 2)
  //
  // KIẾN TRÚC MỚI (khác hẳn lần trước, cố ý): đây là MỘT BIẾN STATE THUẦN
  // TUÝ của Widget State, KHÔNG PHẢI một vùng `_VungDinhDangThuCong` 0-ký-tự
  // gắn ở con trỏ — không có mục nào được thêm vào `_boDieuKhien.dinhDang`
  // cho bộ nhớ đệm cả. Lỗi offset của kiến trúc cũ tới từ việc một "vùng"
  // 0-ký-tự phải được các hàm xử lý offset (đặc biệt
  // `_dieuChinhLoiChinhTaSauKhiSua`) dời/nới đúng theo mỗi phép sửa — kiến
  // trúc mới KHÔNG có offset nào để dời cả, nên hoàn toàn tách biệt khỏi cơ
  // chế đó: mỗi lần chèn ký tự, code chỉ ĐỌC giá trị hiện tại của
  // `_boNhoDem` rồi gán thẳng, xong việc, không "theo dõi" gì thêm.
  //
  // Kích hoạt: bấm nút/phím tắt định dạng lúc vùng chọn RỖNG (xem
  // `_bamNutDinhDangTaiConTro`). Huỷ: con trỏ bị NGƯỜI DÙNG di chuyển sang
  // vị trí khác — phân biệt với việc con trỏ tự dịch do CHÍNH việc gõ bằng
  // "cờ một lần" `_vuaChenKyTuBangBoNhoDem` (xem `_tinhTrangThaiDinhDangHienTai`
  // và `_apDungChinhSuaNguoiDung`/`_thayVungTamBangGiongNoi`).
  bool _boNhoDemDangHoatDong = false;
  _HopDinhDang? _boNhoDem;

  /// Cờ MỘT LẦN: đặt `true` ngay TRƯỚC khi `_apDungChinhSuaNguoiDung` hoặc
  /// `_thayVungTamBangGiongNoi` ghi ký tự mới vào `_boDieuKhien` (trước khi
  /// Flutter tự cập nhật `selection` và kích hoạt listener
  /// `_tinhTrangThaiDinhDangHienTai`). Callback đó đọc cờ này: `true` nghĩa
  /// là selection VỪA đổi là HỆ QUẢ của chính việc gõ (con trỏ tự dịch theo
  /// ký tự mới) — không phải người dùng chủ động di chuyển con trỏ — nên
  /// KHÔNG huỷ bộ nhớ đệm, chỉ đặt cờ về `false` để lần đổi selection TIẾP
  /// THEO (nếu không đi kèm một lượt gõ mới) được hiểu đúng là do người dùng
  /// bấm mũi tên/chạm màn hình và huỷ bộ nhớ đệm như bình thường.
  bool _vuaChenKyTuBangBoNhoDem = false;
  Color? _mauChuDangCho;
  Color? _mauNenDangCho;

  /// (VIỆC 1 — chống gọi trùng) `(văn bản, vùng chọn)` mà
  /// `_tinhTrangThaiDinhDangHienTai` vừa xử lý XONG gần nhất. `_ghiVaoO` tự
  /// gán `_boDieuKhien.value` NGAY BÊN TRONG `_apDungChinhSuaNguoiDung`/
  /// `_thayVungTamBangGiongNoi` — chính hai hàm đó lại đang chạy như là hệ
  /// quả của một lượt `notifyListeners()` GỐC do bàn phím/IME phát ra (chúng
  /// là listener của `_boDieuKhien`). Gán `.value` bên trong kích một lượt
  /// `notifyListeners()` LỒNG chạy hết toàn bộ danh sách listener (kể cả
  /// `_tinhTrangThaiDinhDangHienTai`) NGAY LẬP TỨC rồi mới trả quyền điều
  /// khiển lại cho lượt GỐC — lượt gốc sau đó tiếp tục gọi NỐT các listener
  /// còn lại của CHÍNH NÓ, tức là gọi lại `_tinhTrangThaiDinhDangHienTai` MỘT
  /// LẦN NỮA cho đúng một (văn bản, con trỏ) đã xử lý xong ở lượt lồng. Lượt
  /// lồng thấy đúng cờ `_vuaChenKyTuBangBoNhoDem == true` (đặt ngay trước khi
  /// gọi `_ghiVaoO`) nên giữ đúng bộ nhớ đệm; lượt gốc chạy SAU đó thấy cờ đã
  /// bị lượt lồng tiêu (`false`) nên hiểu NHẦM thành người dùng chủ động dời
  /// con trỏ và HUỶ OAN bộ nhớ đệm — đúng lúc ký tự tiếp theo cần nó. Ghi nhớ
  /// cặp giá trị vừa xử lý và bỏ qua ngay khi gặp lại y hệt là cách chặn gọn
  /// nhất, không phải sửa lại toàn bộ kiến trúc cờ một lần.
  String? _vanBanDaTinhDinhDang;
  TextSelection? _luaChonDaTinhDinhDang;

  /// Điểm vào chính của mọi nút/phím tắt định dạng. [loai] là một trong:
  /// 'dam', 'nghieng', 'gachChan', 'gachNgang', 'treMu', 'treChan', 'mauChu',
  /// 'mauNen', 'xoaDinhDang'. [mau] chỉ dùng cho 'mauChu'/'mauNen'.
  /// Đọc cờ boolean ứng với [loai] ('dam'/'nghieng'/'gachChan'/'gachNgang'/
  /// 'treMu'/'treChan') của một `_VungDinhDangThuCong` — dùng chung cho cả
  /// việc XÉT trạng thái (D3) và việc GHI trạng thái (D1) để không lặp code
  /// gán từng nhánh if/else ở nhiều nơi.
  bool _coCoDinhDang(_VungDinhDangThuCong d, String loai) {
    switch (loai) {
      case 'dam':
        return d.dam;
      case 'nghieng':
        return d.nghieng;
      case 'gachChan':
        return d.gachChan;
      case 'gachNgang':
        return d.gachNgang;
      case 'treMu':
        return d.treMu;
      case 'treChan':
        return d.treChan;
      default:
        return false;
    }
  }

  /// D1/D3: [batDau, ketThuc) có ĐỒNG NHẤT thoả [doc] không — nghĩa là MỌI
  /// ký tự trong vùng đều được một `_VungDinhDangThuCong` nào đó che phủ
  /// TRỌN VẸN và thoả [doc]. Chia vùng thành các đoạn con tại mọi biên của
  /// `dinhDang` giao với [batDau, ketThuc) (giống cách `buildTextSpan` và
  /// `_dinhDangDongNhatTrongVung` gộp OR nhiều vùng chồng lấn), rồi xét từng
  /// đoạn con — chỉ một đoạn con không thoả là coi cả vùng KHÔNG đồng nhất.
  bool _coDongNhatTrongVung(int batDau, int ketThuc, bool Function(_VungDinhDangThuCong) doc) {
    if (batDau >= ketThuc) return false;
    final diem = <int>{batDau, ketThuc};
    for (final d in _boDieuKhien.dinhDang) {
      if (d.batDau > batDau && d.batDau < ketThuc) diem.add(d.batDau);
      if (d.ketThuc > batDau && d.ketThuc < ketThuc) diem.add(d.ketThuc);
    }
    final moc = diem.toList()..sort();
    for (var i = 0; i < moc.length - 1; i++) {
      final a = moc[i], b = moc[i + 1];
      if (a >= b) continue;
      var co = false;
      for (final d in _boDieuKhien.dinhDang) {
        if (d.batDau <= a && d.ketThuc >= b && doc(d)) {
          co = true;
          break;
        }
      }
      if (!co) return false;
    }
    return true;
  }

  /// Lõi dùng chung cho mọi thao tác "ghi đè một thuộc tính định dạng lên
  /// TOÀN BỘ [batDau, ketThuc), GIỮ NGUYÊN mọi thuộc tính KHÁC của từng đoạn
  /// con" — [apDung] chỉ sửa đúng thuộc tính cần đổi trên bản sao cờ hiện có
  /// của mỗi đoạn con, không đụng gì khác. Khác `_xoaDinhDangTrongVung` (xoá
  /// sạch mọi định dạng): ở đây định dạng KHÁC của mỗi đoạn con phải được
  /// đọc ra và GIỮ LẠI trước khi phần giao với [batDau, ketThuc) bị gỡ khỏi
  /// danh sách, rồi mới thêm lại đoạn con đã áp [apDung].
  void _ghiDeDinhDangTrongVung(
    int batDau,
    int ketThuc,
    void Function(_VungDinhDangThuCong v) apDung,
  ) {
    if (batDau >= ketThuc) return;
    final ds = _boDieuKhien.dinhDang;
    final diem = <int>{batDau, ketThuc};
    for (final d in ds) {
      if (d.batDau > batDau && d.batDau < ketThuc) diem.add(d.batDau);
      if (d.ketThuc > batDau && d.ketThuc < ketThuc) diem.add(d.ketThuc);
    }
    final moc = diem.toList()..sort();

    // Chụp lại cờ ĐANG CÓ của mỗi đoạn con — PHẢI làm trước khi gỡ bất cứ gì
    // khỏi `ds` ở bước sau, không thì không còn gì để đọc.
    final doanCon = <_VungDinhDangThuCong>[];
    for (var i = 0; i < moc.length - 1; i++) {
      final a = moc[i], b = moc[i + 1];
      if (a >= b) continue;
      var dam = false, nghieng = false, gachChan = false, gachNgang = false, treMu = false, treChan = false;
      Color? mauChu;
      Color? mauNen;
      for (final d in ds) {
        if (d.batDau <= a && d.ketThuc >= b) {
          dam = dam || d.dam;
          nghieng = nghieng || d.nghieng;
          gachChan = gachChan || d.gachChan;
          gachNgang = gachNgang || d.gachNgang;
          treMu = treMu || d.treMu;
          treChan = treChan || d.treChan;
          mauChu = d.mauChu ?? mauChu;
          mauNen = d.mauNen ?? mauNen;
        }
      }
      doanCon.add(_VungDinhDangThuCong(
        batDau: a,
        ketThuc: b,
        dam: dam,
        nghieng: nghieng,
        gachChan: gachChan,
        gachNgang: gachNgang,
        treMu: treMu,
        treChan: treChan,
        mauChu: mauChu,
        mauNen: mauNen,
      ));
    }

    // Gỡ phần GIAO của mọi vùng cũ với [batDau, ketThuc), giữ lại phần nằm
    // NGOÀI — y hệt cách `_xoaDinhDangTrongVung` tách đôi vùng bị cắt đứt.
    final ngoai = <_VungDinhDangThuCong>[];
    for (final d in List<_VungDinhDangThuCong>.of(ds)) {
      if (d.ketThuc <= batDau || d.batDau >= ketThuc) continue;
      ds.remove(d);
      if (d.batDau < batDau) {
        ngoai.add(_VungDinhDangThuCong(
          batDau: d.batDau,
          ketThuc: batDau,
          dam: d.dam,
          nghieng: d.nghieng,
          gachChan: d.gachChan,
          gachNgang: d.gachNgang,
          treMu: d.treMu,
          treChan: d.treChan,
          mauChu: d.mauChu,
          mauNen: d.mauNen,
        ));
      }
      if (d.ketThuc > ketThuc) {
        ngoai.add(_VungDinhDangThuCong(
          batDau: ketThuc,
          ketThuc: d.ketThuc,
          dam: d.dam,
          nghieng: d.nghieng,
          gachChan: d.gachChan,
          gachNgang: d.gachNgang,
          treMu: d.treMu,
          treChan: d.treChan,
          mauChu: d.mauChu,
          mauNen: d.mauNen,
        ));
      }
    }
    ds.addAll(ngoai);

    // Áp [apDung] lên từng đoạn con rồi thêm lại — bỏ đoạn nào hoá "rỗng"
    // (không còn định dạng gì) để không tích rác trong danh sách.
    for (final v in doanCon) {
      apDung(v);
      if (!v.rong) ds.add(v);
    }
  }

  /// D1 (cờ boolean) + D2 (chữ trên/chữ dưới loại trừ nhau, thực thi ngay ở
  /// tầng DỮ LIỆU, không chỉ ở UI): đặt [loai] thành [giaTri] cho toàn bộ
  /// [batDau, ketThuc), giữ nguyên mọi cờ khác.
  void _datCoDinhDangTrongVung(int batDau, int ketThuc, String loai, bool giaTri) {
    _ghiDeDinhDangTrongVung(batDau, ketThuc, (v) {
      if (loai == 'dam') {
        v.dam = giaTri;
      } else if (loai == 'nghieng') {
        v.nghieng = giaTri;
      } else if (loai == 'gachChan') {
        v.gachChan = giaTri;
      } else if (loai == 'gachNgang') {
        v.gachNgang = giaTri;
      } else if (loai == 'treMu') {
        v.treMu = giaTri;
        // D2: chữ trên/chữ dưới loại trừ nhau — bật cái này thì tắt cái kia
        // NGAY Ở TẦNG DỮ LIỆU, không chỉ ở UI.
        if (giaTri) v.treChan = false;
      } else if (loai == 'treChan') {
        v.treChan = giaTri;
        if (giaTri) v.treMu = false;
      }
    });
  }

  /// Ranh giới đoạn văn (mỗi đoạn là văn bản giữa hai dấu `\n` liên tiếp,
  /// KHÔNG kể chính dấu `\n`) chứa vị trí [viTri] — dùng chung cho cả nút
  /// "Tích chọn" lẫn việc bấm-đổi-biểu-tượng của một thẻ đã có sẵn.
  (int, int) _ranhGioiDoanTaiViTri(String vb, int viTri) {
    var s = viTri.clamp(0, vb.length);
    while (s > 0 && vb.codeUnitAt(s - 1) != 0x0A) s--;
    var e = viTri.clamp(0, vb.length);
    while (e < vb.length && vb.codeUnitAt(e) != 0x0A) e++;
    return (s, e);
  }

  /// Đoạn văn [s, e) coi là RỖNG (tính năng Tích chọn "không thấy" để áp
  /// dụng) nếu bỏ token (nếu có) đi mà phần còn lại chỉ toàn dấu cách hoặc
  /// không còn gì — dùng chung cho cả nút Tích chọn lẫn dọn-tự-động.
  bool _doanRongChoTichChon(String noiDungDoan) {
    final khop = reTheTichChon.firstMatch(noiDungDoan);
    final phanChu =
        khop == null ? noiDungDoan : noiDungDoan.replaceRange(khop.start, khop.end, '');
    return phanChu.trim().isEmpty;
  }

  /// (YÊU CẦU MỚI) Chu kỳ hiện tại của nút "Aa" — mỗi lần bấm ĐƠN GIẢN (không
  /// qua menu thả xuống) dùng đúng kiểu này rồi tăng lên 1 (mod 4), luân
  /// phiên qua lại giữa 4 kiểu — xem `_apDungHoanDoiChuHoaThuong`.
  int _chuKyHoanDoiChuHoa = 0;

  /// Áp một trong 4 kiểu Hoa/thường lên vùng chọn hiện tại:
  /// 0 = Viết hoa chữ đầu MỖI TỪ; 1 = Viết hoa TẤT CẢ; 2 = Viết thường TẤT
  /// CẢ; 3 = Viết hoa chữ đầu CỦA TỪ ĐẦU TIÊN (những từ sau viết thường).
  /// [kieuCoDinh] khác `null` khi bấm chọn trực tiếp từ menu thả xuống —
  /// không đụng tới [_chuKyHoanDoiChuHoa] trong trường hợp đó, hai cách
  /// bấm (nút chính/menu) độc lập hẳn với nhau. Không có vùng chọn (hoặc
  /// vùng chọn rỗng) thì chỉ báo nhanh, không làm gì — không có "chữ thô"
  /// nào để mà xoá sạch dù kết quả không đổi 1-1 ký tự (đổi hoa/thường
  /// không bao giờ đổi ĐỘ DÀI chuỗi), nên không cần dời/co giãn `dinhDang`
  /// hay bất kỳ vùng AI nào khác — chỉ thay THẲNG đúng đoạn chữ đó.
  void _apDungHoanDoiChuHoaThuong({int? kieuCoDinh}) {
    final chon = _boDieuKhien.selection;
    if (!chon.isValid || chon.isCollapsed) {
      hienThongBaoGiua(
        context,
        'Chọn vùng văn bản trước khi hoán đổi chữ Hoa chữ thường',
      );
      return;
    }
    final kieu = kieuCoDinh ?? (_chuKyHoanDoiChuHoa % 4);
    if (kieuCoDinh == null) _chuKyHoanDoiChuHoa++;
    final batDau = chon.start, ketThuc = chon.end;
    final vb = _boDieuKhien.text;
    final doan = vb.substring(batDau, ketThuc);
    final doanMoi = _doiHoaThuongTheoKieu(doan, kieu);
    if (doanMoi == doan) return;
    _luuDiemMoc();
    final moi = vb.replaceRange(batDau, ketThuc, doanMoi);
    _ghiVaoO(moi, ketThuc);
    _boDieuKhien.selection = TextSelection(baseOffset: batDau, extentOffset: ketThuc);
    _henLuu();
    // (SỬA LỖI — màu tô vùng chọn "biến mất" sau khi bấm "Aa"/menu thả
    // xuống của nó) Bấm nút/mục menu làm ô soạn thảo mất tiêu điểm, Flutter
    // ngừng vẽ màu tô — vùng chọn ở trên vẫn ĐÚNG, chỉ cần tiêu điểm quay
    // lại để được vẽ ra. Dùng lại đúng hàm đã dùng cho Copy/Cắt/Dán/All và
    // menu "Làm việc với AI".
    _giuFocusOChuSauKhiBam();
  }

  String _doiHoaThuongTheoKieu(String doan, int kieu) {
    switch (kieu) {
      case 0:
        final buf = StringBuffer();
        var dauTu = true;
        for (final r in doan.runes) {
          final ch = String.fromCharCode(r);
          final trang = ch.trim().isEmpty;
          buf.write(dauTu && !trang ? ch.toUpperCase() : ch.toLowerCase());
          dauTu = trang;
        }
        return buf.toString();
      case 1:
        return doan.toUpperCase();
      case 2:
        return doan.toLowerCase();
      default:
        final thuong = doan.toLowerCase();
        for (var i = 0; i < thuong.length; i++) {
          if (thuong[i].trim().isNotEmpty) {
            return thuong.substring(0, i) + thuong[i].toUpperCase() + thuong.substring(i + 1);
          }
        }
        return thuong;
    }
  }

  /// Nút "Tích chọn" (✅) ở thanh định dạng thủ công — TOGGLE theo từng đoạn
  /// văn mà con trỏ/vùng chọn hiện đang chạm tới (vùng chọn trải nhiều đoạn
  /// thì áp dụng độc lập cho từng đoạn — kể cả đoạn đầu/cuối chưa được chọn
  /// hết): đoạn đã có sẵn thẻ (dùng đúng thẻ ĐẦU TIÊN nếu có nhiều thẻ do
  /// người dùng tự gõ/dán — thẻ thừa phía sau giữ nguyên, không đụng tới) —
  /// XOÁ thẻ đó, kèm bỏ gạch ngang cả đoạn nếu thẻ vừa xoá là ✅ (giống hệt
  /// side-effect của việc 🔲 xuất hiện); đoạn CHƯA có thẻ — THÊM ` (🔲) `
  /// vào đầu đoạn, ép cả đoạn (trừ thẻ) về KHÔNG gạch ngang. Bỏ qua (coi
  /// như không thấy) đoạn RỖNG (`_doanRongChoTichChon`) hoặc đang bị khoá
  /// bởi AI/thẻ ghi âm (`_giaoVoiVungAi`) — mỗi đoạn xét riêng, không chặn
  /// cả thao tác.
  void _bamNutTichChon() {
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _oChu.requestFocus();
      });
      return;
    }
    final vb = _boDieuKhien.text;
    final diemDau = chon.start, diemCuoi = chon.end;

    final danhSachDoan = <(int, int)>[];
    var batDauHienTai = 0;
    for (var i = 0; i <= vb.length; i++) {
      if (i == vb.length || vb.codeUnitAt(i) == 0x0A) {
        final s = batDauHienTai, e = i;
        if (s <= diemCuoi && e >= diemDau) danhSachDoan.add((s, e));
        batDauHienTai = i + 1;
      }
    }
    if (danhSachDoan.isEmpty) return;

    final dsHopLe = <(int, int)>[];
    for (final (s, e) in danhSachDoan) {
      if (_giaoVoiVungAi(s, e, boQuaTheTichChon: true)) continue;
      if (_doanRongChoTichChon(vb.substring(s, e))) continue;
      dsHopLe.add((s, e));
    }
    if (dsHopLe.isEmpty) {
      _bao('Không có đoạn văn nào hợp lệ để bật/tắt ô tích chọn (đoạn '
          'trống, hoặc đang bị khoá bởi AI/thẻ ghi âm).');
      return;
    }

    _luuDiemMoc();
    var moi = vb;
    var viTriConTroMoi = diemCuoi;

    // Xử lý từ đoạn CUỐI (offset lớn nhất) lùi về đầu — sửa ở một đoạn
    // không làm lệch offset của các đoạn đứng trước nó, nên không cần dồn
    // tính độ lệch qua từng bước.
    for (final (s, e) in dsHopLe.reversed) {
      final khopDau = reTheTichChon.firstMatch(moi.substring(s, e));
      int lech;
      int viTriSua;
      if (khopDau != null) {
        // Đã có thẻ ĐẦU — xoá nó (toggle tắt).
        final batDauT = s + khopDau.start, ketThucT = s + khopDau.end;
        final doDaiXoa = ketThucT - batDauT;
        final iconCu = khopDau.group(1)!;
        final vbTruoc = moi;
        moi = moi.replaceRange(batDauT, ketThucT, '');
        _dieuChinhVungToanVanSauKhiSua(batDauT, doDaiXoa, 0);
        _dieuChinhLoiChinhTaSauKhiSua(batDauT, doDaiXoa, 0,
            vanBanCu: vbTruoc, vanBanMoi: moi);
        if (iconCu == bieuTuongTichChonDaXong) {
          _datCoDinhDangTrongVung(s, e - doDaiXoa, 'gachNgang', false);
        }
        lech = -doDaiXoa;
        viTriSua = batDauT;
      } else {
        // Chưa có thẻ — thêm 🔲 vào đầu đoạn (toggle bật).
        final chen = nhanTheTichChon(bieuTuongTichChonChuaXong);
        final vbTruoc = moi;
        moi = moi.replaceRange(s, s, chen);
        _dieuChinhVungToanVanSauKhiSua(s, 0, chen.length);
        _dieuChinhLoiChinhTaSauKhiSua(s, 0, chen.length, vanBanCu: vbTruoc, vanBanMoi: moi);
        _datCoDinhDangTrongVung(s + chen.length, e + chen.length, 'gachNgang', false);
        lech = chen.length;
        viTriSua = s;
      }
      if (viTriSua <= viTriConTroMoi) viTriConTroMoi += lech;
    }
    _ghiVaoO(moi, viTriConTroMoi.clamp(0, moi.length));
    _boDieuKhien.veLai();
    _henLuu();
    _dongThanhDinhDangNeuChuaGhim();
  }

  /// Bấm vào một thẻ Tích chọn đã có (` (🔲) ` hoặc ` (✅) `, tại đúng
  /// [batDau, ketThuc) trong văn bản HIỆN TẠI) — đổi biểu tượng của ĐÚNG thẻ
  /// vừa bấm (dù nó có phải thẻ đầu tiên của đoạn hay không), rồi áp lại
  /// side-effect gạch ngang theo thẻ ĐẦU TIÊN của đoạn (sau khi đổi) — nếu
  /// thẻ vừa bấm không phải thẻ đầu, trạng thái đoạn coi như không đổi
  /// (nhưng vẫn áp lại cho chắc, vô hại). Không giả định thẻ luôn nằm ĐÚNG
  /// đầu đoạn (gõ thêm chữ ngay trước thẻ theo thời gian có thể làm nó trôi
  /// khỏi vị trí đầu), nên tìm lại ranh giới đoạn thật bằng
  /// `_ranhGioiDoanTaiViTri`.
  void _khiBamTheTichChon(int batDau, int ketThuc) {
    if (!mounted) return;
    final vb = _boDieuKhien.text;
    if (ketThuc > vb.length || batDau < 0 || batDau >= ketThuc) return;
    final doan = vb.substring(batDau, ketThuc);
    final khop = reTheTichChon.firstMatch(doan);
    if (khop == null || khop.start != 0 || khop.end != doan.length) return;

    final iconCu = khop.group(1)!;
    final iconMoi =
        iconCu == bieuTuongTichChonDaXong ? bieuTuongTichChonChuaXong : bieuTuongTichChonDaXong;
    final tokenMoi = nhanTheTichChon(iconMoi);
    final (s, e) = _ranhGioiDoanTaiViTri(vb, batDau);

    _luuDiemMoc();
    var vbSau = vb.replaceRange(batDau, ketThuc, tokenMoi);
    _dieuChinhVungToanVanSauKhiSua(batDau, doan.length, tokenMoi.length);
    _dieuChinhLoiChinhTaSauKhiSua(batDau, doan.length, tokenMoi.length,
        vanBanCu: vb, vanBanMoi: vbSau);

    final viTriConTroCuoi = batDau + tokenMoi.length;
    var eSau = e + (tokenMoi.length - doan.length);
    final khopDauMoi = reTheTichChon.firstMatch(vbSau.substring(s, eSau));
    if (khopDauMoi != null) {
      final batDauTokDau = s + khopDauMoi.start, ketThucTokDau = s + khopDauMoi.end;
      final apGachNgang = khopDauMoi.group(1)! == bieuTuongTichChonDaXong;
      _datCoDinhDangTrongVung(s, batDauTokDau, 'gachNgang', apGachNgang);

      if (apGachNgang) {
        // YÊU CẦU MỚI: vừa chuyển sang ✅ thì KHÔNG gạch ngang đè lên các
        // dấu cách ở CUỐI đoạn văn — tìm ranh giới "thân" đoạn (bỏ hết dấu
        // cách cuối cùng, nếu có). Không có dấu cách nào ở cuối cả thì tự
        // chèn thêm ĐÚNG một dấu cách rồi gạch ngang trừ dấu cách mới đó ra
        // — luôn đảm bảo có ít nhất một dấu cách cuối đoạn không bị gạch.
        var cuoiThan = eSau;
        while (cuoiThan > ketThucTokDau && vbSau[cuoiThan - 1] == ' ') {
          cuoiThan--;
        }
        if (cuoiThan == eSau) {
          vbSau = vbSau.substring(0, eSau) + ' ' + vbSau.substring(eSau);
          _dieuChinhVungToanVanSauKhiSua(eSau, 0, 1);
          _dieuChinhLoiChinhTaSauKhiSua(eSau, 0, 1);
          eSau += 1;
        }
        _datCoDinhDangTrongVung(ketThucTokDau, cuoiThan, 'gachNgang', true);
        _datCoDinhDangTrongVung(cuoiThan, eSau, 'gachNgang', false);
      } else {
        _datCoDinhDangTrongVung(ketThucTokDau, eSau, 'gachNgang', false);
      }
    }

    _ghiVaoO(vbSau, viTriConTroCuoi);
    _boDieuKhien.veLai();
    _henLuu();
  }

  /// Xoá một thẻ Tích chọn ✅ bằng bàn phím (Backspace/Delete chạm vào nó,
  /// tự "phóng to" xoá cả 5 ký tự — xem `ChanSuaGiuaTheTichChon`) — cùng
  /// side-effect "bỏ gạch ngang cả đoạn" như khi 🔲 xuất hiện, dù người
  /// dùng không hề bấm nút hay chạm vào thẻ. 🔲 bị xoá kiểu này thì không
  /// cần làm gì (đoạn vốn đã không gạch ngang).
  void _khiDaXoaTheTichChon(int viTri, String iconDaXoa) {
    if (!mounted || iconDaXoa != bieuTuongTichChonDaXong) return;
    final vb = _boDieuKhien.text;
    final (s, e) = _ranhGioiDoanTaiViTri(vb, viTri.clamp(0, vb.length));
    if (s >= e) return;
    if (vb.substring(s, e).trim().isEmpty) return; // đoạn đã rỗng — vô nghĩa.
    _luuDiemMocDinhDang();
    _datCoDinhDangTrongVung(s, e, 'gachNgang', false);
    _boDieuKhien.veLai();
    _henLuu();
  }

  /// Quét quanh hai vị trí [a]/[b] (thường là điểm bắt đầu/kết thúc của một
  /// lần sửa văn bản vừa xong) — đoạn văn nào ở đó đang có thẻ Tích chọn mà
  /// đã trở thành RỖNG (`_doanRongChoTichChon`, do người dùng xoá hết chữ
  /// xung quanh) thì tự xoá luôn thẻ đó, vì nó không còn ý nghĩa gì. Gọi sau
  /// MỌI lần đổi văn bản (gõ tay, Lùi lại/Tiến tới...) — chỉ quét quanh chỗ
  /// vừa đổi, không quét lại toàn bài, nên rất rẻ.
  void _donDepTheTichChonRongQuanhViTri(int a, int b) {
    for (final diem in {a, b}) {
      final vb = _boDieuKhien.text;
      if (diem < 0 || diem > vb.length) continue;
      final (s, e) = _ranhGioiDoanTaiViTri(vb, diem);
      if (s >= e) continue;
      final noiDung = vb.substring(s, e);
      if (!_doanRongChoTichChon(noiDung)) continue;
      final khop = reTheTichChon.firstMatch(noiDung);
      if (khop == null) continue; // đoạn rỗng nhưng vốn không có thẻ, bỏ qua.
      final batDauT = s + khop.start, ketThucT = s + khop.end;

      _luuDiemMoc();
      final vbSau = vb.replaceRange(batDauT, ketThucT, '');
      _dieuChinhVungToanVanSauKhiSua(batDauT, ketThucT - batDauT, 0);
      _dieuChinhLoiChinhTaSauKhiSua(batDauT, ketThucT - batDauT, 0,
          vanBanCu: vb, vanBanMoi: vbSau);
      final conTro = _boDieuKhien.selection.isValid
          ? _boDieuKhien.selection.start
          : vbSau.length;
      final conTroMoi =
          (conTro > batDauT ? conTro - (ketThucT - batDauT) : conTro).clamp(0, vbSau.length);
      _ghiVaoO(vbSau, conTroMoi);
      _boDieuKhien.veLai();
      _henLuu();
    }
  }

  /// D1 cho màu chữ/màu nền: đặt mauChu/mauNen thành [mau] (null = xoá) cho
  /// toàn bộ [batDau, ketThuc), giữ nguyên mọi cờ khác.
  void _datMauTrongVung(int batDau, int ketThuc, String loai, Color? mau) {
    _ghiDeDinhDangTrongVung(batDau, ketThuc, (v) {
      if (loai == 'mauChu') {
        v.mauChu = mau;
      } else {
        v.mauNen = mau;
      }
    });
  }

  void _apDungDinhDang(String loai, {Color? mau}) {
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _oChu.requestFocus();
      });
      return;
    }
    // YÊU CẦU 2a/3: vùng chọn RỖNG — KHÔNG còn "không làm gì" như trước nữa.
    // Bấm nút/phím tắt lúc này kích hoạt (hoặc cập nhật) bộ nhớ đệm định
    // dạng tại con trỏ, để lần gõ/nói tiếp theo mang đúng định dạng vừa
    // bấm. Không đụng `_boDieuKhien.dinhDang`, không lưu mốc lịch sử (chưa
    // có chữ nào đổi để mà lùi lại).
    if (chon.isCollapsed) {
      _bamNutDinhDangTaiConTro(loai, mau: mau);
      _dongThanhDinhDangNeuChuaGhim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _oChu.requestFocus();
      });
      return;
    }

    // Mục 5: mỗi lần áp/bỏ định dạng là MỘT mốc lịch sử riêng, để Ctrl+Z
    // hoàn tác đúng thao tác này (không đụng tới chữ, chỉ đụng `dinhDang`).
    _luuDiemMocDinhDang();
    final batDau = chon.start, ketThuc = chon.end;
    // ĐIỀU CẤM KỴ (B7): có giao với vùng AI thì bỏ qua TOÀN BỘ thao tác.
    if (_giaoVoiVungAi(batDau, ketThuc)) return;
    // Chặn treMu (chữ trên) nếu vùng chọn chứa BẤT KỲ ký tự nào không hợp
    // lệ (ngoài a-z/0-9) — chặn TOÀN BỘ thao tác, không áp cho cả những ký
    // tự hợp lệ nằm trong cùng vùng chọn. Chỉ cần kiểm tra khi vùng chọn
    // SẮP được chuyển sang mang treMu (không cần kiểm tra khi đang TẮT
    // treMu hoặc áp cờ khác). Một lượt duyệt O(độ dài vùng chọn), gọi đúng
    // MỘT LẦN tại đây — không lặp lại trong buildTextSpan/paint.
    if (loai == 'treMu') {
      final dangDongNhatTreMu = _coDongNhatTrongVung(batDau, ketThuc, (d) => d.treMu);
      if (!dangDongNhatTreMu) {
        final vb = _boDieuKhien.text;
        for (var i = batDau; i < ketThuc; i++) {
          if (!_kyTuHopLeChoTreMu(vb[i])) {
            _baoLoiTreMu();
            return;
          }
        }
      }
    }
    if (loai == 'xoaDinhDang') {
      _xoaDinhDangTrongVung(batDau, ketThuc);
    } else if (loai == 'mauChu' || loai == 'mauNen') {
      // D1 áp cho màu: bấm nút màu lần 1 → áp màu gần nhất; bấm lại lần 2
      // (vùng chọn đã đang mang ĐÚNG màu gần nhất đó, đồng nhất suốt vùng)
      // → xoá màu đó (trả về null), đúng quy tắc toggle chung — không có
      // logic riêng nào khác ngoài quy tắc này.
      final mauApDung = mau ?? (loai == 'mauChu' ? widget.caiDat.mauChuGanNhat : widget.caiDat.mauNenGanNhat);
      final dongNhatMauNay = _coDongNhatTrongVung(
        batDau,
        ketThuc,
        (d) => loai == 'mauChu' ? d.mauChu == mauApDung : d.mauNen == mauApDung,
      );
      _datMauTrongVung(batDau, ketThuc, loai, dongNhatMauNay ? null : mauApDung);
    } else {
      // D1 áp cho các cờ đậm/nghiêng/gạch chân/gạch ngang/chữ trên/chữ dưới:
      // vùng chọn ĐỒNG NHẤT đã có [loai] rồi thì bấm lại là TẮT; còn không
      // đồng nhất (hoặc chưa ai có) thì bấm là ÁP cho toàn vùng — đúng hành
      // vi chuẩn của Word/Google Docs, không phải luôn ÁP như trước (thiếu
      // nhánh TẮT).
      final dangDongNhatCo = _coDongNhatTrongVung(batDau, ketThuc, (d) => _coCoDinhDang(d, loai));
      _datCoDinhDangTrongVung(batDau, ketThuc, loai, !dangDongNhatCo);
    }
    // Áp định dạng không đổi độ dài văn bản, nên vùng chọn cũ vẫn còn hợp
    // lệ nguyên offset — bấm nút toolbar làm ô soạn thảo tạm mất focus (nút tự
    // nhận focus khi bấm) và có thể khiến vùng chọn bị co lại; đặt lại đúng
    // vùng cũ ở đây để nút toolbar giữ được vùng bôi đen giống hệt phím tắt
    // (phím tắt không rời focus khỏi ô soạn thảo nên không gặp vấn đề này).
    _boDieuKhien.selection = chon;
    // (VIỆC 3) `requestFocus()` gọi ngay trong `onPressed` có thể bị chính
    // IconButton GHI ĐÈ ngay sau đó — Flutter tự cho nút nhận focus khi bấm
    // (nút cũng là một focusable widget), và việc đó xảy ra SAU callback
    // `onPressed` trong cùng frame, nên con trỏ nháy biến mất dù `selection`
    // vẫn đúng offset. Hoãn `requestFocus()` sang `addPostFrameCallback` để
    // nó là hành động CUỐI CÙNG trong frame, thắng focus của nút. Phím tắt
    // (Shortcuts/Actions) không đi qua nhánh này vì TextField không hề rời
    // focus khi bấm phím.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
    });
    _boDieuKhien.veLai();
    _henLuu();
    _dongThanhDinhDangNeuChuaGhim();
  }

  /// YÊU CẦU 2a: bấm nút/phím tắt định dạng khi vùng chọn ĐANG RỖNG — tính
  /// TOGGLE đúng [loai] vừa bấm trên NỀN là bộ nhớ đệm hiện tại nếu nó đang
  /// hoạt động (để bấm B rồi bấm I liên tiếp mà chưa gõ gì cộng dồn được cả
  /// hai), hoặc trên nền "hợp 2 bên" tại con trỏ nếu bộ nhớ đệm CHƯA hoạt
  /// động — rồi CHỤP LẠI toàn bộ 8 thuộc tính vào `_boNhoDem`. Không lưu mốc
  /// lịch sử, không đụng `_boDieuKhien.dinhDang` (xem chú thích khai báo
  /// `_boNhoDemDangHoatDong`).
  void _bamNutDinhDangTaiConTro(String loai, {Color? mau}) {
    final vt = _boDieuKhien.selection.start;
    final nen = _boNhoDemDangHoatDong
        ? _boNhoDem!
        : _dinhDangHopTaiViTri(vt, vt, _boDieuKhien.text.length);

    var dam = nen.dam;
    var nghieng = nen.nghieng;
    var gachChan = nen.gachChan;
    var gachNgang = nen.gachNgang;
    var treMu = nen.treMu;
    var treChan = nen.treChan;
    var mauChu = nen.mauChu;
    var mauNen = nen.mauNen;

    switch (loai) {
      case 'dam':
        dam = !dam;
        break;
      case 'nghieng':
        nghieng = !nghieng;
        break;
      case 'gachChan':
        gachChan = !gachChan;
        break;
      case 'gachNgang':
        gachNgang = !gachNgang;
        break;
      case 'treMu':
        treMu = !treMu;
        // D2: chữ trên/chữ dưới loại trừ nhau — hệt `_datCoDinhDangTrongVung`.
        if (treMu) treChan = false;
        break;
      case 'treChan':
        treChan = !treChan;
        if (treChan) treMu = false;
        break;
      case 'mauChu':
        {
          final apDung = mau ?? widget.caiDat.mauChuGanNhat;
          mauChu = (mauChu == apDung) ? null : apDung;
        }
        break;
      case 'mauNen':
        {
          final apDung = mau ?? widget.caiDat.mauNenGanNhat;
          mauNen = (mauNen == apDung) ? null : apDung;
        }
        break;
      case 'xoaDinhDang':
        dam = false;
        nghieng = false;
        gachChan = false;
        gachNgang = false;
        treMu = false;
        treChan = false;
        mauChu = null;
        mauNen = null;
        break;
    }

    final ketQua = _chuanHoaXungDotTreMuTreChan((
      dam: dam,
      nghieng: nghieng,
      gachChan: gachChan,
      gachNgang: gachNgang,
      treMu: treMu,
      treChan: treChan,
      mauChu: mauChu,
      mauNen: mauNen,
    ));

    setState(() {
      _boNhoDem = ketQua;
      _boNhoDemDangHoatDong = true;
      _damDangCho = ketQua.dam;
      _nghiengDangCho = ketQua.nghieng;
      _gachChanDangCho = ketQua.gachChan;
      _gachNganDangCho = ketQua.gachNgang;
      _treMuDangCho = ketQua.treMu;
      _treChanDangCho = ketQua.treChan;
      _mauChuDangCho = ketQua.mauChu;
      _mauNenDangCho = ketQua.mauNen;
    });
  }

  /// Dự phòng (YÊU CẦU 2b): bộ nhớ đệm luôn toggle treMu/treChan loại trừ
  /// nhau ngay tại `_bamNutDinhDangTaiConTro`, nên về lý thuyết không bao
  /// giờ chứa cả hai `true` cùng lúc — NHƯNG nếu một lỗi logic nào đó (hiện
  /// tại chưa biết) vẫn để lọt trạng thái đó, hàm này là chốt chặn cuối:
  /// ưu tiên treMu (chữ trên), tắt treChan. Áp dụng cho MỌI [_HopDinhDang]
  /// trước khi dùng để gán cho ký tự mới chèn, dù nguồn là "hợp 2 bên" (đã
  /// tự loại trừ đúng ở `_dinhDangHopTaiViTri`) hay bộ nhớ đệm.
  _HopDinhDang _chuanHoaXungDotTreMuTreChan(_HopDinhDang h) {
    if (h.treMu && h.treChan) {
      return (
        dam: h.dam,
        nghieng: h.nghieng,
        gachChan: h.gachChan,
        gachNgang: h.gachNgang,
        treMu: true,
        treChan: false,
        mauChu: h.mauChu,
        mauNen: h.mauNen,
      );
    }
    return h;
  }

  /// D3: [batDau, ketThuc) có phải MỌI đoạn con đều mang CÙNG một giá trị
  /// màu (mauChu nếu [laMauChu], ngược lại mauNen) — trả về màu đó nếu đồng
  /// nhất và không null ở đâu, `null` nếu không (kể cả khi không ai có màu).
  /// Cùng cách chia đoạn con như `_coDongNhatTrongVung` — một lượt duyệt
  /// tuyến tính qua các mốc, không lặp lồng vòng lặp trên từng ký tự.
  Color? _mauDongNhatTrongVung(int batDau, int ketThuc, {required bool laMauChu}) {
    if (batDau >= ketThuc) return null;
    final diem = <int>{batDau, ketThuc};
    for (final d in _boDieuKhien.dinhDang) {
      if (d.batDau > batDau && d.batDau < ketThuc) diem.add(d.batDau);
      if (d.ketThuc > batDau && d.ketThuc < ketThuc) diem.add(d.ketThuc);
    }
    final moc = diem.toList()..sort();
    Color? chung;
    var coDoan = false;
    for (var i = 0; i < moc.length - 1; i++) {
      final a = moc[i], b = moc[i + 1];
      if (a >= b) continue;
      Color? mauDoan;
      for (final d in _boDieuKhien.dinhDang) {
        if (d.batDau <= a && d.ketThuc >= b) {
          mauDoan = laMauChu ? (d.mauChu ?? mauDoan) : (d.mauNen ?? mauDoan);
        }
      }
      if (mauDoan == null) return null;
      if (!coDoan) {
        chung = mauDoan;
        coDoan = true;
      } else if (chung != mauDoan) {
        return null;
      }
    }
    return coDoan ? chung : null;
  }

  /// NGUỒN DUY NHẤT của logic "kế thừa 2 bên": hợp (OR) riêng từng loại định
  /// dạng giữa ký tự ở [vtTrai - 1, vtTrai) (bên TRÁI) và ký tự ở
  /// [vtPhai, vtPhai + 1) (bên PHẢI) trong một văn bản dài [doDaiVanBan] ký
  /// tự — kể cả khi một trong hai bên là dấu cách mang định dạng ngầm, tra
  /// cứu y hệt ký tự thường qua `_coDongNhatTrongVung`/`_mauDongNhatTrongVung`,
  /// không có ngoại lệ. Thiếu một bên (đầu/cuối văn bản) thì chỉ dùng bên còn
  /// lại. [vtTrai] và [vtPhai] tách rời để gọi được cả hai cách:
  /// - Con trỏ ĐANG ĐỨNG tại [vt]: gọi `_dinhDangHopTaiViTri(vt, vt, doDai)`
  ///   (bên trái là ký tự ngay trước [vt], bên phải là ký tự ngay tại [vt]).
  /// - VỪA CHÈN/THAY [soXoa] ký tự tại [dau] (TRƯỚC khi các vùng `dinhDang`
  ///   bị dời/nới bởi `_dieuChinhLoiChinhTaSauKhiSua`): gọi
  ///   `_dinhDangHopTaiViTri(dau, dau + soXoa, cu.length)` — bên trái là ký
  ///   tự ngay trước điểm sửa, bên phải là ký tự ngay SAU đoạn vừa bị xoá
  ///   (đứng yên, không dịch chuyển bởi chính phép sửa này).
  ///
  /// KHÔNG dùng khi vùng chọn không rỗng — trường hợp đó dùng D1
  /// (`_coDongNhatTrongVung` áp cho TOÀN vùng chọn), giữ nguyên như cũ.
  _HopDinhDang _dinhDangHopTaiViTri(int vtTrai, int vtPhai, int doDaiVanBan) {
    final coTrai = vtTrai - 1 >= 0;
    final coPhai = vtPhai >= 0 && vtPhai < doDaiVanBan;

    bool hopCo(bool Function(_VungDinhDangThuCong) doc) {
      final trai = coTrai && _coDongNhatTrongVung(vtTrai - 1, vtTrai, doc);
      final phai = coPhai && _coDongNhatTrongVung(vtPhai, vtPhai + 1, doc);
      return trai || phai;
    }

    Color? hopMau({required bool laMauChu}) {
      final trai = coTrai ? _mauDongNhatTrongVung(vtTrai - 1, vtTrai, laMauChu: laMauChu) : null;
      if (trai != null) return trai;
      return coPhai ? _mauDongNhatTrongVung(vtPhai, vtPhai + 1, laMauChu: laMauChu) : null;
    }

    // YÊU CẦU 1 (sửa lỗi xung đột chữ trên/chữ dưới tại điểm chèn): treMu và
    // treChan là HAI ĐỊNH DẠNG LOẠI TRỪ NHAU (một ký tự không thể vừa
    // treMu vừa treChan — xem D2 ở `_datCoDinhDangTrongVung`). Nếu bên TRÁI
    // đang mang treMu VÀ bên PHẢI đang mang treChan (hoặc ngược lại), OR mù
    // quáng từng cờ riêng lẻ sẽ cho ra treMu=true VÀ treChan=true CÙNG LÚC —
    // không phải chữ trên, cũng không phải chữ dưới, chỉ còn lại tác dụng
    // phụ vô nghĩa (cỡ chữ bị thu nhỏ qua nhánh treChan trong khi
    // FontFeature 'sups' của treMu cũng bật, chồng lên nhau).
    //
    // Sửa: CHỈ RIÊNG cho cặp treMu/treChan, khi phát hiện xung đột kiểu này
    // thì bỏ hẳn quy tắc OR — LUÔN ưu tiên định dạng của bên PHẢI (ký tự
    // chèn vào đứng ngay trước bên phải, "nối vào" đoạn bên phải một cách tự
    // nhiên hơn là đoạn bên trái đã kết thúc). Các định dạng KHÁC (đậm,
    // nghiêng, gạch chân, gạch ngang, màu chữ, màu nền) không hề đổi — vẫn
    // OR (hợp 2 bên) bình thường như trước.
    final traiTreMu = coTrai && _coDongNhatTrongVung(vtTrai - 1, vtTrai, (d) => d.treMu);
    final traiTreChan = coTrai && _coDongNhatTrongVung(vtTrai - 1, vtTrai, (d) => d.treChan);
    final phaiTreMu = coPhai && _coDongNhatTrongVung(vtPhai, vtPhai + 1, (d) => d.treMu);
    final phaiTreChan = coPhai && _coDongNhatTrongVung(vtPhai, vtPhai + 1, (d) => d.treChan);
    final xungDotTreMuTreChan = (traiTreMu && phaiTreChan) || (traiTreChan && phaiTreMu);
    final bool treMuKetQua;
    final bool treChanKetQua;
    if (xungDotTreMuTreChan) {
      treMuKetQua = phaiTreMu;
      treChanKetQua = phaiTreChan;
    } else {
      treMuKetQua = traiTreMu || phaiTreMu;
      treChanKetQua = traiTreChan || phaiTreChan;
    }

    return (
      dam: hopCo((d) => d.dam),
      nghieng: hopCo((d) => d.nghieng),
      gachChan: hopCo((d) => d.gachChan),
      gachNgang: hopCo((d) => d.gachNgang),
      treMu: treMuKetQua,
      treChan: treChanKetQua,
      mauChu: hopMau(laMauChu: true),
      mauNen: hopMau(laMauChu: false),
    );
  }

  /// Gán [hop] (kết quả `_dinhDangHopTaiViTri` tính TRƯỚC khi chèn) cho đúng
  /// đoạn [batDau, ketThuc) vừa được chèn vào văn bản — GHI ĐÈ toàn bộ 8
  /// thuộc tính, không quan tâm đoạn đó vừa "kế thừa" được gì một cách tự
  /// nhiên qua phép nới vùng của `_dieuChinhLoiChinhTaSauKhiSua` (có thể chỉ
  /// đúng MỘT bên, không phải hợp cả hai) — đây là bước áp cuối cùng, đảm bảo
  /// luôn đúng "hợp 2 bên" bất kể cách nới ở tầng dưới.
  void _apDinhDangHopChoDoanMoiChen(int batDau, int ketThuc, _HopDinhDang hop) {
    _ghiDeDinhDangTrongVung(batDau, ketThuc, (v) {
      v
        ..dam = hop.dam
        ..nghieng = hop.nghieng
        ..gachChan = hop.gachChan
        ..gachNgang = hop.gachNgang
        ..treMu = hop.treMu
        ..treChan = hop.treChan
        ..mauChu = hop.mauChu
        ..mauNen = hop.mauNen;
    });
  }

  /// D3: tính trạng thái 8 loại định dạng (dam/nghieng/gachChan/gachNgang/
  /// treMu/treChan/mauChu/mauNen) cho vị trí/vùng chọn HIỆN TẠI, rồi GHI vào
  /// đúng các cờ `_xxxDangCho` mà thanh công cụ đang đọc để tô sáng nút —
  /// tái dùng luôn các cờ có sẵn, không thêm biến trạng thái mới cho UI.
  ///
  /// - Vùng chọn KHÔNG rỗng: đồng nhất trên TOÀN vùng chọn (`_coDongNhatTrongVung`,
  ///   D1 — không đổi).
  /// - Vùng chọn rỗng: gọi thẳng `_dinhDangHopTaiViTri` — hợp (OR) định dạng
  ///   của ký tự ngay TRƯỚC và ngay SAU con trỏ. KHÔNG còn "bộ nhớ đệm"/
  ///   override nào chen vào nữa — đây là nguồn DUY NHẤT.
  ///
  /// O(k) với k = số `_VungDinhDangThuCong` giao vùng đang xét (thường vài
  /// chục vùng) — không quét toàn văn bản, không lặp lồng vòng lặp trên mỗi
  /// ký tự, an toàn gọi mỗi lần selection đổi (kể cả mỗi lần gõ phím).
  void _tinhTrangThaiDinhDangHienTai() {
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) return;

    // (VIỆC 1 — chống gọi trùng, xem giải thích tại khai báo hai biến) Lượt
    // gọi thứ hai cho đúng CÙNG một (văn bản, vùng chọn) là hệ quả của việc
    // `notifyListeners()` LỒNG bên trong lượt gốc — bỏ qua thẳng, đừng chạm
    // tới cờ `_vuaChenKyTuBangBoNhoDem`/`_boNhoDemDangHoatDong` ở dưới, vì
    // lượt đầu (lồng) đã xử lý đúng và đủ rồi.
    final vanBanHienTai = _boDieuKhien.text;
    if (vanBanHienTai == _vanBanDaTinhDinhDang && chon == _luaChonDaTinhDinhDang) {
      return;
    }
    // (SỬA LỖI — "mic ngắt tiếng sau khi ngừng nói vài giây, phải chạm/gõ
    // tay mới chịu bắt lại") Bản trước ở ĐÂY có thêm một nhánh: hễ vùng
    // chọn đổi mà chữ không đổi, trong lúc mic đang nghe, là gọi thẳng
    // `_nguoiDungVuaGo()` (NGẮT HẲN phiên đang nghe, hẹn giờ bật lại sau
    // vài giây theo "Cài đặt Micro"). Ý định đúng là bắt lượt KÉO CHỌN/
    // MŨI TÊN thật — nhưng hàm này chạy trên MỌI `notifyListeners()` của
    // `_boDieuKhien`, kể cả những lượt không phải người dùng chủ động đổi
    // vùng chọn (ví dụ dội lại từ chính bộ điều khiển trong lúc mic đang
    // yên, không có gì đổi thật) — gọi `_nguoiDungVuaGo()` nhầm sẽ ngắt
    // hẳn phiên mic đang nghe mà không ai biết, chỉ còn lại hẹn giờ bật
    // lại cỡ vài giây — ĐÚNG triệu chứng người dùng báo: nói liên tục thì
    // không sao (chữ luôn đổi, không rơi vào nhánh này), ngừng vài giây
    // rồi nói lại thì im bặt (đã bị ngắt từ lúc ngừng, dù nút vẫn hiện
    // "đang nghe" vì UI của `_nguoiDungVuaGo` tự bật lại rất nhanh).
    //
    // `_khiNguoiDungSua` (đăng ký RIÊNG, cũng nghe `_boDieuKhien`) đã tự xử
    // lý đúng và AN TOÀN hơn nhiều cho đúng trường hợp "chữ không đổi,
    // vùng chọn đổi" này từ trước — có hẳn hai lớp chặn dội ngược
    // (`trungKhit`/`vuaGhiXong`) để không tưởng nhầm chính bộ điều khiển
    // của mình là người dùng, và xử lý NHẸ TAY (chỉ đóng băng đoạn đang
    // nhảy + dời neo, KHÔNG ngắt hẳn phiên nghe) cho cả lúc kéo chọn
    // (`!chon.isCollapsed`) và dời con trỏ bằng mũi tên. Bỏ hẳn nhánh thêm
    // ở đây — nó chỉ trùng lặp có hại, không cần thiết. Lượt CHẠM đúng tại
    // vị trí con trỏ cũ (chữ và vùng chọn đều không đổi, nên không hàm nào
    // ở đây bắt được) đã có `onTap` riêng của `TextField` xử lý.
    _vanBanDaTinhDinhDang = vanBanHienTai;
    _luaChonDaTinhDinhDang = chon;

    // YÊU CẦU 2c (cờ một lần): mọi lần selection đổi mà KHÔNG phải hệ quả
    // trực tiếp của chính việc chèn ký tự (bộ nhớ đệm đang hoạt động) đều
    // coi là người dùng CHỦ ĐỘNG di chuyển con trỏ (mũi tên, chạm màn hình,
    // click chuột...) → huỷ bộ nhớ đệm ngay. Đặt ở ĐẦU hàm, trước cả nhánh
    // vùng chọn rỗng/không rỗng, vì cả hai trường hợp đều là "con trỏ không
    // còn ở đúng chỗ bộ nhớ đệm được kích hoạt" theo đúng nghĩa của yêu cầu.
    if (_boNhoDemDangHoatDong) {
      if (_vuaChenKyTuBangBoNhoDem) {
        _vuaChenKyTuBangBoNhoDem = false;
      } else {
        _boNhoDemDangHoatDong = false;
        _boNhoDem = null;
      }
    }

    int batDau;
    int ketThuc;
    if (!chon.isCollapsed) {
      batDau = chon.start;
      ketThuc = chon.end;
    } else {
      final vt = chon.start;
      final hop = _dinhDangHopTaiViTri(vt, vt, _boDieuKhien.text.length);
      if (hop.dam == _damDangCho &&
          hop.nghieng == _nghiengDangCho &&
          hop.gachChan == _gachChanDangCho &&
          hop.gachNgang == _gachNganDangCho &&
          hop.treMu == _treMuDangCho &&
          hop.treChan == _treChanDangCho &&
          hop.mauChu == _mauChuDangCho &&
          hop.mauNen == _mauNenDangCho) {
        return; // Không đổi gì — khỏi setState vô ích.
      }
      setState(() {
        _damDangCho = hop.dam;
        _nghiengDangCho = hop.nghieng;
        _gachChanDangCho = hop.gachChan;
        _gachNganDangCho = hop.gachNgang;
        _treMuDangCho = hop.treMu;
        _treChanDangCho = hop.treChan;
        _mauChuDangCho = hop.mauChu;
        _mauNenDangCho = hop.mauNen;
      });
      return;
    }
    final dam = _coDongNhatTrongVung(batDau, ketThuc, (d) => d.dam);
    final nghieng = _coDongNhatTrongVung(batDau, ketThuc, (d) => d.nghieng);
    final gachChan = _coDongNhatTrongVung(batDau, ketThuc, (d) => d.gachChan);
    final gachNgang = _coDongNhatTrongVung(batDau, ketThuc, (d) => d.gachNgang);
    final treMu = _coDongNhatTrongVung(batDau, ketThuc, (d) => d.treMu);
    final treChan = _coDongNhatTrongVung(batDau, ketThuc, (d) => d.treChan);
    final mauChu = _mauDongNhatTrongVung(batDau, ketThuc, laMauChu: true);
    final mauNen = _mauDongNhatTrongVung(batDau, ketThuc, laMauChu: false);
    if (dam == _damDangCho &&
        nghieng == _nghiengDangCho &&
        gachChan == _gachChanDangCho &&
        gachNgang == _gachNganDangCho &&
        treMu == _treMuDangCho &&
        treChan == _treChanDangCho &&
        mauChu == _mauChuDangCho &&
        mauNen == _mauNenDangCho) {
      return; // Không đổi gì — khỏi setState vô ích.
    }
    setState(() {
      _damDangCho = dam;
      _nghiengDangCho = nghieng;
      _gachChanDangCho = gachChan;
      _gachNganDangCho = gachNgang;
      _treMuDangCho = treMu;
      _treChanDangCho = treChan;
      _mauChuDangCho = mauChu;
      _mauNenDangCho = mauNen;
    });
  }

  /// Mục 6c: [batDau, ketThuc) (đoạn GỐC sắp bị xoá khi chấp nhận thay thế)
  /// có phải TOÀN BỘ ký tự cùng mang đúng MỘT tổ hợp định dạng thủ công
  /// không (kể cả tổ hợp "không định dạng gì") — nếu đúng, trả về tổ hợp đó
  /// để đoạn ĐỀ XUẤT thay vào kế thừa; nếu ký tự trong đoạn có định dạng
  /// khác nhau (không đồng nhất), trả về `null` (đoạn mới không kế thừa gì).
  _VungDinhDangThuCong? _dinhDangDongNhatTrongVung(int batDau, int ketThuc) {
    if (batDau >= ketThuc) return null;
    final diem = <int>{batDau, ketThuc};
    for (final d in _boDieuKhien.dinhDang) {
      if (d.batDau > batDau) diem.add(d.batDau.clamp(batDau, ketThuc));
      if (d.ketThuc < ketThuc) diem.add(d.ketThuc.clamp(batDau, ketThuc));
    }
    final moc = diem.toList()..sort();
    _VungDinhDangThuCong? truoc;
    for (var i = 0; i < moc.length - 1; i++) {
      final a = moc[i], b = moc[i + 1];
      if (a >= b) continue;
      var dam = false, nghieng = false, gachChan = false, gachNgang = false, treMu = false, treChan = false;
      Color? mauChu;
      Color? mauNen;
      for (final d in _boDieuKhien.dinhDang) {
        if (d.batDau <= a && d.ketThuc >= b) {
          dam = dam || d.dam;
          nghieng = nghieng || d.nghieng;
          gachChan = gachChan || d.gachChan;
          gachNgang = gachNgang || d.gachNgang;
          treMu = treMu || d.treMu;
          treChan = treChan || d.treChan;
          mauChu = d.mauChu ?? mauChu;
          mauNen = d.mauNen ?? mauNen;
        }
      }
      final hienTai = _VungDinhDangThuCong(
        batDau: a,
        ketThuc: b,
        dam: dam,
        nghieng: nghieng,
        gachChan: gachChan,
        gachNgang: gachNgang,
        treMu: treMu,
        treChan: treChan,
        mauChu: mauChu,
        mauNen: mauNen,
      );
      if (truoc == null) {
        truoc = hienTai;
      } else if (truoc.dam != hienTai.dam ||
          truoc.nghieng != hienTai.nghieng ||
          truoc.gachChan != hienTai.gachChan ||
          truoc.gachNgang != hienTai.gachNgang ||
          truoc.treMu != hienTai.treMu ||
          truoc.treChan != hienTai.treChan ||
          truoc.mauChu != hienTai.mauChu ||
          truoc.mauNen != hienTai.mauNen) {
        return null; // Không đồng nhất.
      }
    }
    return truoc;
  }

  /// Xoá phần định dạng thủ công nằm TRONG [batDau, ketThuc) khỏi mọi vùng
  /// hiện có — vùng nào bị cắt đôi (định dạng trải dài qua cả hai biên) thì
  /// tách thành hai vùng con giữ nguyên phần còn lại NGOÀI khoảng bị xoá.
  void _xoaDinhDangTrongVung(int batDau, int ketThuc) {
    final ds = _boDieuKhien.dinhDang;
    final moi = <_VungDinhDangThuCong>[];
    for (final d in List<_VungDinhDangThuCong>.of(ds)) {
      if (d.ketThuc <= batDau || d.batDau >= ketThuc) continue; // Không giao.
      ds.remove(d);
      if (d.batDau < batDau) {
        moi.add(_VungDinhDangThuCong(
          batDau: d.batDau,
          ketThuc: batDau,
          dam: d.dam,
          nghieng: d.nghieng,
          gachChan: d.gachChan,
          gachNgang: d.gachNgang,
          treMu: d.treMu,
          treChan: d.treChan,
          mauChu: d.mauChu,
          mauNen: d.mauNen,
        ));
      }
      if (d.ketThuc > ketThuc) {
        moi.add(_VungDinhDangThuCong(
          batDau: ketThuc,
          ketThuc: d.ketThuc,
          dam: d.dam,
          nghieng: d.nghieng,
          gachChan: d.gachChan,
          gachNgang: d.gachNgang,
          treMu: d.treMu,
          treChan: d.treChan,
          mauChu: d.mauChu,
          mauNen: d.mauNen,
        ));
      }
    }
    ds.addAll(moi);
  }

  // ----------------------------------------------------------- lùi/tiến tới

  /// Đóng gói trạng thái hiện tại (chữ + con trỏ + mọi đánh dấu AI đang
  /// hiển thị) thành một điểm mốc. Chỉ giữ lại những đề xuất AI CÒN ĐANG CHỜ
  /// quyết định (`nhapNhayMau == null` / `!dangNhapNhay`) — mục nào đang
  /// nhấp nháy sau khi vừa quyết định chỉ là hiệu ứng thoáng qua 4 giây, tự
  /// biến mất dù có Lùi/Tiến hay không, nên không cần lưu lại nguyên trạng
  /// hoạt ảnh của nó.
  _TrangThaiVanBan _chupTrangThai({required String vanBan, required int viTriConTro}) {
    return _TrangThaiVanBan(
      vanBan: vanBan,
      viTriConTro: viTriConTro,
      loi: List<LoiChinhTa>.from(_boDieuKhien.loi),
      khongPhuHop: [
        for (final k in _boDieuKhien.khongPhuHop)
          if (k.nhapNhayMau == null)
            _MocVungKhongPhuHop(
              batDauGoc: k.batDauGoc,
              ketThucGoc: k.ketThucGoc,
              batDauDeXuat: k.batDauDeXuat,
              ketThucDeXuat: k.ketThucDeXuat,
            ),
      ],
      canXoa: [
        for (final x in _boDieuKhien.canXoa)
          if (!x.dangNhapNhay) _MocVungCanXoa(batDau: x.batDau, ketThuc: x.ketThuc),
      ],
      dinhDang: [
        for (final d in _boDieuKhien.dinhDang)
          _VungDinhDangThuCong(
            batDau: d.batDau,
            ketThuc: d.ketThuc,
            dam: d.dam,
            nghieng: d.nghieng,
            gachChan: d.gachChan,
            gachNgang: d.gachNgang,
            treMu: d.treMu,
            treChan: d.treChan,
            mauChu: d.mauChu,
            mauNen: d.mauNen,
          ),
      ],
    );
  }

  /// Y hệt [_luuDiemMoc] nhưng dành riêng cho một thao tác áp/bỏ ĐỊNH DẠNG
  /// THỦ CÔNG (mục 5): gọi NGAY TRƯỚC khi sửa `_boDieuKhien.dinhDang`, để
  /// Ctrl+Z hoàn tác đúng về trạng thái định dạng trước đó. Không thể dùng
  /// chung [_luuDiemMoc] vì hàm đó bỏ qua mốc khi chữ chưa đổi — một thao
  /// tác định dạng không đổi chữ (`vanBan` y nguyên) nên sẽ luôn bị bỏ qua
  /// nếu đi qua đường dedupe đó; ở đây LUÔN chụp, không dedupe theo chữ.
  void _luuDiemMocDinhDang() {
    setState(() {
      _lichSuLui.add(_chupTrangThai(
        vanBan: _boDieuKhien.text,
        viTriConTro: _viTriConTroHienTai(),
      ));
      if (_lichSuLui.length > _soLuongLichSuToiDa) _lichSuLui.removeAt(0);
      _lichSuToi.clear();
    });
  }

  /// Chụp lại trọn vẹn trạng thái NGAY TRƯỚC một đợt gõ/nói/hành động sắp
  /// diễn ra. Bỏ qua nếu chữ chưa đổi gì so với điểm mốc gần nhất (tránh
  /// những điểm mốc thừa, ví dụ micro thử bật lại liên tiếp do lỗi mạng).
  ///
  /// Nhận tham số tường minh thay vì tự đọc `_boDieuKhien.text` — ở nơi gọi
  /// từ `_apDungChinhSuaNguoiDung`, bộ điều khiển đã mang chữ MỚI (đã gõ
  /// xong) từ trước khi hàm đó kịp chạy dòng nào, nên phải truyền tay chữ CŨ
  /// (`_chuGanNhat`) vào mới chụp đúng trạng thái ngay TRƯỚC đợt gõ này.
  void _luuDiemMoc({String? vanBan, int? viTriConTro}) {
    final vb = vanBan ?? _boDieuKhien.text;
    if (_lichSuLui.isNotEmpty && _lichSuLui.last.vanBan == vb) return;
    setState(() {
      _lichSuLui.add(_chupTrangThai(
        vanBan: vb,
        viTriConTro: viTriConTro ?? _viTriConTroHienTai(),
      ));
      if (_lichSuLui.length > _soLuongLichSuToiDa) _lichSuLui.removeAt(0);
      _lichSuToi.clear(); // Hành động mới thì đường Tiến tới cũ không còn ý nghĩa.
    });
  }

  int _viTriConTroHienTai() {
    final chon = _boDieuKhien.selection;
    return chon.isValid ? chon.start : _boDieuKhien.text.length;
  }

  /// Nhãn nguyên văn của mọi thẻ ghi âm CHƯA có trong bộ nhớ đệm (chưa từng
  /// chuyển hoá thành công: đang ghi / ghi xong chưa gửi / đang chuyển / lỗi
  /// tạm thời) — mất là mất thật, nên Ctrl+Z/Ctrl+Y không được phép làm
  /// chúng biến mất. Thẻ đã có trong bộ nhớ đệm thì không cần giữ kiểu này,
  /// vì mất thì hoàn tác/chuyển hoá lại vẫn lấy đúng chữ cũ ra được.
  Set<String> _nhanTheChuaCoTrongBoNhoDem() {
    final vb = _boDieuKhien.text;
    final ds = <String>{};
    for (final m in reTheGhiAmHoanChinh.allMatches(vb)) {
      final soThe = int.parse(m.group(1)!);
      if (!_vanBanDaTraVeTheoTheGhiAm.containsKey(soThe)) ds.add(m[0]!);
    }
    for (final m in reTheDangChuyen.allMatches(vb)) {
      ds.add(m[0]!);
    }
    if (vb.contains(tenTokenDangGhiAm)) ds.add(tenTokenDangGhiAm);
    return ds;
  }

  bool _conNguyenCacThePhaiGiu(String vanBan, Set<String> nhanPhaiGiu) {
    for (final nhan in nhanPhaiGiu) {
      if (!vanBan.contains(nhan)) return false;
    }
    return true;
  }

  void _lui() {
    if (_lichSuLui.isEmpty) return;
    // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Xem
    // `_ngungMicroVaGhiAmTheNeuDangBat`.
    unawaited(_ngungMicroVaGhiAmTheNeuDangBat());
    // Hướng B đã bàn: KHÔNG tự chèn thẻ vào giữa chừng (sẽ làm thẻ trôi vị
    // trí mỗi lần bấm) — chỉ NHẢY QUA những mốc lịch sử nào thiếu bất kỳ thẻ
    // nào đang cần giữ, tới khi gặp mốc còn giữ nguyên văn TẤT CẢ các thẻ đó.
    final nhanPhaiGiu = _nhanTheChuaCoTrongBoNhoDem();
    final biNhayQua = <_TrangThaiVanBan>[];
    _TrangThaiVanBan? truoc;
    while (_lichSuLui.isNotEmpty) {
      final ung = _lichSuLui.removeLast();
      if (_conNguyenCacThePhaiGiu(ung.vanBan, nhanPhaiGiu)) {
        truoc = ung;
        break;
      }
      biNhayQua.add(ung);
    }
    if (truoc == null) {
      _lichSuLui.addAll(biNhayQua.reversed); // trả lại đúng thứ tự cũ.
      _bao(Ch.khongTheHoanTacKhiConTheChuaXuLy(ngonNguHienTai.value));
      return;
    }
    _lichSuToi.add(_chupTrangThai(
      vanBan: _boDieuKhien.text,
      viTriConTro: _viTriConTroHienTai(),
    ));
    // Các mốc bị nhảy qua cũng phải sang bên Tiến, đúng thứ tự, để bấm Tiến
    // sau đó đi lại đúng đường vừa nhảy qua (xem chứng minh thứ tự ở lượt
    // bàn bạc trước khi làm).
    _lichSuToi.addAll(biNhayQua);
    // setState trần NGAY tại đây (không đợi _apDungTrangThai) — nút Lùi/Tiến
    // trên AppBar phải phản ánh đúng độ dài hai danh sách vừa đổi ngay lập
    // tức, kẻo bấm liên tiếp trước khi khung hình kịp vẽ lại sẽ tưởng nút
    // chưa hoạt động.
    setState(() {});
    _apDungTrangThai(truoc);
  }

  void _toi() {
    if (_lichSuToi.isEmpty) return;
    // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Xem
    // `_ngungMicroVaGhiAmTheNeuDangBat`.
    unawaited(_ngungMicroVaGhiAmTheNeuDangBat());
    final nhanPhaiGiu = _nhanTheChuaCoTrongBoNhoDem();
    final biNhayQua = <_TrangThaiVanBan>[];
    _TrangThaiVanBan? sau;
    while (_lichSuToi.isNotEmpty) {
      final ung = _lichSuToi.removeLast();
      if (_conNguyenCacThePhaiGiu(ung.vanBan, nhanPhaiGiu)) {
        sau = ung;
        break;
      }
      biNhayQua.add(ung);
    }
    if (sau == null) {
      _lichSuToi.addAll(biNhayQua.reversed);
      _bao(Ch.khongTheLamLaiKhiConTheChuaXuLy(ngonNguHienTai.value));
      return;
    }
    _lichSuLui.add(_chupTrangThai(
      vanBan: _boDieuKhien.text,
      viTriConTro: _viTriConTroHienTai(),
    ));
    _lichSuLui.addAll(biNhayQua);
    setState(() {});
    _apDungTrangThai(sau);
  }

  void _apDungTrangThai(_TrangThaiVanBan tt) {
    // An toàn trước: đừng để một kết quả giọng nói còn treo ghi đè lên đúng
    // lúc vừa khôi phục xong.
    if (_muonNghe) _tatMicro();
    _chuTam = '';
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];
    _neo = tt.viTriConTro.clamp(0, tt.vanBan.length);

    // Huỷ mọi hẹn giờ nhấp nháy đang chạy trước khi thay hẳn ba danh sách.
    for (final k in _boDieuKhien.khongPhuHop) {
      k.henNhapNhay?.cancel();
    }
    for (final x in _boDieuKhien.canXoa) {
      x.henNhapNhay?.cancel();
    }

    _boDieuKhien.loi
      ..clear()
      ..addAll(tt.loi);
    _boDieuKhien.khongPhuHop
      ..clear()
      ..addAll(tt.khongPhuHop.map((m) => _VungKhongPhuHop(
            batDauGoc: m.batDauGoc,
            ketThucGoc: m.ketThucGoc,
            batDauDeXuat: m.batDauDeXuat,
            ketThucDeXuat: m.ketThucDeXuat,
          )));
    _boDieuKhien.canXoa
      ..clear()
      ..addAll(tt.canXoa.map((m) => _VungCanXoa(batDau: m.batDau, ketThuc: m.ketThuc)));
    _boDieuKhien.dinhDang
      ..clear()
      ..addAll(tt.dinhDang.map((d) => _VungDinhDangThuCong(
            batDau: d.batDau,
            ketThuc: d.ketThuc,
            dam: d.dam,
            nghieng: d.nghieng,
            gachChan: d.gachChan,
            gachNgang: d.gachNgang,
            treMu: d.treMu,
            treChan: d.treChan,
            mauChu: d.mauChu,
            mauNen: d.mauNen,
          )));

    // setState trần: buộc vẽ lại AppBar để nút Lùi/Tiến bật/tắt đúng theo độ
    // dài _lichSuLui/_lichSuToi vừa đổi (bản thân chúng không tự kích rebuild).
    setState(() {});

    _henChinhTa?.cancel();
    _viTriDaKiemTraChinhTa = tt.vanBan.length;
    _ghiVaoO(tt.vanBan, _neo);
    // (SỬA LỖI đường kẻ chia không theo kịp Lùi lại/Tiến tới) Snapshot lịch
    // sử (`_TrangThaiVanBan`) KHÔNG lưu `_cacViTriDuongKeChia` — danh sách
    // offset đó vẫn còn nguyên giá trị CŨ (từ trước khi Lùi/Tiến), trong khi
    // nội dung/toạ độ văn bản vừa đổi hẳn sang một trạng thái khác. Quét lại
    // TỪ ĐẦU trên văn bản MỚI (giống hệt lúc mở một ghi chú) là cách chắc
    // chắn đúng duy nhất — không thể "dời" danh sách cũ theo kiểu diff, vì
    // Lùi/Tiến có thể nhảy xa qua nhiều bước cùng lúc.
    _cacViTriDuongKeChia.clear();
    if (widget.caiDat.tuDongThemDuongKeChia) {
      _quetVaXayDungDuongKeChia();
    }
    // Lưới an toàn — bản thân các mốc lịch sử vốn đã sạch (mỗi lần lưu mốc
    // đều chạy qua bước dọn này rồi), nhưng dọn lại cho chắc, cùng lý do
    // với `_apDungChinhSuaNguoiDung`.
    _donDepTheTichChonRongQuanhViTri(_neo, _neo);
    _henLuu();
  }

  // ------------------------------------------------------------------- nút

  /// Sao chép toàn bộ văn bản vào bộ nhớ tạm. Dùng cả cho mục "Sao chép tất
  /// cả" và làm bước đầu của "Sao chép rồi xoá tất cả" trong menu "+ Thêm
  /// lựa chọn" — [baoKetQua] tắt đi khi gọi từ đó để tránh hiện hai popup
  /// liên tiếp, nhường popup cuối cho hành động gộp.
  Future<bool> _chepTatCa({bool baoKetQua = true}) async {
    final chu = _boDieuKhien.text;
    if (chu.isEmpty) {
      if (baoKetQua) _bao(Ch.chuaCoChuNaoDeChep(ngonNguHienTai.value));
      return false;
    }
    await Clipboard.setData(ClipboardData(text: chu));
    if (baoKetQua && mounted) _bao(Ch.daSaoChepTatCaToast(ngonNguHienTai.value));
    return true;
  }

  /// Xoá toàn bộ văn bản. Không hỏi xác nhận — Lùi lại (Ctrl + Z) đã là lưới
  /// an toàn cho việc xoá nhầm, nên thực hiện ngay khi bấm. Dùng chung cho
  /// mục "Xoá tất cả" và bước sau của "Sao chép rồi xoá tất cả" — [baoKetQua]
  /// tắt đi khi gọi từ đó với cùng lý do như ở [_chepTatCa].
  Future<bool> _xoaTatCa({bool baoKetQua = true}) async {
    if (_boDieuKhien.text.isEmpty) {
      if (baoKetQua) _bao(Ch.trangDangTrongKhongCoGiDeXoa(ngonNguHienTai.value));
      return false;
    }

    _luuDiemMoc();

    // Trả mọi mốc về vạch xuất phát, nếu không thì câu nói kế tiếp lại nhắm
    // vào một vị trí không còn tồn tại.
    _ghiVaoO('', 0);
    _neo = 0;
    _chuTam = '';
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    for (final k in _boDieuKhien.khongPhuHop) {
      k.henNhapNhay?.cancel();
    }
    _boDieuKhien.khongPhuHop.clear();
    for (final x in _boDieuKhien.canXoa) {
      x.henNhapNhay?.cancel();
    }
    _boDieuKhien.canXoa.clear();
    _viTriDaKiemTraChinhTa = 0;
    // (SỬA LỖI đường kẻ chia "bóng ma") Văn bản vừa về rỗng hoàn toàn — mọi
    // đường kẻ chia cũ không còn ý nghĩa gì, xoá sạch để khỏi vẽ nhầm ở dòng
    // đầu tiên của trang trống.
    _cacViTriDuongKeChia.clear();
    _viTriChoVietHoa = null;
    _boQuaCauNay = _micro.isListening;
    await _luuVanBan();
    if (baoKetQua && mounted) _bao(Ch.daXoaTatCaToast(ngonNguHienTai.value));
    return true;
  }

  /// Sao chép rồi xoá tất cả, gộp hai thao tác trên thành một mục trong menu
  /// "+ Thêm lựa chọn" — tái dùng nguyên logic của cả hai, chỉ tự lo popup
  /// thông báo cuối cùng.
  Future<void> _chepRoiXoaTatCa() async {
    final daChep = await _chepTatCa(baoKetQua: false);
    if (!daChep || !mounted) return;
    await _xoaTatCa(baoKetQua: false);
    if (mounted) _bao(Ch.daSaoChepTatCaVaXoa(ngonNguHienTai.value));
  }

  void _moModalCaiDatKiemTraToanVan() {
    moModalCaiDatKiemTraToanVan(context, widget.caiDat);
  }

  /// Modal "Danh sách phím tắt" — đọc TRỰC TIẾP từ `CaiDat.phimTatCoDinh`
  /// (nguồn động DUY NHẤT, xem B6), cộng thêm hai dòng riêng cho Micro và
  /// Ghi âm (đọc `widget.caiDat.phimTatMicro`/`phimTatGhiAm`, cũng động —
  /// luôn khớp với Cài đặt).
  void _moDanhSachPhimTat() {
    String tim(String khoa) =>
        CaiDat.moTaPhimTat(CaiDat.phimTatCoDinh[khoa], ngonNguHienTai.value);

    // Hai kiểu "bấm 2 lần liên tiếp" không tự nói lên cách kích hoạt qua
    // mỗi cái tên ngắn (`LuaChonPhimTat.nhan`) — ghi rõ thêm ở đây, đúng
    // yêu cầu "phải giải thích rõ kích hoạt nó như thế nào".
    String moTaThem(LuaChonPhimTat lc) => switch (lc.loai) {
          'ctrlDup' => Ch.moTaThemBamNhanhLienTiep(ngonNguHienTai.value, 'Ctrl'),
          'shiftDup' => Ch.moTaThemBamNhanhLienTiep(ngonNguHienTai.value, 'Shift'),
          'altDup' => Ch.moTaThemBamNhanhLienTiep(ngonNguHienTai.value, 'Alt'),
          _ => '',
        };

    Widget dong(String phim, String chuc) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(phim, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Expanded(child: Text(chuc, style: const TextStyle(fontSize: 13))),
            ],
          ),
        );

    Widget deMuc(String chu) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(chu, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
        );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.keyboard_alt_outlined, size: 28),
        // (YÊU CẦU MỚI) Bỏ nút "Đóng" ở `actions` — thay bằng nút X đỏ gọn
        // gàng ở góc trên bên phải.
        title: Row(
          children: [
            Expanded(child: Text(Ch.danhSachPhimTat(ngonNguHienTai.value))),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: Ch.dong(ngonNguHienTai.value),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                deMuc(Ch.microVaGhiAm(ngonNguHienTai.value)),
                dong(
                  widget.caiDat.phimTatMicro.nhan,
                  '${Ch.batTatMicro(ngonNguHienTai.value)}'
                      '${moTaThem(widget.caiDat.phimTatMicro)}',
                ),
                dong(
                  widget.caiDat.phimTatGhiAm.nhan,
                  '${Ch.moDongTrinhGhiAm(ngonNguHienTai.value)}'
                      '${moTaThem(widget.caiDat.phimTatGhiAm)}',
                ),
                if (widget.caiDat.boNhoTamDanVanBanBat)
                  dong(
                    widget.caiDat.phimTatBoNhoTam.nhan,
                    '${Ch.anHienBoNhoTamDanVanBan(ngonNguHienTai.value)}'
                        '${moTaThem(widget.caiDat.phimTatBoNhoTam)}',
                  ),
                if (_tuDienNhapLieuNhanhBatKyNguon)
                  dong(
                    widget.caiDat.phimTatTuDienNhapLieuNhanh.nhan,
                    '${Ch.anHienTuDienNhapLieuNhanh(ngonNguHienTai.value)}'
                        '${moTaThem(widget.caiDat.phimTatTuDienNhapLieuNhanh)}',
                  ),
                deMuc(Ch.dieuHuong(ngonNguHienTai.value)),
                dong('Ctrl + Z', tim('Ctrl+Z')),
                dong('Ctrl + Shift + Z', tim('Ctrl+Shift+Z')),
                deMuc(Ch.chung(ngonNguHienTai.value)),
                dong('Ctrl + F', tim('Ctrl+F')),
                dong('Ctrl + A', tim('Ctrl+A')),
                dong('Ctrl + S', tim('Ctrl+S')),
                dong('Ctrl + X', tim('Ctrl+X')),
                dong('Ctrl + C', tim('Ctrl+C')),
                dong('Ctrl + V', tim('Ctrl+V')),
                // (YÊU CẦU MỚI) Chỉ LIỆT KÊ — phím tắt này do HỆ ĐIỀU HÀNH/
                // TRÌNH DUYỆT xử lý sẵn, app không tự viết logic riêng cho nó.
                dong('Ctrl + Shift + V', Ch.danChuTho(ngonNguHienTai.value)),
                dong('Ctrl + Enter', tim('Ctrl+Enter')),
                deMuc(Ch.dinhDangVanBanDeMuc(ngonNguHienTai.value)),
                dong('Ctrl + B', tim('Ctrl+B')),
                dong('Ctrl + I', tim('Ctrl+I')),
                dong('Ctrl + U', tim('Ctrl+U')),
                dong('Ctrl + Shift + X', tim('Ctrl+Shift+X')),
                dong('Ctrl + Shift + =', tim('Ctrl+Shift+Equal')),
                dong('Ctrl + =', tim('Ctrl+Equal')),
                dong('Ctrl + Shift + C', tim('Ctrl+Shift+C')),
                dong('Ctrl + Shift + H', tim('Ctrl+Shift+H')),
                dong('Ctrl + Q',
                    Ch.xoaDinhDangKemMoTa(ngonNguHienTai.value, tim('Ctrl+Q'))),
                const SizedBox(height: 12),
                Text(
                  Ch.huongDanBamPhimTat(ngonNguHienTai.value),
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Color(0xFF5F6368)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------- chuyển file âm thanh thành văn bản (AI)

  /// Giới hạn dung lượng tệp GỐC (chưa mã hoá base64) cho phép chọn — khớp
  /// đúng giới hạn cứng 25MB của Groq (nơi thật sự xử lý audio, xem
  /// `cloud-function/index.js`), không phải một con số tự chọn tuỳ ý.
  static const _gioiHanTepAmThanhByte = 25 * 1024 * 1024;

  /// Các đuôi tệp Groq/Whisper hỗ trợ — lọc ngay trong hộp thoại chọn tệp,
  /// tránh người dùng chọn nhầm định dạng chắc chắn bị từ chối phía máy chủ.
  static const _duoiTepAmThanhHoTro = [
    'mp3', 'mp4', 'mpeg', 'mpga', 'm4a', 'wav', 'webm', 'flac', 'ogg', 'oga', 'aac',
  ];

  String _doanMimeTuDuoiTep(String duoi) {
    switch (duoi.toLowerCase()) {
      case 'mp3':
      case 'mpga':
        return 'audio/mpeg';
      case 'mp4':
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'webm':
        return 'audio/webm';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
      case 'oga':
        return 'audio/ogg';
      case 'aac':
        return 'audio/aac';
      default:
        return 'audio/mpeg';
    }
  }

  /// Mục "Chuyển file âm thanh thành văn bản" trong menu "Làm việc với AI"
  /// (`thanh_cong_cu.dart`) — mở hộp thoại chọn tệp, kiểm dung lượng, gửi
  /// qua ĐÚNG luồng AI dùng chung với ghi âm trong app (`guiGhiAmChoGemini`,
  /// nay chạy qua Groq — xem `gui_ghi_am_gemini.dart`), rồi hiện modal kết
  /// quả kèm hai nút Huỷ/Chèn.
  Future<void> _chonVaChuyenFileAmThanh() async {
    // (file_picker 13.x — bản 12.0.0 viết lại toàn bộ API) `FilePickerResult`
    // đã bị bỏ hẳn: `pickFile()` (số ít) giờ trả thẳng `PlatformFile?`, không
    // còn wrapper `.files`; đọc dữ liệu qua `readAsBytes()` thay vì tham số
    // `withData`/thuộc tính `.bytes` (cả hai đã bị đánh dấu bỏ). `.platform`
    // cũng bị bỏ luôn — bản 13.x gọi thẳng hàm TĨNH `FilePicker.pickFile()`,
    // không còn qua `FilePicker.platform` như các bản cũ.
    PlatformFile? tep;
    try {
      tep = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _duoiTepAmThanhHoTro,
      );
    } catch (e) {
      if (mounted) _bao(Ch.khongMoDuocHopThoaiChonTep(ngonNguHienTai.value, '$e'));
      return;
    }
    if (tep == null) return; // người dùng huỷ chọn.

    Uint8List bytes;
    try {
      bytes = await tep.readAsBytes();
    } catch (e) {
      _bao(Ch.khongDocDuocNoiDungTepVuaChon(ngonNguHienTai.value, '$e'));
      return;
    }
    if (bytes.length > _gioiHanTepAmThanhByte) {
      final soMB = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      _bao(Ch.tepAmThanhVuotQuaGioiHan(ngonNguHienTai.value, tep.name, soMB));
      return;
    }

    final mimeType = _doanMimeTuDuoiTep(tep.extension ?? '');

    if (await chanNeuDaChamHanMucAi(context, LoaiHanMucAi.amThanh)) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text(Ch.dangChuyenTepAmThanhThanhVanBan(ngonNguHienTai.value))),
          ],
        ),
      ),
    );

    String? vanBanKetQua;
    String? loi;
    Object? loiObj;
    try {
      // locHallucination CỐ Ý để mặc định (false) — tệp người dùng tự tải
      // lên có thể là nhạc/podcast/nhiều giọng, không phải một lượt ghi âm
      // giọng nói ngắn, nên không áp dụng lọc "im lặng = hallucination".
      vanBanKetQua = await guiGhiAmChoGemini(bytes, mimeType);
    } catch (e) {
      loi = e.toString();
      loiObj = e;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // đóng hộp "đang xử lý".

    if (loiObj is LoiHanMucAi) {
      await ghiNhoDaChamHanMucAi(loiObj.loai, loiObj.thongDiep);
      if (mounted) await hienHopThoaiHanMucAi(context, loiObj.thongDiep);
      return;
    }
    if (loi != null || vanBanKetQua == null || vanBanKetQua.trim().isEmpty) {
      _bao(Ch.chuyenTepThatBai(ngonNguHienTai.value, loi ?? 'không có nội dung trả về.'));
      return;
    }

    _moModalKetQuaFileAmThanh(vanBanKetQua);
  }

  /// Các đuôi ảnh Gemini nhận — lọc ngay trong hộp thoại chọn tệp, tránh
  /// chọn nhầm định dạng chắc chắn bị từ chối phía máy chủ.
  static const _duoiAnhHoTro = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'];

  /// Giới hạn dung lượng ảnh GỐC — rộng rãi hơn nhiều so với ảnh thường gặp
  /// (điện thoại chụp cũng chỉ vài MB), chỉ để chặn tệp bất thường; Gemini
  /// nhận tới 100MB dữ liệu inline nên không phải giới hạn cứng như bên
  /// Groq/audio.
  static const _gioiHanTepAnhByte = 15 * 1024 * 1024;

  String _doanMimeAnhTuDuoiTep(String duoi) {
    switch (duoi.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  /// Mục "Chuyển hình ảnh thành văn bản" trong menu "Làm việc với AI" —
  /// ĐÚNG LUỒNG như `_chonVaChuyenFileAmThanh` ở trên (chọn tệp, kiểm dung
  /// lượng, gửi AI, modal kết quả sửa được + Huỷ có xác nhận + Chọn vị trí
  /// để chèn), chỉ khác: gửi qua Gemini (`guiAnhChoGemini`, xem lý do chọn
  /// Gemini thay Groq ở `cloud-function/index.js`) thay vì Groq.
  Future<void> _chonVaChuyenAnhThanhVanBan() async {
    PlatformFile? tep;
    try {
      tep = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _duoiAnhHoTro,
      );
    } catch (e) {
      if (mounted) _bao(Ch.khongMoDuocHopThoaiChonAnh(ngonNguHienTai.value, '$e'));
      return;
    }
    if (tep == null) return; // người dùng huỷ chọn.

    Uint8List bytes;
    try {
      bytes = await tep.readAsBytes();
    } catch (e) {
      _bao(Ch.khongDocDuocNoiDungAnhVuaChon(ngonNguHienTai.value, '$e'));
      return;
    }
    if (bytes.length > _gioiHanTepAnhByte) {
      final soMB = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      _bao(Ch.anhVuotQuaGioiHan(ngonNguHienTai.value, tep.name, soMB));
      return;
    }

    final mimeType = _doanMimeAnhTuDuoiTep(tep.extension ?? '');

    if (await chanNeuDaChamHanMucAi(context, LoaiHanMucAi.hinhAnh)) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text(Ch.dangChuyenHinhAnhThanhVanBan(ngonNguHienTai.value))),
          ],
        ),
      ),
    );

    String? vanBanKetQua;
    String? loi;
    Object? loiObj;
    try {
      vanBanKetQua = await guiAnhChoGemini(bytes, mimeType);
    } catch (e) {
      loi = e.toString();
      loiObj = e;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // đóng hộp "đang xử lý".

    if (loiObj is LoiHanMucAi) {
      await ghiNhoDaChamHanMucAi(loiObj.loai, loiObj.thongDiep);
      if (mounted) await hienHopThoaiHanMucAi(context, loiObj.thongDiep);
      return;
    }
    if (loi != null || vanBanKetQua == null || vanBanKetQua.trim().isEmpty) {
      _bao(Ch.chuyenAnhThatBai(ngonNguHienTai.value, loi ?? 'không có nội dung trả về.'));
      return;
    }

    _moModalKetQuaFileAmThanh(vanBanKetQua, tieuDe: 'hinhAnh');
  }

  /// Mục "Tóm tắt toàn văn" trong menu "Làm việc với AI" — mở modal "Chọn
  /// kiểu tóm tắt" trước khi gọi Gemini: theo % độ dài, theo câu lệnh tự do
  /// của người dùng, hoặc cả hai — bắt buộc chọn ít nhất một trong hai mới
  /// bấm "Gửi cho AI xử lý" được.
  /// Bộ nhớ đệm cho modal "Tóm tắt toàn văn"/"Mở rộng toàn văn"/"Viết lại
  /// cho hay hơn" — MỖI NÚT một bộ nhớ RIÊNG (không lẫn giữa ba nút), nhưng
  /// CHUNG cho mọi tệp ghi chú và mọi ngữ cảnh (toàn văn/đoạn chọn) — mở lại
  /// modal của cùng một nút thì luôn thấy đúng % và câu lệnh đã ghi lần
  /// trước. Chỉ sống trong RAM của phiên hiện tại — F5 hay vào lại app thì
  /// mất, giống mọi bộ nhớ đệm khác trong tệp này.
  bool _tomTatNhoChonPhanTram = true;
  double _tomTatNhoPhanTram = 50.0;
  bool _tomTatNhoChonCauLenh = false;
  String _tomTatNhoCauLenh = '';

  bool _moRongNhoChonPhanTram = true;
  double _moRongNhoPhanTram = 200.0;
  bool _moRongNhoChonCauLenh = false;
  String _moRongNhoCauLenh = '';

  String _vietLaiNhoCauLenh = '';

  /// Nút "Xoá tất cả" dưới ô câu lệnh tự do trong ba modal Tóm tắt/Mở
  /// rộng/Viết lại — hỏi xác nhận trước, xác nhận thì xoá trắng cả ô nhập
  /// lẫn bộ nhớ đệm của nút đó.
  Future<void> _xacNhanXoaCauLenh(
    BuildContext ctx,
    TextEditingController oCauLenh,
    void Function() capNhat,
  ) async {
    final dongY = await showDialog<bool>(
      context: ctx,
      builder: (ctx2) => AlertDialog(
        title: Text(Ch.xoaTatCaCauLenh(ngonNguHienTai.value)),
        content: Text(Ch.noiDungCauLenhSeBiXoaSach(ngonNguHienTai.value)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx2).pop(false), child: Text(Ch.huy(ngonNguHienTai.value))),
          TextButton(
            onPressed: () => Navigator.of(ctx2).pop(true),
            child: Text(Ch.xoaTatCaDam(ngonNguHienTai.value), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (dongY == true) {
      oCauLenh.clear();
      capNhat();
    }
  }

  void _moModalChonKieuTomTat() {
    final vungChon = _vungDangChonHopLe();
    final vanBanGoc = vungChon != null ? vungChon.textInside(_boDieuKhien.text) : _boDieuKhien.text;
    if (vanBanGoc.trim().isEmpty) {
      _bao(vungChon != null
          ? Ch.doanDangChonTrongKhongCoGiDeTomTat(ngonNguHienTai.value)
          : Ch.trangDangTrongKhongCoGiDeTomTat(ngonNguHienTai.value));
      return;
    }
    if (!_coTheDungAIVoiVanBan(vanBanGoc, coVungChon: vungChon != null)) return;
    var chonPhanTram = _tomTatNhoChonPhanTram;
    var phanTram = _tomTatNhoPhanTram;
    var chonCauLenh = _tomTatNhoChonCauLenh;
    final oCauLenh = TextEditingController(text: _tomTatNhoCauLenh);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhat) {
          final coTheGui = chonPhanTram || chonCauLenh;
          return AlertDialog(
            title: Text(Ch.chonKieuTomTat(ngonNguHienTai.value, vungChon != null)),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: chonPhanTram,
                      onChanged: (gia) => capNhat(() => chonPhanTram = gia ?? false),
                      title: Text(Ch.tomTatTheoPhanTram(ngonNguHienTai.value)),
                    ),
                    if (chonPhanTram) ...[
                      Text(
                        Ch.rutGonConPhanTramVanBanGoc(ngonNguHienTai.value, phanTram.round()),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: phanTram,
                        min: 10,
                        max: 90,
                        divisions: 80,
                        label: '${phanTram.round()}%',
                        onChanged: (gia) => capNhat(() => phanTram = gia),
                      ),
                    ],
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: chonCauLenh,
                      onChanged: (gia) => capNhat(() => chonCauLenh = gia ?? false),
                      title: Text(Ch.rutGonTheoYeuCau(ngonNguHienTai.value)),
                    ),
                    if (chonCauLenh) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: TextField(
                          controller: oCauLenh,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: Ch.viDuChiGiuYChinh(ngonNguHienTai.value),
                            contentPadding: EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _xacNhanXoaCauLenh(ctx, oCauLenh, () => capNhat(() {})),
                          child: Text(Ch.xoaTatCaDam(ngonNguHienTai.value), style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(Ch.dongBang(ngonNguHienTai.value)),
              ),
              FilledButton(
                onPressed: !coTheGui
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        _guiTomTatChoAi(
                          vanBanGoc: vanBanGoc,
                          vungChon: vungChon,
                          phanTram: chonPhanTram ? phanTram.round() : null,
                          huongDanNguoiDung: chonCauLenh ? oCauLenh.text : null,
                        );
                      },
                child: Text(Ch.guiChoAiXuLy(ngonNguHienTai.value)),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      _tomTatNhoChonPhanTram = chonPhanTram;
      _tomTatNhoPhanTram = phanTram;
      _tomTatNhoChonCauLenh = chonCauLenh;
      _tomTatNhoCauLenh = oCauLenh.text;
      oCauLenh.dispose();
    });
  }

  Future<void> _guiTomTatChoAi({
    required String vanBanGoc,
    required TextSelection? vungChon,
    int? phanTram,
    String? huongDanNguoiDung,
  }) async {
    if (await chanNeuDaChamHanMucAi(context, LoaiHanMucAi.vanBan)) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text(Ch.dangTomTatToanVan(ngonNguHienTai.value))),
          ],
        ),
      ),
    );

    String? vanBanKetQua;
    String? loi;
    Object? loiObj;
    try {
      vanBanKetQua = await guiTomTatChoGemini(
        vanBanGoc,
        phanTram: phanTram,
        huongDanNguoiDung: huongDanNguoiDung,
      );
    } catch (e) {
      loi = e.toString();
      loiObj = e;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // đóng hộp "đang xử lý".

    if (loiObj is LoiHanMucAi) {
      await ghiNhoDaChamHanMucAi(loiObj.loai, loiObj.thongDiep);
      if (mounted) await hienHopThoaiHanMucAi(context, loiObj.thongDiep);
      return;
    }
    if (loi != null || vanBanKetQua == null || vanBanKetQua.trim().isEmpty) {
      _bao(Ch.tomTatThatBai(ngonNguHienTai.value, loi ?? 'không có nội dung trả về.'));
      return;
    }

    _moModalKetQuaToanVan(
      vanBanKetQua,
      tieuDe: Ch.ketQuaTomTat(ngonNguHienTai.value, vungChon != null),
      vungChon: vungChon,
    );
  }

  /// Mục "Mở rộng toàn văn" trong menu "Làm việc với AI" — ĐÚNG KHUÔN
  /// `_moModalChonKieuTomTat` ở trên, chỉ đảo ngược ý nghĩa: thanh kéo là
  /// % ĐỘ DÀI MONG MUỐN so với bản gốc (120-400%, mỗi mốc cách nhau 10,
  /// mặc định 200%), không phải % còn lại như tóm tắt.
  void _moModalChonKieuMoRong() {
    final vungChon = _vungDangChonHopLe();
    final vanBanGoc = vungChon != null ? vungChon.textInside(_boDieuKhien.text) : _boDieuKhien.text;
    if (vanBanGoc.trim().isEmpty) {
      _bao(vungChon != null
          ? Ch.doanDangChonTrongKhongCoGiDeMoRong(ngonNguHienTai.value)
          : Ch.trangDangTrongKhongCoGiDeMoRong(ngonNguHienTai.value));
      return;
    }
    if (!_coTheDungAIVoiVanBan(vanBanGoc, coVungChon: vungChon != null)) return;
    var chonPhanTram = _moRongNhoChonPhanTram;
    var phanTram = _moRongNhoPhanTram;
    var chonCauLenh = _moRongNhoChonCauLenh;
    final oCauLenh = TextEditingController(text: _moRongNhoCauLenh);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhat) {
          final coTheGui = chonPhanTram || chonCauLenh;
          return AlertDialog(
            title: Text(Ch.chonKieuMoRong(ngonNguHienTai.value, vungChon != null)),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: chonPhanTram,
                      onChanged: (gia) => capNhat(() => chonPhanTram = gia ?? false),
                      title: Text(Ch.moRongTheoPhanTram(ngonNguHienTai.value)),
                    ),
                    if (chonPhanTram) ...[
                      Text(
                        Ch.moRongThanhPhanTramVanBanGoc(ngonNguHienTai.value, phanTram.round()),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: phanTram,
                        min: 120,
                        max: 400,
                        divisions: 28, // Mỗi mốc cách nhau 10: (400-120)/10.
                        label: '${phanTram.round()}%',
                        onChanged: (gia) => capNhat(() => phanTram = gia),
                      ),
                    ],
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: chonCauLenh,
                      onChanged: (gia) => capNhat(() => chonCauLenh = gia ?? false),
                      title: Text(Ch.moRongTheoYeuCau(ngonNguHienTai.value)),
                    ),
                    if (chonCauLenh) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: TextField(
                          controller: oCauLenh,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: Ch.viDuThemViDuMinhHoa(ngonNguHienTai.value),
                            contentPadding: EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _xacNhanXoaCauLenh(ctx, oCauLenh, () => capNhat(() {})),
                          child: Text(Ch.xoaTatCaDam(ngonNguHienTai.value), style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(Ch.dongBang(ngonNguHienTai.value)),
              ),
              FilledButton(
                onPressed: !coTheGui
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        _guiMoRongChoAi(
                          vanBanGoc: vanBanGoc,
                          vungChon: vungChon,
                          phanTram: chonPhanTram ? phanTram.round() : null,
                          huongDanNguoiDung: chonCauLenh ? oCauLenh.text : null,
                        );
                      },
                child: Text(Ch.guiChoAiXuLy(ngonNguHienTai.value)),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      _moRongNhoChonPhanTram = chonPhanTram;
      _moRongNhoPhanTram = phanTram;
      _moRongNhoChonCauLenh = chonCauLenh;
      _moRongNhoCauLenh = oCauLenh.text;
      oCauLenh.dispose();
    });
  }

  Future<void> _guiMoRongChoAi({
    required String vanBanGoc,
    required TextSelection? vungChon,
    int? phanTram,
    String? huongDanNguoiDung,
  }) async {
    if (await chanNeuDaChamHanMucAi(context, LoaiHanMucAi.vanBan)) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text(Ch.dangMoRongToanVan(ngonNguHienTai.value))),
          ],
        ),
      ),
    );

    String? vanBanKetQua;
    String? loi;
    Object? loiObj;
    try {
      vanBanKetQua = await guiMoRongChoGemini(
        vanBanGoc,
        phanTram: phanTram,
        huongDanNguoiDung: huongDanNguoiDung,
      );
    } catch (e) {
      loi = e.toString();
      loiObj = e;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // đóng hộp "đang xử lý".

    if (loiObj is LoiHanMucAi) {
      await ghiNhoDaChamHanMucAi(loiObj.loai, loiObj.thongDiep);
      if (mounted) await hienHopThoaiHanMucAi(context, loiObj.thongDiep);
      return;
    }
    if (loi != null || vanBanKetQua == null || vanBanKetQua.trim().isEmpty) {
      _bao(Ch.moRongThatBai(ngonNguHienTai.value, loi ?? 'không có nội dung trả về.'));
      return;
    }

    _moModalKetQuaToanVan(
      vanBanKetQua,
      tieuDe: Ch.ketQuaMoRong(ngonNguHienTai.value, vungChon != null),
      vungChon: vungChon,
    );
  }

  /// Mục "Viết lại cho hay hơn" trong menu "Làm việc với AI" — ĐƠN GIẢN HƠN
  /// tóm tắt/mở rộng: modal chỉ có MỘT ô câu lệnh tự do (giới hạn 500 ký
  /// tự), CÓ THỂ ĐỂ TRỐNG — để trống thì AI tự do chọn cách viết lại theo
  /// ý nó, không có lựa chọn %.
  void _moModalChonKieuVietLai() {
    final vungChon = _vungDangChonHopLe();
    final vanBanGoc = vungChon != null ? vungChon.textInside(_boDieuKhien.text) : _boDieuKhien.text;
    if (vanBanGoc.trim().isEmpty) {
      _bao(vungChon != null
          ? Ch.doanDangChonTrongKhongCoGiDeVietLai(ngonNguHienTai.value)
          : Ch.trangDangTrongKhongCoGiDeVietLai(ngonNguHienTai.value));
      return;
    }
    if (!_coTheDungAIVoiVanBan(vanBanGoc, coVungChon: vungChon != null)) return;
    final oCauLenh = TextEditingController(text: _vietLaiNhoCauLenh);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhat) => AlertDialog(
          title: Text(Ch.vietLaiChoHayHonTieuDe(ngonNguHienTai.value, vungChon != null)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Ch.banCoTheGhiCauLenhRiengChoCachVietLai(ngonNguHienTai.value),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: oCauLenh,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: Ch.viDuVietGiongTrangTrong(ngonNguHienTai.value),
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _xacNhanXoaCauLenh(ctx, oCauLenh, () => capNhat(() {})),
                    child: Text(Ch.xoaTatCaDam(ngonNguHienTai.value), style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(Ch.dongBang(ngonNguHienTai.value)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _guiVietLaiChoAi(
                  vanBanGoc: vanBanGoc,
                  vungChon: vungChon,
                  huongDanNguoiDung: oCauLenh.text,
                );
              },
              child: Text(Ch.guiChoAiXuLy(ngonNguHienTai.value)),
            ),
          ],
        ),
      ),
    ).then((_) {
      _vietLaiNhoCauLenh = oCauLenh.text;
      oCauLenh.dispose();
    });
  }

  Future<void> _guiVietLaiChoAi({
    required String vanBanGoc,
    required TextSelection? vungChon,
    String? huongDanNguoiDung,
  }) async {
    if (await chanNeuDaChamHanMucAi(context, LoaiHanMucAi.vanBan)) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text(Ch.dangVietLaiToanVan(ngonNguHienTai.value))),
          ],
        ),
      ),
    );

    String? vanBanKetQua;
    String? loi;
    Object? loiObj;
    try {
      vanBanKetQua = await guiVietLaiChoGemini(
        vanBanGoc,
        huongDanNguoiDung: huongDanNguoiDung,
      );
    } catch (e) {
      loi = e.toString();
      loiObj = e;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // đóng hộp "đang xử lý".

    if (loiObj is LoiHanMucAi) {
      await ghiNhoDaChamHanMucAi(loiObj.loai, loiObj.thongDiep);
      if (mounted) await hienHopThoaiHanMucAi(context, loiObj.thongDiep);
      return;
    }
    if (loi != null || vanBanKetQua == null || vanBanKetQua.trim().isEmpty) {
      _bao(Ch.vietLaiThatBai(ngonNguHienTai.value, loi ?? 'không có nội dung trả về.'));
      return;
    }

    _moModalKetQuaToanVan(
      vanBanKetQua,
      tieuDe: Ch.ketQuaVietLai(ngonNguHienTai.value, vungChon != null),
      vungChon: vungChon,
    );
  }

  /// Mục "Trò chuyện về văn bản này" trong menu "Làm việc với AI" — mở màn
  /// hình chat TOÀN MÀN HÌNH (`ManHinhTroChuyen`). RIÊNG với nút "Trò
  /// chuyện" ngoài thanh công cụ (tính năng xã hội khác hẳn, xem
  /// `_moThongBaoTroChuyenDangNangCap`).
  ///
  /// [_troChuyenTheoTep]: mỗi tệp ghi chú giữ RIÊNG một cuộc trò chuyện,
  /// khoá theo `_ghiChuHienTai.id` — y hệt cách `_lichSuLuiTheoTep` giữ
  /// riêng Lùi lại/Tiến tới cho từng tệp. Chỉ sống trong bộ nhớ (RAM) của
  /// phiên hiện tại — tải lại trang (F5) hay mở lại app thì mất sạch, đúng
  /// như "bộ nhớ đệm" yêu cầu, KHÔNG lưu ổ đĩa/Realtime Database. Danh
  /// sách trả về là THAM CHIẾU thật nằm trong Map, nên `ManHinhTroChuyen`
  /// tự thêm/xoá tin nhắn thẳng vào đó là đã "lưu" lại cho tệp này, không
  /// cần cơ chế callback nào thêm.
  final Map<String, List<TinNhanTroChuyen>> _troChuyenTheoTep = {};

  /// (YÊU CẦU MỚI) Câu đang gõ dở, CHƯA gửi, trong khung nhập của kênh
  /// chat — CÙNG khuôn với [_troChuyenTheoTep] (khoá theo
  /// `_ghiChuHienTai.id`, chỉ sống trong RAM của phiên hiện tại): thoát
  /// kênh chat ra rồi vào lại (của ĐÚNG tệp này) vẫn thấy câu đang gõ dở,
  /// chứ không chỉ riêng lịch sử các tin đã gửi.
  final Map<String, String> _draftTroChuyenTheoTep = {};

  void _moTroChuyenVeVanBan() {
    final idTep = _ghiChuHienTai.id;
    final lichSu = _troChuyenTheoTep.putIfAbsent(idTep, () => []);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManHinhTroChuyen(
          lichSu: lichSu,
          layVanBanHienTai: () => _boDieuKhien.text,
          layDoanVanDangChon: _layDoanVanDangChon,
          caiDat: widget.caiDat,
          draftBanDau: _draftTroChuyenTheoTep[idTep],
          khiDoiDraft: (chu) => _draftTroChuyenTheoTep[idTep] = chu,
        ),
      ),
    );
  }

  /// Nút "Trò chuyện" NGOÀI thanh công cụ — "Trò chuyện VỚI MỌI NGƯỜI", một
  /// tính năng xã hội khác hẳn "Trò chuyện về văn bản này" (chat với AI, ở
  /// trên) — chưa làm, chỉ báo đang nâng cấp.
  void _moThongBaoTroChuyenDangNangCap() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Ch.troChuyenDangNangCapTieuDe(ngonNguHienTai.value)),
        content: Text(Ch.troChuyenDangNangCapNoiDung(ngonNguHienTai.value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Ch.daHieu(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
  }

  /// Giữ nội dung modal kết quả "Tóm tắt toàn văn"/"Mở rộng toàn văn"/"Viết
  /// lại cho hay hơn" qua lần mở lại (nếu có, dù luồng hiện tại luôn
  /// mở-rồi-đóng-hẳn) — dùng CHUNG cho cả ba tính năng (chỉ khác [tieuDe]),
  /// cùng ý tưởng `_oKetQuaFileAmThanh`, nhưng KHÔNG có "Chọn vị trí để chèn văn bản":
  /// cả hai đều luôn thay thế TOÀN VĂN, không chèn tại một vị trí.
  TextEditingController? _oKetQuaToanVan;
  String _tieuDeModalKetQuaToanVan = 'Kết quả tóm tắt';

  void _dongHanKetQuaToanVan() {
    _oKetQuaToanVan?.dispose();
    _oKetQuaToanVan = null;
  }

  void _moModalKetQuaToanVan(String vanBan, {String? tieuDe, TextSelection? vungChon}) {
    if (tieuDe != null) _tieuDeModalKetQuaToanVan = tieuDe;
    _oKetQuaToanVan ??= TextEditingController(text: vanBan);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tieuDeModalKetQuaToanVan),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Ch.banCoTheBamOBenDuoiDeSuaTruocKhiThayThe(ngonNguHienTai.value),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: TextField(
                    controller: _oKetQuaToanVan,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => _xacNhanHuyKetQuaToanVan(ctx),
            child: Text(Ch.huy(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _oKetQuaToanVan?.text ?? ''));
              if (mounted) _bao(Ch.daSaoChepToast(ngonNguHienTai.value));
            },
            child: Text(Ch.saoChepTatCa(ngonNguHienTai.value)),
          ),
          FilledButton(
            onPressed: () {
              final vb = _oKetQuaToanVan?.text ?? '';
              Navigator.of(ctx).pop();
              _dongHanKetQuaToanVan();
              if (vb.trim().isEmpty) return;
              if (vungChon != null) {
                _thayTheDoanDangChon(vungChon, vb);
              } else {
                _thayTheToanBoVanBan(vb);
              }
            },
            child: Text(Ch.thayTheDoanDaChon(ngonNguHienTai.value, vungChon != null)),
          ),
        ],
      ),
    );
  }

  Future<void> _xacNhanHuyKetQuaToanVan(BuildContext ctxModal) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx2) => AlertDialog(
        title: Text(Ch.huyKetQuaNay(ngonNguHienTai.value)),
        content: Text(Ch.vanBanAiSapMatKhiHuy(ngonNguHienTai.value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx2).pop(false),
            child: Text(Ch.khongGiuLai(ngonNguHienTai.value)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx2).pop(true),
            child: Text(Ch.huy(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (dongY == true && mounted) {
      Navigator.of(ctxModal).pop();
      _dongHanKetQuaToanVan();
    }
  }

  /// Nút "Thay thế toàn bộ văn bản" ở modal kết quả "Tóm tắt toàn văn"/"Mở
  /// rộng toàn văn" — xoá sạch văn bản hiện tại, ghi đè bằng [vanBanMoi]. Y
  /// HỆT logic `_xoaTatCa` (mọi mốc trạng thái phải reset về vạch xuất phát,
  /// nếu không câu nói kế tiếp lại nhắm vào vị trí không còn tồn tại) — chỉ
  /// khác ghi [vanBanMoi] thay vì chuỗi rỗng. `_luuDiemMoc()` chụp lại bản
  /// CŨ trước khi ghi đè (kèm lưu vào bộ nhớ đệm qua `_luuVanBan()`), để
  /// Lùi lại (Ctrl+Z) khôi phục đúng bản gốc.
  Future<void> _thayTheToanBoVanBan(String vanBanMoi) async {
    _luuDiemMoc();

    _ghiVaoO(vanBanMoi, vanBanMoi.length);
    _neo = vanBanMoi.length;
    _chuTam = '';
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    for (final k in _boDieuKhien.khongPhuHop) {
      k.henNhapNhay?.cancel();
    }
    _boDieuKhien.khongPhuHop.clear();
    for (final x in _boDieuKhien.canXoa) {
      x.henNhapNhay?.cancel();
    }
    _boDieuKhien.canXoa.clear();
    _viTriDaKiemTraChinhTa = 0;
    _cacViTriDuongKeChia.clear();
    _viTriChoVietHoa = null;
    _boQuaCauNay = _micro.isListening;
    await _luuVanBan();
    // Toàn văn vừa được AI viết lại nhấp nháy xanh/đen 4 giây — TÁI DÙNG
    // nguyên cơ chế `_VungKhongPhuHop` của "đoạn AI đề xuất thay thế" (mục
    // "Kiểm tra toàn văn"), xem `_nhapNhayToanVan`.
    if (mounted) _nhapNhayToanVan(0, vanBanMoi.length);
    if (mounted) _bao(Ch.daThayTheToanBoVanBan(ngonNguHienTai.value));
  }

  /// Cho khoảng chữ [batDau, ketThuc) — thường là TOÀN BỘ văn bản vừa được
  /// AI viết lại/thay thế — nhấp nháy xanh dương/đen trong 4 giây rồi tự
  /// dọn, không cần gọi gì thêm. TÁI DÙNG NGUYÊN `_VungKhongPhuHop` +
  /// `_batNhapNhayKhongPhuHop` đã có cho "đoạn AI đề xuất thay thế" (mục
  /// "Kiểm tra toàn văn") — chỉ khác: "gốc" và "đề xuất" trỏ CHUNG một
  /// khoảng (không có gì để đổi qua đổi lại, chỉ mượn hiệu ứng thị giác,
  /// không có tương tác bấm chọn nào đi kèm).
  void _nhapNhayToanVan(int batDau, int ketThuc) {
    if (batDau < 0 || batDau >= ketThuc || ketThuc > _boDieuKhien.text.length) return;
    final v = _VungKhongPhuHop(
      batDauGoc: batDau,
      ketThucGoc: ketThuc,
      batDauDeXuat: batDau,
      ketThucDeXuat: ketThuc,
    );
    _boDieuKhien.khongPhuHop.add(v);
    _batNhapNhayKhongPhuHop(v, 'xanh');
  }

  // --------------------------------------- AI làm việc với vùng đang chọn

  /// Nội dung vùng chọn hiện có trong ô soạn thảo, hay `null` nếu không có
  /// vùng chọn thật (con trỏ đứng yên/không hợp lệ/rỗng) — dùng để các mục
  /// "Làm việc với AI" (tóm tắt/mở rộng/viết lại/kiểm tra chính tả/kiểm tra
  /// dấu câu/trò chuyện) tự đổi tên "...toàn văn" → "...đoạn văn này"/"...
  /// đoạn văn đã chọn" ngay trong menu, và kênh chat biết có gì để đính kèm
  /// khi bấm "+". Gọi lại MỖI LẦN cần biết (không lưu trạng thái), vì vùng
  /// chọn đổi liên tục theo thao tác của người dùng.
  String? _layDoanVanDangChon() {
    final vung = _vungDangChonHopLe();
    return vung == null ? null : vung.textInside(_boDieuKhien.text);
  }

  /// Vùng chọn THẬT SỰ đang có trên trang soạn thảo — KHÔNG bị ảnh hưởng bởi
  /// công tắc [_epToanVanKhiCoVungChon]. Dùng để quyết định nút "Làm việc với
  /// AI" có sáng nền xanh hay không, và mục "Làm việc với Toàn bộ văn
  /// bản"/"Làm việc với Đoạn văn đang chọn" có hiện ra hay không — hai chỗ đó
  /// PHẢI thấy vùng chọn thật dù công tắc đang ép toàn văn, nếu không bấm ép
  /// xong sẽ không còn cách nào bấm lại để quay về xử lý đoạn chọn.
  TextSelection? _vungChonThatSu() {
    final sel = _boDieuKhien.selection;
    if (!sel.isValid || sel.isCollapsed) return null;
    final vb = _boDieuKhien.text;
    final batDau = sel.start.clamp(0, vb.length);
    final ketThuc = sel.end.clamp(0, vb.length);
    if (batDau >= ketThuc) return null;
    return TextSelection(baseOffset: batDau, extentOffset: ketThuc);
  }

  /// Y HỆT [_layDoanVanDangChon] nhưng trả về cả TOẠ ĐỘ (`TextSelection`)
  /// — dùng ở nơi cần thay thế ĐÚNG LẠI đoạn đó sau khi AI xử lý xong (xem
  /// `_thayTheDoanDangChon`), thay vì thay cả bài. Tôn trọng công tắc
  /// [_epToanVanKhiCoVungChon]: đang ép toàn văn thì coi như không có vùng
  /// chọn, để mọi nơi xử lý AI tự chuyển sang xử lý cả bài.
  TextSelection? _vungDangChonHopLe() {
    if (_epToanVanKhiCoVungChon) return null;
    return _vungChonThatSu();
  }

  /// (YÊU CẦU MỚI) Giới hạn ký tự khi dùng các mục "Làm việc với AI" tác
  /// động lên TOÀN VĂN hoặc một VÙNG CHỌN (tóm tắt/mở rộng/viết lại/trò
  /// chuyện/kiểm tra toàn văn/chính tả/dấu câu) — tránh gửi một văn bản quá
  /// dài khiến yêu cầu AI chậm/tốn kém bất thường. Gọi NGAY ĐẦU mỗi hàm xử
  /// lý, trước khi làm gì khác; trả `false` (và tự hiện thông báo giữa màn
  /// hình) nếu vượt giới hạn — nơi gọi `return` ngay khi gặp `false`.
  /// - Không có vùng chọn (áp dụng cho TOÀN VĂN): tối đa 20.000 ký tự.
  /// - Có vùng chọn: tối đa 10.000 ký tự.
  bool _coTheDungAIVoiVanBan(String vanBan, {required bool coVungChon}) {
    final gioiHan = coVungChon ? 10000 : 20000;
    if (vanBan.length <= gioiHan) return true;
    hienThongBaoGiua(
      context,
      coVungChon
          ? Ch.vungChonVuotQua10000KyTu(ngonNguHienTai.value)
          : Ch.toanBoVanBanVuotQua20000KyTu(ngonNguHienTai.value),
    );
    return false;
  }

  /// Nút "Thay thế đoạn đã chọn" ở modal kết quả (tóm tắt/mở rộng/viết lại
  /// khi bắt đầu từ một vùng chọn) — như `_thayTheToanBoVanBan` nhưng chỉ
  /// ghi đè đúng [vung]: vị trí vùng chọn LÚC BẤM MỞ modal chọn kiểu, KHÔNG
  /// phải vùng chọn hiện tại. Trong suốt lúc chờ AI xử lý, mọi hộp thoại đi
  /// qua đều `barrierDismissible: false` nên trang soạn thảo phía sau không
  /// thể bị đụng vào — vị trí đó chắc chắn còn đúng, chỉ kiểm tra lại cho
  /// chắc (đề phòng văn bản bị đổi qua đường khác, ví dụ ghi âm nền).
  Future<void> _thayTheDoanDangChon(TextSelection vung, String vanBanMoi) async {
    final vbHienTai = _boDieuKhien.text;
    if (vung.start < 0 || vung.end > vbHienTai.length || vung.start >= vung.end) {
      _bao(Ch.doanVanBanGocDaThayDoi(ngonNguHienTai.value));
      return;
    }
    _luuDiemMoc();
    _dieuChinhLoiChinhTaSauKhiSua(vung.start, vung.end - vung.start, vanBanMoi.length);
    _dieuChinhVungToanVanSauKhiSua(vung.start, vung.end - vung.start, vanBanMoi.length);
    final moi = vbHienTai.replaceRange(vung.start, vung.end, vanBanMoi);
    final viTriConTroMoi = vung.start + vanBanMoi.length;
    _ghiVaoO(moi, viTriConTroMoi);
    _neo = viTriConTroMoi;
    await _luuVanBan();
    if (mounted) _nhapNhayToanVan(vung.start, viTriConTroMoi);
    if (mounted) _bao(Ch.daThayTheDoanVanBanDaChon(ngonNguHienTai.value));
  }

  /// Dịch mọi "viTri" trong [kq] thêm [dich] — dùng khi "Kiểm tra lỗi chính
  /// tả toàn văn"/"Kiểm tra dấu câu toàn văn" chạy trên một ĐOẠN CHỌN thay
  /// vì cả bài: máy chủ AI trả "viTri" tính trên đoạn gửi lên (bắt đầu từ
  /// 0), phải cộng lại đúng vị trí bắt đầu của đoạn đó trên TOÀN VĂN trước
  /// khi đưa cho `_apDungKetQuaToanVan` (hàm đó luôn thao tác trên toạ độ
  /// toàn văn).
  KetQuaKiemTraToanVan _dichKetQuaToanVan(KetQuaKiemTraToanVan kq, int dich) {
    if (dich == 0) return kq;
    return KetQuaKiemTraToanVan(
      chinhTa: [
        for (final c in kq.chinhTa) ChinhTaMuc(tu: c.tu, viTri: c.viTri + dich, deXuat: c.deXuat),
      ],
      khongPhuHop: [
        for (final k in kq.khongPhuHop)
          KhongPhuHopMuc(doan: k.doan, viTri: k.viTri + dich, deXuat: k.deXuat),
      ],
      canXoa: [
        for (final x in kq.canXoa) CanXoaMuc(doan: x.doan, viTri: x.viTri + dich),
      ],
      dauCauMoi: [
        for (final d in kq.dauCauMoi) DauCauMoiToanVanMuc(dauCau: d.dauCau, viTri: d.viTri + dich),
      ],
    );
  }

  /// Mục "Chụp ảnh (camera)" trong menu "Làm việc với AI" — ĐÚNG LUỒNG với
  /// `_chonVaChuyenAnhThanhVanBan` ở trên (cùng gọi Gemini, cùng modal kết
  /// quả sửa được + Huỷ có xác nhận + Chọn vị trí để chèn), chỉ khác nguồn
  /// ảnh: mở thẳng camera thiết bị (`image_picker`) thay vì bộ chọn tệp có
  /// sẵn.
  Future<void> _chupVaChuyenAnhThanhVanBan() async {
    XFile? anh;
    try {
      anh = await ImagePicker().pickImage(source: ImageSource.camera);
    } catch (e) {
      if (mounted) _bao(Ch.khongMoDuocCamera(ngonNguHienTai.value, '$e'));
      return;
    }
    if (anh == null) return; // người dùng huỷ chụp (bấm lùi lại/đóng camera).

    Uint8List bytes;
    try {
      bytes = await anh.readAsBytes();
    } catch (e) {
      if (mounted) _bao(Ch.khongDocDuocAnhVuaChup(ngonNguHienTai.value, '$e'));
      return;
    }
    if (bytes.length > _gioiHanTepAnhByte) {
      final soMB = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      _bao(Ch.anhVuaChupNangQuaMB(ngonNguHienTai.value, soMB));
      return;
    }

    final phanDuoi = anh.name.contains('.') ? anh.name.split('.').last : 'jpg';
    final mimeType = anh.mimeType ?? _doanMimeAnhTuDuoiTep(phanDuoi);

    if (!mounted) return;
    if (await chanNeuDaChamHanMucAi(context, LoaiHanMucAi.hinhAnh)) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text(Ch.dangChuyenHinhAnhThanhVanBan(ngonNguHienTai.value))),
          ],
        ),
      ),
    );

    String? vanBanKetQua;
    String? loi;
    Object? loiObj;
    try {
      vanBanKetQua = await guiAnhChoGemini(bytes, mimeType);
    } catch (e) {
      loi = e.toString();
      loiObj = e;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // đóng hộp "đang xử lý".

    if (loiObj is LoiHanMucAi) {
      await ghiNhoDaChamHanMucAi(loiObj.loai, loiObj.thongDiep);
      if (mounted) await hienHopThoaiHanMucAi(context, loiObj.thongDiep);
      return;
    }
    if (loi != null || vanBanKetQua == null || vanBanKetQua.trim().isEmpty) {
      _bao(Ch.chuyenAnhThatBai(ngonNguHienTai.value, loi ?? 'không có nội dung trả về.'));
      return;
    }

    _moModalKetQuaFileAmThanh(vanBanKetQua, tieuDe: 'anhChup');
  }

  /// Giữ nội dung modal kết quả AI qua nhiều lần mở/đóng (bấm "Chọn vị trí
  /// để chèn văn bản" chỉ ẨN modal, không đóng hẳn — quay lại vẫn phải thấy
  /// đúng bản người dùng vừa sửa, không phải bản gốc AI trả về ban đầu).
  /// `null` nghĩa là không có phiên "kết quả AI từ tệp" nào đang mở. DÙNG
  /// CHUNG cho cả "Chuyển file âm thanh" lẫn "Chuyển hình ảnh" — luồng hai
  /// tính năng giống hệt nhau, chỉ khác tiêu đề modal
  /// (`_tieuDeModalKetQuaFile`) và hàm gọi AI phía trước.
  TextEditingController? _oKetQuaFileAmThanh;
  String _tieuDeModalKetQuaFile = 'amThanh';

  void _dongHanKetQuaFileAmThanh() {
    _oKetQuaFileAmThanh?.dispose();
    _oKetQuaFileAmThanh = null;
  }

  /// [vanBan] chỉ dùng để KHỞI TẠO controller lần đầu (từ text AI trả về) —
  /// những lần mở lại sau đó (do bấm "Quay lại kết quả AI") controller đã
  /// tồn tại sẵn với đúng nội dung người dùng vừa sửa, không ghi đè lại.
  /// [tieuDe] chỉ cần truyền ở lần mở ĐẦU (từ `_chonVaChuyenFileAmThanh`/
  /// `_chonVaChuyenAnhThanhVanBan`) — các lần mở lại sau đó bỏ trống, giữ
  /// nguyên tiêu đề đã lưu.
  void _moModalKetQuaFileAmThanh(String vanBan, {String? tieuDe}) {
    if (tieuDe != null) _tieuDeModalKetQuaFile = tieuDe;
    _oKetQuaFileAmThanh ??= TextEditingController(text: vanBan);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Ch.tieuDeModalKetQuaFile(_tieuDeModalKetQuaFile, ngonNguHienTai.value)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Ch.banCoTheBamOBenDuoiDeSuaTruocKhiChen(ngonNguHienTai.value),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: TextField(
                    controller: _oKetQuaFileAmThanh,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => _xacNhanHuyKetQuaFileAmThanh(ctx),
            child: Text(Ch.huy(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _oKetQuaFileAmThanh?.text ?? ''),
                  );
                  if (mounted) _bao(Ch.daSaoChepToast(ngonNguHienTai.value));
                },
                child: Text(Ch.saoChepTatCa(ngonNguHienTai.value)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _batDauChonViTriChenFile();
                },
                child: Text(Ch.chonViTriDeChenVanBan(ngonNguHienTai.value)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final vb = _oKetQuaFileAmThanh?.text ?? '';
                  Navigator.of(ctx).pop();
                  _dongHanKetQuaFileAmThanh();
                  if (vb.isNotEmpty) _chenKyTuTuPhimAo(vb);
                },
                child: Text(Ch.chenVaoVanBanDangSoan(ngonNguHienTai.value)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bấm "Huỷ" trên modal kết quả AI — hỏi xác nhận trước vì kết quả AI vừa
  /// tốn tiền phiên âm sẽ mất hẳn, không lấy lại được.
  Future<void> _xacNhanHuyKetQuaFileAmThanh(BuildContext ctxModal) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx2) => AlertDialog(
        title: Text(Ch.huyKetQuaTuAi(ngonNguHienTai.value)),
        content: Text(Ch.vanBanAiVuaPhienAmSeMatNeuHuy(ngonNguHienTai.value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx2).pop(false),
            child: Text(Ch.khongGiuLai(ngonNguHienTai.value)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx2).pop(true),
            child: Text(Ch.huy(ngonNguHienTai.value), style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (dongY == true && mounted) {
      Navigator.of(ctxModal).pop();
      _dongHanKetQuaFileAmThanh();
    }
  }

  // --------------------- chọn vị trí chèn (file âm thanh thành văn bản)

  /// Bật "chế độ chọn vị trí chèn" — ẩn hết AppBar/thanh định dạng/Bộ phím
  /// nhanh/thanh công cụ dưới, chỉ chừa khung soạn thảo (di chuyển con trỏ
  /// bằng chạm/chuột/phím mũi tên bình thường) và một thanh riêng ở đáy
  /// (dấu cách/xuống dòng/xoá — mượn lại từ Bộ phím nhanh — cộng hai nút
  /// Chèn/Quay lại).
  void _batDauChonViTriChenFile() {
    setState(() => _dangChonViTriChenFile = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
    });
  }

  /// Bấm "Quay lại kết quả AI" — tắt chế độ chọn vị trí, mở lại ĐÚNG modal
  /// cũ (controller vẫn giữ nguyên nội dung, kể cả phần đã sửa).
  void _quayLaiKetQuaFileAmThanh() {
    setState(() => _dangChonViTriChenFile = false);
    if (_oKetQuaFileAmThanh != null) {
      _moModalKetQuaFileAmThanh(_oKetQuaFileAmThanh!.text);
    }
  }

  /// Bấm "Chèn vào vị trí này" — lấy đúng bản CUỐI CÙNG trong ô sửa (dù
  /// người dùng có sửa hay không), chèn ngay tại vị trí con trỏ/đè lên vùng
  /// đang chọn (`_chenKyTuTuPhimAo` đã tự lo việc này), rồi thoát hẳn khỏi
  /// cả chế độ chọn vị trí lẫn phiên chuyển-file-âm-thanh — không hỏi lại.
  void _chenTaiViTriDaChon() {
    final vb = _oKetQuaFileAmThanh?.text ?? '';
    setState(() => _dangChonViTriChenFile = false);
    _dongHanKetQuaFileAmThanh();
    if (vb.isNotEmpty) _chenKyTuTuPhimAo(vb);
  }

  OverlayEntry? _baoDangHien;

  /// (VIỆC 6) [spans] khác null thì hiện bằng `RichText`/`TextSpan` (cho phép
  /// một phần câu nổi bật hơn phần còn lại, ví dụ tên tệp) thay vì [loi]
  /// dạng chuỗi trần — TÁI DÙNG đúng khung/màu nền/thời lượng tự ẩn 2 giây,
  /// chỉ khác phần nội dung bên trong.
  void _bao(String loi, {List<InlineSpan>? spans}) {
    if (!mounted) return;
    _baoDangHien?.remove();
    _baoDangHien = null;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF323232),
              borderRadius: BorderRadius.circular(10),
            ),
            child: spans == null
                ? Text(
                    loi,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  )
                : RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      children: spans,
                    ),
                  ),
          ),
        ),
      ),
    );
    _baoDangHien = entry;
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (_baoDangHien == entry) {
        entry.remove();
        _baoDangHien = null;
      }
    });
  }

  /// (VIỆC 6c) Popup "Đang ở trong Tệp <tên tệp>" sau khi chuyển sang ghi
  /// chú khác bằng nút "Tệp trước"/"Tệp sau" — phần tên tệp in đậm/nổi bật
  /// hơn phần còn lại của câu.
  void _baoDangOTrongTep(String ten) {
    _bao(
      'Đang ở trong Tệp $ten',
      spans: [
        const TextSpan(text: 'Đang ở trong Tệp '),
        TextSpan(
          text: ten,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8AB4F8)),
        ),
      ],
    );
  }

  /// Chặn mở CHỒNG nhiều hộp thoại lỗi treMu khi người dùng gõ nhanh/giọng
  /// nói đổ về nhiều ký tự không hợp lệ liên tiếp — chỉ hộp thoại ĐẦU TIÊN
  /// mở ra, các lần gọi tiếp theo trong lúc nó còn mở đều bị bỏ qua.
  bool _dangHienLoiTreMu = false;

  /// Hộp thoại cảnh báo dùng chung cho MỌI điểm treMu bị chặn (bấm nút/phím
  /// tắt với vùng chọn có ký tự không hợp lệ, gõ tay/giọng nói chèn ký tự
  /// không hợp lệ khi đang "chờ áp treMu" hoặc đang kế thừa treMu từ ký tự
  /// liền trước) — khác `_bao()` (tự biến mất sau 2 giây): cái này cần người
  /// dùng chủ động bấm "Đã hiểu" để đóng, nên dùng `showDialog` chuẩn.
  void _baoLoiTreMu() {
    if (!mounted || _dangHienLoiTreMu) return;
    _dangHienLoiTreMu = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Ch.khongApDungDuocChuTren(ngonNguHienTai.value)),
        content: Text(Ch.dinhDangChuTrenChiApDungChoSoVaChuThuong(ngonNguHienTai.value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Ch.daHieu(ngonNguHienTai.value)),
          ),
        ],
      ),
    ).then((_) {
      _dangHienLoiTreMu = false;
    });
  }

  String _dichLoi(String ma) {
    switch (ma) {
      case 'error_network':
      case 'error_network_timeout':
        return 'Mất mạng — bộ nhận dạng giọng nói cần Internet.';
      case 'error_audio':
        return 'Không đọc được micro.';
      case 'error_permission':
      case 'error_insufficient_permissions':
        return 'Chưa được cấp quyền ghi âm.';
      case 'error_busy':
        return 'Micro đang bị ứng dụng khác chiếm.';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return 'Máy chưa có gói tiếng Việt cho nhận dạng giọng nói.';
      default:
        return 'Micro gặp trục trặc ($ma).';
    }
  }

  // ----------------------------------------------------------------- dựng

  /// Ngưỡng bề ngang phân biệt màn hình rộng (máy tính bảng — giữ giao diện
  /// một dòng như từ trước tới giờ) và màn hình hẹp (điện thoại — tên tệp và
  /// công cụ phải tách hai dòng, không thì đè lên nhau). 600dp là mốc
  /// Material Design vẫn dùng để phân biệt "compact" và "medium".
  static const _nguongManHinhHep = 600.0;

  /// (VIỆC 6) Ba nút vuông góc 90° dính sát nhau, sát mép trái thanh chứa
  /// tên tệp: "Mở thư mục" (tái dùng ĐÚNG `_moManHinhThuMuc`), "Tệp trước",
  /// "Tệp sau". Mỗi ô là một `Container` viền `Border.all` không bo góc
  /// (không set `borderRadius`) — viền giữa hai ô liền kề chấp nhận bị đôi,
  /// đơn giản nhất mà không lỗi.
  static const _canhNutDieuHuongTep = 34.0;

  Widget _nutVuongDieuHuongTep(
    IconData icon,
    String nhan,
    VoidCallback? khiBam, {
    bool oBienGioi = false,
  }) {
    return Tooltip(
      message: nhan,
      child: InkWell(
        onTap: khiBam,
        child: Container(
          width: _canhNutDieuHuongTep,
          height: _canhNutDieuHuongTep,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: oBienGioi ? Colors.red.shade50 : Colors.white,
            border: Border.all(color: const Color(0xFFDADCE0)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: khiBam == null ? const Color(0xFFBDC1C6) : const Color(0xFF5F6368),
          ),
        ),
      ),
    );
  }

  /// Chiều rộng nút "Thư mục" khi dài ra có chữ (màn hình rộng) — thay cho
  /// ô vuông `_canhNutDieuHuongTep` bình thường. Dùng để tính `leadingWidth`
  /// của AppBar ở nhánh màn rộng.
  static const _rongNutThuMucCoChu = 108.0;

  /// Nút "Mở thư mục" — hai kiểu: ô VUÔNG chỉ icon (màn hẹp, giữ nguyên như
  /// cũ) hoặc DÀI RA có thêm chữ "Thư mục" cạnh icon (màn rộng). Đây giờ là
  /// LỐI VÀO DUY NHẤT của màn Thư mục — nút cùng tên ở thanh công cụ ngang
  /// phía dưới (`ThanhCongCu`) đã bỏ, tránh trùng hai nút một chức năng.
  Widget _nutThuMuc({required bool coChu}) {
    if (!coChu) {
      return _nutVuongDieuHuongTep(
          Icons.folder, Ch.moThuMuc(ngonNguHienTai.value), _moManHinhThuMuc);
    }
    return Tooltip(
      message: Ch.moThuMuc(ngonNguHienTai.value),
      child: InkWell(
        onTap: _moManHinhThuMuc,
        child: Container(
          width: _rongNutThuMucCoChu,
          height: _canhNutDieuHuongTep,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDADCE0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder, size: 18, color: Color(0xFF5F6368)),
              const SizedBox(width: 6),
              Text(Ch.nutThuMuc(ngonNguHienTai.value),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
            ],
          ),
        ),
      ),
    );
  }

  /// Hai nút Copy/Cắt — ĐÚNG widget/hàm dùng ở Bộ phím nhanh
  /// (`_NutCongCuChu`/`_phimAoCopy`/`_phimAoCut`). CHỈ còn dùng cho thanh
  /// công cụ DƯỚI (`ThanhCongCu`, khi có vùng chọn thật) — không còn thay
  /// chỗ 4 nút điều hướng tệp ở AppBar trên nữa (từng khiến Copy/Cắt hiện
  /// ra CÙNG LÚC ở cả hai nơi, lỗi người dùng báo). KHÔNG có "Dán" ở đây —
  /// nút Dán đã luôn hiện sẵn, cố định, ở `_dsNutCongCu`/`_nutDanCongCu`
  /// (thanh trên cùng), thêm một nút Dán thứ hai ở đây chỉ dư thừa.
  ///
  /// (YÊU CẦU MỚI) Thêm nút "Xoá" ngay cạnh bên phải "Cắt" — hình dạng/logic
  /// Y CHANG nút xoá ký tự của Bộ phím nhanh (`_NutPhimAo`, nền/viền đỏ,
  /// nhãn ⌫, gọi thẳng `_xoaKyTuTuPhimAo` — hàm đó đã tự xử lý đúng việc
  /// xoá nguyên vùng đang chọn khi `selection` không rỗng, không cần viết
  /// logic mới), bọc qua `_bamCopyCutPasteOHangThayNav` y hệt Copy/Cắt để
  /// hàng này tự ẩn ngay sau khi bấm. CHỈ hiện ở màn hình KHÔNG quá hẹp —
  /// màn RẤT hẹp (ngưỡng 420, xem `_nguongManHinhRatHep` ở
  /// `thanh_cong_cu.dart`) thì nút này dời lên hàng trên cạnh "Dán" (xem
  /// `build`), không lặp lại ở đây.
  /// (YÊU CẦU MỚI) Hai nút 📖 "Thêm vào Từ điển nhập liệu nhanh"/📒 "Thêm
  /// vào Từ điển sửa lỗi chính tả" — LUÔN đứng ngay bên phải nút "Xoá đoạn
  /// đang chọn" (⌫), bất kể màn rộng/hẹp (xem hai nơi gọi: [_hangCopyCutPaste]
  /// và hàng của màn RẤT hẹp ở `build`) — nền xanh dương đậm "sáng lên" để
  /// nổi bật so với Copy/Cắt/Xoá.
  List<Widget> _haiNutThemVaoTuDien() => [
        const SizedBox(width: 6),
        _NutPhimAo(
          nhan: '📖',
          moTa: Ch.themVungChonVaoTuDienNhapLieuNhanh(ngonNguHienTai.value),
          mauNen: const Color(0xFF1A73E8),
          mauVien: const Color(0xFF0B57D0),
          rong: 40,
          onTap: () => _bamCopyCutPasteOHangThayNav(_themVungChonVaoTuDienNhapLieuNhanh),
        ),
        const SizedBox(width: 6),
        _NutPhimAo(
          nhan: '📒',
          moTa: Ch.themVungChonVaoTuDienChinhTa(ngonNguHienTai.value),
          mauNen: const Color(0xFF1A73E8),
          mauVien: const Color(0xFF0B57D0),
          rong: 40,
          onTap: () => _bamCopyCutPasteOHangThayNav(_themVungChonVaoTuDienChinhTa),
        ),
      ];

  Widget _hangCopyCutPaste() {
    // Chữ xanh dương — nổi bật đúng ngữ cảnh "đang ở phía trên", khác hai nút
    // cùng tên ở Bộ phím nhanh (giữ màu mặc định).
    const mauChu = Color(0xFF1A73E8);
    final ratHep = MediaQuery.sizeOf(context).width < 420;
    // (YÊU CẦU MỚI) Màn hẹp BÌNH THƯỜNG (không rất hẹp) — hai nút 📖/📒 dời
    // LÊN hàng trên cùng (chung dòng tên tệp, sát bên trái "Dán", xem
    // `build`), không lặp lại ở đây nữa. Màn RỘNG (không `manHinhHep`) vẫn
    // giữ ở đây, ngay cạnh nút Xoá như cũ.
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NutCongCuChu(
          nhan: 'Copy',
          mauChu: mauChu,
          onTap: () => _bamCopyCutPasteOHangThayNav(_phimAoCopy),
        ),
        const SizedBox(width: 6),
        _NutCongCuChu(
          nhan: Ch.cat(ngonNguHienTai.value),
          mauChu: mauChu,
          onTap: () => _bamCopyCutPasteOHangThayNav(_phimAoCut),
        ),
        if (!ratHep) ...[
          const SizedBox(width: 6),
          _NutPhimAo(
            nhan: '⌫',
            moTa: Ch.xoaDoanDangChon(ngonNguHienTai.value),
            mauNen: Colors.red.shade50,
            mauVien: Colors.red.shade300,
            rong: 40,
            onTap: () => _bamCopyCutPasteOHangThayNav(_xoaChonOHangCopyCutPaste),
          ),
          if (!manHinhHep) ..._haiNutThemVaoTuDien(),
        ],
      ],
    );
  }

  Widget _nutDieuHuongTep({bool nutThuMucCoChu = false}) {
    // Copy/Cắt giờ CHỈ hiện ở thanh công cụ DƯỚI (`ThanhCongCu`) khi có
    // vùng chọn thật — không còn thay chỗ 4 nút điều hướng tệp ở đây nữa,
    // tránh hiện ra CÙNG LÚC ở cả hai nơi (lỗi người dùng báo). 4 nút điều
    // hướng tệp giờ LUÔN hiện, không đổi theo vùng chọn.
    //
    // (YÊU CẦU MỚI) Hai nút này KHÔNG còn bị xám/liệt ở đầu/cuối danh sách
    // nữa — bấm ở biên thì NHẢY VÒNG (xem `_chuyenTepTrongThuMuc`), và nút
    // đang ở đúng biên đó đổi nền đỏ nhạt để báo hiệu. Chỉ liệt hẳn khi thư
    // mục CHỈ CÓ một tệp (không có gì khác để nhảy tới).
    final ds = _dsGhiChuCungThuMuc();
    final viTriHienTai = ds.indexWhere((g) => g.id == _ghiChuHienTai.id);
    final coNhieuHonMotTep = ds.length > 1;
    final oDauDanhSach = viTriHienTai == 0;
    final oCuoiDanhSach = viTriHienTai == ds.length - 1;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _nutThuMuc(coChu: nutThuMucCoChu),
          _nutMoRongTep(),
          _nutVuongDieuHuongTep(
            Icons.arrow_back,
            Ch.tepTruoc(ngonNguHienTai.value),
            coNhieuHonMotTep ? () => _chuyenTepTrongThuMuc(-1) : null,
            oBienGioi: coNhieuHonMotTep && oDauDanhSach,
          ),
          _nutVuongDieuHuongTep(
            Icons.arrow_forward,
            Ch.tepSau(ngonNguHienTai.value),
            coNhieuHonMotTep ? () => _chuyenTepTrongThuMuc(1) : null,
            oBienGioi: coNhieuHonMotTep && oCuoiDanhSach,
          ),
        ],
      ),
    );
  }

  /// Nút "Mở rộng" — nằm giữa "Mở thư mục" và "Tệp trước". Icon ba chấm xếp
  /// DỌC (`Icons.more_vert`, khác `Icons.more_horiz` của các menu ngang khác
  /// trong app) cho đúng ý "ba chấm xếp chồng lên nhau thành một hàng dọc".
  /// Ba lựa chọn đều gọi lại ĐÚNG hàm đã có (tạo/xoá/đổi màu tệp), không
  /// viết logic mới — chỉ nối thêm một lối vào khác cho chúng.
  Widget _nutMoRongTep() {
    return Tooltip(
      message: Ch.moRong(ngonNguHienTai.value),
      child: PopupMenuButton<String>(
        tooltip: '',
        onSelected: (v) {
          // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Xem
          // `_ngungMicroVaGhiAmTheNeuDangBat`.
          unawaited(_ngungMicroVaGhiAmTheNeuDangBat());
          switch (v) {
            case 'taoMoi':
              _taoTepMoiTuThanhCongCu();
            case 'xoa':
              _xoaTepHienTaiTuThanhCongCu();
            case 'mau':
              _chonMauTenTepHienTai();
            case 'tai_ve':
              () async {
                hienThongBaoGiua(context, Ch.dangTaiFileTxtVeThietBi(ngonNguHienTai.value));
                try {
                  final tenTep =
                      '${_ghiChuHienTai.ten.trim().isEmpty ? 'Ghi chú' : _ghiChuHienTai.ten.trim()}.txt';
                  await luuVaChiaSeGhiChu(
                      tenTep, _ghiChuHienTai.noiDung, _ghiChuHienTai.ten);
                } catch (_) {
                  if (mounted) {
                    hienThongBaoGiua(context, Ch.khongXuatDuocTepThuLaiSau(ngonNguHienTai.value));
                  }
                }
              }();
            case 'thong_tin':
              hienThongTinGhiChu(
                  context, ten: _ghiChuHienTai.ten, noiDung: _ghiChuHienTai.noiDung);
            case 'chia_se_link':
              if (widget.kho is KhoDuLieuDamMay) {
                hienModalChiaSeTep(context,
                    ghiChu: _ghiChuHienTai, kho: widget.kho as KhoDuLieuDamMay);
              }
          }
        },
        itemBuilder: (ctx) {
          final vb = _boDieuKhien.text;
          final soTu = vb.trim().isEmpty ? 0 : RegExp(r'\S+').allMatches(vb).length;
          final soKyTuCoDauCach = vb.length;
          final soKyTuKhongDauCach = vb.replaceAll(RegExp(r'\s'), '').length;
          // Đếm "đoạn" ĐÚNG cùng công thức với nhãn "Đoạn số: N" đứng canh
          // mép trái khi cuộn (`_demSoDoanTaiViTri`) — có tính cả dấu
          // Enter xuống dòng, nhất quán với trải nghiệm người dùng đã
          // thấy ở chỗ khác trong app.
          final soDoan = vb.isEmpty ? 0 : _demSoDoanTaiViTri(vb, vb.length);
          PopupMenuEntry<String> dongThongTin(String s) => PopupMenuItem<String>(
                enabled: false,
                child: Text(s, style: TextStyle(color: Colors.purple.shade700, fontSize: 13)),
              );
          Widget dong(IconData icon, String chu) => Row(children: [
                Icon(icon, size: 18, color: const Color(0xFF5F6368)),
                const SizedBox(width: 10),
                Text(chu),
              ]);
          return [
            PopupMenuItem(
                value: 'taoMoi',
                child: dong(Icons.note_add_outlined, Ch.taoTepVanBanMoi(ngonNguHienTai.value))),
            PopupMenuItem(
                value: 'xoa',
                child: dong(Icons.delete_outline, Ch.chuyenVaoThungRac(ngonNguHienTai.value))),
            PopupMenuItem(
                value: 'mau',
                child: dong(Icons.palette_outlined, Ch.chonMauTenTep(ngonNguHienTai.value))),
            PopupMenuItem(
                value: 'tai_ve',
                child: dong(Icons.download_outlined, Ch.taiVe(ngonNguHienTai.value))),
            PopupMenuItem(
                value: 'thong_tin',
                child: dong(Icons.info_outline, Ch.thongTinTepNay(ngonNguHienTai.value))),
            if (widget.kho is KhoDuLieuDamMay)
              PopupMenuItem(
                value: 'chia_se_link',
                child: Row(children: [
                  const Icon(Icons.link, size: 18, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 10),
                  Text(Ch.chiaSeTepBangDuongLink(ngonNguHienTai.value),
                      style: const TextStyle(color: Color(0xFF0D47A1))),
                ]),
              ),
            const PopupMenuDivider(),
            dongThongTin(Ch.soTuDong(soTu, ngonNguHienTai.value)),
            dongThongTin(Ch.kyTuCoDauCachDong(soKyTuCoDauCach, ngonNguHienTai.value)),
            dongThongTin(Ch.kyTuKhongDauCachDong(soKyTuKhongDauCach, ngonNguHienTai.value)),
            dongThongTin(Ch.soDoanDong(soDoan, ngonNguHienTai.value)),
          ];
        },
        child: Container(
          width: _canhNutDieuHuongTep,
          height: _canhNutDieuHuongTep,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDADCE0)),
          ),
          child: const Icon(Icons.more_vert, size: 18, color: Color(0xFF5F6368)),
        ),
      ),
    );
  }

  /// (YÊU CẦU MỚI) `true` trong khoảng hiệu ứng lượn sóng MỘT LẦN của tên
  /// tệp — kích hoạt mỗi lần chuyển sang tệp khác (nút Tệp trước/sau) hoặc
  /// mỗi lần quay lại trang soạn thảo từ cây thư mục. Xem `_ChuLuonSong`
  /// (`motLan: true`) và `_kichHoatLuonSongTen`.
  bool _tenDangLuonSong = false;

  void _kichHoatLuonSongTen() {
    if (mounted) setState(() => _tenDangLuonSong = true);
  }

  Widget _oTenField() {
    // Đọc lại `_ghiChuHienTai.mau` mỗi lần dựng — không cache riêng, nên
    // đổi màu ở màn hình thư mục (cùng tham chiếu `widget.kho`) hay ở nút
    // "Mở rộng" đều tự hiện đúng ngay lần dựng kế tiếp, không cần đồng bộ
    // tay giữa hai nơi.
    final mauTen = _ghiChuHienTai.mau;
    final mau = mauTen != null ? Color(mauTen) : Colors.black87;
    final style = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mau);

    final Widget noiDung;
    if (_tenDangLuonSong) {
      noiDung = _ChuLuonSong(
        chu: _tenController.text,
        mau: mau,
        coChu: 18,
        motLan: true,
        khiXong: () {
          if (mounted) setState(() => _tenDangLuonSong = false);
        },
      );
    } else {
      // (YÊU CẦU MỚI) Bấm vào tên tệp không còn đặt con trỏ TẠI CHỖ để sửa
      // nữa — mở một modal nhỏ chính giữa màn hình riêng (xem
      // `_moModalDoiTenTep`), hiện đầy đủ tên (dù dài), có nút "Huỷ - quay
      // lại"/"Lưu thay đổi", vẫn áp đúng các quy tắc cũ (ký tự cấm, độ dài,
      // không trùng tên) qua `KhoDuLieu.doiTenGhiChu`.
      noiDung = InkWell(
        onTap: _moModalDoiTenTep,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(_tenController.text, style: style, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    // (YÊU CẦU MỚI) Ghi chú thuộc "Bộ nhớ trên đám mây" — khung tên tệp nền
    // xanh lá nhạt + icon đám mây đứng trước tên, LUÔN LUÔN hiện (không phụ
    // thuộc tên tệp là gì). Chỉ phủ ĐÚNG khung tên tệp này (nằm trong `title`
    // của AppBar, tách biệt hẳn `actions`/`leading`) — không bao giờ chồng
    // lên các nút khác cùng hàng ngang, dù màn rộng hay hẹp.
    if (widget.kho is! KhoDuLieuDamMay) return noiDung;
    // (YÊU CẦU MỚI) Màn hình RẤT hẹp — bớt icon đám mây, chỉ còn nền xanh lá
    // nhạt, đỡ chật chỗ cho tên tệp.
    final ratHep = MediaQuery.sizeOf(context).width < 420;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ratHep) ...[
            Icon(Icons.cloud, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 6),
          ],
          Flexible(child: noiDung),
        ],
      ),
    );
  }

  Future<void> _moModalDoiTenTep() async {
    // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Xem
    // `_ngungMicroVaGhiAmTheNeuDangBat`.
    await _ngungMicroVaGhiAmTheNeuDangBat();
    if (!mounted) return;
    final tenGoc = _ghiChuHienTai.ten;
    final bo = TextEditingController(text: tenGoc)
      ..selection = TextSelection(baseOffset: 0, extentOffset: tenGoc.length);
    String? loi;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhat) {
          void luu() {
            final tenMoi = bo.text.trim();
            if (tenMoi.isEmpty) {
              capNhat(() => loi = 'Tên không được để trống.');
              return;
            }
            if (tenMoi == tenGoc) {
              Navigator.of(ctx).pop();
              return;
            }
            final k = widget.kho.doiTenGhiChu(_ghiChuHienTai.id, tenMoi);
            if (k != null) {
              capNhat(() => loi = k);
              return;
            }
            widget.kho.luu();
            if (mounted) setState(() => _tenController.text = tenMoi);
            Navigator.of(ctx).pop();
          }

          return AlertDialog(
            title: Text(Ch.doiTenTep(ngonNguHienTai.value)),
            content: TextField(
              controller: bo,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              maxLength: doDaiTenToiDa,
              inputFormatters: [FilteringTextInputFormatter.deny(kyTuCamTrongTen)],
              decoration: InputDecoration(errorText: loi),
              onSubmitted: (_) => luu(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(Ch.huyQuayLai(ngonNguHienTai.value)),
              ),
              FilledButton(onPressed: luu, child: Text(Ch.luuThayDoi(ngonNguHienTai.value))),
            ],
          );
        },
      ),
    );
  }

  /// Mục 11: ẩn/hiện thanh định dạng thủ công (B/I/U/S/...). Mặc định ẨN —
  /// bấm nút "abc" (`_nutAnThanhDinhDang`, xem dưới) để mở, rồi bấm bất kỳ
  /// nút định dạng nào bên trong (kích hoạt logic của nút đó xong) sẽ tự ẩn
  /// lại ngay, TRỪ KHI đã ghim (`widget.caiDat.ghimThanhDinhDang`) — xem
  /// `_dongThanhDinhDangNeuChuaGhim`.
  bool _anThanhDinhDang = true;

  /// (YÊU CẦU MỚI) Màn hình rộng CẢ HAI chiều (ngang VÀ cao) — máy tính
  /// bảng 12 inch trở lên hoặc PC — tự hiện thanh định dạng VÀ tự ghim
  /// (nút ghim sáng lên) ngay khi vào app, không cần người dùng tự bấm.
  /// Chỉ cần ĐỦ rộng ở một lần vào app là ghim lâu dài (ghi vào
  /// `CaiDat`) — những lần sau đọc lại đúng giá trị đã ghim như mọi cài
  /// đặt khác, không tự ý bỏ ghim nếu sau đó họ thu nhỏ cửa sổ.
  void _tuGhimThanhDinhDangNeuManHinhLon() {
    final kt = MediaQuery.sizeOf(context);
    if (kt.width < 900 || kt.height < 900) return;
    if (_anThanhDinhDang) setState(() => _anThanhDinhDang = false);
    if (!widget.caiDat.ghimThanhDinhDang) {
      widget.caiDat.datGhimThanhDinhDang(true);
      setState(() {});
    }
  }

  /// Gọi ngay sau khi một nút trong thanh định dạng vừa kích hoạt xong logic
  /// của nó (áp định dạng, tích chọn...) — tự ẩn thanh lại, trừ khi người
  /// dùng đã ghim. Không làm gì nếu thanh vốn đã ẩn sẵn (đỡ `setState` thừa).
  void _dongThanhDinhDangNeuChuaGhim() {
    if (widget.caiDat.ghimThanhDinhDang) return;
    if (_anThanhDinhDang) return;
    setState(() => _anThanhDinhDang = true);
  }

  // "Sao chép tất cả", "Sao chép rồi xoá tất cả" và "Xoá tất cả" đã dời vào
  // menu "+ Thêm lựa chọn" của thanh công cụ dưới (xem `ThanhCongCu`); nút
  // "Chọn tất cả" đã bỏ hẳn; nút "Tìm kiếm" (mục 8b) cũng đã dời vào menu đó
  // (đổi tên "Tìm kiếm và thay thế") — thanh trên giờ còn Lùi lại/Tiến
  // tới/Lưu, cộng thêm nút Ẩn/hiện thanh định dạng mới (mục 11) sát mép
  // phải, ngay sau nút Lưu.
  // Phần B: IconButton để mặc định có `padding: EdgeInsets.all(8)` VÀ ngưỡng
  // chạm tối thiểu Material (48x48) dù thanh dưới (`_thanhDinhDangThuCong`)
  // đã bó lại — đây là 4 nút của THANH TRÊN, trước đó không hề bó, nên thanh
  // trên vẫn cao y như cũ dù báo cáo trước nói "đã thu hẹp". Bó y hệt cách
  // thanh dưới đã làm: bỏ padding mặc định, `VisualDensity.compact` +
  // `constraints` khoá cứng 36x36 (icon 20-22 + đôi ba pixel đệm mỗi bên —
  // đủ để viền còn ôm khít quanh icon, không dư khoảng trống).
  static const _kichThuocNutTren = BoxConstraints.tightFor(width: 36, height: 36);

  // Nút "Lưu" đã bỏ — hệ thống tự lưu sau mỗi lần sửa rồi (`_henLuu`, hẹn
  // giờ 600ms), bấm tay chỉ còn ý nghĩa "lưu ngay + báo đã lưu", không phải
  // điểm duy nhất giữ an toàn dữ liệu. Thay bằng nút "Dán" — ĐÚNG hình
  // dạng/logic/hiệu ứng với nút cùng tên ở Bộ phím nhanh (cùng widget
  // `_NutCongCuChu`, cùng cờ liệt `_phimPasteDangLiet`, cùng hàm
  // `_phimAoPasteCoLiet`) để Dán luôn trong tầm tay, kể cả khi Bộ phím nhanh
  // đang tắt. `_bamNutLuu`/Ctrl+S vẫn còn, chỉ mất nút hiển thị này.
  ///
  /// Màn hình hẹp đặt RIÊNG nút này lên cùng dòng với Tên tệp (sát mép
  /// phải — xem `build`), nên tách ra một hàm dùng chung thay vì lặp lại.
  Widget _nutDanCongCu() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _NutCongCuChu(
          nhan: Ch.dan(ngonNguHienTai.value),
          bLiet: _phimPasteDangLiet,
          onTap: _phimAoPasteCoLiet,
        ),
      );

  /// [coDan] = false ở nhánh màn hình hẹp — nút Dán đã dời lên cùng dòng
  /// Tên tệp riêng (`_nutDanCongCu`), không lặp lại ở đây nữa.
  /// (YÊU CẦU MỚI) Nút "Bộ nhớ tạm" tách riêng thành hàm dùng chung — màn
  /// rộng vẫn gọi từ `_dsNutCongCu` (cạnh "abc" như cũ); màn hẹp gọi riêng
  /// ở hàng TRÊN (cạnh "Dán"), không còn nằm trong `_dsNutCongCu` nữa — xem
  /// `build()`.
  Widget _nutBoNhoTamCongCu() => IconButton(
        onPressed: _moHopThoaiLichSuBoNhoTam,
        // (SỬA LỖI — nhánh thử nghiệm) `Icons.content_paste_search` — một
        // icon Material khá mới — bị mất hẳn trên bản dựng thật (tree-shake
        // font icon chỉ giữ icon nào chắc chắn dùng được). Đổi qua emoji
        // (`Text`) — y hệt cách đã né lỗi này ở nút "🔤"/"🔼" bên dưới.
        icon: const Text('📋', style: TextStyle(fontSize: 18)),
        tooltip: Ch.boNhoTamCoPhimTat(
            ngonNguHienTai.value, widget.caiDat.phimTatBoNhoTam.nhan),
        visualDensity: VisualDensity.compact,
        constraints: _kichThuocNutTren,
        padding: EdgeInsets.zero,
      );

  /// (YÊU CẦU MỚI) Cuộn lên đầu/xuống cuối văn bản — opacity 50% (thấy mờ
  /// mờ tên tệp phía sau nếu tên tệp dài, ở màn hẹp hai nút này đứng ngay
  /// trước tên tệp). CHỈ bấm vào mới cuộn — rê chuột không còn tác dụng
  /// (đã bỏ `MouseRegion.onEnter` theo yêu cầu mới).
  void _cuonVanBanLenDauTrang() {
    if (!_cuonVanBan.hasClients) return;
    _cuonVanBan.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _cuonVanBanXuongCuoiTrang() {
    if (!_cuonVanBan.hasClients) return;
    _cuonVanBan.animateTo(
      _cuonVanBan.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  List<Widget> _haiNutCuonLenXuong() => [
        Opacity(
          opacity: 0.5,
          child: IconButton(
            onPressed: _cuonVanBanLenDauTrang,
            icon: const Icon(Icons.arrow_upward, size: 20),
            tooltip: Ch.cuonLenDauVanBan(ngonNguHienTai.value),
            visualDensity: VisualDensity.compact,
            constraints: _kichThuocNutTren,
            padding: EdgeInsets.zero,
          ),
        ),
        Opacity(
          opacity: 0.5,
          child: IconButton(
            onPressed: _cuonVanBanXuongCuoiTrang,
            icon: const Icon(Icons.arrow_downward, size: 20),
            tooltip: Ch.cuonXuongCuoiVanBan(ngonNguHienTai.value),
            visualDensity: VisualDensity.compact,
            constraints: _kichThuocNutTren,
            padding: EdgeInsets.zero,
          ),
        ),
      ];

  /// [coCuonLenXuong]: `false` ở hàng DƯỚI của màn hẹp — hai nút cuộn lên/
  /// xuống đã dời lên hàng TRÊN (cùng dòng tên tệp, cạnh "Dán") ở màn hẹp,
  /// xem `build()`, không lặp lại ở đây.
  List<Widget> _dsNutCongCu({
    bool coDan = true,
    bool coBoNhoTam = true,
    bool coCuonLenXuong = true,
  }) => [
        if (coCuonLenXuong) ..._haiNutCuonLenXuong(),
        IconButton(
          onPressed: _lichSuLui.isEmpty ? null : _lui,
          icon: const Icon(Icons.undo, size: 22),
          tooltip: Ch.luiLaiCoPhimTat(ngonNguHienTai.value),
          visualDensity: VisualDensity.compact,
          constraints: _kichThuocNutTren,
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: _lichSuToi.isEmpty ? null : _toi,
          icon: const Icon(Icons.redo, size: 22),
          tooltip: Ch.tienToiCoPhimTat(ngonNguHienTai.value),
          visualDensity: VisualDensity.compact,
          constraints: _kichThuocNutTren,
          padding: EdgeInsets.zero,
        ),
        // (YÊU CẦU MỚI) Nút "Từ điển nhập liệu nhanh" — ngay bên phải "Tiến
        // tới", chỉ hiện khi công tắc tổng đang BẬT.
        if (_tuDienNhapLieuNhanhBatKyNguon)
          IconButton(
            onPressed: _moHopThoaiTuDienNhapLieuNhanh,
            icon: const Text('📖', style: TextStyle(fontSize: 18)),
            tooltip: Ch.tuDienNhapLieuNhanhVoiPhimTat(
                widget.caiDat.phimTatTuDienNhapLieuNhanh.nhan, ngonNguHienTai.value),
            visualDensity: VisualDensity.compact,
            constraints: _kichThuocNutTren,
            padding: EdgeInsets.zero,
          ),
        if (coDan) _nutDanCongCu(),
        // (YÊU CẦU MỚI) Màn rộng vẫn giữ nút "Bộ nhớ tạm" ở đây (giữa Dán
        // và "abc"); màn hẹp giờ chuyển nó lên hàng trên cạnh Dán (xem
        // `build()`), nên gọi `_dsNutCongCu` cho hàng dưới ở màn hẹp với
        // `coBoNhoTam: false` để không hiện trùng 2 lần.
        if (widget.caiDat.boNhoTamDanVanBanBat && coBoNhoTam) _nutBoNhoTamCongCu(),
        IconButton(
          // (SỬA LỖI — "vùng chọn bị ẩn mất khi bấm abc/Làm việc với AI")
          // Bấm nút này cũng giành tiêu điểm khỏi `_oChu` như mọi nút khác —
          // Flutter chỉ vẽ màu tô vùng chọn khi ô ĐANG giữ tiêu điểm, nên
          // tiêu điểm rời đi là màu tô biến mất (logic vẫn áp dụng đúng vào
          // đúng vùng, chỉ MẮT không thấy). Xin lại tiêu điểm ngay sau khi
          // đổi xong — cùng hàm đã dùng cho Copy/Cắt/Dán/All.
          onPressed: () {
            setState(() => _anThanhDinhDang = !_anThanhDinhDang);
            _giuFocusOChuSauKhiBam();
            // (YÊU CẦU MỚI) Bấm nút này LUÔN ép ẩn bàn phím ảo — bất kể lúc
            // bấm nó đang hiện hay đang ẩn sẵn, và bất kể đang ẨN hay HIỆN
            // thanh định dạng (cả hai chiều bấm đều ép ẩn, không chỉ một
            // chiều). CHỈ áp dụng khi không có bàn phím vật lý gắn ngoài —
            // bàn phím vật lý không đụng gì tới bàn phím ảo nên ép ẩn ở đó
            // vô nghĩa. Ghi đè lên hành vi "giữ nguyên trạng thái" của
            // `_giuFocusOChuSauKhiBam()` ở trên — mượn đúng cơ chế ép ẩn đã
            // có ở `_resetManHinhTruocKhiMoMenu` (gọi `TextInput.hide` +
            // khoá tạm `readOnly` qua `_epAnBanPhimAoKhiGiuFocus`, tự mở lại
            // sau 600ms).
            if (!_coBanPhimVatLy) {
              SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
              setState(() => _epAnBanPhimAoKhiGiuFocus = true);
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted) setState(() => _epAnBanPhimAoKhiGiuFocus = false);
              });
            }
          },
          // Emoji "chữ" — các nút khác trong hai thanh này đều dùng
          // Material Icon (`Icon(IconData)`), nhưng không có icon Material
          // nào diễn tả đúng "thanh định dạng chữ"; dùng `Text` với cùng cỡ
          // icon (24) là cách nhất quán nhất còn lại (emoji render bình
          // thường qua `Text`, không cần gói phụ thuộc thêm).
          icon: const Text('🔤', style: TextStyle(fontSize: 18)),
          tooltip: _anThanhDinhDang
              ? Ch.hienThanhDinhDang(ngonNguHienTai.value)
              : Ch.anThanhDinhDang(ngonNguHienTai.value),
          visualDensity: VisualDensity.compact,
          constraints: _kichThuocNutTren,
          padding: EdgeInsets.zero,
        ),
        // "Thu gọn" — sát mép phải cùng (nút cuối trong danh sách, và danh
        // sách này dùng làm `actions` của AppBar hoặc nằm trong một
        // `Align(alignment: centerRight)`, nên tự nhiên luôn ở sát mép phải
        // màn hình). Ẩn HẲN mọi thanh công cụ phía trên (xem `build`), nhả
        // hết đất cho khung soạn thảo — nút "Mở rộng" nổi (`_NutNoiTuTho`)
        // trả lại như cũ. Emoji (Text) thay Icon Material — xem giải thích ở
        // `_NutAnHienDieuHuongConTro` (icon Material mới thêm có thể bị
        // "tree-shake" mất trên bản dựng thật dù code không lỗi).
        IconButton(
          onPressed: () {
            setState(() => _thuGonThanhCongCu = true);
            unawaited(widget.caiDat.datThuGonThanhCongCu(true));
            unawaited(_dayCaiDatDongBoTaiKhoan({'thuGonThanhCongCu': true}));
          },
          icon: const Text('🔼', style: TextStyle(fontSize: 18)),
          tooltip: Ch.thuGonAnThanhCongCu(ngonNguHienTai.value),
          visualDensity: VisualDensity.compact,
          constraints: _kichThuocNutTren,
          padding: EdgeInsets.zero,
        ),
      ];

  /// Xem `_dsNutCongCu` (nút "Thu gọn") và `_NutMoRongThanhCongCu` (nút nổi
  /// "Mở rộng" trả lại) — ẩn HẲN AppBar (tên tệp, Lùi/Tiến/Lưu/định dạng) và
  /// thanh định dạng thủ công, nhường toàn bộ phần trên cho khung soạn
  /// thảo.
  bool _thuGonThanhCongCu = false;

  /// "Chọn vị trí để chèn văn bản" (mục "Chuyển file âm thanh thành văn
  /// bản") — xem `_batDauChonViTriChenFile`.
  bool _dangChonViTriChenFile = false;

  /// Hàng 4 nút mũi tên điều hướng con trỏ (Lên/Xuống/Trái/Phải) — nằm NGAY
  /// TRÊN hàng phím nhanh cảm ứng (`_xayHangPhimNhanhCamUng`), cùng bật/tắt
  /// theo `_boPhimNhanhCamUngMo`. LUÔN hiện cùng Bộ phím nhanh — hàng
  /// Copy/Cut/Paste/All và nút ẩn/hiện riêng của hàng này đã bỏ hẳn (trùng
  /// với All/Copy/Cắt/Dán ngoài màn hình chính), không còn gì để ẩn/hiện
  /// nữa.
  Widget _xayHangDieuHuongConTro() {
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;
    final khoangCach = manHinhHep ? 0.0 : 8.0;
    final rongNut = manHinhHep ? 48.0 * 0.85 : 48.0;
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Align(
                // Màn hình rộng: căn GIỮA (đủ chỗ ngang, không cần ép về
                // trái); màn hình hẹp vẫn ép trái như cũ để nhường chỗ.
                alignment: manHinhHep ? Alignment.centerLeft : Alignment.center,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // (KHÔNG dùng `icon:`) 4 nút mũi tên chỉ hiện qua
                      // [nhan] (ký tự mũi tên Unicode) — `icon:` (Icon
                      // Material) từng khiến ↑/↓ hiện RỖNG trên bản dựng
                      // thật, xem giải thích ở `_NutAnHienDieuHuongConTro`.
                      _NutPhimAo(
                        nhan: '↑',
                        moTa: 'Lên — bấm giữ để đi liên tục',
                        rong: rongNut,
                        lapLai: true,
                        onTap: () => _diChuyenConTro(dy: -1),
                      ),
                      SizedBox(width: khoangCach),
                      _NutPhimAo(
                        nhan: '↓',
                        moTa: 'Xuống — bấm giữ để đi liên tục',
                        rong: rongNut,
                        lapLai: true,
                        onTap: () => _diChuyenConTro(dy: 1),
                      ),
                      SizedBox(width: khoangCach),
                      _NutPhimAo(
                        nhan: '←',
                        moTa: 'Trái — bấm giữ để đi liên tục',
                        rong: rongNut,
                        lapLai: true,
                        onTap: () => _diChuyenConTro(dx: -1),
                      ),
                      SizedBox(width: khoangCach),
                      _NutPhimAo(
                        nhan: '→',
                        moTa: 'Phải — bấm giữ để đi liên tục',
                        rong: rongNut,
                        lapLai: true,
                        onTap: () => _diChuyenConTro(dx: 1),
                      ),
                      SizedBox(width: khoangCach),
                      // Home/End "đổi chỗ" với Lùi lại/Tiến tới — xuống hàng
                      // Copy/Cut/Paste/All (`_xayHangCongCuVanBanCamUng`),
                      // sang đây thay chỗ, hình dạng/logic giữ NGUYÊN VĂN
                      // (vẫn `_NutCongCuChu`, vẫn `_phimAoHome`/`_phimAoEnd`).
                      _NutCongCuChu(
                        nhan: 'Home',
                        moTa: 'Đầu dòng — bấm 2 lần: đầu văn bản',
                        onTap: _phimAoHome,
                        tyLeThuHep: 0.85,
                      ),
                      SizedBox(width: khoangCach),
                      _NutCongCuChu(
                        nhan: 'End',
                        moTa: 'Cuối dòng — bấm 2 lần: cuối văn bản',
                        onTap: _phimAoEnd,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nút "*" — mở bảng ký tự đặc biệt (`_moBangKyTuDacBiet`). Dính
            // liền (không khoảng cách) với nút "bàn phím" ngay bên phải, hẹp
            // hết mức (chỉ vừa rộng bằng 4 dấu `*`) vì hết chỗ ngang rồi.
            SizedBox(
              width: 30,
              height: 36,
              child: Material(
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: InkWell(
                  onTap: () {},
                  onTapDown: (_) => _moBangKyTuDacBiet(),
                  child: const Center(
                    child: Text('*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            // Nút "bàn phím" — sát mép phải cùng, cạnh nút End. Bấm lần 1:
            // ép bàn phím ảo hệ thống hiện ra CÙNG LÚC với mọi thanh công cụ
            // của Bộ phím nhanh (xem `_bamNutBanPhimAoTrongBoPhimNhanh`).
            // Bấm lần 2: tắt bàn phím ảo lại. Icon Material đã dùng sẵn ở
            // nơi khác trong tệp này (menu "Bàn phím") nên chắc chắn không
            // bị "tree-shake" mất (khác 4 nút mũi tên/nút Thu gọn mới thêm
            // trước đây).
            IconButton(
              onPressed: _bamNutBanPhimAoTrongBoPhimNhanh,
              icon: Icon(
                Icons.keyboard_alt_outlined,
                size: 22,
                color: _epHienBanPhimAoTrongBoPhimNhanh ? Colors.white : null,
              ),
              tooltip: _epHienBanPhimAoTrongBoPhimNhanh
                  ? Ch.tatBanPhimAo(ngonNguHienTai.value)
                  : Ch.hienBanPhimAoCungBoPhimNhanh(ngonNguHienTai.value),
              visualDensity: VisualDensity.compact,
              constraints: _kichThuocNutTren,
              style: IconButton.styleFrom(
                backgroundColor: _epHienBanPhimAoTrongBoPhimNhanh ? Colors.blue.shade600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hàng phím thay thế bàn phím hệ thống — nằm sát mép trên, ngay phía
  /// trên `ThanhCongCu`, khi "Bộ phím nhanh cho màn hình cảm ứng" đang mở.
  /// Nút X đỏ sát mép phải tắt hẳn công cụ, trả lại bàn phím ảo bình
  /// thường.
  /// Độ rộng cố định của nút "Đóng" — khoá cứng một độ rộng thay vì để tự
  /// co theo nội dung, cho đồng bộ với các nút vuông khác trong hàng.
  static const _rongNutAnDong = 64.0;

  Widget _xayHangPhimNhanhCamUng() {
    // Màn hình hẹp: các nút phím ảo sát vào nhau (không khoảng cách), ép
    // hẳn về bên trái — cùng lý do đã áp dụng cho hàng Copy/Cut/Paste/...
    // ở `_xayHangCongCuVanBanCamUng`.
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;
    final khoangCach = manHinhHep ? 0.0 : 8.0;
    // Màn hình hẹp: hẹp thêm 15% chiều rộng mặc định (48) mỗi nút, để cả 5
    // nút cùng lọt vào khung nhìn mà không cần cuộn ngang.
    final rongNutPhimAo = manHinhHep ? 48.0 * 0.85 : 48.0;
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: manHinhHep ? Alignment.centerLeft : Alignment.center,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: khoangCach,
                    runSpacing: khoangCach,
                    children: [
                    _NutPhimAo(
                      nhan: '.',
                      rong: rongNutPhimAo,
                      onTap: () => _chenKyTuTuPhimAo('.'),
                    ),
                    _NutPhimAo(
                      nhan: ',',
                      rong: rongNutPhimAo,
                      onTap: () => _chenKyTuTuPhimAo(','),
                    ),
                    _NutPhimAo(
                      nhan: '␣',
                      moTa: 'Dấu cách',
                      rong: rongNutPhimAo,
                      onTap: () => _chenKyTuTuPhimAo(' '),
                    ),
                    _NutPhimAo(
                      nhan: '⏎',
                      moTa: 'Xuống dòng',
                      rong: rongNutPhimAo,
                      onTap: () => _chenKyTuTuPhimAo('\n'),
                    ),
                    _NutPhimAo(
                      nhan: '⌫',
                      moTa: 'Xoá — bấm giữ để xoá liên tục',
                      mauNen: Colors.red.shade50,
                      mauVien: Colors.red.shade300,
                      rong: rongNutPhimAo,
                      lapLai: true,
                      onTap: _xoaKyTuTuPhimAo,
                    ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Lùi lại/Tiến tới — dời từ hàng Copy/Cut/Paste/All (đã bỏ hẳn,
            // trùng với nút All/Copy/Cắt ngoài màn hình chính) xuống đây,
            // ngay cạnh "Đóng", cả ba căn phải sát mép phải màn hình.
            _NutPhimAo(
              nhan: Ch.luiLai(ngonNguHienTai.value),
              icon: Icons.undo,
              moTa: 'Lùi lại (Ctrl + Z)',
              mauNen: Colors.red.shade50,
              mauVien: Colors.red.shade300,
              rong: 48 * 0.85,
              onTap: _lichSuLui.isEmpty ? () {} : _lui,
            ),
            SizedBox(width: khoangCach),
            _NutPhimAo(
              nhan: Ch.tienToi(ngonNguHienTai.value),
              icon: Icons.redo,
              moTa: 'Tiến tới (Ctrl + Shift + Z)',
              mauNen: Colors.red.shade50,
              mauVien: Colors.red.shade300,
              rong: 48 * 0.85,
              onTap: _lichSuToi.isEmpty ? () {} : _toi,
            ),
            const SizedBox(width: 8),
            // Nút "Đóng" (đỏ, tắt hẳn Bộ phím nhanh) — nút "Ẩn" (tạm ẩn, chỉ
            // nhường chỗ cho bàn phím ảo) đã bỏ hẳn: giờ bật/tắt Bộ phím
            // nhanh đã dễ dàng ngay ở nút trên màn hình chính rồi, không cần
            // đường tắt tạm ẩn riêng nữa.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Tooltip(
                message: Ch.dongBoPhimNhanhChoManHinhCamUng(ngonNguHienTai.value),
                child: InkWell(
                  onTap: () {},
                  onTapDown: (_) => _bamNutBoPhimNhanhCamUng(),
                  child: Container(
                    // Màn hình hẹp: thu gọn nhãn "Đóng" thành "X" + bớt độ
                    // rộng cố định — cho gọn gàng, nhường chỗ ngang cho các
                    // nút phím ảo bên trái.
                    width: manHinhHep ? _rongNutAnDong * 0.6 : _rongNutAnDong,
                    color: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Text(manHinhHep ? 'X' : Ch.dong(ngonNguHienTai.value),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh đáy riêng khi đang "chọn vị trí để chèn văn bản" (kết quả AI từ
  /// tệp âm thanh) — mượn lại nguyên ba nút dấu cách/xuống dòng/xoá của Bộ
  /// phím nhanh, cộng hai nút Chèn/Quay lại. Đây là NƠI DUY NHẤT còn bấm
  /// được lúc này — AppBar, thanh định dạng, Bộ phím nhanh gốc, thanh công
  /// cụ dưới đều đã ẩn hết (xem các điều kiện `_dangChonViTriChenFile` ở
  /// `build`), chỉ còn khung soạn thảo (di chuyển con trỏ/tạo vùng chọn
  /// bình thường) và thanh này.
  Widget _xayThanhChonViTriChenFile() {
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;
    final rongNutPhimAo = manHinhHep ? 48.0 * 0.85 : 48.0;
    // Chế độ "Thay đổi vị trí của thẻ ghi âm" (xem `_batDauDoiViTriTheGhiAm`/
    // `_batDauDoiViTriTheDangGhi`) dùng CHUNG khung thanh này với chế độ
    // "chèn kết quả AI từ file âm thanh" gốc — chỉ khác lời hướng dẫn, hai
    // nút hành động, và KHÔNG có hàng dấu cách/xuống dòng/xoá (di chuyển
    // thẻ không cần gõ thêm chữ nào cả).
    final dangDoiViTriThe = _soTheDangDoiViTri != null;
    return Material(
      color: Colors.white,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dangDoiViTriThe
                      ? Ch.diChuyenConTroToiViTriDatThe(
                          _soTheDangDoiViTri!, ngonNguHienTai.value)
                      : Ch.diChuyenConTroToiViTriChenVanBanAi(ngonNguHienTai.value),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                ),
              ),
              if (!dangDoiViTriThe) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NutPhimAo(
                      nhan: '␣',
                      moTa: 'Dấu cách',
                      rong: rongNutPhimAo,
                      onTap: () => _chenKyTuTuPhimAo(' '),
                    ),
                    const SizedBox(width: 8),
                    _NutPhimAo(
                      nhan: '⏎',
                      moTa: 'Xuống dòng',
                      rong: rongNutPhimAo,
                      onTap: () => _chenKyTuTuPhimAo('\n'),
                    ),
                    const SizedBox(width: 8),
                    _NutPhimAo(
                      nhan: '⌫',
                      moTa: 'Xoá — bấm giữ để xoá liên tục',
                      mauNen: Colors.red.shade50,
                      mauVien: Colors.red.shade300,
                      rong: rongNutPhimAo,
                      lapLai: true,
                      onTap: _xoaKyTuTuPhimAo,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          dangDoiViTriThe ? _huyDoiViTriThe : _quayLaiKetQuaFileAmThanh,
                      child: Text(dangDoiViTriThe
                          ? Ch.huyQuayLai(ngonNguHienTai.value)
                          : Ch.quayLaiKetQuaAi(ngonNguHienTai.value)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: dangDoiViTriThe ? _xacNhanDoiViTriThe : _chenTaiViTriDaChon,
                      child: Text(dangDoiViTriThe
                          ? Ch.chuyenToiDay(ngonNguHienTai.value)
                          : Ch.chenVaoViTriNay(ngonNguHienTai.value)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Một ô trong bảng nút trình ghi âm — icon + nhãn (tự xuống hàng khi màn
  /// hình hẹp, không cắt chữ), nền màu riêng theo nhóm chức năng, viền mảnh
  /// xám để trông như một bảng lưới thật. Bắt `onTapDown` (không đợi
  /// `onTap`/nhấc tay) — y hệt lý do cũ: trên WEB, tiêu điểm DOM đang ở
  /// khung nhập ẩn phía sau khung soạn thảo chuyển đi lúc nhấc tay có thể
  /// "ăn" mất đúng lượt chạm đầu.
  Widget _oTrinhGhiAmMoi({
    required String nhan,
    required IconData icon,
    required Color mauNen,
    required Color mauChu,
    required VoidCallback onBam,
    required bool manHinhHep,
  }) {
    final coChu = manHinhHep ? 11.5 : 13.5;
    final coIcon = manHinhHep ? 16.0 : 19.0;
    return Container(
      decoration: BoxDecoration(
        color: mauNen,
        border: Border.all(color: Colors.grey.shade400, width: 0.6),
      ),
      child: InkWell(
        onTap: () {},
        onTapDown: (_) => onBam(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: manHinhHep ? 6 : 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: mauChu, size: coIcon),
              const SizedBox(height: 3),
              Text(
                nhan,
                textAlign: TextAlign.center,
                style: TextStyle(color: mauChu, fontWeight: FontWeight.w600, fontSize: coChu),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ô lớn "Đang Ghi âm mm:ss" / "Tạm dừng mm:ss" — chữ to hơn hẳn các ô
  /// nút khác (dễ nhìn, theo yêu cầu), chỉ lượn sóng lúc THẬT SỰ đang ghi
  /// (tái dùng nguyên `_ChuLuonSong`, gộp luôn cả đồng hồ vào chung một
  /// chuỗi lượn sóng — đơn giản hơn hẳn so với ghép hai widget so le nhau,
  /// và trông vẫn đúng ý "dòng chữ Đang ghi âm lượn sóng"). Không phải nút
  /// bấm — thuần hiển thị trạng thái.
  Widget _oTrangThaiGhiAmLon(bool manHinhHep) {
    final coChu = manHinhHep ? 16.0 : 21.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 0.6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: Alignment.center,
      // Đè nhãn "Đang chuyển #N"/"Đã chuyển xong #N" — thẻ vừa chốt không
      // còn ghi âm thật nữa, đứng yên không lượn sóng, thay hẳn cho đồng hồ
      // ghi âm cho tới khi bắt đầu ghi thẻ mới (`_nhanTrangThaiGhiAmGheDe`
      // reset về null lúc đó).
      child: ValueListenableBuilder<TrangThaiGheDe?>(
        valueListenable: _nhanTrangThaiGhiAmGheDe,
        builder: (context, ghe, _) {
          if (ghe != null) {
            return Text(
              Ch.trangThaiGheDe(ghe.loai, ghe.soThe, ngonNguHienTai.value),
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: coChu),
            );
          }
          if (_soTheGhiAmDangGhi == null) {
            return Text(
              'Đang chuẩn bị…',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: coChu),
            );
          }
          return ValueListenableBuilder<Duration>(
            valueListenable: _thoiLuongTheGhiAmDangGhi,
            builder: (context, gia, _) {
              // Cả dòng (chữ + số) nhấp nháy khi sắp chạm hạn 60 giây — xem
              // `_NhapNhayGioiHanGhiAm` — THAY cho hộp thoại "sắp chạm 60
              // giây" cũ.
              final kieuSo = TextStyle(
                  color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: coChu);
              return _NhapNhayGioiHanGhiAm(
                // (YÊU CẦU MỚI — nhánh thử nghiệm) "Tạm dừng mm:ss" KHÔNG
                // được nhấp nháy dù đang ở giây thứ bao nhiêu — truyền 0
                // (dưới ngưỡng 45s) tắt hẳn nhịp nhấp nháy của
                // `_NhapNhayGioiHanGhiAm` trong lúc tạm dừng; "Đang Ghi âm"
                // vẫn nhấp nháy đúng theo giây thật khi tiếp tục ghi.
                giay: _theGhiAmDangTamDung ? 0 : gia.inSeconds,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_theGhiAmDangTamDung)
                      Text(Ch.tamDungCoDauCach(ngonNguHienTai.value), style: kieuSo)
                    else
                      _ChuLuonSong(
                          chu: Ch.dangGhiAmPrefixLabel(ngonNguHienTai.value),
                          mau: Colors.red.shade700,
                          coChu: coChu),
                    _SoPhutGiayGhiAm(thoiLuong: gia, style: kieuSo),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Ô "Tạm dừng"/"Tiếp tục" — đối nghịch nhau, cái này hiện thì cái kia ẩn
  /// (dùng chung MỘT ô, không phải hai ô cạnh nhau).
  Widget _oTamDungTiepTuc(bool manHinhHep) {
    return _theGhiAmDangTamDung
        ? _oTrinhGhiAmMoi(
            nhan: Ch.tiepTuc(ngonNguHienTai.value),
            icon: Icons.play_circle_outline,
            mauNen: Colors.green.shade100,
            mauChu: Colors.green.shade800,
            onBam: _tiepTucTheGhiAmHienTai,
            manHinhHep: manHinhHep,
          )
        : _oTrinhGhiAmMoi(
            nhan: Ch.tamDung(ngonNguHienTai.value),
            icon: Icons.pause_circle_outline,
            mauNen: Colors.red.shade100,
            mauChu: Colors.red.shade800,
            onBam: _tamDungTheGhiAmHienTai,
            manHinhHep: manHinhHep,
          );
  }

  /// Bảng nút trình ghi âm — thay HẲN cho AppBar bình thường trong lúc
  /// trình ghi âm mở (xem nơi dùng ở `build`). Màn hình rộng: 1 hàng 2 ô
  /// (trạng thái to + Hiện bảng điều khiển) rồi 2 hàng 3 ô. Màn hình hẹp:
  /// mọi hàng đều 2 ô, thêm một hàng — giữ các ô đủ rộng để chữ không vỡ
  /// nát, đúng yêu cầu "sát vào nhau, ổn định, tự xuống hàng bên trong ô".
  AppBar _xayAppBarTrinhGhiAmThe() {
    final manHinhHep = MediaQuery.of(context).size.width < _nguongManHinhHep;

    final oDangGhi = _oTrangThaiGhiAmLon(manHinhHep);
    final oHienBang = _oTrinhGhiAmMoi(
      nhan: Ch.hienBangDieuKhien(ngonNguHienTai.value),
      icon: Icons.tune_rounded,
      mauNen: Colors.amber.shade100,
      mauChu: Colors.brown.shade800,
      onBam: _bamNutHienBangDieuKhienGhiAm,
      manHinhHep: manHinhHep,
    );
    final oTamTiep = _oTamDungTiepTuc(manHinhHep);
    final oChuyenVanBan = _oTrinhGhiAmMoi(
      nhan: Ch.hoanThanhChuyenThanhVanBanGach(ngonNguHienTai.value),
      icon: Icons.text_snippet_outlined,
      mauNen: Colors.green.shade100,
      mauChu: Colors.green.shade900,
      onBam: _hoanThanhChuyenThanhVanBan,
      manHinhHep: manHinhHep,
    );
    final oTaoMoi = _oTrinhGhiAmMoi(
      nhan: Ch.hoanThanhTaoBanGhiAmMoiGach(ngonNguHienTai.value),
      icon: Icons.add_circle_outline,
      mauNen: Colors.cyan.shade100,
      mauChu: Colors.cyan.shade900,
      onBam: _taoPhienGhiAmMoiThe,
      manHinhHep: manHinhHep,
    );
    final oPhatLai = _oTrinhGhiAmMoi(
      nhan: Ch.hoanThanhPhatDeNgheLaiGach(ngonNguHienTai.value),
      icon: Icons.play_arrow_rounded,
      mauNen: Colors.lightGreen.shade100,
      mauChu: Colors.green.shade900,
      onBam: _hoanThanhPhatDeNgheLai,
      manHinhHep: manHinhHep,
    );
    final oDong = _oTrinhGhiAmMoi(
      nhan: Ch.hoanThanhDongTrinhGhiAmGach(ngonNguHienTai.value),
      icon: Icons.check_circle_outline,
      mauNen: Colors.blue.shade100,
      mauChu: Colors.blue.shade900,
      onBam: _dongTrinhGhiAmThe,
      manHinhHep: manHinhHep,
    );
    final oXoa = _oTrinhGhiAmMoi(
      // Không còn gì để xoá (thẻ vừa chốt đã chuyển hoá xong hẳn) — chỉ
      // còn ý nghĩa "đóng trình ghi âm" đơn thuần.
      nhan: _khongCoGiDeXoaTrongTrinhGhiAm
          ? Ch.dongTrinhGhiAm(ngonNguHienTai.value)
          : Ch.xoaBanNayDongTrinhGhiAm(ngonNguHienTai.value),
      icon: Icons.delete_outline,
      mauNen: Colors.red.shade100,
      mauChu: Colors.red.shade900,
      onBam: _huyBanGhiAmDangDoDangVaDong,
      manHinhHep: manHinhHep,
    );

    Widget hang(List<Widget> oCac, {List<int>? doRong}) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < oCac.length; i++)
              Expanded(flex: doRong == null ? 1 : doRong[i], child: oCac[i]),
          ],
        ),
      );
    }

    final luoi = manHinhHep
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            hang([oDangGhi, oHienBang]),
            hang([oTamTiep, oChuyenVanBan]),
            hang([oTaoMoi, oPhatLai]),
            hang([oDong, oXoa]),
          ])
        : Column(mainAxisSize: MainAxisSize.min, children: [
            hang([oDangGhi, oHienBang], doRong: const [2, 1]),
            hang([oTamTiep, oChuyenVanBan, oTaoMoi]),
            hang([oPhatLai, oDong, oXoa]),
          ]);

    // Số ước lượng CHỈ dùng cho khung hình đầu tiên (trước khi đo được
    // chiều cao thật) — ngay sau đó `_doLaiCaoLuoiTrinhGhiAmThe` đo lại
    // đúng chiều cao lưới nút thật rồi tự setState, AppBar co khít theo,
    // không còn dư khoảng trống lẫn phải cuộn.
    final caoUocLuong = manHinhHep ? 300.0 : 210.0;
    final caoBang = _caoLuoiTrinhGhiAmThe ?? caoUocLuong;
    _doLaiCaoLuoiTrinhGhiAmThe();

    return AppBar(
      backgroundColor: Colors.red.shade50,
      surfaceTintColor: Colors.red.shade50,
      elevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: caoBang,
      // Nút "tự động gửi ngầm" đã bị xoá khỏi dải này — cài đặt đó nay chỉ
      // còn ở "phím 7" trong Bảng điều khiển ghi âm (nhiều chức năng hơn,
      // xem `_moModalCaiDatTuDongChuyenHoa`), tránh trùng lặp hai chỗ.
      title: Container(key: _khoaLuoiTrinhGhiAmThe, child: luoi),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tự đo chiều cao bàn phím thay vì giao cho Scaffold: đặt thanh công cụ
    // làm dòng cuối của thân trang rồi chừa đúng khoảng đó bên dưới, thì
    // thanh luôn nằm khít mép trên bàn phím.
    final caoBanPhim = MediaQuery.viewInsetsOf(context).bottom;
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;
    // (YÊU CẦU MỚI) Màn RẤT hẹp — xem `_nguongManHinhRatHep` ở
    // `thanh_cong_cu.dart` (cùng ngưỡng 420) — dời nút "Xoá" từ hàng
    // Copy/Cắt (`_hangCopyCutPaste`) lên đây, cạnh "Dán".
    final ratHep = MediaQuery.sizeOf(context).width < 420;

    // Màn hình rộng (máy tính bảng): tên tệp và công cụ chung một dòng, như
    // thiết kế gốc. Màn hình hẹp (điện thoại): tên tệp một dòng riêng, công
    // cụ xuống dòng thứ hai — không thì tên tệp dài bị công cụ đè lên, hoặc
    // ngược lại công cụ bị ép chật tới mức khó bấm trúng.
    final appBar = manHinhHep
        ? AppBar(
            // (SỬA LỖI — nút lùi thừa ở dòng tên tệp khi trang này được MỞ
            // RA bằng Navigator.push, ví dụ ghi chú đám mây) Không đặt
            // `leading` riêng cho màn hẹp như màn rộng (`_nutDieuHuongTep`)
            // — Flutter mặc định TỰ chèn một nút lùi vào `leading` bất cứ
            // khi nào trang đứng trên một trang khác có thể pop về (đúng
            // trường hợp trang này được mở bằng `Navigator.push`). Bấm nút
            // thừa đó vô tình pop về đúng màn hình đã mở ra trang này —
            // chưa bao giờ là luồng điều hướng mong muốn, tắt hẳn.
            automaticallyImplyLeading: false,
            // Màn hình hẹp: bốn nút thư mục/mở rộng/tệp trước/tệp sau KHÔNG
            // còn nằm cùng dòng với tên tệp nữa — dồn hết xuống dòng dưới,
            // sát mép trái, cùng dòng với Lùi/Tiến/Lưu/Ẩn-hiện-định-dạng.
            // Tên tệp một mình đứng riêng một dòng phía trên (đủ chỗ đọc tên
            // dài, không bị bốn nút kia chèn vào nữa).
            title: _oTenField(),
            // Nút "Dán" đứng RIÊNG, cùng dòng với Tên tệp, sát mép phải —
            // đúng yêu cầu người dùng cho màn hình hẹp (trước đây nó nằm
            // lẫn trong hàng công cụ ở dòng DƯỚI cùng Lùi/Tiến/..., xa tên
            // tệp). Hàng dưới (`_dsNutCongCu(coDan: false)`) không lặp lại
            // nó nữa.
            // (YÊU CẦU MỚI) Màn hẹp: nút "Bộ nhớ tạm" đi CHUNG với "Dán" ở
            // hàng trên (cùng dòng tên tệp), sát mép phải — không còn ở gần
            // "abc" nữa (xem `_dsNutCongCu`, `coBoNhoTam: false` ở dưới).
            //
            // (YÊU CẦU MỚI) Màn RẤT hẹp + có vùng chọn thật: nút "Xoá" (y
            // chang hình dạng/logic nút xoá ký tự của Bộ phím nhanh), kèm
            // NGAY sau nó hai nút 📖/📒 ([_haiNutThemVaoTuDien] — LUÔN đi
            // theo nút Xoá bất kể màn rộng/hẹp) — đứng ngay bên TRÁI "Dán",
            // đây là nơi DUY NHẤT cả ba xuất hiện ở màn rất hẹp, không lặp
            // lại ở hàng Copy/Cắt dưới (`_hangCopyCutPaste` đã tự ẩn khi
            // `ratHep`).
            actions: [
              if (ratHep && _hienHangCopyCutPaste())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NutPhimAo(
                        nhan: '⌫',
                        moTa: Ch.xoaDoanDangChon(ngonNguHienTai.value),
                        mauNen: Colors.red.shade50,
                        mauVien: Colors.red.shade300,
                        rong: 40,
                        onTap: () => _bamCopyCutPasteOHangThayNav(_xoaChonOHangCopyCutPaste),
                      ),
                      ..._haiNutThemVaoTuDien(),
                    ],
                  ),
                ),
              // (YÊU CẦU MỚI) Màn hẹp BÌNH THƯỜNG (không rất hẹp) + có vùng
              // chọn thật: chỉ hai nút 📖/📒 (KHÔNG có nút Xoá — nút đó vẫn ở
              // hàng Copy/Cắt dưới như cũ) dời lên đây, sát bên TRÁI "Dán".
              if (!ratHep && _hienHangCopyCutPaste())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: _haiNutThemVaoTuDien()),
                ),
              // (YÊU CẦU MỚI) Hai nút cuộn lên đầu/xuống cuối — màn hẹp dời
              // lên đây (cạnh "Dán"), tên tệp dài thấy mờ mờ phía sau nhờ
              // opacity 50%. Màn RẤT hẹp + có vùng chọn thật thì ẨN hẳn,
              // nhường chỗ cho nút Xoá + 📖/📒 ở trên — CHỈ đúng trường hợp
              // đó mới ẩn (màn hẹp bình thường có vùng chọn vẫn hiện).
              if (!(ratHep && _hienHangCopyCutPaste()))
                Row(mainAxisSize: MainAxisSize.min, children: _haiNutCuonLenXuong()),
              _nutDanCongCu(),
              if (widget.caiDat.boNhoTamDanVanBanBat) _nutBoNhoTamCongCu(),
            ],
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(38),
              child: SizedBox(
                height: 38,
                child: Row(
                  children: [
                    _nutDieuHuongTep(),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _dsNutCongCu(
                              coDan: false,
                              coBoNhoTam: false,
                              coCuonLenXuong: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : AppBar(
            leading: _nutDieuHuongTep(nutThuMucCoChu: true),
            leadingWidth: _rongNutThuMucCoChu + _canhNutDieuHuongTep * 3 + 4,
            title: _oTenField(),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            actions: _dsNutCongCu(),
          );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // B1: thanh tìm kiếm mở thì nhường hẳn vị trí trên cùng — ẩn AppBar
      // (tên tệp, Lùi/Tiến/Lưu/Ẩn-hiện-định-dạng). Đóng lại thì AppBar trở
      // về y nguyên như cũ. Trình ghi âm đang mở thì appBar này CŨNG bị
      // thay hẳn bằng 4 nút nhỏ của trình ghi âm (đúng yêu cầu: mọi thứ
      // của thanh công cụ trên — tên tệp, Lùi/Tiến/Lưu/định dạng — đều
      // nhường chỗ, không phải chồng lớp CSS lên, để tránh 2 hệ thống input
      // giẫm lên nhau).
      appBar: _hienThanhTimKiem
          ? null
          : (_dangChonViTriChenFile
              // Chế độ "chọn vị trí" (chèn kết quả AI, HOẶC "Thay đổi vị
              // trí của thẻ ghi âm" — kể cả cho thẻ ĐANG ghi dở, phím 9)
              // LUÔN thắng AppBar của trình ghi âm — "ẩn hết thanh công
              // cụ, chỉ chừa các nút cần thiết" phải đúng nghĩa tuyệt đối,
              // không chừa ngoại lệ nào.
              ? null
              : (_trinhGhiAmMo
                  ? _xayAppBarTrinhGhiAmThe()
                  : (_thuGonThanhCongCu ? null : appBar))),
      // translucent: chỉ NGHE sự kiện chạm để tắt chú thích, không chặn nó
      // đi tiếp xuống nút/ô bên dưới — một cú bấm vừa tắt chú thích vừa làm
      // đúng việc của nút đó (mở cài đặt, bật micro...).
      // Bọc Stack ngoài cùng — chỗ duy nhất cần cho nút nổi "Mở rộng" (xem
      // `_thuGonThanhCongCu`), ghim cố định góc trên-phải MÀN HÌNH (không
      // phải góc trên-phải khung soạn thảo — dùng `MediaQuery.paddingOf`
      // để né tai thỏ/thanh trạng thái, không cần bọc thêm SafeArea riêng).
      body: Stack(
        children: [
          Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _tatChuThich(),
        child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_loi.isNotEmpty)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF4E5),
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Color(0xFF8A5300)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loi,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A5300)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: const Color(0xFF8A5300),
                      onPressed: () => setState(() => _loi = ''),
                    ),
                  ],
                ),
              ),
            // Dải gợi ý "Tải app APK" — CHỈ trên web VÀ khi thiết bị (tự
            // đoán hoặc chọn tay) là Android: bản APK ổn định hơn hẳn bản
            // web trên di động (không dính lỗi "bãi đất trống" của bàn
            // phím ảo, xem CLAUDE.md). Web chỉ thật sự hợp với PC/Mac.
            // Bấm X thì nhớ luôn, không hiện lại nữa (`caiDat.anGoiYTaiApk`).
            if (kIsWeb && _thietBiHienTai == ThietBi.android && !widget.caiDat.anGoiYTaiApk)
              Container(
                width: double.infinity,
                color: const Color(0xFFE3F2FD),
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    const Icon(Icons.android, size: 18, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bạn đang dùng Android — tải app APK sẽ ổn định hơn bản web.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          moLienKetNgoai('https://github.com/sotay99/ghi-noi/releases/latest'),
                      child: Text(Ch.taiApk(ngonNguHienTai.value)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: const Color(0xFF1565C0),
                      onPressed: () {
                        widget.caiDat.datAnGoiYTaiApk(true);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            // (YÊU CẦU MỚI) Dải "Có bản APK mới" — CHỈ trên bản APK thật
            // (`!kIsWeb`, ngược hẳn dải "Tải app APK" ở trên). Đóng thì nhớ
            // ĐÚNG số hiệu bản này (`daDongGoiYCapNhatApkBanSo`) — có bản
            // mới hơn nữa thì dải lại hiện, khác "ẩn vĩnh viễn".
            if (!kIsWeb &&
                _banApkMoiPhatHien != null &&
                _banApkMoiPhatHien! > widget.caiDat.daDongGoiYCapNhatApkBanSo)
              Container(
                width: double.infinity,
                color: const Color(0xFFE3F2FD),
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    const Icon(Icons.system_update, size: 18, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã có bản APK mới (v$_banApkMoiPhatHien) — cập nhật để dùng bản ổn định nhất.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          moLienKetNgoai('https://github.com/sotay99/ghi-noi/releases/latest'),
                      child: Text(Ch.taiBanMoi(ngonNguHienTai.value)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: const Color(0xFF1565C0),
                      onPressed: () {
                        widget.caiDat.datDaDongGoiYCapNhatApkBanSo(_banApkMoiPhatHien!);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            // (YÊU CẦU MỚI — xem/soạn offline) Ghi chú đám mây đang mở từ
            // bản cache trên đĩa (mất mạng, hoặc chưa đồng bộ kịp một thay
            // đổi nào) — báo thẳng, đừng để người dùng tưởng nhầm mọi thứ
            // đã an toàn trên đám mây.
            if (widget.kho is KhoDuLieuDamMay &&
                (widget.kho as KhoDuLieuDamMay).dangXemBanNgoaiTuyen)
              Container(
                width: double.infinity,
                color: const Color(0xFFFCE8E6),
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, size: 18, color: Color(0xFFB3261E)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đang xem bản ngoại tuyến — sẽ đồng bộ khi có mạng.',
                        style: TextStyle(fontSize: 13, color: Color(0xFFB3261E)),
                      ),
                    ),
                  ],
                ),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              child: _hienThanhTimKiem ? _thanhTimKiem() : const SizedBox(width: double.infinity),
            ),
            // B2/B6: thanh "Thay thế" ngay dưới thanh tìm kiếm, chỉ khi có
            // ít nhất một kết quả — tự ẩn/hiện theo `_ketQuaTimKiem`.
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              child: _hienThanhTimKiem && _ketQuaTimKiem.isNotEmpty
                  ? _thanhThayThe()
                  : const SizedBox(width: double.infinity),
            ),
            // Mục 7: đường kẻ mỏng phân tách thanh Lùi/Tiến/Lưu (AppBar) với
            // thanh định dạng thủ công ngay dưới nó. Mờ hơn nữa (0.12 thay
            // vì màu `Colors.grey` mặc định gần như đen-xám) — chỉ đủ để mắt
            // nhận ra có ranh giới, không tạo thêm một "đường kẻ đậm" nhìn
            // rối mắt giữa hai thanh vốn đã sát nhau.
            // B1: thanh định dạng thủ công cũng nhường chỗ khi tìm kiếm mở.
            if (!_anThanhDinhDang && !_hienThanhTimKiem && !_trinhGhiAmMo && !_thuGonThanhCongCu && !_dangChonViTriChenFile)
              Divider(height: 1, thickness: 1, color: Colors.grey.withValues(alpha: 0.12)),
            if (!_anThanhDinhDang && !_hienThanhTimKiem && !_trinhGhiAmMo && !_thuGonThanhCongCu && !_dangChonViTriChenFile)
              _thanhDinhDangThuCong(),
            // Mục 7: và một đường kẻ mỏng nữa ở mép dưới thanh định dạng,
            // phân tách nó với vùng soạn thảo bên dưới.
            if (!_anThanhDinhDang && !_hienThanhTimKiem && !_trinhGhiAmMo && !_thuGonThanhCongCu && !_dangChonViTriChenFile)
              Divider(height: 1, thickness: 1, color: Colors.grey.withValues(alpha: 0.12)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                // Ctrl+Z / Ctrl+Shift+Z bấm ra "liệt" khi con trỏ đang nằm
                // trong ô soạn thảo (nhưng chạy bình thường khi không có con
                // trỏ ở đó) — vì `HardwareKeyboard.addHandler` là một tầng
                // nghe TOÀN CỤC riêng biệt, không hề chặn được tầng
                // Shortcuts/Actions của chính ô văn bản đang giữ tiêu điểm
                // (EditableText có sẵn logic tự xử lý một số tổ hợp phím
                // ngay tại tiêu điểm, tầng đó chạy TRƯỚC hoặc ĐÈ LÊN tầng
                // nghe toàn cục). Cách chắc chắn duy nhất để CHIẾM lại tổ
                // hợp phím này khi ô văn bản đang giữ tiêu điểm là khai báo
                // một `Shortcuts` NGAY TRÊN nó — Flutter luôn ưu tiên
                // `Shortcuts` gần tiêu điểm nhất trong cây, nên khai báo ở
                // đây thắng chắc chắn, bất kể ô văn bản tự xử lý gì bên
                // trong.
                child: Shortcuts(
                  shortcuts: {
                    const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                        const _YDinhLuiLai(),
                    const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
                        const _YDinhToi(),
                    const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                        const _YDinhTimKiem(),
                    const SingleActivator(LogicalKeyboardKey.keyB, control: true):
                        const _YDinhDinhDang('dam'),
                    const SingleActivator(LogicalKeyboardKey.keyI, control: true):
                        const _YDinhDinhDang('nghieng'),
                    const SingleActivator(LogicalKeyboardKey.keyU, control: true):
                        const _YDinhDinhDang('gachChan'),
                    const SingleActivator(LogicalKeyboardKey.keyX, control: true, shift: true):
                        const _YDinhDinhDang('gachNgang'),
                    const SingleActivator(LogicalKeyboardKey.equal, control: true, shift: true):
                        const _YDinhDinhDang('treMu'),
                    const SingleActivator(LogicalKeyboardKey.equal, control: true):
                        const _YDinhDinhDang('treChan'),
                    const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true):
                        const _YDinhDinhDang('mauChu'),
                    const SingleActivator(LogicalKeyboardKey.keyH, control: true, shift: true):
                        const _YDinhDinhDang('mauNen'),
                    const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
                        const _YDinhDinhDang('xoaDinhDang'),
                    const SingleActivator(LogicalKeyboardKey.keyS, control: true):
                        const _YDinhDinhDang('luu'),
                    const SingleActivator(LogicalKeyboardKey.keyC, control: true): const _YDinhCopy(),
                    const SingleActivator(LogicalKeyboardKey.keyX, control: true): const _YDinhCut(),
                    const SingleActivator(LogicalKeyboardKey.keyV, control: true): const _YDinhPaste(),
                  },
                  child: Actions(
                    actions: {
                      _YDinhLuiLai: CallbackAction<_YDinhLuiLai>(
                        onInvoke: (_) {
                          if (_lichSuLui.isNotEmpty) _lui();
                          return null;
                        },
                      ),
                      _YDinhToi: CallbackAction<_YDinhToi>(
                        onInvoke: (_) {
                          if (_lichSuToi.isNotEmpty) _toi();
                          return null;
                        },
                      ),
                      _YDinhTimKiem: CallbackAction<_YDinhTimKiem>(
                        onInvoke: (_) {
                          if (_hienThanhTimKiem) {
                            _dongTimKiem();
                          } else {
                            _moTimKiem();
                          }
                          return null;
                        },
                      ),
                      _YDinhDinhDang: CallbackAction<_YDinhDinhDang>(
                        onInvoke: (y) {
                          if (y.loai == 'luu') {
                            _bamNutLuu();
                          } else {
                            _apDungDinhDang(y.loai);
                          }
                          return null;
                        },
                      ),
                      // Chiếm lại Ctrl+C/Ctrl+X/Ctrl+V (bàn phím vật lý) — qua
                      // Intent RIÊNG của Flowrite (`_YDinhCopy`/`_YDinhCut`/
                      // `_YDinhPaste`, bắt ở `Shortcuts` phía trên), KHÔNG
                      // phải Intent có sẵn của Flutter (đã thử, không ăn —
                      // xem chú thích khai báo `_YDinhCopy`). Nhờ vậy nút
                      // Copy/Cắt/Dán ở Bộ phím nhanh và phím tắt vật lý giờ
                      // CÙNG đi qua một con đường (`_phimAoCopy`/`_phimAoCut`/
                      // `_phimAoPaste`), cùng giữ được định dạng khi dán
                      // trong app. Không khai báo gì cho chuột phải/bấm giữ —
                      // menu nổi lên lúc bôi đen (`contextMenuBuilder`) là cơ
                      // chế khác, cố ý CHƯA đụng tới (rủi ro cao hơn, ảnh
                      // hưởng tới mọi người dùng, xem thảo luận trong lịch
                      // sử).
                      _YDinhCopy: CallbackAction<_YDinhCopy>(
                        onInvoke: (_) {
                          _phimAoCopy();
                          return null;
                        },
                      ),
                      _YDinhCut: CallbackAction<_YDinhCut>(
                        onInvoke: (_) {
                          _phimAoCut();
                          return null;
                        },
                      ),
                      _YDinhPaste: CallbackAction<_YDinhPaste>(
                        onInvoke: (_) {
                          _phimAoPasteCoLiet();
                          return null;
                        },
                      ),
                    },
                    child: Stack(
                      key: _khungVanBanKey,
                      children: [
                        // Chữ gợi ý khi bài còn trống trơn — tự tay dựng
                        // thay cho InputDecoration.hintText mặc định, vì
                        // hintText chỉ nhận chuỗi trần, không chèn được icon
                        // "?" tròn y hệt icon nút Hướng dẫn vào giữa câu.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _boDieuKhien,
                              builder: (context, _) => _goiYTrong(),
                            ),
                          ),
                        ),
                        // Gạch chân đỏ lỗi chính tả — cố ý đặt TRƯỚC (dưới)
                        // TextField trong danh sách con của Stack, để lớp
                        // chữ của TextField vẽ ĐÈ LÊN sau đó, nét đi xuống
                        // của chữ (g, ệ, ụ, q, y...) nhờ vậy luôn nổi trên
                        // gạch chân thay vì bị nó che mất.
                        Positioned.fill(
                          child: IgnorePointer(
                            // Phải lắng nghe CẢ `_cuonVanBan` (giống chấm
                            // tròn tím cuối văn bản ở dưới), không chỉ
                            // `_boDieuKhien` — painter đo toạ độ ngay lúc
                            // paint() nên bản thân nó luôn đúng, nhưng
                            // AnimatedBuilder chỉ gọi lại build() (và do đó
                            // paint()) khi Listenable nó nghe đổi giá trị.
                            // Cuộn (vuốt) đổi `_cuonVanBan.offset`, không đổi
                            // nội dung `_boDieuKhien`, nên nếu chỉ nghe
                            // `_boDieuKhien` thì gạch chân/gạch giữa thân
                            // đứng hình tại vị trí cũ cho tới khi có việc
                            // khác (tap đặt con trỏ) làm rebuild theo đường
                            // khác.
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_boDieuKhien, _cuonVanBan]),
                              builder: (context, _) => Stack(
                                children: [_veDanhDauAi()],
                              ),
                            ),
                          ),
                        ),
                        // (VIỆC 5c) Đường kẻ chia văn bản — cùng lớp "dưới
                        // chữ" như gạch chân AI, cùng lý do phải nghe cả
                        // `_cuonVanBan`.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_boDieuKhien, _cuonVanBan]),
                              builder: (context, _) => Stack(
                                children: [_veDuongKeChia()],
                              ),
                            ),
                          ),
                        ),
                        // Nền gradient đỏ→vàng của kết quả tìm kiếm — cùng lớp
                        // "dưới chữ" như gạch chân AI ở trên, và cùng lý do
                        // phải lắng nghe cả `_cuonVanBan` lẫn `_oTimKiem` (đổi
                        // từ khoá cũng phải vẽ lại ngay).
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_boDieuKhien, _cuonVanBan, _oTimKiem]),
                              builder: (context, _) => Stack(
                                children: [_veTimKiem()],
                              ),
                            ),
                          ),
                        ),
                        // (VIỆC 4) Nền gradient đỏ→vàng NHẤP NHÁY 1 giây của
                        // "Thay chỗ này"/"Tất cả" — chỉ cần lắng nghe
                        // `_boDieuKhien` (mỗi nhịp nhấp nháy tự gọi `veLai()`)
                        // và `_cuonVanBan` (cuộn cũng phải vẽ lại ngay).
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_boDieuKhien, _cuonVanBan]),
                              builder: (context, _) => Stack(
                                children: [_veHieuUngThayThe()],
                              ),
                            ),
                          ),
                        ),
                        TextField(
                          key: _oVanBanKey,
                          controller: _boDieuKhien,
                          focusNode: _oChu,
                          scrollController: _cuonVanBan,
                          maxLines: null,
                          expands: true,
                          autofocus: true,
                          // (SỬA LỖI — thảo luận với người dùng, "liệt bàn
                          // phím ảo") Chỉ có TÁC DỤNG khi `_choChamLaiDeBatBanPhimAo`
                          // đang bật (xem `_giuTieuDiemKhongBatBanPhimAo`) —
                          // mượn đúng cử chỉ chạm thật này để gọi
                          // `TextInput.show()`, việc mà lúc dọn kết nối
                          // trước đó (chạy trong `Timer`, không có cử chỉ
                          // nào đi kèm) không chắc làm được. Chạm bình
                          // thường (cờ đang tắt) thì không có gì xảy ra
                          // thêm — không ảnh hưởng gì tới việc di chuyển
                          // con trỏ/chọn vùng bằng chạm như cũ.
                          onTap: () {
                            // (YÊU CẦU MỚI) Chạm vào khung soạn thảo cũng phải
                            // coi như một lượt "gõ tay" để thắng mic — kể cả
                            // khi con trỏ KHÔNG đổi vị trí (chạm đúng chỗ đang
                            // nhấp nháy), trường hợp mà việc chỉ nghe `selection`
                            // đổi (nếu có) không tự bắt ra được. `onTap` luôn
                            // bắn sau MỖI lần chạm thật, bất kể con trỏ dời đi
                            // hay giữ y vị trí cũ.
                            if (_muonNghe || _micro.isListening) _nguoiDungVuaGo();
                            if (!_choChamLaiDeBatBanPhimAo) return;
                            _choChamLaiDeBatBanPhimAo = false;
                            SystemChannels.textInput.invokeMethod<void>('TextInput.show');
                          },
                          textAlignVertical: TextAlignVertical.top,
                          // (SỬA LỖI mất hết dấu xuống dòng khi chạm vào khung,
                          // chỉ xảy ra lúc "Bộ phím nhanh cho màn hình cảm
                          // ứng" đang bật) TRƯỚC ĐÂY dùng `keyboardType:
                          // TextInputType.none` để báo hệ thống đừng bật bàn
                          // phím ảo — nhưng trên WEB, đổi `keyboardType` đổi
                          // luôn LOẠI phần tử DOM ẩn mà Flutter Web dùng để
                          // đồng bộ nội dung/con trỏ với trình duyệt; với
                          // `TextInputType.none`, phần tử đó không còn giữ
                          // được `\n` như một `<textarea>` bình thường — hễ
                          // chạm vào khung (kích hoạt đồng bộ lại từ DOM) là
                          // Flutter đọc ngược nội dung ĐÃ MẤT hết dấu xuống
                          // dòng đó rồi ghi đè lên văn bản thật.
                          //
                          // Sửa: GIỮ NGUYÊN `TextInputType.multiline` mọi lúc
                          // (đúng loại phần tử DOM, không đổi hành vi đồng bộ)
                          // và dùng `readOnly` để chặn bàn phím ảo thay thế —
                          // `readOnly` chỉ chặn NGƯỜI DÙNG gõ qua bàn phím hệ
                          // thống, KHÔNG chặn việc sửa văn bản bằng tay qua
                          // `_boDieuKhien.value` (chính là cách hàng phím ảo
                          // `_chenKyTuTuPhimAo`/`_xoaKyTuTuPhimAo` hoạt động),
                          // và vẫn cho chạm để di chuyển con trỏ/chọn vùng
                          // bình thường như tài liệu Flutter đã ghi rõ.
                          keyboardType: TextInputType.multiline,
                          readOnly: (_boPhimNhanhCamUngMo && !_epHienBanPhimAoTrongBoPhimNhanh) ||
                              _epAnBanPhimAoKhiGiuFocus,
                          // Chặn sửa/xoá từng-ký-tự-riêng-lẻ bên trong một
                          // thẻ ghi âm — xem `ChanSuaGiuaThe`.
                          inputFormatters: [
                            ChanSuaGiuaThe(khiCanXoaThe: _khiCanXoaTheTuBanPhim),
                            ChanSuaGiuaTheTichChon(khiDaXoaThe: _khiDaXoaTheTichChon),
                            _XoaCachDauKhiDanLucThutDauDong(
                              dangBatTuDongThut: () => widget.caiDat.tuDongThutDauDong,
                            ),
                          ],
                          textCapitalization: TextCapitalization.sentences,
                          style: _kieuVanBan,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          // Sửa LỖI 1 (vùng CHỌN lan ra hết phần trống cuối
                          // dòng khi bôi chọn nhiều dòng): mặc định Flutter
                          // dùng BoxWidthStyle.max cho vùng chọn NATIVE khi
                          // selection trải qua nhiều dòng, khiến những dòng
                          // ngắn (xuống dòng tự nhiên trước khi hết khung) bị
                          // tô kín tới tận mép phải dù không có chữ ở đó.
                          // `tight` khiến vùng tô chỉ ôm đúng phần có ký tự.
                          selectionWidthStyle: ui.BoxWidthStyle.tight,
                          // (VIỆC 2) Con trỏ nháy (caret) bị "nuốt mất" khi
                          // đứng trên/cạnh ký tự có `mauNen` (màu nền định
                          // dạng thủ công): `backgroundColor` của TextSpan
                          // được engine vẽ CÙNG với chữ trong một lần vẽ đoạn
                          // văn bản, còn caret GỐC của TextField/EditableText
                          // vẽ CÙNG lớp đó (dưới nền của span kế tiếp khi
                          // caret đứng NGAY TRƯỚC nó) — thử đổi hẳn màu caret
                          // (từng làm) KHÔNG đủ, vì đây là chuyện THỨ TỰ VẼ,
                          // không phải màu sắc: nền vẫn che kín caret dù màu
                          // gì. TextField không có tham số nào đổi thứ tự vẽ
                          // (không lộ `paintCursorAboveText` của EditableText
                          // ra ngoài), nên tắt hẳn caret gốc và tự vẽ một
                          // caret RIÊNG ở lớp TRÊN CÙNG của Stack (`_VeConTro`,
                          // cuối danh sách con bên dưới) — xem chú thích ở đó.
                          showCursor: false,
                          cursorColor: const Color(0xFFE91E63),
                          // D3: cập nhật trạng thái định dạng theo vị trí
                          // con trỏ/selection. TextField không có tham số
                          // `onSelectionChanged` (đó là API của EditableText),
                          // nên việc gọi `_tinhTrangThaiDinhDangHienTai` được
                          // đăng ký qua `_boDieuKhien.addListener` ở
                          // `initState` — xem chú thích ở đó.
                        ),
                        // Chấm tròn tím đánh dấu cuối văn bản — chỉ mang tính
                        // trang trí, KHÔNG phải một ký tự thật, nên con trỏ
                        // không bao giờ đứng được sau nó (vị trí xa nhất của
                        // con trỏ vẫn là cuối chuỗi thật, tức trước chấm này).
                        //
                        // Positioned.fill phải nằm NGAY DƯỚI Stack — Positioned
                        // là ParentDataWidget, chỉ áp dụng được khi cha trực
                        // tiếp của nó là Stack. `_chamCuoiVanBan` trả về một
                        // Positioned KHÁC (định vị chấm tròn); nó cần một Stack
                        // MỚI làm cha trực tiếp, nên bọc trong Stack con ở đây
                        // chứ không thả thẳng làm con của IgnorePointer/
                        // AnimatedBuilder — làm vậy Flutter báo lỗi "Incorrect
                        // use of ParentDataWidget" và cả khung soạn thảo hoá
                        // thành ô xám lỗi.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_boDieuKhien, _cuonVanBan]),
                              builder: (context, _) => Stack(
                                children: [_chamCuoiVanBan()],
                              ),
                            ),
                          ),
                        ),
                        // (VIỆC 2) Con trỏ nháy tự vẽ — CUỐI CÙNG trong danh
                        // sách con của Stack này nên vẽ SAU CÙNG, đè lên trên
                        // mọi lớp khác kể cả `mauNen` của chữ. Nghe cả
                        // `_boDieuKhien` (đổi vị trí/nội dung) lẫn `_cuonVanBan`
                        // (cuộn) — đúng lý do đã giải thích ở các overlay khác
                        // phía trên; nhịp nhấp nháy tự đổi qua `setState` của
                        // State (Timer ở `_khiFocusConTroDoi`) nên không cần
                        // thêm Listenable riêng cho việc đó.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: Listenable.merge(
                                  [_boDieuKhien, _cuonVanBan, _conTroDangHien]),
                              builder: (context, _) => Stack(
                                children: [_veConTro()],
                              ),
                            ),
                          ),
                        ),
                        // 5 mốc phụ báo "Đoạn số" dọc mép trái — đặt NGAY
                        // TRONG Stack này (cùng khung với `_oVanBanKey`), y
                        // hệt cách `_veConTro()` định vị con trỏ: dùng
                        // `RenderEditable.localToGlobal(point, ancestor:
                        // khungBox)` để quy đổi THẲNG sang toạ độ cục bộ của
                        // CHÍNH Stack này — không đi vòng qua toạ độ TOÀN CỤC
                        // của màn hình rồi quy đổi ngược lại (cách cũ dùng
                        // `_khungThanTrangKey` ở Stack ngoài cùng bị lệch dần
                        // khi cuộn sâu, khiến các mốc phía trên rơi ra ngoài
                        // màn hình và biến mất).
                        _veMocPhuDoanSo(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_dangChonViTriChenFile) _xayThanhChonViTriChenFile(),
            if (!_dangChonViTriChenFile && _boPhimNhanhCamUngMo) _xayHangDieuHuongConTro(),
            if (!_dangChonViTriChenFile && _boPhimNhanhCamUngMo) _xayHangPhimNhanhCamUng(),
            // Bọc riêng bằng ValueListenableBuilder (xem chú thích ở
            // `_songAmTick`) — CHỈ ThanhCongCu dựng lại mỗi lần sóng âm đổi
            // (tới 5 lần/giây lúc ghi âm/nghe), không đụng tới AppBar trình
            // ghi âm hay phần còn lại của trang.
            if (!_dangChonViTriChenFile)
            Stack(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _songAmTick,
                  builder: (context, _, __) => ThanhCongCu(
                // Bê nguyên xi hiệu ứng "đang nghe" (nền hồng, đường kẻ đỏ,
                // sóng âm) từ micro sang cho lúc một thẻ ghi âm đang ghi —
                // cùng logic, chỉ thêm điều kiện.
                bat: _muonNghe || _soTheGhiAmDangGhi != null,
                dangNghe: _dangNghe ||
                    (_soTheGhiAmDangGhi != null && !_theGhiAmDangTamDung),
                songAm: _songAm,
                sanSang: _sanSang && !_ghiAmTheDangKhoaMicro,
                biKhoaThietBi: !_microDungDuocTrenThietBiNay,
                hienChuThich: _hienChuThich,
                khiBamChuThich: _khiBamChuThich,
                nhanPhimTat: widget.caiDat.phimTatMicro.nhan,
                // Bàn phím đóng thì còn phải né thanh điều hướng của máy; bàn
                // phím mở thì nó che mất thanh đó rồi, né nữa là hở một dải
                // trắng giữa thanh công cụ và bàn phím.
                neThanhDieuHuong: caoBanPhim == 0,
                khiBamMicro: _bamNutMicro,
                khiBamCaiDatMicro: () => _moCaiDat(NhomCaiDat.micro),
                khiBamCaiDatHienThi: () => _moCaiDat(NhomCaiDat.hienThiVaTuDongSua),
                khiBamTuDienChinhTa: () async {
                  await moModalTuDienChinhTa(context, widget.caiDat);
                  // Từ điển có thể vừa đổi (thêm/sửa/xoá cặp từ) — quét lại
                  // ngay, không đợi tới lần lưu kế tiếp.
                  if (mounted) _quetTuDienChinhTa();
                },
                khiBamTuDienNhapLieuNhanh: () async {
                  // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Xem
                  // `_ngungMicroVaGhiAmTheNeuDangBat`.
                  await _ngungMicroVaGhiAmTheNeuDangBat();
                  if (!mounted) return;
                  await moModalTuDienNhapLieuNhanh(context, widget.caiDat);
                  // Có thể vừa bật/tắt hoặc đổi phím tắt — vẽ lại nút
                  // toolbar (ẩn/hiện theo công tắc) ngay, không đợi gì cả.
                  if (mounted) setState(() {});
                },
                khiBamBoNhoTam: () async {
                  // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Xem
                  // `_ngungMicroVaGhiAmTheNeuDangBat`.
                  await _ngungMicroVaGhiAmTheNeuDangBat();
                  if (!mounted) return;
                  await moModalBoNhoTam(context, widget.caiDat);
                  // Có thể vừa bật/tắt hoặc đổi phím tắt — vẽ lại nút
                  // toolbar (ẩn/hiện theo công tắc) ngay, không đợi gì cả.
                  if (mounted) setState(() {});
                },
                khiBamHuongDan: () async {
                  // (YÊU CẦU MỚI — loại trừ lẫn nhau Ghi âm/Micro) Xem
                  // `_ngungMicroVaGhiAmTheNeuDangBat`.
                  await _ngungMicroVaGhiAmTheNeuDangBat();
                  if (!mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManHinhHuongDan()),
                  );
                },
                khiBamCaiDatKiemTraToanVan: _moModalCaiDatKiemTraToanVan,
                khiBamChuyenFileAmThanh: _chonVaChuyenFileAmThanh,
                khiBamChuyenAnhThanhVanBan: _chonVaChuyenAnhThanhVanBan,
                khiBamChupAnh: _chupVaChuyenAnhThanhVanBan,
                khiBamTomTatToanVan: _moModalChonKieuTomTat,
                khiBamMoRongToanVan: _moModalChonKieuMoRong,
                khiBamVietLaiToanVan: _moModalChonKieuVietLai,
                khiBamTroChuyenVeVanBan: _moTroChuyenVeVanBan,
                layDoanVanDangChon: _layDoanVanDangChon,
                coVungChonThatSu: () => _vungChonThatSu() != null,
                epToanVanKhiCoVungChon: _epToanVanKhiCoVungChon,
                khiBamDoiCheDoLamViec: _doiCheDoLamViecVoiVungChon,
                khoaMenuAI: _khoaMenuAI,
                khiBamBoPhimNhanh: _bamNutBoPhimNhanhCamUng,
                khiMoMenuCanReset: _resetManHinhTruocKhiMoMenu,
                khiDongMenuAI: _giuFocusOChuSauKhiBam,
                khiBamDangNhapGoogle: _bamDangNhapGoogle,
                khiBamKhoiDongTep: () => moModalKhoiDong(
                  context,
                  caiDat: widget.caiDat,
                  khoNoiBo: widget.khoNoiBo,
                  khoHienTai: widget.kho,
                  ghiChuHienTai: _ghiChuHienTai,
                ),
                khiBamDieuKhoan: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrangDieuKhoan()),
                ),
                khiBamBaoMat: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrangBaoMat()),
                ),
                khiBamLuyenGoPhim: () => moModalLuyenGoPhim(context),
                khiBamCaiDatUngDung: () => moModalCaiDatUngDung(context),
                khiBamGopY: () => moModalGopY(
                  context,
                  emailDaDangNhap: _nguoiDungDangNhap?.email,
                ),
                khiBamQuanLyGopY: () => moModalQuanLyGopY(context),
                khiBamDanhSachUser: () => moModalDanhSachUser(context),
                khiBamCanhBaoApi: () => moModalCanhBaoApi(context),
                coCanhBaoApi: _coCanhBaoApiCanBaoCao,
                khiBamDonate: () => moModalDonate(context),
                // `tenHienThiDaDangNhap` khác `null` LÀ tín hiệu "đang đăng
                // nhập" cho `ThanhCongCu` — không được để `null` chỉ vì tài
                // khoản không có sẵn displayName, nên dự phòng bằng email.
                tenHienThiDaDangNhap: _nguoiDungDangNhap == null
                    ? null
                    : (_nguoiDungDangNhap!.displayName ??
                        _nguoiDungDangNhap!.email ??
                        'Tài khoản Google'),
                emailDaDangNhap: _nguoiDungDangNhap?.email,
                urlAnhDaiDienDaDangNhap: _nguoiDungDangNhap?.photoURL,
                boPhimNhanhDangMo: _boPhimNhanhCamUngMo,
                noiBatBoPhimNhanh:
                    kIsWeb && (_thietBiHienTai == ThietBi.android || _thietBiHienTai == ThietBi.iphone),
                khiBamKiemTraToanVan: _khiBamKiemTraToanVan,
                khiBamKiemTraChinhTaToanVan: () =>
                    _khiBamKiemTraToanVan(loaiKiemTra: 'chinh_ta'),
                khiBamKiemTraDauCauToanVan: () =>
                    _khiBamKiemTraToanVan(loaiKiemTra: 'dau_cau'),
                dangGhiAmThe: _trinhGhiAmMo,
                khiBamGhiAmThe: _bamNutGhiAmThe,
                khoaNutGhiAmThe: _muonNghe && !_trinhGhiAmMo,
                khiBamChonTatCa: _phimAoChonTatCa,
                dangChonTatCa: _phimAllVuaChonTatCa,
                gopMicVaGhiAmThanhMotNut: false,
                khiBamChepTatCa: () => _chepTatCa(),
                khiBamChepRoiXoaTatCa: _chepRoiXoaTatCa,
                khiBamXoaTatCa: () => _xoaTatCa(),
                khiBamChonTatCaTrongMenuThem: _chonTatCaTrucTiepTuMenu,
                khiBamDanhSachPhimTat: _moDanhSachPhimTat,
                khiBamTimKiem: () => _hienThanhTimKiem ? _dongTimKiem() : _moTimKiem(),
                khiBamTroChuyen: _moThongBaoTroChuyenDangNangCap,
                // Có vùng chọn thật — LUÔN tạm thay 4 nút (Hướng dẫn/Thêm/
                // Tài khoản-Cài đặt/Phím nhanh) bằng Copy/Cắt ngay cạnh "Làm
                // việc với AI" (tự sáng sẵn), xem `ThanhCongCu`. Không còn
                // phụ thuộc Thu gọn/Mở rộng thanh công cụ phía trên hay Bộ
                // phím nhanh đang mở/đóng — hàng này giờ luôn hiện ở thanh
                // dưới khi có vùng chọn, bất kể các trạng thái đó.
                thayNutBangCopyCutPaste: _hienHangCopyCutPaste(),
                hangCopyCutPaste: _hangCopyCutPaste(),
                  ),
                ),
                // (Nút ẩn/hiện 4 nút điều hướng không còn "nhảy" tới đè lên
                // `ThanhCongCu` nữa — giờ LUÔN về đúng một chỗ, cuối hàng
                // Copy/Cut/Paste/All, xem `_xayHangCongCuVanBanCamUng`.)
              ],
            ),
            SizedBox(height: caoBanPhim),
          ],
        ),
        ),
          ),
          // (SỬA LỖI đè lên nút "Tắt" đỏ của thanh tìm kiếm) Khi thanh tìm
          // kiếm đang mở, nó đã tự có lối thoát riêng (nút Tắt đỏ) rồi — ẩn
          // hẳn nút nổi "Mở rộng" trong lúc đó thay vì để hai nút chồng lên
          // nhau tranh cử chỉ; đóng thanh tìm kiếm lại thì "Mở rộng" tự hiện
          // lại ngay (vẫn còn `_thuGonThanhCongCu`).
          // Trình ghi âm mở thì AppBar của NÓ đã thay hẳn AppBar thường rồi
          // (có lối thoát riêng "Hoàn thành-Đóng trình ghi âm"/"Xoá bản này")
          // — ẩn luôn nút nổi này, không thì nó đè lên góc phải của bảng nút
          // trình ghi âm mới.
          if (_thuGonThanhCongCu && !_hienThanhTimKiem && !_trinhGhiAmMo && !_dangChonViTriChenFile)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 4,
              right: 8,
              child: _NutNoiTuTho(
                chu: '🔽',
                mau: const Color(0xFF5F6368),
                moTa: 'Mở rộng — hiện lại thanh công cụ',
                onTap: () {
                  setState(() => _thuGonThanhCongCu = false);
                  unawaited(widget.caiDat.datThuGonThanhCongCu(false));
                  unawaited(_dayCaiDatDongBoTaiKhoan({'thuGonThanhCongCu': false}));
                },
              ),
            ),
          // (YÊU CẦU MỚI v123) Thu gọn thanh công cụ làm mất luôn nút "Dán"
          // cố định (`_nutDanCongCu`, ở thanh trên) — thay bằng một nút nổi
          // góc trái, cùng độ cao với "Mở rộng" ở góc phải, để Dán vẫn luôn
          // trong tầm tay. Cùng điều kiện ẩn/hiện với "Mở rộng".
          if (_thuGonThanhCongCu && !_hienThanhTimKiem && !_trinhGhiAmMo && !_dangChonViTriChenFile)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 4,
              left: 8,
              child: _NutDanNoiKhiThuGon(onTap: _phimAoPasteCoLiet),
            ),
          _nhanDoanSo(caoBanPhim),
        ],
      ),
    );
  }
}

/// Dòng "Đang ở giây thứ N / M" trong hộp thoại cảnh báo sắp chạm giới hạn
/// thẻ ghi âm (`_hienCanhBaoGioiHanTheGhiAmNeuChua`) — sống theo
/// `_thoiLuongTheGhiAmDangGhi` (cập nhật mỗi giây), và tự nhấp nháy (đổi độ
/// mờ liên tục) khi chỉ còn 5 giây cuối trước mốc cứng `gioiHan`, để người
/// dùng dễ nhận ra đang gấp.
class _DemGiayCanhBaoTheGhiAm extends StatefulWidget {
  const _DemGiayCanhBaoTheGhiAm({required this.thoiLuong, required this.gioiHan});

  final ValueListenable<Duration> thoiLuong;
  final Duration gioiHan;

  @override
  State<_DemGiayCanhBaoTheGhiAm> createState() => _DemGiayCanhBaoTheGhiAmState();
}

class _DemGiayCanhBaoTheGhiAmState extends State<_DemGiayCanhBaoTheGhiAm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dieuKhien;

  @override
  void initState() {
    super.initState();
    _dieuKhien = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dieuKhien.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gioiHanGiay = widget.gioiHan.inSeconds;
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.thoiLuong,
      builder: (context, thoiLuong, _) {
        final giay = thoiLuong.inSeconds.clamp(0, gioiHanGiay);
        // Đỏ từ 10 giây cuối (ví dụ giây 50/60), đỏ VÀ nhấp nháy từ 5 giây
        // cuối (giây 55/60) — hai mốc tách riêng theo đúng yêu cầu.
        final sapDo = giay >= gioiHanGiay - 10;
        final sapNhapNhay = giay >= gioiHanGiay - 5;
        final chu = Text(
          'Đang ở giây thứ $giay / $gioiHanGiay giây',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: sapDo ? Colors.red.shade700 : Colors.black87,
          ),
        );
        if (!sapNhapNhay) return chu;
        return AnimatedBuilder(
          animation: _dieuKhien,
          builder: (context, child) => Opacity(
            opacity: 0.3 + 0.7 * _dieuKhien.value,
            child: child,
          ),
          child: chu,
        );
      },
    );
  }
}

/// Nguyên cả dòng "Bản Ghi âm số N" ở đầu Bảng điều khiển — CẢ dòng (chữ
/// "Bản Ghi âm số " lẫn số N) cùng nhấp nháy phóng to 1,3 lần rồi thu nhỏ
/// lại, lặp 8 lần (2400ms) rồi đứng im HẲN, MỖI KHI SỐ ĐỔI (đứng im hoàn
/// toàn nếu không đổi) — thu hút chú ý khi bấm "Hoàn thành-Tạo bản ghi âm
/// mới" ngay trong bảng điều khiển (bảng KHÔNG đóng lại, chỉ đổi số — xem
/// `_TrangSoanThaoState._soTheChoBangDieuKhien`).
class _DongBanGhiAmSoNhapNhay extends StatefulWidget {
  const _DongBanGhiAmSoNhapNhay({required this.soThe, required this.coChu});

  final ValueListenable<int> soThe;
  final double coChu;

  @override
  State<_DongBanGhiAmSoNhapNhay> createState() => _DongBanGhiAmSoNhapNhayState();
}

class _DongBanGhiAmSoNhapNhayState extends State<_DongBanGhiAmSoNhapNhay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dieuKhien;
  late final Animation<double> _tiLePhongTo;
  late int _soHienTai;

  @override
  void initState() {
    super.initState();
    _soHienTai = widget.soThe.value;
    // 8 lần phóng to/thu nhỏ, mỗi lần 300ms (150 lên + 150 xuống) — tổng
    // 2400ms rồi đứng im hẳn (không lặp lại nữa, không `repeat()`).
    _dieuKhien = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _tiLePhongTo = TweenSequence<double>([
      for (var i = 0; i < 8; i++) ...[
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
      ],
    ]).animate(CurvedAnimation(parent: _dieuKhien, curve: Curves.easeInOut));
    widget.soThe.addListener(_khiSoTheCoTheDoi);
  }

  void _khiSoTheCoTheDoi() {
    if (widget.soThe.value == _soHienTai) return;
    setState(() => _soHienTai = widget.soThe.value);
    _dieuKhien.forward(from: 0);
  }

  @override
  void dispose() {
    widget.soThe.removeListener(_khiSoTheCoTheDoi);
    _dieuKhien.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tiLePhongTo,
      builder: (context, _) => Transform.scale(
        scale: _tiLePhongTo.value,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(Ch.banGhiAmSoCoDauCach(ngonNguHienTai.value),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.coChu)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              color: Colors.cyanAccent,
              child: Text('$_soHienTai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.coChu)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal "Bảng điều khiển" của trình ghi âm — bảng 8 hàng (1 hàng "Tạm
/// dừng/Tiếp tục" dùng đúng phím tắt Ghi âm hiện tại + 7 hàng dùng phím số
/// 1-7 cố định), cộng 2 nút ghim góc dưới phải (Chuyển hoá/Tạm dừng-Tiếp
/// tục, để bấm nhanh không cần với tới bảng). Có bộ phím tắt CỤC BỘ riêng
/// (chỉ hoạt động khi modal này đang mở) — không đụng gì tới phím tắt
/// toàn cục của `_TrangSoanThaoState` (những cái đó đã tự im lặng khi có
/// modal khác đè lên, xem `_khiPhimTatMicro`/`_khiPhimTatGhiAm`/
/// `_khiHoanTatTapDoiPhimTat`).
class _BangDieuKhienGhiAm extends StatefulWidget {
  const _BangDieuKhienGhiAm({
    required this.soThe,
    required this.thoiLuong,
    required this.trangThaiGheDe,
    required this.songAmTick,
    required this.songAm,
    required this.dangTamDungBanDau,
    required this.phimTatGhiAm,
    required this.khiTamDung,
    required this.khiTiepTuc,
    required this.khiChuyenThanhVanBan,
    required this.khiTaoBanMoi,
    required this.khiPhatLai,
    required this.khiDong,
    required this.khiXoaVaDong,
    required this.khiCaiDatTuDongChuyenHoa,
    required this.khiCaiDatTuDongMoBang,
    required this.khiDoiViTri,
  });

  /// Số thẻ đang hiện ở đầu bảng ("Bản Ghi âm số N") — `ValueListenable`
  /// (không phải `int` cố định) để bảng điều khiển tự đổi số khi bấm
  /// "Hoàn thành-Tạo bản ghi âm mới" MÀ KHÔNG đóng bảng lại (yêu cầu: giữ
  /// bảng mở, chỉ đổi số + nhấp nháy — xem
  /// `_TrangSoanThaoState._soTheChoBangDieuKhien`).
  final ValueListenable<int> soThe;
  final ValueNotifier<Duration> thoiLuong;

  /// Đè nhãn "Đang chuyển #N"/"Đã chuyển xong #N" khi thẻ vừa chốt không
  /// còn ghi âm thật nữa — xem `_TrangSoanThaoState._nhanTrangThaiGhiAmGheDe`.
  final ValueNotifier<TrangThaiGheDe?> trangThaiGheDe;
  final ValueNotifier<int> songAmTick;
  final List<double> songAm;
  final bool dangTamDungBanDau;
  final LuaChonPhimTat phimTatGhiAm;

  final Future<void> Function() khiTamDung;
  final Future<void> Function() khiTiepTuc;
  final Future<void> Function() khiChuyenThanhVanBan;
  final Future<void> Function() khiTaoBanMoi;
  final Future<void> Function() khiPhatLai;
  final Future<void> Function() khiDong;
  final Future<void> Function() khiXoaVaDong;
  final Future<void> Function() khiCaiDatTuDongChuyenHoa;
  final Future<void> Function() khiCaiDatTuDongMoBang;

  /// "Phím 9 — Thay đổi vị trí của thẻ này", CHO THẺ ĐANG GHI — xem
  /// `_TrangSoanThaoState._batDauDoiViTriTheDangGhi`.
  final Future<void> Function() khiDoiViTri;

  @override
  State<_BangDieuKhienGhiAm> createState() => _BangDieuKhienGhiAmState();
}

class _BangDieuKhienGhiAmState extends State<_BangDieuKhienGhiAm> {
  late bool _dangTamDung = widget.dangTamDungBanDau;
  late final _theoDoiTapDoi = TheoDoiTapDoiPhim(khiTapDoi: _khiTapDoiCucBo);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_khiPhimCucBo);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_khiPhimCucBo);
    _theoDoiTapDoi.dispose();
    super.dispose();
  }

  void _khiTapDoiCucBo(String loai) {
    if (!mounted) return;
    if (widget.phimTatGhiAm.loai != loai) return;
    _bamTamDungTiepTuc();
  }

  bool _khopPhimTatGhiAmCucBo(KeyEvent event) {
    switch (widget.phimTatGhiAm.loai) {
      case 'tab':
        return event.logicalKey == LogicalKeyboardKey.tab &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            !HardwareKeyboard.instance.isShiftPressed &&
            !HardwareKeyboard.instance.isMetaPressed;
      case 'ctrl':
        return HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            event.logicalKey.keyLabel.toUpperCase() ==
                (widget.phimTatGhiAm.phim ?? '').toUpperCase();
      default:
        return false;
    }
  }

  static const _cacPhimSo = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  bool _khiPhimCucBo(KeyEvent event) {
    if (!mounted) return false;
    _theoDoiTapDoi.xuLy(event);
    if (event is! KeyDownEvent) return false;

    // Có màn hình khác đè lên bảng này (ví dụ hộp thoại "Sắp chạm giới hạn
    // 5 phút" — ừ thì 4 phút — hiện ra ngay trên nó) thì bỏ qua, không
    // giành phím Tab/1-8 của hộp thoại đó nữa — y hệt lý do `_khiPhimTatMicro`/
    // `_khiPhimTatGhiAm` ở `_TrangSoanThaoState` đã làm.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    if (_khopPhimTatGhiAmCucBo(event)) {
      _bamTamDungTiepTuc();
      return true;
    }

    final chiSoPhimSo = _cacPhimSo.indexOf(event.logicalKey);
    if (chiSoPhimSo >= 0) {
      _cacHanhDongPhimSo[chiSoPhimSo]();
      return true;
    }
    return false;
  }

  Future<void> _bamTamDungTiepTuc() async {
    if (_dangTamDung) {
      await widget.khiTiepTuc();
    } else {
      await widget.khiTamDung();
    }
    if (mounted) setState(() => _dangTamDung = !_dangTamDung);
  }

  Future<void> _dongRoiGoi(Future<void> Function() hanhDong) async {
    Navigator.of(context).pop();
    await hanhDong();
  }

  Future<void> _goiRoiDong(Future<void> Function() hanhDong) async {
    await hanhDong();
    if (mounted) Navigator.of(context).pop();
  }

  /// Cả phím 7 lẫn phím 8 đều trả lại ĐÚNG trạng thái trước đó khi đóng
  /// modal (khác trước đây, phím 7 từng luôn ép tiếp tục) — dùng biến cục
  /// bộ ghi lại NGAY TRƯỚC khi gọi, không dựa vào `widget.dangTamDungBanDau`
  /// (đã cũ, chụp tại lúc MỞ Bảng điều khiển, không phải lúc mở modal con).
  Future<void> _moCaiDatTuDongChuyenHoa() async {
    final truoc = _dangTamDung;
    setState(() => _dangTamDung = true);
    await widget.khiCaiDatTuDongChuyenHoa();
    if (mounted) setState(() => _dangTamDung = truoc);
  }

  Future<void> _moCaiDatTuDongMoBang() async {
    final truoc = _dangTamDung;
    setState(() => _dangTamDung = true);
    await widget.khiCaiDatTuDongMoBang();
    if (mounted) setState(() => _dangTamDung = truoc);
  }

  late final List<Future<void> Function()> _cacHanhDongPhimSo = [
    // (ý 5) KHÔNG còn bọc `_goiRoiDong` — `_hoanThanhChuyenThanhVanBan` giờ
    // tự đóng NGAY cả bảng này (nếu đang mở) VÀ AppBar trình ghi âm ở chính
    // nó (`_TrangSoanThaoState._dongBangDieuKhienGhiAmNeuMo`), không cần
    // đợi chốt/gửi AI xong mới đóng nữa — bọc thêm ở đây sẽ đóng "hụt" 2
    // lần hoặc đóng sai route.
    widget.khiChuyenThanhVanBan,
    // (ý 6) KHÔNG bọc gì cả — giữ bảng MỞ, chỉ số thẻ tự đổi (báo qua
    // `soThe`, xem `_DongBanGhiAmSoNhapNhay`), không đóng/mở lại bảng.
    widget.khiTaoBanMoi,
    () => _goiRoiDong(widget.khiPhatLai),
    () => _goiRoiDong(widget.khiDong),
    () => _dongRoiGoi(widget.khiXoaVaDong),
    () async => Navigator.of(context).pop(),
    _moCaiDatTuDongChuyenHoa,
    _moCaiDatTuDongMoBang,
    // Phím 9: đóng hẳn bảng này rồi mới vào chế độ "Thay đổi vị trí" — thẻ
    // đang ghi có thể vừa bị ép tạm dừng (`_batDauDoiViTriTheDangGhi`), và
    // chế độ đó cần toàn màn hình soạn thảo, không thể để bảng này che lên.
    () => _dongRoiGoi(widget.khiDoiViTri),
  ];

  Widget _oHang({
    required String nhanPhim,
    required IconData icon,
    required Color mau,
    required String nhan,
    required VoidCallback onBam,
    bool manHinhHep = false,
  }) {
    return InkWell(
      onTap: () {},
      onTapDown: (_) => onBam(),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDADCE0))),
        child: Row(
          children: [
            Container(
              width: manHinhHep ? 68 : 92,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              alignment: Alignment.center,
              color: const Color(0xFFE3F2FD),
              child: Text(
                nhanPhim,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: manHinhHep ? 11 : 12),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Row(
                  children: [
                    Icon(icon, color: mau, size: 17),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        nhan,
                        style: TextStyle(
                            color: mau, fontWeight: FontWeight.w600, fontSize: manHinhHep ? 12 : 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dòng 1 ("Bản Ghi âm số N") và dòng 2 (trạng thái/thời lượng) đứng
  /// CHUNG một cột full-width, mỗi dòng cao xấp xỉ các dòng phím 1-8 khác
  /// (cùng padding dọc 10). Vòng sóng âm KHÔNG nằm trong luồng bố cục của
  /// hai dòng đó — nó là một lớp `Positioned` riêng đè lên, canh giữa
  /// đúng ranh giới giữa dòng 1 và dòng 2 — nên dù kích cỡ vòng sóng âm
  /// lớn cỡ nào cũng không bao giờ làm hai dòng kia giãn cao ra.
  Widget _oKhoiTieuDeVaTrangThai(bool manHinhHep) {
    final duongVien = BoxDecoration(border: Border.all(color: const Color(0xFFDADCE0)));
    final choDot = manHinhHep ? 40.0 : 48.0;
    final coChu = manHinhHep ? 13.0 : 14.0;
    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              decoration: duongVien,
              padding: EdgeInsets.fromLTRB(choDot + 14, 10, 12, 10),
              child: _DongBanGhiAmSoNhapNhay(soThe: widget.soThe, coChu: coChu),
            ),
            Container(
              width: double.infinity,
              decoration: duongVien,
              padding: EdgeInsets.fromLTRB(choDot + 14, 10, 12, 10),
              // Đè nhãn "Đang chuyển #N"/"Đã chuyển xong #N" khi thẻ vừa
              // chốt không còn ghi âm thật nữa — y hệt `_oTrangThaiGhiAmLon`
              // ở AppBar, để bảng điều khiển (nếu còn mở lúc bấm "Hoàn
              // thành-Chuyển thành văn bản") cũng đổi chữ theo đúng thời
              // gian thực.
              child: ValueListenableBuilder<TrangThaiGheDe?>(
                valueListenable: widget.trangThaiGheDe,
                builder: (context, ghe, _) => ghe != null
                    ? Text(
                        Ch.trangThaiGheDe(ghe.loai, ghe.soThe, ngonNguHienTai.value),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: coChu,
                        ),
                      )
                    : ValueListenableBuilder<Duration>(
                        valueListenable: widget.thoiLuong,
                        // Cả dòng nhấp nháy khi sắp chạm hạn 60 giây — y hệt
                        // AppBar của trình ghi âm, xem `_NhapNhayGioiHanGhiAm`.
                        builder: (context, gia, _) => _NhapNhayGioiHanGhiAm(
                          // (YÊU CẦU MỚI — nhánh thử nghiệm) Tắt nhấp nháy
                          // hẳn trong lúc tạm dừng — xem giải thích ở
                          // `_oTrangThaiGhiAmLon`.
                          giay: _dangTamDung ? 0 : gia.inSeconds,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_dangTamDung ? 'Tạm dừng' : 'Đang Ghi âm'} ',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: coChu,
                                ),
                              ),
                              _SoPhutGiayGhiAm(
                                thoiLuong: gia,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: coChu,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: widget.songAmTick,
              builder: (context, _, __) => VongSongAm(
                muc: widget.songAm,
                dangNghe: !_dangTamDung,
                mau: Colors.red.shade600,
                kichThuoc: choDot,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _oTamDungTiepTucHang(bool manHinhHep) {
    return _dangTamDung
        ? _oHang(
            nhanPhim: widget.phimTatGhiAm.nhan,
            icon: Icons.play_circle_outline,
            mau: Colors.green.shade800,
            nhan: Ch.tiepTuc(ngonNguHienTai.value),
            onBam: _bamTamDungTiepTuc,
            manHinhHep: manHinhHep,
          )
        : _oHang(
            nhanPhim: widget.phimTatGhiAm.nhan,
            icon: Icons.pause_circle_outline,
            mau: Colors.red.shade800,
            nhan: Ch.tamDung(ngonNguHienTai.value),
            onBam: _bamTamDungTiepTuc,
            manHinhHep: manHinhHep,
          );
  }

  @override
  Widget build(BuildContext context) {
    final manHinhHep = MediaQuery.sizeOf(context).width < 420;

    Widget noiDung = Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _oKhoiTieuDeVaTrangThai(manHinhHep),
                      _oTamDungTiepTucHang(manHinhHep),
                      _oHang(
                        nhanPhim: 'phím 1',
                        icon: Icons.text_snippet_outlined,
                        mau: Colors.green.shade900,
                        nhan: Ch.hoanThanhVaChuyenHoaThanhVanBan(
                            ngonNguHienTai.value),
                        onBam: _cacHanhDongPhimSo[0],
                        manHinhHep: manHinhHep,
                      ),
                      _oHang(
                        nhanPhim: 'phím 2',
                        icon: Icons.add_circle_outline,
                        mau: Colors.cyan.shade900,
                        nhan: Ch.hoanThanhVaTaoBanGhiAmMoi(
                            ngonNguHienTai.value),
                        onBam: _cacHanhDongPhimSo[1],
                        manHinhHep: manHinhHep,
                      ),
                      _oHang(
                        nhanPhim: 'phím 3',
                        icon: Icons.play_arrow_rounded,
                        mau: Colors.green.shade900,
                        nhan: Ch.hoanThanhVaPhatDeNgheLai(
                            ngonNguHienTai.value),
                        onBam: _cacHanhDongPhimSo[2],
                        manHinhHep: manHinhHep,
                      ),
                      _oHang(
                        nhanPhim: 'phím 4',
                        icon: Icons.check_circle_outline,
                        mau: Colors.blue.shade900,
                        nhan: Ch.hoanThanhVaDongTrinhGhiAm(
                            ngonNguHienTai.value),
                        onBam: _cacHanhDongPhimSo[3],
                        manHinhHep: manHinhHep,
                      ),
                      // Nhãn đổi thành "Đóng trình ghi âm" khi không còn gì
                      // để xoá (thẻ vừa chốt đã chuyển hoá xong hẳn) — y hệt
                      // nút "Xoá bản này" ở AppBar (`_khongCoGiDeXoaTrongTrinhGhiAm`).
                      ValueListenableBuilder<TrangThaiGheDe?>(
                        valueListenable: widget.trangThaiGheDe,
                        builder: (context, ghe, _) => _oHang(
                          nhanPhim: 'phím 5',
                          icon: Icons.delete_outline,
                          mau: Colors.red.shade900,
                          nhan: ghe?.loai == LoaiTrangThaiGheDe.daChuyenXong
                              ? Ch.dongTrinhGhiAm(ngonNguHienTai.value)
                              : Ch.xoaBanNayVaDongTrinhGhiAm(ngonNguHienTai.value),
                          onBam: _cacHanhDongPhimSo[4],
                          manHinhHep: manHinhHep,
                        ),
                      ),
                      _oHang(
                        nhanPhim: 'phím 6',
                        icon: Icons.visibility_off_outlined,
                        mau: const Color(0xFF5F6368),
                        nhan: Ch.anBangDieuKhienTiepTucGhiAm(
                            ngonNguHienTai.value),
                        onBam: _cacHanhDongPhimSo[5],
                        manHinhHep: manHinhHep,
                      ),
                      _oHang(
                        nhanPhim: 'phím 7',
                        icon: Icons.cloud_sync,
                        mau: Colors.deepPurple,
                        nhan: Ch.caiDatCheDoTuDongChuyenHoaVanBan(
                            ngonNguHienTai.value),
                        onBam: _cacHanhDongPhimSo[6],
                        manHinhHep: manHinhHep,
                      ),
                      _oHang(
                        nhanPhim: 'phím 8',
                        icon: Icons.tune_rounded,
                        mau: Colors.brown.shade800,
                        nhan: Ch.caiDatTuDongMoBangDieuKhienNay(
                            ngonNguHienTai.value),
                        onBam: _cacHanhDongPhimSo[7],
                        manHinhHep: manHinhHep,
                      ),
                      _oHang(
                        nhanPhim: 'phím 9',
                        icon: Icons.drag_indicator,
                        mau: Colors.indigo.shade800,
                        nhan: Ch.thayDoiViTriTheNay(ngonNguHienTai.value),
                        onBam: _cacHanhDongPhimSo[8],
                        manHinhHep: manHinhHep,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Hai nút ghim — CÙNG LỚP với bảng (cùng Stack, không phải con của
        // Material bảng) nhưng ghim đáy/mép phải màn hình, để bấm nhanh
        // không cần với tay lên giữa màn hình. Logic bên trong y hệt hai
        // nút cùng tên trong bảng.
        Positioned(
          right: 12,
          bottom: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NutGhimBangDieuKhien(
                nhan: 'Chuyển hoá thành văn bản',
                icon: Icons.text_snippet_outlined,
                mau: Colors.green.shade900,
                onBam: _cacHanhDongPhimSo[0],
              ),
              const SizedBox(width: 8),
              _dangTamDung
                  ? _NutGhimBangDieuKhien(
                      nhan: Ch.tiepTuc(ngonNguHienTai.value),
                      icon: Icons.play_circle_outline,
                      mau: Colors.green.shade800,
                      onBam: _bamTamDungTiepTuc,
                    )
                  : _NutGhimBangDieuKhien(
                      nhan: Ch.tamDung(ngonNguHienTai.value),
                      icon: Icons.pause_circle_outline,
                      mau: Colors.red.shade800,
                      onBam: _bamTamDungTiepTuc,
                    ),
            ],
          ),
        ),
      ],
    );

    // Tab mặc định của Flutter còn tự làm việc riêng của nó: chuyển tiêu
    // điểm bàn phím qua các nút — chạy CÙNG LÚC với `_khiPhimCucBo` ở trên
    // (hai cơ chế độc lập, `HardwareKeyboard.addHandler` không chặn được
    // việc này). Chỉ khi Tab đang là phím tắt Ghi âm mới cần chặn hẳn tác
    // dụng "chuyển tiêu điểm" đó lại — nó chỉ gây rối mắt chứ không hỏng gì.
    if (widget.phimTatGhiAm.loai == 'tab') {
      noiDung = Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.tab): DoNothingAndStopPropagationIntent(),
          SingleActivator(LogicalKeyboardKey.tab, shift: true): DoNothingAndStopPropagationIntent(),
        },
        child: noiDung,
      );
    }
    return noiDung;
  }
}

/// Một trong hai nút ghim góc dưới phải của `_BangDieuKhienGhiAm`.
class _NutGhimBangDieuKhien extends StatelessWidget {
  const _NutGhimBangDieuKhien({
    required this.nhan,
    required this.icon,
    required this.mau,
    required this.onBam,
  });

  final String nhan;
  final IconData icon;
  final Color mau;
  final VoidCallback onBam;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {},
        onTapDown: (_) => onBam(),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: mau, size: 16),
              const SizedBox(width: 4),
              Text(nhan, style: TextStyle(color: mau, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút màu chữ/màu nền của thanh định dạng thủ công: bấm THẲNG vào nút áp
/// ngay màu "gần nhất" (giống hành vi phím tắt); bấm mũi tên nhỏ bên cạnh mở
/// lưới màu cơ bản để chọn màu khác — chọn xong màu đó vừa trở thành màu
/// "gần nhất" mới, vừa áp lên luôn.
class _NutMauDinhDang extends StatelessWidget {
  const _NutMauDinhDang({
    required this.nhan,
    required this.bat,
    required this.mauHienThi,
    required this.khiBam,
    required this.khiChonMau,
    required this.choPhepTrongSuot,
    this.laMauNen = false,
  });

  final String nhan;
  final bool bat;
  final Color mauHienThi;
  final VoidCallback khiBam;
  final ValueChanged<Color> khiChonMau;
  final bool choPhepTrongSuot;
  final bool laMauNen;

  static const List<Color> _bangMauCoBan = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.black,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bat ? const Color(0xFFE3F2FD) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 20,
            tooltip: nhan,
            onPressed: khiBam,
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                laMauNen
                    ? const Icon(Icons.highlight, size: 16)
                    : const Text('A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1)),
                Container(width: 16, height: 3, color: mauHienThi),
              ],
            ),
          ),
          IconButton(
            iconSize: 18,
            tooltip: Ch.chonMauKhac(ngonNguHienTai.value),
            icon: const Icon(Icons.arrow_drop_down),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                // (YÊU CẦU MỚI) Bỏ nút "Đóng" ở `actions` — thay bằng nút X
                // đỏ gọn gàng ở góc trên bên phải.
                title: Row(
                  children: [
                    Expanded(child: Text(Ch.chonMau(ngonNguHienTai.value))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: Ch.dong(ngonNguHienTai.value),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                content: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in _bangMauCoBan)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(dialogCtx).pop();
                          khiChonMau(m);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: m,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBDBDBD)),
                          ),
                        ),
                      ),
                    if (choPhepTrongSuot)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(dialogCtx).pop();
                          khiChonMau(Colors.transparent);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBDBDBD)),
                          ),
                          // Hoạ tiết gạch chéo biểu thị "Trong suốt".
                          child: CustomPaint(painter: _VeOTrongSuot()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vẽ một đường chéo đỏ trong ô tròn — biểu thị lựa chọn "Trong suốt" (không
/// màu) ở bảng chọn màu nền.
class _VeOTrongSuot extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ve = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(2, size.height - 2), Offset(size.width - 2, 2), ve);
  }

  @override
  bool shouldRepaint(covariant _VeOTrongSuot cu) => false;
}

/// Một điểm mốc trong lịch sử Lùi lại/Tiến tới — chữ, vị trí con trỏ, và mọi
/// đề xuất AI (chính tả, không phù hợp, cần xoá) còn đang hiển thị/chờ quyết
/// định tại thời điểm đó.
class _TrangThaiVanBan {
  const _TrangThaiVanBan({
    required this.vanBan,
    required this.viTriConTro,
    required this.loi,
    required this.khongPhuHop,
    required this.canXoa,
    required this.dinhDang,
  });

  final String vanBan;
  final int viTriConTro;
  final List<LoiChinhTa> loi;
  final List<_MocVungKhongPhuHop> khongPhuHop;
  final List<_MocVungCanXoa> canXoa;

  /// Định dạng thủ công (mục 5) — mỗi mốc lịch sử chụp luôn cả danh sách
  /// này, giống hệt cách nó đã chụp `loi`/`khongPhuHop`/`canXoa`, để
  /// Lùi/Tiến hoàn tác/làm lại được cả thao tác áp/bỏ định dạng, không chỉ
  /// thao tác gõ chữ.
  final List<_VungDinhDangThuCong> dinhDang;
}

/// Bản chụp "phẳng" của [_VungKhongPhuHop] — chỉ giữ vị trí, không giữ trạng
/// thái nhấp nháy hay hẹn giờ (những thứ đó thuộc về một lần hiển thị cụ
/// thể, không phải một phần của "dữ liệu" cần khôi phục).
class _MocVungKhongPhuHop {
  const _MocVungKhongPhuHop({
    required this.batDauGoc,
    required this.ketThucGoc,
    required this.batDauDeXuat,
    required this.ketThucDeXuat,
  });

  final int batDauGoc;
  final int ketThucGoc;
  final int batDauDeXuat;
  final int ketThucDeXuat;
}

/// Bản chụp "phẳng" của [_VungCanXoa].
class _MocVungCanXoa {
  const _MocVungCanXoa({required this.batDau, required this.ketThuc});

  final int batDau;
  final int ketThuc;
}

/// (YÊU CẦU MỚI — nhánh thử nghiệm) Modal lịch sử "Bộ nhớ tạm để dán văn
/// bản" — 10 dòng (xem `BoNhoTamDanVanBan`), mỗi dòng có "phím N" bên
/// trái (giống đúng khuôn các hàng trong bảng điều khiển ghi âm). Bấm vào
/// dòng/chip HOẶC gõ đúng phím số 1-9/0 trên bàn phím rời thì dán — xem
/// [khiChonDong]. Dòng trống (chưa có lịch sử) không bấm/gõ được gì.
class _HopThoaiLichSuBoNhoTam extends StatefulWidget {
  const _HopThoaiLichSuBoNhoTam({required this.khiChonDong, required this.caiDat});

  final void Function(int chiSo) khiChonDong;
  final CaiDat caiDat;

  @override
  State<_HopThoaiLichSuBoNhoTam> createState() => _HopThoaiLichSuBoNhoTamState();
}

class _HopThoaiLichSuBoNhoTamState extends State<_HopThoaiLichSuBoNhoTam> {
  // KHÔNG được `const` — `LogicalKeyboardKey` không có "primitive equality"
  // (so sánh qua `==`/`hashCode` ghi đè, không phải định danh identity),
  // nên dùng làm khoá trong một Map CONST làm trình biên dịch dart2js báo
  // lỗi "does not have a primitive equality" lúc build Web (`static final`
  // vẫn tạo map đúng một lần như const, chỉ không ép hằng số lúc biên dịch).
  static final _phimSo = {
    LogicalKeyboardKey.digit1: 0,
    LogicalKeyboardKey.digit2: 1,
    LogicalKeyboardKey.digit3: 2,
    LogicalKeyboardKey.digit4: 3,
    LogicalKeyboardKey.digit5: 4,
    LogicalKeyboardKey.digit6: 5,
    LogicalKeyboardKey.digit7: 6,
    LogicalKeyboardKey.digit8: 7,
    LogicalKeyboardKey.digit9: 8,
    LogicalKeyboardKey.digit0: 9,
    LogicalKeyboardKey.numpad1: 0,
    LogicalKeyboardKey.numpad2: 1,
    LogicalKeyboardKey.numpad3: 2,
    LogicalKeyboardKey.numpad4: 3,
    LogicalKeyboardKey.numpad5: 4,
    LogicalKeyboardKey.numpad6: 5,
    LogicalKeyboardKey.numpad7: 6,
    LogicalKeyboardKey.numpad8: 7,
    LogicalKeyboardKey.numpad9: 8,
    LogicalKeyboardKey.numpad0: 9,
  };

  bool _khiPhim(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // (YÊU CẦU MỚI) Modal "Cài đặt Bộ nhớ tạm để dán văn bản" (mở từ nút
    // "Cài đặt" ngay trong bảng này) đứng TRÊN bảng này — nếu không chặn,
    // gõ phím số trong lúc đang ở modal cài đặt vẫn lọt xuống đây, tự dán
    // một dòng + đóng cả hai modal, dù người dùng chỉ đang gõ vào modal
    // cài đặt. `ModalRoute.of(context)?.isCurrent` là `false` ngay khi có
    // route khác đè lên trên — đúng tín hiệu cần để tự khoá, không cần cờ
    // riêng.
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    final i = _phimSo[event.logicalKey];
    if (i == null) return false;
    if (BoNhoTamDanVanBan.lichSu[i] == null) return true;
    widget.khiChonDong(i);
    return true;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_khiPhim);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_khiPhim);
    super.dispose();
  }

  /// (YÊU CẦU MỚI) Modal hướng dẫn riêng, rộng hơn nên viết đầy đủ/dễ
  /// hiểu hơn bản chú thích ngắn cũ — giải thích đúng mọi logic đang có:
  /// cách dán, cách lịch sử tự ghi/đè, ý nghĩa 2 màu nền đỏ/vàng, cơ chế
  /// ghim, và giới hạn 10.000 ký tự âm thầm.
  void _moHuongDanBoNhoTam() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        // (YÊU CẦU MỚI) Bỏ nút "Đóng" ở dưới cùng — thay bằng nút X đỏ gọn
        // gàng ở góc trên bên phải, y hệt kiểu `_tieuDeVaNutDong` đã dùng ở
        // `modal_thong_tin_muc.dart`.
        title: Row(
          children: [
            Expanded(child: Text(Ch.huongDanBoNhoTam(ngonNguHienTai.value))),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: Ch.dong(ngonNguHienTai.value),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Ch.ghiChuBoNhoTamDan1(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuBoNhoTamDan2(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuBoNhoTamDan3(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuBoNhoTamDan4(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuBoNhoTamDan5(ngonNguHienTai.value)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// (YÊU CẦU MỚI) Bấm nút 📖 ở dòng [i] — vượt quá 1000 ký tự (giới hạn
  /// của một dòng Từ điển nhập liệu nhanh, `CaiDat.gioiHanTuDienNhapLieuNhanh`)
  /// thì chỉ báo nhanh giữa màn hình, không mở modal. Hợp lệ thì mở modal
  /// "Thêm nhanh vào từ điển nhập liệu nhanh" (`_HopThoaiThemNhanhTuDien`) —
  /// modal đó đứng TRÊN bảng này nên `_khiPhim` ở trên (đọc
  /// `ModalRoute.isCurrent`) tự ngăn phím số của bảng này kích hoạt trong
  /// lúc đang mở, không cần cờ riêng.
  void _bamThemNhanhVaoTuDien(int i) {
    final doan = BoNhoTamDanVanBan.lichSu[i];
    if (doan == null) return;
    if (doan.length > CaiDat.gioiHanTuDienNhapLieuNhanh) {
      hienThongBaoGiua(
        context,
        Ch.khongTheThemVaoTuDienNhapLieuNhanhVuotQua1000(ngonNguHienTai.value),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _HopThoaiThemNhanhTuDien(
        doanNguon: doan,
        goiDinhDangNguon: BoNhoTamDanVanBan.dinhDang[i],
        caiDat: widget.caiDat,
        nguon: _NguonTuDienNhanh.hienHanh(widget.caiDat),
      ),
    );
  }

  Widget _dong(int i) {
    final doan = BoNhoTamDanVanBan.lichSu[i];
    final rong = doan == null;
    // (YÊU CẦU MỚI) Chỉ là lỗi HIỂN THỊ — đoạn CÓ dấu xuống dòng thật vẫn
    // được dán đầy đủ, nguyên văn, không đổi gì; đây chỉ đổi dấu xuống
    // dòng thành dấu cách NGAY TRÊN MÀN HÌNH để một dòng ngang (không tự
    // xuống dòng, có `...` ở cuối nếu dài) hiện được nhiều chữ hơn.
    final doanHienThi = doan?.replaceAll('\n', ' ');
    final dangGhim = BoNhoTamDanVanBan.ghim[i];
    // (YÊU CẦU MỚI — nhánh thử nghiệm) Chỉ khi ĐỦ 10 dòng (không ô nào
    // trống) mới có khái niệm "cũ nhất"/"gần cũ nhất" — và chỉ xét trong
    // các dòng CHƯA ghim (`oCuNhat`/`oGanCuNhat` đã tự loại dòng ghim ra
    // rồi, không cần kiểm `!dangGhim` thêm ở đây).
    final day = BoNhoTamDanVanBan.day;
    final laCuNhat = day && i == BoNhoTamDanVanBan.oCuNhat;
    final laGanCuNhat = day && i == BoNhoTamDanVanBan.oGanCuNhat;
    // (YÊU CẦU MỚI) Dòng VỪA được thêm vào bộ nhớ tạm gần đây nhất — nền
    // xanh dương nhạt. Tính lại ngay trong `_dong()` (gọi mỗi lần build
    // danh sách) nên tự cập nhật đồng bộ mỗi khi ghim/bỏ ghim một dòng,
    // giống `laCuNhat`/`laGanCuNhat`, không phải trạng thái "đóng băng".
    final laVuaThem = !rong && i == BoNhoTamDanVanBan.oVuaThem;

    // (YÊU CẦU MỚI) Dòng đang ghim: nền xanh lá, chuyển sắc TỪ TRÁI (đậm
    // vừa, không đậm quá) SANG PHẢI — nửa đầu dòng giữ nguyên màu đậm,
    // nửa sau nhạt dần tới hết (không còn xanh) ở sát mép phải.
    final BoxDecoration trangTri;
    if (dangGhim) {
      trangTri = const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.5, 1.0],
          colors: [Color(0xFF81C995), Color(0xFF81C995), Colors.transparent],
        ),
      );
    } else {
      trangTri = BoxDecoration(
        color: laCuNhat
            ? const Color(0xFFFCE8E6)
            : (laGanCuNhat
                ? const Color(0xFFFEF7E0)
                : (laVuaThem ? const Color(0xFFE8F0FE) : null)),
      );
    }

    // (YÊU CẦU MỚI) Màn hẹp: bỏ hẳn khung vuông quanh số — chỉ còn đúng con
    // số, sát mép trái, nhường tối đa chỗ ngang cho đoạn văn bản bên phải.
    // Màn rộng giữ nguyên khung "phím N" như cũ.
    final manHinhHep = MediaQuery.sizeOf(context).width < _TrangSoanThaoState._nguongManHinhHep;
    final oSoThuTu = manHinhHep
        ? Text(
            '${(i + 1) % 10}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: rong ? const Color(0xFF9AA0A6) : const Color(0xFF1A73E8),
            ),
          )
        : Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: rong ? const Color(0xFFF1F3F4) : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              BoNhoTamDanVanBan.nhanPhim(i),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rong ? const Color(0xFF9AA0A6) : const Color(0xFF1A73E8),
              ),
            ),
          );

    return Container(
      decoration: trangTri,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: rong ? null : () => widget.khiChonDong(i),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: manHinhHep ? 2 : 4),
                child: Row(
                  children: [
                    oSoThuTu,
                    SizedBox(width: manHinhHep ? 4 : 10),
                    Expanded(
                      child: Text(
                        doanHienThi ?? Ch.trongNgoacDon(ngonNguHienTai.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: rong ? const Color(0xFF9AA0A6) : null,
                          fontStyle: rong ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // (YÊU CẦU MỚI) Nút ghim — riêng biệt với vùng bấm-để-dán ở trên
          // (`Expanded` + `InkWell` riêng), để bấm ghim không lỡ dán luôn.
          // Icon Material cho pin (`Icons.push_pin`) — dùng emoji 📌 thay
          // vì vài icon Material mới từng bị "tree-shake" mất trên bản
          // dựng thật (xem lỗi icon 📋 vừa sửa) — né hẳn rủi ro đó. "Sáng
          // lên" khi đang ghim thể hiện bằng khung tròn nền xanh lá đậm
          // sau icon, mờ đi khi chưa ghim hoặc dòng trống.
          IconButton(
            onPressed: rong ? null : () => setState(() => BoNhoTamDanVanBan.doiGhim(i)),
            icon: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dangGhim ? const Color(0xFF1E8E3E) : Colors.transparent,
              ),
              child: Opacity(
                opacity: rong ? 0.3 : (dangGhim ? 1.0 : 0.55),
                child: const Text('📌', style: TextStyle(fontSize: 14)),
              ),
            ),
            tooltip: dangGhim
                ? Ch.boGhimChoPhepLichSuMoiDeLenLai(ngonNguHienTai.value)
                : Ch.ghimDongNayKhongBaoGioBiThayThe(ngonNguHienTai.value),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          // (YÊU CẦU MỚI) Nút "Thêm nhanh vào từ điển nhập liệu nhanh" —
          // THAY cho nút sao chép cũ (đã bỏ hẳn, kể cả logic riêng của nó).
          // Icon 📖 y hệt nút mở "Từ điển nhập liệu nhanh" ở thanh công cụ.
          // Luôn là nút CUỐI trong `Row` nên tự sát mép phải modal.
          IconButton(
            onPressed: rong ? null : () => _bamThemNhanhVaoTuDien(i),
            icon: Opacity(
              opacity: rong ? 0.35 : 1.0,
              child: const Text('📖', style: TextStyle(fontSize: 16)),
            ),
            tooltip: Ch.themNhanhVaoTuDien(ngonNguHienTai.value),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manHinhHepBeNgang =
        MediaQuery.sizeOf(context).width < _TrangSoanThaoState._nguongManHinhHep;
    return AlertDialog(
      // (SỬA LỖI — nhánh thử nghiệm) Bỏ nút "Đóng" ở `actions` — thay bằng
      // nút X đỏ cố định ở góc trên-phải, qua `title` dạng `Row` (AlertDialog
      // không có tham số riêng cho việc này).
      title: Row(
        children: [
          Expanded(child: Text(Ch.boNhoTamDeDanVanBan(ngonNguHienTai.value))),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: Ch.dong(ngonNguHienTai.value),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      // (SỬA LỖI — "màn hình hẹp chiều cao vẫn chưa cuộn được để thấy đủ
      // 10 dòng") Trước đây chỉ bọc riêng 10 dòng trong một
      // `ConstrainedBox(maxHeight: 420)` + `SingleChildScrollView` — nhưng
      // `AlertDialog` (mặc định `scrollable: false`) không tự co giãn/cuộn
      // theo chiều cao MÀN HÌNH THẬT: nếu tổng chiều cao tiêu đề + 2 nút +
      // khung 420 đó vượt quá khung mà hệ thống dành cho dialog trên một
      // màn hẹp chiều cao, phần vượt bị CẮT từ ngoài `AlertDialog`, trước
      // khi cuộn nội bộ của khung 420 kịp có tác dụng — y hệt cách
      // `_BangDieuKhienGhiAm` (bảng điều khiển trình ghi âm) đang làm:
      // `scrollable: true` gộp TITLE + CONTENT vào đúng MỘT
      // `SingleChildScrollView` do chính `AlertDialog` tự quản, luôn cuộn
      // được bất kể màn hình cao hay thấp. Bỏ hẳn `ConstrainedBox` cố định
      // 420 cũ — lồng 2 `SingleChildScrollView` vào nhau dễ sinh cử chỉ
      // cuộn chồng chéo, không cần thiết khi đã có đúng một lớp cuộn ngoài.
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (YÊU CẦU MỚI) Thay chú thích rải ở đây bằng 2 nút: mở modal
            // hướng dẫn riêng (xem `_moHuongDanBoNhoTam`), và mở thẳng modal
            // cài đặt (công tắc bật/tắt + phím tắt) — y hệt đường vào từ
            // menu "Tài khoản và Cài đặt" → "Cài đặt Bộ nhớ tạm để dán văn
            // bản".
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: _moHuongDanBoNhoTam,
                  icon: const Icon(Icons.help_outline, size: 18),
                  // (YÊU CẦU MỚI) Màn hẹp bề ngang: rút gọn còn "Hướng dẫn"
                  // (vẫn giữ icon) — màn rộng giữ nguyên tên đầy đủ.
                  label: Text(manHinhHepBeNgang ? Ch.nutHuongDan(ngonNguHienTai.value) : Ch.nutHuongDanDayDu(ngonNguHienTai.value)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                ),
                TextButton.icon(
                  onPressed: () => moModalBoNhoTam(context, widget.caiDat),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(Ch.caiDat(ngonNguHienTai.value)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              children: [
                for (var i = 0; i < BoNhoTamDanVanBan.lichSu.length; i++) _dong(i),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// (YÊU CẦU MỚI) Bảng 26 dòng của "Từ điển nhập liệu nhanh" — y hệt khuôn
/// `_HopThoaiLichSuBoNhoTam` (nút Hướng dẫn/Cài đặt, `scrollable: true`,
/// tự cuộn trên màn hẹp), khác ở: 26 dòng cố định A-Z (không ghim), nhãn
/// "Phím X" ở BÊN PHẢI mỗi dòng (không phải bên trái), phím tắt dán là CHỮ
/// CÁI thay vì phím số, và có 3 TAB (Gần đây/theo hàng phím/A→Z — xem
/// `_tabThuTu`) với lịch sử "gần đây" lưu LÂU DÀI (`CaiDat.ganDayTuDienNhapLieuNhanh`).
/// (YÊU CẦU MỚI — 2 bộ nhớ từ điển) Trỏ tới ĐÚNG MỘT trong hai bộ nhớ của
/// "Từ điển nhập liệu nhanh" — bộ nhớ nào đang BẬT (loại trừ nhau, xem
/// `CaiDat.tuDienNhapLieuNhanhBat`/`TuDienNhapLieuNhanhDamMay.bat`) — để các
/// hộp thoại dùng 26 dòng này (dán vào vị trí con trỏ, lưu nhanh vùng chọn
/// vào dòng trống) luôn đọc/ghi đúng bộ đang bật, không viết chết bộ Nội bộ.
/// Cả hai cùng tắt thì rơi về Nội bộ (các nơi mở những hộp thoại này đã tự
/// kiểm `tuDienNhapLieuNhanhBat` trước, nên trường hợp đó không thực sự xảy
/// ra ở đây — giữ Nội bộ chỉ để luôn có một giá trị an toàn, không `null`).
class _NguonTuDienNhanh {
  _NguonTuDienNhanh._(this._caiDat, this._damMay);

  factory _NguonTuDienNhanh.hienHanh(CaiDat caiDat) {
    final damMay = TuDienNhapLieuNhanhDamMay.dungChung;
    if (!caiDat.tuDienNhapLieuNhanhBat && damMay != null && damMay.bat) {
      return _NguonTuDienNhanh._(caiDat, damMay);
    }
    return _NguonTuDienNhanh._(caiDat, null);
  }

  final CaiDat _caiDat;
  final TuDienNhapLieuNhanhDamMay? _damMay;

  String dong(int i) => _damMay?.dong[i] ?? _caiDat.tuDienNhapLieuNhanh[i];

  List<VungDinhDangDoanVan> dinhDang(int i) {
    final raw = _damMay != null ? _damMay!.dinhDang[i] : _caiDat.dinhDangTuDienNhapLieuNhanh[i];
    if (raw == null) return const [];
    try {
      final ds = jsonDecode(raw);
      if (ds is! List) return const [];
      final doDai = dong(i).length;
      return ds
          .map((j) => VungDinhDangDoanVan.tuJson(j, doDai))
          .whereType<VungDinhDangDoanVan>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> ghiDong(int i, String gia) async {
    if (_damMay != null) {
      await _damMay!.ghiDong(i, gia);
    } else {
      _caiDat.tuDienNhapLieuNhanh[i] = gia;
      await _caiDat.luuTuDienNhapLieuNhanh();
    }
  }

  Future<void> ghiDinhDang(int i, List<VungDinhDangDoanVan> vung) async {
    final goi = vung.isEmpty ? null : jsonEncode(vung.map((v) => v.toJson()).toList());
    if (_damMay != null) {
      await _damMay!.ghiDinhDang(i, goi);
    } else {
      await _caiDat.datDinhDangTuDienNhapLieuNhanh(i, goi);
    }
  }
}

class _HopThoaiTuDienNhapLieuNhanh extends StatefulWidget {
  const _HopThoaiTuDienNhapLieuNhanh({
    required this.khiChonDong,
    required this.caiDat,
    required this.nguon,
  });

  final void Function(int chiSo) khiChonDong;
  final CaiDat caiDat;
  final _NguonTuDienNhanh nguon;

  @override
  State<_HopThoaiTuDienNhapLieuNhanh> createState() => _HopThoaiTuDienNhapLieuNhanhState();
}

/// Ba tab, đúng thứ tự hiển thị trái→phải và cũng là thứ tự dùng cho phím
/// mũi tên trái/phải di chuyển giữa các tab.
const _tabThuTu = ['ganDay', 'hang', 'bangChuCai'];

class _HopThoaiTuDienNhapLieuNhanhState extends State<_HopThoaiTuDienNhapLieuNhanh> {
  // KHÔNG được `const` — xem giải thích ở `_HopThoaiLichSuBoNhoTamState._phimSo`.
  static final _phimChu = {
    for (var i = 0; i < 26; i++)
      LogicalKeyboardKey(LogicalKeyboardKey.keyA.keyId + i): i,
  };

  /// Tab đang mở — khởi tạo từ lựa chọn gần nhất đã lưu lâu dài
  /// (`CaiDat.tabTuDienNhapLieuNhanh`), xem `_doiTab`.
  late String _tab;

  /// Điều khiển cuộn của khung 26 dòng — để phím mũi tên lên/xuống và phím
  /// cách tự cuộn lên đầu/xuống cuối (xem `_khiPhim`), bên cạnh vuốt tay/
  /// lăn chuột/kéo thanh cuộn vẫn hoạt động bình thường qua `Scrollbar` +
  /// `SingleChildScrollView` dưới đây.
  final _cuonController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tab = _tabThuTu.contains(widget.caiDat.tabTuDienNhapLieuNhanh)
        ? widget.caiDat.tabTuDienNhapLieuNhanh
        : 'hang';
    HardwareKeyboard.instance.addHandler(_khiPhim);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_khiPhim);
    _cuonController.dispose();
    super.dispose();
  }

  void _doiTab(String t) {
    if (_tab == t) return;
    setState(() => _tab = t);
    widget.caiDat.datTabTuDienNhapLieuNhanh(t);
  }

  void _doiTabTheoHuong(int delta) {
    final vtMoi = (_tabThuTu.indexOf(_tab) + delta).clamp(0, _tabThuTu.length - 1);
    _doiTab(_tabThuTu[vtMoi]);
  }

  void _cuonLenTrenCung() {
    if (!_cuonController.hasClients) return;
    _cuonController.animateTo(0,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _cuonXuongDuoiCung() {
    if (!_cuonController.hasClients) return;
    _cuonController.animateTo(
      _cuonController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// (YÊU CẦU MỚI) Phím cách — cuộn xuống cuối nếu chưa ở cuối, hoặc cuộn
  /// lên đầu nếu đã ở cuối rồi (bấm lần nữa).
  void _cuonTheoPhimCach() {
    if (!_cuonController.hasClients) return;
    final oDuoiCung =
        _cuonController.offset >= _cuonController.position.maxScrollExtent - 2;
    oDuoiCung ? _cuonLenTrenCung() : _cuonXuongDuoiCung();
  }

  /// (YÊU CẦU MỚI) Khác `_HopThoaiLichSuBoNhoTamState._khiPhim` — dòng
  /// TRỐNG vẫn phải ẨN bảng đi (chỉ là không dán gì), không giữ bảng mở lại
  /// như Bộ nhớ tạm. Luôn gọi `widget.khiChonDong`, hàm đó tự biết bỏ qua
  /// việc dán nếu dòng rỗng — xem `_moHopThoaiTuDienNhapLieuNhanh`. Cũng
  /// bắt thêm phím 1/2/3 (đổi tab), mũi tên trái/phải (đổi tab), mũi tên
  /// lên/xuống (cuộn lên đầu/xuống cuối) và phím cách (cuộn xen kẽ).
  bool _khiPhim(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // (YÊU CẦU MỚI) Xem giải thích ở `_HopThoaiLichSuBoNhoTamState._khiPhim`
    // — cùng lý do: modal "Cài đặt Từ điển nhập liệu nhanh" đè lên trên thì
    // phải khoá hẳn các phím tắt ở đây, không cho lọt xuống dán/đổi tab nhầm.
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final phim = event.logicalKey;
    if (phim == LogicalKeyboardKey.digit1 || phim == LogicalKeyboardKey.numpad1) {
      _doiTab('ganDay');
      return true;
    }
    if (phim == LogicalKeyboardKey.digit2 || phim == LogicalKeyboardKey.numpad2) {
      _doiTab('hang');
      return true;
    }
    if (phim == LogicalKeyboardKey.digit3 || phim == LogicalKeyboardKey.numpad3) {
      _doiTab('bangChuCai');
      return true;
    }
    if (phim == LogicalKeyboardKey.arrowLeft) {
      _doiTabTheoHuong(-1);
      return true;
    }
    if (phim == LogicalKeyboardKey.arrowRight) {
      _doiTabTheoHuong(1);
      return true;
    }
    if (phim == LogicalKeyboardKey.arrowUp) {
      _cuonLenTrenCung();
      return true;
    }
    if (phim == LogicalKeyboardKey.arrowDown) {
      _cuonXuongDuoiCung();
      return true;
    }
    if (phim == LogicalKeyboardKey.space) {
      _cuonTheoPhimCach();
      return true;
    }

    final i = _phimChu[phim];
    if (i == null) return false;
    widget.khiChonDong(i);
    return true;
  }

  /// (YÊU CẦU MỚI) Hướng dẫn đầy đủ cách dùng Từ điển nhập liệu nhanh —
  /// cùng khuôn `_moHuongDanBoNhoTam` (danh sách bullet ngắn, dễ quét mắt).
  void _moHuongDan() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(Ch.huongDanTuDienNhapLieuNhanh(ngonNguHienTai.value))),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: Ch.dong(ngonNguHienTai.value),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Ch.tuDienNayLuuTaiBoNhoLauDaiCuaApp(ngonNguHienTai.value),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(Ch.ghiChuTuDienNhapLieu1(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuTuDienNhapLieu2(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuTuDienNhapLieu3(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuTuDienNhapLieu4(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuTuDienNhapLieu5(ngonNguHienTai.value)),
                const SizedBox(height: 8),
                Text(Ch.ghiChuTuDienNhapLieu6(ngonNguHienTai.value)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Danh sách chỉ số (0-25) đúng thứ tự hiển thị của tab đang mở — "Gần
  /// đây" chỉ gồm các chỉ số ĐÃ có lịch sử (có thể ít hơn 10), sắp xếp theo
  /// ĐÚNG lựa chọn "Chọn thứ tự giữa các phím tắt chữ cái" trong cài đặt;
  /// hai tab còn lại luôn đủ 26, cố định theo tên tab (không phụ thuộc cài
  /// đặt đó).
  List<int> _chiSoTheoTab() {
    if (_tab == 'ganDay') {
      final ds = List<int>.from(widget.caiDat.ganDayTuDienNhapLieuNhanh);
      final thuTu =
          thuTuTuDienNhapLieuNhanhTheoKieu(widget.caiDat.thuTuTuDienNhapLieuNhanh);
      ds.sort((a, b) => thuTu.indexOf(a).compareTo(thuTu.indexOf(b)));
      return ds;
    }
    return thuTuTuDienNhapLieuNhanhTheoKieu(_tab);
  }

  String get _chuThichTab => switch (_tab) {
        'ganDay' => Ch.chuThichTabGanDayTuDien(ngonNguHienTai.value),
        'hang' => Ch.chuThichTabHangTuDien(ngonNguHienTai.value),
        _ => Ch.chuThichTabAZTuDien(ngonNguHienTai.value),
      };

  /// (YÊU CẦU MỚI) Màu chữ của dòng chú thích — riêng cho từng tab, để dễ
  /// phân biệt đang ở tab nào chỉ bằng màu chữ.
  Color get _mauChuThichTab => switch (_tab) {
        'ganDay' => const Color(0xFF137333), // xanh lá đậm
        'hang' => const Color(0xFFB06000), // cam đậm
        _ => const Color(0xFF8430CE), // tím đậm
      };

  /// Một trong 3 nút-tab sát cạnh nhau, không khoảng hở, góc vuông (không
  /// bo góc) — sáng (nền xanh, chữ trắng) khi đang được chọn.
  Widget _nutTab(String id, String nhanRong, String nhanHep, bool hep) {
    final dangChon = _tab == id;
    return Expanded(
      child: InkWell(
        onTap: () => _doiTab(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          color: dangChon ? const Color(0xFF1A73E8) : const Color(0xFFF1F3F4),
          alignment: Alignment.center,
          child: Text(
            hep ? nhanHep : nhanRong,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dangChon ? Colors.white : const Color(0xFF5F6368),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dong(int i) {
    final chuCai = chuCaiTuDienNhapLieuNhanh(i);
    final doan = widget.nguon.dong(i);
    final rong = doan.trim().isEmpty;
    // (YÊU CẦU MỚI) Cùng lý do hiển thị với `_HopThoaiLichSuBoNhoTamState._dong`
    // — đổi dấu xuống dòng thật thành dấu cách CHỈ trên màn hình.
    final doanHienThi = doan.replaceAll('\n', ' ');
    final manHinhHep = MediaQuery.sizeOf(context).width < _TrangSoanThaoState._nguongManHinhHep;
    // (YÊU CẦU MỚI) Tô nền phủ cả dòng nếu dòng này nằm trong lịch sử dán
    // gần nhất (lưu lâu dài) — 5 lần gần nhất xanh đậm, 5 lần kế tiếp xanh
    // nhạt hơn — áp dụng ở CẢ BA tab, không riêng tab "Gần đây".
    final doMoi = widget.caiDat.doMoiTuDienNhapLieuNhanh(i);
    final mauNen = doMoi == null
        ? null
        : (doMoi < 5 ? const Color(0xFF81C995) : const Color(0xFFCEEAD6));
    return Container(
      color: mauNen,
      child: InkWell(
        onTap: rong ? null : () => widget.khiChonDong(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rong ? Ch.trongNgoacDon(ngonNguHienTai.value) : doanHienThi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: rong ? const Color(0xFF9AA0A6) : null,
                    fontStyle: rong ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              SizedBox(width: manHinhHep ? 4 : 10),
              // (YÊU CẦU MỚI) Nhãn ở BÊN PHẢI — ngược vị trí so với Bộ nhớ
              // tạm (bên trái), không khung/nền quanh nó, màu theo hàng phím
              // + gạch chân nếu thuộc nửa phải bàn phím (xem
              // `mau_phim_tu_dien_nhap_lieu_nhanh.dart`) — LUÔN tô màu/gạch
              // chân đúng theo [i], KỂ CẢ khi dòng trống (không còn liệt
              // xám như trước) — áp dụng cả khi rút gọn còn một chữ cái ở
              // màn hẹp.
              Text(
                manHinhHep ? chuCai : Ch.phimChuCai(ngonNguHienTai.value, chuCai),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mauChuPhimTuDienNhapLieuNhanh(i),
                  decoration: ganChanPhimTuDienNhapLieuNhanh(i)
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationThickness: doDayGachChanTuDienNhapLieuNhanh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manHinhHepBeNgang =
        MediaQuery.sizeOf(context).width < _TrangSoanThaoState._nguongManHinhHep;
    final ds = _chiSoTheoTab();
    // (YÊU CẦU MỚI) Chiều cao khung 26 dòng tự co theo chiều cao màn hình
    // thật — 260 là ước lượng chỗ tiêu đề + 2 nút + hàng tab + chú thích +
    // lề dialog chiếm mất, clamp lại để không quá nhỏ/quá to.
    final caoKhungDong = (MediaQuery.sizeOf(context).height - 260).clamp(120.0, 480.0);
    // (YÊU CẦU MỚI) Màn rộng: modal rộng CÀNG NHIỀU CÀNG TỐT, chỉ trừ lại
    // chút lề hai bên — 420 vẫn là mức hẹp tối thiểu (màn hẹp/trung).
    final rongModal = (MediaQuery.sizeOf(context).width - 64).clamp(420.0, 1600.0);
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(Ch.tuDienNhapLieuNhanh(ngonNguHienTai.value))),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: Ch.dong(ngonNguHienTai.value),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      // Xem giải thích đầy đủ ở `_HopThoaiLichSuBoNhoTamState.build` — cùng
      // lý do cần `scrollable: true` để luôn cuộn được trên màn hẹp chiều
      // cao, thay cho `ConstrainedBox` cố định. Lồng thêm MỘT lớp cuộn nội
      // bộ có `_cuonController` riêng (xem `SizedBox` bên dưới) để điều
      // khiển được bằng phím mũi tên/phím cách — an toàn vì lớp trong có
      // chiều cao CỐ ĐỊNH (`caoKhungDong`), không phải `Expanded`, nên lồng
      // trong lớp cuộn ngoài không hề xung đột.
      scrollable: true,
      content: SizedBox(
        width: rongModal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: _moHuongDan,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: Text(manHinhHepBeNgang ? Ch.nutHuongDan(ngonNguHienTai.value) : Ch.nutHuongDanDayDu(ngonNguHienTai.value)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                ),
                TextButton.icon(
                  // (SỬA LỖI) Modal cài đặt có thể đổi nội dung/thứ tự 26
                  // dòng — `setState` rỗng SAU KHI đóng để bảng này tự vẽ
                  // lại ngay với dữ liệu mới nhất, không cần đóng/mở lại
                  // bảng mới thấy (trước đây không có dòng này).
                  onPressed: () async {
                    await moModalTuDienNhapLieuNhanh(context, widget.caiDat);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(Ch.caiDat(ngonNguHienTai.value)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // (YÊU CẦU MỚI) 3 nút-tab sát cạnh nhau, không khoảng hở, góc
            // vuông — Gần đây / Q→M (theo hàng phím) / A→Z.
            Row(
              children: [
                _nutTab('ganDay', Ch.tabGanDayRong(ngonNguHienTai.value), Ch.tabGanDayHep(ngonNguHienTai.value), manHinhHepBeNgang),
                _nutTab('hang', Ch.tabHangPhimRong(ngonNguHienTai.value), 'Q → M (2)', manHinhHepBeNgang),
                _nutTab('bangChuCai', Ch.tabBangChuCaiRong(ngonNguHienTai.value), 'A → Z (3)', manHinhHepBeNgang),
              ],
            ),
            const SizedBox(height: 8),
            Text(_chuThichTab, style: TextStyle(fontSize: 12, color: _mauChuThichTab)),
            const SizedBox(height: 8),
            SizedBox(
              height: caoKhungDong,
              child: ds.isEmpty
                  ? const Center(
                      child: Text(
                        '(Chưa có dòng nào được dán gần đây)',
                        style: TextStyle(color: Color(0xFF9AA0A6), fontStyle: FontStyle.italic),
                      ),
                    )
                  : Scrollbar(
                      controller: _cuonController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _cuonController,
                        child: Column(
                          children: [for (final i in ds) _dong(i)],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// (YÊU CẦU MỚI) Modal "Thêm nhanh vào từ điển nhập liệu nhanh" — mở từ nút
/// 📖 ở mỗi dòng trong `_HopThoaiLichSuBoNhoTam` (bảng 10 dòng lịch sử của
/// Bộ nhớ tạm), VÀ từ nút 📖 mới ở hàng Copy/Cắt khi có vùng chọn thật
/// (xem `_themVungChonVaoTuDienNhapLieuNhanh`) — cả hai nguồn chỉ khác nhau
/// ở [doanNguon]/[goiDinhDangNguon] truyền vào, logic bên trong y hệt. Tái
/// dùng Y HỆT khuôn 3-tab/phím tắt/cuộn của `_HopThoaiTuDienNhapLieuNhanhState`
/// (cùng `_tabThuTu`, cùng `CaiDat.tabTuDienNhapLieuNhanh` lưu lâu dài, cùng
/// phím 1/2/3 + mũi tên + phím cách) — khác ở: phần đầu hiện SẴN đoạn nguồn
/// kèm nút Copy/"Thêm nhanh vào Dòng trống gần nhất", và bấm vào một trong
/// 26 dòng (hoặc gõ đúng chữ cái của nó) là GHI nội dung nguồn vào dòng đó
/// (không phải dán vào vị trí con trỏ như bảng gốc).
class _HopThoaiThemNhanhTuDien extends StatefulWidget {
  const _HopThoaiThemNhanhTuDien({
    required this.doanNguon,
    required this.goiDinhDangNguon,
    required this.caiDat,
    required this.nguon,
  });

  final String doanNguon;
  final String? goiDinhDangNguon;
  final CaiDat caiDat;
  final _NguonTuDienNhanh nguon;

  @override
  State<_HopThoaiThemNhanhTuDien> createState() => _HopThoaiThemNhanhTuDienState();
}

class _HopThoaiThemNhanhTuDienState extends State<_HopThoaiThemNhanhTuDien>
    with SingleTickerProviderStateMixin {
  // KHÔNG được `const` — xem giải thích ở `_HopThoaiLichSuBoNhoTamState._phimSo`.
  static final _phimChu = {
    for (var i = 0; i < 26; i++) LogicalKeyboardKey(LogicalKeyboardKey.keyA.keyId + i): i,
  };

  late String _tab;
  final _cuonController = ScrollController();

  /// (YÊU CẦU MỚI) Hiệu ứng nền cam nhấp nháy tuần hoàn (mờ→rõ→mờ..., mỗi
  /// chiều 2 giây) ở dòng TRỐNG trên cùng của tab 2/tab 3 — `repeat(reverse:
  /// true)` tự chạy đi-về mãi mãi giữa 0.0 và 1.0, dùng thẳng `.value` làm độ
  /// mờ của một lớp phủ màu cam (xem `_dong`).
  late final AnimationController _nhapNhayCam =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
        ..repeat(reverse: true);

  bool _vuaCopy = false;
  Timer? _henCopy;

  String get _doanNguon => widget.doanNguon;

  List<VungDinhDangDoanVan> get _vungDinhDangNguon {
    final goi = widget.goiDinhDangNguon;
    if (goi == null) return const [];
    return giaiMaGoiDinhDang(goi, _doanNguon) ?? const [];
  }

  @override
  void initState() {
    super.initState();
    _tab = _tabThuTu.contains(widget.caiDat.tabTuDienNhapLieuNhanh)
        ? widget.caiDat.tabTuDienNhapLieuNhanh
        : 'hang';
    HardwareKeyboard.instance.addHandler(_khiPhim);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_khiPhim);
    _cuonController.dispose();
    _nhapNhayCam.dispose();
    _henCopy?.cancel();
    super.dispose();
  }

  void _doiTab(String t) {
    if (_tab == t) return;
    setState(() => _tab = t);
    widget.caiDat.datTabTuDienNhapLieuNhanh(t);
  }

  void _doiTabTheoHuong(int delta) {
    final vtMoi = (_tabThuTu.indexOf(_tab) + delta).clamp(0, _tabThuTu.length - 1);
    _doiTab(_tabThuTu[vtMoi]);
  }

  void _cuonLenTrenCung() {
    if (!_cuonController.hasClients) return;
    _cuonController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _cuonXuongDuoiCung() {
    if (!_cuonController.hasClients) return;
    _cuonController.animateTo(
      _cuonController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _cuonTheoPhimCach() {
    if (!_cuonController.hasClients) return;
    final oDuoiCung = _cuonController.offset >= _cuonController.position.maxScrollExtent - 2;
    oDuoiCung ? _cuonLenTrenCung() : _cuonXuongDuoiCung();
  }

  /// Y hệt `_HopThoaiTuDienNhapLieuNhanhState._khiPhim`, chỉ khác hành động
  /// cuối: gõ đúng chữ cái là GHI nội dung nguồn vào dòng đó (`_bamDong`),
  /// không phải dán vào vị trí con trỏ.
  bool _khiPhim(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final phim = event.logicalKey;
    if (phim == LogicalKeyboardKey.digit1 || phim == LogicalKeyboardKey.numpad1) {
      _doiTab('ganDay');
      return true;
    }
    if (phim == LogicalKeyboardKey.digit2 || phim == LogicalKeyboardKey.numpad2) {
      _doiTab('hang');
      return true;
    }
    if (phim == LogicalKeyboardKey.digit3 || phim == LogicalKeyboardKey.numpad3) {
      _doiTab('bangChuCai');
      return true;
    }
    if (phim == LogicalKeyboardKey.arrowLeft) {
      _doiTabTheoHuong(-1);
      return true;
    }
    if (phim == LogicalKeyboardKey.arrowRight) {
      _doiTabTheoHuong(1);
      return true;
    }
    if (phim == LogicalKeyboardKey.arrowUp) {
      _cuonLenTrenCung();
      return true;
    }
    if (phim == LogicalKeyboardKey.arrowDown) {
      _cuonXuongDuoiCung();
      return true;
    }
    if (phim == LogicalKeyboardKey.space) {
      _cuonTheoPhimCach();
      return true;
    }
    final i = _phimChu[phim];
    if (i == null) return false;
    _bamDong(i);
    return true;
  }

  List<int> _chiSoTheoTab() {
    if (_tab == 'ganDay') {
      final ds = List<int>.from(widget.caiDat.ganDayTuDienNhapLieuNhanh);
      final thuTu = thuTuTuDienNhapLieuNhanhTheoKieu(widget.caiDat.thuTuTuDienNhapLieuNhanh);
      ds.sort((a, b) => thuTu.indexOf(a).compareTo(thuTu.indexOf(b)));
      return ds;
    }
    return thuTuTuDienNhapLieuNhanhTheoKieu(_tab);
  }

  String get _chuThichTab => switch (_tab) {
        'ganDay' => Ch.chuThichTabGanDayTuDien(ngonNguHienTai.value),
        'hang' => Ch.chuThichTabHangTuDien(ngonNguHienTai.value),
        _ => Ch.chuThichTabAZTuDien(ngonNguHienTai.value),
      };

  Color get _mauChuThichTab => switch (_tab) {
        'ganDay' => const Color(0xFF137333),
        'hang' => const Color(0xFFB06000),
        _ => const Color(0xFF8430CE),
      };

  Widget _nutTab(String id, String nhanRong, String nhanHep, bool hep) {
    final dangChon = _tab == id;
    return Expanded(
      child: InkWell(
        onTap: () => _doiTab(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          color: dangChon ? const Color(0xFF1A73E8) : const Color(0xFFF1F3F4),
          alignment: Alignment.center,
          child: Text(
            hep ? nhanHep : nhanRong,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dangChon ? Colors.white : const Color(0xFF5F6368),
            ),
          ),
        ),
      ),
    );
  }

  /// Dòng TRỐNG đầu tiên trong [ds] (thứ tự hiển thị của một cách sắp xếp
  /// cụ thể) — `null` nếu không còn dòng trống nào trong thứ tự đó.
  int? _dongTrongDauTien(List<int> ds) {
    for (final i in ds) {
      if (widget.nguon.dong(i).trim().isEmpty) return i;
    }
    return null;
  }

  /// Dòng trống dùng cho nút "Thêm nhanh vào Dòng trống gần nhất (Phím X)"
  /// — tab "Gần đây" dùng ĐÚNG thứ tự của tab "Q→M" (trường hợp 2 trong yêu
  /// cầu), hai tab còn lại dùng thứ tự của chính nó. `'hang'` và
  /// `'bangChuCai'` cùng phủ đủ 26 chỉ số (chỉ khác thứ tự) nên "không còn
  /// dòng trống theo thứ tự này" LUÔN đồng nghĩa "không còn dòng trống nào
  /// trong cả 26 dòng" — đúng điều kiện liệt nút ở yêu cầu.
  int? get _dongTrongGanNhatChoNut {
    final kieu = _tab == 'bangChuCai' ? 'bangChuCai' : 'hang';
    return _dongTrongDauTien(thuTuTuDienNhapLieuNhanhTheoKieu(kieu));
  }

  Future<void> _xacNhanThayThe(int i) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Ch.thayTheNoiDungDongNay(ngonNguHienTai.value)),
        content: Text(
          Ch.dongPhimKyTuDaCoNoiDungSeMat(
              chuCaiTuDienNhapLieuNhanh(i), ngonNguHienTai.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(Ch.huyQuayLai(ngonNguHienTai.value)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(Ch.coXacNhanThayThe(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
    if (dongY == true && mounted) _ghiVaoDong(i);
  }

  void _bamDong(int i) {
    if (widget.nguon.dong(i).trim().isEmpty) {
      _ghiVaoDong(i);
    } else {
      _xacNhanThayThe(i);
    }
  }

  void _ghiVaoDong(int i) {
    final doan = _doanNguon;
    unawaited(widget.nguon.ghiDong(i, doan));
    final vung = _vungDinhDangNguon;
    unawaited(widget.nguon.ghiDinhDang(i, vung));
    final chuCai = chuCaiTuDienNhapLieuNhanh(i);
    Navigator.of(context).pop();
    hienThongBaoGiua(
      context,
      Ch.daDanNoiDungVaoDongNhapLieuNhanhThuocPhim(ngonNguHienTai.value, chuCai),
      ganTren: true,
    );
  }

  Future<void> _copyNguon() async {
    if (_vuaCopy) return;
    final doan = _doanNguon;
    final vung = _vungDinhDangNguon;
    final html = vung.isEmpty ? null : dungHtmlChoClipboard(doan, vung);
    final daGhiGiauDinhDang = html != null && await ghiClipboardCoDinhDang(doan, html);
    if (!daGhiGiauDinhDang) {
      await Clipboard.setData(ClipboardData(text: doan));
    }
    if (!mounted) return;
    setState(() => _vuaCopy = true);
    _henCopy?.cancel();
    _henCopy = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _vuaCopy = false);
    });
  }

  Widget _dong(int i, {required bool nhapNhayCam}) {
    final chuCai = chuCaiTuDienNhapLieuNhanh(i);
    final doanDong = widget.nguon.dong(i);
    final rong = doanDong.trim().isEmpty;
    final doanHienThi = doanDong.replaceAll('\n', ' ');
    final manHinhHep = MediaQuery.sizeOf(context).width < _TrangSoanThaoState._nguongManHinhHep;
    final doMoi = widget.caiDat.doMoiTuDienNhapLieuNhanh(i);
    final mauNenGanDay =
        doMoi == null ? null : (doMoi < 5 ? const Color(0xFF81C995) : const Color(0xFFCEEAD6));

    final noiDung = Container(
      color: mauNenGanDay,
      child: InkWell(
        onTap: () => _bamDong(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              // (YÊU CẦU MỚI) Nút dấu + bên trái — bấm vào đây HOẶC bấm vào
              // nội dung dòng đều cùng một hành động (`_bamDong`).
              IconButton(
                onPressed: () => _bamDong(i),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                tooltip: Ch.themNoiDungVaoDongNay(ngonNguHienTai.value),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  rong ? Ch.trongNgoacDon(ngonNguHienTai.value) : doanHienThi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: rong ? const Color(0xFF9AA0A6) : null,
                    fontStyle: rong ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              SizedBox(width: manHinhHep ? 4 : 10),
              Text(
                manHinhHep ? chuCai : Ch.phimChuCai(ngonNguHienTai.value, chuCai),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mauChuPhimTuDienNhapLieuNhanh(i),
                  decoration: ganChanPhimTuDienNhapLieuNhanh(i)
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationThickness: doDayGachChanTuDienNhapLieuNhanh,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!nhapNhayCam) return noiDung;
    // (YÊU CẦU MỚI) Dòng trống trên cùng của tab 2/tab 3 — phủ một lớp màu
    // cam lên trên, độ mờ chạy theo `_nhapNhayCam.value` (0.0 → 1.0 → 0.0,
    // mỗi chiều 3,5 giây, lặp mãi).
    return AnimatedBuilder(
      animation: _nhapNhayCam,
      builder: (context, child) => Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Color.lerp(
                  const Color(0x00FF9800),
                  const Color(0xFFFF9800),
                  _nhapNhayCam.value,
                ),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: noiDung,
    );
  }

  @override
  Widget build(BuildContext context) {
    final manHinhHepBeNgang =
        MediaQuery.sizeOf(context).width < _TrangSoanThaoState._nguongManHinhHep;
    final ds = _chiSoTheoTab();
    // (YÊU CẦU MỚI) Chỉ tab 2 ("hang")/tab 3 ("bangChuCai") có hiệu ứng nhấp
    // nháy ở dòng trống trên cùng — tab "Gần đây" không có khái niệm "dòng
    // trống" đáng nhấn mạnh (toàn dòng ĐÃ dùng).
    final dongNhapNhay = _tab == 'ganDay' ? null : _dongTrongDauTien(ds);
    final caoKhungDong = (MediaQuery.sizeOf(context).height - 420).clamp(100.0, 420.0);
    final rongModal = (MediaQuery.sizeOf(context).width - 64).clamp(420.0, 1600.0);
    final dongTrongChoNut = _dongTrongGanNhatChoNut;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(Ch.themNhanhVaoTuDien(ngonNguHienTai.value))),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: Ch.dong(ngonNguHienTai.value),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      scrollable: true,
      content: SizedBox(
        width: rongModal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (YÊU CẦU MỚI) Thanh ngang hiển thị đoạn nguồn — y hệt cách
            // hiển thị một dòng trong bảng 10 dòng lịch sử của Bộ nhớ tạm.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _doanNguon.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _copyNguon,
                  icon: Icon(
                    _vuaCopy ? Icons.check : Icons.copy_outlined,
                    size: 16,
                    color: _vuaCopy ? Colors.green.shade700 : null,
                  ),
                  label: Text(
                    _vuaCopy ? 'Đã copy' : 'Copy',
                    style: TextStyle(color: _vuaCopy ? Colors.green.shade700 : null),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                ),
                TextButton.icon(
                  onPressed: dongTrongChoNut == null ? null : () => _ghiVaoDong(dongTrongChoNut),
                  icon: const Icon(Icons.flash_on_outlined, size: 16),
                  label: Text(
                    Ch.themNhanhVaoDongTrongGanNhat(
                        dongTrongChoNut == null
                            ? null
                            : chuCaiTuDienNhapLieuNhanh(dongTrongChoNut),
                        ngonNguHienTai.value),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _nutTab('ganDay', Ch.tabGanDayRong(ngonNguHienTai.value), Ch.tabGanDayHep(ngonNguHienTai.value), manHinhHepBeNgang),
                _nutTab('hang', Ch.tabHangPhimRong(ngonNguHienTai.value), 'Q → M (2)', manHinhHepBeNgang),
                _nutTab('bangChuCai', Ch.tabBangChuCaiRong(ngonNguHienTai.value), 'A → Z (3)', manHinhHepBeNgang),
              ],
            ),
            const SizedBox(height: 8),
            Text(_chuThichTab, style: TextStyle(fontSize: 12, color: _mauChuThichTab)),
            const SizedBox(height: 8),
            SizedBox(
              height: caoKhungDong,
              child: ds.isEmpty
                  ? const Center(
                      child: Text(
                        '(Chưa có dòng nào được dán gần đây)',
                        style: TextStyle(color: Color(0xFF9AA0A6), fontStyle: FontStyle.italic),
                      ),
                    )
                  : Scrollbar(
                      controller: _cuonController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _cuonController,
                        child: Column(
                          children: [
                            for (final i in ds) _dong(i, nhapNhayCam: i == dongNhapNhay),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
