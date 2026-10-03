// Mô hình dữ liệu: thư mục và ghi chú. Toàn bộ cây được lưu vào
// SharedPreferences dưới dạng một khối JSON duy nhất — đủ nhẹ cho một app
// chỉ lưu ghi chú văn bản, không cần tới cơ sở dữ liệu thật.

/// Id của thư mục gốc. Không phải một ThuMuc thật trong danh sách, luôn tồn
/// tại sẵn, không đổi tên/xoá/di chuyển được.
const String thuMucGoc = 'goc';

/// Một "nút" trong cây ĐÃ LỌC đọc được từ một tệp .zip nhập vào — CHƯA phải
/// dữ liệu thật trong `KhoDuLieu`, chỉ dùng để xem trước trong
/// `ModalNhapZip` rồi mới quyết định đưa vào thư mục nào (xem
/// `KhoDuLieu.nhapCayZip`). Chỉ giữ tệp `.txt` và thư mục có chứa `.txt` ở
/// đâu đó bên trong — mọi thứ khác đã bị lọc bỏ trước khi tới đây.
class NutZip {
  NutZip.thuMuc(this.ten, this.con) : noiDung = null;
  NutZip.tep(this.ten, String noiDung)
      : noiDung = noiDung,
        con = const [];

  final String ten;
  final String? noiDung;
  final List<NutZip> con;

  bool get laThuMuc => noiDung == null;
}

class ThuMuc {
  ThuMuc({
    required this.id,
    required this.ten,
    required this.chaId,
    this.mau,
    this.thoiGianXoa,
  });

  final String id;
  String ten;
  String chaId;

  /// Màu chữ của tên thư mục (ARGB, xem `lib/mau_co_ban.dart`) —
  /// `null` là màu chữ mặc định, chưa từng đổi.
  int? mau;

  /// Khác `null` nghĩa là đang nằm trong Thùng rác — thời điểm bị "chuyển
  /// vào thùng rác". `chaId` vẫn giữ NGUYÊN vị trí cũ để khôi phục lại đúng
  /// chỗ. Không còn hiện ra trong `noiDungThuMuc` khi đang ở trạng thái này.
  DateTime? thoiGianXoa;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ten': ten,
        'cha': chaId,
        if (mau != null) 'mau': mau,
        if (thoiGianXoa != null)
          'xoa': thoiGianXoa!.millisecondsSinceEpoch,
      };

  factory ThuMuc.fromJson(Map<String, dynamic> j) => ThuMuc(
        id: j['id'] as String,
        ten: j['ten'] as String,
        chaId: j['cha'] as String,
        mau: j['mau'] as int?,
        thoiGianXoa: j['xoa'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['xoa'] as int),
      );
}

class GhiChuFile {
  GhiChuFile({
    required this.id,
    required this.ten,
    required this.chaId,
    required this.noiDung,
    required this.capNhat,
    this.mau,
    this.thoiGianXoa,
  });

  final String id;
  String ten;
  String chaId;
  String noiDung;
  DateTime capNhat;

  /// Màu chữ của tên tệp — cùng vai trò với `ThuMuc.mau`.
  int? mau;

  /// Cùng vai trò với `ThuMuc.thoiGianXoa` — xem chú thích ở đó.
  DateTime? thoiGianXoa;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ten': ten,
        'cha': chaId,
        'noiDung': noiDung,
        'capNhat': capNhat.millisecondsSinceEpoch,
        if (mau != null) 'mau': mau,
        if (thoiGianXoa != null)
          'xoa': thoiGianXoa!.millisecondsSinceEpoch,
      };

  factory GhiChuFile.fromJson(Map<String, dynamic> j) => GhiChuFile(
        id: j['id'] as String,
        ten: j['ten'] as String,
        chaId: j['cha'] as String,
        noiDung: j['noiDung'] as String? ?? '',
        capNhat: DateTime.fromMillisecondsSinceEpoch(
          j['capNhat'] as int? ?? 0,
        ),
        mau: j['mau'] as int?,
        thoiGianXoa: j['xoa'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['xoa'] as int),
      );
}
