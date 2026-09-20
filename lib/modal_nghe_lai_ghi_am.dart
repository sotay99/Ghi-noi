import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Modal "Nghe bản ghi âm này" — phát lại trực tiếp từ bytes đang giữ trong
/// bộ nhớ (`_duLieuTheoTheGhiAm`), không ghi ra file tạm, dùng chung được cho
/// cả web và Android/iOS qua `BytesSource`.
Future<void> hienModalNgheLaiGhiAm(
  BuildContext context, {
  required Uint8List bytes,
  required String mime,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ModalNgheLaiGhiAm(bytes: bytes, mime: mime),
  );
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

  @override
  void initState() {
    super.initState();
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
    _player.setSourceBytes(widget.bytes, mimeType: widget.mime);
  }

  @override
  void dispose() {
    _dsViTri?.cancel();
    _dsThoiLuong?.cancel();
    _dsTrangThai?.cancel();
    _dsXongHet?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _bamPlayTamDung() async {
    if (_dangPhat) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  String _dinhDang(Duration d) {
    final phut = d.inMinutes;
    final giay = d.inSeconds % 60;
    return '$phut:${giay.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tongMili = _tongThoiLuong.inMilliseconds;
    final viTriHienThi = _dangKeo ? _viTriDangKeo : _viTri;
    final gia = tongMili <= 0
        ? 0.0
        : (viTriHienThi.inMilliseconds / tongMili).clamp(0.0, 1.0);
    return AlertDialog(
      title: const Text('Nghe bản ghi âm này'),
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
          onPressed: () async {
            await _player.stop();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
