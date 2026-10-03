// Màn hình cây thư mục: xem, thêm, đổi tên, xoá, sao chép, cắt-di chuyển thư
// mục và ghi chú. Bấm vào một ghi chú thì trả id của nó về cho trang soạn
// thảo qua Navigator.pop; đi dạo rồi quay lại tay không thì trả về null.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kho_du_lieu.dart';
import 'mau_co_ban.dart';
import 'mo_hinh.dart';
import 'tai_ve_ghi_chu.dart';
import 'thong_bao_giua.dart';

enum _LoaiChoDan { catThuMuc, catGhiChu, chepThuMuc, chepGhiChu }

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
  });

  final KhoDuLieu kho;
  final String idGhiChuDangMo;

  @override
  State<ManHinhThuMuc> createState() => _ManHinhThuMucState();
}

class _ManHinhThuMucState extends State<ManHinhThuMuc> {
  String _thuMucHienTaiId = _ngoiNhaChung;
  final List<String> _duongDan = []; // Ngăn xếp id thư mục cha, để quay lại.

  String? _choDanId;
  _LoaiChoDan? _choDanLoai;
  String _choDanTen = '';

  KhoDuLieu get _kho => widget.kho;

  @override
  void initState() {
    super.initState();
    // (YÊU CẦU MỚI) Có nhớ từ lần mở trước (trong CÙNG phiên app) thì vào
    // đúng chỗ đó; chưa có gì (lần đầu, hoặc vừa F5/mở lại app) thì mặc
    // định đi thẳng tới thư mục đang chứa tệp mở ở trang soạn thảo.
    final nhoId = _nhoThuMucId;
    final nhoDuongDan = _nhoDuongDan;
    if (nhoId != null && nhoDuongDan != null) {
      _thuMucHienTaiId = nhoId;
      _duongDan.addAll(nhoDuongDan);
    } else {
      final thuMucId = _thuMucChuaTepDangSoanThao;
      _thuMucHienTaiId = thuMucId;
      _duongDan.addAll(_duongDanToiThuMuc(thuMucId));
    }
  }

  @override
  void dispose() {
    // Ghi lại NGAY LÚC rời màn hình — lần mở kế tiếp (vẫn trong phiên app
    // này) đọc lại đúng ở `initState`.
    _nhoThuMucId = _thuMucHienTaiId;
    _nhoDuongDan = List<String>.from(_duongDan);
    super.dispose();
  }

  /// (YÊU CẦU MỚI) Tên thư mục "Bộ nhớ nội bộ" — khác nhau giữa bản web
  /// (đọc từ Trình duyệt web) và bản APK/iOS (đọc thẳng từ máy).
  String get _tenBoNhoNoiBo => kIsWeb
      ? 'Bộ nhớ nội bộ trong Trình duyệt web của thiết bị'
      : 'Bộ nhớ nội bộ trong thiết bị';

  String get _tenThuMucHienTai {
    if (_thuMucHienTaiId == _ngoiNhaChung) return 'Chọn nơi lưu trữ';
    // (YÊU CẦU MỚI) Đứng NGAY tại gốc Bộ nhớ nội bộ (không phải một thư mục
    // con nào bên trong) — đổi tên hiển thị, xem màu ở `_dongTenThuMuc`.
    if (_thuMucHienTaiId == thuMucGoc) return 'Bộ nhớ Nội bộ';
    return _kho.timThuMuc(_thuMucHienTaiId)?.ten ?? 'Bộ nhớ Nội bộ';
  }

  /// (YÊU CẦU MỚI) "Bộ nhớ trên đám mây"/"Bộ nhớ được chia sẻ với bạn" —
  /// để dành cho sau này (đăng nhập Google), chưa làm gì cả ngoài báo biết.
  void _baoDangNangCap() {
    hienThongBaoGiua(context, 'Tính năng đang nâng cấp');
  }

  // (YÊU CẦU MỚI) Bộ nhớ đệm "đang đứng ở đâu" — chỉ là biến `static` sống
  // trong RAM của phiên app hiện tại: F5 (web) hay tắt/mở lại app là mất,
  // ĐÚNG ý yêu cầu "dễ dàng bị xoá". Ghi lại ở `dispose()`, đọc lại ở
  // `initState()` của LẦN MỞ SAU — same type (`ManHinhThuMuc`) nhưng là một
  // instance State hoàn toàn mới mỗi lần Navigator.push, nên không thể
  // dùng field thường (field thường mất theo State khi màn hình đóng).
  static String? _nhoThuMucId;
  static List<String>? _nhoDuongDan;

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
  String? _idGhiChuCanNhayNhay;
  int _demLanNhayToiTep = 0;

  void _veTrangSoanThao() => Navigator.of(context).pop();

