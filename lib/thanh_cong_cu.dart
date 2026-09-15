// Thanh ngang dưới màn hình soạn thảo: bên trái là hướng dẫn, cài đặt, làm
// việc với AI, bàn phím, thư mục; bên phải là sóng âm rồi micro sát mép phải
// màn hình. Tự nằm khít mép trên bàn phím ảo — việc đó do trang gọi widget
// này lo, ở đây chỉ vẽ giao diện.

import 'package:flutter/material.dart';

class ThanhCongCu extends StatelessWidget {
  const ThanhCongCu({
    super.key,
    required this.bat,
    required this.dangNghe,
    required this.songAm,
    required this.sanSang,
    required this.neThanhDieuHuong,
    required this.nhanPhimTat,
    required this.khiBamMicro,
    required this.khiBamThuMuc,
    required this.khiBamCaiDat,
    required this.khiBamHuongDan,
    required this.khiBamAI,
    required this.khiBamBanPhim,
    required this.khiBamKiemTraToanVan,
    required this.khiBamGhiAmAI,
    required this.hienChuThich,
    required this.khiBamChuThich,
  });

  final bool bat;
  final bool dangNghe;
  final List<double> songAm;
  final bool sanSang;
  final bool neThanhDieuHuong;

  /// Đang hiện dòng chữ chú thích dọc phía trên từng nút hay không.
  final bool hienChuThich;
  final VoidCallback khiBamChuThich;

  /// Nhãn phím tắt hiện đang cài, ví dụ "Ctrl + F" — hiện lên khi rê chuột
  /// vào nút micro (chỉ có ý nghĩa với thiết bị có chuột/con trỏ thật).
  final String nhanPhimTat;

  final VoidCallback khiBamMicro;
  final VoidCallback khiBamThuMuc;
  final VoidCallback khiBamCaiDat;
  final VoidCallback khiBamHuongDan;
  final VoidCallback khiBamAI;
  final VoidCallback khiBamBanPhim;
  final VoidCallback khiBamKiemTraToanVan;
  final VoidCallback khiBamGhiAmAI;

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
          // Micro đang bật (đỏ) thì đường kẻ ngăn cách với trang soạn thảo
          // cũng đỏ đậm và dày hẳn lên — dấu hiệu dễ thấy dù mắt đang nhìn
          // vào bài, không cần liếc xuống tận nút micro mới biết đang ghi.
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: bat ? Colors.red.shade600 : const Color(0xFFE3E3E3),
                width: bat ? 3 : 1,
              ),
            ),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _NutCoChuThich(
                        hien: hienChuThich,
                        chu: 'Hướng dẫn sử dụng',
                        child: NutNho(
                          bieuTuong: Icons.help_outline_rounded,
                          nhan: 'Hướng dẫn',
                          khiBam: khiBamHuongDan,
                        ),
                      ),
                      _NutCoChuThich(
                        hien: hienChuThich,
                        chu: 'Cài đặt',
                        child: NutNho(
                          bieuTuong: Icons.settings_outlined,
                          nhan: 'Cài đặt',
                          khiBam: khiBamCaiDat,
                        ),
                      ),
                      _NutCoChuThich(
                        hien: hienChuThich,
                        chu: 'Thư mục và Tệp tin',
                        child: NutNho(
                          bieuTuong: Icons.folder_outlined,
                          nhan: 'Thư mục',
                          khiBam: khiBamThuMuc,
                        ),
                      ),
                      _NutCoChuThich(
                        hien: hienChuThich,
                        chu: 'Làm việc với AI',
                        child: NutNho(
                          bieuTuong: Icons.smart_toy_outlined,
                          nhan: 'Làm việc với AI',
                          khiBam: khiBamAI,
                        ),
                      ),
                      _NutCoChuThich(
                        hien: hienChuThich,
                        chu: 'Kiểm tra toàn văn (AI)',
                        child: NutNho(
                          bieuTuong: Icons.task_alt,
                          nhan: 'Kiểm tra toàn văn bằng AI',
                          mau: Colors.green.shade600,
                          khiBam: khiBamKiemTraToanVan,
                        ),
                      ),
                      _NutCoChuThich(
                        hien: hienChuThich,
                        chu: 'Xem thêm lựa chọn',
                        child: _NutThemMenu(khiBamBanPhim: khiBamBanPhim),
                      ),
                    ],
                  ),
                ),
              ),

              // Bên phải: nút ghi âm, rồi sóng âm, rồi micro sát mép phải.
              _NutCoChuThich(
                hien: hienChuThich,
                chu: 'Ghi âm xong rồi mới ra chữ',
                child: NutNho(
                  bieuTuong: Icons.settings_voice,
                  nhan: 'Ghi âm xong mới ra chữ',
                  khiBam: khiBamGhiAmAI,
                ),
              ),
              _NutCoChuThich(
                hien: hienChuThich && !bat,
                chu: 'Hiện chú thích',
                vang: true,
                child: SongAm(
                  muc: songAm,
                  dangNghe: bat && dangNghe,
                  micDangBat: bat,
                  khiBamChuThich: khiBamChuThich,
                ),
              ),
              const SizedBox(width: 6),
              _NutCoChuThich(
                hien: hienChuThich,
                chu: 'Micro Vừa nói vừa ra chữ',
                child: _NutMicroTron(
                  bat: bat,
                  sanSang: sanSang,
                  mau: mau,
                  nhanPhimTat: nhanPhimTat,
                  khiBam: sanSang ? khiBamMicro : null,
                ),
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
    required this.nhanPhimTat,
    required this.khiBam,
  });

  final bool bat;
  final bool sanSang;
  final ColorScheme mau;
  final String nhanPhimTat;
  final VoidCallback? khiBam;

  @override
  Widget build(BuildContext context) {
    final nen = !sanSang
        ? Colors.grey.shade400
        : (bat ? Colors.red.shade600 : mau.primary);

    return Semantics(
      button: true,
      label: bat ? 'Tắt micro' : 'Bật micro',
      child: Tooltip(
        message: '${bat ? 'Tắt' : 'Bật'} micro ($nhanPhimTat)',
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
    this.mau = const Color(0xFF5F6368),
  });

  final IconData bieuTuong;
  final String nhan;
  final VoidCallback khiBam;
  final Color mau;

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
            child: Icon(bieuTuong, size: 20, color: mau),
          ),
        ),
      ),
    );
  }
}

