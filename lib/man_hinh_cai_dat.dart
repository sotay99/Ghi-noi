// Màn hình cài đặt: bốn dòng — thời gian bật lại micro, tự động chèn dấu
// cách, kiểm tra chính tả bằng AI (chưa làm, luôn tắt), và trạng thái quyền
// micro của thiết bị.

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'cai_dat.dart';

const _cacMucThoiGian = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, _khongTuBatLai];

/// Giá trị đặc biệt: micro tắt hẳn khi gõ phím, người dùng phải tự bấm nút
/// micro mới nghe lại — không có bộ đếm thời gian nào tự động bật hộ.
const _khongTuBatLai = -1.0;

class ManHinhCaiDat extends StatefulWidget {
  const ManHinhCaiDat({
    super.key,
    required this.caiDat,
    required this.khiTatTuDongChenKhoangCach,
    required this.khiKiemTraLaiMicro,
  });

  final CaiDat caiDat;

  /// Gọi ngay khi người dùng gạt dòng "tự động chèn dấu cách" từ Có sang
  /// Không — trang soạn thảo dùng đây để xoá bộ nhớ đánh dấu ký tự của nó.
  final VoidCallback khiTatTuDongChenKhoangCach;

  /// Gọi lại speech_to_text.initialize() để trang soạn thảo cập nhật xem
  /// micro có dùng được không, sau khi người dùng vừa xin quyền.
  final Future<void> Function() khiKiemTraLaiMicro;

  @override
  State<ManHinhCaiDat> createState() => _ManHinhCaiDatState();
}

class _ManHinhCaiDatState extends State<ManHinhCaiDat> {
  late double _thoiGian;
  late bool _tuDongChen;
  PermissionStatus? _trangThaiMicro;
  bool _dangXuLyMicro = false;

  @override
  void initState() {
    super.initState();
    _thoiGian = widget.caiDat.thoiGianBatLaiGiay;
    _tuDongChen = widget.caiDat.tuDongChenKhoangCach;
    _kiemTraQuyenMicro();
  }

  Future<void> _kiemTraQuyenMicro() async {
    final tt = await Permission.microphone.status;
    if (mounted) setState(() => _trangThaiMicro = tt);
  }

  Future<void> _capQuyenMicro() async {
    setState(() => _dangXuLyMicro = true);
    await Permission.microphone.request();
    await widget.khiKiemTraLaiMicro();
    await _kiemTraQuyenMicro();
    if (mounted) setState(() => _dangXuLyMicro = false);
  }

  Future<void> _moCaiDatUngDung() async {
    setState(() => _dangXuLyMicro = true);
    await openAppSettings();
    if (mounted) setState(() => _dangXuLyMicro = false);
  }

  String _nhanThoiGian(double giay) {
    if (giay == _khongTuBatLai) return 'Không tự động bật lại Micro';
    final tron = giay == giay.roundToDouble();
    final so =
        tron ? giay.toInt().toString() : giay.toStringAsFixed(1).replaceAll('.', ',');
    return '$so giây';
  }

