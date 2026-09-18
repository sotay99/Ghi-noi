// (VIỆC 3) Màn hình Nhật ký gỡ lỗi giọng nói — chỉ đọc: hiện toàn bộ log đã
// ghi trong phiên soạn thảo hiện tại (`_logGiongNoi` ở trang_soan_thao.dart),
// có nút Sao chép toàn bộ (dán ra máy khác/gửi cho người phát triển đọc) và
// nút Xoá log để bắt đầu ghi lại sạch cho lần test tiếp theo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManHinhNhatKyGiongNoi extends StatefulWidget {
  const ManHinhNhatKyGiongNoi({
    super.key,
    required this.log,
    required this.khiXoaLog,
    required this.hienThongBao,
  });

  /// Danh sách dòng log hiện có — mỗi lần mở màn hình là một bản chụp mới
  /// nhất của `_logGiongNoi` (nó được truyền theo tham chiếu, nên "Xoá log"
  /// xoá luôn ở nguồn).
  final List<String> log;

  /// Gọi khi người dùng bấm "Xoá log" — trang soạn thảo tự xoá sạch
  /// `_logGiongNoi` của chính nó (màn hình này chỉ có tham chiếu tới list).
  final VoidCallback khiXoaLog;

  /// TÁI DÙNG đúng cơ chế `_bao()` (thông báo nhỏ tự biến mất) đã có ở trang
  /// soạn thảo — truyền thẳng hàm đó vào đây thay vì tự dựng một cơ chế
  /// thông báo khác.
  final void Function(String) hienThongBao;

  @override
  State<ManHinhNhatKyGiongNoi> createState() => _ManHinhNhatKyGiongNoiState();
}

class _ManHinhNhatKyGiongNoiState extends State<ManHinhNhatKyGiongNoi> {
  Future<void> _saoChepTatCa() async {
    final noiDung = widget.log.join('\n');
    await Clipboard.setData(ClipboardData(text: noiDung));
    widget.hienThongBao(
      widget.log.isEmpty ? 'Log đang trống, không có gì để chép.' : 'Đã sao chép',
    );
  }

  void _xoaLog() {
    widget.khiXoaLog();
    setState(() {});
    widget.hienThongBao('Đã xoá log');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký gỡ lỗi giọng nói'),
        actions: [
          IconButton(
            onPressed: _saoChepTatCa,
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Sao chép',
          ),
          IconButton(
            onPressed: _xoaLog,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xoá log',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.log.length} dòng — chỉ ghi giữ trong bộ nhớ, mất '
                    'khi thoát hẳn ứng dụng.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.log.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có dòng log nào.\nBật micro và nói thử để log bắt đầu ghi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9AA0A6)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: widget.log.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: SelectableText(
                        widget.log[i],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saoChepTatCa,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Sao chép'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _xoaLog,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xoá log'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
