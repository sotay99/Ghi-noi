// Thẻ ghi âm — phần LÕI dùng chung giữa Android, PC/Mac-web và iPhone-web:
// định dạng token, cách tìm vùng thẻ trong văn bản, và formatter chặn
// sửa/xoá giữa thẻ. KHÔNG chứa gì đụng tới việc GHI âm thật (đó là việc
// của lớp bọc riêng từng nền tảng — xem `ghi_am_the_io.dart`/
// `ghi_am_the_web.dart`) — file này chỉ lo phần "thẻ trông như thế nào
// trong văn bản", để dùng được ở cả `trang_soan_thao.dart` (Android/iOS
// gốc + web đầy đủ) mà không kéo theo bất kỳ import riêng nền tảng nào.
//
// Nguyên văn thiết kế đã kiểm chứng ở `main_web_test.dart` (phòng thí
// nghiệm web) — chỉ tổng quát hoá thành hàm/lớp dùng chung, không đổi
// thuật toán.

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'ngon_ngu.dart';

/// Từ "Ghi âm"/"Đang chuyển" ghép vào token LƯU TRONG TÀI LIỆU (khác chữ
/// hiển thị ở UI chrome thường, vì đây trở thành một phần nội dung đã lưu
/// của người dùng — đổi ngôn ngữ app KHÔNG được làm "mất" các thẻ đã tạo từ
/// trước bằng ngôn ngữ khác). Token MỚI luôn ghép bằng ngôn ngữ app hiện
/// tại; các regex bên dưới khớp CẢ HAI từ (mọi ngôn ngữ đã từng hỗ trợ) để
/// thẻ cũ vẫn nhận ra được sau khi đổi ngôn ngữ. Thêm ngôn ngữ mới thì
/// thêm đúng 1 case ở mỗi hàm `_tu*` này VÀ nối thêm vào alternation của
/// regex tương ứng.
String _tuGhiAm(NgonNgu nn) => Ch.tuGhiAmTrongThe(nn);
String _tuDangChuyen(NgonNgu nn) => Ch.tuDangChuyenTrongThe(nn);

/// Chữ thường của [_tuGhiAm] — placeholder dùng dạng tiếp diễn thường
/// ("đang ghi âm"/"recording"), không viết hoa đầu câu như trong token đã
/// chốt ("Ghi âm N").
String _tuGhiAmThuong(NgonNgu nn) =>
    nn == NgonNgu.en ? 'recording' : 'đang ghi âm';

/// Token của một thẻ ĐANG ghi dở (chưa có thời lượng) — placeholder hiển
/// thị màu đỏ cho tới khi chốt xong thành `〔Ghi âm N 🎙️ mm:ss〕` (màu
/// xanh lá). [nn] mặc định `NgonNgu.vi` để không phá chữ ký cũ ở nơi chưa
/// kịp cập nhật — luôn truyền `ngonNguHienTai.value` ở nơi gọi mới.
String tenTokenDangGhiAm([NgonNgu nn = NgonNgu.vi]) =>
    '〔🎙️ … ${_tuGhiAmThuong(nn)} …〕';

/// Mọi biến thể placeholder "đang ghi dở" (mọi ngôn ngữ) — dùng để QUÉT
/// (không phải để hiển thị) trong `timCacVungTheGhiAm`.
List<String> get _tatCaTenTokenDangGhiAm =>
    NgonNgu.values.map(tenTokenDangGhiAm).toList();

/// Thẻ đã ghi xong: `〔Ghi âm 3 🎙️ 01:25〕` (hoặc `〔Recording 3 🎙️ 01:25〕`)
/// — màu xanh lá (bình thường) hoặc cam đậm (đang lỗi tạm thời, chờ gửi
/// lại — chữ giống nhau, chỉ khác màu, xem `_theGhiAmLoiTamThoi` trong
/// `trang_soan_thao.dart`). Khớp CẢ HAI từ ngôn ngữ (xem chú thích
/// `_tuGhiAm` ở trên) để thẻ tạo từ ngôn ngữ trước vẫn nhận ra sau khi đổi.
final RegExp reTheGhiAmHoanChinh =
    RegExp('〔(?:${NgonNgu.values.map(_tuGhiAm).join('|')}) (\\d+) 🎙️ \\d+:\\d+〕');

