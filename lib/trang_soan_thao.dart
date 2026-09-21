// Trang soạn thảo — một trang văn bản trắng, gõ phím và nói bằng micro cùng
// lúc. Mọi chữ — dù đến từ bàn phím hay từ micro — đều rơi vào đúng vị trí
// con trỏ. Micro không tắt khi người dùng gõ phím; ngược lại, gõ phím ngắt
// hẳn micro trong một giây rồi tự bật lại.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'cai_dat.dart';
import 'doan_thiet_bi.dart';
import 'ghi_am_the.dart';
import 'gui_ghi_am_gemini.dart';
import 'canh_bao_roi_trang.dart';
import 'kho_du_lieu.dart';
import 'mau_co_ban.dart';
import 'kiem_tra_chinh_ta.dart';
import 'kiem_tra_toan_van.dart';
import 'loai_thiet_bi.dart';
import 'man_hinh_cai_dat.dart';
import 'man_hinh_thu_muc.dart';
import 'modal_cai_dat_kiem_tra_toan_van.dart';
import 'modal_nghe_lai_ghi_am.dart';
import 'mo_hinh.dart';
import 'phien_ban_web_day_du.dart';
import 'the_ghi_am.dart';
import 'thanh_cong_cu.dart';
import 'thong_bao_giua.dart';
import 'trang_huong_dan.dart';

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
  const _ChuLuonSong({required this.chu, required this.mau});
  final String chu;
  final Color mau;

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
      duration: const Duration(milliseconds: 2400),
    )..repeat();
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
      fontSize: 12,
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
    return Tooltip(
      message: widget.moTa ?? widget.nhan,
      child: InkWell(
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
      ),
    );
  }
}

/// Nút ẩn/hiện 4 nút điều hướng (`_xayHangDieuHuongConTro`) — "nhảy" giữa 3
/// vị trí khác nhau tuỳ trạng thái (xem `_dieuHuongConTroAn`), mỗi lần
/// nhảy sang vị trí MỚI thì Flutter dựng lại một `State` MỚI (widget khác
/// cha, khác vị trí trong cây) nên `initState` chắc chắn được gọi lại đúng
/// lúc đó — dùng ngay điểm này để chạy hiệu ứng phóng to/thu nhỏ 4 lần
/// trong 3 giây một lần duy nhất mỗi khi "nhảy", không cần cờ điều khiển
/// riêng.
class _NutAnHienDieuHuongConTro extends StatefulWidget {
  const _NutAnHienDieuHuongConTro({required this.an, required this.onTap});

  final bool an;
  final VoidCallback onTap;

  @override
  State<_NutAnHienDieuHuongConTro> createState() => _NutAnHienDieuHuongConTroState();
}

