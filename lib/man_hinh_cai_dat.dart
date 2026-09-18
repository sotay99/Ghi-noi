// Màn hình cài đặt: sáu dòng — thời gian bật lại micro, tự động tắt micro
// khi im lặng, tự động chèn dấu cách, kiểm tra chính tả bằng AI, tự động
// chèn dấu câu bằng AI, phím tắt tắt/mở micro, và trạng thái quyền micro
// của thiết bị.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'cai_dat.dart';

/// Hai bộ biến đổi cho phép chọn làm phím tắt — bàn phím Android/desktop
/// thường chỉ có hai phím này ở vị trí dễ bấm cùng lúc với một phím khác.
const _cacBoBienDoi = ['Ctrl', 'Alt'];

const _cacMucThoiGian = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, _khongTuBatLai];

/// Giá trị đặc biệt: micro tắt hẳn khi gõ phím, người dùng phải tự bấm nút
/// micro mới nghe lại — không có bộ đếm thời gian nào tự động bật hộ.
const _khongTuBatLai = -1.0;

class ManHinhCaiDat extends StatefulWidget {
  const ManHinhCaiDat({
    super.key,
    required this.caiDat,
    required this.khiTatKiemTraChinhTa,
    required this.khiKiemTraLaiMicro,
    this.khiDoiTuDongThemDuongKeChia,
  });

  final CaiDat caiDat;

  /// Gọi ngay khi người dùng tắt "kiểm tra chính tả bằng AI" — trang soạn
  /// thảo dùng đây để xoá hết gạch đỏ chân đang hiển thị.
  final VoidCallback khiTatKiemTraChinhTa;

  /// (VIỆC 3) Gọi ngay khi người dùng BẬT/TẮT "tự động thêm đường kẻ chia
  /// văn bản" — trang soạn thảo dùng đây để quét lại (khi bật) hoặc buộc vẽ
  /// lại ngay (khi tắt) cho ghi chú ĐANG MỞ, không cần đợi mở/chuyển ghi chú
  /// khác mới thấy hiệu ứng. Không bắt buộc.
  final VoidCallback? khiDoiTuDongThemDuongKeChia;

  /// Gọi lại speech_to_text.initialize() để trang soạn thảo cập nhật xem
  /// micro có dùng được không, sau khi người dùng vừa xin quyền.
  final Future<void> Function() khiKiemTraLaiMicro;

  @override
  State<ManHinhCaiDat> createState() => _ManHinhCaiDatState();
}

class _ManHinhCaiDatState extends State<ManHinhCaiDat> {
  late double _thoiGian;
  late bool _tuDongChen;
  late bool _kiemTraChinhTa;
  late bool _tuDongChenDauCau;
  late bool _tuDongThemDauCham;
  late bool _tuDongThutDauDong;
  late bool _tuDongThemDuongKeChia;
  late bool _tuDongVietHoaDauCau;
  late String _phimTatBoBienDoi;
  late String _phimTatPhim;
  PermissionStatus? _trangThaiMicro;
  bool _dangXuLyMicro = false;

  late final TextEditingController _oTuTatMicro;
  final _focusTuTatMicro = FocusNode();

  @override
  void initState() {
    super.initState();
    _thoiGian = widget.caiDat.thoiGianBatLaiGiay;
    _tuDongChen = widget.caiDat.tuDongChenKhoangCach;
    _kiemTraChinhTa = widget.caiDat.kiemTraChinhTaBangAI;
    _tuDongChenDauCau = widget.caiDat.tuDongChenDauCauBangAI;
    _tuDongThemDauCham = widget.caiDat.tuDongThemDauCham;
    _tuDongThutDauDong = widget.caiDat.tuDongThutDauDong;
    _tuDongThemDuongKeChia = widget.caiDat.tuDongThemDuongKeChia;
    _tuDongVietHoaDauCau = widget.caiDat.tuDongVietHoaDauCau;
    _phimTatBoBienDoi = widget.caiDat.phimTatBoBienDoi;
    _phimTatPhim = widget.caiDat.phimTatPhim;
    _oTuTatMicro = TextEditingController(text: '${widget.caiDat.thoiGianTuTatMicroGiay}');
    _focusTuTatMicro.addListener(_khiMatTieuDiemTuTatMicro);
    _kiemTraQuyenMicro();
  }

