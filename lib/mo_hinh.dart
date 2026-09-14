// Mô hình dữ liệu: thư mục và ghi chú. Toàn bộ cây được lưu vào
// SharedPreferences dưới dạng một khối JSON duy nhất — đủ nhẹ cho một app
// chỉ lưu ghi chú văn bản, không cần tới cơ sở dữ liệu thật.

/// Id của thư mục gốc. Không phải một ThuMuc thật trong danh sách, luôn tồn
/// tại sẵn, không đổi tên/xoá/di chuyển được.
const String thuMucGoc = 'goc';

class ThuMuc {
  ThuMuc({required this.id, required this.ten, required this.chaId});

  final String id;
  String ten;
  String chaId;

  Map<String, dynamic> toJson() => {'id': id, 'ten': ten, 'cha': chaId};

  factory ThuMuc.fromJson(Map<String, dynamic> j) => ThuMuc(
        id: j['id'] as String,
        ten: j['ten'] as String,
        chaId: j['cha'] as String,
      );
}

class GhiChuFile {
  GhiChuFile({
    required this.id,
    required this.ten,
    required this.chaId,
    required this.noiDung,
    required this.capNhat,
  });

  final String id;
  String ten;
  String chaId;
  String noiDung;
  DateTime capNhat;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ten': ten,
        'cha': chaId,
        'noiDung': noiDung,
        'capNhat': capNhat.millisecondsSinceEpoch,
      };

  factory GhiChuFile.fromJson(Map<String, dynamic> j) => GhiChuFile(
        id: j['id'] as String,
        ten: j['ten'] as String,
        chaId: j['cha'] as String,
        noiDung: j['noiDung'] as String? ?? '',
        capNhat: DateTime.fromMillisecondsSinceEpoch(
          j['capNhat'] as int? ?? 0,
        ),
      );
}
