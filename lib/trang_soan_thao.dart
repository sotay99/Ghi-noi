// Trang soạn thảo — một trang văn bản trắng, gõ phím và nói bằng micro cùng
// lúc. Mọi chữ — dù đến từ bàn phím hay từ micro — đều rơi vào đúng vị trí
// con trỏ. Micro không tắt khi người dùng gõ phím; ngược lại, gõ phím ngắt
// hẳn micro trong một giây rồi tự bật lại.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'cai_dat.dart';
import 'ghi_am_ai.dart';
import 'kho_du_lieu.dart';
import 'kiem_tra_chinh_ta.dart';
import 'kiem_tra_toan_van.dart';
import 'man_hinh_cai_dat.dart';
import 'man_hinh_thu_muc.dart';
import 'mo_hinh.dart';
import 'thanh_cong_cu.dart';
import 'thong_bao_giua.dart';
import 'trang_huong_dan.dart';

/// Một vùng chữ AI cho là "không phù hợp" (câu từ lủng củng, lạc đề, thừa ý,
/// lặp lại, quá nhiều lỗi chính tả, hoặc nên thay bằng đoạn khác hay hơn).
/// Đoạn GỐC [batDauGoc, ketThucGoc) và đoạn ĐỀ XUẤT [batDauDeXuat,
/// ketThucDeXuat) đều là chữ THẬT nằm trong văn bản — đoạn đề xuất được chèn
/// ngay sau đoạn gốc lúc áp dụng kết quả AI, "nằm cạnh nhau" đúng như yêu cầu.
class _VungKhongPhuHop {
  _VungKhongPhuHop({
    required this.batDauGoc,
    required this.ketThucGoc,
    required this.batDauDeXuat,
    required this.ketThucDeXuat,
  });

  int batDauGoc;
  int ketThucGoc;
  int batDauDeXuat;
  int ketThucDeXuat;

  /// null = còn chờ người dùng quyết định (gốc đỏ gạch giữa, đề xuất xanh
  /// gạch chân, đề xuất bấm được). 'xanh'/'do' = đã quyết định, đang nhấp
  /// nháy giữa màu đó và màu chữ thường trong 4 giây trước khi hoá chữ đen.
  String? nhapNhayMau;
  bool sangMau = true;
  Timer? henNhapNhay;
}

/// Một vùng chữ AI đề xuất xoá hẳn.
class _VungCanXoa {
  _VungCanXoa({required this.batDau, required this.ketThuc});

  int batDau;
  int ketThuc;
  bool dangNhapNhay = false;
  bool sangMau = true;
  Timer? henNhapNhay;
}

/// Một khoảng chữ cần vẽ với kiểu riêng — bước trung gian để gộp cả ba nguồn
/// (lỗi chính tả, đoạn không phù hợp, đoạn cần xoá) thành một danh sách duy
/// nhất trước khi dựng TextSpan.
class _VungVe {
  _VungVe({required this.batDau, required this.ketThuc, this.style, this.recognizer});
  final int batDau;
  final int ketThuc;
  final TextStyle? style;
  final GestureRecognizer? recognizer;
}

/// Một mục kết quả "Kiểm tra toàn văn", gắn kèm vị trí gốc để sắp xếp và áp
/// dụng lần lượt theo đúng thứ tự xuất hiện trong bài.
sealed class _MucToanVan {
  const _MucToanVan(this.viTri);
  final int viTri;
}

class _MucChinhTaToanVan extends _MucToanVan {
  _MucChinhTaToanVan(this.goc) : super(goc.viTri);
  final ChinhTaMuc goc;
}

class _MucKhongPhuHopToanVan extends _MucToanVan {
  _MucKhongPhuHopToanVan(this.goc) : super(goc.viTri);
  final KhongPhuHopMuc goc;
}

class _MucCanXoaToanVan extends _MucToanVan {
  _MucCanXoaToanVan(this.goc) : super(goc.viTri);
  final CanXoaMuc goc;
}

/// Màu và độ đậm gạch chân đỏ dưới từ/cụm từ sai chính tả — vẽ ở một
/// CustomPainter riêng (`_veGachChanLoiChinhTa` trong TrangSoanThao), không
/// còn gắn qua TextStyle.decoration nữa. Độ đậm 4 gấp đôi mức cũ (2), theo
/// yêu cầu, nhìn rõ hơn hẳn.
const _mauGachChanLoi = Colors.red;
const _damGachChanLoi = 4.0;

/// Vẽ một đường lượn sóng đỏ dưới mỗi hộp toạ độ trong [hop] — mỗi hộp ứng
/// với một dòng của một từ/cụm từ AI báo sai chính tả (một cụm dài bị ngắt
/// dòng thì có nhiều hộp, mỗi dòng một đường sóng riêng).
class _VeGachChanLoiChinhTa extends CustomPainter {
  _VeGachChanLoiChinhTa(this.hop);
  final List<Rect> hop;

  @override
  void paint(Canvas canvas, Size size) {
    final ve = Paint()
      ..color = _mauGachChanLoi
      ..strokeWidth = _damGachChanLoi
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const buocSong = 6.0;
    const bienDo = 2.5;
    for (final h in hop) {
      final y = h.bottom - 1;
      final duong = Path()..moveTo(h.left, y);
      var x = h.left;
      var xuong = true;
      while (x < h.right) {
        final xTiep = (x + buocSong).clamp(h.left, h.right);
        duong.quadraticBezierTo(
          x + (xTiep - x) / 2,
          y + (xuong ? bienDo : -bienDo),
          xTiep,
          y,
        );
        x = xTiep;
        xuong = !xuong;
      }
      canvas.drawPath(duong, ve);
    }
  }

  @override
  bool shouldRepaint(covariant _VeGachChanLoiChinhTa cu) => true;
}

/// Bộ điều khiển ô văn bản riêng — vẽ mọi đánh dấu AI ngay trong văn bản:
/// gạch đỏ dưới từ/cụm sai chính tả, đoạn không phù hợp (đỏ, gạch giữa thân)
/// cạnh đoạn đề xuất thay thế (xanh, gạch chân), và đoạn đề xuất xoá (đỏ,
/// gạch giữa thân). Việc vẽ diễn ra ngay trong `buildTextSpan` — cách duy
/// nhất chèn định dạng riêng cho từng đoạn vào một `TextField` đang gõ được.
class _BoDieuKhienChinhTa extends TextEditingController {
  _BoDieuKhienChinhTa({super.text});

  /// Ba danh sách dưới đây là NGUỒN DUY NHẤT của sự thật — trang soạn thảo
  /// sửa trực tiếp rồi gọi `notifyListeners()` để vẽ lại, không giữ bản sao.
  final List<LoiChinhTa> loi = [];
  final List<_VungKhongPhuHop> khongPhuHop = [];
  final List<_VungCanXoa> canXoa = [];

  void Function(LoiChinhTa loi, Offset viTriManHinh)? khiBamTuSai;
  void Function(_VungKhongPhuHop vung, Offset viTriManHinh)? khiBamDoanKhongPhuHop;
  void Function(_VungCanXoa vung, Offset viTriManHinh)? khiBamDoanCanXoa;

  /// `notifyListeners()` được đánh dấu @protected trong ChangeNotifier — bọc
  /// lại một hàm công khai để trang soạn thảo gọi vẽ lại sau khi tự tay sửa
  /// trực tiếp `loi`/`khongPhuHop`/`canXoa` mà không đi qua đường đổi `text`.
  void veLai() => notifyListeners();

