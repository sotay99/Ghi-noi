// Flowrite — BẢN THỬ NGHIỆM riêng cho Flutter Web.
//
// File này là MỘT APP FLUTTER ĐỘC LẬP, có `void main()`/`runApp()` riêng.
// KHÔNG import `main.dart`, `trang_soan_thao.dart` hay bất kỳ file nào khác
// của app Android hiện có — mục đích DUY NHẤT là kiểm chứng xem thuật toán
// xử lý kết quả giọng nói (chốt dần + tìm điểm nối) có chạy ổn với nguồn dữ
// liệu từ Web Speech API (qua package `speech_to_text` chạy trên web) hay
// không, TÁCH BIỆT HOÀN TOÀN khỏi app Android.
//
// Thuật toán lõi bên dưới là bản ĐƠN GIẢN HOÁ, viết lại (không import) từ
// `_khiCoChu`/`_tuDaChotTrongPhien`/`_partialTruocDo`/`_timDiemNoiTrong` và
// LỚP 1 (re-check `idPhien`) trong `lib/trang_soan_thao.dart` — xem chú thích
// ở đó để biết đầy đủ lý do thiết kế. Ở đây bỏ bớt các phần không cần cho mục
// đích test: không có "bộ đệm chống nhân đôi qua ranh giới phiên" (LỚP 2),
// không đụng chỉnh tả/bộ nhớ đệm định dạng. CÓ gõ-phím-thắng-micro (xem
// `_khiNguoiDungGoPhim`) để test vừa nói vừa gõ tay.
//
// THÊM MỚI (vòng test di động):
// - Nhận diện thiết bị qua User-Agent (enum `ThietBi`: android/pc/iphone),
//   có nút chuyển tay (SegmentedButton) để ép chế độ khi nhận diện sai —
//   MỖI nhánh gọi một hàm xử lý kết quả RIÊNG (`_xuLyKetQuaDienThoai` /
//   `_xuLyKetQuaPc` / `_xuLyKetQuaIphone`) để sửa nhánh này không đụng
//   nhánh khác.
// - Khung "Nhật ký" hiển thị NGAY trên trang (không cần USB debug) để người
//   dùng chụp màn hình gửi lại khi rà lỗi trên điện thoại.
// - Vá lỗi nhân bản chữ đã thấy trên Chrome Android: khi không tìm được
//   điểm nối VÀ đoạn partial mới dài bằng/hơn toàn bộ phần đã chốt — dấu
//   hiệu bộ nhận dạng đang gửi lại TOÀN BỘ câu từ đầu chứ không phải phần
//   mới — thì coi partial mới là toàn bộ nội dung phiên, không nối thêm
//   (nối thêm trong trường hợp này là nguyên nhân gây chữ nhân bản chồng
//   chất trong ảnh chụp người dùng gửi).
// - Ghi âm thô + gửi Gemini phiên âm (dành cho iPhone, nơi Web Speech API
//   không hoạt động kể cả bấm tay): mỗi lần dừng ghi âm chèn một token
//   "〔🎙️ Ghi âm N〕" vào đúng vị trí con trỏ trong khung nhập — token văn
//   bản THUẦN TUÝ, không phải ô chip đồ hoạ thật (TextField của Flutter
//   không hỗ trợ chèn widget vào giữa văn bản có thể sửa). Nút "Tạo văn
//   bản" gửi từng file ghi âm cho máy chủ trung gian AI đã có sẵn action
//   'ghi_am' (xem cloud-function/index.js, app Android cũng dùng chung —
//   lib/ghi_am_ai.dart), rồi thay đúng mỗi token bằng chữ phiên âm được,
//   giữ nguyên các đoạn gõ tay xen kẽ xung quanh.
// - (v18) Thẻ hiện NGAY lúc bắt đầu ghi (token tĩnh "đang ghi âm", đồng hồ
//   đếm giờ hiển thị ở hàng tiêu đề "Kết quả", KHÔNG nhét vào trong nội
//   dung văn bản để tránh xung đột với gõ tay), đổi thành "Thẻ ghi âm số N"
//   khi dừng. Trên iPhone, nút micro CHÍNH (nút xanh lá) giờ gọi thẳng cơ
//   chế ghi-âm-rồi-gửi-Gemini thay vì thử Web Speech API (vốn không chạy
//   được trên iOS). Bàn phím ảo hiện lên thì ẩn hết các hàng bên dưới khung
//   nhập, để khung nhập giãn hết cỡ phần còn lại phía trên bàn phím.
// - (v19) Thẻ giờ KHÔNG thể sửa/xoá từng ký tự bên trong — `_ChanSuaGiuaThe`
//   (một `TextInputFormatter`) phóng to mọi chỉnh sửa chồng lấn một phần
//   vùng thẻ thành xoá TRỌN thẻ, và đẩy con trỏ ra khỏi giữa thẻ khi chỉ di
//   chuyển (không gõ). Thẻ cũng được tô màu: "Ghi âm N" xanh lá, token
//   "đang ghi âm" đỏ (`_BoDieuKhienVanBanCoThe`, override `buildTextSpan`).
//   Bỏ hai nút "Nghe lại"/"Tải xuống"; trên iPhone ẩn nút "Ghi âm" riêng vì
//   nút micro chính đã làm đúng việc đó rồi.
// - (v20) Sửa TẬN GỐC lỗi "gõ tay lúc đang ghi làm token rác/thứ tự sai":
//   thiết kế cũ (v18/v19) COI gõ tay là HUỶ bản ghi, nhưng `MediaRecorder.
//   stop()` luôn bắn sự kiện 'stop' bất đồng bộ SAU ĐÓ — trong khoảng chờ
//   đó (có thể trải qua nhiều phím gõ tiếp theo) token "đang ghi âm" vẫn
//   còn nằm lù lù trong văn bản như chữ thật, gây đúng các lỗi đã gặp.
//   Nay đổi hẳn cách hiểu: gõ tay trong lúc ghi KHÔNG huỷ mà CHỐT NGAY
//   (đồng bộ, không đợi 'stop') thẻ đang ghi thành "〔🎙️ Ghi âm N〕" tại
//   đúng vị trí cũ, rồi BẮT ĐẦU MỘT THẺ MỚI ngay sau ký tự vừa gõ, dùng lại
//   đúng luồng mic đã xin quyền — ghi âm tiếp tục liền mạch, tách thành hai
//   thẻ, không mất tiếng, không còn token rác. Số thẻ được DÀNH SẴN ngay
//   lúc bắt đầu ghi (`_soTheDangGhiHienTai`), không đợi tới lúc có blob âm
//   thanh — sự kiện 'stop' giờ CHỈ lưu blob vào đúng số thẻ đã dành sẵn,
//   không động gì tới văn bản nữa. `_chenTheGhiAmVaoVanBan` cũng được sửa
//   để GIỮ NGUYÊN vị trí tương đối của con trỏ so với phần chữ nằm sau
//   token (ví dụ dấu phẩy vừa gõ), thay vì luôn đẩy con trỏ về ngay sau
//   token — tránh lỗi con trỏ nhảy lùi đã gặp.
// - (v21) `_batDauMotThe` tách làm hai (`_taoBoGhiAmMoi` chỉ tạo
//   `MediaRecorder`, không đụng văn bản) để lúc tách thẻ có thể gộp
//   chốt-token-cũ + chèn-token-mới vào một thao tác — mục đích ban đầu là
//   sửa lỗi "phải gõ hai ký tự", nhưng chẩn đoán lúc đó SAI (xem v22).
// - (v22) TÌM RA nguyên nhân THẬT của lỗi "phải gõ hai ký tự mới tách thẻ":
//   gán `TextEditingController.value =` theo cách lập trình KHÔNG khiến
//   `TextField.onChanged` tự chạy lại — khác hẳn giả định ở các bản v18–v21.
//   Bằng chứng (log v21): token "đang ghi âm" chèn lúc 17:30:13, nhưng
//   dòng log lẽ ra phải in NGAY nếu có `onChanged` chạy lại chỉ thực sự
//   xuất hiện lúc 17:30:17 — đúng lúc người dùng gõ phím THẬT tiếp theo.
//   Cờ "bỏ qua một lần" (`_boQuaKiemTraGoTrongLucGhiMotLan`) vì vậy nằm
//   chờ mãi và NUỐT MẤT đúng lượt gõ phím thật kế tiếp — đó là lý do luôn
//   phải gõ thêm một ký tự nữa. Sửa: BỎ HẲN cơ chế cờ; mọi hàm chèn/thay
//   token giờ tự chốt cứng trạng thái (`_vanBanDaChot`, `_tuDaChot`...)
//   NGAY TẠI CHỖ bằng `_ghiVanBanChoTheVaChotCung`, không còn trông chờ
//   một `onChanged` không tồn tại nữa.
//   CHƯA LÀM (còn nợ, sẽ làm khi có xác nhận thêm): tự kết thúc thẻ khi con
//   trỏ DI CHUYỂN mà không gõ tay; chế độ tự động gửi ngầm các thẻ đã xong
//   trong lúc ghi thẻ mới; gộp nhiều thẻ vào một lần gọi Gemini để có ngữ
//   cảnh (cần sửa cả Cloud Function, phải làm riêng).

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';

// Ngoại lệ DUY NHẤT cho luật "không import file nào khác của app" ở đầu
// file — import CHỈ hai hằng số (địa chỉ + mật khẩu máy chủ trung gian AI),
// không kéo theo bất kỳ logic nào có thể ảnh hưởng tới thuật toán mic đã
// test kỹ. Giữ một nguồn duy nhất cho bí mật thay vì chép tay chuỗi mật
// khẩu ra thêm một chỗ trong mã nguồn.
import 'ai_cau_hinh.dart';

// Số phiên bản bản thử — TĂNG THỦ CÔNG mỗi lần đẩy bản mới lên Firebase
// Hosting, để người test biết chắc trình duyệt đã tải đúng bản mới nhất
// hay đang dùng bản cache cũ (Chrome hay giữ cache service worker của
// Flutter Web dù đã bấm tải lại thường).
const _phienBanThuNghiem = 'v22';

// `diaChiMayChuAI`/`matKhauMayChuAI` đến từ ai_cau_hinh.dart (import ở
// trên) — máy chủ đó đã có sẵn action 'ghi_am' (xem cloud-function/
// index.js) dùng đúng cho việc gửi âm thanh cho Gemini phiên âm, app
// Android cũng đang dùng chung cơ chế này (lib/ghi_am_ai.dart).

// (Chỉ import đúng MỘT file `speech_to_text/speech_to_text.dart` — y hệt
// cách `trang_soan_thao.dart` đang dùng đã chứng minh hoạt động — thay vì
// đoán thêm đường import phụ (`speech_recognition_result.dart`,
// `speech_recognition_error.dart`) không có gì đảm bảo đúng khi môi trường
// này không compile-check được. `onResult`/`onError` vì thế nhận `dynamic`,
// giống hệt `_khiCoChu(dynamic ketQua, ...)` trong app chính.)

