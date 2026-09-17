// Thanh ngang dưới màn hình soạn thảo: bên trái là hướng dẫn, cài đặt, làm
// việc với AI, bàn phím, thư mục; bên phải là sóng âm rồi micro sát mép phải
// màn hình. Tự nằm khít mép trên bàn phím ảo — việc đó do trang gọi widget
// này lo, ở đây chỉ vẽ giao diện.

import 'dart:async';

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
    required this.khiBamChepTatCa,
    required this.khiBamChepRoiXoaTatCa,
    required this.khiBamXoaTatCa,
    required this.khiBamDanhSachPhimTat,
    required this.khiBamTimKiem,
    required this.khiBamTroChuyen,
    required this.khiBamTaiKhoan,
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

  /// Ba mục đầu của menu "+ Thêm lựa chọn" — trước đây là ba nút riêng
  /// (Sao chép tất cả/Xoá tất cả trên thanh công cụ trên, cộng thêm mục gộp
  /// mới "Sao chép rồi xoá tất cả"), nay dồn cả vào đây.
  final VoidCallback khiBamChepTatCa;
  final VoidCallback khiBamChepRoiXoaTatCa;
  final VoidCallback khiBamXoaTatCa;

  /// Gắn với mục "Danh sách phím tắt", ngay dưới "Kiểu gõ bàn phím".
  final VoidCallback khiBamDanhSachPhimTat;

  /// Mục 8b: nút "Tìm kiếm" trước đây nằm ở thanh trên cùng (Lùi/Tiến/Lưu)
  /// của trang soạn thảo — nay dời vào menu "+ Thêm lựa chọn" của thanh
  /// này, dưới tên "Tìm kiếm và thay thế".
  final VoidCallback khiBamTimKiem;

  /// Mục 9: hai nút mới, chưa gắn logic.
  final VoidCallback khiBamTroChuyen;
  final VoidCallback khiBamTaiKhoan;

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
                          // Thứ tự mới (mục 10): Hướng dẫn, Thư mục, Làm
                          // việc với AI, Trò chuyện, Thêm lựa chọn, Tài
                          // khoản — "Cài đặt" và "Kiểm tra toàn văn" đã dời
                          // vào trong hai menu (mục 8b/8c).
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Hướng dẫn sử dụng',
                            child: _nut(rong, Icons.help_outline_rounded,
                                'Hướng dẫn', 'Hướng dẫn', khiBamHuongDan),
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
                              khiBamKiemTraToanVan: khiBamKiemTraToanVan,
                            ),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Trò chuyện với mọi người',
                            child: _nut(rong, Icons.chat,
                                'Trò chuyện', 'Trò chuyện', khiBamTroChuyen),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Xem thêm lựa chọn',
                            child: _NutThemMenu(
                              rong: rong,
                              khiBamBanPhim: khiBamBanPhim,
                              khiBamChepTatCa: khiBamChepTatCa,
                              khiBamChepRoiXoaTatCa: khiBamChepRoiXoaTatCa,
                              khiBamXoaTatCa: khiBamXoaTatCa,
                              khiBamDanhSachPhimTat: khiBamDanhSachPhimTat,
                              khiBamCaiDat: khiBamCaiDat,
                              khiBamTimKiem: khiBamTimKiem,
                            ),
                          ),
                          _NutCoChuThich(
                            hien: hienChuThich,
                            chu: 'Tài khoản của bạn',
                            child: _nut(rong, Icons.account_circle,
                                'Tài khoản', 'Tài khoản', khiBamTaiKhoan),
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

/// (VIỆC 3) Một dòng BẤM ĐƯỢC bên trong khung cuộn dùng chung của
/// `_mucCuonDanhSach` — thay cho một `PopupMenuItem` riêng lẻ (kiến trúc cũ
/// khiến Flutter tự dựng một `Scrollable` nội bộ không lấy lại được đáng tin
/// cậy, xem `_mucDongMenu`). Bấm vào tự đóng menu và trả về [gia] qua
/// `Navigator.pop`, ĐÚNG cơ chế mà một `PopupMenuItem` bình thường dùng nội
/// bộ — `onSelected` của `PopupMenuButton` vẫn nhận được giá trị y hệt,
/// không đổi gì ở phía gọi.
class _DongMenuCoTheBam extends StatelessWidget {
  const _DongMenuCoTheBam({
    required this.gia,
    required this.child,
    this.height = 34,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final int gia;
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop<int>(context, gia),
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: padding,
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

/// Một dòng trong menu thả xuống của nút dấu cộng — cao vừa đủ chữ, viền sát
/// chữ, không rộng thùng thình như PopupMenuItem mặc định (cao tối thiểu 48).
Widget _mucMenuThem(int gia, String chu) {
  return _DongMenuCoTheBam(
    gia: gia,
    child: Text(chu, style: const TextStyle(fontSize: 13)),
  );
}

/// Đường kẻ phân cách giữa các nhóm mục — GIỮ NGUYÊN chiều cao/vẻ ngoài của
/// `PopupMenuDivider(height: 8)` trước đây, chỉ đổi sang một `Divider`
/// thường vì các dòng giờ nằm trong một `Column` bên trong khung cuộn, không
/// còn là `PopupMenuEntry` riêng của `PopupMenuButton` nữa.
Widget _dividerMenu() => const Divider(height: 8, thickness: 1);

/// (VIỆC 3) Nút tròn nhỏ dùng chung cho hai nút cuộn (lên đầu/xuống cuối)
/// nằm cạnh nút X trong `_mucDongMenu`. Dùng `GestureDetector` riêng (không
/// phải `IconButton` — kích thước tối thiểu 48 của nó quá to cho hàng cao
/// 28) để bấm vào đây KHÔNG đóng menu: một widget bấm được lồng BÊN TRONG
/// `PopupMenuItem` luôn thắng trong đấu trường cử chỉ (gesture arena) trước
/// `InkWell` mặc định bọc ngoài của `PopupMenuItem` (cái vẫn khiến bấm vào
/// nút X đóng menu, vì X không có `onTap` riêng) — đây là hành vi chuẩn của
/// Flutter với các widget bấm được lồng nhau, không cần tự chặn sự kiện nổi
/// bọt (bubbling) thủ công.
///
/// StatefulWidget (không phải Stateless như trước) để có `dispose()` HUỶ
/// ĐÚNG CÁCH bộ đếm giờ của [onHoverTick] — [onHoverTick] (nếu có) được gọi
/// LIÊN TỤC (~40 lần/giây) trong lúc con trỏ CHUỘT đang rê trên nút, để cuộn
/// dần mà không cần bấm (hữu ích trên tablet/Chromebook/bản thử desktop có
/// chuột; trên cảm ứng thuần như điện thoại Android, `MouseRegion` không bao
/// giờ kích hoạt nên callback này đơn giản không được gọi — không lỗi, không
/// ảnh hưởng gì). Bộ đếm giờ được huỷ ở CẢ `onExit` (rê chuột ra khỏi nút)
/// LẪN `dispose()` (nút bị gỡ khỏi cây — ví dụ menu đóng lại) nên không có
/// đường nào rò rỉ.
class _NutCuonMenu extends StatefulWidget {
  const _NutCuonMenu({required this.icon, required this.onTap, this.onHoverTick});

  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onHoverTick;

  @override
  State<_NutCuonMenu> createState() => _NutCuonMenuState();
}

class _NutCuonMenuState extends State<_NutCuonMenu> {
  Timer? _henCuonLienTuc;

  void _batCuonLienTuc() {
    _henCuonLienTuc?.cancel();
    final tick = widget.onHoverTick;
    if (tick == null) return;
    _henCuonLienTuc = Timer.periodic(const Duration(milliseconds: 24), (_) => tick());
  }

  void _dungCuonLienTuc() {
    _henCuonLienTuc?.cancel();
    _henCuonLienTuc = null;
  }

  @override
  void dispose() {
    _henCuonLienTuc?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duocBam = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => _batCuonLienTuc(),
      onExit: (_) => _dungCuonLienTuc(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: duocBam ? Colors.grey.shade300 : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: 13,
            color: duocBam ? Colors.grey.shade800 : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

/// (VIỆC 3) Mục đầu tiên của cả hai menu (`_NutThemMenu`, `_NutAIMenu`): một
/// hàng gồm hai nút cuộn (lên đầu / xuống cuối) và nút tròn đỏ chữ X đóng
/// menu ngay lập tức. Dùng `value: -1` (không khớp case nào trong
/// `onSelected`) để việc bấm nút X tự đóng menu theo đúng cơ chế mặc định
/// của `PopupMenuItem` — vì đây vẫn là một `PopupMenuItem` bình thường
/// (enabled mặc định) trong cùng danh sách, không phải widget tự vẽ lồng bên
/// trong, nên KHÔNG bị ăn màu mờ và không đẩy các mục khác vào một khung
/// cuộn bó hẹp.
///
/// [controller] là bộ điều khiển cuộn THẬT của khung cuộn ở `_mucCuonDanhSach`
/// — được TẠO Ở NGOÀI, trong `itemBuilder`, và truyền tay vào ĐÂY, KHÔNG còn
/// dò tìm qua `Scrollable.maybeOf(context)` (cách cũ không đáng tin: có thể
/// tìm trúng một `Scrollable` không phải cái mình muốn, hoặc bấm không thấy
/// tác dụng vì thời điểm đo `maxScrollExtent` chưa ổn định). Cùng MỘT
/// `controller` này được gán cho `SingleChildScrollView` ở
/// `_mucCuonDanhSach`, nên hai nút ở đây chắc chắn điều khiển ĐÚNG khung cuộn
/// chứa danh sách lựa chọn.
PopupMenuItem<int> _mucDongMenu(ScrollController controller) {
  void cuonToi(double dich) {
    if (!controller.hasClients) return;
    controller.animateTo(
      dich,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void nhichLen(double buoc) {
    if (!controller.hasClients) return;
    final vt = controller.position;
    controller.jumpTo((vt.pixels - buoc).clamp(0.0, vt.maxScrollExtent));
  }

  void nhichXuong(double buoc) {
    if (!controller.hasClients) return;
    final vt = controller.position;
    controller.jumpTo((vt.pixels + buoc).clamp(0.0, vt.maxScrollExtent));
  }

  return PopupMenuItem<int>(
    value: -1,
    height: 28,
    padding: EdgeInsets.zero,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _NutCuonMenu(
          icon: Icons.vertical_align_top,
          onTap: () => cuonToi(0),
          onHoverTick: () => nhichLen(14),
        ),
        const SizedBox(width: 6),
        _NutCuonMenu(
          icon: Icons.vertical_align_bottom,
          onTap: () => cuonToi(
            controller.hasClients ? controller.position.maxScrollExtent : 0,
          ),
          onHoverTick: () => nhichXuong(14),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

/// (VIỆC 3) Mục thứ hai của cả hai menu: TOÀN BỘ các mục lựa chọn còn lại
/// ([muc], đã gồm cả các đường kẻ phân cách `_dividerMenu()`) gộp vào MỘT
/// `PopupMenuItem` DUY NHẤT — thay cho mỗi mục một `PopupMenuItem` riêng như
/// trước (kiến trúc khiến hai nút cuộn ở `_mucDongMenu` không lấy lại được
/// đúng khung cuộn một cách đáng tin cậy). `enabled: true` (mặc định) +
/// `padding: EdgeInsets.zero` để không bị tô mờ xám như khi dùng
/// `enabled: false`.
///
/// Bọc trong `ConstrainedBox(maxHeight: ...)` + `SingleChildScrollView`
/// (`shrinkWrap: true`, gắn [controller]) thay vì để trần: khung cuộn nội bộ
/// SẴN CÓ của chính `PopupMenuButton` (một `SingleChildScrollView` khác, bọc
/// toàn bộ danh sách mục) cho con của nó chiều cao KHÔNG GIỚI HẠN — lồng
/// thẳng một `SingleChildScrollView` khác vào đó (chiều cuộn giống hệt) sẽ
/// ném lỗi "unbounded height". Giới hạn chiều cao TỐI ĐA ở đây (một tỉ lệ
/// màn hình, có trần) vừa tránh lỗi đó, vừa giữ đúng yêu cầu "không cuộn ép
/// vào khung nhỏ nếu đủ chỗ": `shrinkWrap: true` khiến khung tự co theo đúng
/// chiều cao nội dung khi nội dung NGẮN hơn trần, chỉ thật sự cuộn khi nội
/// dung DÀI hơn.
PopupMenuItem<int> _mucCuonDanhSach(
  BuildContext context,
  ScrollController controller,
  List<Widget> muc,
) {
  final caoManHinh = MediaQuery.sizeOf(context).height;
  final gioiHanCao = (caoManHinh * 0.65).clamp(240.0, 560.0);
  return PopupMenuItem<int>(
    enabled: true,
    padding: EdgeInsets.zero,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: gioiHanCao),
      child: SingleChildScrollView(
        controller: controller,
        shrinkWrap: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: muc,
        ),
      ),
    ),
  );
}

/// Nút dấu cộng ở thanh công cụ: mở một menu sổ lên (nằm trên đỉnh nút, vì
/// nút ở sát đáy màn hình — PopupMenuButton tự né mép màn hình nên không cần
/// tự tính toán vị trí). Đa số các mục chưa gắn logic gì, chỉ là chỗ đặt
/// trước cho tính năng sau này.
class _NutThemMenu extends StatelessWidget {
  const _NutThemMenu({
    required this.rong,
    required this.khiBamBanPhim,
    required this.khiBamChepTatCa,
    required this.khiBamChepRoiXoaTatCa,
    required this.khiBamXoaTatCa,
    required this.khiBamDanhSachPhimTat,
    required this.khiBamCaiDat,
    required this.khiBamTimKiem,
  });

  final bool rong;

  /// Gắn với mục "Kiểu gõ bàn phím" trong danh sách.
  final VoidCallback khiBamBanPhim;

  final VoidCallback khiBamChepTatCa;
  final VoidCallback khiBamChepRoiXoaTatCa;
  final VoidCallback khiBamXoaTatCa;
  final VoidCallback khiBamDanhSachPhimTat;

  /// Mục 8b: "Cài đặt" và "Tìm kiếm và thay thế" dời vào đây, đúng vị trí mà
  /// "Thêm ảnh"/"Chụp ảnh (camera)" vừa rời đi (nay ở menu "Làm việc với
  /// AI") — giữ nguyên logic cũ của cả hai, chỉ đổi chỗ đặt (và đổi tên hiển
  /// thị của nút tìm kiếm thành "Tìm kiếm và thay thế").
  final VoidCallback khiBamCaiDat;
  final VoidCallback khiBamTimKiem;

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
            switch (gia) {
              case 4:
                khiBamBanPhim();
                break;
              case 23:
                khiBamDanhSachPhimTat();
                break;
              case 20:
                khiBamChepTatCa();
                break;
              case 21:
                khiBamChepRoiXoaTatCa();
                break;
              case 22:
                khiBamXoaTatCa();
                break;
              case 24:
                khiBamCaiDat();
                break;
              case 25:
                khiBamTimKiem();
                break;
            }
          },
          // (VIỆC 3) Một `ScrollController` MỚI mỗi lần menu mở — `itemBuilder`
          // là một closure được GỌI LẠI mỗi lần bấm nút mở menu, nên biến cục
          // bộ này tồn tại đúng trong phạm vi vòng đời của route hiện tại,
          // không lẫn giữa các lần mở menu khác nhau. Dùng CHUNG giữa nút
          // cuộn (`_mucDongMenu`, đọc để `animateTo`/`jumpTo`) và khung cuộn
          // thật (`_mucCuonDanhSach`, gán `controller:`).
          itemBuilder: (ctx) {
            final cuon = ScrollController();
            return [
              // Nút X đỏ đóng menu + hai nút cuộn — luôn ở đầu danh sách,
              // KHÔNG cuộn theo phần còn lại.
              _mucDongMenu(cuon),
              _mucCuonDanhSach(ctx, cuon, [
                // Ba mục đầu — dời từ ba nút riêng trên thanh công cụ trên
                // (Sao chép tất cả/Xoá tất cả) xuống đây, cộng thêm mục gộp
                // mới "Sao chép rồi xoá tất cả".
                _mucMenuThem(20, 'Sao chép tất cả'),
                _mucMenuThem(21, 'Sao chép rồi xoá tất cả'),
                _mucMenuThem(22, 'Xoá tất cả'),
                _dividerMenu(),
                // "Thêm ảnh"/"Chụp ảnh (camera)" đã dời sang menu "Làm việc
                // với AI" (đổi tên "Chuyển hình ảnh thành văn bản") — "Cài
                // đặt" và "Tìm kiếm và thay thế" (trước đây là hai nút riêng
                // ngoài thanh công cụ) vào thay đúng vị trí này.
                _mucMenuThem(24, 'Cài đặt'),
                _mucMenuThem(25, 'Tìm kiếm và thay thế'),
                _dividerMenu(),
                _mucMenuThem(3, 'Bật bộ điều hướng và phím nhanh'),
                _mucMenuThem(4, 'Kiểu gõ bàn phím'),
                _mucMenuThem(23, 'Danh sách phím tắt'),
                _mucMenuThem(5, 'Luyện gõ phím bằng 10 ngón tay'),
                _dividerMenu(),
                _mucMenuThem(6, 'Chia sẻ ứng dụng này đến với mọi người'),
                _mucMenuThem(7, 'Góp ý thêm, báo lỗi về ứng dụng'),
                _mucMenuThem(8, 'Donate ủng hộ-cảm ơn tác giả'),
                _dividerMenu(),
                _mucMenuThem(9, 'Điều khoản sử dụng'),
                _mucMenuThem(10, 'Bảo mật và quyền riêng tư'),
                _dividerMenu(),
                _mucMenuThem(11, 'Đăng nhập tài khoản'),
              ]),
            ];
          },
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
  const _NutAIMenu({
    required this.rong,
    required this.khiBamCaiDatKiemTraToanVan,
    required this.khiBamKiemTraToanVan,
  });

  final bool rong;
  final VoidCallback khiBamCaiDatKiemTraToanVan;

  /// Mục 8c: "Kiểm tra toàn văn" dời từ một nút riêng ngoài thanh công cụ
  /// vào đây, giữ nguyên logic thật.
  final VoidCallback khiBamKiemTraToanVan;

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
            if (gia == 9) khiBamKiemTraToanVan();
          },
          // (VIỆC 3) Xem chú thích ở `_NutThemMenu` — cùng cơ chế: một
          // `ScrollController` mới mỗi lần menu mở, dùng chung giữa nút cuộn
          // và khung cuộn thật.
          itemBuilder: (ctx) {
            final cuon = ScrollController();
            return [
              // Nút X đỏ đóng menu + hai nút cuộn — luôn ở đầu danh sách,
              // KHÔNG cuộn theo phần còn lại.
              _mucDongMenu(cuon),
              _mucCuonDanhSach(ctx, cuon, [
                // Ba mục mới đầu menu — "Thêm ảnh"/"Chụp ảnh (camera)" dời
                // từ menu "+ Thêm lựa chọn" sang đây (đổi tên mục ảnh), cộng
                // thêm mục hoàn toàn mới cho âm thanh (chưa gắn logic).
                _mucMenuThem(6, 'Chuyển hình ảnh thành văn bản'),
                _mucMenuThem(7, 'Chụp ảnh (camera)'),
                _mucMenuThem(8, 'Chuyển file âm thanh thành văn bản'),
                _dividerMenu(),
                _mucMenuThem(1, 'Trò chuyện về văn bản này'),
                _mucMenuThem(2, 'Tóm tắt toàn văn'),
                _mucMenuThem(3, 'Mở rộng toàn văn'),
                _mucMenuThem(4, 'Viết lại cho hay hơn'),
                _dividerMenu(),
                // "Kiểm tra toàn văn" dời từ một nút riêng ngoài thanh công
                // cụ vào ngay TRÊN mục cài đặt của nó — giữ màu xanh lá +
                // icon dấu tích ở đây; mục cài đặt bên dưới không cần tô màu
                // lặp lại nữa.
                _DongMenuCoTheBam(
                  gia: 9,
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.task_alt, size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Kiểm tra toàn văn',
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ),
                _DongMenuCoTheBam(
                  gia: 5,
                  height: 34,
                  child: const Text('Cài đặt nút "Kiểm tra toàn văn"'),
                ),
              ]),
            ];
          },
        ),
      ),
    );
  }
}