  @override
  void dispose() {
    for (final k in khongPhuHop) {
      k.henNhapNhay?.cancel();
    }
    for (final x in canXoa) {
      x.henNhapNhay?.cancel();
    }
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final vb = text;
    if (vb.isEmpty) return TextSpan(style: style, text: vb);

    final vung = <_VungVe>[];

    for (final l in loi) {
      if (l.batDau < 0 || l.ketThuc > vb.length || l.batDau >= l.ketThuc) continue;
      // KHÔNG gắn kiểu gạch chân ở đây nữa — gạch chân đỏ giờ được vẽ ở một
      // lớp RIÊNG, nằm DƯỚI lớp chữ (xem `_veGachChanLoiChinhTa` ở
      // TrangSoanThao), để những nét đi xuống của chữ (g, ệ, ụ, q, y...) đè
      // lên được gạch chân thay vì bị gạch chân che mất. Ở đây chỉ còn giữ
      // vùng bắt chạm để mở menu đề xuất.
      vung.add(_VungVe(
        batDau: l.batDau,
        ketThuc: l.ketThuc,
        recognizer: TapGestureRecognizer()
          ..onTapDown = (ct) => khiBamTuSai?.call(l, ct.globalPosition),
      ));
    }

    for (final k in khongPhuHop) {
      if (k.batDauGoc < 0 || k.ketThucDeXuat > vb.length) continue;
      if (k.nhapNhayMau == null) {
        if (k.batDauGoc < k.ketThucGoc) {
          vung.add(_VungVe(
            batDau: k.batDauGoc,
            ketThuc: k.ketThucGoc,
            style: TextStyle(
              color: Colors.red.shade700,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.red.shade700,
              decorationThickness: 2,
            ),
          ));
        }
        if (k.batDauDeXuat < k.ketThucDeXuat) {
          vung.add(_VungVe(
            batDau: k.batDauDeXuat,
            ketThuc: k.ketThucDeXuat,
            style: TextStyle(
              color: Colors.blue.shade700,
              decoration: TextDecoration.underline,
              decorationColor: Colors.blue.shade700,
              decorationThickness: 2,
            ),
            recognizer: TapGestureRecognizer()
              ..onTapDown = (ct) => khiBamDoanKhongPhuHop?.call(k, ct.globalPosition),
          ));
        }
      } else if (k.sangMau) {
        final laXanh = k.nhapNhayMau == 'xanh';
        final batDau = laXanh ? k.batDauDeXuat : k.batDauGoc;
        final ketThuc = laXanh ? k.ketThucDeXuat : k.ketThucGoc;
        if (batDau < ketThuc && ketThuc <= vb.length) {
          vung.add(_VungVe(
            batDau: batDau,
            ketThuc: ketThuc,
            style: TextStyle(color: laXanh ? Colors.blue.shade700 : Colors.red.shade700),
          ));
        }
      }
      // sangMau == false trong lúc nhấp nháy: không thêm gì, chữ hiện màu mặc định.
    }

    for (final x in canXoa) {
      if (x.batDau < 0 || x.ketThuc > vb.length || x.batDau >= x.ketThuc) continue;
      if (!x.dangNhapNhay) {
        vung.add(_VungVe(
          batDau: x.batDau,
          ketThuc: x.ketThuc,
          style: TextStyle(
            color: Colors.red.shade700,
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.red.shade700,
            decorationThickness: 2,
          ),
          recognizer: TapGestureRecognizer()
            ..onTapDown = (ct) => khiBamDoanCanXoa?.call(x, ct.globalPosition),
        ));
      } else if (x.sangMau) {
        vung.add(_VungVe(
          batDau: x.batDau,
          ketThuc: x.ketThuc,
          style: TextStyle(color: Colors.red.shade700),
        ));
      }
    }

    vung.sort((a, b) => a.batDau.compareTo(b.batDau));

    final children = <InlineSpan>[];
    var vt = 0;
    for (final v in vung) {
      if (v.batDau < vt) continue; // Chồng lấn với vùng đã vẽ trước — bỏ qua.
      if (v.batDau > vt) children.add(TextSpan(text: vb.substring(vt, v.batDau)));
      children.add(TextSpan(text: vb.substring(v.batDau, v.ketThuc), style: v.style, recognizer: v.recognizer));
      vt = v.ketThuc;
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

  /// Đang hiện dòng chữ chú thích dọc bên trên từng nút của thanh công cụ
  /// hay không — bật bằng nút "i" (chỉ xuất hiện khi micro tắt), hoặc tự bật
  /// khi vừa mở một ghi chú còn trống trơn. Tắt bằng bất kỳ thao tác nào:
  /// chạm màn hình ở bất cứ đâu, hoặc gõ bất kỳ phím nào trên bàn phím rời.
  bool _hienChuThich = false;

  /// Chụp lại trạng thái NGAY TRƯỚC khi bị `_tatChuThich()` tắt đi — nút "i"
  /// cần biết trạng thái này để đảo (toggle) đúng, vì bản thân cú chạm vào
  /// nút "i" cũng đi qua `_tatChuThich()` trước (Listener bọc quanh `body`
  /// bắt sự kiện chạm xuống trước khi onTap của nút kịp chạy).
  bool _hienChuThichTruocKhiTat = false;

  void _tatChuThich() {
    if (_hienChuThich) {
      _hienChuThichTruocKhiTat = true;
      if (mounted) setState(() => _hienChuThich = false);
    } else {
      _hienChuThichTruocKhiTat = false;
    }
  }

  /// Bấm nút "i" thì ĐẢO trạng thái chú thích — đang tắt thì bật lên, đang
  /// hiện thì tắt đi (đúng như mọi thao tác khác trên màn hình).
  void _khiBamChuThich() {
    setState(() => _hienChuThich = !_hienChuThichTruocKhiTat);
  }

  /// Micro đang bật mà im lặng quá lâu (không thêm được chữ nào, dù do nói
  /// hay do gõ tay) thì tự tắt HẲN — không tự bật lại như các cơ chế khác,
  /// người dùng phải tự bấm nút hoặc phím tắt mới nghe lại. Số phút lấy từ
  /// Cài đặt (widget.caiDat.thoiGianTuTatMicroGiay).
  Timer? _henTuTatMicroImLang;

  /// Chấm tròn tím cuối văn bản mờ đi còn 35% trong lúc CÒN ĐANG có ký tự
  /// mới xuất hiện (gõ tay hay do nói ra đều tính) — im hẳn 4 giây không
  /// thêm ký tự nào nữa thì mới sáng rõ 100% trở lại. Mỗi ký tự mới xuất
  /// hiện thì hẹn giờ này lại được đặt lại từ đầu.
  bool _chamCuoiMoDam = false;
  Timer? _henMoDamChamCuoi;

  void _batDauMoDamChamCuoi() {
    if (!_chamCuoiMoDam && mounted) setState(() => _chamCuoiMoDam = true);
    _henMoDamChamCuoi?.cancel();
    _henMoDamChamCuoi = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _chamCuoiMoDam = false);
    });
  }

  /// Mấy mức âm gần nhất, để vẽ sóng. Mới nhất nằm ở cuối.
  final List<double> _songAm = List<double>.filled(16, 0);

  /// Vị trí bắt đầu của câu đang đọc dở, và ĐÚNG đoạn chữ tạm đã chèn ở đó.
  ///
  /// Giữ nguyên văn đoạn chữ chứ không chỉ giữ độ dài: trước mỗi lần ghi, ta
  /// đọc lại trong bài xem đoạn đó còn nguyên ở chỗ cũ không. Còn thì đè lên,
  /// không còn thì coi như câu mới. Nhờ vậy mốc có lệch cũng không lặp chữ.
  int _neo = 0;
  String _chuTam = '';

  /// Đúng nguyên văn `recognizedWords` (chưa chèn dấu cách nào của ta) của
  /// lần cập nhật gần nhất đã CHẤP NHẬN cho đoạn đang đọc dở — dùng để chặn
  /// bộ nhận dạng quay lại rút ngắn/sửa chữ đã hiện lên màn hình (xem
  /// `_khiCoChu`). Luôn coi là rỗng bất cứ khi nào `_chuTam` rỗng (đoạn mới).
  String _noiGocDaKhoa = '';

  /// Số lần liên tiếp một kết quả tạm bị TỪ CHỐI (xem `_khiCoChu`) vì không
  /// nối dài đúng phần đã khoá. Chỉ chặn tối đa MỘT lần liên tiếp — bộ nhận
  /// dạng thỉnh thoảng "nghĩ lại" một lần rồi thôi thì chặn được cái đó,
  /// nhưng nếu nó cứ liên tục trả về khác hẳn (ví dụ autoPunctuation viết
  /// lại nguyên câu khi có thêm ngữ cảnh), chặn mãi sẽ làm sóng âm vẫn chạy
  /// mà không ra chữ nào cả — bắt buộc phải nhượng bộ sau lần từ chối đầu.
  int _soLanTuChoiLienTuc = 0;

  static bool _laKhoangTrang(String kyTu) =>
      kyTu == ' ' || kyTu == '\n' || kyTu == '\t';

  /// Năm dấu câu tự động "nhảy" qua trước một dấu cách có sẵn khi gõ tay —
  /// xem chỗ dùng trong `_apDungChinhSuaNguoiDung`.
  static const _kyTuDacBiet = {'.', ',', ';', '?', '!', ':'};

  /// Kiểu chữ của ô soạn thảo — dùng chung cho cả TextField thật lẫn
  /// TextPainter đo vị trí ký tự cuối (`_chamCuoiVanBan`).
  ///
  /// `inherit: false` KHÔNG PHẢI để trang trí — nếu để mặc định (`true`),
  /// Material tự trộn thêm kiểu chữ của theme (ví dụ letterSpacing) vào
  /// TextField lúc vẽ THẬT, nhưng TextPainter đo ở `_chamCuoiVanBan` không hề
  /// biết chuyện trộn đó nên đo theo đúng mỗi `_kieuVanBan` trần trụi — hai
  /// bên ra hai độ rộng chữ khác nhau, càng lệch dần theo từng ký tự, khiến
  /// chấm tròn trôi dần ra khỏi vị trí thật khi câu càng dài. Khoá cứng bằng
  /// `inherit: false` (kèm đủ màu chữ, vì lúc đó không còn gì để kế thừa)
  /// thì TextField dùng ĐÚNG y hệt kiểu chữ này, không trộn thêm gì — khớp
  /// tuyệt đối với TextPainter.
  static const _kieuVanBan = TextStyle(
    fontSize: 17,
    height: 1.5,
    color: Color(0xFF1F1F1F),
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    inherit: false,
  );

  /// Khoá của chính TextField và của Stack bọc ngoài nó — `_chamCuoiVanBan`
  /// dùng hai khoá này để tìm thẳng `RenderEditable` THẬT đang vẽ ô soạn
  /// thảo, thay vì tự đo lại bằng một `TextPainter` riêng.
  final _oVanBanKey = GlobalKey();
  final _khungVanBanKey = GlobalKey();

  /// Dò xuống cây RenderObject tìm `RenderEditable` — chính là render object
  /// mà `TextField` dùng để vẽ chữ và đặt con trỏ thật. `visitChildren` không
  /// có cách dừng giữa chừng nên vẫn duyệt hết, nhưng `??=` đảm bảo chỉ giữ
  /// kết quả tìm thấy ĐẦU TIÊN.
  RenderEditable? _timRenderEditable(RenderObject o) {
    if (o is RenderEditable) return o;
    RenderEditable? ket;
    o.visitChildren((con) => ket ??= _timRenderEditable(con));
    return ket;
  }

  /// Chữ gợi ý hiện khi bài còn trống trơn — thay cho `InputDecoration
  /// .hintText` (chỉ nhận chuỗi trần) vì cần chèn một icon "?" tròn NGAY
  /// GIỮA câu, y hệt icon nút Hướng dẫn ở thanh công cụ ngang
  /// (`Icons.help_outline_rounded`), không phải ký tự Unicode giả icon.
  Widget _goiYTrong() {
    if (_boDieuKhien.text.isNotEmpty) return const SizedBox.shrink();
    const mauChuMo = Color(0xFF9E9E9E);
    return const RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 17, height: 1.5, color: mauChuMo),
        children: [
          TextSpan(
            text: 'Gõ chữ và bấm Micro để nói...\n'
                'Thực hiện song song hai việc trên cùng lúc.\n'
                'Vui lòng đọc hướng dẫn và mẹo sử dụng App (Nút ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.help_outline_rounded, size: 16, color: mauChuMo),
          ),
          TextSpan(text: ' )'),
        ],
      ),
    );
  }

  /// Chấm tròn tím báo hiệu cuối văn bản, luôn bám sát ngay sau ký tự cuối
  /// cùng.
  ///
  /// Lần trước dùng một `TextPainter` riêng để tự đo lại vị trí — tưởng đo
  /// đúng kiểu chữ là khớp, nhưng NHIỀU thứ khác có thể âm thầm làm hai bên
  /// đo ra kết quả khác nhau (hệ số phóng chữ của hệ điều hành, đệm bên
  /// trong TextField, cách bẻ dòng...), sai một chút thôi là dồn lại thành
  /// lệch hẳn khi câu dài. Thay vì đoán tiếp xem còn thiếu gì, HỎI THẲNG
  /// chính `RenderEditable` (render object THẬT đang vẽ con trỏ) xem con trỏ
  /// cuối văn bản nằm ở đâu — `getLocalRectForCaret` là hàm nội bộ Flutter
  /// dùng để tự vẽ con trỏ thật, nên tuyệt đối khớp, không còn gì để lệch.
  Widget _chamCuoiVanBan() {
    final chu = _boDieuKhien.text;
    if (chu.isEmpty) return const SizedBox.shrink();

    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    final khungBox = _khungVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null || khungBox is! RenderBox || !khungBox.hasSize) {
      return const SizedBox.shrink();
    }
    final re = _timRenderEditable(hopVanBan);
    if (re == null || !re.hasSize) return const SizedBox.shrink();

    const duongKinh = 17.0;
    Rect goc;
    Offset diem;
    try {
      goc = re.getLocalRectForCaret(TextPosition(offset: chu.length));
      diem = re.localToGlobal(goc.topLeft, ancestor: khungBox);
    } catch (_) {
      // Render object vừa đổi kích thước giữa chừng (xoay màn hình, bàn phím
      // ảo mở/đóng) — bỏ qua khung hình này, AnimatedBuilder sẽ tự vẽ lại
      // ngay khi ổn định.
      return const SizedBox.shrink();
    }

    return Positioned(
      left: diem.dx + 2,
      top: diem.dy + (goc.height - duongKinh) / 2,
      child: AnimatedOpacity(
        opacity: _chamCuoiMoDam ? 0.35 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: duongKinh,
          height: duongKinh,
          decoration: const BoxDecoration(
            color: Color(0xFF6A1B9A),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  /// Gạch chân đỏ, lượn sóng, dưới mỗi từ/cụm từ AI báo sai chính tả — vẽ ở
  /// một lớp RIÊNG nằm DƯỚI chữ (xem giải thích ở nơi ghép layer trong
  /// `build`), thay vì gắn qua TextStyle.decoration như trước. TextStyle
  /// .decoration vẽ CÙNG một lượt với chữ nên có lúc đè lên cả nét đi xuống
  /// của chữ (g, ệ, ụ, q, y...) — tách thành lớp riêng, vẽ trước rồi để chữ
  /// vẽ đè lên sau, thì nét đi xuống luôn luôn nổi trên gạch chân, không bao
  /// giờ bị che.
  ///
  /// Dùng `RenderEditable.getBoxesForSelection` (cùng kỹ thuật với
  /// `_chamCuoiVanBan`) để lấy đúng toạ độ THẬT của từng từ sai — kể cả khi
  /// một cụm từ sai bị ngắt xuống hai dòng, hàm này tự trả về nhiều hộp,
  /// mỗi dòng một hộp.
  Widget _gachChanLoiChinhTa() {
    if (_boDieuKhien.loi.isEmpty) return const SizedBox.shrink();

    final hopVanBan = _oVanBanKey.currentContext?.findRenderObject();
    final khungBox = _khungVanBanKey.currentContext?.findRenderObject();
    if (hopVanBan == null || khungBox is! RenderBox || !khungBox.hasSize) {
      return const SizedBox.shrink();
    }
    final re = _timRenderEditable(hopVanBan);
    if (re == null || !re.hasSize) return const SizedBox.shrink();

    final vb = _boDieuKhien.text;
    final hop = <Rect>[];
    for (final l in _boDieuKhien.loi) {
      if (l.batDau < 0 || l.ketThuc > vb.length || l.batDau >= l.ketThuc) continue;
      try {
        for (final h in re.getBoxesForSelection(
          TextSelection(baseOffset: l.batDau, extentOffset: l.ketThuc),
        )) {
          hop.add(Rect.fromPoints(
            re.localToGlobal(Offset(h.left, h.top), ancestor: khungBox),
            re.localToGlobal(Offset(h.right, h.bottom), ancestor: khungBox),
          ));
        }
      } catch (_) {
        // Bỏ qua từ này ở khung hình hiện tại — AnimatedBuilder sẽ tự vẽ lại.
      }
    }
    if (hop.isEmpty) return const SizedBox.shrink();

    return CustomPaint(painter: _VeGachChanLoiChinhTa(hop));
  }

  /// Lịch sử Lùi lại/Tiến tới. Mỗi điểm mốc là trạng thái TRỌN VẸN của bài
  /// (chữ + vị trí con trỏ) tại một ranh giới có ý nghĩa — KHÔNG phải từng
  /// ký tự một. Ranh giới đó là: bắt đầu một đợt gõ tay mới
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

  /// Số phiên nghe — tăng mỗi lần `_batMicro()` chạy, dùng để loại kết quả
  /// trễ của một phiên nghe đã đóng. Xem giải thích đầy đủ trong `_batMicro`.
  int _phienNgheHienTai = 0;

  /// Micro đang tắt vì người dùng gõ phím, chứ không phải vì họ bấm nút tắt.
  /// Phân biệt hai chuyện này mới biết có được tự bật lại hay không.
  bool _microNgungDeGo = false;

  /// Đang ở giữa một "đợt gõ tay" cho mục đích Lùi lại/Tiến tới hay không —
  /// độc lập hẳn với việc micro có tự bật lại hay không (người dùng có thể
  /// chọn "Không tự động bật lại Micro" mà vẫn cần ranh giới riêng cho gõ
  /// tay). Một đợt kết thúc sau 5 giây liên tục không gõ thêm gì.
  bool _dangTrongDotGoTay = false;
  Timer? _henRanhGioiGoTay;
  static const _thoiGianRanhGioiGoTay = Duration(seconds: 5);

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

  /// Từ/cụm từ người dùng đã tự tay xử lý xong (chấp nhận đề xuất, xoá, hoặc
  /// huỷ đề xuất) — AI không được báo lỗi lại những từ này nữa, dù có tìm
  /// thấy y hệt ở một đoạn khác hoặc ở lượt kiểm tra sau.
  final Set<String> _tuChinhTaDaXuLy = {};

  /// Đang có một lượt "Kiểm tra toàn văn bằng AI" chạy dở hay không — chặn
  /// bấm nút này thêm lần nữa trong lúc đang chờ.
  bool _dangKiemTraToanVan = false;
  final _dichVuToanVan = DichVuKiemTraToanVan();

  @override
  void initState() {
    super.initState();
    _ghiChuHienTai = widget.kho.timGhiChu(widget.ghiChuId)!;
    _tenController = TextEditingController(text: _ghiChuHienTai.ten);
    _oTen.addListener(_khiOTenMatFocus);

    WidgetsBinding.instance.addObserver(this);
    _boDieuKhien.addListener(_khiNguoiDungSua);
    _boDieuKhien.khiBamTuSai = _khiBamTuSai;
    _boDieuKhien.khiBamDoanKhongPhuHop = _khiBamDoanKhongPhuHop;
    _boDieuKhien.khiBamDoanCanXoa = _khiBamDoanCanXoa;

    final banDau = _ghiChuHienTai.noiDung;
    if (banDau.isNotEmpty) {
      _ghiVaoO(banDau, banDau.length);
    } else {
      // Ghi chú vừa tạo, chưa từng có ký tự nào — tự hiện chú thích ngay từ
      // đầu, y hệt như vừa bấm nút "i", để người dùng lần đầu biết mỗi nút
      // dùng để làm gì.
      _hienChuThich = true;
    }
    _neo = banDau.length;
    _viTriDaKiemTraChinhTa = banDau.length;

    _khoiTaoMicro();
    // Lắng nghe TOÀN CỤC (không phụ thuộc widget nào đang giữ tiêu điểm) —
    // phím tắt phải hoạt động kể cả đang gõ dở trong ô văn bản.
    HardwareKeyboard.instance.addHandler(_khiPhimTatMicro);
    HardwareKeyboard.instance.addHandler(_khiPhimTatLuiTien);
    HardwareKeyboard.instance.addHandler(_khiGoPhimBatKyTatChuThich);
  }

  /// Gõ BẤT KỲ phím nào trên bàn phím rời cũng tắt chú thích — không riêng gì
  /// chạm màn hình. Chỉ quan sát (luôn trả về false), không chặn phím đi
  /// tiếp xuống ô văn bản hay các phím tắt khác.
  bool _khiGoPhimBatKyTatChuThich(KeyEvent event) {
    if (event is KeyDownEvent) _tatChuThich();
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_khiPhimTatMicro);
    HardwareKeyboard.instance.removeHandler(_khiPhimTatLuiTien);
    HardwareKeyboard.instance.removeHandler(_khiGoPhimBatKyTatChuThich);
    WidgetsBinding.instance.removeObserver(this);
    _hen?.cancel();
    _henLuuTru?.cancel();
    _henGoXong?.cancel();
    _henChinhTa?.cancel();
    _henRanhGioiGoTay?.cancel();
    _henTuTatMicroImLang?.cancel();
    _henMoDamChamCuoi?.cancel();
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

  Future<void> _bamNutLuu() async {
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
          // Người dùng vừa tắt "kiểm tra chính tả bằng AI": xoá hết gạch đỏ
          // đang hiển thị ngay, vì đó là dữ liệu riêng của trang soạn thảo,
          // màn Cài đặt không cầm được.
          khiTatKiemTraChinhTa: () {
            _boDieuKhien.loi.clear();
            _boDieuKhien.veLai();
          },
          khiKiemTraLaiMicro: _khoiTaoMicro,
        ),
      ),
    );
    // Phím tắt có thể vừa đổi trong màn Cài đặt — vẽ lại nhãn hiện trên nút
    // micro cho khớp giá trị mới nhất.
    if (mounted) setState(() {});
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

    // Đánh số PHIÊN nghe — mỗi lần _batMicro() chạy (kể cả tự bật lại sau
    // khi hệ điều hành tự ngắt vì im lặng) là một phiên MỚI. `onResult` chỉ
    // nhận đúng phiên vừa đăng ký (so `idPhien` chụp lúc này với
    // `_phienNgheHienTai` tại thời điểm callback chạy); phiên cũ đóng rồi mà
    // vẫn có kết quả trễ bay về (bộ nhận dạng đôi khi trả thêm một kết quả
    // chốt cuối cùng sau khi đã coi như đã ngắt) thì bị vứt thẳng, không cho
    // nhập lại vào bài — đây chính là nguồn gốc lỗi thỉnh thoảng nhân đôi cả
    // một câu vừa nói xong: phiên mới đã coi đoạn đó là chữ THẬT rồi, kết
    // quả trễ của phiên cũ lại chèn thêm một lần nữa.
    final idPhien = ++_phienNgheHienTai;
    try {
      await _micro.listen(
        onResult: (ketQua) {
          if (idPhien != _phienNgheHienTai) return;
          _khiCoChu(ketQua);
        },
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
    _henTuTatMicroImLang?.cancel();
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
      _datLaiHenTuTatMicroImLang();
      // Cố ý gọi _batMicro() TRƯỚC: nó chạy đồng bộ tới tận await đầu tiên,
      // chốt xong đoạn tạm còn sót (nếu có) từ lượt nghe trước — rồi mới cho
      // _datNeoTaiConTro() đặt neo/vùng-tạm THẬT cho lượt nghe này. Gọi
      // ngược lại thì _chotCauDangDoc() bên trong _batMicro() sẽ xoá mất
      // ngay vùng đang chọn mà _datNeoTaiConTro() vừa chuẩn bị để đè lên.
      _batMicro();
      _datNeoTaiConTro();
    }
  }

  /// Bàn phím vật lý bấm đúng tổ hợp phím tắt đang cài (mặc định Ctrl + F):
  /// tắt/mở micro, y hệt bấm nút. Trả về true để chặn phím này lan xuống ô
  /// văn bản (không thì gõ Ctrl+F trong lúc soạn thảo cũng gõ luôn chữ "f").
  bool _khiPhimTatMicro(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;

    // Đang có màn hình khác đè lên (Cài đặt, Thư mục, Hướng dẫn...) thì
    // không xử lý ở đây — kẻo đang gõ thử phím tắt trong màn Cài đặt lại vô
    // tình tắt/mở luôn micro của trang soạn thảo bên dưới.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final dungBoBienDoi = widget.caiDat.phimTatBoBienDoi == 'Ctrl'
        ? HardwareKeyboard.instance.isControlPressed
        : HardwareKeyboard.instance.isAltPressed;
    if (!dungBoBienDoi) return false;

    if (event.logicalKey.keyLabel.toUpperCase() !=
        widget.caiDat.phimTatPhim.toUpperCase()) {
      return false;
    }

    _bamNutMicro();
    return true;
  }

  /// Ctrl + Z (Lùi lại) và Ctrl + Shift + Z (Tiến tới) — cố định, không cho
  /// người dùng đổi (khác phím tắt micro, có thể tuỳ chỉnh trong Cài đặt).
  bool _khiPhimTatLuiTien(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    if (!HardwareKeyboard.instance.isControlPressed) return false;
    if (event.logicalKey != LogicalKeyboardKey.keyZ) return false;

    if (HardwareKeyboard.instance.isShiftPressed) {
      if (_lichSuToi.isNotEmpty) _toi();
    } else {
      if (_lichSuLui.isNotEmpty) _lui();
    }
    return true;
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
    if (chon.isValid && !chon.isCollapsed) {
      // Đang chọn (tô đậm) một vùng — để giọng nói ĐÈ LÊN đúng vùng đó, y
      // hệt cách gõ tay đè lên vùng đang chọn. Đặt neo ở đầu vùng và coi
      // nguyên đoạn đang chọn là "vùng tạm" — lần nói đầu tiên sẽ tự động
      // thay thế nó qua đúng con đường `_thayVungTamBangGiongNoi` vẫn dùng.
      _neo = chon.start;
      _chuTam = _boDieuKhien.text.substring(chon.start, chon.end);
    } else {
      _neo = chon.isValid ? chon.end : _boDieuKhien.text.length;
      _chuTam = '';
    }
    _noiGocDaKhoa = '';
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
  /// lần giọng nói chèn hoặc sửa chữ tạm.
  void _thayVungTamBangGiongNoi(String chenVao) {
    final cu = _boDieuKhien.text;
    final het = _neo + _chuTam.length;
    final moi = cu.replaceRange(_neo, het, chenVao);

    _dieuChinhLoiChinhTaSauKhiSua(_neo, het - _neo, chenVao.length);
    _dieuChinhVungToanVanSauKhiSua(_neo, het - _neo, chenVao.length);

    final viTri = _neo + chenVao.length;
    _ghiVaoO(moi, viTri);
    _chuTam = chenVao;
    _chuGanNhat = moi; // Để lần _khiNguoiDungSua tiếp theo không hiểu nhầm.
    _batDauMoDamChamCuoi();
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

    // Chặn hồi tố: bộ nhận dạng thỉnh thoảng "nghĩ lại" và trả về một bản
    // NGẮN HƠN hoặc KHÁC HẲN cho cùng một đoạn đang đọc dở — nhìn như thể
    // micro tự quay lại sửa/xoá chữ đã hiện lên màn hình. Chữ đã hiện ra rồi
    // thì phải CHẾT CỨNG: chỉ chấp nhận cập nhật khi `noi` nối dài thêm đúng
    // từ phần đã khoá (`_noiGocDaKhoa`); coi như đoạn mới (`_chuTam` rỗng)
    // thì không có gì để khoá, chấp nhận bất cứ nội dung nào.
    //
    // Chỉ chặn tối đa MỘT lần liên tiếp (`_soLanTuChoiLienTuc`): nếu bộ nhận
    // dạng cứ liên tục trả về khác hẳn phần đã khoá (ví dụ autoPunctuation
    // viết lại nguyên câu khi có thêm ngữ cảnh), chặn mãi sẽ làm sóng âm vẫn
    // chạy mà không ra chữ nào cả — phải nhượng bộ sau lần từ chối đầu.
    final coBanDaKhoa = _chuTam.isEmpty ? '' : _noiGocDaKhoa;
    final chapNhan = noi.startsWith(coBanDaKhoa) || _soLanTuChoiLienTuc >= 1;
    if (chapNhan) {
      _soLanTuChoiLienTuc = 0;
      _noiGocDaKhoa = noi;

      var chen = noi;
      // Nếu ngay trước neo đã có chữ mà chưa có dấu cách, thêm một dấu cách
      // cho câu mới không dính vào câu cũ.
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

      if (chen != _chuTam) {
        // _chuTam rỗng nghĩa là đây là mẩu đầu tiên của một đoạn nói MỚI
        // (đoạn trước, nếu có, đã chốt xong và xoá _chuTam ở _chotCauDangDoc)
        // — đúng ranh giới cần lưu một điểm mốc Lùi lại riêng, để một bài dài
        // nói nhiều lần vẫn lùi được từng đoạn một, không gộp chung cả bài
        // thành một bước.
        if (_chuTam.isEmpty) {
          _luuDiemMoc(vanBan: cu, viTriConTro: _neo);
        }
        _thayVungTamBangGiongNoi(chen);
      }
    } else {
      _soLanTuChoiLienTuc++;
    }

    if (xong) {
      _chotCauDangDoc();
      _noiGocDaKhoa = '';
      _soLanTuChoiLienTuc = 0;
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

    // Vừa có thêm chữ (dù do nói hay gõ tay, mọi lần ghi đều qua đây) — huỷ
    // đếm ngược tự tắt micro vì im lặng, đặt lại từ đầu.
    if (_muonNghe) _datLaiHenTuTatMicroImLang();

    // Chữ vừa thêm vào cuối bài thì kéo màn hình xuống theo, để dòng mới nhất
    // luôn nằm trong tầm mắt.
    if (viTri >= chu.length) _cuonXuongDuoi();
  }

  /// Đặt lại (hoặc bắt đầu) đếm ngược tự tắt hẳn micro nếu không có thêm chữ
  /// nào — gọi mỗi khi có chữ mới VÀ mỗi khi micro vừa bật, để khoảng lặng
  /// được tính từ đúng lúc bật micro, không phải chờ có chữ đầu tiên mới bắt
  /// đầu đếm.
  void _datLaiHenTuTatMicroImLang() {
    _henTuTatMicroImLang?.cancel();
    _henTuTatMicroImLang = Timer(
      Duration(seconds: widget.caiDat.thoiGianTuTatMicroGiay),
      () {
        if (_muonNghe) _tatMicro();
      },
    );
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
    _datLaiHenTuTatMicroImLang();
    _batMicro(); // Xem giải thích thứ tự gọi trong _bamNutMicro().
    _datNeoTaiConTro();
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

  /// Người dùng gõ phím hoặc bấm để dời con trỏ. So khác biệt giữa chữ cũ
  /// (_chuGanNhat) và chữ mới để biết đúng vùng vừa đổi — cách này gộp được
  /// cả gõ chèn, xoá, và autocorrect của bàn phím thay nguyên một cụm chữ,
  /// vào cùng một logic duy nhất.
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

    // (b) Người dùng thật sự chạm màn hình để dời con trỏ — hoặc TÔ ĐẬM một
    // vùng trong lúc micro vẫn đang nghe. Trường hợp sau phải đặt neo/vùng
    // tạm lên đúng vùng vừa chọn (giống hệt lúc bấm micro với sẵn vùng đã
    // chọn) thì câu nói tiếp theo mới đè lên được — trước đây chỉ có
    // `_bamNutMicro()`/`_batLaiSauKhiGoXong()` gọi `_datNeoTaiConTro()`, nên
    // chọn vùng khi micro ĐÃ bật sẵn (không qua hai hàm đó) bị bỏ sót.
    if (_muonNghe && !chon.isCollapsed) {
      _dongBangDoanDangNhay();
      _datNeoTaiConTro();
      return;
    }
    _neo = chon.end;
    _dongBangDoanDangNhay();
  }

  void _apDungChinhSuaNguoiDung(String chuMoi) {
    // Gõ tay chèn ký tự cũng phải tắt chú thích, y hệt bấm phím rời hay chạm
    // màn hình — bắt ngay tại đây (chữ THẬT SỰ đổi) thay vì chỉ trông chờ
    // bắt được sự kiện bàn phím vật lý, vì trường hợp CHỮ ĐẦU TIÊN của một
    // ghi chú vừa tạo còn trống trơn có lúc không đi qua đúng đường bắt phím
    // đó (autofocus + khung còn đang dựng dở lúc gõ quá nhanh).
    _tatChuThich();
    _batDauMoDamChamCuoi();

    // Chỉ lưu điểm mốc vào LẦN GÕ ĐẦU TIÊN của một đợt — một đợt kết thúc
    // sau 5 giây liên tục không gõ thêm gì (xem _dangTrongDotGoTay). Độc lập
    // hẳn với việc micro có tự bật lại hay không.
    //
    // Truyền tay _chuGanNhat (chữ CŨ) và _neo (vị trí con trỏ CŨ): bộ điều
    // khiển tại đây đã mang chữ MỚI rồi, tự đọc _boDieuKhien.text sẽ chụp
    // nhầm đúng cái vừa gõ, không lùi được.
    if (!_dangTrongDotGoTay) {
      _luuDiemMoc(vanBan: _chuGanNhat, viTriConTro: _neo);
      _dangTrongDotGoTay = true;
    }
    _henRanhGioiGoTay?.cancel();
    _henRanhGioiGoTay = Timer(_thoiGianRanhGioiGoTay, () {
      _dangTrongDotGoTay = false;
    });

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
    final soLuongXoa = cu.length - dau - duoi;
    _dieuChinhLoiChinhTaSauKhiSua(dau, soLuongXoa, doDaiChenVao);
    _dieuChinhVungToanVanSauKhiSua(dau, soLuongXoa, doDaiChenVao);

    // Gõ đúng MỘT ký tự đặc biệt (. , ; ? !) ngay sau một dấu cách có sẵn —
    // hoán đổi hai ký tự đó cho nhau, để dấu câu nằm sát vào chữ trước nó
    // thay vì kẹt sau dấu cách: "abc |" gõ "." thành "abc. |", con trỏ vẫn
    // đứng nguyên vị trí (chỉ đổi chỗ hai ký tự liền kề, độ dài không đổi).
    var chuMoiCuoi = chuMoi;
    if (soLuongXoa == 0 &&
        doDaiChenVao == 1 &&
        dau > 0 &&
        cu[dau - 1] == ' ' &&
        _kyTuDacBiet.contains(chuMoi[dau])) {
      chuMoiCuoi = chuMoi.substring(0, dau - 1) + chuMoi[dau] + ' ' + chuMoi.substring(dau + 1);
    }

    final chon = _boDieuKhien.selection;
    final viTriConTro = chon.isValid ? chon.end : chuMoiCuoi.length;

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
    scheduleMicrotask(_boDieuKhien.veLai);
  }

  /// Y hệt [_dieuChinhLoiChinhTaSauKhiSua] nhưng cho hai danh sách của lượt
  /// "Kiểm tra toàn văn": dời vùng nằm sau, bỏ vùng chồng lấn vào chỗ vừa
  /// sửa. [boQua] dùng khi CHÍNH thao tác đang xử lý một vùng gây ra sự thay
  /// đổi này (ví dụ chèn/xoá chữ của chính nó) — đừng tự bỏ nó khỏi danh
  /// sách của chính nó.
  void _dieuChinhVungToanVanSauKhiSua(int vitri, int soXoa, int soChen, {Object? boQua}) {
    if (soXoa == 0 && soChen == 0) return;
    final ketThucXoa = vitri + soXoa;
    final lech = soChen - soXoa;

    for (final k in List<_VungKhongPhuHop>.of(_boDieuKhien.khongPhuHop)) {
      if (identical(k, boQua)) continue;
      var bo = false;
      if (k.batDauGoc >= ketThucXoa) {
        k.batDauGoc += lech;
        k.ketThucGoc += lech;
      } else if (k.ketThucGoc > vitri) {
        bo = true;
      }
      if (!bo) {
        if (k.batDauDeXuat >= ketThucXoa) {
          k.batDauDeXuat += lech;
          k.ketThucDeXuat += lech;
        } else if (k.ketThucDeXuat > vitri) {
          bo = true;
        }
      }
      if (bo) {
        k.henNhapNhay?.cancel();
        _boDieuKhien.khongPhuHop.remove(k);
      }
    }

    for (final x in List<_VungCanXoa>.of(_boDieuKhien.canXoa)) {
      if (identical(x, boQua)) continue;
      if (x.batDau >= ketThucXoa) {
        x.batDau += lech;
        x.ketThuc += lech;
      } else if (x.ketThuc > vitri) {
        x.henNhapNhay?.cancel();
        _boDieuKhien.canXoa.remove(x);
      }
    }

    scheduleMicrotask(_boDieuKhien.veLai);
  }

  /// Hẹn giờ gọi AI kiểm tra chính tả, dồn nhiều thay đổi liên tiếp (gõ từng
  /// phím, hay từng phần câu nói dội về) lại thành một lần gọi duy nhất khi
  /// mọi thứ đã tạm lắng — đúng lúc "vừa ra xong một câu văn mới".
  void _lenLichKiemTraChinhTa() {
    if (!widget.caiDat.kiemTraChinhTaBangAI) return;
    _henChinhTa?.cancel();
    _henChinhTa = Timer(const Duration(milliseconds: 900), _kiemTraChinhTaMoi);
  }

  /// Số ký tự văn bản NGAY TRƯỚC đoạn mới, gửi kèm làm ngữ cảnh cho AI — đủ
  /// dài để bao được vài đoạn văn trước đó (không phải một câu cộc lốc, cũng
  /// không phải toàn bộ bài).
  static const _doDaiNguCanhChinhTa = 800;

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
    final dauNguCanh = (tuViTri - _doDaiNguCanhChinhTa).clamp(0, tuViTri);
    final nguCanh = vanBan.substring(dauNguCanh, tuViTri);

    List<LoiChinhTa> loiMoi;
    try {
      loiMoi = await _dichVuChinhTa.kiemTra(doan, nguCanh: nguCanh);
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

    // Từ/cụm từ người dùng đã tự tay xử lý (chấp nhận đề xuất, xoá, hoặc huỷ
    // đề xuất) trước đó thì không báo lỗi lại nữa, dù AI có tìm thấy y hệt.
    final loiChuaXuLy =
        loiMoi.where((l) => !_tuChinhTaDaXuLy.contains(l.tu));

    _boDieuKhien.loi.addAll(loiChuaXuLy.map((l) => l.dich(tuViTri)));
    _viTriDaKiemTraChinhTa = tuViTri + doan.length;
    _boDieuKhien.veLai();
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
    _luuDiemMoc();

    // Đã tự tay xử lý (chọn thay, xoá, hay huỷ) — đánh dấu để AI không báo
    // lại đúng từ/cụm từ này ở những lượt kiểm tra sau.
    _tuChinhTaDaXuLy.add(loi.tu);

    switch (chon.$1) {
      case 'thay':
        _apDungThayTheChinhTa(loi, chon.$2!);
      case 'xoa':
        _apDungThayTheChinhTa(loi, '');
      default: // 'huy'
        _boDieuKhien.loi.remove(loi);
        _boDieuKhien.veLai();
    }
  }

  /// Thay đúng vùng [loi.batDau, loi.ketThuc) bằng [thayBang] — dùng chung
  /// cho cả "chọn từ AI đề xuất" (thayBang là từ mới) và "Xoá" (thayBang
  /// rỗng).
  void _apDungThayTheChinhTa(LoiChinhTa loi, String thayBang) {
    final vb = _boDieuKhien.text;
    final conKhop = loi.ketThuc <= vb.length &&
        vb.substring(loi.batDau, loi.ketThuc) == loi.tu;
    if (!conKhop) {
      // Bài đã đổi từ lúc gạch đỏ này xuất hiện — bỏ đề xuất, không đụng gì
      // vào bài nữa vì không còn chắc đúng chỗ.
      _boDieuKhien.loi.remove(loi);
      _boDieuKhien.veLai();
      return;
    }

    final moi = vb.replaceRange(loi.batDau, loi.ketThuc, thayBang);
    _boDieuKhien.loi.remove(loi);
    _dieuChinhLoiChinhTaSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, thayBang.length);
    _dieuChinhVungToanVanSauKhiSua(loi.batDau, loi.ketThuc - loi.batDau, thayBang.length);

    final viTri = loi.batDau + thayBang.length;
    _neo = viTri;
    _ghiVaoO(moi, viTri);
    _henLuu();
  }

  // ---------------------------------------------------- ghi âm xong mới ra chữ

  /// Bấm nút "Ghi âm xong mới ra chữ": mở bảng ghi âm, chèn kết quả phiên âm
  /// vào đúng vị trí con trỏ nếu có. Việc ghi âm, gửi lên AI, chờ kết quả
  /// đều nằm trọn trong `moBangGhiAmAI` — ở đây chỉ lo phần chèn vào bài.
  Future<void> _khiBamGhiAmAI() async {
    final ketQua = await moBangGhiAmAI(context);
    if (ketQua == null || ketQua.trim().isEmpty || !mounted) return;
    _chenVanBanTuGhiAmAI(ketQua.trim());
  }

  /// Chèn văn bản mới vào đúng vị trí con trỏ, rồi cho nó nhấp nháy xanh/đen
  /// 4 giây trước khi hoá đen như chữ thường — dùng lại nguyên cơ chế nhấp
  /// nháy của "đoạn không phù hợp" (coi như đoạn GỐC rỗng, chỉ có đoạn ĐỀ
  /// XUẤT, và nhảy thẳng vào trạng thái "đã chọn dùng đề xuất").
  void _chenVanBanTuGhiAmAI(String vanBanMoi) {
    _luuDiemMoc();

    final vb = _boDieuKhien.text;
    final chon = _boDieuKhien.selection;
    final viTri = (chon.isValid ? chon.end : vb.length).clamp(0, vb.length);

    var chen = vanBanMoi;
    if (viTri > 0 && !_laKhoangTrang(vb[viTri - 1])) chen = ' $chen';
    if (viTri < vb.length && !_laKhoangTrang(vb[viTri])) chen = '$chen ';

    _dieuChinhVungToanVanSauKhiSua(viTri, 0, chen.length);
    _dieuChinhLoiChinhTaSauKhiSua(viTri, 0, chen.length);

    final moi = vb.replaceRange(viTri, viTri, chen);
    final viTriConTro = viTri + chen.length;
    _neo = viTriConTro;
    _ghiVaoO(moi, viTriConTro);
    _henLuu();

    final v = _VungKhongPhuHop(
      batDauGoc: viTri,
      ketThucGoc: viTri,
      batDauDeXuat: viTri,
      ketThucDeXuat: viTriConTro,
    );
    _boDieuKhien.khongPhuHop.add(v);
    _batNhapNhayKhongPhuHop(v, 'xanh');
  }

  // ------------------------------------------------- kiểm tra toàn văn bằng AI

  /// Bấm nút "Kiểm tra toàn văn bằng AI": gửi TOÀN BỘ văn bản hiện có lên
  /// máy chủ AI soát lại một lượt, trong lúc chờ hiện popup có thể bấm "Dừng
  /// ngay lập tức" để huỷ (kết quả về trễ vẫn bị vứt, không áp dụng gì cả).
  Future<void> _khiBamKiemTraToanVan() async {
    if (_dangKiemTraToanVan) return;
    final vanBan = _boDieuKhien.text;
    if (vanBan.trim().isEmpty) {
      _bao('Chưa có văn bản nào để kiểm tra.');
      return;
    }

    final daHuy = ValueNotifier<bool>(false);
    setState(() => _dangKiemTraToanVan = true);

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI đang kiểm tra lại toàn văn để soát lỗi chính tả - ngữ '
              'pháp, và đề xuất cách sửa đổi. Đây là bước quan trọng trước '
              'khi hoàn thiện văn bản.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.4),
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () {
                daHuy.value = true;
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
              child: const Text('Dừng ngay lập tức'),
            ),
          ),
        ],
      ),
    ));

    KetQuaKiemTraToanVan? ketQua;
    Object? loiXayRa;
    try {
      ketQua = await _dichVuToanVan.kiemTra(vanBan);
    } catch (e) {
      loiXayRa = e;
    }

    if (daHuy.value || !mounted) {
      if (mounted) setState(() => _dangKiemTraToanVan = false);
      return;
    }

    // Popup "đang kiểm tra" vẫn còn hiện (người dùng không bấm Dừng) — đóng
    // nó lại trước khi báo kết quả.
    Navigator.of(context, rootNavigator: true).pop();
    setState(() => _dangKiemTraToanVan = false);

    if (loiXayRa != null || ketQua == null) {
      _bao('Không kiểm tra được: $loiXayRa');
      return;
    }

    _apDungKetQuaToanVan(ketQua);
    _henLuu();
    _hienPopupXongTamThoi();
  }

  void _hienPopupXongTamThoi() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('AI đã trả về kết quả'),
            ],
          ),
        );
      },
    );
  }

  /// Đưa kết quả AI vào văn bản thật: từ/cụm sai chính tả gạch đỏ như bình
  /// thường; đoạn "không phù hợp" thì CHÈN đoạn đề xuất ngay sau đoạn gốc
  /// (một chữ thật nằm trong bài, không phải chữ ảo vẽ đè lên); đoạn "cần
  /// xoá" chỉ đánh dấu, chưa xoá gì. Xử lý theo đúng thứ tự vị trí gốc (từ
  /// đầu bài tới cuối), cộng dồn độ lệch mỗi lần chèn thêm chữ — không thì
  /// các mục đứng sau sẽ trỏ nhầm chỗ.
  void _apDungKetQuaToanVan(KetQuaKiemTraToanVan kq) {
    // Một điểm mốc DUY NHẤT trước khi áp cả loạt kết quả — Lùi lại một lần
    // là xoá sạch mọi đề xuất AI vừa thêm, trả bài về y như trước khi bấm
    // "Kiểm tra toàn văn bằng AI".
    _luuDiemMoc();

    final tatCa = <_MucToanVan>[
      for (final c in kq.chinhTa) _MucChinhTaToanVan(c),
      for (final k in kq.khongPhuHop) _MucKhongPhuHopToanVan(k),
      for (final x in kq.canXoa) _MucCanXoaToanVan(x),
    ]..sort((a, b) => a.viTri.compareTo(b.viTri));

    var lech = 0;
    for (final muc in tatCa) {
      final vb = _boDieuKhien.text;
      final viTriThuc = muc.viTri + lech;
      if (viTriThuc < 0 || viTriThuc > vb.length) continue;

      switch (muc) {
        case _MucChinhTaToanVan(:final goc):
          final ketThuc = viTriThuc + goc.tu.length;
          if (ketThuc > vb.length || vb.substring(viTriThuc, ketThuc) != goc.tu) continue;
          _boDieuKhien.loi.add(LoiChinhTa(
            batDau: viTriThuc,
            ketThuc: ketThuc,
            tu: goc.tu,
            deXuat: goc.deXuat,
          ));

        case _MucKhongPhuHopToanVan(:final goc):
          final ketThucGoc = viTriThuc + goc.doan.length;
          if (ketThucGoc > vb.length || vb.substring(viTriThuc, ketThucGoc) != goc.doan) continue;
          final moi = vb.replaceRange(ketThucGoc, ketThucGoc, goc.deXuat);
          final viTriConTro = ketThucGoc + goc.deXuat.length;
          _ghiVaoO(moi, viTriConTro);
          _boDieuKhien.khongPhuHop.add(_VungKhongPhuHop(
            batDauGoc: viTriThuc,
            ketThucGoc: ketThucGoc,
            batDauDeXuat: ketThucGoc,
            ketThucDeXuat: viTriConTro,
          ));
          lech += goc.deXuat.length;

        case _MucCanXoaToanVan(:final goc):
          final ketThuc = viTriThuc + goc.doan.length;
          if (ketThuc > vb.length || vb.substring(viTriThuc, ketThuc) != goc.doan) continue;
          _boDieuKhien.canXoa.add(_VungCanXoa(batDau: viTriThuc, ketThuc: ketThuc));
      }
    }

    _boDieuKhien.veLai();
  }

  /// Bắt đầu nhấp nháy 4 giây (đổi giữa [mau] và màu chữ thường, mỗi 250ms)
  /// rồi tự hoá chữ đen như bình thường, xoá luôn khỏi danh sách.
  void _batNhapNhayKhongPhuHop(_VungKhongPhuHop v, String mau) {
    v.nhapNhayMau = mau;
    v.sangMau = true;
    v.henNhapNhay?.cancel();
    var dem = 0;
    v.henNhapNhay = Timer.periodic(const Duration(milliseconds: 250), (t) {
      dem++;
      v.sangMau = !v.sangMau;
      if (dem >= 16) {
        t.cancel();
        _boDieuKhien.khongPhuHop.remove(v);
      }
      if (mounted) _boDieuKhien.veLai();
    });
    _boDieuKhien.veLai();
  }

  void _batNhapNhayCanXoa(_VungCanXoa x) {
    x.dangNhapNhay = true;
    x.sangMau = true;
    x.henNhapNhay?.cancel();
    var dem = 0;
    x.henNhapNhay = Timer.periodic(const Duration(milliseconds: 250), (t) {
      dem++;
      x.sangMau = !x.sangMau;
      if (dem >= 16) {
        t.cancel();
        _boDieuKhien.canXoa.remove(x);
      }
      if (mounted) _boDieuKhien.veLai();
    });
    _boDieuKhien.veLai();
  }

  /// Người dùng bấm vào đoạn ĐỀ XUẤT (xanh) cạnh một đoạn "không phù hợp".
  Future<void> _khiBamDoanKhongPhuHop(_VungKhongPhuHop v, Offset viTriManHinh) async {
    final chon = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: const [
        PopupMenuItem(value: 'dung', child: Text('Dùng đề xuất này')),
        PopupMenuItem(value: 'bo', child: Text('Bỏ đề xuất này và trả lại như cũ')),
      ],
    );
    if (chon == null || !mounted) return;
    if (!_boDieuKhien.khongPhuHop.contains(v)) return; // Văn bản đổi trong lúc mở menu.

    final vb = _boDieuKhien.text;
    if (v.ketThucDeXuat > vb.length) {
      _boDieuKhien.khongPhuHop.remove(v);
      _boDieuKhien.veLai();
      return;
    }

    _luuDiemMoc();

    if (chon == 'dung') {
      // Xoá đoạn GỐC, giữ đoạn ĐỀ XUẤT — cho đoạn đề xuất nhấp nháy xanh/đen.
      final doDaiGoc = v.ketThucGoc - v.batDauGoc;
      final moi = vb.replaceRange(v.batDauGoc, v.ketThucGoc, '');
      _dieuChinhLoiChinhTaSauKhiSua(v.batDauGoc, doDaiGoc, 0);
      _dieuChinhVungToanVanSauKhiSua(v.batDauGoc, doDaiGoc, 0, boQua: v);
      v.ketThucGoc = v.batDauGoc;
      v.batDauDeXuat -= doDaiGoc;
      v.ketThucDeXuat -= doDaiGoc;
      _ghiVaoO(moi, v.ketThucDeXuat);
      _henLuu();
      _batNhapNhayKhongPhuHop(v, 'xanh');
    } else {
      // Xoá đoạn ĐỀ XUẤT, giữ đoạn GỐC — cho đoạn gốc nhấp nháy đỏ/đen.
      final doDaiDeXuat = v.ketThucDeXuat - v.batDauDeXuat;
      final moi = vb.replaceRange(v.batDauDeXuat, v.ketThucDeXuat, '');
      _dieuChinhLoiChinhTaSauKhiSua(v.batDauDeXuat, doDaiDeXuat, 0);
      _dieuChinhVungToanVanSauKhiSua(v.batDauDeXuat, doDaiDeXuat, 0, boQua: v);
      v.batDauDeXuat = v.ketThucDeXuat = v.ketThucGoc;
      _ghiVaoO(moi, v.ketThucGoc);
      _henLuu();
      _batNhapNhayKhongPhuHop(v, 'do');
    }
  }

  /// Người dùng bấm vào một đoạn AI đề xuất xoá.
  Future<void> _khiBamDoanCanXoa(_VungCanXoa x, Offset viTriManHinh) async {
    final chon = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        viTriManHinh.dx,
        viTriManHinh.dy,
        viTriManHinh.dx,
        viTriManHinh.dy,
      ),
      items: const [
        PopupMenuItem(value: 'xoa', child: Text('Chấp nhận xoá đoạn văn này')),
        PopupMenuItem(value: 'khoiphuc', child: Text('Khôi phục đoạn văn này — không xoá')),
      ],
    );
    if (chon == null || !mounted) return;
    if (!_boDieuKhien.canXoa.contains(x)) return;

    _luuDiemMoc();

    if (chon == 'xoa') {
      final vb = _boDieuKhien.text;
      if (x.ketThuc > vb.length) {
        _boDieuKhien.canXoa.remove(x);
        _boDieuKhien.veLai();
        return;
      }
      final doDai = x.ketThuc - x.batDau;
      final moi = vb.replaceRange(x.batDau, x.ketThuc, '');
      _dieuChinhLoiChinhTaSauKhiSua(x.batDau, doDai, 0);
      _dieuChinhVungToanVanSauKhiSua(x.batDau, doDai, 0, boQua: x);
      _boDieuKhien.canXoa.remove(x);
      _ghiVaoO(moi, x.batDau);
      _henLuu();
      _bao('Đã xoá đoạn văn.');
    } else {
      _batNhapNhayCanXoa(x);
    }
  }

  // ----------------------------------------------------------- lùi/tiến tới

  /// Đóng gói trạng thái hiện tại (chữ + con trỏ + mọi đánh dấu AI đang
  /// hiển thị) thành một điểm mốc. Chỉ giữ lại những đề xuất AI CÒN ĐANG CHỜ
  /// quyết định (`nhapNhayMau == null` / `!dangNhapNhay`) — mục nào đang
  /// nhấp nháy sau khi vừa quyết định chỉ là hiệu ứng thoáng qua 4 giây, tự
  /// biến mất dù có Lùi/Tiến hay không, nên không cần lưu lại nguyên trạng
  /// hoạt ảnh của nó.
  _TrangThaiVanBan _chupTrangThai({required String vanBan, required int viTriConTro}) {
    return _TrangThaiVanBan(
      vanBan: vanBan,
      viTriConTro: viTriConTro,
      loi: List<LoiChinhTa>.from(_boDieuKhien.loi),
      khongPhuHop: [
        for (final k in _boDieuKhien.khongPhuHop)
          if (k.nhapNhayMau == null)
            _MocVungKhongPhuHop(
              batDauGoc: k.batDauGoc,
              ketThucGoc: k.ketThucGoc,
              batDauDeXuat: k.batDauDeXuat,
              ketThucDeXuat: k.ketThucDeXuat,
            ),
      ],
      canXoa: [
        for (final x in _boDieuKhien.canXoa)
          if (!x.dangNhapNhay) _MocVungCanXoa(batDau: x.batDau, ketThuc: x.ketThuc),
      ],
    );
  }

  /// Chụp lại trọn vẹn trạng thái NGAY TRƯỚC một đợt gõ/nói/hành động sắp
  /// diễn ra. Bỏ qua nếu chữ chưa đổi gì so với điểm mốc gần nhất (tránh
  /// những điểm mốc thừa, ví dụ micro thử bật lại liên tiếp do lỗi mạng).
  ///
  /// Nhận tham số tường minh thay vì tự đọc `_boDieuKhien.text` — ở nơi gọi
  /// từ `_apDungChinhSuaNguoiDung`, bộ điều khiển đã mang chữ MỚI (đã gõ
  /// xong) từ trước khi hàm đó kịp chạy dòng nào, nên phải truyền tay chữ CŨ
  /// (`_chuGanNhat`) vào mới chụp đúng trạng thái ngay TRƯỚC đợt gõ này.
  void _luuDiemMoc({String? vanBan, int? viTriConTro}) {
    final vb = vanBan ?? _boDieuKhien.text;
    if (_lichSuLui.isNotEmpty && _lichSuLui.last.vanBan == vb) return;
    setState(() {
      _lichSuLui.add(_chupTrangThai(
        vanBan: vb,
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
    _lichSuToi.add(_chupTrangThai(
      vanBan: _boDieuKhien.text,
      viTriConTro: _viTriConTroHienTai(),
    ));
    final truoc = _lichSuLui.removeLast();
    // setState trần NGAY tại đây (không đợi _apDungTrangThai) — nút Lùi/Tiến
    // trên AppBar phải phản ánh đúng độ dài hai danh sách vừa đổi ngay lập
    // tức, kẻo bấm liên tiếp trước khi khung hình kịp vẽ lại sẽ tưởng nút
    // chưa hoạt động.
    setState(() {});
    _apDungTrangThai(truoc);
  }

  void _toi() {
    if (_lichSuToi.isEmpty) return;
    _lichSuLui.add(_chupTrangThai(
      vanBan: _boDieuKhien.text,
      viTriConTro: _viTriConTroHienTai(),
    ));
    final sau = _lichSuToi.removeLast();
    setState(() {});
    _apDungTrangThai(sau);
  }

  void _apDungTrangThai(_TrangThaiVanBan tt) {
    // An toàn trước: đừng để một kết quả giọng nói còn treo ghi đè lên đúng
    // lúc vừa khôi phục xong.
    if (_muonNghe) _tatMicro();
    _chuTam = '';
    _neo = tt.viTriConTro.clamp(0, tt.vanBan.length);

    // Huỷ mọi hẹn giờ nhấp nháy đang chạy trước khi thay hẳn ba danh sách.
    for (final k in _boDieuKhien.khongPhuHop) {
      k.henNhapNhay?.cancel();
    }
    for (final x in _boDieuKhien.canXoa) {
      x.henNhapNhay?.cancel();
    }

    _boDieuKhien.loi
      ..clear()
      ..addAll(tt.loi);
    _boDieuKhien.khongPhuHop
      ..clear()
      ..addAll(tt.khongPhuHop.map((m) => _VungKhongPhuHop(
            batDauGoc: m.batDauGoc,
            ketThucGoc: m.ketThucGoc,
            batDauDeXuat: m.batDauDeXuat,
            ketThucDeXuat: m.ketThucDeXuat,
          )));
    _boDieuKhien.canXoa
      ..clear()
      ..addAll(tt.canXoa.map((m) => _VungCanXoa(batDau: m.batDau, ketThuc: m.ketThuc)));

    // setState trần: buộc vẽ lại AppBar để nút Lùi/Tiến bật/tắt đúng theo độ
    // dài _lichSuLui/_lichSuToi vừa đổi (bản thân chúng không tự kích rebuild).
    setState(() {});

    _henChinhTa?.cancel();
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
          'Toàn bộ văn bản đang soạn sẽ bị xoá ngay. Vẫn có thể bấm "Lùi '
          'lại" ở thanh trên để khôi phục lại nếu xoá nhầm.',
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

    _luuDiemMoc();

    // Trả mọi mốc về vạch xuất phát, nếu không thì câu nói kế tiếp lại nhắm
    // vào một vị trí không còn tồn tại.
    _ghiVaoO('', 0);
    _neo = 0;
    _chuTam = '';
    _henChinhTa?.cancel();
    _boDieuKhien.loi.clear();
    for (final k in _boDieuKhien.khongPhuHop) {
      k.henNhapNhay?.cancel();
    }
    _boDieuKhien.khongPhuHop.clear();
    for (final x in _boDieuKhien.canXoa) {
      x.henNhapNhay?.cancel();
    }
    _boDieuKhien.canXoa.clear();
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
          tooltip: 'Lùi lại (Ctrl + Z)',
        ),
        IconButton(
          onPressed: _lichSuToi.isEmpty ? null : _toi,
          icon: const Icon(Icons.redo),
          tooltip: 'Tiến tới (Ctrl + Shift + Z)',
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
      // translucent: chỉ NGHE sự kiện chạm để tắt chú thích, không chặn nó
      // đi tiếp xuống nút/ô bên dưới — một cú bấm vừa tắt chú thích vừa làm
      // đúng việc của nút đó (mở cài đặt, bật micro...).
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _tatChuThich(),
        child: SafeArea(
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
                child: Stack(
                      key: _khungVanBanKey,
                      children: [
                        // Chữ gợi ý khi bài còn trống trơn — tự tay dựng
                        // thay cho InputDecoration.hintText mặc định, vì
                        // hintText chỉ nhận chuỗi trần, không chèn được icon
                        // "?" tròn y hệt icon nút Hướng dẫn vào giữa câu.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _boDieuKhien,
                              builder: (context, _) => _goiYTrong(),
                            ),
                          ),
                        ),
                        // Gạch chân đỏ lỗi chính tả — cố ý đặt TRƯỚC (dưới)
                        // TextField trong danh sách con của Stack, để lớp
                        // chữ của TextField vẽ ĐÈ LÊN sau đó, nét đi xuống
                        // của chữ (g, ệ, ụ, q, y...) nhờ vậy luôn nổi trên
                        // gạch chân thay vì bị nó che mất.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _boDieuKhien,
                              builder: (context, _) => Stack(
                                children: [_gachChanLoiChinhTa()],
                              ),
                            ),
                          ),
                        ),
                        TextField(
                          key: _oVanBanKey,
                          controller: _boDieuKhien,
                          focusNode: _oChu,
                          scrollController: _cuonVanBan,
                          maxLines: null,
                          expands: true,
                          autofocus: true,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: _kieuVanBan,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                        // Chấm tròn tím đánh dấu cuối văn bản — chỉ mang tính
                        // trang trí, KHÔNG phải một ký tự thật, nên con trỏ
                        // không bao giờ đứng được sau nó (vị trí xa nhất của
                        // con trỏ vẫn là cuối chuỗi thật, tức trước chấm này).
                        //
                        // Positioned.fill phải nằm NGAY DƯỚI Stack — Positioned
                        // là ParentDataWidget, chỉ áp dụng được khi cha trực
                        // tiếp của nó là Stack. `_chamCuoiVanBan` trả về một
                        // Positioned KHÁC (định vị chấm tròn); nó cần một Stack
                        // MỚI làm cha trực tiếp, nên bọc trong Stack con ở đây
                        // chứ không thả thẳng làm con của IgnorePointer/
                        // AnimatedBuilder — làm vậy Flutter báo lỗi "Incorrect
                        // use of ParentDataWidget" và cả khung soạn thảo hoá
                        // thành ô xám lỗi.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_boDieuKhien, _cuonVanBan]),
                              builder: (context, _) => Stack(
                                children: [_chamCuoiVanBan()],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            ThanhCongCu(
              bat: _muonNghe,
              dangNghe: _dangNghe,
              songAm: _songAm,
              sanSang: _sanSang,
              hienChuThich: _hienChuThich,
              khiBamChuThich: _khiBamChuThich,
              nhanPhimTat: '${widget.caiDat.phimTatBoBienDoi} + ${widget.caiDat.phimTatPhim}',
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
              khiBamKiemTraToanVan: _khiBamKiemTraToanVan,
              khiBamGhiAmAI: _khiBamGhiAmAI,
            ),
            SizedBox(height: caoBanPhim),
          ],
        ),
        ),
      ),
    );
  }
}

