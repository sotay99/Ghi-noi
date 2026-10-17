// (YÊU CẦU MỚI — chỉ admin) Trang "Cảnh báo hạn mức API" — mở từ menu "Tài
// khoản và Cài đặt" (chỉ hiện với 2 email admin, xem `quyen_admin.dart`).
// Đọc collection `canhBaoApi` — ghi bởi `gui_ghi_am_gemini.dart` mỗi khi
// Groq báo gần/đã chạm hạn mức miễn phí (đọc header của chính Groq, không
// phải đoán) — để admin chủ động nâng cấp gói TRƯỚC KHI app bị chặn hẳn.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void moModalCanhBaoApi(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _TrangCanhBaoApi()),
  );
}

/// Tự ghép tay (HH:mm dd/MM/yyyy) — cùng lý do với hai màn hình admin khác,
/// tránh thêm phụ thuộc `intl` chỉ cho một dòng hiển thị.
String _dinhDangThoiGian(DateTime t) {
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(t.hour)}:${hai(t.minute)} ${hai(t.day)}/${hai(t.month)}/${t.year}';
}

class _TrangCanhBaoApi extends StatelessWidget {
  const _TrangCanhBaoApi();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        title: const Text('Cảnh báo hạn mức API'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // Không `where` kèm `orderBy` field khác — một field duy nhất
          // không đòi composite index (xem bài học ở `modal_quan_ly_gop_y.dart`).
          stream: FirebaseFirestore.instance
              .collection('canhBaoApi')
              .orderBy('thoiGian', descending: true)
              .limit(100)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'Chưa có cảnh báo nào — Groq vẫn còn dư hạn mức.',
                  style: TextStyle(color: Color(0xFF5F6368)),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _dongCanhBao(docs[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _dongCanhBao(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    final thongDiep = j['thongDiep'] as String? ?? '';
    final daChamHan = thongDiep.startsWith('[ĐÃ CHẠM HẠN MỨC]');
    final thoiGian = j['thoiGian'];
    final chuoiThoiGian = thoiGian is Timestamp ? _dinhDangThoiGian(thoiGian.toDate()) : '...';
    final mauNen = daChamHan ? const Color(0xFFFCE8E6) : const Color(0xFFFFF4E5);
    final mauChu = daChamHan ? const Color(0xFFC5221F) : const Color(0xFF8A5300);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mauNen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mauChu.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(daChamHan ? Icons.error_outline : Icons.warning_amber_outlined, color: mauChu, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thongDiep, style: TextStyle(fontSize: 13.5, color: mauChu, height: 1.4)),
                const SizedBox(height: 4),
                Text(chuoiThoiGian, style: const TextStyle(fontSize: 11.5, color: Color(0xFF9AA0A6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
