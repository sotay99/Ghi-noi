// Viết TAY thay cho lệnh `flutterfire configure` — môi trường dựng mã này
// không có Flutter SDK cài sẵn để chạy lệnh đó. Giá trị lấy thẳng từ Console
// Firebase, project `flowrite219` (project ĐÃ CÓ sẵn, đang dùng cho Firebase
// Hosting của bản Web — xem `.github/workflows/deploy-web-full.yml`), lúc
// đăng ký thêm app Android và app Web cho Đăng nhập Google.
//
// `apiKey` ở đây KHÔNG phải bí mật cần giấu — nó luôn lộ ra công khai trong
// bản JS/APK đã dựng xong của BẤT KỲ app Firebase nào (ai cũng tải app về
// rồi đọc ra được), vai trò của nó chỉ là xác định ĐÚNG project, không phải
// xác thực quyền. Lớp bảo vệ thật nằm ở "Authorized domains" (web) và chữ ký
// SHA-1 đăng ký với package name (Android) trong Console, cùng luật của
// Firebase Authentication/Security Rules — không nằm ở việc giấu `apiKey`.
//
// Chỉ có HAI nền tảng app này build (xem README mục "Cấu trúc mã nguồn"):
// Web và Android. Thêm nền tảng khác (iOS...) thì vào Console đăng ký app
// mới rồi thêm một nhánh `FirebaseOptions` nữa ở đây.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions chưa có cấu hình cho nền tảng này — app '
          'Flowrite chỉ dựng cho Web và Android.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCwqNQKmIo3S_wny8hzaZcosA0jKAaC7IA',
    appId: '1:1081343450729:web:5833f9c895d22212338cf8',
    messagingSenderId: '1081343450729',
    projectId: 'flowrite219',
    authDomain: 'flowrite219.firebaseapp.com',
    storageBucket: 'flowrite219.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDSRo0ia7UQ2cxI8QQX_JcD2fLEPB7Va9s',
    appId: '1:1081343450729:android:0ddbecc02fa7384c338cf8',
    messagingSenderId: '1081343450729',
    projectId: 'flowrite219',
    storageBucket: 'flowrite219.firebasestorage.app',
  );
}
