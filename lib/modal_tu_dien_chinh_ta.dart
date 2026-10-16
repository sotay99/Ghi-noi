// Trang "Từ điển sửa lỗi chính tả của bạn" — mở từ menu "Tài khoản của
// bạn", ngay dưới "Cài đặt hiển thị và tự động sửa". Người dùng tự khai các
// cặp (từ hay gõ sai thường gặp / tối đa 3 từ thay vào) — app tự quét văn
// bản, gạch vàng lượn sóng những từ khớp (xem `_boDieuKhien.tuDien` trong
// trang_soan_thao.dart), bấm vào để thay/xoá. Công tắc ở đầu trang bật/tắt
// hẳn việc quét (không đụng tới việc xem/sửa danh sách bên dưới).
//
// TOÀN MÀN HÌNH (Navigator.push, có nút X đóng) — ĐÚNG KHUÔN
// `ManHinhTroChuyen` (màn hình chat với AI), không còn là modal đáy màn
// hình nhỏ như bản trước (người dùng chê "xấu quá").

import 'dart:async';

import 'package:flutter/material.dart';

import 'cai_dat.dart';
import 'dang_nhap_google.dart';
import 'thong_bao_giua.dart';
import 'tu_dien_dam_may.dart';

const _mauChinh = Color(0xFF1A73E8);

/// (YÊU CẦU MỚI) Giới hạn ký tự của MỖI trường (từ lỗi hay từ thay thế) —
/// public để nơi khác (ví dụ nút "Thêm vào từ điển sửa lỗi chính tả" khi có
/// vùng chọn, `trang_soan_thao.dart`) tự kiểm trước khi mở modal này, báo
/// đúng con số nếu vượt quá, không viết chết số `500` ở nơi thứ hai.
const gioiHanTuDienChinhTa = 500;

/// [noiDungCanDua]: (YÊU CẦU MỚI) có nội dung sẵn cần đưa ngay vào từ điển —
/// tự tìm/tạo một cặp RỖNG, điền nội dung đó vào trường "Từ bị lỗi chính tả
/// hay gặp" (dòng 1) của cặp đó, cuộn tới giữa màn hình, và nhấp nháy nền
/// vàng đậm vài giây để người dùng chú ý — xem `_dienNoiDungVaoCapRong`.
Future<void> moModalTuDienChinhTa(
  BuildContext context,
  CaiDat caiDat, {
  String? noiDungCanDua,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _ManHinhTuDienChinhTa(caiDat: caiDat, noiDungCanDua: noiDungCanDua),
    ),
  );
}

/// Một kết quả khớp của thanh tìm kiếm trong modal từ điển — [laLoi] phân
/// biệt dòng "Từ bị lỗi chính tả" ([chiSoThayThe] bỏ qua, luôn -1) với một
/// trong các dòng "Từ thay thế" (xác định bởi [chiSoThayThe]).
class _KetQuaTimTuDien {
  _KetQuaTimTuDien({
    required this.cap,
    required this.laLoi,
    required this.chiSoThayThe,
    required this.batDau,
    required this.ketThuc,
  });
  final CapTuDien cap;
  final bool laLoi;
  final int chiSoThayThe;
  final int batDau;
  final int ketThuc;
}

const _nhanThuThayThe = [
  'Từ thay thế vào thứ nhất',
  'Từ thay thế vào thứ hai',
  'Từ thay thế vào thứ ba',
];

class _ManHinhTuDienChinhTa extends StatefulWidget {
  const _ManHinhTuDienChinhTa({required this.caiDat, this.noiDungCanDua});
  final CaiDat caiDat;
  final String? noiDungCanDua;

  @override
  State<_ManHinhTuDienChinhTa> createState() => _ManHinhTuDienChinhTaState();
}

class _ManHinhTuDienChinhTaState extends State<_ManHinhTuDienChinhTa> {
  /// Tham chiếu THẬT tới `caiDat.tuDienChinhTa` — thêm/xoá thẳng vào đây là
  /// đã "lưu" cho cả app (trang soạn thảo đọc đúng danh sách này mỗi lần
  /// quét), chỉ cần gọi thêm `luuTuDienChinhTa()` để ghi xuống đĩa.
  late List<CapTuDien> _ds;
  final Map<CapTuDien, TextEditingController> _oLoi = {};

  /// Mỗi cặp có TỐI ĐA 3 ô — luôn có ít nhất ô "thứ nhất" (dù rỗng).
  final Map<CapTuDien, List<TextEditingController>> _oThayThe = {};

