// Ghi Nói — một trang văn bản trắng, gõ phím và nói bằng micro cùng lúc.
//
// Ý tưởng cốt lõi: mọi chữ — dù đến từ bàn phím hay từ micro — đều rơi vào
// đúng vị trí con trỏ. Micro không tắt khi người dùng gõ phím.

import 'dart:async';

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
  final _micro = SpeechToText();

  /// Người dùng ĐANG MUỐN micro bật hay không. Khác với việc bộ nhận dạng có
  /// thực sự đang nghe hay không: Android tự ngắt sau vài giây im lặng, ta
  /// bật lại ngay, nhưng ý muốn của người dùng thì không đổi.
  bool _muonNghe = false;
  bool _dangNghe = false;
  bool _sanSang = false;
  String _loi = '';
  double _doTo = 0;

  /// Vị trí bắt đầu của câu đang được đọc dở, và độ dài phần chữ tạm đã chèn.
  /// Mỗi khi có kết quả mới, ta thay đúng đoạn [_neo, _neo + _daiTam) — nhờ
  /// vậy chữ được sửa dần tại chỗ thay vì lặp lại.
  int _neo = 0;
  int _daiTam = 0;

  /// Bật lên khi chính ta đang sửa nội dung, để phân biệt với người gõ phím.
  bool _tuSua = false;

  Timer? _hen;
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
    _micro.cancel();
    _boDieuKhien.dispose();
    _oChu.dispose();
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
    _tuSua = true;
    _boDieuKhien.value = TextEditingValue(
      text: cu,
      selection: TextSelection.collapsed(offset: cu.length),
    );
    _tuSua = false;
    _neo = cu.length;
  }

  Future<void> _luuVanBan() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaLuu, _boDieuKhien.text);
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
    try {
      await _micro.listen(
        onResult: _khiCoChu,
        localeId: _maNgonNgu,
        onSoundLevelChange: (muc) {
          if (mounted) setState(() => _doTo = muc);
        },
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
        _doTo = 0;
      });
    }
  }

  void _bamNutMicro() {
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

  // ------------------------------------------------------- chèn chữ vào chỗ

  void _datNeoTaiConTro() {
    final chon = _boDieuKhien.selection;
    _neo = chon.isValid ? chon.end : _boDieuKhien.text.length;
    _daiTam = 0;
  }

  /// Coi phần chữ tạm hiện tại là đã xong, và dời neo ra sau nó.
  void _chotCauDangDoc() {
    _neo += _daiTam;
    _daiTam = 0;
  }

  void _khiCoChu(dynamic ketQua) {
    final noi = ketQua.recognizedWords as String? ?? '';
    final xong = ketQua.finalResult as bool? ?? false;
    if (noi.isEmpty && !xong) return;

    final cu = _boDieuKhien.text;
    // Neo có thể lệch nếu người dùng vừa xoá bớt chữ — kéo về trong khoảng hợp lệ.
    if (_neo > cu.length) _neo = cu.length;
    var het = _neo + _daiTam;
    if (het > cu.length) het = cu.length;

    var chen = noi;
    // Nếu ngay trước neo đã có chữ mà chưa có dấu cách, thêm một dấu cách cho
    // câu mới không dính vào câu cũ.
    if (_neo > 0 && chen.isNotEmpty) {
      final truoc = cu[_neo - 1];
      if (truoc != ' ' && truoc != '\n' && truoc != '\t') {
        chen = ' $chen';
      }
    }

    final moi = cu.replaceRange(_neo, het, chen);
    final viTri = _neo + chen.length;

    _tuSua = true;
    _boDieuKhien.value = TextEditingValue(
      text: moi,
      selection: TextSelection.collapsed(offset: viTri),
    );
    _tuSua = false;

    _daiTam = chen.length;
    if (xong) {
      _chotCauDangDoc();
      _luuVanBan();
    }
  }

  /// Người dùng gõ phím hoặc bấm để dời con trỏ. Phần chữ tạm đang hiện được
  /// coi như đã xong, và câu nói tiếp theo sẽ rơi vào chỗ con trỏ mới.
  void _khiNguoiDungSua() {
    if (_tuSua) return;
    final chon = _boDieuKhien.selection;
    _neo = chon.isValid ? chon.end : _boDieuKhien.text.length;
    _daiTam = 0;
    _henLuu();
  }

  Timer? _henLuuTru;
  void _henLuu() {
    _henLuuTru?.cancel();
    _henLuuTru = Timer(const Duration(milliseconds: 600), _luuVanBan);
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
    final mau = Theme.of(context).colorScheme;

    return Scaffold(
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
        ],
      ),
      body: SafeArea(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                child: TextField(
                  controller: _boDieuKhien,
                  focusNode: _oChu,
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
          ],
        ),
      ),
      floatingActionButton: _NutMicro(
        bat: _muonNghe,
        dangNghe: _dangNghe,
        doTo: _doTo,
        mau: mau,
        khiBam: _sanSang ? _bamNutMicro : null,
      ),
    );
  }
}

/// Nút micro: vòng sáng quanh nút phình theo độ to của giọng nói, để người
/// dùng biết máy đang thật sự nghe được mình.
class _NutMicro extends StatelessWidget {
  const _NutMicro({
    required this.bat,
    required this.dangNghe,
    required this.doTo,
    required this.mau,
    required this.khiBam,
  });

  final bool bat;
  final bool dangNghe;
  final double doTo;
  final ColorScheme mau;
  final VoidCallback? khiBam;

  @override
  Widget build(BuildContext context) {
    final muc = (doTo.clamp(0, 10)) / 10.0;
    final vong = bat ? 64.0 + muc * 26.0 : 0.0;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (bat)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: vong,
              height: vong,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.18),
              ),
            ),
          FloatingActionButton.large(
            onPressed: khiBam,
            backgroundColor: khiBam == null
                ? Colors.grey.shade400
                : (bat ? Colors.red.shade600 : mau.primary),
            foregroundColor: Colors.white,
            tooltip: bat ? 'Tắt micro' : 'Bật micro',
            child: Icon(
              bat
                  ? (dangNghe ? Icons.mic : Icons.mic_none)
                  : Icons.mic_off_outlined,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}
