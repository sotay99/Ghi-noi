// Trang "Bảo mật và quyền riêng tư" — mở từ menu "Tài khoản và Cài đặt".
// Toàn màn hình, nội dung chọn/copy được (bọc trong `SelectionArea`), cùng
// khuôn trình bày với `trang_huong_dan.dart` qua các khối ở
// `trang_phap_ly_dung_chung.dart`.
//
// Nội dung dài theo đa ngôn ngữ nằm ở `chuoi_phap_ly.dart`.

import 'package:flutter/material.dart';

import 'chuoi_phap_ly.dart';
import 'ngon_ngu.dart';
import 'trang_phap_ly_dung_chung.dart';

const _capNhat = '16/10/2026';

class TrangBaoMat extends StatelessWidget {
  const TrangBaoMat({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NgonNgu>(
      valueListenable: ngonNguHienTai,
      builder: (context, nn, _) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: mauChinhPhapLy,
          foregroundColor: Colors.white,
          title: Text(ChPhapLy.baoMatTieuDe(nn)),
        ),
        body: SafeArea(
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ChPhapLy.capNhatLanCuoi(nn, _capNhat),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF5F6368)),
                  ),
                  const SizedBox(height: 16),
                  // (YÊU CẦU) Hộp tóm tắt nổi bật đầu trang — một câu, nói
                  // thẳng dữ liệu của người dùng đi đâu, cho ai lười đọc hết
                  // cũng nắm được ý chính ngay.
                  HopNoiBatPhapLy(
                    child: DoanPhapLy(ChPhapLy.baoMatTomTat(nn)),
                  ),
                  const SizedBox(height: 28),

                  MucLonPhapLy(so: '1', tieuDe: ChPhapLy.bmMuc1TieuDe(nn)),
                  const SizedBox(height: 12),
                  DoanPhapLy(ChPhapLy.bmMuc1(nn)),
                  const SizedBox(height: 22),

                  MucLonPhapLy(so: '2', tieuDe: ChPhapLy.bmMuc2TieuDe(nn)),
                  const SizedBox(height: 12),
                  DoanPhapLy(ChPhapLy.bmMuc2(nn)),
                  const SizedBox(height: 10),
                  DongGachDauPhapLy(ChPhapLy.bmMuc2Dong1(nn)),
                  DongGachDauPhapLy(ChPhapLy.bmMuc2Dong2(nn)),
                  DongGachDauPhapLy(ChPhapLy.bmMuc2Dong3(nn)),
                  const SizedBox(height: 10),
                  DoanPhapLy(ChPhapLy.bmMuc2Sau(nn)),
                  const SizedBox(height: 22),

                  MucLonPhapLy(so: '3', tieuDe: ChPhapLy.bmMuc3TieuDe(nn)),
                  const SizedBox(height: 12),
                  DoanPhapLy(ChPhapLy.bmMuc3(nn)),
                  const SizedBox(height: 22),

                  MucLonPhapLy(so: '4', tieuDe: ChPhapLy.bmMuc4TieuDe(nn)),
                  const SizedBox(height: 12),
                  DoanPhapLy(ChPhapLy.bmMuc4(nn)),
                  const SizedBox(height: 22),

                  MucLonPhapLy(so: '5', tieuDe: ChPhapLy.bmMuc5TieuDe(nn)),
                  const SizedBox(height: 12),
                  DongGachDauPhapLy(ChPhapLy.bmMuc5Dong1(nn)),
                  DongGachDauPhapLy(ChPhapLy.bmMuc5Dong2(nn)),
                  DongGachDauPhapLy(ChPhapLy.bmMuc5Dong3(nn)),
                  const SizedBox(height: 22),

                  MucLonPhapLy(so: '6', tieuDe: ChPhapLy.bmMuc6TieuDe(nn)),
                  const SizedBox(height: 12),
                  DoanPhapLy(ChPhapLy.bmMuc6(nn)),
                  const SizedBox(height: 22),

                  MucLonPhapLy(so: '7', tieuDe: ChPhapLy.bmMuc7TieuDe(nn)),
                  const SizedBox(height: 12),
                  DoanPhapLy(ChPhapLy.bmMuc7(nn)),
                  const SizedBox(height: 22),

                  MucLonPhapLy(so: '8', tieuDe: ChPhapLy.bmMuc8TieuDe(nn)),
                  const SizedBox(height: 12),
                  DoanPhapLy(ChPhapLy.bmMuc8(nn)),
                  const SizedBox(height: 22),

                  MucLonPhapLy(so: '9', tieuDe: ChPhapLy.muc9TieuDe(nn)),
                  const SizedBox(height: 12),
                  DoanPhapLy(ChPhapLy.muc9Dan(nn)),
                  const SizedBox(height: 12),
                  HopNoiBatPhapLy(
                    mauNen: const Color(0xFFF1F8F3),
                    mauVien: const Color(0xFFB7E1C1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DoanPhapLy(ChPhapLy.lienHeEmail(nn)),
                        const SizedBox(height: 6),
                        DoanPhapLy(ChPhapLy.lienHeEmailKhac(nn)),
                        const SizedBox(height: 6),
                        DoanPhapLy(ChPhapLy.lienHeDienThoai(nn)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
