// Thẻ "Tích chọn" — token 5 ký tự ` (🔲) `/` (✅) ` chèn ở đầu một đoạn văn
// để đánh dấu đoạn đó CHƯA/ĐÃ hoàn thành. Cùng NGUYÊN TẮC khoá cứng như thẻ
// ghi âm (xem `the_ghi_am.dart`/`ChanSuaGiuaThe`): không sửa/xoá được từng
// ký tự riêng lẻ bên trong, chạm vào một phần thì "phóng to" thành xoá
// nguyên cả token — nhưng KHÔNG hỏi xác nhận trước khi xoá (không phải dữ
// liệu quý như bản ghi âm; xoá nhầm thì bấm lại nút Tích chọn là có ngay).

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const bieuTuongTichChonChuaXong = '🔲';
const bieuTuongTichChonDaXong = '✅';

/// Token đầy đủ của một biểu tượng — luôn đúng dạng ` (X) ` (dấu cách, mở
/// ngoặc, biểu tượng, đóng ngoặc, dấu cách).
String nhanTheTichChon(String bieuTuong) => ' ($bieuTuong) ';

/// Khớp CẢ HAI biểu tượng — nhóm 1 là chính biểu tượng đó.
final RegExp reTheTichChon = RegExp(' \\(($bieuTuongTichChonChuaXong|$bieuTuongTichChonDaXong)\\) ');

/// Tìm toàn bộ vùng thẻ tích chọn trong [text] — dùng làm "vùng khoá" cho
/// formatter chặn sửa/xoá một phần, và loại trừ lẫn với định dạng thủ công/
/// AI (xem `_giaoVoiVungAi` trong `trang_soan_thao.dart`).
List<(int, int)> timCacVungTheTichChon(String text) {
  final vung = <(int, int)>[];
  for (final m in reTheTichChon.allMatches(text)) {
    vung.add((m.start, m.end));
  }
  return vung;
}

/// Y hệt thuật toán của `ChanSuaGiuaThe` (`the_ghi_am.dart`) — chặn sửa/xoá
/// TỪNG KÝ TỰ bên trong một thẻ tích chọn, và đẩy con trỏ ra biên gần nhất
/// khi chỉ di chuyển (không gõ gì). KHÁC `ChanSuaGiuaThe`: không có đường
/// hỏi xác nhận — chồng lấn một phần luôn được xoá thẳng cả token, không hỏi.
class ChanSuaGiuaTheTichChon extends TextInputFormatter {
  ChanSuaGiuaTheTichChon({this.khiDaXoaThe});

  /// Gọi (một khung hình SAU, qua `addPostFrameCallback` — không gọi ngay
  /// trong lúc formatter còn chạy, cùng lý do với `ChanSuaGiuaThe`) ngay sau
  /// khi một token bị xoá NGUYÊN CẢ (dù do gõ/xoá bàn phím chồng lấn một
  /// phần, hay chọn/xoá trọn) — [viTri] là vị trí nó từng đứng, [iconDaXoa]
  /// là biểu tượng của nó lúc bị xoá. Nơi gọi dùng để áp side-effect "bỏ
  /// gạch ngang cả đoạn" khi token bị xoá là ✅.
  final void Function(int viTri, String iconDaXoa)? khiDaXoaThe;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    if (oldText == newText) {
      final vung = timCacVungTheTichChon(newText);
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

    final vungCu = timCacVungTheTichChon(oldText);
    if (vungCu.isEmpty) return newValue;

    var dau = 0;
    final ngan = oldText.length < newText.length ? oldText.length : newText.length;
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
      final icon = reTheTichChon.firstMatch(oldText.substring(batDau, ketThuc))?.group(1);
      final goi = khiDaXoaThe;
      if (goi != null && icon != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) => goi(batDau, icon));
      }
      final vanBanKetQua = oldText.replaceRange(batDau, ketThuc, '');
      return TextEditingValue(
        text: vanBanKetQua,
        selection: TextSelection.collapsed(offset: batDau),
      );
    }
    return newValue;
  }
}
