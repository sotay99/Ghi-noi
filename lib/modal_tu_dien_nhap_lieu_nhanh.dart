// Trang "Cài đặt Từ điển nhập liệu nhanh" — mở từ menu "Tài khoản và Cài
// đặt", giữa "Cài đặt từ điển sửa lỗi chính tả" và "Cài đặt Bộ nhớ tạm để
// dán văn bản". TOÀN MÀN HÌNH, cùng khuôn với `modal_tu_dien_chinh_ta.dart`
// (Navigator.push, nút X đóng ở `leading`) — KHÁC ở chỗ KHÔNG có nút "+
// Thêm" ở `actions` (26 dòng A-Z là cố định, không thêm/xoá dòng được).
//
// Nội dung thật của 26 dòng (dán vào vị trí con trỏ) nằm ở
// `_HopThoaiTuDienNhapLieuNhanh` trong `trang_soan_thao.dart` — modal này
// chỉ cấu hình: công tắc bật/tắt tổng, phím tắt ẩn/hiện bảng đó, đổi thứ tự
// giữa 26 dòng, và chính 26 ô nhập liệu (lưu thẳng vào
// `CaiDat.tuDienNhapLieuNhanh`).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cai_dat.dart';
import 'dinh_dang_clip.dart';
import 'dinh_dang_doan_van_tu_dien.dart';
import 'lua_chon_phim_tat.dart';
import 'mau_phim_tu_dien_nhap_lieu_nhanh.dart';

const _mauChinh = Color(0xFF1A73E8);

Future<void> moModalTuDienNhapLieuNhanh(BuildContext context, CaiDat caiDat) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _ManHinhTuDienNhapLieuNhanh(caiDat: caiDat),
    ),
  );
}

String _chuCai(int i) => String.fromCharCode('A'.codeUnitAt(0) + i);

class _ManHinhTuDienNhapLieuNhanh extends StatefulWidget {
  const _ManHinhTuDienNhapLieuNhanh({required this.caiDat});
  final CaiDat caiDat;

  @override
  State<_ManHinhTuDienNhapLieuNhanh> createState() =>
      _ManHinhTuDienNhapLieuNhanhState();
}

/// (YÊU CẦU MỚI) Intent riêng để "chiếm lại" Ctrl+V khỏi hành vi dán mặc
/// định của `TextField` — y hệt cách màn hình soạn thảo chính đã làm ổn
/// định cho Copy/Cắt/Dán của nó (`_YDinhPaste`/`Shortcuts`+`Actions` quanh ô
/// soạn thảo), chỉ khác đích đến là nút "Dán" của ĐÚNG Ô đang có tiêu điểm
/// trong 26 ô này (xem `_ManHinhTuDienNhapLieuNhanhState._focusNodes`).
class _YDinhDanTuDien extends Intent {
  const _YDinhDanTuDien();
}

