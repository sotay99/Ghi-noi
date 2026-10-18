// Trang Hướng dẫn: một bài viết dài, trình bày như một trang thiết kế thật
// sự — tiêu đề lớn, tiêu đề phụ có màu, đoạn văn có chữ đậm/tô nền/đổi màu,
// thẻ thống kê, hộp mẹo, trích dẫn — chứ không phải một khối chữ đơn điệu.
//
// Nội dung dài (đoạn văn, danh sách) nằm ở `chuoi_huong_dan.dart` theo đa
// ngôn ngữ — trang này chỉ lắp khung, đọc `ngonNguHienTai` tại lúc build.

import 'package:flutter/material.dart';

import 'chuoi_huong_dan.dart';
import 'ngon_ngu.dart';

const _mauChinh = Color(0xFF1A73E8);
const _mauChinhDam = Color(0xFF0B3D91);

class ManHinhHuongDan extends StatelessWidget {
  const ManHinhHuongDan({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NgonNgu>(
      valueListenable: ngonNguHienTai,
      builder: (context, nn, _) => Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _mauChinh,
              foregroundColor: Colors.white,
              title: Text(ChHuongDan.tieuDeTrang(nn)),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Hero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HopMoDau(nn),
                        const SizedBox(height: 28),
                        _MucLon(so: 'I', tieuDe: ChHuongDan.mucI(nn)),
                        const SizedBox(height: 14),
                        _Doan(ChHuongDan.doan1(nn)),
                        const SizedBox(height: 28),
                        _MucLon(so: 'II', tieuDe: ChHuongDan.mucII(nn)),
                        const SizedBox(height: 14),
                        _Doan(ChHuongDan.doan2(nn)),
                        const SizedBox(height: 14),
                        _TheHanChe(
                          mau: const Color(0xFF185ABC),
                          mauNen: const Color(0xFFE8F0FE),
                          icon: Icons.folder_copy_outlined,
                          tieuDe: ChHuongDan.theDaTepTieuDe(nn),
                          gachDau: ChHuongDan.dacDiemDaTep(nn),
                        ),
                        const SizedBox(height: 28),
                        _MucLon(so: 'III', tieuDe: ChHuongDan.mucIII(nn)),
                        const SizedBox(height: 14),
                        _Doan(ChHuongDan.doan3b(nn)),
                        const SizedBox(height: 14),
                        _TheHanChe(
                          mau: const Color(0xFF188038),
                          mauNen: const Color(0xFFE6F4EA),
                          icon: Icons.content_paste_outlined,
                          tieuDe: ChHuongDan.theGoNhanhTieuDe(nn),
                          gachDau: ChHuongDan.dacDiemGoNhanh(nn),
                        ),
                        const SizedBox(height: 28),
                        _MucLon(so: 'IV', tieuDe: ChHuongDan.mucIV(nn)),
                        const SizedBox(height: 14),
                        _Doan(ChHuongDan.doan3(nn)),
                        const SizedBox(height: 14),
                        _TheHanChe(
                          mau: const Color(0xFF9334E6),
                          mauNen: const Color(0xFFF3E8FD),
                          icon: Icons.auto_awesome_outlined,
                          tieuDe: ChHuongDan.theAiTieuDe(nn),
                          gachDau: ChHuongDan.dacDiemAi(nn),
                        ),
                        const SizedBox(height: 28),
                        _MucLon(so: 'V', tieuDe: ChHuongDan.mucV(nn)),
                        const SizedBox(height: 14),
                        _Doan(ChHuongDan.doan4(nn)),
                        const SizedBox(height: 28),
                        _MucLon(so: 'VI', tieuDe: ChHuongDan.mucVI(nn)),
                        const SizedBox(height: 6),
                        _ChiChuNenTang(ChHuongDan.chiDanhAndroid(nn)),
                        const SizedBox(height: 14),
                        _Doan(ChHuongDan.doan5Widget(nn)),
                        const SizedBox(height: 14),
                        _CacBuocDanhSo(cacBuoc: ChHuongDan.cacBuocCaiWidget(nn)),
                        const SizedBox(height: 28),
                        _MucLon(so: 'VII', tieuDe: ChHuongDan.mucVII(nn)),
                        const SizedBox(height: 14),
                        _Doan(ChHuongDan.doan8(nn)),
                        const SizedBox(height: 14),
                        _OGoiY(
                          icon: Icons.keyboard_alt_outlined,
                          mau: _mauChinhDam,
                          mauNen: const Color(0xFFE8F0FE),
                          tieuDe: ChHuongDan.oGoiYBanPhimTieuDe(nn),
                          noiDung: ChHuongDan.oGoiYBanPhim(nn),
                        ),
                        const SizedBox(height: 12),
                        _OGoiY(
                          icon: Icons.translate_outlined,
                          mau: const Color(0xFF188038),
                          mauNen: const Color(0xFFE6F4EA),
                          tieuDe: ChHuongDan.oGoiYBoGoTieuDe(nn),
                          noiDung: ChHuongDan.oGoiYBoGo(nn),
                        ),
                        const SizedBox(height: 12),
                        _OGoiY(
                          icon: Icons.school_outlined,
                          mau: const Color(0xFF9334E6),
                          mauNen: const Color(0xFFF3E8FD),
                          tieuDe: ChHuongDan.oGoiYMuoiNgonTieuDe(nn),
                          noiDung: ChHuongDan.oGoiYMuoiNgon(nn),
                        ),
                        const SizedBox(height: 12),
                        _OGoiY(
                          icon: Icons.mic_external_on_outlined,
                          mau: const Color(0xFFD01884),
                          mauNen: const Color(0xFFFCE4EC),
                          tieuDe: ChHuongDan.oGoiYMicroRoiTieuDe(nn),
                          noiDung: ChHuongDan.oGoiYMicroRoi(nn),
                        ),
                        const SizedBox(height: 28),
                        _MucLon(so: 'VIII', tieuDe: ChHuongDan.mucVIII(nn)),
                        const SizedBox(height: 14),
                        _Doan(ChHuongDan.lienHe(nn)),
                        const SizedBox(height: 28),
                        _TrichDan(nn),
                        const SizedBox(height: 8),
                      ],
                    ),
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

// ------------------------------------------------------------------- hero

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_mauChinh, _mauChinhDam],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // (YÊU CẦU MỚI) Logo Flowrite thật — thay cho icon mic tạm trước
          // đây. `assets/logo.png` đã tự có nền xanh dương bo góc riêng, chỉ
          // cần viền trắng mỏng để tách khỏi nền gradient cùng tông màu.
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/logo.png'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'FLOWRITE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<NgonNgu>(
            valueListenable: ngonNguHienTai,
            builder: (context, nn, _) => Text(
              ChHuongDan.heroDongTrichDan(nn),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Số phiên bản cố định tại đây — chỉ đổi khi có yêu cầu, hoặc khi
          // app lên chợ ứng dụng thì đổi theo đúng bản phát hành thật.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Phiên bản v1.1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- mục lớn

// ------------------------------------------------------------- khung mở đầu

/// Nói thẳng vấn đề ngay dưới tiêu đề — ai lười đọc cả bài vẫn nắm được ý
/// chính trong vài giây.
class _HopMoDau extends StatelessWidget {
  const _HopMoDau(this.nn);
  final NgonNgu nn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFAECBFA)),
      ),
      child: _Doan(ChHuongDan.hopMoDau(nn)),
    );
  }
}