  /// (YÊU CẦU MỚI — tìm kiếm trong từ điển) Một `FocusNode` riêng cho MỖI ô
  /// (từ lỗi/từ thay thế) — cần để `_dieuHuongTimKiemTuDien` tự
  /// `requestFocus()` đúng ô có kết quả khớp rồi đặt `selection` lên đúng
  /// đoạn khớp, nhờ đó Flutter tự vẽ màu tô NỀN của chính selection đó lên
  /// đoạn ký tự khớp — y hệt cách trang soạn thảo chính giữ màu tô vùng
  /// chọn, không cần tự vẽ thêm painter riêng cho từng ô nhỏ rời rạc này.
  final Map<CapTuDien, FocusNode> _focusLoi = {};
  final Map<CapTuDien, List<FocusNode>> _focusThayThe = {};

  /// Cặp đang hiện cảnh báo "từ thay thế giống hệt từ lỗi" hoặc "từ lỗi bị
  /// trùng với một cặp khác" (mục 5) — vẽ viền đỏ + dòng chữ đỏ ngay dưới ô
  /// liên quan, không chặn gõ (chỉ chặn hoàn thành/rời ô, xem `_oNhap`).
  final Set<CapTuDien> _loiTrungThayThe = {};
  final Set<CapTuDien> _loiTrungTuLoi = {};

  Timer? _henLuu;

  /// (YÊU CẦU MỚI) Tự cuộn xuống cuối danh sách sau khi bấm "Thêm cặp từ"
  /// — cặp mới luôn được `_ds.add` vào CUỐI, nên người dùng thấy ngay cặp
  /// vừa sinh ra mà không cần tự cuộn tay.
  final _cuon = ScrollController();

  /// (YÊU CẦU MỚI) Một `GlobalKey` cho đầu mỗi cặp — dùng để cuộn tới ĐÚNG
  /// cặp đó (`Scrollable.ensureVisible`), cả khi cặp đã có từ trước lẫn cặp
  /// vừa thêm mới, xem `_themCap`.
  final Map<CapTuDien, GlobalKey> _khoaCap = {};

  /// (YÊU CẦU MỚI) Cặp vừa được điền sẵn nội dung từ vùng chọn
  /// ([_dienNoiDungVaoCapRong]) — dòng 1 (từ lỗi) của ĐÚNG cặp này nhấp
  /// nháy nền vàng đậm vài giây để người dùng chú ý, rồi tự tắt hẳn
  /// (`_capVuaThem = null`), không phải tô màu lâu dài.
  CapTuDien? _capVuaThem;
  bool _capVuaThemSang = true;
  Timer? _henNhapNhayCapMoi;

  // ------------------------------------------------- Tìm kiếm trong từ điển

  /// (YÊU CẦU MỚI) Thanh tìm kiếm riêng cho modal này — mở bằng nút kính
  /// lúp cạnh "+ Thêm cặp từ". Y khuôn thanh tìm kiếm ở trang soạn thảo
  /// chính (ô nhập, số kết quả, mũi tên lên/xuống, nút X xanh lá, nút Tắt
  /// đỏ) nhưng KHÔNG có thanh thay thế ở dưới.
  bool _hienThanhTimKiemTuDien = false;
  final _oTimKiemTuDien = TextEditingController();
  final _focusTimKiemTuDien = FocusNode();
  List<_KetQuaTimTuDien> _ketQuaTimTuDien = [];
  int _chiSoTimTuDienHienTai = -1;

  // --------------------------------------------- (YÊU CẦU MỚI) 2 bộ nhớ

  /// 'noiBo' hoặc 'damMay' — bộ nhớ ĐANG XEM/SỬA. Khởi tạo từ tab xem gần
  /// nhất đã lưu lâu dài (`CaiDat.tabNguonTuDienChinhTa`) — KHÔNG có quy
  /// tắc "tự suy ra từ công tắc đang bật" như từ điển nhập liệu nhanh, vì ở
  /// đây công tắc hai bên không loại trừ nhau (có thể cùng bật/cùng tắt).
  late String _tab;
  bool get _dangODamMay => _tab == 'damMay';

  /// Bản đám mây của tài khoản đang đăng nhập — `null` nếu chưa đăng nhập.
  TuDienChinhTaDamMay? _khoDamMay;

  void _dungControllerTheoDs() {
    for (final c in _ds) {
      _oLoi[c] = TextEditingController(text: c.loi);
      _oThayThe[c] = (c.dsThayThe.isEmpty ? [''] : c.dsThayThe)
          .map((s) => TextEditingController(text: s))
          .toList();
      _khoaCap[c] = GlobalKey();
      _focusLoi[c] = FocusNode();
      _focusThayThe[c] = _oThayThe[c]!.map((_) => FocusNode()).toList();
    }
    _kiemTraTrung();
  }

