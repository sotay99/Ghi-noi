// Màn hình cây thư mục: xem, thêm, đổi tên, xoá, sao chép, cắt-di chuyển thư
// mục và ghi chú. Bấm vào một ghi chú thì trả id của nó về cho trang soạn
// thảo qua Navigator.pop; đi dạo rồi quay lại tay không thì trả về null.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cai_dat.dart';
import 'kho_du_lieu.dart';
import 'luu_va_chia_se_tep.dart';
import 'mau_co_ban.dart';
import 'mo_hinh.dart';
import 'modal_nhap_zip.dart';
import 'modal_thong_tin_muc.dart';
import 'modal_thung_rac.dart';
import 'tai_ve_ghi_chu.dart';
import 'thong_bao_giua.dart';
// (YÊU CẦU MỚI) "Bộ nhớ trên đám mây" — mở một `TrangSoanThao`/`ManHinhThuMuc`
// KHÁC, cùng y hệt giao diện/logic, chỉ khác `kho` truyền vào
// (`KhoDuLieuDamMay` thay vì `KhoDuLieu` nội bộ). Import vòng lại
// `trang_soan_thao.dart` (file đó cũng import file này cho nút "Thư mục") —
// Dart cho phép import vòng giữa hai thư viện, không phải lỗi.
import 'trang_soan_thao.dart';
import 'zip_thu_muc.dart';

/// (YÊU CẦU MỚI) "Ngôi nhà chung" — một mức ẢO đứng TRÊN `thuMucGoc` thật,
/// chứa 3 "bộ nhớ" lớn (Nội bộ/Đám mây/Chia sẻ). Không phải id thư mục thật
/// trong `KhoDuLieu` — chỉ dùng để `_thuMucHienTaiId` nhận biết đang ở mức
/// này, build() rẽ nhánh riêng, KHÔNG bao giờ đưa vào `_kho.noiDungThuMuc`.
const _ngoiNhaChung = '#ngoi-nha-chung#';

class ManHinhThuMuc extends StatefulWidget {
  const ManHinhThuMuc({
    super.key,
    required this.kho,
    required this.idGhiChuDangMo,
    required this.caiDat,
    this.boNhoDocLap = false,
  });

  final KhoDuLieu kho;
  final String idGhiChuDangMo;
  final CaiDat caiDat;

  /// (SỬA LỖI — vào "Bộ nhớ trên đám mây" bị lẫn với "Ngôi nhà chung") `true`
  /// cho một cây ĐỨNG RIÊNG (hiện chỉ dùng cho `KhoDuLieuDamMay`) — màn hình
  /// này đứng thẳng ở `thuMucGoc` của ĐÚNG [kho] được giao, không còn mức ảo
  /// "Ngôi nhà chung" (3 ô chọn Nội bộ/Đám mây/Chia sẻ) phía trên nữa. Thiếu
  /// cờ này, lùi lại từ gốc cây đám mây sẽ về lại 3 ô đó — bấm "Bộ nhớ nội
  /// bộ" ở ĐÓ vẫn chỉ vào gốc của [kho] HIỆN TẠI (vẫn là đám mây, không đổi
  /// được kho) — một cái bẫy UI làm người dùng tưởng app xoá mất dữ liệu nội
  /// bộ, trong khi dữ liệu thật không hề đụng tới.
  final bool boNhoDocLap;

  @override
  State<ManHinhThuMuc> createState() => _ManHinhThuMucState();
}

class _ManHinhThuMucState extends State<ManHinhThuMuc> {
  String _thuMucHienTaiId = _ngoiNhaChung;
  final List<String> _duongDan = []; // Ngăn xếp id thư mục cha, để quay lại.

  // (YÊU CẦU MỚI) Bộ nhớ tạm "cắt/sao chép" — giữ DANH SÁCH để hỗ trợ cả
  // "Chọn nhiều" (nhiều mục cùng lúc) lẫn một mục đơn lẻ (danh sách 1 phần
  // tử) qua đúng MỘT cơ chế. `_choDanLaCat` phân biệt cắt (di chuyển) hay
  // sao chép — không còn cần enum riêng cho từng loại x từng kiểu mục.
  List<String> _choDanThuMucIds = [];
  List<String> _choDanGhiChuIds = [];
  bool _choDanLaCat = false;
  String _choDanTen = '';
  bool get _coDangChoDan =>
      _choDanThuMucIds.isNotEmpty || _choDanGhiChuIds.isNotEmpty;

  // (YÊU CẦU MỚI) "Chọn nhiều" — chế độ tích chọn nhiều thư mục/ghi chú
  // cùng lúc để Sao chép/Cắt/Chuyển vào thùng rác một lượt.
  bool _dangChonNhieu = false;
  final Set<String> _dsThuMucDaChon = {};
  final Set<String> _dsGhiChuDaChon = {};

  // (YÊU CẦU MỚI) Cây đã xem trước ở `ModalNhapZip`, đang chờ người dùng đi
  // tìm một thư mục khác rồi bấm "Đưa vào chỗ này" — `null` là không có gì
  // đang chờ.
  List<NutZip>? _zipDangChoNhap;

  // (YÊU CẦU MỚI) "Tìm kiếm trong này" — thay hẳn 3 dòng trên cùng + thanh
  // ghim đáy (nếu có) bằng 2 thanh riêng khi đang mở. `static` để GIỮ
  // NGUYÊN trạng thái (đang mở hay không, từ khoá đang gõ) qua lần đóng
  // màn hình này để mở TỆP vừa bấm trong kết quả tìm — mở lại "Thư mục" ở
  // trang soạn thảo thì quay thẳng lại modal tìm kiếm, đúng ý "quay lại
  // modal tìm kiếm nếu chưa đóng".
  bool _dangTimKiem = false;
  String? _timKiemTrongThuMucId;
  String _timKiemTrongThuMucTen = '';
  final _oTimKiemThuMuc = TextEditingController();

  static bool _dangTimKiemNho = false;
  static String? _timKiemTrongThuMucIdNho;
  static String _timKiemTrongThuMucTenNho = '';
  static String _tuKhoaTimKiemNho = '';

  // (YÊU CẦU MỚI) Mục "vừa dán/nhập/khôi phục" — icon nhấp nháy (hiện/ẩn
  // mỗi giây) trong 10 giây rồi im lặng hẳn. `static` để sống qua các lần
  // Navigator.push/pop khác nhau của CHÍNH màn hình này trong một phiên
  // (giống `_nhoThuMucId`), KHÔNG lưu xuống đĩa — mất khi F5/mở lại app
  // cũng không sao, chỉ là hiệu ứng thu hút chú ý tạm thời.
  static final Map<String, DateTime> _thoiDiemMucMoi = {};
  Timer? _nhipNhayNhay;

  // (YÊU CẦU MỚI) Nhanh hơn 1,3 lần so với trước (mỗi pha hiện/ẩn 1 giây
  // → còn ~770ms) nhưng vẫn giữ nguyên tổng thời gian hiệu ứng (10 giây).
  static const _nhipNhayNhayMs = 770;
  static const _tongGiayNhayNhay = 10;

  /// (YÊU CẦU MỚI) Cuộn lên đầu/xuống cuối danh sách thư mục/tệp hiện tại
  /// — xem `_haiNutCuonLenXuongThuMuc`.
  final _cuonDanhSachThuMuc = ScrollController();

  void _danhDauMucMoi(Iterable<String> ids) {
    if (ids.isEmpty) return;
    final luc = DateTime.now();
    for (final id in ids) {
      _thoiDiemMucMoi[id] = luc;
    }
    _dambaoNhipDangChay();
  }

  void _dambaoNhipDangChay() {
    if (_nhipNhayNhay != null || _thoiDiemMucMoi.isEmpty) return;
    _nhipNhayNhay = Timer.periodic(const Duration(milliseconds: _nhipNhayNhayMs), (_) {
      final luc = DateTime.now();
      _thoiDiemMucMoi.removeWhere(
        (_, t) => luc.difference(t).inSeconds >= _tongGiayNhayNhay,
      );
      if (_thoiDiemMucMoi.isEmpty) {
        _nhipNhayNhay?.cancel();
        _nhipNhayNhay = null;
      }
      if (mounted) setState(() {});
    });
  }

  /// true nếu icon của [id] nên VẼ RA ở đúng lúc này (nhấp nháy — xen kẽ
  /// hiện/ẩn mỗi ~770ms trong 10 giây đầu, mục không nằm trong danh sách
  /// thì luôn vẽ bình thường).
  bool _hienIconLucNay(String id) {
    final t = _thoiDiemMucMoi[id];
    if (t == null) return true;
    final ms = DateTime.now().difference(t).inMilliseconds;
    return (ms ~/ _nhipNhayNhayMs).isEven;
  }

  KhoDuLieu get _kho => widget.kho;

  @override
  void initState() {
    super.initState();
    // (YÊU CẦU MỚI) Có nhớ từ lần mở trước (trong CÙNG phiên app) thì vào
    // đúng chỗ đó; chưa có gì (lần đầu, hoặc vừa F5/mở lại app) thì mặc
    // định đi thẳng tới thư mục đang chứa tệp mở ở trang soạn thảo.
    if (widget.boNhoDocLap) {
      // Cây đứng RIÊNG — luôn bắt đầu thẳng tại gốc của chính [kho] này,
      // KHÔNG nhớ vị trí cũ giữa các lần mở (mỗi lần mở là một phiên mới).
      // Vẫn giữ `_ngoiNhaChung` trong `_duongDan` để nút lùi/thanh địa chỉ
      // hiện ra như bình thường — chỉ CHẶN trước khi nó thật sự được dùng
      // (xem `_thoatKhoiCayDocLap`, gọi từ `_veThuMucCha`/`_nhayToiViTri`).
      _thuMucHienTaiId = thuMucGoc;
      _duongDan.addAll(_duongDanToiThuMuc(thuMucGoc));
    } else {
      final nhoId = _nhoThuMucId;
      final nhoDuongDan = _nhoDuongDan;
      if (nhoId != null && nhoDuongDan != null && identical(_nhoKho, widget.kho)) {
        _thuMucHienTaiId = nhoId;
        _duongDan.addAll(nhoDuongDan);
      } else {
        final thuMucId = _thuMucChuaTepDangSoanThao;
        _thuMucHienTaiId = thuMucId;
        _duongDan.addAll(_duongDanToiThuMuc(thuMucId));
      }
    }
    // Có mục đang nhấp nháy từ lần mở trước (vẫn trong phiên app này) —
    // tiếp tục đếm nhịp luôn, đừng chờ tới lần `_danhDauMucMoi` kế tiếp.
    _dambaoNhipDangChay();
    // Modal "Tìm kiếm trong này" chưa bị tắt ở lần mở trước — quay lại
    // đúng chỗ đó (xem chú thích ở khai báo `_dangTimKiemNho`).
    if (_dangTimKiemNho && _timKiemTrongThuMucIdNho != null) {
      _dangTimKiem = true;
      _timKiemTrongThuMucId = _timKiemTrongThuMucIdNho;
      _timKiemTrongThuMucTen = _timKiemTrongThuMucTenNho;
      _oTimKiemThuMuc.text = _tuKhoaTimKiemNho;
    }
  }

