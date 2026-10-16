// (YÊU CẦU MỚI — chỉ admin) Trang "Các User đã đăng nhập" — mở từ menu
// "Tài khoản và Cài đặt" (chỉ hiện với 2 email admin, xem `quyen_admin.dart`).
// Đọc collection gốc `users/{uid}` — hồ sơ được GHI mỗi lần đăng nhập Google
// thành công (xem `dang_nhap_google.dart`), sắp theo lần đăng nhập GẦN NHẤT
// lên trước. Tải hết một lần (không phân trang) — dữ liệu còn ít lúc đầu.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void moModalDanhSachUser(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _TrangDanhSachUser()),
  );
}

/// Tự ghép tay (HH:mm dd/MM/yyyy) — tránh thêm phụ thuộc `intl` chỉ cho một
/// dòng hiển thị, cùng lý do với `modal_quan_ly_gop_y.dart`.
String _dinhDangThoiGian(DateTime t) {
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(t.hour)}:${hai(t.minute)} ${hai(t.day)}/${hai(t.month)}/${t.year}';
}

class _TrangDanhSachUser extends StatelessWidget {
  const _TrangDanhSachUser();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        foregroundColor: Colors.black,
        title: const Text('Các User đã đăng nhập'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('lanCuoiDangNhap', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Tổng số: ${docs.length} user đã đăng nhập',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: docs.isEmpty
                      ? const Center(
                          child: Text('Chưa có user nào đăng nhập.',
                              style: TextStyle(color: Color(0xFF5F6368))),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _dongUser(docs[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dongUser(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    final ten = j['tenHienThi'] as String?;
    final email = j['email'] as String?;
    final urlAnh = j['urlAnhDaiDien'] as String?;
    final lanDau = j['lanDauDangNhap'];
    final lanCuoi = j['lanCuoiDangNhap'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: urlAnh != null ? NetworkImage(urlAnh) : null,
            child: urlAnh == null
                ? const Icon(Icons.person, color: Color(0xFF9AA0A6))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ten ?? '(không có tên)',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                if (email != null)
                  Text(email, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6368))),
                const SizedBox(height: 4),
                if (lanDau is Timestamp)
                  Text('Lần đầu đăng nhập: ${_dinhDangThoiGian(lanDau.toDate())}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF9AA0A6))),
                if (lanCuoi is Timestamp)
                  Text('Gần nhất: ${_dinhDangThoiGian(lanCuoi.toDate())}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF9AA0A6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
