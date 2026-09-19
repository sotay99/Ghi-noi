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
// không đụng chỉnh tả/bộ nhớ đệm định dạng. CÓ gõ-phím-thắng-micro (xem
// `_khiNguoiDungGoPhim`) để test vừa nói vừa gõ tay.
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

// Số phiên bản bản thử — TĂNG THỦ CÔNG mỗi lần đẩy bản mới lên Firebase
// Hosting, để người test biết chắc trình duyệt đã tải đúng bản mới nhất
// hay đang dùng bản cache cũ (Chrome hay giữ cache service worker của
// Flutter Web dù đã bấm tải lại thường).
const _phienBanThuNghiem = 'v10';

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

  // ---- văn bản đang hiển thị — giờ CHO PHÉP gõ tay trực tiếp vào khung
  // kết quả, với nguyên tắc gõ-phím-thắng-micro (y hệt tinh thần
  // `_nguoiDungVuaGo()` bên app chính): gõ một phím là micro tắt NGAY, tự
  // bật lại sau 1 giây không gõ tiếp. ----
  String _vanBan = '';
  final _boDieuKhienVanBan = TextEditingController();

  // Văn bản đã "chốt cứng" — giữ NGUYÊN VĂN (kể cả dấu xuống dòng/khoảng
  // trắng người dùng tự gõ). Micro chỉ được phép NỐI THÊM vào biến này
  // (không bao giờ dựng lại toàn bộ `_vanBan` bằng cách join(' ') danh sách
  // từ — làm vậy sẽ nuốt mất mọi dấu xuống dòng gõ tay, đúng lỗi người dùng
  // báo: bấm Enter xong nói tiếp thì dấu xuống dòng biến mất).
  String _vanBanDaChot = '';

  // Cờ chặn: khi TRUE nghĩa là đoạn `_boDieuKhienVanBan.text` đang được
  // chính code (do micro) ghi vào, không phải người dùng gõ — để
  // `_khiNguoiDungGoPhim` (gắn vào `onChanged`) không hiểu nhầm là người
  // dùng gõ rồi tắt oan micro.
  bool _dangGhiTuMicro = false;

  Timer? _henMoLaiMicroSauKhiGo;

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

  // Riêng cho nhánh điện thoại: chuỗi thô (sau khi đã cắt-đoạn-cuối-sạch)
  // của lần callback TRƯỚC trong CÙNG phiên hiện tại — dùng để lấy đúng
  // phần MỚI thêm vào bằng cách so sánh chuỗi (không phụ thuộc việc đoạn
  // lặp lại có viết hoa hay không, vì cách cắt theo chữ hoa không bắt được
  // mọi trường hợp lặp — xem log thực tế: có lúc lặp lại giữa câu, không
  // hoa chữ nào). Reset về rỗng mỗi khi phiên nghe mới bắt đầu.
  String _rawTruocDoTrongPhien = '';

  // Đánh số phiên nghe, y hệt `idPhien`/`_phienNgheHienTai` bên app chính —
  // để loại bỏ callback trễ của một phiên đã đóng (LỚP 1).
  int _phienHienTai = 0;

  Timer? _henBatLai;

  @override
  void initState() {
    super.initState();
    _laDiDong = _doanLaDiDong();
    _ghiLog('Phiên bản bản thử: $_phienBanThuNghiem');
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
    _rawTruocDoTrongPhien = '';
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

  /// Gắn vào `onChanged` của khung kết quả — NGUYÊN TẮC gõ-phím-thắng-micro,
  /// y hệt tinh thần `_nguoiDungVuaGo()` bên app chính: gõ một phím là micro
  /// tắt NGAY LẬP TỨC (không đợi micro nói xong đoạn dở dang), và tự bật lại
  /// sau 1 giây không gõ tiếp — không cần bấm nút bật lại bằng tay.
  ///
  /// Chỉ coi là "người dùng gõ" khi thay đổi này KHÔNG phải do chính code tự
  /// ghi vào (`_dangGhiTuMicro`) — nếu không sẽ tắt oan micro mỗi khi chính
  /// micro cập nhật chữ.
  void _khiNguoiDungGoPhim(String vanBanMoi) {
    if (_dangGhiTuMicro) return;
    _vanBan = vanBanMoi;
    // Coi toàn bộ chữ hiện có (kể cả phần vừa gõ tay, NGUYÊN VĂN không bị
    // tách-rồi-nối lại) là đã "chốt cứng", để khi micro bật lại nó nối tiếp
    // sau đúng chỗ người dùng vừa gõ mà không đè lên, xoá mất, hay làm mất
    // định dạng (xuống dòng, khoảng trắng) người dùng tự gõ.
    _vanBanDaChot = vanBanMoi;
    _tuDaChot = _tachTu(vanBanMoi);
    _partialTruocDo = [];
    _rawTruocDoTrongPhien = '';
    _ghiLog('Người dùng gõ tay — tắt micro ngay, tự bật lại sau 1 giây '
        'nếu không gõ tiếp.');
    _ngatMicroNgayViGoPhim();
  }

  Future<void> _ngatMicroNgayViGoPhim() async {
    _henMoLaiMicroSauKhiGo?.cancel();
    _henBatLai?.cancel();
    _phienHienTai++; // Huỷ callback của phiên đang chạy dở (LỚP 1).
    await _micro.cancel();
    if (mounted && _dangNghe) setState(() => _dangNghe = false);
    _henMoLaiMicroSauKhiGo = Timer(const Duration(seconds: 1), () {
      if (_muonNghe && !_micro.isListening) _batNghe();
    });
  }

  /// Ghi văn bản do MICRO tạo ra vào cả `_vanBan` lẫn khung gõ, mà không để
  /// `_khiNguoiDungGoPhim` hiểu nhầm là người dùng gõ (dùng cờ chặn).
  void _ghiVanBanTuMicro(String vanBanMoi) {
    _dangGhiTuMicro = true;
    _vanBan = vanBanMoi;
    _boDieuKhienVanBan.value = TextEditingValue(
      text: vanBanMoi,
      selection: TextSelection.collapsed(offset: vanBanMoi.length),
    );
    _dangGhiTuMicro = false;
  }

  Future<void> _saoChepVanBan() async {
    final noiDung = _vanBan.isEmpty ? '(chưa có chữ nào)' : _vanBan;
    await Clipboard.setData(ClipboardData(text: noiDung));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép kết quả vào bộ nhớ tạm'),
        duration: Duration(seconds: 2),
      ),
    );
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

  /// Nhật ký giờ nằm trong modal riêng (mở bằng nút nhỏ cạnh micro) thay vì
  /// chiếm nguyên một khối trên trang — theo yêu cầu để khung nhập to ra.
  void _moModalNhatKy() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, capNhatModal) {
            return AlertDialog(
              title: const Text('Nhật ký'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Scrollbar(
                  controller: _cuonNhatKy,
                  child: SingleChildScrollView(
                    controller: _cuonNhatKy,
                    child: SelectableText(
                      _nhatKy.isEmpty
                          ? '(chưa có nhật ký)'
                          : _nhatKy.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _saoChepNhatKy,
                  child: const Text('Sao chép tất cả'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _nhatKy.clear());
                    capNhatModal(() {});
                  },
                  child: const Text('Xoá tất cả'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _doiCheDoThietBi() {
    setState(() {
      _laDiDong = !_laDiDong;
    });
    _ghiLog('Chuyển tay sang chế độ: ${_laDiDong ? "điện thoại" : "PC"}');
  }

  // ------------------------------------------------------ thuật toán lõi

  // Chrome Android trả `recognizedWords` bị lặp lại TOÀN BỘ lịch sử của
  // phiên như tiền tố mỗi lần có kết quả mới (vd lần 3 gửi
  // "XinXin chàoXin chàoXin chào" thay vì chỉ "Xin chào") — mỗi lần lặp lại
  // luôn bắt đầu bằng chữ hoa. Quan sát log thực tế cho thấy: ĐOẠN CUỐI
  // CÙNG (tính từ lần chuyển chữ-thường-sang-chữ-hoa gần cuối chuỗi nhất)
  // luôn là bản ghi ĐẦY ĐỦ, SẠCH của toàn phiên tới thời điểm đó — không
  // lặp lại gì cả. Vì vậy chỉ cần cắt lấy đúng đoạn cuối này, bỏ hết phần
  // lặp lại dư thừa phía trước, là có được dữ liệu y hệt một partial bình
  // thường (giống PC) để đưa vào thuật toán tìm-điểm-nối bên dưới. Chỉ
  // dùng cho nhánh điện thoại — PC không có lỗi này nên không đụng tới.
  static const _chuThuongViet =
      'a-zàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const _chuHoaViet =
      'A-ZÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  static final RegExp _reRanhGioiDoanDinh =
      RegExp('[$_chuThuongViet][$_chuHoaViet]');

  /// Cắt lấy đoạn cuối cùng (từ lần chuyển chữ-thường→chữ-hoa gần cuối
  /// chuỗi nhất tới hết chuỗi) — đây là bản ghi sạch, không lặp.
  static String _catDoanCuoiCung(String s) {
    var viTri = 0;
    for (final m in _reRanhGioiDoanDinh.allMatches(s)) {
      viTri = m.start + 1;
    }
    return s.substring(viTri);
  }

  /// Nối [tuMoi] vào SAU [hienTai] theo đúng nguyên tắc "chỉ nối thêm,
  /// không dựng lại" — giữ NGUYÊN VĂN [hienTai] (kể cả dấu xuống dòng gõ
  /// tay), chỉ thêm dấu cách phân tách nếu [hienTai] chưa tự kết thúc bằng
  /// khoảng trắng/xuống dòng sẵn.
  static String _noiTiep(String hienTai, List<String> tuMoi) {
    if (tuMoi.isEmpty) return hienTai;
    final phanMoi = tuMoi.join(' ');
    if (hienTai.isEmpty) return phanMoi;
    if (hienTai.endsWith('\n') || hienTai.endsWith(' ')) {
      return '$hienTai$phanMoi';
    }
    return '$hienTai $phanMoi';
  }

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

  /// Thuật toán "tìm điểm nối": thử N từ CUỐI của [daChot] (từ dài nhất có
  /// thể xuống 1), xem [partialMoi] có bắt đầu đúng bằng N từ đó không (so
  /// khớp nới lỏng). `null` = không tìm được, coi là nội dung mới hoàn
  /// toàn. `[]` = trùng nguyên văn N từ cuối, không có gì thêm (nhân đôi).
  /// khác = phần mới thật sự nằm sau điểm nối.
  ///
  /// KHÔNG giới hạn N ở 6 như bản gốc bên app chính (nơi cụm lặp trên
  /// Android luôn ngắn) — trên nhánh điện thoại của bản test này, cụm lặp
  /// do Chrome tự lặp lại có thể dài hơn 6 từ rất nhiều (xem log thực tế:
  /// "bị lặp lại từ của tôi Bởi vậy cho nên..." lặp nguyên cụm mỗi lần),
  /// giới hạn 6 làm bỏ lỡ điểm nối và gây nối nhầm nguyên cụm dài vào cuối.
  static List<String>? _timDiemNoiTrong(
    List<String> daChot,
    List<String> partialMoi,
  ) {
    final soDaChot = daChot.length;
    final maxN = soDaChot < partialMoi.length ? soDaChot : partialMoi.length;
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

    if (_laDiDong) {
      _xuLyKetQuaDienThoai(noi);
    } else {
      _xuLyKetQuaPc(noi, xong);
    }
  }

  /// Nhánh PC: dùng nguyên thuật toán "chốt dần theo độ ổn định" gốc — coi
  /// [noi] là TOÀN BỘ hypothesis đang tăng dần của bộ nhận dạng (đúng như
  /// Web Speech API trên PC hoạt động).
  void _xuLyKetQuaPc(String noi, bool xong) {
    final tuMoi = _tachTu(noi);
    if (tuMoi.isEmpty) return;

    // Phần từ CHƯA/MỚI cần hiển thị thêm sau `_vanBanDaChot` hiện tại —
    // không bao giờ dựng lại toàn bộ văn bản, chỉ nối thêm, để giữ nguyên
    // định dạng (xuống dòng...) người dùng có thể đã gõ tay trước đó.
    List<String> phanMoiCanNoi;
    if (_batDauBangPhanDaChot(tuMoi, _tuDaChot)) {
      final tienToChung = _doDaiTienToChung(tuMoi, _partialTruocDo);
      if (tienToChung > _tuDaChot.length) {
        // Chỉ đúng phần MỚI được coi là ổn định (tienToChung tăng thêm) mới
        // thật sự chốt cứng vào `_vanBanDaChot` — phần còn lại của tuMoi
        // (dưới đây) vẫn chỉ là xem trước, chưa ghi đè lên bản chốt.
        final tuMoiChotThem = tuMoi.sublist(_tuDaChot.length, tienToChung);
        _vanBanDaChot = _noiTiep(_vanBanDaChot, tuMoiChotThem);
        _tuDaChot = tuMoi.sublist(0, tienToChung);
      }
      phanMoiCanNoi = tuMoi.sublist(_tuDaChot.length);
    } else {
      final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
      if (ketQuaNoi == null) {
        phanMoiCanNoi = tuMoi;
      } else if (ketQuaNoi.isEmpty) {
        _partialTruocDo = tuMoi;
        return;
      } else {
        phanMoiCanNoi = ketQuaNoi;
      }
    }

    _partialTruocDo = tuMoi;
    final vanBanHienThi = _noiTiep(_vanBanDaChot, phanMoiCanNoi);
    setState(() => _ghiVanBanTuMicro(vanBanHienThi));

    if (xong) {
      // Kết quả FINAL: toàn bộ nội dung hiện có (kể cả phần xem trước) coi
      // là chốt cứng, giữ nguyên văn.
      _vanBanDaChot = vanBanHienThi;
      _tuDaChot = _tachTu(vanBanHienThi);
      _partialTruocDo = [];
    }
  }

  /// Nhánh điện thoại: Chrome Android không gửi hypothesis tăng dần sạch —
  /// nó lặp lại lịch sử của CHÍNH PHIÊN NÀY làm tiền tố mỗi lần có kết quả
  /// mới, có lúc viết hoa đầu đoạn lặp (bắt được bằng `_catDoanCuoiCung`),
  /// có lúc KHÔNG (lặp giữa câu, toàn chữ thường — xem log thực tế: "rất"
  /// → "rấtrất là" → "rấtrất làrất là"...). Cách chắc ăn với CẢ HAI kiểu
  /// lặp: so sánh chuỗi thô của lần này với lần TRƯỚC trong cùng phiên —
  /// phần thêm vào luôn nằm ở cuối, vì bộ nhận dạng chỉ có APPEND, không
  /// bao giờ xoá. Lấy đúng phần đuôi mới đó rồi đưa vào tìm-điểm-nối để
  /// gộp vào nội dung đã chốt.
  void _xuLyKetQuaDienThoai(String noiGoc) {
    final noiDaCat = _catDoanCuoiCung(noiGoc);
    if (noiDaCat != noiGoc) {
      _ghiLog('  → cắt còn đoạn cuối sạch: "$noiDaCat"');
    }

    String phanMoi;
    if (_rawTruocDoTrongPhien.isNotEmpty &&
        noiDaCat.startsWith(_rawTruocDoTrongPhien)) {
      phanMoi = noiDaCat.substring(_rawTruocDoTrongPhien.length);
    } else {
      phanMoi = noiDaCat;
    }
    _rawTruocDoTrongPhien = noiDaCat;

    final tuMoi = _tachTu(phanMoi);
    if (tuMoi.isEmpty) return;
    _ghiLog('  → phần đuôi mới so với lần trước: "${tuMoi.join(' ')}"');

    final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
    List<String> tuThemVao;
    if (ketQuaNoi == null) {
      _ghiLog('  → không tìm được điểm nối, nối thẳng đuôi mới vào cuối');
      tuThemVao = tuMoi;
    } else if (ketQuaNoi.isEmpty) {
      _ghiLog('  → đuôi mới trùng hoàn toàn với phần đã chốt, bỏ qua');
      return;
    } else {
      _ghiLog('  → tìm được điểm nối, thêm ${ketQuaNoi.length} từ mới');
      tuThemVao = ketQuaNoi;
    }

    // Nhánh điện thoại không có FINAL đáng tin cậy — chốt cứng ngay mỗi lần
    // có nội dung mới, để không bao giờ mất chữ đã hiện ra. CHỈ NỐI THÊM
    // vào `_vanBanDaChot` (giữ nguyên văn, kể cả xuống dòng gõ tay), không
    // bao giờ dựng lại bằng join(' ') từ danh sách từ.
    _vanBanDaChot = _noiTiep(_vanBanDaChot, tuThemVao);
    _tuDaChot = _tachTu(_vanBanDaChot);
    setState(() => _ghiVanBanTuMicro(_vanBanDaChot));
  }

  @override
  void dispose() {
    _henBatLai?.cancel();
    _henMoLaiMicroSauKhiGo?.cancel();
    _micro.cancel();
    _cuonNhatKy.dispose();
    _boDieuKhienVanBan.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- giao diện

  @override
  Widget build(BuildContext context) {
    // Phím tắt Ctrl+G bật/tắt micro — CallbackShortcuts bọc NGOÀI Scaffold
    // nên vẫn bắt được dù đang focus vào khung nhập kết quả (Shortcuts đi
    // theo cây tổ tiên của focus hiện tại, không cần focus đúng widget này).
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG):
            () {
          if (_sanSang) _bamNutMicro();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Flowrite — thử micro trên Web ($_phienBanThuNghiem)'),
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
              Row(
                children: [
                  const Text('Kết quả (gõ tay được — gõ phím sẽ tắt micro '
                      'ngay, tự bật lại sau 1 giây)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: _saoChepVanBan,
                    child: const Text('Sao chép tất cả'),
                  ),
                ],
              ),
              Expanded(
                // Không giới hạn flex — nhật ký đã chuyển vào modal riêng
                // (nút nhỏ cạnh micro), nên khung nhập được dùng gần hết
                // chỗ trống, dễ thao tác trên màn hình hẹp của điện thoại.
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _boDieuKhienVanBan,
                    onChanged: _khiNguoiDungGoPhim,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '(chưa có chữ nào — nói hoặc gõ vào đây)',
                    ),
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _ghiVanBanTuMicro('');
                        _vanBanDaChot = '';
                        _tuDaChot = [];
                        _partialTruocDo = [];
                        _rawTruocDoTrongPhien = '';
                        _soLanPartial = 0;
                        _soLanFinal = 0;
                      });
                      _ghiLog('Xoá để thử lại.');
                    },
                    child: const Text('Xoá để thử lại'),
                  ),
                  const SizedBox(width: 16),
                  // Nút nhật ký — nhỏ, mở modal riêng thay vì chiếm chỗ
                  // ngay trên trang như trước.
                  Tooltip(
                    message: 'Xem nhật ký',
                    child: IconButton(
                      onPressed: _moModalNhatKy,
                      icon: const Icon(Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nút micro — thu nhỏ lại giống kiểu nút trong app APK,
                  // có phím tắt Ctrl+G (xem `CallbackShortcuts` bao ngoài).
                  Tooltip(
                    message: 'Bật/tắt micro (Ctrl+G)',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sanSang ? _bamNutMicro : null,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _muonNghe
                              ? Colors.red
                              : Colors.lightGreen.shade200,
                          border: Border.all(
                            color: Colors.blue.shade900,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _muonNghe ? Icons.mic : Icons.mic_none,
                          color: _muonNghe ? Colors.white : Colors.blue.shade900,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
