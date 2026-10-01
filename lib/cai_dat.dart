// Cài đặt của app — đọc/ghi vào SharedPreferences, tách riêng khỏi kho ghi
// chú vì đây là tuỳ chọn của NGƯỜI DÙNG về cách app vận hành, không phải nội
// dung ghi chú của họ.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loai_thiet_bi.dart';
import 'lua_chon_phim_tat.dart';

/// Một cặp từ trong "Từ điển sửa lỗi chính tả của bạn" (xem
/// `moModalTuDienChinhTa` trong `modal_tu_dien_chinh_ta.dart`) — [loi] là
/// từ hay gõ sai thường gặp, [thayThe] là
/// từ thay vào. [thayThe] RỖNG nghĩa là "đề xuất xoá hẳn [loi] đi", không
/// phải thay bằng chữ nào khác.
class CapTuDien {
  CapTuDien({required this.loi, this.thayThe = ''});

  String loi;
  String thayThe;

  Map<String, dynamic> toJson() => {'loi': loi, 'thayThe': thayThe};

  static CapTuDien? tuJson(dynamic j) {
    if (j is! Map) return null;
    final loi = j['loi'];
    if (loi is! String || loi.trim().isEmpty) return null;
    final thayThe = j['thayThe'];
    return CapTuDien(loi: loi, thayThe: thayThe is String ? thayThe : '');
  }
}

class CaiDat {
  static const _khoaThoiGianBatLai = 'ghi_noi_thoi_gian_bat_lai_micro_giay';
  static const _khoaTuDongChenCach = 'ghi_noi_tu_dong_chen_khoang_cach';
  static const _khoaKiemTraChinhTaAI = 'ghi_noi_kiem_tra_chinh_ta_ai';
  static const _khoaPhimTatMicroLoai = 'ghi_noi_phim_tat_micro_loai';
  static const _khoaPhimTatMicroPhimCtrl = 'ghi_noi_phim_tat_micro_phim_ctrl';
  static const _khoaPhimTatGhiAmLoai = 'ghi_noi_phim_tat_ghi_am_loai';
  static const _khoaPhimTatGhiAmPhimCtrl = 'ghi_noi_phim_tat_ghi_am_phim_ctrl';
  static const _khoaThoiGianTuTatMicro = 'ghi_noi_thoi_gian_tu_tat_micro_giay';
  static const _khoaTuDongGuiNgamTheGhiAm = 'ghi_noi_tu_dong_gui_ngam_the_ghi_am';
  static const _khoaNguongTuDongGuiTheGhiAmGiay =
      'ghi_noi_nguong_tu_dong_gui_the_ghi_am_giay';
  static const _khoaTuDongChenDauCau = 'ghi_noi_tu_dong_chen_dau_cau_ai';
  static const _khoaMucDoDaiDeXuat = 'ghi_noi_muc_do_dai_de_xuat';
  static const _khoaCauLenhTuyChinhKiemTraToanVan =
      'ghi_noi_cau_lenh_tuy_chinh_kiem_tra_toan_van';
  static const _khoaMauChuGanNhat = 'ghi_noi_mau_chu_gan_nhat';
  static const _khoaMauNenGanNhat = 'ghi_noi_mau_nen_gan_nhat';
  static const _khoaTuDongMoBangDieuKhienGhiAm =
      'ghi_noi_tu_dong_mo_bang_dieu_khien_ghi_am';
  static const _khoaGhimThanhDinhDang = 'ghi_noi_ghim_thanh_dinh_dang';

  /// Số giây chờ, kể từ lúc người dùng ngừng gõ phím, tới khi micro tự bật
  /// lại. Mặc định 1 giây.
  double thoiGianBatLaiGiay = 1.0;

  /// Số giây liên tục không có thêm chữ nào (dù do nói hay gõ tay) trong lúc
  /// micro đang bật thì tự tắt HẲN. Mặc định 45 giây, giới hạn 10-120.
  int thoiGianTuTatMicroGiay = 45;

  static const gioiHanDuoiTuTatMicro = 10;
  static const gioiHanTrenTuTatMicro = 120;

