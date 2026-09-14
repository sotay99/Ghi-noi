// Thanh ngang dưới màn hình soạn thảo: bên trái là hướng dẫn, cài đặt, làm
// việc với AI, bàn phím, thư mục; bên phải là micro sát cạnh sóng âm. Tự nằm
// khít mép trên bàn phím ảo — việc đó do trang gọi widget này lo, ở đây chỉ
// vẽ giao diện.

import 'dart:math' as toan;

import 'package:flutter/material.dart';

class ThanhCongCu extends StatelessWidget {
  const ThanhCongCu({
    super.key,
    required this.bat,
    required this.dangNghe,
    required this.songAm,
    required this.sanSang,
    required this.neThanhDieuHuong,
    required this.khiBamMicro,
    required this.khiBamThuMuc,
    required this.khiBamCaiDat,
    required this.khiBamHuongDan,
    required this.khiBamAI,
    required this.khiBamBanPhim,
  });

  final bool bat;
  final bool dangNghe;
  final List<double> songAm;
  final bool sanSang;
  final bool neThanhDieuHuong;
  final VoidCallback khiBamMicro;
  final VoidCallback khiBamThuMuc;
  final VoidCallback khiBamCaiDat;
  final VoidCallback khiBamHuongDan;
  final VoidCallback khiBamAI;
  final VoidCallback khiBamBanPhim;

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        bottom: neThanhDieuHuong,
        child: Container(
          // Thấp hết mức còn bấm trúng: 48px vẫn đủ vùng chạm theo chuẩn
          // Material, mà nhường gần hết màn hình cho chữ.
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE3E3E3))),
          ),
          child: Row(
            children: [
              // Bên trái: hướng dẫn sát mép màn hình, rồi cài đặt, rồi hai
              // nút mới (AI, bàn phím), rồi thư mục.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      NutNho(
                        bieuTuong: Icons.help_outline_rounded,
                        nhan: 'Hướng dẫn',
                        khiBam: khiBamHuongDan,
                      ),
                      NutNho(
                        bieuTuong: Icons.settings_outlined,
                        nhan: 'Cài đặt',
                        khiBam: khiBamCaiDat,
                      ),
                      NutNho(
                        bieuTuong: Icons.smart_toy_outlined,
                        nhan: 'Làm việc với AI',
                        khiBam: khiBamAI,
                      ),
                      NutNho(
                        bieuTuong: Icons.keyboard_outlined,
                        nhan: 'Bàn phím',
                        khiBam: khiBamBanPhim,
                      ),
                      NutNho(
                        bieuTuong: Icons.folder_outlined,
                        nhan: 'Thư mục',
                        khiBam: khiBamThuMuc,
                      ),
                    ],
                  ),
                ),
              ),

              // Bên phải: micro nằm sát ngay cạnh sóng âm, không còn ở giữa.
              _NutMicroTron(
                bat: bat,
                sanSang: sanSang,
                mau: mau,
                khiBam: sanSang ? khiBamMicro : null,
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SongAm(muc: songAm, dangNghe: bat && dangNghe),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutMicroTron extends StatelessWidget {
  const _NutMicroTron({
    required this.bat,
    required this.sanSang,
    required this.mau,
    required this.khiBam,
  });

  final bool bat;
  final bool sanSang;
  final ColorScheme mau;
  final VoidCallback? khiBam;

  @override
  Widget build(BuildContext context) {
    final nen = !sanSang
        ? Colors.grey.shade400
        : (bat ? Colors.red.shade600 : mau.primary);

    return Semantics(
      button: true,
      label: bat ? 'Tắt micro' : 'Bật micro',
      child: Material(
        color: nen,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: khiBam,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              bat ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút biểu tượng cỡ nhỏ. IconButton sẵn có chiếm tối thiểu 48x48, quá cao so
/// với thanh công cụ này, nên tự dựng lấy một cái vừa vặn hơn.
class NutNho extends StatelessWidget {
  const NutNho({
    super.key,
    required this.bieuTuong,
    required this.nhan,
    required this.khiBam,
  });

  final IconData bieuTuong;
  final String nhan;
  final VoidCallback khiBam;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: nhan,
      child: Tooltip(
        message: nhan,
        child: InkResponse(
          onTap: khiBam,
          radius: 22,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(bieuTuong, size: 20, color: const Color(0xFF5F6368)),
          ),
        ),
      ),
    );
  }
}

/// Mấy vạch nhảy theo giọng nói. Micro tắt thì nằm im thành một đường phẳng —
/// nhìn vào là biết ngay máy có đang nghe thấy mình hay không.
class SongAm extends StatelessWidget {
  const SongAm({super.key, required this.muc, required this.dangNghe});

  final List<double> muc;
  final bool dangNghe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 22,
      child: CustomPaint(
        painter: _VeSongAm(
          muc: muc,
          mau: dangNghe ? Colors.red.shade600 : const Color(0xFFBDBDBD),
          dangNghe: dangNghe,
        ),
      ),
    );
  }
}

class _VeSongAm extends CustomPainter {
  _VeSongAm({required this.muc, required this.mau, required this.dangNghe});

  final List<double> muc;
  final Color mau;
  final bool dangNghe;

  @override
  void paint(Canvas canvas, Size size) {
    final but = Paint()
      ..color = mau
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final soVach = muc.length;
    final buoc = size.width / soVach;
    final giua = size.height / 2;

    for (var i = 0; i < soVach; i++) {
      final x = buoc * i + buoc / 2;
      final cao = dangNghe ? toan.max(3.0, muc[i] * size.height) : 3.0;
      canvas.drawLine(
        Offset(x, giua - cao / 2),
        Offset(x, giua + cao / 2),
        but,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VeSongAm cu) => true;
}