class _NutAnHienDieuHuongConTroState extends State<_NutAnHienDieuHuongConTro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dk;

  @override
  void initState() {
    super.initState();
    _dk = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
  }

  @override
  void dispose() {
    _dk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dk,
      builder: (context, _) {
        // 4 nhịp phóng to (tới 1.3 lần)/thu nhỏ mượt trong 3 giây, rồi đứng
        // im hẳn ở 1.0 — |sin| có đúng 4 "nhịp" khi đối số quét từ 0 tới 4π.
        final tyLe = 1 + 0.3 * math.sin(4 * math.pi * _dk.value).abs();
        return Tooltip(
          message: widget.an ? 'Hiện lại 4 nút điều hướng con trỏ' : 'Ẩn 4 nút điều hướng con trỏ',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {},
            onTapDown: (_) => widget.onTap(),
            child: Transform.scale(
              scale: tyLe,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.an ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Nút nổi "Mở rộng" — trả lại mọi thanh công cụ phía trên sau khi bấm "Thu
/// gọn" (`_thuGonThanhCongCu`). Nổi TRÊN chữ đang soạn (không chiếm đất),
/// độ rõ tự thở tuần hoàn: 20% → 100% (5 giây) → đứng im (1 giây) →
/// 100% → 20% (5 giây) → đứng im (1 giây) → lặp lại mãi mãi (chu kỳ 12
/// giây) — vẫn LUÔN bấm được dù đang mờ tới đâu, giống mọi nút `Opacity`
/// khác trong tệp này (xem giải thích ở `_HangNutBoPhimNhanhTamAn`).
class _NutMoRongThanhCongCu extends StatefulWidget {
  const _NutMoRongThanhCongCu({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NutMoRongThanhCongCu> createState() => _NutMoRongThanhCongCuState();
}

class _NutMoRongThanhCongCuState extends State<_NutMoRongThanhCongCu>
    with SingleTickerProviderStateMixin {
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
            message: 'Mở rộng — hiện lại thanh công cụ',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {},
              onTapDown: (_) => widget.onTap(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF5F6368),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.expand_more, color: Colors.white, size: 22),
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
  const _NutCongCuChu({required this.nhan, required this.onTap, this.moTa});

  final String nhan;
  final String? moTa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: moTa ?? nhan,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        onTapDown: (_) => onTap(),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          alignment: Alignment.center,
          child: Text(
            nhan,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
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

/// Ba nút "Hiện lại Bộ phím nhanh"/"Đóng lại"/con mắt thay chỗ tên tệp khi
/// Bộ phím nhanh đang TẠM ẨN (xem `_hangNutBoPhimNhanhTamAn`). Có hiệu ứng
/// mờ-tỏ tuần hoàn: rõ hẳn 3 giây, mờ dần trong 5 giây, mờ hẳn (im lặng)
/// 1 giây, rõ dần trong 5 giây, rồi lặp lại — mỗi khi 3 nút mờ đi bao
/// nhiêu phần trăm thì [oTenField] hiện rõ đúng bấy nhiêu phần trăm (bù
/// trừ 1-1), để người dùng thấy lại tên tệp xen kẽ mà không cần thao tác
/// gì. Bấm/rê chuột vào NGAY vùng đất của 3 nút vẫn LUÔN hoạt động bình
/// thường bất kể đang mờ hay rõ tới đâu — `Opacity` (khác `Visibility`)
/// không tắt hit-test theo độ mờ, nên không cần `IgnorePointer` riêng cho
/// việc này.
///
/// Nút con mắt (ngoài cùng bên phải): bấm-giữ (di động) hoặc rê chuột vào
/// (`MouseRegion`, máy tính) sẽ NGAY LẬP TỨC ép 3 nút mờ hẳn (0%) và tên
/// tệp hiện rõ hẳn (100%), đồng thời TẠM DỪNG vòng lặp mờ-tỏ; thả tay/rê
/// chuột ra thì vòng lặp khởi động lại TỪ ĐẦU (không tiếp tục dở dang).
///
/// Tách thành widget riêng (có `vsync` riêng) theo đúng lý do đã ghi ở
/// `_ChamCuoiVanBan`: không phải thêm `TickerProviderStateMixin` cho cả
/// màn hình soạn thảo khổng lồ chỉ vì một hiệu ứng nhỏ.
class _HangNutBoPhimNhanhTamAn extends StatefulWidget {
  const _HangNutBoPhimNhanhTamAn({
    required this.onHienLai,
    required this.onDong,
    required this.oTenField,
  });

  final VoidCallback onHienLai;
  final VoidCallback onDong;
  final Widget oTenField;

  @override
  State<_HangNutBoPhimNhanhTamAn> createState() => _HangNutBoPhimNhanhTamAnState();
}

class _HangNutBoPhimNhanhTamAnState extends State<_HangNutBoPhimNhanhTamAn>
    with SingleTickerProviderStateMixin {
  static const _chuKy = Duration(seconds: 14);
  late final AnimationController _dk;
  bool _dangGiuNutConMat = false;
  bool _dangDiChuotVaoNutConMat = false;

  bool get _matDangMo => _dangGiuNutConMat || _dangDiChuotVaoNutConMat;

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

  /// Độ rõ của 3 nút tại thời điểm [gia] (0..1, phần trăm đã đi hết chu kỳ
  /// 14 giây): 0-3s rõ hẳn, 3-8s mờ dần, 8-9s mờ hẳn, 9-14s rõ dần.
  double _doRoNutTaiThoiDiem(double gia) {
    final t = gia * 14;
    if (t < 3) return 1;
    if (t < 8) return 1 - (t - 3) / 5;
    if (t < 9) return 0;
    return (t - 9) / 5;
  }

  void _kichHoatNutConMat() => setState(() => _dk.stop());

  void _ngungKichHoatNutConMat() {
    setState(() {});
    if (!_matDangMo) {
      _dk.value = 0;
      _dk.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dk,
      builder: (context, _) {
        final doRoNut = _matDangMo ? 0.0 : _doRoNutTaiThoiDiem(_dk.value);
        final doRoTen = 1 - doRoNut;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Opacity(opacity: doRoTen, child: IgnorePointer(child: widget.oTenField)),
            Opacity(
              opacity: doRoNut,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onHienLai,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Hiện lại Bộ phím nhanh'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.onDong,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Đóng lại'),
                  ),
                  const SizedBox(width: 8),
                  MouseRegion(
                    onEnter: (_) {
                      _dangDiChuotVaoNutConMat = true;
                      _kichHoatNutConMat();
                    },
                    onExit: (_) {
                      _dangDiChuotVaoNutConMat = false;
                      _ngungKichHoatNutConMat();
                    },
                    child: GestureDetector(
                      onTapDown: (_) {
                        _dangGiuNutConMat = true;
                        _kichHoatNutConMat();
                      },
                      onTapUp: (_) {
                        _dangGiuNutConMat = false;
                        _ngungKichHoatNutConMat();
                      },
                      onTapCancel: () {
                        _dangGiuNutConMat = false;
                        _ngungKichHoatNutConMat();
                      },
                      child: Container(
                        width: 48,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.visibility, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

  /// Dấu câu AI vừa tự chèn (mục 3) — chỉ tồn tại trong 4 giây hiệu ứng nhấp
  /// nháy, không phải "nguồn duy nhất của sự thật" như ba danh sách trên,
  /// vì hết hiệu ứng thì chữ đã ở trong [text] rồi, không cần theo dõi nữa.
  final List<_VungDauCauMoi> dauCauMoi = [];

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
  void Function(_VungKhongPhuHop vung, Offset viTriManHinh)? khiBamDoanKhongPhuHop;
  void Function(_VungCanXoa vung, Offset viTriManHinh)? khiBamDoanCanXoa;
  void Function(int soThe, Offset viTriManHinh)? khiBamTheGhiAmHoanChinh;
  void Function(int soThe, Offset viTriManHinh)? khiBamTheDangChuyen;

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

class TrangSoanThao extends StatefulWidget {
  const TrangSoanThao({
    super.key,
    required this.kho,
    required this.caiDat,
    required this.ghiChuId,
  });

  final KhoDuLieu kho;
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
  final _micro = SpeechToText();

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
      _bao('Đang mở trình ghi âm — hãy đóng trình ghi âm trước khi tìm kiếm.');
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
        title: const Text('Xác nhận thay thế'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            children: [
              TextSpan(
                text: laXoa
                    ? 'Bạn có chắc chắn xoá các ký tự '
                    : 'Bạn có chắc chắn thay đổi các ký tự ',
              ),
              _oanTuHopThoai(tuKhoa),
              if (!laXoa) ...[
                const TextSpan(text: ' thành '),
                _oanTuHopThoai(thayThe),
              ],
              const TextSpan(text: ' ở '),
              _oanTuHopThoaiXanh('$soLuong'),
              const TextSpan(text: ' kết quả tìm kiếm không?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Chấp nhận'),
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
                child: const Text('Tìm hiểu thêm', style: TextStyle(fontSize: 12)),
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
        title: Text(tieuDe),
        content: Text(noiDung, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
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
            title: const Text('Cài đặt tìm kiếm và hướng dẫn thay thế'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Cài đặt chế độ tìm kiếm',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    _dongCongTacTimKiem(
                      'Khớp cả chữ Hoa và chữ thường',
                      !phanBietHoaThuong,
                      (bat) => datHoaThuong(!bat),
                      khiBamTimHieuThem: () => _hienGiaiThichTimKiem(
                        'Khớp cả chữ Hoa và chữ thường',
                        'Tìm "h" sẽ ra cả "h" và "H" — không phân biệt chữ '
                            'Hoa/thường khi so khớp.',
                      ),
                    ),
                    _dongCongTacTimKiem(
                      'Chữ Hoa và chữ thường luôn khác nhau',
                      phanBietHoaThuong,
                      (bat) => datHoaThuong(bat),
                      khiBamTimHieuThem: () => _hienGiaiThichTimKiem(
                        'Chữ Hoa và chữ thường luôn khác nhau',
                        'Tìm "h" chỉ ra đúng "h", không ra "H" — phân biệt '
                            'chính xác chữ Hoa/thường.',
                      ),
                    ),
                    const SizedBox(height: 6),
                    _dongCongTacTimKiem(
                      'Khớp cả chữ không dấu và chữ có dấu',
                      !phanBietDauThanh,
                      (bat) => datDauThanh(!bat),
                      khiBamTimHieuThem: () => _hienGiaiThichTimKiem(
                        'Khớp cả chữ không dấu và chữ có dấu',
                        'Tìm "thang" sẽ ra cả "thắng", "thằng", "tháng"... — '
                            'không phân biệt dấu thanh khi so khớp.',
                      ),
                    ),
                    _dongCongTacTimKiem(
                      'Chữ không dấu và chữ có dấu luôn khác nhau',
                      phanBietDauThanh,
                      (bat) => datDauThanh(bat),
                      khiBamTimHieuThem: () => _hienGiaiThichTimKiem(
                        'Chữ không dấu và chữ có dấu luôn khác nhau',
                        'Tìm đúng chính xác dấu đã gõ — gõ "thang" chỉ ra '
                            '"thang", không ra các từ có dấu khác.',
                      ),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Hướng dẫn thay thế',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• "Thay chỗ này": chỉ thay đúng kết quả đang chọn (số '
                      'thứ tự đang hiện, ví dụ 3/5).\n\n'
                      '• "Tất cả": thay hết mọi kết quả cùng lúc, có hỏi xác '
                      'nhận trước khi làm.\n\n'
                      '• Để trống ô Thay thế rồi bấm một trong hai nút: kết '
                      'quả tìm kiếm đó bị XOÁ, không cần gõ gì để thay vào '
                      'chỗ trống.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đã hiểu'),
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

  /// Nhật ký gỡ lỗi micro — CHỈ ghi trên web (xem `_ghiNhatKyMicro`), để
  /// người dùng bấm "Xem nhật ký micro" trong Cài đặt, sao chép rồi gửi lại
  /// khi micro ra chữ sai — không cần USB debug hay console trình duyệt.
  /// Giới hạn 300 dòng, dòng cũ nhất bị bỏ khi đầy (y hệt bản thử nghiệm
  /// `main_web_test.dart`).
  final List<String> _nhatKyMicro = [];

  /// CHỈ dùng cho web + Android — xem chú thích chi tiết tại nơi dùng trong
  /// `_khiCoChu`. Reset về rỗng mỗi khi một PHIÊN nghe mới thật sự bắt đầu
  /// (`_batMicro()`) — bộ nhận dạng của trình duyệt tạo lại từ đầu lúc đó.
  String _rawTichLuyChromeAndroid = '';

  void _ghiNhatKyMicro(String dong) {
    if (!kIsWeb) return;
    final gio = DateTime.now();
    String hai(int n) => n.toString().padLeft(2, '0');
    final gioChuoi = '${hai(gio.hour)}:${hai(gio.minute)}:${hai(gio.second)}';
    _nhatKyMicro.add('[$gioChuoi] $dong');
    if (_nhatKyMicro.length > 300) _nhatKyMicro.removeAt(0);
  }

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
  /// loại trên, nên KHÔNG được áp dụng kiểu "quét lại toàn bộ" như trên —
  /// (SỬA LỖI gõ 1 dấu nháy ở giữa làm đảo lộn cách ghép cặp của MỌI dấu
  /// nháy phía sau nó) bản trước đây quét lại toàn văn bản mỗi lần gõ, coi
  /// dấu thứ 1/3/5.../2/4/6... lần lượt là mở/đóng — nhưng chèn/xoá MỘT
  /// dấu nháy làm lệch thứ tự đếm của TẤT CẢ dấu nháy đứng sau nó, khiến
  /// những cặp đã chuẩn hoá ổn định trước đó bị ghép lại sai rồi bị chuẩn
  /// hoá nhầm theo, dù người dùng chỉ gõ đúng MỘT ký tự ở một chỗ. Sửa:
  /// CHỈ xét đúng dấu nháy VỪA GÕ — đếm số dấu nháy đứng TRƯỚC nó (không
  /// đụng gì tới những dấu đứng SAU) để suy ra vai trò (đếm được số LẺ dấu
  /// đứng trước ⇒ nó là dấu ĐÓNG), rồi ghép với dấu nháy GẦN NHẤT ngay
  /// phía trước nó — không đá động gì tới các cặp khác trong bài.
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
      // CHỈ xét đúng dấu nháy VỪA GÕ (tại [vt]) — đếm số dấu nháy đứng
      // TRƯỚC nó để suy ra vai trò, rồi ghép với dấu nháy GẦN NHẤT ngay
      // phía trước — KHÔNG quét/đụng gì tới các dấu nháy khác trong bài,
      // để không làm đảo lộn những cặp đã ổn định từ trước (xem giải thích
      // ở trên hàm).
      var soDauTruoc = 0;
      for (var i = 0; i < vt; i++) {
        if (vb[i] == '"') soDauTruoc++;
      }
      if (soDauTruoc.isOdd) {
        for (var i = vt - 1; i >= 0; i--) {
          if (vb[i] == '"') {
            chuanHoaMotCap(i, vt);
            break;
          }
        }
      }
      // Số dấu trước nó CHẴN ⇒ chính nó là dấu MỞ — chưa có gì để chuẩn
      // hoá, chờ dấu đóng của nó xuất hiện trong tương lai.
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
  final _oVanBanKey = GlobalKey();
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
    final cacDong = <InlineSpan>[
      const TextSpan(
        text: 'Gõ chữ và bấm Micro để nói...\n'
            'Thực hiện song song hai việc trên cùng lúc.\n'
            'Vui lòng đọc hướng dẫn và mẹo sử dụng App (Nút ',
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(Icons.help_outline_rounded, size: 16, color: mauChuMo),
      ),
      const TextSpan(text: ')'),
    ];
    // Riêng bản WEB (không đụng bản Android/iOS gốc): thêm dòng chỉ đường
    // khi micro trục trặc + tên thiết bị đang dùng (đoán/chọn tay, xem
    // `_thietBiHienTai`) + số phiên bản web + gợi ý dùng Chrome.
    if (kIsWeb) {
      cacDong.addAll([
        const TextSpan(
          text: '\nNếu Micro trục trặc, hãy vào Cài đặt hệ thống\n',
        ),
        const TextSpan(
          text: 'Đang sử dụng bộ Micro của Thiết bị ',
          style: TextStyle(decoration: TextDecoration.underline),
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
          text: '\n@Flowrite web (phiên bản $phienBanWebDayDu)\n'
              'Truy cập Web bằng trình duyệt Chrome để sử dụng tốt nhất!',
        ),
      ]);
    }
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
        _boDieuKhien.canXoa.isEmpty) {
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
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Tìm trong văn bản...',
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
            tooltip: 'Kết quả trước',
            onPressed: _ketQuaTimKiem.isEmpty ? null : () => _dieuHuongTimKiem(-1),
            visualDensity: manHinhHep ? VisualDensity.compact : VisualDensity.standard,
            constraints: manHinhHep ? kichThuocNutNho : null,
            padding: manHinhHep ? EdgeInsets.zero : const EdgeInsets.all(8),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Kết quả tiếp theo',
            onPressed: _ketQuaTimKiem.isEmpty ? null : () => _dieuHuongTimKiem(1),
            visualDensity: manHinhHep ? VisualDensity.compact : VisualDensity.standard,
            constraints: manHinhHep ? kichThuocNutNho : null,
            padding: manHinhHep ? EdgeInsets.zero : const EdgeInsets.all(8),
          ),
          _NutXoaCoThongBao(
            tooltip: 'Xoá nội dung tìm',
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
            child: const Text('Tắt'),
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
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Thay thế những ký tự trên bằng ký tự gì?',
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
            child: const Text('Thay chỗ này'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: demNutChuHep,
              minimumSize: manHinhHep ? const Size(0, 36) : null,
            ),
            onPressed: _ketQuaTimKiem.isEmpty ? null : _xacNhanThayTatCa,
            child: const Text('Tất cả'),
          ),
          _NutXoaCoThongBao(
            tooltip: 'Xoá nội dung thay thế',
            onXoa: () => _oThayThe.clear(),
            nho: manHinhHep,
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            tooltip: 'Cài đặt tìm kiếm và hướng dẫn thay thế',
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
          nut(Icons.format_bold, _damDangCho, 'dam', 'Đậm (Ctrl+B)'),
          nut(Icons.format_italic, _nghiengDangCho, 'nghieng', 'Nghiêng (Ctrl+I)'),
          nut(Icons.format_underlined, _gachChanDangCho, 'gachChan', 'Gạch chân (Ctrl+U)'),
          nut(Icons.strikethrough_s, _gachNganDangCho, 'gachNgang', 'Gạch ngang thân (Ctrl+Shift+X)'),
          nutChu('x²', _treMuDangCho, 'treMu', 'Chữ trên (Ctrl+Shift+=)'),
          nutChu('x₂', _treChanDangCho, 'treChan', 'Chữ dưới (Ctrl+=)'),
          _NutMauDinhDang(
            nhan: 'Màu chữ (Ctrl+Shift+C)',
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
            nhan: 'Màu nền chữ (Ctrl+Shift+H)',
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
            tooltip: 'Xoá định dạng văn bản (Ctrl+Q)',
            icon: const Icon(Icons.format_clear),
            visualDensity: matDoNut,
            constraints: kichThuocNut,
            padding: EdgeInsets.zero,
            onPressed: () => _apDungDinhDang('xoaDinhDang'),
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
  final List<_TrangThaiVanBan> _lichSuLui = [];
  final List<_TrangThaiVanBan> _lichSuToi = [];
  static const _soLuongLichSuToiDa = 50;

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

  /// Đang có một lượt "Kiểm tra toàn văn bằng AI" chạy dở hay không — chặn
  /// bấm nút này thêm lần nữa trong lúc đang chờ.
  bool _dangKiemTraToanVan = false;
  final _dichVuToanVan = DichVuKiemTraToanVan();

  @override
  void initState() {
    super.initState();
    _ghiChuHienTai = widget.kho.timGhiChu(widget.ghiChuId)!;
    _thietBiHienTai = widget.caiDat.thietBiChonTay ?? doanThietBi();
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

    WidgetsBinding.instance.addObserver(this);
    _boDieuKhien.addListener(_khiNguoiDungSua);
    _boDieuKhien.addListener(_capNhatTimKiemNeuDangMo);
    // TextField (Material) không có tham số `onSelectionChanged` — đó là
    // API của EditableText, không lộ ra ở TextField. Vì
    // `_tinhTrangThaiDinhDangHienTai` vốn đã an toàn gọi mỗi lần selection
    // đổi, KỂ CẢ mỗi lần gõ phím (xem chú thích ngay tại khai báo hàm),
    // đăng ký nó như một listener bình thường ở đây là đủ và không lặp lại
    // lỗi ANR cũ (hàm chỉ làm việc O(k) nhỏ, không quét toàn văn bản).
    _boDieuKhien.addListener(_tinhTrangThaiDinhDangHienTai);
    _boDieuKhien.khiBamTuSai = _khiBamTuSai;
    _boDieuKhien.khiBamDoanKhongPhuHop = _khiBamDoanKhongPhuHop;
    _boDieuKhien.khiBamDoanCanXoa = _khiBamDoanCanXoa;
    _boDieuKhien.khiBamTheGhiAmHoanChinh = _khiBamTheGhiAmHoanChinh;
    _boDieuKhien.khiBamTheDangChuyen = _khiBamTheDangChuyen;
    _oTimKiem.addListener(_capNhatKetQuaTimKiem);
    _oTimKiem.addListener(_khiOTimKiemDoi);
    _oThayThe.addListener(_khiOThayTheDoi);

    // Nội dung lưu trữ có thể mang thêm một khối định dạng AI mã hoá ở cuối
    // (xem `_macDinhDangAi`/`_apDungDinhDangAi`) — tách nó ra TRƯỚC khi đưa
    // vào ô soạn thảo, để `_boDieuKhien.text` chỉ chứa đúng văn bản THẬT,
    // không lộ khối mã hoá ra màn hình.
    final rawNoiDung = _ghiChuHienTai.noiDung;
    final (banDau, khoiDinhDang, khoiDinhDangThuCong) = _tachCacKhoiDinhDang(rawNoiDung);

    if (banDau.isNotEmpty) {
      _ghiVaoO(banDau, banDau.length);
    } else {
      // Ghi chú vừa tạo, chưa từng có ký tự nào — tự hiện chú thích ngay từ
      // đầu, y hệt như vừa bấm nút "i", để người dùng lần đầu biết mỗi nút
      // dùng để làm gì.
      _hienChuThich = true;
    }
    _neo = banDau.length;
    _viTriDaKiemTraChinhTa = banDau.length;
    if (khoiDinhDang != null) _apDungDinhDangAi(khoiDinhDang);
    if (khoiDinhDangThuCong != null) _apDungDinhDangThuCong(khoiDinhDangThuCong);

    _khoiTaoMicro();
    // Lắng nghe TOÀN CỤC (không phụ thuộc widget nào đang giữ tiêu điểm) —
    // phím tắt phải hoạt động kể cả đang gõ dở trong ô văn bản.
    HardwareKeyboard.instance.addHandler(_khiPhimTatMicro);
    HardwareKeyboard.instance.addHandler(_khiPhimTatLuiTien);
    HardwareKeyboard.instance.addHandler(_khiGoPhimBatKyTatChuThich);
  }

  /// Gõ BẤT KỲ phím nào trên bàn phím rời cũng tắt chú thích — không riêng gì
  /// chạm màn hình. Chỉ quan sát (luôn trả về false), không chặn phím đi
  /// tiếp xuống ô văn bản hay các phím tắt khác.
  bool _khiGoPhimBatKyTatChuThich(KeyEvent event) {
    if (event is KeyDownEvent) _tatChuThich();
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_khiPhimTatMicro);
    HardwareKeyboard.instance.removeHandler(_khiPhimTatLuiTien);
    HardwareKeyboard.instance.removeHandler(_khiGoPhimBatKyTatChuThich);
    WidgetsBinding.instance.removeObserver(this);
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
    _conTroDangHien.dispose();
    _oChu.removeListener(_khiFocusConTroDoi);
    _bomDongHoTheGhiAm?.cancel();
    _dangKyMucAmTheGhiAm?.cancel();
    _thoiLuongTheGhiAmDangGhi.dispose();
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

  // ---------------------------------------------------------------- lưu trữ

  /// `true` = có thay đổi CHƯA kịp tự động lưu — chỉ web mới dùng tới (xem
  /// `canh_bao_roi_trang.dart`), nhưng đặt ở đây cho MỌI nền tảng cho đơn
  /// giản, không cần bọc `kIsWeb` quanh một biến bool vô hại.
  bool _coThayDoiChuaLuu = false;

  Future<void> _luuVanBan() async {
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
      hienThongBaoGiua(context, 'Đã lưu "${_ghiChuHienTai.ten}" vào bộ nhớ máy.');
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

  Future<void> _moCaiDat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManHinhCaiDat(
          caiDat: widget.caiDat,
          layNhatKyMicro: () => List<String>.from(_nhatKyMicro),
          xoaNhatKyMicro: _nhatKyMicro.clear,
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
    if (_muonNghe) await _tatMicro();
    if (!mounted) return;
    final idChon = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ManHinhThuMuc(
          kho: widget.kho,
          idGhiChuDangMo: _ghiChuHienTai.id,
        ),
      ),
    );
    if (!mounted) return;

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
      _bao('Ghi chú đang mở đã bị xoá, đã tạo ghi chú mới.');
    } else {
      setState(() => _tenController.text = vanConDo.ten);
    }
  }

  /// (VIỆC 6b) Danh sách ghi chú trong CÙNG thư mục với ghi chú đang mở,
  /// đúng THỨ TỰ hiển thị của `ManHinhThuMuc` — TÁI DÙNG đúng
  /// `KhoDuLieu.noiDungThuMuc` (nguồn thứ tự DUY NHẤT, sắp theo tên không
  /// phân biệt hoa/thường), không tự bịa thứ tự khác.
  List<GhiChuFile> _dsGhiChuCungThuMuc() =>
      widget.kho.noiDungThuMuc(_ghiChuHienTai.chaId).ghiChuCon;

  /// (VIỆC 6b) "Tệp trước"/[buoc] = -1, "Tệp sau"/[buoc] = 1. Không có tệp
  /// trước/sau (đang ở đầu/cuối danh sách) thì không làm gì — ưu tiên đơn
  /// giản, tránh phức tạp hoá bằng thông báo riêng.
  Future<void> _chuyenTepTrongThuMuc(int buoc) async {
    final ds = _dsGhiChuCungThuMuc();
    final viTriHienTai = ds.indexWhere((g) => g.id == _ghiChuHienTai.id);
    if (viTriHienTai < 0) return;
    final viTriMoi = viTriHienTai + buoc;
    if (viTriMoi < 0 || viTriMoi >= ds.length) return;
    final tepMoi = ds[viTriMoi];

    // Lưu ghi chú đang mở TRƯỚC KHI chuyển — đúng luồng `_moManHinhThuMuc`
    // đã dùng khi rời trang (tắt micro nếu đang nghe, rồi lưu).
    if (_muonNghe) await _tatMicro();
    if (!mounted) return;
    await _luuVanBan();
    if (!mounted) return;

    _moGhiChu(tepMoi.id);
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
            title: const Text('Tạo tệp văn bản mới'),
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
                child: const Text('Huỷ'),
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
                child: const Text('Tạo'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "Xoá Tệp văn bản này" — hỏi xác nhận, xoá xong nhảy sang một tệp khác
  /// còn lại trong CÙNG thư mục nếu còn, hoặc tự tạo "Ghi chú N" (hệt tên tự
  /// gợi ý mặc định) nếu đây là tệp CUỐI CÙNG của thư mục — rồi làm việc
  /// ngay ở tệp đó, kèm thông báo giữa màn hình.
  Future<void> _xoaTepHienTaiTuThanhCongCu() async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá tệp văn bản này?'),
        content: Text('Ghi chú "${_ghiChuHienTai.ten}" sẽ bị xoá VĨNH VIỄN, '
            'không thể phục hồi lại được. Bạn có chắc chắn muốn xoá không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không, giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Xoá', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) return;

    final chaId = _ghiChuHienTai.chaId;
    widget.kho.xoaGhiChu(_ghiChuHienTai.id);

    final conLai = widget.kho.noiDungThuMuc(chaId).ghiChuCon;
    final laTuDongTao = conLai.isEmpty;
    final ke = laTuDongTao ? widget.kho.taoGhiChuMoi(chaId) : conLai.first;
    await widget.kho.luu();
    if (!mounted) return;
    _moGhiChu(ke.id);
    if (laTuDongTao) {
      _bao('Đã xoá tệp — đang ở trong tệp "${ke.ten}" do hệ thống tự tạo.');
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
      tieuDe: 'Chọn màu Tên Tệp',
    );
    if (mau == null || !mounted) return;
    widget.kho.datMauGhiChu(_ghiChuHienTai.id, mau.value);
    setState(() {});
    await widget.kho.luu();
  }

  void _moGhiChu(String id) {
    final g = widget.kho.timGhiChu(id);
    if (g == null) return;

    setState(() {
      _ghiChuHienTai = g;
      _tenController.text = g.ten;
    });

    if (g.noiDung.isEmpty) {
      _ghiVaoO('', 0);
    } else {
      _ghiVaoO(g.noiDung, g.noiDung.length);
    }
    _neo = g.noiDung.length;
    _chuTam = '';
    _tuDaChotTrongPhien = [];
    _partialTruocDo = [];
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    _viTriDaKiemTraChinhTa = g.noiDung.length;
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
    _viTriChoVietHoa = null;

    widget.kho.datGhiChuDangMo(id);
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
    _ghiNhatKyMicro(
        'Bật micro — bản $phienBanWebDayDu, thiết bị đang dùng: '
        '${_thietBiHienTai.ten}${widget.caiDat.thietBiChonTay != null ? ' (đã CHỌN TAY)' : ' (tự đoán)'}');
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

  /// TẠM ẨN (khác với TẮT hẳn) — cả hai thanh công cụ của Bộ phím nhanh ẩn
  /// đi, TextField hết `readOnly` để bàn phím ảo hệ thống hiện ra ngay tại
  /// con trỏ, và vùng tên tệp trên AppBar nhường chỗ cho hai nút "Hiện lại
  /// Bộ phím nhanh"/"Đóng lại" (xem `_hangNutBoPhimNhanhTamAn`). Chỉ có ý
  /// nghĩa khi `_boPhimNhanhCamUngMo` đang bật — TẮT hẳn (nút "Đóng") luôn
  /// đặt lại `false`, để không "mồ côi" ở trạng thái ẩn khi mở lại từ đầu.
  bool _boPhimNhanhCamUngAn = false;

  void _bamNutBoPhimNhanhCamUng() {
    final dangBat = !_boPhimNhanhCamUngMo;
    setState(() {
      _boPhimNhanhCamUngMo = dangBat;
      _boPhimNhanhCamUngAn = false;
      if (!dangBat) _dieuHuongConTroAn = false;
    });
    if (dangBat) {
      _batConTroNgay();
      _epConTroHienRaMatThuong();
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
  /// không đủ) "Bấm hộ" đúng hai nút thật của hàng phím ảo — dấu cách
  /// (`_chenKyTuTuPhimAo`) rồi Xoá (`_xoaKyTuTuPhimAo`) — thay vì tự ghi
  /// thẳng qua `_ghiVaoO` như bản trước.
  ///
  /// (SỬA LỖI vẫn không thấy con trỏ dù đã có mẹo) Quan sát thực tế: tự tay
  /// bấm nút dấu cách hay nút Xoá ở hàng phím ảo thì con trỏ LUÔN hiện ra
  /// ngay lập tức — hai nút đó vốn đã tự đi qua đúng con đường khiến hệ
  /// thống đồng bộ lại con trỏ (`_boDieuKhien.value =` rồi giành lại tiêu
  /// điểm ở `addPostFrameCallback`, xem hai hàm đó). Bản trước tự ghi
  /// thẳng qua `_ghiVaoO` — một con đường KHÁC, "êm" hơn (không dựng lại
  /// UI qua listener), và đúng cái "êm" đó lại không đủ để ép con trỏ hiện
  /// ra. Sửa: đừng tự làm nữa — nhờ THẲNG hai nút thật làm hộ, để chắc
  /// chắn đi đúng con đường đã biết là hiệu quả.
  ///
  /// Vẫn giữ trì hoãn 300ms trước khi "bấm" — bàn phím ảo bật/tắt kèm đổi
  /// `readOnly` kéo theo một nhịp layout/resize riêng của hệ điều hành/
  /// trình duyệt đến sau khung hình kế tiếp; trì hoãn để cặp bấm-hộ này
  /// luôn là sự kiện cuối cùng, chạy sau khi màn hình đã ổn định hẳn.
  void _epConTroHienRaMatThuong() {
    _henEpConTro?.cancel();
    _henEpConTro = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _chenKyTuTuPhimAo(' ');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _xoaKyTuTuPhimAo();
      });
    });
  }

  /// Nút "Ẩn" (cam) — xem giải thích ở `_boPhimNhanhCamUngAn`. Ép bàn phím
  /// ảo hiện ra ngay bằng `TextInput.show` — chỉ đổi `readOnly` (qua
  /// `setState`) có lúc KHÔNG đủ để hệ thống tự mở bàn phím ngay lập tức vì
  /// tiêu điểm vốn đã nằm sẵn ở `_oChu` từ trước (không có sự kiện focus
  /// MỚI để hệ thống tự nhận ra mà bật kèm).
  void _anBoPhimNhanhCamUng() {
    setState(() => _boPhimNhanhCamUngAn = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _oChu.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
    // (BỎ MẸO chèn+xoá dấu cách) Nút "Ẩn" đã tự ép bàn phím ảo hiện ra bằng
    // `TextInput.show` ở trên rồi — không liên quan gì tới mẹo chèn+xoá
    // dấu cách (mẹo đó chỉ để ép CON TRỎ NHÁY hiện lại sau khi TOÀN BỘ
    // trạng thái soạn thảo đổi/dựng lại, dùng cho hai lối "bật"/"hiện lại").
    // Giữ mẹo đó ở đây từng có tác dụng phụ KHÔNG mong muốn: nếu người dùng
    // đang BÔI CHỌN một vùng văn bản rồi bấm "Ẩn", chèn dấu cách sẽ XOÁ
    // MẤT vùng đang chọn đó (gõ đè lên selection) trước khi tự xoá lại dấu
    // cách — vô tình phá nội dung người dùng đang chọn. Chỉ giữ
    // `_batConTroNgay()` (khởi động lại nhịp nhấp nháy, không đụng gì tới
    // nội dung) là đủ.
    _batConTroNgay();
  }

  /// Nút "Hiện lại Bộ phím nhanh" (xanh lá) — trả lại đúng trạng thái hiện
  /// hành của Bộ phím nhanh, ẩn bàn phím ảo hệ thống đi.
  void _hienLaiBoPhimNhanhCamUng() {
    setState(() => _boPhimNhanhCamUngAn = false);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    _batConTroNgay();
    _epConTroHienRaMatThuong();
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
    // Xem giải thích ở `_chenKyTuTuPhimAo` — cùng lý do, cùng cách sửa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
    });
  }

  /// Giành lại tiêu điểm cho ô soạn thảo sau khi bấm một nút của hàng công
  /// cụ (Copy/Cut/Paste/All/Home/End...) — xem giải thích ở `_chenKyTuTuPhimAo`.
  void _giuFocusOChuSauKhiBam() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oChu.requestFocus();
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

  /// "Copy" — chỉ làm gì đó khi ĐANG CÓ vùng chọn (không collapsed); vùng
  /// chọn rỗng thì không có gì để chép, im lặng bỏ qua.
  Future<void> _phimAoCopy() async {
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    if (!chon.isValid || chon.isCollapsed) return;
    final doan = _boDieuKhien.text.substring(chon.start, chon.end);
    if (doan.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: doan));
    if (mounted) hienThongBaoGiua(context, 'Đã copy vào bộ nhớ đệm');
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
    await Clipboard.setData(ClipboardData(text: doan));
    final moi = vb.replaceRange(batDau, ketThuc, '');
    _boDieuKhien.value =
        TextEditingValue(text: moi, selection: TextSelection.collapsed(offset: batDau));
    if (mounted) hienThongBaoGiua(context, 'Đã cắt và lưu vào bộ nhớ đệm');
  }

  /// "Paste" — không có thông báo nào theo yêu cầu (quá đơn giản, không cần
  /// xác nhận). Rỗng bộ nhớ đệm hoặc không đọc được thì im lặng bỏ qua.
  Future<void> _phimAoPaste() async {
    final data = await Clipboard.getData('text/plain');
    final chen = data?.text;
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
    final moi = vb.replaceRange(batDau, ketThuc, chen);
    _boDieuKhien.value = TextEditingValue(
      text: moi,
      selection: TextSelection.collapsed(offset: batDau + chen.length),
    );
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
  void _phimAoChonTatCa() {
    final vb = _boDieuKhien.text;
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    final bay = DateTime.now();
    final conTrongNguong =
        _lanBamAllTruoc != null && bay.difference(_lanBamAllTruoc!) <= _nguongBamAll;
    _demBamAll = conTrongNguong ? _demBamAll + 1 : 1;
    _lanBamAllTruoc = bay;

    if (_demBamAll >= 4) {
      _demBamAll = 0;
      _lanBamAllTruoc = null;
      _boDieuKhien.selection = TextSelection(baseOffset: 0, extentOffset: vb.length);
      if (mounted) hienThongBaoGiua(context, 'Đã chọn tất cả');
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

    if (_demBamAll >= 2 && vung.$1 == 0 && vung.$2 == vb.length) {
      _demBamAll = 0;
      _lanBamAllTruoc = null;
      if (mounted) hienThongBaoGiua(context, 'Đã chọn tất cả');
    } else if (mounted) {
      hienThongBaoGiua(context, 'Bấm "All" 2-4 lần để chọn vùng rộng hơn');
    }
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
    if (mounted) {
      hienThongBaoGiua(context, 'Bấm Home 2 lần để lên trên cùng văn bản');
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
    if (mounted) {
      hienThongBaoGiua(context, 'Bấm End 2 lần để xuống dưới cùng văn bản');
    }
  }

  /// 4 nút mũi tên điều hướng (`_xayHangDieuHuongConTro`) — "rút gọn" ẩn cả
  /// hàng đó đi (xem nơi dựng ở `build`), TRỪ nút ẩn/hiện — nút đó "nhảy"
  /// sang thanh Copy/Cut/.../End (màn hình rộng) hoặc đè lên nút "Hướng dẫn"
  /// của `ThanhCongCu` (màn hình hẹp).
  bool _dieuHuongConTroAn = false;

  void _bamNutAnHienDieuHuongConTro() {
    setState(() => _dieuHuongConTroAn = !_dieuHuongConTroAn);
  }

  /// Trái/Phải: [dx] = ±1 ký tự. Lên/Xuống: [dy] = ±1 dòng, cố gắng giữ
  /// nguyên CỘT (cột = số ký tự từ đầu dòng tới con trỏ) — đứng ở dòng đầu
  /// mà bấm Lên (hoặc dòng cuối mà bấm Xuống) thì đứng yên, không phải lỗi:
  /// nút bấm-giữ gọi lại no-op liên tục cũng vô hại.
  void _diChuyenConTro({int dx = 0, int dy = 0}) {
    final chon = _boDieuKhien.selection;
    _giuFocusOChuSauKhiBam();
    if (!chon.isValid) return;
    final vb = _boDieuKhien.text;
    var vt = chon.extentOffset;
    if (dx != 0) {
      vt = (vt + dx).clamp(0, vb.length);
    } else if (dy < 0) {
      final dauDongHienTai = vt <= 0 ? 0 : vb.lastIndexOf('\n', vt - 1) + 1;
      if (dauDongHienTai > 0) {
        final cot = vt - dauDongHienTai;
        final dauDongTruoc = dauDongHienTai <= 1 ? 0 : vb.lastIndexOf('\n', dauDongHienTai - 2) + 1;
        final doDaiDongTruoc = (dauDongHienTai - 1) - dauDongTruoc;
        vt = dauDongTruoc + cot.clamp(0, doDaiDongTruoc);
      }
    } else if (dy > 0) {
      final dauDongHienTai = vt <= 0 ? 0 : vb.lastIndexOf('\n', vt - 1) + 1;
      final ketThucDongHienTaiTho = vb.indexOf('\n', vt);
      if (ketThucDongHienTaiTho != -1) {
        final cot = vt - dauDongHienTai;
        final dauDongSau = ketThucDongHienTaiTho + 1;
        final ketThucDongSauTho = vb.indexOf('\n', dauDongSau);
        final doDaiDongSau = (ketThucDongSauTho == -1 ? vb.length : ketThucDongSauTho) - dauDongSau;
        vt = dauDongSau + cot.clamp(0, doDaiDongSau);
      }
    }
    _boDieuKhien.selection = TextSelection.collapsed(offset: vt);
  }

  // ------------------------------------------------------------- thẻ ghi âm

  /// Trình ghi âm đang mở (4 nút nhỏ hiện, thanh công cụ trên ẩn) — dùng
  /// chung một cờ cho cả việc hiện overlay VÀ việc có một thẻ đang ghi hay
  /// không, vì theo thiết kế đã chốt, mở trình ghi âm là lập tức ghi luôn.
  bool _trinhGhiAmMo = false;
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
  bool _tuDongGuiNgamTheGhiAm = true;
  bool _daCanhBaoGioiHanTheGhiAm = false;
  bool _hopThoaiCanhBaoTheGhiAmDangMo = false;

  static const _nguongTuDongGuiTheGhiAm = Duration(seconds: 20);
  static const _gioiHanMoiTheGhiAm = Duration(minutes: 5);
  static const _canhBaoGioiHanTheGhiAm = Duration(minutes: 4, seconds: 30);

  /// Ghi âm và micro-vừa-nói-vừa-ra-chữ không được cùng chạy — cả hai đều
  /// cần độc chiếm microphone của máy. Áp dụng cho MỌI nền tảng (kể cả
  /// Android/iOS gốc), không riêng web.
  bool get _ghiAmTheDangKhoaMicro => _trinhGhiAmMo;

  void _bamNutTuDongGuiNgamTheGhiAm() {
    setState(() => _tuDongGuiNgamTheGhiAm = !_tuDongGuiNgamTheGhiAm);
    hienThongBaoGiua(
      context,
      _tuDongGuiNgamTheGhiAm
          ? 'Đã BẬT tự động chuyển hoá văn bản khi các thẻ ghi âm tích đủ '
              'từ 20 giây trở lên'
          : 'Đã TẮT tự động chuyển hoá văn bản khi các thẻ ghi âm tích đủ '
              'từ 20 giây trở lên',
    );
  }

  String _nhanTheGhiAmHoanChinh(int soThe) =>
      nhanTheHoanChinh(soThe, _thoiLuongTheoTheGhiAm[soThe] ?? Duration.zero);

  Future<void> _bamNutGhiAmThe() async {
    if (_trinhGhiAmMo) {
      await _dongTrinhGhiAmThe();
      return;
    }
    if (_hienThanhTimKiem) {
      _bao('Đang mở tìm kiếm — hãy đóng tìm kiếm trước khi ghi âm.');
      return;
    }
    if (_muonNghe) await _tatMicro();
    if (!mounted) return;
    final ok = await ghiAmTheKhoiTao();
    if (!mounted) return;
    if (!ok) {
      _bao('Không xin được quyền micro để ghi âm.');
      return;
    }
    setState(() => _trinhGhiAmMo = true);
    await _batDauMotTheGhiAmMoi();
  }

  Future<void> _batDauMotTheGhiAmMoi() async {
    await ghiAmTheBatDauThe();
    if (!mounted) return;
    final soThe = _soThuTuTheGhiAmTiepTheo++;
    _soTheGhiAmDangGhi = soThe;
    _theGhiAmDangTamDung = false;
    _thoiLuongTheGhiAmDangGhi.value = Duration.zero;
    _daCanhBaoGioiHanTheGhiAm = false;
    _chenTokenDangGhiTheVaoVanBan();
    _batDauTheoDoiMucAmGhiAm();
    _bomDongHoTheGhiAm?.cancel();
    _bomDongHoTheGhiAm = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _theGhiAmDangTamDung) return;
      final moi = _thoiLuongTheGhiAmDangGhi.value + const Duration(seconds: 1);
      _thoiLuongTheGhiAmDangGhi.value = moi;
      if (moi >= _gioiHanMoiTheGhiAm) {
        _dongHopThoaiCanhBaoTheGhiAmNeuMo();
        _chotTheGhiAmVaBatDauTheMoiDoQuaGioiHan();
      } else if (moi >= _canhBaoGioiHanTheGhiAm) {
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

  void _chotTheGhiAmVaBatDauTheMoiDoQuaGioiHan() {
    if (_soTheGhiAmDangGhi == null) return;
    _chotTheGhiAmHienTaiThanhHoanChinh().then((_) {
      if (mounted && _trinhGhiAmMo) _batDauMotTheGhiAmMoi();
    });
  }

  void _dongHopThoaiCanhBaoTheGhiAmNeuMo() {
    if (_hopThoaiCanhBaoTheGhiAmDangMo && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _hienCanhBaoGioiHanTheGhiAmNeuChua() {
    if (_daCanhBaoGioiHanTheGhiAm || !mounted) return;
    _daCanhBaoGioiHanTheGhiAm = true;
    _hopThoaiCanhBaoTheGhiAmDangMo = true;
    final soThe = _soTheGhiAmDangGhi;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sắp chạm giới hạn 5 phút'),
        content: Text('Thẻ ghi âm #$soThe sắp ghi đủ 5 phút. Nếu không chọn, '
            'tới đúng phút thứ 5 nó sẽ tự động chốt và ghi tiếp bằng một '
            'thẻ mới. Bạn muốn làm gì bây giờ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chotTheGhiAmVaBatDauTheMoiDoQuaGioiHan();
            },
            child: const Text('Tạo bản ghi âm mới'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dongTrinhGhiAmThe();
            },
            child: const Text('Dừng và không ghi âm nữa'),
          ),
        ],
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
    await _batDauMotTheGhiAmMoi();
  }

  /// Nút "Dừng và hoàn thành ghi âm": chốt thẻ đang ghi (dù đang ghi hay
  /// đang tạm dừng) thành thẻ ghi âm XONG, nhưng KHÔNG tạo thẻ mới nào —
  /// trình ghi âm vẫn mở (người dùng có thể "Tạo phiên ghi âm mới" sau nếu
  /// muốn ghi tiếp, hoặc "Đóng trình ghi âm" luôn).
  Future<void> _dungVaHoanThanhGhiAmThe() async {
    if (_soTheGhiAmDangGhi == null) return;
    await _chotTheGhiAmHienTaiThanhHoanChinh();
    if (mounted) setState(() {});
  }

  /// Nút "Đóng trình ghi âm": chốt thẻ đang ghi (nếu có) rồi đóng hẳn —
  /// giải phóng micro, ẩn 4 nút nhỏ, thanh công cụ trên hiện lại.
  Future<void> _dongTrinhGhiAmThe() async {
    if (!_trinhGhiAmMo) return;
    await _chotTheGhiAmHienTaiThanhHoanChinh();
    await ghiAmTheDongHan();
    if (mounted) setState(() => _trinhGhiAmMo = false);
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
  void _kiemTraVaGuiNgamTheGhiAmNeuDu() {
    if (!_tuDongGuiNgamTheGhiAm) return;
    final vanBan = _boDieuKhien.text;
    final soTheChuaGui = <int>[];
    for (final m in reTheGhiAmHoanChinh.allMatches(vanBan)) {
      final soThe = int.parse(m.group(1)!);
      if (_theGhiAmDangGui.contains(soThe)) continue;
      if (!_duLieuTheoTheGhiAm.containsKey(soThe)) continue;
      soTheChuaGui.add(soThe);
    }
    if (soTheChuaGui.isEmpty) return;
    final tongThoiLuong = soTheChuaGui.fold<Duration>(
      Duration.zero,
      (tong, soThe) => tong + (_thoiLuongTheoTheGhiAm[soThe] ?? Duration.zero),
    );
    if (tongThoiLuong < _nguongTuDongGuiTheGhiAm) return;
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
        _bao('Thẻ ghi âm #$soThe: dữ liệu đã bị xoá vĩnh viễn trước đó, '
            'không thể chuyển hoá được nữa.');
      }
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
      final chu = await guiGhiAmChoGemini(duLieu.bytes, duLieu.mime);
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
      if (mounted) {
        final viTri = _boDieuKhien.text.indexOf(nhanDangChuyen);
        if (viTri >= 0) {
          _doiNhanTheGhiAm(viTri, nhanDangChuyen.length, nhanGoc);
          _boDieuKhien.theGhiAmLoiTamThoi.add(soThe);
          _boDieuKhien.veLai();
        }
      }
      if (baoLoi) _bao('Thẻ ghi âm #$soThe: lỗi gửi — $e');
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
      _bao('Không có thẻ ghi âm nào trong văn bản để gửi.');
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
        const PopupMenuItem(
          value: 'tatCa',
          child: Text('Chuyển hoá TẤT CẢ thẻ ghi âm'),
        ),
        const PopupMenuItem(
          value: 'moiThe',
          child: Text('Chỉ chuyển hoá thẻ này'),
        ),
        const PopupMenuItem(
          value: 'nghe',
          child: Text('Nghe bản ghi âm này'),
        ),
        PopupMenuItem(
          value: 'xoa',
          child: Text('Xoá thẻ ghi âm này',
              style: TextStyle(color: Colors.red.shade600)),
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
    }
  }

  /// Bấm "Nghe bản ghi âm này" — thẻ đã chuyển hoá rồi (đã trả về văn bản,
  /// theo cơ chế giữ trí nhớ: `_vanBanDaTraVeTheoTheGhiAm` và
  /// `_duLieuTheoTheGhiAm` LOẠI TRỪ NHAU, xem `_guiVaXuLyMotThe`) thì bytes
  /// gốc đã bị giải phóng — không còn gì để phát, báo cho người dùng biết
  /// thay vì mở modal trống/lỗi.
  Future<void> _ngheLaiGhiAmThe(int soThe) async {
    if (_vanBanDaTraVeTheoTheGhiAm.containsKey(soThe)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Không còn bản ghi âm'),
          content: const Text(
            'Cái thẻ này đã được chuyển hoá rồi nên không còn bản ghi âm '
            'nào nữa. Bạn chỉ có thể bấm nút Chuyển hoá thì có thể xem toàn '
            'bộ văn bản.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }
    final duLieu = _duLieuTheoTheGhiAm[soThe];
    if (duLieu == null || !mounted) return;
    await hienModalNgheLaiGhiAm(
      context,
      bytes: duLieu.bytes,
      mime: duLieu.mime,
    );
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
        const PopupMenuItem(
          value: 'nghe',
          child: Text('Nghe bản ghi âm này'),
        ),
        PopupMenuItem(
          value: 'xoa',
          child: Text('Xoá thẻ ghi âm này',
              style: TextStyle(color: Colors.red.shade600)),
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
        title: const Text('Xoá thẻ ghi âm?'),
        content: const Text('Thẻ này ĐANG được gửi đi phiên âm — xoá sẽ bỏ '
            'luôn kết quả sắp về, không thể phục hồi lại được. Bạn có chắc '
            'chắn muốn xoá không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không, giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Xoá', style: TextStyle(color: Colors.red.shade600)),
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

  /// Bấm Backspace/Delete ngay cạnh một thẻ, đủ để xoá một phần thẻ đó —
  /// `ChanSuaGiuaThe` đã CHẶN lại (không tự xoá) và báo về đây bằng đúng
  /// [batDau, ketThuc) của thẻ. Hỏi xác nhận y hệt cách xoá qua menu bấm-
  /// vào-thẻ, rồi mới xoá thật nếu đồng ý — không còn âm thầm xoá nữa.
  Future<void> _khiCanXoaTheTuBanPhim(int batDau, int ketThuc) async {
    if (!mounted) return;
    final vb = _boDieuKhien.text;
    if (ketThuc > vb.length) return;
    final doanThe = vb.substring(batDau, ketThuc);
    final khopHoanChinh = reTheGhiAmHoanChinh.firstMatch(doanThe);
    final khopDangChuyen = reTheDangChuyen.firstMatch(doanThe);
    final laDangGhi = doanThe == tenTokenDangGhiAm;
    if (khopHoanChinh == null && khopDangChuyen == null && !laDangGhi) {
      return; // đã đổi, bỏ qua.
    }

    // "Đang chuyển" thì chưa bao giờ có trong bộ nhớ đệm (mới gửi lần đầu,
    // còn đang bay) — luôn phải hỏi. "Ghi âm N" thì có thể đã có cache (do
    // vừa được hoàn tác về lại dạng thẻ) — có cache thì xoá thẳng, không hỏi.
    final soTheHoanChinh =
        khopHoanChinh != null ? int.parse(khopHoanChinh.group(1)!) : null;
    final coCache = soTheHoanChinh != null &&
        _vanBanDaTraVeTheoTheGhiAm.containsKey(soTheHoanChinh);

    var dongY = true;
    if (!coCache) {
      dongY = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Xoá thẻ ghi âm?'),
              content: Text(laDangGhi
                  ? 'Thẻ này ĐANG GHI ÂM — xoá sẽ HUỶ LUÔN bản ghi đang thu, '
                      'không thể phục hồi lại được. Bạn có chắc chắn muốn '
                      'xoá không?'
                  : khopDangChuyen != null
                      ? 'Thẻ này ĐANG được gửi đi phiên âm — xoá sẽ bỏ luôn '
                          'kết quả sắp về, không thể phục hồi lại được. Bạn '
                          'có chắc chắn muốn xoá không?'
                      : 'Thẻ ghi âm này sẽ bị xoá VĨNH VIỄN, không thể phục '
                          'hồi lại được. Bạn có chắc chắn muốn xoá không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Không, giữ lại'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Xoá',
                      style: TextStyle(color: Colors.red.shade600)),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!dongY || !mounted) return;

    if (laDangGhi) {
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
    if (ketThuc > vbHienTai.length ||
        vbHienTai.substring(batDau, ketThuc) != doanThe) {
      return; // văn bản đã đổi trong lúc chờ hỏi — đừng xoá nhầm chỗ khác.
    }
    _dieuChinhVungToanVanSauKhiSua(batDau, doanThe.length, 0);
    _dieuChinhLoiChinhTaSauKhiSua(batDau, doanThe.length, 0);
    final moi = vbHienTai.replaceRange(batDau, ketThuc, '');
    _ghiVaoO(moi, batDau);
    _henLuu();
    if (khopHoanChinh != null) {
      final soThe = soTheHoanChinh!;
      if (!coCache) {
        _duLieuTheoTheGhiAm.remove(soThe);
        _thoiLuongTheoTheGhiAm.remove(soThe);
        _theGhiAmDangGui.remove(soThe);
        if (_boDieuKhien.theGhiAmLoiTamThoi.remove(soThe)) {
          _boDieuKhien.veLai();
        }
      }
    } else if (khopDangChuyen != null) {
      final soThe = int.parse(khopDangChuyen.group(1)!);
      _duLieuTheoTheGhiAm.remove(soThe);
      _thoiLuongTheoTheGhiAm.remove(soThe);
      if (_boDieuKhien.theGhiAmLoiTamThoi.remove(soThe)) _boDieuKhien.veLai();
      // KHÔNG xoá khỏi `_theGhiAmDangGui` — yêu cầu Gemini có thể vẫn đang
      // bay; để nó tự no-op khi về (không còn tìm thấy nhãn "Đang chuyển").
    }
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
          title: const Text('Xoá thẻ ghi âm?'),
          content: Text('Thẻ ghi âm #$soThe sẽ bị xoá VĨNH VIỄN, không thể '
              'phục hồi lại được. Bạn có chắc chắn muốn xoá không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không, giữ lại'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Xoá', style: TextStyle(color: Colors.red.shade600)),
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

  void _bamNutMicro() {
    if (!_microDungDuocTrenThietBiNay) return;
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
  }

  /// Bàn phím vật lý bấm đúng tổ hợp phím tắt đang cài (mặc định Ctrl + G):
  /// tắt/mở micro, y hệt bấm nút. Trả về true để chặn phím này lan xuống ô
  /// văn bản (không thì gõ Ctrl+G trong lúc soạn thảo cũng gõ luôn chữ "g").
  bool _khiPhimTatMicro(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;

    // Đang có màn hình khác đè lên (Cài đặt, Thư mục, Hướng dẫn...) thì
    // không xử lý ở đây — kẻo đang gõ thử phím tắt trong màn Cài đặt lại vô
    // tình tắt/mở luôn micro của trang soạn thảo bên dưới.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final dungBoBienDoi = widget.caiDat.phimTatBoBienDoi == 'Ctrl'
        ? HardwareKeyboard.instance.isControlPressed
        : HardwareKeyboard.instance.isAltPressed;
    if (!dungBoBienDoi) return false;

    if (event.logicalKey.keyLabel.toUpperCase() !=
        widget.caiDat.phimTatPhim.toUpperCase()) {
      return false;
    }

    _bamNutMicro();
    return true;
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

    _ghiNhatKyMicro(
        'onResult(xong=$xong): "${noi.length > 120 ? '${noi.substring(0, 120)}…' : noi}"');

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
      _ghiNhatKyMicro('  → phần đuôi mới sau khi trừ raw lần trước: "$noi"');
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
  String _thutDauDongNeuCan(String vanBan, int viTri) {
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
      // còn phải XOÁ LUÔN dấu cách thừa đó trước khi xuống dòng.
      const kyTuDacBiet = {
        '.', ',', '!', '@', '#', '\$', '%', '^', '&', '*', '(', ')', '_', '+',
        '=', '?', '/', '>', '<', '{', '}', ']', '[',
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
  bool _giaoVoiVungAi(int batDau, int ketThuc) {
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

    KetQuaKiemTraChinhTaMoi ketQua;
    try {
      ketQua = await _dichVuChinhTa.kiemTra(
        doan,
        nguCanh: nguCanh,
        layLoiChinhTa: layLoiChinhTa,
        chenDauCau: chenDauCau,
      );
    } catch (_) {
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
    // đề xuất) trước đó thì không báo lỗi lại nữa, dù AI có tìm thấy y hệt.
    final loiChuaXuLy = ketQua.loi.where((l) => !_tuChinhTaDaXuLy.contains(l.tu)).toList();
    final loiDich = loiChuaXuLy.map((l) => l.dich(tuViTri)).toList();
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
          child: Text('Xoá', style: TextStyle(color: Colors.red.shade600)),
        ),
        PopupMenuItem(
          value: ('huy', null),
          child: Text('Huỷ đề xuất', style: TextStyle(color: Colors.green.shade700)),
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
  Future<void> _khiBamKiemTraToanVan() async {
    if (_dangKiemTraToanVan) return;
    final vanBan = _boDieuKhien.text;
    if (vanBan.trim().isEmpty) {
      _bao('Chưa có văn bản nào để kiểm tra.');
      return;
    }

    final daHuy = ValueNotifier<bool>(false);
    setState(() => _dangKiemTraToanVan = true);

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
            const Text(
              'AI đang kiểm tra lại toàn văn để soát lỗi chính tả - ngữ '
              'pháp, và đề xuất cách sửa đổi. Đây là bước quan trọng trước '
              'khi hoàn thiện văn bản.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.4),
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
              child: const Text('Dừng ngay lập tức'),
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
        vungDaXuLy: _vungToanVanDaXuLy(),
        chenDauCau: widget.caiDat.tuDongChenDauCauBangAI,
        khoangKyTu: widget.caiDat.khoangKyTuDeXuatHienTai(),
        cauLenhTuyChinh: widget.caiDat.cauLenhTuyChinhKiemTraToanVan,
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

    if (loiXayRa != null || ketQua == null) {
      _bao('Không kiểm tra được: $loiXayRa');
      return;
    }

    _apDungKetQuaToanVan(ketQua);
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
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('AI đã trả về kết quả'),
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
      items: const [
        PopupMenuItem(value: 'dung', child: Text('Dùng đề xuất này')),
        PopupMenuItem(value: 'bo', child: Text('Bỏ đề xuất này và trả lại như cũ')),
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
      items: const [
        PopupMenuItem(value: 'xoa', child: Text('Chấp nhận xoá đoạn văn này')),
        PopupMenuItem(value: 'khoiphuc', child: Text('Khôi phục đoạn văn này — không xoá')),
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
      _bao('Đã xoá đoạn văn.');
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
      _bao('Không thể hoàn tác thêm khi còn thẻ ghi âm chưa xử lý xong.');
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
      _bao('Không thể làm lại thêm khi còn thẻ ghi âm chưa xử lý xong.');
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
      if (baoKetQua) _bao('Chưa có chữ nào để chép.');
      return false;
    }
    await Clipboard.setData(ClipboardData(text: chu));
    if (baoKetQua && mounted) _bao('Đã sao chép tất cả');
    return true;
  }

  /// Xoá toàn bộ văn bản. Không hỏi xác nhận — Lùi lại (Ctrl + Z) đã là lưới
  /// an toàn cho việc xoá nhầm, nên thực hiện ngay khi bấm. Dùng chung cho
  /// mục "Xoá tất cả" và bước sau của "Sao chép rồi xoá tất cả" — [baoKetQua]
  /// tắt đi khi gọi từ đó với cùng lý do như ở [_chepTatCa].
  Future<bool> _xoaTatCa({bool baoKetQua = true}) async {
    if (_boDieuKhien.text.isEmpty) {
      if (baoKetQua) _bao('Trang đang trống, không có gì để xoá.');
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
    if (baoKetQua && mounted) _bao('Đã xoá tất cả');
    return true;
  }

  /// Sao chép rồi xoá tất cả, gộp hai thao tác trên thành một mục trong menu
  /// "+ Thêm lựa chọn" — tái dùng nguyên logic của cả hai, chỉ tự lo popup
  /// thông báo cuối cùng.
  Future<void> _chepRoiXoaTatCa() async {
    final daChep = await _chepTatCa(baoKetQua: false);
    if (!daChep || !mounted) return;
    await _xoaTatCa(baoKetQua: false);
    if (mounted) _bao('Đã sao chép tất cả và xoá');
  }

  void _moModalCaiDatKiemTraToanVan() {
    moModalCaiDatKiemTraToanVan(context, widget.caiDat);
  }

  /// Modal "Danh sách phím tắt" — đọc TRỰC TIẾP từ `CaiDat.phimTatCoDinh`
  /// (nguồn động DUY NHẤT, xem B6), cộng thêm dòng riêng cho "Bật/tắt micro"
  /// (đọc `widget.caiDat.phimTatBoBienDoi`/`phimTatPhim`, cũng động).
  void _moDanhSachPhimTat() {
    String tim(String khoa) => CaiDat.phimTatCoDinh[khoa] ?? khoa;

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
        title: const Text('Danh sách phím tắt'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                deMuc('Micro'),
                dong(
                  '${widget.caiDat.phimTatBoBienDoi} + ${widget.caiDat.phimTatPhim}',
                  'Bật/tắt micro',
                ),
                deMuc('Điều hướng'),
                dong('Ctrl + Z', tim('Ctrl+Z')),
                dong('Ctrl + Shift + Z', tim('Ctrl+Shift+Z')),
                deMuc('Chung'),
                dong('Ctrl + F', tim('Ctrl+F')),
                dong('Ctrl + A', tim('Ctrl+A')),
                dong('Ctrl + S', tim('Ctrl+S')),
                dong('Ctrl + X', tim('Ctrl+X')),
                dong('Ctrl + C', tim('Ctrl+C')),
                dong('Ctrl + V', tim('Ctrl+V')),
                deMuc('Định dạng văn bản'),
                dong('Ctrl + B', tim('Ctrl+B')),
                dong('Ctrl + I', tim('Ctrl+I')),
                dong('Ctrl + U', tim('Ctrl+U')),
                dong('Ctrl + Shift + X', tim('Ctrl+Shift+X')),
                dong('Ctrl + Shift + =', tim('Ctrl+Shift+Equal')),
                dong('Ctrl + =', tim('Ctrl+Equal')),
                dong('Ctrl + Shift + C', tim('Ctrl+Shift+C')),
                dong('Ctrl + Shift + H', tim('Ctrl+Shift+H')),
                dong('Ctrl + Q',
                    '${tim('Ctrl+Q')} — đưa văn bản về trạng thái ban đầu (không áp dụng cho các đoạn AI đang đề xuất)'),
                const SizedBox(height: 12),
                const Text(
                  'Để sử dụng phím tắt: Một ngón tay bấm và giữ im phím Ctrl, '
                  'sau đó ngón tay thứ hai bấm phím còn lại.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Color(0xFF5F6368)),
                ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _moModalTam(String tieuDe, IconData bieuTuong, [String? moTaThem]) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(bieuTuong, size: 28),
        title: Text(tieuDe),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tính năng đang nâng cấp.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (moTaThem != null) ...[
                const SizedBox(height: 12),
                Text(
                  moTaThem,
                  textAlign: TextAlign.left,
                  style: const TextStyle(height: 1.5, color: Color(0xFF5F6368)),
                ),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
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
        title: const Text('Không áp dụng được chữ trên'),
        content: const Text(
          'Định dạng chữ trên (superscript) chỉ áp dụng cho con số và chữ cái '
          '(chữ thường) trong bảng chữ cái Quốc tế.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
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

  Widget _nutVuongDieuHuongTep(IconData icon, String nhan, VoidCallback? khiBam) {
    return Tooltip(
      message: nhan,
      child: InkWell(
        onTap: khiBam,
        child: Container(
          width: _canhNutDieuHuongTep,
          height: _canhNutDieuHuongTep,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
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

  Widget _nutDieuHuongTep() {
    final ds = _dsGhiChuCungThuMuc();
    final viTriHienTai = ds.indexWhere((g) => g.id == _ghiChuHienTai.id);
    final coTruoc = viTriHienTai > 0;
    final coSau = viTriHienTai >= 0 && viTriHienTai < ds.length - 1;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _nutVuongDieuHuongTep(Icons.folder, 'Mở thư mục', _moManHinhThuMuc),
          _nutMoRongTep(),
          _nutVuongDieuHuongTep(
            Icons.arrow_back,
            'Tệp trước',
            coTruoc ? () => _chuyenTepTrongThuMuc(-1) : null,
          ),
          _nutVuongDieuHuongTep(
            Icons.arrow_forward,
            'Tệp sau',
            coSau ? () => _chuyenTepTrongThuMuc(1) : null,
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
      message: 'Mở rộng',
      child: PopupMenuButton<String>(
        tooltip: '',
        onSelected: (v) {
          switch (v) {
            case 'taoMoi':
              _taoTepMoiTuThanhCongCu();
            case 'xoa':
              _xoaTepHienTaiTuThanhCongCu();
            case 'mau':
              _chonMauTenTepHienTai();
          }
        },
        itemBuilder: (ctx) => const [
          PopupMenuItem(value: 'taoMoi', child: Text('Tạo Tệp văn bản mới')),
          PopupMenuItem(value: 'xoa', child: Text('Xoá Tệp văn bản này')),
          PopupMenuItem(value: 'mau', child: Text('Chọn màu Tên Tệp')),
        ],
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

  /// Thay cho `_oTenField()` khi Bộ phím nhanh đang TẠM ẨN
  /// (`_boPhimNhanhCamUngAn`) — ba nút "Hiện lại Bộ phím nhanh"/"Đóng
  /// lại"/nút con mắt chiếm đúng vùng tên tệp, để người dùng luôn thấy
  /// đường quay lại (hoặc tắt hẳn) ngay trong lúc đang gõ bằng bàn phím ảo
  /// hệ thống. Bọc trong `_HangNutBoPhimNhanhTamAn` để có hiệu ứng mờ-tỏ
  /// tuần hoàn kèm tên tệp hiện dần lên xen kẽ — xem widget đó.
  Widget _hangNutBoPhimNhanhTamAn() {
    return _HangNutBoPhimNhanhTamAn(
      onHienLai: _hienLaiBoPhimNhanhCamUng,
      onDong: _bamNutBoPhimNhanhCamUng,
      oTenField: _oTenField(),
    );
  }

  Widget _oTenField() {
    // Đọc lại `_ghiChuHienTai.mau` mỗi lần dựng — không cache riêng, nên
    // đổi màu ở màn hình thư mục (cùng tham chiếu `widget.kho`) hay ở nút
    // "Mở rộng" đều tự hiện đúng ngay lần dựng kế tiếp, không cần đồng bộ
    // tay giữa hai nơi.
    final mauTen = _ghiChuHienTai.mau;
    return TextField(
      controller: _tenController,
      focusNode: _oTen,
      maxLength: doDaiTenToiDa,
      inputFormatters: [FilteringTextInputFormatter.deny(kyTuCamTrongTen)],
      style: TextStyle(
        fontSize: 18,
        color: mauTen != null ? Color(mauTen) : Colors.black87,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        counterText: '',
      ),
      onSubmitted: (_) => _oTen.unfocus(),
    );
  }

  /// Mục 11: ẩn/hiện thanh định dạng thủ công (B/I/U/S/...) — chỉ một biến
  /// bool đơn giản, không cần lưu lại giữa các lần mở trang.
  bool _anThanhDinhDang = false;

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

  List<Widget> _dsNutCongCu() => [
        IconButton(
          onPressed: _lichSuLui.isEmpty ? null : _lui,
          icon: const Icon(Icons.undo, size: 22),
          tooltip: 'Lùi lại (Ctrl + Z)',
          visualDensity: VisualDensity.compact,
          constraints: _kichThuocNutTren,
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: _lichSuToi.isEmpty ? null : _toi,
          icon: const Icon(Icons.redo, size: 22),
          tooltip: 'Tiến tới (Ctrl + Shift + Z)',
          visualDensity: VisualDensity.compact,
          constraints: _kichThuocNutTren,
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: _bamNutLuu,
          icon: const Icon(Icons.save_outlined, size: 22),
          tooltip: 'Lưu',
          visualDensity: VisualDensity.compact,
          constraints: _kichThuocNutTren,
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: () => setState(() => _anThanhDinhDang = !_anThanhDinhDang),
          // Emoji "chữ" — các nút khác trong hai thanh này đều dùng
          // Material Icon (`Icon(IconData)`), nhưng không có icon Material
          // nào diễn tả đúng "thanh định dạng chữ"; dùng `Text` với cùng cỡ
          // icon (24) là cách nhất quán nhất còn lại (emoji render bình
          // thường qua `Text`, không cần gói phụ thuộc thêm).
          icon: const Text('🔤', style: TextStyle(fontSize: 18)),
          tooltip: _anThanhDinhDang ? 'Hiện thanh định dạng' : 'Ẩn thanh định dạng',
          visualDensity: VisualDensity.compact,
          constraints: _kichThuocNutTren,
          padding: EdgeInsets.zero,
        ),
        // "Thu gọn" — sát mép phải cùng (nút cuối trong danh sách, và danh
        // sách này dùng làm `actions` của AppBar hoặc nằm trong một
        // `Align(alignment: centerRight)`, nên tự nhiên luôn ở sát mép phải
        // màn hình). Ẩn HẲN mọi thanh công cụ phía trên (xem `build`), nhả
        // hết đất cho khung soạn thảo — nút "Mở rộng" nổi
        // (`_NutMoRongThanhCongCu`) trả lại như cũ.
        IconButton(
          onPressed: () => setState(() => _thuGonThanhCongCu = true),
          icon: const Icon(Icons.expand_less, size: 22),
          tooltip: 'Thu gọn — ẩn hết thanh công cụ phía trên',
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

  /// Hàng 4 nút mũi tên điều hướng con trỏ (Lên/Xuống/Trái/Phải) — nằm
  /// NGAY TRÊN hàng Copy/Cut/Paste/All/Home/End (`_xayHangCongCuVanBanCamUng`),
  /// cùng bật/tắt theo `_boPhimNhanhCamUngMo`. CHỈ dựng khi
  /// `!_dieuHuongConTroAn` — "rút gọn" thì ẩn HẲN cả hàng này (xem nơi gọi ở
  /// `build`), nút ẩn/hiện tự "nhảy" sang chỗ khác (xem
  /// `_NutAnHienDieuHuongConTro`).
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
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _NutPhimAo(
                        nhan: '↑',
                        icon: Icons.arrow_upward,
                        moTa: 'Lên — bấm giữ để đi liên tục',
                        rong: rongNut,
                        lapLai: true,
                        onTap: () => _diChuyenConTro(dy: -1),
                      ),
                      SizedBox(width: khoangCach),
                      _NutPhimAo(
                        nhan: '↓',
                        icon: Icons.arrow_downward,
                        moTa: 'Xuống — bấm giữ để đi liên tục',
                        rong: rongNut,
                        lapLai: true,
                        onTap: () => _diChuyenConTro(dy: 1),
                      ),
                      SizedBox(width: khoangCach),
                      _NutPhimAo(
                        nhan: '←',
                        icon: Icons.arrow_back,
                        moTa: 'Trái — bấm giữ để đi liên tục',
                        rong: rongNut,
                        lapLai: true,
                        onTap: () => _diChuyenConTro(dx: -1),
                      ),
                      SizedBox(width: khoangCach),
                      _NutPhimAo(
                        nhan: '→',
                        icon: Icons.arrow_forward,
                        moTa: 'Phải — bấm giữ để đi liên tục',
                        rong: rongNut,
                        lapLai: true,
                        onTap: () => _diChuyenConTro(dx: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _NutAnHienDieuHuongConTro(
              an: _dieuHuongConTroAn,
              onTap: _bamNutAnHienDieuHuongConTro,
            ),
          ],
        ),
      ),
    );
  }

  /// Hàng công cụ Copy/Cut/Paste/All/Home/End — nằm NGAY TRÊN hàng phím
  /// nhanh cảm ứng (`_xayHangPhimNhanhCamUng`), cùng bật/tắt theo
  /// `_boPhimNhanhCamUngMo`. Giữ NGUYÊN VĂN nhãn tiếng Anh theo yêu cầu,
  /// không dịch — Home/End có thông báo gợi ý "bấm 2 lần" ngay trong nhãn
  /// nút để người dùng biết trước, không cần bấm thử.
  Widget _xayHangCongCuVanBanCamUng() {
    // Màn hình hẹp: sát các nút vào nhau (không khoảng cách) và ép hẳn về
    // bên trái — nhường tối đa chỗ ngang để càng nhiều nút lọt vào khung
    // nhìn cùng lúc càng tốt, đỡ phải cuộn ngang mới thấy hết. Màn hình
    // rộng giữ khoảng cách 8 như cũ.
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;
    final khoangCach = manHinhHep ? 0.0 : 8.0;
    final cacNut = <Widget>[
      _NutCongCuChu(nhan: 'Copy', onTap: _phimAoCopy),
      _NutCongCuChu(nhan: 'Cut', onTap: _phimAoCut),
      _NutCongCuChu(nhan: 'Paste', onTap: _phimAoPaste),
      _NutCongCuChu(
        nhan: 'All',
        moTa: 'Chọn từ — bấm 2-4 lần: đoạn văn/cụm đoạn văn/tất cả',
        onTap: _phimAoChonTatCa,
      ),
      _NutCongCuChu(
        nhan: 'Home',
        moTa: 'Đầu dòng — bấm 2 lần: đầu văn bản',
        onTap: _phimAoHome,
      ),
      _NutCongCuChu(
        nhan: 'End',
        moTa: 'Cuối dòng — bấm 2 lần: cuối văn bản',
        onTap: _phimAoEnd,
      ),
      // "Rút gọn" (màn hình rộng): nút ẩn/hiện 4 nút điều hướng "nhảy" tới
      // đây, sát bên phải End — xem `_NutAnHienDieuHuongConTro`.
      if (_dieuHuongConTroAn && !manHinhHep)
        _NutAnHienDieuHuongConTro(an: true, onTap: _bamNutAnHienDieuHuongConTro),
    ];
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < cacNut.length; i++) ...[
                  if (i > 0) SizedBox(width: khoangCach),
                  cacNut[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hàng phím thay thế bàn phím hệ thống — nằm sát mép trên, ngay phía
  /// trên `ThanhCongCu`, khi "Bộ phím nhanh cho màn hình cảm ứng" đang mở.
  /// Nút X đỏ sát mép phải tắt hẳn công cụ, trả lại bàn phím ảo bình
  /// thường.
  /// "Ẩn" và "Đóng" luôn RỘNG BẰNG NHAU (áp dụng cả màn hình hẹp lẫn rộng)
  /// — nhãn "Đóng" (4 chữ) tự nhiên rộng hơn "Ẩn" (2 chữ) nếu để tự co theo
  /// nội dung, nên khoá cứng cùng một độ rộng, đo theo nhãn DÀI HƠN.
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
                alignment: Alignment.centerLeft,
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
            // Hai nút sát nhau, không khoảng cách giữa: "Ẩn" (cam, tạm ẩn —
            // xem `_anBoPhimNhanhCamUng`) bên trái, "Đóng" (đỏ, tắt hẳn) bên
            // phải — cùng bo góc NGOÀI của cụm, góc giữa vuông để dính liền.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Tạm ẩn Bộ phím nhanh, hiện bàn phím ảo',
                    child: InkWell(
                      onTap: () {},
                      onTapDown: (_) => _anBoPhimNhanhCamUng(),
                      child: Container(
                        width: _rongNutAnDong,
                        color: Colors.orange.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: const Text('Ẩn',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Đóng bộ phím nhanh cho màn hình cảm ứng',
                    child: InkWell(
                      onTap: () {},
                      onTapDown: (_) => _bamNutBoPhimNhanhCamUng(),
                      child: Container(
                        width: _rongNutAnDong,
                        color: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: const Text('Đóng',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bốn nút nhỏ của trình ghi âm + đồng hồ đếm giây — thay HẲN cho AppBar
  /// bình thường trong lúc trình ghi âm mở (xem nơi dùng ở `build`).
  /// Nút chữ/icon của thanh công cụ trình ghi âm — bắt `onTapDown` (không
  /// đợi `onTap`/nhấc tay) vì trên WEB, tiêu điểm DOM đang ở khung nhập
  /// (input ẩn phía sau khung soạn thảo) chuyển đi lúc nhấc tay có thể "ăn"
  /// mất đúng lượt chạm đầu, buộc phải chạm lần hai (không xảy ra ở app
  /// Android/iOS gốc vì không có input DOM nào cả).
  Widget _nutTrinhGhiAm(String nhan, VoidCallback onBam,
      {Color? mau, IconData? icon, bool manHinhHep = false}) {
    final mauThuc = mau ?? Theme.of(context).colorScheme.primary;
    // Màn hình hẹp: thu cỡ chữ/icon xuống bằng đúng cỡ "Đang ghi"/"Tạm dừng"
    // (12) — trước đó cố định 17 nên trên màn hẹp các nút dễ vỡ dòng/tràn.
    final coChu = manHinhHep ? 12.0 : 17.0;
    final coIcon = manHinhHep ? 13.0 : 17.0;
    return InkWell(
      onTap: () {},
      onTapDown: (_) => onBam(),
      borderRadius: BorderRadius.circular(6),
      // Đệm co lại tối thiểu — chỉ đủ vùng chạm, để cả thanh không cao hơn
      // mức cần thiết.
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: manHinhHep ? 4 : 8, vertical: manHinhHep ? 2 : 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: mauThuc, size: coIcon),
              SizedBox(width: manHinhHep ? 2 : 4),
            ],
            Text(
              nhan,
              style: TextStyle(
                  color: mauThuc, fontWeight: FontWeight.w600, fontSize: coChu),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _xayAppBarTrinhGhiAmThe() {
    final manHinhHep = MediaQuery.of(context).size.width < _nguongManHinhHep;
    return AppBar(
      backgroundColor: Colors.red.shade50,
      surfaceTintColor: Colors.red.shade50,
      elevation: 1,
      automaticallyImplyLeading: false,
      // Màn hình hẹp: bớt đệm hai bên tiêu đề để nhường thêm chỗ cho các nút
      // — màn hình rộng giữ 4 như cũ.
      titleSpacing: manHinhHep ? 0 : 4,
      // Dồn cả hai hàng (nút bấm + trạng thái/đồng hồ) vào ĐÚNG vùng
      // tiêu đề chính của AppBar — không còn hàng tiêu đề "Đang ghi âm"
      // rỗng ở trên cùng chiếm chỗ thừa, và cũng không cần một `bottom`
      // riêng nữa. Chiều cao để `null` (tự co theo nội dung) — nội dung
      // đã thu nhỏ hết mức (cỡ chữ thường, đệm tối thiểu) nên AppBar cũng
      // thấp hơn trước (76 → 68) — AppBar không tự co theo nội dung được,
      // phải khai số cụ thể; chọn dư một chút để phòng lúc `Wrap` phải
      // xuống dòng thứ hai trên màn hình hẹp (không thì bị cắt nội dung).
      toolbarHeight: 68,
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Căn GIỮA màn hình theo chiều ngang, không dạt về bên trái.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // `Wrap` (không phải cuộn ngang) để cả cụm nút luôn nằm giữa
            // — không vừa một dòng thì tự xuống dòng, không cần cuộn.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: manHinhHep ? 2 : 4,
              runSpacing: 2,
              children: [
                Tooltip(
                  message: _tuDongGuiNgamTheGhiAm
                      ? 'Tự động gửi ngầm thẻ ≥20s: đang BẬT (bấm để tắt)'
                      : 'Tự động gửi ngầm thẻ ≥20s: đang TẮT (bấm để bật)',
                  child: InkWell(
                    onTap: () {},
                    onTapDown: (_) => _bamNutTuDongGuiNgamTheGhiAm(),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        _tuDongGuiNgamTheGhiAm
                            ? Icons.cloud_sync
                            : Icons.cloud_sync_outlined,
                        color: _tuDongGuiNgamTheGhiAm
                            ? Colors.deepPurple
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Thay cho "Tạo văn bản" (từng thẻ đã có sẵn lựa chọn
                // này trong menu riêng của nó) — chỉ hiện khi có một
                // thẻ đang ghi (kể cả đang tạm dừng).
                if (_soTheGhiAmDangGhi != null)
                  _nutTrinhGhiAm(
                    'Dừng và hoàn thành ghi âm',
                    _dungVaHoanThanhGhiAmThe,
                    manHinhHep: manHinhHep,
                  ),
                _nutTrinhGhiAm(
                  'Tạo phiên ghi âm mới',
                  _taoPhienGhiAmMoiThe,
                  mau: Colors.green.shade700,
                  manHinhHep: manHinhHep,
                ),
                _nutTrinhGhiAm(
                  'Đóng trình ghi âm',
                  _dongTrinhGhiAmThe,
                  mau: Colors.red.shade700,
                  icon: Icons.cancel,
                  manHinhHep: manHinhHep,
                ),
              ],
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_soTheGhiAmDangGhi != null)
                    _theGhiAmDangTamDung
                        ? Text('Tạm dừng',
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))
                        : _ChuLuonSong(chu: 'Đang ghi', mau: Colors.red.shade700),
                  const SizedBox(width: 4),
                  ValueListenableBuilder<Duration>(
                    valueListenable: _thoiLuongTheGhiAmDangGhi,
                    builder: (context, gia, _) => Text(
                      '${dinhDangMmSs(gia)} / ${dinhDangMmSs(_gioiHanMoiTheGhiAm)}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_soTheGhiAmDangGhi != null)
                    InkWell(
                      onTap: () {},
                      onTapDown: (_) => _theGhiAmDangTamDung
                          ? _tiepTucTheGhiAmHienTai()
                          : _tamDungTheGhiAmHienTai(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _theGhiAmDangTamDung
                                  ? Icons.play_circle_outline
                                  : Icons.pause_circle_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _theGhiAmDangTamDung ? 'Tiếp tục' : 'Dừng lại',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tự đo chiều cao bàn phím thay vì giao cho Scaffold: đặt thanh công cụ
    // làm dòng cuối của thân trang rồi chừa đúng khoảng đó bên dưới, thì
    // thanh luôn nằm khít mép trên bàn phím.
    final caoBanPhim = MediaQuery.viewInsetsOf(context).bottom;
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;

    // Màn hình rộng (máy tính bảng): tên tệp và công cụ chung một dòng, như
    // thiết kế gốc. Màn hình hẹp (điện thoại): tên tệp một dòng riêng, công
    // cụ xuống dòng thứ hai — không thì tên tệp dài bị công cụ đè lên, hoặc
    // ngược lại công cụ bị ép chật tới mức khó bấm trúng.
    final appBar = manHinhHep
        ? AppBar(
            // Màn hình hẹp: bốn nút thư mục/mở rộng/tệp trước/tệp sau KHÔNG
            // còn nằm cùng dòng với tên tệp nữa — dồn hết xuống dòng dưới,
            // sát mép trái, cùng dòng với Lùi/Tiến/Lưu/Ẩn-hiện-định-dạng.
            // Tên tệp một mình đứng riêng một dòng phía trên (đủ chỗ đọc tên
            // dài, không bị bốn nút kia chèn vào nữa).
            title: (_boPhimNhanhCamUngMo && _boPhimNhanhCamUngAn) ? _hangNutBoPhimNhanhTamAn() : _oTenField(),
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
                          child: Row(children: _dsNutCongCu()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : AppBar(
            leading: _nutDieuHuongTep(),
            leadingWidth: _canhNutDieuHuongTep * 4 + 4,
            title: (_boPhimNhanhCamUngMo && _boPhimNhanhCamUngAn) ? _hangNutBoPhimNhanhTamAn() : _oTenField(),
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
          : (_trinhGhiAmMo ? _xayAppBarTrinhGhiAmThe() : (_thuGonThanhCongCu ? null : appBar)),
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
            if (!_anThanhDinhDang && !_hienThanhTimKiem && !_trinhGhiAmMo && !_thuGonThanhCongCu)
              Divider(height: 1, thickness: 1, color: Colors.grey.withValues(alpha: 0.12)),
            if (!_anThanhDinhDang && !_hienThanhTimKiem && !_trinhGhiAmMo && !_thuGonThanhCongCu)
              _thanhDinhDangThuCong(),
            // Mục 7: và một đường kẻ mỏng nữa ở mép dưới thanh định dạng,
            // phân tách nó với vùng soạn thảo bên dưới.
            if (!_anThanhDinhDang && !_hienThanhTimKiem && !_trinhGhiAmMo && !_thuGonThanhCongCu)
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
                          readOnly: _boPhimNhanhCamUngMo && !_boPhimNhanhCamUngAn,
                          // Chặn sửa/xoá từng-ký-tự-riêng-lẻ bên trong một
                          // thẻ ghi âm — xem `ChanSuaGiuaThe`.
                          inputFormatters: [
                            ChanSuaGiuaThe(khiCanXoaThe: _khiCanXoaTheTuBanPhim),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_boPhimNhanhCamUngMo && !_boPhimNhanhCamUngAn && !_dieuHuongConTroAn)
              _xayHangDieuHuongConTro(),
            if (_boPhimNhanhCamUngMo && !_boPhimNhanhCamUngAn) _xayHangCongCuVanBanCamUng(),
            if (_boPhimNhanhCamUngMo && !_boPhimNhanhCamUngAn) _xayHangPhimNhanhCamUng(),
            // Bọc riêng bằng ValueListenableBuilder (xem chú thích ở
            // `_songAmTick`) — CHỈ ThanhCongCu dựng lại mỗi lần sóng âm đổi
            // (tới 5 lần/giây lúc ghi âm/nghe), không đụng tới AppBar trình
            // ghi âm hay phần còn lại của trang.
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
                sanSang: _sanSang &&
                    _microDungDuocTrenThietBiNay &&
                    !_ghiAmTheDangKhoaMicro,
                hienChuThich: _hienChuThich,
                khiBamChuThich: _khiBamChuThich,
                nhanPhimTat: '${widget.caiDat.phimTatBoBienDoi} + ${widget.caiDat.phimTatPhim}',
                // Bàn phím đóng thì còn phải né thanh điều hướng của máy; bàn
                // phím mở thì nó che mất thanh đó rồi, né nữa là hở một dải
                // trắng giữa thanh công cụ và bàn phím.
                neThanhDieuHuong: caoBanPhim == 0,
                khiBamMicro: _bamNutMicro,
                khiBamThuMuc: _moManHinhThuMuc,
                khiBamCaiDat: _moCaiDat,
                khiBamHuongDan: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManHinhHuongDan()),
                ),
                khiBamCaiDatKiemTraToanVan: _moModalCaiDatKiemTraToanVan,
                khiBamBanPhim: () => _moModalTam(
                  'Bàn phím',
                  Icons.keyboard_outlined,
                  'Bàn phím riêng của Flowrite sẽ cho bạn tự chọn ngôn ngữ và '
                      'kiểu gõ, tích hợp sẵn nhiều ngôn ngữ và kiểu gõ khác '
                      'nhau trong cùng một nơi.\n\n'
                      'Hữu ích nhất cho máy chưa cài sẵn bàn phím ngôn ngữ '
                      'mình cần, hoặc khi bạn muốn dùng hẳn bàn phím và bộ gõ '
                      'riêng của Flowrite thay vì bàn phím mặc định của máy.',
                ),
                khiBamBoPhimNhanh: _bamNutBoPhimNhanhCamUng,
                boPhimNhanhDangMo: _boPhimNhanhCamUngMo,
                noiBatBoPhimNhanh:
                    kIsWeb && (_thietBiHienTai == ThietBi.android || _thietBiHienTai == ThietBi.iphone),
                khiBamKiemTraToanVan: _khiBamKiemTraToanVan,
                dangGhiAmThe: _trinhGhiAmMo,
                khiBamGhiAmThe: _bamNutGhiAmThe,
                gopMicVaGhiAmThanhMotNut:
                    kIsWeb && _thietBiHienTai == ThietBi.iphone,
                khiBamChepTatCa: () => _chepTatCa(),
                khiBamChepRoiXoaTatCa: _chepRoiXoaTatCa,
                khiBamXoaTatCa: () => _xoaTatCa(),
                khiBamDanhSachPhimTat: _moDanhSachPhimTat,
                khiBamTimKiem: () => _hienThanhTimKiem ? _dongTimKiem() : _moTimKiem(),
                khiBamTroChuyen: () {},
                khiBamTaiKhoan: () {},
                  ),
                ),
                // "Rút gọn" (màn hình hẹp): nút ẩn/hiện 4 nút điều hướng
                // "nhảy" tới đây, đè lên đúng nút "Hướng dẫn" (luôn ở sát
                // mép trái của `ThanhCongCu`) — widget này nằm TRÊN trong
                // Stack nên tự nhận hết cử chỉ bấm tại đúng vùng đó, nút
                // "Hướng dẫn" bên dưới vì vậy không bấm được nữa cho tới khi
                // hiện lại 4 nút điều hướng.
                if (_boPhimNhanhCamUngMo &&
                    !_boPhimNhanhCamUngAn &&
                    _dieuHuongConTroAn &&
                    MediaQuery.sizeOf(context).width < _nguongManHinhHep)
                  Positioned(
                    left: 4,
                    top: 4,
                    child: _NutAnHienDieuHuongConTro(an: true, onTap: _bamNutAnHienDieuHuongConTro),
                  ),
              ],
            ),
            SizedBox(height: caoBanPhim),
          ],
        ),
        ),
          ),
          if (_thuGonThanhCongCu)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 4,
              right: 8,
              child: _NutMoRongThanhCongCu(
                onTap: () => setState(() => _thuGonThanhCongCu = false),
              ),
            ),
        ],
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
            tooltip: 'Chọn màu khác',
            icon: const Icon(Icons.arrow_drop_down),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                title: const Text('Chọn màu'),
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
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Đóng'),
                  ),
                ],
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
