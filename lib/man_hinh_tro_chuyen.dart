// Màn hình "Trò chuyện về văn bản này" (mục trong menu "Làm việc với AI")
// — toàn màn hình, giống chuyển sang một trang mới (Navigator.push), có nút
// đóng (X) ở AppBar để quay lại trang soạn thảo. Chỉ người dùng hỏi-đáp với
// AI (Gemini) về văn bản đang soạn — không sửa văn bản gốc, không có luồng
// nào khác ngoài chat.
//
// Lượt hỏi ĐẦU TIÊN của một cuộc trò chuyện MỚI luôn gửi kèm toàn văn bản
// (nhúng vào nội dung lượt đó gửi cho AI — ẩn khỏi khung hiển thị, người
// dùng chỉ thấy đúng câu họ gõ). Từ lượt thứ hai trở đi KHÔNG tự kèm nữa —
// muốn AI đọc lại bản mới nhất (vì văn bản có thể đã đổi từ lúc mở chat) thì
// bấm nút "+" cạnh khung nhập, chọn "Đính kèm lại toàn bộ văn bản mới nhất".
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
  });

  /// Tham chiếu sống — mọi thêm/xoá ở đây đều "lưu" thẳng vào bộ nhớ đệm của
  /// tệp ghi chú đang mở (do nơi gọi cầm List này).
  final List<TinNhanTroChuyen> lichSu;

  /// Gọi lại mỗi khi cần ĐÍNH KÈM văn bản (lượt đầu tiên, hoặc khi người
  /// dùng chủ động bấm "+" → "Đính kèm lại...") — LUÔN lấy bản MỚI NHẤT tại
  /// đúng thời điểm gửi, không phải bản chụp lúc mở màn hình.
  final String Function() layVanBanHienTai;

  @override
  State<ManHinhTroChuyen> createState() => _ManHinhTroChuyenState();
}

class _ManHinhTroChuyenState extends State<ManHinhTroChuyen> {
  final _oNhap = TextEditingController();
  final _cuon = ScrollController();
  bool _dangGui = false;
  bool _dinhKemVanBanMoiNhat = false;

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
    final canDinhKem = laLuotDau || _dinhKemVanBanMoiNhat;
    final choAi = canDinhKem
        ? 'Đây là toàn văn bản đang soạn (mới nhất):\n"""\n'
            '${widget.layVanBanHienTai()}\n"""\n\n'
            'Câu hỏi của tôi: $cauHoi'
        : cauHoi;

    setState(() {
      widget.lichSu.add(TinNhanTroChuyen(laNguoiDung: true, choHienThi: cauHoi, choAi: choAi));
      _dangGui = true;
      _dinhKemVanBanMoiNhat = false; // Đính kèm là một lần cho MỖI lượt gửi.
    });
    _cuonXuongDuoi();

    String? loi;
    String? traLoi;
    try {
      traLoi = await guiTroChuyenChoGemini([
        for (final t in widget.lichSu)
          LuotTroChuyen(
            vaiTro: t.laNguoiDung ? 'nguoiDung' : 'ai',
            noiDung: t.choAi,
          ),
      ]);
    } catch (e) {
      loi = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _dangGui = false;
      if (traLoi != null && traLoi.trim().isNotEmpty) {
        widget.lichSu.add(TinNhanTroChuyen(laNguoiDung: false, choHienThi: traLoi.trim()));
      } else {
        widget.lichSu.add(TinNhanTroChuyen(
          laNguoiDung: false,
          choHienThi: 'AI trả lời thất bại: ${loi ?? "không có nội dung trả về."}',
        ));
      }
    });
    _cuonXuongDuoi();
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
        _dinhKemVanBanMoiNhat = false;
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
                  : ListView.builder(
                      controller: _cuon,
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.lichSu.length + (_dangGui ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= widget.lichSu.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'AI đang trả lời...',
                                  style: TextStyle(color: Color(0xFF5F6368)),
                                ),
                              ],
                            ),
                          );
                        }
                        final t = widget.lichSu[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: t.laNguoiDung
                              ? _BongBongNguoiDung(chu: t.choHienThi)
                              : _TinNhanAi(chu: t.choHienThi),
                        );
                      },
                    ),
            ),
            if (_dinhKemVanBanMoiNhat)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Toàn bộ văn bản mới nhất'),
                    onDeleted: () => setState(() => _dinhKemVanBanMoiNhat = false),
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
                        child: Text('Đính kèm lại toàn bộ văn bản mới nhất'),
                      ),
                    ],
                    onSelected: (_) => setState(() => _dinhKemVanBanMoiNhat = true),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _oNhap,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _gui(),
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
                  _NutGui(dangGui: _dangGui, khiBam: _gui),
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

/// Bong bóng tin nhắn của người dùng — bọc khung, sát mép phải. Cho chọn
/// văn bản để sao chép (`SelectableText`).
class _BongBongNguoiDung extends StatelessWidget {
  const _BongBongNguoiDung({required this.chu});
  final String chu;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _mauChinh.withValues(alpha: 0.1),
          border: Border.all(color: _mauChinh.withValues(alpha: 0.4)),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        child: SelectableText(chu),
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
class _TinNhanAi extends StatelessWidget {
  const _TinNhanAi({required this.chu});
  final String chu;

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {
                Clipboard.setData(ClipboardData(text: chu));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
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