  @override
  void dispose() {
    // Ghi lại NGAY LÚC rời màn hình — lần mở kế tiếp (vẫn trong phiên app
    // này) đọc lại đúng ở `initState`. Cây đứng riêng (`boNhoDocLap`) luôn
    // khởi động lại từ gốc mỗi lần mở — không cần (và không nên) nhớ gì.
    if (!widget.boNhoDocLap) {
      _nhoThuMucId = _thuMucHienTaiId;
      _nhoDuongDan = List<String>.from(_duongDan);
      _nhoKho = widget.kho;
    }
    _dangTimKiemNho = _dangTimKiem;
    _timKiemTrongThuMucIdNho = _timKiemTrongThuMucId;
    _timKiemTrongThuMucTenNho = _timKiemTrongThuMucTen;
    _tuKhoaTimKiemNho = _oTimKiemThuMuc.text;
    _oTimKiemThuMuc.dispose();
    _nhipNhayNhay?.cancel();
    _cuonDanhSachThuMuc.dispose();
    super.dispose();
  }

  /// Xem giải thích ở `_haiNutCuonLenXuongThuMuc`.
  void _cuonDanhSachThuMucLenDau() {
    if (!_cuonDanhSachThuMuc.hasClients) return;
    _cuonDanhSachThuMuc.animateTo(0,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _cuonDanhSachThuMucXuongCuoi() {
    if (!_cuonDanhSachThuMuc.hasClients) return;
    _cuonDanhSachThuMuc.animateTo(
      _cuonDanhSachThuMuc.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// (YÊU CẦU MỚI) Hai nút cuộn lên đầu/xuống cuối danh sách — opacity 50%
  /// (thấy mờ mờ tên thư mục cha phía sau nếu tên dài), đứng ngay bên trái
  /// nút "Thêm ghi chú". CHỈ bấm vào mới cuộn — rê chuột không còn tác dụng.
  List<Widget> _haiNutCuonLenXuongThuMuc() => [
        Opacity(
          opacity: 0.5,
          child: IconButton(
            onPressed: _cuonDanhSachThuMucLenDau,
            icon: const Icon(Icons.arrow_upward, size: 20),
            tooltip: 'Cuộn lên đầu danh sách',
          ),
        ),
        Opacity(
          opacity: 0.5,
          child: IconButton(
            onPressed: _cuonDanhSachThuMucXuongCuoi,
            icon: const Icon(Icons.arrow_downward, size: 20),
            tooltip: 'Cuộn xuống cuối danh sách',
          ),
        ),
      ];

  /// (YÊU CẦU MỚI) Tên thư mục "Bộ nhớ nội bộ" — khác nhau giữa bản web
  /// (đọc từ Trình duyệt web) và bản APK/iOS (đọc thẳng từ máy).
  String get _tenBoNhoNoiBo => kIsWeb
      ? 'Bộ nhớ nội bộ trong Trình duyệt web của thiết bị'
      : 'Bộ nhớ nội bộ trong thiết bị';

  /// (SỬA LỖI) `thuMucGoc` ('goc') là HẰNG SỐ DÙNG CHUNG cho MỌI cây (nội
  /// bộ lẫn đám mây) — chỉ kiểm `_thuMucHienTaiId == thuMucGoc` không đủ để
  /// biết đây là gốc cây NÀO. Phải hỏi thẳng kiểu của `widget.kho`.
  bool get _laKhoDamMay => widget.kho is KhoDuLieuDamMay;

  String get _tenThuMucHienTai {
    if (_thuMucHienTaiId == _ngoiNhaChung) return 'Chọn nơi lưu trữ';
    // (YÊU CẦU MỚI) Đứng NGAY tại gốc (không phải một thư mục con nào bên
    // trong) — đổi tên hiển thị, xem màu ở `_dongTenThuMuc`.
    if (_thuMucHienTaiId == thuMucGoc) {
      return _laKhoDamMay ? 'Bộ nhớ trên đám mây' : 'Bộ nhớ Nội bộ';
    }
    return _kho.timThuMuc(_thuMucHienTaiId)?.ten ??
        (_laKhoDamMay ? 'Bộ nhớ trên đám mây' : 'Bộ nhớ Nội bộ');
  }

  /// (YÊU CẦU MỚI) "Bộ nhớ được chia sẻ với bạn" — để dành cho sau này,
  /// chưa làm gì cả ngoài báo biết.
  void _baoDangNangCap() {
    hienThongBaoGiua(context, 'Tính năng đang nâng cấp');
  }

  /// "Bộ nhớ trên đám mây" — một cây HOÀN TOÀN TÁCH BIỆT khỏi cây nội bộ
  /// (Mô hình B), chạy trên `KhoDuLieuDamMay` (xem `kho_du_lieu.dart`). Mở
  /// ra bằng cách đẩy một `TrangSoanThao` MỚI dùng kho đó — chính nó đã tự
  /// có nút "Thư mục" mở `ManHinhThuMuc` với kho đó, nên toàn bộ giao diện/
  /// logic cây thư mục (tạo/đổi tên/xoá/sắp xếp/thùng rác...) hoạt động Y
  /// HỆT cây nội bộ mà không cần sửa gì thêm ở hai màn hình đó.
  Future<void> _moBoNhoDamMay() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _bao('Cần đăng nhập Google trước (menu "Tài khoản và Cài đặt" ở trang soạn thảo).');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final khoDamMay = KhoDuLieuDamMay(uid);
      final idMoDau = await khoDamMay.tai();
      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng vòng xoay chờ.
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TrangSoanThao(
          kho: khoDamMay,
          caiDat: widget.caiDat,
          ghiChuId: idMoDau,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _bao('Không mở được Bộ nhớ trên đám mây: $e');
    }
  }

  // (YÊU CẦU MỚI) Bộ nhớ đệm "đang đứng ở đâu" — chỉ là biến `static` sống
  // trong RAM của phiên app hiện tại: F5 (web) hay tắt/mở lại app là mất,
  // ĐÚNG ý yêu cầu "dễ dàng bị xoá". Ghi lại ở `dispose()`, đọc lại ở
  // `initState()` của LẦN MỞ SAU — same type (`ManHinhThuMuc`) nhưng là một
  // instance State hoàn toàn mới mỗi lần Navigator.push, nên không thể
  // dùng field thường (field thường mất theo State khi màn hình đóng).
  static String? _nhoThuMucId;
  static List<String>? _nhoDuongDan;
  // (SỬA LỖI) `static` nên DÙNG CHUNG cho MỌI instance của màn hình này —
  // kể cả hai cây TÁCH BIỆT (nội bộ/đám mây, Mô hình B). Không ghi thêm
  // field này thì mở cây đám mây SAU KHI đã từng mở cây nội bộ sẽ lỡ dùng
  // nhớ của cây KIA (id thư mục không tồn tại ở cây này) — chỉ dùng bộ nhớ
  // khi ĐÚNG CÙNG MỘT `kho` (so bằng danh tính đối tượng) như lần ghi lại.
  static KhoDuLieu? _nhoKho;

  /// Id thư mục cha của ghi chú đang mở ở trang soạn thảo — `null` nếu ghi
  /// chú đó không còn tồn tại (đã bị xoá) hay không rõ, lúc đó coi như gốc.
  String get _thuMucChuaTepDangSoanThao =>
      _kho.timGhiChu(widget.idGhiChuDangMo)?.chaId ?? thuMucGoc;

  /// Dựng lại cả đường dẫn (ngăn xếp `_duongDan`, KHÔNG gồm chính [id]) từ
  /// "Ngôi nhà chung" đi xuống tới ĐÚNG thư mục [id] — dùng cho cả việc nhớ
  /// vị trí cũ và nút "Vị trí Tệp đang soạn thảo".
  List<String> _duongDanToiThuMuc(String id) {
    final chuoi = <String>[];
    var hienTai = id;
    while (hienTai != thuMucGoc) {
      chuoi.add(hienTai);
      final t = _kho.timThuMuc(hienTai);
      if (t == null) break; // Thư mục đã bị xoá — dừng, coi như tới đây.
      hienTai = t.chaId;
    }
    chuoi.add(thuMucGoc);
    final ds = chuoi.reversed.toList()..removeLast();
    return [_ngoiNhaChung, ...ds];
  }

  /// Id ghi chú vừa được nhảy tới qua "Vị trí Tệp đang soạn thảo" — tên của
  /// nó trong danh sách được phóng to/thu nhỏ vài lần để thu hút chú ý, ĐÚNG
  /// hệt hiệu ứng tên thư mục ở thanh địa chỉ (`_ChuMucNhayNhay`). Mỗi lần
  /// bấm nút lại tăng [_demLanNhayToiTep] để đổi `key`, hiệu ứng tự chạy lại
  /// dù đang nhảy tới ĐÚNG ghi chú vừa rồi.
  String? _idMucCanNhayNhay;
  int _demLanNhayToiTep = 0;

  /// (YÊU CẦU MỚI) Gắn vào đúng `ListTile` của tệp vừa nhảy tới — dùng để
  /// cuộn màn hình tới đó NGAY SAU khi thư mục chứa nó vừa dựng xong, canh
  /// nó ra CHÍNH GIỮA khung nhìn (không chỉ "vào trong khung nhìn").
  final GlobalKey _khoaMucVuaNhayToi = GlobalKey();

  void _veTrangSoanThao() => Navigator.of(context).pop();

  void _toiViTriTepDangSoanThao() {
    final thuMucId = _thuMucChuaTepDangSoanThao;
    setState(() {
      _thuMucHienTaiId = thuMucId;
      _duongDan
        ..clear()
        ..addAll(_duongDanToiThuMuc(thuMucId));
      _idMucCanNhayNhay = widget.idGhiChuDangMo;
      _demLanNhayToiTep++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _khoaMucVuaNhayToi.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _moThuMuc(String id) {
    setState(() {
      _duongDan.add(_thuMucHienTaiId);
      _thuMucHienTaiId = id;
    });
  }

  bool _veThuMucCha() {
    if (_duongDan.isEmpty) return false;
    if (_duongDan.last == _ngoiNhaChung && widget.boNhoDocLap) {
      _thoatKhoiCayDocLap();
      return true;
    }
    setState(() => _thuMucHienTaiId = _duongDan.removeLast());
    return true;
  }

  /// (SỬA LỖI — không có đường ra khỏi cây đứng riêng) Cây đứng riêng (đám
  /// mây) không có "Ngôi nhà chung" CỦA CHÍNH NÓ để quay về — bấm nút
  /// lùi/icon ngôi nhà ở gốc của cây này nghĩa là THOÁT HẲN, trả lại đúng
  /// "Ngôi nhà chung" của nơi đã mở ra nó: đóng CẢ màn hình thư mục đang
  /// đứng (đây) LẪN trang soạn thảo riêng đã mở ra cây này (xem
  /// `_moBoNhoDamMay` ở trang soạn thảo nội bộ) — hai `pop` liên tiếp.
  void _thoatKhoiCayDocLap() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  Future<void> _themThuMuc() async {
    final goiY = _kho.tenThuMucGoiY(_thuMucHienTaiId);
    final ten = await _hoiTenMoiTao(tieuDe: 'Thư mục mới', tenGoiY: goiY);
    if (ten == null) return;
    setState(() {
      final t = _kho.taoThuMucMoi(_thuMucHienTaiId);
      t.ten = ten;
    });
    await _kho.luu();
  }

  Future<void> _themGhiChu() async {
    final goiY = _kho.tenGhiChuGoiY(_thuMucHienTaiId);
    final ten = await _hoiTenMoiTao(tieuDe: 'Ghi chú mới', tenGoiY: goiY);
    if (ten == null) return;
    setState(() {
      final g = _kho.taoGhiChuMoi(_thuMucHienTaiId);
      g.ten = ten;
    });
    await _kho.luu();
  }

  /// Hộp thoại đặt tên khi TẠO MỚI (thư mục hoặc ghi chú): tên gợi ý điền sẵn
  /// và được BÔI ĐEN toàn bộ, gõ chữ đầu tiên là thay hẳn chứ không phải nối
  /// vào. Kiểm tên ngay khi bấm Lưu, sai thì báo lỗi tại chỗ và không đóng.
  Future<String?> _hoiTenMoiTao({
    required String tieuDe,
    required String tenGoiY,
  }) {
    final bo = TextEditingController(text: tenGoiY)
      ..selection = TextSelection(baseOffset: 0, extentOffset: tenGoiY.length);
    String? loi;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, capNhat) {
          return AlertDialog(
            title: Text(tieuDe),
            content: TextField(
              controller: bo,
              autofocus: true,
              maxLength: doDaiTenToiDa,
              inputFormatters: [FilteringTextInputFormatter.deny(kyTuCamTrongTen)],
              decoration: InputDecoration(errorText: loi),
              onSubmitted: (_) {
                final k = _kho.loiTenTrongThuMuc(bo.text, _thuMucHienTaiId);
                if (k != null) {
                  capNhat(() => loi = k);
                  return;
                }
                Navigator.of(ctx).pop(bo.text.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () {
                  final k = _kho.loiTenTrongThuMuc(bo.text, _thuMucHienTaiId);
                  if (k != null) {
                    capNhat(() => loi = k);
                    return;
                  }
                  Navigator.of(ctx).pop(bo.text.trim());
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _doiTen({
    required bool laThuMuc,
    required String id,
    required String tenCu,
  }) async {
    final ten = await _hoiTen(tieuDe: 'Đổi tên', tenBanDau: tenCu);
    if (ten == null || ten.trim().isEmpty) return;
    final loi = laThuMuc
        ? _kho.doiTenThuMuc(id, ten.trim())
        : _kho.doiTenGhiChu(id, ten.trim());
    if (loi != null) {
      _bao(loi);
      return;
    }
    setState(() {});
    await _kho.luu();
  }

  /// "Chọn màu Tên Tệp"/"Chọn màu Tên Thư mục" trong menu ba chấm — chọn
  /// xong là đổi màu ngay, không cần bấm thêm gì khác.
  Future<void> _chonMau({required bool laThuMuc, required String id}) async {
    final mau = await hienThiChonMauCoBanChoTen(
      context,
      tieuDe: laThuMuc ? 'Chọn màu Tên Thư mục' : 'Chọn màu Tên Tệp',
    );
    if (mau == null) return;
    if (laThuMuc) {
      _kho.datMauThuMuc(id, mau.value);
    } else {
      _kho.datMauGhiChu(id, mau.value);
    }
    setState(() {});
    await _kho.luu();
  }

  Future<String?> _hoiTen({
    required String tieuDe,
    required String tenBanDau,
  }) {
    final bo = TextEditingController(text: tenBanDau);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tieuDe),
        content: TextField(
          controller: bo,
          autofocus: true,
          maxLength: doDaiTenToiDa,
          inputFormatters: [FilteringTextInputFormatter.deny(kyTuCamTrongTen)],
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(bo.text),
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }

  List<GhiChuFile> _timGhiChuTrongCay(String thuMucId) {
    final ketQua = <GhiChuFile>[];
    void duyet(String id) {
      ketQua.addAll(_kho.ghiChu.where((g) => g.chaId == id));
      for (final con in _kho.thuMuc.where((t) => t.chaId == id)) {
        duyet(con.id);
      }
    }

    duyet(thuMucId);
    return ketQua;
  }

  /// "Chuyển vào thùng rác" — không hỏi xác nhận gì cả, đưa thẳng vào Thùng
  /// rác Nội bộ (xem `lib/modal_thung_rac.dart`), khôi phục được trong 30
  /// ngày.
  Future<void> _xoaThuMuc(ThuMuc t) async {
    final coGhiChuDangMoBenTrong =
        _timGhiChuTrongCay(t.id).any((g) => g.id == widget.idGhiChuDangMo);
    setState(() => _kho.chuyenThuMucVaoThungRac(t.id));
    await _kho.luu();
    if (!mounted) return;
    _baoDaChuyenVaoThungRac();
    if (coGhiChuDangMoBenTrong) {
      _bao('Ghi chú đang mở nằm trong thư mục vừa chuyển vào thùng rác.');
    }
  }

  /// Thông báo nhanh dùng chung cho MỌI lượt "Chuyển vào thùng rác" — cao
  /// ~85% màn hình (`ganTren: true`), ĐÚNG hệt thông báo Copy/Cắt/Dán/All ở
  /// thanh công cụ soạn thảo.
  void _baoDaChuyenVaoThungRac() {
    hienThongBaoGiua(context, 'Đã di chuyển vào Thùng rác', ganTren: true);
  }

  /// Xuất ghi chú thành một tệp .txt rồi mở màn hình chia sẻ của máy — dạng
  /// tệp đơn giản nhất, mở được và gửi đi được ở bất cứ đâu. Android hiện đại
  /// không cho ứng dụng tự ý ghi thẳng vào thư mục Tải xuống công khai nữa
  /// (phải xin quyền lưu trữ nặng nề), nên đi qua màn hình chia sẻ sẵn có của
  /// máy — người dùng chọn "Lưu vào máy"/"Tệp" hoặc gửi thẳng đi nơi khác.
  Future<void> _taiVeGhiChu(GhiChuFile g) async {
    hienThongBaoGiua(context, 'Đang tải file TXT về thiết bị');
    try {
      final tenTep = '${g.ten.trim().isEmpty ? 'Ghi chú' : g.ten.trim()}.txt';
      await luuVaChiaSeGhiChu(tenTep, g.noiDung, g.ten);
    } catch (_) {
      if (mounted) _bao('Không xuất được tệp. Thử lại sau.');
    }
  }

  Future<void> _xoaGhiChu(GhiChuFile g) async {
    final laDangMo = g.id == widget.idGhiChuDangMo;
    setState(() => _kho.chuyenGhiChuVaoThungRac(g.id));
    await _kho.luu();
    if (!mounted) return;
    _baoDaChuyenVaoThungRac();
    if (laDangMo) {
      _bao('Ghi chú đang mở vừa chuyển vào thùng rác.');
    }
  }

  /// Mở modal "Thùng rác Bộ nhớ Nội bộ" — xem `lib/modal_thung_rac.dart`.
  /// Nếu người dùng chọn "Đến vị trí vừa được khôi phục" thì modal trả về
  /// đúng id mục vừa khôi phục, còn mình nhảy tới đó ngay (dùng lại đúng
  /// hiệu ứng/luồng của "Vị trí Tệp đang soạn thảo").
  Future<void> _moThungRac() async {
    final ketQua = await Navigator.of(context).push<({bool laThuMuc, String id})>(
      MaterialPageRoute(builder: (_) => ModalThungRac(kho: _kho)),
    );
    if (ketQua == null || !mounted) return;
    final thuMucId = ketQua.laThuMuc
        ? (_kho.timThuMuc(ketQua.id)?.chaId ?? thuMucGoc)
        : (_kho.timGhiChu(ketQua.id)?.chaId ?? thuMucGoc);
    setState(() {
      _thuMucHienTaiId = thuMucId;
      _duongDan
        ..clear()
        ..addAll(_duongDanToiThuMuc(thuMucId));
      _idMucCanNhayNhay = ketQua.id;
      _demLanNhayToiTep++;
    });
    // (YÊU CẦU MỚI) Hiệu ứng nhấp nháy icon 10 giây bắt đầu NGAY LÚC bấm
    // "Đến vị trí vừa được khôi phục" — không phải lúc khôi phục thật ở
    // modal Thùng rác.
    _danhDauMucMoi([ketQua.id]);
  }

  /// "Tải và chia sẻ thư mục này" — nén nguyên thư mục [id] (và mọi thứ bên
  /// trong) thành .zip rồi tải/chia sẻ, xem `lib/zip_thu_muc.dart`. Dùng
  /// chung cho cả dòng tên thư mục ĐANG ĐỨNG (dòng 3) và từng thư mục con
  /// trong danh sách (menu ba chấm riêng của nó).
  Future<void> _taiThuMuc(String id, String ten) async {
    hienThongBaoGiua(
      context,
      'Đang tải file nén Zip về thiết bị, hãy giải nén file Zip để có thể '
      'sử dụng ở các thiết bị',
    );
    try {
      final bytes = nenThuMucThanhZip(_kho, id, ten);
      await luuVaChiaSeTep('$ten.zip', bytes, loaiMime: 'application/zip');
    } catch (_) {
      if (mounted) _bao('Không tạo được tệp nén. Thử lại sau.');
    }
  }

  Future<void> _taiThuMucHienTai() => _taiThuMuc(_thuMucHienTaiId, _tenThuMucHienTai);

  /// "Nhập ZIP hoặc TXT vào đây" — cho chọn NHIỀU tệp .zip/.txt cùng lúc
  /// (`FilePicker.pickFiles()`). Đúng 1 tệp .txt (≤2 MB) thì bỏ hẳn modal
  /// xem trước, đưa thẳng vào thư mục đang đứng; mọi trường hợp khác (1
  /// .zip, hoặc 2+ tệp bất kỳ loại) đều qua `ModalNhapZip` (nền tím nhạt).
  Future<void> _nhapZip() async {
    List<PlatformFile> teps;
    try {
      teps = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'txt'],
      );
    } catch (e) {
      _bao('Không mở được hộp thoại chọn tệp: $e');
      return;
    }
    if (teps.isEmpty) return;

    // Đúng 1 tệp .txt — bỏ hẳn modal, đưa thẳng vào thư mục đang đứng.
    if (teps.length == 1 && teps.single.name.toLowerCase().endsWith('.txt')) {
      final tep = teps.single;
      Uint8List bytes;
      try {
        bytes = await tep.readAsBytes();
      } catch (e) {
        _bao('Không đọc được nội dung tệp vừa chọn: $e');
        return;
      }
      if (bytes.length > gioiHanTxtByte) {
        if (mounted) {
          hienThongBaoGiua(context, 'Không cho nhập tệp TXT quá 2 MB');
        }
        return;
      }
      final ten = tep.name.substring(0, tep.name.length - 4);
      final noiDung = utf8.decode(bytes, allowMalformed: true);
      if (!mounted) return;
      List<String> ids = [];
      setState(() {
        ids = _kho.nhapCayZip([NutZip.tep(ten, noiDung)], _thuMucHienTaiId);
      });
      _danhDauMucMoi(ids);
      await _kho.luu();
      if (mounted) {
        hienThongBaoGiua(context, 'Đã nhập tệp vào thư mục', ganTren: true);
      }
      return;
    }

    // Còn lại: đọc hết TỪNG tệp, mỗi .zip thành một "nguồn" riêng (tên gốc
    // giữ lại để phân biệt), mỗi .txt rời cũng vậy — rồi LUÔN qua modal
    // xem trước.
    final nguon = <NguonNhap>[];
    var coTepQuaNang = false;
    for (final tep in teps) {
      Uint8List bytes;
      try {
        bytes = await tep.readAsBytes();
      } catch (e) {
        _bao('Không đọc được "${tep.name}": $e');
        continue;
      }
      if (tep.name.toLowerCase().endsWith('.txt')) {
        if (bytes.length > gioiHanTxtByte) {
          coTepQuaNang = true;
          continue;
        }
        final ten = tep.name.substring(0, tep.name.length - 4);
        nguon.add(NguonNhap.tepTxtRoi(
          tep.name,
          NutZip.tep(ten, utf8.decode(bytes, allowMalformed: true)),
        ));
      } else {
        try {
          final ketQua = phanTichZip(bytes);
          if (ketQua.coTepQuaNang) coTepQuaNang = true;
          nguon.add(NguonNhap.zip(tep.name, ketQua.cay));
        } catch (_) {
          _bao('Tệp "${tep.name}" không phải .zip hợp lệ, đã bỏ qua.');
        }
      }
    }
    if (nguon.isEmpty) {
      if (coTepQuaNang && mounted) {
        hienThongBaoGiua(
          context,
          'Không có tệp hợp lệ để nhập — tệp TXT quá 2 MB đã bị bỏ qua',
        );
      }
      return;
    }
    if (!mounted) return;

    final ketQua = await Navigator.of(context).push<KetQuaNhapZip>(
      MaterialPageRoute(
        builder: (_) => ModalNhapZip(nguon: nguon, coTepQuaNang: coTepQuaNang),
      ),
    );
    if (ketQua == null || ketQua == KetQuaNhapZip.huy || !mounted) return;

    final tatCaCay = [for (final n in nguon) ...n.goc];
    if (ketQua == KetQuaNhapZip.dayVaoHienTai) {
      List<String> ids = [];
      setState(() {
        ids = _kho.nhapCayZip(tatCaCay, _thuMucHienTaiId);
      });
      _danhDauMucMoi(ids);
      await _kho.luu();
      if (mounted) {
        hienThongBaoGiua(context, 'Đã nhập vào thư mục', ganTren: true);
      }
    } else {
      // chonViTriKhac — chờ người dùng tự đi tìm chỗ, xem thanh ghim đáy
      // "Đưa vào chỗ này" (`_zipDangChoNhap`).
      setState(() => _zipDangChoNhap = tatCaCay);
    }
  }

  Future<void> _dayZipVaoDay() async {
    final cay = _zipDangChoNhap;
    if (cay == null) return;
    List<String> ids = [];
    setState(() {
      ids = _kho.nhapCayZip(cay, _thuMucHienTaiId);
      _zipDangChoNhap = null;
    });
    _danhDauMucMoi(ids);
    await _kho.luu();
    if (mounted) {
      hienThongBaoGiua(context, 'Đã nhập tệp nén vào thư mục', ganTren: true);
    }
  }

  void _huyZipDangChoNhap() => setState(() => _zipDangChoNhap = null);

  /// Đặt bộ nhớ tạm cho MỘT mục đơn (từ menu ba chấm của đúng một tệp/thư
  /// mục) — danh sách chỉ có 1 phần tử, dùng chung máy "dán" với "Chọn
  /// nhiều" ở dưới.
  void _dat({required bool laCat, required bool laThuMuc, required String id, required String ten}) {
    setState(() {
      _choDanLaCat = laCat;
      _choDanThuMucIds = laThuMuc ? [id] : [];
      _choDanGhiChuIds = laThuMuc ? [] : [id];
      _choDanTen = ten;
    });
  }

  void _huyChoDan() {
    setState(() {
      _choDanThuMucIds = [];
      _choDanGhiChuIds = [];
    });
  }

  Future<void> _dan() async {
    if (!_coDangChoDan) return;
    // (YÊU CẦU MỚI) Thu lại id THẬT SỰ nằm ở nơi vừa dán tới — với "Cắt"
    // là chính id cũ (chỉ đổi `chaId`), với "Sao chép" là id bản SAO MỚI
    // — để đánh dấu nhấp nháy icon 10 giây (`_danhDauMucMoi`).
    final idsMoi = <String>[];
    for (final id in _choDanThuMucIds) {
      if (_choDanLaCat) {
        if (id == _thuMucHienTaiId) {
          _bao('Không thể chuyển vào chính nó.');
          continue;
        }
        if (!_kho.diChuyenThuMuc(id, _thuMucHienTaiId)) {
          _bao('Không thể chuyển thư mục vào chính con cháu của nó.');
          continue;
        }
        idsMoi.add(id);
      } else {
        idsMoi.add(_kho.saoChepThuMuc(id, _thuMucHienTaiId).id);
      }
    }
    for (final id in _choDanGhiChuIds) {
      if (_choDanLaCat) {
        _kho.diChuyenGhiChu(id, _thuMucHienTaiId);
        idsMoi.add(id);
      } else {
        idsMoi.add(_kho.saoChepGhiChu(id, _thuMucHienTaiId).id);
      }
    }

    setState(() {
      _choDanThuMucIds = [];
      _choDanGhiChuIds = [];
    });
    _danhDauMucMoi(idsMoi);
    await _kho.luu();
  }

  // ------------------------------------------------------- "Chọn nhiều"

  void _batDauChonNhieu() {
    setState(() {
      _dangChonNhieu = true;
      _dsThuMucDaChon.clear();
      _dsGhiChuDaChon.clear();
    });
  }

  void _huyChonNhieu() {
    setState(() {
      _dangChonNhieu = false;
      _dsThuMucDaChon.clear();
      _dsGhiChuDaChon.clear();
    });
  }

  void _toggleChonThuMuc(String id) {
    setState(() {
      if (!_dsThuMucDaChon.remove(id)) _dsThuMucDaChon.add(id);
    });
  }

  void _toggleChonGhiChu(String id) {
    setState(() {
      if (!_dsGhiChuDaChon.remove(id)) _dsGhiChuDaChon.add(id);
    });
  }

  void _datChonTatCa(
    bool chon,
    ({List<ThuMuc> thuMucCon, List<GhiChuFile> ghiChuCon})? noiDung,
  ) {
    setState(() {
      if (chon) {
        _dsThuMucDaChon.addAll((noiDung?.thuMucCon ?? const []).map((t) => t.id));
        _dsGhiChuDaChon.addAll((noiDung?.ghiChuCon ?? const []).map((g) => g.id));
      } else {
        _dsThuMucDaChon.clear();
        _dsGhiChuDaChon.clear();
      }
    });
  }

  String _tenMucDangChonDuyNhat() {
    if (_dsThuMucDaChon.isNotEmpty) {
      return _kho.timThuMuc(_dsThuMucDaChon.first)?.ten ?? '1 mục';
    }
    if (_dsGhiChuDaChon.isNotEmpty) {
      return _kho.timGhiChu(_dsGhiChuDaChon.first)?.ten ?? '1 mục';
    }
    return '1 mục';
  }

  /// "Sao chép"/"Cắt (di chuyển)" ở thanh hành động "Chọn nhiều" — gửi cả
  /// lô vào ĐÚNG bộ nhớ tạm dùng chung với thao tác một mục đơn (xem
  /// `_dat`/`_dan`), rồi thoát luôn chế độ "Chọn nhiều".
  void _datNhieu({required bool laCat}) {
    final tong = _dsThuMucDaChon.length + _dsGhiChuDaChon.length;
    final ten = tong == 1 ? _tenMucDangChonDuyNhat() : '$tong mục';
    setState(() {
      _choDanLaCat = laCat;
      _choDanThuMucIds = _dsThuMucDaChon.toList();
      _choDanGhiChuIds = _dsGhiChuDaChon.toList();
      _choDanTen = ten;
      _dangChonNhieu = false;
      _dsThuMucDaChon.clear();
      _dsGhiChuDaChon.clear();
    });
  }

  /// (YÊU CẦU MỚI) "Chọn màu cho tên" ở thanh hành động "Chọn nhiều" — áp
  /// màu vừa chọn cho TÊN của mọi mục (thư mục + tệp) đang tích chọn, dùng
  /// lại đúng hộp chọn màu của thao tác một mục đơn (`_chonMau`), rồi tự
  /// thoát luôn chế độ "Chọn nhiều".
  Future<void> _chonMauNhieu() async {
    final mau = await hienThiChonMauCoBanChoTen(
      context,
      tieuDe: 'Chọn màu cho tên',
    );
    if (mau == null) return;
    for (final id in _dsThuMucDaChon) {
      _kho.datMauThuMuc(id, mau.value);
    }
    for (final id in _dsGhiChuDaChon) {
      _kho.datMauGhiChu(id, mau.value);
    }
    setState(() {
      _dangChonNhieu = false;
      _dsThuMucDaChon.clear();
      _dsGhiChuDaChon.clear();
    });
    await _kho.luu();
  }

  /// "Chuyển vào thùng rác" ở thanh hành động "Chọn nhiều" — không hỏi xác
  /// nhận, giống hệt khi làm với một mục đơn.
  Future<void> _xoaNhieuVaoThungRac() async {
    final coGhiChuDangMo = _dsGhiChuDaChon.contains(widget.idGhiChuDangMo) ||
        _dsThuMucDaChon.any(
          (id) => _timGhiChuTrongCay(id).any((g) => g.id == widget.idGhiChuDangMo),
        );
    for (final id in _dsThuMucDaChon) {
      _kho.chuyenThuMucVaoThungRac(id);
    }
    for (final id in _dsGhiChuDaChon) {
      _kho.chuyenGhiChuVaoThungRac(id);
    }
    setState(() {
      _dangChonNhieu = false;
      _dsThuMucDaChon.clear();
      _dsGhiChuDaChon.clear();
    });
    await _kho.luu();
    if (!mounted) return;
    _baoDaChuyenVaoThungRac();
    if (coGhiChuDangMo) {
      _bao('Ghi chú đang mở nằm trong mục vừa chuyển vào thùng rác.');
    }
  }

  /// Thanh ghim TRÊN CÙNG khi đang "Chọn nhiều" — thay hẳn cho 3 dòng
  /// thường (quay lại/địa chỉ/tên thư mục), vì lúc này KHÔNG điều hướng đi
  /// đâu cả, chỉ tích chọn.
  Widget _thanhChonNhieu(
    ({List<ThuMuc> thuMucCon, List<GhiChuFile> ghiChuCon})? noiDung,
  ) {
    final tongSo = (noiDung?.thuMucCon.length ?? 0) + (noiDung?.ghiChuCon.length ?? 0);
    final daChonHet = tongSo > 0 &&
        (_dsThuMucDaChon.length + _dsGhiChuDaChon.length) == tongSo;
    return Material(
      color: const Color(0xFFF1F3F4),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // (YÊU CẦU MỚI) Bấm vào chữ "Chọn tất cả" cũng tác động luôn
            // checkbox bên cạnh, không chỉ riêng bấm vào ô vuông.
            InkWell(
              onTap: () => _datChonTatCa(!daChonHet, noiDung),
              child: Row(
                children: [
                  Checkbox(
                    value: daChonHet,
                    onChanged: (v) => _datChonTatCa(v ?? false, noiDung),
                  ),
                  const Text('Chọn tất cả'),
                ],
              ),
            ),
            TextButton(
              onPressed: _huyChonNhieu,
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
              child: const Text('Hủy chọn nhiều'),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh ghim ĐÁY khi đang "Chọn nhiều" — 3 nút liệt sẵn, chỉ sáng lên khi
  /// có ít nhất 1 mục được tích chọn; tự co giãn/xuống dòng theo bề ngang
  /// màn hình (`Wrap`, không phải `Row` cứng).
  Widget _thanhHanhDongChonNhieu() {
    final coChon = _dsThuMucDaChon.isNotEmpty || _dsGhiChuDaChon.isNotEmpty;
    return Material(
      color: const Color(0xFFF1F3F4),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: coChon ? () => _datNhieu(laCat: false) : null,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Sao chép'),
              ),
              TextButton.icon(
                onPressed: coChon ? () => _datNhieu(laCat: true) : null,
                icon: const Icon(Icons.cut_outlined, size: 18),
                label: const Text('Cắt (di chuyển)'),
              ),
              TextButton.icon(
                onPressed: coChon ? _chonMauNhieu : null,
                icon: const Icon(Icons.format_color_text_outlined, size: 18),
                label: const Text('Chọn màu cho tên'),
              ),
              TextButton.icon(
                onPressed: coChon ? _xoaNhieuVaoThungRac : null,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: coChon ? Colors.red.shade600 : null,
                ),
                label: Text(
                  'Chuyển vào thùng rác',
                  style: TextStyle(color: coChon ? Colors.red.shade600 : null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toàn bộ đường đi từ gốc tới thư mục đang xem, gốc luôn ở vị trí 0.
  List<String> get _chuoiDuongDan => [..._duongDan, _thuMucHienTaiId];

  void _nhayToiViTri(int viTri) {
    final chuoi = _chuoiDuongDan;
    if (chuoi[viTri] == _ngoiNhaChung && widget.boNhoDocLap) {
      _thoatKhoiCayDocLap();
      return;
    }
    setState(() {
      _thuMucHienTaiId = chuoi[viTri];
      _duongDan
        ..clear()
        ..addAll(chuoi.sublist(0, viTri));
    });
  }

  /// Tên dài quá thì rút gọn ở thanh địa chỉ, không thì tràn ngang màn hình.
  String _rutGon(String ten) {
    const gioiHan = 20;
    if (ten.length <= gioiHan) return ten;
    return '${ten.substring(0, gioiHan)}…';
  }

  Widget _thanhDiaChi() {
    final chuoi = _chuoiDuongDan;
    final manh = <Widget>[
      InkWell(
        onTap: () => _nhayToiViTri(0),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Icon(Icons.home_outlined, size: 18, color: Color(0xFF5F6368)),
        ),
      ),
    ];

    for (var i = 1; i < chuoi.length; i++) {
      // (YÊU CẦU MỚI) Gốc Bộ nhớ nội bộ không có tên thật trong `_kho` (nó
      // không phải một `ThuMuc` được lưu) — hiện "Nội bộ", chữ ĐỎ, phân
      // biệt hẳn với tên các thư mục con (xanh dương) phía sau.
      final laGocNoiBo = chuoi[i] == thuMucGoc;
      final ten = laGocNoiBo
          ? (_laKhoDamMay ? 'Đám mây' : 'Nội bộ')
          : (_kho.timThuMuc(chuoi[i])?.ten ?? '?');
      final laCuoiCung = i == chuoi.length - 1;
      manh.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Icon(Icons.chevron_right, size: 16, color: Color(0xFFBDBDBD)),
      ));
      manh.add(
        laCuoiCung
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                // Khoá theo id thư mục: mỗi lần bước vào (bằng cách nào cũng
                // vậy — bấm thẻ, bấm lùi, bấm thanh địa chỉ) là một widget
                // MỚI, nên hiệu ứng nhấp nháy tự chạy lại từ đầu mỗi lần.
                child: _ChuMucNhayNhay(
                  key: ValueKey('deang-${chuoi[i]}'),
                  chu: _rutGon(ten),
                  kieuChu: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: laGocNoiBo ? Colors.red.shade700 : null,
                  ),
                ),
              )
            : InkWell(
                onTap: () => _nhayToiViTri(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    _rutGon(ten),
                    style: TextStyle(
                      fontSize: 13,
                      color: laGocNoiBo ? Colors.red.shade700 : const Color(0xFF1A73E8),
                    ),
                  ),
                ),
              ),
      );
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      // Wrap chứ không phải cuộn ngang: chui càng sâu, thanh địa chỉ càng
      // dài, tự động xuống dòng theo đúng bề ngang màn hình đang có, không
      // cần biết trước máy rộng hay hẹp.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 2,
        children: manh,
      ),
    );
  }

  void _bao(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
      );
  }

  /// (YÊU CẦU MỚI) Nội dung của mức "Ngôi nhà chung" — ba "bộ nhớ" lớn.
  /// Chỉ "Bộ nhớ nội bộ" có thật (dẫn vào đúng cây thư mục đã làm xong từ
  /// trước, neo tại `thuMucGoc`); hai cái sau để dành cho sau này (đăng
  /// nhập Google), bấm vào chỉ báo "đang nâng cấp", không điều hướng đi
  /// đâu cả.
  Widget _danhSachNgoiNhaChung() {
    return ListView(
      children: [
        // (YÊU CẦU MỚI) Icon riêng cho từng "bộ nhớ" — hình dạng/ý nghĩa
        // khác hẳn nhau, không còn dùng chung icon thư mục vàng cho cả ba.
        ListTile(
          leading: Icon(Icons.smartphone, color: Colors.blue.shade700),
          title: Text(_tenBoNhoNoiBo),
          onTap: () => _moThuMuc(thuMucGoc),
        ),
        ListTile(
          leading: Icon(Icons.cloud_outlined, color: Colors.lightBlue.shade400),
          title: const Text('Bộ nhớ trên đám mây'),
          onTap: _moBoNhoDamMay,
        ),
        ListTile(
          leading: Icon(Icons.folder_shared_outlined, color: Colors.green.shade600),
          title: const Text('Bộ nhớ được chia sẻ với bạn'),
          onTap: _baoDangNangCap,
        ),
      ],
    );
  }

  /// (YÊU CẦU MỚI) Thanh ngang TRÊN TẤT CẢ — luôn hiện bất kể đang ở Ngôi
  /// nhà chung hay trong bất kỳ thư mục nào. "Quay lại Trang soạn thảo"
  /// (trái) đóng hẳn màn hình này; "Vị trí Tệp đang soạn thảo" (phải) nhảy
  /// thẳng tới thư mục chứa tệp đang mở.
  Widget _thanhQuayLaiVaViTriTep() {
    return Material(
      color: const Color(0xFFF1F3F4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _veTrangSoanThao,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Quay lại Trang soạn thảo'),
          ),
          TextButton.icon(
            onPressed: _toiViTriTepDangSoanThao,
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Vị trí Tệp đang soạn thảo'),
          ),
        ],
      ),
    );
  }

  /// (YÊU CẦU MỚI) Thanh ghim đáy màn hình, chỉ hiện ở gốc mỗi cây — chữ co
  /// giãn/tự xuống dòng theo bề ngang màn hình (`Wrap`/`Text` thường trong
  /// `Padding` co giãn tự nhiên, không cần ép chiều cao cố định).
  Widget _thanhChuThichBoNhoNoiBo() {
    final chu = _laKhoDamMay
        ? 'Bộ nhớ này lưu trên máy chủ đám mây, có thể truy cập bộ nhớ này '
            'ở bất cứ thiết bị nào nếu có internet và đăng nhập bằng tài '
            'khoản này, App tự động lưu file lên bộ nhớ đám mây khi soạn thảo'
        : kIsWeb
            ? 'Bộ nhớ nội bộ này lưu tại trình duyệt web này của thiết bị, '
                'riêng tư tuyệt đối, nếu xoá Tệp và dữ liệu trang web thì bộ '
                'nhớ nội bộ này sẽ bị xoá theo. App tự động lưu file mỗi khi '
                'có sự thay đổi mà không cần bấm nút lưu file.'
            : 'Bộ nhớ nội bộ này lưu tại thiết bị, riêng tư và an toàn. App '
                'tự động lưu file mỗi khi có sự thay đổi mà không cần bấm '
                'nút lưu file.';
    return Material(
      color: const Color(0xFFF1F3F4),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            chu,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
          ),
        ),
      ),
    );
  }

  /// (YÊU CẦU MỚI) Dòng tên thư mục hiện tại + các nút thêm/sửa — y hệt
  /// `AppBar` cũ (title/leading/actions), chỉ dời vào hẳn trong `body` làm
  /// dòng thứ BA, dưới thanh địa chỉ.
  Widget _dongTenThuMucVaNutThem({required bool laNgoiNhaChung}) {
    // (YÊU CẦU MỚI) Nền xanh dương cho cả thanh — đổi luôn màu chữ/icon
    // sang trắng để còn đọc được (trừ tên thư mục gốc, vẫn giữ đỏ nổi bật
    // như cũ, đủ tương phản trên nền xanh).
    return Material(
      elevation: 1,
      color: const Color(0xFF1A73E8),
      child: IconTheme(
        data: const IconThemeData(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              if (_duongDan.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _veThuMucCha,
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: _duongDan.isEmpty ? 16 : 0),
                  child: Text(
                    _tenThuMucHienTai,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      // (YÊU CẦU MỚI) Đứng ngay gốc Bộ nhớ nội bộ — chữ đỏ,
                      // phân biệt với tên các thư mục con bên trong.
                      color: _thuMucHienTaiId == thuMucGoc
                          ? Colors.red.shade100
                          : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // (YÊU CẦU MỚI) "Ngôi nhà chung" chỉ để CHỌN một trong 3 bộ
            // nhớ — không có gì để thêm/sửa ở chính mức này.
            if (!laNgoiNhaChung) ...[
              ..._haiNutCuonLenXuongThuMuc(),
              IconButton(
                onPressed: _themGhiChu,
                icon: const Icon(Icons.note_add_outlined),
                tooltip: 'Thêm ghi chú',
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Thêm',
                onSelected: (v) {
                  switch (v) {
                    case 1:
                      _themThuMuc();
                      break;
                    case 6:
                      _nhapZip();
                      break;
                    case 2:
                      _batDauChonNhieu();
                      break;
                    case 3:
                      _taiThuMucHienTai();
                      break;
                    case 5:
                      _moThungRac();
                      break;
                    case 4:
                      hienThongTinThuMuc(
                        context,
                        _kho,
                        id: _thuMucHienTaiId,
                        ten: _tenThuMucHienTai,
                      );
                      break;
                    case 7:
                      _moTimKiemTrongThuMuc(_thuMucHienTaiId, _tenThuMucHienTai);
                      break;
                    case 8:
                      widget.caiDat.datSapXepNguoc(_thuMucHienTaiId, false);
                      setState(() {});
                      break;
                    case 9:
                      widget.caiDat.datSapXepNguoc(_thuMucHienTaiId, true);
                      setState(() {});
                      break;
                  }
                },
                itemBuilder: (ctx) {
                  final dangNguoc = widget.caiDat.sapXepNguoc(_thuMucHienTaiId);
                  return [
                    PopupMenuItem(
                      value: 8,
                      child: Row(children: [
                        if (!dangNguoc) const Icon(Icons.check, size: 18),
                        if (!dangNguoc) const SizedBox(width: 6),
                        const Text('Sắp xếp A → Z'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 9,
                      child: Row(children: [
                        if (dangNguoc) const Icon(Icons.check, size: 18),
                        if (dangNguoc) const SizedBox(width: 6),
                        const Text('Sắp xếp Z → A'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 1, child: Text('Tạo thư mục mới')),
                    const PopupMenuItem(value: 6, child: Text('Nhập ZIP hoặc TXT vào đây')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 2, child: Text('Chọn nhiều')),
                    const PopupMenuItem(value: 3, child: Text('Tải và chia sẻ thư mục này')),
                    const PopupMenuItem(value: 4, child: Text('Thông tin thư mục này')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 5, child: Text('Thùng rác Nội bộ')),
                    const PopupMenuItem(value: 7, child: Text('Tìm kiếm trong này')),
                  ];
                },
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------- "Tìm kiếm trong này"

  void _moTimKiemTrongThuMuc(String chaId, String ten) {
    setState(() {
      _dangTimKiem = true;
      _timKiemTrongThuMucId = chaId;
      _timKiemTrongThuMucTen = ten;
      _oTimKiemThuMuc.clear();
    });
  }

  void _tatTimKiem() {
    setState(() {
      _dangTimKiem = false;
      _timKiemTrongThuMucId = null;
      _timKiemTrongThuMucTen = '';
      _oTimKiemThuMuc.clear();
    });
  }

  /// Bấm vào một THƯ MỤC trong kết quả tìm kiếm — đóng hẳn modal tìm kiếm,
  /// cây thư mục đi thẳng vào bên trong thư mục đó.
  void _chonThuMucTuKetQuaTim(ThuMuc t) {
    setState(() {
      _dangTimKiem = false;
      _timKiemTrongThuMucId = null;
      _timKiemTrongThuMucTen = '';
      _oTimKiemThuMuc.clear();
      _duongDan.add(_thuMucHienTaiId);
      _thuMucHienTaiId = t.id;
    });
  }

  /// Thu thập ĐỆ QUY mọi thư mục con/tệp con (mọi tầng, bỏ qua mục đang
  /// trong Thùng rác — `noiDungThuMuc` đã tự lọc) bên trong [chaId].
  ({List<ThuMuc> thuMuc, List<GhiChuFile> ghiChu}) _thuThapDeQuy(String chaId) {
    final noiDung = _kho.noiDungThuMuc(chaId);
    final dsThuMuc = <ThuMuc>[...noiDung.thuMucCon];
    final dsGhiChu = <GhiChuFile>[...noiDung.ghiChuCon];
    for (final t in noiDung.thuMucCon) {
      final con = _thuThapDeQuy(t.id);
      dsThuMuc.addAll(con.thuMuc);
      dsGhiChu.addAll(con.ghiChu);
    }
    return (thuMuc: dsThuMuc, ghiChu: dsGhiChu);
  }

  /// 4 nhóm kết quả, ĐÚNG thứ tự xếp từ trên xuống đã yêu cầu: thư mục
  /// khớp có-dấu, tệp khớp có-dấu, thư mục chỉ khớp sau khi bỏ dấu, tệp
  /// chỉ khớp sau khi bỏ dấu. Rỗng (chưa gõ gì) thì trả về 4 danh sách
  /// rỗng.
  ({
    List<ThuMuc> tmCoDau,
    List<GhiChuFile> gcCoDau,
    List<ThuMuc> tmKhongDau,
    List<GhiChuFile> gcKhongDau,
  }) _ketQuaTimKiemTrongThuMuc(String chaId, String tuKhoaTho) {
    final tuKhoa = tuKhoaTho.trim();
    if (tuKhoa.isEmpty) {
      return (tmCoDau: [], gcCoDau: [], tmKhongDau: [], gcKhongDau: []);
    }
    final tuKhoaThuong = tuKhoa.toLowerCase();
    final tuKhoaKhongDau = _boDauTiengViet(tuKhoa);
    final tatCa = _thuThapDeQuy(chaId);

    final tmCoDau = <ThuMuc>[];
    final tmKhongDau = <ThuMuc>[];
    for (final t in tatCa.thuMuc) {
      if (t.ten.toLowerCase().contains(tuKhoaThuong)) {
        tmCoDau.add(t);
      } else if (_boDauTiengViet(t.ten).contains(tuKhoaKhongDau)) {
        tmKhongDau.add(t);
      }
    }
    final gcCoDau = <GhiChuFile>[];
    final gcKhongDau = <GhiChuFile>[];
    for (final g in tatCa.ghiChu) {
      if (g.ten.toLowerCase().contains(tuKhoaThuong)) {
        gcCoDau.add(g);
      } else if (_boDauTiengViet(g.ten).contains(tuKhoaKhongDau)) {
        gcKhongDau.add(g);
      }
    }
    int soTen(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    tmCoDau.sort((a, b) => soTen(a.ten, b.ten));
    tmKhongDau.sort((a, b) => soTen(a.ten, b.ten));
    gcCoDau.sort((a, b) => soTen(a.ten, b.ten));
    gcKhongDau.sort((a, b) => soTen(a.ten, b.ten));
    return (tmCoDau: tmCoDau, gcCoDau: gcCoDau, tmKhongDau: tmKhongDau, gcKhongDau: gcKhongDau);
  }

  // (YÊU CẦU MỚI) Nút ba chấm ở kết quả tìm kiếm — y chang menu thả xuống
  // của thư mục ở ngoài cây (cùng lựa chọn, cùng logic, chỉ tách ra đây để
  // dùng lại được ở cả hàng bình thường và hàng kết quả tìm kiếm).
  Widget _menuBaChamThuMuc(ThuMuc t) => PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'doi_ten':
              _doiTen(laThuMuc: true, id: t.id, tenCu: t.ten);
              break;
            case 'cat':
              _dat(laCat: true, laThuMuc: true, id: t.id, ten: t.ten);
              break;
            case 'chep':
              _dat(laCat: false, laThuMuc: true, id: t.id, ten: t.ten);
              break;
            case 'mau':
              _chonMau(laThuMuc: true, id: t.id);
              break;
            case 'tai':
              _taiThuMuc(t.id, t.ten);
              break;
            case 'thong_tin':
              hienThongTinThuMuc(context, _kho, id: t.id, ten: t.ten);
              break;
            case 'xoa':
              _xoaThuMuc(t);
              break;
          }
        },
        itemBuilder: (ctx) => const [
          PopupMenuItem(value: 'doi_ten', child: Text('Đổi tên')),
          PopupMenuItem(value: 'cat', child: Text('Cắt (di chuyển)')),
          PopupMenuItem(value: 'chep', child: Text('Sao chép')),
          PopupMenuItem(value: 'mau', child: Text('Chọn màu Tên Thư mục')),
          PopupMenuItem(value: 'tai', child: Text('Tải và chia sẻ thư mục này')),
          PopupMenuItem(value: 'thong_tin', child: Text('Thông tin thư mục này')),
          PopupMenuItem(value: 'xoa', child: Text('Chuyển vào thùng rác')),
        ],
      );

  // (YÊU CẦU MỚI) Tương tự cho tệp — y chang menu thả xuống của tệp ở ngoài
  // cây thư mục.
  Widget _menuBaChamGhiChu(GhiChuFile g) => PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'doi_ten':
              _doiTen(laThuMuc: false, id: g.id, tenCu: g.ten);
              break;
            case 'cat':
              _dat(laCat: true, laThuMuc: false, id: g.id, ten: g.ten);
              break;
            case 'chep':
              _dat(laCat: false, laThuMuc: false, id: g.id, ten: g.ten);
              break;
            case 'tai_ve':
              _taiVeGhiChu(g);
              break;
            case 'mau':
              _chonMau(laThuMuc: false, id: g.id);
              break;
            case 'thong_tin':
              hienThongTinGhiChu(context, ten: g.ten, noiDung: g.noiDung);
              break;
            case 'xoa':
              _xoaGhiChu(g);
              break;
          }
        },
        itemBuilder: (ctx) => const [
          PopupMenuItem(value: 'doi_ten', child: Text('Đổi tên')),
          PopupMenuItem(value: 'cat', child: Text('Cắt (di chuyển)')),
          PopupMenuItem(value: 'chep', child: Text('Sao chép')),
          PopupMenuItem(value: 'tai_ve', child: Text('Tải về')),
          PopupMenuItem(value: 'mau', child: Text('Chọn màu Tên Tệp')),
          PopupMenuItem(value: 'thong_tin', child: Text('Thông tin tệp này')),
          PopupMenuItem(value: 'xoa', child: Text('Chuyển vào thùng rác')),
        ],
      );

  Widget _dongKetQuaTimThuMuc(ThuMuc t) => ListTile(
        leading: Icon(Icons.folder, color: Colors.amber.shade700),
        title: Text(t.ten, style: t.mau != null ? TextStyle(color: Color(t.mau!)) : null),
        onTap: () => _chonThuMucTuKetQuaTim(t),
        // (YÊU CẦU MỚI) Nút ba chấm ở mép phải — y chang menu ở ngoài cây.
        trailing: _menuBaChamThuMuc(t),
      );

  Widget _dongKetQuaTimGhiChu(GhiChuFile g) => ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(g.ten, style: g.mau != null ? TextStyle(color: Color(g.mau!)) : null),
        onTap: () => Navigator.of(context).pop(g.id),
        // (YÊU CẦU MỚI) Nút ba chấm ở mép phải — y chang menu ở ngoài cây.
        trailing: _menuBaChamGhiChu(g),
      );

  Widget _buildTimKiem(BuildContext context) {
    final ketQua = _ketQuaTimKiemTrongThuMuc(_timKiemTrongThuMucId!, _oTimKiemThuMuc.text);
    final coGoTim = _oTimKiemThuMuc.text.trim().isNotEmpty;
    final rong = ketQua.tmCoDau.isEmpty &&
        ketQua.gcCoDau.isEmpty &&
        ketQua.tmKhongDau.isEmpty &&
        ketQua.gcKhongDau.isEmpty;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (daThoat, _) {
        if (!daThoat) _tatTimKiem();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Material(
                color: const Color(0xFFF1F3F4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Tìm kiếm trong "$_timKiemTrongThuMucTen"',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Material(
                color: const Color(0xFFF1F3F4),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _oTimKiemThuMuc,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Nhập tên tệp hoặc thư mục...',
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      _NutXoaTimKiemThuMuc(
                        onXoa: () => setState(() => _oTimKiemThuMuc.clear()),
                      ),
                      TextButton(
                        onPressed: _tatTimKiem,
                        style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
                        child: const Text('Tắt'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: !coGoTim
                    ? const Center(
                        child: Text(
                          'Nhập ký tự để tìm kiếm',
                          style: TextStyle(color: Color(0xFF9AA0A6)),
                        ),
                      )
                    : rong
                        ? const Center(
                            child: Text(
                              'Không tìm thấy kết quả',
                              style: TextStyle(color: Color(0xFF9AA0A6)),
                            ),
                          )
                        : ListView(
                            children: [
                              for (final t in ketQua.tmCoDau) _dongKetQuaTimThuMuc(t),
                              for (final g in ketQua.gcCoDau) _dongKetQuaTimGhiChu(g),
                              for (final t in ketQua.tmKhongDau) _dongKetQuaTimThuMuc(t),
                              for (final g in ketQua.gcKhongDau) _dongKetQuaTimGhiChu(g),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dangTimKiem && _timKiemTrongThuMucId != null) {
      return _buildTimKiem(context);
    }
    // (YÊU CẦU MỚI) "Ngôi nhà chung" không phải thư mục thật trong `_kho` —
    // KHÔNG đưa `_ngoiNhaChung` vào `noiDungThuMuc` (id không tồn tại).
    final laNgoiNhaChung = _thuMucHienTaiId == _ngoiNhaChung;
    final noiDung = laNgoiNhaChung
        ? null
        : _kho.noiDungThuMuc(
            _thuMucHienTaiId,
            nguoc: widget.caiDat.sapXepNguoc(_thuMucHienTaiId),
          );
    final trong = noiDung == null
        ? false
        : noiDung.thuMucCon.isEmpty && noiDung.ghiChuCon.isEmpty;

    return PopScope(
      canPop: !_dangChonNhieu && _duongDan.isEmpty,
      onPopInvokedWithResult: (daThoat, ketQua) {
        if (daThoat) return;
        if (_dangChonNhieu) {
          _huyChonNhieu();
        } else {
          _veThuMucCha();
        }
      },
      child: Scaffold(
        // (YÊU CẦU MỚI) Bỏ hẳn `AppBar` — ba dòng ngang giờ xếp lại thành:
        // (1) thanh "Quay lại Trang soạn thảo"/"Vị trí Tệp đang soạn thảo"
        //     — TRÊN TẤT CẢ, luôn hiện bất kể đang ở đâu;
        // (2) thanh địa chỉ (chỉ hiện khi không ở Ngôi nhà chung);
        // (3) dòng tên thư mục hiện tại + các nút thêm/sửa (y hệt AppBar
        //     cũ, chỉ dời xuống hàng riêng trong `body` thay vì `appBar:`).
        // Không còn `AppBar` tự lo khoảng né status bar nữa — `SafeArea`
        // bọc ngoài `body` để thay việc đó.
        // (YÊU CẦU MỚI) "Chọn nhiều" thay hẳn 3 dòng trên cùng bằng MỘT
        // thanh "Chọn tất cả"/"Hủy chọn nhiều" — không điều hướng, chỉ tích
        // chọn.
        body: SafeArea(
          child: Column(
          children: [
            if (_dangChonNhieu)
              _thanhChonNhieu(noiDung)
            else ...[
              _thanhQuayLaiVaViTriTep(),
              if (_duongDan.isNotEmpty) _thanhDiaChi(),
              _dongTenThuMucVaNutThem(laNgoiNhaChung: laNgoiNhaChung),
            ],
            Expanded(
              child: laNgoiNhaChung
                  ? _danhSachNgoiNhaChung()
                  : trong
                  ? const Center(
                      child: Text(
                        'Thư mục trống',
                        style: TextStyle(color: Color(0xFF9AA0A6)),
                      ),
                    )
                  : ListView(
                      controller: _cuonDanhSachThuMuc,
                      children: [
                        for (final t in noiDung!.thuMucCon)
                          ListTile(
                            // (YÊU CẦU MỚI) "Chọn nhiều": thêm checkbox ở
                            // ngoài cùng bên trái, nhưng vẫn giữ icon thư
                            // mục bên cạnh — không còn mở được gì khác, chỉ
                            // chọn/bỏ chọn.
                            leading: _dangChonNhieu
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _dsThuMucDaChon.contains(t.id),
                                        onChanged: (_) => _toggleChonThuMuc(t.id),
                                      ),
                                      Icon(Icons.folder, color: Colors.amber.shade700),
                                    ],
                                  )
                                // Vàng rực để phân biệt ngay với icon ghi
                                // chú (xám) — liếc mắt là biết đâu là thư
                                // mục. Opacity 0/1 mỗi giây trong 10 giây
                                // đầu nếu vừa dán/nhập/khôi phục tới đây.
                                : Opacity(
                                    opacity: _hienIconLucNay(t.id) ? 1 : 0,
                                    child: Icon(Icons.folder, color: Colors.amber.shade700),
                                  ),
                            // Vừa được khôi phục từ Thùng rác và nhảy tới
                            // đây — nhấp nháy để thu hút chú ý, dùng lại
                            // đúng hiệu ứng `_ChuMucNhayNhay`.
                            title: t.id == _idMucCanNhayNhay
                                ? _ChuMucNhayNhay(
                                    key: ValueKey('nhay-tep-$_demLanNhayToiTep'),
                                    chu: t.ten,
                                    kieuChu: TextStyle(
                                      color: t.mau != null ? Color(t.mau!) : null,
                                    ),
                                  )
                                : Text(
                                    t.ten,
                                    style: t.mau != null
                                        ? TextStyle(color: Color(t.mau!))
                                        : null,
                                  ),
                            onTap: _dangChonNhieu
                                ? () => _toggleChonThuMuc(t.id)
                                : () => _moThuMuc(t.id),
                            trailing: _dangChonNhieu
                                ? null
                                : PopupMenuButton<String>(
                              onSelected: (v) {
                                switch (v) {
                                  case 'doi_ten':
                                    _doiTen(
                                      laThuMuc: true,
                                      id: t.id,
                                      tenCu: t.ten,
                                    );
                                    break;
                                  case 'cat':
                                    _dat(laCat: true, laThuMuc: true, id: t.id, ten: t.ten);
                                    break;
                                  case 'chep':
                                    _dat(laCat: false, laThuMuc: true, id: t.id, ten: t.ten);
                                    break;
                                  case 'mau':
                                    _chonMau(laThuMuc: true, id: t.id);
                                    break;
                                  case 'tai':
                                    _taiThuMuc(t.id, t.ten);
                                    break;
                                  case 'thong_tin':
                                    hienThongTinThuMuc(
                                      context,
                                      _kho,
                                      id: t.id,
                                      ten: t.ten,
                                    );
                                    break;
                                  case 'xoa':
                                    _xoaThuMuc(t);
                                    break;
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(
                                  value: 'doi_ten',
                                  child: Text('Đổi tên'),
                                ),
                                PopupMenuItem(
                                  value: 'cat',
                                  child: Text('Cắt (di chuyển)'),
                                ),
                                PopupMenuItem(
                                  value: 'chep',
                                  child: Text('Sao chép'),
                                ),
                                PopupMenuItem(
                                  value: 'mau',
                                  child: Text('Chọn màu Tên Thư mục'),
                                ),
                                PopupMenuItem(
                                  value: 'tai',
                                  child: Text('Tải và chia sẻ thư mục này'),
                                ),
                                PopupMenuItem(
                                  value: 'thong_tin',
                                  child: Text('Thông tin thư mục này'),
                                ),
                                PopupMenuItem(
                                  value: 'xoa',
                                  child: Text('Chuyển vào thùng rác'),
                                ),
                              ],
                            ),
                          ),
                        for (final g in noiDung!.ghiChuCon)
                          ListTile(
                            key: g.id == _idMucCanNhayNhay
                                ? _khoaMucVuaNhayToi
                                : null,
                            leading: _dangChonNhieu
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _dsGhiChuDaChon.contains(g.id),
                                        onChanged: (_) => _toggleChonGhiChu(g.id),
                                      ),
                                      const Icon(Icons.description_outlined),
                                    ],
                                  )
                                : Opacity(
                                    opacity: _hienIconLucNay(g.id) ? 1 : 0,
                                    child: const Icon(Icons.description_outlined),
                                  ),
                            // (YÊU CẦU MỚI) Vừa nhảy tới đây qua nút "Vị trí
                            // Tệp đang soạn thảo" — phóng to/thu nhỏ vài lần
                            // để thu hút chú ý, ĐÚNG hệt hiệu ứng tên thư
                            // mục ở thanh địa chỉ (`_ChuMucNhayNhay`).
                            title: g.id == _idMucCanNhayNhay
                                ? _ChuMucNhayNhay(
                                    key: ValueKey('nhay-tep-$_demLanNhayToiTep'),
                                    chu: g.ten,
                                    kieuChu: TextStyle(
                                      color: g.mau != null ? Color(g.mau!) : null,
                                    ),
                                  )
                                : Text(
                                    g.ten,
                                    style: g.mau != null
                                        ? TextStyle(color: Color(g.mau!))
                                        : null,
                                  ),
                            selected: g.id == widget.idGhiChuDangMo,
                            selectedTileColor: const Color(0xFFE8F0FE),
                            onTap: _dangChonNhieu
                                ? () => _toggleChonGhiChu(g.id)
                                : () => Navigator.of(context).pop(g.id),
                            trailing: _dangChonNhieu
                                ? null
                                : PopupMenuButton<String>(
                              onSelected: (v) {
                                switch (v) {
                                  case 'doi_ten':
                                    _doiTen(
                                      laThuMuc: false,
                                      id: g.id,
                                      tenCu: g.ten,
                                    );
                                    break;
                                  case 'cat':
                                    _dat(laCat: true, laThuMuc: false, id: g.id, ten: g.ten);
                                    break;
                                  case 'chep':
                                    _dat(laCat: false, laThuMuc: false, id: g.id, ten: g.ten);
                                    break;
                                  case 'tai_ve':
                                    _taiVeGhiChu(g);
                                    break;
                                  case 'mau':
                                    _chonMau(laThuMuc: false, id: g.id);
                                    break;
                                  case 'thong_tin':
                                    hienThongTinGhiChu(
                                      context,
                                      ten: g.ten,
                                      noiDung: g.noiDung,
                                    );
                                    break;
                                  case 'xoa':
                                    _xoaGhiChu(g);
                                    break;
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(
                                  value: 'doi_ten',
                                  child: Text('Đổi tên'),
                                ),
                                PopupMenuItem(
                                  value: 'cat',
                                  child: Text('Cắt (di chuyển)'),
                                ),
                                PopupMenuItem(
                                  value: 'chep',
                                  child: Text('Sao chép'),
                                ),
                                PopupMenuItem(
                                  value: 'tai_ve',
                                  child: Text('Tải về'),
                                ),
                                PopupMenuItem(
                                  value: 'mau',
                                  child: Text('Chọn màu Tên Tệp'),
                                ),
                                PopupMenuItem(
                                  value: 'thong_tin',
                                  child: Text('Thông tin tệp này'),
                                ),
                                PopupMenuItem(
                                  value: 'xoa',
                                  child: Text('Chuyển vào thùng rác'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            // (YÊU CẦU MỚI) "Chọn nhiều" thay hẳn mọi thanh ghim đáy khác
            // (chú thích gốc/dán) bằng MỘT thanh hành động riêng.
            if (_dangChonNhieu) _thanhHanhDongChonNhieu(),
            // Ghim ở ĐÁY, chỉ hiện đúng tại thư mục gốc của Bộ nhớ nội bộ —
            // chú thích riêng-tư khác nhau giữa web (lưu trong trình
            // duyệt, mất khi xoá Tệp và dữ liệu trang web) và app APK/iOS
            // (lưu thẳng trên máy).
            if (!_dangChonNhieu && _thuMucHienTaiId == thuMucGoc)
              _thanhChuThichBoNhoNoiBo(),
            if (!_dangChonNhieu && _coDangChoDan)
              Material(
                color: const Color(0xFFE8F0FE),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.content_paste,
                          size: 18,
                          color: Color(0xFF1A73E8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đang giữ "$_choDanTen" — dán vào đây?',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _huyChoDan,
                          child: const Text('Huỷ'),
                        ),
                        FilledButton(
                          onPressed: _dan,
                          child: const Text('Dán'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // (YÊU CẦU MỚI) Đang chờ "Chọn vị trí khác" cho một tệp .zip
            // vừa nhập — đi dạo thoải mái, bấm "Đưa vào chỗ này" ở ĐÚNG nơi
            // muốn, cùng kiểu với thanh "Dán" ở trên.
            if (!_dangChonNhieu && _zipDangChoNhap != null)
              Material(
                color: const Color(0xFFE8F0FE),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.unarchive_outlined,
                          size: 18,
                          color: Color(0xFF1A73E8),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Đang chờ nhập tệp nén — đưa vào đây?',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: _huyZipDangChoNhap,
                          child: const Text('Huỷ'),
                        ),
                        FilledButton(
                          onPressed: _dayZipVaoDay,
                          child: const Text('Đưa vào chỗ này'),
                        ),
                      ],
                    ),
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

/// Bỏ dấu tiếng Việt + hạ chữ thường — dùng cho "Tìm kiếm trong này" khớp cả
/// không dấu (ví dụ gõ "Thắng" vẫn ra "thằng"/"tháng"/"thang"...).
String _boDauTiengViet(String s) {
  const banDo = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
  };
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    buf.write(banDo[ch] ?? ch);
  }
  return buf.toString();
}

/// Nút "X" xoá ô nhập "Tìm kiếm trong này" — cùng kiểu với `_NutXoaCoThongBao`
/// ở màn hình soạn thảo chính (bấm xong tự đổi thành "Đã xoá" trong 1,5 giây
/// rồi quay lại nút X), viết riêng ở đây vì widget gốc là `private` của tệp
/// khác.
class _NutXoaTimKiemThuMuc extends StatefulWidget {
  const _NutXoaTimKiemThuMuc({required this.onXoa});
  final VoidCallback onXoa;

  @override
  State<_NutXoaTimKiemThuMuc> createState() => _NutXoaTimKiemThuMucState();
}

class _NutXoaTimKiemThuMucState extends State<_NutXoaTimKiemThuMuc> {
  bool _vuaXoa = false;
  Timer? _hen;

  @override
  void dispose() {
    _hen?.cancel();
    super.dispose();
  }

  void _bam() {
    widget.onXoa();
    setState(() => _vuaXoa = true);
    _hen?.cancel();
    _hen = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _vuaXoa = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_vuaXoa) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'Đã xoá',
          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
        ),
      );
    }
    return IconButton(
      icon: Icon(Icons.close, color: Colors.green.shade700),
      tooltip: 'Xoá',
      onPressed: _bam,
    );
  }
}

/// Tên thư mục hiện tại ở thanh địa chỉ: phóng to gấp 1,4 lần rồi thu nhỏ lại
/// mượt mà, lặp 4 lần rồi đứng im hẳn. Chạy đúng một lần khi widget này được
/// TẠO MỚI — nơi gọi nó chịu trách nhiệm đổi `key` mỗi lần bước vào một thư
/// mục để widget được dựng lại từ đầu, hiệu ứng nhờ vậy tự chạy lại.
class _ChuMucNhayNhay extends StatefulWidget {
  const _ChuMucNhayNhay({required super.key, required this.chu, required this.kieuChu});

  final String chu;
  final TextStyle kieuChu;

  @override
  State<_ChuMucNhayNhay> createState() => _ChuMucNhayNhayState();
}

class _ChuMucNhayNhayState extends State<_ChuMucNhayNhay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dieuKhien;
  late final Animation<double> _tiLe;

  @override
  void initState() {
    super.initState();
    _dieuKhien = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _tiLe = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _dieuKhien, curve: Curves.easeInOut),
    );
    // reverse:true để mỗi chu kỳ tự phóng to rồi thu nhỏ mượt mà; count:4 để
    // lặp đúng 4 lần rồi tự dừng hẳn, không lặp mãi.
    _dieuKhien.repeat(reverse: true, count: 4);
  }

  @override
  void dispose() {
    _dieuKhien.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _tiLe,
      alignment: Alignment.centerLeft,
      child: Text(widget.chu, style: widget.kieuChu),
    );
  }
}
