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
import 'thong_bao_giua.dart';
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
    this.ghiNhatKyMicro,
  });

  /// Đọc phím tắt Micro/Ghi âm đã cài (`caiDat.phimTatMicro`/`phimTatGhiAm`)
  /// — CÙNG phím tắt với trang soạn thảo chính, hoạt động y hệt trong kênh
  /// chat này (xem `_khiPhimCucBoTroChuyen`).
  final CaiDat caiDat;

  /// Ghi vào CHUNG một nhật ký với micro trang soạn thảo chính
  /// (`_ghiNhatKyMicro`, xem "Xem nhật ký micro" trong Cài đặt) — người
  /// dùng bấm xem/sao chép ngay trong app, không cần console trình duyệt.
  /// `null` thì coi như không ghi (phòng trường hợp màn hình này được mở
  /// từ chỗ khác không có sẵn nhật ký để nối vào).
  final void Function(String dong)? ghiNhatKyMicro;

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
  // (YÊU CẦU MỚI) Bản thường (`TextEditingController`) không tô được nền
  // riêng cho "thẻ ghi âm" — đổi qua `_BoDieuKhienChat` (cuối tệp), tự tô
  // nền token `〔🎙️ ...〕` và chặn con trỏ đứng/xoá lẻ bên trong token.
  final _oNhap = _BoDieuKhienChat();
  // (YÊU CẦU MỚI) Bật Micro bằng nút "+" → "Micro (vừa nói vừa ra chữ)" phải
  // ép được tiêu điểm/con trỏ nhấp nháy vào khung nhập (kéo theo bàn phím ảo
  // tự bật lên, giống cách bật "bàn phím" trong Bộ phím nhanh) — cần một
  // `FocusNode` RIÊNG do mình nắm để gọi `requestFocus()` được, `TextField`
  // không tự cấp một cái ra ngoài nếu không truyền `focusNode` vào.
  final _focusONhap = FocusNode();
  // (YÊU CẦU MỚI) Nút tròn nổi "bật Micro" cạnh nút Gửi — hiện ra NGAY khi
  // bật Micro qua nút "+" lần đầu trong phiên mở kênh chat này, rồi GIỮ
  // NGUYÊN hiện mãi (không tự ẩn khi mic tắt) cho tới khi thoát hẳn màn
  // hình chat — mở lại từ đầu thì phải bấm "+" → Micro lại mới hiện lại.
  bool _hienNutMicNoiChat = false;
  final _cuon = ScrollController();
  // (YÊU CẦU MỚI) Khung nhập đạt chiều cao tối đa phải tự cuộn bên trong để
  // luôn thấy chữ mới — gõ tay thì `TextField` tự làm điều này (đi qua
  // đường bàn phím ảo thật), nhưng mic tự gán `_oNhap.value` lại KHÔNG đi
  // qua đường đó nên không tự cuộn theo — phải tự cuộn tay bằng
  // `ScrollController` riêng này, xem chỗ gọi ở `onResult`.
  final _cuonONhap = ScrollController();
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

  /// Ý ĐỊNH của người dùng (muốn mic đang bật hay không) — BỀN qua khoảng
  /// hở hệ thống tự ngắt/tự bật lại, y hệt `_TrangSoanThaoState._muonNghe`.
  /// Không dùng cho UI (xem `_micDangNgheThat`), chỉ dùng để quyết định có
  /// tự bật lại hay không và để `_khiONhapDoi`/`_apDungTuDongDinhDangChat`
  /// biết có cần xử lý "gõ tay thắng mic" hay không.
  bool _micDangNghe = false;

  /// Trạng thái THẬT, đồng bộ thời gian thực với `onStatus` — ĐÚNG khuôn
  /// `_TrangSoanThaoState._dangNghe`: UI (nút vuông đỏ ⇄ nút Gửi) đọc ĐÚNG
  /// biến này, không đọc `_micDangNghe`, để nhấp nháy ẩn/hiện đúng lúc hệ
  /// thống tự ngắt rồi tự bật lại — khác hẳn `_micDangNghe` (ý định, không
  /// đổi suốt khoảng hở đó).
  bool _micDangNgheThat = false;

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

  /// Selection CUỐI CÙNG mà chính app (mic hoặc tự động định dạng) vừa tự
  /// đặt cho `_oNhap` — dùng ở `_khiONhapDoi` để phân biệt một thông báo
  /// "chữ không đổi, chỉ selection đổi" là PHANTOM (dội lại đúng selection
  /// mình vừa đặt, bỏ qua) hay THẬT (người dùng vừa chạm/dời con trỏ sang
  /// một vị trí khác hẳn, phải dời neo chèn chữ của mic theo).
  TextSelection? _micSelectionVuaGan;

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

  /// (SỬA LỖI "bão tự bật lại micro vô hạn") Đếm số lần LIÊN TIẾP
  /// `_lenLichBatLaiMicChat` phải lên lịch bật lại mà KHÔNG CÓ một `onResult`
  /// nào của phiên đó lọt qua được (kể cả kết quả rỗng) — nghĩa là phiên vừa
  /// mở đã chết ngay, trình nhận dạng của máy/trình duyệt đang kẹt hẳn, bật
  /// lại cũng vô ích. Không có giới hạn nào trước đây: mỗi phiên hỏng chỉ sau
  /// 200ms lại mở tiếp một phiên MỚI, cũng hỏng ngay, lặp lại VÔ HẠN — vừa
  /// ngốn máy vừa (đúng lỗi người dùng báo) giữ `_micDangNghe` mãi `true` nên
  /// mục "Micro (vừa nói vừa ra chữ)" trong nút "+" cứ mờ xám, không bấm lại
  /// được, CHỈ gõ tay (qua `_nguoiDungVuaGoChat`, tự đặt `_micDangNghe` về
  /// `false`) mới thoát ra được. Reset về 0 mỗi khi có MỘT `onResult` thật sự
  /// chạy tới cho phiên hiện tại (dấu hiệu chắc chắn: trình nhận dạng vẫn
  /// sống, không phải đang kẹt) — vượt quá [_soLanBatLaiLienTucToiDa] mà vẫn
  /// chưa thấy `onResult` nào thì coi như chịu, tắt hẳn mic, trả quyền tự
  /// bấm lại cho người dùng (xem `_lenLichBatLaiMicChat`).
  int _soLanBatLaiLienTucKhongKetQua = 0;
  static const _soLanBatLaiLienTucToiDa = 6;

  /// Đánh số PHIÊN nghe — y hệt `_phienNgheHienTai` ở trang soạn thảo
  /// chính. ĐÂY MỚI LÀ MẢNH GHÉP CÒN THIẾU thật sự (không phải việc trừ
  /// raw cộng dồn, cũng không chỉ là "phiên dài hay ngắn"): trên Android
  /// bản web, trạng thái "notListening" có thể bắn ra RẤT THƯỜNG XUYÊN —
  /// kể cả ngay GIỮA một câu đang nói (không phải lúc ngừng nói thật) —
  /// nên `_batPhienNgheMicChat` có thể bị gọi lại nhiều lần trong khi phiên
  /// `listen()` TRƯỚC đó trên thực tế vẫn còn đang bắn `onResult` dở (độ
  /// trễ của tầng JS/trình duyệt). Không có số phiên để phân biệt, CẢ HAI
  /// closure `onResult` (cũ lẫn mới) cùng đọc/ghi chung
  /// `_micDiemBatDau`/`_micChuGanNhat` — phiên mới vừa reset hai biến đó
  /// cho câu nói MỚI, thì kết quả TRỄ của phiên cũ lại ghi đè bằng toàn bộ
  /// câu CŨ, rồi phiên mới ghi tiếp đè lên theo kiểu khác — hai phiên giẫm
  /// chân nhau liên tục chính là thứ tạo ra kiểu lặp "phình dần từng chữ
  /// một" người dùng thấy ("alo Alo Alo Alo bạn Alo bạn có..."). Mỗi
  /// `onResult` giờ tự kiểm `idPhien` CHỤP SẴN lúc đăng ký — khác
  /// `_phienNgheMicChat` hiện tại (nghĩa là đã có phiên MỚI hơn bắt đầu từ
  /// lúc đó) thì vứt thẳng, không đụng gì tới biến chung nữa.
  int _phienNgheMicChat = 0;

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

  // --------------------- Tự động định dạng khi gõ tay (y hệt trang chính)

  /// Bản chữ GẦN NHẤT đã xử lý xong — dùng để so khác biệt (diff) với
  /// `_oNhap.text` hiện tại mỗi khi có thay đổi, y hệt `_chuGanNhat` ở
  /// `_TrangSoanThaoState`. Tự "lành" ngay ở lần gõ kế tiếp nếu có lệch (ví
  /// dụ ngay sau khi mic vừa chèn chữ, bỏ qua không xử lý ở đây) — không
  /// đụng gì tới `_micChuGanNhat` (chuyện riêng của mic).
  String _chuChatGanNhat = '';

  /// Y hệt `_viTriChoVietHoa` ở trang soạn thảo chính, riêng cho ô nhập chat.
  int? _viTriChoVietHoaChat;

  static final RegExp _laChuCaiChat = RegExp(r'[a-zA-ZÀ-ỹ]');
  static const Set<String> _kyTuKetCauChoVietHoaChat = {'.', ':', '!', '?'};

  /// Y hệt `_TrangSoanThaoState._kyTuDacBiet`.
  static const _kyTuDacBietChat = {'.', ',', ';', '?', '!', ':'};

  /// Y hệt `_TrangSoanThaoState._kyTuNgoacCanChuanHoa`.
  static const _kyTuNgoacCanChuanHoaChat = {'(', ')', '{', '}', '[', ']', '"'};

  int? _viTriChenMotKyTuDonChat(String cu, String chuMoi) {
    if (chuMoi.length != cu.length + 1) return null;
    var dau = 0;
    while (dau < cu.length && cu[dau] == chuMoi[dau]) {
      dau++;
    }
    if (cu.substring(dau) != chuMoi.substring(dau + 1)) return null;
    return dau;
  }

  void _kiemTraDanhDauVietHoaChat(String vanBan, int viTriChen) {
    if (viTriChen <= 0 || viTriChen > vanBan.length) return;
    if (vanBan[viTriChen - 1] != ' ') return;
    var i = viTriChen - 1;
    while (i > 0 && vanBan[i - 1] == ' ') {
      i--;
    }
    if (i == 0) return;
    if (_kyTuKetCauChoVietHoaChat.contains(vanBan[i - 1])) {
      _viTriChoVietHoaChat = viTriChen;
    }
  }

  (int, String)? _ketQuaVietHoaChoTuVuaGoXongChat(String vanBan, String ktChen) {
    final vt = _viTriChoVietHoaChat;
    _viTriChoVietHoaChat = null;
    if (vt == null) return null;
    if (ktChen != ' ' && ktChen != '\n') return null;
    if (vt < 0 || vt >= vanBan.length) return null;
    final kt = vanBan[vt];
    if (!_laChuCaiChat.hasMatch(kt)) return null;
    return (vt, kt.toUpperCase());
  }

  /// Ghi lại `_oNhap` kèm vị trí con trỏ MỚI mà không cho `_khiONhapDoi` xử
  /// lý đè lên chính thay đổi này — dùng lại đúng cờ `_micTuDoiONhap` (dù
  /// tên nói về mic, ý nghĩa thật là "đổi do chính app tự gán, không phải
  /// người dùng gõ tay").
  void _ghiLaiVaDatConTroChat(String vanBan, int viTriConTro) {
    _micTuDoiONhap = true;
    final selectionMoi = TextSelection.collapsed(offset: viTriConTro);
    _oNhap.value = TextEditingValue(text: vanBan, selection: selectionMoi);
    _micTuDoiONhap = false;
    _micSelectionVuaGan = selectionMoi;
  }

  /// (Tính năng "Chuẩn hoá các cặp dấu đóng-mở ngoặc") Bản RÚT GỌN của
  /// `_TrangSoanThaoState._chuanHoaNgoacSauKhiGo` cho ô nhập chat — không
  /// đụng gì tới lỗi chính tả/vùng toàn văn (chat không có hai khái niệm
  /// đó), chỉ xoá dấu cách thừa ngay sau dấu mở / ngay trước dấu đóng của
  /// ĐÚNG MỘT cặp mà ký tự vừa gõ hoàn thành.
  void _chuanHoaNgoacSauKhiGoChat(String kyTuVuaGo, int vt) {
    final vb = _oNhap.text;
    if (vt < 0 || vt >= vb.length || vb[vt] != kyTuVuaGo) return;

    final canXoa = <int>{};
    void chuanHoaMotCap(int moTai, int dongTai) {
      if (moTai + 1 < dongTai && vb[moTai + 1] == ' ') canXoa.add(moTai + 1);
      if (dongTai - 1 > moTai && vb[dongTai - 1] == ' ') canXoa.add(dongTai - 1);
    }

    if (kyTuVuaGo == '"') {
      var soDauTruoc = 0;
      for (var i = 0; i < vt; i++) {
        if (vb[i] == '"') soDauTruoc++;
      }
      if (soDauTruoc.isOdd) {
        for (var i = vt - 1; i >= 0; i--) {
          if (vb[i] == '"') {
            chuanHoaMotCap(i, vt);
            break;
          }
        }
      }
    } else {
      const laMoNgoac = {'(', '{', '['};
      if (laMoNgoac.contains(kyTuVuaGo)) return;
      const moUngVoiDong = {')': '(', '}': '{', ']': '['};
      final moNgoac = moUngVoiDong[kyTuVuaGo]!;
      final ngan = <int>[];
      for (var i = 0; i <= vt; i++) {
        if (vb[i] == moNgoac) {
          ngan.add(i);
        } else if (vb[i] == kyTuVuaGo && ngan.isNotEmpty) {
          final moTai = ngan.removeLast();
          if (i == vt) chuanHoaMotCap(moTai, i);
        }
      }
    }

    if (canXoa.isEmpty) return;
    final ds = canXoa.toList()..sort((a, b) => b.compareTo(a));
    var moi = vb;
    var neo = _oNhap.selection.end;
    if (neo < 0) neo = moi.length;
    for (final v in ds) {
      moi = moi.replaceRange(v, v + 1, '');
      if (neo > v) neo--;
    }
    _ghiLaiVaDatConTroChat(moi, neo);
  }

  /// Áp dụng, cho ô nhập chat, ĐÚNG logic ba cài đặt "Tự động thêm dấu chấm
  /// trước khi xuống dòng" / "Tự động viết hoa ở đầu câu" / "Chuẩn hoá các
  /// cặp dấu đóng-mở ngoặc" khi BẬT (khi TẮT thì không đổi gì, y hệt trang
  /// soạn thảo chính), và việc "nhảy dấu câu qua trước dấu cách có sẵn" CHẠY
  /// NGẦM LUÔN (không qua cài đặt nào) — bản rút gọn của
  /// `_TrangSoanThaoState._apDungChinhSuaNguoiDung`, bỏ hẳn phần thụt đầu
  /// dòng/đường kẻ chia/lỗi chính tả vì chat không có các khái niệm đó. Chỉ
  /// chạy khi đây đúng là một lần gõ tay chèn ĐÚNG một ký tự đơn giản.
  void _apDungTuDongDinhDangChat(String cu, String chuMoiGoc) {
    final viTriChenDon = _viTriChenMotKyTuDonChat(cu, chuMoiGoc);
    if (viTriChenDon == null) {
      _chuChatGanNhat = chuMoiGoc;
      return;
    }
    var chuMoi = chuMoiGoc;
    final ktChen = chuMoi[viTriChenDon];

    // (VIỆC 4) Viết hoa đầu câu — CHẠY TRƯỚC mọi thứ khác, đúng thứ tự ưu
    // tiên của trang soạn thảo chính.
    if (widget.caiDat.tuDongVietHoaDauCau) {
      final ketQua = _ketQuaVietHoaChoTuVuaGoXongChat(chuMoi, ktChen);
      if (ketQua != null) {
        final (vt, chuHoa) = ketQua;
        chuMoi = chuMoi.substring(0, vt) + chuHoa + chuMoi.substring(vt + 1);
      }
      _kiemTraDanhDauVietHoaChat(chuMoi, viTriChenDon);
    }

    // (VIỆC 5b) Enter đơn giản — tự thêm dấu chấm trước khi xuống dòng, trừ
    // các trường hợp loại trừ y hệt trang soạn thảo chính.
    if (ktChen == '\n' && widget.caiDat.tuDongThemDauCham) {
      final ktNgayTruoc = viTriChenDon > 0 ? chuMoi[viTriChenDon - 1] : null;
      final daCoChamRoi = ktNgayTruoc == '.' ||
          (ktNgayTruoc == ' ' &&
              viTriChenDon >= 2 &&
              chuMoi[viTriChenDon - 2] == '.');
      const kyTuDacBietChoEnter = {
        ';', '.', ',', '/', ')', '(', '"', "'", '*', ':', '!', '?', '•',
      };
      final ktTruocNua = viTriChenDon >= 2 ? chuMoi[viTriChenDon - 2] : null;
      final laTruongHop6 = ktNgayTruoc == ' ' &&
          ktTruocNua != null &&
          kyTuDacBietChoEnter.contains(ktTruocNua);
      final khongThemDauChamThem = ktNgayTruoc == null ||
          ktNgayTruoc == '\n' ||
          (ktNgayTruoc == ' ' && ktTruocNua == '\n') ||
          (ktNgayTruoc == ' ' && ktTruocNua == null) ||
          kyTuDacBietChoEnter.contains(ktNgayTruoc) ||
          laTruongHop6;
      final themCham = !daCoChamRoi && !khongThemDauChamThem;
      if (themCham || laTruongHop6) {
        var moiDau = viTriChenDon;
        String chenVao;
        if (themCham) {
          if (ktNgayTruoc == ' ') moiDau = viTriChenDon - 1;
          chenVao = '.\n';
        } else {
          moiDau = viTriChenDon - 1;
          chenVao = '\n';
        }
        chuMoi = chuMoi.substring(0, moiDau) + chenVao + chuMoi.substring(viTriChenDon + 1);
        final viTriConTroMoi = moiDau + chenVao.length;
        _chuChatGanNhat = chuMoi;
        _ghiLaiVaDatConTroChat(chuMoi, viTriConTroMoi);
        return;
      }
    }

    // (VIỆC 5, chạy NGẦM, không qua cài đặt) Gõ đúng một ký tự đặc biệt
    // (. , ; ? ! :) ngay sau một dấu cách có sẵn — hoán đổi hai ký tự đó
    // cho nhau, để dấu câu nằm sát vào chữ trước nó.
    var chuMoiCuoi = chuMoi;
    var viTriConTro = viTriChenDon + 1;
    if (viTriChenDon > 0 &&
        chuMoi[viTriChenDon - 1] == ' ' &&
        _kyTuDacBietChat.contains(ktChen)) {
      chuMoiCuoi = chuMoi.substring(0, viTriChenDon - 1) +
          ktChen +
          ' ' +
          chuMoi.substring(viTriChenDon + 1);
      viTriConTro = viTriChenDon;
      if (widget.caiDat.tuDongVietHoaDauCau) {
        _kiemTraDanhDauVietHoaChat(chuMoiCuoi, viTriChenDon + 1);
      }
    }

    _chuChatGanNhat = chuMoiCuoi;
    if (chuMoiCuoi != chuMoiGoc) {
      _ghiLaiVaDatConTroChat(chuMoiCuoi, viTriConTro);
    }

    // (Tính năng "Chuẩn hoá các cặp dấu đóng-mở ngoặc") `_kyTuDacBietChat`
    // và `_kyTuNgoacCanChuanHoaChat` không giao nhau, nên nếu vừa nhảy dấu
    // câu ở trên thì chắc chắn KHÔNG rơi vào nhánh này — vị trí ký tự vừa gõ
    // trong [chuMoiCuoi] luôn vẫn là [viTriChenDon].
    if (widget.caiDat.tuDongChuanHoaNgoac &&
        _kyTuNgoacCanChuanHoaChat.contains(ktChen)) {
      _chuanHoaNgoacSauKhiGoChat(ktChen, viTriChenDon);
    }
  }

  void _khiONhapDoi() {
    if (_micTuDoiONhap) return;
    final cuChat = _chuChatGanNhat;
    final chuMoiChat = _oNhap.text;
    // (SỬA LỖI v124 — "micro chỉ cho ra MỘT từ rồi tự tắt/bật lại ngay",
    // CHỈ xảy ra khi khung nhập đang có tiêu điểm/con trỏ nhấp nháy thật)
    // `TextEditingController` phát thông báo (gọi listener này) mỗi khi
    // `value` đổi — kể cả khi CHỈ `selection` đổi, chữ không hề đổi. Khung
    // nhập đang có tiêu điểm thật thì mỗi lần mic tự gán `_oNhap.value`
    // (dù đã bọc cờ `_micTuDoiONhap`) có thể khiến trình duyệt/bàn phím ảo
    // dội lại một thông báo đổi SELECTION riêng (không đổi chữ) tới SAU KHI
    // cờ đã được trả về `false` — khi đó hàm này tưởng nhầm là "người dùng
    // vừa gõ tay" (dù chữ không đổi gì cả) và gọi `_nguoiDungVuaGoChat()`,
    // huỷ ngay phiên đang nghe — đúng triệu chứng "nói nhiều từ nhưng chỉ
    // vào được một từ". Chặn tại gốc: KHÔNG có gì để làm (không đụng tới
    // cả tự động định dạng lẫn "gõ tay thắng mic") khi CHỮ chưa hề đổi,
    // bất kể vì sao hàm này được gọi.
    if (cuChat == chuMoiChat) {
      // (YÊU CẦU MỚI, SỬA LỖI v132/v133 — "chữ lặp lại liên tục, nhân đôi")
      // Chữ không đổi nhưng con trỏ vừa dời đi nơi khác trong lúc mic đang
      // nghe. Nhánh này cũng chạy cho MỌI thông báo dội lại PHANTOM sau khi
      // mic tự gán chữ (rất thường xuyên, selection lúc đó vẫn y hệt vị trí
      // mic VỪA tự đặt) — CHỈ coi là người dùng chạm/dời con trỏ THẬT khi
      // selection khác với vị trí mic tự đặt gần nhất (`_micSelectionVuaGan`).
      //
      // (SỬA LỖI v133 — bản vá trước CHỈ dời neo `_micDiemBatDau` tại chỗ,
      // không đụng gì tới phiên `listen()` đang chạy) Bộ nhận dạng của máy
      // là MỘT phiên `listen()` LIÊN TỤC từ lúc bắt đầu nghe — nó không hề
      // biết người dùng vừa dời con trỏ, vẫn coi toàn bộ những gì đã/đang
      // nói là MỘT utterance DUY NHẤT kéo dài xuyên qua lúc dời con trỏ.
      // Cứ chỉ dời neo cục bộ mà không báo cho bộ nhận dạng thì câu
      // (`chen`) nó trả về sau đó vẫn mang theo nguyên cụm chữ CŨ (đã nằm
      // sẵn ở vị trí cũ) lồng ở ĐẦU, rồi mình lại chèn nguyên cụm đó một
      // lần nữa vào vị trí MỚI — nhân đôi đúng như log người dùng gửi.
      // Cách đúng — ĐÚNG HỆT khi người dùng gõ tay chen vào lúc mic đang
      // nghe: coi việc dời con trỏ như MỘT LƯỢT GÕ TAY ảo, gọi thẳng
      // `_nguoiDungVuaGoChat()` — HUỶ hẳn phiên đang nghe (`cancel()`,
      // không đợi kết quả trễ), tự bật lại một phiên HOÀN TOÀN MỚI sau
      // đúng số giây đã cài ở Cài đặt Micro. Phiên mới có bộ đệm/neo sạch
      // từ đầu (xem `_batPhienNgheMicChat`, nay neo đúng tại vị trí con trỏ
      // MỚI), không còn gì của utterance cũ lẫn vào.
      if (_micDangNghe &&
          _oNhap.selection.isValid &&
          _oNhap.selection != _micSelectionVuaGan) {
        _nguoiDungVuaGoChat();
      }
      return;
    }
    _apDungTuDongDinhDangChat(cuChat, chuMoiChat);

    // `_micDangNghe` tắt vì gõ tay (`_dangTamTatMicChatDeGo`) VẪN phải tiếp
    // tục xử lý ở đây — gõ thêm ký tự nữa trong lúc đang đếm ngược chờ bật
    // lại phải DỜI LẠI đồng hồ đó (y hệt trang soạn thảo chính: gõ liên tục
    // thì mic chỉ bật lại sau khi tay NGỪNG hẳn đủ số giây, không phải tính
    // từ ký tự đầu tiên). Mic tắt vì lý do KHÁC (người dùng tự bấm tắt hẳn)
    // thì không liên quan gì tới đây nữa.
    if (!_micDangNghe && !_dangTamTatMicChatDeGo) return;
    // Có chữ mới (gõ tay hay mic) — huỷ đếm ngược tự tắt vì im lặng, đặt lại
    // từ đầu, y hệt trang soạn thảo chính.
    _datLaiHenTuTatMicChatImLang();
    // Người dùng vừa gõ tay (hoặc dán/xoá) — ĐÚNG KHUÔN `_nguoiDungVuaGo` ở
    // trang soạn thảo chính: gõ tay phải THẮNG hẳn, không chỉ dời lại mốc.
    // (SỬA LỖI — bản trước chỉ dời `_micDiemBatDau`/`_micChuGanNhat`, KHÔNG
    // huỷ phiên đang nghe: bộ nhận dạng vẫn giữ nguyên cụm chữ cũ trong bộ
    // nhớ của NÓ, kết quả trễ bay về sau đó chèn lại cụm cũ tại vị trí mới
    // — đúng kiểu "Xin chào,Xin chào tôi muốn..." người dùng báo. Cách
    // đúng: HUỶ hẳn phiên đang nghe ngay (không đợi, không tin kết quả
    // trễ), tắt mic hẳn (ẩn nút vuông đỏ, hiện lại nút Gửi), rồi tự bật lại
    // một phiên HOÀN TOÀN MỚI sau đúng số giây đã cài trong Cài đặt Micro.
    _nguoiDungVuaGoChat();
  }

  Timer? _henGoXongMicChat;

  /// `true` = mic kênh chat đang TẠM tắt vì vừa gõ tay, đang đếm ngược chờ
  /// tự bật lại — khác hẳn người dùng tự bấm tắt hẳn. Trong lúc này
  /// `_micDangNghe` cũng `false` (UI ẩn nút vuông đỏ/hiện nút Gửi, ĐÚNG
  /// yêu cầu), nhưng cờ riêng này mới là thứ quyết định có tự bật lại hay
  /// không, và có cho phép gõ tiếp DỜI đồng hồ đếm ngược hay không.
  bool _dangTamTatMicChatDeGo = false;

  /// Người dùng vừa gõ phím (hoặc dán/xoá) trong lúc Micro kênh chat đang
  /// nghe HOẶC đang đếm ngược chờ bật lại — ĐÚNG KHUÔN
  /// `_TrangSoanThaoState._nguoiDungVuaGo`: huỷ hẳn phiên đang nghe (không
  /// phải chỉ dời mốc), tắt mic hẳn, rồi tự bật lại sau số giây đã cài
  /// trong Cài đặt Micro (âm = không tự bật lại) — gõ liên tục thì đồng hồ
  /// cứ dời lại mãi, chỉ thật sự đếm khi tay đã ngừng hẳn.
  void _nguoiDungVuaGoChat() {
    if (_micDangNghe) {
      widget.ghiNhatKyMicro
          ?.call('[chat] Người dùng gõ tay — huỷ phiên #$_phienNgheMicChat, tắt mic');
      // Tăng số phiên NGAY — mọi `onResult` của phiên vừa huỷ (kể cả tới
      // trễ) bị vứt thẳng, không ghi đè gì vào bài nữa.
      _phienNgheMicChat++;
      _henBatLaiMicChat?.cancel();
      // Đặt cờ TRƯỚC khi gọi cancel() — cancel() kích `onStatus` một cách
      // KHÔNG đồng bộ, `_khiMicDoiTrangThai` đọc đúng cờ `_micDangNghe` này
      // để quyết định có tự bật lại hay không.
      _dangTamTatMicChatDeGo = true;
      setState(() {
        _micDangNghe = false;
        _micDangNgheThat = false;
      });
      // cancel() (không phải stop()) — không đợi một kết quả chốt cuối
      // cùng bay về rồi đổ nhầm vào chỗ mới, y hệt lý do trang soạn thảo
      // chính dùng cancel() ở đây.
      _micro.cancel();
    } else {
      widget.ghiNhatKyMicro?.call('[chat] Người dùng gõ tiếp — dời lại đồng hồ chờ bật mic lại');
    }

    _henGoXongMicChat?.cancel();
    final giay = widget.caiDat.thoiGianBatLaiGiay;
    // Người dùng chọn "Không tự động bật lại Micro" trong Cài đặt: cứ tắt
    // vậy luôn, đợi tự tay bấm lại.
    if (giay < 0) {
      _dangTamTatMicChatDeGo = false;
      return;
    }
    _henGoXongMicChat = Timer(
      Duration(milliseconds: (giay * 1000).round()),
      _batLaiMicChatSauKhiGoXong,
    );
  }

  Future<void> _batLaiMicChatSauKhiGoXong() async {
    if (!_dangTamTatMicChatDeGo || !mounted) return;
    _dangTamTatMicChatDeGo = false;
    widget.ghiNhatKyMicro?.call('[chat] Hết giờ chờ sau khi gõ tay — tự bật lại micro');
    setState(() => _micDangNghe = true);
    _datLaiHenTuTatMicChatImLang();
    await _batPhienNgheMicChat();
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

  /// (YÊU CẦU MỚI) Bấm nút Micro nổi cạnh nút Gửi: đang TẮT thì bật ngay
  /// (gọi thẳng `_batMicChat`); đang BẬT thì ÉP tắt rồi tự bật lại NGAY —
  /// ĐÚNG HỆT cơ chế đã có sẵn cho lúc người dùng gõ tay/dời con trỏ trong
  /// lúc mic đang nghe (`_nguoiDungVuaGoChat`, xem `_khiONhapDoi`) — không
  /// làm gì mới, chỉ mượn lại cơ chế đã chứng minh ổn định đó. Giúp mic
  /// không bị "xung đột" nếu đang nghe mà người dùng vẫn bấm nút này (một
  /// phiên MỚI sạch, bộ đệm/neo reset lại từ đầu).
  void _bamNutMicNoiChat() {
    // (YÊU CẦU MỚI) Ép tiêu điểm/con trỏ nhấp nháy + bàn phím ảo hiện ra,
    // ĐÚNG HỆT cách nút Micro trong "+" đã làm (`_batMicChat`) — áp dụng
    // cho CẢ HAI nhánh dưới đây, vì nhánh "đang nghe → ép tắt/bật lại"
    // (`_nguoiDungVuaGoChat`) không tự làm việc này.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusONhap.requestFocus();
    });
    if (_micDangNghe) {
      _nguoiDungVuaGoChat();
    } else {
      _batMicChat();
    }
  }

  Future<void> _batMicChat() async {
    // Ghi âm và Micro loại trừ nhau — bật cái này thì tự tắt cái kia trước.
    if (_ghiDangMo) return; // đang có hộp thoại ghi âm mở — không thể bật mic.
    // Người dùng tự tay bật lại — một lượt thử MỚI, cho đủ hạn mức bật lại
    // liên tục từ đầu, không tính dồn với những lần thất bại trước đó.
    _soLanBatLaiLienTucKhongKetQua = 0;
    // (YÊU CẦU MỚI) Micro hoạt động tốt nhất khi khung nhập đang có tiêu
    // điểm/con trỏ nhấp nháy THẬT (kéo theo bàn phím ảo tự hiện) — ép điều
    // đó mỗi lần bật Micro, bất kể trước đó khung nhập có tiêu điểm hay
    // không (đã có rồi thì gọi lại vô hại). `requestFocus()` gọi ngay trong
    // `onSelected` của `PopupMenuButton` có thể bị menu tự ĐÓNG (trả focus
    // về chỗ khác) GHI ĐÈ ngay sau đó trong cùng khung hình — hoãn sang
    // `addPostFrameCallback` để là hành động CUỐI CÙNG, thắng được việc đó
    // (đúng mẹo đã dùng cho `_oChu.requestFocus()` ở trang soạn thảo).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusONhap.requestFocus();
    });
    // Nút Micro nổi cạnh nút Gửi: hiện ra từ lần bật Micro đầu tiên trong
    // phiên mở kênh chat này, giữ nguyên hiện tới khi rời màn hình.
    if (!_hienNutMicNoiChat && mounted) {
      setState(() => _hienNutMicNoiChat = true);
    }
    // Người dùng tự bấm bật lại (kể cả đang giữa lúc đếm ngược chờ tự bật
    // lại sau khi gõ tay) — ý họ là quyết định cuối cùng, huỷ hẳn đếm ngược
    // cũ, không để nó tự bật lại một lần nữa sau đó.
    _dangTamTatMicChatDeGo = false;
    _henGoXongMicChat?.cancel();
    if (!_microChatDungDuocTrenThietBiNay) {
      _hienCanhBaoMicIphoneChat();
      return;
    }
    if (!_micKhoiTaoXong) {
      _micKhoiTaoXong = await _micro.initialize(
        onStatus: _khiMicDoiTrangThai,
        // ĐÚNG khuôn `_TrangSoanThaoState._khoiTaoMicro`: trình nhận dạng
        // bắn lỗi 'nhẹ' (hết câu do im lặng, bận, bị hệ thống chặn bật lại
        // quá nhanh...) RẤT THƯỜNG XUYÊN, đặc biệt ngay sau mỗi lần tự
        // ngắt/tự bật lại — và những lỗi đó KHÔNG hề có nghĩa là mic đã
        // chết hẳn. Trước đây chat KHÔNG có `onError` nào cả — một lỗi bắn
        // ra mà không kèm đúng sự kiện `onStatus` "notListening" tương ứng
        // (có thể xảy ra, tuỳ trình duyệt/thiết bị) sẽ làm mic coi như kẹt
        // luôn, không tự bật lại nữa, dù người dùng không hề tắt — đúng
        // triệu chứng người dùng báo. Luôn gọi `_lenLichBatLaiMicChat()`
        // bất kể lỗi gì (y hệt trang soạn thảo chính luôn gọi `_henBatLai()`
        // trong `onError`, không phân biệt — vô hại nếu phiên NÀY vẫn đang
        // chạy tốt vì `_khiMicDoiTrangThai` cũng gọi lại y hệt).
        onError: (loi) {
          widget.ghiNhatKyMicro?.call('[chat] onError: "${loi.errorMsg}"');
          if (mounted) setState(() => _micDangNgheThat = false);
          _lenLichBatLaiMicChat();
        },
        debugLogging: false,
      );
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
    // (YÊU CẦU MỚI) Neo tại ĐÚNG vị trí con trỏ hiện tại — không phải luôn
    // luôn cuối văn bản. Quan trọng nhất ở lượt TỰ BẬT LẠI sau khi người
    // dùng vừa dời con trỏ (qua `_nguoiDungVuaGoChat`, xem `_khiONhapDoi`):
    // phiên MỚI phải chèn đúng tại vị trí con trỏ MỚI đó, không phải quay
    // về cuối văn bản như trước.
    final selection = _oNhap.selection;
    _micDiemBatDau =
        selection.isValid ? selection.start : _oNhap.text.length;
    _micChuGanNhat = '';
    _rawTichLuyChromeAndroidChat = '';
    // Chụp số phiên NGAY LÚC đăng ký — xem giải thích đầy đủ ở
    // `_phienNgheMicChat`. Mỗi lần gọi hàm này (kể cả tự bật lại) là một
    // phiên MỚI; `onResult` chỉ nhận đúng phiên vừa đăng ký.
    final idPhien = ++_phienNgheMicChat;
    widget.ghiNhatKyMicro?.call('[chat] Bắt đầu phiên #$idPhien');
    // (SỬA LỖI v121 — "nút vuông đỏ không còn xuất hiện") Hàm này LUÔN được
    // gọi với ý định (`_micDangNghe`) đã là `true` từ trước — nhưng trước
    // đây UI (`_micDangNgheThat`) CHỈ bật lên khi `onStatus` thật sự báo
    // "listening", một sự kiện KHÔNG đáng tin cậy để chờ (có lúc tới rất
    // trễ hoặc không tới — y hệt lý do không nên tiếp tục tin tưởng tuyệt
    // đối vào sự kiện hệ thống ở các lỗi khác đã sửa). Đặt lạc quan NGAY
    // TẠI ĐÂY, đúng lúc TA chủ động ra lệnh bắt đầu nghe — không cần chờ
    // xác nhận ngược lại mới cho hiện nút.
    if (mounted) setState(() => _micDangNgheThat = true);
    try {
      await _micro.listen(
        onResult: (ketQua) {
          if (idPhien != _phienNgheMicChat) {
            widget.ghiNhatKyMicro?.call(
                '[chat] onResult phiên CŨ #$idPhien (hiện tại #$_phienNgheMicChat) — vứt: '
                '"${ketQua.recognizedWords}"');
            return;
          }
          if (!_micDangNghe) return;
          // (SỬA LỖI "bão tự bật lại micro vô hạn") Có `onResult` thật sự
          // lọt tới đây cho đúng phiên hiện tại — bằng chứng chắc chắn
          // trình nhận dạng vẫn sống, không phải đang kẹt — reset bộ đếm
          // bật lại liên tiếp, xem `_soLanBatLaiLienTucKhongKetQua`.
          _soLanBatLaiLienTucKhongKetQua = 0;
          // (SỬA LỖI v121 — "tự xoá chữ vừa nói khi micro tự tắt") Một số
          // trình duyệt/thiết bị gửi một kết quả CUỐI (`finalResult: true`)
          // VỚI CHUỖI RỖNG ngay lúc `pauseFor` cắt phiên do im lặng — không
          // phải "câu nói rỗng", mà là tín hiệu kỹ thuật "hết, không còn gì
          // thêm". Xử lý tiếp như một `chen` rỗng BÌNH THƯỜNG (như code cũ
          // vẫn làm) sẽ THAY THẾ đúng vùng `_micChuGanNhat` (toàn bộ câu vừa
          // hiện ra) bằng chuỗi rỗng — XOÁ MẤT câu đó. Không có gì mới để
          // chèn thì dừng ngay, đừng đụng gì vào văn bản đang có.
          if (ketQua.recognizedWords.isEmpty) {
            widget.ghiNhatKyMicro?.call(
                '[chat] onResult phiên #$idPhien, xong=${ketQua.finalResult}: rỗng — bỏ qua, '
                'không xoá chữ đã hiện ra');
            return;
          }
          _datLaiHenTuTatMicChatImLang();
          var chen = ketQua.recognizedWords;
          widget.ghiNhatKyMicro?.call(
              '[chat] onResult phiên #$idPhien, xong=${ketQua.finalResult}: "$chen"');
          // Android bản web: `recognizedWords` không phải "toàn bộ utterance
          // tính từ đầu, sạch sẽ" — nó CỘNG DỒN VÔ HẠN, mỗi lần gọi lại ghép
          // THÊM đuôi mới vào SAU TOÀN BỘ raw đã gửi ở MỌI lần gọi trước đó
          // (không phải chỉ lần ngay trước). Bằng chứng từ nhật ký thật:
          // raw đi "Alo" → "AloAlo" → "AloAloAlo" → "AloAloAloAlo bạn" →
          // "...Alo bạnAlo bạn có" — phần ĐUÔI MỚI sau khi trừ đúng
          // phần raw đã thấy ở lần gọi NGAY TRƯỚC luôn là "Alo", "Alo",
          // "Alo", "Alo bạn", "Alo bạn có"... — TỰ NÓ đã là cụm chữ ĐẦY ĐỦ,
          // SẠCH của utterance hiện tại rồi, không phải một "từ mới" cần
          // ghép thêm. (SỬA LẠI LỖI CŨ — bản trước đây GHÉP đuôi này vào
          // `_micChuGanNhat` cũ, biến một cụm vốn đã đầy đủ thành nhân đôi
          // liên tục; đây chính là nguồn gốc thật của lỗi lặp chữ, không
          // phải do thiếu cơ chế phiên.) Giờ dùng THẲNG đuôi mới làm `chen`
          // — ĐÚNG hệt cách trang soạn thảo chính xử lý `noi` sau khi trừ.
          if (kIsWeb && _thietBiChoMicChat == ThietBi.android) {
            final raw = chen;
            if (raw.startsWith(_rawTichLuyChromeAndroidChat)) {
              chen = raw.substring(_rawTichLuyChromeAndroidChat.length);
            }
            // else: raw không còn khớp tiền tố đã theo dõi (trình duyệt vừa
            // âm thầm khởi động lại bộ đệm) — coi nguyên `raw` là cụm chữ
            // thật, an toàn hơn là trừ nhầm.
            _rawTichLuyChromeAndroidChat = raw;
            widget.ghiNhatKyMicro?.call('[chat]   → sau khi trừ raw cộng dồn: "$chen"');
            // Trừ xong ra rỗng (raw mới khớp NGUYÊN VĂN tiền tố đã thấy, tức
            // chẳng có gì mới) — y hệt lý do ở trên: KHÔNG được dùng chuỗi
            // rỗng này để thay thế/xoá mất `_micChuGanNhat` hiện có.
            if (chen.isEmpty) return;
          }
          final vb = _oNhap.text;
          final batDau = _micDiemBatDau.clamp(0, vb.length);
          // Trước khi chèn chữ do lời nói ra, luôn đảm bảo có dấu cách TRƯỚC
          // nó (tách biệt đoạn nói trước/sau, không dính chùm) — TRỪ KHI
          // ngay trước vị trí chèn đã là dấu cách rồi, hoặc đang ở đầu văn
          // bản (không có ký tự gì cả) thì không cần thêm nữa. Luôn áp dụng,
          // không phụ thuộc cài đặt nào — ĐÚNG khuôn trang soạn thảo chính.
          if (chen.isNotEmpty && batDau > 0 && vb[batDau - 1] != ' ' && vb[batDau - 1] != '\n') {
            chen = ' $chen';
          }
          // "Tự động chèn dấu cách sau mỗi lần nói" (Cài đặt) — ĐÚNG khuôn
          // trang soạn thảo chính: thêm một dấu cách NGAY SAU cụm chữ vừa
          // nhận dạng, mỗi lần cập nhật (không đợi câu chốt xong).
          if (chen.isNotEmpty &&
              widget.caiDat.tuDongChenKhoangCach &&
              chen[chen.length - 1] != ' ' &&
              chen[chen.length - 1] != '\n') {
            chen = '$chen ';
          }
          final ketThucCu = (batDau + _micChuGanNhat.length).clamp(batDau, vb.length);
          final moi = vb.substring(0, batDau) + chen + vb.substring(ketThucCu);
          final selectionMoi = TextSelection.collapsed(offset: batDau + chen.length);
          _micTuDoiONhap = true;
          _oNhap.value = TextEditingValue(text: moi, selection: selectionMoi);
          _micTuDoiONhap = false;
          _micSelectionVuaGan = selectionMoi;
          // (SỬA LỖI — "nói nhiều từ nhưng chỉ vào được một từ rồi tự
          // tắt/bật lại ngay") `_khiONhapDoi` tin `_chuChatGanNhat` luôn
          // đúng bằng `_oNhap.text` NGAY SAU lần đổi chữ gần nhất, bất kể vì
          // sao chữ đổi (xem chú thích ở đó) — nhưng ở đây mic tự gán
          // `_oNhap.value` lại KHÔNG cập nhật `_chuChatGanNhat` theo, vẫn để
          // nó đứng yên ở giá trị CŨ (từ trước khi mic chèn chữ này). Một
          // thông báo dội lại từ trình duyệt/bàn phím ảo tới SAU, dù chữ
          // không hề đổi thêm gì nữa, sẽ bị `_khiONhapDoi` so `cuChat` (giá
          // trị cũ, stale) với `chuMoiChat` (đã có "Xin" mic vừa chèn) ra
          // KHÁC NHAU — hiểu lầm thành một lượt gõ tay chèn nguyên cụm "Xin"
          // vào, gọi `_nguoiDungVuaGoChat()`, huỷ ngay phiên đang nghe. Phải
          // đồng bộ `_chuChatGanNhat` theo `_oNhap.text` ở MỌI nơi tự gán chữ
          // (y hệt `_apDungTuDongDinhDangChat`/`_ghiLaiVaDatConTroChat` đã
          // làm cho nhánh gõ tay), không chỉ nhánh đó.
          _chuChatGanNhat = moi;
          _micChuGanNhat = chen;
          // (YÊU CẦU MỚI) Chữ mic vừa chèn có thể đã đẩy khung nhập ra
          // ngoài tầm nhìn (khung đã đạt chiều cao tối đa, phải tự cuộn
          // bên trong) — gõ tay thì `TextField` tự cuộn theo caret, mic tự
          // gán `.value` thì không, phải tự cuộn tay xuống đáy ở đây.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_cuonONhap.hasClients) {
              _cuonONhap.jumpTo(_cuonONhap.position.maxScrollExtent);
            }
          });
          // (SỬA LỖI "micro quay lại sửa chữ đã hiện ra") Một kết quả FINAL
          // (`finalResult == true`) nghĩa là CÂU NÓI hiện tại đã xong — y
          // hệt BƯỚC E ở `_TrangSoanThaoState._khiCoChu`, coi toàn bộ nội
          // dung hiện có là CHỐT CỨNG: dời hẳn `_micDiemBatDau` tới ngay sau
          // đoạn vừa chèn và rỗng `_micChuGanNhat`. Trước đây hai biến này
          // CHỈ reset lúc bắt đầu một PHIÊN `listen()` mới (hệ thống tự ngắt
          // hẳn, xem `_batPhienNgheMicChat`) — nhưng MỘT phiên `listen()`
          // (dài tới 10 phút) có thể chứa NHIỀU câu nói, mỗi câu kết thúc
          // bằng một kết quả FINAL riêng mà vẫn ở NGUYÊN phiên đó. Không dời
          // mốc ở đây thì câu nói THỨ HAI trong cùng một phiên vẫn thay thế
          // đúng vùng `[batDau, batDau + độ dài câu THỨ NHẤT)` — tức là ghi
          // ĐÈ/XOÁ mất câu đã chốt trước đó, đúng triệu chứng người dùng
          // báo. Rỗng luôn bộ đệm cộng dồn Chrome Android — câu nói MỚI sau
          // đây là một utterance hoàn toàn khác, không còn gì để trừ.
          if (ketQua.finalResult) {
            _micDiemBatDau = batDau + chen.length;
            _micChuGanNhat = '';
            _rawTichLuyChromeAndroidChat = '';
          }
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
      // (SỬA LỖI "mic đôi khi không tự bật lại") Trước đây lỗi ở đây làm
      // tắt hẳn `_micDangNghe` — coi như người dùng đã chủ động tắt, không
      // bao giờ tự bật lại nữa. ĐÚNG khuôn trang soạn thảo chính
      // (`_batMicro` → `catch (_) { _henBatLai(); }`): một lần `listen()`
      // ném lỗi KHÔNG có nghĩa ý định người dùng đã đổi — vẫn giữ
      // `_micDangNghe`, chỉ cập nhật UI thật (ẩn nút vuông) rồi lên lịch
      // bật lại y hệt lúc hệ thống tự ngắt bình thường.
      if (mounted) setState(() => _micDangNgheThat = false);
      _lenLichBatLaiMicChat();
    }
  }

  /// Lên lịch bật lại một phiên MỚI sau 200ms — dùng chung cho cả hai
  /// nguồn: hệ thống tự ngắt bình thường (`_khiMicDoiTrangThai`) và
  /// `listen()`/`initialize()` ném lỗi (`_batPhienNgheMicChat` catch,
  /// `onError`). Không làm gì nếu người dùng đã tự tắt hẳn ý định nghe
  /// (`_micDangNghe` false) — tránh bật lại ngoài ý muốn.
  void _lenLichBatLaiMicChat() {
    if (!_micDangNghe) return;
    _soLanBatLaiLienTucKhongKetQua++;
    widget.ghiNhatKyMicro?.call(
        '[chat] Lên lịch bật lại lần $_soLanBatLaiLienTucKhongKetQua liên tiếp '
        'chưa có onResult nào');
    if (_soLanBatLaiLienTucKhongKetQua > _soLanBatLaiLienTucToiDa) {
      widget.ghiNhatKyMicro?.call(
          '[chat] Bật lại $_soLanBatLaiLienTucToiDa lần liên tiếp vẫn không '
          'nghe được gì — chịu, tắt hẳn mic');
      _soLanBatLaiLienTucKhongKetQua = 0;
      _henBatLaiMicChat?.cancel();
      if (mounted) {
        setState(() {
          _micDangNghe = false;
          _micDangNgheThat = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Micro liên tục không bật lại được — đã tắt. Hãy thử bấm lại.'),
        ));
      }
      return;
    }
    _henBatLaiMicChat?.cancel();
    _henBatLaiMicChat = Timer(const Duration(milliseconds: 200), () {
      if (_micDangNghe && mounted) _batPhienNgheMicChat();
    });
  }

  /// Hệ điều hành/engine tự ngắt phiên `listen()` sau một khoảng — y hệt
  /// trang soạn thảo chính (`_henBatLai`): nếu người dùng CHƯA tự tắt mic
  /// (`_micDangNghe` vẫn `true`), bật lại ngay một phiên MỚI, không coi là
  /// "đã tắt". Thấy ĐÚNG "notListening" mới bật lại — tránh vòng lặp vô ích
  /// nếu lỡ nhận nhầm trạng thái khác.
  ///
  /// (YÊU CẦU MỚI) Cập nhật `_micDangNgheThat` NGAY TẠI ĐÂY, đồng bộ với
  /// MỌI lần đổi trạng thái thật (cả "bắt đầu nghe" lẫn "ngừng nghe") — ĐÚNG
  /// khuôn `_TrangSoanThaoState._khiDoiTrangThai` (`_dangNghe`). UI (nút
  /// vuông đỏ) nhờ vậy tự ẩn/hiện đúng lúc hệ thống tự ngắt rồi tự bật lại,
  /// không còn đứng yên hiển thị sai suốt khoảng hở đó.
  void _khiMicDoiTrangThai(String trangThai) {
    final dangNghe = trangThai == SpeechToText.listeningStatus;
    widget.ghiNhatKyMicro?.call('[chat] onStatus: "$trangThai" (micDangNghe=$_micDangNghe)');
    if (mounted && _micDangNgheThat != dangNghe) {
      setState(() => _micDangNgheThat = dangNghe);
    }
    if (dangNghe || !mounted) return;
    if (!_micDangNghe) return; // người dùng đã tự bấm tắt — đừng bật lại.
    _lenLichBatLaiMicChat();
  }

  Future<void> _tatMicChat() async {
    _henTuTatMicChatImLang?.cancel();
    _henBatLaiMicChat?.cancel();
    _henGoXongMicChat?.cancel();
    _dangTamTatMicChatDeGo = false;
    // Tăng số phiên NGAY — mọi `onResult` còn đang trên đường về từ phiên
    // vừa tắt (kể cả tới trễ) bị vứt thẳng, không ghi đè gì vào bài nữa.
    _phienNgheMicChat++;
    // Đặt cờ `false` TRƯỚC khi gọi `stop()` — `stop()` kích `onStatus`
    // ("notListening") một cách KHÔNG đồng bộ; `_khiMicDoiTrangThai` đọc
    // đúng cờ này để quyết định có bật lại hay không, nên đặt sau dễ lọt
    // đúng khoảng hở đó, vô tình bật lại mic ngay sau khi người dùng tắt.
    if (mounted) {
      setState(() {
        _micDangNghe = false;
        _micDangNgheThat = false;
      });
    }
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

  /// (YÊU CẦU MỚI) "Thẻ ghi âm" cho kênh chat — bản ĐƠN GIẢN HOÁ của thẻ
  /// ghi âm ở trang soạn thảo chính (`the_ghi_am.dart`): không cần đánh số
  /// nhiều thẻ song song, không cần phát lại hay menu — thẻ ở đây chỉ
  /// sống qua 2 trạng thái liên tiếp (đang ghi → đang chuyển) rồi biến
  /// mất ngay khi có chữ, nên không cần cả bộ máy render phức tạp của
  /// trang chính. Token dạng `〔🎙️ Đang ghi âm #N〕`/`〔🎙️ Đang chuyển #N〕`
  /// được tô nền riêng bởi `_BoDieuKhienChat` (xem cuối tệp) — `_oNhap`
  /// dùng CHÍNH controller này thay `TextEditingController` thường.
  int _dinhDanhTheChoChuyenChatKeTiep = 0;
  // soThe (của `_KhungGhiAmChat`) -> id token hiện đang đại diện cho nó
  // trong `_oNhap.text` — một hộp thoại ghi âm có thể tạo NHIỀU thẻ liên
  // tiếp (phím "Tạo bản ghi âm mới"), mỗi thẻ một token riêng.
  final Map<int, int> _idTheChoChuyenChat = {};

  /// Chèn thẻ MỚI ("Đang ghi âm") tại đúng vị trí con trỏ — cùng cách tính
  /// dấu cách trước khi chèn với mic "vừa nói vừa ra chữ" ở trên.
  void _chenTheChoChuyenChat(int soThe) {
    if (!mounted) return;
    final id = ++_dinhDanhTheChoChuyenChatKeTiep;
    _idTheChoChuyenChat[soThe] = id;
    final token = '〔🎙️ Đang ghi âm #$id〕';
    final vb = _oNhap.text;
    final selection = _oNhap.selection;
    final viTri = selection.isValid ? selection.start : vb.length;
    final ketThuc = selection.isValid ? selection.end : viTri;
    final canDauCachTruoc = viTri > 0 && vb[viTri - 1] != ' ' && vb[viTri - 1] != '\n';
    final phanChen = canDauCachTruoc ? ' $token' : token;
    final moi = vb.replaceRange(viTri, ketThuc, phanChen);
    setState(() => _oNhap.text = moi);
    _oNhap.selection = TextSelection.collapsed(offset: viTri + phanChen.length);
  }

  /// Đổi nhãn thẻ của [soThe] từ "Đang ghi âm" sang "Đang chuyển" — vẫn
  /// giữ ĐÚNG id token cũ, chỉ sửa chữ.
  void _doiTheSangDangChuyen(int soThe) {
    if (!mounted) return;
    final id = _idTheChoChuyenChat[soThe];
    if (id == null) return;
    final cu = '〔🎙️ Đang ghi âm #$id〕';
    final moiLabel = '〔🎙️ Đang chuyển #$id〕';
    final vb = _oNhap.text;
    final i = vb.indexOf(cu);
    if (i == -1) return;
    final selCu = _oNhap.selection;
    setState(() => _oNhap.text = vb.replaceRange(i, i + cu.length, moiLabel));
    // Token mới dài hơn 1 ký tự ("ghi âm" dài hơn "chuyển") — dời con trỏ
    // theo đúng độ lệch nếu nó đang đứng NGAY SAU token (vị trí thường
    // gặp nhất: vừa chèn xong).
    if (selCu.isValid && selCu.baseOffset >= i + cu.length) {
      final lech = moiLabel.length - cu.length;
      _oNhap.selection = TextSelection.collapsed(offset: selCu.baseOffset + lech);
    }
  }

  /// Thay token (bất kể đang ở nhãn nào) bằng [chu] — gọi khi AI trả chữ
  /// xong. Không tìm thấy token (hiếm — người dùng tự xoá tay) thì rơi về
  /// hành vi cũ: chèn tại vị trí con trỏ hiện tại.
  void _hoanThanhTheChoChuyenChat(int soThe, String chu) {
    if (!mounted) return;
    final id = _idTheChoChuyenChat.remove(soThe);
    final vb = _oNhap.text;
    int? batDau, ketThuc;
    if (id != null) {
      for (final g in ['Đang ghi âm', 'Đang chuyển']) {
        final token = '〔🎙️ $g #$id〕';
        final i = vb.indexOf(token);
        if (i != -1) {
          batDau = i;
          ketThuc = i + token.length;
          break;
        }
      }
    }
    if (batDau == null || ketThuc == null) {
      _chenVanBanTaiConTroChat(chu);
      return;
    }
    final moi = vb.replaceRange(batDau, ketThuc, chu);
    setState(() => _oNhap.text = moi);
    _oNhap.selection = TextSelection.collapsed(offset: batDau + chu.length);
  }

  /// Xoá hẳn token của [soThe] (dùng khi bấm "Xoá bản này và Đóng" lúc thẻ
  /// CHƯA hoàn thành) hoặc khi chuyển hoá LỖI — không để kẹt lại mãi.
  void _xoaTheChoChuyenChat(int soThe) {
    if (mounted) {
      final id = _idTheChoChuyenChat.remove(soThe);
      if (id != null) {
        final vb = _oNhap.text;
        for (final g in ['Đang ghi âm', 'Đang chuyển']) {
          final token = '〔🎙️ $g #$id〕';
          final i = vb.indexOf(token);
          if (i != -1) {
            setState(() => _oNhap.text = vb.replaceRange(i, i + token.length, ''));
            _oNhap.selection = TextSelection.collapsed(offset: i);
            break;
          }
        }
      }
    }
    // (YÊU CẦU MỚI) Lưới an toàn — bấm "Xoá bản này và Đóng" quá nhanh có
    // lúc khiến tra `id` ở trên không khớp (lệch nhịp với lúc token được
    // ghi), để sót lại thẻ "đang ghi âm" ma trong ô nhập chat. Rà soát lại
    // sau 1 giây bằng chính HÌNH DẠNG token (không cần biết `id`) — còn sót
    // cái nào thì xoá nốt.
    Future.delayed(const Duration(seconds: 1), _raSoatVaXoaTheGhiAmConSotChat);
  }

  /// Xem giải thích ở [_xoaTheChoChuyenChat] — quét token "〔🎙️ Đang ghi âm
  /// #N〕" còn sót trong ô nhập chat (không dựa vào `id` đã lưu) rồi xoá.
  void _raSoatVaXoaTheGhiAmConSotChat() {
    if (!mounted) return;
    final vb = _oNhap.text;
    final m = RegExp('〔🎙️ Đang ghi âm #\\d+〕').firstMatch(vb);
    if (m == null) return;
    setState(() => _oNhap.text = vb.replaceRange(m.start, m.end, ''));
    _oNhap.selection = TextSelection.collapsed(offset: m.start);
  }

  /// (SỬA LỖI cũ) Chèn tại đúng vị trí con trỏ (hoặc thay vùng đang chọn)
  /// — dùng chung cho cả mic "vừa nói vừa ra chữ" và khi không tìm lại
  /// được token của thẻ ghi âm.
  void _chenVanBanTaiConTroChat(String chu) {
    final vb = _oNhap.text;
    final selection = _oNhap.selection;
    final viTri = selection.isValid ? selection.start : vb.length;
    final ketThuc = selection.isValid ? selection.end : viTri;
    final canDauCachTruoc = viTri > 0 && vb[viTri - 1] != ' ' && vb[viTri - 1] != '\n';
    final phanChen = canDauCachTruoc ? ' $chu' : chu;
    final moi = vb.replaceRange(viTri, ketThuc, phanChen);
    setState(() => _oNhap.text = moi);
    _oNhap.selection = TextSelection.collapsed(offset: viTri + phanChen.length);
  }

  Future<void> _moGhiAmChat() async {
    if (!mounted) return;
    setState(() => _ghiDangMo = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _KhungGhiAmChat(
        phimTatGhiAm: widget.caiDat.phimTatGhiAm,
        khiBatDauThe: _chenTheChoChuyenChat,
        khiHoanThanhGhiThe: _doiTheSangDangChuyen,
        khiCoVanBan: _hoanThanhTheChoChuyenChat,
        khiLoiChuyenHoa: _xoaTheChoChuyenChat,
        khiHuyThe: _xoaTheChoChuyenChat,
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
    _henGoXongMicChat?.cancel();
    if (_micDangNghe) _micro.stop();
    _oNhap.removeListener(_khiONhapDoi);
    _oNhap.dispose();
    _focusONhap.dispose();
    _cuon.dispose();
    _cuonONhap.dispose();
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
    // (YÊU CẦU MỚI) Giới hạn ký tự cho MỖI LẦN gửi tin nhắn — khác với
    // `_GioiHanKyTuChat` (chỉ chặn khung nhập không cho gõ/dán quá
    // 100.000 ký tự); đây là một mức thấp hơn, chặn hẳn việc GỬI nếu câu
    // hỏi người dùng tự gõ đã vượt quá 10.000 ký tự.
    if (cauHoi.length > 10000) {
      hienThongBaoGiua(
        context,
        'Tin nhắn vượt quá 10.000 ký tự - không thể gửi',
      );
      return;
    }
    _oNhap.clear();

    final laLuotDau = widget.lichSu.isEmpty;
    // Lượt đầu tiên của một cuộc trò chuyện MỚI vẫn LUÔN tự đính kèm toàn
    // văn nếu người dùng chưa tự chọn thẻ nào khác — giữ nguyên hành vi cũ.
    final dinhKem = _dinhKemHienTai != LoaiDinhKemTroChuyen.khong
        ? _dinhKemHienTai
        : (laLuotDau ? LoaiDinhKemTroChuyen.toanVan : LoaiDinhKemTroChuyen.khong);

    // (YÊU CẦU MỚI) Cùng giới hạn ký tự áp cho mọi mục "Làm việc với AI"
    // khác trong trang soạn thảo — áp cho phần văn bản ĐÍNH KÈM gửi theo
    // tin nhắn (khác với giới hạn 10.000 ký tự cho riêng câu hỏi tự gõ ở
    // trên).
    if (dinhKem == LoaiDinhKemTroChuyen.toanVan &&
        widget.layVanBanHienTai().length > 20000) {
      hienThongBaoGiua(
        context,
        'Toàn bộ văn bản vượt quá 20.000 ký tự - không thể sử dụng AI',
      );
      return;
    }
    if (dinhKem == LoaiDinhKemTroChuyen.doanChon &&
        (_noiDungDoanChonDinhKem ?? '').length > 10000) {
      hienThongBaoGiua(
        context,
        'Vùng chọn vượt quá 10.000 ký tự - không thể sử dụng AI',
      );
      return;
    }

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
        // (YÊU CẦU MỚI) Bỏ nút "Đóng" ở `actions` — thay bằng nút X đỏ gọn
        // gàng ở góc trên bên phải.
        title: Row(
          children: [
            Expanded(child: Text(tieuDe)),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Đóng',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(child: SelectableText(noiDung)),
          ),
        ),
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
                          focusNode: _focusONhap,
                          scrollController: _cuonONhap,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          // (YÊU CẦU MỚI) Chạm/tạo vùng chọn trong khung nhập
                          // cũng phải coi như một lượt "gõ tay" để thắng mic —
                          // kể cả khi con trỏ KHÔNG đổi vị trí (chạm đúng chỗ
                          // đang nhấp nháy) nên `_khiONhapDoi` (chỉ bắt được
                          // lúc `selection` thật sự đổi) không tự bắt ra.
                          // `onTap` của `TextField` luôn bắn sau MỖI lần chạm
                          // thật vào khung, dù con trỏ dời đi hay giữ y vị trí
                          // cũ.
                          onTap: () {
                            if (_micDangNghe || _dangTamTatMicChatDeGo) {
                              _nguoiDungVuaGoChat();
                            }
                          },
                          // (YÊU CẦU MỚI) Giới hạn 100.000 ký tự — dán đoạn
                          // dài hơn thì tự cắt bớt, kèm thông báo nhanh.
                          inputFormatters: [
                            _GioiHanKyTuChat(() {
                              if (mounted) {
                                hienThongBaoGiua(
                                  context,
                                  'Tin nhắn không được vượt quá 100.000 ký tự',
                                  ganTren: true,
                                );
                              }
                            }),
                          ],
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
                  // (YÊU CẦU MỚI) Nút Micro nổi ngay PHÍA TRÊN nút Gửi, mờ
                  // 50% nhưng vẫn bấm được — xem `_hienNutMicNoiChat`.
                  // (SỬA LỖI — "bấm vào không có tác dụng gì") Trước đây dùng
                  // `Stack` + `Positioned(bottom: 48, ...)` để nút nổi VƯỢT
                  // RA NGOÀI khung của nút Gửi — vẽ ra thì đúng (nhìn thấy),
                  // nhưng KHÔNG bấm được: `RenderBox.hitTest` (bước ĐẦU
                  // TIÊN `Stack` nhận được từ `Row` cha) chỉ kiểm điểm bấm
                  // có nằm trong kích thước CỦA CHÍNH Stack đó không — kích
                  // thước đó co theo đúng nút Gửi (nhỏ hơn hẳn), còn nút nổi
                  // nằm HOÀN TOÀN NGOÀI vùng đó nên never được hỏi tới, bất
                  // kể `clipBehavior: Clip.none` (chỉ ảnh hưởng việc VẼ, không
                  // ảnh hưởng việc TÍNH vùng bấm). Đổi qua `Column` xếp dọc
                  // thật — kích thước tự bao trọn cả hai nút, không còn phần
                  // nào "vượt khung" nữa, bấm được bình thường.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // (YÊU CẦU MỚI — TRẢ VỀ NHƯ CŨ) Nút nổi này hiện/ẩn chỉ
                      // phụ thuộc `_hienNutMicNoiChat` (đã bật Micro qua nút
                      // "+" ít nhất một lần trong phiên mở kênh chat này) —
                      // KHÔNG còn phụ thuộc việc mục Micro trong nút "+" có
                      // đang mờ xám (liệt) hay không.
                      //
                      // (YÊU CẦU MỚI) Trừ khi thiết bị không dùng được Micro
                      // kênh chat (web + iPhone, xem
                      // `_microChatDungDuocTrenThietBiNay`) — lúc đó nút nổi
                      // này thừa thãi hẳn, ẩn luôn, không cho hiện lên dù
                      // `_hienNutMicNoiChat` đã từng bật.
                      if (_hienNutMicNoiChat && _microChatDungDuocTrenThietBiNay)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Opacity(
                            opacity: 0.5,
                            child: _NutMicNoiChat(khiBam: _bamNutMicNoiChat),
                          ),
                        ),
                      _micDangNgheThat
                          ? _NutDungMic(khiBam: _tatMicChat)
                          : _NutGui(dangGui: _dangGui, khiBam: _guiHoacXacNhanSua),
                    ],
                  ),
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

/// (YÊU CẦU MỚI) Nút tròn nhỏ nổi phía trên nút Gửi — ĐÚNG hình dạng nút
/// Micro ở màn hình chính lúc CHƯA hoạt động (`_NutMicroTron` ở
/// `thanh_cong_cu.dart`: nền xanh lá nhạt, viền xanh dương đậm, 🎤), thu nhỏ
/// hơn một chút cho vừa chỗ nổi phía trên nút Gửi. Bấm vào gọi lại đúng
/// `_batMicChat()` — không có logic riêng nào khác.
class _NutMicNoiChat extends StatelessWidget {
  const _NutMicNoiChat({required this.khiBam});
  final VoidCallback khiBam;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Micro (vừa nói vừa ra chữ)',
      child: Material(
        color: Colors.green.shade100,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          onTapDown: (_) => khiBam(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade900, width: 2),
            ),
            alignment: Alignment.center,
            child: const Text('🎤', style: TextStyle(fontSize: 18)),
          ),
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

/// (YÊU CẦU MỚI) Bỏ các ký tự đánh dấu markdown-lite mà AI trả về (`#`/`##`/
/// `###` tiêu đề, `**đậm**`, `*nghiêng*`/`_nghiêng_`, `` `mã` ``, gạch đầu
/// dòng `- `/`* `) — CÙNG đúng những mẫu [_spanDongMarkdown]/[_spanDoanVanBan]
/// dùng để hiển thị, chỉ khác là ở đây BỎ hẳn ký tự đánh dấu thay vì áp kiểu
/// chữ — giữ lại đúng chữ thô bên trong. Dùng khi Sao chép tin nhắn AI
/// (`_TinNhanAi`), để bộ nhớ đệm không dính ký tự định dạng ngầm.
String _boDinhDangMarkdownNgam(String vanBan) {
  return vanBan.split('\n').map((dong) {
    var d = dong;
    final de = RegExp(r'^(\s*)#{1,3}\s+').firstMatch(d);
    if (de != null) d = '${de.group(1)}${d.substring(de.end)}';
    d = d.replaceFirstMapped(RegExp(r'^(\s*)[-*]\s+'), (m) => '${m.group(1)}• ');
    d = d.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|_(.+?)_|`(.+?)`'),
      (m) => m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4) ?? '',
    );
    return d;
  }).join('\n');
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
            onTap: () => _saoChep(context, _boDinhDangMarkdownNgam(chu)),
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
  const _KhungGhiAmChat({
    required this.phimTatGhiAm,
    required this.khiBatDauThe,
    required this.khiHoanThanhGhiThe,
    required this.khiCoVanBan,
    required this.khiLoiChuyenHoa,
    required this.khiHuyThe,
  });
  final LuaChonPhimTat phimTatGhiAm;

  /// (YÊU CẦU MỚI) Gọi NGAY lúc một thẻ BẮT ĐẦU ghi (mở hộp thoại, hoặc
  /// bấm "Hoàn thành và Tạo bản ghi âm mới") — nơi gọi chèn ngay một "thẻ
  /// đang ghi âm" vào đúng vị trí con trỏ trong ô nhập chat.
  final void Function(int soThe) khiBatDauThe;

  /// Gọi NGAY lúc thẻ [soThe] DỪNG ghi và bắt đầu gửi AI chuyển hoá — nơi
  /// gọi đổi "thẻ đang ghi âm" (của đúng thẻ này) thành "thẻ đang chuyển".
  final void Function(int soThe) khiHoanThanhGhiThe;

  /// Gọi lại MỖI LẦN một thẻ vừa chuyển hoá XONG — nơi gọi (`_moGhiAmChat`)
  /// thay "thẻ đang chuyển" bằng chữ AI trả về.
  final void Function(int soThe, String chu) khiCoVanBan;

  /// Chuyển hoá LỖI — nơi gọi dọn hẳn "thẻ đang chuyển" của thẻ đó (không
  /// để kẹt lại mãi trong ô nhập).
  final void Function(int soThe) khiLoiChuyenHoa;

  /// Bấm "Xoá bản này và Đóng" trong khi thẻ [soThe] CHƯA hoàn thành (còn
  /// đang ghi) — nơi gọi xoá hẳn "thẻ đang ghi âm" của thẻ đó khỏi ô nhập.
  final void Function(int soThe) khiHuyThe;

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
    widget.khiBatDauThe(_soThe);
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
      if (chu.trim().isNotEmpty) {
        widget.khiCoVanBan(soThe, chu.trim());
      } else {
        widget.khiLoiChuyenHoa(soThe);
      }
    } catch (e) {
      widget.khiLoiChuyenHoa(soThe);
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
    widget.khiHoanThanhGhiThe(soTheVuaXong);
    final kq = await ghiAmTheKetThucThe();
    if (kq != null) {
      unawaited(_chuyenHoa(kq, soTheVuaXong));
    } else {
      widget.khiLoiChuyenHoa(soTheVuaXong);
    }

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
    widget.khiBatDauThe(_soThe);
    _chayDongHo();
  }

  Future<void> _xoaVaDong() async {
    if (_dangXuLy) return;
    setState(() => _dangXuLy = true);
    _dongHo?.cancel();
    // Thẻ hiện tại chưa hoàn thành (chưa gửi AI) — xoá hẳn "thẻ đang ghi
    // âm" của nó khỏi ô nhập chat, không để kẹt lại.
    widget.khiHuyThe(_soThe);
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
                  // (YÊU CẦU MỚI — nhánh thử nghiệm) "Tạm dừng" không nhấp
                  // nháy — xem giải thích ở `_NhapNhayGioiHanGhiAm` (trang
                  // soạn thảo chính).
                  giay: _dangTamDung ? 0 : _thoiLuong.inSeconds,
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

/// (YÊU CẦU MỚI) Controller riêng cho ô nhập chat — tô nền cho "thẻ ghi
/// âm" (token `〔🎙️ Đang ghi âm #N〕`/`〔🎙️ Đang chuyển #N〕`, xem
/// `_ManHinhTroChuyenState._chenTheChoChuyenChat`) và ngăn người dùng
/// đứng/xoá lẻ TỪNG KÝ TỰ bên trong token — chỉ xoá được nguyên cả token
/// (phím Backspace ngay sau nó) hoặc để code tự thay nguyên token bằng
/// chữ AI trả về. Đơn giản hơn NHIỀU so với bộ máy "thẻ ghi âm" của trang
/// soạn thảo chính vì thẻ ở đây không cần phát lại, không cần menu, và
/// chỉ sống qua đúng 2 trạng thái liên tiếp rồi biến mất ngay khi có chữ.
/// (YÊU CẦU MỚI) Chặn khung nhập chat vượt quá 100.000 ký tự — dán một
/// đoạn dài hơn thì tự cắt bớt (giữ đúng 100.000 ký tự đầu), gọi
/// [khiVuotGioiHan] đúng một lần cho lần cắt đó (hoãn qua
/// `addPostFrameCallback` — không gọi `Overlay`/`showDialog` ngay giữa lúc
/// khung hình đang build từ `TextInputFormatter`).
class _GioiHanKyTuChat extends TextInputFormatter {
  _GioiHanKyTuChat(this.khiVuotGioiHan);

  static const gioiHanKyTu = 100000;

  final VoidCallback khiVuotGioiHan;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length <= gioiHanKyTu) return newValue;
    WidgetsBinding.instance.addPostFrameCallback((_) => khiVuotGioiHan());
    return TextEditingValue(
      text: newValue.text.substring(0, gioiHanKyTu),
      selection: TextSelection.collapsed(offset: gioiHanKyTu),
    );
  }
}

