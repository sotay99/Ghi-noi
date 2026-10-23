// (MỚI) Modal "Cài đặt Ngôn ngữ" — mở từ menu Tài khoản-Cài đặt, mục
// "Ngôn ngữ - Language" (thay cho việc mở thẳng `moModalChonNgonNgu` như
// trước). Có HAI dòng cài đặt: (1) ngôn ngữ của ứng dụng, (2) ngôn ngữ
// riêng cho tính năng ghi âm (nói xong mới ra chữ). Không bắt buộc chọn —
// đóng được bằng nút X/chạm ra ngoài, không đổi gì nếu không bấm lựa chọn
// nào. KHÔNG thay thế `modal_chon_ngon_ngu.dart` (modal bắt chọn lúc mở
// app lần đầu) — hai modal độc lập, giữ nguyên hành vi lần-đầu-mở-app.

import 'package:flutter/material.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'ngon_ngu.dart';

Future<void> moModalCaiDatNgonNgu(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _ModalCaiDatNgonNgu(),
  );
}

class _ModalCaiDatNgonNgu extends StatefulWidget {
  const _ModalCaiDatNgonNgu();

  @override
  State<_ModalCaiDatNgonNgu> createState() => _ModalCaiDatNgonNguState();
}

class _ModalCaiDatNgonNguState extends State<_ModalCaiDatNgonNgu> {
  @override
  void initState() {
    super.initState();
    // Dòng 2 hiện tên ngôn ngữ app NGAY trong nhãn tuỳ chọn 1 — phải tự vẽ
    // lại dòng 2 mỗi khi dòng 1 đổi (đổi app language trong CHÍNH lúc modal
    // này còn mở), không cần đóng/mở lại modal mới thấy đúng.
    ngonNguHienTai.addListener(_veLai);
    ngonNguGhiAmHienTai.addListener(_veLai);
  }

  @override
  void dispose() {
    ngonNguHienTai.removeListener(_veLai);
    ngonNguGhiAmHienTai.removeListener(_veLai);
    super.dispose();
  }

  void _veLai() {
    if (mounted) setState(() {});
  }

  Future<void> _chonNgonNguApp() async {
    final nn = ngonNguHienTai.value;
    final chon = await showDialog<NgonNgu>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(Ch.ngonNguCuaUngDung(nn)),
        children: NgonNgu.values
            .map((v) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(v),
                  child: Row(
                    children: [
                      if (v == nn) const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.check, size: 18, color: Color(0xFF1A73E8)),
                      ) else const SizedBox(width: 26),
                      // Tên ngôn ngữ — KHÔNG BAO GIỜ dịch, luôn nguyên văn.
                      Text(tenRiengNgonNgu(v), style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (chon != null) await datNgonNgu(chon);
  }

  Future<void> _chonNgonNguGhiAm() async {
    final nn = ngonNguHienTai.value;
    final hienTai = ngonNguGhiAmHienTai.value;
    final chon = await showDialog<NgonNguGhiAm>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(Ch.ngonNguGhiAmNhan(nn)),
        children: NgonNguGhiAm.values.map((v) {
          final String nhan;
          switch (v) {
            case NgonNguGhiAm.theoApp:
              nhan = Ch.tuyChonTheoNgonNguApp(nn, tenRiengNgonNgu(ngonNguHienTai.value));
              break;
            case NgonNguGhiAm.tuDongNhanDien:
              nhan = Ch.tuyChonTuDongNhanDien(nn);
              break;
            case NgonNguGhiAm.vi:
              nhan = tenRiengNgonNgu(NgonNgu.vi);
              break;
            case NgonNguGhiAm.en:
              nhan = tenRiengNgonNgu(NgonNgu.en);
              break;
          }
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(v),
            child: Row(
              children: [
                if (v == hienTai) const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check, size: 18, color: Color(0xFF1A73E8)),
                ) else const SizedBox(width: 26),
                Expanded(child: Text(nhan, style: const TextStyle(fontSize: 16))),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (chon != null) await datNgonNguGhiAm(chon);
  }

  String _nhanNgonNguGhiAmHienTai(NgonNgu nn) {
    switch (ngonNguGhiAmHienTai.value) {
      case NgonNguGhiAm.theoApp:
        return Ch.tuyChonTheoNgonNguApp(nn, tenRiengNgonNgu(ngonNguHienTai.value));
      case NgonNguGhiAm.tuDongNhanDien:
        return Ch.tuyChonTuDongNhanDien(nn);
      case NgonNguGhiAm.vi:
        return tenRiengNgonNgu(NgonNgu.vi);
      case NgonNguGhiAm.en:
        return tenRiengNgonNgu(NgonNgu.en);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nn = ngonNguHienTai.value;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Ch.tieuDeModalCaiDatNgonNgu(nn),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(Ch.ngonNguCuaUngDung(nn)),
                subtitle: Text(tenRiengNgonNgu(nn)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _chonNgonNguApp,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(Ch.ngonNguGhiAmNhan(nn)),
                subtitle: Text(
                  '${_nhanNgonNguGhiAmHienTai(nn)}\n${Ch.moTaNgonNguGhiAm(nn)}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: _chonNgonNguGhiAm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