  void _toiViTriTepDangSoanThao() {
    final thuMucId = _thuMucChuaTepDangSoanThao;
    setState(() {
      _thuMucHienTaiId = thuMucId;
      _duongDan
        ..clear()
        ..addAll(_duongDanToiThuMuc(thuMucId));
      _idGhiChuCanNhayNhay = widget.idGhiChuDangMo;
      _demLanNhayToiTep++;
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
    setState(() => _thuMucHienTaiId = _duongDan.removeLast());
    return true;
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

  Future<void> _xoaThuMuc(ThuMuc t) async {
    final coNoiDung = _kho.thuMuc.any((x) => x.chaId == t.id) ||
        _kho.ghiChu.any((x) => x.chaId == t.id);
    final dongY = await _hoiXoa(
      ten: t.ten,
      canhBao: coNoiDung ? ' và toàn bộ nội dung bên trong nó' : '',
    );
    if (dongY != true) return;
    final xoaCaGhiChuDangMo =
        _timGhiChuTrongCay(t.id).any((g) => g.id == widget.idGhiChuDangMo);
    setState(() => _kho.xoaThuMuc(t.id));
    await _kho.luu();
    if (xoaCaGhiChuDangMo && mounted) {
      _bao('Ghi chú đang mở nằm trong thư mục vừa xoá.');
    }
  }

  /// Xuất ghi chú thành một tệp .txt rồi mở màn hình chia sẻ của máy — dạng
  /// tệp đơn giản nhất, mở được và gửi đi được ở bất cứ đâu. Android hiện đại
  /// không cho ứng dụng tự ý ghi thẳng vào thư mục Tải xuống công khai nữa
  /// (phải xin quyền lưu trữ nặng nề), nên đi qua màn hình chia sẻ sẵn có của
  /// máy — người dùng chọn "Lưu vào máy"/"Tệp" hoặc gửi thẳng đi nơi khác.
  Future<void> _taiVeGhiChu(GhiChuFile g) async {
    try {
      final tenTep = '${g.ten.trim().isEmpty ? 'Ghi chú' : g.ten.trim()}.txt';
      await luuVaChiaSeGhiChu(tenTep, g.noiDung, g.ten);
    } catch (_) {
      _bao('Không xuất được tệp. Thử lại sau.');
    }
  }

  Future<void> _xoaGhiChu(GhiChuFile g) async {
    final dongY = await _hoiXoa(ten: g.ten, canhBao: '');
    if (dongY != true) return;
    final laDangMo = g.id == widget.idGhiChuDangMo;
    setState(() => _kho.xoaGhiChu(g.id));
    await _kho.luu();
    if (laDangMo && mounted) {
      _bao('Ghi chú đang mở vừa bị xoá.');
    }
  }

  Future<bool?> _hoiXoa({required String ten, required String canhBao}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline, size: 28),
        title: const Text('Xoá?'),
        content: Text('Xoá "$ten"$canhBao. Không lấy lại được.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  void _dat(_LoaiChoDan loai, String id, String ten) {
    setState(() {
      _choDanLoai = loai;
      _choDanId = id;
      _choDanTen = ten;
    });
  }

  void _huyChoDan() {
    setState(() {
      _choDanId = null;
      _choDanLoai = null;
    });
  }

  Future<void> _dan() async {
    if (_choDanId == null || _choDanLoai == null) return;
    final id = _choDanId!;

    switch (_choDanLoai!) {
      case _LoaiChoDan.catThuMuc:
        if (id == _thuMucHienTaiId) {
          _bao('Không thể chuyển vào chính nó.');
          return;
        }
        if (!_kho.diChuyenThuMuc(id, _thuMucHienTaiId)) {
          _bao('Không thể chuyển thư mục vào chính con cháu của nó.');
          return;
        }
        break;
      case _LoaiChoDan.catGhiChu:
        _kho.diChuyenGhiChu(id, _thuMucHienTaiId);
        break;
      case _LoaiChoDan.chepThuMuc:
        _kho.saoChepThuMuc(id, _thuMucHienTaiId);
        break;
      case _LoaiChoDan.chepGhiChu:
        _kho.saoChepGhiChu(id, _thuMucHienTaiId);
        break;
    }

    setState(() {
      _choDanId = null;
      _choDanLoai = null;
    });
    await _kho.luu();
  }

  /// Toàn bộ đường đi từ gốc tới thư mục đang xem, gốc luôn ở vị trí 0.
  List<String> get _chuoiDuongDan => [..._duongDan, _thuMucHienTaiId];

  void _nhayToiViTri(int viTri) {
    final chuoi = _chuoiDuongDan;
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
      final ten = laGocNoiBo ? 'Nội bộ' : (_kho.timThuMuc(chuoi[i])?.ten ?? '?');
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
          onTap: _baoDangNangCap,
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

  /// (YÊU CẦU MỚI) Dòng tên thư mục hiện tại + các nút thêm/sửa — y hệt
  /// `AppBar` cũ (title/leading/actions), chỉ dời vào hẳn trong `body` làm
  /// dòng thứ BA, dưới thanh địa chỉ.
  Widget _dongTenThuMucVaNutThem({required bool laNgoiNhaChung}) {
    return Material(
      elevation: 1,
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
                    color: _thuMucHienTaiId == thuMucGoc ? Colors.red.shade700 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // (YÊU CẦU MỚI) "Ngôi nhà chung" chỉ để CHỌN một trong 3 bộ
            // nhớ — không có gì để thêm/sửa ở chính mức này.
            if (!laNgoiNhaChung) ...[
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
                    // 2-5: "Chọn nhiều", "Tải và chia sẻ thư mục này",
                    // "Thông tin thư mục này", "Thùng rác" — chỗ đặt
                    // trước, chưa gắn logic gì cả.
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 1, child: Text('Tạo thư mục mới')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 2, child: Text('Chọn nhiều')),
                  PopupMenuItem(value: 3, child: Text('Tải và chia sẻ thư mục này')),
                  PopupMenuItem(value: 4, child: Text('Thông tin thư mục này')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 5, child: Text('Thùng rác')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // (YÊU CẦU MỚI) "Ngôi nhà chung" không phải thư mục thật trong `_kho` —
    // KHÔNG đưa `_ngoiNhaChung` vào `noiDungThuMuc` (id không tồn tại).
    final laNgoiNhaChung = _thuMucHienTaiId == _ngoiNhaChung;
    final noiDung = laNgoiNhaChung ? null : _kho.noiDungThuMuc(_thuMucHienTaiId);
    final trong = noiDung == null
        ? false
        : noiDung.thuMucCon.isEmpty && noiDung.ghiChuCon.isEmpty;

    return PopScope(
      canPop: _duongDan.isEmpty,
      onPopInvokedWithResult: (daThoat, ketQua) {
        if (!daThoat) _veThuMucCha();
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
        body: SafeArea(
          child: Column(
          children: [
            _thanhQuayLaiVaViTriTep(),
            if (_duongDan.isNotEmpty) _thanhDiaChi(),
            _dongTenThuMucVaNutThem(laNgoiNhaChung: laNgoiNhaChung),
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
                      children: [
                        for (final t in noiDung!.thuMucCon)
                          ListTile(
                            // Vàng rực để phân biệt ngay với icon ghi chú
                            // (xám) — liếc mắt là biết đâu là thư mục.
                            leading: Icon(Icons.folder, color: Colors.amber.shade700),
                            title: Text(
                              t.ten,
                              style: t.mau != null
                                  ? TextStyle(color: Color(t.mau!))
                                  : null,
                            ),
                            onTap: () => _moThuMuc(t.id),
                            trailing: PopupMenuButton<String>(
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
                                    _dat(_LoaiChoDan.catThuMuc, t.id, t.ten);
                                    break;
                                  case 'chep':
                                    _dat(_LoaiChoDan.chepThuMuc, t.id, t.ten);
                                    break;
                                  case 'mau':
                                    _chonMau(laThuMuc: true, id: t.id);
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
                                  child: Text('Cắt'),
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
                                  value: 'xoa',
                                  child: Text('Xoá'),
                                ),
                              ],
                            ),
                          ),
                        for (final g in noiDung!.ghiChuCon)
                          ListTile(
                            leading: const Icon(Icons.description_outlined),
                            // (YÊU CẦU MỚI) Vừa nhảy tới đây qua nút "Vị trí
                            // Tệp đang soạn thảo" — phóng to/thu nhỏ vài lần
                            // để thu hút chú ý, ĐÚNG hệt hiệu ứng tên thư
                            // mục ở thanh địa chỉ (`_ChuMucNhayNhay`).
                            title: g.id == _idGhiChuCanNhayNhay
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
                            onTap: () => Navigator.of(context).pop(g.id),
                            trailing: PopupMenuButton<String>(
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
                                    _dat(_LoaiChoDan.catGhiChu, g.id, g.ten);
                                    break;
                                  case 'chep':
                                    _dat(_LoaiChoDan.chepGhiChu, g.id, g.ten);
                                    break;
                                  case 'tai_ve':
                                    _taiVeGhiChu(g);
                                    break;
                                  case 'mau':
                                    _chonMau(laThuMuc: false, id: g.id);
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
                                  child: Text('Cắt'),
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
                                  value: 'xoa',
                                  child: Text('Xoá'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            if (_choDanId != null)
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
          ],
          ),
        ),
      ),
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
