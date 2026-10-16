// Trang "Điều khoản sử dụng" — mở từ menu "Tài khoản và Cài đặt". Toàn màn
// hình, nội dung chọn/copy được (bọc trong `SelectionArea`), cùng khuôn
// trình bày với `trang_huong_dan.dart` qua các khối ở `trang_phap_ly_dung_chung.dart`.

import 'package:flutter/material.dart';

import 'trang_phap_ly_dung_chung.dart';

const _capNhat = '16/10/2026';

class TrangDieuKhoan extends StatelessWidget {
  const TrangDieuKhoan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mauChinhPhapLy,
        foregroundColor: Colors.white,
        title: const Text('Điều khoản sử dụng'),
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
                const HopNoiBatPhapLy(
                  child: DoanPhapLy(
                    'Dùng Flowrite tức là bạn đồng ý với các điều khoản dưới '
                    'đây. Flowrite là app ghi chú bằng giọng nói kèm trợ lý '
                    'AI — đọc kỹ ==phần 4== và ==phần 5== nếu bạn hay dùng '
                    'tính năng AI.',
                  ),
                ),
                const SizedBox(height: 28),

                const MucLonPhapLy(so: '1', tieuDe: 'Về Flowrite'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Flowrite là ứng dụng ghi chú, soạn thảo văn bản bằng '
                  'giọng nói kèm bàn phím, có thêm một số tính năng trợ lý '
                  'AI (kiểm tra chính tả, tóm tắt, viết lại, trò chuyện...). '
                  'App **đang tiếp tục được phát triển** — tính năng có thể '
                  'thay đổi, bổ sung theo thời gian.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '2', tieuDe: 'Tài khoản Google'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Đăng nhập tài khoản Google là **hoàn toàn tuỳ chọn** — '
                  'bạn dùng được đầy đủ Flowrite mà không cần đăng nhập. '
                  'Đăng nhập chỉ để đồng bộ ghi chú/cài đặt giữa nhiều '
                  'thiết bị. Bạn tự chịu trách nhiệm giữ an toàn tài khoản '
                  'Google của mình.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '3', tieuDe: 'Nội dung của bạn'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Mọi ghi chú, văn bản bạn tạo ra trong Flowrite **thuộc '
                  'về bạn**. Flowrite không đọc, không kiểm duyệt nội dung '
                  'đó — bạn tự chịu trách nhiệm về những gì mình viết và '
                  'lưu trong app.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '4', tieuDe: 'Tính năng AI'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Các tính năng gắn nhãn AI (kiểm tra chính tả, tóm tắt, '
                  'viết lại, trò chuyện, đọc ảnh/âm thanh...) do một dịch '
                  'vụ AI của Google xử lý. Kết quả AI trả về **chỉ là gợi '
                  'ý** — ==có thể sai, có thể thiếu chính xác==, bạn luôn là '
                  'người quyết định cuối cùng trước khi dùng kết quả đó.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '5', tieuDe: 'Không đảm bảo tuyệt đối'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Flowrite được cung cấp "nguyên trạng" (as-is). Chúng tôi '
                  'cố gắng giữ app hoạt động ổn định, nhưng không đảm bảo '
                  'app luôn chạy không lỗi, không gián đoạn, hay phù hợp '
                  'tuyệt đối với mọi mục đích sử dụng của bạn.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '6', tieuDe: 'Hành vi không được phép'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Không dùng Flowrite để tạo/lưu/phát tán nội dung vi '
                  'phạm pháp luật, hoặc để tấn công/can thiệp vào hệ thống '
                  'của Flowrite và các dịch vụ mà app sử dụng (Google, '
                  'Firebase...). Vi phạm có thể dẫn tới **khoá hoặc xoá tài '
                  'khoản** liên quan.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '7', tieuDe: 'Thay đổi điều khoản'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Điều khoản này có thể được cập nhật theo thời gian. Thay '
                  'đổi đáng kể sẽ được thông báo ngay trong app. Bạn tiếp '
                  'tục dùng Flowrite sau khi điều khoản cập nhật nghĩa là '
                  'bạn đồng ý với bản mới.',
                ),
                const SizedBox(height: 22),

                const MucLonPhapLy(so: '8', tieuDe: 'Giới hạn trách nhiệm'),
                const SizedBox(height: 12),
                const DoanPhapLy(
                  'Trong phạm vi pháp luật cho phép, Flowrite không chịu '
                  'trách nhiệm cho thiệt hại gián tiếp phát sinh từ việc sử '
                  'dụng hoặc không thể sử dụng app, bao gồm cả thiệt hại do '
                  'dựa vào kết quả của tính năng AI.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
