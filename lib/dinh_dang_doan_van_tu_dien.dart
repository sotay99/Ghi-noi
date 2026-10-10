// (YÊU CẦU MỚI) Bản PUBLIC của cơ chế "gói định dạng" đã dùng cho Copy/Cắt/
// Dán ở màn hình soạn thảo chính và "Bộ nhớ tạm để dán văn bản"
// (`_VungDinhDangThuCong`, `_macGoiDinhDangChoClipboard`,
// `_apDungGoiDinhDangTuClipboard`... trong `trang_soan_thao.dart`) — CÙNG
// một khuôn JSON (vt/kt/dam/ngh/gc/gn/tm/tc/mc/mn, gói base64(JSON({len,
// ham, sp}))), để Copy/Cắt ở màn hình soạn thảo và Dán ở "Từ điển nhập liệu
// nhanh" đọc/ghi định dạng CHO NHAU được, dù hai hệ thống lưu trữ hoàn toàn
// tách biệt (Từ điển nhập liệu nhanh có 26 "tài liệu" RIÊNG, không đụng tới
// `_boDieuKhien.dinhDang` của màn hình soạn thảo).
//
// Đặt ở module riêng (không viết thẳng vào `trang_soan_thao.dart`) vì các
// hằng/hàm liên quan ở đó đều là riêng-theo-TỆP (`_` của Dart là theo LIBRARY,
// và mỗi tệp không `part of` là một library riêng) — `modal_tu_dien_nhap_lieu_nhanh.dart`
// cần một bản PUBLIC, dùng được từ tệp khác.

import 'dart:convert';

import 'package:flutter/material.dart';

