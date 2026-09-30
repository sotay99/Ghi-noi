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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gui_tro_chuyen_gemini.dart';
import 'tin_nhan_tro_chuyen.dart';

const _mauChinh = Color(0xFF1A73E8);

class ManHinhTroChuyen extends StatefulWidget {
  const ManHinhTroChuyen({
    super.key,
    required this.lichSu,
    required this.layVanBanHienTai,
    required this.layDoanVanDangChon,
  });

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
  }

  @override
  void dispose() {
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
                    ],
                    onSelected: (v) {
                      if (v == 1) {
                        _chonDinhKemToanVan();
                      } else {
                        _chonDinhKemDoanChon();
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _oNhap,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _guiHoacXacNhanSua(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập câu hỏi...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NutGui(dangGui: _dangGui, khiBam: _guiHoacXacNhanSua),
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
