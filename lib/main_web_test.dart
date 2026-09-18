// Flowrite — BẢN THỬ NGHIỆM riêng cho Flutter Web.
//
// File này là MỘT APP FLUTTER ĐỘC LẬP, có `void main()`/`runApp()` riêng.
// KHÔNG import `main.dart`, `trang_soan_thao.dart` hay bất kỳ file nào khác
// của app Android hiện có — mục đích DUY NHẤT là kiểm chứng xem thuật toán
// xử lý kết quả giọng nói (chốt dần + tìm điểm nối) có chạy ổn với nguồn dữ
// liệu từ Web Speech API (qua package `speech_to_text` chạy trên web) hay
// không, TÁCH BIỆT HOÀN TOÀN khỏi app Android.
//
// Thuật toán lõi bên dưới là bản ĐƠN GIẢN HOÁ, viết lại (không import) từ
// `_khiCoChu`/`_tuDaChotTrongPhien`/`_partialTruocDo`/`_timDiemNoiTrong` và
// LỚP 1 (re-check `idPhien`) trong `lib/trang_soan_thao.dart` — xem chú thích
// ở đó để biết đầy đủ lý do thiết kế. Ở đây bỏ bớt các phần không cần cho mục
// đích test: không có "bộ đệm chống nhân đôi qua ranh giới phiên" (LỚP 2),
// không đụng chỉnh tả/bộ nhớ đệm định dạng/gõ-phím-thắng-micro.
//
// THÊM MỚI (vòng test di động):
// - Nhận diện thiết bị (điện thoại/PC) qua User-Agent, có nút chuyển tay để
//   ép chế độ khi nhận diện sai — hai chế độ dùng CÙNG MỘT khối logic, chỉ
//   khác một cờ `_laDiDong` để tránh việc sửa cho di động làm hỏng PC.
// - Khung "Nhật ký" hiển thị NGAY trên trang (không cần USB debug) để người
//   dùng chụp màn hình gửi lại khi rà lỗi trên điện thoại.
// - Vá lỗi nhân bản chữ đã thấy trên Chrome Android: khi không tìm được
//   điểm nối VÀ đoạn partial mới dài bằng/hơn toàn bộ phần đã chốt — dấu
//   hiệu bộ nhận dạng đang gửi lại TOÀN BỘ câu từ đầu chứ không phải phần
//   mới — thì coi partial mới là toàn bộ nội dung phiên, không nối thêm
//   (nối thêm trong trường hợp này là nguyên nhân gây chữ nhân bản chồng
//   chất trong ảnh chụp người dùng gửi).

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

// (Chỉ import đúng MỘT file `speech_to_text/speech_to_text.dart` — y hệt
// cách `trang_soan_thao.dart` đang dùng đã chứng minh hoạt động — thay vì
// đoán thêm đường import phụ (`speech_recognition_result.dart`,
// `speech_recognition_error.dart`) không có gì đảm bảo đúng khi môi trường
// này không compile-check được. `onResult`/`onError` vì thế nhận `dynamic`,
// giống hệt `_khiCoChu(dynamic ketQua, ...)` trong app chính.)

void main() {
  runApp(const UngDungThuMicroWeb());
}

class UngDungThuMicroWeb extends StatelessWidget {
  const UngDungThuMicroWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowrite — thử micro web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
      ),
      home: const TrangThuMicro(),
    );
  }
}

/// Đoán thiết bị bằng User-Agent — chỉ dùng làm giá trị GỢI Ý ban đầu, người
/// dùng luôn bấm được nút chuyển tay nếu đoán sai (ví dụ PC thu nhỏ cửa sổ).
bool _doanLaDiDong() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('android') ||
      ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('mobile');
}

class TrangThuMicro extends StatefulWidget {
  const TrangThuMicro({super.key});

  @override
  State<TrangThuMicro> createState() => _TrangThuMicroState();
}

class _TrangThuMicroState extends State<TrangThuMicro> {
  final _micro = SpeechToText();

