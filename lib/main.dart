// Ghi Nói — một trang văn bản trắng, gõ phím và nói bằng micro cùng lúc.
//
// Ý tưởng cốt lõi: mọi chữ — dù đến từ bàn phím hay từ micro — đều rơi vào
// đúng vị trí con trỏ. Micro không tắt khi người dùng gõ phím.

import 'dart:async';
import 'dart:math' as toan;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UngDungGhiNoi());
}

class UngDungGhiNoi extends StatelessWidget {
  const UngDungGhiNoi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghi Nói',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const TrangSoanThao(),
    );
  }
}

class TrangSoanThao extends StatefulWidget {
  const TrangSoanThao({super.key});

  @override
  State<TrangSoanThao> createState() => _TrangSoanThaoState();
}

class _TrangSoanThaoState extends State<TrangSoanThao>
    with WidgetsBindingObserver {
  static const _khoaLuu = 'noi_dung_van_ban';

  final _boDieuKhien = TextEditingController();
  final _oChu = FocusNode();
  final _cuonVanBan = ScrollController();
  final _micro = SpeechToText();

  /// Người dùng ĐANG MUỐN micro bật hay không. Khác với việc bộ nhận dạng có
  /// thực sự đang nghe hay không: Android tự ngắt sau vài giây im lặng, ta
  /// bật lại ngay, nhưng ý muốn của người dùng thì không đổi.
  bool _muonNghe = false;
  bool _dangNghe = false;
  bool _sanSang = false;
  String _loi = '';

  /// Mấy mức âm gần nhất, để vẽ sóng. Mới nhất nằm ở cuối.
  final List<double> _songAm = List<double>.filled(16, 0);

  /// Vị trí bắt đầu của câu đang đọc dở, và ĐÚNG đoạn chữ tạm đã chèn ở đó.
  ///
  /// Giữ nguyên văn đoạn chữ chứ không chỉ giữ độ dài: trước mỗi lần ghi, ta
  /// đọc lại trong bài xem đoạn đó còn nguyên ở chỗ cũ không. Còn thì đè lên,
  /// không còn thì coi như câu mới. Nhờ vậy mốc có lệch cũng không lặp chữ.
  int _neo = 0;
  String _chuTam = '';

  /// Vị trí NGAY SAU đoạn chữ giọng nói vừa chốt xong, nếu đoạn đó chưa kết
  /// thúc bằng khoảng trắng. Chỉ có giá trị đến lần gõ phím kế tiếp: người
  /// dùng gõ ký tự dính ngay tại đây thì ta chen một dấu cách trước, giữ đúng
  /// một lần rồi thôi. -1 nghĩa là không có ranh giới nào đang chờ.
  int _ranhGioiGiongNoi = -1;

  /// Bỏ qua mọi kết quả còn lại của câu nói đang dở.
  ///
  /// Bật lên khi người dùng chạm vào bàn phím giữa chừng: đoạn chữ đã hiện ra
  /// phải CHẾT CỨNG tại đó, không được tự sửa nữa. Nếu không bỏ qua, bộ nhận
  /// dạng sẽ trả nốt cả câu và đổ nguyên câu ấy ra lần thứ hai.
  bool _boQuaCauNay = false;
  bool _dangCatCau = false;

  /// Micro đang tắt vì người dùng gõ phím, chứ không phải vì họ bấm nút tắt.
  /// Phân biệt hai chuyện này mới biết có được tự bật lại hay không.
  bool _microNgungDeGo = false;

  /// Bật lên khi chính ta đang sửa nội dung, để phân biệt với người gõ phím.
  /// Chỉ là lớp chắn thứ nhất: bộ gõ báo ngược trạng thái về một cách bất
  /// đồng bộ, lúc đó cờ này đã tắt rồi — nên còn hai lớp chắn nữa bên dưới.
  bool _tuSua = false;

  /// Nội dung, vị trí con trỏ và thời điểm của lần ghi gần nhất do chính ta
  /// thực hiện. Dùng để nhận ra đâu là trạng thái bộ gõ báo ngược về.
  String _chuGanNhat = '';
  int _viTriGanNhat = -1;
  DateTime _lucGhi = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _hen;
  Timer? _henLuuTru;
  Timer? _henGoXong;
  String? _maNgonNgu;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boDieuKhien.addListener(_khiNguoiDungSua);
    _napVanBan();
    _khoiTaoMicro();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hen?.cancel();
    _henLuuTru?.cancel();
    _henGoXong?.cancel();
    _micro.cancel();
    _boDieuKhien.dispose();
    _oChu.dispose();
    _cuonVanBan.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState trangThai) {
    if (trangThai != AppLifecycleState.resumed) {
      _luuVanBan();
      if (_muonNghe) _tatMicro();
    }
  }

  // ---------------------------------------------------------------- lưu trữ

  Future<void> _napVanBan() async {
    final kho = await SharedPreferences.getInstance();
    final cu = kho.getString(_khoaLuu) ?? '';
    if (cu.isEmpty || !mounted) return;
    _ghiVaoO(cu, cu.length);
    _neo = cu.length;
    _chuTam = '';
    _ranhGioiGiongNoi = -1;
  }

  Future<void> _luuVanBan() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaLuu, _boDieuKhien.text);
  }

  void _henLuu() {
    _henLuuTru?.cancel();
    _henLuuTru = Timer(const Duration(milliseconds: 600), _luuVanBan);
  }

  // ----------------------------------------------------------------- micro

  Future<void> _khoiTaoMicro() async {
    final duoc = await _micro.initialize(
      onStatus: _khiDoiTrangThai,
      onError: (loi) {
        // 'error_no_match' và 'error_speech_timeout' chỉ nghĩa là người dùng
        // im lặng — không phải hỏng, đừng làm phiền họ.
        final nhe = loi.errorMsg == 'error_no_match' ||
            loi.errorMsg == 'error_speech_timeout';
        if (!nhe && mounted) {
          setState(() => _loi = _dichLoi(loi.errorMsg));
        }
        _henBatLai();
      },
      debugLogging: false,
    );
    if (!mounted) return;
    if (duoc) {
      _maNgonNgu = await _chonTiengViet();
    }
    setState(() {
      _sanSang = duoc;
      if (!duoc) {
        _loi = 'Máy không dùng được micro. Hãy kiểm tra quyền ghi âm và '
            'ứng dụng Google trên máy.';
      }
    });
  }

  /// Ưu tiên tiếng Việt nếu máy có; không có thì để máy tự chọn.
  Future<String?> _chonTiengViet() async {
    try {
      final ds = await _micro.locales();
      for (final l in ds) {
        if (l.localeId.replaceAll('-', '_').toLowerCase().startsWith('vi')) {
          return l.localeId;
        }
      }
    } catch (_) {
      // Không lấy được danh sách thì cứ để mặc định.
    }
    return null;
  }

  void _khiDoiTrangThai(String trangThai) {
    final dangChay = trangThai == SpeechToText.listeningStatus;
    if (mounted && _dangNghe != dangChay) {
      setState(() => _dangNghe = dangChay);
    }
    if (!dangChay) _henBatLai();
  }

  /// Android tự ngắt nhận dạng sau vài giây im lặng. Ta bật lại ngay để người
  /// dùng thấy micro như luôn bật. Khe hở ngắn này là giới hạn của hệ điều
  /// hành, không phải lỗi của ứng dụng.
  void _henBatLai() {
    if (!_muonNghe) return;
    _hen?.cancel();
    _hen = Timer(const Duration(milliseconds: 200), () {
      if (_muonNghe && !_micro.isListening) _batMicro();
    });
  }

  Future<void> _batMicro() async {
    if (!_sanSang) return;
    _chotCauDangDoc();
    _boQuaCauNay = false;
    _dangCatCau = false;
    try {
      await _micro.listen(
        onResult: _khiCoChu,
        localeId: _maNgonNgu,
        onSoundLevelChange: _khiDoiMucAm,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          autoPunctuation: true,
        ),
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 8),
      );
    } catch (_) {
      _henBatLai();
    }
  }

  Future<void> _tatMicro() async {
    _muonNghe = false;
    _hen?.cancel();
    await _micro.stop();
    _chotCauDangDoc();
    if (mounted) {
      setState(() {
        _dangNghe = false;
        _songAm.fillRange(0, _songAm.length, 0);
      });
    }
  }

  void _bamNutMicro() {
    // Người dùng tự bấm thì ý họ là quyết định cuối cùng — bỏ mọi kế hoạch
    // tự bật lại đang chờ.
    _microNgungDeGo = false;
    _henGoXong?.cancel();

    if (_muonNghe) {
      _tatMicro();
    } else {
      setState(() {
        _muonNghe = true;
        _loi = '';
      });
      _datNeoTaiConTro();
      _batMicro();
    }
  }

  void _khiDoiMucAm(double muc) {
    if (!mounted) return;
    // Mức âm Android trả về nằm khoảng -2 đến 10. Ép về 0..1 cho dễ vẽ.
    final chuan = ((muc + 2) / 12).clamp(0.0, 1.0);
    setState(() {
      for (var i = 0; i < _songAm.length - 1; i++) {
        _songAm[i] = _songAm[i + 1];
      }
      _songAm[_songAm.length - 1] = chuan;
    });
  }

  // ------------------------------------------------------- chèn chữ vào chỗ

  void _datNeoTaiConTro() {
    final chon = _boDieuKhien.selection;
    _neo = chon.isValid ? chon.end : _boDieuKhien.text.length;
    _chuTam = '';
  }

  /// Coi phần chữ tạm hiện tại là đã xong, và dời neo ra sau nó.
  void _chotCauDangDoc() {
    _neo += _chuTam.length;
    _chuTam = '';
  }

  /// Đoạn chữ tạm có còn nguyên vẹn ở đúng chỗ cũ không?
  ///
  /// Đây là lớp chắn quan trọng nhất chống lặp chữ: nếu đoạn cũ không còn ở
  /// đó (người dùng vừa xoá, vừa gõ chèn, hoặc mốc bị lệch vì bộ gõ báo ngược
  /// trạng thái về), ta KHÔNG đè bừa mà đặt lại mốc tại con trỏ.
  bool _vungTamConNguyen(String cu) {
    if (_chuTam.isEmpty) return false;
    if (_neo < 0) return false;
    final het = _neo + _chuTam.length;
    if (het > cu.length) return false;
    return cu.substring(_neo, het) == _chuTam;
  }

  void _khiCoChu(dynamic ketQua) {
    final noi = (ketQua.recognizedWords as String? ?? '').trim();
    final xong = ketQua.finalResult as bool? ?? false;

    // Người dùng vừa gõ phím giữa chừng: chữ đã hiện ra phải nằm im. Nuốt hết
    // phần còn lại của câu này, chờ câu mới.
    if (_boQuaCauNay) {
      if (xong) _boQuaCauNay = false;
      return;
    }
    if (noi.isEmpty) return;

    final cu = _boDieuKhien.text;

    // Không tin vào mốc suông. Đoạn tạm không còn nguyên thì bắt đầu lại từ
    // chỗ con trỏ, coi như đây là câu mới.
    if (!_vungTamConNguyen(cu)) {
      final chon = _boDieuKhien.selection;
      _neo = chon.isValid ? chon.end : cu.length;
      if (_neo > cu.length) _neo = cu.length;
      if (_neo < 0) _neo = 0;
      _chuTam = '';
    }

    var chen = noi;
    // Nếu ngay trước neo đã có chữ mà chưa có dấu cách, thêm một dấu cách cho
    // câu mới không dính vào câu cũ.
    if (_neo > 0) {
      final truoc = cu[_neo - 1];
      if (truoc != ' ' && truoc != '\n' && truoc != '\t') {
        chen = ' $chen';
      }
    }

    if (chen == _chuTam) return; // Không có gì đổi, khỏi động vào ô văn bản.

    final moi = cu.replaceRange(_neo, _neo + _chuTam.length, chen);
    final viTri = _neo + chen.length;

    _ghiVaoO(moi, viTri);
    _chuTam = chen;

    if (xong) {
      _chotCauDangDoc();
      // Ranh giới chỉ đáng giữ nếu chữ ngay trước nó không phải khoảng
      // trắng — có khoảng trắng rồi thì gõ tiếp không cần thêm gì cả.
      if (_neo > 0 && !_laKhoangTrang(moi[_neo - 1])) {
        _ranhGioiGiongNoi = _neo;
      } else {
        _ranhGioiGiongNoi = -1;
      }
      _luuVanBan();
    }
  }

  static bool _laKhoangTrang(String kyTu) =>
      kyTu == ' ' || kyTu == '\n' || kyTu == '\t';

  /// Mọi lần ghi do máy thực hiện đều đi qua đây, để ghi nhớ nội dung, vị trí
  /// con trỏ và thời điểm — ba thứ dùng để nhận ra trạng thái bộ gõ báo về.
  void _ghiVaoO(String chu, int viTri) {
    _tuSua = true;
    _boDieuKhien.value = TextEditingValue(
      text: chu,
      selection: TextSelection.collapsed(offset: viTri),
    );
    _tuSua = false;
    _chuGanNhat = chu;
    _viTriGanNhat = viTri;
    _lucGhi = DateTime.now();

    // Chữ vừa thêm vào cuối bài thì kéo màn hình xuống theo, để dòng mới nhất
    // luôn nằm trong tầm mắt.
    if (viTri >= chu.length) _cuonXuongDuoi();
  }

  /// Kéo ô văn bản xuống hết cỡ, sau khi khung hình đã dựng lại xong — lúc đó
  /// chiều cao mới của bài mới được tính ra.
  ///
  /// Chỉ gọi khi chữ vừa thêm vào CUỐI bài. Người dùng chèn chữ vào giữa mà
  /// nhảy xuống đáy thì họ mất chỗ đang làm. Ngoài những lúc đó, họ cuộn lên
  /// xuống xem lại bài hoàn toàn tự do.
  void _cuonXuongDuoi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cuonVanBan.hasClients) return;
      final day = _cuonVanBan.position.maxScrollExtent;
      if ((_cuonVanBan.offset - day).abs() < 1) return;
      _cuonVanBan.jumpTo(day);
    });
  }

  /// Người dùng vừa GÕ PHÍM. Cắt sạch mọi thứ đang chạy của micro.
  ///
  /// Chữ nào đã lỡ ra màn hình thì chết tại đó. Phần câu nói còn dở trong máy
  /// bị vứt bỏ hẳn — dùng cancel() chứ không phải stop(), vì stop() còn trả về
  /// một kết quả chốt, mà kết quả đó sẽ đổ nguyên câu ra lần nữa ở chỗ con trỏ
  /// mới. Nút micro tắt luôn, không được nghe gì nữa.
  ///
  /// Sau khi người dùng ngừng gõ đủ một giây thì micro tự bật lại như cũ.
  void _nguoiDungVuaGo() {
    _chuTam = ''; // Nhả đoạn đang nhảy ra: không gì đè lên nó được nữa.

    if (_muonNghe || _micro.isListening) {
      _boQuaCauNay = true;
      _microNgungDeGo = true;
      _muonNghe = false; // Ngăn _henBatLai() lén bật lại.
      _hen?.cancel();
      _micro.cancel();
      if (mounted) {
        setState(() {
          _dangNghe = false;
          _songAm.fillRange(0, _songAm.length, 0);
        });
      }
    }

    // Đồng hồ đếm lại từ đầu sau MỖI phím, nên nó chỉ điểm khi người dùng đã
    // thật sự ngừng tay.
    if (_microNgungDeGo) {
      _henGoXong?.cancel();
      _henGoXong = Timer(const Duration(seconds: 1), _batLaiSauKhiGoXong);
    }
  }

  void _batLaiSauKhiGoXong() {
    if (!_microNgungDeGo || !mounted) return;
    _microNgungDeGo = false;
    _boQuaCauNay = false;
    setState(() => _muonNghe = true);
    _datNeoTaiConTro();
    _batMicro();
  }

  /// Người dùng chạm để dời con trỏ, chứ không gõ chữ. Nhẹ tay hơn: chỉ đóng
  /// băng đoạn đang nhảy và cắt câu đang dở, micro vẫn nghe tiếp.
  void _dongBangDoanDangNhay() {
    final dangVietDo = _chuTam.isNotEmpty;
    _chuTam = '';
    if (!dangVietDo) return;
    if (!_muonNghe || _dangCatCau || !_micro.isListening) return;
    _boQuaCauNay = true;
    _dangCatCau = true;
    _micro.stop().whenComplete(() {
      _dangCatCau = false;
      _henBatLai();
    });
  }

  /// Người dùng gõ phím hoặc bấm để dời con trỏ.
  void _khiNguoiDungSua() {
    if (_tuSua) return;

    final chu = _boDieuKhien.text;

    if (chu != _chuGanNhat) {
      // Chữ thật sự đổi mà không phải do ta → người dùng vừa gõ. Tìm đúng
      // chỗ vừa gõ bằng cách so khác biệt với chữ cũ, để biết ký tự đầu tiên
      // họ gõ rơi vào vị trí nào.
      final cu = _chuGanNhat;
      var dau = 0;
      while (dau < cu.length &&
          dau < chu.length &&
          cu[dau] == chu[dau]) {
        dau++;
      }
      final viTriGo = dau;
      final coChenChu = chu.length > cu.length; // false nếu là xoá chữ

      // Người dùng gõ đúng ngay tại ranh giới chữ do giọng nói tạo ra, mà
      // chưa có khoảng trắng ở đó — chen một dấu cách trước khi ghi nhận chữ
      // họ vừa gõ. Chỉ áp dụng cho giọng nói: gõ tay nối gõ tay thì dính liền
      // như người dùng gõ, không tự ý chen gì cả.
      if (coChenChu &&
          viTriGo == _ranhGioiGiongNoi &&
          !_laKhoangTrang(chu[viTriGo])) {
        // Chèn một dấu cách vào đúng chỗ này trong CHỮ MỚI: phần trước
        // viTriGo không đổi so với chữ cũ (đó là định nghĩa của viTriGo), nên
        // chỉ cần chen thêm một dấu cách vào chữ mới là đủ.
        final chuCuoiCung =
            chu.substring(0, viTriGo) + ' ' + chu.substring(viTriGo);
        final chon = _boDieuKhien.selection;
        final viTriConTro =
            (chon.isValid ? chon.end : chu.length) + 1;

        _ranhGioiGiongNoi = -1; // Dùng một lần rồi mất.
        _ghiVaoO(chuCuoiCung, viTriConTro);
        _chuGanNhat = chuCuoiCung;
        _neo = viTriConTro;
        _nguoiDungVuaGo();
        _henLuu();
        if (_neo >= chuCuoiCung.length) _cuonXuongDuoi();
        return;
      }

      _ranhGioiGiongNoi = -1; // Người dùng gõ, ranh giới cũ hết hiệu lực.
      _chuGanNhat = chu;
      final chon = _boDieuKhien.selection;
      _neo = chon.isValid ? chon.end : chu.length;
      _nguoiDungVuaGo();
      _henLuu();
      if (_neo >= chu.length) _cuonXuongDuoi();
      return;
    }

    // Chữ y nguyên, chỉ con trỏ đổi. Có hai khả năng, và phải phân biệt cho
    // đúng — nhầm chỗ này là chữ lặp lại y như bản v1.
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) return;

    // (a) Bộ gõ báo ngược lại đúng trạng thái ta vừa đặt. Con trỏ trùng khít
    //     chỗ ta vừa đặt nó, hoặc chuyện xảy ra ngay sau khi ta ghi.
    final trungKhit = chon.end == _viTriGanNhat && chon.isCollapsed;
    final vuaGhiXong =
        DateTime.now().difference(_lucGhi) < const Duration(milliseconds: 600);
    if (trungKhit || vuaGhiXong) return;

    // (b) Người dùng thật sự chạm màn hình để dời con trỏ.
    _neo = chon.end;
    _dongBangDoanDangNhay();
  }

  // ------------------------------------------------------------------- nút

  Future<void> _chepTatCa() async {
    final chu = _boDieuKhien.text;
    if (chu.isEmpty) {
      _bao('Chưa có chữ nào để chép.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: chu));
    _bao('Đã chép toàn bộ văn bản.');
  }

  void _bao(String loi) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(loi),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _xoaTatCa() async {
    if (_boDieuKhien.text.isEmpty) {
      _bao('Trang đang trống, không có gì để xoá.');
      return;
    }

    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline, size: 28),
        title: const Text('Xoá tất cả?'),
        content: const Text(
          'Toàn bộ văn bản đang soạn sẽ bị xoá và không lấy lại được.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Có, xoá tất cả'),
          ),
        ],
      ),
    );

    if (dongY != true || !mounted) return;

    // Trả mọi mốc về vạch xuất phát, nếu không thì câu nói kế tiếp lại nhắm
    // vào một vị trí không còn tồn tại.
    _ghiVaoO('', 0);
    _neo = 0;
    _chuTam = '';
    _ranhGioiGiongNoi = -1;
    _boQuaCauNay = _micro.isListening;
    await _luuVanBan();
    if (mounted) _bao('Đã xoá toàn bộ văn bản.');
  }

  void _moModalTam(String tieuDe, IconData bieuTuong) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(bieuTuong, size: 28),
        title: Text(tieuDe),
        content: const Text(
          'Tính năng đang nâng cấp.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _dichLoi(String ma) {
    switch (ma) {
      case 'error_network':
      case 'error_network_timeout':
        return 'Mất mạng — bộ nhận dạng giọng nói cần Internet.';
      case 'error_audio':
        return 'Không đọc được micro.';
      case 'error_permission':
      case 'error_insufficient_permissions':
        return 'Chưa được cấp quyền ghi âm.';
      case 'error_busy':
        return 'Micro đang bị ứng dụng khác chiếm.';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return 'Máy chưa có gói tiếng Việt cho nhận dạng giọng nói.';
      default:
        return 'Micro gặp trục trặc ($ma).';
    }
  }

  // ----------------------------------------------------------------- dựng

  @override
  Widget build(BuildContext context) {
    // Tự đo chiều cao bàn phím thay vì giao cho Scaffold: đặt thanh công cụ
    // làm dòng cuối của thân trang rồi chừa đúng khoảng đó bên dưới, thì
    // thanh luôn nằm khít mép trên bàn phím.
    final caoBanPhim = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Ghi Nói'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _chepTatCa,
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Chép toàn bộ văn bản',
          ),
          IconButton(
            onPressed: _xoaTatCa,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xoá tất cả',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_loi.isNotEmpty)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF4E5),
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Color(0xFF8A5300)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loi,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A5300)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: const Color(0xFF8A5300),
                      onPressed: () => setState(() => _loi = ''),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _boDieuKhien,
                  focusNode: _oChu,
                  scrollController: _cuonVanBan,
                  maxLines: null,
                  expands: true,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 17, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Gõ chữ, hoặc bấm nút micro và nói…',
                  ),
                ),
              ),
            ),
            _ThanhCongCu(
              bat: _muonNghe,
              dangNghe: _dangNghe,
              songAm: _songAm,
              sanSang: _sanSang,
              // Bàn phím đóng thì còn phải né thanh điều hướng của máy; bàn
              // phím mở thì nó che mất thanh đó rồi, né nữa là hở một dải
              // trắng giữa thanh công cụ và bàn phím.
              neThanhDieuHuong: caoBanPhim == 0,
              khiBamMicro: _bamNutMicro,
              khiBamCaiDat: () => _moModalTam('Cài đặt', Icons.settings_outlined),
              khiBamHuongDan: () =>
                  _moModalTam('Hướng dẫn', Icons.help_outline_rounded),
            ),
            SizedBox(height: caoBanPhim),
          ],
        ),
      ),
    );
  }
}