void main() {
  runApp(const UngDungThuMicroWeb());
}

class UngDungThuMicroWeb extends StatelessWidget {
  const UngDungThuMicroWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowrite — thử micro web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
      ),
      home: const TrangThuMicro(),
    );
  }
}

/// Ba nhánh thiết bị — mỗi nhánh một cách xử lý kết quả giọng nói riêng, vì
/// mỗi hệ điều hành/trình duyệt có cách trả kết quả khác nhau:
/// - `android`: Chrome trên Android (đã test kỹ, dùng bộ máy Chromium thật).
/// - `pc`: Chrome/Edge trên Windows/Linux VÀ trên macOS (Chrome trên Mac
///   dùng đúng bộ máy Chromium như Windows/Linux, không bị Apple ép dùng
///   WebKit như trên iOS — nên gộp chung một nhánh).
/// - `iPhone`: Safari/Chrome trên iOS — trên iOS, MỌI trình duyệt (kể cả
///   Chrome) đều bị Apple bắt buộc dùng chung bộ máy WebKit của Safari, nên
///   chỉ cần MỘT nhánh cho toàn bộ iPhone/iPad, bất kể tên trình duyệt.
enum ThietBi { android, pc, iphone }

String _tenThietBi(ThietBi t) {
  switch (t) {
    case ThietBi.android:
      return 'Android';
    case ThietBi.pc:
      return 'PC/Mac';
    case ThietBi.iphone:
      return 'iPhone';
  }
}

/// Đoán thiết bị bằng User-Agent — chỉ dùng làm giá trị GỢI Ý ban đầu, người
/// dùng luôn bấm được nút chuyển tay nếu đoán sai (ví dụ PC thu nhỏ cửa sổ).
ThietBi _doanThietBi() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  // iOS trước Android/mobile: iPad ở chế độ "Desktop site" vẫn có thể lẫn
  // chữ "mobile", nhưng chữ "iphone"/"ipad" luôn xuất hiện trên iOS thật.
  if (ua.contains('iphone') || ua.contains('ipad')) return ThietBi.iphone;
  if (ua.contains('android') || ua.contains('mobile')) return ThietBi.android;
  return ThietBi.pc;
}

/// Bộ điều khiển văn bản riêng, CHỈ khác `TextEditingController` chuẩn ở
/// việc tô màu: thẻ đã ghi âm xong ("〔🎙️ Ghi âm N〕") màu XANH LÁ, token
/// đang ghi dở ("〔🎙️ … đang ghi âm …〕") màu ĐỎ — để người dùng phân biệt
/// bằng mắt ngay trong khung nhập, không cần chờ bấm "Tạo văn bản". Không
/// đụng gì tới cách lưu trữ text (`text`/`value` vẫn y hệt controller gốc),
/// chỉ override cách VẼ ra màn hình.
class _BoDieuKhienVanBanCoThe extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final noiDung = text;
    final moc = <(int, int, Color)>[];
    for (final m in _TrangThuMicroState._reTheGhiAm.allMatches(noiDung)) {
      moc.add((m.start, m.end, Colors.green.shade700));
    }
    var timTu = 0;
    while (true) {
      final i = noiDung.indexOf(
          _TrangThuMicroState._tenTokenDangGhi, timTu);
      if (i < 0) break;
      moc.add((i, i + _TrangThuMicroState._tenTokenDangGhi.length,
          Colors.red.shade700));
      timTu = i + _TrangThuMicroState._tenTokenDangGhi.length;
    }
    moc.sort((a, b) => a.$1.compareTo(b.$1));

    final spans = <InlineSpan>[];
    var conTro = 0;
    for (final m in moc) {
      if (m.$1 < conTro) continue; // đè nhau (không nên xảy ra) — bỏ qua.
      if (m.$1 > conTro) {
        spans.add(TextSpan(text: noiDung.substring(conTro, m.$1)));
      }
      spans.add(TextSpan(
        text: noiDung.substring(m.$1, m.$2),
        style: TextStyle(color: m.$3, fontWeight: FontWeight.bold),
      ));
      conTro = m.$2;
    }
    if (conTro < noiDung.length) {
      spans.add(TextSpan(text: noiDung.substring(conTro)));
    }
    return TextSpan(style: style, children: spans);
  }
}

/// Chặn sửa/xoá TỪNG KÝ TỰ bên trong một thẻ ghi âm (dù đã xong hay đang
/// ghi dở) — mọi chỉnh sửa CHỒNG LẤN một phần vùng ký tự của thẻ (không phủ
/// trọn thẻ) sẽ bị "phóng to" thành xoá NGUYÊN CẢ THẺ đó, để người dùng chỉ
/// có hai lựa chọn: giữ nguyên thẻ, hoặc xoá trọn một lần. Đồng thời chặn
/// con trỏ (hoặc vùng chọn) dừng lại ở GIỮA một thẻ khi người dùng chỉ di
/// chuyển con trỏ (không gõ gì) — tự đẩy ra biên gần nhất.
class _ChanSuaGiuaThe extends TextInputFormatter {
  List<(int, int)> _cacVungThe(String text) {
    final vung = <(int, int)>[];
    for (final m in _TrangThuMicroState._reTheGhiAm.allMatches(text)) {
      vung.add((m.start, m.end));
    }
    var timTu = 0;
    while (true) {
      final i = text.indexOf(_TrangThuMicroState._tenTokenDangGhi, timTu);
      if (i < 0) break;
      vung.add((i, i + _TrangThuMicroState._tenTokenDangGhi.length));
      timTu = i + _TrangThuMicroState._tenTokenDangGhi.length;
    }
    return vung;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    if (oldText == newText) {
      // Không đổi chữ — chỉ đổi vùng chọn (di chuyển con trỏ bằng phím mũi
      // tên hoặc chạm/bấm chuột). Đẩy con trỏ ra khỏi giữa thẻ nếu cần.
      final vung = _cacVungThe(newText);
      if (vung.isEmpty) return newValue;
      int day(int viTri) {
        for (final v in vung) {
          if (viTri > v.$1 && viTri < v.$2) {
            return (viTri - v.$1) < (v.$2 - viTri) ? v.$1 : v.$2;
          }
        }
        return viTri;
      }
      final base = day(newValue.selection.baseOffset);
      final extent = day(newValue.selection.extentOffset);
      if (base == newValue.selection.baseOffset &&
          extent == newValue.selection.extentOffset) {
        return newValue;
      }
      return newValue.copyWith(
        selection: TextSelection(baseOffset: base, extentOffset: extent),
      );
    }

    final vungCu = _cacVungThe(oldText);
    if (vungCu.isEmpty) return newValue;

    // Tìm đoạn khác nhau đầu/cuối giữa văn bản cũ và mới — cách đơn giản để
    // biết chính xác vùng ký tự nào trong `oldText` vừa bị đổi.
    var dau = 0;
    final ngan =
        oldText.length < newText.length ? oldText.length : newText.length;
    while (dau < ngan && oldText[dau] == newText[dau]) dau++;
    var cuoiCu = oldText.length;
    var cuoiMoi = newText.length;
    while (cuoiCu > dau &&
        cuoiMoi > dau &&
        oldText[cuoiCu - 1] == newText[cuoiMoi - 1]) {
      cuoiCu--;
      cuoiMoi--;
    }

    for (final v in vungCu) {
      final chongLan = dau < v.$2 && cuoiCu > v.$1;
      final phuTron = dau <= v.$1 && cuoiCu >= v.$2;
      if (chongLan && !phuTron) {
        // Sửa/xoá một phần của thẻ — phóng to vùng xoá ra trọn thẻ đó,
        // giữ nguyên phần chữ gõ tay còn lại ở hai đầu (nếu có).
        final vanBanKetQua = oldText.replaceRange(v.$1, v.$2, '');
        return TextEditingValue(
          text: vanBanKetQua,
          selection: TextSelection.collapsed(offset: v.$1),
        );
      }
    }
    return newValue;
  }
}

class TrangThuMicro extends StatefulWidget {
  const TrangThuMicro({super.key});

  @override
  State<TrangThuMicro> createState() => _TrangThuMicroState();
}

class _TrangThuMicroState extends State<TrangThuMicro> {
  final _micro = SpeechToText();

  bool _sanSang = false;
  bool _muonNghe = false; // người dùng bấm bật, kể cả khi trình duyệt tạm dừng.
  bool _dangNghe = false;
  String _loi = '';

  // Chế độ thiết bị: đoán ban đầu qua User-Agent, người dùng đổi được bằng
  // nút chuyển tay (SegmentedButton 3 lựa chọn). Mỗi nhánh gọi một hàm xử
  // lý kết quả RIÊNG (`_xuLyKetQuaPc`/`_xuLyKetQuaDienThoai`/
  // `_xuLyKetQuaIphone`) — sửa cho nhánh này không đụng nhánh khác.
  late ThietBi _thietBi;

  // ---- đếm để nhìn bằng mắt lúc debug ----
  int _soLanPartial = 0;
  int _soLanFinal = 0;

  // ---- văn bản đang hiển thị — giờ CHO PHÉP gõ tay trực tiếp vào khung
  // kết quả, với nguyên tắc gõ-phím-thắng-micro (y hệt tinh thần
  // `_nguoiDungVuaGo()` bên app chính): gõ một phím là micro tắt NGAY, tự
  // bật lại sau 1 giây không gõ tiếp. ----
  String _vanBan = '';
  final _boDieuKhienVanBan = _BoDieuKhienVanBanCoThe();

  // Văn bản đã "chốt cứng" — giữ NGUYÊN VĂN (kể cả dấu xuống dòng/khoảng
  // trắng người dùng tự gõ). Micro chỉ được phép NỐI THÊM vào biến này
  // (không bao giờ dựng lại toàn bộ `_vanBan` bằng cách join(' ') danh sách
  // từ — làm vậy sẽ nuốt mất mọi dấu xuống dòng gõ tay, đúng lỗi người dùng
  // báo: bấm Enter xong nói tiếp thì dấu xuống dòng biến mất).
  String _vanBanDaChot = '';

  // Cờ chặn: khi TRUE nghĩa là đoạn `_boDieuKhienVanBan.text` đang được
  // chính code (do micro) ghi vào, không phải người dùng gõ — để
  // `_khiNguoiDungGoPhim` (gắn vào `onChanged`) không hiểu nhầm là người
  // dùng gõ rồi tắt oan micro.
  bool _dangGhiTuMicro = false;

  Timer? _henMoLaiMicroSauKhiGo;

  // ---- nhật ký hiển thị ngay trên trang, để test trên điện thoại không
  // cần USB debug — mỗi dòng có giờ:phút:giây để dễ đối chiếu. ----
  final List<String> _nhatKy = [];
  final _cuonNhatKy = ScrollController();