/// Một chấm tròn nhỏ khi im lặng; micro bật lên thì có thêm các vòng tròn
/// đồng tâm bao quanh chấm, âm càng lớn thì vòng càng nhiều và càng đậm.
/// Gọn hơn hẳn dãy vạch cũ — chỉ chiếm đúng bằng cỡ nút micro bên cạnh.
class SongAm extends StatelessWidget {
  const SongAm({
    super.key,
    required this.muc,
    required this.dangNghe,
    required this.micDangBat,
    required this.khiBamChuThich,
  });

  final List<double> muc;
  final bool dangNghe;

  /// Micro lớn (nút sát mép phải) có đang bật hay không — bật thì vẽ sóng
  /// âm như cũ; tắt thì cái chấm tròn này biến thành nút "i" để mở chú
  /// thích, vì lúc này sóng âm chẳng còn gì để vẽ.
  final bool micDangBat;
  final VoidCallback khiBamChuThich;

  @override
  Widget build(BuildContext context) {
    if (!micDangBat) {
      return Semantics(
        button: true,
        label: 'Hiện chú thích',
        child: Tooltip(
          message: 'Hiện chú thích',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: khiBamChuThich,
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.info_outline, size: 22, color: Color(0xFF5F6368)),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 34,
      height: 34,
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

/// Bọc một nút của thanh công cụ, thêm dòng chữ chú thích DỌC ngay phía trên
/// khi `hien` bật — chữ nằm nghiêng 90 độ, đầu ký tự hướng về bên trái, nên
/// đọc từ dưới lên trên chứ không phải trái sang phải như bình thường.
class _NutCoChuThich extends StatelessWidget {
  const _NutCoChuThich({
    required this.hien,
    required this.chu,
    required this.child,
    this.vang = false,
  });

  final bool hien;
  final String chu;
  final Widget child;

  /// Riêng chú thích của nút "i" có nền vàng nhạt để nổi bật hẳn so với các
  /// chú thích khác.
  final bool vang;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        child,
        if (hien)
          Positioned(
            bottom: 42,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              decoration: BoxDecoration(
                color: vang ? const Color(0xFFFFF9C4) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFDADCE0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  chu,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF202124)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VeSongAm extends CustomPainter {
  _VeSongAm({required this.muc, required this.mau, required this.dangNghe});

  final List<double> muc;
  final Color mau;
  final bool dangNghe;

  static const _banKinhCham = 3.0;
  static const _soVongToiDa = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final tam = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(tam, _banKinhCham, Paint()..color = mau);
    if (!dangNghe) return;

    // Mức âm hiện tại: trung bình vài mẫu gần nhất (mẫu mới nhất nằm cuối
    // danh sách) — mượt hơn hẳn so với chỉ nhìn đúng một mẫu tức thời.
    final soMauDung = muc.length < 4 ? muc.length : 4;
    final ganDay = soMauDung == 0 ? const <double>[] : muc.sublist(muc.length - soMauDung);
    final mucHienTai = ganDay.isEmpty
        ? 0.0
        : (ganDay.reduce((a, b) => a + b) / ganDay.length).clamp(0.0, 1.0);

    final soVong = 1 + (mucHienTai * _soVongToiDa).round().clamp(0, _soVongToiDa);
    final banKinhToiDa = size.shortestSide / 2 - 1;

    for (var i = 1; i <= soVong; i++) {
      final banKinh = _banKinhCham + (banKinhToiDa - _banKinhCham) * i / soVong;
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
  bool shouldRepaint(covariant _VeSongAm cu) => true;
}

/// Nút dấu cộng ở thanh công cụ: mở một menu sổ lên (nằm trên đỉnh nút, vì
/// nút ở sát đáy màn hình — PopupMenuButton tự né mép màn hình nên không cần
/// tự tính toán vị trí). Các mục hiện tại chưa gắn logic gì, chỉ là chỗ đặt
/// trước cho tính năng sau này.
class _NutThemMenu extends StatelessWidget {
  const _NutThemMenu({required this.khiBamBanPhim});

  /// Vị trí thứ 3 trong danh sách — trước đây là nút riêng ngoài thanh công
  /// cụ, giờ dồn vào đây cho gọn.
  final VoidCallback khiBamBanPhim;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Thêm',
      child: Tooltip(
        message: 'Thêm',
        child: PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          splashRadius: 20,
          icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF5F6368)),
          onSelected: (gia) {
            if (gia == 3) khiBamBanPhim();
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(
              value: 1,
              child: Text('Luyện gõ bàn phím bằng 10 ngón tay'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 2,
              child: Text('Bật bộ điều hướng và phím nhanh'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 3,
              child: Text('Kiểu gõ bàn phím'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 4,
              child: Text('Chia sẻ ứng dụng này đến với mọi người'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 5,
              child: Text('Góp ý thêm, báo lỗi về ứng dụng'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 6,
              child: Text('Donate ủng hộ-cảm ơn tác giả'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 7,
              child: Text('Điều khoản sử dụng'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 8,
              child: Text('Bảo mật và quyền riêng tư'),
            ),
          ],
        ),
      ),
    );
  }
}
