// Modal "Cài đặt nút Kiểm tra toàn văn" — mở từ mục cùng tên trong menu
// "Làm việc với AI". Gồm: dòng giải thích, thanh trượt chọn độ dài đoạn đề
// xuất, và ô nhập câu lệnh tuỳ chỉnh riêng của người dùng. Tách riêng khỏi
// trang_soan_thao.dart vì đây là một khối giao diện khá lớn, tự đứng độc lập.

import 'package:flutter/material.dart';

import 'cai_dat.dart';

/// Mô phỏng đúng style của nút "Kiểm tra toàn văn" thật trên thanh công cụ:
/// icon `task_alt` + chữ, cùng màu xanh lá `Colors.green.shade600`.
class _NutKiemTraToanVanMoPhong extends StatelessWidget {
  const _NutKiemTraToanVanMoPhong();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDADCE0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 15, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Text(
            'Kiểm toàn văn',
            style: TextStyle(fontSize: 11, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }
}

void _hienGiaiThich(BuildContext context, String tieuDe, String noiDung) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tieuDe),
      content: SingleChildScrollView(
        child: Text(noiDung, style: const TextStyle(height: 1.5)),
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

const _giaiThichDoDaiDeXuat =
    'Đây là độ dài THAM KHẢO cho từng đoạn mà AI đề xuất khi bấm "Kiểm tra '
    'toàn văn" — không phải giới hạn cứng nhắc, AI vẫn có thể vượt ra ngoài '
    'khoảng này nếu ngữ cảnh đòi hỏi.\n\n'
    'Đoạn đề xuất càng NGẮN thì càng bám sát nguyên văn của bạn, ít khả năng '
    'lệch ý hơn, nhưng có thể chưa đủ mượt vì AI phải sửa từng mẩu nhỏ.\n\n'
    'Đoạn đề xuất càng DÀI thì AI càng có chỗ để viết lại cho gọn gàng, súc '
    'tích hơn, nhưng cũng dễ lệch khỏi ý gốc của bạn hơn vì AI phải diễn đạt '
    'lại nhiều hơn.\n\n'
    'Khoảng ký tự tham khảo cho từng mức:\n'
    'Rất ngắn: khoảng 4–8 ký tự\n'
    'Ngắn: khoảng 8–14 ký tự\n'
    'Trung bình: khoảng 12–20 ký tự\n'
    'Dài: khoảng 20–34 ký tự\n'
    'Rất dài: khoảng 34–56 ký tự';

const _giaiThichCauLenhTuyChinh =
    'Đây là câu lệnh RIÊNG của bạn, gửi kèm theo chỉ dẫn gốc của hệ thống mỗi '
    'lần bấm "Kiểm tra toàn văn". Nếu ý bạn viết ở đây xung đột với chỉ dẫn '
    'gốc, AI sẽ ưu tiên làm theo ý của bạn trước.\n\n'
    'Ví dụ: bạn có thể dặn AI giữ nguyên văn phong thân mật, tránh dùng từ Hán '
    'Việt, hoặc luôn viết hoa một tên riêng nào đó.';

/// Mở modal "Cài đặt nút Kiểm tra toàn văn".
void moModalCaiDatKiemTraToanVan(BuildContext context, CaiDat caiDat) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ThanCaiDatKiemTraToanVan(caiDat: caiDat),
  );
}

class _ThanCaiDatKiemTraToanVan extends StatefulWidget {
  const _ThanCaiDatKiemTraToanVan({required this.caiDat});
  final CaiDat caiDat;

  @override
  State<_ThanCaiDatKiemTraToanVan> createState() => _ThanCaiDatKiemTraToanVanState();
}

class _ThanCaiDatKiemTraToanVanState extends State<_ThanCaiDatKiemTraToanVan> {
  late int _mucDo;
  late String _cauLenhTuyChinh;

  @override
  void initState() {
    super.initState();
    _mucDo = widget.caiDat.mucDoDaiDeXuat;
    _cauLenhTuyChinh = widget.caiDat.cauLenhTuyChinhKiemTraToanVan;
  }

  Future<void> _moSuaCauLenhTuyChinh() async {
    final oNhap = TextEditingController(text: _cauLenhTuyChinh);
    final ketQua = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Câu lệnh riêng của bạn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: oNhap,
              maxLines: 5,
              minLines: 3,
              maxLength: CaiDat.gioiHanCauLenhTuyChinh,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: giữ văn phong thân mật, tránh từ Hán Việt...',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Câu lệnh này được gửi kèm theo chỉ dẫn gốc của hệ thống mỗi '
              'lần bấm "Kiểm tra toàn văn", và được ưu tiên hơn nếu có xung '
              'đột.',
              style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(oNhap.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ketQua == null || !mounted) return;
    setState(() => _cauLenhTuyChinh = ketQua);
    await widget.caiDat.datCauLenhTuyChinhKiemTraToanVan(ketQua);
  }

  @override
  Widget build(BuildContext context) {
    final banPhim = MediaQuery.of(context).viewInsets.bottom;
    final soTu = _cauLenhTuyChinh.trim().isEmpty
        ? 0
        : _cauLenhTuyChinh.trim().split(RegExp(r'\s+')).length;

    return Padding(
      padding: EdgeInsets.only(bottom: banPhim),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cài đặt nút "Kiểm tra toàn văn"',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: const TextStyle(height: 1.5, color: Colors.black87),
                children: [
                  const TextSpan(
                      text: 'Để sử dụng chức năng kiểm tra toàn văn bằng AI, vui lòng bấm nút '
                          '"Làm việc với AI" ở thanh công cụ rồi chọn mục '),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _NutKiemTraToanVanMoPhong(),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Đây là bước quan trọng sau mỗi lần soạn xong 1 bài văn bản.',
              style: TextStyle(height: 1.5, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 24),
            const Text(
              'CÀI ĐẶT TÍNH NĂNG NÀY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Độ dài đoạn đề xuất ----
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Độ dài của từng đoạn văn được đề xuất',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            Text(
              CaiDat.tenMucDoDaiDeXuat[_mucDo],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _mucDo.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              label: CaiDat.tenMucDoDaiDeXuat[_mucDo],
              onChanged: (gia) {
                setState(() => _mucDo = gia.round());
              },
              onChangeEnd: (gia) {
                widget.caiDat.datMucDoDaiDeXuat(gia.round());
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _hienGiaiThich(
                  context,
                  'Độ dài của từng đoạn văn được đề xuất',
                  _giaiThichDoDaiDeXuat,
                ),
                child: const Text('Tìm hiểu thêm'),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Câu lệnh tuỳ chỉnh ----
            InkWell(
              onTap: _moSuaCauLenhTuyChinh,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tùy chỉnh câu lệnh để cho AI làm việc',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF9AA0A6)),
                  ],
                ),
              ),
            ),
            Text(
              _cauLenhTuyChinh.trim().isEmpty
                  ? 'Câu lệnh riêng của bạn đang trống'
                  : 'Câu lệnh của bạn đang chứa $soTu từ',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _hienGiaiThich(
                  context,
                  'Tùy chỉnh câu lệnh để cho AI làm việc',
                  _giaiThichCauLenhTuyChinh,
                ),
                child: const Text('Tìm hiểu thêm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
