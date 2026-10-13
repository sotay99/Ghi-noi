// Đăng nhập/đăng xuất Google cho nút "Đăng nhập tài khoản" trong menu "Tài
// khoản và Cài đặt" (`thanh_cong_cu.dart`) — dùng CHUNG một lớp dịch vụ cho
// cả Web và Android, chỉ khác NỘI BỘ cách lấy được "credential" đưa cho
// Firebase:
// - Web: `FirebaseAuth.signInWithPopup` tự mở popup OAuth của Google, không
//   cần gói `google_sign_in` (gói đó trên web từ bản mới đòi phải tự vẽ nút
//   "Sign in with Google" riêng theo chuẩn Google Identity Services, phức
//   tạp hơn hẳn — không cần tới nếu chỉ cần MỘT nút bấm là đăng nhập ngay).
// - Android: `google_sign_in` mở màn hình chọn tài khoản Google NGUYÊN BẢN
//   của máy, lấy access/id token rồi đổi sang credential cho Firebase —
//   `signInWithPopup` không chạy được trên Android.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class DichVuDangNhapGoogle {
  DichVuDangNhapGoogle._();
  static final DichVuDangNhapGoogle instance = DichVuDangNhapGoogle._();

  final _googleSignIn = GoogleSignIn(scopes: const ['email']);

  User? get nguoiDungHienTai => FirebaseAuth.instance.currentUser;

  /// Bắn ra mỗi lần trạng thái đăng nhập đổi (đăng nhập xong/đăng xuất) —
  /// nơi gọi (`trang_soan_thao.dart`) lắng nghe để vẽ lại menu.
  Stream<User?> get doiTrangThai => FirebaseAuth.instance.authStateChanges();

  /// Trả `null` nếu người dùng tự bấm Huỷ ở màn hình chọn tài khoản —
  /// KHÔNG phải lỗi, nơi gọi không cần báo gì thêm trong trường hợp đó.
  /// Lỗi thật (mất mạng, cấu hình sai...) tự ném `Exception`, nơi gọi bọc
  /// `try/catch` để hiện thông báo.
  Future<void> dangNhap() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      return;
    }
    final taiKhoan = await _googleSignIn.signIn();
    if (taiKhoan == null) return;
    final xacThuc = await taiKhoan.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: xacThuc.accessToken,
      idToken: xacThuc.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> dangXuat() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) await _googleSignIn.signOut();
  }
}
