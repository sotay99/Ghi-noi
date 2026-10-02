// Màn hình "Trò chuyện về văn bản này"/"Trò chuyện về đoạn văn đã chọn"
// (mục trong menu "Làm việc với AI", tên đổi tuỳ có vùng chọn hay không lúc
// bấm — xem `thanh_cong_cu.dart`) — toàn màn hình, giống chuyển sang một
// trang mới (Navigator.push), có nút đóng (X) ở AppBar để quay lại trang
// soạn thảo. Chỉ người dùng hỏi-đáp với AI (Gemini) về văn bản đang soạn —
// không sửa văn bản gốc, không có luồng nào khác ngoài chat.
//
// Lượt hỏi ĐẦU TIÊN của một cuộc trò chuyện MỚI luôn gửi kèm toàn văn bản
// NẾU người dùng không tự chọn thẻ đính kèm nào khác. Từ lượt thứ hai trở
// đi KHÔNG tự kèm gì nữa — muốn AI đọc thêm gì thì bấm nút "+" cạnh khung
// nhập, chọn MỘT trong hai thẻ: "Toàn bộ văn bản mới nhất" hoặc "Đoạn văn
// đang chọn" (chỉ bấm được khi trang soạn thảo phía sau đang có vùng chọn —
// xem [layDoanVanDangChon]). Chỉ MỘT thẻ cho mỗi lượt gửi — chọn thẻ mới
// thì mất thẻ cũ; thẻ đã đính kèm cho một tin nhắn ĐÃ GỬI hiện lại y nguyên
// phía trên bong bóng tin nhắn đó khi xem lại lịch sử.
//
// [lichSu] là THAM CHIẾU do nơi gọi (`trang_soan_thao.dart`) cầm — màn hình
// này chỉ thêm/xoá thẳng vào đó, nơi gọi tự động "nhớ" theo từng tệp ghi chú
// mà không cần callback nào thêm (xem `_TrangSoanThaoState._troChuyenTheoTep`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'cai_dat.dart';
import 'doan_thiet_bi.dart';
import 'ghi_am_the.dart';
import 'gui_ghi_am_gemini.dart';
import 'gui_tro_chuyen_gemini.dart';
import 'ket_qua_ghi_am_the.dart';
import 'loai_thiet_bi.dart';
import 'lua_chon_phim_tat.dart';
import 'the_ghi_am.dart' show dinhDangMmSs;
import 'theo_doi_tap_doi_phim.dart';
import 'tin_nhan_tro_chuyen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const _mauChinh = Color(0xFF1A73E8);

class ManHinhTroChuyen extends StatefulWidget {
  const ManHinhTroChuyen({
    super.key,
    required this.lichSu,
    required this.layVanBanHienTai,
    required this.layDoanVanDangChon,
    required this.caiDat,
  });

  /// Đọc phím tắt Micro/Ghi âm đã cài (`caiDat.phimTatMicro`/`phimTatGhiAm`)
  /// — CÙNG phím tắt với trang soạn thảo chính, hoạt động y hệt trong kênh
  /// chat này (xem `_khiPhimCucBoTroChuyen`).
  final CaiDat caiDat;

  /// Tham chiếu sống — mọi thêm/xoá ở đây đều "lưu" thẳng vào bộ nhớ đệm của
  /// tệp ghi chú đang mở (do nơi gọi cầm List này).
  final List<TinNhanTroChuyen> lichSu;

  /// Gọi lại mỗi khi cần ĐÍNH KÈM toàn văn bản (lượt đầu tiên, hoặc khi
  /// người dùng chủ động bấm "+" → "Toàn bộ văn bản mới nhất") — LUÔN lấy
  /// bản MỚI NHẤT tại đúng thời điểm gửi, không phải bản chụp lúc mở màn
  /// hình.
  final String Function() layVanBanHienTai;

  /// Nội dung vùng chọn hiện có ở trang soạn thảo PHÍA SAU màn hình chat
  /// này, hay `null` nếu không có — trang soạn thảo vẫn "sống" trong cây
  /// widget (chỉ bị che, không bị huỷ) nên gọi lại hàm này bất cứ lúc nào
  /// trong lúc màn hình chat đang mở đều cho kết quả đúng (và ổn định,
  /// không đổi, vì trang phía sau không thể tương tác được trong lúc này).
  final String? Function() layDoanVanDangChon;

  @override
  State<ManHinhTroChuyen> createState() => _ManHinhTroChuyenState();
}

class _ManHinhTroChuyenState extends State<ManHinhTroChuyen> {
  final _oNhap = TextEditingController();
  final _cuon = ScrollController();
  bool _dangGui = false;
  LoaiDinhKemTroChuyen _dinhKemHienTai = LoaiDinhKemTroChuyen.khong;

  /// Chỉ có ý nghĩa khi [_dinhKemHienTai] == doanChon — nội dung đoạn chọn
  /// đã chụp lúc bấm "+", KHÔNG đọc lại `layDoanVanDangChon()` mỗi lần gửi
  /// (đề phòng giữa lúc bấm "+" và lúc thật sự gửi, dù hiếm, có gì đó đổi).
  String? _noiDungDoanChonDinhKem;

  /// Khác `null` khi đang sửa lại một tin nhắn người dùng đã gửi (bấm bút
  /// chì) — giữ ĐÚNG chỉ số của tin nhắn đó trong [ManHinhTroChuyen.lichSu].
  /// Gửi lại lúc này sẽ XOÁ tin nhắn cũ CÙNG mọi tin nhắn sau nó (kể cả câu
  /// trả lời của AI), rồi coi như vừa gõ một câu hỏi mới đúng tại vị trí đó
  /// — xem `_guiHoacXacNhanSua`.
  int? _dangSuaChiSo;

  // ------------------------------------------------------- Micro/Ghi âm

  /// "Micro (vừa nói vừa ra chữ)" — phiên bản RIÊNG, ĐƠN GIẢN HƠN cho kênh
  /// chat: không đụng gì tới bộ máy micro phức tạp (neo/vùng-tạm/chốt câu)
  /// của trang soạn thảo chính — chỉ cần append chữ nhận dạng được vào ô
  /// nhập, gõ tay thì thắng (xem `_khiONhapDoi`).
  final SpeechToText _micro = SpeechToText();
  bool _micKhoiTaoXong = false;
  bool _micDangNghe = false;

  /// Vị trí BẮT ĐẦU của cụm chữ mic đang "sống" (đang được cập nhật dần)
  /// trong `_oNhap.text`, và chữ mic đã chèn ở đó tại lần cập nhật GẦN NHẤT
  /// — mỗi kết quả mới từ `onResult` thay đúng đoạn đó bằng chữ mới (đúng
  /// kiểu "càng nói càng sửa câu đang nói dở", y hệt core-logic của trang
  /// soạn thảo, chỉ đơn giản hoá phần offset).
  int _micDiemBatDau = 0;
  String _micChuGanNhat = '';

  /// Chrome trên Android (web) không gửi `recognizedWords` là "toàn bộ
  /// utterance tính từ đầu, sạch sẽ" — nó CỘNG DỒN vô hạn, ghép thêm nội
  /// dung mới vào đuôi của TOÀN BỘ raw đã gửi ở lần gọi trước, nên chuỗi cứ
  /// phình to dần qua mỗi lần callback. Không trừ phần ĐÃ THẤY này ra là
  /// nguồn gốc lỗi "chữ chạy lung tung, lặp lại rất nhiều" người dùng báo —
  /// y hệt lý do `_rawTichLuyChromeAndroid` tồn tại ở trang soạn thảo chính
  /// (`_khiCoChu`), chỉ là bản này của kênh chat từng QUÊN áp dụng.
  String _rawTichLuyChromeAndroidChat = '';

  /// Đặt `true` NGAY TRƯỚC khi tự gán `_oNhap.value` (do mic tự chèn chữ)
  /// — `_khiONhapDoi` dựa vào cờ này để phân biệt "đổi do mic" (bỏ qua) với
  /// "đổi do người dùng gõ tay" (chốt lại đoạn mic đang sống, dời neo ra
  /// sau vị trí gõ).
  bool _micTuDoiONhap = false;

