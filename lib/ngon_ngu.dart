// Khung đa ngôn ngữ của app — hiện có Tiếng Việt và English, thêm ngôn ngữ
// mới (ví dụ tiếng Trung, tiếng Thái) sau này chỉ cần: (1) thêm 1 case vào
// enum [NgonNgu] dưới đây, (2) thêm 1 nhánh giá trị cho MỖI chuỗi trong
// `lib/chuoi_da_ngon_ngu.dart`. Không đụng gì ở từng màn hình đang gọi `Ch.*`.
//
// KHÔNG dùng `flutter_localizations`/ARB (cần Flutter CLI để sinh code, môi
// trường build hiện tại không kiểm chứng được bước đó) — tự viết thuần Dart,
// đơn giản, kiểm tra được bằng mắt.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NgonNgu { vi, en }

const _khoaNgonNgu = 'ghi_noi_ngon_ngu';
const _khoaDaChonNgonNgu = 'ghi_noi_da_chon_ngon_ngu';

/// Tên RIÊNG (tự xưng) của mỗi ngôn ngữ — dùng cho MỌI nơi liệt kê tên ngôn
/// ngữ để người dùng chọn (dropdown ngôn ngữ app, dropdown ngôn ngữ ghi âm):
/// KHÔNG BAO GIỜ dịch, luôn hiện nguyên văn "English"/"Tiếng Việt" dù app
/// đang ở ngôn ngữ nào. Thêm ngôn ngữ mới vào enum [NgonNgu] thì thêm đúng
/// MỘT case ở đây — không đụng gì ở nơi gọi.
String tenRiengNgonNgu(NgonNgu nn) {
  switch (nn) {
    case NgonNgu.vi:
      return 'Tiếng Việt';
    case NgonNgu.en:
      return 'English';
  }
}

/// Mã ISO-639-1 của ngôn ngữ — dùng khi gửi lên máy chủ AI (ví dụ tham số
/// `ngonNgu` cho Groq Whisper, xem `goiGroqAmThanh` ở `cloud-function/index.js`).
String maIso6391(NgonNgu nn) {
  switch (nn) {
    case NgonNgu.vi:
      return 'vi';
    case NgonNgu.en:
      return 'en';
  }
}

/// (MỚI — mục B, "đồng bộ ngôn ngữ prompt khi làm việc với AI") Chỉ dẫn
/// NGÔN NGỮ TRẢ LỜI để chèn vào prompt/lịch sử gửi AI — dùng cho các tính
/// năng mà client TỰ XÂY prompt (hiện chỉ có "Trò chuyện"/`tro_chuyen`,
/// xem `lib/man_hinh_tro_chuyen.dart`): server chỉ chuyển tiếp thẳng
/// `lichSu` cho Gemini (`goiGeminiChatStream`), không tự thêm chỉ dẫn nào,
/// nên client chèn được trực tiếp. Luôn đọc [nn] tại nơi gọi (không cache)
/// để theo sát ngôn ngữ app hiện tại. Thêm ngôn ngữ mới vào [NgonNgu] thì
/// thêm đúng một case ở đây.
///
/// LƯU Ý QUAN TRỌNG (chưa áp dụng được cho các tính năng AI khác): Tóm
/// tắt/Mở rộng/Viết lại/Kiểm tra toàn văn/Kiểm tra chính tả/Đề xuất ý
/// tưởng đều có prompt XÂY SẴN Ở PHÍA SERVER (`cloud-function/index.js`,
/// các hàm `huongDanTomTat`/`huongDanMoRong`/`huongDanVietLai`/
/// `huongDanToanVan`/`huongDanChiChinhTaToanVan`/`huongDanChiDauCauToanVan`/
/// `huongDanChinhTa`/`huongDanTheoHanhDong` case `de_xuat_y_tuong`) — mỗi
/// hàm đó đều VIẾT CỨNG "tiếng Việt" ngay trong câu chỉ dẫn gửi Gemini.
/// Client không có cách chèn ngôn ngữ vào prompt của các tính năng này —
/// muốn đồng bộ đúng mục B cho chúng PHẢI sửa `cloud-function/index.js`
/// (đọc field `ngonNguApp` các request đã gửi kèm sẵn ở dưới, rồi tự ghép
/// câu chỉ dẫn ngôn ngữ tương ứng vào từng hàm `huongDan*`) — việc đó CHƯA
/// làm ở đây, để dành cho lượt sửa `cloud-function/index.js` sau.
String huongDanNgonNguChoAiTheo(NgonNgu nn) {
  switch (nn) {
    case NgonNgu.vi:
      return 'Hãy luôn trả lời bằng tiếng Việt.';
    case NgonNgu.en:
      return 'Always answer in English.';
  }
}

