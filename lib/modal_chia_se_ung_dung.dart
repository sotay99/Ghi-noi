// (YÊU CẦU MỚI) Modal "Chia sẻ ứng dụng" — thay cho việc gọi thẳng
// `navigator.share()`/`share_plus` ngay khi bấm "Chia sẻ ứng dụng này đến
// với mọi người" (menu "Thêm lựa chọn"). Hiện modal xem trước nội dung sẽ
// chia sẻ, kèm 3 hành động: chia sẻ qua ứng dụng khác (mở màn hình chia sẻ
// hệ thống thật, `chiaSeUngDung()` — Web Share API trên web, `share_plus`
// trên bản gốc), sao chép nội dung chia sẻ đầy đủ, sao chép RIÊNG link, và
// mở link ở tab mới (`moLienKetNgoai`, dùng chung với các nơi khác trong
// app đã mở link ngoài).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chia_se_ung_dung.dart';
import 'chuoi_da_ngon_ngu.dart';
import 'mo_lien_ket_ngoai.dart';
import 'ngon_ngu.dart';
import 'thong_bao_giua.dart';

void hienModalChiaSeUngDung(
  BuildContext context, {
  required String tieuDe,
  required String vanBan,
  required String url,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tieuDe),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              '$vanBan $url',
              style: const TextStyle(fontSize: 14.5, height: 1.4),
            ),
            const SizedBox(height: 18),
            _NutHanhDongChiaSe(
              icon: Icons.ios_share,
              nhan: Ch.chiaSeQuaUngDungKhac(ngonNguHienTai.value),
              onBam: () async {
                await chiaSeUngDung(tieuDe: tieuDe, vanBan: vanBan, url: url);
              },
            ),
            _NutHanhDongChiaSe(
              icon: Icons.content_copy,
              nhan: Ch.saoChepNoiDungChiaSe(ngonNguHienTai.value),
              onBam: () async {
                await Clipboard.setData(ClipboardData(text: '$vanBan $url'));
                if (!ctx.mounted) return;
                hienThongBaoGiua(ctx, Ch.daCopyNoiDungChiaSe(ngonNguHienTai.value), ganTren: true);
              },
            ),
            _NutHanhDongChiaSe(
              icon: Icons.link,
              nhan: Ch.saoChepLink(ngonNguHienTai.value),
              onBam: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (!ctx.mounted) return;
                hienThongBaoGiua(ctx, Ch.daCopyLink(ngonNguHienTai.value), ganTren: true);
              },
            ),
            _NutHanhDongChiaSe(
              icon: Icons.open_in_new,
              nhan: Ch.moLinkTabMoi(ngonNguHienTai.value),
              onBam: () => moLienKetNgoai(url),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(Ch.dong(ngonNguHienTai.value)),
        ),
      ],
    ),
  );
}

class _NutHanhDongChiaSe extends StatelessWidget {
  const _NutHanhDongChiaSe({required this.icon, required this.nhan, required this.onBam});

  final IconData icon;
  final String nhan;
  final VoidCallback onBam;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onBam,
        icon: Icon(icon, size: 19),
        label: Text(nhan),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
      ),
    );
  }
}
