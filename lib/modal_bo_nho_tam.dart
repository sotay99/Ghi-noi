// Modal cài đặt "Bộ nhớ tạm để dán văn bản" — mở từ menu "Tài khoản và Cài
// đặt", ngay dưới "Từ điển sửa lỗi chính tả của bạn". Công tắc bật/tắt
// tổng, phím tắt ẩn/hiện bảng lịch sử (dùng CHUNG bốn kiểu phím tắt với
// Micro/Ghi âm, xem `LuaChonPhimTat`/`TinhNangPhimTat`), và lời giải thích
// ngắn. Bảng LỊCH SỬ thật (10 dòng) nằm riêng ở `trang_soan_thao.dart`
// (`_HopThoaiLichSuBoNhoTam`) — modal này chỉ cấu hình, không hiện lịch sử.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cai_dat.dart';
import 'chuoi_da_ngon_ngu.dart';
import 'lua_chon_phim_tat.dart';
import 'ngon_ngu.dart';
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
                title: Text(Ch.nhanMotPhim(ngonNguHienTai.value)),
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
                  child: SizedBox(
                    height: 60,
                    child: Center(child: Text(Ch.hayNhanMotPhimBatKyTrenBanPhim(ngonNguHienTai.value))),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx2).pop(), child: Text(Ch.huy(ngonNguHienTai.value))),
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
            title: Text(Ch.phimTatChoBoNhoTamDanVanBan(ngonNguHienTai.value)),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    oLuaChon(
                      loai: 'tab',
                      nhan: Ch.tenTab(ngonNguHienTai.value),
                      giaiThich: Ch.giaiThichTab(ngonNguHienTai.value),
                    ),
                    oLuaChon(
                      loai: 'ctrl',
                      nhan: Ch.tenCtrlCongThem(ngonNguHienTai.value),
                      giaiThich: Ch.giaiThichCtrlCongThem(ngonNguHienTai.value),
                    ),
                    oLuaChon(
                      loai: 'ctrlDup',
                      nhan: Ch.tenBamCtrl2Lan(ngonNguHienTai.value),
                      giaiThich: Ch.giaiThichBamCtrl2Lan(ngonNguHienTai.value),
                    ),
                    oLuaChon(
                      loai: 'shiftDup',
                      nhan: Ch.tenBamShift2Lan(ngonNguHienTai.value),
                      giaiThich: Ch.giaiThichBamShift2Lan(ngonNguHienTai.value),
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
                                  phimCtrlTam == null ? Ch.bamDeChonPhim(ngonNguHienTai.value) : 'Ctrl + $phimCtrlTam',
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
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(Ch.huy(ngonNguHienTai.value))),
              FilledButton(
                onPressed: () async {
                  if (loaiTam == 'ctrl' && phimCtrlTam == null) {
                    capNhatModal(() => loiXungDot = Ch.hayBamChonMotPhimTruocKhiLuu(ngonNguHienTai.value));
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
                      capNhatModal(() => loiXungDot = Ch.phimTatDangTrungVoiChucNang(
                          ngonNguHienTai.value, xungDotCoDinh, moi.nhan));
                      return;
                    }
                    // Lựa chọn 4 (tổ hợp tự chọn) không có cơ chế tự đổi hộ
                    // — chặn lưu nếu trùng BẤT KỲ phím tắt nào của Micro/
                    // Ghi âm.
                    if (widget.caiDat.phimTatMicro.coBangVoi(moi)) {
                      capNhatModal(() => loiXungDot = Ch.phimTatDangTrungVoiChucNang(
                          ngonNguHienTai.value, Ch.micoVuaNoiVuaRaChuTen(ngonNguHienTai.value), moi.nhan));
                      return;
                    }
                    if (widget.caiDat.phimTatGhiAm.coBangVoi(moi)) {
                      capNhatModal(() => loiXungDot = Ch.phimTatDangTrungVoiChucNang(
                          ngonNguHienTai.value, Ch.ghiAmXongMoiRaChuTen(ngonNguHienTai.value), moi.nhan));
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
                        .map((e) => Ch.chonPhimTatChoNut(
                            ngonNguHienTai.value, e.value.nhan, e.key == TinhNangPhimTat.micro))
                        .join(', ');
                    hienThongBaoGiua(
                      context,
                      Ch.daChonPhimTatChoBoNhoTam(ngonNguHienTai.value, moi.nhan, doan),
                      thoiGian: const Duration(seconds: 4),
                    );
                  }
                },
                child: Text(Ch.luu(ngonNguHienTai.value)),
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
          Expanded(child: Text(Ch.boNhoTamDanVanBanTen(ngonNguHienTai.value))),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: Ch.dong(ngonNguHienTai.value),
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
                title: Text(Ch.batBoNhoTamDanVanBan(ngonNguHienTai.value)),
                value: _bat,
                onChanged: _doiCongTac,
              ),
              const SizedBox(height: 8),
              Text(Ch.phimTatAnHienBoNhoTamNay(ngonNguHienTai.value),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
              Text(
                Ch.gioiThieuBoNhoTamDanVanBan(ngonNguHienTai.value),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
