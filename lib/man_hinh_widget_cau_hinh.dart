// Màn hình cấu hình widget "Ghi nhanh" — Android tự mở Activity NÀY (qua
// `android:configure` khai trong `tool/android_widget/ghi_nhanh_widget_info.xml`)
// đúng một lần, ngay sau khi người dùng vừa thả widget vào màn hình chính.
// Chỉ việc chọn MỘT ghi chú NỘI BỘ (xem lý do giới hạn ở dưới), lưu lại rồi
// báo hệ thống "xong" — không có gì khác để cấu hình ở v1.
import 'package:flutter/material.dart';

import 'ghi_chu_nhanh_widget.dart';
import 'kho_du_lieu.dart';
import 'khoi_dong_tep.dart';
import 'thong_bao_giua.dart';

class ManHinhWidgetCauHinh extends StatefulWidget {
  const ManHinhWidgetCauHinh({super.key, required this.idWidget});
  final int idWidget;

  @override
  State<ManHinhWidgetCauHinh> createState() => _ManHinhWidgetCauHinhState();
}

class _ManHinhWidgetCauHinhState extends State<ManHinhWidgetCauHinh> {
  final _kho = KhoDuLieu();

  @override
  void initState() {
    super.initState();
    _napRoiChon();
  }

  Future<void> _napRoiChon() async {
    await _kho.tai();
    if (!mounted) return;
    await _chon();
  }

  Future<void> _chon() async {
    // (GIỚI HẠN v1) Chỉ nhận ghi chú NỘI BỘ — widget ghi trực tiếp vào
    // KhoDuLieu nội bộ ngay trên máy, không cần mạng, không cần xử lý
    // tranh chấp đồng bộ với bản đám mây đang mở song song ở app. Bộ chọn
    // dùng CHUNG (`moChonKhoiDong`) cũng cho thấy cả thư mục đám mây — lọc
    // lại ở đây, không sửa bộ chọn chung chỉ vì widget này.
    final kq = await moChonKhoiDong(context, khoNoiBo: _kho, mode: ModeChonKhoiDong.tep);
    if (!mounted) return;
    if (kq == null) {
      // Người dùng bấm Back thoát bộ chọn — không có gì để lưu, nhưng vẫn
      // phải đóng Activity (không thể giữ widget ở trạng thái "đang cấu
      // hình" lơ lửng), coi như huỷ đặt widget.
      Navigator.of(context).maybePop();
      return;
    }
    if (kq.kho is KhoDuLieuDamMay) {
      hienThongBaoGiua(context, 'Widget này chỉ dùng được ghi chú NỘI BỘ — hãy chọn lại.');
      await _chon();
      return;
    }
    final ghiChu = kq.kho.timGhiChu(kq.id);
    if (ghiChu == null) {
      await _chon();
      return;
    }
    await luuMucTieuWidget(idWidget: widget.idWidget, ghiChuId: ghiChu.id, ten: ghiChu.ten);
    await hoanTatCauHinhWidget(widget.idWidget);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
