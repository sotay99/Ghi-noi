// Bản Flowrite ĐẦY ĐỦ chạy trên Web — nhân bản gần như nguyên văn màn hình
// soạn thảo của app Android (`trang_soan_thao.dart` và toàn bộ file phụ
// thuộc của nó) sang web, THAY vì lắp từng phần app Android vào file thử
// nghiệm nhỏ (`main_web_test.dart`). Cơ chế thẻ ghi âm (xem `the_ghi_am.dart`/
// `ghi_am_the.dart`) đã ghép chung cho cả Android/iOS gốc và web — bản
// ghi-âm-rồi-mới-ra-chữ cũ riêng của APK (`ghi_am_ai*.dart`) đã bị gỡ.
//
// Mic vẫn dùng `speech_to_text` nguyên bản của app Android (có hỗ trợ web
// nhưng CHƯA được kiểm chứng kỹ như Web Speech API tự viết tay ở
// `main_web_test.dart`) — việc thay động cơ mic cho web là bước sau.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'cai_dat.dart';
import 'chan_esc_lui_trang.dart';
import 'firebase_options.dart';
import 'kho_du_lieu.dart';
import 'khoi_dong_lai_app.dart';
import 'khoi_dong_tep.dart';
import 'trang_soan_thao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // (YÊU CẦU MỚI) Bọc trong `KhoiDongLaiApp` — cho phép khởi động lại toàn
  // bộ app tại chỗ sau khi đăng xuất, xem `khoi_dong_lai_app.dart`.
  runApp(const KhoiDongLaiApp(child: UngDungFlowriteWebDayDu()));
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

  /// (YÊU CẦU MỚI — "Khi khởi động App: Mở tệp...") Xem giải thích đầy đủ ở
  /// `main.dart` (cùng logic y hệt, chỉ khác giao diện khởi động).
  KhoDuLieu? _khoMoDau;

  @override
  void initState() {
    super.initState();
    _napTruoc();
  }

  Future<void> _napTruoc() async {
    final idNoiBoMacDinh = await _kho.tai();
    await _caiDat.tai();
    if (!mounted) return;
    final (khoChon, idChon) = await giaiQuyetKhoiDong(
      khoNoiBo: _kho,
      idNoiBoMacDinh: idNoiBoMacDinh,
      caiDat: _caiDat,
    );
    if (!mounted) return;
    setState(() {
      _khoMoDau = khoChon;
      _idGhiChuMoDau = idChon;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // (YÊU CẦU MỚI) Tên hiện ở tab trình duyệt — 3 emoji: Đám mây/Cuốn
      // sách đang mở/Tay cầm bút viết.
      title: 'Flowrite - ☁️📖✍️',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        scaffoldBackgroundColor: Colors.white,
      ),
      // (YÊU CẦU MỚI) Xem giải thích đầy đủ ở `main.dart` — bọc toàn app
      // trong một `SelectionArea` để tên nút/mục menu/nội dung mọi trang
      // chọn/copy được như text thường.
      builder: (context, child) => SelectionArea(child: child!),
      home: ChanEscLuiTrang(
        child: _idGhiChuMoDau == null
            ? const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator()),
              )
            : TrangSoanThao(
                kho: _khoMoDau ?? _kho,
                khoNoiBo: _kho,
                caiDat: _caiDat,
                ghiChuId: _idGhiChuMoDau!,
              ),
      ),
    );
  }
}
