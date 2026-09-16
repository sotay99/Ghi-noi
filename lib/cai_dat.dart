// Cài đặt của app — đọc/ghi vào SharedPreferences, tách riêng khỏi kho ghi
// chú vì đây là tuỳ chọn của NGƯỜI DÙNG về cách app vận hành, không phải nội
// dung ghi chú của họ.

import 'package:shared_preferences/shared_preferences.dart';

class CaiDat {
  static const _khoaThoiGianBatLai = 'ghi_noi_thoi_gian_bat_lai_micro_giay';
  static const _khoaTuDongChenCach = 'ghi_noi_tu_dong_chen_khoang_cach';
  static const _khoaKiemTraChinhTaAI = 'ghi_noi_kiem_tra_chinh_ta_ai';
  static const _khoaPhimTatBoBienDoi = 'ghi_noi_phim_tat_bo_bien_doi';
  static const _khoaPhimTatPhim = 'ghi_noi_phim_tat_phim';
  static const _khoaThoiGianTuTatMicro = 'ghi_noi_thoi_gian_tu_tat_micro_giay';
  static const _khoaTuDongChenDauCau = 'ghi_noi_tu_dong_chen_dau_cau_ai';
  static const _khoaMucDoDaiDeXuat = 'ghi_noi_muc_do_dai_de_xuat';
  static const _khoaCauLenhTuyChinhKiemTraToanVan =
      'ghi_noi_cau_lenh_tuy_chinh_kiem_tra_toan_van';

  /// Số giây chờ, kể từ lúc người dùng ngừng gõ phím, tới khi micro tự bật
  /// lại. Mặc định 1 giây.
  double thoiGianBatLaiGiay = 1.0;

  /// Số giây liên tục không có thêm chữ nào (dù do nói hay gõ tay) trong lúc
  /// micro đang bật thì tự tắt HẲN. Mặc định 45 giây, giới hạn 10-120.
  int thoiGianTuTatMicroGiay = 45;

  static const gioiHanDuoiTuTatMicro = 10;
  static const gioiHanTrenTuTatMicro = 120;

  /// Có tự chèn một dấu cách ngay sau đoạn chữ mỗi lần nói xong hay không.
  /// Mặc định bật.
  bool tuDongChenKhoangCach = true;

  /// Có tự gọi AI kiểm tra chính tả mỗi khi có đoạn văn mới hay không.
  /// Mặc định BẬT.
  bool kiemTraChinhTaBangAI = true;

  /// Có tự gọi AI chèn dấu câu còn thiếu vào giữa các đoạn văn hay không.
  /// Mặc định BẬT.
  bool tuDongChenDauCauBangAI = true;

  /// Mức độ dài của từng đoạn văn được AI đề xuất khi "Kiểm tra toàn văn",
  /// chỉ số 0-4 tương ứng Rất ngắn/Ngắn/Trung bình/Dài/Rất dài. Mặc định 2
  /// (Trung bình).
  int mucDoDaiDeXuat = 2;

  /// Câu lệnh riêng của người dùng, gửi kèm chỉ dẫn hệ thống mỗi khi bấm
  /// "Kiểm tra toàn văn". Mặc định rỗng (không có).
  String cauLenhTuyChinhKiemTraToanVan = '';

  /// Giới hạn độ dài của [cauLenhTuyChinhKiemTraToanVan].
  static const gioiHanCauLenhTuyChinh = 500;

  /// Khoảng ký tự (min, max) tham khảo cho từng mức của [mucDoDaiDeXuat].
  static const List<(int, int)> khoangKyTuTheoMucDoDaiDeXuat = [
    (4, 8), // Rất ngắn
    (8, 14), // Ngắn
    (12, 20), // Trung bình
    (20, 34), // Dài
    (34, 56), // Rất dài
  ];

  static const List<String> tenMucDoDaiDeXuat = [
    'Rất ngắn',
    'Ngắn',
    'Trung bình',
    'Dài',
    'Rất dài',
  ];

  /// Phím tắt tắt/mở micro: một tổ hợp bộ biến đổi ('Ctrl' hoặc 'Alt') và
  /// một phím khác đi kèm. Mặc định Ctrl + F. Chỉ có tác dụng khi máy có gắn
  /// bàn phím vật lý (bao gồm bàn phím rời cắm vào máy tính bảng).
  String phimTatBoBienDoi = 'Ctrl';
  String phimTatPhim = 'F';

  Future<void> tai() async {
    final kho = await SharedPreferences.getInstance();
    thoiGianBatLaiGiay = kho.getDouble(_khoaThoiGianBatLai) ?? 1.0;
    tuDongChenKhoangCach = kho.getBool(_khoaTuDongChenCach) ?? true;
    kiemTraChinhTaBangAI = kho.getBool(_khoaKiemTraChinhTaAI) ?? true;
    phimTatBoBienDoi = kho.getString(_khoaPhimTatBoBienDoi) ?? 'Ctrl';
    phimTatPhim = kho.getString(_khoaPhimTatPhim) ?? 'F';
    thoiGianTuTatMicroGiay =
        (kho.getInt(_khoaThoiGianTuTatMicro) ?? 45).clamp(gioiHanDuoiTuTatMicro, gioiHanTrenTuTatMicro);
    tuDongChenDauCauBangAI = kho.getBool(_khoaTuDongChenDauCau) ?? true;
    mucDoDaiDeXuat = (kho.getInt(_khoaMucDoDaiDeXuat) ?? 2).clamp(0, 4);
    cauLenhTuyChinhKiemTraToanVan = kho.getString(_khoaCauLenhTuyChinhKiemTraToanVan) ?? '';
  }

  Future<void> datThoiGianBatLai(double giay) async {
    thoiGianBatLaiGiay = giay;
    final kho = await SharedPreferences.getInstance();
    await kho.setDouble(_khoaThoiGianBatLai, giay);
  }

  Future<void> datTuDongChenKhoangCach(bool bat) async {
    tuDongChenKhoangCach = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongChenCach, bat);
  }

  Future<void> datKiemTraChinhTaBangAI(bool bat) async {
    kiemTraChinhTaBangAI = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaKiemTraChinhTaAI, bat);
  }

  Future<void> datPhimTat(String boBienDoi, String phim) async {
    phimTatBoBienDoi = boBienDoi;
    phimTatPhim = phim;
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaPhimTatBoBienDoi, boBienDoi);
    await kho.setString(_khoaPhimTatPhim, phim);
  }

  Future<void> datThoiGianTuTatMicro(int giay) async {
    thoiGianTuTatMicroGiay = giay.clamp(gioiHanDuoiTuTatMicro, gioiHanTrenTuTatMicro);
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaThoiGianTuTatMicro, thoiGianTuTatMicroGiay);
  }

  Future<void> datTuDongChenDauCauBangAI(bool bat) async {
    tuDongChenDauCauBangAI = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongChenDauCau, bat);
  }

  Future<void> datMucDoDaiDeXuat(int mucDo) async {
    mucDoDaiDeXuat = mucDo.clamp(0, 4);
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaMucDoDaiDeXuat, mucDoDaiDeXuat);
  }

  Future<void> datCauLenhTuyChinhKiemTraToanVan(String cauLenh) async {
    cauLenhTuyChinhKiemTraToanVan = cauLenh;
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaCauLenhTuyChinhKiemTraToanVan, cauLenh);
  }

  /// Trả về khoảng (min, max) ký tự tham khảo cho mức độ dài hiện tại.
  (int, int) khoangKyTuDeXuatHienTai() =>
      khoangKyTuTheoMucDoDaiDeXuat[mucDoDaiDeXuat.clamp(0, 4)];
}