  /// Luôn soi ĐÚNG thiết bị trong "Cài đặt Micro" (chọn tay hoặc hệ thống tự
  /// đoán) — y hệt trang soạn thảo chính, không tự có bộ cấu hình riêng.
  ThietBi get _thietBiChoMicChat => widget.caiDat.thietBiChonTay ?? doanThietBi();

  /// iPhone trên web không dùng được "Micro (vừa nói vừa ra chữ)" — y hệt
  /// trang soạn thảo chính (`_microDungDuocTrenThietBiNay`).
  bool get _microChatDungDuocTrenThietBiNay =>
      !(kIsWeb && _thietBiChoMicChat == ThietBi.iphone);

  String? _micMaNgonNguChat;
  Timer? _henTuTatMicChatImLang;

  /// Android tự ngắt một PHIÊN `listen()` sau một khoảng — y hệt trang
  /// soạn thảo chính (`_henBatLai`), bật lại NGAY lúc đó (không coi là
  /// người dùng tắt mic) để `_micDangNghe` (ý định của người dùng, điều
  /// khiển UI) không nhầm với trạng thái "đang nghe thật" của TỪNG phiên.
  /// Quan trọng hơn cả việc giữ UI đúng: mỗi phiên mới lại reset
  /// `_rawTichLuyChromeAndroidChat` — bộ đệm cộng dồn của Chrome Android
  /// (xem đó) nhờ vậy không bao giờ phình to qua nhiều phút nói liên tục,
  /// mà luôn gọn trong PHẠM VI MỘT PHIÊN NGẮN như bên trang soạn thảo
  /// chính — đây mới là nguyên nhân thật khiến bản kênh chat (một phiên
  /// `listen()` DUY NHẤT, dài tới 10 phút) hay bị lặp/lộn chữ hơn hẳn,
  /// không phải do thiếu bước trừ raw (đã có từ trước, không đủ).
  Timer? _henBatLaiMicChat;

  void _datLaiHenTuTatMicChatImLang() {
    _henTuTatMicChatImLang?.cancel();
    _henTuTatMicChatImLang = Timer(
      Duration(seconds: widget.caiDat.thoiGianTuTatMicroGiay),
      () {
        if (_micDangNghe) _tatMicChat();
      },
    );
  }

  void _hienCanhBaoMicIphoneChat() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Không khả dụng trên iPhone'),
        content: const Text(
          'Micro (vừa nói vừa ra chữ) tại điện thoại Iphone không thể khả '
          'dụng trên môi trường Website, chỉ khả dụng trên môi trường app '
          'mobile. Nếu bạn cho rằng thiết bị của bạn không phải Iphone, hãy '
          'bấm vào Cài đặt Micro. Bạn có thể tải app mobile cho Iphone để '
          'sử dụng tính năng này.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _khiONhapDoi() {
    if (!_micDangNghe) return;
    // Có chữ mới (gõ tay hay mic) — huỷ đếm ngược tự tắt vì im lặng, đặt lại
    // từ đầu, y hệt trang soạn thảo chính.
    _datLaiHenTuTatMicChatImLang();
    if (_micTuDoiONhap) return;
    // Người dùng vừa gõ tay (hoặc dán/xoá) trong lúc mic đang nghe — gõ tay
    // THẮNG: coi như cụm chữ mic hiện tại đã chốt xong, lần kết quả mic kế
    // tiếp sẽ bắt đầu một cụm MỚI ngay tại vị trí con trỏ hiện giờ.
    final vt = _oNhap.selection.baseOffset;
    _micDiemBatDau = vt >= 0 ? vt : _oNhap.text.length;
    _micChuGanNhat = '';
  }

