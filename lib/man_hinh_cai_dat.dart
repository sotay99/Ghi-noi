// Màn hình cài đặt: sáu dòng — thời gian bật lại micro, tự động tắt micro
// khi im lặng, tự động chèn dấu cách, kiểm tra chính tả bằng AI, tự động
// chèn dấu câu bằng AI, phím tắt tắt/mở micro, và trạng thái quyền micro
// của thiết bị.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'cai_dat.dart';
import 'doan_thiet_bi.dart';
import 'loai_thiet_bi.dart';
import 'lua_chon_phim_tat.dart';
import 'mau_co_ban.dart';
import 'thong_bao_giua.dart';

const _cacMucThoiGian = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, _khongTuBatLai];

/// Hai nhóm cài đặt — trước đây là MỘT màn hình dài 12 dòng liên tiếp, nay
/// tách theo đúng chủ đề để dễ tìm hơn: [micro] gồm mọi thứ liên quan tới
/// việc bật/tắt/nghe micro và ghi âm; [hienThiVaTuDongSua] gồm mọi thứ AI tự
/// sửa chữ và hiển thị (đường kẻ chia, chấm cuối văn bản...). Vào từ hai mục
/// riêng trong menu "Tài khoản của bạn" (xem `thanh_cong_cu.dart`).
enum NhomCaiDat { micro, hienThiVaTuDongSua }

/// Giá trị đặc biệt: micro tắt hẳn khi gõ phím, người dùng phải tự bấm nút
/// micro mới nghe lại — không có bộ đếm thời gian nào tự động bật hộ.
const _khongTuBatLai = -1.0;

class ManHinhCaiDat extends StatefulWidget {
  const ManHinhCaiDat({
    super.key,
    required this.caiDat,
    required this.nhom,
    required this.khiTatKiemTraChinhTa,
    required this.khiKiemTraLaiMicro,
    this.khiDoiTuDongThemDuongKeChia,
    this.layNhatKyMicro,
    this.xoaNhatKyMicro,
  });

  final CaiDat caiDat;

  /// Nhóm cài đặt nào đang mở — quyết định tiêu đề AppBar và danh sách dòng
  /// hiển thị trong `build()`.
  final NhomCaiDat nhom;

