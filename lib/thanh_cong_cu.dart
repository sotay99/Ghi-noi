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
    required this.khiBamCaiDatKiemTraToanVan,
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

  /// Gắn với mục "Cài đặt nút "Kiểm tra toàn văn"" trong menu "Làm việc với
  /// AI" — mục duy nhất trong menu đó đã gắn logic thật, các mục còn lại
  /// (trò chuyện, tóm tắt, mở rộng, viết lại) chỉ là chỗ đặt trước.
  final VoidCallback khiBamCaiDatKiemTraToanVan;
  final VoidCallback khiBamBanPhim;
  final VoidCallback khiBamKiemTraToanVan;
  final VoidCallback khiBamGhiAmAI;

  /// Ngưỡng bề ngang chuẩn của Material để phân biệt điện thoại (hẹp) với
  /// máy tính bảng/màn hình gập mở ra (rộng) — đủ chỗ để các nút giãn ra
  /// thành khung có tên mà không giẫm chân lên nhau.
  static const _nguongManHinhRong = 600.0;

  Widget _nut(
    bool rong,
    IconData icon,
    String nhanHep,
    String nhanRong,
    VoidCallback khiBam, {
    Color mau = const Color(0xFF5F6368),
  }) {
    return rong
        ? _NutRong(bieuTuong: icon, nhan: nhanRong, khiBam: khiBam, mau: mau)
        : NutNho(bieuTuong: icon, nhan: nhanHep, khiBam: khiBam, mau: mau);
  }

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        bottom: neThanhDieuHuong,
        child: LayoutBuilder(
          builder: (context, rangBuoc) {
            final rong = rangBuoc.maxWidth >= _nguongManHinhRong;

            return Container(
              // Thấp hết mức còn bấm trúng: 48px vẫn đủ vùng chạm theo chuẩn
              // Material, mà nhường gần hết màn hình cho chữ.
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              // Micro đang bật (đỏ) thì đường kẻ ngăn cách với trang soạn
              // thảo cũng đỏ đậm và dày hẳn lên — dấu hiệu dễ thấy dù mắt
              // đang nhìn vào bài, không cần liếc xuống tận nút micro mới
              // biết đang ghi.
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
                  // Bên trái: hướng dẫn sát mép màn hình, rồi cài đặt, rồi
                  // hai nút mới (AI, bàn phím), rồi thư mục — dải này (KHÔNG
                  // gồm nút Ghi âm, sóng âm, micro) tô nền hồng nhạt khi micro
                  // đang bật, đồng bộ với đường kẻ đỏ phía trên. Container chỉ
                  // bọc riêng Expanded này, KHÔNG bọc luôn nút Ghi âm — nền
                  // hồng vì vậy CHẠM tới mép trái nút Ghi âm (liền kề, không
                  // khoảng hở) nhưng dừng lại đúng ở đó, không lấn vào trong
                  // nút. Bản thân các nút (Hướng dẫn/Cài đặt/…) không tự vẽ
                  // nền riêng, chỉ có icon/chữ, nên nền hồng của Container vẫn
                  // hiện được ở khoảng trống quanh chúng mà không "ám" màu
                  // lên icon hay chữ — icon/chữ luôn giữ đúng màu của nó.
                  Expanded(
                    child: Container(
                      color: bat ? Colors.red.shade50 : Colors.transparent,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        // Mặc định ScrollView CẮT mọi thứ tràn ra ngoài khung
                        // nhìn của nó — chú thích dọc của các nút bên trong
                        // đây cố ý vẽ TRÀN LÊN TRÊN nút (Positioned âm), nên
                        // phải tắt hẳn việc cắt này thì chú thích mới hiện ra
                        // được.
                        clipBehavior: Clip.none,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Hướng dẫn sử dụng',
                            child: _nut(rong, Icons.help_outline_rounded,
                                'Hướng dẫn', 'Hướng dẫn', khiBamHuongDan),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Cài đặt',
                            child: _nut(rong, Icons.settings_outlined,
                                'Cài đặt', 'Cài đặt', khiBamCaiDat),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Thư mục và Tệp tin',
                            child: _nut(rong, Icons.folder_outlined,
                                'Thư mục', 'Thư mục', khiBamThuMuc),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Làm việc với AI',
                            child: _NutAIMenu(
                              rong: rong,
                              khiBamCaiDatKiemTraToanVan: khiBamCaiDatKiemTraToanVan,
                            ),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Kiểm tra toàn văn (AI)',
                            child: _nut(
                              rong,
                              Icons.task_alt,
                              'Kiểm tra toàn văn bằng AI',
                              'Kiểm toàn văn',
                              khiBamKiemTraToanVan,
                              mau: Colors.green.shade600,
                            ),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Xem thêm lựa chọn',
                            child: _NutThemMenu(
                              rong: rong,
                              khiBamBanPhim: khiBamBanPhim,
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  _NutCoChuThich(
                    hien: hienChuThich,
                    chu: 'Ghi âm xong rồi mới ra chữ',
                    child: _nut(rong, Icons.settings_voice,
                        'Ghi âm xong mới ra chữ', 'Ghi âm', khiBamGhiAmAI),
                  ),

                  // Bên phải: sóng âm, rồi micro sát mép phải. Micro luôn
                  // giữ nguyên giao diện tròn quen thuộc, kể cả ở màn hình
                  // rộng — và không nằm trong dải nền hồng phía trên.
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
            );
          },
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
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            // Nền trắng RIÊNG của nút — không lấy màu nền của thanh công cụ
            // (thường là trắng, nhưng đổi hồng nhạt lúc micro bật). Trắng
            // trên trắng thì không thấy khác gì, nhưng trên nền hồng thì nút
            // vẫn giữ nguyên trắng, không bị nhuộm theo.
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(bieuTuong, size: 20, color: mau),
          ),
        ),
      ),
    );
  }
}

