// Trang "Cài đặt Từ điển nhập liệu nhanh" — mở từ menu "Tài khoản và Cài
// đặt", giữa "Cài đặt từ điển sửa lỗi chính tả" và "Cài đặt Bộ nhớ tạm để
// dán văn bản". TOÀN MÀN HÌNH, cùng khuôn với `modal_tu_dien_chinh_ta.dart`
// (Navigator.push, nút X đóng ở `leading`) — KHÁC ở chỗ KHÔNG có nút "+
// Thêm" ở `actions` (26 dòng A-Z là cố định, không thêm/xoá dòng được).
//
// Nội dung thật của 26 dòng (dán vào vị trí con trỏ) nằm ở
// `_HopThoaiTuDienNhapLieuNhanh` trong `trang_soan_thao.dart` — modal này
// chỉ cấu hình: công tắc bật/tắt tổng, phím tắt ẩn/hiện bảng đó, và chính
// 26 ô nhập liệu (lưu thẳng vào `CaiDat.tuDienNhapLieuNhanh`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cai_dat.dart';
import 'lua_chon_phim_tat.dart';

const _mauChinh = Color(0xFF1A73E8);

Future<void> moModalTuDienNhapLieuNhanh(BuildContext context, CaiDat caiDat) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _ManHinhTuDienNhapLieuNhanh(caiDat: caiDat),
    ),
  );
}

class _ManHinhTuDienNhapLieuNhanh extends StatefulWidget {
  const _ManHinhTuDienNhapLieuNhanh({required this.caiDat});
  final CaiDat caiDat;

  @override
  State<_ManHinhTuDienNhapLieuNhanh> createState() =>
      _ManHinhTuDienNhapLieuNhanhState();
}

class _ManHinhTuDienNhapLieuNhanhState
    extends State<_ManHinhTuDienNhapLieuNhanh> {
  late List<TextEditingController> _oNhap;

  @override
  void initState() {
    super.initState();
    _oNhap = List.generate(
      26,
      (i) => TextEditingController(text: widget.caiDat.tuDienNhapLieuNhanh[i]),
    );
  }

  @override
  void dispose() {
    for (final o in _oNhap) {
      o.dispose();
    }
    super.dispose();
  }

  void _doiDong(int i, String gia) {
    widget.caiDat.tuDienNhapLieuNhanh[i] = gia;
    // (YÊU CẦU MỚI) Tự lưu ngay mỗi lần đổi, không cần nút Lưu riêng — xem
    // yêu cầu gốc. Không cần debounce 500ms như từ điển chính tả vì đây chỉ
    // ghi MỘT danh sách chuỗi (rẻ hơn hẳn việc ghi lại cả cây CapTuDien).
    widget.caiDat.luuTuDienNhapLieuNhanh();
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
                    // (YÊU CẦU MỚI) CHỈ hai lựa chọn — khác bốn lựa chọn của
                    // Micro/Ghi âm/Bộ nhớ tạm.
                    oLuaChon(
                      loai: 'altShift',
                      nhan: 'Alt + Shift',
                      giaiThich: 'Giữ phím Alt và Shift cùng lúc (mặc định).',
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
            const SizedBox(height: 16),
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
            for (var i = 0; i < 26; i++) ...[
              const Divider(height: 24),
              Text(
                'Phím ${String.fromCharCode('A'.codeUnitAt(0) + i)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5F6368),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _oNhap[i],
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
            ],
          ],
        ),
      ),
    );
  }
}
