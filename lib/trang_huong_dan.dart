// Trang Hướng dẫn: một bài viết dài, trình bày như một trang thiết kế thật
// sự — tiêu đề lớn, tiêu đề phụ có màu, đoạn văn có chữ đậm/tô nền/đổi màu,
// thẻ thống kê, hộp mẹo, trích dẫn — chứ không phải một khối chữ đơn điệu.

import 'package:flutter/material.dart';

const _mauChinh = Color(0xFF1A73E8);
const _mauChinhDam = Color(0xFF0B3D91);

class ManHinhHuongDan extends StatelessWidget {
  const ManHinhHuongDan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _mauChinh,
            foregroundColor: Colors.white,
            title: const Text('Hướng dẫn'),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _Hero(),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HopMoDau(),
                      SizedBox(height: 28),
                      _MucLon(so: 'I', tieuDe: 'Vì sao Flowrite ra đời?'),
                      SizedBox(height: 14),
                      _Doan(_doan1),
                      SizedBox(height: 12),
                      _Doan(_doan2),
                      SizedBox(height: 12),
                      _OGoiY(
                        icon: Icons.error_outline,
                        mau: Color(0xFFD93025),
                        mauNen: Color(0xFFFCE8E6),
                        tieuDe: 'Nỗi bức xúc chưa app nào giải quyết',
                        noiDung: _oGoiY1,
                      ),
                      SizedBox(height: 28),
                      _MucLon(so: 'II', tieuDe: 'Nhanh gấp bội — có số liệu hẳn hoi'),
                      SizedBox(height: 14),
                      _Doan(_doan3),
                      SizedBox(height: 18),
                      _HangTheThongKe(),
                      SizedBox(height: 18),
                      _Doan(_doan4),
                      SizedBox(height: 28),
                      _MucLon(so: 'III', tieuDe: 'Hai nỗi đau, một lời giải'),
                      SizedBox(height: 14),
                      _Doan(_doan5),
                      SizedBox(height: 14),
                      _TheHanChe(
                        mau: Color(0xFFB06000),
                        mauNen: Color(0xFFFEF7E0),
                        icon: Icons.record_voice_over_outlined,
                        tieuDe: 'Nói — nhanh nhưng dễ vấp',
                        gachDau: _hanCheNoi,
                      ),
                      SizedBox(height: 12),
                      _TheHanChe(
                        mau: Color(0xFF185ABC),
                        mauNen: Color(0xFFE8F0FE),
                        icon: Icons.keyboard_outlined,
                        tieuDe: 'Gõ tay — chuẩn nhưng chậm và mỏi',
                        gachDau: _hanCheGo,
                      ),
                      SizedBox(height: 14),
                      _Doan(_doan6),
                      SizedBox(height: 28),
                      _MucLon(so: 'IV', tieuDe: 'Flowrite dành cho ai?'),
                      SizedBox(height: 14),
                      _Doan(_doan7),
                      SizedBox(height: 14),
                      _DanhSachDoiTuong(),
                      SizedBox(height: 28),
                      _MucLon(so: 'V', tieuDe: 'Bí quyết để nhanh hơn nữa'),
                      SizedBox(height: 14),
                      _Doan(_doan8),
                      SizedBox(height: 14),
                      _OGoiY(
                        icon: Icons.keyboard_alt_outlined,
                        mau: _mauChinhDam,
                        mauNen: Color(0xFFE8F0FE),
                        tieuDe: 'Chọn đúng bàn phím',
                        noiDung: _oGoiYBanPhim,
                      ),
                      SizedBox(height: 12),
                      _OGoiY(
                        icon: Icons.translate_outlined,
                        mau: Color(0xFF188038),
                        mauNen: Color(0xFFE6F4EA),
                        tieuDe: 'Chọn đúng bộ gõ',
                        noiDung: _oGoiYBoGo,
                      ),
                      SizedBox(height: 12),
                      _OGoiY(
                        icon: Icons.school_outlined,
                        mau: Color(0xFF9334E6),
                        mauNen: Color(0xFFF3E8FD),
                        tieuDe: 'Học gõ mười ngón, không nhìn phím',
                        noiDung: _oGoiYMuoiNgon,
                      ),
                      SizedBox(height: 12),
                      _OGoiY(
                        icon: Icons.mic_external_on_outlined,
                        mau: Color(0xFFD01884),
                        mauNen: Color(0xFFFCE4EC),
                        tieuDe: 'Dùng micro rời — nghe rõ hơn hẳn',
                        noiDung: _oGoiYMicroRoi,
                      ),
                      SizedBox(height: 28),
                      _TrichDan(),
                      SizedBox(height: 8),
                    ],
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 32),
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
          Text(
            'Nói ra ý tưởng, gõ tay sửa liền — không đợi, không xung đột, '
            'không mất mạch suy nghĩ.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
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
  const _HopMoDau();

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
      child: const _Doan(
        'Nói và gõ tay, xưa nay luôn phải **chọn một**: bật giọng nói thì '
        'tắt bàn phím, ngồi gõ thì im giọng nói. Flowrite phá bỏ luật đó — '
        'để bạn ==nói và gõ cùng lúc, không lẫn không đè lên nhau==, ra chữ '
        'nhanh hơn hẳn cách làm cũ.',
      ),
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

// -------------------------------------------------------------- thống kê

class _HangTheThongKe extends StatelessWidget {
  const _HangTheThongKe();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _TheThongKe(
          icon: Icons.keyboard_outlined,
          mau: Color(0xFF185ABC),
          nhan: 'Gõ tay thông thường',
          soLieu: '≈ 35–45 từ/phút',
        ),
        SizedBox(height: 10),
        _TheThongKe(
          icon: Icons.record_voice_over_outlined,
          mau: Color(0xFFB06000),
          nhan: 'Nói chuyện bình thường',
          soLieu: '≈ 130–150 từ/phút',
        ),
        SizedBox(height: 10),
        _TheThongKe(
          icon: Icons.bolt,
          mau: Color(0xFF188038),
          nhan: 'Nói + gõ tay xen kẽ trong Flowrite',
          soLieu: 'Gấp 3–4 lần cách gõ tay thuần tuý',
          noiBat: true,
        ),
      ],
    );
  }
}