  /// Chỉ có trên web (xem `_dong0ThietBi`) — đọc/xoá nhật ký gỡ lỗi micro
  /// (`_nhatKyMicro` bên trang soạn thảo). `null` trên Android/iOS gốc vì
  /// trang đó không ghi log này.
  final List<String> Function()? layNhatKyMicro;
  final VoidCallback? xoaNhatKyMicro;

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
  late int _soDauCachThutDauDong;
  late bool _tuDongThemDuongKeChia;
  late int _mauDuongKeChia;
  late int _phanTramMoDuongKeChia;
  late bool _chamCuoiVanBanBat;
  late int _mauChamCuoiVanBan;
  late bool _tuDongVietHoaDauCau;
  late bool _tuDongChuanHoaNgoac;
  late LuaChonPhimTat _phimTatMicro;
  late LuaChonPhimTat _phimTatGhiAm;
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
    _soDauCachThutDauDong = widget.caiDat.soDauCachThutDauDong;
    _tuDongThemDuongKeChia = widget.caiDat.tuDongThemDuongKeChia;
    _mauDuongKeChia = widget.caiDat.mauDuongKeChia;
    _phanTramMoDuongKeChia = widget.caiDat.phanTramMoDuongKeChia;
    _chamCuoiVanBanBat = widget.caiDat.chamCuoiVanBanBat;
    _mauChamCuoiVanBan = widget.caiDat.mauChamCuoiVanBan;
    _tuDongVietHoaDauCau = widget.caiDat.tuDongVietHoaDauCau;
    _tuDongChuanHoaNgoac = widget.caiDat.tuDongChuanHoaNgoac;
    _phimTatMicro = widget.caiDat.phimTatMicro;
    _phimTatGhiAm = widget.caiDat.phimTatGhiAm;
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
    final laMicro = widget.nhom == NhomCaiDat.micro;
    return Scaffold(
      appBar: AppBar(
        title: Text(laMicro ? 'Cài đặt Micro' : 'Cài đặt Hiển thị và tự động sửa'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: laMicro
            ? [
                // Nhóm MICRO — xếp theo mức quan trọng: lối thoát khi micro
                // trục trặc (chỉ web) lên đầu, rồi hai mốc thời gian tự
                // bật/tắt micro, rồi hai phím tắt (Micro/Ghi âm — cùng chủ đề
                // "bấm gì để nghe"), cuối cùng là trạng thái quyền thiết bị.
                if (kIsWeb) ...[
                  _dong0ThietBi(),
                  const Divider(height: 40),
                ],
                _dong1ThoiGian(),
                const Divider(height: 40),
                _dong2TuTatMicro(),
                const Divider(height: 40),
                _dongPhimTat(
                  laMicro: true,
                  tieuDe: 'Phím tắt cho Micro (vừa nói vừa ra chữ)',
                  hienTai: _phimTatMicro,
                ),
                const Divider(height: 40),
                _dongPhimTat(
                  laMicro: false,
                  tieuDe:
                      'Phím tắt cho Ghi âm (Ghi âm xong mới ra chữ — tạo thẻ ghi âm)',
                  hienTai: _phimTatGhiAm,
                ),
                const Divider(height: 40),
                _dong6Micro(),
              ]
            : [
                // Nhóm HIỂN THỊ & TỰ ĐỘNG SỬA — các dòng AI sửa chữ đứng
                // trước (chính tả, dấu câu, dấu cách, dấu chấm, viết hoa,
                // chuẩn hoá ngoặc — cùng chủ đề "AI/tự động chỉnh câu chữ"),
                // rồi các dòng thuần hiển thị đứng sau (thụt đầu dòng, đường
                // kẻ chia đoạn, chấm cuối văn bản — cùng chủ đề "trình bày").
                _dong4AI(),
                const Divider(height: 40),
                _dong4bChenDauCauAI(),
                const Divider(height: 40),
                _dong3TuDongChen(),
                const Divider(height: 40),
                _dong4cTuDongThemDauCham(),
                const Divider(height: 40),
                _dong4fTuDongVietHoaDauCau(),
                const Divider(height: 40),
                _dong4hTuDongChuanHoaNgoac(),
                const Divider(height: 40),
                _dong4dTuDongThutDauDong(),
                const Divider(height: 40),
                _dong4eTuDongThemDuongKeChia(),
                const Divider(height: 40),
                _dong4gChamCuoiVanBan(),
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

  /// Chỉ hiện trên WEB (xem `kIsWeb` ở `build`) — micro trên web tự đoán
  /// thiết bị (Android/PC-Mac/iPhone) bằng User-Agent, đoán sai thì người
  /// dùng bấm dòng này để tự chọn tay. Đặt ĐẦU TIÊN trong Cài đặt vì đây là
  /// lối thoát quan trọng nhất khi micro "im re" không rõ lý do.
  Widget _dong0ThietBi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _moChonThietBi,
          behavior: HitTestBehavior.opaque,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
              children: [
                const TextSpan(text: 'Nếu Micro bị trục trặc, hãy '),
                TextSpan(
                  text: 'Bấm vào đây',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _moChonThietBi,
                ),
              ],
            ),
          ),
        ),
        if (widget.layNhatKyMicro != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: _moNhatKyMicro,
              child: const Text('Xem nhật ký micro (gỡ lỗi)'),
            ),
          ),
        ],
      ],
    );
  }

  /// Bảng nhật ký micro — chỉ để GỬI CHO NGƯỜI PHÁT TRIỂN đọc khi micro ra
  /// chữ sai, không phải màn hình dùng hàng ngày. Có nút Sao chép (copy
  /// toàn bộ vào clipboard) và Xoá (dọn sạch, bắt đầu ghi lại từ đầu).
  Future<void> _moNhatKyMicro() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, capNhat) {
            final dong = widget.layNhatKyMicro!();
            final noiDung = dong.isEmpty
                ? '(chưa có gì — bật micro và nói thử, rồi mở lại bảng này)'
                : dong.join('\n');
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhật ký micro (gỡ lỗi)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bấm Sao chép rồi gửi lại toàn bộ đoạn này khi micro ra '
                      'chữ sai.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 360),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          noiDung,
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Sao chép'),
                            onPressed: dong.isEmpty
                                ? null
                                : () {
                                    Clipboard.setData(
                                        ClipboardData(text: noiDung));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Đã sao chép nhật ký.')),
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xoá'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700),
                            onPressed: dong.isEmpty
                                ? null
                                : () {
                                    widget.xoaNhatKyMicro?.call();
                                    capNhat(() {});
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Bảng modal nhỏ hiện lên từ dưới, mỗi thiết bị một dòng gồm HAI dòng
  /// chồng lên nhau (tên đậm ở trên, mô tả ngắn ở dưới) — dễ chọn bằng
  /// ngón tay. Trả về `(true, thietBi)` khi người dùng THẬT SỰ chọn một
  /// mục (kể cả "Tự động nhận diện", lúc đó `thietBi` là `null`) để phân
  /// biệt với việc đóng modal mà không chọn gì (trả về `null`).
  Future<void> _moChonThietBi() async {
    final ketQua = await showModalBottomSheet<(bool, ThietBi?)>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        Widget dong({
          required String ten,
          required String moTa,
          required bool dangChon,
          required VoidCallback onTap,
          IconData? bieuTuong,
        }) {
          return ListTile(
            onTap: onTap,
            leading: bieuTuong == null ? null : Icon(bieuTuong),
            title: Text(ten,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(moTa),
            trailing:
                dangChon ? const Icon(Icons.check, color: Colors.blue) : null,
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chọn thiết bị - Micro (vừa nói vừa ra chữ) sẽ hoạt động '
                    'ổn định với Đúng thiết bị đang chọn',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              dong(
                ten: 'Tự động nhận diện (mặc định)',
                moTa: 'Để app tự đoán qua trình duyệt — kết quả hiện tại: '
                    '${doanThietBi().ten}.',
                dangChon: widget.caiDat.thietBiChonTay == null,
                onTap: () => Navigator.of(context).pop((true, null)),
                bieuTuong: Icons.auto_awesome,
              ),
              for (final t in ThietBi.values)
                dong(
                  ten: t.ten,
                  moTa: t.moTa,
                  dangChon: widget.caiDat.thietBiChonTay == t,
                  onTap: () => Navigator.of(context).pop((true, t)),
                  bieuTuong: t.bieuTuong,
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (ketQua == null) return; // đóng modal mà không chọn gì.
    final (_, thietBiMoi) = ketQua;
    await widget.caiDat.datThietBiChonTay(thietBiMoi);
    await widget.khiKiemTraLaiMicro();
    if (mounted) setState(() {});
  }

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
        if (_tuDongThutDauDong) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Số dấu cách chèn vào: '),
              DropdownButton<int>(
                value: _soDauCachThutDauDong,
                items: [
                  for (var n = 1; n <= 7; n++)
                    DropdownMenuItem(value: n, child: Text('$n dấu cách')),
                ],
                onChanged: (n) async {
                  if (n == null) return;
                  setState(() => _soDauCachThutDauDong = n);
                  await widget.caiDat.datSoDauCachThutDauDong(n);
                },
              ),
            ],
          ),
        ],
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
        _tieuDeDong('Tự động thêm đường kẻ chia đoạn văn khi xuống dòng 2 lần'),
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
        if (_tuDongThemDuongKeChia) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Màu đường kẻ: '),
              GestureDetector(
                onTap: () async {
                  final mau = await hienThiChonMauCoBanChoTen(
                    context,
                    tieuDe: 'Chọn màu đường kẻ chia đoạn văn',
                  );
                  if (mau == null) return;
                  setState(() => _mauDuongKeChia = mau.toARGB32());
                  await widget.caiDat.datMauDuongKeChia(mau);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(_mauDuongKeChia),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBDBDBD)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Độ rõ: '),
              Expanded(
                child: Slider(
                  value: _phanTramMoDuongKeChia.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 90,
                  label: '$_phanTramMoDuongKeChia%',
                  onChanged: (g) => setState(() => _phanTramMoDuongKeChia = g.round()),
                  onChangeEnd: (g) async {
                    await widget.caiDat.datPhanTramMoDuongKeChia(g.round());
                  },
                ),
              ),
              SizedBox(
                width: 44,
                child: Text('$_phanTramMoDuongKeChia%', textAlign: TextAlign.right),
              ),
            ],
          ),
        ],
        _nutTimHieuThem(() => _hienGiaiThich(
              'Đường kẻ chia đoạn văn',
              _giaiThichDuongKeChiaNgan,
              _giaiThichDuongKeChia,
            )),
      ],
    );
  }

  /// "Chấm tròn đánh dấu cuối văn bản" — bật/tắt và chọn màu (cả hai vòng
  /// tròn đồng tâm cùng đổi màu theo lựa chọn này).
  Widget _dong4gChamCuoiVanBan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Chấm tròn đánh dấu cuối văn bản'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _chamCuoiVanBanBat ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _chamCuoiVanBanBat
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _chamCuoiVanBanBat,
              onChanged: (bat) async {
                setState(() => _chamCuoiVanBanBat = bat);
                await widget.caiDat.datChamCuoiVanBanBat(bat);
              },
            ),
          ],
        ),
        if (_chamCuoiVanBanBat) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Màu chấm tròn: '),
              GestureDetector(
                onTap: () async {
                  final mau = await hienThiChonMauCoBanChoTen(
                    context,
                    tieuDe: 'Chọn màu chấm tròn cuối văn bản',
                  );
                  if (mau == null) return;
                  setState(() => _mauChamCuoiVanBan = mau.toARGB32());
                  await widget.caiDat.datMauChamCuoiVanBan(mau);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(_mauChamCuoiVanBan),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBDBDBD)),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _dong4hTuDongChuanHoaNgoac() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Chuẩn hoá các cặp dấu đóng-mở ngoặc'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongChuanHoaNgoac ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _tuDongChuanHoaNgoac
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _tuDongChuanHoaNgoac,
              onChanged: (bat) async {
                setState(() => _tuDongChuanHoaNgoac = bat);
                await widget.caiDat.datTuDongChuanHoaNgoac(bat);
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Chuẩn hoá các cặp dấu đóng-mở ngoặc',
              _giaiThichChuanHoaNgoacNgan,
              _giaiThichChuanHoaNgoac,
            )),
      ],
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

  /// Tên chức năng, dùng cả trong thông báo hoán đổi lẫn thông báo xung đột
  /// — luôn kèm chú thích phân biệt hai chức năng (theo đúng yêu cầu: đừng
  /// để người dùng nhầm "Micro" với "Ghi âm").
  String _tenChucNangPhimTat(bool laMicro) =>
      laMicro ? 'Micro (vừa nói vừa ra chữ)' : 'Ghi âm (Ghi âm xong mới ra chữ)';

  /// Modal 4 lựa chọn phím tắt — DÙNG CHUNG cho cả Micro lẫn Ghi âm
  /// ([laMicro] chọn cái nào đang sửa). Bốn lựa chọn loại trừ lẫn nhau
  /// (radio thật, không thể bỏ trống hay chọn nhiều): phím Tab một mình,
  /// Ctrl + một phím do người dùng tự bấm chọn, bấm Ctrl 2 lần liên tiếp,
  /// hoặc bấm Shift 2 lần liên tiếp.
  Future<void> _moDialogChonPhimTat({required bool laMicro}) async {
    final banDau = laMicro ? _phimTatMicro : _phimTatGhiAm;
    var loaiTam = banDau.loai;
    var phimCtrlTam = banDau.phim;
    String? loiXungDot;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhatModal) {
          Widget oLuaChon({
            required String loai,
            required String nhan,
            required String giaiThich,
          }) {
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
            final chon = await _moDialogBatPhim(ctx);
            if (chon != null) {
              capNhatModal(() {
                phimCtrlTam = chon;
                loiXungDot = null;
              });
            }
          }

          return AlertDialog(
            title: Text('Phím tắt cho ${_tenChucNangPhimTat(laMicro)}'),
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
                                        : const Color(0xFF1A73E8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit_outlined,
                                    size: 16, color: Color(0xFF5F6368)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (loiXungDot != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        loiXungDot!,
                        style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Huỷ'),
              ),
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
                  }
                  // Ba lựa chọn không tham số (Tab/CtrlDup/ShiftDup) có cơ
                  // chế TỰ ĐỔI hộ theo vòng tròn (xem
                  // `datPhimTatVaTuHoanDoiNeuTrung`) nên không cần chặn ở
                  // đây — chỉ 'ctrl'+phím (có tham số, không nằm trong
                  // vòng tự đổi) mới cần chặn thủ công khi trùng.
                  if (moi.loai == 'ctrl') {
                    final kia = laMicro ? widget.caiDat.phimTatGhiAm : widget.caiDat.phimTatMicro;
                    if (kia.coBangVoi(moi)) {
                      capNhatModal(() => loiXungDot =
                          'Phím tắt này đang trùng với chức năng "${_tenChucNangPhimTat(!laMicro)}" '
                          '(${moi.nhan}) — chọn phím khác nhé.');
                      return;
                    }
                  }

                  final coHoanDoi = await widget.caiDat.datPhimTatVaTuHoanDoiNeuTrung(
                    laMicro: laMicro,
                    moi: moi,
                  );
                  if (!mounted) return;
                  setState(() {
                    _phimTatMicro = widget.caiDat.phimTatMicro;
                    _phimTatGhiAm = widget.caiDat.phimTatGhiAm;
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (coHoanDoi && mounted) {
                    hienThongBaoGiua(
                      context,
                      'Đã chọn phím ${laMicro ? _phimTatMicro.nhan : _phimTatGhiAm.nhan} cho '
                      'chức năng ${_tenChucNangPhimTat(laMicro)}\n'
                      'Đã chọn phím ${laMicro ? _phimTatGhiAm.nhan : _phimTatMicro.nhan} cho '
                      'chức năng ${_tenChucNangPhimTat(!laMicro)}',
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

  Widget _dongPhimTat({
    required bool laMicro,
    required String tieuDe,
    required LuaChonPhimTat hienTai,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong(tieuDe),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _moDialogChonPhimTat(laMicro: laMicro),
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
                  hienTai.nhan,
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
Khi tay bạn chạm bàn phím để gõ thêm chữ, ứng dụng **tắt hẳn micro** ngay lập tức, để tiếng gõ phím hay tiếng lẩm bẩm lúc nghĩ chữ không bị nghe nhầm thành lời nói. Cài đặt này quyết định ứng dụng chờ bao lâu, kể từ lúc bạn **ngừng gõ**, rồi mới tự bật micro nghe lại.

Chọn **ngắn** thì nói tiếp được gần như ngay, nhưng nếu bạn hay gõ ngắt quãng (gõ một chữ, dừng tay suy nghĩ, gõ tiếp), micro có thể bật sớm và nghe nhầm tiếng lẩm bẩm hay tiếng ồn xung quanh thành chữ chen ngang. Chọn **dài** thì an toàn hơn nhưng phải chờ lâu hơn mới nói tiếp được.

Mặc định **1 giây** là mức vừa phải, hợp với cách gõ của phần lớn mọi người.
''';

const _giaiThichChenCachNgan = '''
Mỗi lần bạn nói xong một đoạn, ứng dụng tự thêm một **dấu cách** vào ngay sau đoạn đó, để chữ gõ tay tiếp theo (nếu có) không bị dính liền vào cuối câu vừa nói. Tắt đi thì để nguyên như bộ nhận dạng giọng nói trả về, không tự chèn gì thêm.
''';

const _giaiThichChenCach = '''
Bộ nhận dạng giọng nói không phải lúc nào cũng tự thêm dấu cách vào cuối câu — có lúc dừng lại đúng ngay sau chữ cuối, không có khoảng trắng theo sau. Nếu ngay đó bạn gõ tay tiếp hoặc nói tiếp, chữ mới sẽ bị **dính liền** vào chữ vừa nói. Ví dụ: nói ra "Thành đẹp trai ./.", rồi gõ tay tiếp "abc" — không có tính năng này sẽ dính thành "./.abc".

Bật tính năng này (mặc định **bật**), mỗi khi nói xong một đoạn, ứng dụng tự chèn một dấu cách vào cuối đoạn đó để chữ tiếp theo không bị dính. Tắt đi thì để nguyên như bộ nhận dạng trả về, không tự chèn gì thêm.

Chỉ áp dụng ở cuối mỗi đoạn NÓI — gõ tay ở bất kỳ đâu trong bài luôn dính liền bình thường như một trang soạn thảo thường, không có gì tự động chèn thêm.
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
Sau khi xuống dòng, ứng dụng tự chèn một số dấu cách (bạn chọn từ 1-7, mặc định 3) ở đầu dòng mới, con trỏ đứng ngay sau đó — giống thụt đầu dòng của một đoạn văn.
''';

const _giaiThichThutDauDong = '''
Mỗi lần bấm Enter để xuống dòng, ngay khi con trỏ vừa sang dòng mới, ứng dụng tự chèn thêm một số dấu cách vào đầu dòng đó — con trỏ đứng ngay sau các dấu cách này, sẵn sàng để bạn gõ hoặc nói tiếp. Số dấu cách do bạn chọn ở Menu thả xuống ngay dưới công tắc này (từ 1 đến 7, mặc định 3) — đổi lựa chọn thì áp dụng ngay cho lần xuống dòng kế tiếp. Đây là cách thụt đầu dòng quen thuộc của văn bản tiếng Việt. Tắt tính năng này thì dòng mới bắt đầu ngay từ cột đầu tiên, không có khoảng thụt nào.
''';

const _giaiThichDuongKeChiaNgan = '''
Bấm Enter hai lần liên tiếp (tạo một dòng trống) sẽ vẽ một đường kẻ chia đoạn văn mờ ngay tại dòng trống đó, giúp nhìn ra ranh giới giữa các đoạn.
''';

const _giaiThichDuongKeChia = '''
Khi bạn xuống dòng và để lại một dòng TRỐNG (hoặc chỉ toàn dấu cách) — thường là do bấm Enter hai lần liên tiếp — ứng dụng tự vẽ một đường kẻ chia đoạn văn mờ ngay tại dòng trống đó, giúp phân biệt rõ các đoạn văn khác nhau trong bài. Bạn chọn được màu và độ rõ của đường kẻ này ở ngay bên trên.

Đường kẻ này chỉ là một nét vẽ hiển thị, KHÔNG phải ký tự thật chèn vào bài — nó tự bám đúng dòng trống dù màn hình xoay hay đổi kích thước. Nếu bạn gõ chữ vào đúng dòng trống đó (không còn trống nữa), đường kẻ tự biến mất; xoá hẳn dòng đó cũng vậy.
''';

const _giaiThichVietHoaDauCauNgan = '''
Gõ xong một câu (kết thúc bằng . , : ! hoặc ?) rồi sang câu mới, chữ cái đầu của từ đầu tiên tự được viết Hoa.
''';

const _giaiThichVietHoaDauCau = '''
Sau khi bạn gõ một trong các dấu . , : ! ? rồi một dấu cách, ứng dụng ghi nhớ: từ tiếp theo cần viết Hoa chữ đầu. Khi bạn gõ xong từ đó (tới khi gặp dấu cách hoặc xuống dòng tiếp theo), ứng dụng mới viết Hoa chữ cái đầu tiên của từ — không đổi gì khác trong từ đó.

Nếu ký tự đầu từ không phải chữ cái (ví dụ số), ứng dụng bỏ qua, không viết Hoa được thì thôi. Việc này áp dụng cho cả gõ tay và giọng nói. Tắt tính năng này thì chữ giữ nguyên như bạn gõ/nói, không tự viết Hoa gì cả.
''';

const _giaiThichChuanHoaNgoacNgan = '''
Gõ một trong các dấu ( ) { } [ ] " thì ứng dụng tự xoá dấu cách thừa ngay sau dấu mở hoặc ngay trước dấu đóng của cặp đó.
''';

const _giaiThichChuanHoaNgoac = '''
Áp dụng cho bốn cặp dấu: ngoặc đơn ( ), ngoặc nhọn { }, ngoặc vuông [ ] và ngoặc kép " ". Mỗi lần bạn gõ một trong bảy ký tự này, ứng dụng quét lại để tìm ra cặp mà ký tự đó vừa hoàn thành, rồi chuẩn hoá: nếu ngay sau dấu mở là một dấu cách, xoá nó đi; nếu ngay trước dấu đóng là một dấu cách, cũng xoá nó đi. Ví dụ "( chào )" tự thành "(chào)".

Với ( ) { } [ ]: dấu mở và dấu đóng phân biệt rõ ràng, ứng dụng ghép mỗi dấu đóng với dấu mở gần nhất còn chưa có cặp. Dấu nào lẻ loi (mở mà chưa có đóng, hoặc đóng mà không có mở) thì bỏ qua, không đụng gì tới.

Với " ": dấu nháy kép không phân biệt được mở/đóng qua hình dạng, nên ứng dụng dùng quy ước đơn giản — quét từ đầu bài, dấu nháy kép thứ nhất/ba/năm... luôn là dấu mở, thứ hai/tư/sáu... luôn là dấu đóng, ghép theo đúng thứ tự đó.

Tắt tính năng này thì dấu cách quanh các dấu ngoặc/nháy kép giữ nguyên như bạn gõ, không tự xoá gì cả.
''';