  /// Ưu tiên tiếng Việt nếu máy có — y hệt
  /// `_TrangSoanThaoState._chonTiengViet`.
  Future<String?> _chonTiengVietChat() async {
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

  Future<void> _batMicChat() async {
    // Ghi âm và Micro loại trừ nhau — bật cái này thì tự tắt cái kia trước.
    if (_ghiDangMo) return; // đang có hộp thoại ghi âm mở — không thể bật mic.
    if (!_microChatDungDuocTrenThietBiNay) {
      _hienCanhBaoMicIphoneChat();
      return;
    }
    if (!_micKhoiTaoXong) {
      _micKhoiTaoXong =
          await _micro.initialize(onStatus: _khiMicDoiTrangThai, debugLogging: false);
      if (!_micKhoiTaoXong) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Máy không dùng được micro. Hãy kiểm tra quyền ghi âm.'),
          ));
        }
        return;
      }
    }
    _micMaNgonNguChat = await _chonTiengVietChat();
    if (!mounted) return;
    setState(() => _micDangNghe = true);
    _datLaiHenTuTatMicChatImLang();
    await _batPhienNgheMicChat();
  }

  /// Bắt đầu đúng MỘT phiên `listen()` — tách riêng khỏi [_batMicChat] để
  /// còn gọi lại được mỗi khi Android tự ngắt phiên (xem
  /// `_henBatLaiMicChat`), không chạy lại phần khởi tạo/xin quyền mỗi lần.
  /// Reset cả ba biến theo-dõi-phiên ngay tại đây — phiên MỚI thì cụm chữ
  /// "đang sống" của phiên CŨ coi như đã chốt xong (y hệt lúc người dùng tự
  /// gõ tay chen vào, xem `_khiONhapDoi`), và bộ đệm cộng dồn Chrome Android
  /// (`_rawTichLuyChromeAndroidChat`) phải rỗng lại — đây chính là tác dụng
  /// THẬT giúp bộ đệm đó không bao giờ phình to qua nhiều phút nói liên tục.
  Future<void> _batPhienNgheMicChat() async {
    _micDiemBatDau = _oNhap.text.length;
    _micChuGanNhat = '';
    _rawTichLuyChromeAndroidChat = '';
    try {
      await _micro.listen(
        onResult: (ketQua) {
          if (!_micDangNghe) return;
          _datLaiHenTuTatMicChatImLang();
          // `chen` phải LUÔN LÀ TOÀN BỘ cụm chữ đang nói dở tính từ đầu
          // utterance (để thay nguyên vẹn đoạn [batDau, ketThucCu) bên
          // dưới) — Android bản web không gửi `recognizedWords` kiểu đó, nó
          // CỘNG DỒN VÔ HẠN (ghép thêm đuôi mới vào TOÀN BỘ raw của mọi lần
          // gọi trước, kể cả phần đã lặp/im ắng), nên phải tự trừ phần raw
          // đã thấy rồi GHÉP đuôi mới đó vào `_micChuGanNhat` cũ mới ra đúng
          // cụm chữ thật. Không trừ là nguồn gốc lỗi "chữ chạy lung tung,
          // lặp lại rất nhiều" — xem `_rawTichLuyChromeAndroidChat`.
          var chen = ketQua.recognizedWords;
          if (kIsWeb && _thietBiChoMicChat == ThietBi.android) {
            final raw = chen;
            if (raw.startsWith(_rawTichLuyChromeAndroidChat)) {
              final duoiMoi = raw.substring(_rawTichLuyChromeAndroidChat.length);
              chen = duoiMoi.isEmpty
                  ? _micChuGanNhat
                  : (_micChuGanNhat.isEmpty || _micChuGanNhat.endsWith(' ')
                      ? '$_micChuGanNhat$duoiMoi'
                      : '$_micChuGanNhat $duoiMoi');
            }
            // else: raw không còn khớp tiền tố đã theo dõi (trình duyệt vừa
            // âm thầm khởi động lại bộ đệm) — coi nguyên `chen` hiện tại
            // (raw) là cụm chữ thật, an toàn hơn là trừ nhầm.
            _rawTichLuyChromeAndroidChat = raw;
          }
          final vb = _oNhap.text;
          final batDau = _micDiemBatDau.clamp(0, vb.length);
          final ketThucCu = (batDau + _micChuGanNhat.length).clamp(batDau, vb.length);
          final moi = vb.substring(0, batDau) + chen + vb.substring(ketThucCu);
          _micTuDoiONhap = true;
          _oNhap.value = TextEditingValue(
            text: moi,
            selection: TextSelection.collapsed(offset: batDau + chen.length),
          );
          _micTuDoiONhap = false;
          _micChuGanNhat = chen;
        },
        localeId: _micMaNgonNguChat,
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
      if (mounted) setState(() => _micDangNghe = false);
    }
  }

  /// Hệ điều hành/engine tự ngắt phiên `listen()` sau một khoảng — y hệt
  /// trang soạn thảo chính (`_henBatLai`): nếu người dùng CHƯA tự tắt mic
  /// (`_micDangNghe` vẫn `true`), bật lại ngay một phiên MỚI, không coi là
  /// "đã tắt". Thấy ĐÚNG "notListening" mới bật lại — tránh vòng lặp vô ích
  /// nếu lỡ nhận nhầm trạng thái khác.
  void _khiMicDoiTrangThai(String trangThai) {
    final dangNghe = trangThai == SpeechToText.listeningStatus;
    if (dangNghe || !mounted) return;
    if (!_micDangNghe) return; // người dùng đã tự bấm tắt — đừng bật lại.
    _henBatLaiMicChat?.cancel();
    _henBatLaiMicChat = Timer(const Duration(milliseconds: 200), () {
      if (_micDangNghe && mounted) _batPhienNgheMicChat();
    });
  }

  Future<void> _tatMicChat() async {
    _henTuTatMicChatImLang?.cancel();
    _henBatLaiMicChat?.cancel();
    // Đặt cờ `false` TRƯỚC khi gọi `stop()` — `stop()` kích `onStatus`
    // ("notListening") một cách KHÔNG đồng bộ; `_khiMicDoiTrangThai` đọc
    // đúng cờ này để quyết định có bật lại hay không, nên đặt sau dễ lọt
    // đúng khoảng hở đó, vô tình bật lại mic ngay sau khi người dùng tắt.
    if (mounted) setState(() => _micDangNghe = false);
    await _micro.stop();
  }

  Future<void> _bamMicChat() async {
    if (_micDangNghe) {
      await _tatMicChat();
    } else {
      await _batMicChat();
    }
  }

  /// Phiên "Ghi âm (nói xong mới ra chữ)" đang mở hay không — xem
  /// `_moGhiAmChat`.
  bool _ghiDangMo = false;

  /// Bấm phím tắt Ghi âm. Hộp thoại ghi âm đã mở sẵn thì KHÔNG tới được đây
  /// — nó không `barrierDismissible` nên chiếm hẳn route hiện tại, và
  /// `_khiPhimCucBoTroChuyen` đã tự nhường (route của CHÍNH màn hình chat
  /// không còn "current") cho bộ dò phím tắt CỤC BỘ của chính hộp thoại đó
  /// (`_KhungGhiAmChat._khiPhimCucBo`, xử lý tạm dừng/tiếp tục). Ở đây chỉ
  /// còn lo đúng MỘT việc: mic đang nghe thì tắt mic trước (loại trừ nhau),
  /// rồi mở phiên ghi âm mới.
  Future<void> _bamGhiAmChat() async {
    if (_ghiDangMo) return;
    if (_micDangNghe) await _tatMicChat();
    await _moGhiAmChat();
  }

  Future<void> _moGhiAmChat() async {
    if (!mounted) return;
    setState(() => _ghiDangMo = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _KhungGhiAmChat(
        phimTatGhiAm: widget.caiDat.phimTatGhiAm,
        khiCoVanBan: (chu) {
          if (!mounted) return;
          final vb = _oNhap.text;
          final ghep = vb.isEmpty ? chu : (vb.endsWith(' ') || vb.endsWith('\n') ? '$vb$chu' : '$vb $chu');
          setState(() => _oNhap.text = ghep);
          _oNhap.selection = TextSelection.collapsed(offset: _oNhap.text.length);
        },
      ),
    );
    if (mounted) setState(() => _ghiDangMo = false);
  }

  /// Phím tắt Micro/Ghi âm TOÀN CỤC của màn hình chat — CÙNG phím tắt với
  /// trang soạn thảo chính (`caiDat.phimTatMicro`/`phimTatGhiAm`), hoạt
  /// động y hệt trong lúc đang ở kênh chat này (trang soạn thảo phía sau tự
  /// nhường vì route của nó không còn "current" nữa lúc này).
  bool _khopPhimTatTroChuyen(LuaChonPhimTat lc, KeyEvent event) {
    switch (lc.loai) {
      case 'tab':
        return event.logicalKey == LogicalKeyboardKey.tab &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            !HardwareKeyboard.instance.isShiftPressed &&
            !HardwareKeyboard.instance.isMetaPressed;
      case 'ctrl':
        return HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            event.logicalKey.keyLabel.toUpperCase() == (lc.phim ?? '').toUpperCase();
      default:
        return false;
    }
  }

  late final _theoDoiTapDoiTroChuyen =
      TheoDoiTapDoiPhim(khiTapDoi: _khiHoanTatTapDoiTroChuyen);

  void _khiHoanTatTapDoiTroChuyen(String loai) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    if (widget.caiDat.phimTatMicro.loai == loai) {
      _bamMicChat();
    } else if (widget.caiDat.phimTatGhiAm.loai == loai) {
      _bamGhiAmChat();
    }
  }

  bool _khiPhimCucBoTroChuyen(KeyEvent event) {
    if (!mounted) return false;
    // `xuLy` CẦN thấy cả sự kiện NHẢ (KeyUpEvent) để xác nhận đã buông
    // phím — lọc hết KeyUp trước khi tới đây (như dòng cũ từng làm) thì dò
    // "bấm Ctrl/Shift 2 lần" không bao giờ kết luận được, phím tắt kiểu đó
    // coi như chết hẳn trong kênh chat.
    _theoDoiTapDoiTroChuyen.xuLy(event);
    if (event is! KeyDownEvent) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    if (_khopPhimTatTroChuyen(widget.caiDat.phimTatMicro, event)) {
      _bamMicChat();
      return true;
    }
    if (_khopPhimTatTroChuyen(widget.caiDat.phimTatGhiAm, event)) {
      _bamGhiAmChat();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Mở kênh chat lúc trang soạn thảo đang có vùng chọn (dù từ mục "Trò
    // chuyện về đoạn văn đã chọn" hay bất kỳ lối vào nào khác) — tự đính
    // kèm sẵn "Đoạn văn đang chọn" ngay khi mở, không bắt người dùng phải tự
    // bấm "+" lại. Cuộc trò chuyện cũ (nếu có, đang trống hay đang dở) vẫn
    // giữ nguyên, chỉ thêm thẻ chờ gửi cho lượt kế tiếp.
    final doan = widget.layDoanVanDangChon();
    if (doan != null) {
      _dinhKemHienTai = LoaiDinhKemTroChuyen.doanChon;
      _noiDungDoanChonDinhKem = doan;
    }
    _oNhap.addListener(_khiONhapDoi);
    HardwareKeyboard.instance.addHandler(_khiPhimCucBoTroChuyen);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_khiPhimCucBoTroChuyen);
    _theoDoiTapDoiTroChuyen.dispose();
    _henTuTatMicChatImLang?.cancel();
    _henBatLaiMicChat?.cancel();
    if (_micDangNghe) _micro.stop();
    _oNhap.removeListener(_khiONhapDoi);
    _oNhap.dispose();
    _cuon.dispose();
    super.dispose();
  }

  void _cuonXuongDuoi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cuon.hasClients) return;
      _cuon.animateTo(
        _cuon.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _gui() async {
    final cauHoi = _oNhap.text.trim();
    if (cauHoi.isEmpty || _dangGui) return;
    _oNhap.clear();

    final laLuotDau = widget.lichSu.isEmpty;
    // Lượt đầu tiên của một cuộc trò chuyện MỚI vẫn LUÔN tự đính kèm toàn
    // văn nếu người dùng chưa tự chọn thẻ nào khác — giữ nguyên hành vi cũ.
    final dinhKem = _dinhKemHienTai != LoaiDinhKemTroChuyen.khong
        ? _dinhKemHienTai
        : (laLuotDau ? LoaiDinhKemTroChuyen.toanVan : LoaiDinhKemTroChuyen.khong);

    String? noiDungDinhKem;
    String choAi;
    switch (dinhKem) {
      case LoaiDinhKemTroChuyen.toanVan:
        choAi = 'Đây là toàn văn bản đang soạn (mới nhất):\n"""\n'
            '${widget.layVanBanHienTai()}\n"""\n\n'
            'Câu hỏi của tôi: $cauHoi';
      case LoaiDinhKemTroChuyen.doanChon:
        noiDungDinhKem = _noiDungDoanChonDinhKem ?? '';
        choAi = 'Đây là một đoạn trong văn bản đang soạn (đoạn đã chọn):\n"""\n'
            '$noiDungDinhKem\n"""\n\n'
            'Câu hỏi của tôi: $cauHoi';
      case LoaiDinhKemTroChuyen.khong:
        choAi = cauHoi;
    }

    late final int chiSoAi;
    setState(() {
      widget.lichSu.add(TinNhanTroChuyen(
        laNguoiDung: true,
        choHienThi: cauHoi,
        choAi: choAi,
        dinhKem: dinhKem,
        noiDungDinhKem: noiDungDinhKem,
      ));
      _dangGui = true;
      // Đính kèm là MỘT LẦN cho MỖI lượt gửi.
      _dinhKemHienTai = LoaiDinhKemTroChuyen.khong;
      _noiDungDoanChonDinhKem = null;
      // Thêm sẵn tin nhắn AI RỖNG ngay bây giờ — chữ sẽ chảy dần vào đây
      // (STREAMING) thay vì đợi AI trả lời xong hết mới hiện một lần.
      widget.lichSu.add(TinNhanTroChuyen(laNguoiDung: false, choHienThi: ''));
      chiSoAi = widget.lichSu.length - 1;
    });
    _cuonXuongDuoi();

    String? loi;
    var coChu = false;
    try {
      final luong = guiTroChuyenChoGeminiStream([
        // KHÔNG gửi tin nhắn AI rỗng vừa thêm ở trên (sublist bỏ phần tử
        // cuối) — nó chưa có nội dung gì để làm "lịch sử" cả.
        for (final t in widget.lichSu.sublist(0, chiSoAi))
          LuotTroChuyen(
            vaiTro: t.laNguoiDung ? 'nguoiDung' : 'ai',
            // Tin nhắn AI luôn lấy chữ ĐANG HIỂN THỊ (đã chảy xong hoàn
            // chỉnh từ lượt trước) — không dùng choAi (chỉ có ý nghĩa cho
            // tin nhắn NGƯỜI DÙNG, mang theo văn bản đính kèm).
            noiDung: t.laNguoiDung ? t.choAi : t.choHienThi,
          ),
      ]);
      await for (final doan in luong) {
        coChu = true;
        if (!mounted) return;
        setState(() => widget.lichSu[chiSoAi].choHienThi += doan);
        _cuonXuongDuoi();
      }
    } catch (e) {
      loi = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _dangGui = false;
      if (loi != null && !coChu) {
        // Lỗi ngay từ đầu, chưa nhận được chữ nào — thay hẳn bằng thông
        // báo lỗi (tin nhắn rỗng để nguyên nhìn rất kỳ).
        widget.lichSu[chiSoAi].choHienThi = 'AI trả lời thất bại: $loi';
      } else if (loi != null) {
        // Đã nhận được một phần rồi mới đứt giữa chừng (mất mạng...) — giữ
        // lại phần đã có, chỉ báo thêm là bị ngắt ngang.
        widget.lichSu[chiSoAi].choHienThi += '\n\n[Bị ngắt giữa chừng: $loi]';
      } else if (widget.lichSu[chiSoAi].choHienThi.trim().isEmpty) {
        widget.lichSu[chiSoAi].choHienThi =
            'AI trả lời thất bại: không có nội dung trả về.';
      }
    });
    _cuonXuongDuoi();
  }

  void _chonDinhKemToanVan() {
    setState(() {
      _dinhKemHienTai = LoaiDinhKemTroChuyen.toanVan;
      _noiDungDoanChonDinhKem = null;
    });
  }

  void _chonDinhKemDoanChon() {
    final doan = widget.layDoanVanDangChon();
    if (doan == null) return; // Menu đã tự vô hiệu mục này khi không có gì chọn.
    setState(() {
      _dinhKemHienTai = LoaiDinhKemTroChuyen.doanChon;
      _noiDungDoanChonDinhKem = doan;
    });
  }

  void _boDinhKem() {
    setState(() {
      _dinhKemHienTai = LoaiDinhKemTroChuyen.khong;
      _noiDungDoanChonDinhKem = null;
    });
  }

  void _hienNoiDungDinhKem(String tieuDe, String noiDung) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tieuDe),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(child: SelectableText(noiDung)),
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

  /// Nút bút chì trên một tin nhắn người dùng — nạp sẵn nội dung cũ vào ô
  /// nhập để sửa, KHÔNG xoá gì cho tới khi thật sự bấm gửi lại (xem
  /// `_guiHoacXacNhanSua`) — bấm bút chì rồi đổi ý (bấm chip "Huỷ sửa")
  /// thì mọi thứ nguyên vẹn.
  void _batDauSua(int chiSo) {
    setState(() {
      _dangSuaChiSo = chiSo;
      _oNhap.text = widget.lichSu[chiSo].choHienThi;
      _oNhap.selection = TextSelection.collapsed(offset: _oNhap.text.length);
    });
  }

  void _huySua() {
    setState(() {
      _dangSuaChiSo = null;
      _oNhap.clear();
    });
  }

  /// Nút Gửi khi đang ở chế độ sửa: xoá tin nhắn cũ CÙNG mọi tin nhắn sau
  /// nó (kể cả câu trả lời của AI đứng ngay sau), rồi để `_gui()` xử lý
  /// tiếp y hệt một câu hỏi mới bình thường — nếu tin nhắn bị sửa vốn là
  /// tin nhắn ĐẦU TIÊN, danh sách rỗng lại nên `_gui()` tự nhận ra đây lại
  /// là "lượt đầu" và tự đính kèm toàn văn lại như cũ, không cần xử lý gì
  /// thêm.
  Future<void> _guiHoacXacNhanSua() async {
    final chiSo = _dangSuaChiSo;
    if (chiSo != null) {
      setState(() {
        widget.lichSu.removeRange(chiSo, widget.lichSu.length);
        _dangSuaChiSo = null;
      });
    }
    await _gui();
  }

  Future<void> _xacNhanXoaTroChuyen() async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá cuộc trò chuyện?'),
        content: const Text(
          'Toàn bộ tin nhắn trong cuộc trò chuyện này (về tệp ghi chú đang '
          'mở) sẽ mất hẳn, không thể lấy lại. Bạn có chắc chắn muốn xoá '
          'không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không, giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Xoá', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (dongY == true && mounted) {
      setState(() {
        widget.lichSu.clear();
        _dinhKemHienTai = LoaiDinhKemTroChuyen.khong;
        _noiDungDoanChonDinhKem = null;
        _dangSuaChiSo = null;
        _oNhap.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _mauChinh,
        foregroundColor: Colors.white,
        title: const Text('Trò chuyện về văn bản này'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xoá trò chuyện',
            onPressed: widget.lichSu.isEmpty ? null : _xacNhanXoaTroChuyen,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: widget.lichSu.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bạn có thể hỏi tuỳ ý về văn bản này.',
                          style: TextStyle(color: Color(0xFF5F6368), fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Builder(builder: (context) {
                      // CHỈ 2 tin nhắn NGƯỜI DÙNG gần nhất được phép sửa —
                      // tính sẵn tập chỉ số một lần mỗi lần build, tra cứu
                      // nhanh trong itemBuilder bên dưới.
                      final chiSoNguoiDung = [
                        for (var i = 0; i < widget.lichSu.length; i++)
                          if (widget.lichSu[i].laNguoiDung) i,
                      ];
                      final chiSoChoPhepSua = chiSoNguoiDung.length <= 2
                          ? chiSoNguoiDung.toSet()
                          : chiSoNguoiDung.sublist(chiSoNguoiDung.length - 2).toSet();

                      return ListView.builder(
                        controller: _cuon,
                        padding: const EdgeInsets.all(12),
                        itemCount: widget.lichSu.length,
                        itemBuilder: (context, i) {
                          final t = widget.lichSu[i];
                          // Tin nhắn AI cuối cùng, trong lúc còn đang chảy
                          // chữ dần (STREAMING) — chưa cho sao chép (chữ
                          // chưa xong), hiện gợi ý "đang trả lời" nếu vẫn
                          // còn rỗng (chưa nhận được mẩu chữ đầu tiên).
                          final dangStream =
                              _dangGui && !t.laNguoiDung && i == widget.lichSu.length - 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: t.laNguoiDung
                                ? _BongBongNguoiDung(
                                    tin: t,
                                    onSua: (!_dangGui && chiSoChoPhepSua.contains(i))
                                        ? () => _batDauSua(i)
                                        : null,
                                    onXemDinhKem: () => _hienNoiDungDinhKem(
                                      'Đoạn văn đang chọn',
                                      t.noiDungDinhKem ?? '',
                                    ),
                                  )
                                : _TinNhanAi(chu: t.choHienThi, dangStream: dangStream),
                          );
                        },
                      );
                    }),
            ),
            if (_dangSuaChiSo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Đang sửa tin nhắn — gửi lại sẽ xoá các tin nhắn sau đó'),
                    onDeleted: _huySua,
                  ),
                ),
              ),
            if (_dinhKemHienTai != LoaiDinhKemTroChuyen.khong)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TheDinhKem(
                    nhan: _dinhKemHienTai == LoaiDinhKemTroChuyen.toanVan
                        ? 'Toàn bộ văn bản mới nhất'
                        : 'Đoạn văn đang chọn',
                    onXoa: _boDinhKem,
                    onBam: _dinhKemHienTai == LoaiDinhKemTroChuyen.doanChon
                        ? () => _hienNoiDungDinhKem(
                            'Đoạn văn đang chọn', _noiDungDoanChonDinhKem ?? '')
                        : null,
                  ),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<int>(
                    tooltip: 'Thêm',
                    icon: const Icon(Icons.add_circle_outline, color: _mauChinh),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 1,
                        child: Text('Toàn bộ văn bản mới nhất'),
                      ),
                      PopupMenuItem(
                        value: 2,
                        enabled: widget.layDoanVanDangChon() != null,
                        child: const Text('Đoạn văn đang chọn'),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 3,
                        enabled: !_micDangNghe && !_ghiDangMo,
                        child: const Text('Ghi âm (nói xong mới ra chữ)'),
                      ),
                      PopupMenuItem(
                        value: 4,
                        enabled: !_micDangNghe && !_ghiDangMo,
                        child: const Text('Micro (vừa nói vừa ra chữ)'),
                      ),
                    ],
                    onSelected: (v) {
                      switch (v) {
                        case 1:
                          _chonDinhKemToanVan();
                        case 2:
                          _chonDinhKemDoanChon();
                        case 3:
                          _moGhiAmChat();
                        case 4:
                          _batMicChat();
                      }
                    },
                  ),
                  Expanded(
                    // Enter = xuống dòng (hành vi mặc định của ô nhiều dòng,
                    // không còn `onSubmitted`/`TextInputAction.send` — hai
                    // thứ đó từng khiến Enter gửi luôn). CHỈ Ctrl+Enter mới
                    // gửi — bắt riêng tổ hợp này bằng `Focus.onKeyEvent`,
                    // Enter một mình luôn rơi qua cho `TextField` tự xuống
                    // dòng như bình thường.
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            HardwareKeyboard.instance.isControlPressed) {
                          _guiHoacXacNhanSua();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: ConstrainedBox(
                        // Co giãn thoải mái theo nội dung gõ, cao tối đa
                        // khoảng 40% chiều cao màn hình (giống độ cao rộng
                        // rãi của khung chat) — vượt quá thì tự cuộn bên
                        // trong ô nhập, không đẩy tràn màn hình.
                        constraints: BoxConstraints(
                          maxHeight: (MediaQuery.sizeOf(context).height * 0.4)
                              .clamp(120.0, 420.0),
                        ),
                        child: TextField(
                          controller: _oNhap,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Ctrl + Enter để gửi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mic đang nghe thì nút Gửi đổi hẳn thành ô vuông đỏ
                  // (biểu thị "dừng micro") — bấm vào là đóng mic lại, KHÔNG
                  // gửi tin nhắn; gửi thật vẫn luôn cần Ctrl+Enter/nút Gửi
                  // bình thường sau khi đã tắt mic.
                  _micDangNghe
                      ? _NutDungMic(khiBam: _tatMicChat)
                      : _NutGui(dangGui: _dangGui, khiBam: _guiHoacXacNhanSua),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút gửi hình tròn — Material + InkWell thủ công (KHÔNG dùng
/// `IconButton.filled`, từng bị lỗi hiển thị chỉ ra hình tròn trống,
/// không thấy icon bên trong).
class _NutGui extends StatelessWidget {
  const _NutGui({required this.dangGui, required this.khiBam});
  final bool dangGui;
  final VoidCallback khiBam;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dangGui ? Colors.grey.shade400 : _mauChinh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: dangGui ? null : khiBam,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.send, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Nút ô vuông đỏ thay chỗ nút Gửi khi Micro đang nghe — bấm để đóng mic.
class _NutDungMic extends StatelessWidget {
  const _NutDungMic({required this.khiBam});
  final VoidCallback khiBam;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade600,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: khiBam,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.stop, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Thẻ đính kèm — dùng chung cho thẻ CHỜ GỬI (trên khung nhập, có nút X để
/// bỏ) và thẻ LỊCH SỬ (trên một tin nhắn đã gửi, không có nút X, chỉ có thể
/// bấm xem lại nội dung nếu [onBam] khác `null`).
class _TheDinhKem extends StatelessWidget {
  const _TheDinhKem({required this.nhan, this.onXoa, this.onBam});
  final String nhan;
  final VoidCallback? onXoa;
  final VoidCallback? onBam;

  @override
  Widget build(BuildContext context) {
    final the = Chip(
      avatar: const Icon(Icons.description_outlined, size: 18),
      label: Text(nhan),
      onDeleted: onXoa,
      visualDensity: VisualDensity.compact,
    );
    if (onBam == null) return the;
    return InkWell(borderRadius: BorderRadius.circular(20), onTap: onBam, child: the);
  }
}

/// Sao chép [chu] vào bộ nhớ đệm của thiết bị, kèm thông báo ngắn — dùng
/// CHUNG cho mọi nút "Sao chép" trong màn hình này (bong bóng người dùng,
/// tin nhắn AI, khung kết quả riêng từng khối ```...```).
void _saoChep(BuildContext context, String chu) {
  Clipboard.setData(ClipboardData(text: chu));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đã sao chép'), duration: Duration(seconds: 1)),
  );
}

/// Nút hành động nhỏ (sao chép/sửa) hiện dưới mỗi tin nhắn — icon nhỏ, màu
/// xám nhạt, không lấn át nội dung chính.
class _NutHanhDongNho extends StatelessWidget {
  const _NutHanhDongNho({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: const Color(0xFF5F6368)),
        ),
      ),
    );
  }
}

/// Bong bóng tin nhắn của người dùng — bọc khung, sát mép phải. Cho chọn
/// văn bản để sao chép (`SelectableText`), kèm nút Sao chép + nút Sửa (bút
/// chì, chỉ hiện khi [onSua] khác `null` — xem giới hạn "2 tin nhắn gần
/// nhất" ở nơi gọi). Có thẻ đính kèm (nếu có) hiện ngay phía trên.
class _BongBongNguoiDung extends StatelessWidget {
  const _BongBongNguoiDung({
    required this.tin,
    required this.onSua,
    required this.onXemDinhKem,
  });
  final TinNhanTroChuyen tin;
  final VoidCallback? onSua;
  final VoidCallback onXemDinhKem;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (tin.dinhKem != LoaiDinhKemTroChuyen.khong)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _TheDinhKem(
                nhan: tin.dinhKem == LoaiDinhKemTroChuyen.toanVan
                    ? 'Toàn bộ văn bản mới nhất'
                    : 'Đoạn văn đang chọn',
                onBam: tin.dinhKem == LoaiDinhKemTroChuyen.doanChon ? onXemDinhKem : null,
              ),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _mauChinh.withValues(alpha: 0.1),
              border: Border.all(color: _mauChinh.withValues(alpha: 0.4)),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: SelectableText(tin.choHienThi),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onSua != null)
                _NutHanhDongNho(icon: Icons.edit_outlined, tooltip: 'Sửa', onTap: onSua!),
              _NutHanhDongNho(
                icon: Icons.copy,
                tooltip: 'Sao chép',
                onTap: () => _saoChep(context, tin.choHienThi),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tin nhắn của AI — KHÔNG bọc khung, rộng cả hai bên màn hình. Tách những
/// khối ```...``` (nếu có) ra khỏi văn xuôi thường, hiện trong khung riêng
/// kèm nút sao chép (`_tachKhoiMa`); phần văn xuôi còn lại render markdown-
/// lite nhẹ (`#`/`##`/`###`, `**đậm**`, `*nghiêng*`/`_nghiêng_`, `` `mã` ``,
/// gạch đầu dòng `- `/`* `) thay vì hiện nguyên các ký tự đánh dấu — xem
/// `_spanDoanVanBan`. Toàn bộ đều cho chọn để sao chép.
///
/// [dangStream] true khi đây là câu trả lời ĐANG CHẢY CHỮ DẦN (streaming,
/// chưa xong hẳn): rỗng thì hiện gợi ý "đang trả lời", có chữ rồi thì cứ
/// hiện y hệt bình thường (chữ tự dài ra theo từng lần build lại) nhưng ẨN
/// nút Sao chép — nội dung chưa trọn vẹn, sao chép lúc này dễ chép thiếu.
class _TinNhanAi extends StatelessWidget {
  const _TinNhanAi({required this.chu, this.dangStream = false});
  final String chu;
  final bool dangStream;

  @override
  Widget build(BuildContext context) {
    if (dangStream && chu.isEmpty) {
      return const Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('AI đang trả lời...', style: TextStyle(color: Color(0xFF5F6368))),
        ],
      );
    }
    final doan = _tachKhoiMa(chu);
    final kieuGoc = DefaultTextStyle.of(context).style;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in doan)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: d.laKhoiMa
                ? _KhungKetQua(chu: d.chu)
                : SelectableText.rich(
                    TextSpan(children: _spanDoanVanBan(d.chu, kieuGoc)),
                  ),
          ),
        // Sao chép NGUYÊN VĂN cả tin nhắn (gồm cả dấu ```...``` nếu có) —
        // khác với nút "Sao chép" riêng trong từng khung kết quả (chỉ sao
        // chép đúng khối đó). Ẩn trong lúc còn đang chảy chữ dở.
        if (!dangStream)
          _NutHanhDongNho(
            icon: Icons.copy,
            tooltip: 'Sao chép',
            onTap: () => _saoChep(context, chu),
          ),
      ],
    );
  }
}

