import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'chuoi_da_ngon_ngu.dart';
import 'ngon_ngu.dart';
import 'nguon_am_thanh_the_ghi_am.dart';
import 'tai_ve_bytes.dart';

/// Modal "Nghe bản ghi âm này" — phát lại trực tiếp từ bytes đang giữ trong
/// bộ nhớ (`_duLieuTheoTheGhiAm`), không ghi ra file tạm. Nguồn phát tạo qua
/// `taoNguonPhatGhiAm` — TRÊN WEB là một Blob URL thật (không phải
/// `BytesSource`/`setSourceBytes`, vốn từng làm trình duyệt từ chối phát với
/// lỗi "content type (Code: 4)" — xem giải thích ở `nguon_am_thanh_the_ghi_am.dart`).
/// Trả về `true` nếu người dùng bấm nút "Chuyển hoá thẻ ghi âm này thành văn
/// bản" ở dưới modal — bên gọi tự lo việc chuyển hoá thật (đóng luôn Bảng
/// điều khiển nếu đang mở, rồi gọi logic gửi AI), modal này chỉ báo Ý ĐỊNH.
Future<bool> hienModalNgheLaiGhiAm(
  BuildContext context, {
  required Uint8List bytes,
  required String mime,
}) async {
  final ketQua = await showDialog<bool>(
    context: context,
    builder: (context) => _ModalNgheLaiGhiAm(bytes: bytes, mime: mime),
  );
  return ketQua ?? false;
}

class _ModalNgheLaiGhiAm extends StatefulWidget {
  const _ModalNgheLaiGhiAm({required this.bytes, required this.mime});

  final Uint8List bytes;
  final String mime;

  @override
  State<_ModalNgheLaiGhiAm> createState() => _ModalNgheLaiGhiAmState();
}

class _ModalNgheLaiGhiAmState extends State<_ModalNgheLaiGhiAm> {
  final _player = AudioPlayer();
  Duration _viTri = Duration.zero;
  Duration _tongThoiLuong = Duration.zero;
  bool _dangPhat = false;
  bool _dangKeo = false;
  Duration _viTriDangKeo = Duration.zero;

  StreamSubscription<Duration>? _dsViTri;
  StreamSubscription<Duration>? _dsThoiLuong;
  StreamSubscription<PlayerState>? _dsTrangThai;
  StreamSubscription<void>? _dsXongHet;
  late final NguonPhatGhiAm _nguonPhat;

  @override
  void initState() {
    super.initState();
    _nguonPhat = taoNguonPhatGhiAm(widget.bytes, widget.mime);
    _dsViTri = _player.onPositionChanged.listen((vt) {
      if (!mounted) return;
      setState(() => _viTri = vt);
    });
    _dsThoiLuong = _player.onDurationChanged.listen((tl) {
      if (!mounted) return;
      setState(() => _tongThoiLuong = tl);
    });
    _dsTrangThai = _player.onPlayerStateChanged.listen((tt) {
      if (!mounted) return;
      setState(() => _dangPhat = tt == PlayerState.playing);
    });
    _dsXongHet = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _dangPhat = false;
        _viTri = Duration.zero;
      });
    });
    _player.setSource(_nguonPhat.nguon);
  }

  @override
  void dispose() {
    _dsViTri?.cancel();
    _dsThoiLuong?.cancel();
    _dsTrangThai?.cancel();
    _dsXongHet?.cancel();
    _player.dispose();
    giaiPhongNguonPhatGhiAm(_nguonPhat);
    super.dispose();
  }

  bool _daBatDauPhat = false;

  Future<void> _bamPlayTamDung() async {
    if (_dangPhat) {
      await _player.pause();
      return;
    }
    // Lần bấm Play ĐẦU TIÊN: dùng `play(nguon)` để chắc chắn khởi động
    // ngay từ nguồn đã dựng (`_nguonPhat.nguon`), không dựa vào `resume()`
    // — ở trạng thái vừa `setSource` xong (chưa từng phát), `resume()` có
    // lúc không khởi động được vì bộ máy chưa coi là "đang tạm dừng".
    if (!_daBatDauPhat) {
      _daBatDauPhat = true;
      await _player.play(_nguonPhat.nguon);
    } else {
      await _player.resume();
    }
  }

  String _dinhDang(Duration d) {
    final phut = d.inMinutes;
    final giay = d.inSeconds % 60;
    return '$phut:${giay.toString().padLeft(2, '0')}';
  }

  /// Đuôi tệp suy ra từ MIME — ví dụ 'audio/webm' → 'webm'. Không cần chính
  /// xác tuyệt đối với mọi trình phát ngoài, chỉ cần tệp tải về có đuôi hợp
  /// lý để người dùng nhận ra loại tệp.
  String get _duoiTep {
    final phan = widget.mime.split('/');
    if (phan.length < 2) return 'audio';
    return phan[1].split(';').first.trim();
  }

  Future<void> _taiVeMay() async {
    await taiVeBytes(widget.bytes, 'ghi-am.$_duoiTep', widget.mime);
  }

  @override
  Widget build(BuildContext context) {
    final tongMili = _tongThoiLuong.inMilliseconds;
    final viTriHienThi = _dangKeo ? _viTriDangKeo : _viTri;
    final gia = tongMili <= 0
        ? 0.0
        : (viTriHienThi.inMilliseconds / tongMili).clamp(0.0, 1.0);
    return AlertDialog(
      title: Text(Ch.ngheBanGhiAmNay(ngonNguHienTai.value)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 48,
            icon: Icon(_dangPhat ? Icons.pause_circle : Icons.play_circle),
            onPressed: _bamPlayTamDung,
          ),
          Slider(
            value: gia,
            onChangeStart: (_) => setState(() => _dangKeo = true),
            onChanged: (g) {
              if (tongMili <= 0) return;
              setState(() =>
                  _viTriDangKeo = Duration(milliseconds: (g * tongMili).round()));
            },
            onChangeEnd: (g) async {
              final moi = Duration(milliseconds: (g * tongMili).round());
              await _player.seek(moi);
              setState(() {
                _dangKeo = false;
                _viTri = moi;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dinhDang(viTriHienThi)),
              Text(_dinhDang(_tongThoiLuong)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _taiVeMay,
          child: Text(Ch.taiFileGhiAmVeMay(ngonNguHienTai.value)),
        ),
        TextButton(
          onPressed: () async {
            await _player.stop();
            if (context.mounted) Navigator.of(context).pop(false);
          },
          child: Text(Ch.dong(ngonNguHienTai.value)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
          onPressed: () async {
            await _player.stop();
            if (context.mounted) Navigator.of(context).pop(true);
          },
          child: Text(Ch.chuyenHoaTheGhiAmNayThanhVanBan(ngonNguHienTai.value)),
        ),
      ],
    );
  }
}