class _BoDieuKhienChat extends TextEditingController {
  static final RegExp _reThe = RegExp('〔🎙️ (?:Đang ghi âm|Đang chuyển) #(\\d+)〕');

  @override
  set selection(TextSelection newSelection) {
    super.selection = _naRaKhoiThe(newSelection);
  }

  /// Không cho một selection RỖNG (con trỏ nhấp nháy, không bôi đen gì)
  /// đứng NGAY GIỮA một token — đẩy ra biên gần nhất (trái hoặc phải, tuỳ
  /// bên nào gần hơn).
  TextSelection _naRaKhoiThe(TextSelection sel) {
    if (!sel.isValid || !sel.isCollapsed) return sel;
    final s = text;
    for (final m in _reThe.allMatches(s)) {
      final o = sel.baseOffset;
      if (o > m.start && o < m.end) {
        final bien = (o - m.start) <= (m.end - o) ? m.start : m.end;
        return TextSelection.collapsed(offset: bien);
      }
    }
    return sel;
  }

  @override
  set value(TextEditingValue newValue) {
    final cu = text;
    // Backspace/Delete làm MẤT ĐÚNG 1 KÝ TỰ ngay sát một biên token — coi
    // như đang muốn xoá nguyên token đó, không để sứt mẻ còn lại nửa token
    // vô nghĩa giữa văn bản.
    if (newValue.text.length == cu.length - 1 && newValue.selection.isCollapsed) {
      for (final m in _reThe.allMatches(cu)) {
        // Backspace ngay sau token (con trỏ đứng ở m.end, xoá ký tự cuối).
        if (newValue.selection.baseOffset == m.end - 1 &&
            cu.substring(0, m.end - 1) + cu.substring(m.end) == newValue.text) {
          super.value = TextEditingValue(
            text: cu.replaceRange(m.start, m.end, ''),
            selection: TextSelection.collapsed(offset: m.start),
          );
          return;
        }
        // Delete ngay trước token (con trỏ đứng ở m.start, xoá ký tự đầu).
        if (newValue.selection.baseOffset == m.start &&
            cu.substring(0, m.start) + cu.substring(m.start + 1) == newValue.text) {
          super.value = TextEditingValue(
            text: cu.replaceRange(m.start, m.end, ''),
            selection: TextSelection.collapsed(offset: m.start),
          );
          return;
        }
      }
    }
    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final s = text;
    final matches = _reThe.allMatches(s).toList();
    if (matches.isEmpty) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    final spans = <TextSpan>[];
    var vt = 0;
    for (final m in matches) {
      if (m.start > vt) spans.add(TextSpan(text: s.substring(vt, m.start), style: style));
      spans.add(TextSpan(
        text: s.substring(m.start, m.end),
        style: (style ?? const TextStyle()).copyWith(
          backgroundColor: const Color(0xFFE1BEE7),
          color: Colors.purple.shade900,
          fontWeight: FontWeight.w600,
        ),
      ));
      vt = m.end;
    }
    if (vt < s.length) spans.add(TextSpan(text: s.substring(vt), style: style));
    return TextSpan(style: style, children: spans);
  }
}