class _DoanChat {
  const _DoanChat({required this.chu, required this.laKhoiMa});
  final String chu;
  final bool laKhoiMa;
}

/// Tách các khối ```...``` (quy ước phổ biến các mô hình AI dùng để đánh
/// dấu "đây là một khối kết quả/đoạn văn/tệp riêng", khác văn xuôi thường)
/// ra khỏi phần còn lại. Không có khối nào thì trả về nguyên văn bản như
/// MỘT đoạn văn xuôi duy nhất.
List<_DoanChat> _tachKhoiMa(String vanBan) {
  final ketQua = <_DoanChat>[];
  final re = RegExp(r'```[a-zA-Z0-9_-]*\n?([\s\S]*?)```');
  var viTri = 0;
  for (final m in re.allMatches(vanBan)) {
    if (m.start > viTri) {
      final truoc = vanBan.substring(viTri, m.start).trim();
      if (truoc.isNotEmpty) ketQua.add(_DoanChat(chu: truoc, laKhoiMa: false));
    }
    final noiDung = (m.group(1) ?? '').trimRight();
    if (noiDung.trim().isNotEmpty) ketQua.add(_DoanChat(chu: noiDung, laKhoiMa: true));
    viTri = m.end;
  }
  if (viTri < vanBan.length) {
    final sau = vanBan.substring(viTri).trim();
    if (sau.isNotEmpty) ketQua.add(_DoanChat(chu: sau, laKhoiMa: false));
  }
  if (ketQua.isEmpty && vanBan.trim().isNotEmpty) {
    ketQua.add(_DoanChat(chu: vanBan.trim(), laKhoiMa: false));
  }
  return ketQua;
}

