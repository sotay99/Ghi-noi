// Khung đa ngôn ngữ của app — hiện có Tiếng Việt và English, thêm ngôn ngữ
// mới (ví dụ tiếng Trung, tiếng Thái) sau này chỉ cần: (1) thêm 1 case vào
// enum [NgonNgu] dưới đây, (2) thêm 1 nhánh giá trị cho MỖI chuỗi trong
// `lib/chuoi_da_ngon_ngu.dart`. Không đụng gì ở từng màn hình đang gọi `Ch.*`.
//
// KHÔNG dùng `flutter_localizations`/ARB (cần Flutter CLI để sinh code, môi
// trường build hiện tại không kiểm chứng được bước đó) — tự viết thuần Dart,
// đơn giản, kiểm tra được bằng mắt.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NgonNgu { vi, en }

const _khoaNgonNgu = 'ghi_noi_ngon_ngu';
const _khoaDaChonNgonNgu = 'ghi_noi_da_chon_ngon_ngu';

/// Ngôn ngữ hiện tại của app — một `ValueNotifier` toàn cục, mọi widget cần
/// tự vẽ lại khi đổi ngôn ngữ thì bọc trong `ValueListenableBuilder` hoặc gọi
/// `setState` trong callback `addListener`. Mặc định Tiếng Việt trước khi đọc
/// xong `SharedPreferences` lúc khởi động.
final ValueNotifier<NgonNgu> ngonNguHienTai = ValueNotifier<NgonNgu>(NgonNgu.vi);

/// `true` nếu người dùng đã từng chọn ngôn ngữ (modal bắt chọn lúc mở app lần
/// đầu không cần hiện lại nữa, trừ khi tự mở lại từ màn Cài đặt).
bool _daChonNgonNgu = false;
bool get daChonNgonNgu => _daChonNgonNgu;

/// Gọi lúc khởi động, TRƯỚC khi vẽ UI đầu tiên (xem `main.dart`/
/// `main_web_full.dart`).
Future<void> taiNgonNgu() async {
  final kho = await SharedPreferences.getInstance();
  final ma = kho.getString(_khoaNgonNgu);
  ngonNguHienTai.value = ma == 'en' ? NgonNgu.en : NgonNgu.vi;
  _daChonNgonNgu = kho.getBool(_khoaDaChonNgonNgu) ?? false;
}

/// Từ khoá tìm kiếm Google cho mục "Luyện gõ phím bằng 10 ngón tay" —
/// mỗi ngôn ngữ một từ khoá tự nhiên (không cần dịch sát nghĩa). Thêm ngôn
/// ngữ mới vào enum ở trên mà quên thêm case ở đây thì rơi vào `default`
/// (từ khoá tiếng Anh) thay vì vỡ ứng dụng.
String tuKhoaLuyenGoPhim(NgonNgu nn) {
  switch (nn) {
    case NgonNgu.vi:
      return 'luyện gõ phím bằng 10 ngón tay';
    case NgonNgu.en:
      return 'touch typing practice 10 fingers';
  }
}

/// Đường link tìm kiếm Google đã mã hoá đúng theo ngôn ngữ hiện tại — dùng
/// `Uri.encodeQueryComponent` nên không cần tự escape tay, đúng với mọi
/// ngôn ngữ (kể cả tiếng Trung/Thái sau này).
String linkTimKiemLuyenGoPhim(NgonNgu nn) =>
    'https://www.google.com/search?q=${Uri.encodeQueryComponent(tuKhoaLuyenGoPhim(nn))}';

Future<void> datNgonNgu(NgonNgu nn) async {
  ngonNguHienTai.value = nn;
  _daChonNgonNgu = true;
  final kho = await SharedPreferences.getInstance();
  await kho.setString(_khoaNgonNgu, nn == NgonNgu.en ? 'en' : 'vi');
  await kho.setBool(_khoaDaChonNgonNgu, true);
}

/// Trạng thái của thẻ ghi âm vừa chốt (không còn ghi âm thật nữa, đang gửi
/// AI hoặc đã có kết quả) — tách RIÊNG khỏi chuỗi hiển thị để so khớp nội
/// bộ (`startsWith`/`==` trên chuỗi tiếng Việt cũ) không bị phá khi người
/// dùng đổi ngôn ngữ. Chuỗi hiển thị dịch qua `Ch.trangThaiGheDe` ở
/// `chuoi_da_ngon_ngu.dart`. Đặt ở đây (không phải `trang_soan_thao.dart`)
/// để tránh import vòng với `chuoi_da_ngon_ngu.dart`.
enum LoaiTrangThaiGheDe { dangChuyen, daChuyenXong, loiKhiChuyen, daGhiXongChuaChuyen }

class TrangThaiGheDe {
  const TrangThaiGheDe(this.loai, this.soThe);
  final LoaiTrangThaiGheDe loai;
  final int soThe;
}
