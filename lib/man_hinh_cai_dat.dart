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
import 'chuoi_cai_dat.dart';
import 'doan_thiet_bi.dart';
import 'loai_thiet_bi.dart';
import 'lua_chon_phim_tat.dart';
import 'mau_co_ban.dart';
import 'ngon_ngu.dart';
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
  });

  final CaiDat caiDat;

  /// Nhóm cài đặt nào đang mở — quyết định tiêu đề AppBar và danh sách dòng
  /// hiển thị trong `build()`.
  final NhomCaiDat nhom;

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
  NgonNgu _nn = ngonNguHienTai.value;

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
    if (giay == _khongTuBatLai) return ChCaiDat.khongTuBatLaiMicro(_nn);
    final tron = giay == giay.roundToDouble();
    final so =
        tron ? giay.toInt().toString() : giay.toStringAsFixed(1).replaceAll('.', ',');
    return '$so ${ChCaiDat.giay(_nn)}';
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
        // (YÊU CẦU MỚI) Bỏ nút "Đóng" ở `actions` — thay bằng nút X đỏ gọn
        // gàng ở góc trên bên phải.
        title: Row(
          children: [
            Expanded(child: Text(tieuDe)),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: ChCaiDat.dong(_nn),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ChCaiDat.giaiThichNganTieuDe(_nn),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 8),
              _doanVanCoDam(ngan),
              const SizedBox(height: 20),
              Text(
                ChCaiDat.giaiThichChiTietTieuDe(_nn),
                style: const TextStyle(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NgonNgu>(
      valueListenable: ngonNguHienTai,
      builder: (context, nn, _) => _build(context, nn),
    );
  }

  Widget _build(BuildContext context, NgonNgu nn) {
    _nn = nn;
    final laMicro = widget.nhom == NhomCaiDat.micro;
    return Scaffold(
      appBar: AppBar(
        title: Text(laMicro
            ? ChCaiDat.caiDatMicro(nn)
            : ChCaiDat.caiDatHienThiVaTuDongSua(nn)),
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
                  tieuDe: ChCaiDat.phimTatChoMicro(_nn),
                  hienTai: _phimTatMicro,
                ),
                const Divider(height: 40),
                _dongPhimTat(
                  laMicro: false,
                  tieuDe: ChCaiDat.phimTatChoGhiAm(_nn),
                  hienTai: _phimTatGhiAm,
                ),
                const Divider(height: 40),
                _dong6Micro(),
              ]
            : [
                // Nhóm HIỂN THỊ & TỰ ĐỘNG SỬA — (YÊU CẦU MỚI) hai dòng AI
                // tốn hạn mức gọi API (chính tả, dấu câu) dời xuống CUỐI
                // CÙNG; các dòng thuần hiển thị/tự động sửa cục bộ (dấu
                // cách, dấu chấm, viết hoa, chuẩn hoá ngoặc, thụt đầu dòng,
                // đường kẻ chia đoạn, chấm cuối văn bản) lên trước.
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
                const Divider(height: 40),
                _dong4AI(),
                const Divider(height: 40),
                _dong4bChenDauCauAI(),
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
        child: TextButton(onPressed: onPressed, child: Text(ChCaiDat.timHieuThem(_nn))),
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
                TextSpan(text: ChCaiDat.neuMicroTrucTrac(_nn)),
                TextSpan(
                  text: ChCaiDat.bamVaoDay(_nn),
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
      ],
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ChCaiDat.chonThietBiTieuDe(_nn),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              dong(
                ten: ChCaiDat.tuDongNhanDienMacDinh(_nn),
                moTa: ChCaiDat.moTaTuDongNhanDien(_nn, doanThietBi().ten),
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
            Expanded(
              child: Text(
                ChCaiDat.khiKhongNoiTuDongTat(_nn),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
            Text(ChCaiDat.giay(_nn)),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              ChCaiDat.tuDongTatMicroKhiKhongNoi(_nn),
              ChCaiDat.giaiThichTuTatMicroNgan(_nn),
              ChCaiDat.giaiThichTuTatMicro(_nn),
            )),
      ],
    );
  }

  Widget _dong1ThoiGian() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong(ChCaiDat.thoiGianBatLaiMicro(_nn)),
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
              ChCaiDat.thoiGianBatLaiMicroTieuDe(_nn),
              ChCaiDat.giaiThichThoiGianNgan(_nn),
              ChCaiDat.giaiThichThoiGian(_nn),
            )),
      ],
    );
  }

  Widget _dong3TuDongChen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong(ChCaiDat.tuDongChenDauCachSauKhiNoi(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongChen ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              ChCaiDat.tuDongChenDauCachTieuDe(_nn),
              ChCaiDat.giaiThichChenCachNgan(_nn),
              ChCaiDat.giaiThichChenCach(_nn),
            )),
      ],
    );
  }

  Widget _dong4AI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong(ChCaiDat.tuDongKiemTraChinhTaVaDeXuatAI(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _kiemTraChinhTa ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              ChCaiDat.kiemTraChinhTaBangAITieuDe(_nn),
              ChCaiDat.giaiThichChinhTaNgan(_nn),
              ChCaiDat.giaiThichChinhTa(_nn),
            )),
      ],
    );
  }

  Widget _dong4bChenDauCauAI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong(ChCaiDat.tuDongChenDauCauVaoGiuaDoanVanAI(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongChenDauCau ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              ChCaiDat.tuDongChenDauCauBangAITieuDe(_nn),
              ChCaiDat.giaiThichChenDauCauNgan(_nn),
              ChCaiDat.giaiThichChenDauCau(_nn),
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
        _tieuDeDong(ChCaiDat.tuDongThemDauChamTruocXuongDong(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongThemDauCham ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              ChCaiDat.tuDongThemDauChamTieuDe(_nn),
              ChCaiDat.giaiThichThemDauChamNgan(_nn),
              ChCaiDat.giaiThichThemDauCham(_nn),
            )),
      ],
    );
  }

  Widget _dong4dTuDongThutDauDong() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong(ChCaiDat.tuDongThutDauDongKhiXuongDong(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongThutDauDong ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              Text(ChCaiDat.soDauCachChenVao(_nn)),
              DropdownButton<int>(
                value: _soDauCachThutDauDong,
                items: [
                  for (var n = 1; n <= 7; n++)
                    DropdownMenuItem(value: n, child: Text(ChCaiDat.dauCachSoLuong(_nn, n))),
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
              ChCaiDat.tuDongThutDauDongTieuDe(_nn),
              ChCaiDat.giaiThichThutDauDongNgan(_nn),
              ChCaiDat.giaiThichThutDauDong(_nn),
            )),
      ],
    );
  }

  Widget _dong4eTuDongThemDuongKeChia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong(ChCaiDat.tuDongThemDuongKeChiaKhiXuongDong2Lan(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongThemDuongKeChia ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              Text(ChCaiDat.mauDuongKe(_nn)),
              GestureDetector(
                onTap: () async {
                  final mau = await hienThiChonMauCoBanChoTen(
                    context,
                    tieuDe: ChCaiDat.chonMauDuongKeChiaDoanVan(_nn),
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
              Text(ChCaiDat.doRo(_nn)),
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
              ChCaiDat.duongKeChiaDoanVanTieuDe(_nn),
              ChCaiDat.giaiThichDuongKeChiaNgan(_nn),
              ChCaiDat.giaiThichDuongKeChia(_nn),
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
        _tieuDeDong(ChCaiDat.chamTronDanhDauCuoiVanBan(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _chamCuoiVanBanBat ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              Text(ChCaiDat.mauChamTron(_nn)),
              GestureDetector(
                onTap: () async {
                  final mau = await hienThiChonMauCoBanChoTen(
                    context,
                    tieuDe: ChCaiDat.chonMauChamTronCuoiVanBan(_nn),
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
        _tieuDeDong(ChCaiDat.tuDongVietHoaDauCauTieuDe(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongVietHoaDauCau ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              ChCaiDat.tuDongVietHoaDauCauTieuDe(_nn),
              ChCaiDat.giaiThichVietHoaDauCauNgan(_nn),
              ChCaiDat.giaiThichVietHoaDauCau(_nn),
            )),
      ],
    );
  }

  Widget _dong4hTuDongChuanHoaNgoac() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong(ChCaiDat.chuanHoaCacCapDauDongMoNgoac(_nn)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongChuanHoaNgoac ? ChCaiDat.dangBatCo(_nn) : ChCaiDat.dangTatKhong(_nn),
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
              ChCaiDat.chuanHoaCacCapDauDongMoNgoac(_nn),
              ChCaiDat.giaiThichChuanHoaNgoacNgan(_nn),
              ChCaiDat.giaiThichChuanHoaNgoac(_nn),
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
        title: Text(ChCaiDat.nhanMotPhim(_nn)),
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
          child: SizedBox(
            height: 60,
            child: Center(child: Text(ChCaiDat.hayNhanMotPhimBatKy(_nn))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ChCaiDat.huy(_nn)),
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
      laMicro ? ChCaiDat.tenChucNangMicro(_nn) : ChCaiDat.tenChucNangGhiAm(_nn);

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
            title: Text(ChCaiDat.phimTatCho(_nn, _tenChucNangPhimTat(laMicro))),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    oLuaChon(
                      loai: 'tab',
                      nhan: ChCaiDat.phimTab(_nn),
                      giaiThich: ChCaiDat.giaiThichTab(_nn),
                    ),
                    oLuaChon(
                      loai: 'ctrl',
                      nhan: ChCaiDat.ctrlVaPhimKhac(_nn),
                      giaiThich: ChCaiDat.giaiThichCtrl(_nn),
                    ),
                    oLuaChon(
                      loai: 'ctrlDup',
                      nhan: ChCaiDat.bamCtrl2LanLienTiep(_nn),
                      giaiThich: ChCaiDat.giaiThichCtrlDup(_nn),
                    ),
                    oLuaChon(
                      loai: 'shiftDup',
                      nhan: ChCaiDat.bamShift2LanLienTiep(_nn),
                      giaiThich: ChCaiDat.giaiThichShiftDup(_nn),
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
                                  phimCtrlTam == null
                                      ? ChCaiDat.bamDeChonPhim(_nn)
                                      : 'Ctrl + $phimCtrlTam',
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
                child: Text(ChCaiDat.huy(_nn)),
              ),
              FilledButton(
                onPressed: () async {
                  if (loaiTam == 'ctrl' && phimCtrlTam == null) {
                    capNhatModal(() =>
                        loiXungDot = ChCaiDat.hayBamChonMotPhimTruocKhiLuu(_nn));
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
                      capNhatModal(() => loiXungDot = ChCaiDat
                          .phimTatDangTrungVoiChucNang(_nn, xungDotCoDinh, moi.nhan));
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
                      capNhatModal(() => loiXungDot = ChCaiDat.phimTatDangTrungVoiChucNang(
                          _nn, _tenChucNangPhimTat(!laMicro), moi.nhan));
                      return;
                    }
                    // (YÊU CẦU MỚI — nhánh thử nghiệm) Lựa chọn 4 (tổ hợp tự
                    // chọn) không có cơ chế tự đổi hộ — phải chặn lưu nếu
                    // trùng với BẤT KỲ phím tắt nào trong 3 chức năng dùng
                    // chung, kể cả "Bộ nhớ tạm để dán văn bản" (modal riêng,
                    // không mở cùng màn này).
                    if (widget.caiDat.phimTatBoNhoTam.coBangVoi(moi)) {
                      capNhatModal(() => loiXungDot = ChCaiDat.phimTatDangTrungVoiChucNang(
                          _nn, ChCaiDat.boNhoTamDeDanVanBan(_nn), moi.nhan));
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
                      ChCaiDat.daChonPhimChoChucNang(
                        _nn,
                        laMicro ? _phimTatMicro.nhan : _phimTatGhiAm.nhan,
                        _tenChucNangPhimTat(laMicro),
                        laMicro ? _phimTatGhiAm.nhan : _phimTatMicro.nhan,
                        _tenChucNangPhimTat(!laMicro),
                      ),
                      thoiGian: const Duration(seconds: 4),
                    );
                  }
                },
                child: Text(ChCaiDat.luu(_nn)),
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
        Text(
          ChCaiDat.chiCoTacDungBanPhimVatLy(_nn),
          style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0A6)),
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
      tieuDe = ChCaiDat.dangKiemTra(_nn);
      moTa = '';
    } else if (tt.isGranted || tt.isLimited || tt.isProvisional) {
      icon = Icons.check_circle_outline;
      mau = const Color(0xFF188038);
      tieuDe = ChCaiDat.daCapQuyenMicro(_nn);
      moTa = ChCaiDat.moTaDaCapQuyen(_nn);
    } else if (tt.isPermanentlyDenied) {
      icon = Icons.mic_off_outlined;
      mau = Colors.red.shade600;
      tieuDe = ChCaiDat.quyenMicroDaBiChan(_nn);
      moTa = ChCaiDat.moTaQuyenBiChanVinhVien(_nn);
      nut = FilledButton.icon(
        onPressed: _dangXuLyMicro ? null : _moCaiDatUngDung,
        icon: const Icon(Icons.settings_outlined),
        label: Text(ChCaiDat.moCaiDatUngDung(_nn)),
      );
    } else if (tt.isRestricted) {
      icon = Icons.block;
      mau = Colors.red.shade600;
      tieuDe = ChCaiDat.quyenMicroBiChanBoiThietBi(_nn);
      moTa = ChCaiDat.moTaQuyenBiHanChe(_nn);
    } else {
      icon = Icons.mic_none;
      mau = const Color(0xFFF29900);
      tieuDe = ChCaiDat.chuaCapQuyenMicro(_nn);
      moTa = ChCaiDat.moTaChuaCapQuyen(_nn);
      nut = FilledButton.icon(
        onPressed: _dangXuLyMicro ? null : _capQuyenMicro,
        icon: const Icon(Icons.mic),
        label: Text(ChCaiDat.capQuyenMicro(_nn)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _tieuDeDong(ChCaiDat.quyenDungMicroCuaThietBi(_nn))),
            IconButton(
              onPressed: _dangXuLyMicro ? null : _kiemTraQuyenMicro,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: ChCaiDat.kiemTraLai(_nn),
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
