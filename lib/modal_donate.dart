// (YÊU CẦU MỚI) Mục "Donate ủng hộ-cảm ơn tác giả" — mở từ menu "+ Thêm lựa
// chọn" (trước đây chưa gắn logic). Modal NHỎ giữa màn hình (khác hẳn các
// trang toàn màn hình như "Cài đặt Ứng dụng"/"Góp ý" — nội dung ở đây ngắn,
// chỉ một đoạn văn + 3 nút), có nút X đóng. Bấm một trong 3 nút mở TIẾP một
// modal nhỏ khác, hiện mã QR (ảnh tải từ mạng, không cần thêm gói Flutter
// nào — tránh đúng kiểu xung đột phiên bản đã gặp với package_info_plus)
// cộng thông tin nhận tiền, có nút chép từng dòng.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'mo_lien_ket_ngoai.dart';
import 'ngon_ngu.dart';
import 'thong_bao_giua.dart';

void moModalDonate(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 14, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Ch.donateUngHoCamOnTacGia(ngonNguHienTai.value),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              Ch.noiDungDonate(ngonNguHienTai.value),
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 18),
            _nutDonate(
              context,
              icon: Icons.payment,
              nhan: Ch.donateQuaPaypal(ngonNguHienTai.value),
              khiBam: () => _moModalQr(
                context,
                tieuDe: Ch.donateQuaPaypal(ngonNguHienTai.value),
                urlAnhQr:
                    'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data='
                    '${Uri.encodeComponent('https://www.paypal.com/ncp/payment/JJDRYY4HXDHB6')}',
                moTaQr: Ch.quetMaHoacBamLinkPaypal(ngonNguHienTai.value),
                dongThongTin: [
                  // (YÊU CẦU MỚI) Bấm TRỰC TIẾP vào link cũng mở được (ngoài
                  // nút chép) — gạch chân + chữ xanh dương để người dùng
                  // biết bấm được, xem `urlMo`/`_dongTinChepDuoc`.
                  _DongThongTin(
                    nhan: Ch.linkPaypal(ngonNguHienTai.value),
                    gia: 'paypal.com/ncp/payment/JJDRYY4HXDHB6',
                    urlMo: 'https://www.paypal.com/ncp/payment/JJDRYY4HXDHB6',
                  ),
                  _DongThongTin(nhan: Ch.email(ngonNguHienTai.value), gia: 'lookatmevanthanhpham@gmail.com'),
                  _DongThongTin(nhan: Ch.ten(ngonNguHienTai.value), gia: 'PHAM VAN THANH'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _nutDonate(
              context,
              icon: Icons.phone_android,
              nhan: Ch.donateQuaMomo(ngonNguHienTai.value),
              khiBam: () => _moModalQr(
                context,
                tieuDe: Ch.donateQuaMomo(ngonNguHienTai.value),
                urlAnhQr:
                    'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data='
                    '${Uri.encodeComponent('https://nhantien.momo.vn/0376060540')}',
                moTaQr: Ch.moAppMomoQuetMa(ngonNguHienTai.value),
                dongThongTin: [
                  _DongThongTin(nhan: Ch.soDienThoai(ngonNguHienTai.value), gia: '0376060540'),
                  _DongThongTin(nhan: Ch.ten(ngonNguHienTai.value), gia: 'PHAM VAN THANH'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _nutDonate(
              context,
              icon: Icons.account_balance,
              nhan: Ch.donateQuaNganHangTPBank(ngonNguHienTai.value),
              khiBam: () => _moModalQr(
                context,
                tieuDe: Ch.donateQuaNganHangTPBankNgan(ngonNguHienTai.value),
                urlAnhQr:
                    'https://img.vietqr.io/image/970423-10001034843-compact2.png'
                    '?accountName=${Uri.encodeComponent('PHAM VAN THANH')}',
                moTaQr: Ch.moAppNganHangVietQr(ngonNguHienTai.value),
                dongThongTin: [
                  _DongThongTin(nhan: Ch.nganHang(ngonNguHienTai.value), gia: 'TPBank'),
                  _DongThongTin(nhan: Ch.soTaiKhoan(ngonNguHienTai.value), gia: '10001034843'),
                  _DongThongTin(nhan: Ch.ten(ngonNguHienTai.value), gia: 'PHAM VAN THANH'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _nutDonate(
  BuildContext context, {
  required IconData icon,
  required String nhan,
  required VoidCallback khiBam,
}) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: khiBam,
      icon: Icon(icon, size: 18),
      label: Align(alignment: Alignment.centerLeft, child: Text(nhan)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
    ),
  );
}

class _DongThongTin {
  const _DongThongTin({required this.nhan, required this.gia, this.urlMo});
  final String nhan;
  final String gia;

  /// Khác `null` thì [gia] hiện thành link (xanh dương, gạch chân), bấm
  /// trực tiếp vào mở [urlMo] qua `moLienKetNgoai` — tách riêng khỏi [gia]
  /// vì [gia] có thể là bản RÚT GỌN để hiển thị (không có "https://").
  final String? urlMo;
}

void _moModalQr(
  BuildContext context, {
  required String tieuDe,
  required String urlAnhQr,
  required String moTaQr,
  required List<_DongThongTin> dongThongTin,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 14, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tieuDe,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urlAnhQr,
                  width: 220,
                  height: 220,
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Text(
                        Ch.khongTaiDuocMaQr(ngonNguHienTai.value),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(moTaQr, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6368))),
            const SizedBox(height: 14),
            ...dongThongTin.map((d) => _dongTinChepDuoc(context, d)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                Ch.khuyenKhichGhiNoiDungChuyenKhoan(ngonNguHienTai.value),
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A5300)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _dongTinChepDuoc(BuildContext context, _DongThongTin d) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          child: d.urlMo == null
              ? RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13.5, color: Colors.black),
                    children: [
                      TextSpan(
                        text: '${d.nhan}: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: d.gia),
                    ],
                  ),
                )
              : InkWell(
                  onTap: () => moLienKetNgoai(d.urlMo!),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13.5, color: Colors.black),
                      children: [
                        TextSpan(
                          text: '${d.nhan}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: d.gia,
                          style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 17),
          tooltip: Ch.chep(ngonNguHienTai.value),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: d.gia));
            hienThongBaoGiua(context, Ch.daChepTen(ngonNguHienTai.value, d.nhan));
          },
        ),
      ],
    ),
  );
}
