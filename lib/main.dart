// Flowrite — một trang văn bản trắng, gõ phím và nói bằng micro cùng lúc,
// với một cây thư mục để tổ chức nhiều ghi chú. Xem lib/trang_soan_thao.dart
// cho phần soạn thảo, lib/man_hinh_thu_muc.dart cho phần quản lý thư mục, và
// lib/kho_du_lieu.dart cho phần lưu trữ.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'cai_dat.dart';
import 'chan_esc_lui_trang.dart';
import 'firebase_options.dart';
import 'ghi_chu_nhanh_widget.dart';
import 'kho_du_lieu.dart';
import 'khoi_dong_tep.dart';
import 'man_hinh_go_nhanh_widget.dart';
import 'man_hinh_widget_cau_hinh.dart';
import 'trang_soan_thao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const UngDungFlowrite());
}

class UngDungFlowrite extends StatefulWidget {
  const UngDungFlowrite({super.key});

  @override
  State<UngDungFlowrite> createState() => _UngDungFlowriteState();
}

class _UngDungFlowriteState extends State<UngDungFlowrite> {
  final _kho = KhoDuLieu();
  final _caiDat = CaiDat();
  String? _idGhiChuMoDau;

  /// (YÊU CẦU MỚI — "Khi khởi động App: Mở tệp...") Kho sẽ mở ngay lúc
  /// khởi động — có thể là [_kho] (nội bộ) hay một `KhoDuLieuDamMay` (đám
  /// mây), tuỳ cài đặt; xem `giaiQuyetKhoiDong`. `null` nghĩa là CHƯA quyết
  /// xong (đang hiện vòng xoay chờ).
  KhoDuLieu? _khoMoDau;

  /// (YÊU CẦU MỚI) Activity này được mở ra từ nút trên widget "Ghi nhanh"
  /// ở màn hình chính Android (`config` lúc hệ thống tự mở sau khi vừa đặt
  /// widget, `quick` lúc bấm nút "Ghi nhanh") — `null` nghĩa là mở BÌNH
  /// THƯỜNG (bấm icon app, hoặc nút "Mở app" của widget, không có Intent
  /// extra gì) VÀ đã đọc xong (không còn ở trạng thái "chưa biết"), luồng
  /// khởi động cũ chạy tiếp y như trước, không đụng gì.
  YeuCauMoTuWidget? _yeuCauWidget;
  bool _daDocYeuCauWidget = false;

  @override
  void initState() {
    super.initState();
    _napTruoc();
  }

  Future<void> _napTruoc() async {
    final yeuCauWidget = await docYeuCauMoTuWidget();
    if (!mounted) return;
    if (yeuCauWidget != null) {
      setState(() {
        _yeuCauWidget = yeuCauWidget;
        _daDocYeuCauWidget = true;
      });
      return;
    }
    _daDocYeuCauWidget = true;

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
    final yeuCauWidget = _yeuCauWidget;
    return MaterialApp(
      title: 'Flowrite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        scaffoldBackgroundColor: Colors.white,
      ),
      // (YÊU CẦU MỚI) Bọc TOÀN APP trong một `SelectionArea` DUY NHẤT — tên
      // mọi nút, mọi mục trong menu thả xuống, nội dung mọi trang (Hướng
      // dẫn, Điều khoản, Bảo mật...) đều chọn/copy được như text thường,
      // không cần sửa riêng từng nơi. Overlay của `showMenu`/`PopupMenuButton`
      // vẫn nằm trong `Navigator` được `builder` bọc nên cũng được tính.
      // Không ảnh hưởng vùng soạn thảo chính (`TextField`/`EditableText` tự
      // quản lý vùng chọn riêng của nó) hay việc bấm nút bình thường —
      // `SelectionArea` chỉ thêm khả năng kéo-chọn, không chặn `onTap`.
      builder: (context, child) => SelectionArea(child: child!),
      home: ChanEscLuiTrang(
        child: !_daDocYeuCauWidget
            ? const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator()),
              )
            : yeuCauWidget != null
                ? (yeuCauWidget.hanhDong == 'config'
                    ? ManHinhWidgetCauHinh(idWidget: yeuCauWidget.idWidget)
                    : ManHinhGoNhanhWidget(idWidget: yeuCauWidget.idWidget))
                : _idGhiChuMoDau == null
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
