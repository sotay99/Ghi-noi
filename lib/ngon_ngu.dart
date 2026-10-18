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

Future<void> datNgonNgu(NgonNgu nn) async {
  ngonNguHienTai.value = nn;
  _daChonNgonNgu = true;
  final kho = await SharedPreferences.getInstance();
  await kho.setString(_khoaNgonNgu, nn == NgonNgu.en ? 'en' : 'vi');
  await kho.setBool(_khoaDaChonNgonNgu, true);
}
