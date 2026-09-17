// Trang soạn thảo — một trang văn bản trắng, gõ phím và nói bằng micro cùng
// lúc. Mọi chữ — dù đến từ bàn phím hay từ micro — đều rơi vào đúng vị trí
// con trỏ. Micro không tắt khi người dùng gõ phím; ngược lại, gõ phím ngắt
// hẳn micro trong một giây rồi tự bật lại.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'cai_dat.dart';
import 'ghi_am_ai.dart';
import 'kho_du_lieu.dart';
import 'kiem_tra_chinh_ta.dart';
import 'kiem_tra_toan_van.dart';
import 'man_hinh_cai_dat.dart';
import 'man_hinh_thu_muc.dart';
import 'modal_cai_dat_kiem_tra_toan_van.dart';
import 'mo_hinh.dart';
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

/// (VIỆC 2) Bản ghi 8 giá trị định dạng — kiểu trả về DUY NHẤT của
/// `_dinhDangHopTaiViTri`, dùng chung cho CẢ việc tô sáng nút toolbar LẪN
/// việc quyết định định dạng của ký tự mới chèn. Không có hai nguồn tính
/// riêng rẽ nào khác — đây chính là bài học từ các lỗi "bộ nhớ đệm" trước.
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
class _VeChamCuoiVanBan extends CustomPainter {
  _VeChamCuoiVanBan({
    required this.re,
    required this.khungBox,
    required this.viTri,
    required this.duongKinh,
    required this.mau,
  });
  final RenderEditable re;
  final RenderBox khungBox;
  final int viTri;
  final double duongKinh;
  final Color mau;

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
      diem.dx + 2 + duongKinh / 2,
      diem.dy + goc.height / 2,
    );
    canvas.drawCircle(tam, duongKinh / 2, Paint()..color = mau);
  }

  @override
  bool shouldRepaint(covariant _VeChamCuoiVanBan cu) => true;
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

  void _moTimKiem() {
    setState(() => _hienThanhTimKiem = true);
    _capNhatKetQuaTimKiem();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusTimKiem.requestFocus());
  }

  void _dongTimKiem() {
    setState(() {
      _hienThanhTimKiem = false;
      _oTimKiem.clear();
      _ketQuaTimKiem = [];
      _chiSoTimKiemHienTai = -1;
    });
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

  void _capNhatKetQuaTimKiem() {
    if (_dangCapNhatTimKiem) return;
    _dangCapNhatTimKiem = true;
    try {
      final tuKhoa = _oTimKiem.text;
      final vb = _boDieuKhien.text;
      final ds = <int>[];
      if (tuKhoa.isNotEmpty) {
        final vbHa = vb.toLowerCase();
        final tkHa = tuKhoa.toLowerCase();
        var vt = 0;
        while (true) {
          final i = vbHa.indexOf(tkHa, vt);
          if (i < 0) break;
          ds.add(i);
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

  /// Mấy mức âm gần nhất, để vẽ sóng. Mới nhất nằm ở cuối.
  final List<double> _songAm = List<double>.filled(16, 0);

  /// Vị trí bắt đầu của câu đang đọc dở, và ĐÚNG đoạn chữ tạm đã chèn ở đó.
  ///
  /// Giữ nguyên văn đoạn chữ chứ không chỉ giữ độ dài: trước mỗi lần ghi, ta
  /// đọc lại trong bài xem đoạn đó còn nguyên ở chỗ cũ không. Còn thì đè lên,
  /// không còn thì coi như câu mới. Nhờ vậy mốc có lệch cũng không lặp chữ.
  int _neo = 0;
  String _chuTam = '';

  /// Đúng nguyên văn `recognizedWords` (chưa chèn dấu cách nào của ta) của
  /// lần cập nhật gần nhất đã CHẤP NHẬN cho đoạn đang đọc dở — dùng để chặn
  /// bộ nhận dạng quay lại rút ngắn/sửa chữ đã hiện lên màn hình (xem
  /// `_khiCoChu`). Luôn coi là rỗng bất cứ khi nào `_chuTam` rỗng (đoạn mới).
  String _noiGocDaKhoa = '';

  /// Số lần liên tiếp một kết quả tạm bị TỪ CHỐI (xem `_khiCoChu`) vì không
  /// nối dài đúng phần đã khoá. Chỉ chặn tối đa MỘT lần liên tiếp — bộ nhận
  /// dạng thỉnh thoảng "nghĩ lại" một lần rồi thôi thì chặn được cái đó,
  /// nhưng nếu nó cứ liên tục trả về khác hẳn (ví dụ autoPunctuation viết
  /// lại nguyên câu khi có thêm ngữ cảnh), chặn mãi sẽ làm sóng âm vẫn chạy
  /// mà không ra chữ nào cả — bắt buộc phải nhượng bộ sau lần từ chối đầu.
  int _soLanTuChoiLienTuc = 0;

  static bool _laKhoangTrang(String kyTu) =>
      kyTu == ' ' || kyTu == '\n' || kyTu == '\t';

  /// Các dấu câu tự động "nhảy" qua trước một dấu cách có sẵn khi gõ tay —
  /// xem chỗ dùng trong `_apDungChinhSuaNguoiDung`.
  static const _kyTuDacBiet = {'.', ',', ';', '?', '!', ':', ')'};

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
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 17, height: 1.5, color: mauChuMo),
        children: [
          TextSpan(
            text: 'Gõ chữ và bấm Micro để nói...\n'
                'Thực hiện song song hai việc trên cùng lúc.\n'
                'Vui lòng đọc hướng dẫn và mẹo sử dụng App (Nút ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.help_outline_rounded, size: 16, color: mauChuMo),
          ),
          TextSpan(text: ')'),
        ],
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
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _VeChamCuoiVanBan(
            re: re,
            khungBox: khungBox,
            viTri: chu.length,
            duongKinh: 17.0,
            mau: const Color(0xFF6A1B9A),
          ),
        ),
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

  /// Thanh tìm kiếm nổi lên trên cùng khung soạn thảo — ô nhập, số kết quả,
  /// mũi tên lên/xuống, nút xoá và nút "Tắt" (đóng hẳn).
  Widget _thanhTimKiem() {
    return Container(
      key: const ValueKey('thanhTimKiem'),
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
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
          const SizedBox(width: 8),
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
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Kết quả tiếp theo',
            onPressed: _ketQuaTimKiem.isEmpty ? null : () => _dieuHuongTimKiem(1),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Xoá nội dung tìm',
            onPressed: () => _oTimKiem.clear(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: _dongTimKiem,
            child: const Text('Tắt'),
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
    _tenController = TextEditingController(text: _ghiChuHienTai.ten);
    _oTen.addListener(_khiOTenMatFocus);

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
    _oTimKiem.addListener(_capNhatKetQuaTimKiem);

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
    _micro.cancel();
    _boDieuKhien.dispose();
    _oChu.dispose();
    _cuonVanBan.dispose();
    _tenController.dispose();
    _oTen.dispose();
    _oTimKiem.dispose();
    _focusTimKiem.dispose();
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
          // Người dùng vừa tắt "kiểm tra chính tả bằng AI": xoá hết gạch đỏ
          // đang hiển thị ngay, vì đó là dữ liệu riêng của trang soạn thảo,
          // màn Cài đặt không cầm được.
          khiTatKiemTraChinhTa: () {
            _boDieuKhien.loi.clear();
            _boDieuKhien.veLai();
          },
          khiKiemTraLaiMicro: _khoiTaoMicro,
        ),
      ),
    );
    // Phím tắt có thể vừa đổi trong màn Cài đặt — vẽ lại nhãn hiện trên nút
    // micro cho khớp giá trị mới nhất.
    if (mounted) setState(() {});
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
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    _viTriDaKiemTraChinhTa = g.noiDung.length;

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
        final nhe = loi.errorMsg == 'error_no_match' ||
            loi.errorMsg == 'error_speech_timeout' ||
            loi.errorMsg == 'error_client';
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
    if (!dangChay) _henBatLai();
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
          _khiCoChu(ketQua);
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

  void _bamNutMicro() {
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
    setState(() {
      for (var i = 0; i < _songAm.length - 1; i++) {
        _songAm[i] = _songAm[i + 1];
      }
      _songAm[_songAm.length - 1] = chuan;
    });
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
    _noiGocDaKhoa = '';
  }

  /// Coi phần chữ tạm hiện tại là đã xong, và dời neo ra sau nó.
  void _chotCauDangDoc() {
    _neo += _chuTam.length;
    _chuTam = '';
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
    // `dinhDang`, vì hàm đó đọc theo toạ độ CŨ. Đây là NGUỒN DUY NHẤT quyết
    // định định dạng của chữ vừa được giọng nói chèn — không có override nào
    // khác chen vào (xem `_dinhDangHopTaiViTri`).
    final hopMoi = _dinhDangHopTaiViTri(_neo, het, cu.length);

    _dieuChinhLoiChinhTaSauKhiSua(_neo, het - _neo, chenVao.length);
    _dieuChinhVungToanVanSauKhiSua(_neo, het - _neo, chenVao.length);
    if (chenVao.isNotEmpty) {
      _apDinhDangHopChoDoanMoiChen(_neo, _neo + chenVao.length, hopMoi);
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

  void _khiCoChu(dynamic ketQua) {
    final noi = (ketQua.recognizedWords as String? ?? '').trim();
    final xong = ketQua.finalResult as bool? ?? false;

    // Người dùng vừa gõ phím giữa chừng: chữ đã hiện ra phải nằm im. Nuốt hết
    // phần còn lại của câu này, chờ câu mới.
    if (_boQuaCauNay) {
      if (xong) _boQuaCauNay = false;
      return;
    }
    if (noi.isEmpty) return;

    final cu = _boDieuKhien.text;

    // Không tin vào mốc suông. Đoạn tạm không còn nguyên thì bắt đầu lại từ
    // chỗ con trỏ, coi như đây là câu mới.
    if (!_vungTamConNguyen(cu)) {
      final chon = _boDieuKhien.selection;
      _neo = chon.isValid ? chon.end : cu.length;
      if (_neo > cu.length) _neo = cu.length;
      if (_neo < 0) _neo = 0;
      _chuTam = '';
    }

    // Chặn hồi tố: bộ nhận dạng thỉnh thoảng "nghĩ lại" và trả về một bản
    // NGẮN HƠN hoặc KHÁC HẲN cho cùng một đoạn đang đọc dở — nhìn như thể
    // micro tự quay lại sửa/xoá chữ đã hiện lên màn hình. Chữ đã hiện ra rồi
    // thì phải CHẾT CỨNG: chỉ chấp nhận cập nhật khi `noi` nối dài thêm đúng
    // từ phần đã khoá (`_noiGocDaKhoa`); coi như đoạn mới (`_chuTam` rỗng)
    // thì không có gì để khoá, chấp nhận bất cứ nội dung nào.
    //
    // Chỉ chặn tối đa MỘT lần liên tiếp (`_soLanTuChoiLienTuc`): nếu bộ nhận
    // dạng cứ liên tục trả về khác hẳn phần đã khoá (ví dụ autoPunctuation
    // viết lại nguyên câu khi có thêm ngữ cảnh), chặn mãi sẽ làm sóng âm vẫn
    // chạy mà không ra chữ nào cả — phải nhượng bộ sau lần từ chối đầu.
    final coBanDaKhoa = _chuTam.isEmpty ? '' : _noiGocDaKhoa;
    final chapNhan = noi.startsWith(coBanDaKhoa) || _soLanTuChoiLienTuc >= 1;
    if (chapNhan) {
      _soLanTuChoiLienTuc = 0;
      _noiGocDaKhoa = noi;

      var chen = noi;
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
      if (widget.caiDat.tuDongChenKhoangCach && !_laKhoangTrang(chen[chen.length - 1])) {
        chen = '$chen ';
      }

      if (chen != _chuTam) {
        // _chuTam rỗng nghĩa là đây là mẩu đầu tiên của một đoạn nói MỚI
        // (đoạn trước, nếu có, đã chốt xong và xoá _chuTam ở _chotCauDangDoc)
        // — đúng ranh giới cần lưu một điểm mốc Lùi lại riêng, để một bài dài
        // nói nhiều lần vẫn lùi được từng đoạn một, không gộp chung cả bài
        // thành một bước.
        if (_chuTam.isEmpty) {
          _luuDiemMoc(vanBan: cu, viTriConTro: _neo);
        }
        _thayVungTamBangGiongNoi(chen);
      }
    } else {
      _soLanTuChoiLienTuc++;
    }

    if (xong) {
      _chotCauDangDoc();
      _noiGocDaKhoa = '';
      _soLanTuChoiLienTuc = 0;
      _luuVanBan();
      _lenLichKiemTraChinhTa();
    }
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

    if (_muonNghe || _micro.isListening) {
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
    if (!dangVietDo) return;
    if (!_muonNghe || _dangCatCau || !_micro.isListening) return;
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
    _neo = chon.end;
    _dongBangDoanDangNhay();
  }

  void _apDungChinhSuaNguoiDung(String chuMoi) {
    final cu = _chuGanNhat;

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
    // đọc theo toạ độ CŨ. Đây là NGUỒN DUY NHẤT quyết định định dạng của ký
    // tự vừa gõ — không có "bộ nhớ đệm"/override nào khác chen vào (xem
    // `_dinhDangHopTaiViTri`), và cùng một hàm này cũng quyết định nút nào
    // sáng trên thanh công cụ (xem `_tinhTrangThaiDinhDangHienTai`).
    final hopMoi = _dinhDangHopTaiViTri(dau, dau + soLuongXoa, cu.length);

    _dieuChinhLoiChinhTaSauKhiSua(
      dau,
      soLuongXoa,
      doDaiChenVao,
      vanBanCu: cu,
      vanBanMoi: chuMoi,
    );
    _dieuChinhVungToanVanSauKhiSua(dau, soLuongXoa, doDaiChenVao);
    if (doDaiChenVao > 0) {
      _apDinhDangHopChoDoanMoiChen(dau, dau + doDaiChenVao, hopMoi);
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
    }

    final chon = _boDieuKhien.selection;
    final viTriConTro = chon.isValid ? chon.end : chuMoiCuoi.length;

    _neo = viTriConTro;
    _nguoiDungVuaGo();
    _ghiVaoO(chuMoiCuoi, viTriConTro);
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

  // ---------------------------------------------------- ghi âm xong mới ra chữ

  /// Bấm nút "Ghi âm xong mới ra chữ": mở bảng ghi âm, chèn kết quả phiên âm
  /// vào đúng vị trí con trỏ nếu có. Việc ghi âm, gửi lên AI, chờ kết quả
  /// đều nằm trọn trong `moBangGhiAmAI` — ở đây chỉ lo phần chèn vào bài.
  Future<void> _khiBamGhiAmAI() async {
    final ketQua = await moBangGhiAmAI(context);
    if (ketQua == null || ketQua.trim().isEmpty || !mounted) return;
    _chenVanBanTuGhiAmAI(ketQua.trim());
  }

  /// Chèn văn bản mới vào đúng vị trí con trỏ, rồi cho nó nhấp nháy xanh/đen
  /// 4 giây trước khi hoá đen như chữ thường — dùng lại nguyên cơ chế nhấp
  /// nháy của "đoạn không phù hợp" (coi như đoạn GỐC rỗng, chỉ có đoạn ĐỀ
  /// XUẤT, và nhảy thẳng vào trạng thái "đã chọn dùng đề xuất").
  void _chenVanBanTuGhiAmAI(String vanBanMoi) {
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
  Color? _mauChuDangCho;
  Color? _mauNenDangCho;

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
    // Không có "bộ nhớ đệm"/override nào để đặt nữa (đã bỏ hẳn), và vùng
    // chọn rỗng thì cũng không có vùng nào để áp — bấm nút/phím tắt lúc này
    // ĐƠN GIẢN LÀ KHÔNG LÀM GÌ: không lưu mốc lịch sử, không đổi `dinhDang`,
    // không đụng tới các cờ `_xxxDangCho` (chúng chỉ do
    // `_tinhTrangThaiDinhDangHienTai` ghi, phản ánh "hợp 2 bên" tại con trỏ).
    if (!chon.isValid || chon.isCollapsed) {
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

    return (
      dam: hopCo((d) => d.dam),
      nghieng: hopCo((d) => d.nghieng),
      gachChan: hopCo((d) => d.gachChan),
      gachNgang: hopCo((d) => d.gachNgang),
      treMu: hopCo((d) => d.treMu),
      treChan: hopCo((d) => d.treChan),
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

  void _lui() {
    if (_lichSuLui.isEmpty) return;
    _lichSuToi.add(_chupTrangThai(
      vanBan: _boDieuKhien.text,
      viTriConTro: _viTriConTroHienTai(),
    ));
    final truoc = _lichSuLui.removeLast();
    // setState trần NGAY tại đây (không đợi _apDungTrangThai) — nút Lùi/Tiến
    // trên AppBar phải phản ánh đúng độ dài hai danh sách vừa đổi ngay lập
    // tức, kẻo bấm liên tiếp trước khi khung hình kịp vẽ lại sẽ tưởng nút
    // chưa hoạt động.
    setState(() {});
    _apDungTrangThai(truoc);
  }

  void _toi() {
    if (_lichSuToi.isEmpty) return;
    _lichSuLui.add(_chupTrangThai(
      vanBan: _boDieuKhien.text,
      viTriConTro: _viTriConTroHienTai(),
    ));
    final sau = _lichSuToi.removeLast();
    setState(() {});
    _apDungTrangThai(sau);
  }

  void _apDungTrangThai(_TrangThaiVanBan tt) {
    // An toàn trước: đừng để một kết quả giọng nói còn treo ghi đè lên đúng
    // lúc vừa khôi phục xong.
    if (_muonNghe) _tatMicro();
    _chuTam = '';
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

  void _bao(String loi) {
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
            child: Text(
              loi,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
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

  Widget _oTenField() {
    return TextField(
      controller: _tenController,
      focusNode: _oTen,
      maxLength: doDaiTenToiDa,
      inputFormatters: [FilteringTextInputFormatter.deny(kyTuCamTrongTen)],
      style: const TextStyle(fontSize: 18, color: Colors.black87),
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
      ];

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
            title: _oTenField(),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            bottom: PreferredSize(
              // Phần B: 40px trước đây còn dư khá nhiều quanh nút 36x36 mới
              // (36 + một chút đệm trên/dưới cho viền chạm là đủ) — 38px sát
              // hơn, không cắt icon.
              preferredSize: const Size.fromHeight(38),
              child: SizedBox(
                height: 38,
                // Chỉ còn 3 nút (Lùi/Tiến/Lưu) sau khi dời phần còn lại vào
                // menu "+ Thêm lựa chọn" — Align đẩy cả cụm sát mép phải
                // thay vì nằm lệch trái như một Row thường trong
                // SingleChildScrollView.
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _dsNutCongCu()),
                  ),
                ),
              ),
            ),
          )
        : AppBar(
            title: _oTenField(),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            actions: _dsNutCongCu(),
          );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      // translucent: chỉ NGHE sự kiện chạm để tắt chú thích, không chặn nó
      // đi tiếp xuống nút/ô bên dưới — một cú bấm vừa tắt chú thích vừa làm
      // đúng việc của nút đó (mở cài đặt, bật micro...).
      body: Listener(
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
            // Mục 7: đường kẻ mỏng phân tách thanh Lùi/Tiến/Lưu (AppBar) với
            // thanh định dạng thủ công ngay dưới nó. Mờ hơn nữa (0.12 thay
            // vì màu `Colors.grey` mặc định gần như đen-xám) — chỉ đủ để mắt
            // nhận ra có ranh giới, không tạo thêm một "đường kẻ đậm" nhìn
            // rối mắt giữa hai thanh vốn đã sát nhau.
            if (!_anThanhDinhDang)
              Divider(height: 1, thickness: 1, color: Colors.grey.withValues(alpha: 0.12)),
            if (!_anThanhDinhDang) _thanhDinhDangThuCong(),
            // Mục 7: và một đường kẻ mỏng nữa ở mép dưới thanh định dạng,
            // phân tách nó với vùng soạn thảo bên dưới.
            if (!_anThanhDinhDang)
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
                        TextField(
                          key: _oVanBanKey,
                          controller: _boDieuKhien,
                          focusNode: _oChu,
                          scrollController: _cuonVanBan,
                          maxLines: null,
                          expands: true,
                          autofocus: true,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: _kieuVanBan,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ThanhCongCu(
              bat: _muonNghe,
              dangNghe: _dangNghe,
              songAm: _songAm,
              sanSang: _sanSang,
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
              khiBamKiemTraToanVan: _khiBamKiemTraToanVan,
              khiBamGhiAmAI: _khiBamGhiAmAI,
              khiBamChepTatCa: () => _chepTatCa(),
              khiBamChepRoiXoaTatCa: _chepRoiXoaTatCa,
              khiBamXoaTatCa: () => _xoaTatCa(),
              khiBamDanhSachPhimTat: _moDanhSachPhimTat,
              khiBamTimKiem: () => _hienThanhTimKiem ? _dongTimKiem() : _moTimKiem(),
              khiBamTroChuyen: () {},
              khiBamTaiKhoan: () {},
            ),
            SizedBox(height: caoBanPhim),
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