  /// Trình ghi âm: có tự động gửi ngầm một thẻ đi chuyển hoá thành văn bản
  /// ngay khi nó tích đủ số giây (xem [nguongTuDongGuiTheGhiAmGiay]) hay
  /// không, không cần người dùng tự bấm. Mặc định BẬT.
  bool tuDongGuiNgamTheGhiAm = true;

  /// Ngưỡng số giây — chỉ có ý nghĩa khi [tuDongGuiNgamTheGhiAm] bật. Mặc
  /// định 20 giây, giới hạn 5-120.
  int nguongTuDongGuiTheGhiAmGiay = 20;

  static const gioiHanDuoiNguongTuDongGuiTheGhiAm = 5;
  static const gioiHanTrenNguongTuDongGuiTheGhiAm = 120;

  /// Mỗi lần bắt đầu ghi âm, Bảng điều khiển trình ghi âm có tự mở ra ngay
  /// hay không. `null` = CHƯA từng lưu — nơi gọi tự suy ra mặc định theo
  /// thiết bị (PC/Mac → HIỆN; Android/iPhone → ẨN, xem `ThietBi`), KHÔNG
  /// suy ở đây vì `CaiDat` không tự biết thiết bị hiện tại.
  bool? tuDongMoBangDieuKhienGhiAm;

  /// Có tự chèn một dấu cách ngay sau đoạn chữ mỗi lần nói xong hay không.
  /// Mặc định bật.
  bool tuDongChenKhoangCach = true;

  /// Thanh công cụ định dạng (đậm/nghiêng/gạch chân/màu chữ...) có đang được
  /// GHIM hay không — ghim thì bấm nút định dạng KHÔNG tự ẩn thanh đó đi
  /// nữa. Mặc định TẮT (chưa ghim — thanh tự ẩn sau mỗi lần bấm, đúng hành
  /// vi mới).
  bool ghimThanhDinhDang = false;

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

  /// Phím tắt tắt/mở "Micro vừa nói vừa ra chữ" — một trong bốn kiểu (xem
  /// `LuaChonPhimTat`): bấm Ctrl 2 lần liên tiếp (MẶC ĐỊNH), phím Tab một
  /// mình, Ctrl + một phím bất kỳ do người dùng chọn, hoặc bấm Shift 2 lần
  /// liên tiếp. Chỉ có tác dụng khi máy có gắn bàn phím vật lý (bao gồm
  /// bàn phím rời cắm vào máy tính bảng).
  LuaChonPhimTat phimTatMicro = const LuaChonPhimTat.ctrlDup();

  /// Phím tắt mở/đóng "trình ghi âm" (Ghi âm xong mới ra chữ — tạo thẻ ghi
  /// âm) — cùng bốn kiểu như trên, MẶC ĐỊNH phím Tab một mình. Không bao
  /// giờ được phép trùng [phimTatMicro] ở BẤT KỲ lựa chọn không tham số
  /// nào (Tab/CtrlDup/ShiftDup) — xem `datPhimTatVaTuHoanDoiNeuTrung`.
  LuaChonPhimTat phimTatGhiAm = const LuaChonPhimTat.tab();

  /// Màu chữ/màu nền gần nhất người dùng dùng ở công cụ định dạng thủ công —
  /// nút màu chữ/màu nền trên thanh công cụ và phím tắt Ctrl+Shift+C /
  /// Ctrl+Shift+H đều dùng lại đúng màu này. Mặc định đỏ (chữ) / vàng (nền)
  /// khi chưa từng dùng lần nào.
  Color mauChuGanNhat = Colors.red;
  Color mauNenGanNhat = Colors.yellow;

  /// Cài đặt chế độ tìm kiếm/thay thế: có phân biệt chữ Hoa/thường hay không.
  /// `true` = phân biệt (khớp chính xác); `false` (mặc định) = không phân
  /// biệt (khớp cả hai, so sánh sau khi hạ chữ thường).
  bool timKiemPhanBietHoaThuong = false;

  /// Cài đặt chế độ tìm kiếm/thay thế: có phân biệt dấu thanh tiếng Việt hay
  /// không. `true` (mặc định) = phân biệt (khớp chính xác, có dấu ra có dấu,
  /// không dấu ra không dấu); `false` = không phân biệt (khớp cả không dấu và
  /// có dấu, so sánh sau khi bỏ dấu).
  bool timKiemPhanBietDauThanh = true;

