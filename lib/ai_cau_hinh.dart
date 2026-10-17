// Địa chỉ và mật khẩu của máy chủ trung gian AI (xem cloud-function/ trong
// kho mã). App KHÔNG BAO GIỜ cầm khoá Gemini thật — chỉ gọi vào đây kèm mật
// khẩu riêng này, máy chủ mới là nơi thật sự gọi Google.

import 'dart:math';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const diaChiMayChuAI =
    'https://flowrite-ai-338376009826.asia-southeast1.run.app';

const matKhauMayChuAI = 'hGzPGCntDDGc0cfAkzePuypITzrJHA55ltIvl9zq';

/// (YÊU CẦU MỚI — vá lỗ hổng "xót tiền") Site key reCAPTCHA Enterprise của
/// dự án `flowrite219` — không phải bí mật (site key LUÔN lộ ra trình duyệt
/// theo đúng cách reCAPTCHA hoạt động, khác hẳn `matKhauMayChuAI`), dùng để
/// App Check sinh token chứng minh "yêu cầu này đến từ app Flowrite thật"
/// trên web. Android dùng Play Integrity, không cần khoá nào ở đây.
const _siteKeyReCaptchaEnterprise = '6LelK_MtAAAAALyj5zKPexmETI4GwyoXiB_uYMl2';

/// Gọi ĐÚNG MỘT LẦN lúc khởi động app (`main.dart`/`main_web_full.dart`,
/// ngay sau `Firebase.initializeApp`). `cloud-function/index.js` xác minh
/// token này (chữ ký RS256 thật, không phải chỉ đọc payload như `idToken`
/// ở trên) trước khi xử lý — hàm `xacMinhAppCheckToken`.
Future<void> khoiTaoAppCheck() async {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    webProvider: ReCaptchaEnterpriseProvider(_siteKeyReCaptchaEnterprise),
  );
}

/// Trả `null` nếu lấy token thất bại (mất mạng, App Check chưa kịp khởi
/// tạo...) — KHÔNG được chặn luồng gọi AI chính vì lỗi ở đây, máy chủ vẫn
/// đang chạy chế độ "chỉ ghi log" (`APP_CHECK_ENFORCE` chưa bật), token
/// thiếu chỉ bị log lại chứ chưa bị từ chối.
Future<String?> _layAppCheckToken() async {
  try {
    return await FirebaseAppCheck.instance.getToken();
  } catch (_) {
    return null;
  }
}

/// Header dùng chung cho MỌI yêu cầu AI — mật khẩu tĩnh (như cũ) CỘNG token
/// App Check (mới). Mọi file `gui_*_gemini.dart`/`kiem_tra_*.dart` đều phải
/// dùng hàm này thay vì tự ghép `headers: {...}` riêng.
Future<Map<String, String>> taoHeaderGoiAi() async {
  final token = await _layAppCheckToken();
  return {
    'content-type': 'application/json',
    'x-flowrite-secret': matKhauMayChuAI,
    if (token != null) 'X-Firebase-AppCheck': token,
  };
}

const _khoaMaThietBiAi = 'maThietBiAi';

/// Mã ngẫu nhiên đại diện cho "thiết bị" khi CHƯA đăng nhập — sinh một lần,
/// lưu `SharedPreferences`, dùng lại mãi sau đó. Máy chủ dùng mã này để tính
/// hạn mức AI riêng cho người chưa đăng nhập (xem `cloud-function/index.js`,
/// `GIOI_HAN_AI`). Xoá dữ liệu trình duyệt/cài lại app thì mã đổi — chấp
/// nhận được, chỉ là lớp chặn lạm dụng thông thường, không phải bảo mật.
Future<String> _taoHoacLayMaThietBiAi() async {
  final kho = await SharedPreferences.getInstance();
  final maCu = kho.getString(_khoaMaThietBiAi);
  if (maCu != null && maCu.isNotEmpty) return maCu;
  final ngauNhien = Random.secure();
  final maMoi = List.generate(24, (_) => ngauNhien.nextInt(36).toRadixString(36)).join();
  await kho.setString(_khoaMaThietBiAi, maMoi);
  return maMoi;
}

/// (YÊU CẦU MỚI — giới hạn hạn mức AI theo từng người) Gắn định danh người
/// gọi vào MỌI yêu cầu AI: `maThietBi` (mã thiết bị ở trên, luôn gửi) và
/// `idToken` (Firebase ID token thật, CHỈ gửi khi đã đăng nhập) — máy chủ
/// dùng để tính hạn mức riêng, tránh một người dùng/script đốt hết ngân sách
/// AI chung. Mọi file `gui_*_gemini.dart`/`kiem_tra_*.dart` đều phải bọc
/// `than` (map thân yêu cầu JSON) qua hàm này trước khi `jsonEncode`.
Future<Map<String, dynamic>> ganDinhDanhAi(Map<String, dynamic> than) async {
  final ma = await _taoHoacLayMaThietBiAi();
  String? idToken;
  final nguoiDung = FirebaseAuth.instance.currentUser;
  if (nguoiDung != null) {
    try {
      idToken = await nguoiDung.getIdToken();
    } catch (_) {
      idToken = null;
    }
  }
  return {
    ...than,
    'maThietBi': ma,
    if (idToken != null) 'idToken': idToken,
  };
}
