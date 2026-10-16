// Kiểm tra bản APK mới trên GitHub Releases — CHỈ có ý nghĩa trên bản APK
// thật (`!kIsWeb`), KHÔNG dùng trên web (web luôn tự cập nhật qua Firebase
// Hosting, không có khái niệm "bản cũ cài trên máy").
//
// Repo tự đăng một Release công khai, tag `v<run_number>`, mỗi lần đẩy nhánh
// không phải "thu-nghiem/" (xem .github/workflows/build-apk.yml) — số hiệu
// Release LUÔN tăng dần nên so sánh được trực tiếp bằng số, không cần phân
// tích chuỗi phiên bản kiểu semver. Bước "Dựng bản phát hành" của CI gắn
// `--build-number=<run_number>` vào APK, nên app tự biết bản mình đang chạy
// là số mấy qua `PackageInfo.buildNumber`, không cần tự lưu hằng số nào ở
// đây (hằng số đó KHÔNG tin được — người ta có thể quên bump).
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// `null` nếu không có bản mới hơn (hoặc kiểm tra lỗi — mất mạng, API
/// GitHub chặn/giới hạn...). KHÔNG BAO GIỜ ném lỗi ra ngoài — lỗi mạng ở
/// đây không phải điều gì nghiêm trọng, im lặng bỏ qua là đúng.
Future<int?> kiemTraBanApkMoiHon() async {
  try {
    final thongTin = await PackageInfo.fromPlatform();
    final banHienTai = int.tryParse(thongTin.buildNumber);
    if (banHienTai == null) return null;

    final res = await http
        .get(
          Uri.parse('https://api.github.com/repos/sotay99/ghi-noi/releases/latest'),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;

    final j = jsonDecode(res.body);
    if (j is! Map) return null;
    final tag = j['tag_name'];
    if (tag is! String || !tag.startsWith('v')) return null;
    final banMoiNhat = int.tryParse(tag.substring(1));
    if (banMoiNhat == null) return null;

    return banMoiNhat > banHienTai ? banMoiNhat : null;
  } catch (_) {
    return null;
  }
}