  @override
  void dispose() {
    _focusTuTatMicro.removeListener(_khiMatTieuDiemTuTatMicro);
    _focusTuTatMicro.dispose();
    _oTuTatMicro.dispose();
    super.dispose();
  }

  void _khiMatTieuDiemTuTatMicro() {
    if (_focusTuTatMicro.hasFocus) return;
    _apDungTuTatMicro();
  }

  Future<void> _apDungTuTatMicro() async {
    final gia = int.tryParse(_oTuTatMicro.text) ?? widget.caiDat.thoiGianTuTatMicroGiay;
    final hopLe = gia.clamp(CaiDat.gioiHanDuoiTuTatMicro, CaiDat.gioiHanTrenTuTatMicro);
    _oTuTatMicro.text = '$hopLe';
    if (hopLe != widget.caiDat.thoiGianTuTatMicroGiay) {
      await widget.caiDat.datThoiGianTuTatMicro(hopLe);
    }
  }

  Future<void> _kiemTraQuyenMicro() async {
    final tt = await Permission.microphone.status;
    if (mounted) setState(() => _trangThaiMicro = tt);
  }

  Future<void> _capQuyenMicro() async {
    setState(() => _dangXuLyMicro = true);
    await Permission.microphone.request();
    await widget.khiKiemTraLaiMicro();
    await _kiemTraQuyenMicro();
    if (mounted) setState(() => _dangXuLyMicro = false);
  }

  Future<void> _moCaiDatUngDung() async {
    setState(() => _dangXuLyMicro = true);
    await openAppSettings();
    if (mounted) setState(() => _dangXuLyMicro = false);
  }

  String _nhanThoiGian(double giay) {
    if (giay == _khongTuBatLai) return 'Không tự động bật lại Micro';
    final tron = giay == giay.roundToDouble();
    final so =
        tron ? giay.toInt().toString() : giay.toStringAsFixed(1).replaceAll('.', ',');
    return '$so giây';
  }

  /// Chữ giữa cặp **hai dấu sao** được in đậm — cách đánh dấu nhẹ nhàng để
  /// viết văn bản giải thích dài mà vẫn tô đậm được từ khoá quan trọng.
  List<InlineSpan> _phanTichDam(String vanBan) {
    final ketQua = <InlineSpan>[];
    final mauDam = RegExp(r'\*\*(.+?)\*\*');
    var viTri = 0;
    for (final m in mauDam.allMatches(vanBan)) {
      if (m.start > viTri) {
        ketQua.add(TextSpan(text: vanBan.substring(viTri, m.start)));
      }
      ketQua.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      viTri = m.end;
    }
    if (viTri < vanBan.length) {
      ketQua.add(TextSpan(text: vanBan.substring(viTri)));
    }
    return ketQua;
  }

  Widget _doanVanCoDam(String vanBan, {double fontSize = 14}) {
    return Text.rich(
      TextSpan(
        style: TextStyle(height: 1.5, fontSize: fontSize, color: Colors.black87),
        children: _phanTichDam(vanBan),
      ),
    );
  }

