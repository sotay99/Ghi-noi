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
                      _MucLon(so: 'I', tieuDe: 'Nói và gõ tay cùng lúc'),
                      SizedBox(height: 14),
                      _Doan(_doan1),
                      SizedBox(height: 28),
                      _MucLon(so: 'II', tieuDe: 'Quản lý nhiều ghi chú, chuyển tệp trong một nhịp'),
                      SizedBox(height: 14),
                      _Doan(_doan2),
                      SizedBox(height: 14),
                      _TheHanChe(
                        mau: Color(0xFF185ABC),
                        mauNen: Color(0xFFE8F0FE),
                        icon: Icons.folder_copy_outlined,
                        tieuDe: 'Phần lớn app ghi chú khác chưa chú trọng điều này',
                        gachDau: _dacDiemDaTep,
                      ),
                      SizedBox(height: 28),
                      _MucLon(so: 'III', tieuDe: 'Trợ lý AI đi kèm'),
                      SizedBox(height: 14),
                      _Doan(_doan3),
                      SizedBox(height: 14),
                      _TheHanChe(
                        mau: Color(0xFF9334E6),
                        mauNen: Color(0xFFF3E8FD),
                        icon: Icons.auto_awesome_outlined,
                        tieuDe: 'Không cần rời khỏi app',
                        gachDau: _dacDiemAi,
                      ),
                      SizedBox(height: 28),
                      _MucLon(so: 'IV', tieuDe: 'Đồng bộ nhiều thiết bị'),
                      SizedBox(height: 14),
                      _Doan(_doan4),
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
        'bạn ==nói và gõ cùng lúc, không lẫn không đè lên nhau==, lại còn '
        'quản lý nhiều ghi chú, có AI hỗ trợ, đồng bộ mọi thiết bị.',
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
            'Nói nhanh, gõ chính xác, chuyển tệp tức khắc, có AI hỗ trợ, và '
            'mở đúng ghi chú ở bất kỳ thiết bị nào — đó là Flowrite.',
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
    'Phần lớn app ghi âm chuyển chữ buộc bạn chọn MỘT trong hai: hoặc **nói**, '
    'hoặc **gõ**. Flowrite để cả hai diễn ra ĐAN XEN tự nhiên — nói một câu '
    'dài, rồi đưa tay gõ chèn ngay một từ, một con số — không cần tắt micro, '
    'không lo giọng nói và ký tự gõ tay ==đá nhau làm hỏng câu==.';

const _doan2 =
    'Ghi chú được tổ chức theo **thư mục lồng nhau** như một cây thư mục '
    'thật — không phải một danh sách dài vô tổ chức. Và khi đang soạn một '
    'tệp, bạn chuyển ngay sang tệp kế tiếp trong cùng thư mục bằng nút '
    '**"Tệp trước/Tệp sau"** ngay tại màn hình soạn thảo.';

const _dacDiemDaTep = [
  'Chuyển qua ghi chú khác KHÔNG phải quay lại màn hình thư mục rồi bấm mở lại từng cái — chỉ một nút, ngay tại chỗ đang soạn.',
  'Hết tệp cuối tự vòng về tệp đầu (và ngược lại) — không bao giờ "kẹt ở biên".',
  'Tìm nhanh trong thư mục, và tuỳ chọn mở sẵn đúng ghi chú mỗi khi khởi động app.',
];

const _doan3 =
    'Không cần rời Flowrite để dùng AI — mọi tính năng AI nằm sẵn trong '
    'thanh công cụ, xử lý ngay trên văn bản đang soạn.';

const _dacDiemAi = [
  'Kiểm tra chính tả, tóm tắt, viết lại cả bài hoặc một đoạn đang chọn.',
  'Trò chuyện hỏi đáp ngay trong app để brainstorm hoặc hỏi về nội dung bài viết.',
  'Đọc ảnh chụp hoặc file âm thanh, tự động chuyển thành văn bản.',
];

const _doan4 =
    'Đăng nhập tài khoản Google (**hoàn toàn tuỳ chọn**) để mở đúng ghi chú '
    'đó ở một thiết bị khác — điện thoại, máy tính, trình duyệt nào cũng '
    'thấy cùng một dữ liệu.';

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