  static const _khoaTimKiemPhanBietHoaThuong =
      'ghi_noi_tim_kiem_phan_biet_hoa_thuong';
  static const _khoaTimKiemPhanBietDauThanh =
      'ghi_noi_tim_kiem_phan_biet_dau_thanh';

  /// (VIỆC 5) Ba cài đặt cho hành vi khi xuống dòng (Enter) — mặc định cả
  /// ba đều BẬT.
  bool tuDongThemDauCham = true;
  bool tuDongThutDauDong = true;
  bool tuDongThemDuongKeChia = true;

  /// Số dấu cách chèn vào khi thụt đầu dòng (tính năng "Tự động thụt đầu
  /// dòng khi xuống dòng" ở trên) — người dùng chọn từ 1 tới 7 trong Menu
  /// thả xuống ở màn hình Cài đặt. Mặc định 3 (trước đây ép cứng 5, rồi 4).
  int soDauCachThutDauDong = 3;

  static const _khoaTuDongThemDauCham = 'ghi_noi_tu_dong_them_dau_cham';
  static const _khoaTuDongThutDauDong = 'ghi_noi_tu_dong_thut_dau_dong';
  static const _khoaTuDongThemDuongKeChia = 'ghi_noi_tu_dong_them_duong_ke_chia';
  static const _khoaSoDauCachThutDauDong = 'ghi_noi_so_dau_cach_thut_dau_dong';

  /// Màu và độ mờ (opacity, %) của đường kẻ chia văn bản — chỉ có ý nghĩa
  /// khi [tuDongThemDuongKeChia] đang bật. Mặc định tím 25%, giữ NGUYÊN
  /// giao diện cũ (trước khi hai lựa chọn này tồn tại) cho người dùng chưa
  /// từng đổi gì.
  int mauDuongKeChia = Colors.purple.toARGB32();
  int phanTramMoDuongKeChia = 25;

  static const _khoaMauDuongKeChia = 'ghi_noi_mau_duong_ke_chia';
  static const _khoaPhanTramMoDuongKeChia = 'ghi_noi_phan_tram_mo_duong_ke_chia';

  /// Chấm tròn tím đánh dấu cuối văn bản — bật/tắt và màu. Mặc định BẬT,
  /// màu tím, giữ nguyên giao diện cũ cho người dùng chưa từng đổi gì.
  bool chamCuoiVanBanBat = true;
  int mauChamCuoiVanBan = Colors.purple.toARGB32();

  static const _khoaChamCuoiVanBanBat = 'ghi_noi_cham_cuoi_van_ban_bat';
  static const _khoaMauChamCuoiVanBan = 'ghi_noi_mau_cham_cuoi_van_ban';

  /// Có tự viết hoa chữ cái đầu của một từ ngay sau dấu câu kết thúc câu
  /// (. , : ! ?) hay không. Mặc định BẬT.
  bool tuDongVietHoaDauCau = true;

  static const _khoaTuDongVietHoaDauCau = 'ghi_noi_tu_dong_viet_hoa_dau_cau';

  /// "Chuẩn hoá các cặp dấu đóng-mở ngoặc" — (),{},[]," " — xoá dấu cách
  /// thừa ngay sau dấu mở/ngay trước dấu đóng của mỗi cặp, ngay sau mỗi lần
  /// gõ một trong bảy ký tự đó. Mặc định BẬT.
  bool tuDongChuanHoaNgoac = true;

  static const _khoaTuDongChuanHoaNgoac = 'ghi_noi_tu_dong_chuan_hoa_ngoac';

  /// Chỉ có ý nghĩa trên WEB (xem `loai_thiet_bi.dart`): người dùng tự chọn
  /// tay một trong ba "bản" thiết bị khi cơ chế tự đoán (User-Agent) đoán
  /// sai — mic bị trục trặc. `null` (mặc định) nghĩa là để tự đoán, không
  /// ép. Vô hại trên Android/iOS gốc — không có chỗ nào đọc giá trị này ở
  /// đó.
  ThietBi? thietBiChonTay;

  static const _khoaThietBiChonTay = 'ghi_noi_thiet_bi_chon_tay';