  void _huyCacControllerCu() {
    for (final o in _oLoi.values) {
      o.dispose();
    }
    for (final ds in _oThayThe.values) {
      for (final o in ds) {
        o.dispose();
      }
    }
    for (final f in _focusLoi.values) {
      f.dispose();
    }
    for (final ds in _focusThayThe.values) {
      for (final f in ds) {
        f.dispose();
      }
    }
    _oLoi.clear();
    _oThayThe.clear();
    _khoaCap.clear();
    _focusLoi.clear();
    _focusThayThe.clear();
    _loiTrungThayThe.clear();
    _loiTrungTuLoi.clear();
  }

  /// Tab "Bộ nhớ Đám mây" chỉ bấm được khi đã đăng nhập.
  Future<void> _doiTabNguon(String tab) async {
    if (_tab == tab) return;
    if (tab == 'damMay') {
      final uid = DichVuDangNhapGoogle.instance.nguoiDungHienTai?.uid;
      if (uid == null) {
        if (mounted) {
          hienThongBaoGiua(context, 'Vui lòng đăng nhập tài khoản Google trước.');
        }
        return;
      }
      var kho = _khoDamMay ?? TuDienChinhTaDamMay.dungChung;
      if (kho == null || kho.uid != uid) {
        kho = TuDienChinhTaDamMay(uid);
        await kho.tai();
        TuDienChinhTaDamMay.dungChung = kho;
      }
      _khoDamMay = kho;
      if (!mounted) return;
    }
    _dongTimKiemTuDien();
    setState(() {
      _huyCacControllerCu();
      _tab = tab;
      _ds = tab == 'damMay' ? _khoDamMay!.ds : widget.caiDat.tuDienChinhTa;
      _ds.sort((a, b) => a.loi.trim().toLowerCase().compareTo(b.loi.trim().toLowerCase()));
      _dungControllerTheoDs();
    });
    widget.caiDat.datTabNguonTuDienChinhTa(tab);
  }

