// Trang soạn thảo — một trang văn bản trắng, gõ phím và nói bằng micro cùng
// lúc. Mọi chữ — dù đến từ bàn phím hay từ micro — đều rơi vào đúng vị trí
// con trỏ. Micro không tắt khi người dùng gõ phím; ngược lại, gõ phím ngắt
// hẳn micro trong một giây rồi tự bật lại.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'cai_dat.dart';
import 'kho_du_lieu.dart';
import 'kiem_tra_chinh_ta.dart';
import 'man_hinh_cai_dat.dart';
import 'man_hinh_thu_muc.dart';
import 'mo_hinh.dart';
import 'thanh_cong_cu.dart';
import 'thong_bao_giua.dart';
import 'trang_huong_dan.dart';

/// Bộ điều khiển ô văn bản riêng, biết gạch đỏ chân những từ sai chính tả AI
/// tìm được (`loi`) và báo lại khi người dùng bấm đúng vào một từ như vậy.
/// Việc gạch chân được vẽ ngay trong `buildTextSpan` — cách duy nhất chèn
/// định dạng riêng cho từng đoạn vào một `TextField` đang cho gõ được.
class _BoDieuKhienChinhTa extends TextEditingController {
  _BoDieuKhienChinhTa({super.text});

  /// Danh sách lỗi hiện có. Đây là NGUỒN DUY NHẤT của sự thật — trang soạn
  /// thảo sửa trực tiếp danh sách này rồi gọi `notifyListeners()` để vẽ lại,
  /// không giữ một bản sao nào khác.
  final List<LoiChinhTa> loi = [];

  void Function(LoiChinhTa loi, Offset viTriManHinh)? khiBamTuSai;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final vb = text;
    if (loi.isEmpty || vb.isEmpty) return TextSpan(style: style, text: vb);

    final sapXep = List<LoiChinhTa>.from(loi)
      ..sort((a, b) => a.batDau.compareTo(b.batDau));
    final children = <InlineSpan>[];
    var vt = 0;
    for (final l in sapXep) {
      if (l.batDau < vt || l.ketThuc > vb.length || l.batDau >= l.ketThuc) {
        continue; // Vị trí không còn hợp lệ (văn bản đã đổi) — bỏ qua, vẽ như bình thường.
      }
      if (l.batDau > vt) children.add(TextSpan(text: vb.substring(vt, l.batDau)));
      children.add(TextSpan(
        text: vb.substring(l.batDau, l.ketThuc),
        style: const TextStyle(
          decoration: TextDecoration.underline,
          decorationColor: Colors.red,
          decorationThickness: 2,
          decorationStyle: TextDecorationStyle.wavy,
        ),
        recognizer: TapGestureRecognizer()
          ..onTapDown = (chiTiet) => khiBamTuSai?.call(l, chiTiet.globalPosition),
      ));
      vt = l.ketThuc;
    }
    if (vt < vb.length) children.add(TextSpan(text: vb.substring(vt)));

    return TextSpan(style: style, children: children);
  }
}

class TrangSoanThao extends StatefulWidget {
  const TrangSoanThao({
    super.key,
    required this.kho,
    required this.caiDat,
    required this.ghiChuId,
  });

  final KhoDuLieu kho;
  final CaiDat caiDat;
  final String ghiChuId;

  @override
  State<TrangSoanThao> createState() => _TrangSoanThaoState();
}