  void _hienGiaiThich(String tieuDe, String ngan, String chiTiet) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tieuDe),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GIẢI THÍCH NGẮN GỌN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 8),
              _doanVanCoDam(ngan),
              const SizedBox(height: 20),
              const Text(
                'GIẢI THÍCH CHI TIẾT HƠN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 8),
              _doanVanCoDam(chiTiet),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _dong1ThoiGian(),
          const Divider(height: 40),
          _dong2TuTatMicro(),
          const Divider(height: 40),
          _dong3TuDongChen(),
          const Divider(height: 40),
          _dong4AI(),
          const Divider(height: 40),
          _dong4bChenDauCauAI(),
          const Divider(height: 40),
          _dong4cTuDongThemDauCham(),
          const Divider(height: 40),
          _dong4dTuDongThutDauDong(),
          const Divider(height: 40),
          _dong4eTuDongThemDuongKeChia(),
          const Divider(height: 40),
          _dong4fTuDongVietHoaDauCau(),
          const Divider(height: 40),
          _dong5PhimTat(),
          const Divider(height: 40),
          _dong6Micro(),
        ],
      ),
    );
  }

  Widget _tieuDeDong(String s) => Text(
        s,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );

  Widget _nutTimHieuThem(VoidCallback onPressed) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton(onPressed: onPressed, child: const Text('Tìm hiểu thêm')),
      );

  Widget _dong2TuTatMicro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Khi không nói, tự động tắt Micro sau:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            SizedBox(
              width: 56,
              child: TextField(
                controller: _oTuTatMicro,
                focusNode: _focusTuTatMicro,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _apDungTuTatMicro(),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('giây'),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Tự động tắt Micro khi không nói',
              _giaiThichTuTatMicroNgan,
              _giaiThichTuTatMicro,
            )),
      ],
    );
  }

  Widget _dong1ThoiGian() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Thời gian bật lại micro sau khi gõ tay xong'),
        const SizedBox(height: 10),
        DropdownButton<double>(
          value: _thoiGian,
          isExpanded: true,
          items: [
            for (final g in _cacMucThoiGian)
              DropdownMenuItem(value: g, child: Text(_nhanThoiGian(g))),
          ],
          onChanged: (gia) {
            if (gia == null) return;
            setState(() => _thoiGian = gia);
            widget.caiDat.datThoiGianBatLai(gia);
          },
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Thời gian bật lại micro',
              _giaiThichThoiGianNgan,
              _giaiThichThoiGian,
            )),
      ],
    );
  }

  Widget _dong3TuDongChen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động chèn dấu cách sau mỗi lần nói'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongChen ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _tuDongChen ? const Color(0xFF1A73E8) : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _tuDongChen,
              onChanged: (bat) async {
                setState(() => _tuDongChen = bat);
                await widget.caiDat.datTuDongChenKhoangCach(bat);
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Tự động chèn dấu cách',
              _giaiThichChenCachNgan,
              _giaiThichChenCach,
            )),
      ],
    );
  }

  Widget _dong4AI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động kiểm tra chính tả và đề xuất sửa bằng AI'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _kiemTraChinhTa ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _kiemTraChinhTa
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _kiemTraChinhTa,
              onChanged: (bat) async {
                setState(() => _kiemTraChinhTa = bat);
                await widget.caiDat.datKiemTraChinhTaBangAI(bat);
                if (!bat) widget.khiTatKiemTraChinhTa();
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Kiểm tra chính tả bằng AI',
              _giaiThichChinhTaNgan,
              _giaiThichChinhTa,
            )),
      ],
    );
  }

  Widget _dong4bChenDauCauAI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động chèn dấu câu vào giữa các đoạn văn bằng AI'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongChenDauCau ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _tuDongChenDauCau
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _tuDongChenDauCau,
              onChanged: (bat) async {
                setState(() => _tuDongChenDauCau = bat);
                await widget.caiDat.datTuDongChenDauCauBangAI(bat);
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Tự động chèn dấu câu bằng AI',
              _giaiThichChenDauCauNgan,
              _giaiThichChenDauCau,
            )),
      ],
    );
  }

  /// (VIỆC 5a) Ba dòng cài đặt mới cho hành vi khi xuống dòng (Enter) —
  /// cùng pattern Column + Row + Switch + nút "Tìm hiểu thêm" với
  /// `_dong3TuDongChen`/`_dong4AI` ở trên.
  Widget _dong4cTuDongThemDauCham() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động thêm dấu chấm trước khi xuống dòng'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongThemDauCham ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _tuDongThemDauCham
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _tuDongThemDauCham,
              onChanged: (bat) async {
                setState(() => _tuDongThemDauCham = bat);
                await widget.caiDat.datTuDongThemDauCham(bat);
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Tự động thêm dấu chấm',
              _giaiThichThemDauChamNgan,
              _giaiThichThemDauCham,
            )),
      ],
    );
  }

  Widget _dong4dTuDongThutDauDong() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động thụt đầu dòng khi xuống dòng'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongThutDauDong ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _tuDongThutDauDong
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _tuDongThutDauDong,
              onChanged: (bat) async {
                setState(() => _tuDongThutDauDong = bat);
                await widget.caiDat.datTuDongThutDauDong(bat);
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Tự động thụt đầu dòng',
              _giaiThichThutDauDongNgan,
              _giaiThichThutDauDong,
            )),
      ],
    );
  }

  Widget _dong4eTuDongThemDuongKeChia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động thêm đường kẻ chia văn bản khi xuống dòng 2 lần'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongThemDuongKeChia ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _tuDongThemDuongKeChia
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _tuDongThemDuongKeChia,
              onChanged: (bat) async {
                setState(() => _tuDongThemDuongKeChia = bat);
                await widget.caiDat.datTuDongThemDuongKeChia(bat);
                widget.khiDoiTuDongThemDuongKeChia?.call();
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Đường kẻ chia văn bản',
              _giaiThichDuongKeChiaNgan,
              _giaiThichDuongKeChia,
            )),
      ],
    );
  }

  /// (VIỆC 4a) Cùng pattern Column + Row + Switch + nút "Tìm hiểu thêm" với
  /// ba dòng cài đặt xuống dòng ở trên.
  Widget _dong4fTuDongVietHoaDauCau() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động viết Hoa ở đầu câu'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongVietHoaDauCau ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _tuDongVietHoaDauCau
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _tuDongVietHoaDauCau,
              onChanged: (bat) async {
                setState(() => _tuDongVietHoaDauCau = bat);
                await widget.caiDat.datTuDongVietHoaDauCau(bat);
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Tự động viết Hoa ở đầu câu',
              _giaiThichVietHoaDauCauNgan,
              _giaiThichVietHoaDauCau,
            )),
      ],
    );
  }

  Widget _oPhim(String nhan, VoidCallback khiBam) {
    return InkWell(
      onTap: khiBam,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDADCE0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(nhan, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// Modal chọn phím thứ hai: nghe phím vật lý kế tiếp, bỏ qua các phím biến
  /// đổi (Ctrl/Alt/Shift/Meta) — chính cách này đã tự bảo đảm phím thứ hai
  /// không bao giờ trùng với bộ biến đổi đang chọn (một phím biến đổi không
  /// bao giờ lọt qua được để trở thành "phím thứ hai" cả).
  Future<String?> _moDialogBatPhim(BuildContext ctxCha) async {
    final tieuDiem = FocusNode();
    final ketQua = await showDialog<String>(
      context: ctxCha,
      builder: (ctx) => AlertDialog(
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
            if (laBoBienDoi) return; // Phím biến đổi không được làm phím thứ hai.
            final nhan = phim.keyLabel;
            if (nhan.isEmpty) return;
            Navigator.of(ctx).pop(nhan.toUpperCase());
          },
          child: const SizedBox(
            height: 60,
            child: Center(child: Text('Hãy nhấn một phím bất kỳ trên bàn phím...')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Huỷ'),
          ),
        ],
      ),
    );
    tieuDiem.dispose();
    return ketQua;
  }

  Future<void> _moDialogSuaPhimTat() async {
    var boBienDoiTam = _phimTatBoBienDoi;
    var phimTam = _phimTatPhim;
    var loiXungDot = false;
    String? tenXungDot;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhatModal) {
          Future<void> chonBoBienDoi() async {
            final chon = await showDialog<String>(
              context: ctx,
              builder: (ctx2) => SimpleDialog(
                title: const Text('Chọn bộ biến đổi'),
                children: [
                  for (final bbd in _cacBoBienDoi)
                    SimpleDialogOption(
                      onPressed: () => Navigator.of(ctx2).pop(bbd),
                      child: Text(bbd),
                    ),
                ],
              ),
            );
            if (chon != null) {
              capNhatModal(() {
                boBienDoiTam = chon;
                loiXungDot = false;
              });
            }
          }

          Future<void> chonPhim() async {
            final chon = await _moDialogBatPhim(ctx);
            if (chon != null) {
              capNhatModal(() {
                phimTam = chon;
                loiXungDot = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Phím tắt tắt/mở Micro'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _oPhim(boBienDoiTam, chonBoBienDoi),
                    const SizedBox(width: 8),
                    const Text('+', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    _oPhim(phimTam, chonPhim),
                  ],
                ),
                if (loiXungDot) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Phím tắt này đang trùng với chức năng "$tenXungDot" '
                    '($boBienDoiTam + $phimTam) — chọn tổ hợp khác cho micro nhé.',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () async {
                  final xungDot = CaiDat.tenXungDot(boBienDoiTam, phimTam);
                  if (xungDot != null) {
                    capNhatModal(() {
                      loiXungDot = true;
                      tenXungDot = xungDot;
                    });
                    return;
                  }
                  await widget.caiDat.datPhimTat(boBienDoiTam, phimTam);
                  if (mounted) {
                    setState(() {
                      _phimTatBoBienDoi = boBienDoiTam;
                      _phimTatPhim = phimTam;
                    });
                  }
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

  Widget _dong5PhimTat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Phím tắt để tắt/mở Nút Micro'),
        const SizedBox(height: 6),
        InkWell(
          onTap: _moDialogSuaPhimTat,
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
                  '$_phimTatBoBienDoi + $_phimTatPhim',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF5F6368)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Chỉ có tác dụng khi thiết bị gắn bàn phím vật lý (kể cả bàn phím '
          'rời cắm vào máy tính bảng).',
          style: TextStyle(fontSize: 12, color: Color(0xFF9AA0A6)),
        ),
      ],
    );
  }

  Widget _dong6Micro() {
    final tt = _trangThaiMicro;
    IconData icon;
    Color mau;
    String tieuDe;
    String moTa;
    Widget? nut;

    if (tt == null) {
      icon = Icons.hourglass_empty;
      mau = const Color(0xFF9AA0A6);
      tieuDe = 'Đang kiểm tra…';
      moTa = '';
    } else if (tt.isGranted || tt.isLimited || tt.isProvisional) {
      icon = Icons.check_circle_outline;
      mau = const Color(0xFF188038);
      tieuDe = 'Đã cấp quyền micro';
      moTa = 'Ứng dụng dùng được micro để nghe và ghi lại giọng nói.';
    } else if (tt.isPermanentlyDenied) {
      icon = Icons.mic_off_outlined;
      mau = Colors.red.shade600;
      tieuDe = 'Quyền micro đã bị chặn';
      moTa = 'Có thể do trước đây bạn từng từ chối và chọn "Không hỏi lại", '
          'hoặc có ai đó (kể cả chính bạn) vào Cài đặt máy rồi tắt quyền này '
          'đi. Ứng dụng không thể tự hỏi lại nữa — bấm nút bên dưới để mở '
          'màn hình cài đặt riêng của Flowrite, rồi tự bật mục "Micro" lên.';
      nut = FilledButton.icon(
        onPressed: _dangXuLyMicro ? null : _moCaiDatUngDung,
        icon: const Icon(Icons.settings_outlined),
        label: const Text('Mở cài đặt ứng dụng'),
      );
    } else if (tt.isRestricted) {
      icon = Icons.block;
      mau = Colors.red.shade600;
      tieuDe = 'Quyền micro bị chặn bởi thiết bị';
      moTa = 'Thiết bị này đang bị quản lý bởi một chính sách nào đó (ví dụ '
          'máy của cơ quan, trường học) và chặn hẳn quyền micro. Liên hệ '
          'người quản lý thiết bị để được mở.';
    } else {
      icon = Icons.mic_none;
      mau = const Color(0xFFF29900);
      tieuDe = 'Chưa cấp quyền micro';
      moTa = 'Ứng dụng cần quyền ghi âm của máy mới nghe được giọng nói. '
          'Bấm nút bên dưới để cấp quyền.';
      nut = FilledButton.icon(
        onPressed: _dangXuLyMicro ? null : _capQuyenMicro,
        icon: const Icon(Icons.mic),
        label: const Text('Cấp quyền micro'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _tieuDeDong('Quyền dùng micro của thiết bị')),
            IconButton(
              onPressed: _dangXuLyMicro ? null : _kiemTraQuyenMicro,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Kiểm tra lại',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: mau, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tieuDe, style: TextStyle(color: mau, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (moTa.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(moTa, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
        ],
        if (nut != null) ...[
          const SizedBox(height: 10),
          nut,
        ],
        if (_dangXuLyMicro) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}

const _giaiThichTuTatMicroNgan = '''
Micro đang bật mà quá lâu không có thêm chữ nào (nói hay gõ tay đều tính) thì tự tắt hẳn, đỡ hao pin. Chỉnh từ **10 đến 120 giây**.
''';

const _giaiThichTuTatMicro = '''
Micro bật mãi mà không dùng tới rất tốn pin. Cài đặt này quy định: nếu micro đang bật mà im lặng liên tục — không có chữ nào mới xuất hiện trong bài, dù do nói hay do bạn tự gõ tay — quá số giây đặt ở đây, ứng dụng sẽ tự tắt hẳn micro. Muốn nghe lại thì tự bấm nút micro hoặc phím tắt, ứng dụng không tự bật lại.
''';

const _giaiThichThoiGianNgan = '''
Khi bạn gõ phím, ứng dụng **tắt hẳn micro** một lúc để khỏi nghe nhầm tiếng gõ phím thành lời nói. Cài đặt này là **thời gian chờ** sau khi bạn ngừng gõ, trước khi micro tự bật lại. Để **ngắn** thì nói tiếp nhanh hơn nhưng dễ bắt nhầm âm thanh lúc bạn còn đang lơ đãng; để **dài** thì an toàn hơn nhưng phải chờ lâu hơn. Mặc định **1 giây** là hợp lý cho hầu hết mọi người. Chọn **"Không tự động bật lại Micro"** nếu bạn muốn hoàn toàn tự bấm nút micro mỗi lần muốn nói tiếp, không để ứng dụng tự quyết định thời điểm.
''';

const _giaiThichThoiGian = '''
Khi bạn đang nói mà tay chạm vào bàn phím để gõ thêm chữ, ứng dụng sẽ **tắt hẳn micro** ngay lập tức trong một lúc — làm vậy để tiếng gõ phím, tiếng bạn lẩm bẩm khi suy nghĩ chữ cần gõ, hay bất cứ âm thanh nào trong lúc bạn đang bận tay gõ không bị micro nghe nhầm thành một câu nói mới.

Cài đặt này quyết định **ứng dụng sẽ chờ bao lâu**, kể từ lúc bạn **ngừng gõ** (không chạm bàn phím nữa), rồi mới tự động bật micro nghe lại.

Ví dụ dễ hình dung: bạn đang nói dở câu "Cuộc họp sáng mai lúc", rồi bạn ngừng nói, tự tay gõ thêm mấy chữ "9 giờ". Ngay khi ngón tay bạn chạm phím đầu tiên, micro tắt phụt. Gõ xong chữ cuối cùng, ứng dụng bắt đầu đếm — hết đúng khoảng thời gian bạn chọn ở đây thì micro mới bật trở lại, để bạn nói tiếp phần còn lại của câu.

Chọn thời gian **ngắn** (ví dụ 0,5 giây): tiện vì nói tiếp được gần như ngay lập tức. Nhưng nếu thói quen gõ của bạn hay bị ngắt quãng — gõ một chữ, dừng tay một chút để suy nghĩ, rồi gõ tiếp — thì trong lúc bạn đang dừng tay suy nghĩ đó (chưa gõ xong hẳn), micro có thể đã bật lên và vô tình nghe được tiếng bạn lẩm bẩm, tiếng thở dài, hay tiếng ồn xung quanh, biến chúng thành chữ chen ngang vào bài mà bạn không muốn.

Chọn thời gian **dài** (ví dụ 5 giây): an toàn hơn, gần như chắc chắn bạn đã gõ xong hẳn ứng dụng mới bật lại micro. Nhưng đổi lại, gõ xong mà muốn nói tiếp ngay, bạn sẽ phải chờ lâu hơn, cảm giác ứng dụng "đơ" một nhịp trước khi chịu nghe.

Mức mặc định **1 giây** là khoảng vừa phải, hợp với cách gõ của phần lớn mọi người: đủ để gõ xong một từ hay một con số ngắn mà không bị ngắt giữa chừng, mà cũng không phải chờ quá lâu để nói tiếp.
''';

const _giaiThichChenCachNgan = '''
Mỗi lần bạn nói xong một đoạn, ứng dụng tự thêm một **dấu cách** vào ngay sau đoạn đó, để chữ gõ tay tiếp theo (nếu có) không bị dính liền vào cuối câu vừa nói. Tắt đi thì để nguyên như bộ nhận dạng giọng nói trả về, không tự chèn gì thêm.
''';

const _giaiThichChenCach = '''
Khi giọng nói vừa dứt một câu, bộ nhận dạng của máy không phải lúc nào cũng tự thêm dấu cách vào cuối câu — có lúc câu vừa nói dừng lại đúng ngay sau chữ cuối, không có khoảng trắng nào theo sau cả.

Nếu ngay lúc đó bạn gõ tay tiếp vào (hoặc nói tiếp một câu khác), chữ mới sẽ bị **dính liền** vào chữ vừa nói, tạo ra một cụm chữ sai chính tả. Ví dụ: bạn nói ra được câu "Thành đẹp trai ./.", câu này kết thúc ngay sau dấu chấm cuối, không có dấu cách theo sau. Gõ tay tiếp chữ "abc" ngay sau đó — nếu không có tính năng này, kết quả sẽ là "./.abc" dính chùm lại với nhau.

Bật tính năng này (mặc định là **bật**), mỗi khi bạn nói xong một đoạn, ứng dụng tự chèn ngay một dấu cách vào cuối đoạn đó, cho ra kết quả đúng: "./. " sẵn sàng đón chữ tiếp theo, gõ tay hay nói tiếp đều không còn bị dính.

Tắt tính năng này (chọn Không), ứng dụng để nguyên đúng như bộ nhận dạng giọng nói trả về, không tự thêm dấu cách nào cả — gõ hay nói tiếp ngay sau đó có thể bị dính liền như ví dụ ở trên.

Việc chèn dấu cách này chỉ xảy ra ở cuối mỗi đoạn NÓI. Còn gõ tay ở bất kỳ đâu trong bài — kể cả ngay giữa một đoạn do nói tạo ra — luôn dính liền bình thường như một trang soạn thảo thường, không có gì tự động chèn thêm; ứng dụng không còn phân biệt chữ nào do nói, chữ nào do gõ tay nữa, mọi chữ trong bài đều bình đẳng như nhau.
''';

const _giaiThichChinhTaNgan = '''
Bật lên, mỗi khi bạn viết xong một đoạn mới (nói hoặc gõ), ứng dụng gửi ĐÚNG đoạn mới đó cho AI kiểm tra chính tả. Từ nào sai sẽ được **gạch đỏ chân** — bấm vào từ đó để xem AI đề xuất từ thay thế.
''';

const _giaiThichChinhTa = '''
Khi tính năng này bật, mỗi lần bạn viết xong một đoạn văn mới (dù bằng giọng nói hay gõ tay), ứng dụng sẽ gửi đoạn văn đó lên máy chủ AI để kiểm tra chính tả. Chỉ đoạn văn **CHƯA từng được kiểm tra** mới được gửi đi — đoạn nào AI đã đọc qua rồi sẽ không gửi lại, để đỡ tốn dữ liệu và hạn mức AI.

Từ nào AI cho là sai chính tả sẽ được **gạch chân màu đỏ** ngay trong bài. Bấm vào đúng từ đó, một menu nhỏ hiện ra:

- Các dòng đầu là những từ **AI đề xuất thay thế** — bấm vào từ nào thì từ đó lập tức đè lên từ sai.
- Dòng **"Xoá"** (màu đỏ) — xoá hẳn từ sai đó khỏi bài, không thay bằng gì cả. Đây không phải do AI đề xuất, mà là một lựa chọn có sẵn của ứng dụng cho mọi từ bị gạch đỏ.
- Dòng **"Huỷ đề xuất"** (màu xanh lá) — bấm vào thì không có gì đổi trong bài, chỉ là ứng dụng thôi coi từ đó là sai nữa (hết gạch đỏ chân).

Tắt tính năng này đi thì mọi gạch đỏ đang hiện biến mất ngay, và ứng dụng ngừng gọi AI kiểm tra chính tả cho tới khi bạn bật lại.
''';

const _giaiThichChenDauCauNgan = '''
Bật lên, AI tự chèn thêm dấu câu còn thiếu (dấu chấm, phẩy, hỏi, than...) vào những chỗ hợp lý trong bài. Đoạn dấu câu vừa chèn nhấp nháy **nền xanh dương** trong 4 giây rồi trở về chữ bình thường.
''';

const _giaiThichChenDauCau = '''
Khi tính năng này bật, cùng lúc với việc kiểm tra chính tả (nếu tính năng đó cũng đang bật), AI còn tự chèn thêm những dấu câu còn thiếu vào bài: dấu chấm, phẩy, hỏi, than, chấm phẩy, hai chấm, ba chấm, ngoặc đơn, ngoặc kép, gạch ngang... tuỳ chỗ nào AI thấy cần.

Ngay sau khi AI chèn xong, đúng đoạn dấu câu đó **nhấp nháy nền xanh dương** trong 4 giây để bạn dễ nhận ra chỗ AI vừa sửa, rồi tự động biến mất — trở về chữ bình thường như mọi ký tự khác trong bài, không cần bấm gì thêm.

Nếu cả hai tính năng "Kiểm tra chính tả bằng AI" và "Tự động chèn dấu câu bằng AI" đều bật, chúng gộp chung vào MỘT lần gọi AI duy nhất để đỡ tốn hạn mức. Tắt tính năng này đi thì AI chỉ còn sửa chính tả, không tự thêm dấu câu nào nữa.
''';

const _giaiThichThemDauChamNgan = '''
Bấm **Enter** ở cuối câu: nếu ký tự ngay trước con trỏ là dấu cách, nó được thay bằng dấu chấm; nếu không, ứng dụng tự thêm một dấu chấm rồi mới xuống dòng.
''';

const _giaiThichThemDauCham = '''
Khi bạn bấm Enter để xuống dòng, ứng dụng nhìn lại ký tự ngay trước con trỏ:

- Nếu đó là một **dấu cách**, dấu cách đó được **thay** bằng dấu chấm.
- Nếu KHÔNG phải dấu cách, ứng dụng **chèn thêm** một dấu chấm ngay trước khi xuống dòng.

Nhờ vậy mỗi dòng (đoạn) trong bài luôn kết thúc bằng dấu chấm, không cần tự gõ tay. Tắt tính năng này thì Enter chỉ đơn thuần xuống dòng, không thêm bớt gì.
''';

const _giaiThichThutDauDongNgan = '''
Sau khi xuống dòng, ứng dụng tự chèn **5 dấu cách** ở đầu dòng mới, con trỏ đứng ngay sau đó — giống thụt đầu dòng của một đoạn văn.
''';

const _giaiThichThutDauDong = '''
Mỗi lần bấm Enter để xuống dòng, ngay khi con trỏ vừa sang dòng mới, ứng dụng tự chèn thêm 5 dấu cách vào đầu dòng đó — con trỏ đứng ngay sau 5 dấu cách này, sẵn sàng để bạn gõ hoặc nói tiếp. Đây là cách thụt đầu dòng quen thuộc của văn bản tiếng Việt. Tắt tính năng này thì dòng mới bắt đầu ngay từ cột đầu tiên, không có khoảng thụt nào.
''';

const _giaiThichDuongKeChiaNgan = '''
Bấm Enter hai lần liên tiếp (tạo một dòng trống) sẽ vẽ một đường kẻ chia mờ ngay tại dòng trống đó, giúp nhìn ra ranh giới giữa các đoạn.
''';

const _giaiThichDuongKeChia = '''
Khi bạn xuống dòng và để lại một dòng TRỐNG (hoặc chỉ toàn dấu cách) — thường là do bấm Enter hai lần liên tiếp — ứng dụng tự vẽ một đường kẻ chia mờ ngay tại dòng trống đó, giúp phân biệt rõ các đoạn văn khác nhau trong bài.

Đường kẻ này chỉ là một nét vẽ hiển thị, KHÔNG phải ký tự thật chèn vào bài — nó tự bám đúng dòng trống dù màn hình xoay hay đổi kích thước. Nếu bạn gõ chữ vào đúng dòng trống đó (không còn trống nữa), đường kẻ tự biến mất; xoá hẳn dòng đó cũng vậy.
''';

const _giaiThichVietHoaDauCauNgan = '''
Gõ xong một câu (kết thúc bằng . , : ! hoặc ?) rồi sang câu mới, chữ cái đầu của từ đầu tiên tự được viết Hoa.
''';

const _giaiThichVietHoaDauCau = '''
Sau khi bạn gõ một trong các dấu . , : ! ? rồi một dấu cách, ứng dụng ghi nhớ: từ tiếp theo cần viết Hoa chữ đầu. Khi bạn gõ xong từ đó (tới khi gặp dấu cách hoặc xuống dòng tiếp theo), ứng dụng mới viết Hoa chữ cái đầu tiên của từ — không đổi gì khác trong từ đó.

Nếu ký tự đầu từ không phải chữ cái (ví dụ số), ứng dụng bỏ qua, không viết Hoa được thì thôi. Việc này áp dụng cho cả gõ tay và giọng nói. Tắt tính năng này thì chữ giữ nguyên như bạn gõ/nói, không tự viết Hoa gì cả.
''';
