// Nén một thư mục (và mọi thứ bên trong) thành .zip để tải về/chia sẻ, và
// đọc ngược lại một .zip bất kỳ thành cây xem-trước (`NutZip`) cho
// `ModalNhapZip` — chỉ giữ tệp .txt và thư mục có chứa .txt ở đâu đó bên
// trong, mọi thứ khác bị lọc bỏ ngay ở bước đọc này.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'kho_du_lieu.dart';
import 'mo_hinh.dart';

/// Nén nguyên THƯ MỤC làm gốc trong archive (không nén trần nội dung ra
/// ngay gốc) — giải nén ra là thấy ngay một thư mục tên [tenGoc], không lẫn
/// vào các tệp khác đang có sẵn ở nơi giải nén.
Uint8List nenThuMucThanhZip(KhoDuLieu kho, String thuMucId, String tenGoc) {
  final archive = Archive();

  void duyet(String id, String duongDan) {
    final noiDung = kho.noiDungThuMuc(id);
    for (final t in noiDung.thuMucCon) {
      duyet(t.id, '$duongDan/${t.ten}');
    }
    for (final g in noiDung.ghiChuCon) {
      final bytes = utf8.encode(g.noiDung);
      archive.addFile(ArchiveFile('$duongDan/${g.ten}.txt', bytes.length, bytes));
    }
  }

  duyet(thuMucId, tenGoc);
  final bytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(bytes ?? const []);
}

/// Nút tạm, gom trong lúc đọc — gộp các thư mục con/tệp con theo tên trước
/// khi dựng hẳn thành `NutZip` (`Map` chống trùng tên ngay trong archive).
class _NoiTam {
  final Map<String, _NoiTam> conThuMuc = {};
  final Map<String, String> conTep = {};
}

List<NutZip> _dungThanhCay(_NoiTam nut) {
  final ds = <NutZip>[];
  nut.conThuMuc.forEach((ten, con) {
    ds.add(NutZip.thuMuc(ten, _dungThanhCay(con)));
  });
  nut.conTep.forEach((ten, noiDung) {
    ds.add(NutZip.tep(ten, noiDung));
  });
  return ds;
}

/// Đọc một .zip tuỳ ý thành cây xem-trước — CHỈ lấy tệp `.txt` (không phân
/// biệt hoa/thường) và thư mục có chứa `.txt` ở đâu đó bên trong; thư mục
/// không hề có `.txt` nào bên trong thì không bao giờ xuất hiện trong cây
/// (không cần một bước "tỉa" riêng — chỉ dựng Map từ đường dẫn của mỗi .txt
/// tìm thấy).
///
/// Ném lỗi nếu [bytes] không phải một .zip đọc được.
List<NutZip> phanTichZip(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final goc = _NoiTam();

  for (final f in archive.files) {
    if (!f.isFile) continue;
    if (!f.name.toLowerCase().endsWith('.txt')) continue;
    final phan = f.name.split('/').where((p) => p.isNotEmpty).toList();
    if (phan.isEmpty) continue;

    var hienTai = goc;
    for (var i = 0; i < phan.length - 1; i++) {
      hienTai = hienTai.conThuMuc.putIfAbsent(phan[i], () => _NoiTam());
    }
    final tenTepDayDu = phan.last;
    final ten = tenTepDayDu.substring(0, tenTepDayDu.length - 4);
    final noiDungBytes = f.content as List<int>;
    hienTai.conTep[ten] = utf8.decode(noiDungBytes, allowMalformed: true);
  }

  return _dungThanhCay(goc);
}