class _TrangSoanThaoState extends State<TrangSoanThao>
    with WidgetsBindingObserver {
  final _boDieuKhien = _BoDieuKhienChinhTa();
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

  /// Lịch sử Lùi lại/Tiến tới. Mỗi điểm mốc là trạng thái TRỌN VẸN của bài
  /// (chữ + đánh dấu nguồn gốc từng ký tự) tại một ranh giới có ý nghĩa —
  /// KHÔNG phải từng ký tự một. Ranh giới đó là: bắt đầu một đợt gõ tay mới
  /// (_apDungChinhSuaNguoiDung, chỉ lần đầu của đợt), hoặc bắt đầu một lượt
  /// micro mới (_batMicro). Nhờ đặt mốc đúng hai chỗ này, mỗi lần Lùi lại
  /// luôn lùi vừa đúng một đợt gõ hoặc một lượt nói trọn vẹn — không cắt
  /// ngang giữa chừng, và tự nhiên phân biệt được đợt đó là gõ tay hay nói,
  /// vì hai đợt hai nguồn không bao giờ trộn chung một điểm mốc.
  final List<_TrangThaiVanBan> _lichSuLui = [];
  final List<_TrangThaiVanBan> _lichSuToi = [];
  static const _soLuongLichSuToiDa = 50;

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

  /// Vị trí trong bài mà AI đã kiểm tra chính tả tới đó rồi. Mỗi lần kiểm
  /// tra chỉ gửi phần văn bản TỪ đây trở đi, không gửi lại phần đã kiểm tra.
  int _viTriDaKiemTraChinhTa = 0;
  Timer? _henChinhTa;
  final _dichVuChinhTa = DichVuKiemTraChinhTa();

  @override
  void initState() {
    super.initState();
    _ghiChuHienTai = widget.kho.timGhiChu(widget.ghiChuId)!;
    _tenController = TextEditingController(text: _ghiChuHienTai.ten);
    _oTen.addListener(_khiOTenMatFocus);

    WidgetsBinding.instance.addObserver(this);
    _boDieuKhien.addListener(_khiNguoiDungSua);
    _boDieuKhien.khiBamTuSai = _khiBamTuSai;

    final banDau = _ghiChuHienTai.noiDung;
    if (banDau.isNotEmpty) {
      _ghiVaoO(banDau, banDau.length);
    }
    _neo = banDau.length;
    _nguonKyTu.addAll(List<bool>.filled(banDau.length, true));
    _viTriDaKiemTraChinhTa = banDau.length;

    _khoiTaoMicro();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hen?.cancel();
    _henLuuTru?.cancel();
    _henGoXong?.cancel();
    _henChinhTa?.cancel();
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
    if (mounted) {
      hienThongBaoGiua(context, 'Đã lưu "${_ghiChuHienTai.ten}" vào bộ nhớ máy.');
    }
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
    final loi = widget.kho.doiTenGhiChu(_ghiChuHienTai.id, tenMoi);
    if (loi != null) {
      _tenController.text = _ghiChuHienTai.ten;
      _bao(loi);
      return;
    }
    widget.kho.luu();
  }

  // ---------------------------------------------------------------- cài đặt

  Future<void> _moCaiDat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManHinhCaiDat(
          caiDat: widget.caiDat,
          // Người dùng vừa tắt tính năng trong màn Cài đặt — xoá bộ nhớ
          // đánh dấu ký tự ngay tại đây, vì nó là dữ liệu riêng của trang
          // soạn thảo, màn Cài đặt không cầm được.
          khiTatTuDongChenKhoangCach: () {
            setState(() {
              _nguonKyTu
                ..clear()
                ..addAll(List<bool>.filled(_boDieuKhien.text.length, true));
            });
          },
          // Người dùng vừa tắt "kiểm tra chính tả bằng AI": xoá hết gạch đỏ
          // đang hiển thị ngay, giống cách khiTatTuDongChenKhoangCach xoá bộ
          // nhớ đánh dấu ký tự của nó.
          khiTatKiemTraChinhTa: () {
            _boDieuKhien.loi.clear();
            _boDieuKhien.notifyListeners();
          },
          khiKiemTraLaiMicro: _khoiTaoMicro,
        ),
      ),
    );
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
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    _viTriDaKiemTraChinhTa = g.noiDung.length;

    widget.kho.datGhiChuDangMo(id);
  }

  // ----------------------------------------------------------------- micro

  Future<void> _khoiTaoMicro() async {
    final duoc = await _micro.initialize(
      onStatus: _khiDoiTrangThai,
      onError: (loi) {
        // 'error_no_match' và 'error_speech_timeout' chỉ nghĩa là người dùng
        // im lặng — không phải hỏng, đừng làm phiền họ. 'error_client' xảy ra
        // rất thường xuyên vì app tự bật lại micro liên tục (kể cả lúc không
        // nghe thấy gì) — Android thỉnh thoảng từ chối một lượt bật lại quá
        // nhanh, tự hết ngay ở lượt kế tiếp, không phải sự cố đáng báo.
        final nhe = loi.errorMsg == 'error_no_match' ||
            loi.errorMsg == 'error_speech_timeout' ||
            loi.errorMsg == 'error_client';
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
    _luuDiemMoc(); // Mỗi lượt micro mới là một điểm có thể Lùi lại về.
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
    // Chặn NGAY mọi kết quả còn đang trên đường về, trước khi ra lệnh tắt —
    // nếu không, một câu đang nói dở sẽ trả về kết quả chốt SAU KHI đã bấm
    // tắt, đổ thêm một lần chữ nữa đè lên trên chữ vừa hiện.
    _boQuaCauNay = true;
    _chotCauDangDoc(); // Chữ đã hiện ra đứng im tại đó, không sửa thêm.
    // cancel() vứt bỏ hẳn phiên nghe, không như stop() còn cố trả về một kết
    // quả chốt cuối cùng — chính kết quả chốt đó là nguồn gốc của lỗi nhân
    // đôi câu nói khi bấm tắt micro.
    await _micro.cancel();
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

    _dieuChinhLoiChinhTaSauKhiSua(_neo, het - _neo, chenVao.length);

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
      if (!_laKhoangTrang(truoc)) chen = ' $chen';
    }

    // Luôn giữ NGAY SAU CON TRỎ là một khoảng trắng trong suốt lúc câu còn
    // đang đọc dở — không đợi tới lúc câu chốt xong mới chèn.
    //
    // Đây là cách DUY NHẤT thực sự chặn được lỗi bộ gõ tiếng Việt gộp ngược
    // ('Thành' + phím 's' → 'Thánh'): ứng dụng chỉ biết được người dùng vừa
    // gõ phím gì SAU KHI bàn phím đã xử lý xong. Nếu người dùng gõ phím tạo
    // dấu (Telex: s, f, r, x, j...) NGAY TRONG LÚC câu còn dở — tức là chưa
    // kịp chốt để chèn dấu cách — bộ gõ vẫn nhìn thấy nguyên âm trần ngay
    // trước con trỏ và gộp ngược y hệt. Chèn dấu cách theo TỪNG lần nghe rõ
    // thêm (không đợi chốt) thì tại BẤT KỲ thời điểm nào người dùng gõ phím
    // xen vào, trước con trỏ luôn sẵn một dấu cách, không phải nguyên âm.
    if (widget.caiDat.tuDongChenKhoangCach && !_laKhoangTrang(chen[chen.length - 1])) {
      chen = '$chen ';
    }

    if (chen == _chuTam) return; // Không có gì đổi, khỏi động vào ô văn bản.

    _thayVungTamBangGiongNoi(chen);

    if (xong) {
      _chotCauDangDoc();
      _luuVanBan();
      _lenLichKiemTraChinhTa();
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

    // Người dùng chọn "Không tự động bật lại Micro" trong Cài đặt: micro cứ
    // tắt vậy luôn, đợi tự tay bấm nút micro mới nghe lại — không hẹn giờ gì.
    _henGoXong?.cancel();
    if (widget.caiDat.thoiGianBatLaiGiay < 0) return;

    // Đồng hồ đếm lại từ đầu sau MỖI phím, nên nó chỉ điểm khi người dùng đã
    // thật sự ngừng tay.
    if (_microNgungDeGo) {
      _henGoXong = Timer(
        Duration(
          milliseconds: (widget.caiDat.thoiGianBatLaiGiay * 1000).round(),
        ),
        _batLaiSauKhiGoXong,
      );
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
    // Chỉ lưu điểm mốc vào LẦN GÕ ĐẦU TIÊN của một đợt (micro chưa bị cắt vì
    // gõ trước đó) — các phím gõ tiếp theo trong cùng đợt (trước khi micro
    // tự bật lại) không lưu thêm, để một đợt gõ trọn vẹn ứng với đúng một
    // lần Lùi lại, không phải mỗi phím một lần.
    //
    // Truyền tay _chuGanNhat (chữ CŨ) và _neo (vị trí con trỏ CŨ): bộ điều
    // khiển tại đây đã mang chữ MỚI rồi, tự đọc _boDieuKhien.text sẽ chụp
    // nhầm đúng cái vừa gõ, không lùi được.
    if (!_microNgungDeGo) {
      _luuDiemMoc(vanBan: _chuGanNhat, viTriConTro: _neo);
    }

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
    // Tắt trong Cài đặt thì bỏ hẳn bước này, dính liền như soạn thảo thường.
    if (widget.caiDat.tuDongChenKhoangCach &&
        doDaiChenVao > 0 &&
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
    _dieuChinhLoiChinhTaSauKhiSua(dau, soLuongXoa, doDaiChenVao + lechConTro);
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
    _lenLichKiemTraChinhTa();
  }

  // --------------------------------------------------- kiểm tra chính tả AI

  /// Vùng [vitri, vitri + soXoa) trong bài vừa bị thay bằng [soChen] ký tự
  /// mới. Dời mọi lỗi nằm SAU vùng đó theo đúng độ lệch; lỗi nào NẰM TRONG
  /// (hoặc đè lên) vùng vừa đổi thì coi như không còn đáng tin và bỏ luôn —
  /// văn bản ở đó đã khác, gạch đỏ cũ không còn ý nghĩa gì nữa.
  void _dieuChinhLoiChinhTaSauKhiSua(int vitri, int soXoa, int soChen) {
    if (soXoa == 0 && soChen == 0) return;
    final ketThucXoa = vitri + soXoa;
    final lech = soChen - soXoa;

    _boDieuKhien.loi.removeWhere((l) => l.batDau < ketThucXoa && l.ketThuc > vitri);
    for (var i = 0; i < _boDieuKhien.loi.length; i++) {
      final l = _boDieuKhien.loi[i];
      if (l.batDau >= ketThucXoa) _boDieuKhien.loi[i] = l.dich(lech);
    }

    if (_viTriDaKiemTraChinhTa > ketThucXoa) {
      _viTriDaKiemTraChinhTa += lech;
    } else if (_viTriDaKiemTraChinhTa > vitri) {
      // Đoạn đã kiểm tra bị sửa giữa chừng — coi như chưa kiểm tra từ đó.
      _viTriDaKiemTraChinhTa = vitri;
    }
    // scheduleMicrotask, KHÔNG gọi notifyListeners() ngay tại đây: hàm này
    // chạy ngay bên trong _khiNguoiDungSua — chính nó là một listener của
    // _boDieuKhien. Gọi notifyListeners() đồng bộ ở đây sẽ gọi lại ngay lập
    // tức _khiNguoiDungSua một lần nữa trong khi lần gọi trước còn dang dở
    // (chuMoi lúc đó vẫn khác _chuGanNhat vì _ghiVaoO() chưa kịp chạy), tạo
    // vòng lặp đệ quy vô hạn — đúng nguyên nhân app đơ cứng khi gõ tay. Dời
    // việc thông báo ra một microtask thì nó chạy SAU KHI toàn bộ lệnh gọi
    // hiện tại (kể cả _ghiVaoO cập nhật _chuGanNhat) đã xong.
    scheduleMicrotask(_boDieuKhien.notifyListeners);
  }

  /// Hẹn giờ gọi AI kiểm tra chính tả, dồn nhiều thay đổi liên tiếp (gõ từng
  /// phím, hay từng phần câu nói dội về) lại thành một lần gọi duy nhất khi
  /// mọi thứ đã tạm lắng — đúng lúc "vừa ra xong một câu văn mới".
  void _lenLichKiemTraChinhTa() {
    if (!widget.caiDat.kiemTraChinhTaBangAI) return;
    _henChinhTa?.cancel();
    _henChinhTa = Timer(const Duration(milliseconds: 900), _kiemTraChinhTaMoi);
  }

  Future<void> _kiemTraChinhTaMoi() async {
    if (!widget.caiDat.kiemTraChinhTaBangAI || !mounted) return;

    final vanBan = _boDieuKhien.text;
    final tuViTri = _viTriDaKiemTraChinhTa.clamp(0, vanBan.length);
    if (tuViTri >= vanBan.length) return;

    final doan = vanBan.substring(tuViTri);
    if (doan.trim().isEmpty) {
      _viTriDaKiemTraChinhTa = vanBan.length;
      return;
    }

    List<LoiChinhTa> loiMoi;
    try {
      loiMoi = await _dichVuChinhTa.kiemTra(doan);
    } catch (_) {
      return; // Mất mạng hay máy chủ lỗi — im lặng bỏ qua, lần sau thử lại.
    }
    if (!mounted) return;

    // Bài có thể đã đổi trong lúc chờ AI trả lời — chỉ áp dụng kết quả nếu
    // đúng nguyên đoạn vừa gửi vẫn còn ở đúng chỗ cũ.
    final vbHienTai = _boDieuKhien.text;
    if (tuViTri + doan.length > vbHienTai.length ||
        vbHienTai.substring(tuViTri, tuViTri + doan.length) != doan) {
      return;
    }

    _boDieuKhien.loi.addAll(loiMoi.map((l) => l.dich(tuViTri)));
    _viTriDaKiemTraChinhTa = tuViTri + doan.length;
    _boDieuKhien.notifyListeners();
  }

  /// Người dùng vừa bấm đúng vào một từ đang bị gạch đỏ — mở menu đề xuất.
  Future<void> _khiBamTuSai(LoiChinhTa loi, Offset viTriManHinh) async {
    final chon = await showMenu<(String, String?)>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: [
        for (final tu in loi.deXuat)
          PopupMenuItem(value: ('thay', tu), child: Text(tu)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ('xoa', null),
          child: Text('Xoá', style: TextStyle(color: Colors.red.shade600)),
        ),
        PopupMenuItem(
          value: ('huy', null),
          child: Text('Huỷ đề xuất', style: TextStyle(color: Colors.green.shade700)),
        ),
      ],
    );
    if (chon == null || !mounted) return;

    switch (chon.$1) {
      case 'thay':
        _apDungThayTheChinhTa(loi, chon.$2!);
      case 'xoa':
        _apDungThayTheChinhTa(loi, '');
      default: // 'huy'
        _boDieuKhien.loi.remove(loi);
        _boDieuKhien.notifyListeners();
    }
  }

  /// Thay đúng vùng [loi.batDau, loi.ketThuc) bằng [thayBang] — dùng chung
  /// cho cả "chọn từ AI đề xuất" (thayBang là từ mới) và "Xoá" (thayBang
  /// rỗng). Đi qua cùng con đường với mọi chỉnh sửa khác của app: cập nhật
  /// _nguonKyTu (đánh dấu là "tay gõ"), dời các lỗi khác, rồi lưu bài.
  void _apDungThayTheChinhTa(LoiChinhTa loi, String thayBang) {
    final vb = _boDieuKhien.text;
    final conKhop = loi.ketThuc <= vb.length &&
        vb.substring(loi.batDau, loi.ketThuc) == loi.tu;
    if (!conKhop) {
      // Bài đã đổi từ lúc gạch đỏ này xuất hiện — bỏ đề xuất, không đụng gì
      // vào bài nữa vì không còn chắc đúng chỗ.
      _boDieuKhien.loi.remove(loi);
      _boDieuKhien.notifyListeners();
      return;
    }

    final moi = vb.replaceRange(loi.batDau, loi.ketThuc, thayBang);
    _nguonKyTu.removeRange(loi.batDau, loi.ketThuc);
    _nguonKyTu.insertAll(loi.batDau, List<bool>.filled(thayBang.length, true));
    _boDieuKhien.loi.remove(loi);
    _dieuChinhLoiChinhTaSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, thayBang.length);

    final viTri = loi.batDau + thayBang.length;
    _neo = viTri;
    _ghiVaoO(moi, viTri);
    _henLuu();
  }

  // ----------------------------------------------------------- lùi/tiến tới

  /// Chụp lại trọn vẹn trạng thái NGAY TRƯỚC một đợt gõ/nói sắp diễn ra.
  /// Bỏ qua nếu chữ chưa đổi gì so với điểm mốc gần nhất (tránh những điểm
  /// mốc thừa, ví dụ micro thử bật lại liên tiếp do lỗi mạng).
  ///
  /// Nhận tham số tường minh thay vì tự đọc `_boDieuKhien.text` — ở nơi gọi
  /// từ `_apDungChinhSuaNguoiDung`, bộ điều khiển đã mang chữ MỚI (đã gõ
  /// xong) từ trước khi hàm đó kịp chạy dòng nào, nên phải truyền tay chữ CŨ
  /// (`_chuGanNhat`) vào mới chụp đúng trạng thái ngay TRƯỚC đợt gõ này.
  void _luuDiemMoc({String? vanBan, int? viTriConTro}) {
    final vb = vanBan ?? _boDieuKhien.text;
    if (_lichSuLui.isNotEmpty && _lichSuLui.last.vanBan == vb) return;
    setState(() {
      _lichSuLui.add(_TrangThaiVanBan(
        vanBan: vb,
        nguonKyTu: List<bool>.from(_nguonKyTu),
        viTriConTro: viTriConTro ?? _viTriConTroHienTai(),
      ));
      if (_lichSuLui.length > _soLuongLichSuToiDa) _lichSuLui.removeAt(0);
      _lichSuToi.clear(); // Hành động mới thì đường Tiến tới cũ không còn ý nghĩa.
    });
  }

  int _viTriConTroHienTai() {
    final chon = _boDieuKhien.selection;
    return chon.isValid ? chon.start : _boDieuKhien.text.length;
  }

  void _lui() {
    if (_lichSuLui.isEmpty) return;
    _lichSuToi.add(_TrangThaiVanBan(
      vanBan: _boDieuKhien.text,
      nguonKyTu: List<bool>.from(_nguonKyTu),
      viTriConTro: _viTriConTroHienTai(),
    ));
    final truoc = _lichSuLui.removeLast();
    _apDungTrangThai(truoc);
  }

  void _toi() {
    if (_lichSuToi.isEmpty) return;
    _lichSuLui.add(_TrangThaiVanBan(
      vanBan: _boDieuKhien.text,
      nguonKyTu: List<bool>.from(_nguonKyTu),
      viTriConTro: _viTriConTroHienTai(),
    ));
    final sau = _lichSuToi.removeLast();
    _apDungTrangThai(sau);
  }

  void _apDungTrangThai(_TrangThaiVanBan tt) {
    // An toàn trước: đừng để một kết quả giọng nói còn treo ghi đè lên đúng
    // lúc vừa khôi phục xong.
    if (_muonNghe) _tatMicro();
    _chuTam = '';
    _neo = tt.viTriConTro.clamp(0, tt.vanBan.length);
    setState(() {
      _nguonKyTu
        ..clear()
        ..addAll(tt.nguonKyTu);
    });
    // Lùi/tiến đổi hẳn nội dung bài — vị trí các gạch đỏ cũ không còn đáng
    // tin nữa. Coi cả bài vừa khôi phục là "chưa kiểm tra", để lần kiểm tra
    // kế tiếp (nếu tính năng đang bật) tự soát lại từ đầu bài mới này.
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    _viTriDaKiemTraChinhTa = tt.vanBan.length;
    _ghiVaoO(tt.vanBan, _neo);
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
    if (mounted) {
      hienThongBaoGiua(
        context,
        'Đã sao chép tất cả văn bản vào bộ nhớ tạm của thiết bị',
      );
    }
  }

  /// Bôi đen toàn bộ văn bản, để người dùng dùng menu chọn sẵn có của máy
  /// (Sao chép, Cắt, Chia sẻ...) thao tác tiếp trên phần đã chọn.
  void _chonTatCa() {
    final chu = _boDieuKhien.text;
    if (chu.isEmpty) return;
    _oChu.requestFocus();
    _boDieuKhien.selection = TextSelection(baseOffset: 0, extentOffset: chu.length);
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
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    _viTriDaKiemTraChinhTa = 0;
    _boQuaCauNay = _micro.isListening;
    await _luuVanBan();
    if (mounted) _bao('Đã xoá toàn bộ văn bản.');
  }

  void _moModalTam(String tieuDe, IconData bieuTuong, [String? moTaThem]) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(bieuTuong, size: 28),
        title: Text(tieuDe),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tính năng đang nâng cấp.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (moTaThem != null) ...[
                const SizedBox(height: 12),
                Text(
                  moTaThem,
                  textAlign: TextAlign.left,
                  style: const TextStyle(height: 1.5, color: Color(0xFF5F6368)),
                ),
              ],
            ],
          ),
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

  /// Ngưỡng bề ngang phân biệt màn hình rộng (máy tính bảng — giữ giao diện
  /// một dòng như từ trước tới giờ) và màn hình hẹp (điện thoại — tên tệp và
  /// công cụ phải tách hai dòng, không thì đè lên nhau). 600dp là mốc
  /// Material Design vẫn dùng để phân biệt "compact" và "medium".
  static const _nguongManHinhHep = 600.0;

  Widget _oTenField() {
    return TextField(
      controller: _tenController,
      focusNode: _oTen,
      maxLength: doDaiTenToiDa,
      inputFormatters: [FilteringTextInputFormatter.deny(kyTuCamTrongTen)],
      style: const TextStyle(fontSize: 18, color: Colors.black87),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        counterText: '',
      ),
      onSubmitted: (_) => _oTen.unfocus(),
    );
  }

  List<Widget> _dsNutCongCu() => [
        IconButton(
          onPressed: _lichSuLui.isEmpty ? null : _lui,
          icon: const Icon(Icons.undo),
          tooltip: 'Lùi lại',
        ),
        IconButton(
          onPressed: _lichSuToi.isEmpty ? null : _toi,
          icon: const Icon(Icons.redo),
          tooltip: 'Tiến tới',
        ),
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
        IconButton(
          onPressed: _chonTatCa,
          icon: const Icon(Icons.select_all),
          tooltip: 'Chọn tất cả',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    // Tự đo chiều cao bàn phím thay vì giao cho Scaffold: đặt thanh công cụ
    // làm dòng cuối của thân trang rồi chừa đúng khoảng đó bên dưới, thì
    // thanh luôn nằm khít mép trên bàn phím.
    final caoBanPhim = MediaQuery.viewInsetsOf(context).bottom;
    final manHinhHep = MediaQuery.sizeOf(context).width < _nguongManHinhHep;

    // Màn hình rộng (máy tính bảng): tên tệp và công cụ chung một dòng, như
    // thiết kế gốc. Màn hình hẹp (điện thoại): tên tệp một dòng riêng, công
    // cụ xuống dòng thứ hai — không thì tên tệp dài bị công cụ đè lên, hoặc
    // ngược lại công cụ bị ép chật tới mức khó bấm trúng.
    final appBar = manHinhHep
        ? AppBar(
            title: _oTenField(),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _dsNutCongCu()),
                ),
              ),
            ),
          )
        : AppBar(
            title: _oTenField(),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            actions: _dsNutCongCu(),
          );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBar,
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
                    hintText: 'Gõ chữ và Bấm Micro để nói...\n'
                        'Thực hiện song song 2 việc trên cùng lúc',
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
              khiBamCaiDat: _moCaiDat,
              khiBamHuongDan: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManHinhHuongDan()),
              ),
              khiBamAI: () => _moModalTam(
                'Làm việc với AI',
                Icons.smart_toy_outlined,
                'AI sẽ giúp bạn tóm tắt văn bản, mở rộng văn bản, gọt dũa '
                    'câu chữ, đề xuất ý tưởng dựa trên nội dung đang có, và '
                    'trò chuyện thêm về mọi thứ liên quan tới văn bản này.\n\n'
                    'AI chỉ trả về kết quả bằng văn bản — không trả về âm '
                    'thanh, hình ảnh, video hay bất kỳ loại tệp tin nào khác.',
              ),
              khiBamBanPhim: () => _moModalTam(
                'Bàn phím',
                Icons.keyboard_outlined,
                'Bàn phím riêng của Flowrite sẽ cho bạn tự chọn ngôn ngữ và '
                    'kiểu gõ, tích hợp sẵn nhiều ngôn ngữ và kiểu gõ khác '
                    'nhau trong cùng một nơi.\n\n'
                    'Hữu ích nhất cho máy chưa cài sẵn bàn phím ngôn ngữ '
                    'mình cần, hoặc khi bạn muốn dùng hẳn bàn phím và bộ gõ '
                    'riêng của Flowrite thay vì bàn phím mặc định của máy.',
              ),
            ),
            SizedBox(height: caoBanPhim),
          ],
        ),
      ),
    );
  }
}

/// Một điểm mốc trong lịch sử Lùi lại/Tiến tới — trọn vẹn chữ và bảng đánh
/// dấu nguồn gốc từng ký tự tại thời điểm đó.
class _TrangThaiVanBan {
  const _TrangThaiVanBan({
    required this.vanBan,
    required this.nguonKyTu,
    required this.viTriConTro,
  });

  final String vanBan;
  final List<bool> nguonKyTu;
  final int viTriConTro;
}
