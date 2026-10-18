// (YÊU CẦU MỚI) Trang "Cài đặt Ứng dụng vào Thiết bị" — mở từ menu "+ Thêm
// lựa chọn", ngay phía trên "Chia sẻ ứng dụng này đến với mọi người". Toàn
// màn hình, gồm 3 khối xếp dọc: cài qua Chrome (PWA, chạy được NGAY, không
// cần code gì thêm — `flutter build web` đã tự sinh đủ `manifest.json`),
// cài cho iPhone/iPad (chưa có — hiện lời xin lỗi), cài cho Android (APK
// tải trực tiếp từ GitHub Releases, dùng lại đúng link banner "Tải app
// APK" đang có).
import 'package:flutter/material.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'mo_lien_ket_ngoai.dart';
import 'ngon_ngu.dart';

void moModalCaiDatUngDung(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _TrangCaiDatUngDung()),
  );
}

/// Thông báo nhỏ, nổi GIỮA màn hình, có nút X ở góc trên-phải để đóng —
/// khác `hienThongBaoGiua` (tự ẩn sau 2 giây, không có nút đóng): hai lời
/// xin lỗi/hướng dẫn ở dưới cần người dùng ĐỌC XONG rồi tự đóng, không nên
/// tự biến mất giữa lúc đang đọc.
void _hienThongBaoNhoCoNutDong(BuildContext context, String noiDung) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 14, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 6, bottom: 4),
              child: Text(noiDung, style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TrangCaiDatUngDung extends StatelessWidget {
  const _TrangCaiDatUngDung();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: Text(Ch.caiDatUngDungVaoThietBi(ngonNguHienTai.value)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _khoiCaiDat(
                icon: Icons.language,
                mauIcon: const Color(0xFF1A73E8),
                tieuDe: Ch.caiDatBangChrome(ngonNguHienTai.value),
                moTa: Ch.moTaCaiDatChrome(ngonNguHienTai.value),
              ),
              const SizedBox(height: 28),
              _khoiCaiDat(
                icon: Icons.apple,
                mauIcon: Colors.black,
                tieuDe: Ch.caiDatChoIphoneIpad(ngonNguHienTai.value),
                moTa: Ch.moTaCaiDatIphone(ngonNguHienTai.value),
                tenNutCaiDat: Ch.caiDatChoIphoneIpad(ngonNguHienTai.value),
                khiBamCaiDat: () => _hienThongBaoNhoCoNutDong(
                  context,
                  Ch.thongBaoIphoneDangXayDung(ngonNguHienTai.value),
                ),
              ),
              const SizedBox(height: 28),
              _khoiCaiDat(
                icon: Icons.android,
                mauIcon: const Color(0xFF3DDC84),
                tieuDe: Ch.caiDatChoAndroid(ngonNguHienTai.value),
                moTa: Ch.moTaCaiDatAndroid(ngonNguHienTai.value),
                tenNutCaiDat: Ch.caiDatChoAndroidNut(ngonNguHienTai.value),
                khiBamCaiDat: () => _hienThongBaoNhoCoNutDong(
                  context,
                  Ch.thongBaoAndroidChuaLenChPlay(ngonNguHienTai.value),
                ),
                khiBamTaiApk: () =>
                    moLienKetNgoai('https://github.com/sotay99/ghi-noi/releases/latest'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _khoiCaiDat({
    required IconData icon,
    required Color mauIcon,
    required String tieuDe,
    required String moTa,
    String? tenNutCaiDat,
    VoidCallback? khiBamCaiDat,
    VoidCallback? khiBamTaiApk,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: mauIcon, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tieuDe,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(moTa, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          if (tenNutCaiDat != null && khiBamCaiDat != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: khiBamCaiDat, child: Text(tenNutCaiDat)),
            ),
          ],
          if (khiBamTaiApk != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: khiBamTaiApk,
                icon: const Icon(Icons.download),
                label: Text(Ch.taiFileApkVeMayVaCaiDat(ngonNguHienTai.value)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