/// Khung trực quan của một nút "mở rộng": icon sát mép trái bên trong khung
/// viền bo tròn, tên nút liền ngay bên phải icon. Tách riêng phần khung khỏi
/// phần bắt chạm (`_NutRong` bên dưới, hoặc `PopupMenuButton.child` cho nút
/// dấu cộng) vì có chỗ cần InkWell riêng, có chỗ nút cha (PopupMenuButton) đã
/// tự lo việc bắt chạm rồi.
class _KhungNutRong extends StatelessWidget {
  const _KhungNutRong({
    required this.bieuTuong,
    required this.nhan,
    this.mau = const Color(0xFF5F6368),
  });

  final IconData bieuTuong;
  final String nhan;
  final Color mau;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      // Nền trắng riêng, không lấy màu nền của thanh công cụ — xem giải
      // thích ở NutNho.
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDADCE0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(bieuTuong, size: 16, color: mau),
          const SizedBox(width: 6),
          Text(nhan, style: TextStyle(fontSize: 12, color: mau)),
        ],
      ),
    );
  }
}

/// Nút "mở rộng" dùng cho màn hình rộng: cùng khung với `_KhungNutRong`,
/// nhưng tự lo việc bắt chạm (những nút gọi thẳng một callback, khác với nút
/// dấu cộng vốn đã nằm sẵn trong `PopupMenuButton`).
class _NutRong extends StatelessWidget {
  const _NutRong({
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: khiBam,
          borderRadius: BorderRadius.circular(16),
          child: _KhungNutRong(bieuTuong: bieuTuong, nhan: nhan, mau: mau),
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

/// Một dòng trong menu thả xuống của nút dấu cộng — cao vừa đủ chữ, viền sát
/// chữ, không rộng thùng thình như PopupMenuItem mặc định (cao tối thiểu 48).
PopupMenuItem<int> _mucMenuThem(int gia, String chu) {
  return PopupMenuItem<int>(
    value: gia,
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Text(chu, style: const TextStyle(fontSize: 13)),
  );
}

/// Nút dấu cộng ở thanh công cụ: mở một menu sổ lên (nằm trên đỉnh nút, vì
/// nút ở sát đáy màn hình — PopupMenuButton tự né mép màn hình nên không cần
/// tự tính toán vị trí). Đa số các mục chưa gắn logic gì, chỉ là chỗ đặt
/// trước cho tính năng sau này.
class _NutThemMenu extends StatelessWidget {
  const _NutThemMenu({required this.rong, required this.khiBamBanPhim});

  final bool rong;

  /// Gắn với mục "Kiểu gõ bàn phím" trong danh sách.
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
          child: rong
              ? const _KhungNutRong(
                  bieuTuong: Icons.add_circle_outline,
                  nhan: 'Thêm lựa chọn',
                )
              : Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  // Nền trắng riêng — cùng lý do với NutNho.
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_circle_outline,
                      size: 20, color: Color(0xFF5F6368)),
                ),
          onSelected: (gia) {
            if (gia == 4) khiBamBanPhim();
          },
          itemBuilder: (ctx) => [
            _mucMenuThem(1, 'Thêm ảnh'),
            _mucMenuThem(2, 'Chụp ảnh (camera)'),
            const PopupMenuDivider(height: 8),
            _mucMenuThem(3, 'Bật bộ điều hướng và phím nhanh'),
            _mucMenuThem(4, 'Kiểu gõ bàn phím'),
            _mucMenuThem(5, 'Luyện gõ phím bằng 10 ngón tay'),
            const PopupMenuDivider(height: 8),
            _mucMenuThem(6, 'Chia sẻ ứng dụng này đến với mọi người'),
            _mucMenuThem(7, 'Góp ý thêm, báo lỗi về ứng dụng'),
            _mucMenuThem(8, 'Donate ủng hộ-cảm ơn tác giả'),
            const PopupMenuDivider(height: 8),
            _mucMenuThem(9, 'Điều khoản sử dụng'),
            _mucMenuThem(10, 'Bảo mật và quyền riêng tư'),
            const PopupMenuDivider(height: 8),
            _mucMenuThem(11, 'Đăng nhập tài khoản'),
          ],
        ),
      ),
    );
  }
}