  // ---- trạng thái thuật toán "chốt dần theo độ ổn định" + "tìm điểm nối",
  // bản đơn giản hoá cho một PHIÊN duy nhất (không cần đệm ranh giới phiên
  // vì mục đích test không cần chính xác 100% qua mỗi lần trình duyệt tự
  // ngắt — chỉ cần QUAN SÁT được thuật toán chạy ổn hay không). ----
  List<String> _tuDaChot = [];
  List<String> _partialTruocDo = [];

  // Riêng cho nhánh điện thoại: chuỗi thô (sau khi đã cắt-đoạn-cuối-sạch)
  // của lần callback TRƯỚC trong CÙNG phiên hiện tại — dùng để lấy đúng
  // phần MỚI thêm vào bằng cách so sánh chuỗi (không phụ thuộc việc đoạn
  // lặp lại có viết hoa hay không, vì cách cắt theo chữ hoa không bắt được
  // mọi trường hợp lặp — xem log thực tế: có lúc lặp lại giữa câu, không
  // hoa chữ nào). Reset về rỗng mỗi khi phiên nghe mới bắt đầu.
  String _rawTruocDoTrongPhien = '';

  // Đánh số phiên nghe, y hệt `idPhien`/`_phienNgheHienTai` bên app chính —
  // để loại bỏ callback trễ của một phiên đã đóng (LỚP 1).
  int _phienHienTai = 0;

  Timer? _henBatLai;

  // ---- Ghi âm thô + nghe lại — TÁCH BIỆT HOÀN TOÀN khỏi Web Speech API ở
  // trên. Dùng MediaRecorder chuẩn của trình duyệt (ghi ra file âm thanh,
  // không nhận dạng chữ gì cả) — vì trên iPhone (Safari/Chrome đều chung
  // WebKit) Web Speech API không hoạt động được kể cả khi bấm tay từng lần
  // (xem log thực tế: "onError: aborted" ngay lập tức bất kể tự động hay
  // bấm tay). Mục đích: kiểm chứng máy CÓ ghi được âm thanh hay không, để
  // sau này nếu ổn thì gửi file ghi được cho một AI khác (vd Gemini) nghe
  // và chuyển thành chữ — đường vòng khi trình duyệt tự nhận dạng không ăn
  // thua trên iOS.
  html.MediaStream? _luongGhiAm; // tái sử dụng qua NHIỀU thẻ liên tiếp.
  html.MediaRecorder? _boGhiAm; // recorder của thẻ ĐANG ghi hiện tại.
  bool _dangGhiAm = false;

  // ---- Ghi âm NHIỀU LẦN, chèn thành "thẻ" giữa các đoạn gõ tay (dành riêng
  // cho iPhone, nơi Web Speech API không hoạt động). Mỗi lần dừng ghi âm,
  // một token văn bản dạng "〔🎙️ Ghi âm N〕" được chèn vào đúng vị trí con
  // trỏ trong khung nhập — ĐÂY LÀ TOKEN VĂN BẢN THUẦN TUÝ, không phải ô
  // chip đồ hoạ thật, vì TextField của Flutter không hỗ trợ chèn widget vào
  // giữa văn bản có thể sửa. Khi bấm "Tạo văn bản", từng thẻ được thay bằng
  // đúng chữ Gemini phiên âm được từ file ghi âm tương ứng.
  int _soThuTuGhiAmTiepTheo = 1;
  final Map<int, html.Blob> _cacDoanGhiAmTheoThe = {};
  bool _dangTaoVanBan = false;
  static final RegExp _reTheGhiAm = RegExp('〔🎙️ Ghi âm (\\d+)〕');

  // ---- Đếm giờ hiển thị lúc đang ghi thẻ — hiển thị NGOÀI khung nhập (ở
  // hàng trạng thái), không nhét vào trong nội dung văn bản: TextField
  // không hỗ trợ widget sống động chèn giữa chữ có thể sửa, và việc tự động
  // ghi đè chữ mỗi giây vào đúng lúc người dùng có thể đang gõ tay ở chỗ
  // khác sẽ phá vỡ nguyên tắc gõ-phím-thắng-micro. Token trong văn bản vẫn
  // chỉ là placeholder tĩnh, chèn một lần duy nhất lúc BẮT ĐẦU ghi (xem
  // `_chenTheDangGhiVaoVanBan`), rồi được thay bằng "Thẻ ghi âm số N" khi
  // dừng.
  Timer? _bomDongHoGhiAm;
  Duration _thoiLuongDangGhi = Duration.zero;
  int? _viTriTokenDangGhi; // vị trí ký tự bắt đầu của token đang ghi dở.

  // Số thẻ đã DÀNH SẴN cho lần ghi đang chạy — gán NGAY lúc bắt đầu ghi
  // (không đợi tới lúc dữ liệu âm thanh sẵn sàng ở sự kiện 'stop', vốn bất
  // đồng bộ), để việc CHỐT thẻ (do bấm dừng tay, hoặc do gõ phím giữa
  // chừng) có thể đổi ngay token hiển thị trong văn bản mà không phải chờ.
  int? _soTheDangGhiHienTai;
  static const String _tenTokenDangGhi = '〔🎙️ … đang ghi âm …〕';

  // Đếm số lần lỗi liên tiếp KHÔNG kèm bất kỳ chữ nào (không có partial nào
  // trước khi lỗi) — dấu hiệu bộ nhận dạng bị chặn ngay từ đầu chứ không
  // phải lỗi tạm thời giữa chừng. Thấy thật trên iPhone (Safari/WebKit):
  // liên tục "onError: aborted" ngay sau "onStatus: listening", lặp hàng
  // chục lần một giây — nhiều khả năng do WebKit trên iOS đòi hỏi mỗi lần
  // bắt đầu nhận dạng phải xuất phát trực tiếp từ một cử chỉ bấm tay của
  // người dùng (không cho tự động bật lại bằng Timer như Android/PC vẫn
  // làm được). Dừng vòng lặp lại càng sớm càng tốt để khỏi xả pin/CPU vô
  // ích và báo rõ cho người dùng biết thay vì im lặng treo.
  int _soLanLoiLienTiepKhongChu = 0;
  static const _nguongDungTuBatLai = 4;

  @override
  void initState() {
    super.initState();
    _thietBi = _doanThietBi();
    _ghiLog('Phiên bản bản thử: $_phienBanThuNghiem');
    _ghiLog('Đoán thiết bị: ${_tenThietBi(_thietBi)} '
        '(User-Agent: ${html.window.navigator.userAgent})');
    _khoiTao();
  }

