// Modal cài đặt "Bộ nhớ tạm để dán văn bản" — mở từ menu "Tài khoản và Cài
// đặt", ngay dưới "Từ điển sửa lỗi chính tả của bạn". Công tắc bật/tắt
// tổng, phím tắt ẩn/hiện bảng lịch sử (dùng CHUNG bốn kiểu phím tắt với
// Micro/Ghi âm, xem `LuaChonPhimTat`/`TinhNangPhimTat`), và lời giải thích
// ngắn. Bảng LỊCH SỬ thật (10 dòng) nằm riêng ở `trang_soan_thao.dart`
// (`_HopThoaiLichSuBoNhoTam`) — modal này chỉ cấu hình, không hiện lịch sử.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cai_dat.dart';
import 'lua_chon_phim_tat.dart';
import 'thong_bao_giua.dart';

const _mauChinh = Color(0xFF1A73E8);

Future<void> moModalBoNhoTam(BuildContext context, CaiDat caiDat) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ModalBoNhoTam(caiDat: caiDat),
  );
}

class _ModalBoNhoTam extends StatefulWidget {
  const _ModalBoNhoTam({required this.caiDat});
  final CaiDat caiDat;

  @override
  State<_ModalBoNhoTam> createState() => _ModalBoNhoTamState();
}

class _ModalBoNhoTamState extends State<_ModalBoNhoTam> {
  late bool _bat;
  late LuaChonPhimTat _phimTat;

  @override
  void initState() {
    super.initState();
    _bat = widget.caiDat.boNhoTamDanVanBanBat;
    _phimTat = widget.caiDat.phimTatBoNhoTam;
  }

  Future<void> _doiCongTac(bool v) async {
    setState(() => _bat = v);
    await widget.caiDat.datBoNhoTamDanVanBanBat(v);
  }

  Future<void> _moDoiPhimTat() async {
    var loaiTam = _phimTat.loai;
    var phimCtrlTam = _phimTat.phim;
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
            title: const Text('Phím tắt cho Bộ nhớ tạm để dán văn bản'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    oLuaChon(
                      loai: 'tab',
                      nhan: 'Tab',
                      giaiThich: 'Phím Tab — hình mũi tên hai chiều (⇥). Nằm '
                          'ở góc trên bên trái bàn phím, ngay phía trên phím '
                          'Caps Lock, bên trái chữ Q.',
                    ),
                    oLuaChon(
                      loai: 'ctrl',
                      nhan: 'Ctrl + ...',
                      giaiThich: 'Giữ phím Ctrl (góc dưới cùng bên trái bàn '
                          'phím) rồi bấm thêm một phím khác — ví dụ Ctrl + G.',
                    ),
                    oLuaChon(
                      loai: 'ctrlDup',
                      nhan: 'Bấm Ctrl 2 lần liên tiếp',
                      giaiThich: 'Bấm phím Ctrl rồi BUÔNG RA NGAY (không giữ), '
                          'sau đó bấm Ctrl thêm một lần nữa trong vòng 1 giây '
                          '— giống bấm đúp chuột nhưng bằng phím Ctrl.',
                    ),
                    oLuaChon(
                      loai: 'shiftDup',
                      nhan: 'Bấm Shift 2 lần liên tiếp',
                      giaiThich: 'Bấm phím Shift rồi buông ra ngay, bấm Shift '
                          'thêm một lần nữa trong vòng 1 giây. Lưu ý: nếu gõ '
                          'chữ hoa rất nhanh, đôi khi có thể vô tình kích hoạt.',
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
                      : (loaiTam == 'tab'
                          ? const LuaChonPhimTat.tab()
                          : (loaiTam == 'shiftDup'
                              ? const LuaChonPhimTat.shiftDup()
                              : const LuaChonPhimTat.ctrlDup()));

                  if (moi.loai == 'ctrl') {
                    final xungDotCoDinh = CaiDat.tenXungDot(moi);
                    if (xungDotCoDinh != null) {
                      capNhatModal(() => loiXungDot =
                          'Phím tắt này đang trùng với chức năng "$xungDotCoDinh" '
                          '(${moi.nhan}) — chọn phím khác nhé.');
                      return;
                    }
                    // Lựa chọn 4 (tổ hợp tự chọn) không có cơ chế tự đổi hộ
                    // — chặn lưu nếu trùng BẤT KỲ phím tắt nào của Micro/
                    // Ghi âm.
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
                  }

                  final doiHo = await widget.caiDat.datPhimTatTinhNangVaTuHoanDoiNeuTrung(
                    tinhNang: TinhNangPhimTat.boNhoTam,
                    moi: moi,
                  );
                  if (!mounted) return;
                  setState(() => _phimTat = widget.caiDat.phimTatBoNhoTam);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (doiHo.isNotEmpty && mounted) {
                    final doan = doiHo.entries
                        .map((e) => 'chọn phím tắt ${e.value.nhan} cho '
                            '${e.key == TinhNangPhimTat.micro ? 'nút micro vừa nói vừa ra chữ' : 'nút ghi âm'}')
                        .join(', ');
                    hienThongBaoGiua(
                      context,
                      'Đã chọn phím tắt ${moi.nhan} cho Bộ nhớ tạm để dán văn bản, '
                      'tự động $doan',
                      thoiGian: const Duration(seconds: 4),
                    );
                  }
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
    return AlertDialog(
      // (YÊU CẦU MỚI) Bỏ nút "Đóng" ở `actions` — thay bằng nút X đỏ gọn
      // gàng ở góc trên bên phải.
      title: Row(
        children: [
          const Expanded(child: Text('Bộ nhớ tạm để dán văn bản')),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bật Bộ nhớ tạm để dán văn bản'),
                value: _bat,
                onChanged: _doiCongTac,
              ),
              const SizedBox(height: 8),
              const Text('Phím tắt ẩn hiện bộ nhớ tạm này',
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
                      Text(_phimTat.nhan,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: _mauChinh)),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF5F6368)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Bộ nhớ tạm để dán văn bản là một bảng NHỚ RIÊNG của app, giữ '
                'lại tối đa 10 đoạn văn bản gần nhất bạn đã Cắt hoặc Copy — '
                'khác với bộ nhớ đệm thường của máy (chỉ nhớ được ĐÚNG MỘT '
                'đoạn gần nhất). Khi BẬT: mỗi lần Cắt/Copy, đoạn văn bản tự '
                'được thêm vào bảng; bấm nút hoặc dùng phím tắt ở trên để mở '
                'bảng, rồi bấm vào một dòng (hoặc gõ đúng phím số của dòng '
                'đó) để dán ngay vào vị trí con trỏ. Khi TẮT: Cắt/Copy vẫn '
                'hoạt động bình thường với bộ nhớ đệm của máy như trước, chỉ '
                'không ghi thêm vào bảng 10 dòng này nữa, và nút/phím tắt mở '
                'bảng cũng ẩn đi.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
