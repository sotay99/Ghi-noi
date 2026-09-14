// Ghi Nói — một trang văn bản trắng, gõ phím và nói bằng micro cùng lúc, với
// một cây thư mục để tổ chức nhiều ghi chú. Xem lib/trang_soan_thao.dart cho
// phần soạn thảo, lib/man_hinh_thu_muc.dart cho phần quản lý thư mục, và
// lib/kho_du_lieu.dart cho phần lưu trữ.

import 'package:flutter/material.dart';

import 'cai_dat.dart';
import 'kho_du_lieu.dart';
import 'trang_soan_thao.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UngDungGhiNoi());
}

class UngDungGhiNoi extends StatefulWidget {
  const UngDungGhiNoi({super.key});

  @override
  State<UngDungGhiNoi> createState() => _UngDungGhiNoiState();
}

class _UngDungGhiNoiState extends State<UngDungGhiNoi> {
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
      title: 'Ghi Nói',
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
