// Bảng "Ghi âm xong mới ra chữ": ghi âm thật (không phải nhận dạng giọng nói
// theo thời gian thực như micro chính của app), rồi gửi cả tệp âm thanh cho
// AI phiên âm một lượt. Khác hẳn cơ chế speech_to_text đang dùng ở trang
// soạn thảo — cái đó nghe tới đâu ra chữ tới đó, còn đây ghi trọn vẹn xong
// mới xử lý, hợp với người muốn nói một mạch dài rồi mới để máy gõ lại.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'ai_cau_hinh.dart';

/// Mở bảng ghi âm, chờ tới khi xong (chuyển hoá thành công, huỷ, hay tắt).
/// Trả về văn bản đã phiên âm, hoặc null nếu không có gì để chèn vào bài.
Future<String?> moBangGhiAmAI(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _BangGhiAmAI(),
  );
}

/// Ghi âm quá 10 phút thì file đã khá nặng cho một lượt gọi AI — tự động
/// chuyển hoá luôn, không để người dùng vô tình ghi cả tiếng đồng hồ.
const _thoiLuongToiDaGiay = 10 * 60;

/// Im lặng liên tục 15 giây thì coi như người dùng đã nói xong hoặc quên tắt
/// — tự tạm dừng, không âm thầm ghi vào khoảng không.
const _giayImLangToiDaTuDung = 15;

/// Ngưỡng âm lượng (dBFS, phần lớn nằm trong khoảng -60..0) để coi là "có
/// tiếng nói" — dưới mức này coi là im lặng/tạp âm nền.
const _nguongImLangDb = -35.0;

class _BangGhiAmAI extends StatefulWidget {
  const _BangGhiAmAI();

  @override
  State<_BangGhiAmAI> createState() => _BangGhiAmAIState();
}

class _BangGhiAmAIState extends State<_BangGhiAmAI> {
  final _recorder = AudioRecorder();
  String? _duongDanTep;

  bool _dangKhoiDong = true;
  bool _dangGhi = false;
  bool _tamDung = false;
  bool _dangXuLy = false;
  String? _loi;

  int _giayDaGhi = 0;
  int _giayImLangLienTuc = 0;
  Timer? _henDemGiay;
  StreamSubscription<Amplitude>? _dangKyMucAm;

  /// 40 mẫu gần nhất, 0..1 — vẽ sóng âm nằm ngang trong lúc ghi.
  final List<double> _mucAmGanDay = List<double>.filled(40, 0);

  int _giayXuLy = 0;
  Timer? _henDemGiayXuLy;
  bool _huyXuLy = false;

  @override
  void initState() {
    super.initState();
    _batDau();
  }