class _MucLon extends StatelessWidget {
  const _MucLon({required this.so, required this.tieuDe});

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
            color: _mauChinh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            so,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tieuDe,
            style: const TextStyle(
              fontSize: 20,
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

// --------------------------------------------- chú thích nền tảng / các bước

/// Dòng chú thích nhỏ, nghiêng, ngay dưới tiêu đề mục — báo rõ mục này chỉ
/// áp dụng cho MỘT nền tảng (ví dụ "Chỉ dành cho Android").
class _ChiChuNenTang extends StatelessWidget {
  const _ChiChuNenTang(this.chu);
  final String chu;

  @override
  Widget build(BuildContext context) {
    return Text(
      chu,
      style: const TextStyle(
        fontSize: 12.5,
        fontStyle: FontStyle.italic,
        color: Color(0xFF9AA0A6),
      ),
    );
  }
}

/// Danh sách các bước đánh số tròn — dùng cho hướng dẫn thao tác từng bước
/// (khác `_TheHanChe`/`dacDiemDaTep` là liệt kê đặc điểm, không phải thứ tự).
class _CacBuocDanhSo extends StatelessWidget {
  const _CacBuocDanhSo({required this.cacBuoc});
  final List<String> cacBuoc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cacBuoc.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _mauChinh, shape: BoxShape.circle),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _Doan(cacBuoc[i])),
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------- đoạn văn

/// Đoạn văn hỗ trợ đánh dấu nhẹ trong nguồn: `**đậm**`, `==tô nền==`,
/// `~~đổi màu~~` — tách bằng biểu thức chính quy rồi dựng thành TextSpan.
class _Doan extends StatelessWidget {
  const _Doan(this.vanBan);

  final String vanBan;

  static final _mauDanhDau =
      RegExp(r'\*\*(.+?)\*\*|==(.+?)==|~~(.+?)~~');

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
          style: const TextStyle(color: _mauChinh, fontWeight: FontWeight.w700),
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
        style: const TextStyle(fontSize: 15.5, height: 1.65, color: Color(0xFF3C4043)),
        children: _phanTich(),
      ),
    );
  }
}

// ---------------------------------------------------------------- hộp mẹo

class _OGoiY extends StatelessWidget {
  const _OGoiY({
    required this.icon,
    required this.mau,
    required this.mauNen,
    required this.tieuDe,
    required this.noiDung,
  });

  final IconData icon;
  final Color mau;
  final Color mauNen;
  final String tieuDe;
  final String noiDung;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mauNen,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: mau, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: mau, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tieuDe,
                  style: TextStyle(fontWeight: FontWeight.bold, color: mau, fontSize: 14.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Doan(noiDung),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- thẻ hạn chế

class _TheHanChe extends StatelessWidget {
  const _TheHanChe({
    required this.mau,
    required this.mauNen,
    required this.icon,
    required this.tieuDe,
    required this.gachDau,
  });

  final Color mau;
  final Color mauNen;
  final IconData icon;
  final String tieuDe;
  final List<String> gachDau;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mauNen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: mau, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tieuDe,
                  style: TextStyle(fontWeight: FontWeight.bold, color: mau, fontSize: 15.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final dong in gachDau)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: mau, shape: BoxShape.circle),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      dong,
                      style: const TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF3C4043)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- trích dẫn

class _TrichDan extends StatelessWidget {
  const _TrichDan(this.nn);
  final NgonNgu nn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_mauChinh, _mauChinhDam]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: Colors.white70, size: 30),
          const SizedBox(height: 8),
          Text(
            ChHuongDan.trichDanLon(nn),
            style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(height: 14),
          Text(
            ChHuongDan.trichDanNho(nn),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