  bool _sanSang = false;
  bool _muonNghe = false; // người dùng bấm bật, kể cả khi trình duyệt tạm dừng.
  bool _dangNghe = false;
  String _loi = '';

  // Chế độ thiết bị: đoán ban đầu qua User-Agent, người dùng đổi được bằng
  // nút chuyển tay. Cả hai chế độ dùng chung một khối xử lý bên dưới, chỉ
  // khác đúng MỘT cờ `_laDiDong` — sửa cho di động sẽ không đụng nhánh PC.
  late bool _laDiDong;

  // ---- đếm để nhìn bằng mắt lúc debug ----
  int _soLanPartial = 0;
  int _soLanFinal = 0;

  // ---- văn bản đang hiển thị ----
  String _vanBan = '';

  // ---- nhật ký hiển thị ngay trên trang, để test trên điện thoại không
  // cần USB debug — mỗi dòng có giờ:phút:giây để dễ đối chiếu. ----
  final List<String> _nhatKy = [];
  final _cuonNhatKy = ScrollController();

  // ---- trạng thái thuật toán "chốt dần theo độ ổn định" + "tìm điểm nối",
  // bản đơn giản hoá cho một PHIÊN duy nhất (không cần đệm ranh giới phiên
  // vì mục đích test không cần chính xác 100% qua mỗi lần trình duyệt tự
  // ngắt — chỉ cần QUAN SÁT được thuật toán chạy ổn hay không). ----
  List<String> _tuDaChot = [];
  List<String> _partialTruocDo = [];

  // Đánh số phiên nghe, y hệt `idPhien`/`_phienNgheHienTai` bên app chính —
  // để loại bỏ callback trễ của một phiên đã đóng (LỚP 1).
  int _phienHienTai = 0;

  Timer? _henBatLai;

  @override
  void initState() {
    super.initState();
    _laDiDong = _doanLaDiDong();
    _ghiLog('Đoán thiết bị: ${_laDiDong ? "điện thoại" : "PC"} '
        '(User-Agent: ${html.window.navigator.userAgent})');
    _khoiTao();
  }

