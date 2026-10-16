// (YÊU CẦU MỚI — chỉ admin) Trang "Các ý kiến góp ý, báo lỗi của user" — mở
// từ menu "Tài khoản và Cài đặt" (chỉ hiện với 2 email admin, xem
// `quyen_admin.dart`). Ba tab Chưa xử lý/Đã xử lý/Thùng rác, mặc định ở tab
// đầu, mới nhất lên trước. Dữ liệu còn ít lúc đầu — tải HẾT một lần theo
// từng tab (không phân trang), đơn giản cho v1.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Tránh thêm phụ thuộc `intl` chỉ để định dạng một dòng thời gian — tự
/// ghép tay, đủ dùng cho nhu cầu hiển thị ở đây (HH:mm dd/MM/yyyy).
String _dinhDangThoiGian(DateTime t) {
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(t.hour)}:${hai(t.minute)} ${hai(t.day)}/${hai(t.month)}/${t.year}';
}

void moModalQuanLyGopY(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _TrangQuanLyGopY()),
  );
}

const _tenTab = ['Chưa xử lý', 'Đã xử lý', 'Thùng rác'];
const _giaTrangThaiTheoTab = ['chuaXuLy', 'daXuLy', 'thungRac'];

class _TrangQuanLyGopY extends StatefulWidget {
  const _TrangQuanLyGopY();

  @override
  State<_TrangQuanLyGopY> createState() => _TrangQuanLyGopYState();
}

class _TrangQuanLyGopYState extends State<_TrangQuanLyGopY> {
  int _tabHienTai = 0;

  // (SỬA LỖI — "The query requires an index") Lọc theo `trangThai` CỘNG sắp
  // theo `thoiGian` (hai field khác nhau) đòi Firestore phải có composite
  // index — chưa tạo thì đỏ ngay. Bỏ hẳn `orderBy` ở Firestore, tự sắp lại
  // phía Dart sau khi tải về (`_nguon` dưới) — màn này vốn đã tải HẾT một
  // lần theo từng tab (không phân trang), sắp ở client không tốn thêm gì,
  // và khỏi phải tạo index thủ công mỗi lần thêm lọc/tab mới sau này.
  Stream<QuerySnapshot<Map<String, dynamic>>> _nguon(String trangThai) {
    return FirebaseFirestore.instance
        .collection('gopY')
        .where('trangThai', isEqualTo: trangThai)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sapMoiNhatTruoc(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final ds = [...docs];
    ds.sort((a, b) {
      final ta = a.data()['thoiGian'];
      final tb = b.data()['thoiGian'];
      if (ta is! Timestamp) return 1;
      if (tb is! Timestamp) return -1;
      return tb.compareTo(ta);
    });
    return ds;
  }

  Future<void> _doiTrangThai(String docId, String trangThaiMoi) {
    return FirebaseFirestore.instance
        .collection('gopY')
        .doc(docId)
        .update({'trangThai': trangThaiMoi});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        title: const Text('Các ý kiến góp ý, báo lỗi của user'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: List.generate(_tenTab.length, (i) {
                  final chon = i == _tabHienTai;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: chon ? const Color(0xFF1A73E8) : null,
                          foregroundColor: chon ? Colors.white : const Color(0xFF1A73E8),
                        ),
                        onPressed: () => setState(() => _tabHienTai = i),
                        child: Text(_tenTab[i]),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _nguon(_giaTrangThaiTheoTab[_tabHienTai]),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = _sapMoiNhatTruoc(snap.data!.docs);
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Chưa có ý kiến nào ở mục "${_tenTab[_tabHienTai]}".',
                        style: const TextStyle(color: Color(0xFF5F6368)),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _dongYKien(docs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dongYKien(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    final noiDung = j['noiDung'] as String? ?? '';
    final email = j['email'] as String?;
    final thoiGian = j['thoiGian'];
    final chuoiThoiGian = thoiGian is Timestamp ? _dinhDangThoiGian(thoiGian.toDate()) : '...';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  email ?? '(không để lại email)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: email == null ? const Color(0xFF9AA0A6) : const Color(0xFF1A73E8),
                  ),
                ),
              ),
              Text(chuoiThoiGian,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF9AA0A6))),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (gia) => _doiTrangThai(doc.id, gia),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'daXuLy',
                    child: Row(children: [
                      Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF34A853)),
                      SizedBox(width: 10),
                      Text('Đánh dấu Đã xử lý'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'chuaXuLy',
                    child: Row(children: [
                      Icon(Icons.radio_button_unchecked, size: 18, color: Color(0xFF5F6368)),
                      SizedBox(width: 10),
                      Text('Đánh dấu Chưa xử lý'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'thungRac',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Đưa vào Thùng rác'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(noiDung, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