/// Nhận diện `**đậm**`, `*nghiêng*`/`_nghiêng_`, `` `mã` `` NGAY TRONG một
/// dòng, trả về danh sách span để ghép vào `TextSpan` cha — không đụng tới
/// dấu xuống dòng (xử lý ở `_spanDoanVanBan`, cấp cao hơn).
List<InlineSpan> _spanDongMarkdown(String dong, TextStyle kieuGoc) {
  final ket = <InlineSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|_(.+?)_|`(.+?)`');
  var vi = 0;
  for (final m in re.allMatches(dong)) {
    if (m.start > vi) ket.add(TextSpan(text: dong.substring(vi, m.start), style: kieuGoc));
    if (m.group(1) != null) {
      ket.add(TextSpan(text: m.group(1), style: kieuGoc.copyWith(fontWeight: FontWeight.bold)));
    } else if (m.group(2) != null) {
      ket.add(TextSpan(text: m.group(2), style: kieuGoc.copyWith(fontStyle: FontStyle.italic)));
    } else if (m.group(3) != null) {
      ket.add(TextSpan(text: m.group(3), style: kieuGoc.copyWith(fontStyle: FontStyle.italic)));
    } else if (m.group(4) != null) {
      ket.add(TextSpan(
        text: m.group(4),
        style: kieuGoc.copyWith(
          fontFamily: 'monospace',
          backgroundColor: const Color(0xFFF1F3F4),
        ),
      ));
    }
    vi = m.end;
  }
  if (vi < dong.length) ket.add(TextSpan(text: dong.substring(vi), style: kieuGoc));
  return ket;
}