/// Một vùng định dạng thủ công — CÙNG khuôn JSON với `_VungDinhDangThuCong`
/// ở `trang_soan_thao.dart` nên gói tạo ra ở MỘT nơi (Copy/Cắt màn hình
/// soạn thảo, hay Dán ở Từ điển nhập liệu nhanh) đọc lại được ở nơi KHÁC.
class VungDinhDangDoanVan {
  const VungDinhDangDoanVan({
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

  final int batDau;
  final int ketThuc;
  final bool dam;
  final bool nghieng;
  final bool gachChan;
  final bool gachNgang;
  final bool treMu;
  final bool treChan;
  final Color? mauChu;
  final Color? mauNen;

  /// Dời cả vùng đi [lech] ký tự — dùng khi chèn đoạn có định dạng vào giữa
  /// một tài liệu khác (toạ độ gốc là TƯƠNG ĐỐI trong đoạn vừa dán, cần dịch
  /// theo đúng vị trí chèn thật).
  VungDinhDangDoanVan dich(int lech) => VungDinhDangDoanVan(
        batDau: batDau + lech,
        ketThuc: ketThuc + lech,
        dam: dam,
        nghieng: nghieng,
        gachChan: gachChan,
        gachNgang: gachNgang,
        treMu: treMu,
        treChan: treChan,
        mauChu: mauChu,
        mauNen: mauNen,
      );

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
      fontSize: treChan ? (style.fontSize ?? 15) * 0.7 : null,
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

  static VungDinhDangDoanVan? tuJson(dynamic j, int doDaiVanBan) {
    if (j is! Map) return null;
    final batDau = j['vt'];
    final ketThuc = j['kt'];
    if (batDau is! int || ketThuc is! int) return null;
    if (batDau < 0 || ketThuc > doDaiVanBan || batDau >= ketThuc) return null;
    final mc = j['mc'];
    final mn = j['mn'];
    return VungDinhDangDoanVan(
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

/// Băm FNV-1a 32-bit — chỉ để XÁC MINH một đoạn văn bản còn nguyên vẹn hay
/// không, CÙNG thuật toán với `_bamFnv1a` ở `trang_soan_thao.dart` (để gói
/// tạo ra ở hai nơi tương thích nhau).
String _bamFnv1a(String chu) {
  const soNguyenTo = 16777619;
  const mat32Bit = 0xFFFFFFFF;
  var h = 2166136261;
  for (final donVi in chu.codeUnits) {
    h = ((h ^ donVi) * soNguyenTo) & mat32Bit;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

const _danhDauGoiDinhDangClip = 'FLOWRITE-CLIP-V1';
final _reGoiDinhDangClip = RegExp('<!--$_danhDauGoiDinhDangClip:([A-Za-z0-9+/=]+)-->');

/// Tách gói JSON (nếu có) khỏi chuỗi `text/html` đọc được từ clipboard —
/// cùng đánh dấu với `_tachGoiDinhDangTuHtml` ở `trang_soan_thao.dart`.
String? tachGoiDinhDangTuHtml(String? htmlClipboard) {
  if (htmlClipboard == null) return null;
  return _reGoiDinhDangClip.firstMatch(htmlClipboard)?.group(1);
}

/// Đóng gói [vung] (toạ độ TƯƠNG ĐỐI trong [doan]) thành base64 — `null`
/// nếu không có vùng nào đáng ghi.
String? macGoiDinhDang(String doan, List<VungDinhDangDoanVan> vung) {
  final ds = vung.where((v) => v.batDau < v.ketThuc).toList();
  if (ds.isEmpty) return null;
  final goi = {'len': doan.length, 'ham': _bamFnv1a(doan), 'sp': ds.map((v) => v.toJson()).toList()};
  return base64Encode(utf8.encode(jsonEncode(goi)));
}

/// Ngược lại [macGoiDinhDang] — decode, XÁC MINH [vanBanDaDan] khớp đúng độ
/// dài/mã băm đã ghi, trả về danh sách vùng (toạ độ vẫn TƯƠNG ĐỐI, nơi gọi
/// tự dịch theo [VungDinhDangDoanVan.dich]). `null` nếu hỏng khuôn/không
/// khớp — mất định dạng còn hơn gán sai chỗ.
List<VungDinhDangDoanVan>? giaiMaGoiDinhDang(String maHoa, String vanBanDaDan) {
  try {
    final goi = jsonDecode(utf8.decode(base64Decode(maHoa)));
    if (goi is! Map) return null;
    if (goi['len'] != vanBanDaDan.length) return null;
    if (goi['ham'] != _bamFnv1a(vanBanDaDan)) return null;
    final sp = goi['sp'];
    if (sp is! List) return null;
    return sp
        .map((j) => VungDinhDangDoanVan.tuJson(j, vanBanDaDan.length))
        .whereType<VungDinhDangDoanVan>()
        .toList();
  } catch (_) {
    return null;
  }
}

String _mauCss(Color m) => '#${m.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

/// Dựng `text/html` hoàn chỉnh (gói riêng của Flowrite + HTML thật tối
/// giản) cho [doan] theo [vung] — dùng khi Copy nội dung một dòng trong Từ
/// điển nhập liệu nhanh, giữ định dạng để dán ra ngoài hay dán lại đúng
/// định dạng cũ.
String? dungHtmlChoClipboard(String doan, List<VungDinhDangDoanVan> vung) {
  final maHoaGoi = macGoiDinhDang(doan, vung);
  if (maHoaGoi == null) return null;
  final diem = <int>{0, doan.length};
  for (final v in vung) {
    diem.add(v.batDau.clamp(0, doan.length));
    diem.add(v.ketThuc.clamp(0, doan.length));
  }
  final moc = diem.toList()..sort();
  final buf = StringBuffer();
  for (var i = 0; i < moc.length - 1; i++) {
    final a = moc[i], b = moc[i + 1];
    if (a >= b) continue;
    var dam = false, nghieng = false, gachChan = false, gachNgang = false, treMu = false, treChan = false;
    Color? mauChu, mauNen;
    for (final v in vung) {
      if (v.batDau <= a && v.ketThuc >= b) {
        dam = dam || v.dam;
        nghieng = nghieng || v.nghieng;
        gachChan = gachChan || v.gachChan;
        gachNgang = gachNgang || v.gachNgang;
        treMu = treMu || v.treMu;
        treChan = treChan || v.treChan;
        mauChu = v.mauChu ?? mauChu;
        mauNen = v.mauNen ?? mauNen;
      }
    }
    final chuThoat = const HtmlEscape().convert(doan.substring(a, b)).replaceAll('\n', '<br>');
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
    if (mauChu != null) css.write('color:${_mauCss(mauChu)};');
    if (mauNen != null) css.write('background-color:${_mauCss(mauNen)};');
    buf.write(css.isEmpty ? chuThoat : '<span style="$css">$chuThoat</span>');
  }
  return '<!--$_danhDauGoiDinhDangClip:$maHoaGoi--><span>$buf</span>';
}

/// Hiển thị [doan] có áp dụng [vung] (rỗng thì chỉ là `Text` chữ thô) —
/// dùng để xem trước định dạng ở các dòng trong modal cài đặt "Từ điển nhập
/// liệu nhanh". KHÔNG dùng ở bảng 26 dòng để dán nhanh hay modal "Thay đổi
/// thứ tự giữa các dòng" — những nơi đó vẫn hiển thị chữ thô như trước.
Widget vanBanCoDinhDangTuDien(
  String doan,
  List<VungDinhDangDoanVan> vung,
  TextStyle goc, {
  int? maxLines,
  TextOverflow? overflow,
}) {
  if (vung.isEmpty || doan.isEmpty) {
    return Text(doan, style: goc, maxLines: maxLines, overflow: overflow);
  }
  final diem = <int>{0, doan.length};
  for (final v in vung) {
    diem.add(v.batDau.clamp(0, doan.length));
    diem.add(v.ketThuc.clamp(0, doan.length));
  }
  final moc = diem.toList()..sort();
  final spans = <InlineSpan>[];
  for (var i = 0; i < moc.length - 1; i++) {
    final a = moc[i], b = moc[i + 1];
    if (a >= b) continue;
    var style = goc;
    for (final v in vung) {
      if (v.batDau <= a && v.ketThuc >= b) style = v.apDungLen(style);
    }
    spans.add(TextSpan(text: doan.substring(a, b), style: style));
  }
  return RichText(
    text: TextSpan(style: goc, children: spans),
    maxLines: maxLines,
    overflow: overflow ?? TextOverflow.clip,
  );
}
