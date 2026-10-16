// Khối dùng CHUNG cho hai trang pháp lý ("Điều khoản sử dụng",
// "Bảo mật và quyền riêng tư") — CÙNG kiểu trình bày với
// `trang_huong_dan.dart` (`_MucLon`/`_Doan`: tiêu đề có số + chữ đậm/tô
// nền/đổi màu trong đoạn văn qua `**đậm**`/`==tô nền==`/`~~đổi màu~~`),
// tách ra một tệp riêng (không sửa `trang_huong_dan.dart`, tránh động vào
// trang đang chạy ổn định) vì hai trang MỚI này cần thêm: tiêu đề NHỎ (mục
// con, không có số thứ tự lớn) và một khung hộp màu dùng lại được nhiều lần
// (hộp tóm tắt đầu trang, hộp liên hệ...). Toàn bộ nội dung bọc trong
// `SelectionArea` ở nơi gọi (`modal_dieu_khoan.dart`/`modal_bao_mat.dart`)
// để chọn/copy được xuyên suốt cả trang bằng một lần kéo, không bị ngắt
// quãng giữa các khối `Text.rich` rời rạc.

import 'package:flutter/material.dart';

const mauChinhPhapLy = Color(0xFF1A73E8);
const mauChinhDamPhapLy = Color(0xFF0B3D91);

/// Tiêu đề LỚN — số thứ tự trong khối vuông bo góc + chữ đậm, mở đầu mỗi
/// phần chính của trang.
class MucLonPhapLy extends StatelessWidget {
  const MucLonPhapLy({required this.so, required this.tieuDe});

  final String so;
  final String tieuDe;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: mauChinhPhapLy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            so,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tieuDe,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF202124),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tiêu đề NHỎ — mục con bên trong một `MucLonPhapLy`, không có số, màu
/// khác hẳn tiêu đề lớn để mắt phân biệt ngay cấp độ.
class MucNhoPhapLy extends StatelessWidget {
  const MucNhoPhapLy(this.tieuDe);

  final String tieuDe;

  @override
  Widget build(BuildContext context) {
    return Text(
      tieuDe,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF00695C),
        height: 1.3,
      ),
    );
  }
}

/// Đoạn văn — hỗ trợ `**đậm**`, `==tô nền vàng==`, `~~đổi màu xanh dương==`
/// NGAY TRONG CÂU, đúng khuôn `_Doan` của `trang_huong_dan.dart`.
class DoanPhapLy extends StatelessWidget {
  const DoanPhapLy(this.vanBan);

  final String vanBan;

  static final _mauDanhDau = RegExp(r'\*\*(.+?)\*\*|==(.+?)==|~~(.+?)~~');

  List<InlineSpan> _phanTich() {
    final ketQua = <InlineSpan>[];
    var viTri = 0;
    for (final m in _mauDanhDau.allMatches(vanBan)) {
      if (m.start > viTri) {
        ketQua.add(TextSpan(text: vanBan.substring(viTri, m.start)));
      }
      if (m.group(1) != null) {
        ketQua.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124)),
        ));
      } else if (m.group(2) != null) {
        ketQua.add(TextSpan(
          text: m.group(2),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFF3B0),
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C4300),
          ),
        ));
      } else if (m.group(3) != null) {
        ketQua.add(TextSpan(
          text: m.group(3),
          style: const TextStyle(color: mauChinhPhapLy, fontWeight: FontWeight.w700),
        ));
      }
      viTri = m.end;
    }
    if (viTri < vanBan.length) {
      ketQua.add(TextSpan(text: vanBan.substring(viTri)));
    }
    return ketQua;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF3C4043)),
        children: _phanTich(),
      ),
    );
  }
}

/// Một dòng trong danh sách gạch đầu dòng — chấm tròn màu + `DoanPhapLy`.
class DongGachDauPhapLy extends StatelessWidget {
  const DongGachDauPhapLy(this.vanBan, {this.mauCham = mauChinhPhapLy});

  final String vanBan;
  final Color mauCham;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: mauCham, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: DoanPhapLy(vanBan)),
        ],
      ),
    );
  }
}

/// Khung hộp màu dùng lại nhiều lần — hộp tóm tắt đầu trang, hộp liên hệ...
class HopNoiBatPhapLy extends StatelessWidget {
  const HopNoiBatPhapLy({
    required this.child,
    this.mauNen = const Color(0xFFE8F0FE),
    this.mauVien = const Color(0xFFAECBFA),
  });

  final Widget child;
  final Color mauNen;
  final Color mauVien;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mauNen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mauVien),
      ),
      child: child,
    );
  }
}