/// Dựng span cho CẢ MỘT đoạn văn xuôi (nhiều dòng) — mỗi dòng tự nhận diện
/// tiêu đề (`#`/`##`/`###`) hoặc gạch đầu dòng (`- `/`* `) trước khi áp
/// markdown-lite trong dòng (`_spanDongMarkdown`), rồi nối lại bằng
/// `TextSpan('\n')` — dùng chung MỘT `SelectableText.rich` cho cả đoạn để
/// chọn được liền mạch qua nhiều dòng.
List<InlineSpan> _spanDoanVanBan(String doan, TextStyle kieuGoc) {
  final dong = doan.split('\n');
  final ket = <InlineSpan>[];
  for (var i = 0; i < dong.length; i++) {
    if (i > 0) ket.add(const TextSpan(text: '\n'));
    final d = dong[i];
    final trim = d.trimLeft();
    if (trim.startsWith('### ')) {
      ket.addAll(_spanDongMarkdown(
        trim.substring(4),
        kieuGoc.copyWith(fontWeight: FontWeight.bold, fontSize: (kieuGoc.fontSize ?? 14) + 1),
      ));
    } else if (trim.startsWith('## ')) {
      ket.addAll(_spanDongMarkdown(
        trim.substring(3),
        kieuGoc.copyWith(fontWeight: FontWeight.bold, fontSize: (kieuGoc.fontSize ?? 14) + 2),
      ));
    } else if (trim.startsWith('# ')) {
      ket.addAll(_spanDongMarkdown(
        trim.substring(2),
        kieuGoc.copyWith(fontWeight: FontWeight.bold, fontSize: (kieuGoc.fontSize ?? 14) + 4),
      ));
    } else if (trim.startsWith('- ') || trim.startsWith('* ')) {
      ket.add(TextSpan(text: '•  ', style: kieuGoc));
      ket.addAll(_spanDongMarkdown(trim.substring(2), kieuGoc));
    } else {
      ket.addAll(_spanDongMarkdown(d, kieuGoc));
    }
  }
  return ket;
}

