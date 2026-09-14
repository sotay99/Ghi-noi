// Trang soạn thảo — một trang văn bản trắng, gõ phím và nói bằng micro cùng
// lúc. Mọi chữ — dù đến từ bàn phím hay từ micro — đều rơi vào đúng vị trí
// con trỏ. Micro không tắt khi người dùng gõ phím; ngược lại, gõ phím ngắt
// hẳn micro trong một giây rồi tự bật lại.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'kho_du_lieu.dart';
import 'man_hinh_thu_muc.dart';
import 'mo_hinh.dart';
import 'thanh_cong_cu.dart';

class TrangSoanThao extends StatefulWidget {
  const TrangSoanThao({super.key, required this.kho, required this.ghiChuId});

  final KhoDuLieu kho;
  final String ghiChuId;

  @override
  State<TrangSoanThao> createState() => _TrangSoanThaoState();
}

class _TrangSoanThaoState extends State<TrangSoanThao>
    with WidgetsBindingObserver {
  final _boDieuKhien = TextEditingController();
  final _oChu = FocusNode();
  final _cuonVanBan = ScrollController();
  final _micro = SpeechToText();

  late GhiChuFile _ghiChuHienTai;
  late final TextEditingController _tenController;
  final _oTen = FocusNode();

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

  /// Mỗi ký tự trong bài được đánh dấu true (do tay gõ) hay false (do giọng
  /// nói tạo ra). Luôn có ĐÚNG BẰNG độ dài văn bản hiện tại — mọi chỗ đổi chữ
  /// đều phải sửa danh sách này theo cùng một nhịp, không thì hai bên lệch
  /// nhau và mọi suy luận dựa trên nó đều sai.
  ///
  /// Dùng để quyết định có tự chèn dấu cách hay không: gõ dính ngay sau một
  /// ký tự do GIỌNG NÓI tạo ra (và ký tự đó chưa phải khoảng trắng) thì chèn
  /// một dấu cách trước. Gõ dính sau ký tự do TAY gõ thì để dính bình thường,
  /// coi như người dùng cố ý.
  final List<bool> _nguonKyTu = [];

  static bool _laKhoangTrang(String kyTu) =>
      kyTu == ' ' || kyTu == '\n' || kyTu == '\t';

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
    _ghiChuHienTai = widget.kho.timGhiChu(widget.ghiChuId)!;
    _tenController = TextEditingController(text: _ghiChuHienTai.ten);
    _oTen.addListener(_khiOTenMatFocus);

    WidgetsBinding.instance.addObserver(this);
    _boDieuKhien.addListener(_khiNguoiDungSua);

    final banDau = _ghiChuHienTai.noiDung;
    if (banDau.isNotEmpty) {
      _ghiVaoO(banDau, banDau.length);
    }
    _neo = banDau.length;
    _nguonKyTu.addAll(List<bool>.filled(banDau.length, true));

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
    _tenController.dispose();
    _oTen.dispose();
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

  Future<void> _luuVanBan() async {
    widget.kho.suaNoiDungGhiChu(_ghiChuHienTai.id, _boDieuKhien.text);
    await widget.kho.luu();
  }

  void _henLuu() {
    _henLuuTru?.cancel();
    _henLuuTru = Timer(const Duration(milliseconds: 600), _luuVanBan);
  }

  /// Bấm nút Lưu: chốt bài xuống kho VÀ coi toàn bộ chữ hiện có là "do tay
  /// gõ" — như thể vừa mở lại một ghi chú đã lưu. Xoá bộ nhớ đánh dấu ký tự
  /// đúng nghĩa là đưa nó về trạng thái mặc định này, vì bộ nhớ đó luôn phải
  /// dài bằng đúng văn bản, không thể "để trống" trong khi bài vẫn còn chữ.
  Future<void> _bamNutLuu() async {
    _nguonKyTu
      ..clear()
      ..addAll(List<bool>.filled(_boDieuKhien.text.length, true));
    await _luuVanBan();
    _bao('Đã lưu "${_ghiChuHienTai.ten}".');
  }

  // -------------------------------------------------------------- tên file

  void _khiOTenMatFocus() {
    if (_oTen.hasFocus) return;
    _xacNhanDoiTen();
  }

  void _xacNhanDoiTen() {
    final tenMoi = _tenController.text.trim();
    if (tenMoi.isEmpty) {
      _tenController.text = _ghiChuHienTai.ten;
      return;
    }
    if (tenMoi == _ghiChuHienTai.ten) return;
    final thanhCong = widget.kho.doiTenGhiChu(_ghiChuHienTai.id, tenMoi);
    if (!thanhCong) {
      _tenController.text = _ghiChuHienTai.ten;
      _bao('Tên "$tenMoi" đã có trong thư mục này.');
      return;
    }
    widget.kho.luu();
  }

  // --------------------------------------------------------------- thư mục

  Future<void> _moManHinhThuMuc() async {
    if (_muonNghe) await _tatMicro();
    if (!mounted) return;
    final idChon = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ManHinhThuMuc(
          kho: widget.kho,
          idGhiChuDangMo: _ghiChuHienTai.id,
        ),
      ),
    );
    if (!mounted) return;

    if (idChon != null && idChon != _ghiChuHienTai.id) {
      _moGhiChu(idChon);
      return;
    }

    // Không chọn gì — nhưng có thể ghi chú đang mở đã bị xoá hoặc đổi tên
    // trong lúc dạo thư mục.
    final vanConDo = widget.kho.timGhiChu(_ghiChuHienTai.id);
    if (vanConDo == null) {
      final moi = widget.kho.taoGhiChuMoi(thuMucGoc);
      await widget.kho.luu();
      _moGhiChu(moi.id);
      _bao('Ghi chú đang mở đã bị xoá, đã tạo ghi chú mới.');
    } else {
      setState(() => _tenController.text = vanConDo.ten);
    }
  }

  void _moGhiChu(String id) {
    final g = widget.kho.timGhiChu(id);
    if (g == null) return;

    setState(() {
      _ghiChuHienTai = g;
      _tenController.text = g.ten;
    });

    if (g.noiDung.isEmpty) {
      _ghiVaoO('', 0);
    } else {
      _ghiVaoO(g.noiDung, g.noiDung.length);
    }
    _neo = g.noiDung.length;
    _chuTam = '';
    _nguonKyTu
      ..clear()
      ..addAll(List<bool>.filled(g.noiDung.length, true));

    widget.kho.datGhiChuDangMo(id);
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

  /// Thay đoạn [_neo, _neo + _chuTam.length) bằng [chenVao] — dùng cho MỌI
  /// lần giọng nói chèn hoặc sửa chữ tạm. Đoạn mới luôn đánh dấu là "giọng
  /// nói" trong _nguonKyTu, giữ đúng nhịp với _boDieuKhien.
  void _thayVungTamBangGiongNoi(String chenVao) {
    final cu = _boDieuKhien.text;
    final het = _neo + _chuTam.length;
    final moi = cu.replaceRange(_neo, het, chenVao);

    _nguonKyTu.removeRange(_neo, het);
    _nguonKyTu.insertAll(_neo, List<bool>.filled(chenVao.length, false));

    final viTri = _neo + chenVao.length;
    _ghiVaoO(moi, viTri);
    _chuTam = chenVao;
    _chuGanNhat = moi; // Để lần _khiNguoiDungSua tiếp theo không hiểu nhầm.
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

    _thayVungTamBangGiongNoi(chen);

    if (xong) {
      _chotCauDangDoc();
      _luuVanBan();
    }
  }

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

  /// Người dùng gõ phím hoặc bấm để dời con trỏ. Đây cũng là nơi duy nhất
  /// cập nhật _nguonKyTu cho phần TAY GÕ, bằng cách so khác biệt giữa chữ cũ
  /// (_chuGanNhat) và chữ mới — cách này gộp được cả gõ chèn, xoá, và autocorrect
  /// của bàn phím thay nguyên một cụm chữ, vào cùng một logic duy nhất.
  void _khiNguoiDungSua() {
    if (_tuSua) return;

    final chuMoi = _boDieuKhien.text;

    if (chuMoi != _chuGanNhat) {
      _apDungChinhSuaNguoiDung(chuMoi);
      return;
    }

    // Chữ y nguyên, chỉ con trỏ đổi. Có hai khả năng, và phải phân biệt cho
    // đúng — nhầm chỗ này là chữ lặp lại y như bản trước.
    final chon = _boDieuKhien.selection;
    if (!chon.isValid) return;

    // (a) Bộ gõ báo ngược lại đúng trạng thái ta vừa đặt. Con trỏ trùng khít
    //     chỗ ta vừa đặt nó, hoặc chuyện xảy ra ngay sau khi ta ghi.
    final trungKhit = chon.end == _viTriGanNhat && chon.isCollapsed;
    final vuaGhiXong = DateTime.now().difference(_lucGhi) <
        const Duration(milliseconds: 600);
    if (trungKhit || vuaGhiXong) return;

    // (b) Người dùng thật sự chạm màn hình để dời con trỏ.
    _neo = chon.end;
    _dongBangDoanDangNhay();
  }

  void _apDungChinhSuaNguoiDung(String chuMoi) {
    final cu = _chuGanNhat;

    // So khác biệt: phần đầu giống nhau dài bao nhiêu, phần đuôi giống nhau
    // dài bao nhiêu. Khoảng giữa còn lại chính là chỗ vừa bị đổi.
    final gioiHan = cu.length < chuMoi.length ? cu.length : chuMoi.length;
    var dau = 0;
    while (dau < gioiHan && cu[dau] == chuMoi[dau]) {
      dau++;
    }
    var duoi = 0;
    final gioiHanDuoi = gioiHan - dau;
    while (duoi < gioiHanDuoi &&
        cu[cu.length - 1 - duoi] == chuMoi[chuMoi.length - 1 - duoi]) {
      duoi++;
    }

    final doDaiChenVao = chuMoi.length - dau - duoi;
    var chuMoiCuoi = chuMoi;
    var lechConTro = 0;

    // Có chèn chữ mới (không phải chỉ xoá), ngay tại ranh giới một ký tự do
    // GIỌNG NÓI tạo ra và chưa phải khoảng trắng → chen một dấu cách trước.
    if (doDaiChenVao > 0 &&
        dau > 0 &&
        dau <= _nguonKyTu.length &&
        !_nguonKyTu[dau - 1] &&
        !_laKhoangTrang(cu[dau - 1]) &&
        !_laKhoangTrang(chuMoi[dau])) {
      chuMoiCuoi = chuMoi.substring(0, dau) + ' ' + chuMoi.substring(dau);
      lechConTro = 1;
    }

    // Cập nhật _nguonKyTu đúng theo đoạn vừa đổi: xoá phần cũ bị thay, chèn
    // phần mới — mọi ký tự người dùng vừa gõ đều đánh dấu "tay", kể cả dấu
    // cách vừa tự chèn ở trên.
    final soLuongXoa = _nguonKyTu.length - dau - duoi;
    _nguonKyTu.removeRange(dau, dau + soLuongXoa);
    _nguonKyTu.insertAll(
      dau,
      List<bool>.filled(doDaiChenVao + lechConTro, true),
    );

    final chon = _boDieuKhien.selection;
    final viTriConTro =
        (chon.isValid ? chon.end : chuMoiCuoi.length) + lechConTro;

    _neo = viTriConTro;
    _nguoiDungVuaGo();
    _ghiVaoO(chuMoiCuoi, viTriConTro);
    _henLuu();
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
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
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
    _nguonKyTu.clear();
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
        title: TextField(
          controller: _tenController,
          focusNode: _oTen,
          style: const TextStyle(fontSize: 18, color: Colors.black87),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
          ),
          onSubmitted: (_) => _oTen.unfocus(),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _bamNutLuu,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Lưu',
          ),
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
            ThanhCongCu(
              bat: _muonNghe,
              dangNghe: _dangNghe,
              songAm: _songAm,
              sanSang: _sanSang,
              // Bàn phím đóng thì còn phải né thanh điều hướng của máy; bàn
              // phím mở thì nó che mất thanh đó rồi, né nữa là hở một dải
              // trắng giữa thanh công cụ và bàn phím.
              neThanhDieuHuong: caoBanPhim == 0,
              khiBamMicro: _bamNutMicro,
              khiBamThuMuc: _moManHinhThuMuc,
              khiBamCaiDat: () =>
                  _moModalTam('Cài đặt', Icons.settings_outlined),
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
