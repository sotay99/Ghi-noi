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

/// Token của một thẻ ĐANG ghi dở (chưa có thời lượng) — placeholder hiển
/// thị màu đỏ cho tới khi chốt xong thành `〔Ghi âm N 🎙️ mm:ss〕` (màu
/// xanh lá).
const tenTokenDangGhiAm = '〔🎙️ … đang ghi âm …〕';

/// Thẻ đã ghi xong: `〔Ghi âm 3 🎙️ 01:25〕` — màu xanh lá (bình thường) hoặc
/// cam đậm (đang lỗi tạm thời, chờ gửi lại — chữ giống nhau, chỉ khác màu,
/// xem `_theGhiAmLoiTamThoi` trong `trang_soan_thao.dart`).
final RegExp reTheGhiAmHoanChinh = RegExp('〔Ghi âm (\\d+) 🎙️ \\d+:\\d+〕');

/// Thẻ ĐANG được gửi cho Gemini: `〔Đang chuyển 3 🎙️ 01:25〕` — giữ nguyên số
/// N (khác thời điểm chưa gửi/gửi lỗi chỉ khác PHẦN CHỮ đầu, mm:ss không
/// đổi) để vẫn tìm lại đúng bằng cách so khớp nguyên văn nhãn, không lẫn
/// giữa nhiều thẻ đang gửi cùng lúc (auto gửi ngầm có thể gửi nhiều thẻ một
/// lượt). Nhóm 2 (`\d+:\d+`) là phần mm:ss — tách riêng để tô màu khác
/// phần "Đang chuyển N" (xem `_BoDieuKhienChinhTa.buildTextSpan`).
final RegExp reTheDangChuyen =
    RegExp('〔Đang chuyển (\\d+) 🎙️ (\\d+:\\d+)〕');

/// "mm:ss" — dùng cho cả đồng hồ đang ghi và nhãn thẻ đã chốt.
String dinhDangMmSs(Duration d) {
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(d.inMinutes)}:${hai(d.inSeconds % 60)}';
}

/// Nhãn hiển thị đầy đủ của thẻ số [soThe] với thời lượng [thoiLuong].
String nhanTheHoanChinh(int soThe, Duration thoiLuong) =>
    '〔Ghi âm $soThe 🎙️ ${dinhDangMmSs(thoiLuong)}〕';

/// Nhãn "đang gửi cho Gemini" của thẻ số [soThe].
String nhanTheDangChuyen(int soThe, Duration thoiLuong) =>
    '〔Đang chuyển $soThe 🎙️ ${dinhDangMmSs(thoiLuong)}〕';

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
  var timTu = 0;
  while (true) {
    final i = text.indexOf(tenTokenDangGhiAm, timTu);
    if (i < 0) break;
    vung.add((i, i + tenTokenDangGhiAm.length));
    timTu = i + tenTokenDangGhiAm.length;
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

    for (final (batDau, ketThuc) in vungCu) {
      final chongLan = dau < ketThuc && cuoiCu > batDau;
      if (!chongLan) continue;
      final goi = khiCanXoaThe;
      if (goi != null) {
        // CHẶN hẳn, không tự xoá — báo lại để nơi gọi hỏi xác nhận trước
        // (hoặc xoá thẳng không hỏi, nếu thẻ đã có trong bộ nhớ đệm — tuỳ
        // nơi gọi quyết định, xem `_khiCanXoaTheTuBanPhim`). ÁP DỤNG CHO CẢ
        // sửa một phần LẪN xoá TRỌN thẻ (ví dụ Ctrl+A rồi Xoá) — trước đây
        // xoá trọn được cho qua thẳng không hỏi gì, khiến thẻ "chưa xử lý
        // xong" mất không dấu vết. Không gọi [goi] ngay tại đây: formatter
        // đang chạy giữa lượt cập nhật của chính TextField, mở dialog/
        // setState ngay lúc này không an toàn.
        SchedulerBinding.instance
            .addPostFrameCallback((_) => goi(batDau, ketThuc));
        return oldValue;
      }
      final phuTron = dau <= batDau && cuoiCu >= ketThuc;
      if (phuTron) continue; // không có callback — theo cách cũ, cho qua.
      final vanBanKetQua = oldText.replaceRange(batDau, ketThuc, '');
      return TextEditingValue(
        text: vanBanKetQua,
        selection: TextSelection.collapsed(offset: batDau),
      );
    }
    return newValue;
  }
}