  void _ghiLog(String dong) {
    final gio = DateTime.now();
    String hai(int n) => n.toString().padLeft(2, '0');
    final gioChuoi = '${hai(gio.hour)}:${hai(gio.minute)}:${hai(gio.second)}';
    if (!mounted) {
      _nhatKy.add('[$gioChuoi] $dong');
      return;
    }
    setState(() {
      _nhatKy.add('[$gioChuoi] $dong');
      if (_nhatKy.length > 300) _nhatKy.removeAt(0);
    });
    // Cuộn xuống dòng mới nhất sau khi khung vẽ lại.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cuonNhatKy.hasClients) {
        _cuonNhatKy.jumpTo(_cuonNhatKy.position.maxScrollExtent);
      }
    });
  }

  Future<void> _khoiTao() async {
    final duoc = await _micro.initialize(
      onStatus: _khiDoiTrangThai,
      onError: _khiCoLoi,
      debugLogging: false,
    );
    if (!mounted) return;
    setState(() {
      _sanSang = duoc;
      if (!duoc) {
        _loi = 'Trình duyệt không cấp được quyền micro/không hỗ trợ '
            'Web Speech API. Thử Chrome hoặc Edge, và bật quyền micro cho '
            'trang này.';
      }
    });
    _ghiLog('Khởi tạo micro: ${duoc ? "được" : "THẤT BẠI"}');
  }

  void _khiCoLoi(dynamic loi) {
    // Trên web, một lượt bộ nhận dạng tự ngắt vì im lặng cũng có thể bắn ra
    // qua onError tuỳ trình duyệt — coi các mã "nhẹ" như bên Android, không
    // làm phiền, cứ tự bật lại.
    final maLoi = loi.errorMsg as String? ?? '';
    final nhe = maLoi == 'error_no_match' ||
        maLoi == 'error_speech_timeout' ||
        maLoi == 'error_client' ||
        maLoi == 'error_busy';
    _ghiLog('onError: $maLoi ${nhe ? "(nhẹ, tự bật lại)" : "(HIỂN THỊ ĐỎ)"}');
    if (!nhe && mounted) {
      setState(() => _loi = 'Lỗi: $maLoi');
    }
    _henNgheLai();
  }

  void _khiDoiTrangThai(String trangThai) {
    _ghiLog('onStatus: $trangThai');
    final dangChay = trangThai == SpeechToText.listeningStatus;
    if (mounted && _dangNghe != dangChay) {
      setState(() => _dangNghe = dangChay);
    }
    if (!dangChay) {
      // Phiên vừa chết (trình duyệt tự dừng do im lặng, hoặc do web speech
      // API không hỗ trợ nghe liên tục dài như Android) — tăng số phiên NGAY,
      // đồng bộ, để mọi kết quả trễ của phiên cũ bị vứt (LỚP 1).
      _phienHienTai++;
      _henNgheLai();
    }
  }

  /// Y hệt `_henBatLai()` bên app chính: nếu người dùng vẫn đang muốn nghe mà
  /// phiên vừa tự ngắt (đặc điểm hay gặp trên web — Web Speech API không giữ
  /// phiên mở liên tục như Android), tự bật lại ngay để trải nghiệm như micro
  /// luôn bật.
  void _henNgheLai() {
    if (!_muonNghe) return;
    _henBatLai?.cancel();
    // Điện thoại (Chrome Android) có xu hướng tự ngắt phiên dày hơn PC — bật
    // lại nhanh hơn một chút để đỡ hụt tiếng nói giữa hai phiên.
    final treDoiChoDo =
        Duration(milliseconds: _laDiDong ? 150 : 300);
    _henBatLai = Timer(treDoiChoDo, () {
      if (_muonNghe && !_micro.isListening) _batNghe();
    });
  }

  Future<void> _batNghe() async {
    if (!_sanSang) return;
    final idPhien = ++_phienHienTai;
    _ghiLog('Bắt đầu phiên nghe #$idPhien (${_laDiDong ? "điện thoại" : "PC"})');
    try {
      await _micro.listen(
        onResult: (ketQua) {
          if (idPhien != _phienHienTai) {
            _ghiLog('Bỏ callback trễ của phiên cũ #$idPhien '
                '(phiên hiện tại là #$_phienHienTai)');
            return;
          }
          _khiCoKetQua(ketQua);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
        // Web Speech API không đảm bảo tôn trọng listenFor/pauseFor giống
        // Android (một số trình duyệt tự ngắt sớm hơn) — cứ khai để không
        // khác app chính, nhưng thiết kế phải chịu được việc trình duyệt
        // ngắt bất cứ lúc nào (_henNgheLai phía trên lo việc đó).
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 8),
      );
    } catch (loi) {
      _ghiLog('listen() ném lỗi: $loi');
      _henNgheLai();
    }
  }

  Future<void> _tatNghe() async {
    _phienHienTai++; // Phiên hiện tại coi như chết ngay (LỚP 1).
    _muonNghe = false;
    _henBatLai?.cancel();
    await _micro.cancel();
    if (mounted) setState(() => _dangNghe = false);
    _ghiLog('Người dùng tắt micro.');
  }

  void _bamNutMicro() {
    if (_muonNghe) {
      _tatNghe();
    } else {
      setState(() {
        _muonNghe = true;
        _loi = '';
      });
      _batNghe();
    }
  }

  Future<void> _saoChepNhatKy() async {
    final noiDung = _nhatKy.isEmpty ? '(chưa có nhật ký)' : _nhatKy.join('\n');
    await Clipboard.setData(ClipboardData(text: noiDung));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép nhật ký vào bộ nhớ tạm'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _doiCheDoThietBi() {
    setState(() {
      _laDiDong = !_laDiDong;
    });
    _ghiLog('Chuyển tay sang chế độ: ${_laDiDong ? "điện thoại" : "PC"}');
  }

  // ------------------------------------------------------ thuật toán lõi

  /// Tách chuỗi thành danh sách từ theo khoảng trắng — y hệt `_tachTu`.
  static List<String> _tachTu(String s) {
    final t = s.trim();
    if (t.isEmpty) return const [];
    return t.split(RegExp(r'\s+'));
  }

  /// Chuẩn hoá một từ để so khớp nới lỏng — y hệt `_chuanHoaSoKhopTho`.
  static String _chuanHoaTho(String tu) =>
      tu.toLowerCase().replaceAll(RegExp(r'[.,!?;:]+$'), '');

  static bool _khopTho(String a, String b) =>
      _chuanHoaTho(a) == _chuanHoaTho(b);

  /// Độ dài tiền tố chung khớp CHÍNH XÁC — y hệt `_doDaiTienToChung`.
  static int _doDaiTienToChung(List<String> a, List<String> b) {
    final n = a.length < b.length ? a.length : b.length;
    var i = 0;
    while (i < n && a[i] == b[i]) {
      i++;
    }
    return i;
  }

  /// [partialMoi] có bắt đầu bằng ĐÚNG toàn bộ [daChot] hay không — y hệt
  /// `_batDauBangPhanDaChot`.
  static bool _batDauBangPhanDaChot(
    List<String> partialMoi,
    List<String> daChot,
  ) {
    if (partialMoi.length < daChot.length) return false;
    for (var i = 0; i < daChot.length; i++) {
      if (!_khopTho(partialMoi[i], daChot[i])) return false;
    }
    return true;
  }

  /// Thuật toán "tìm điểm nối": thử N = 6..1 từ CUỐI của [daChot], xem
  /// [partialMoi] có bắt đầu đúng bằng N từ đó không (so khớp nới lỏng).
  /// `null` = không tìm được, coi là nội dung mới hoàn toàn.
  /// `[]`   = trùng nguyên văn N từ cuối, không có gì thêm (nhân đôi).
  /// khác   = phần mới thật sự nằm sau điểm nối.
  static List<String>? _timDiemNoiTrong(
    List<String> daChot,
    List<String> partialMoi,
  ) {
    final soDaChot = daChot.length;
    final maxN = soDaChot < 6 ? soDaChot : 6;
    for (var n = maxN; n >= 1; n--) {
      if (partialMoi.length < n) continue;
      final duoiDaChot = daChot.sublist(soDaChot - n);
      var khop = true;
      for (var i = 0; i < n; i++) {
        if (!_khopTho(partialMoi[i], duoiDaChot[i])) {
          khop = false;
          break;
        }
      }
      if (khop) {
        if (partialMoi.length == n) return const [];
        return partialMoi.sublist(n);
      }
    }
    return null;
  }

  void _khiCoKetQua(dynamic ketQua) {
    final noi = (ketQua.recognizedWords as String? ?? '').trim();
    final xong = ketQua.finalResult as bool? ?? false;

    setState(() {
      if (xong) {
        _soLanFinal++;
      } else {
        _soLanPartial++;
      }
    });
    _ghiLog('${xong ? "FINAL" : "partial"}: "$noi"');

    if (noi.isEmpty) return;
    final tuMoi = _tachTu(noi);
    if (tuMoi.isEmpty) return;

    List<String> hienThi;
    if (_batDauBangPhanDaChot(tuMoi, _tuDaChot)) {
      // Đường bình thường: bộ nhận dạng vẫn cộng dồn đúng từ đầu phiên.
      final tienToChung = _doDaiTienToChung(tuMoi, _partialTruocDo);
      if (tienToChung > _tuDaChot.length) {
        _tuDaChot = tuMoi.sublist(0, tienToChung);
      }
      hienThi = tuMoi;
    } else {
      // Bộ nhận dạng có vẻ "viết lại" phần đã chốt — tìm điểm nối.
      final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
      if (ketQuaNoi == null) {
        if (tuMoi.length >= _tuDaChot.length) {
          // Partial mới dài bằng/hơn toàn bộ phần đã chốt nhưng không nối
          // được ở đâu cả — dấu hiệu bộ nhận dạng đang gửi lại TOÀN BỘ câu
          // từ đầu phiên (hay gặp trên Chrome Android) chứ không phải một
          // câu mới thật sự. Coi tuMoi là toàn bộ nội dung, KHÔNG nối thêm
          // — nối thêm ở đây là nguyên nhân gây chữ nhân bản chồng chất.
          _ghiLog('  → không tìm được điểm nối, partial dài hơn phần đã '
              'chốt: THAY THẾ toàn bộ (tránh nhân bản)');
          hienThi = tuMoi;
        } else {
          // Partial mới ngắn hơn hẳn phần đã chốt — nhiều khả năng là một
          // câu mới thật sự bắt đầu sau khi phiên cũ đã chốt xong.
          _ghiLog('  → không tìm được điểm nối, partial ngắn: NỐI sau '
              'phần đã chốt');
          hienThi = [..._tuDaChot, ...tuMoi];
        }
      } else if (ketQuaNoi.isEmpty) {
        // Nhân đôi thuần tuý — bỏ qua hoàn toàn.
        _ghiLog('  → nhân đôi thuần tuý, bỏ qua');
        _partialTruocDo = tuMoi;
        return;
      } else {
        _ghiLog('  → tìm được điểm nối, thêm ${ketQuaNoi.length} từ mới');
        hienThi = [..._tuDaChot, ...ketQuaNoi];
      }
    }

    _partialTruocDo = tuMoi;

    setState(() {
      _vanBan = hienThi.join(' ');
    });

    if (xong) {
      // Kết quả FINAL: toàn bộ nội dung hiện có coi là chốt cứng, chờ đoạn
      // nói tiếp theo (phiên có thể vẫn tiếp tục, không chủ động dừng ở
      // đây — y hệt app chính, `_henNgheLai`/trình duyệt lo việc chuyển
      // phiên).
      _tuDaChot = _tachTu(_vanBan);
      _partialTruocDo = [];
    }
  }

  @override
  void dispose() {
    _henBatLai?.cancel();
    _micro.cancel();
    _cuonNhatKy.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- giao diện

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flowrite — thử micro trên Web'),
        actions: [
          TextButton.icon(
            onPressed: _doiCheDoThietBi,
            icon: Icon(
              _laDiDong ? Icons.smartphone : Icons.laptop_mac,
              color: Colors.white,
            ),
            label: Text(
              _laDiDong ? 'Điện thoại' : 'PC',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_sanSang)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Đang khởi tạo micro… nếu trình duyệt hỏi quyền, hãy '
                    'chọn Cho phép.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              if (_loi.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_loi, style: const TextStyle(color: Colors.red)),
                ),
              Row(
                children: [
                  Icon(
                    _dangNghe ? Icons.circle : Icons.circle_outlined,
                    size: 12,
                    color: _dangNghe ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(_dangNghe ? 'Đang nghe' : 'Không nghe'),
                  const Spacer(),
                  Text('PARTIAL: $_soLanPartial   FINAL: $_soLanFinal'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _vanBan.isEmpty ? '(chưa có chữ nào)' : _vanBan,
                      style: const TextStyle(fontSize: 18, height: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Nhật ký',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: _saoChepNhatKy,
                    child: const Text('Sao chép tất cả'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _nhatKy.clear()),
                    child: const Text('Xoá nhật ký'),
                  ),
                ],
              ),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Scrollbar(
                    controller: _cuonNhatKy,
                    child: SingleChildScrollView(
                      controller: _cuonNhatKy,
                      child: SelectableText(
                        _nhatKy.isEmpty
                            ? '(chưa có nhật ký)'
                            : _nhatKy.join('\n'),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _sanSang ? _bamNutMicro : null,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _muonNghe ? Colors.red : Colors.blue,
                    ),
                    child: Icon(
                      _muonNghe ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _vanBan = '';
                      _tuDaChot = [];
                      _partialTruocDo = [];
                      _soLanPartial = 0;
                      _soLanFinal = 0;
                    });
                    _ghiLog('Xoá để thử lại.');
                  },
                  child: const Text('Xoá để thử lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