/// Menu thả xuống của nút "Làm việc với AI" — cùng cơ chế với
/// `_NutThemMenu` (PopupMenuButton tự neo ngay phía trên nút vì nút nằm sát
/// đáy màn hình). Bốn mục đầu chưa gắn logic, chỉ mục cuối "Cài đặt nút
/// "Kiểm tra toàn văn"" gọi callback thật.
class _NutAIMenu extends StatelessWidget {
  const _NutAIMenu({required this.rong, required this.khiBamCaiDatKiemTraToanVan});

  final bool rong;
  final VoidCallback khiBamCaiDatKiemTraToanVan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Làm việc với AI',
      child: Tooltip(
        message: 'Làm việc với AI',
        child: PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          splashRadius: 20,
          child: rong
              ? const _KhungNutRong(
                  bieuTuong: Icons.smart_toy_outlined,
                  nhan: 'Làm việc với AI',
                )
              : Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_outlined,
                      size: 20, color: Color(0xFF5F6368)),
                ),
          onSelected: (gia) {
            if (gia == 5) khiBamCaiDatKiemTraToanVan();
          },
          itemBuilder: (ctx) => [
            _mucMenuThem(1, 'Trò chuyện về văn bản này'),
            _mucMenuThem(2, 'Tóm tắt toàn văn'),
            _mucMenuThem(3, 'Mở rộng toàn văn'),
            _mucMenuThem(4, 'Viết lại cho hay hơn'),
            const PopupMenuDivider(height: 8),
            PopupMenuItem<int>(
              value: 5,
              height: 34,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Cài đặt nút "Kiểm tra toàn văn"',
                    style: TextStyle(color: Colors.green.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
