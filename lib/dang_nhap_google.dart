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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class DichVuDangNhapGoogle {
  DichVuDangNhapGoogle._();
  static final DichVuDangNhapGoogle instance = DichVuDangNhapGoogle._();

  // (SỬA LỖI — trang trắng sau khi F5 lúc đã đăng nhập) Trước đây đây là
  // field khởi tạo NGAY (`final _googleSignIn = GoogleSignIn(...)`) — dựng
  // `GoogleSignIn()` chạy NGAY LÚC `DichVuDangNhapGoogle.instance` được
  // chạm tới lần đầu, mà việc đó xảy ra VÔ ĐIỀU KIỆN mỗi lần mở trang
  // (`TrangSoanThao.initState`, đọc `nguoiDungHienTai`) — kể cả trên WEB,
  // dù code này chỉ thật sự DÙNG `GoogleSignIn` trên Android (xem chú thích
  // đầu tệp). Trên web, dựng `GoogleSignIn()` khiến gói `google_sign_in_web`
  // tự khởi động Google Identity Services và tự thử "đăng nhập lặng lẽ" lại
  // phiên cũ — khi đang có phiên đăng nhập thật, bước tự thử đó có lúc ném
  // lỗi KHÔNG BẮT ĐƯỢC (uncaught, trong `google_sign_in_web.dart`), sập cả
  // trang ngay từ lúc khởi động → màn hình trắng. Đổi sang getter LƯỜI —
  // chỉ dựng khi THẬT SỰ được gọi tới (luồng Android, `if (!kIsWeb)`), nên
  // trên web không bao giờ chạm tới `GoogleSignIn()` nữa.
  GoogleSignIn? _googleSignInLuuTru;
  GoogleSignIn get _googleSignIn =>
      _googleSignInLuuTru ??= GoogleSignIn(scopes: const ['email']);

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
      await _ghiHoSoNguoiDung(FirebaseAuth.instance.currentUser);
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
    await _ghiHoSoNguoiDung(FirebaseAuth.instance.currentUser);
  }

  /// (YÊU CẦU MỚI) Ghi/cập nhật hồ sơ `users/{uid}` mỗi lần đăng nhập thành
  /// công — phục vụ màn hình admin "Các User đã đăng nhập"
  /// (`modal_danh_sach_user.dart`). Trước đây KHÔNG ghi gì ở đây cả (doc
  /// gốc `users/{uid}` chỉ có các subcollection riêng của bộ nhớ đám mây).
  /// `lanDauDangNhap` chỉ đặt khi doc CHƯA từng có — những lần đăng nhập
  /// sau chỉ cập nhật `lanCuoiDangNhap` cùng email/tên/ảnh mới nhất. Lỗi ở
  /// đây (mất mạng, luật Firestore...) không được làm hỏng cả luồng đăng
  /// nhập — bắt lại, bỏ qua im lặng.
  Future<void> _ghiHoSoNguoiDung(User? nguoiDung) async {
    if (nguoiDung == null) return;
    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(nguoiDung.uid);
      final hienCo = await doc.get();
      final du = <String, dynamic>{
        'email': nguoiDung.email,
        'tenHienThi': nguoiDung.displayName,
        'urlAnhDaiDien': nguoiDung.photoURL,
        'lanCuoiDangNhap': FieldValue.serverTimestamp(),
      };
      if (!hienCo.exists) du['lanDauDangNhap'] = FieldValue.serverTimestamp();
      await doc.set(du, SetOptions(merge: true));
    } catch (_) {
      // Không chặn luồng đăng nhập chỉ vì ghi hồ sơ thất bại.
    }
  }

  Future<void> dangXuat() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) await _googleSignIn.signOut();
  }
}
