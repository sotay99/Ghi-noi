// (YÊU CẦU MỚI) Trang "Cài đặt Ứng dụng vào Thiết bị" — mở từ menu "+ Thêm
// lựa chọn", ngay phía trên "Chia sẻ ứng dụng này đến với mọi người". Toàn
// màn hình, gồm 3 khối xếp dọc: cài qua Chrome (PWA, chạy được NGAY, không
// cần code gì thêm — `flutter build web` đã tự sinh đủ `manifest.json`),
// cài cho iPhone/iPad (chưa có — hiện lời xin lỗi), cài cho Android (APK
// tải trực tiếp từ GitHub Releases, dùng lại đúng link banner "Tải app
// APK" đang có).
import 'package:flutter/material.dart';

import 'mo_lien_ket_ngoai.dart';

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
        title: const Text('Cài đặt Ứng dụng vào Thiết bị'),
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
                tieuDe: 'Cài đặt bằng trình duyệt Chrome (PC, điện thoại, máy tính bảng)',
                moTa:
                    'Mở trang web này bằng trình duyệt Chrome (hoặc Edge, Brave — cùng '
                    'nền Chromium). Nhìn lên thanh địa chỉ phía trên, bấm vào nút "Cài '
                    'đặt" (hình máy tính có mũi tên, hoặc hình dấu "+"). App sẽ hiện ra '
                    'ngay ở màn hình chính thiết bị của bạn, giống một app thật — không '
                    'cần CH Play hay App Store, mở lên là chạy, không còn thanh địa chỉ '
                    'của trình duyệt nữa.',
              ),
              const SizedBox(height: 28),
              _khoiCaiDat(
                icon: Icons.apple,
                mauIcon: Colors.black,
                tieuDe: 'Cài đặt cho iPhone, iPad',
                moTa:
                    'Bản app riêng cho iPhone/iPad sẽ không bị kẹt bàn phím ảo như bản '
                    'web, và "Micro vừa nói vừa ra chữ" hoạt động đầy đủ (bản web trên '
                    'iPhone hiện phải tắt tính năng này).',
                tenNutCaiDat: 'Cài đặt cho iPhone, iPad',
                khiBamCaiDat: () => _hienThongBaoNhoCoNutDong(
                  context,
                  'App cho iPhone/iPad đang trong quá trình xây dựng — hiện kinh phí '
                  'còn eo hẹp nên chưa thể triển khai ngay. Khi có bản chính thức, '
                  'Flowrite sẽ thông báo tới bạn. Cảm ơn bạn đã quan tâm!',
                ),
              ),
              const SizedBox(height: 28),
              _khoiCaiDat(
                icon: Icons.android,
                mauIcon: const Color(0xFF3DDC84),
                tieuDe: 'Cài đặt cho điện thoại, máy tính bảng Android',
                moTa:
                    'Bản APK không bị kẹt bàn phím ảo như bản web, và có thêm Widget '
                    '"Ghi nhanh" đặt ngay ở màn hình chính (màn hình chủ) của điện '
                    'thoại, máy tính bảng — ghi nhanh một ý mà không cần mở hẳn app.',
                tenNutCaiDat: 'Cài đặt cho Android',
                khiBamCaiDat: () => _hienThongBaoNhoCoNutDong(
                  context,
                  'App chưa đưa lên CH Play — hiện chỉ tải file APK trực tiếp. Sau khi '
                  'bấm nút dưới đây, máy sẽ tải file APK về; mở file đó lên để cài. '
                  'Máy sẽ hỏi quyền "Cài đặt từ nguồn không xác định" — chọn Cho phép, '
                  'rồi tiếp tục theo các bước của trình cài đặt gói Android là xong.',
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
                label: const Text('Tải file APK về máy và cài đặt'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
