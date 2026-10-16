// Trang "Bảo mật và quyền riêng tư" — mở từ menu "Tài khoản và Cài đặt".
// Toàn màn hình, nội dung chọn/copy được (bọc trong `SelectionArea`), cùng
// khuôn trình bày với `trang_huong_dan.dart` qua các khối ở
// `trang_phap_ly_dung_chung.dart`.

import 'package:flutter/material.dart';

import 'trang_phap_ly_dung_chung.dart';

const _capNhat = '16/10/2026';

class TrangBaoMat extends StatelessWidget {
  const TrangBaoMat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mauChinhPhapLy,
        foregroundColor: Colors.white,
        title: const Text('Bảo mật và quyền riêng tư'),
      ),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cập nhật lần cuối: $_capNhat',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6368)),
                ),
                const SizedBox(height: 16),
                // (YÊU CẦU) Hộp tóm tắt nổi bật đầu trang — một câu, nói
                // thẳng dữ liệu của người dùng đi đâu, cho ai lười đọc hết
                // cũng nắm được ý chính ngay.
                const HopNoiBatPhapLy(
                  child: DoanPhapLy(
                    '**Tóm tắt nhanh:** Flowrite ==không có máy chủ riêng== '
                    'thu thập dữ liệu của bạn. Dữ liệu chỉ có thể nằm ở MỘT '
                    'trong ba nơi: **thiết bị của bạn**, **tài khoản Google** '
                    '(nếu bạn chọn đăng nhập), hoặc **dịch vụ AI của Google** '
                    '(chỉ khi bạn chủ động bấm dùng một tính năng AI).',
                  ),
                ),
                const SizedBox(height: 28),

                const MucLonPhapLy(so: '1', tieuDe: 'Chưa đăng nhập'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Toàn bộ ghi chú, thư mục và cài đặt của bạn chỉ lưu '
                  '**ngay trên thiết bị** (hoặc trình duyệt) đang dùng. '
                  'Không nơi nào khác — kể cả người viết app — đọc được dữ '
                  'liệu này.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '2', tieuDe: 'Khi đăng nhập Google'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Đăng nhập là **tuỳ chọn**, chỉ để đồng bộ dữ liệu giữa '
                  'nhiều thiết bị cùng tài khoản, lưu trên hạ tầng Firebase '
                  'của Google. Khi đó, những thứ sau được lưu THEO TÀI '
                  'KHOẢN của bạn:',
                ),
                const SizedBox(height: 10),
                const DongGachDauPhapLy('Ghi chú và thư mục trong "Bộ nhớ trên đám mây".'),
                const DongGachDauPhapLy(
                    'Một số cài đặt hiển thị (ghim/thu gọn thanh công cụ, Micro, '
                    'tự động sửa, Bộ nhớ tạm, Khi khởi động App...).'),
                const DongGachDauPhapLy('Hai từ điển cá nhân (sửa lỗi chính tả, nhập liệu nhanh).'),
                const SizedBox(height: 10),
                const DoanPhapLy(
                  'Đăng xuất sẽ tự xoá bản sao lưu tạm (cache) của tài khoản '
                  'đó khỏi thiết bị đang dùng.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '3', tieuDe: 'Tính năng Micro'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Giọng nói được chuyển thành chữ bằng bộ nhận diện giọng '
                  'nói **của chính thiết bị/trình duyệt** bạn đang dùng '
                  '(Android, Chrome...) — không đi qua máy chủ riêng nào '
                  'của Flowrite.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '4', tieuDe: 'Tính năng AI'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Khi bạn chủ động bấm dùng một tính năng AI (kiểm tra '
                  'chính tả, tóm tắt, viết lại, trò chuyện, đọc ảnh/âm '
                  'thanh...), đúng phần nội dung liên quan đến tính năng đó '
                  '(không phải toàn bộ ghi chú) được gửi tới **dịch vụ AI '
                  'của Google** để xử lý rồi trả kết quả về. ==Không bấm '
                  'dùng tính năng AI thì không có gì được gửi đi==.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '5', tieuDe: 'Flowrite không làm gì với dữ liệu của bạn'),
                const SizedBox(height: 12),
                const DongGachDauPhapLy('**Không bán**, không cho thuê dữ liệu của bạn.'),
                const DongGachDauPhapLy('Không chia sẻ dữ liệu cho bên thứ ba vì mục đích quảng cáo.'),
                const DongGachDauPhapLy('Không tự ý đọc nội dung ghi chú của bạn.'),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '6', tieuDe: 'Trẻ em'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Flowrite không nhắm tới và không chủ đích thu thập dữ '
                  'liệu của trẻ em dưới 13 tuổi.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '7', tieuDe: 'Quyền của bạn'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Bạn có thể xoá ghi chú, đăng xuất, hoặc gỡ app bất cứ '
                  'lúc nào. Muốn xoá hẳn dữ liệu đã đồng bộ trên tài khoản '
                  'Google, liên hệ theo thông tin ở phần 9 bên dưới.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '8', tieuDe: 'Thay đổi chính sách'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Chính sách này có thể được cập nhật theo thời gian. Thay '
                  'đổi đáng kể sẽ được thông báo ngay trong app.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '9', tieuDe: 'Liên hệ'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Có thắc mắc về quyền riêng tư, hoặc muốn yêu cầu xoá dữ '
                  'liệu, liên hệ qua một trong các cách sau:',
                ),
                const SizedBox(height: 12),
                HopNoiBatPhapLy(
                  mauNen: const Color(0xFFF1F8F3),
                  mauVien: const Color(0xFFB7E1C1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      DoanPhapLy('**Email:** lookatmevanthanhpham@gmail.com'),
                      SizedBox(height: 6),
                      DoanPhapLy('**Email khác:** 219thanhdeptrai@gmail.com'),
                      SizedBox(height: 6),
                      DoanPhapLy('**Điện thoại:** +84 91 711 4941'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
