// Bản Flowrite ĐẦY ĐỦ chạy trên Web — nhân bản gần như nguyên văn màn hình
// soạn thảo của app Android (`trang_soan_thao.dart` và toàn bộ file phụ
// thuộc của nó) sang web, THAY vì lắp từng phần app Android vào file thử
// nghiệm nhỏ (`main_web_test.dart`). Mục đích: dựng được một website hoạt
// động giống hệt app Android trước, rồi mới ghép ngược phần mic/ghi âm/gửi
// Gemini/nhấp nháy/tự lưu đã kiểm chứng kỹ từ `main_web_test.dart` vào đây,
// thay cho phần tương ứng của Android (ví dụ nút "Ghi âm xong mới ra chữ"
// dùng `dart:io`/`record` — xem `ghi_am_ai_web.dart`).
//
// Đây là bản đầu tiên: mic vẫn dùng `speech_to_text` nguyên bản của app
// Android (có hỗ trợ web nhưng CHƯA được kiểm chứng kỹ như Web Speech API
// tự viết tay ở `main_web_test.dart`), và nút ghi âm kiểu Android chỉ là
// giữ chỗ (xem `ghi_am_ai_web.dart`) — cả hai sẽ được thay ở bước ghép sau.

import 'package:flutter/material.dart';

import 'cai_dat.dart';
import 'kho_du_lieu.dart';
import 'trang_soan_thao.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UngDungFlowriteWebDayDu());
}

class UngDungFlowriteWebDayDu extends StatefulWidget {
  const UngDungFlowriteWebDayDu({super.key});

  @override
  State<UngDungFlowriteWebDayDu> createState() =>
      _UngDungFlowriteWebDayDuState();
}

class _UngDungFlowriteWebDayDuState extends State<UngDungFlowriteWebDayDu> {
  final _kho = KhoDuLieu();
  final _caiDat = CaiDat();
  String? _idGhiChuMoDau;

  @override
  void initState() {
    super.initState();
    _napTruoc();
  }

  Future<void> _napTruoc() async {
    final id = await _kho.tai();
    await _caiDat.tai();
    if (!mounted) return;
    setState(() => _idGhiChuMoDau = id);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowrite — bản đầy đủ trên Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: _idGhiChuMoDau == null
          ? const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            )
          : TrangSoanThao(
              kho: _kho,
              caiDat: _caiDat,
              ghiChuId: _idGhiChuMoDau!,
            ),
    );
  }
}