  @override
  void initState() {
    super.initState();
    _khoDamMay = TuDienChinhTaDamMay.dungChung;
    _tab = widget.caiDat.tabNguonTuDienChinhTa == 'damMay' && _khoDamMay != null
        ? 'damMay'
        : 'noiBo';
    _ds = _dangODamMay ? _khoDamMay!.ds : widget.caiDat.tuDienChinhTa;
    // CHỈ sắp xếp lại đúng lúc MỞ modal (không sắp lại mỗi lần gõ — gõ dở
    // một từ mà hàng tự nhảy chỗ thì rất khó chịu).
    _ds.sort((a, b) => a.loi.trim().toLowerCase().compareTo(b.loi.trim().toLowerCase()));
    _dungControllerTheoDs();
    final noiDung = widget.noiDungCanDua;
    if (noiDung != null && noiDung.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _dienNoiDungVaoCapRong(noiDung));
    }
    _oTimKiemTuDien.addListener(_capNhatKetQuaTimTuDien);
  }

  @override
  void dispose() {
    _henLuu?.cancel();
    _henNhapNhayCapMoi?.cancel();
    _cuon.dispose();
    _oTimKiemTuDien.dispose();
    _focusTimKiemTuDien.dispose();
    _huyCacControllerCu();
    super.dispose();
  }

  /// Quét lại TOÀN BỘ danh sách — khớp cả chữ Hoa/thường (so sánh ở dạng
  /// chữ thường), tìm trong TẤT CẢ các dòng (từ lỗi VÀ mọi từ thay thế) của
  /// TẤT CẢ các cặp. Gọi lại mỗi khi [_oTimKiemTuDien] đổi; danh sách từ
  /// điển nhỏ nên quét lại từ đầu mỗi lần không tốn gì đáng kể.
  void _capNhatKetQuaTimTuDien() {
    final tuKhoa = _oTimKiemTuDien.text;
    final ketQuaCu = _chiSoTimTuDienHienTai >= 0 && _chiSoTimTuDienHienTai < _ketQuaTimTuDien.length
        ? _ketQuaTimTuDien[_chiSoTimTuDienHienTai]
        : null;
    final moi = <_KetQuaTimTuDien>[];
    if (tuKhoa.isNotEmpty) {
      final tuKhoaThuong = tuKhoa.toLowerCase();
      for (final c in _ds) {
        void quet(String text, bool laLoi, int chiSoThayThe) {
          final textThuong = text.toLowerCase();
          var tu = 0;
          while (true) {
            final vt = textThuong.indexOf(tuKhoaThuong, tu);
            if (vt < 0) break;
            moi.add(_KetQuaTimTuDien(
              cap: c,
              laLoi: laLoi,
              chiSoThayThe: chiSoThayThe,
              batDau: vt,
              ketThuc: vt + tuKhoa.length,
            ));
            tu = vt + 1;
          }
        }

        quet(_oLoi[c]!.text, true, -1);
        for (var i = 0; i < _oThayThe[c]!.length; i++) {
          quet(_oThayThe[c]![i].text, false, i);
        }
      }
    }
    setState(() {
      _ketQuaTimTuDien = moi;
      if (ketQuaCu == null) {
        _chiSoTimTuDienHienTai = moi.isEmpty ? -1 : 0;
      } else {
        final vtCu = moi.indexWhere((k) => k.cap == ketQuaCu.cap &&
            k.laLoi == ketQuaCu.laLoi &&
            k.chiSoThayThe == ketQuaCu.chiSoThayThe &&
            k.batDau == ketQuaCu.batDau);
        _chiSoTimTuDienHienTai = vtCu >= 0 ? vtCu : (moi.isEmpty ? -1 : 0);
      }
    });
    if (_chiSoTimTuDienHienTai >= 0) _nhayToiKetQuaTimTuDien(_ketQuaTimTuDien[_chiSoTimTuDienHienTai]);
  }

  void _dieuHuongTimKiemTuDien(int chieu) {
    if (_ketQuaTimTuDien.isEmpty) return;
    setState(() {
      _chiSoTimTuDienHienTai =
          (_chiSoTimTuDienHienTai + chieu) % _ketQuaTimTuDien.length;
      if (_chiSoTimTuDienHienTai < 0) _chiSoTimTuDienHienTai += _ketQuaTimTuDien.length;
    });
    _nhayToiKetQuaTimTuDien(_ketQuaTimTuDien[_chiSoTimTuDienHienTai]);
  }

  /// Cuộn tới đúng cặp chứa kết quả, rồi đặt tiêu điểm + vùng chọn lên ĐÚNG
  /// đoạn ký tự khớp của đúng ô — Flutter tự vẽ màu tô NỀN của selection lên
  /// đúng đoạn đó, y hệt cách giữ màu tô vùng chọn ở trang soạn thảo chính.
  void _nhayToiKetQuaTimTuDien(_KetQuaTimTuDien k) {
    _cuonToiCap(k.cap);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focus = k.laLoi ? _focusLoi[k.cap] : _focusThayThe[k.cap]?[k.chiSoThayThe];
      final oDk = k.laLoi ? _oLoi[k.cap] : _oThayThe[k.cap]?[k.chiSoThayThe];
      if (focus == null || oDk == null) return;
      focus.requestFocus();
      oDk.selection = TextSelection(baseOffset: k.batDau, extentOffset: k.ketThuc);
    });
  }

  void _dongTimKiemTuDien() {
    setState(() {
      _hienThanhTimKiemTuDien = false;
      _ketQuaTimTuDien = [];
      _chiSoTimTuDienHienTai = -1;
    });
  }

  void _moTimKiemTuDien() {
    setState(() => _hienThanhTimKiemTuDien = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusTimKiemTuDien.requestFocus();
    });
  }

  /// (YÊU CẦU MỚI) Tìm/tạo một cặp RỖNG, điền [noiDung] vào trường "Từ bị
  /// lỗi chính tả hay gặp" (dòng 1) của cặp đó, cuộn tới giữa màn hình, rồi
  /// nhấp nháy nền vàng đậm vài giây — xem giải thích đầy đủ ở
  /// `moModalTuDienChinhTa`/[_capVuaThem].
  void _dienNoiDungVaoCapRong(String noiDung) {
    final capRongCo = _capRong;
    final CapTuDien c;
    if (capRongCo != null) {
      c = capRongCo;
    } else {
      c = CapTuDien(loi: '');
      setState(() {
        _ds.add(c);
        _oLoi[c] = TextEditingController();
        _oThayThe[c] = [TextEditingController()];
        _khoaCap[c] = GlobalKey();
        _focusLoi[c] = FocusNode();
        _focusThayThe[c] = [FocusNode()];
      });
    }
    setState(() {
      c.loi = noiDung;
      _oLoi[c]!.text = noiDung;
      _kiemTraTrung();
      _capVuaThem = c;
      _capVuaThemSang = true;
    });
    _datLuu();
    _cuonToiCap(c);
    _henNhapNhayCapMoi?.cancel();
    var lan = 0;
    _henNhapNhayCapMoi = Timer.periodic(const Duration(milliseconds: 400), (t) {
      lan++;
      if (lan > 6) {
        t.cancel();
        if (mounted) setState(() => _capVuaThem = null);
        return;
      }
      if (mounted) setState(() => _capVuaThemSang = !_capVuaThemSang);
    });
  }

  /// Tự lưu xuống đĩa 500ms sau lần gõ cuối — không cần nút "Lưu" riêng,
  /// đúng yêu cầu "mỗi lần thao tác thì hệ thống tự động lưu".
  void _datLuu() {
    _henLuu?.cancel();
    _henLuu = Timer(const Duration(milliseconds: 500), () {
      if (_dangODamMay) {
        unawaited(_khoDamMay?.ghiDs(_ds));
      } else {
        widget.caiDat.luuTuDienChinhTa();
      }
    });
  }

  /// (YÊU CẦU MỚI) Không còn làm nút "+ Thêm cặp từ" bị LIỆT khi đang có một
  /// cặp rỗng hoàn toàn (cả từ lỗi lẫn mọi từ thay thế đều trống) — bấm vào
  /// lúc đó giờ CUỘN tới ĐÚNG cặp rỗng ấy (hiện ra giữa màn hình) thay vì
  /// thêm cặp mới, xem `_themCap`.
  bool _laCapRong(CapTuDien c) =>
      c.loi.trim().isEmpty && _oThayThe[c]!.every((o) => o.text.trim().isEmpty);

  CapTuDien? get _capRong {
    for (final c in _ds) {
      if (_laCapRong(c)) return c;
    }
    return null;
  }

  void _cuonToiCap(CapTuDien c) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _khoaCap[c]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    });
  }

  void _themCap() {
    // Đang có sẵn một cặp rỗng — bắt điền nó trước đã, không đẻ thêm cặp
    // rỗng khác: cuộn tới đúng cặp đó cho người dùng thấy ngay.
    final capRong = _capRong;
    if (capRong != null) {
      _cuonToiCap(capRong);
      return;
    }
    final c = CapTuDien(loi: '');
    setState(() {
      _ds.add(c);
      _oLoi[c] = TextEditingController();
      _oThayThe[c] = [TextEditingController()];
      _khoaCap[c] = GlobalKey();
      _focusLoi[c] = FocusNode();
      _focusThayThe[c] = [FocusNode()];
    });
    // Đợi khung hình kế tiếp (sau khi `ListView` đã dựng thêm cặp mới, biết
    // được chiều cao thật mới) rồi mới cuộn — cuộn ngay trong `setState` sẽ
    // tính theo chiều cao CŨ, hụt mất đúng phần vừa thêm.
    _cuonToiCap(c);
  }

  void _xoaCap(CapTuDien c) {
    setState(() {
      _ds.remove(c);
      _oLoi.remove(c)?.dispose();
      for (final o in _oThayThe.remove(c) ?? <TextEditingController>[]) {
        o.dispose();
      }
      _loiTrungThayThe.remove(c);
      _loiTrungTuLoi.remove(c);
      _khoaCap.remove(c);
      _focusLoi.remove(c)?.dispose();
      for (final f in _focusThayThe.remove(c) ?? <FocusNode>[]) {
        f.dispose();
      }
    });
    if (_dangODamMay) {
      unawaited(_khoDamMay?.ghiDs(_ds));
    } else {
      widget.caiDat.luuTuDienChinhTa();
    }
  }

  /// Đồng bộ `c.dsThayThe` với nội dung đang gõ của mọi ô thay thế của [c].
  void _dongBoThayThe(CapTuDien c) {
    c.dsThayThe = _oThayThe[c]!.map((o) => o.text).toList();
  }

  /// "+ Thêm Từ thay thế" — thêm một ô mới (thứ hai hoặc thứ ba), tối đa 3.
  void _themTuThayThe(CapTuDien c) {
    final ds = _oThayThe[c]!;
    if (ds.length >= 3) return;
    setState(() {
      ds.add(TextEditingController());
      _focusThayThe[c]!.add(FocusNode());
      _dongBoThayThe(c);
    });
    _datLuu();
  }

  /// Xoá HẲN ô thứ hai/ba (không chỉ xoá chữ) — các ô sau tự dồn lên
  /// (danh sách là List nên xoá đúng vị trí là tự dồn).
  void _xoaHangTuThayThe(CapTuDien c, int chiSo) {
    setState(() {
      _oThayThe[c]!.removeAt(chiSo).dispose();
      _focusThayThe[c]!.removeAt(chiSo).dispose();
      _dongBoThayThe(c);
      _kiemTraTrung();
    });
    _datLuu();
  }

  /// Mục 5: kiểm tra lại TOÀN BỘ danh sách sau mỗi lần gõ — cờ trùng từ lỗi
  /// (so các [CapTuDien.loi] với nhau) và cờ "từ thay thế thứ nhất giống hệt
  /// từ lỗi" của CHÍNH cặp đó. Không xoá chữ người dùng gõ — chỉ đánh dấu
  /// cảnh báo, để họ tự sửa.
  void _kiemTraTrung() {
    _loiTrungThayThe.clear();
    _loiTrungTuLoi.clear();
    final demLoi = <String, int>{};
    for (final c in _ds) {
      final loi = c.loi.trim().toLowerCase();
      if (loi.isEmpty) continue;
      demLoi[loi] = (demLoi[loi] ?? 0) + 1;
    }
    for (final c in _ds) {
      final loi = c.loi.trim().toLowerCase();
      final thayThe = c.thayThe.trim().toLowerCase();
      if (loi.isNotEmpty && thayThe.isNotEmpty && loi == thayThe) {
        _loiTrungThayThe.add(c);
      }
      if (loi.isNotEmpty && (demLoi[loi] ?? 0) > 1) {
        _loiTrungTuLoi.add(c);
      }
    }
  }

  Widget _oNhap({
    required String nhan,
    required TextEditingController controller,
    required String goiY,
    required void Function(String) onChanged,
    FocusNode? focusNode,
    String? canhBao,
    VoidCallback? khiXoaHang,
    // (YÊU CẦU MỚI) Cặp từ đang RỖNG hoàn toàn — viền xanh dương đậm ở mọi
    // trường của cặp đó để nổi bật hẳn lên so với các cặp khác, giúp nhận
    // ra ngay cặp nào còn đang bỏ trống. `canhBao` (viền đỏ, trùng từ) vẫn
    // ưu tiên hơn nếu cả hai cùng xảy ra — dù thực tế cặp rỗng thì không
    // thể nào trùng được gì.
    bool noiBatRong = false,
    // (YÊU CẦU MỚI) Dòng 1 của cặp vừa được điền sẵn từ vùng chọn — nền
    // vàng đậm, nhấp nháy vài giây rồi tự tắt (xem [_capVuaThem]). Ưu tiên
    // CAO NHẤT trong mọi kiểu tô nền/viền (đang cố tình gây chú ý ngay lúc
    // đó, hơn cả cảnh báo đỏ hay viền rỗng xanh).
    bool noiBatVangNhapNhay = false,
  }) {
    final mauVien = noiBatVangNhapNhay
        ? Colors.amber.shade800
        : (canhBao != null
            ? Colors.red.shade400
            : (noiBatRong ? Colors.blue.shade700 : const Color(0xFFDADCE0)));
    final doRongVien = noiBatVangNhapNhay ? 2.0 : (canhBao != null ? 1.0 : (noiBatRong ? 2.0 : 1.0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nhan,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                // (YÊU CẦU MỚI) Giới hạn ký tự cho MỌI trường của từ điển —
                // `maxLength` tự kèm `LengthLimitingTextInputFormatter`, nên
                // dán đoạn dài hơn cũng tự cắt bớt, không cần thêm gì.
                maxLength: gioiHanTuDienChinhTa,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  // (SỬA LỖI — "không thấy gì khác biệt") Chỉ đổi màu/độ dày
                  // viền thì quá mờ để nhận ra ngay, đặc biệt lúc không
                  // focus — tô luôn NỀN xanh nhạt cho cặp đang rỗng, không
                  // thể nào không thấy.
                  filled: noiBatRong || noiBatVangNhapNhay,
                  fillColor: noiBatVangNhapNhay
                      ? Colors.amber.shade600
                      : (noiBatRong ? Colors.blue.shade50 : null),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: mauVien, width: doRongVien),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: canhBao != null
                          ? Colors.red.shade400
                          : (noiBatRong ? Colors.blue.shade700 : _mauChinh),
                      width: 2,
                    ),
                  ),
                  hintText: goiY,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: khiXoaHang != null ? 'Xoá hàng này' : 'Xoá chữ này',
              onPressed: khiXoaHang ??
                  () {
                    controller.clear();
                    onChanged('');
                  },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (canhBao != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              canhBao,
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ),
      ],
    );
  }

  Widget _congTacBatTat() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Bật hoạt động của từ điển sửa lỗi chính tả',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: _dangODamMay
                ? (_khoDamMay?.bat ?? true)
                : widget.caiDat.tuDienChinhTaBatHoatDong,
            activeThumbColor: _mauChinh,
            // (YÊU CẦU MỚI — 2 bộ nhớ) KHÔNG loại trừ nhau ở từ điển sửa
            // lỗi chính tả — cho phép tắt 1, tắt cả 2, hoặc bật cả 2.
            onChanged: (gia) async {
              if (_dangODamMay) {
                await _khoDamMay?.ghiBat(gia);
              } else {
                widget.caiDat.tuDienChinhTaBatHoatDong = gia;
                await widget.caiDat.luuTuDienChinhTaBatHoatDong();
              }
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// (YÊU CẦU MỚI — 2 bộ nhớ) Hai "tab" dính sát nhau, góc vuông — y hệt
  /// khuôn của "Từ điển nhập liệu nhanh".
  Widget _thanChonNguon() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _nutTabNguon('noiBo', 'Bộ nhớ Nội bộ')),
              Expanded(child: _nutTabNguon('damMay', 'Bộ nhớ Đám mây')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _dangODamMay
                ? 'Từ điển này trong Bộ nhớ Đám mây lâu dài trên internet của tài khoản đang đăng nhập vào'
                : 'Từ điển này trong Bộ nhớ nội bộ lâu dài của thiết bị (hoặc của trình duyệt)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
        ],
      );

  Widget _nutTabNguon(String tab, String nhan) {
    final dangChon = _tab == tab;
    return InkWell(
      onTap: () => _doiTabNguon(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: dangChon ? _mauChinh : const Color(0xFFF1F3F4),
        alignment: Alignment.center,
        child: Text(
          nhan,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: dangChon ? Colors.white : const Color(0xFF5F6368),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dangODamMay ? const Color(0xFFE6F4EA) : null,
      appBar: AppBar(
        backgroundColor: _mauChinh,
        foregroundColor: Colors.white,
        title: const Text('Từ điển sửa lỗi chính tả của bạn'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
        // "+ Thêm cặp từ" luôn ở góc trên bên phải, cùng dòng tiêu đề — lướt
        // màn hình lên xuống vẫn thấy, không cần cuộn lên tận đầu mới bấm
        // được. Hiện tên đầy đủ kèm icon, không rút gọn chỉ còn icon.
        actions: [
          // (YÊU CẦU MỚI) Nút kính lúp — mở thanh tìm kiếm riêng của modal
          // này, cạnh "+ Thêm cặp từ".
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Tìm trong từ điển',
            onPressed: _hienThanhTimKiemTuDien ? _dongTimKiemTuDien : _moTimKiemTuDien,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _themCap,
              icon: const Icon(Icons.add_circle_outline),
              // (YÊU CẦU MỚI) Màn hẹp: rút gọn chữ còn "Thêm" (vẫn giữ icon)
              // cho đỡ chật — màn rộng giữ nguyên tên đầy đủ.
              label: Text(
                MediaQuery.sizeOf(context).width < 600 ? 'Thêm' : 'Thêm cặp từ',
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white38,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_hienThanhTimKiemTuDien) _thanhTimKiemTuDien(),
            Expanded(
              child: ListView(
                controller: _cuon,
          // (SỬA LỖI — "bấm Thêm cặp từ không tự cuộn tới cặp rỗng")
          // `Scrollable.ensureVisible` cần context CỦA ĐÚNG WIDGET đích đã
          // THẬT SỰ được dựng (`currentContext` khác `null`) — nhưng
          // `ListView` (dù dùng constructor `children:` liệt kê sẵn) vẫn ẢO
          // HOÁ (chỉ dựng Element cho phần trong viewport + vùng đệm mặc
          // định ~250px) như `ListView.builder`. Cặp rỗng/cặp vừa thêm nằm
          // xa ngoài vùng đệm đó thì `_khoaCap[c]!.currentContext` vẫn
          // `null` ngay cả sau khung hình kế tiếp — cuộn im lặng không làm
          // gì. Ép `cacheExtent` cực lớn để TOÀN BỘ danh sách luôn được
          // dựng sẵn (danh sách cặp từ không đủ lớn để lo tốn bộ nhớ).
          cacheExtent: 100000,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _thanChonNguon(),
            _congTacBatTat(),
            const SizedBox(height: 16),
            const Text(
              'App tự quét văn bản — từ nào khớp "Từ bị lỗi chính tả hay '
              'gặp" sẽ được gạch vàng lượn sóng, bấm vào để thay/xoá nhanh. '
              'Để trống "Từ thay thế vào thứ nhất" (và không thêm từ thay '
              'thế nào khác) nghĩa là đề xuất xoá hẳn từ đó. Có thể thêm tối '
              'đa 3 từ thay thế cho mỗi cặp — tất cả đều hiện trong đề xuất, '
              'còn "Chấp nhận tất cả đề xuất của từ điển" chỉ áp dụng từ thay '
              'thế thứ nhất.',
              style: TextStyle(height: 1.5, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 8),
            for (final c in _ds) ...[
              KeyedSubtree(key: _khoaCap[c], child: const Divider(height: 28)),
              _oNhap(
                nhan: 'Từ bị lỗi chính tả hay gặp',
                controller: _oLoi[c]!,
                focusNode: _focusLoi[c],
                goiY: 'Ví dụ: vd, mik, ...',
                // (YÊU CẦU MỚI) Cặp rỗng hoàn toàn (xem `_capRong`) — viền
                // xanh dương đậm ở MỌI trường trong cặp đó, phân biệt với
                // các cặp còn lại. Tự hết ngay khi cặp không còn rỗng nữa
                // (gõ bất kỳ trường nào), tự hiện lại nếu xoá hết về rỗng.
                noiBatRong: _laCapRong(c),
                noiBatVangNhapNhay: c == _capVuaThem && _capVuaThemSang,
                canhBao: _loiTrungTuLoi.contains(c)
                    ? 'Từ này đã có trong một cặp khác — các từ bị lỗi không được trùng nhau.'
                    : null,
                onChanged: (gia) {
                  setState(() {
                    c.loi = gia;
                    _kiemTraTrung();
                    // Người dùng tự gõ tiếp — coi như đã chú ý rồi, tắt
                    // nhấp nháy ngay, không chờ hết vài giây.
                    if (c == _capVuaThem) {
                      _henNhapNhayCapMoi?.cancel();
                      _capVuaThem = null;
                    }
                  });
                  _datLuu();
                },
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _oThayThe[c]!.length; i++) ...[
                _oNhap(
                  nhan: _nhanThuThayThe[i],
                  controller: _oThayThe[c]![i],
                  focusNode: _focusThayThe[c]?[i],
                  goiY: i == 0 ? 'Để trống = đề xuất xoá' : 'Từ thay thế thêm',
                  noiBatRong: _laCapRong(c),
                  canhBao: i == 0 && _loiTrungThayThe.contains(c)
                      ? 'Từ thay thế thứ nhất không được giống hệt từ bị lỗi ở trên.'
                      : null,
                  khiXoaHang: i == 0 ? null : () => _xoaHangTuThayThe(c, i),
                  onChanged: (gia) {
                    setState(() {
                      _dongBoThayThe(c);
                      _kiemTraTrung();
                    });
                    _datLuu();
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (_oThayThe[c]!.length < 3)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _themTuThayThe(c),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm Từ thay thế'),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _xoaCap(c),
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
                  label: Text('Xoá cặp từ', style: TextStyle(color: Colors.red.shade600)),
                ),
              ),
            ],
          ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh tìm kiếm nổi ngay dưới AppBar — y khuôn `_thanhTimKiem` của trang
  /// soạn thảo chính (ô nhập, số kết quả, mũi tên lên/xuống, nút X xanh lá,
  /// nút Tắt đỏ) nhưng KHÔNG có thanh thay thế ở dưới.
  Widget _thanhTimKiemTuDien() {
    return Container(
      key: const ValueKey('thanhTimKiemTuDien'),
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _oTimKiemTuDien,
              focusNode: _focusTimKiemTuDien,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Tìm trong từ điển...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _dieuHuongTimKiemTuDien(1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _ketQuaTimTuDien.isEmpty
                ? '0/0'
                : '${_chiSoTimTuDienHienTai + 1}/${_ketQuaTimTuDien.length}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: 'Kết quả trước',
            onPressed: _ketQuaTimTuDien.isEmpty ? null : () => _dieuHuongTimKiemTuDien(-1),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Kết quả tiếp theo',
            onPressed: _ketQuaTimTuDien.isEmpty ? null : () => _dieuHuongTimKiemTuDien(1),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.green.shade700),
            tooltip: 'Xoá nội dung tìm',
            onPressed: () => _oTimKiemTuDien.clear(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: _dongTimKiemTuDien,
            child: const Text('Tắt'),
          ),
        ],
      ),
    );
  }
}