  /// Bảng ký tự đặc biệt (nút "*" ở Bộ phím nhanh) — bấm một ký tự có tự
  /// đóng luôn bảng lại hay không. Mặc định BẬT.
  bool tuDongDongBangKyTuDacBiet = true;

  static const _khoaTuDongDongBangKyTuDacBiet = 'ghi_noi_tu_dong_dong_bang_ky_tu_dac_biet';

  /// Dải gợi ý "Tải app APK ổn định hơn" — chỉ hiện trên bản Web khi thiết
  /// bị (tự đoán hoặc chọn tay) là Android. Người dùng bấm X đóng lại thì
  /// nhớ luôn, không hiện lại nữa. Mặc định HIỆN (false = chưa đóng).
  bool anGoiYTaiApk = false;

  static const _khoaAnGoiYTaiApk = 'ghi_noi_an_goi_y_tai_apk';

  /// "Từ điển sửa lỗi chính tả của bạn" — danh sách cặp (từ lỗi/từ thay
  /// thế) người dùng tự khai ở `ManHinhTuDienChinhTa`. Đây là THAM CHIẾU
  /// THẬT (không phải bản sao) — màn hình đó tự thêm/xoá/sửa thẳng vào danh
  /// sách này rồi gọi [luuTuDienChinhTa], không cần cơ chế callback riêng.
  List<CapTuDien> tuDienChinhTa = [];

  static const _khoaTuDienChinhTa = 'ghi_noi_tu_dien_chinh_ta';