/// Thanh ngang dưới màn hình: cài đặt và hướng dẫn bên trái, micro ở giữa,
/// sóng âm bên phải. Nằm trên bàn phím ảo khi bàn phím hiện lên.
class _ThanhCongCu extends StatelessWidget {
  const _ThanhCongCu({
    required this.bat,
    required this.dangNghe,
    required this.songAm,
    required this.sanSang,
    required this.neThanhDieuHuong,
    required this.khiBamMicro,
    required this.khiBamCaiDat,
    required this.khiBamHuongDan,
  });

  final bool bat;
  final bool dangNghe;
  final List<double> songAm;
  final bool sanSang;
  final bool neThanhDieuHuong;
  final VoidCallback khiBamMicro;
  final VoidCallback khiBamCaiDat;
  final VoidCallback khiBamHuongDan;

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
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE3E3E3))),
          ),
          child: Row(
            children: [
              // Bên trái: cài đặt rồi tới hướng dẫn.
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _NutNho(
                      bieuTuong: Icons.settings_outlined,
                      nhan: 'Cài đặt',
                      khiBam: khiBamCaiDat,
                    ),
                    _NutNho(
                      bieuTuong: Icons.help_outline_rounded,
                      nhan: 'Hướng dẫn',
                      khiBam: khiBamHuongDan,
                    ),
                  ],
                ),
              ),

              // Giữa: nút micro.
              _NutMicroTron(
                bat: bat,
                sanSang: sanSang,
                mau: mau,
                khiBam: sanSang ? khiBamMicro : null,
              ),

              // Bên phải: sóng âm cho biết micro có nghe được gì không.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SongAm(muc: songAm, dangNghe: bat && dangNghe),
                  ),
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
class _NutNho extends StatelessWidget {
  const _NutNho({
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
            width: 42,
            height: 42,
            child: Icon(bieuTuong, size: 22, color: const Color(0xFF5F6368)),
          ),
        ),
      ),
    );
  }
}

/// Mấy vạch nhảy theo giọng nói. Micro tắt thì nằm im thành một đường phẳng —
/// nhìn vào là biết ngay máy có đang nghe thấy mình hay không.
class _SongAm extends StatelessWidget {
  const _SongAm({required this.muc, required this.dangNghe});

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
      final cao = dangNghe
          ? toan.max(3.0, muc[i] * size.height)
          : 3.0;
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