/// Khung riêng cho một đoạn AI trả về dạng "kết quả" (khối ```...```) — nền
/// xám nhạt, chữ đơn cách (monospace), có nút "Sao chép" ở góc trên bên
/// phải, cho chọn văn bản để sao chép tuỳ ý ngoài nút bấm.
class _KhungKetQua extends StatelessWidget {
  const _KhungKetQua({required this.chu});
  final String chu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _saoChep(context, chu),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Sao chép'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          SelectableText(
            chu,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ============================================================ Ghi âm (chat)

/// Số "phút:giây" của một thẻ đang ghi trong kênh chat — đổi màu TÍM từ
/// giây 45 (việc NHẤP NHÁY của cả dòng do `_NhapNhayGhiAmChat` bên ngoài lo)
/// — ĐÚNG khuôn `_SoPhutGiayGhiAm` của trang soạn thảo chính.
class _SoPhutGiayChat extends StatelessWidget {
  const _SoPhutGiayChat({required this.thoiLuong, required this.style});
  final Duration thoiLuong;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final giay = thoiLuong.inSeconds;
    final chu = dinhDangMmSs(thoiLuong);
    if (giay < 45) return Text(chu, style: style);
    return Text(chu, style: style.copyWith(color: Colors.purple.shade700));
  }
}

/// Bọc cả dòng trạng thái ghi âm để nhấp nháy khi sắp chạm hạn 60 giây —
/// ĐÚNG khuôn `_NhapNhayGioiHanGhiAm` của trang soạn thảo chính (từ giây 45
/// nhấp nháy chu kỳ 500ms, từ giây 55 tăng gấp đôi còn 250ms).
class _NhapNhayGhiAmChat extends StatefulWidget {
  const _NhapNhayGhiAmChat({required this.giay, required this.child});
  final int giay;
  final Widget child;

  @override
  State<_NhapNhayGhiAmChat> createState() => _NhapNhayGhiAmChatState();
}

class _NhapNhayGhiAmChatState extends State<_NhapNhayGhiAmChat> {
  Timer? _hen;
  bool _an = false;

  int _vung(int g) => g < 45 ? 0 : (g < 55 ? 1 : 2);

  void _datHen() {
    _hen?.cancel();
    if (widget.giay < 45) {
      _an = false;
      return;
    }
    final chuKy = widget.giay >= 55
        ? const Duration(milliseconds: 250)
        : const Duration(milliseconds: 500);
    _hen = Timer.periodic(chuKy, (_) {
      if (!mounted) return;
      setState(() => _an = !_an);
    });
  }

  @override
  void initState() {
    super.initState();
    _datHen();
  }

  @override
  void didUpdateWidget(covariant _NhapNhayGhiAmChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_vung(oldWidget.giay) != _vung(widget.giay)) _datHen();
  }

  @override
  void dispose() {
    _hen?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.giay < 45) return widget.child;
    return Opacity(opacity: _an ? 0.2 : 1.0, child: widget.child);
  }
}

/// Hộp thoại "Ghi âm (nói xong mới ra chữ)" dành RIÊNG cho kênh chat — Ở
/// GIỮA MÀN HÌNH (khác AppBar trên đầu của trang soạn thảo chính). Chỉ còn
/// 3 hành động: phím 1 "Hoàn thành và Chuyển hoá thành văn bản", phím 2
/// "Hoàn thành và Tạo bản ghi âm mới", phím 5 "Xoá bản này và Đóng" — không
/// có các phím 3/4/6/7/8/9 của bảng điều khiển trang chính (không có ý
/// nghĩa gì ở đây: không "phát để nghe lại", không cài đặt tự động/bảng
/// riêng, không "chọn vị trí chèn vào văn bản"). Thẻ ở đây LUÔN tự động
/// chuyển hoá thành văn bản khi hoàn thành (nối thẳng vào ô nhập chat qua
/// `khiCoVanBan`) — không có lựa chọn "chỉ ghi, chưa chuyển" như trang
/// chính.
///
/// Cùng hạn 60 giây/thẻ (tự động chốt + ghi tiếp bằng thẻ mới, tối đa 5 thẻ
/// liên tiếp không ai bấm gì = 5 phút tổng), cùng hiệu ứng nhấp nháy 45/55
/// giây, và cùng hộp thoại cảnh báo sắp chạm 5 phút — PORT nguyên luật từ
/// bảng điều khiển của trang soạn thảo chính (`_BangDieuKhienGhiAm`,
/// `trang_soan_thao.dart`), không đổi ý nghĩa, chỉ đơn giản hoá phần giao
/// diện cho vừa một hộp thoại nhỏ.
class _KhungGhiAmChat extends StatefulWidget {
  const _KhungGhiAmChat({required this.phimTatGhiAm, required this.khiCoVanBan});
  final LuaChonPhimTat phimTatGhiAm;

  /// Gọi lại MỖI LẦN một thẻ vừa chuyển hoá xong — nơi gọi (`_moGhiAmChat`)
  /// tự nối thẳng vào ô nhập chat.
  final void Function(String chu) khiCoVanBan;

  @override
  State<_KhungGhiAmChat> createState() => _KhungGhiAmChatState();
}

class _KhungGhiAmChatState extends State<_KhungGhiAmChat> {
  static const _gioiHanMoiThe = Duration(seconds: 60);
  static const _canhBaoGiayCuoiCung = Duration(seconds: 30);
  static const _soLanToiDaTuDongTaoTheLienTiep = 5;

  int _soThe = 1;
  Duration _thoiLuong = Duration.zero;
  bool _dangTamDung = false;
  bool _dangXuLy = false;
  bool _daSanSang = false;
  bool _daHienCanhBao5Phut = false;
  Timer? _dongHo;
  int _soLanTuDongTaoTheLienTiep = 0;

  late final _theoDoiTapDoi = TheoDoiTapDoiPhim(khiTapDoi: _khiTapDoiCucBo);

