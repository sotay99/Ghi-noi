// Màn hình "Trò chuyện về văn bản này" (mục trong menu "Làm việc với AI")
// — toàn màn hình, giống chuyển sang một trang mới (Navigator.push), có nút
// đóng (X) ở AppBar để quay lại trang soạn thảo. Chỉ người dùng hỏi-đáp với
// AI (Gemini) về văn bản đang soạn — không sửa văn bản gốc, không có luồng
// nào khác ngoài chat.
//
// Lượt hỏi ĐẦU TIÊN gửi kèm toàn văn bản (nhúng vào nội dung lượt đó gửi
// cho AI — ẩn khỏi khung hiển thị, người dùng chỉ thấy đúng câu họ gõ); từ
// lượt thứ hai trở đi chỉ gửi đúng câu mới, KHÔNG nhúng lại toàn văn — lịch
// sử hội thoại (đã có lượt 1 mang theo văn bản) đủ để AI nhớ ngữ cảnh, xem
// `lib/gui_tro_chuyen_gemini.dart`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gui_tro_chuyen_gemini.dart';

const _mauChinh = Color(0xFF1A73E8);

/// Một dòng trong khung chat — [choAi] khác [choHienThi] CHỈ ở lượt người
/// dùng ĐẦU TIÊN (lượt đó gửi cho AI kèm toàn văn bản, nhưng người dùng chỉ
/// thấy đúng câu họ gõ).
class _TinNhan {
  _TinNhan({required this.laNguoiDung, required this.choHienThi, String? choAi})
      : choAi = choAi ?? choHienThi;

  final bool laNguoiDung;
  final String choHienThi;
  final String choAi;
}

class ManHinhTroChuyen extends StatefulWidget {
  const ManHinhTroChuyen({super.key, required this.vanBan});

  /// Toàn văn bản đang soạn TẠI THỜI ĐIỂM mở màn hình này — chụp một lần,
  /// không tự cập nhật theo những gì người dùng gõ tiếp ở trang soạn thảo
  /// trong lúc đang trò chuyện (đơn giản hơn, và các câu hỏi/trả lời trong
  /// cùng một phiên vẫn nhất quán với đúng một bản đã hỏi).
  final String vanBan;

  @override
  State<ManHinhTroChuyen> createState() => _ManHinhTroChuyenState();
}

class _ManHinhTroChuyenState extends State<ManHinhTroChuyen> {
  final _tinNhan = <_TinNhan>[];
  final _oNhap = TextEditingController();
  final _cuon = ScrollController();
  bool _dangGui = false;

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

    final laLuotDau = _tinNhan.isEmpty;
    final choAi = laLuotDau
        ? 'Đây là toàn văn bản đang soạn:\n"""\n${widget.vanBan}\n"""\n\n'
            'Câu hỏi của tôi: $cauHoi'
        : cauHoi;

    setState(() {
      _tinNhan.add(_TinNhan(laNguoiDung: true, choHienThi: cauHoi, choAi: choAi));
      _dangGui = true;
    });
    _cuonXuongDuoi();

    String? loi;
    String? traLoi;
    try {
      traLoi = await guiTroChuyenChoGemini([
        for (final t in _tinNhan)
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
        _tinNhan.add(_TinNhan(laNguoiDung: false, choHienThi: traLoi.trim()));
      } else {
        _tinNhan.add(_TinNhan(
          laNguoiDung: false,
          choHienThi: 'AI trả lời thất bại: ${loi ?? "không có nội dung trả về."}',
        ));
      }
    });
    _cuonXuongDuoi();
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _tinNhan.isEmpty
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
                      itemCount: _tinNhan.length + (_dangGui ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _tinNhan.length) {
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
                        final t = _tinNhan[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: t.laNguoiDung
                              ? _BongBongNguoiDung(chu: t.choHienThi)
                              : _TinNhanAi(chu: t.choHienThi),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                children: [
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
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: _mauChinh),
                    onPressed: _dangGui ? null : _gui,
                    icon: const Icon(Icons.send, color: Colors.white),
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

/// Bong bóng tin nhắn của người dùng — bọc khung, sát mép phải.
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
        child: Text(chu),
      ),
    );
  }
}

/// Tin nhắn của AI — KHÔNG bọc khung, rộng cả hai bên màn hình. Tách những
/// khối ```...``` (nếu có) ra khỏi văn xuôi thường, hiện trong khung riêng
/// kèm nút sao chép — xem `_tachKhoiMa`.
class _TinNhanAi extends StatelessWidget {
  const _TinNhanAi({required this.chu});
  final String chu;

  @override
  Widget build(BuildContext context) {
    final doan = _tachKhoiMa(chu);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in doan)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: d.laKhoiMa ? _KhungKetQua(chu: d.chu) : Text(d.chu),
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

/// Khung riêng cho một đoạn AI trả về dạng "kết quả" (khối ```...```) — nền
/// xám nhạt, chữ đơn cách (monospace), có nút "Sao chép" ở góc trên bên
/// phải.
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
