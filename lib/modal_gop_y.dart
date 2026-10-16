// (YÊU CẦU MỚI) Trang "Góp ý thêm, báo lỗi về ứng dụng" — mở từ menu "+
// Thêm lựa chọn". Ai cũng gửi được, không cần đăng nhập (luật Firestore
// cho "tạo" công khai ở collection `gopY`; chỉ admin mới ĐỌC/SỬA được, xem
// `quyen_admin.dart`). Nội dung bắt buộc 20-10000 ký tự; email tuỳ chọn,
// tự điền sẵn (sửa được) nếu người dùng đang đăng nhập Google.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'trang_phap_ly_dung_chung.dart';

const _gioiHanDuoiNoiDung = 20;
const _gioiHanTrenNoiDung = 10000;

void moModalGopY(BuildContext context, {String? emailDaDangNhap}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _TrangGopY(emailDaDangNhap: emailDaDangNhap),
    ),
  );
}

class _TrangGopY extends StatefulWidget {
  const _TrangGopY({this.emailDaDangNhap});
  final String? emailDaDangNhap;

  @override
  State<_TrangGopY> createState() => _TrangGopYState();
}

class _TrangGopYState extends State<_TrangGopY> {
  final _oNoiDung = TextEditingController();
  late final _oEmail = TextEditingController(text: widget.emailDaDangNhap ?? '');
  bool _dangGui = false;
  bool _daGuiXong = false;
  String? _loi;

  bool get _hopLe =>
      _oNoiDung.text.trim().length >= _gioiHanDuoiNoiDung &&
      _oNoiDung.text.trim().length <= _gioiHanTrenNoiDung;

  Future<void> _gui() async {
    if (!_hopLe || _dangGui) return;
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      await FirebaseFirestore.instance.collection('gopY').add({
        'noiDung': _oNoiDung.text.trim(),
        'email': _oEmail.text.trim().isEmpty ? null : _oEmail.text.trim(),
        'thoiGian': FieldValue.serverTimestamp(),
        'trangThai': 'chuaXuLy',
      });
      if (!mounted) return;
      setState(() {
        _daGuiXong = true;
        _dangGui = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dangGui = false;
        _loi = 'Gửi không thành công — kiểm tra lại mạng rồi thử lại.';
      });
    }
  }

  @override
  void dispose() {
    _oNoiDung.dispose();
    _oEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mauChinhPhapLy,
        foregroundColor: Colors.white,
        title: const Text('Góp ý thêm, báo lỗi về ứng dụng'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
          child: _daGuiXong ? _noiDungCamOn() : _noiDungForm(),
        ),
      ),
    );
  }

  Widget _noiDungCamOn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF34A853), size: 48),
        const SizedBox(height: 16),
        const Text(
          'Cảm ơn bạn đã góp ý, báo lỗi về ứng dụng!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Admin sẽ tiếp thu và triển khai sớm nhất có thể.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Đóng'),
          ),
        ),
      ],
    );
  }

  Widget _noiDungForm() {
    final soKyTu = _oNoiDung.text.trim().length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mời bạn góp ý thêm hoặc báo lỗi về ứng dụng — mọi ý kiến đều được '
          'ghi nhận và sẽ giúp Flowrite tốt hơn.',
          style: TextStyle(fontSize: 14.5, height: 1.4),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _oNoiDung,
          maxLines: 8,
          minLines: 5,
          maxLength: _gioiHanTrenNoiDung,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Nhập góp ý hoặc mô tả lỗi bạn gặp phải (tối thiểu $_gioiHanDuoiNoiDung ký tự)...',
            counterText: '$soKyTu/$_gioiHanTrenNoiDung',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _oEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Email của bạn (không bắt buộc)',
            hintText: 'Để admin phản hồi lại nếu cần',
          ),
        ),
        const SizedBox(height: 18),
        if (_loi != null) ...[
          Text(_loi!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _hopLe && !_dangGui ? _gui : null,
            child: _dangGui
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Gửi'),
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Có thắc mắc, góp ý, báo lỗi, vui lòng liên hệ qua một trong các cách sau:',
          style: TextStyle(fontSize: 13.5),
        ),
        const SizedBox(height: 12),
        HopNoiBatPhapLy(
          mauNen: const Color(0xFFF1F8F3),
          mauVien: const Color(0xFFB7E1C1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              DoanPhapLy('**Email:** lookatmevanthanhpham@gmail.com'),
              SizedBox(height: 6),
              DoanPhapLy('**Email khác:** 219thanhdeptrai@gmail.com'),
              SizedBox(height: 6),
              DoanPhapLy('**Điện thoại:** +84 91 711 4941'),
            ],
          ),
        ),
      ],
    );
  }
}
