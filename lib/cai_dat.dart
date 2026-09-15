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
  static const _khoaThoiGianTuTatMicro = 'ghi_noi_thoi_gian_tu_tat_micro_phut';

  /// Số giây chờ, kể từ lúc người dùng ngừng gõ phím, tới khi micro tự bật
  /// lại. Mặc định 1 giây.
  double thoiGianBatLaiGiay = 1.0;

  /// Số phút liên tục không có thêm chữ nào (dù do nói hay gõ tay) trong lúc
  /// micro đang bật thì tự tắt HẲN. Mặc định 15 phút, giới hạn 10-45.
  int thoiGianTuTatMicroPhut = 15;

  static const gioiHanDuoiTuTatMicro = 10;
  static const gioiHanTrenTuTatMicro = 45;

  /// Có tự chèn một dấu cách ngay sau đoạn chữ mỗi lần nói xong hay không.
  /// Mặc định bật.
  bool tuDongChenKhoangCach = true;

  /// Có tự gọi AI kiểm tra chính tả mỗi khi có đoạn văn mới hay không.
  /// Mặc định TẮT — tính năng này gọi mạng và tốn hạn mức AI.
  bool kiemTraChinhTaBangAI = false;

  /// Phím tắt tắt/mở micro: một tổ hợp bộ biến đổi ('Ctrl' hoặc 'Alt') và
  /// một phím khác đi kèm. Mặc định Ctrl + F. Chỉ có tác dụng khi máy có gắn
  /// bàn phím vật lý (bao gồm bàn phím rời cắm vào máy tính bảng).
  String phimTatBoBienDoi = 'Ctrl';
  String phimTatPhim = 'F';

  Future<void> tai() async {
    final kho = await SharedPreferences.getInstance();
    thoiGianBatLaiGiay = kho.getDouble(_khoaThoiGianBatLai) ?? 1.0;
    tuDongChenKhoangCach = kho.getBool(_khoaTuDongChenCach) ?? true;
    kiemTraChinhTaBangAI = kho.getBool(_khoaKiemTraChinhTaAI) ?? false;
    phimTatBoBienDoi = kho.getString(_khoaPhimTatBoBienDoi) ?? 'Ctrl';
    phimTatPhim = kho.getString(_khoaPhimTatPhim) ?? 'F';
    thoiGianTuTatMicroPhut =
        (kho.getInt(_khoaThoiGianTuTatMicro) ?? 15).clamp(gioiHanDuoiTuTatMicro, gioiHanTrenTuTatMicro);
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

  Future<void> datThoiGianTuTatMicro(int phut) async {
    thoiGianTuTatMicroPhut = phut.clamp(gioiHanDuoiTuTatMicro, gioiHanTrenTuTatMicro);
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaThoiGianTuTatMicro, thoiGianTuTatMicroPhut);
  }
}