class _TheThongKe extends StatelessWidget {
  const _TheThongKe({
    required this.icon,
    required this.mau,
    required this.nhan,
    required this.soLieu,
    this.noiBat = false,
  });

  final IconData icon;
  final Color mau;
  final String nhan;
  final String soLieu;
  final bool noiBat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: noiBat ? mau : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: noiBat ? mau : const Color(0xFFE0E0E0)),
        boxShadow: noiBat
            ? [BoxShadow(color: mau.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      // Xếp dọc, không xếp ngang: nhãn và số liệu cùng nằm trên một hàng thì
      // hàng chữ dài (như "Nói + gõ tay xen kẽ trong Flowrite") ép ô còn lại
      // hẹp tới mức vỡ chữ ra từng ký tự một trên màn hình điện thoại. Xếp
      // dọc thì nhãn và số liệu đều được dùng toàn bộ bề ngang, không bao
      // giờ bị bóp bất kể màn hình rộng hay hẹp.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: noiBat ? Colors.white : mau, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nhan,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: noiBat ? Colors.white : const Color(0xFF5F6368),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            soLieu,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: noiBat ? Colors.white : mau,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- đối tượng

class _DanhSachDoiTuong extends StatelessWidget {
  const _DanhSachDoiTuong();

  static const _muc = [
    (Icons.menu_book_outlined, 'Nhà văn, người viết truyện', 'tuôn trào mạch cảm xúc bằng lời nói, không bị ngắt quãng vì gõ chậm.'),
    (Icons.campaign_outlined, 'Người viết content, chạy quảng cáo', 'ra bản nháp nhanh gấp nhiều lần, còn thời gian đầu tư vào chỉnh sửa.'),
    (Icons.smart_toy_outlined, 'Người soạn lệnh (prompt) cho AI', 'mô tả yêu cầu dài, chi tiết, nhiều ràng buộc mà không ngại gõ mỏi tay.'),
    (Icons.code_outlined, 'Người làm "vibe coding" — lập trình bằng cách mô tả ý tưởng cho AI viết code', 'diễn giải logic phức tạp bằng lời, để AI hiện thực hoá thành mã nguồn.'),
    (Icons.school_outlined, 'Sinh viên, người ghi chú bài giảng', 'ghi lại ý chính ngay khi đang nghe, không sợ chậm tay lỡ mất câu sau.'),
    (Icons.directions_walk_outlined, 'Người bận rộn, tranh thủ lúc di chuyển', 'đọc chính tả khi đang đi, đang chờ, rồi về gõ tay chỉnh sửa cho gọn.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (icon, ten, moTa) in _muc)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _mauChinh, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ten,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        moTa,
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF5F6368), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- trích dẫn

class _TrichDan extends StatelessWidget {
  const _TrichDan();

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
          const Text(
            'Kết hợp cả năm điều trên — nói và gõ không xung đột, bàn phím '
            'tốt, bộ gõ đúng ngôn ngữ, đôi tay đã luyện mười ngón, và một '
            'chiếc micro nghe rõ từng lời — bạn sẽ đứng vào nhóm những người '
            'soạn thảo văn bản nhanh nhất thế giới.',
            style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(height: 14),
          Text(
            'Flowrite không thay bạn viết — nó chỉ dọn đường để ý tưởng của '
            'bạn ra tới trang giấy nhanh nhất có thể.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- văn bản

const _doan1 =
    'Bạn đã bao giờ rơi vào tình huống này chưa: đang **thao thao bất tuyệt** '
    'đọc chính tả cho điện thoại ghi lại, chợt nhận ra mình lỡ dùng sai một '
    'từ hoặc muốn chêm ngay một con số vào giữa câu — thế là phải dừng nói, '
    'bấm nút tắt micro, gõ sửa, rồi bấm mở micro lại, cố nhớ xem mình đang '
    'nói dở tới đâu? Từng ứng dụng ghi âm chuyển chữ trên thị trường, dù tốt '
    'đến mấy, đều buộc bạn chọn MỘT trong hai: hoặc là **nói**, hoặc là **gõ** '
    '— không có ứng dụng nào cho phép hai việc đó diễn ra ĐAN XEN một cách '
    'tự nhiên, an toàn, không giẫm chân lên nhau.';

const _doan2 =
    'Flowrite sinh ra chính là để giải quyết đúng nỗi bức xúc đó. Bạn có thể '
    'nói một câu dài, rồi ngay lập tức đưa tay gõ chèn một từ, một con số, '
    'một dấu câu — mà không cần tắt micro thủ công, không lo chữ bị lặp, '
    'không lo giọng nói và ký tự gõ tay "đá nhau" làm hỏng cả câu. Đây là bài '
    'toán tưởng chừng đơn giản nhưng **cực kỳ khó làm cho đúng**: ứng dụng '
    'phải tự nhận biết ký tự nào đến từ giọng nói, ký tự nào đến từ bàn '
    'phím, để ứng xử khác nhau trong từng tình huống — điều mà rất ít ứng '
    'dụng chịu đầu tư làm tới nơi tới chốn.';

const _oGoiY1 =
    'Tất cả các ứng dụng gõ chính tả phổ biến hiện nay coi giọng nói và bàn '
    'phím là **hai chế độ tách biệt**: bật cái này thì tắt cái kia. Flowrite '
    'là nỗ lực để hai chế độ đó ==chạy song song thật sự==, không phải giả '
    'lập bằng cách bật tắt luân phiên.';

const _doan3 =
    'Tốc độ nói của một người bình thường nhanh hơn tốc độ gõ tay của người '
    'gõ giỏi rất nhiều lần. Đây không phải là con số Flowrite tự nhận, mà là '
    'những mức tham khảo phổ biến vẫn được nhắc tới khi so sánh tốc độ nói '
    'và tốc độ gõ của con người:';

const _doan4 =
    'Con số ~~gấp 3-4 lần~~ ở trên là ước tính MINH HOẠ cho trải nghiệm '
    'thực tế khi bạn dùng Flowrite: phần lớn nội dung tuôn ra bằng giọng nói '
    'với tốc độ gần bằng lúc bạn nói chuyện, chỉ xen vào những đoạn gõ tay '
    'ngắn để sửa lỗi hoặc thêm chi tiết — chứ không phải một phép đo khoa '
    'học chính xác tuyệt đối cho mọi người, mọi giọng nói, mọi ngôn ngữ.';

const _doan5 =
    'Không có cách soạn thảo nào là hoàn hảo tuyệt đối — nói và gõ tay mỗi '
    'cách đều có điểm mạnh và điểm yếu riêng. Vấn đề không phải là chọn bên '
    'nào, mà là **để mỗi cách làm đúng phần việc nó giỏi nhất**.';

const _hanCheNoi = [
  'Bộ nhận dạng giọng nói vẫn có lúc nghe sai từ, đặc biệt với tên riêng, thuật ngữ chuyên ngành, hay khi môi trường ồn.',
  'Nói tự nhiên thường ra câu không có cấu trúc logic chặt chẽ như văn viết — nhiều từ đệm, câu dài lan man.',
  'Dấu câu (phẩy, chấm, xuống dòng) thường bị thiếu hoặc đặt sai chỗ, vì khi nói ít ai tự nhắc "chấm câu" giữa chừng.',
];

const _hanCheGo = [
  'Tốc độ gõ bị giới hạn bởi tốc độ ngón tay — kể cả người gõ nhanh cũng khó vượt qua tốc độ nói chuyện bình thường.',
  'Gõ liên tục trong thời gian dài gây mỏi tay, mỏi cổ tay, và với điện thoại là mỏi cả hai ngón cái.',
  'Cúi nhìn màn hình gõ lâu dễ mỏi cổ, mỏi mắt — một vấn đề tư thế quen thuộc của thời đại cầm điện thoại cả ngày.',
];

const _doan6 =
    'Flowrite để giọng nói lo phần **tốc độ** — tuôn ý tưởng ra thật nhanh — '
    'và để đôi tay lo phần **độ chính xác** — sửa lỗi chính tả, thêm dấu câu, '
    'chỉnh câu chữ cho logic — ngay tại chỗ, ngay lúc đang nói, không cần '
    'dừng lại quy trình nào cả. Hai điểm yếu tự triệt tiêu lẫn nhau.';

const _doan7 =
    'Bất kỳ ai cần tạo ra văn bản NHIỀU và NHANH đều được lợi từ Flowrite, '
    'nhưng có vài nhóm người sẽ thấy sự khác biệt rõ rệt nhất:';

const _doan8 =
    'Bản thân ứng dụng chỉ là một nửa câu chuyện — nửa còn lại nằm ở chính '
    'thói quen của bạn. Vài điều chỉnh nhỏ dưới đây có thể nhân đôi, nhân ba '
    'hiệu quả của việc kết hợp nói và gõ:';

const _oGoiYBanPhim =
    'Bàn phím ảo trên màn hình cảm ứng chỉ để dùng tạm — gõ chậm hơn, dễ gõ '
    'nhầm, và không có phản hồi lực bấm để ngón tay "nhớ vị trí phím". Nếu '
    'soạn thảo nhiều, hãy **gắn thêm một bàn phím rời** cho điện thoại/máy '
    'tính bảng qua Bluetooth. Có điều kiện hơn thì bàn phím cơ (cơ khí) cho '
    'cảm giác gõ rõ ràng, độ nảy tốt, giúp gõ nhanh và chính xác hơn hẳn so '
    'với bàn phím màng thông thường.';

const _oGoiYBoGo =
    'Hãy chắc chắn bạn đang dùng đúng bộ gõ cho ngôn ngữ mình viết — với '
    'tiếng Việt là các kiểu gõ **Telex** hoặc **VNI** quen thuộc. Một bộ gõ '
    'phù hợp, được thiết lập đúng, giúp gõ dấu nhanh và chính xác hơn nhiều '
    'so với việc gõ chữ có dấu theo kiểu thủ công từng ký tự.';

const _oGoiYMuoiNgon =
    'Kỹ năng có ảnh hưởng lớn nhất tới tốc độ gõ tay chính là **gõ mười '
    'ngón mà không cần nhìn xuống bàn phím**. Người mới tập thường chỉ gõ '
    'bằng vài ngón và phải liên tục liếc bàn phím, vừa chậm vừa dễ sai. Có '
    'rất nhiều trang web luyện gõ mười ngón miễn phí và trực quan — chỉ cần '
    'tìm "luyện gõ mười ngón" hoặc "typing practice" là ra hàng loạt lựa '
    'chọn để luyện tập mỗi ngày vài phút. Kiên trì một thời gian ngắn, tốc '
    'độ gõ của bạn có thể tăng gấp đôi, gấp ba so với gõ theo bản năng.';

const _oGoiYMicroRoi =
    'Micro của điện thoại thường nằm ở cạnh dưới máy — càng xa miệng, máy '
    'càng khó nghe rõ, càng dễ nhận nhầm chữ. Một chiếc **micro rời** (micro '
    'cài áo, tai nghe có micro) đặt gần miệng hơn hẳn, giúp bộ nhận dạng '
    'nghe chuẩn hơn thấy rõ.\n\n'
    'Vài mẹo nhỏ giúp giọng nói tới máy sạch nhất: luôn để micro **sát '
    'miệng**, ưu tiên loại có ==bộ lọc chống ồn== nếu có điều kiện, và cố '
    'gắng thu âm ở nơi yên tĩnh. Ở chỗ ồn mà không có micro rời, một mẹo đơn '
    'giản là lấy tay khum lại che quanh miệng và micro của máy — vừa chắn '
    'bớt tiếng ồn xung quanh, vừa hướng giọng nói thẳng vào micro.';