class _ManHinhTuDienNhapLieuNhanhState
    extends State<_ManHinhTuDienNhapLieuNhanh> {
  late List<TextEditingController> _oNhap;

  /// (YÊU CẦU MỚI) Một `FocusNode` riêng cho mỗi ô — để biết ô nào đang có
  /// tiêu điểm khi Ctrl+V được bấm (xem `_YDinhDanTuDien`).
  late List<FocusNode> _focusNodes;

  /// (YÊU CẦU MỚI) Định dạng HIỆN HÀNH của từng dòng, dạng `ValueNotifier`
  /// để nút "Xem đầy đủ nội dung của dòng này" (ẩn/hiện theo nội dung) VÀ
  /// modal xem đầy đủ (đồng bộ thời gian thực) cùng nghe được — mỗi lần gõ
  /// tay/dán/xoá đều gán LẠI `.value` (danh sách MỚI, xem `_ganDinhDang`),
  /// nên luôn tự bắn ra `notifyListeners` dù nội dung mới có hệt nội dung cũ
  /// (`List` so sánh theo danh tính, không theo phần tử) — không cần tự so
  /// sánh "có đổi gì không" trước khi gán.
  late List<ValueNotifier<List<VungDinhDangDoanVan>>> _dinhDangLive;

  /// (YÊU CẦU MỚI) Đang ở chế độ "Thay đổi thứ tự giữa các dòng" — thay hết
  /// mọi thứ khác (công tắc, phím tắt, chú thích, 26 ô nhập + Copy/Dán/Xoá)
  /// bằng 26 dòng kéo-thả, xem `build`.
  bool _dangSapXepLai = false;

  /// Bản TẠM của 26 đoạn văn bản trong lúc kéo-thả — chỉ áp dụng thật vào
  /// `widget.caiDat`/các ô nhập khi bấm "Lưu thay đổi"; bấm "Huỷ" thì vứt
  /// bỏ, không đụng gì tới dữ liệu thật.
  List<String> _dsSapXepTam = [];

  /// Vị trí (0-25) đang bị kéo đi — `null` khi không kéo gì.
  int? _chiSoDangKeo;

  /// Vị trí CHÈN dự kiến nếu thả ra ngay lúc này — 0-25 nghĩa là "chèn
  /// ngay TRƯỚC dòng này", 26 nghĩa là "chèn vào cuối cùng". `null` khi con
  /// chuột không ở trên vùng thả nào.
  int? _chiSoThaDuKien;

  /// (YÊU CẦU MỚI) Các dòng đang hiện nút "Đã copy"/"Đã dán" (chữ xanh lá,
  /// bấm vào không làm gì cả) — tự trở lại "Copy"/"Dán" sau 2 giây, xem
  /// `_copyDong`/`_danDong`.
  final Set<int> _vuaCopy = {};
  final Set<int> _vuaDan = {};
  final Map<int, Timer> _henCopy = {};
  final Map<int, Timer> _henDan = {};

  @override
  void initState() {
    super.initState();
    _oNhap = List.generate(
      26,
      (i) => TextEditingController(text: widget.caiDat.tuDienNhapLieuNhanh[i]),
    );
    _focusNodes = List.generate(26, (_) => FocusNode());
    _dinhDangLive = List.generate(
      26,
      (i) => ValueNotifier(widget.caiDat.docDinhDangTuDienNhapLieuNhanh(i)),
    );
  }

  @override
  void dispose() {
    for (final o in _oNhap) {
      o.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final n in _dinhDangLive) {
      n.dispose();
    }
    for (final h in _henCopy.values) {
      h.cancel();
    }
    for (final h in _henDan.values) {
      h.cancel();
    }
    super.dispose();
  }

  /// Gán định dạng MỚI [vung] cho dòng [i] — cập nhật `_dinhDangLive[i]`
  /// (để nút "Xem đầy đủ nội dung của dòng này" và modal xem đầy đủ tự vẽ
  /// lại) VÀ lưu lâu dài vào `CaiDat`. Dùng chung cho cả đường gõ tay
  /// ([_doiDong]) lẫn đường dán ([_doiDongKemDinhDang]).
  void _ganDinhDang(int i, List<VungDinhDangDoanVan> vung) {
    _dinhDangLive[i].value = vung;
    widget.caiDat.datDinhDangTuDienNhapLieuNhanh(
      i,
      vung.isEmpty ? null : jsonEncode(vung.map((v) => v.toJson()).toList()),
    );
  }

  /// Gõ tay (qua `onChanged`) hoặc xoá trắng — (YÊU CẦU MỚI) không còn bỏ
  /// hẳn định dạng cũ nữa: dời/co giãn từng vùng theo đúng phép sửa vừa xảy
  /// ra (`apDungChinhSuaChoDinhDang`, CÙNG thuật toán đã dùng cho khung soạn
  /// thảo chính), y hệt cách chèn/sửa/xoá ký tự trong một đoạn đang có định
  /// dạng ở đó — chỉ ký tự THẬT SỰ bị đổi mới mất định dạng, phần còn lại
  /// giữ nguyên.
  void _doiDong(int i, String gia) {
    final cu = widget.caiDat.tuDienNhapLieuNhanh[i];
    widget.caiDat.tuDienNhapLieuNhanh[i] = gia;
    // (YÊU CẦU MỚI) Tự lưu ngay mỗi lần đổi, không cần nút Lưu riêng — xem
    // yêu cầu gốc. Không cần debounce 500ms như từ điển chính tả vì đây chỉ
    // ghi MỘT danh sách chuỗi (rẻ hơn hẳn việc ghi lại cả cây CapTuDien).
    widget.caiDat.luuTuDienNhapLieuNhanh();
    _ganDinhDang(i, apDungChinhSuaChoDinhDang(_dinhDangLive[i].value, cu, gia));
  }

  /// (YÊU CẦU MỚI) Lưu CẢ chữ LẪN định dạng mới cho dòng [i] — dùng riêng
  /// cho đường "Dán": [cu] là chữ TRƯỚC khi dán, [gia] là chữ SAU khi dán,
  /// [vungChenThem] là định dạng (nếu có, toạ độ đã dịch đúng vị trí dán)
  /// của riêng đoạn VỪA được dán vào. Định dạng của phần chữ KHÔNG bị đụng
  /// tới (trước/sau đoạn dán) vẫn được GIỮ NGUYÊN — dời/co giãn theo đúng
  /// phép sửa bằng `apDungChinhSuaChoDinhDang` y hệt `_doiDong`, rồi cộng
  /// thêm định dạng riêng của đoạn mới dán vào, không còn thay HẲN cả dòng
  /// như trước (mất oan định dạng của phần không liên quan tới chỗ dán).
  void _doiDongKemDinhDang(
    int i,
    String cu,
    String gia,
    List<VungDinhDangDoanVan>? vungChenThem,
  ) {
    widget.caiDat.tuDienNhapLieuNhanh[i] = gia;
    widget.caiDat.luuTuDienNhapLieuNhanh();
    final conLai = apDungChinhSuaChoDinhDang(_dinhDangLive[i].value, cu, gia);
    _ganDinhDang(i, [...conLai, ...(vungChenThem ?? const [])]);
  }

  /// (YÊU CẦU MỚI) Copy nội dung dòng [i] vào bộ nhớ đệm HỆ THỐNG — CHỦ Ý
  /// không ghi vào "Bộ nhớ tạm để dán văn bản" (lịch sử 10 dòng riêng của
  /// tính năng khác). Có định dạng thì thử ghi kèm `text/html` giữ định
  /// dạng (y hệt `_phimAoCopy` ở màn hình soạn thảo chính) — thất bại/không
  /// có thì rơi về `Clipboard.setData` chữ thô như trước giờ. Bấm xong, nút
  /// tự đổi thành "Đã copy" (chữ xanh lá) 2 giây — bấm vào trong lúc đó
  /// không làm gì cả (xem `_vuaCopy`, chặn ngay ở đầu hàm).
  Future<void> _copyDong(int i) async {
    if (_vuaCopy.contains(i)) return;
    final doan = _oNhap[i].text;
    final vung = _dinhDangLive[i].value;
    final html = vung.isEmpty ? null : dungHtmlChoClipboard(doan, vung);
    final daGhiGiauDinhDang = html != null && await ghiClipboardCoDinhDang(doan, html);
    if (!daGhiGiauDinhDang) {
      await Clipboard.setData(ClipboardData(text: doan));
    }
    if (!mounted) return;
    setState(() => _vuaCopy.add(i));
    _henCopy[i]?.cancel();
    _henCopy[i] = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _vuaCopy.remove(i));
    });
  }

  /// (YÊU CẦU MỚI) Dán từ bộ nhớ đệm HỆ THỐNG vào ô nhập dòng [i] — vào
  /// đúng vị trí con trỏ nếu ô đang có vùng chọn/con trỏ hợp lệ, hoặc vào
  /// cuối văn bản của dòng đó nếu không (ô chưa từng được chạm vào,
  /// `selection` không hợp lệ). Thử lấy kèm định dạng từ `text/html` của
  /// clipboard (y hệt cách "Bộ nhớ tạm để dán văn bản" đang làm ở màn hình
  /// soạn thảo chính) — định dạng của phần chữ KHÔNG bị đụng tới vẫn được
  /// giữ nguyên (xem `_doiDongKemDinhDang`), chỉ đoạn vừa dán mới mang định
  /// dạng mới đọc được. Cùng cơ chế "Đã dán" 2 giây như `_copyDong`.
  Future<void> _danDong(int i) async {
    if (_vuaDan.contains(i)) return;
    final du = await Clipboard.getData('text/plain');
    final chenGoc = du?.text;
    if (chenGoc == null || chenGoc.isEmpty) return;
    final oDieuKhien = _oNhap[i];
    final vb = oDieuKhien.text;
    final chon = oDieuKhien.selection;
    final batDau = chon.isValid ? chon.start : vb.length;
    final ketThuc = chon.isValid ? chon.end : vb.length;
    var chen = chenGoc;
    var moi = vb.replaceRange(batDau, ketThuc, chen);
    var viTriConTroMoi = batDau + chen.length;
    // (YÊU CẦU MỚI) Giới hạn 1000 ký tự — gán thẳng `.text` không tự cắt
    // như lúc gõ tay qua `maxLength`, phải tự cắt ở đây.
    if (moi.length > CaiDat.gioiHanTuDienNhapLieuNhanh) {
      moi = moi.substring(0, CaiDat.gioiHanTuDienNhapLieuNhanh);
      viTriConTroMoi = viTriConTroMoi.clamp(0, moi.length);
      // Đoạn chèn thật đã bị cắt bớt — không còn khớp y nguyên [chen] nữa,
      // bỏ hẳn định dạng cho an toàn (mất định dạng còn hơn gán sai chỗ).
      chen = '';
    }
    List<VungDinhDangDoanVan>? vungMoi;
    if (chen.isNotEmpty) {
      final htmlClipboard = await docHtmlTuClipboard();
      final maHoaGoi = tachGoiDinhDangTuHtml(htmlClipboard);
      if (maHoaGoi != null) {
        final vung = giaiMaGoiDinhDang(maHoaGoi, chen);
        if (vung != null) {
          vungMoi = [for (final v in vung) v.dich(batDau)];
        }
      }
    }
    setState(() {
      oDieuKhien.value = TextEditingValue(
        text: moi,
        selection: TextSelection.collapsed(offset: viTriConTroMoi),
      );
      _vuaDan.add(i);
    });
    _doiDongKemDinhDang(i, vb, moi, vungMoi);
    _henDan[i]?.cancel();
    _henDan[i] = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _vuaDan.remove(i));
    });
  }

  /// (YÊU CẦU MỚI) Mở modal nhỏ giữa màn hình, hiện ĐẦY ĐỦ nội dung dòng
  /// [i] (kèm định dạng nếu có) — thay cho khung xem trước cũ, không còn bị
  /// giới hạn `maxLines`. Nội dung LUÔN đồng bộ thời gian thực với ô nhập ở
  /// khung cài đặt phía sau: `ValueListenableBuilder` nghe `_dinhDangLive[i]`
  /// (xem `_ganDinhDang`, luôn bắn `notifyListeners` đúng lúc `_oNhap[i].text`
  /// cũng vừa đổi xong — đọc `_oNhap[i].text` ngay trong `builder` luôn thấy
  /// giá trị MỚI NHẤT), nên modal này vẽ lại ngay mỗi lần gõ/dán/xoá ở ô kia,
  /// dù modal đang mở ở một route khác — không cần tự đóng/mở lại.
  void _moXemDayDuDong(int i) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.sizeOf(ctx).width - 48).clamp(280.0, 560.0),
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Phím ${_chuCai(i)} — đầy đủ nội dung',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: ValueListenableBuilder<List<VungDinhDangDoanVan>>(
                      valueListenable: _dinhDangLive[i],
                      builder: (context, vung, _) => vanBanCoDinhDangTuDien(
                        _oNhap[i].text,
                        vung,
                        const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// (YÊU CẦU MỚI) Xoá trắng dòng [i] — hỏi xác nhận trước, không xoá nhầm.
  Future<void> _xoaDong(int i) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, size: 28),
        title: Text('Xoá nội dung dòng Phím ${_chuCai(i)}?'),
        content: const Text('Không thể hoàn tác lại được. Bạn có chắc chắn không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) return;
    setState(() => _oNhap[i].clear());
    _doiDong(i, '');
  }

  Future<void> _moDoiPhimTat() async {
    var loaiTam = widget.caiDat.phimTatTuDienNhapLieuNhanh.loai;
    var phimCtrlTam = widget.caiDat.phimTatTuDienNhapLieuNhanh.phim;
    String? loiXungDot;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhatModal) {
          Widget oLuaChon({required String loai, required String nhan, required String giaiThich}) {
            return RadioListTile<String>(
              value: loai,
              groupValue: loaiTam,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(nhan, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(giaiThich, style: const TextStyle(fontSize: 12)),
              onChanged: (v) {
                if (v == null) return;
                capNhatModal(() {
                  loaiTam = v;
                  loiXungDot = null;
                });
              },
            );
          }

          // (YÊU CẦU MỚI) Y hệt khung "Nhấn một phím" của modal Bộ nhớ tạm
          // (`modal_bo_nho_tam.dart`) — không tách ra dùng chung vì mỗi nơi
          // tự quản lý biến tạm riêng của modal mình, tách ra sẽ phải truyền
          // qua lại nhiều tham số hơn là chỉ chép lại khối này.
          Future<void> chonPhimCtrl() async {
            final tieuDiem = FocusNode();
            final chon = await showDialog<String>(
              context: ctx,
              builder: (ctx2) => AlertDialog(
                title: const Text('Nhấn một phím'),
                content: KeyboardListener(
                  focusNode: tieuDiem,
                  autofocus: true,
                  onKeyEvent: (event) {
                    if (event is! KeyDownEvent) return;
                    final phim = event.logicalKey;
                    final laBoBienDoi = phim == LogicalKeyboardKey.controlLeft ||
                        phim == LogicalKeyboardKey.controlRight ||
                        phim == LogicalKeyboardKey.altLeft ||
                        phim == LogicalKeyboardKey.altRight ||
                        phim == LogicalKeyboardKey.shiftLeft ||
                        phim == LogicalKeyboardKey.shiftRight ||
                        phim == LogicalKeyboardKey.metaLeft ||
                        phim == LogicalKeyboardKey.metaRight;
                    if (laBoBienDoi) return;
                    final nhan = phim.keyLabel;
                    if (nhan.isEmpty) return;
                    Navigator.of(ctx2).pop(nhan.toUpperCase());
                  },
                  child: const SizedBox(
                    height: 60,
                    child: Center(child: Text('Hãy nhấn một phím bất kỳ trên bàn phím...')),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx2).pop(), child: const Text('Huỷ')),
                ],
              ),
            );
            tieuDiem.dispose();
            if (chon != null) {
              capNhatModal(() {
                phimCtrlTam = chon;
                loiXungDot = null;
              });
            }
          }

          return AlertDialog(
            title: const Text('Phím tắt cho Từ điển nhập liệu nhanh'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // (YÊU CẦU MỚI) BA lựa chọn — khác bốn lựa chọn của
                    // Micro/Ghi âm/Bộ nhớ tạm (gia đình tổ hợp hoàn toàn
                    // khác, không bao giờ trùng).
                    oLuaChon(
                      loai: 'altDup',
                      nhan: 'Bấm Alt 2 lần liên tiếp',
                      giaiThich: 'Bấm phím Alt, buông ra, rồi bấm lại lần '
                          'nữa trong khoảng 1 giây (mặc định).',
                    ),
                    oLuaChon(
                      loai: 'altShift',
                      nhan: 'Alt + Shift',
                      giaiThich: 'Giữ phím Alt và Shift cùng lúc.',
                    ),
                    oLuaChon(
                      loai: 'ctrl',
                      nhan: 'Ctrl + ...',
                      giaiThich: 'Giữ phím Ctrl rồi bấm thêm một phím khác — '
                          'ví dụ Ctrl + G.',
                    ),
                    if (loaiTam == 'ctrl') ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: InkWell(
                          onTap: chonPhimCtrl,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFDADCE0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  phimCtrlTam == null ? 'Bấm để chọn phím' : 'Ctrl + $phimCtrlTam',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: phimCtrlTam == null
                                        ? const Color(0xFF5F6368)
                                        : _mauChinh,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF5F6368)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (loiXungDot != null) ...[
                      const SizedBox(height: 12),
                      Text(loiXungDot!, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Huỷ')),
              FilledButton(
                onPressed: () async {
                  if (loaiTam == 'ctrl' && phimCtrlTam == null) {
                    capNhatModal(() => loiXungDot = 'Hãy bấm chọn một phím trước khi lưu.');
                    return;
                  }
                  final moi = loaiTam == 'ctrl'
                      ? LuaChonPhimTat.ctrl(phimCtrlTam!)
                      : const LuaChonPhimTat.altShift();

                  // (YÊU CẦU MỚI) "Ctrl + ..." không được trùng phím tắt CỐ
                  // ĐỊNH của app, cũng không được trùng phím tắt hiện có của
                  // Micro/Ghi âm/Bộ nhớ tạm — không có cơ chế tự đổi hộ ở
                  // đây (tính năng này đứng NGOÀI vòng tự đổi hộ 3 chiều),
                  // nên trùng thì chặn lưu, bắt tự chọn phím khác.
                  if (moi.loai == 'ctrl') {
                    final xungDotCoDinh = CaiDat.tenXungDot(moi);
                    if (xungDotCoDinh != null) {
                      capNhatModal(() => loiXungDot =
                          'Phím tắt này đang trùng với chức năng "$xungDotCoDinh" '
                          '(${moi.nhan}) — chọn phím khác nhé.');
                      return;
                    }
                    if (widget.caiDat.phimTatMicro.coBangVoi(moi)) {
                      capNhatModal(() => loiXungDot =
                          'Phím tắt này đang trùng với chức năng "Micro (vừa nói vừa ra chữ)" '
                          '(${moi.nhan}) — chọn phím khác nhé.');
                      return;
                    }
                    if (widget.caiDat.phimTatGhiAm.coBangVoi(moi)) {
                      capNhatModal(() => loiXungDot =
                          'Phím tắt này đang trùng với chức năng "Ghi âm (Ghi âm xong mới ra chữ)" '
                          '(${moi.nhan}) — chọn phím khác nhé.');
                      return;
                    }
                    if (widget.caiDat.phimTatBoNhoTam.coBangVoi(moi)) {
                      capNhatModal(() => loiXungDot =
                          'Phím tắt này đang trùng với chức năng "Bộ nhớ tạm để dán văn bản" '
                          '(${moi.nhan}) — chọn phím khác nhé.');
                      return;
                    }
                  }

                  await widget.caiDat.datPhimTatTuDienNhapLieuNhanh(moi);
                  if (!mounted) return;
                  setState(() {});
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// (YÊU CẦU MỚI) "Chọn thứ tự giữa các phím tắt chữ cái" — áp dụng ngay và
  /// tự đóng modal khi chọn (không cần nút Lưu riêng, chỉ 2 lựa chọn loại
  /// trừ nhau). Đổi lựa chọn này làm đổi NGAY thứ tự hiển thị 26 dòng ở màn
  /// cài đặt này VÀ ở modal "Thay đổi thứ tự giữa các dòng".
  Future<void> _moChonThuTuPhimTat() async {
    Widget oLuaChon({required String gt, required String nhan, required String giaiThich}) {
      return RadioListTile<String>(
        value: gt,
        groupValue: widget.caiDat.thuTuTuDienNhapLieuNhanh,
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(nhan, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(giaiThich, style: const TextStyle(fontSize: 12)),
        onChanged: (v) {
          if (v == null) return;
          widget.caiDat.datThuTuTuDienNhapLieuNhanh(v);
          setState(() {});
          Navigator.of(context).pop();
        },
      );
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Chọn thứ tự giữa các phím tắt chữ cái')),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Đóng',
              onPressed: () => Navigator.of(ctx).pop(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              oLuaChon(
                gt: 'hang',
                nhan: 'Sắp xếp theo các hàng chữ cái trên bàn phím',
                giaiThich: 'Sắp xếp theo hàng phím của bàn phím vật lý.',
              ),
              oLuaChon(
                gt: 'bangChuCai',
                nhan: 'Sắp xếp theo Bảng chữ cái A → Z',
                giaiThich: 'Sắp xếp theo tiêu chuẩn bảng chữ cái quốc tế '
                    'alphabet, tức là từ A đến Z.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------- "Thay đổi thứ tự giữa các dòng"

  /// (YÊU CẦU MỚI) Thứ tự CHỮ CÁI (không phải thứ tự nội dung) đang áp dụng
  /// cho lượt sắp xếp-lại này — chụp lại NGAY lúc bấm "Thay đổi thứ tự giữa
  /// các dòng" (xem `_batDauSapXepLai`) để nếu người dùng đổi "Chọn thứ tự
  /// giữa các phím tắt chữ cái" trong lúc đang kéo-thả (hiếm, nhưng modal đó
  /// vẫn mở được từ đây) thì KHÔNG làm xáo trộn lượt kéo-thả đang dở —
  /// `_thuTuSapXep[p]` = chữ cái (0-25) đang đứng ở VỊ TRÍ HIỂN THỊ `p`.
  List<int> _thuTuSapXep = [];

  /// (YÊU CẦU MỚI) Định dạng đi KÈM từng phần tử của `_dsSapXepTam`, cùng
  /// chỉ số — kéo-thả phải mang CẢ định dạng đi theo nội dung (không thì
  /// sau khi đổi vị trí, định dạng sẽ dính nhầm vào phím tắt chữ cái khác).
  List<String?> _dsSapXepDinhDangTam = [];

  void _batDauSapXepLai() {
    setState(() {
      _thuTuSapXep =
          thuTuTuDienNhapLieuNhanhTheoKieu(widget.caiDat.thuTuTuDienNhapLieuNhanh);
      _dsSapXepTam = [for (final chuCai in _thuTuSapXep) _oNhap[chuCai].text];
      _dsSapXepDinhDangTam = [
        for (final chuCai in _thuTuSapXep) widget.caiDat.dinhDangTuDienNhapLieuNhanh[chuCai],
      ];
      _dangSapXepLai = true;
    });
  }

  void _huySapXepLai() {
    setState(() {
      _dangSapXepLai = false;
      _dsSapXepTam = [];
      _dsSapXepDinhDangTam = [];
      _thuTuSapXep = [];
      _chiSoDangKeo = null;
      _chiSoThaDuKien = null;
    });
  }

  void _luuSapXepLai() {
    final moi = List<String>.of(_dsSapXepTam);
    final moiDinhDang = List<String?>.of(_dsSapXepDinhDangTam);
    final thuTu = _thuTuSapXep;
    setState(() {
      for (var p = 0; p < 26; p++) {
        final chuCai = thuTu[p];
        widget.caiDat.tuDienNhapLieuNhanh[chuCai] = moi[p];
        _oNhap[chuCai].text = moi[p];
        widget.caiDat.dinhDangTuDienNhapLieuNhanh[chuCai] = moiDinhDang[p];
      }
      _dangSapXepLai = false;
      _dsSapXepTam = [];
      _dsSapXepDinhDangTam = [];
      _thuTuSapXep = [];
      _chiSoDangKeo = null;
      _chiSoThaDuKien = null;
    });
    widget.caiDat.luuTuDienNhapLieuNhanh();
    widget.caiDat.luuDinhDangTuDienNhapLieuNhanh();
  }

  /// [nguon] (0-25) là vị trí ĐANG bị kéo; [dich] (0-26) là vị trí CHÈN
  /// (xem [_chiSoThaDuKien]) — đúng công thức xoá-rồi-chèn-lại tiêu chuẩn,
  /// trừ bớt 1 nếu nguồn nằm TRƯỚC đích (xoá nguồn làm mọi phần tử sau nó
  /// dồn lên một bậc trước khi chèn). Dời CẢ `_dsSapXepDinhDangTam` theo
  /// đúng cùng phép xoá-chèn, giữ định dạng dính đúng với nội dung của nó.
  void _apDungKeoTha(int nguon, int dich) {
    setState(() {
      final tu = _dsSapXepTam.removeAt(nguon);
      final tuDinhDang = _dsSapXepDinhDangTam.removeAt(nguon);
      var d = dich;
      if (nguon < dich) d -= 1;
      _dsSapXepTam.insert(d, tu);
      _dsSapXepDinhDangTam.insert(d, tuDinhDang);
      _chiSoThaDuKien = null;
      _chiSoDangKeo = null;
    });
  }

  /// Đường kẻ ngang màu xanh — vị trí sẽ chèn tới nếu thả tay ra NGAY LÚC
  /// NÀY, đi theo con chuột trong lúc đang kéo (chưa thả).
  Widget _duongKeChiThi() => Container(
        height: 3,
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  /// (YÊU CẦU MỚI) Đường kẻ ngang MỜ ngăn cách giữa 2 dòng liên tiếp — chỉ
  /// để mắt thấy ranh giới, không phải đường chèn (xem [_duongKeChiThi]).
  Widget _duongNganCachDong() => Container(height: 1, color: const Color(0x14000000));

  /// (YÊU CẦU MỚI) Phần NỘI DUNG kéo được (icon 3 gạch + chữ) — KHÔNG gồm
  /// nhãn "Phím X" (xem [_dongKeoTha]: nhãn đó cố ý đứng NGOÀI `Draggable`
  /// để chạm/vuốt đúng khu vực nó — ở màn hình cảm ứng, chỗ dễ vuốt lên/
  /// xuống để cuộn trang nhất — không vô tình khởi động kéo-thả dòng).
  Widget _noiDungKeoDuocKeo(String noiDung) => Row(
        children: [
          const Icon(Icons.drag_handle, color: Color(0xFF9AA0A6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              noiDung.trim().isEmpty ? '(trống)' : noiDung.replaceAll('\n', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: noiDung.trim().isEmpty ? const Color(0xFF9AA0A6) : null,
                fontStyle: noiDung.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      );

  /// Một trong 26 dòng ở chế độ kéo-thả — bấm/kéo được ở phần nội dung bên
  /// trái (icon 3 gạch hoặc chữ), KHÔNG kéo được ở khu vực nhãn "Phím X"
  /// bên phải (xem [_noiDungKeoDuocKeo]). Vị trí CHÈN TRƯỚC dòng này là
  /// chính [i].
  Widget _dongKeoTha(int i) {
    final dangBiKeo = _chiSoDangKeo == i;
    final noiDung = _dsSapXepTam[i];
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != i,
      onMove: (_) {
        if (_chiSoThaDuKien != i) setState(() => _chiSoThaDuKien = i);
      },
      onLeave: (_) {
        if (_chiSoThaDuKien == i) setState(() => _chiSoThaDuKien = null);
      },
      onAcceptWithDetails: (details) => _apDungKeoTha(details.data, i),
      builder: (context, candidate, rejected) => Column(
        children: [
          if (_chiSoThaDuKien == i)
            _duongKeChiThi()
          else if (i > 0)
            _duongNganCachDong(),
          Opacity(
            opacity: dangBiKeo ? 0.3 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Draggable<int>(
                      data: i,
                      axis: Axis.vertical,
                      feedback: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: MediaQuery.sizeOf(context).width - 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFDADCE0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _noiDungKeoDuocKeo(noiDung),
                        ),
                      ),
                      childWhenDragging: const SizedBox(height: 24),
                      onDragStarted: () => setState(() => _chiSoDangKeo = i),
                      onDragEnd: (_) => setState(() => _chiSoDangKeo = null),
                      onDraggableCanceled: (_, __) => setState(() => _chiSoDangKeo = null),
                      child: _noiDungKeoDuocKeo(noiDung),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Phím ${_chuCai(_thuTuSapXep[i])}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: mauChuPhimTuDienNhapLieuNhanh(_thuTuSapXep[i]),
                      decoration: ganChanPhimTuDienNhapLieuNhanh(_thuTuSapXep[i])
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationThickness: doDayGachChanTuDienNhapLieuNhanh,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vùng thả cuối cùng — chèn vào CUỐI danh sách (vị trí 26).
  Widget _vungThaCuoiDanhSach() => DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != 25,
        onMove: (_) {
          if (_chiSoThaDuKien != 26) setState(() => _chiSoThaDuKien = 26);
        },
        onLeave: (_) {
          if (_chiSoThaDuKien == 26) setState(() => _chiSoThaDuKien = null);
        },
        onAcceptWithDetails: (details) => _apDungKeoTha(details.data, 26),
        builder: (context, candidate, rejected) => Column(
          children: [
            if (_chiSoThaDuKien == 26) _duongKeChiThi(),
            const SizedBox(height: 32),
          ],
        ),
      );

  Widget _thanSapXepLai() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
                  onPressed: _huySapXepLai,
                  child: const Text('Huỷ - Không lưu thay đổi'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
                  onPressed: _luuSapXepLai,
                  child: const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Bấm và giữ từng dòng, sau đó kéo và thả để thay đổi vị trí cho '
            'từng dòng.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < 26; i++) _dongKeoTha(i),
          _vungThaCuoiDanhSach(),
        ],
      );

  Widget _thanBinhThuong() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bật Từ điển nhập liệu nhanh',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: widget.caiDat.tuDienNhapLieuNhanhBat,
                  activeThumbColor: _mauChinh,
                  onChanged: (gia) {
                    setState(() => widget.caiDat.tuDienNhapLieuNhanhBat = gia);
                    widget.caiDat.datTuDienNhapLieuNhanhBat(gia);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Phím tắt ẩn hiện bảng Từ điển nhập liệu nhanh',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _moDoiPhimTat,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDADCE0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.caiDat.phimTatTuDienNhapLieuNhanh.nhan,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: _mauChinh)),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF5F6368)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // (YÊU CẦU MỚI) Nút "Thay đổi thứ tự giữa các dòng" — ngay dưới
          // cài đặt phím tắt.
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _batDauSapXepLai,
              icon: const Icon(Icons.swap_vert, size: 18),
              label: const Text('Thay đổi thứ tự giữa các dòng'),
            ),
          ),
          const SizedBox(height: 8),
          // (YÊU CẦU MỚI) Nút "Chọn thứ tự giữa các phím tắt chữ cái" — ngay
          // sát dưới nút trên.
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _moChonThuTuPhimTat,
              icon: const Icon(Icons.sort_by_alpha, size: 18),
              label: const Text('Chọn thứ tự giữa các phím tắt chữ cái'),
            ),
          ),
          const SizedBox(height: 16),
          // (YÊU CẦU MỚI) Dòng chú thích mới — đứng TRƯỚC dòng chú thích cũ.
          const Text(
            'Từ điển được lưu lâu dài trong bộ nhớ nội bộ của thiết bị.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mỗi dòng ứng với một phím chữ cái trên bàn phím vật lý — gõ '
            'sẵn đoạn văn bản muốn dán nhanh vào dòng tương ứng. Mở bảng '
            'bằng nút trên thanh công cụ hoặc phím tắt ở trên, rồi bấm vào '
            'một dòng (hoặc gõ đúng phím chữ cái của dòng đó) để dán ngay '
            'vào vị trí con trỏ. Để trống dòng nào cũng được. Mỗi lần sửa '
            'tự lưu lại ngay, không cần bấm nút Lưu.',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 8),
          // (YÊU CẦU MỚI) Bọc cả 26 ô trong MỘT `Shortcuts`/`Actions` để
          // "chiếm lại" Ctrl+V — y hệt cách màn hình soạn thảo chính đã làm
          // ổn định cho Copy/Cắt/Dán của nó — rồi gọi thẳng `_danDong` của
          // ĐÚNG ô đang có tiêu điểm (`_focusNodes`), dán kèm định dạng
          // giống như bấm nút "Dán" ngay dưới ô đó.
          Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.keyV, control: true): _YDinhDanTuDien(),
            },
            child: Actions(
              actions: {
                _YDinhDanTuDien: CallbackAction<_YDinhDanTuDien>(
                  onInvoke: (_) {
                    final i = _focusNodes.indexWhere((f) => f.hasFocus);
                    if (i != -1) _danDong(i);
                    return null;
                  },
                ),
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _danhSachODong(),
              ),
            ),
          ),
        ],
      );

  /// 26 khối "nhãn Phím X + ô nhập + xem trước định dạng (nếu có) + nút
  /// Copy/Dán/Xoá", tách ra khỏi `_thanBinhThuong` để bọc gọn trong MỘT
  /// `Shortcuts`/`Actions` (chiếm Ctrl+V) ở trên.
  List<Widget> _danhSachODong() => [
        for (final i in thuTuTuDienNhapLieuNhanhTheoKieu(widget.caiDat.thuTuTuDienNhapLieuNhanh)) ...[
          const Divider(height: 24),
          Text(
            'Phím ${_chuCai(i)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: mauChuPhimTuDienNhapLieuNhanh(i),
              decoration:
                  ganChanPhimTuDienNhapLieuNhanh(i) ? TextDecoration.underline : TextDecoration.none,
              decorationThickness: doDayGachChanTuDienNhapLieuNhanh,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _oNhap[i],
            focusNode: _focusNodes[i],
            onChanged: (gia) => _doiDong(i, gia),
            maxLines: 3,
            minLines: 1,
            // (YÊU CẦU MỚI) Giới hạn 1000 ký tự — dán đoạn dài hơn cũng
            // tự cắt bớt nhờ `maxLength`, không cần thêm gì.
            maxLength: CaiDat.gioiHanTuDienNhapLieuNhanh,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          // (YÊU CẦU MỚI) Nút "Xem đầy đủ nội dung của dòng này" — THAY cho
          // khung xem trước định dạng cũ. CHỈ hiện khi dòng này ĐANG có ký
          // tự (bất kể có định dạng hay không — trước đây khung cũ chỉ hiện
          // khi có định dạng). Nghe `_dinhDangLive[i]` để tự ẩn/hiện ngay
          // mỗi lần gõ/dán/xoá (xem `_ganDinhDang`, luôn gán LẠI `.value`
          // dù nội dung định dạng mới có rỗng y hệt nội dung cũ, nên LUÔN
          // bắn `notifyListeners` đúng lúc `_oNhap[i].text` cũng vừa đổi).
          ValueListenableBuilder<List<VungDinhDangDoanVan>>(
            valueListenable: _dinhDangLive[i],
            builder: (context, vung, _) {
              if (_oNhap[i].text.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _moXemDayDuDong(i),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Xem đầy đủ nội dung của dòng này'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
            // (YÊU CẦU MỚI) Ba nút Copy/Dán/Xoá riêng cho từng dòng — Copy
            // và Dán tự đổi thành "Đã copy"/"Đã dán" (chữ xanh lá) 2 giây
            // sau khi bấm, bấm vào lúc đó không làm gì cả (xem `_copyDong`/
            // `_danDong`).
            Row(
              children: [
                TextButton.icon(
                  onPressed: _vuaCopy.contains(i) ? () {} : () => _copyDong(i),
                  icon: Icon(
                    _vuaCopy.contains(i) ? Icons.check : Icons.copy_outlined,
                    size: 16,
                    color: _vuaCopy.contains(i) ? Colors.green.shade700 : null,
                  ),
                  label: Text(
                    _vuaCopy.contains(i) ? 'Đã copy' : 'Copy',
                    style: TextStyle(color: _vuaCopy.contains(i) ? Colors.green.shade700 : null),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton.icon(
                  onPressed: _vuaDan.contains(i) ? () {} : () => _danDong(i),
                  icon: Icon(
                    _vuaDan.contains(i) ? Icons.check : Icons.content_paste,
                    size: 16,
                    color: _vuaDan.contains(i) ? Colors.green.shade700 : null,
                  ),
                  label: Text(
                    _vuaDan.contains(i) ? 'Đã dán' : 'Dán',
                    style: TextStyle(color: _vuaDan.contains(i) ? Colors.green.shade700 : null),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton.icon(
                  onPressed: () => _xoaDong(i),
                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade600),
                  label: Text('Xoá', style: TextStyle(color: Colors.red.shade600)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ],
        ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _mauChinh,
        foregroundColor: Colors.white,
        title: const Text('Từ điển nhập liệu nhanh'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _dangSapXepLai ? _thanSapXepLai() : _thanBinhThuong(),
          ],
        ),
      ),
    );
  }
}
