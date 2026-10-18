// Modal "Cài đặt nút Kiểm tra toàn văn" — mở từ mục cùng tên trong menu
// "Làm việc với AI". Gồm: dòng giải thích, thanh trượt chọn độ dài đoạn đề
// xuất, và ô nhập câu lệnh tuỳ chỉnh riêng của người dùng. Tách riêng khỏi
// trang_soan_thao.dart vì đây là một khối giao diện khá lớn, tự đứng độc lập.

import 'package:flutter/material.dart';

import 'cai_dat.dart';
import 'chuoi_da_ngon_ngu.dart';
import 'ngon_ngu.dart';

/// Mô phỏng đúng style của nút "Kiểm tra toàn văn" thật trên thanh công cụ:
/// icon `task_alt` + chữ, cùng màu xanh lá `Colors.green.shade600`.
class _NutKiemTraToanVanMoPhong extends StatelessWidget {
  const _NutKiemTraToanVanMoPhong();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDADCE0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 15, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Text(
            Ch.kiemToanVanMoPhong(ngonNguHienTai.value),
            style: TextStyle(fontSize: 11, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }
}

void _hienGiaiThich(BuildContext context, String tieuDe, String noiDung) {
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
            tooltip: Ch.dong(ngonNguHienTai.value),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(noiDung, style: const TextStyle(height: 1.5)),
      ),
    ),
  );
}

String _giaiThichDoDaiDeXuat(NgonNgu nn) => Ch.giaiThichDoDaiDeXuat(nn);

String _giaiThichCauLenhTuyChinh(NgonNgu nn) => Ch.giaiThichCauLenhTuyChinh(nn);

/// Mở modal "Cài đặt nút Kiểm tra toàn văn".
void moModalCaiDatKiemTraToanVan(BuildContext context, CaiDat caiDat) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ThanCaiDatKiemTraToanVan(caiDat: caiDat),
  );
}

class _ThanCaiDatKiemTraToanVan extends StatefulWidget {
  const _ThanCaiDatKiemTraToanVan({required this.caiDat});
  final CaiDat caiDat;

  @override
  State<_ThanCaiDatKiemTraToanVan> createState() => _ThanCaiDatKiemTraToanVanState();
}

class _ThanCaiDatKiemTraToanVanState extends State<_ThanCaiDatKiemTraToanVan> {
  late int _mucDo;
  late String _cauLenhTuyChinh;

  @override
  void initState() {
    super.initState();
    _mucDo = widget.caiDat.mucDoDaiDeXuat;
    _cauLenhTuyChinh = widget.caiDat.cauLenhTuyChinhKiemTraToanVan;
  }

  Future<void> _moSuaCauLenhTuyChinh() async {
    final oNhap = TextEditingController(text: _cauLenhTuyChinh);
    final ketQua = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Ch.cauLenhRiengCuaBan(ngonNguHienTai.value)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: oNhap,
              maxLines: 5,
              minLines: 3,
              maxLength: CaiDat.gioiHanCauLenhTuyChinh,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: Ch.viDuGiuVanPhongThanMat(ngonNguHienTai.value),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Ch.cauLenhGuiKemChiDanGoc(ngonNguHienTai.value),
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(Ch.huy(ngonNguHienTai.value)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(oNhap.text.trim()),
            child: Text(Ch.luu(ngonNguHienTai.value)),
          ),
        ],
      ),
    );
    if (ketQua == null || !mounted) return;
    setState(() => _cauLenhTuyChinh = ketQua);
    await widget.caiDat.datCauLenhTuyChinhKiemTraToanVan(ketQua);
  }

  @override
  Widget build(BuildContext context) {
    final banPhim = MediaQuery.of(context).viewInsets.bottom;
    final soTu = _cauLenhTuyChinh.trim().isEmpty
        ? 0
        : _cauLenhTuyChinh.trim().split(RegExp(r'\s+')).length;

    return Padding(
      padding: EdgeInsets.only(bottom: banPhim),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Ch.caiDatNutKiemTraToanVanTieuDe(ngonNguHienTai.value),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: const TextStyle(height: 1.5, color: Colors.black87),
                children: [
                  TextSpan(
                      text: Ch.deSuDungChucNangKiemTraToanVan(ngonNguHienTai.value)),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _NutKiemTraToanVanMoPhong(),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              Ch.dayLaBuocQuanTrongSauMoiLanSoanXong(ngonNguHienTai.value),
              style: const TextStyle(height: 1.5, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 24),
            Text(
              Ch.caiDatTinhNangNay(ngonNguHienTai.value),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Độ dài đoạn đề xuất ----
            Row(
              children: [
                Expanded(
                  child: Text(
                    Ch.doDaiTungDoanVanDuocDeXuat(ngonNguHienTai.value),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            Text(
              CaiDat.tenMucDoDaiDeXuat[_mucDo],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _mucDo.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              label: CaiDat.tenMucDoDaiDeXuat[_mucDo],
              onChanged: (gia) {
                setState(() => _mucDo = gia.round());
              },
              onChangeEnd: (gia) {
                widget.caiDat.datMucDoDaiDeXuat(gia.round());
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _hienGiaiThich(
                  context,
                  Ch.doDaiTungDoanVanDuocDeXuat(ngonNguHienTai.value),
                  _giaiThichDoDaiDeXuat(ngonNguHienTai.value),
                ),
                child: Text(Ch.timHieuThem(ngonNguHienTai.value)),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Câu lệnh tuỳ chỉnh ----
            InkWell(
              onTap: _moSuaCauLenhTuyChinh,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Ch.tuyChinhCauLenhChoAiLamViec(ngonNguHienTai.value),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF9AA0A6)),
                  ],
                ),
              ),
            ),
            Text(
              _cauLenhTuyChinh.trim().isEmpty
                  ? Ch.cauLenhRiengDangTrong(ngonNguHienTai.value)
                  : Ch.cauLenhDangChuaSoTu(ngonNguHienTai.value, soTu),
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _hienGiaiThich(
                  context,
                  Ch.tuyChinhCauLenhChoAiLamViec(ngonNguHienTai.value),
                  _giaiThichCauLenhTuyChinh(ngonNguHienTai.value),
                ),
                child: Text(Ch.timHieuThem(ngonNguHienTai.value)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