/// (MỚI — "Ngôn ngữ ghi âm") Ngôn ngữ dùng cho tính năng ghi âm (nói xong
/// mới ra chữ, gọi Groq) — TÁCH RIÊNG khỏi [NgonNgu] (ngôn ngữ app) vì có
/// thêm 2 lựa chọn mà [NgonNgu] không có: "theo ngôn ngữ app hiện tại" và
/// "tự động nhận diện trong âm thanh". Thêm ngôn ngữ mới vào [NgonNgu] thì
/// thêm đúng một case tương ứng ở đây ([vi]/[en] hiện có là ví dụ).
enum NgonNguGhiAm { theoApp, tuDongNhanDien, vi, en }

const _khoaNgonNguGhiAm = 'ghi_noi_ngon_ngu_ghi_am';

final ValueNotifier<NgonNguGhiAm> ngonNguGhiAmHienTai =
    ValueNotifier<NgonNguGhiAm>(NgonNguGhiAm.theoApp);

Future<void> taiNgonNguGhiAm() async {
  final kho = await SharedPreferences.getInstance();
  final ma = kho.getString(_khoaNgonNguGhiAm);
  switch (ma) {
    case 'tuDongNhanDien':
      ngonNguGhiAmHienTai.value = NgonNguGhiAm.tuDongNhanDien;
      break;
    case 'vi':
      ngonNguGhiAmHienTai.value = NgonNguGhiAm.vi;
      break;
    case 'en':
      ngonNguGhiAmHienTai.value = NgonNguGhiAm.en;
      break;
    default:
      ngonNguGhiAmHienTai.value = NgonNguGhiAm.theoApp;
  }
}

String _maLuuNgonNguGhiAm(NgonNguGhiAm nng) {
  switch (nng) {
    case NgonNguGhiAm.theoApp:
      return 'theoApp';
    case NgonNguGhiAm.tuDongNhanDien:
      return 'tuDongNhanDien';
    case NgonNguGhiAm.vi:
      return 'vi';
    case NgonNguGhiAm.en:
      return 'en';
  }
}

/// Mã ngôn ngữ THẬT (`vi`/`en`) để gửi lên máy chủ AI cho tính năng ghi âm,
/// tính từ [nng] (đã chọn) + [ngonNguApp] (ngôn ngữ app hiện tại, dùng khi
/// [nng] là [NgonNguGhiAm.theoApp]). Trả `null` khi chọn "Tự động nhận
/// diện trong âm thanh" — nơi gọi (`gui_ghi_am_gemini.dart`) không gửi
/// field lên server trong trường hợp này.
String? maNgonNguGhiAmChoAi(NgonNguGhiAm nng, NgonNgu ngonNguApp) {
  switch (nng) {
    case NgonNguGhiAm.theoApp:
      return maIso6391(ngonNguApp);
    case NgonNguGhiAm.tuDongNhanDien:
      return null;
    case NgonNguGhiAm.vi:
      return 'vi';
    case NgonNguGhiAm.en:
      return 'en';
  }
}

Future<void> datNgonNguGhiAm(NgonNguGhiAm nng) async {
  ngonNguGhiAmHienTai.value = nng;
  final kho = await SharedPreferences.getInstance();
  await kho.setString(_khoaNgonNguGhiAm, _maLuuNgonNguGhiAm(nng));
  unawaited(_dayHaiCaiDatNgonNguLenTaiKhoanNeuDangNhap());
}