/// Thẻ ĐANG được gửi cho Gemini: `〔Đang chuyển 3 🎙️ 01:25〕` (hoặc
/// `〔Transcribing 3 🎙️ 01:25〕`) — giữ nguyên số N (khác thời điểm chưa
/// gửi/gửi lỗi chỉ khác PHẦN CHỮ đầu, mm:ss không đổi) để vẫn tìm lại đúng
/// bằng cách so khớp nguyên văn nhãn, không lẫn giữa nhiều thẻ đang gửi
/// cùng lúc (auto gửi ngầm có thể gửi nhiều thẻ một lượt). Nhóm 2
/// (`\d+:\d+`) là phần mm:ss — tách riêng để tô màu khác phần "Đang chuyển
/// N" (xem `_BoDieuKhienChinhTa.buildTextSpan`). Khớp cả hai ngôn ngữ, lý
/// do như `reTheGhiAmHoanChinh`.
final RegExp reTheDangChuyen = RegExp(
    '〔(?:${NgonNgu.values.map(_tuDangChuyen).join('|')}) (\\d+) 🎙️ (\\d+:\\d+)〕');

/// "mm:ss" — dùng cho cả đồng hồ đang ghi và nhãn thẻ đã chốt.
String dinhDangMmSs(Duration d) {
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(d.inMinutes)}:${hai(d.inSeconds % 60)}';
}

/// Nhãn hiển thị đầy đủ của thẻ số [soThe] với thời lượng [thoiLuong], ghép
/// bằng ngôn ngữ app hiện tại [nn] (luôn truyền `ngonNguHienTai.value` —
/// mặc định `NgonNgu.vi` chỉ để không phá chữ ký cũ).
String nhanTheHoanChinh(int soThe, Duration thoiLuong, [NgonNgu nn = NgonNgu.vi]) =>
    '〔${_tuGhiAm(nn)} $soThe 🎙️ ${dinhDangMmSs(thoiLuong)}〕';

/// Nhãn "đang gửi cho Gemini" của thẻ số [soThe], ghép bằng ngôn ngữ app
/// hiện tại [nn].
String nhanTheDangChuyen(int soThe, Duration thoiLuong, [NgonNgu nn = NgonNgu.vi]) =>
    '〔${_tuDangChuyen(nn)} $soThe 🎙️ ${dinhDangMmSs(thoiLuong)}〕';

/// Tìm TOÀN BỘ vùng thẻ ghi âm (đã xong, đang gửi, VÀ đang ghi dở) trong
/// [text] — dùng làm "vùng khoá" cho: formatter chặn sửa giữa thẻ, đẩy con
/// trỏ ra ngoài, và loại trừ lẫn với định dạng thủ công/AI/tìm-kiếm (xem
/// `_giaoVoiVungAi`/`_diemNgoaiVungKhoa`/tìm-kiếm trong `trang_soan_thao.dart`).
List<(int, int)> timCacVungTheGhiAm(String text) {
  final vung = <(int, int)>[];
  for (final m in reTheGhiAmHoanChinh.allMatches(text)) {
    vung.add((m.start, m.end));
  }
  for (final m in reTheDangChuyen.allMatches(text)) {
    vung.add((m.start, m.end));
  }
  // Quét MỌI biến thể ngôn ngữ của placeholder "đang ghi dở" — thẻ có thể
  // đã được tạo khi app ở ngôn ngữ khác ngôn ngữ hiện tại.
  for (final token in _tatCaTenTokenDangGhiAm) {
    var timTu = 0;
    while (true) {
      final i = text.indexOf(token, timTu);
      if (i < 0) break;
      vung.add((i, i + token.length));
      timTu = i + token.length;
    }
  }
  return vung;
}

/// [viTri] có nằm NGAY TRONG một thẻ (không phải hai đầu mút) không.
bool viTriNamGiuaThe(int viTri, List<(int, int)> vungThe) {
  for (final (batDau, ketThuc) in vungThe) {
    if (viTri > batDau && viTri < ketThuc) return true;
  }
  return false;
}

/// Chặn sửa/xoá TỪNG KÝ TỰ bên trong một thẻ ghi âm (dù đã xong hay đang
/// ghi dở) — mọi chỉnh sửa CHỒNG LẤN một phần vùng ký tự của thẻ (không phủ
/// trọn thẻ) sẽ bị "phóng to" thành xoá NGUYÊN CẢ THẺ đó. Đồng thời chặn con
/// trỏ (hoặc vùng chọn) dừng lại ở GIỮA một thẻ khi người dùng chỉ di
/// chuyển con trỏ (không gõ gì) — tự đẩy ra biên gần nhất. Nguyên văn thuật
/// toán từ `main_web_test.dart` (`_ChanSuaGiuaThe`), tổng quát hoá để dùng
/// `timCacVungTheGhiAm` thay vì đọc trực tiếp state riêng của trang thử.
class ChanSuaGiuaThe extends TextInputFormatter {
  ChanSuaGiuaThe({this.khiCanXoaThe});

