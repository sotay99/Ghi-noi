// (YÊU CẦU MỚI) Mục "Donate ủng hộ-cảm ơn tác giả" — mở từ menu "+ Thêm lựa
// chọn" (trước đây chưa gắn logic). Modal NHỎ giữa màn hình (khác hẳn các
// trang toàn màn hình như "Cài đặt Ứng dụng"/"Góp ý" — nội dung ở đây ngắn,
// chỉ một đoạn văn + 3 nút), có nút X đóng. Bấm một trong 3 nút mở TIẾP một
// modal nhỏ khác, hiện mã QR (ảnh tải từ mạng, không cần thêm gói Flutter
// nào — tránh đúng kiểu xung đột phiên bản đã gặp với package_info_plus)
// cộng thông tin nhận tiền, có nút chép từng dòng.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                const Expanded(
                  child: Text(
                    'Donate ủng hộ - cảm ơn tác giả',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Flowrite vẫn đang trong quá trình xây dựng và hoàn thiện. '
              'Donate của bạn giúp tác giả có thêm kinh phí trả cho bộ nhớ '
              'đám mây, các API xử lý văn bản/hình ảnh/âm thanh, duy trì '
              'app, đưa app lên các chợ ứng dụng, và phát triển thêm những '
              'app mới trong tương lai.\n\n'
              'Donate là nguồn động lực để tác giả tiếp tục, giúp Flowrite '
              'luôn luôn miễn phí cho mọi người. Nhiều hay ít đều quý giá — '
              'cảm ơn bạn rất nhiều!',
              style: TextStyle(fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 18),
            _nutDonate(
              context,
              icon: Icons.payment,
              nhan: 'Donate qua Paypal',
              khiBam: () => _moModalQr(
                context,
                tieuDe: 'Donate qua Paypal',
                urlAnhQr:
                    'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data='
                    '${Uri.encodeComponent('https://www.paypal.com/ncp/payment/JJDRYY4HXDHB6')}',
                moTaQr: 'Quét mã hoặc bấm link dưới để mở trang nhận donate trên Paypal.',
                dongThongTin: const [
                  _DongThongTin(nhan: 'Link Paypal', gia: 'paypal.com/ncp/payment/JJDRYY4HXDHB6'),
                  _DongThongTin(nhan: 'Email', gia: 'lookatmevanthanhpham@gmail.com'),
                  _DongThongTin(nhan: 'Tên', gia: 'PHAM VAN THANH'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _nutDonate(
              context,
              icon: Icons.phone_android,
              nhan: 'Donate qua Momo',
              khiBam: () => _moModalQr(
                context,
                tieuDe: 'Donate qua Momo',
                urlAnhQr:
                    'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data='
                    '${Uri.encodeComponent('https://nhantien.momo.vn/0376060540')}',
                moTaQr: 'Mở app Momo rồi quét mã này, hoặc chuyển trực tiếp tới số điện thoại dưới đây.',
                dongThongTin: const [
                  _DongThongTin(nhan: 'Số điện thoại', gia: '0376060540'),
                  _DongThongTin(nhan: 'Tên', gia: 'PHAM VAN THANH'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _nutDonate(
              context,
              icon: Icons.account_balance,
              nhan: 'Donate qua Ngân hàng TPBank (Việt Nam)',
              khiBam: () => _moModalQr(
                context,
                tieuDe: 'Donate qua Ngân hàng TPBank',
                urlAnhQr:
                    'https://img.vietqr.io/image/970423-10001034843-compact2.png'
                    '?accountName=${Uri.encodeComponent('PHAM VAN THANH')}',
                moTaQr: 'Mở app ngân hàng bất kỳ (hỗ trợ VietQR) rồi quét mã này.',
                dongThongTin: const [
                  _DongThongTin(nhan: 'Ngân hàng', gia: 'TPBank'),
                  _DongThongTin(nhan: 'Số tài khoản', gia: '10001034843'),
                  _DongThongTin(nhan: 'Tên', gia: 'PHAM VAN THANH'),
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
  const _DongThongTin({required this.nhan, required this.gia});
  final String nhan;
  final String gia;
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
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Text(
                        'Không tải được mã QR — kiểm tra lại mạng.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red, fontSize: 12),
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
              child: const Text(
                'Khuyến khích ghi thêm nội dung chuyển khoản: "Donate app Flowrite" — '
                'để tác giả biết được nguồn donate.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF8A5300)),
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
          child: RichText(
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
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 17),
          tooltip: 'Chép',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: d.gia));
            hienThongBaoGiua(context, 'Đã chép "${d.nhan}"');
          },
        ),
      ],
    ),
  );
}