  void _ghiLog(String dong) {
    final gio = DateTime.now();
    String hai(int n) => n.toString().padLeft(2, '0');
    final gioChuoi = '${hai(gio.hour)}:${hai(gio.minute)}:${hai(gio.second)}';
    if (!mounted) {
      _nhatKy.add('[$gioChuoi] $dong');
      return;
    }
    setState(() {
      _nhatKy.add('[$gioChuoi] $dong');
      if (_nhatKy.length > 300) _nhatKy.removeAt(0);
    });
    // Cuộn xuống dòng mới nhất sau khi khung vẽ lại.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cuonNhatKy.hasClients) {
        _cuonNhatKy.jumpTo(_cuonNhatKy.position.maxScrollExtent);
      }
    });
  }

  Future<void> _khoiTao() async {
    final duoc = await _micro.initialize(
      onStatus: _khiDoiTrangThai,
      onError: _khiCoLoi,
      debugLogging: false,
    );
    if (!mounted) return;
    setState(() {
      _sanSang = duoc;
      if (!duoc) {
        _loi = 'Trình duyệt không cấp được quyền micro/không hỗ trợ '
            'Web Speech API. Thử Chrome hoặc Edge, và bật quyền micro cho '
            'trang này.';
      }
    });
    _ghiLog('Khởi tạo micro: ${duoc ? "được" : "THẤT BẠI"}');
  }

  void _khiCoLoi(dynamic loi) {
    // Trên web, một lượt bộ nhận dạng tự ngắt vì im lặng cũng có thể bắn ra
    // qua onError tuỳ trình duyệt — coi các mã "nhẹ" như bên Android, không
    // làm phiền, cứ tự bật lại.
    final maLoi = loi.errorMsg as String? ?? '';
    final nhe = maLoi == 'error_no_match' ||
        maLoi == 'error_speech_timeout' ||
        maLoi == 'error_client' ||
        maLoi == 'error_busy';
    _ghiLog('onError: $maLoi ${nhe ? "(nhẹ, tự bật lại)" : "(HIỂN THỊ ĐỎ)"}');
    if (!nhe && mounted) {
      setState(() => _loi = 'Lỗi: $maLoi');
    }

    _soLanLoiLienTiepKhongChu++;
    if (_soLanLoiLienTiepKhongChu >= _nguongDungTuBatLai) {
      // Đã thử tự bật lại nhiều lần liên tiếp mà lần nào cũng lỗi ngay lập
      // tức, không có lấy một chữ nào — dừng hẳn vòng lặp, không đoán mò
      // thêm nữa, để người dùng biết mà tự bấm lại bằng tay.
      _ghiLog('Lỗi liên tiếp $_soLanLoiLienTiepKhongChu lần không kèm chữ '
          'nào — dừng tự bật lại micro. Có thể ${_tenThietBi(_thietBi)} '
          'không cho tự động bật micro mà cần người dùng tự bấm nút mỗi '
          'lần.');
      _henBatLai?.cancel();
      _muonNghe = false;
      if (mounted) {
        setState(() {
          _dangNghe = false;
          _loi = 'Micro liên tục bị lỗi "$maLoi" ngay khi vừa bật, không '
              'nói được câu nào. Có thể trình duyệt này không cho tự động '
              'bật lại micro — hãy bấm nút micro lại bằng tay sau mỗi câu.';
        });
      }
      return;
    }
    _henNgheLai();
  }

  void _khiDoiTrangThai(String trangThai) {
    _ghiLog('onStatus: $trangThai');
    final dangChay = trangThai == SpeechToText.listeningStatus;
    if (mounted && _dangNghe != dangChay) {
      setState(() => _dangNghe = dangChay);
    }
    if (!dangChay) {
      // Phiên vừa chết (trình duyệt tự dừng do im lặng, hoặc do web speech
      // API không hỗ trợ nghe liên tục dài như Android) — tăng số phiên NGAY,
      // đồng bộ, để mọi kết quả trễ của phiên cũ bị vứt (LỚP 1).
      _phienHienTai++;
      _henNgheLai();
    }
  }

  /// Y hệt `_henBatLai()` bên app chính: nếu người dùng vẫn đang muốn nghe mà
  /// phiên vừa tự ngắt (đặc điểm hay gặp trên web — Web Speech API không giữ
  /// phiên mở liên tục như Android), tự bật lại ngay để trải nghiệm như micro
  /// luôn bật.
  void _henNgheLai() {
    if (!_muonNghe) return;
    _henBatLai?.cancel();
    // Điện thoại (Android/iPhone) có xu hướng tự ngắt phiên dày hơn PC — bật
    // lại nhanh hơn một chút để đỡ hụt tiếng nói giữa hai phiên.
    final treDoiChoDo = Duration(
      milliseconds: _thietBi == ThietBi.pc ? 300 : 150,
    );
    _henBatLai = Timer(treDoiChoDo, () {
      if (_muonNghe && !_micro.isListening) _batNghe();
    });
  }

  Future<void> _batNghe() async {
    if (!_sanSang) return;
    final idPhien = ++_phienHienTai;
    _rawTruocDoTrongPhien = '';
    _ghiLog('Bắt đầu phiên nghe #$idPhien (${_tenThietBi(_thietBi)})');
    try {
      await _micro.listen(
        onResult: (ketQua) {
          if (idPhien != _phienHienTai) {
            _ghiLog('Bỏ callback trễ của phiên cũ #$idPhien '
                '(phiên hiện tại là #$_phienHienTai)');
            return;
          }
          _khiCoKetQua(ketQua);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
        // Web Speech API không đảm bảo tôn trọng listenFor/pauseFor giống
        // Android (một số trình duyệt tự ngắt sớm hơn) — cứ khai để không
        // khác app chính, nhưng thiết kế phải chịu được việc trình duyệt
        // ngắt bất cứ lúc nào (_henNgheLai phía trên lo việc đó).
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 8),
      );
    } catch (loi) {
      _ghiLog('listen() ném lỗi: $loi');
      _henNgheLai();
    }
  }

  Future<void> _tatNghe() async {
    _phienHienTai++; // Phiên hiện tại coi như chết ngay (LỚP 1).
    _muonNghe = false;
    _henBatLai?.cancel();
    await _micro.cancel();
    if (mounted) setState(() => _dangNghe = false);
    _ghiLog('Người dùng tắt micro.');
  }

  void _bamNutMicro() {
    // Trên iPhone, Web Speech API không hoạt động kể cả bấm tay (xem log
    // "onError: aborted" lặp lại) — nút micro chính vì thế chuyển hẳn sang
    // cơ chế ghi-âm-rồi-gửi-Gemini (đúng nút "ghi âm" bên dưới), để người
    // dùng iPhone không cần biết có hai nút khác nhau.
    if (_thietBi == ThietBi.iphone) {
      _bamNutGhiAm();
      return;
    }
    if (_muonNghe) {
      _tatNghe();
    } else {
      _soLanLoiLienTiepKhongChu = 0; // người dùng tự bấm — cho thử lại từ đầu.
      setState(() {
        _muonNghe = true;
        _loi = '';
      });
      _batNghe();
    }
  }

  // ------------------------------------------------ ghi âm thô theo thẻ

  Future<void> _bamNutGhiAm() async {
    if (_dangGhiAm) {
      _dungHanGhiAm();
      return;
    }
    // Tắt hẳn vòng Web Speech API trước khi ghi âm thô — hai bên cùng
    // tranh giành một microphone có thể làm hỏng/im tiếng bản ghi. Ghi âm
    // thử cần độc chiếm mic để kết quả đáng tin.
    _henBatLai?.cancel();
    _henMoLaiMicroSauKhiGo?.cancel();
    _muonNghe = false;
    await _micro.cancel();
    if (mounted) setState(() => _dangNghe = false);

    final thietBiMedia = html.window.navigator.mediaDevices;
    if (thietBiMedia == null) {
      _ghiLog('Trình duyệt không hỗ trợ getUserMedia (ghi âm).');
      setState(() => _loi = 'Trình duyệt này không hỗ trợ ghi âm.');
      return;
    }
    try {
      _luongGhiAm = await thietBiMedia.getUserMedia({'audio': true});
      setState(() {
        _dangGhiAm = true;
        _loi = '';
      });
      _batDauMotThe();
      _ghiLog('Bắt đầu ghi âm thử (không qua Web Speech API).');
    } catch (e) {
      _ghiLog('Lỗi khi xin quyền/ghi âm: $e');
      if (mounted) setState(() => _loi = 'Không ghi âm được: $e');
    }
  }

  /// Bắt đầu MỘT PHIÊN `MediaRecorder` mới trên `_luongGhiAm` đã xin quyền
  /// sẵn — dùng cả lúc bấm nút ghi lần đầu VÀ lúc tách thẻ giữa chừng do gõ
  /// tay (xem `_chotTheDoGoTayVaBatDauTheMoi`). Số thẻ được DÀNH SẴN ngay
  /// tại đây, KHÔNG đợi tới lúc dữ liệu âm thanh sẵn sàng (sự kiện 'stop'
  /// bất đồng bộ) — nhờ vậy lúc cần chốt thẻ có thể đổi ngay token hiển thị
  /// mà không phải chờ, tránh đúng lỗi "token rác" đã gặp trước đây.
  void _batDauMotThe() {
    _taoBoGhiAmMoi();
    _chenTokenDangGhiVaoVanBan();
  }

  /// Phần LÕI của `_batDauMotThe` — chỉ tạo `MediaRecorder` mới và dành sẵn
  /// số thẻ, KHÔNG động gì tới văn bản. Tách riêng để dùng trong
  /// `_chotTheDoGoTayVaBatDauTheMoi`, nơi việc chèn token mới phải nằm
  /// CHUNG một lượt cập nhật văn bản DUY NHẤT với việc chốt token cũ (xem
  /// chú thích ở đó) — gọi `_chenTokenDangGhiVaoVanBan` riêng ở đây sẽ tạo
  /// thêm một lượt `.value=`/`onChanged` thứ hai, đúng nguyên nhân gây lỗi
  /// "phải gõ hai ký tự mới tách thẻ" đã gặp.
  void _taoBoGhiAmMoi() {
    final luong = _luongGhiAm;
    if (luong == null) return;
    // Safari/WebKit KHÔNG hỗ trợ 'audio/webm' (mặc định của Chrome) — nếu
    // ép ghi/gói bằng webm trên Safari, trình duyệt vẫn "ghi" được (không
    // báo lỗi) nhưng dữ liệu thực chất ở định dạng khác, khiến thẻ <audio>
    // không giải mã nổi và IM LẶNG không báo lỗi gì. Dò định dạng trình
    // duyệt THỰC SỰ hỗ trợ trước khi ghi.
    const cacDinhDangUuTien = [
      'audio/mp4',
      'audio/webm',
      'audio/ogg',
      'audio/wav',
    ];
    String? dinhDangDung;
    for (final dd in cacDinhDangUuTien) {
      if (html.MediaRecorder.isTypeSupported(dd)) {
        dinhDangDung = dd;
        break;
      }
    }
    final boGhi = dinhDangDung == null
        ? html.MediaRecorder(luong)
        : html.MediaRecorder(luong, {'mimeType': dinhDangDung});
    final soThe = _soThuTuGhiAmTiepTheo++;
    final doanGhi = <html.Blob>[];
    _boGhiAm = boGhi;
    _soTheDangGhiHienTai = soThe;
    boGhi.addEventListener('dataavailable', (suKien) {
      final doan = (suKien as html.BlobEvent).data;
      if (doan != null && doan.size > 0) doanGhi.add(doan);
    });
    // Listener này CHỈ lưu blob vào đúng số thẻ đã dành sẵn — KHÔNG động gì
    // tới văn bản nữa, vì token hiển thị đã được đổi thành "Ghi âm N" NGAY
    // LÚC CHỐT (đồng bộ, xem `_dungHanGhiAm`/`_chotTheDoGoTayVaBatDauTheMoi`)
    // chứ không đợi tới đây — sự kiện 'stop' luôn tới SAU (bất đồng bộ),
    // nên nếu vẫn còn động vào văn bản ở đây sẽ chèn sai vị trí (đúng lỗi
    // "token rác"/"chèn thẻ lộn xộn" đã gặp trước đây).
    boGhi.addEventListener('stop', (_) {
      final loaiThuc = boGhi.mimeType;
      final blob = html.Blob(doanGhi,
          (loaiThuc == null || loaiThuc.isEmpty) ? 'audio/mp4' : loaiThuc);
      _cacDoanGhiAmTheoThe[soThe] = blob;
      _ghiLog('Thẻ #$soThe: ghi xong (${doanGhi.length} đoạn dữ liệu).');
    });
    boGhi.start();
    _ghiLog('MediaRecorder.mimeType thực tế: "${boGhi.mimeType}" (thẻ #$soThe).');
    _thoiLuongDangGhi = Duration.zero;
    _bomDongHoGhiAm?.cancel();
    _bomDongHoGhiAm = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _thoiLuongDangGhi += const Duration(seconds: 1));
    });
  }

  /// Ghi [vanBanMoi] vào khung nhập VÀ chốt cứng nó ngay tại đây — dùng cho
  /// MỌI chỉnh sửa văn bản do CHÍNH CODE (không phải người dùng) thực hiện
  /// xoay quanh cơ chế thẻ ghi âm (chèn/thay/xoá token).
  ///
  /// QUAN TRỌNG: gán `TextEditingController.value =` theo cách lập trình
  /// KHÔNG khiến `TextField.onChanged` (do đó `_khiNguoiDungGoPhim`) tự
  /// chạy — khác với suy đoán ban đầu ở các bản trước. Bằng chứng thực tế
  /// (log v21): token "đang ghi âm" được chèn lúc 17:30:13, nhưng dòng log
  /// đáng lẽ phải in ra NGAY SAU đó (nếu `onChanged` chạy lại) chỉ thực sự
  /// xuất hiện lúc 17:30:17 — đúng thời điểm người dùng gõ phím THẬT tiếp
  /// theo. Nghĩa là `onChanged` không hề chạy lại cho lần gán `.value=` đó;
  /// cờ "bỏ qua một lần" ở các bản trước vì vậy nằm chờ mãi và vô tình NUỐT
  /// MẤT đúng lượt gõ phím thật kế tiếp — đó là lý do phải gõ hai lần mới
  /// thấy thẻ tách ra. Sửa bằng cách bỏ hẳn cơ chế cờ, và tự chốt cứng
  /// trạng thái NGAY TẠI ĐÂY thay vì trông chờ một `onChanged` không tồn
  /// tại.
  void _ghiVanBanChoTheVaChotCung(String vanBanMoi, TextSelection luaChonMoi) {
    _boDieuKhienVanBan.value =
        TextEditingValue(text: vanBanMoi, selection: luaChonMoi);
    _vanBan = vanBanMoi;
    _vanBanDaChot = vanBanMoi;
    _tuDaChot = _tachTu(vanBanMoi);
    _partialTruocDo = [];
    _rawTruocDoTrongPhien = '';
  }

  /// Chèn token tĩnh "đang ghi âm" tại vị trí con trỏ HIỆN TẠI. Ghi lại vị
  /// trí ký tự để lúc chốt thẻ (dừng tay hoặc gõ phím) thay ĐÚNG token này
  /// bằng "〔🎙️ Ghi âm N〕", không chèn thêm token mới sai chỗ.
  void _chenTokenDangGhiVaoVanBan() {
    final vanBanCu = _boDieuKhienVanBan.text;
    var viTri = _boDieuKhienVanBan.selection.baseOffset;
    if (viTri < 0 || viTri > vanBanCu.length) viTri = vanBanCu.length;
    final vanBanMoi = vanBanCu.replaceRange(viTri, viTri, _tenTokenDangGhi);
    _viTriTokenDangGhi = viTri;
    _ghiVanBanChoTheVaChotCung(
      vanBanMoi,
      TextSelection.collapsed(offset: viTri + _tenTokenDangGhi.length),
    );
    _ghiLog('Chèn token "đang ghi âm" tại vị trí ký tự $viTri (thẻ '
        '#$_soTheDangGhiHienTai).');
  }

  /// Bấm nút dừng bằng tay: CHỐT thẻ đang ghi thành "〔🎙️ Ghi âm N〕" và
  /// dừng HẲN — không ghi tiếp, không có thẻ mới nào được tạo ra.
  void _dungHanGhiAm() {
    final soThe = _soTheDangGhiHienTai;
    _bomDongHoGhiAm?.cancel();
    _bomDongHoGhiAm = null;
    if (soThe != null) _chenTheGhiAmVaoVanBan(soThe);
    _boGhiAm?.stop();
    _boGhiAm = null;
    _soTheDangGhiHienTai = null;
    for (final track in _luongGhiAm?.getTracks() ?? const []) {
      track.stop();
    }
    _luongGhiAm = null;
    if (mounted) setState(() => _dangGhiAm = false);
    _ghiLog('Dừng ghi âm theo yêu cầu — đã chốt thẻ #$soThe.');
  }

  /// Người dùng gõ tay trong lúc thẻ đang ghi dở: đúng nguyên tắc "gõ tay
  /// luôn luôn thắng micro kể cả đang ghi âm", nhưng ở đây "thắng" nghĩa là
  /// CHỐT NGAY thẻ đang ghi thành thẻ hoàn chỉnh tại đúng vị trí cũ (trước
  /// ký tự vừa gõ), rồi bắt đầu một thẻ MỚI ngay sau chỗ vừa gõ để ghi âm
  /// tiếp tục liền mạch — KHÔNG làm mất bản ghi, chỉ tách nó thành hai thẻ.
  /// Dùng lại đúng `_luongGhiAm` đã xin quyền, không xin lại từ đầu.
  ///
  /// [vanBanSauKhiGo] là văn bản NGAY SAU khi ký tự vừa gõ đã được chèn vào
  /// (tham số gốc của `_khiNguoiDungGoPhim`). Toàn bộ việc chốt token cũ +
  /// giữ ký tự vừa gõ + chèn token mới được dựng thành MỘT chuỗi văn bản
  /// DUY NHẤT rồi gán `.value=` ĐÚNG MỘT LẦN, và trạng thái (`_vanBanDaChot`
  /// v.v.) được chốt cứng NGAY TẠI ĐÂY qua `_ghiVanBanChoTheVaChotCung` —
  /// xem chú thích ở hàm đó để biết vì sao KHÔNG được trông chờ một
  /// `onChanged` chạy lại sau khi gán `.value=`.
  void _chotTheDoGoTayVaBatDauTheMoi(String vanBanSauKhiGo) {
    if (!_dangGhiAm) return;
    final soTheCu = _soTheDangGhiHienTai;
    final viTriTokenCu = _viTriTokenDangGhi;
    final viTriConTro = _boDieuKhienVanBan.selection.baseOffset;
    final sauTokenCu = viTriTokenCu == null
        ? null
        : viTriTokenCu + _tenTokenDangGhi.length;

    if (soTheCu == null ||
        viTriTokenCu == null ||
        sauTokenCu == null ||
        sauTokenCu > vanBanSauKhiGo.length ||
        vanBanSauKhiGo.substring(viTriTokenCu, sauTokenCu) !=
            _tenTokenDangGhi ||
        viTriConTro < 0 ||
        viTriConTro < sauTokenCu) {
      // Không rơi đúng vào ca thường gặp (gõ ngay sau/tại vị trí token) —
      // ví dụ người dùng bấm con trỏ ra chỗ khác rồi gõ. Rơi về cách cũ:
      // chốt token cũ tại đúng vị trí lưu, rồi bắt đầu thẻ mới tại vị trí
      // con trỏ hiện tại (hai lượt cập nhật riêng, chấp nhận độ trễ này ở
      // ca hiếm gặp).
      _ghiLog('Người dùng gõ tay trong lúc đang ghi thẻ #$soTheCu, không '
          'phải ngay sau token — dùng đường xử lý chung (hai lượt).');
      if (soTheCu != null) _chenTheGhiAmVaoVanBan(soTheCu);
      _boGhiAm?.stop();
      _batDauMotThe();
      return;
    }

    _ghiLog('Người dùng gõ tay trong lúc đang ghi thẻ #$soTheCu — chốt '
        'ngay thành thẻ hoàn chỉnh, bắt đầu thẻ MỚI tiếp tục ghi ngay sau '
        'chỗ vừa gõ (một lượt cập nhật văn bản duy nhất).');

    final theCu = '〔🎙️ Ghi âm $soTheCu〕';
    final truocToken = vanBanSauKhiGo.substring(0, viTriTokenCu);
    // Phần nằm giữa hết token cũ và vị trí con trỏ hiện tại — chính là ký
    // tự (hoặc các ký tự) người dùng vừa gõ.
    final phanVuaGo = vanBanSauKhiGo.substring(sauTokenCu, viTriConTro);
    final phanConLai = vanBanSauKhiGo.substring(viTriConTro);
    final vanBanKetQua =
        '$truocToken$theCu$phanVuaGo$_tenTokenDangGhi$phanConLai';
    final conTroMoi =
        truocToken.length + theCu.length + phanVuaGo.length + _tenTokenDangGhi.length;

    _ghiVanBanChoTheVaChotCung(
      vanBanKetQua,
      TextSelection.collapsed(offset: conTroMoi),
    );

    _boGhiAm?.stop(); // 'stop' sẽ tới sau, chỉ để lưu blob vào thẻ #$soTheCu.
    _taoBoGhiAmMoi(); // thẻ mới — KHÔNG chèn token nữa, đã chèn ở trên rồi.
    _viTriTokenDangGhi = truocToken.length + theCu.length + phanVuaGo.length;
  }

  /// Thay ĐÚNG token tĩnh "đang ghi âm" (chèn lúc bắt đầu ghi, xem
  /// `_chenTokenDangGhiVaoVanBan`) bằng "〔🎙️ Ghi âm N〕", GIỮ NGUYÊN vị trí
  /// tương đối của con trỏ so với phần văn bản NẰM SAU token (ví dụ dấu
  /// phẩy người dùng vừa gõ ngay sau token) — nếu không giữ, con trỏ sẽ bị
  /// nhảy lùi về trước ký tự vừa gõ, đúng lỗi đã gặp. Nếu vì lý do gì đó
  /// không còn tìm thấy token đó nữa (người dùng đã xoá/sửa nó), rơi về
  /// hành vi cũ: chèn thẻ mới tại vị trí con trỏ hiện tại.
  void _chenTheGhiAmVaoVanBan(int soThe) {
    final the = '〔🎙️ Ghi âm $soThe〕';
    final vanBanCu = _boDieuKhienVanBan.text;
    final viTriToken = _viTriTokenDangGhi;
    final chonCu = _boDieuKhienVanBan.selection;
    _viTriTokenDangGhi = null;
    if (viTriToken != null &&
        viTriToken >= 0 &&
        viTriToken + _tenTokenDangGhi.length <= vanBanCu.length &&
        vanBanCu.substring(viTriToken, viTriToken + _tenTokenDangGhi.length) ==
            _tenTokenDangGhi) {
      final vanBanMoi = vanBanCu.replaceRange(
          viTriToken, viTriToken + _tenTokenDangGhi.length, the);
      final ketThucTokenCu = viTriToken + _tenTokenDangGhi.length;
      final lech = the.length - _tenTokenDangGhi.length;
      int dichChuyen(int viTri) {
        if (viTri >= ketThucTokenCu) return viTri + lech;
        if (viTri <= viTriToken) return viTri;
        return viTriToken + the.length; // rơi giữa token cũ (hiếm) — đẩy ra sau.
      }
      final baseMoi = chonCu.baseOffset < 0
          ? viTriToken + the.length
          : dichChuyen(chonCu.baseOffset);
      final extentMoi =
          chonCu.extentOffset < 0 ? baseMoi : dichChuyen(chonCu.extentOffset);
      _ghiVanBanChoTheVaChotCung(
        vanBanMoi,
        TextSelection(baseOffset: baseMoi, extentOffset: extentMoi),
      );
      _ghiLog('Thay token "đang ghi âm" bằng thẻ #$soThe tại vị trí '
          '$viTriToken (giữ con trỏ ở $baseMoi).');
      return;
    }
    var viTri = _boDieuKhienVanBan.selection.baseOffset;
    if (viTri < 0 || viTri > vanBanCu.length) viTri = vanBanCu.length;
    final vanBanMoi = vanBanCu.replaceRange(viTri, viTri, the);
    _ghiVanBanChoTheVaChotCung(
      vanBanMoi,
      TextSelection.collapsed(offset: viTri + the.length),
    );
    _ghiLog('Chèn thẻ ghi âm #$soThe vào văn bản tại vị trí ký tự $viTri '
        '(không tìm thấy token "đang ghi âm" — có thể đã bị xoá/sửa).');
  }

  // `_bamNutNgheLai`/`_taiXuongGhiAm` (nút "Nghe lại"/"Tải xuống") đã bỏ từ
  // v19 — cơ chế ghi âm đã kiểm chứng hoạt động đúng qua nhiều bản thử,
  // không cần công cụ kiểm tra nhanh này nữa; thẻ `<audio>` để nghe lại
  // cũng bỏ theo từ v20 (không còn nút nào gọi tới nó).

  /// Đọc [blob] thành chuỗi base64 thuần (không kèm tiền tố
  /// "data:...;base64,") — dùng FileReader vì Blob trên web không có sẵn
  /// phương thức đồng bộ để lấy bytes.
  Future<String> _doiBlobSangBase64(html.Blob blob) {
    final doc = html.FileReader();
    final xong = Completer<String>();
    doc.onLoadEnd.listen((_) {
      final ketQua = doc.result as String;
      final viTriPhay = ketQua.indexOf(',');
      xong.complete(viTriPhay >= 0 ? ketQua.substring(viTriPhay + 1) : ketQua);
    });
    doc.onError.listen((e) => xong.completeError(e));
    doc.readAsDataUrl(blob);
    return xong.future;
  }

  /// Nút "Tạo văn bản": quét toàn bộ văn bản tìm các thẻ "〔🎙️ Ghi âm N〕",
  /// gửi từng file ghi âm tương ứng cho máy chủ trung gian AI (action
  /// 'ghi_am' — đã có sẵn, xem cloud-function/index.js, app Android cũng
  /// đang dùng chung), rồi thay ĐÚNG mỗi thẻ bằng chữ Gemini phiên âm được,
  /// giữ nguyên các phần chữ gõ tay xen kẽ xung quanh.
  Future<void> _taoVanBanTuTheGhiAm() async {
    if (_dangTaoVanBan) return;
    var vanBanHienTai = _boDieuKhienVanBan.text;
    // Lưới an toàn: đáng lẽ không còn token "đang ghi âm" nào sót lại (mọi
    // lần chốt thẻ — dừng tay hoặc gõ phím giữa chừng — đều thay token
    // ngay, đồng bộ, xem `_dungHanGhiAm`/`_chotTheDoGoTayVaBatDauTheMoi`),
    // nhưng nếu vẫn còn (ví dụ lỗi chưa lường hết) thì dọn sạch trước khi
    // gửi, đừng để nó lọt vào văn bản cuối cùng dưới dạng chữ vô nghĩa.
    if (vanBanHienTai.contains(_tenTokenDangGhi)) {
      _ghiLog('Cảnh báo: còn sót token "đang ghi âm" trong văn bản — dọn '
          'trước khi tạo văn bản.');
      vanBanHienTai = vanBanHienTai.replaceAll(_tenTokenDangGhi, '');
    }
    final cacKhop = _reTheGhiAm.allMatches(vanBanHienTai).toList();
    if (cacKhop.isEmpty) {
      _ghiLog('Không có thẻ ghi âm nào trong văn bản để gửi.');
      return;
    }

    setState(() => _dangTaoVanBan = true);
    _ghiLog('Bắt đầu gửi ${cacKhop.length} thẻ ghi âm cho Gemini phiên âm…');

    // Thay TỪ CUỐI VĂN BẢN VỀ ĐẦU — để vị trí ký tự (đo trên văn bản GỐC,
    // trước khi thay bất kỳ thẻ nào) của các thẻ CHƯA xử lý luôn còn đúng,
    // vì mọi thay thế trước đó chỉ động vào phần văn bản NẰM SAU vị trí của
    // chúng.
    var vanBanMoi = vanBanHienTai;
    for (final khop in cacKhop.toList().reversed) {
      final soThe = int.parse(khop.group(1)!);
      final blob = _cacDoanGhiAmTheoThe[soThe];
      if (blob == null) {
        _ghiLog('  Thẻ #$soThe: không còn dữ liệu ghi âm (đã bị thay/xoá '
            'trước đó?) — bỏ qua.');
        continue;
      }
      try {
        final base64 = await _doiBlobSangBase64(blob);
        _ghiLog('  Thẻ #$soThe: đã mã hoá xong, đang gửi…');
        final phanHoi = await http
            .post(
              Uri.parse(diaChiMayChuAI),
              headers: {
                'content-type': 'application/json',
                'x-flowrite-secret': matKhauMayChuAI,
              },
              body: jsonEncode({
                'action': 'ghi_am',
                'audioBase64': base64,
                'mimeType': blob.type.isNotEmpty ? blob.type : 'audio/mp4',
              }),
            )
            .timeout(const Duration(minutes: 3));
        if (phanHoi.statusCode != 200) {
          throw Exception(
              'Máy chủ AI trả về lỗi ${phanHoi.statusCode}: ${phanHoi.body}');
        }
        final goc =
            jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
        final chu = (goc['text'] as String?)?.trim();
        if (chu == null || chu.isEmpty) {
          throw Exception(
              goc['loi']?.toString() ?? 'Không có nội dung trả về.');
        }
        vanBanMoi = vanBanMoi.replaceRange(khop.start, khop.end, chu);
        _ghiLog('  Thẻ #$soThe: xong — "$chu"');
      } catch (e) {
        _ghiLog('  Thẻ #$soThe: LỖI — $e');
      }
    }

    _vanBanDaChot = vanBanMoi;
    _tuDaChot = _tachTu(vanBanMoi);
    _ghiVanBanTuMicro(vanBanMoi);
    if (mounted) setState(() => _dangTaoVanBan = false);
    _ghiLog('Hoàn tất tạo văn bản từ các thẻ ghi âm.');
  }

  /// Gắn vào `onChanged` của khung kết quả — NGUYÊN TẮC gõ-phím-thắng-micro,
  /// y hệt tinh thần `_nguoiDungVuaGo()` bên app chính: gõ một phím là micro
  /// tắt NGAY LẬP TỨC (không đợi micro nói xong đoạn dở dang), và tự bật lại
  /// sau 1 giây không gõ tiếp — không cần bấm nút bật lại bằng tay.
  ///
  /// Chỉ coi là "người dùng gõ" khi thay đổi này KHÔNG phải do chính code tự
  /// ghi vào (`_dangGhiTuMicro`) — nếu không sẽ tắt oan micro mỗi khi chính
  /// micro cập nhật chữ.
  void _khiNguoiDungGoPhim(String vanBanMoi) {
    if (_dangGhiTuMicro) return;
    if (_dangGhiAm) {
      // Người dùng gõ tay thật trong lúc thẻ đang ghi dở — gõ tay luôn
      // thắng micro, nhưng ở đây "thắng" nghĩa là CHỐT NGAY thẻ đang ghi
      // rồi bắt đầu thẻ MỚI tiếp tục ghi (không huỷ/mất bản ghi). Hàm này
      // tự chốt cứng trạng thái ngay bên trong nó (xem
      // `_ghiVanBanChoTheVaChotCung`) — KHÔNG xử lý tiếp `vanBanMoi` ở dưới
      // nữa, kẻo ghi đè lên đúng kết quả vừa cập nhật.
      _chotTheDoGoTayVaBatDauTheMoi(vanBanMoi);
      return;
    }
    _vanBan = vanBanMoi;
    // Coi toàn bộ chữ hiện có (kể cả phần vừa gõ tay, NGUYÊN VĂN không bị
    // tách-rồi-nối lại) là đã "chốt cứng", để khi micro bật lại nó nối tiếp
    // sau đúng chỗ người dùng vừa gõ mà không đè lên, xoá mất, hay làm mất
    // định dạng (xuống dòng, khoảng trắng) người dùng tự gõ.
    _vanBanDaChot = vanBanMoi;
    _tuDaChot = _tachTu(vanBanMoi);
    _partialTruocDo = [];
    _rawTruocDoTrongPhien = '';
    _ghiLog('Người dùng gõ tay — tắt micro ngay, tự bật lại sau 1 giây '
        'nếu không gõ tiếp.');
    _ngatMicroNgayViGoPhim();
  }

  Future<void> _ngatMicroNgayViGoPhim() async {
    _henMoLaiMicroSauKhiGo?.cancel();
    _henBatLai?.cancel();
    _phienHienTai++; // Huỷ callback của phiên đang chạy dở (LỚP 1).
    await _micro.cancel();
    if (mounted && _dangNghe) setState(() => _dangNghe = false);
    _henMoLaiMicroSauKhiGo = Timer(const Duration(seconds: 1), () {
      if (_muonNghe && !_micro.isListening) _batNghe();
    });
  }

  /// Ghi văn bản do MICRO tạo ra vào cả `_vanBan` lẫn khung gõ, mà không để
  /// `_khiNguoiDungGoPhim` hiểu nhầm là người dùng gõ (dùng cờ chặn).
  void _ghiVanBanTuMicro(String vanBanMoi) {
    _dangGhiTuMicro = true;
    _vanBan = vanBanMoi;
    _boDieuKhienVanBan.value = TextEditingValue(
      text: vanBanMoi,
      selection: TextSelection.collapsed(offset: vanBanMoi.length),
    );
    _dangGhiTuMicro = false;
  }

  Future<void> _saoChepVanBan() async {
    final noiDung = _vanBan.isEmpty ? '(chưa có chữ nào)' : _vanBan;
    await Clipboard.setData(ClipboardData(text: noiDung));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép kết quả vào bộ nhớ tạm'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saoChepNhatKy() async {
    final noiDung = _nhatKy.isEmpty ? '(chưa có nhật ký)' : _nhatKy.join('\n');
    await Clipboard.setData(ClipboardData(text: noiDung));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép nhật ký vào bộ nhớ tạm'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Nhật ký giờ nằm trong modal riêng (mở bằng nút nhỏ cạnh micro) thay vì
  /// chiếm nguyên một khối trên trang — theo yêu cầu để khung nhập to ra.
  void _moModalNhatKy() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, capNhatModal) {
            return AlertDialog(
              title: const Text('Nhật ký'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Scrollbar(
                  controller: _cuonNhatKy,
                  child: SingleChildScrollView(
                    controller: _cuonNhatKy,
                    child: SelectableText(
                      _nhatKy.isEmpty
                          ? '(chưa có nhật ký)'
                          : _nhatKy.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _saoChepNhatKy,
                  child: const Text('Sao chép tất cả'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _nhatKy.clear());
                    capNhatModal(() {});
                  },
                  child: const Text('Xoá tất cả'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _doiCheDoThietBi(ThietBi moi) {
    if (moi == _thietBi) return;
    setState(() => _thietBi = moi);
    _ghiLog('Chuyển tay sang chế độ: ${_tenThietBi(moi)}');
  }

  // ------------------------------------------------------ thuật toán lõi

  // Chrome Android trả `recognizedWords` bị lặp lại TOÀN BỘ lịch sử của
  // phiên như tiền tố mỗi lần có kết quả mới (vd lần 3 gửi
  // "XinXin chàoXin chàoXin chào" thay vì chỉ "Xin chào") — mỗi lần lặp lại
  // luôn bắt đầu bằng chữ hoa. Quan sát log thực tế cho thấy: ĐOẠN CUỐI
  // CÙNG (tính từ lần chuyển chữ-thường-sang-chữ-hoa gần cuối chuỗi nhất)
  // luôn là bản ghi ĐẦY ĐỦ, SẠCH của toàn phiên tới thời điểm đó — không
  // lặp lại gì cả. Vì vậy chỉ cần cắt lấy đúng đoạn cuối này, bỏ hết phần
  // lặp lại dư thừa phía trước, là có được dữ liệu y hệt một partial bình
  // thường (giống PC) để đưa vào thuật toán tìm-điểm-nối bên dưới. Chỉ
  // dùng cho nhánh điện thoại — PC không có lỗi này nên không đụng tới.
  static const _chuThuongViet =
      'a-zàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const _chuHoaViet =
      'A-ZÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  static final RegExp _reRanhGioiDoanDinh =
      RegExp('[$_chuThuongViet][$_chuHoaViet]');

  /// Cắt lấy đoạn cuối cùng (từ lần chuyển chữ-thường→chữ-hoa gần cuối
  /// chuỗi nhất tới hết chuỗi) — đây là bản ghi sạch, không lặp.
  static String _catDoanCuoiCung(String s) {
    var viTri = 0;
    for (final m in _reRanhGioiDoanDinh.allMatches(s)) {
      viTri = m.start + 1;
    }
    return s.substring(viTri);
  }

  /// Nối [tuMoi] vào SAU [hienTai] theo đúng nguyên tắc "chỉ nối thêm,
  /// không dựng lại" — giữ NGUYÊN VĂN [hienTai] (kể cả dấu xuống dòng gõ
  /// tay), chỉ thêm dấu cách phân tách nếu [hienTai] chưa tự kết thúc bằng
  /// khoảng trắng/xuống dòng sẵn.
  static String _noiTiep(String hienTai, List<String> tuMoi) {
    if (tuMoi.isEmpty) return hienTai;
    final phanMoi = tuMoi.join(' ');
    if (hienTai.isEmpty) return phanMoi;
    if (hienTai.endsWith('\n') || hienTai.endsWith(' ')) {
      return '$hienTai$phanMoi';
    }
    return '$hienTai $phanMoi';
  }

  /// Tách chuỗi thành danh sách từ theo khoảng trắng — y hệt `_tachTu`.
  static List<String> _tachTu(String s) {
    final t = s.trim();
    if (t.isEmpty) return const [];
    return t.split(RegExp(r'\s+'));
  }

  /// Chuẩn hoá một từ để so khớp nới lỏng — y hệt `_chuanHoaSoKhopTho`.
  static String _chuanHoaTho(String tu) =>
      tu.toLowerCase().replaceAll(RegExp(r'[.,!?;:]+$'), '');

  static bool _khopTho(String a, String b) =>
      _chuanHoaTho(a) == _chuanHoaTho(b);

  /// Độ dài tiền tố chung khớp CHÍNH XÁC — y hệt `_doDaiTienToChung`.
  static int _doDaiTienToChung(List<String> a, List<String> b) {
    final n = a.length < b.length ? a.length : b.length;
    var i = 0;
    while (i < n && a[i] == b[i]) {
      i++;
    }
    return i;
  }

  /// [partialMoi] có bắt đầu bằng ĐÚNG toàn bộ [daChot] hay không — y hệt
  /// `_batDauBangPhanDaChot`.
  static bool _batDauBangPhanDaChot(
    List<String> partialMoi,
    List<String> daChot,
  ) {
    if (partialMoi.length < daChot.length) return false;
    for (var i = 0; i < daChot.length; i++) {
      if (!_khopTho(partialMoi[i], daChot[i])) return false;
    }
    return true;
  }

  /// Thuật toán "tìm điểm nối": thử N từ CUỐI của [daChot] (từ dài nhất có
  /// thể xuống 1), xem [partialMoi] có bắt đầu đúng bằng N từ đó không (so
  /// khớp nới lỏng). `null` = không tìm được, coi là nội dung mới hoàn
  /// toàn. `[]` = trùng nguyên văn N từ cuối, không có gì thêm (nhân đôi).
  /// khác = phần mới thật sự nằm sau điểm nối.
  ///
  /// KHÔNG giới hạn N ở 6 như bản gốc bên app chính (nơi cụm lặp trên
  /// Android luôn ngắn) — trên nhánh điện thoại của bản test này, cụm lặp
  /// do Chrome tự lặp lại có thể dài hơn 6 từ rất nhiều (xem log thực tế:
  /// "bị lặp lại từ của tôi Bởi vậy cho nên..." lặp nguyên cụm mỗi lần),
  /// giới hạn 6 làm bỏ lỡ điểm nối và gây nối nhầm nguyên cụm dài vào cuối.
  static List<String>? _timDiemNoiTrong(
    List<String> daChot,
    List<String> partialMoi,
  ) {
    final soDaChot = daChot.length;
    final maxN = soDaChot < partialMoi.length ? soDaChot : partialMoi.length;
    for (var n = maxN; n >= 1; n--) {
      if (partialMoi.length < n) continue;
      final duoiDaChot = daChot.sublist(soDaChot - n);
      var khop = true;
      for (var i = 0; i < n; i++) {
        if (!_khopTho(partialMoi[i], duoiDaChot[i])) {
          khop = false;
          break;
        }
      }
      if (khop) {
        if (partialMoi.length == n) return const [];
        return partialMoi.sublist(n);
      }
    }
    return null;
  }

  void _khiCoKetQua(dynamic ketQua) {
    final noi = (ketQua.recognizedWords as String? ?? '').trim();
    final xong = ketQua.finalResult as bool? ?? false;

    setState(() {
      if (xong) {
        _soLanFinal++;
      } else {
        _soLanPartial++;
      }
    });
    _ghiLog('${xong ? "FINAL" : "partial"}: "$noi"');

    if (noi.isEmpty) return;
    // Có chữ thật — bộ đếm lỗi-liên-tiếp-không-chữ hết ý nghĩa, xoá về 0.
    _soLanLoiLienTiepKhongChu = 0;

    switch (_thietBi) {
      case ThietBi.android:
        _xuLyKetQuaDienThoai(noi);
      case ThietBi.pc:
        _xuLyKetQuaPc(noi, xong);
      case ThietBi.iphone:
        _xuLyKetQuaIphone(noi, xong);
    }
  }

  /// Nhánh PC: dùng nguyên thuật toán "chốt dần theo độ ổn định" gốc — coi
  /// [noi] là TOÀN BỘ hypothesis đang tăng dần của bộ nhận dạng (đúng như
  /// Web Speech API trên PC hoạt động).
  void _xuLyKetQuaPc(String noi, bool xong) {
    final tuMoi = _tachTu(noi);
    if (tuMoi.isEmpty) return;

    // Phần từ CHƯA/MỚI cần hiển thị thêm sau `_vanBanDaChot` hiện tại —
    // không bao giờ dựng lại toàn bộ văn bản, chỉ nối thêm, để giữ nguyên
    // định dạng (xuống dòng...) người dùng có thể đã gõ tay trước đó.
    List<String> phanMoiCanNoi;
    if (_batDauBangPhanDaChot(tuMoi, _tuDaChot)) {
      final tienToChung = _doDaiTienToChung(tuMoi, _partialTruocDo);
      if (tienToChung > _tuDaChot.length) {
        // Chỉ đúng phần MỚI được coi là ổn định (tienToChung tăng thêm) mới
        // thật sự chốt cứng vào `_vanBanDaChot` — phần còn lại của tuMoi
        // (dưới đây) vẫn chỉ là xem trước, chưa ghi đè lên bản chốt.
        final tuMoiChotThem = tuMoi.sublist(_tuDaChot.length, tienToChung);
        _vanBanDaChot = _noiTiep(_vanBanDaChot, tuMoiChotThem);
        _tuDaChot = tuMoi.sublist(0, tienToChung);
      }
      phanMoiCanNoi = tuMoi.sublist(_tuDaChot.length);
    } else {
      final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
      if (ketQuaNoi == null) {
        phanMoiCanNoi = tuMoi;
      } else if (ketQuaNoi.isEmpty) {
        _partialTruocDo = tuMoi;
        return;
      } else {
        phanMoiCanNoi = ketQuaNoi;
      }
    }

    _partialTruocDo = tuMoi;
    final vanBanHienThi = _noiTiep(_vanBanDaChot, phanMoiCanNoi);
    setState(() => _ghiVanBanTuMicro(vanBanHienThi));

    if (xong) {
      // Kết quả FINAL: toàn bộ nội dung hiện có (kể cả phần xem trước) coi
      // là chốt cứng, giữ nguyên văn.
      _vanBanDaChot = vanBanHienThi;
      _tuDaChot = _tachTu(vanBanHienThi);
      _partialTruocDo = [];
    }
  }

  /// Nhánh iPhone: CHƯA có máy iOS thật để test (xem log v10 trở về trước —
  /// chỉ test được Android và PC/Mac). Trên iOS, mọi trình duyệt đều bị
  /// Apple ép dùng chung bộ máy WebKit của Safari — hoàn toàn khác bộ máy
  /// Chromium (Chrome/Edge) đang chạy trên Android và PC/Mac. Không có dữ
  /// liệu thật để biết WebKit có bị lỗi lặp-lịch-sử giống Chrome Android
  /// hay không.
  ///
  /// Tạm dùng NGUYÊN VẸN thuật toán của nhánh PC (`_xuLyKetQuaPc`) làm điểm
  /// khởi đầu — lý do chọn PC thay vì Android: thuật toán PC giả định bộ
  /// nhận dạng trả hypothesis tăng dần SẠCH (không tự lặp lại lịch sử), đây
  /// là hành vi "đúng chuẩn" của Web Speech API mà đa số trình duyệt tuân
  /// theo — lỗi lặp lịch sử là ĐẶC THÙ riêng của Chrome Android (xem thuật
  /// toán `_xuLyKetQuaDienThoai`), không có gì cho thấy WebKit trên iOS
  /// cũng mắc lỗi y hệt vậy. Tách thành hàm riêng (không gọi thẳng
  /// `_xuLyKetQuaPc`) để sau này có log/bằng chứng thật từ máy iPhone thì
  /// sửa riêng nhánh này mà không đụng tới nhánh PC đã test kỹ.
  void _xuLyKetQuaIphone(String noi, bool xong) {
    final tuMoi = _tachTu(noi);
    if (tuMoi.isEmpty) return;

    List<String> phanMoiCanNoi;
    if (_batDauBangPhanDaChot(tuMoi, _tuDaChot)) {
      final tienToChung = _doDaiTienToChung(tuMoi, _partialTruocDo);
      if (tienToChung > _tuDaChot.length) {
        final tuMoiChotThem = tuMoi.sublist(_tuDaChot.length, tienToChung);
        _vanBanDaChot = _noiTiep(_vanBanDaChot, tuMoiChotThem);
        _tuDaChot = tuMoi.sublist(0, tienToChung);
      }
      phanMoiCanNoi = tuMoi.sublist(_tuDaChot.length);
    } else {
      final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
      if (ketQuaNoi == null) {
        phanMoiCanNoi = tuMoi;
      } else if (ketQuaNoi.isEmpty) {
        _partialTruocDo = tuMoi;
        return;
      } else {
        phanMoiCanNoi = ketQuaNoi;
      }
    }

    _partialTruocDo = tuMoi;
    final vanBanHienThi = _noiTiep(_vanBanDaChot, phanMoiCanNoi);
    setState(() => _ghiVanBanTuMicro(vanBanHienThi));

    if (xong) {
      _vanBanDaChot = vanBanHienThi;
      _tuDaChot = _tachTu(vanBanHienThi);
      _partialTruocDo = [];
    }
  }

  /// Nhánh điện thoại: Chrome Android không gửi hypothesis tăng dần sạch —
  /// nó lặp lại lịch sử của CHÍNH PHIÊN NÀY làm tiền tố mỗi lần có kết quả
  /// mới, có lúc viết hoa đầu đoạn lặp (bắt được bằng `_catDoanCuoiCung`),
  /// có lúc KHÔNG (lặp giữa câu, toàn chữ thường — xem log thực tế: "rất"
  /// → "rấtrất là" → "rấtrất làrất là"...). Cách chắc ăn với CẢ HAI kiểu
  /// lặp: so sánh chuỗi thô của lần này với lần TRƯỚC trong cùng phiên —
  /// phần thêm vào luôn nằm ở cuối, vì bộ nhận dạng chỉ có APPEND, không
  /// bao giờ xoá. Lấy đúng phần đuôi mới đó rồi đưa vào tìm-điểm-nối để
  /// gộp vào nội dung đã chốt.
  void _xuLyKetQuaDienThoai(String noiGoc) {
    final noiDaCat = _catDoanCuoiCung(noiGoc);
    if (noiDaCat != noiGoc) {
      _ghiLog('  → cắt còn đoạn cuối sạch: "$noiDaCat"');
    }

    String phanMoi;
    if (_rawTruocDoTrongPhien.isNotEmpty &&
        noiDaCat.startsWith(_rawTruocDoTrongPhien)) {
      phanMoi = noiDaCat.substring(_rawTruocDoTrongPhien.length);
    } else {
      phanMoi = noiDaCat;
    }
    _rawTruocDoTrongPhien = noiDaCat;

    final tuMoi = _tachTu(phanMoi);
    if (tuMoi.isEmpty) return;
    _ghiLog('  → phần đuôi mới so với lần trước: "${tuMoi.join(' ')}"');

    final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
    List<String> tuThemVao;
    if (ketQuaNoi == null) {
      _ghiLog('  → không tìm được điểm nối, nối thẳng đuôi mới vào cuối');
      tuThemVao = tuMoi;
    } else if (ketQuaNoi.isEmpty) {
      _ghiLog('  → đuôi mới trùng hoàn toàn với phần đã chốt, bỏ qua');
      return;
    } else {
      _ghiLog('  → tìm được điểm nối, thêm ${ketQuaNoi.length} từ mới');
      tuThemVao = ketQuaNoi;
    }

    // Nhánh điện thoại không có FINAL đáng tin cậy — chốt cứng ngay mỗi lần
    // có nội dung mới, để không bao giờ mất chữ đã hiện ra. CHỈ NỐI THÊM
    // vào `_vanBanDaChot` (giữ nguyên văn, kể cả xuống dòng gõ tay), không
    // bao giờ dựng lại bằng join(' ') từ danh sách từ.
    _vanBanDaChot = _noiTiep(_vanBanDaChot, tuThemVao);
    _tuDaChot = _tachTu(_vanBanDaChot);
    setState(() => _ghiVanBanTuMicro(_vanBanDaChot));
  }

  @override
  void dispose() {
    _henBatLai?.cancel();
    _henMoLaiMicroSauKhiGo?.cancel();
    _bomDongHoGhiAm?.cancel();
    _micro.cancel();
    _cuonNhatKy.dispose();
    _boDieuKhienVanBan.dispose();
    for (final track in _luongGhiAm?.getTracks() ?? const []) {
      track.stop();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- giao diện

  @override
  Widget build(BuildContext context) {
    // Bàn phím ảo đang mở hay không: `viewInsets.bottom > 0` khi hệ điều
    // hành đẩy bàn phím lên. Lúc gõ tay, người dùng chỉ cần thấy khung nhập
    // — các hàng bên dưới (trạng thái nghe, dãy nút micro/ghi âm/nghe lại/
    // tải xuống, tên trang, bộ chọn thiết bị) không cần thiết và chỉ làm
    // khung nhập bị bóp nhỏ lại. Ẩn hẳn chúng khi bàn phím đang mở, để
    // khung nhập giãn ra chiếm trọn phần còn lại phía trên bàn phím.
    final banPhimDangMo = MediaQuery.of(context).viewInsets.bottom > 0;

    // Phím tắt Ctrl+G bật/tắt micro — CallbackShortcuts bọc NGOÀI Scaffold
    // nên vẫn bắt được dù đang focus vào khung nhập kết quả (Shortcuts đi
    // theo cây tổ tiên của focus hiện tại, không cần focus đúng widget này).
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG):
            () {
          if (_sanSang) _bamNutMicro();
        },
      },
      child: Focus(
        autofocus: true,
        // Không dùng AppBar nữa — tên trang giờ nằm trong thân trang (xem
        // bên dưới), theo đúng thứ tự người dùng yêu cầu: khung nhập lên
        // đầu, kế đến thanh micro/nhật ký, rồi mới tới tên trang và cuối
        // cùng là bộ chọn thiết bị.
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Các thông báo quan trọng (đang xin quyền / lỗi) vẫn cố
                  // tình đặt trên cùng — chỉ hiện khi thật sự cần, không
                  // choán chỗ lúc bình thường.
                  if (!_sanSang)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Đang khởi tạo micro… nếu trình duyệt hỏi quyền, '
                        'hãy chọn Cho phép.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  if (_loi.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _loi,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Khung nhập liệu — lên đầu tiên.
                  Row(
                    children: [
                      Tooltip(
                        message: 'Gõ tay được — gõ phím sẽ tắt micro ngay, '
                            'tự bật lại sau 1 giây',
                        child: const Text(
                          'Kết quả',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      if (_dangGhiAm)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fiber_manual_record,
                                  color: Colors.red, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Đang ghi: ${_thoiLuongDangGhi.inMinutes.toString().padLeft(2, '0')}:'
                                '${(_thoiLuongDangGhi.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      if (_dangTaoVanBan)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Tooltip(
                          message: 'Gửi tất cả thẻ 〔🎙️ Ghi âm…〕 trong văn '
                              'bản cho Gemini phiên âm, thay đúng vào chỗ '
                              'của từng thẻ',
                          child: TextButton(
                            onPressed: _taoVanBanTuTheGhiAm,
                            child: const Text('Tạo văn bản'),
                          ),
                        ),
                      TextButton(
                        onPressed: _saoChepVanBan,
                        child: const Text('Sao chép tất cả'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _boDieuKhienVanBan,
                        onChanged: _khiNguoiDungGoPhim,
                        inputFormatters: [_ChanSuaGiuaThe()],
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '(chưa có chữ nào — nói hoặc gõ vào đây)',
                        ),
                        style: const TextStyle(fontSize: 18, height: 1.5),
                      ),
                    ),
                  ),
                  if (!banPhimDangMo) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _dangNghe ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: _dangNghe ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(_dangNghe ? 'Đang nghe' : 'Không nghe'),
                      const Spacer(),
                      Text('PARTIAL: $_soLanPartial   FINAL: $_soLanFinal'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Thanh ngang chứa nút Xoá / Nhật ký / Micro.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _ghiVanBanTuMicro('');
                            _vanBanDaChot = '';
                            _tuDaChot = [];
                            _partialTruocDo = [];
                            _rawTruocDoTrongPhien = '';
                            _soLanPartial = 0;
                            _soLanFinal = 0;
                          });
                          _ghiLog('Xoá để thử lại.');
                        },
                        child: const Text('Xoá để thử lại'),
                      ),
                      const SizedBox(width: 16),
                      // Nút nhật ký — nhỏ, mở modal riêng thay vì chiếm chỗ
                      // ngay trên trang như trước.
                      Tooltip(
                        message: 'Xem nhật ký',
                        child: IconButton(
                          onPressed: _moModalNhatKy,
                          icon: const Icon(Icons.receipt_long),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút micro — thu nhỏ lại giống kiểu nút trong app
                      // APK, có phím tắt Ctrl+G (xem `CallbackShortcuts`
                      // bao ngoài).
                      Tooltip(
                        message: 'Bật/tắt micro (Ctrl+G)',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: (_sanSang && !_dangGhiAm)
                              ? _bamNutMicro
                              : null,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _muonNghe
                                  ? Colors.red
                                  : Colors.lightGreen.shade200,
                              border: Border.all(
                                color: Colors.blue.shade900,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _muonNghe ? Icons.mic : Icons.mic_none,
                              color: _muonNghe
                                  ? Colors.white
                                  : Colors.blue.shade900,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // Nút "Ghi âm" riêng — trên iPhone nút micro chính ở
                      // trên đã gọi thẳng đúng cơ chế này rồi (xem
                      // `_bamNutMicro`), nên ẨN nút riêng này đi để khỏi có
                      // hai nút làm cùng một việc. Trên Android/PC (nơi
                      // micro chính vẫn dùng Web Speech API) vẫn giữ nút
                      // này làm lựa chọn phụ.
                      if (_thietBi != ThietBi.iphone) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: _dangGhiAm ? 'Dừng ghi âm' : 'Ghi âm thử',
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _bamNutGhiAm,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _dangGhiAm
                                    ? Colors.red
                                    : Colors.orange.shade100,
                                border: Border.all(
                                  color: Colors.orange.shade900,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _dangGhiAm
                                    ? Icons.stop
                                    : Icons.fiber_manual_record,
                                color: _dangGhiAm
                                    ? Colors.white
                                    : Colors.orange.shade900,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Nút "Nghe lại" và "Tải xuống" đã bỏ — cơ chế ghi âm
                      // đã kiểm chứng hoạt động đúng (không cần công cụ
                      // kiểm tra nhanh này nữa), thẻ đã được nghe qua Gemini
                      // phiên âm là đủ tin cậy.
                    ],
                  ),
                  if (_dangGhiAm)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Center(
                        child: Text(
                          'Đang ghi âm… bấm lại để dừng.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Tên trang.
                  Center(
                    child: Text(
                      'Flowrite — thử micro trên Web ($_phienBanThuNghiem)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Thiết bị đang chọn — cố tình KHÔNG đặt trong AppBar
                  // (chữ trắng từng bị chìm mất trên nền AppBar gần trắng
                  // của Material 3). Khung nền riêng để luôn nổi bật.
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Thiết bị đang chọn:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        SegmentedButton<ThietBi>(
                          segments: const [
                            ButtonSegment(
                              value: ThietBi.android,
                              icon: Icon(Icons.android),
                              label: Text('Android'),
                            ),
                            ButtonSegment(
                              value: ThietBi.pc,
                              icon: Icon(Icons.laptop_mac),
                              label: Text('PC/Mac'),
                            ),
                            ButtonSegment(
                              value: ThietBi.iphone,
                              icon: Icon(Icons.phone_iphone),
                              label: Text('iPhone'),
                            ),
                          ],
                          selected: {_thietBi},
                          onSelectionChanged: (chon) =>
                              _doiCheDoThietBi(chon.first),
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: Colors.blue.shade700,
                            selectedForegroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ], // đóng `if (!banPhimDangMo) ...[`
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