  Future<void> _xacNhanTatTuDongChen() async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 28),
        title: const Text('Tắt tự động chèn dấu cách?'),
        content: const Text(
          'Bộ nhớ đang ghi nhớ chữ nào do tay gõ, chữ nào do giọng nói tạo ra '
          'sẽ bị XOÁ NGAY và KHÔNG LẤY LẠI ĐƯỢC — kể cả sau này bạn bật lại '
          'tính năng này. Bật lại chỉ có tác dụng cho chữ nói/gõ về sau, chữ '
          'đã có sẵn trong bài sẽ được coi là "gõ tay" hết.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Thôi, giữ nguyên'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Tắt và xoá'),
          ),
        ],
      ),
    );
    if (dongY != true) return;

    setState(() => _tuDongChen = false);
    await widget.caiDat.datTuDongChenKhoangCach(false);
    widget.khiTatTuDongChenKhoangCach();
  }

  /// Chữ giữa cặp **hai dấu sao** được in đậm — cách đánh dấu nhẹ nhàng để
  /// viết văn bản giải thích dài mà vẫn tô đậm được từ khoá quan trọng.
  List<InlineSpan> _phanTichDam(String vanBan) {
    final ketQua = <InlineSpan>[];
    final mauDam = RegExp(r'\*\*(.+?)\*\*');
    var viTri = 0;
    for (final m in mauDam.allMatches(vanBan)) {
      if (m.start > viTri) {
        ketQua.add(TextSpan(text: vanBan.substring(viTri, m.start)));
      }
      ketQua.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      viTri = m.end;
    }
    if (viTri < vanBan.length) {
      ketQua.add(TextSpan(text: vanBan.substring(viTri)));
    }
    return ketQua;
  }

  Widget _doanVanCoDam(String vanBan, {double fontSize = 14}) {
    return Text.rich(
      TextSpan(
        style: TextStyle(height: 1.5, fontSize: fontSize, color: Colors.black87),
        children: _phanTichDam(vanBan),
      ),
    );
  }

  void _hienGiaiThich(String tieuDe, String ngan, String chiTiet) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tieuDe),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GIẢI THÍCH NGẮN GỌN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 8),
              _doanVanCoDam(ngan),
              const SizedBox(height: 20),
              const Text(
                'GIẢI THÍCH CHI TIẾT HƠN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 8),
              _doanVanCoDam(chiTiet),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _dong1ThoiGian(),
          const Divider(height: 40),
          _dong2TuDongChen(),
          const Divider(height: 40),
          _dong3AI(),
          const Divider(height: 40),
          _dong4Micro(),
        ],
      ),
    );
  }

  Widget _tieuDeDong(String s) => Text(
        s,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );

  Widget _nutTimHieuThem(VoidCallback onPressed) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton(onPressed: onPressed, child: const Text('Tìm hiểu thêm')),
      );

  Widget _dong1ThoiGian() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Thời gian bật lại micro sau khi gõ tay xong'),
        const SizedBox(height: 10),
        DropdownButton<double>(
          value: _thoiGian,
          isExpanded: true,
          items: [
            for (final g in _cacMucThoiGian)
              DropdownMenuItem(value: g, child: Text(_nhanThoiGian(g))),
          ],
          onChanged: (gia) {
            if (gia == null) return;
            setState(() => _thoiGian = gia);
            widget.caiDat.datThoiGianBatLai(gia);
          },
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Thời gian bật lại micro',
              _giaiThichThoiGianNgan,
              _giaiThichThoiGian,
            )),
      ],
    );
  }

  Widget _dong2TuDongChen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động chèn dấu cách trước ký tự được gõ tay'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _tuDongChen ? 'Đang bật (Có)' : 'Đang tắt (Không)',
                style: TextStyle(
                  color: _tuDongChen ? const Color(0xFF1A73E8) : const Color(0xFF9AA0A6),
                ),
              ),
            ),
            Switch(
              value: _tuDongChen,
              onChanged: (bat) async {
                if (bat) {
                  setState(() => _tuDongChen = true);
                  await widget.caiDat.datTuDongChenKhoangCach(true);
                } else {
                  await _xacNhanTatTuDongChen();
                }
              },
            ),
          ],
        ),
        _nutTimHieuThem(() => _hienGiaiThich(
              'Tự động chèn dấu cách',
              _giaiThichChenCachNgan,
              _giaiThichChenCach,
            )),
      ],
    );
  }

  Widget _dong3AI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeDong('Tự động kiểm tra chính tả và đề xuất sửa bằng AI'),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Chưa có — tính năng đang phát triển',
                style: TextStyle(color: Color(0xFF9AA0A6)),
              ),
            ),
            Switch(value: false, onChanged: null),
          ],
        ),
      ],
    );
  }

  Widget _dong4Micro() {
    final tt = _trangThaiMicro;
    IconData icon;
    Color mau;
    String tieuDe;
    String moTa;
    Widget? nut;

    if (tt == null) {
      icon = Icons.hourglass_empty;
      mau = const Color(0xFF9AA0A6);
      tieuDe = 'Đang kiểm tra…';
      moTa = '';
    } else if (tt.isGranted || tt.isLimited || tt.isProvisional) {
      icon = Icons.check_circle_outline;
      mau = const Color(0xFF188038);
      tieuDe = 'Đã cấp quyền micro';
      moTa = 'Ứng dụng dùng được micro để nghe và ghi lại giọng nói.';
    } else if (tt.isPermanentlyDenied) {
      icon = Icons.mic_off_outlined;
      mau = Colors.red.shade600;
      tieuDe = 'Quyền micro đã bị chặn';
      moTa = 'Có thể do trước đây bạn từng từ chối và chọn "Không hỏi lại", '
          'hoặc có ai đó (kể cả chính bạn) vào Cài đặt máy rồi tắt quyền này '
          'đi. Ứng dụng không thể tự hỏi lại nữa — bấm nút bên dưới để mở '
          'màn hình cài đặt riêng của Ghi Nói, rồi tự bật mục "Micro" lên.';
      nut = FilledButton.icon(
        onPressed: _dangXuLyMicro ? null : _moCaiDatUngDung,
        icon: const Icon(Icons.settings_outlined),
        label: const Text('Mở cài đặt ứng dụng'),
      );
    } else if (tt.isRestricted) {
      icon = Icons.block;
      mau = Colors.red.shade600;
      tieuDe = 'Quyền micro bị chặn bởi thiết bị';
      moTa = 'Thiết bị này đang bị quản lý bởi một chính sách nào đó (ví dụ '
          'máy của cơ quan, trường học) và chặn hẳn quyền micro. Liên hệ '
          'người quản lý thiết bị để được mở.';
    } else {
      icon = Icons.mic_none;
      mau = const Color(0xFFF29900);
      tieuDe = 'Chưa cấp quyền micro';
      moTa = 'Ứng dụng cần quyền ghi âm của máy mới nghe được giọng nói. '
          'Bấm nút bên dưới để cấp quyền.';
      nut = FilledButton.icon(
        onPressed: _dangXuLyMicro ? null : _capQuyenMicro,
        icon: const Icon(Icons.mic),
        label: const Text('Cấp quyền micro'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _tieuDeDong('Quyền dùng micro của thiết bị')),
            IconButton(
              onPressed: _dangXuLyMicro ? null : _kiemTraQuyenMicro,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Kiểm tra lại',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: mau, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tieuDe, style: TextStyle(color: mau, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (moTa.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(moTa, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
        ],
        if (nut != null) ...[
          const SizedBox(height: 10),
          nut,
        ],
        if (_dangXuLyMicro) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}

const _giaiThichThoiGianNgan = '''
Khi bạn gõ phím, ứng dụng **tắt hẳn micro** một lúc để khỏi nghe nhầm tiếng gõ phím thành lời nói. Cài đặt này là **thời gian chờ** sau khi bạn ngừng gõ, trước khi micro tự bật lại. Để **ngắn** thì nói tiếp nhanh hơn nhưng dễ bắt nhầm âm thanh lúc bạn còn đang lơ đãng; để **dài** thì an toàn hơn nhưng phải chờ lâu hơn. Mặc định **1 giây** là hợp lý cho hầu hết mọi người. Chọn **"Không tự động bật lại Micro"** nếu bạn muốn hoàn toàn tự bấm nút micro mỗi lần muốn nói tiếp, không để ứng dụng tự quyết định thời điểm.
''';

const _giaiThichThoiGian = '''
Khi bạn đang nói mà tay chạm vào bàn phím để gõ thêm chữ, ứng dụng sẽ **tắt hẳn micro** ngay lập tức trong một lúc — làm vậy để tiếng gõ phím, tiếng bạn lẩm bẩm khi suy nghĩ chữ cần gõ, hay bất cứ âm thanh nào trong lúc bạn đang bận tay gõ không bị micro nghe nhầm thành một câu nói mới.

Cài đặt này quyết định **ứng dụng sẽ chờ bao lâu**, kể từ lúc bạn **ngừng gõ** (không chạm bàn phím nữa), rồi mới tự động bật micro nghe lại.

Ví dụ dễ hình dung: bạn đang nói dở câu "Cuộc họp sáng mai lúc", rồi bạn ngừng nói, tự tay gõ thêm mấy chữ "9 giờ". Ngay khi ngón tay bạn chạm phím đầu tiên, micro tắt phụt. Gõ xong chữ cuối cùng, ứng dụng bắt đầu đếm — hết đúng khoảng thời gian bạn chọn ở đây thì micro mới bật trở lại, để bạn nói tiếp phần còn lại của câu.

Chọn thời gian **ngắn** (ví dụ 0,5 giây): tiện vì nói tiếp được gần như ngay lập tức. Nhưng nếu thói quen gõ của bạn hay bị ngắt quãng — gõ một chữ, dừng tay một chút để suy nghĩ, rồi gõ tiếp — thì trong lúc bạn đang dừng tay suy nghĩ đó (chưa gõ xong hẳn), micro có thể đã bật lên và vô tình nghe được tiếng bạn lẩm bẩm, tiếng thở dài, hay tiếng ồn xung quanh, biến chúng thành chữ chen ngang vào bài mà bạn không muốn.

Chọn thời gian **dài** (ví dụ 5 giây): an toàn hơn, gần như chắc chắn bạn đã gõ xong hẳn ứng dụng mới bật lại micro. Nhưng đổi lại, gõ xong mà muốn nói tiếp ngay, bạn sẽ phải chờ lâu hơn, cảm giác ứng dụng "đơ" một nhịp trước khi chịu nghe.

Mức mặc định **1 giây** là khoảng vừa phải, hợp với cách gõ của phần lớn mọi người: đủ để gõ xong một từ hay một con số ngắn mà không bị ngắt giữa chừng, mà cũng không phải chờ quá lâu để nói tiếp.
''';

const _giaiThichChenCachNgan = '''
Tính năng này tự thêm một **dấu cách** khi bạn gõ tay ngay sau chữ do **giọng nói** tạo ra, để hai chữ không bị dính liền sai chính tả. Tắt đi thì ứng dụng gõ dính như một trang soạn thảo bình thường, và bộ nhớ đang ghi nhớ điều này sẽ bị xoá, **không thể khôi phục lại**.
''';

const _giaiThichChenCach = '''
Ứng dụng này cho phép bạn vừa **nói** vừa **gõ tay** xen kẽ trong cùng một bài. Vấn đề là: khi giọng nói vừa dứt một câu, bộ nhận dạng của máy không phải lúc nào cũng tự thêm dấu cách vào cuối câu — có lúc câu vừa nói dừng lại đúng ngay sau chữ cuối, không có khoảng trắng nào theo sau cả.

Nếu ngay lúc đó bạn gõ tay tiếp vào, chữ gõ tay sẽ bị **dính liền** vào chữ vừa nói, tạo ra một cụm chữ sai chính tả. Ví dụ: bạn nói ra được câu "Thành đẹp trai ./.", câu này kết thúc ngay sau dấu chấm cuối, không có dấu cách theo sau. Bạn gõ tay tiếp chữ "abc" ngay sau đó — nếu không có tính năng này, kết quả sẽ là "./.abc" dính chùm lại với nhau.

Bật tính năng này (mặc định là **bật**), ứng dụng sẽ tự nhớ **nguồn gốc** của từng chữ trong bài: chữ nào do bạn **nói** ra, chữ nào do bạn **tự gõ**. Khi bạn gõ tay dính ngay sau một chữ do **giọng nói** tạo ra (mà chữ đó chưa phải khoảng trắng sẵn), ứng dụng sẽ tự động chèn một dấu cách vào giữa trước, cho ra kết quả đúng: "./. abc". Nhưng nếu bạn gõ tay dính ngay sau một chữ cũng do chính tay bạn gõ trước đó, ứng dụng để dính liền như bình thường, không tự ý chèn gì — vì lúc đó rất có thể bạn **cố ý** muốn gõ liền, ví dụ đang gõ một từ dài, một mã số, hay một địa chỉ email.

Tắt tính năng này (chọn Không), ứng dụng sẽ ứng xử như một trang soạn thảo bình thường: gõ tới đâu dính tới đó, không tự chèn thêm gì hết, kể cả khi gõ ngay sau chữ do giọng nói tạo ra.

**Cảnh báo quan trọng:** để làm được việc "nhớ nguồn gốc từng chữ" này, ứng dụng phải liên tục ghi một danh sách riêng trong bộ nhớ máy — không phải là một phần của bài viết, bạn không nhìn thấy nó, và nó không được lưu lại lâu dài như nội dung bài. Nếu bạn tắt tính năng này đi, danh sách ghi nhớ đó bị **xoá sạch ngay** và **không thể lấy lại được**, kể cả sau này bạn có bật tính năng lên lại. Bật lại chỉ giúp tính năng hoạt động cho những chữ bạn nói hoặc gõ sau thời điểm bật lại mà thôi — chữ đã có sẵn trong bài từ trước sẽ được coi là "chữ gõ tay" hết, dù trước đây có thể chúng vốn là do bạn nói ra.
''';