/// (ĐỒNG BỘ TÀI KHOẢN GOOGLE) Document Firestore riêng cho 2 cài đặt ngôn
/// ngữ (app + ghi âm) — CÙNG document `users/<uid>/caiDatDamMay/chinh` mà
/// `CaiDatDamMay` (`kho_du_lieu.dart`) đang dùng cho các cài đặt khác, ghi
/// GỘP (merge) nên không đụng các trường khác đã có. Không import
/// `kho_du_lieu.dart` ở đây (tránh vòng import với `cai_dat.dart` ->
/// `ngon_ngu.dart`) — tự ghi/đọc thẳng Firestore bằng đúng đường dẫn đó.
DocumentReference<Map<String, dynamic>> _vanBanCaiDatDamMay(String uid) =>
    FirebaseFirestore.instance.collection('users').doc(uid).collection('caiDatDamMay').doc('chinh');

Future<void> _dayHaiCaiDatNgonNguLenTaiKhoanNeuDangNhap() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  try {
    await _vanBanCaiDatDamMay(uid).set({
      'ngonNguApp': ngonNguHienTai.value == NgonNgu.en ? 'en' : 'vi',
      'ngonNguGhiAm': _maLuuNgonNguGhiAm(ngonNguGhiAmHienTai.value),
    }, SetOptions(merge: true));
  } catch (_) {
    // Mất mạng/lỗi Firestore — bỏ qua lặng lẽ, y hệt `CaiDatDamMay.luu`;
    // giá trị ở máy (SharedPreferences) đã lưu xong rồi, không mất gì.
  }
}

/// (ĐỒNG BỘ TÀI KHOẢN GOOGLE) Gọi mỗi lần phát hiện tài khoản [uid] đang
/// đăng nhập (đăng nhập thành công MỚI, hoặc phiên cũ tự khôi phục) — xem
/// nơi gọi `_dongBoCaiDatTuTaiKhoanKhiDangNhap` ở `trang_soan_thao.dart`.
/// Quy tắc GIỐNG `CaiDatDamMay`/`CaiDat.apDungCaiDatDongBo`: tài khoản ĐÃ
/// có giá trị thì áp giá trị đó (ghi đè thiết bị); tài khoản CHƯA có (lần
/// đầu đăng nhập) thì lấy giá trị hiện tại của thiết bị và ghi luôn vào
/// tài khoản để lần đăng nhập sau có sẵn.
Future<void> dongBoNgonNguKhiDangNhap(String uid) async {
  Map<String, dynamic> daCo;
  try {
    final snap = await _vanBanCaiDatDamMay(uid).get();
    daCo = snap.data() ?? <String, dynamic>{};
  } catch (_) {
    return; // Mất mạng — giữ nguyên giá trị thiết bị, không đổi gì.
  }

  final canNapDay = <String, dynamic>{};

  final appTaiKhoan = daCo['ngonNguApp'];
  if (appTaiKhoan is String) {
    await datNgonNgu(appTaiKhoan == 'en' ? NgonNgu.en : NgonNgu.vi);
  } else {
    canNapDay['ngonNguApp'] = ngonNguHienTai.value == NgonNgu.en ? 'en' : 'vi';
  }

  final ghiAmTaiKhoan = daCo['ngonNguGhiAm'];
  if (ghiAmTaiKhoan is String) {
    switch (ghiAmTaiKhoan) {
      case 'tuDongNhanDien':
        await datNgonNguGhiAm(NgonNguGhiAm.tuDongNhanDien);
        break;
      case 'vi':
        await datNgonNguGhiAm(NgonNguGhiAm.vi);
        break;
      case 'en':
        await datNgonNguGhiAm(NgonNguGhiAm.en);
        break;
      default:
        await datNgonNguGhiAm(NgonNguGhiAm.theoApp);
    }
  } else {
    canNapDay['ngonNguGhiAm'] = _maLuuNgonNguGhiAm(ngonNguGhiAmHienTai.value);
  }

  if (canNapDay.isNotEmpty) {
    try {
      await _vanBanCaiDatDamMay(uid).set(canNapDay, SetOptions(merge: true));
    } catch (_) {
      // Bỏ qua lặng lẽ — lần đổi cài đặt kế tiếp (có mạng) sẽ tự đẩy lại.
    }
  }
}

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
  unawaited(_dayHaiCaiDatNgonNguLenTaiKhoanNeuDangNhap());
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