/// Một điểm mốc trong lịch sử Lùi lại/Tiến tới — chữ, vị trí con trỏ, và mọi
/// đề xuất AI (chính tả, không phù hợp, cần xoá) còn đang hiển thị/chờ quyết
/// định tại thời điểm đó.
class _TrangThaiVanBan {
  const _TrangThaiVanBan({
    required this.vanBan,
    required this.viTriConTro,
    required this.loi,
    required this.khongPhuHop,
    required this.canXoa,
  });

  final String vanBan;
  final int viTriConTro;
  final List<LoiChinhTa> loi;
  final List<_MocVungKhongPhuHop> khongPhuHop;
  final List<_MocVungCanXoa> canXoa;
}

/// Bản chụp "phẳng" của [_VungKhongPhuHop] — chỉ giữ vị trí, không giữ trạng
/// thái nhấp nháy hay hẹn giờ (những thứ đó thuộc về một lần hiển thị cụ
/// thể, không phải một phần của "dữ liệu" cần khôi phục).
class _MocVungKhongPhuHop {
  const _MocVungKhongPhuHop({
    required this.batDauGoc,
    required this.ketThucGoc,
    required this.batDauDeXuat,
    required this.ketThucDeXuat,
  });

  final int batDauGoc;
  final int ketThucGoc;
  final int batDauDeXuat;
  final int ketThucDeXuat;
}

/// Bản chụp "phẳng" của [_VungCanXoa].
class _MocVungCanXoa {
  const _MocVungCanXoa({required this.batDau, required this.ketThuc});

  final int batDau;
  final int ketThuc;
}