  @override
  void dispose() {
    _henDemGiay?.cancel();
    _henDemGiayXuLy?.cancel();
    _dangKyMucAm?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _batDau() async {
    final quyen = await Permission.microphone.request();
    if (!quyen.isGranted) {
      if (mounted) {
        setState(() {
          _dangKhoiDong = false;
          _loi = 'Chưa được cấp quyền micro — không thể ghi âm.';
        });
      }
      return;
    }

    final thuMuc = await getTemporaryDirectory();
    _duongDanTep =
        '${thuMuc.path}/flowrite_ghi_am_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 32000,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: _duongDanTep!,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _dangKhoiDong = false;
          _loi = 'Không mở được micro để ghi âm: $e';
        });
      }
      return;
    }

    _dangKyMucAm = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen(_khiCoMucAm);

    _henDemGiay = Timer.periodic(const Duration(seconds: 1), (_) => _moiGiay());

    if (mounted) {
      setState(() {
        _dangKhoiDong = false;
        _dangGhi = true;
      });
    }
  }

  void _khiCoMucAm(Amplitude m) {
    if (!mounted || !_dangGhi || _tamDung) return;
    // dBFS thường âm rất sâu (-160 im lặng tuyệt đối) tới 0 (to nhất máy ghi
    // được) — ép về 0..1 để vẽ, coi mọi thứ dưới -60dB là gần như 0.
    final chuan = ((m.current + 60) / 60).clamp(0.0, 1.0);
    setState(() {
      for (var i = 0; i < _mucAmGanDay.length - 1; i++) {
        _mucAmGanDay[i] = _mucAmGanDay[i + 1];
      }
      _mucAmGanDay[_mucAmGanDay.length - 1] = chuan;
    });

    if (m.current < _nguongImLangDb) {
      _giayImLangLienTuc += 1;
      // Mẫu lấy mỗi 200ms — quy đổi ra số mẫu tương ứng ngưỡng giây đặt sẵn.
      if (_giayImLangLienTuc >= _giayImLangToiDaTuDung * 5) {
        _giayImLangLienTuc = 0;
        _tamDungGhi(tuDong: true);
      }
    } else {
      _giayImLangLienTuc = 0;
    }
  }

  void _moiGiay() {
    if (!mounted || _tamDung || _dangXuLy) return;
    setState(() => _giayDaGhi += 1);
    if (_giayDaGhi >= _thoiLuongToiDaGiay) {
      _chuyenHoaThanhVanBan();
    }
  }

  Future<void> _tamDungGhi({bool tuDong = false}) async {
    if (_tamDung || !_dangGhi) return;
    try {
      await _recorder.pause();
    } catch (_) {
      // Máy không hỗ trợ pause() thật — cứ coi như đã dừng đếm giờ, dữ liệu
      // ghi thêm (nếu có) không sao vì lúc Chuyển hoá vẫn dùng nguyên tệp.
    }
    if (mounted) setState(() => _tamDung = true);
  }

  Future<void> _tiepTucGhi() async {
    if (!_tamDung) return;
    try {
      await _recorder.resume();
    } catch (_) {}
    _giayImLangLienTuc = 0;
    if (mounted) setState(() => _tamDung = false);
  }

  Future<void> _tatGhiAm() async {
    try {
      await _recorder.stop();
    } catch (_) {}
    final duongDan = _duongDanTep;
    if (duongDan != null) {
      final tep = File(duongDan);
      if (await tep.exists()) await tep.delete().catchError((_) => tep);
    }
    if (mounted) Navigator.of(context).pop(null);
  }

  Future<void> _chuyenHoaThanhVanBan() async {
    if (_dangXuLy) return;
    _henDemGiay?.cancel();
    await _dangKyMucAm?.cancel();

    String? duongDanCuoi;
    try {
      duongDanCuoi = await _recorder.stop();
    } catch (e) {
      if (mounted) setState(() => _loi = 'Không kết thúc được bản ghi: $e');
      return;
    }
    duongDanCuoi ??= _duongDanTep;
    if (duongDanCuoi == null) {
      if (mounted) setState(() => _loi = 'Không tìm thấy tệp ghi âm.');
      return;
    }

    final tep = File(duongDanCuoi);
    if (!await tep.exists() || await tep.length() < 500) {
      if (mounted) {
        setState(() => _loi = 'Bản ghi quá ngắn hoặc trống, không có gì để phiên âm.');
      }
      return;
    }

    _huyXuLy = false;
    _giayXuLy = 0;
    setState(() {
      _dangGhi = false;
      _dangXuLy = true;
    });
    _henDemGiayXuLy = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _giayXuLy += 1);
    });

    String? vanBan;
    Object? loi;
    try {
      final bytes = await tep.readAsBytes();
      final base64 = base64Encode(bytes);
      final phanHoi = await http
          .post(
            Uri.parse(diaChiMayChuAI),
            headers: {
              'content-type': 'application/json',
              'x-flowrite-secret': matKhauMayChuAI,
            },
            body: jsonEncode({
              'action': 'ghi_am',
              'audioBase64': base64,
              'mimeType': 'audio/mp4',
            }),
          )
          .timeout(const Duration(minutes: 5));

      if (phanHoi.statusCode != 200) {
        throw Exception('Máy chủ AI trả về lỗi ${phanHoi.statusCode}');
      }
      final goc = jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
      vanBan = goc['text'] as String?;
      if (vanBan == null) {
        throw Exception(goc['loi']?.toString() ?? 'Máy chủ AI không trả về nội dung.');
      }
    } catch (e) {
      loi = e;
    } finally {
      await tep.delete().catchError((_) => tep);
    }

    _henDemGiayXuLy?.cancel();
    if (_huyXuLy || !mounted) return;

    if (loi != null || vanBan == null || vanBan.trim().isEmpty) {
      setState(() {
        _dangXuLy = false;
        _loi = 'Không phiên âm được: $loi';
      });
      return;
    }

    Navigator.of(context).pop(vanBan);
  }

  void _huyGiuaChung() {
    _huyXuLy = true;
    Navigator.of(context).pop(null);
  }

  String _dinhDangGio(int giay) {
    final phut = (giay ~/ 60).toString().padLeft(2, '0');
    final le = (giay % 60).toString().padLeft(2, '0');
    return '$phut:$le';
  }

  @override
  Widget build(BuildContext context) {
    Widget noiDung;

    if (_dangKhoiDong) {
      noiDung = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_loi != null) {
      noiDung = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
          const SizedBox(height: 12),
          Text(_loi!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Đóng'),
          ),
        ],
      );
    } else if (_dangXuLy) {
      noiDung = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI đang tiêu hoá thành văn bản',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vui lòng đợi, file ghi âm càng nặng thì xử lý càng lâu ạ.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 16),
          Text(
            _dinhDangGio(_giayXuLy),
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _huyGiuaChung,
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Dừng ngay lập tức và huỷ kết quả'),
          ),
        ],
      );
    } else {
      noiDung = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ghi âm giọng nói', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: CustomPaint(
              size: const Size(double.infinity, 48),
              painter: _VeSongAmNgang(
                muc: _mucAmGanDay,
                mau: _tamDung ? Colors.grey : Colors.red.shade600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _dinhDangGio(_giayDaGhi),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (_tamDung) ...[
            const SizedBox(height: 4),
            const Text('Đã tạm dừng', style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 12)),
          ],
          const SizedBox(height: 16),
          IconButton.filledTonal(
            onPressed: _tamDung ? _tiepTucGhi : _tamDungGhi,
            icon: Icon(_tamDung ? Icons.play_arrow : Icons.pause),
            iconSize: 28,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _chuyenHoaThanhVanBan,
              style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
              child: const Text('Chuyển hoá thành văn bản'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _tatGhiAm,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade600),
              child: const Text('Tắt Ghi âm'),
            ),
          ),
        ],
      );
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: SizedBox(width: 300, child: noiDung),
      ),
    );
  }
}

/// Sóng âm NẰM NGANG cho bảng ghi âm — khác widget SongAm (vòng tròn đồng
/// tâm) đang dùng ở thanh công cụ chính, hợp hơn để biểu diễn cả một dải
/// thời gian ghi âm thay vì chỉ một khoảnh khắc đang nói.
class _VeSongAmNgang extends CustomPainter {
  _VeSongAmNgang({required this.muc, required this.mau});

  final List<double> muc;
  final Color mau;

  @override
  void paint(Canvas canvas, Size size) {
    final but = Paint()
      ..color = mau
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    final soVach = muc.length;
    final buoc = size.width / soVach;
    final giua = size.height / 2;

    for (var i = 0; i < soVach; i++) {
      final x = buoc * i + buoc / 2;
      final cao = (4.0 + muc[i] * (size.height - 4)).clamp(4.0, size.height);
      canvas.drawLine(Offset(x, giua - cao / 2), Offset(x, giua + cao / 2), but);
    }
  }

  @override
  bool shouldRepaint(covariant _VeSongAmNgang cu) => true;
}