  Future<void> luuTuDienChinhTa() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(
      _khoaTuDienChinhTa,
      jsonEncode(tuDienChinhTa.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> tai() async {
    final kho = await SharedPreferences.getInstance();
    thoiGianBatLaiGiay = kho.getDouble(_khoaThoiGianBatLai) ?? 1.0;
    tuDongChenKhoangCach = kho.getBool(_khoaTuDongChenCach) ?? true;
    kiemTraChinhTaBangAI = kho.getBool(_khoaKiemTraChinhTaAI) ?? true;
    phimTatMicro = LuaChonPhimTat.tuLuu(
      kho.getString(_khoaPhimTatMicroLoai),
      kho.getString(_khoaPhimTatMicroPhimCtrl),
    );
    phimTatGhiAm = LuaChonPhimTat.tuLuu(
      kho.getString(_khoaPhimTatGhiAmLoai) ?? 'tab',
      kho.getString(_khoaPhimTatGhiAmPhimCtrl),
    );
    thoiGianTuTatMicroGiay =
        (kho.getInt(_khoaThoiGianTuTatMicro) ?? 45).clamp(gioiHanDuoiTuTatMicro, gioiHanTrenTuTatMicro);
    tuDongGuiNgamTheGhiAm = kho.getBool(_khoaTuDongGuiNgamTheGhiAm) ?? true;
    nguongTuDongGuiTheGhiAmGiay = (kho.getInt(_khoaNguongTuDongGuiTheGhiAmGiay) ?? 20)
        .clamp(gioiHanDuoiNguongTuDongGuiTheGhiAm, gioiHanTrenNguongTuDongGuiTheGhiAm);
    tuDongMoBangDieuKhienGhiAm = kho.getBool(_khoaTuDongMoBangDieuKhienGhiAm);
    ghimThanhDinhDang = kho.getBool(_khoaGhimThanhDinhDang) ?? false;
    tuDongChenDauCauBangAI = kho.getBool(_khoaTuDongChenDauCau) ?? true;
    mucDoDaiDeXuat = (kho.getInt(_khoaMucDoDaiDeXuat) ?? 2).clamp(0, 4);
    cauLenhTuyChinhKiemTraToanVan = kho.getString(_khoaCauLenhTuyChinhKiemTraToanVan) ?? '';
    final mc = kho.getInt(_khoaMauChuGanNhat);
    if (mc != null) mauChuGanNhat = Color(mc);
    final mn = kho.getInt(_khoaMauNenGanNhat);
    if (mn != null) mauNenGanNhat = Color(mn);
    timKiemPhanBietHoaThuong =
        kho.getBool(_khoaTimKiemPhanBietHoaThuong) ?? false;
    timKiemPhanBietDauThanh =
        kho.getBool(_khoaTimKiemPhanBietDauThanh) ?? true;
    tuDongThemDauCham = kho.getBool(_khoaTuDongThemDauCham) ?? true;
    tuDongThutDauDong = kho.getBool(_khoaTuDongThutDauDong) ?? true;
    soDauCachThutDauDong =
        (kho.getInt(_khoaSoDauCachThutDauDong) ?? 3).clamp(1, 7);
    tuDongThemDuongKeChia = kho.getBool(_khoaTuDongThemDuongKeChia) ?? true;
    mauDuongKeChia = kho.getInt(_khoaMauDuongKeChia) ?? Colors.purple.toARGB32();
    phanTramMoDuongKeChia =
        (kho.getInt(_khoaPhanTramMoDuongKeChia) ?? 25).clamp(10, 100);
    chamCuoiVanBanBat = kho.getBool(_khoaChamCuoiVanBanBat) ?? true;
    mauChamCuoiVanBan = kho.getInt(_khoaMauChamCuoiVanBan) ?? Colors.purple.toARGB32();
    tuDongVietHoaDauCau = kho.getBool(_khoaTuDongVietHoaDauCau) ?? true;
    tuDongChuanHoaNgoac = kho.getBool(_khoaTuDongChuanHoaNgoac) ?? true;
    tuDongDongBangKyTuDacBiet = kho.getBool(_khoaTuDongDongBangKyTuDacBiet) ?? true;
    anGoiYTaiApk = kho.getBool(_khoaAnGoiYTaiApk) ?? false;
    final tuDienRaw = kho.getString(_khoaTuDienChinhTa);
    tuDienChinhTa = tuDienRaw == null
        ? []
        : (() {
            try {
              final ds = jsonDecode(tuDienRaw);
              if (ds is! List) return <CapTuDien>[];
              return ds.map(CapTuDien.tuJson).whereType<CapTuDien>().toList();
            } catch (_) {
              return <CapTuDien>[];
            }
          })();
    final tenThietBiDaLuu = kho.getString(_khoaThietBiChonTay);
    thietBiChonTay = tenThietBiDaLuu == null
        ? null
        : ThietBi.values.cast<ThietBi?>().firstWhere(
              (t) => t!.name == tenThietBiDaLuu,
              orElse: () => null,
            );
  }

  /// `null` = xoá lựa chọn thủ công, quay về tự đoán.
  Future<void> datThietBiChonTay(ThietBi? t) async {
    thietBiChonTay = t;
    final kho = await SharedPreferences.getInstance();
    if (t == null) {
      await kho.remove(_khoaThietBiChonTay);
    } else {
      await kho.setString(_khoaThietBiChonTay, t.name);
    }
  }

  Future<void> datTuDongThemDauCham(bool bat) async {
    tuDongThemDauCham = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongThemDauCham, bat);
  }

  Future<void> datTuDongDongBangKyTuDacBiet(bool bat) async {
    tuDongDongBangKyTuDacBiet = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongDongBangKyTuDacBiet, bat);
  }