  bool get _laTheCuoiCung =>
      _soLanTuDongTaoTheLienTiep >= _soLanToiDaTuDongTaoTheLienTiep - 1;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_khiPhimCucBo);
    _batDau();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_khiPhimCucBo);
    _theoDoiTapDoi.dispose();
    _dongHo?.cancel();
    super.dispose();
  }

  Future<void> _batDau() async {
    final ok = await ghiAmTheKhoiTao();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không dùng được micro để ghi âm. Hãy kiểm tra quyền.'),
      ));
      Navigator.of(context).pop();
      return;
    }
    await ghiAmTheBatDauThe();
    if (!mounted) return;
    setState(() => _daSanSang = true);
    _chayDongHo();
  }

  void _chayDongHo() {
    _dongHo?.cancel();
    _dongHo = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_dangTamDung || _dangXuLy) return;
      setState(() => _thoiLuong += const Duration(seconds: 1));
      if (_thoiLuong >= _gioiHanMoiThe) {
        _hoanThanh(taoTheMoi: !_laTheCuoiCung, auto: true);
      } else if (_laTheCuoiCung &&
          !_daHienCanhBao5Phut &&
          _thoiLuong >= _canhBaoGiayCuoiCung) {
        _daHienCanhBao5Phut = true;
        _hienCanhBao5Phut();
      }
    });
  }

  Future<void> _tamDungTiepTuc() async {
    if (_dangTamDung) {
      await ghiAmTheTiepTuc();
    } else {
      await ghiAmTheTamDung();
    }
    if (mounted) setState(() => _dangTamDung = !_dangTamDung);
  }

  Future<void> _chuyenHoa(KetQuaGhiAmThe kq, int soThe) async {
    try {
      final chu = await guiGhiAmChoGemini(kq.bytes, kq.mime, locHallucination: true);
      if (chu.trim().isNotEmpty) widget.khiCoVanBan(chu.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Thẻ ghi âm #$soThe chuyển hoá thất bại: $e'),
        ));
      }
    }
  }

  /// Phím 1 (taoTheMoi: false) hoặc phím 2 (taoTheMoi: true) — [auto] đúng
  /// khi do CHÍNH đồng hồ tự gọi (hết hạn 60 giây, không ai bấm gì): chỉ
  /// trường hợp đó mới TĂNG bộ đếm "tự động liên tiếp"; bấm tay luôn RESET
  /// bộ đếm về 0 (đúng luật của trang soạn thảo chính).
  Future<void> _hoanThanh({required bool taoTheMoi, bool auto = false}) async {
    if (_dangXuLy) return;
    setState(() => _dangXuLy = true);
    _dongHo?.cancel();
    final soTheVuaXong = _soThe;
    final kq = await ghiAmTheKetThucThe();
    if (kq != null) unawaited(_chuyenHoa(kq, soTheVuaXong));

    if (!taoTheMoi) {
      // ĐÃ SỬA (chấm đỏ "đang dùng micro" ở tab trình duyệt kẹt lại mãi dù
      // đã xong ghi âm) — `ghiAmTheKetThucThe()` chỉ dừng `MediaRecorder`,
      // KHÔNG nhả `MediaStream` (cố ý dùng lại cho thẻ kế tiếp nếu còn ghi
      // tiếp — xem `ghi_am_the_web.dart`). Nhánh này đóng hẳn hộp thoại,
      // không còn thẻ nào sắp ghi tiếp nữa, nên phải tự nhả luôn, y hệt
      // `_xoaVaDong()` đã làm — thiếu bước này là nguyên nhân thật của lỗi.
      await ghiAmTheDongHan();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _soLanTuDongTaoTheLienTiep = auto ? _soLanTuDongTaoTheLienTiep + 1 : 0;
    await ghiAmTheBatDauThe();
    if (!mounted) return;
    setState(() {
      _soThe++;
      _thoiLuong = Duration.zero;
      _dangTamDung = false;
      _dangXuLy = false;
      _daHienCanhBao5Phut = false;
    });
    _chayDongHo();
  }

  Future<void> _xoaVaDong() async {
    if (_dangXuLy) return;
    setState(() => _dangXuLy = true);
    _dongHo?.cancel();
    await ghiAmTheDongHan();
    if (mounted) Navigator.of(context).pop();
  }

  void _hienCanhBao5Phut() {
    final tongPhut =
        (_gioiHanMoiThe.inSeconds * _soLanToiDaTuDongTaoTheLienTiep) ~/ 60;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhat) => AlertDialog(
          title: Text('Sắp chạm giới hạn $tongPhut phút'),
          content: Text(
            'Thẻ ghi âm #$_soThe (thẻ tự động thứ $_soLanToiDaTuDongTaoTheLienTiep '
            'liên tiếp) sắp ghi đủ 60 giây. Nếu không chọn, tới đúng giây thứ 60 '
            'hệ thống sẽ TỰ HOÀN THÀNH và đóng trình ghi âm luôn.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _tamDungTiepTuc();
                capNhat(() {});
              },
              child: Text(_dangTamDung ? 'Tiếp tục' : 'Tạm dừng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _hoanThanh(taoTheMoi: false);
              },
              child: const Text('Hoàn thành và Đóng ngay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      ),
    );
  }

  bool _khopPhimTat(LuaChonPhimTat lc, KeyEvent event) {
    switch (lc.loai) {
      case 'tab':
        return event.logicalKey == LogicalKeyboardKey.tab &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            !HardwareKeyboard.instance.isShiftPressed &&
            !HardwareKeyboard.instance.isMetaPressed;
      case 'ctrl':
        return HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            event.logicalKey.keyLabel.toUpperCase() == (lc.phim ?? '').toUpperCase();
      default:
        return false;
    }
  }

  void _khiTapDoiCucBo(String loai) {
    if (!mounted) return;
    if (widget.phimTatGhiAm.loai == loai) _tamDungTiepTuc();
  }

  bool _khiPhimCucBo(KeyEvent event) {
    if (!mounted) return false;
    _theoDoiTapDoi.xuLy(event);
    if (event is! KeyDownEvent) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    if (_khopPhimTat(widget.phimTatGhiAm, event)) {
      _tamDungTiepTuc();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.digit1) {
      _hoanThanh(taoTheMoi: false);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.digit2) {
      _hoanThanh(taoTheMoi: true);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.digit5) {
      _xoaVaDong();
      return true;
    }
    return false;
  }

  Widget _hang(String nhanPhim, IconData icon, Color mau, String nhan, VoidCallback? onBam) {
    final khaDung = onBam != null;
    return InkWell(
      onTap: onBam,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDADCE0))),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                nhanPhim,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: khaDung ? mau : Colors.grey.shade400, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(nhan,
                  style: TextStyle(color: khaDung ? null : Colors.grey.shade400)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const kieuTrangThai =
        TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text('Bản Ghi âm số $_soThe'),
        content: Focus(
          autofocus: true,
          // Chặn hẳn phím Tab khỏi cơ chế di chuyển tiêu điểm (focus
          // traversal) mặc định của Flutter — ở đây Tab (khi được cài làm
          // phím tắt Ghi âm) CHỈ có một tác dụng duy nhất là Tạm
          // dừng/Tiếp tục (xem `_khiPhimCucBo`), không được phép nhảy
          // giữa các nút trong hộp thoại này.
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.tab) {
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_daSanSang)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Đang chuẩn bị…'),
                )
              else
                _NhapNhayGhiAmChat(
                  giay: _thoiLuong.inSeconds,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_dangTamDung ? 'Tạm dừng ' : 'Đang Ghi âm ',
                          style: kieuTrangThai),
                      _SoPhutGiayChat(thoiLuong: _thoiLuong, style: kieuTrangThai),
                    ],
                  ),
                ),
              _hang(
                widget.phimTatGhiAm.nhan,
                _dangTamDung ? Icons.play_circle_outline : Icons.pause_circle_outline,
                _dangTamDung ? Colors.green.shade800 : Colors.red.shade800,
                _dangTamDung ? 'Tiếp tục' : 'Tạm dừng',
                _dangXuLy ? null : _tamDungTiepTuc,
              ),
              _hang(
                'phím 1',
                Icons.text_snippet_outlined,
                Colors.green.shade900,
                'Hoàn thành và Chuyển hoá thành văn bản',
                _dangXuLy ? null : () => _hoanThanh(taoTheMoi: false),
              ),
              _hang(
                'phím 2',
                Icons.add_circle_outline,
                Colors.cyan.shade900,
                'Hoàn thành và Tạo bản ghi âm mới',
                _dangXuLy ? null : () => _hoanThanh(taoTheMoi: true),
              ),
              _hang(
                'phím 5',
                Icons.delete_outline,
                Colors.red.shade900,
                'Xoá bản này và Đóng',
                _dangXuLy ? null : _xoaVaDong,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