  /// Gọi (một khung hình SAU, qua `addPostFrameCallback` — không gọi ngay
  /// trong lúc formatter còn chạy) khi một lần gõ/xoá bằng BÀN PHÍM vừa bị
  /// CHẶN vì nó sẽ xoá một phần thẻ tại [batDau, ketThuc) — nơi gọi tự hỏi
  /// xác nhận rồi xoá thật nếu người dùng đồng ý (y hệt cách xoá qua menu
  /// bấm-vào-thẻ, không âm thầm xoá ngay như trước).
  final void Function(int batDau, int ketThuc)? khiCanXoaThe;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    if (oldText == newText) {
      // Không đổi chữ — chỉ đổi vùng chọn. Đẩy con trỏ ra khỏi giữa thẻ.
      final vung = timCacVungTheGhiAm(newText);
      if (vung.isEmpty) return newValue;
      int day(int viTri) {
        for (final (batDau, ketThuc) in vung) {
          if (viTri > batDau && viTri < ketThuc) {
            return (viTri - batDau) < (ketThuc - viTri) ? batDau : ketThuc;
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

    final vungCu = timCacVungTheGhiAm(oldText);
    if (vungCu.isEmpty) return newValue;

    // Tìm đoạn khác nhau đầu/cuối giữa văn bản cũ và mới.
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

    // GỘP mọi vùng thẻ chồng lấn với khoảng vừa sửa [dau, cuoiCu) thành MỘT
    // khoảng xoá duy nhất — vùng chọn có thể phủ chữ thường XEN LẪN nhiều
    // thẻ (ví dụ tô một đoạn chứa cả chữ thường lẫn 2-3 thẻ ghi âm rồi bấm
    // Xoá một lần), nên không dừng lại ở thẻ ĐẦU TIÊN chạm phải nữa — lặp
    // tới điểm cố định vì gộp thêm một thẻ có thể vừa chạm tiếp thẻ khác.
    var batDauGop = dau, ketThucGop = cuoiCu;
    var coChongLan = false;
    var conDoi = true;
    while (conDoi) {
      conDoi = false;
      for (final (batDau2, ketThuc2) in vungCu) {
        if (batDau2 < ketThucGop && ketThuc2 > batDauGop) {
          coChongLan = true;
          if (batDau2 < batDauGop) {
            batDauGop = batDau2;
            conDoi = true;
          }
          if (ketThuc2 > ketThucGop) {
            ketThucGop = ketThuc2;
            conDoi = true;
          }
        }
      }
    }
    if (!coChongLan) return newValue;

    final goi = khiCanXoaThe;
    if (goi != null) {
      // CHẶN hẳn, không tự xoá — báo lại để nơi gọi hỏi xác nhận trước
      // (hoặc xoá thẳng không hỏi, nếu MỌI thẻ trong khoảng đã có trong bộ
      // nhớ đệm — tuỳ nơi gọi quyết định, xem `_khiCanXoaTheTuBanPhim`, giờ
      // tự quét lại [batDauGop, ketThucGop) để xử lý ĐỦ mọi thẻ trong đó,
      // không giả định chỉ có đúng một thẻ nữa). ÁP DỤNG CHO CẢ sửa một
      // phần LẪN xoá TRỌN thẻ (ví dụ Ctrl+A rồi Xoá) — trước đây xoá trọn
      // được cho qua thẳng không hỏi gì, khiến thẻ "chưa xử lý xong" mất
      // không dấu vết. Không gọi [goi] ngay tại đây: formatter đang chạy
      // giữa lượt cập nhật của chính TextField, mở dialog/setState ngay
      // lúc này không an toàn.
      SchedulerBinding.instance
          .addPostFrameCallback((_) => goi(batDauGop, ketThucGop));
      return oldValue;
    }
    final phuTron = dau <= batDauGop && cuoiCu >= ketThucGop;
    if (phuTron) return newValue; // không có callback — theo cách cũ, cho qua.
    final vanBanKetQua = oldText.replaceRange(batDauGop, ketThucGop, '');
    return TextEditingValue(
      text: vanBanKetQua,
      selection: TextSelection.collapsed(offset: batDauGop),
    );
  }
}
