// (YÊU CẦU MỚI) Màu chữ + gạch chân cho nhãn "Phím X" của Từ điển nhập liệu
// nhanh, và thứ tự hiển thị 26 dòng theo hàng phím bàn phím vật lý — dùng
// CHUNG ở cả 3 nơi: bảng 26 dòng để dán nhanh (`trang_soan_thao.dart`),
// modal cài đặt, và modal "Thay đổi thứ tự giữa các dòng"
// (`modal_tu_dien_nhap_lieu_nhanh.dart`) — tách riêng ra đây để 3 nơi không
// phải chép lại 3 lần.

import 'package:flutter/material.dart';

/// Hàng phím TRÊN cùng của bàn phím vật lý — chữ ở nhãn "Phím X" tô xanh lá
/// đậm.
const _hangTren = 'QWERTYUIOP';

/// Hàng phím GIỮA — tô vàng đậm.
const _hangGiua = 'ASDFGHJKL';

/// (Hàng phím DƯỚI cùng — ZXCVBNM — tô đỏ đậm, là phần `else` của
/// [mauChuPhimTuDienNhapLieuNhanh], không cần liệt kê riêng.)

/// Các phím nằm bên PHẢI bàn phím (phạm vi gõ của tay phải, kiểu gõ 10
/// ngón) — gạch chân ở nhãn "Phím X", không liên quan tới màu chữ.
const _ganChanPhai = 'YUIOPHJKLNM';

String chuCaiTuDienNhapLieuNhanh(int i) => String.fromCharCode('A'.codeUnitAt(0) + i);

/// Xanh lá đậm (hàng trên) / vàng đậm (hàng giữa) / đỏ đậm (hàng dưới) —
/// đúng 3 hàng phím chữ cái của bàn phím vật lý. Áp dụng cho MỌI nơi hiển
/// thị "Phím X" (hoặc chữ cái rút gọn ở màn hẹp) liên quan tới Từ điển nhập
/// liệu nhanh.
Color mauChuPhimTuDienNhapLieuNhanh(int i) {
  final c = chuCaiTuDienNhapLieuNhanh(i);
  if (_hangTren.contains(c)) return const Color(0xFF137333);
  if (_hangGiua.contains(c)) return const Color(0xFF9C6500);
  return const Color(0xFFC5221F);
}

bool ganChanPhimTuDienNhapLieuNhanh(int i) =>
    _ganChanPhai.contains(chuCaiTuDienNhapLieuNhanh(i));

/// (YÊU CẦU MỚI) Độ đậm của gạch chân ở nhãn "Phím X" — mặc định
/// (`decorationThickness: 1.0`) nhìn quá mảnh, tăng lên cho rõ.
const double doDayGachChanTuDienNhapLieuNhanh = 2.2;

/// Thứ tự 26 chỉ số (0=A..25=Z) đúng theo hàng phím Q-W-E-R-T-Y-U-I-O-P rồi
/// A-S-D-F-G-H-J-K-L rồi Z-X-C-V-B-N-M của bàn phím vật lý, từ trái qua
/// phải, từ trên xuống dưới — tính sẵn thành hằng số (đã kiểm đủ 26 chỉ số
/// 0-25, không trùng/thiếu) để không phải tính lại mỗi lần vẽ.
const List<int> thuTuChiSoHangPhimTuDienNhapLieuNhanh = [
  16, 22, 4, 17, 19, 24, 20, 8, 14, 15, // Q W E R T Y U I O P
  0, 18, 3, 5, 6, 7, 9, 10, 11, // A S D F G H J K L
  25, 23, 2, 21, 1, 13, 12, // Z X C V B N M
];

/// [kieu]: `'hang'` (theo hàng phím vật lý) hoặc bất kỳ giá trị khác (coi
/// như `'bangChuCai'`, A→Z) — luôn trả về đúng 26 chỉ số 0-25, mỗi số đúng
/// một lần.
List<int> thuTuTuDienNhapLieuNhanhTheoKieu(String kieu) => kieu == 'hang'
    ? List<int>.from(thuTuChiSoHangPhimTuDienNhapLieuNhanh)
    : List<int>.generate(26, (i) => i);