  Future<void> datAnGoiYTaiApk(bool an) async {
    anGoiYTaiApk = an;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaAnGoiYTaiApk, an);
  }

  Future<void> datTuDongThutDauDong(bool bat) async {
    tuDongThutDauDong = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongThutDauDong, bat);
  }

  Future<void> datSoDauCachThutDauDong(int soDauCach) async {
    soDauCachThutDauDong = soDauCach.clamp(1, 7);
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaSoDauCachThutDauDong, soDauCachThutDauDong);
  }

  Future<void> datTuDongThemDuongKeChia(bool bat) async {
    tuDongThemDuongKeChia = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongThemDuongKeChia, bat);
  }

  Future<void> datMauDuongKeChia(Color mau) async {
    mauDuongKeChia = mau.toARGB32();
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaMauDuongKeChia, mauDuongKeChia);
  }

  Future<void> datPhanTramMoDuongKeChia(int phanTram) async {
    phanTramMoDuongKeChia = phanTram.clamp(10, 100);
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaPhanTramMoDuongKeChia, phanTramMoDuongKeChia);
  }

  Future<void> datChamCuoiVanBanBat(bool bat) async {
    chamCuoiVanBanBat = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaChamCuoiVanBanBat, bat);
  }

  Future<void> datMauChamCuoiVanBan(Color mau) async {
    mauChamCuoiVanBan = mau.toARGB32();
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaMauChamCuoiVanBan, mauChamCuoiVanBan);
  }

  Future<void> datTuDongVietHoaDauCau(bool bat) async {
    tuDongVietHoaDauCau = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongVietHoaDauCau, bat);
  }

  Future<void> datTuDongChuanHoaNgoac(bool bat) async {
    tuDongChuanHoaNgoac = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongChuanHoaNgoac, bat);
  }

  Future<void> datTimKiemPhanBietHoaThuong(bool bat) async {
    timKiemPhanBietHoaThuong = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTimKiemPhanBietHoaThuong, bat);
  }

  Future<void> datTimKiemPhanBietDauThanh(bool bat) async {
    timKiemPhanBietDauThanh = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTimKiemPhanBietDauThanh, bat);
  }

  Future<void> datMauChuGanNhat(Color mau) async {
    mauChuGanNhat = mau;
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaMauChuGanNhat, mau.toARGB32());
  }

  Future<void> datMauNenGanNhat(Color mau) async {
    mauNenGanNhat = mau;
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaMauNenGanNhat, mau.toARGB32());
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

  Future<void> _datPhimTatMicro(LuaChonPhimTat moi) async {
    phimTatMicro = moi;
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaPhimTatMicroLoai, moi.loai);
    if (moi.phim != null) await kho.setString(_khoaPhimTatMicroPhimCtrl, moi.phim!);
  }

  Future<void> _datPhimTatGhiAm(LuaChonPhimTat moi) async {
    phimTatGhiAm = moi;
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaPhimTatGhiAmLoai, moi.loai);
    if (moi.phim != null) await kho.setString(_khoaPhimTatGhiAmPhimCtrl, moi.phim!);
  }

  /// Ba lựa chọn "không cần tham số" (Tab, bấm Ctrl 2 lần, bấm Shift 2 lần)
  /// tạo thành một vòng tự đổi hộ khi trùng — xem `datPhimTatVaTuHoanDoiNeuTrung`.
  /// Xếp thành vòng tròn 3 phần tử để LUÔN có đúng một hướng đổi tới, không
  /// mơ hồ: Tab → CtrlDup → ShiftDup → Tab. `Ctrl + một phím` (có tham số)
  /// KHÔNG nằm trong vòng này — trùng thì chặn lưu, bắt tự chọn phím khác.
  static const Map<String, LuaChonPhimTat> _vongTuDoiPhimTat = {
    'tab': LuaChonPhimTat.ctrlDup(),
    'ctrlDup': LuaChonPhimTat.shiftDup(),
    'shiftDup': LuaChonPhimTat.tab(),
  };

  /// Lưu phím tắt MỚI cho Micro (nếu [laMicro]) hoặc Ghi âm (nếu không) —
  /// và nếu việc này khiến hai chức năng cùng dẫm chân lên nhau ở MỘT
  /// TRONG BA lựa chọn không tham số (xem `_vongTuDoiPhimTat`), tự đổi
  /// luôn chức năng CÒN LẠI sang lựa chọn tiếp theo trong vòng để không
  /// bao giờ trùng nhau. Trả về `true` nếu có xảy ra tự đổi hộ như vậy —
  /// màn Cài đặt dùng giá trị này để quyết định có hiện thông báo hay
  /// không.
  Future<bool> datPhimTatVaTuHoanDoiNeuTrung({
    required bool laMicro,
    required LuaChonPhimTat moi,
  }) async {
    final hienTaiCuaKia = laMicro ? phimTatGhiAm : phimTatMicro;
    LuaChonPhimTat? moiCuaKia;
    if (_vongTuDoiPhimTat.containsKey(moi.loai) && hienTaiCuaKia.coBangVoi(moi)) {
      moiCuaKia = _vongTuDoiPhimTat[moi.loai];
    }

    if (laMicro) {
      await _datPhimTatMicro(moi);
    } else {
      await _datPhimTatGhiAm(moi);
    }
    if (moiCuaKia != null) {
      if (laMicro) {
        await _datPhimTatGhiAm(moiCuaKia);
      } else {
        await _datPhimTatMicro(moiCuaKia);
      }
    }
    return moiCuaKia != null;
  }

  Future<void> datThoiGianTuTatMicro(int giay) async {
    thoiGianTuTatMicroGiay = giay.clamp(gioiHanDuoiTuTatMicro, gioiHanTrenTuTatMicro);
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaThoiGianTuTatMicro, thoiGianTuTatMicroGiay);
  }

  Future<void> datTuDongGuiNgamTheGhiAm(bool bat) async {
    tuDongGuiNgamTheGhiAm = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongGuiNgamTheGhiAm, bat);
  }

  Future<void> datGhimThanhDinhDang(bool bat) async {
    ghimThanhDinhDang = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaGhimThanhDinhDang, bat);
  }

  Future<void> datTuDongMoBangDieuKhienGhiAm(bool bat) async {
    tuDongMoBangDieuKhienGhiAm = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDongMoBangDieuKhienGhiAm, bat);
  }

  Future<void> datNguongTuDongGuiTheGhiAmGiay(int giay) async {
    nguongTuDongGuiTheGhiAmGiay =
        giay.clamp(gioiHanDuoiNguongTuDongGuiTheGhiAm, gioiHanTrenNguongTuDongGuiTheGhiAm);
    final kho = await SharedPreferences.getInstance();
    await kho.setInt(_khoaNguongTuDongGuiTheGhiAmGiay, nguongTuDongGuiTheGhiAmGiay);
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

  /// Danh sách phím tắt CỐ ĐỊNH của app — dùng chung cho cả việc kiểm tra
  /// xung đột khi người dùng đổi phím tắt micro (`man_hinh_cai_dat.dart`) lẫn
  /// modal "Danh sách phím tắt". Đây là NGUỒN DUY NHẤT của các tổ hợp này,
  /// tránh lặp lại rải rác nhiều nơi.
  ///
  /// Khoá là "boBienDoi+PHIM" (ví dụ 'Ctrl+Z'), giá trị là mô tả ngắn để
  /// hiện trong thông báo xung đột / modal.
  static const Map<String, String> phimTatCoDinh = {
    'Ctrl+Z': 'Lùi lại',
    'Ctrl+Shift+Z': 'Tiến tới',
    'Ctrl+F': 'Tìm kiếm và Thay thế',
    'Ctrl+A': 'Chọn tất cả',
    'Ctrl+S': 'Lưu',
    'Ctrl+X': 'Cắt',
    'Ctrl+C': 'Sao chép',
    'Ctrl+V': 'Dán',
    'Ctrl+B': 'Đậm',
    'Ctrl+I': 'Nghiêng',
    'Ctrl+U': 'Gạch chân',
    'Ctrl+Shift+X': 'Gạch ngang thân',
    'Ctrl+Shift+Equal': 'Chữ trên (superscript)',
    'Ctrl+Equal': 'Chữ dưới (subscript)',
    'Ctrl+Shift+C': 'Màu chữ',
    'Ctrl+Shift+H': 'Màu nền chữ',
    'Ctrl+Q': 'Xoá định dạng văn bản',
    // Dành riêng cho "Gửi" ở khung chat với AI (`man_hinh_tro_chuyen.dart`,
    // Enter một mình là xuống dòng) — chặn không cho đặt trùng phím tắt
    // Micro/Ghi âm, để hai phím tắt không giẫm chân nhau.
    'Ctrl+Enter': 'Gửi tin nhắn trong khung chat với AI',
  };

  /// Kiểm tra một lựa chọn Ctrl+<phim> có trùng phím tắt CỐ ĐỊNH nào của
  /// app không (Lùi lại, Tìm kiếm, Đậm...). Trả về mô tả chức năng đang
  /// trùng, hoặc null nếu không trùng. Chỉ có ý nghĩa cho [moi.loai] ==
  /// 'ctrl' — Tab/CtrlDup/ShiftDup không bao giờ trùng phím tắt cố định (toàn
  /// bộ `phimTatCoDinh` đều là tổ hợp Ctrl+...).
  static String? tenXungDot(LuaChonPhimTat moi) {
    if (moi.loai != 'ctrl') return null;
    return phimTatCoDinh['Ctrl+${moi.phim}'];
  }
}
