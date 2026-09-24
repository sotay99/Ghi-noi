// Vòng tròn đồng tâm quanh một chấm — vẽ theo mức âm THẬT (`muc`), dùng
// chung cho cả sóng âm cạnh nút Micro/Ghi âm (`thanh_cong_cu.dart`) lẫn
// chấm đỏ to trong bảng điều khiển ghi âm (`trang_soan_thao.dart`). Tách
// riêng ra đây để không viết trùng logic vẽ ở hai nơi — chỉ khác nhau về
// kích thước.

import 'package:flutter/material.dart';

class VongSongAm extends StatelessWidget {
  const VongSongAm({
    super.key,
    required this.muc,
    required this.dangNghe,
    required this.mau,
    this.kichThuoc = 34,
    this.mauNghi,
  });

  /// Vài mẫu mức âm gần nhất (0..1), mẫu mới nhất ở cuối danh sách.
  final List<double> muc;

  /// Có đang phát ra sóng hay không — tắt thì chỉ còn mỗi chấm ở giữa,
  /// không vẽ vòng nào cả (dùng cho lúc tạm dừng/im lặng).
  final bool dangNghe;

  final Color mau;

  /// Màu chấm giữa lúc `dangNghe == false` — mặc định nhạt hơn [mau] một
  /// chút (giữ nguyên hành vi cũ của `SongAm`).
  final Color? mauNghi;

  final double kichThuoc;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kichThuoc,
      height: kichThuoc,
      child: CustomPaint(
        painter: VeVongSongAm(
          muc: muc,
          mau: dangNghe ? mau : (mauNghi ?? const Color(0xFFBDBDBD)),
          dangNghe: dangNghe,
        ),
      ),
    );
  }
}

class VeVongSongAm extends CustomPainter {
  VeVongSongAm({required this.muc, required this.mau, required this.dangNghe});

  final List<double> muc;
  final Color mau;
  final bool dangNghe;

  static const _tiLeBanKinhCham = 0.09;
  static const _soVongToiDa = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final tam = Offset(size.width / 2, size.height / 2);
    final banKinhCham = size.shortestSide * _tiLeBanKinhCham;

    canvas.drawCircle(tam, banKinhCham, Paint()..color = mau);
    if (!dangNghe) return;

    // Mức âm hiện tại: trung bình vài mẫu gần nhất — mượt hơn hẳn so với
    // chỉ nhìn đúng một mẫu tức thời.
    final soMauDung = muc.length < 4 ? muc.length : 4;
    final ganDay = soMauDung == 0 ? const <double>[] : muc.sublist(muc.length - soMauDung);
    final mucHienTai = ganDay.isEmpty
        ? 0.0
        : (ganDay.reduce((a, b) => a + b) / ganDay.length).clamp(0.0, 1.0);

    final soVong = 1 + (mucHienTai * _soVongToiDa).round().clamp(0, _soVongToiDa);
    final banKinhToiDa = size.shortestSide / 2 - 1;

    for (var i = 1; i <= soVong; i++) {
      final banKinh = banKinhCham + (banKinhToiDa - banKinhCham) * i / soVong;
      final doDam = (0.15 + mucHienTai * 0.6) * (1 - (i - 1) / soVong * 0.5);
      canvas.drawCircle(
        tam,
        banKinh,
        Paint()
          ..color = mau.withValues(alpha: doDam.clamp(0.1, 0.9))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VeVongSongAm cu) => true;
}
