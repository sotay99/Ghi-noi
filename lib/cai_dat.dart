// Cài đặt của app — đọc/ghi vào SharedPreferences, tách riêng khỏi kho ghi
// chú vì đây là tuỳ chọn của NGƯỜI DÙNG về cách app vận hành, không phải nội
// dung ghi chú của họ.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dinh_dang_doan_van_tu_dien.dart';
import 'loai_thiet_bi.dart';
import 'lua_chon_phim_tat.dart';

/// Một cặp từ trong "Từ điển sửa lỗi chính tả của bạn" (xem
/// `moModalTuDienChinhTa` trong `modal_tu_dien_chinh_ta.dart`) — [loi] là
/// từ hay gõ sai thường gặp, [dsThayThe] là danh sách TỐI ĐA 3 từ thay thế
/// ("thứ nhất/hai/ba", theo đúng thứ tự trong danh sách). [dsThayThe] RỖNG
/// nghĩa là "đề xuất xoá hẳn [loi] đi", không phải thay bằng chữ nào khác.
/// [thayThe] (từ thay thế thứ NHẤT, tương thích ngược với dữ liệu cũ) vẫn
/// giữ làm getter tiện dùng ở những chỗ chỉ cần MỘT đề xuất (ví dụ "Chấp
/// nhận tất cả đề xuất của từ điển" — luôn chỉ áp dụng từ thứ nhất).
class CapTuDien {
  CapTuDien({required this.loi, String thayThe = '', List<String>? dsThayThe})
      : dsThayThe = dsThayThe ?? (thayThe.isEmpty ? [] : [thayThe]);

  String loi;

  /// Tối đa 3 phần tử, không phần tử nào rỗng.
  List<String> dsThayThe;

  String get thayThe => dsThayThe.isEmpty ? '' : dsThayThe.first;

  Map<String, dynamic> toJson() => {'loi': loi, 'dsThayThe': dsThayThe};

  static CapTuDien? tuJson(dynamic j) {
    if (j is! Map) return null;
    final loi = j['loi'];
    if (loi is! String || loi.trim().isEmpty) return null;
    final dsRaw = j['dsThayThe'];
    List<String> ds;
    if (dsRaw is List) {
      ds = dsRaw.whereType<String>().where((s) => s.isNotEmpty).take(3).toList();
    } else {
      // Dữ liệu cũ (chỉ có "thayThe" dạng một chuỗi).
      final thayThe = j['thayThe'];
      ds = (thayThe is String && thayThe.isNotEmpty) ? [thayThe] : [];
    }
    return CapTuDien(loi: loi, dsThayThe: ds);
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
  static const _khoaPhimTatBoNhoTamLoai = 'ghi_noi_phim_tat_bo_nho_tam_loai';
  static const _khoaPhimTatBoNhoTamPhimCtrl = 'ghi_noi_phim_tat_bo_nho_tam_phim_ctrl';
  static const _khoaBoNhoTamDanVanBanBat = 'ghi_noi_bo_nho_tam_dan_van_ban_bat';
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
  /// (YÊU CẦU MỚI) Mặc định TẮT — người dùng mới cài app lần đầu không bị
  /// tốn hạn mức AI ngoài ý muốn, tự bật lên khi thật sự cần.
  bool kiemTraChinhTaBangAI = false;

  /// Có tự gọi AI chèn dấu câu còn thiếu vào giữa các đoạn văn hay không.
  /// (YÊU CẦU MỚI) Mặc định TẮT — cùng lý do với `kiemTraChinhTaBangAI`.
  bool tuDongChenDauCauBangAI = false;

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

  /// (YÊU CẦU MỚI — nhánh thử nghiệm) Phím tắt ẩn/hiện modal "Bộ nhớ tạm để
  /// dán văn bản" — cùng bốn kiểu như trên, MẶC ĐỊNH bấm Shift 2 lần. Cùng
  /// vòng tự hoán đổi với [phimTatMicro]/[phimTatGhiAm] ở BA lựa chọn không
  /// tham số — xem `TinhNangPhimTat`/`datPhimTatVaTuHoanDoiNeuTrung`.
  LuaChonPhimTat phimTatBoNhoTam = const LuaChonPhimTat.shiftDup();

  /// Công tắc tổng của "Bộ nhớ tạm để dán văn bản" — mặc định BẬT. Tắt thì
  /// Cắt/Copy vẫn hoạt động như cũ (ghi vào bộ nhớ đệm hệ thống bình
  /// thường), chỉ không CÒN GHI THÊM vào lịch sử 10 dòng của app nữa, và
  /// nút/phím tắt mở bảng lịch sử cũng ẩn/vô hiệu.
  bool boNhoTamDanVanBanBat = true;

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

  /// Công tắc bật/tắt tổng của "Từ điển sửa lỗi chính tả của bạn" — mặc định
  /// BẬT. Tắt thì không gạch vàng lượn sóng nữa, nhưng người dùng vẫn xem/
  /// thêm/sửa/xoá cặp từ bình thường (chỉ phần QUÉT văn bản bị tắt).
  bool tuDienChinhTaBatHoatDong = true;

  static const _khoaTuDienChinhTaBatHoatDong =
      'ghi_noi_tu_dien_chinh_ta_bat_hoat_dong';

  Future<void> luuTuDienChinhTaBatHoatDong() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDienChinhTaBatHoatDong, tuDienChinhTaBatHoatDong);
  }

  Future<void> luuTuDienChinhTa() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(
      _khoaTuDienChinhTa,
      jsonEncode(tuDienChinhTa.map((e) => e.toJson()).toList()),
    );
  }

  /// (YÊU CẦU MỚI — nhánh thử nghiệm) "Từ điển nhập liệu nhanh" — 26 đoạn
  /// văn bản cố định, một cho mỗi chữ cái A-Z (chỉ số 0 = A, 25 = Z), gán
  /// vào phím chữ cái tương ứng để dán nhanh vào vị trí con trỏ. Khác hẳn
  /// "Từ điển sửa lỗi chính tả" (không quét/gạch chân gì cả) — đây chỉ là
  /// 26 đoạn dán nhanh, y hệt vai trò "phím tắt gõ nhanh" của một số app
  /// gõ tiếng Việt khác.
  List<String> tuDienNhapLieuNhanh = List<String>.filled(26, '');

  static const _khoaTuDienNhapLieuNhanh = 'ghi_noi_tu_dien_nhap_lieu_nhanh';

  /// Giới hạn ký tự cho MỖI dòng trong 26 dòng trên.
  static const gioiHanTuDienNhapLieuNhanh = 1000;

  /// Công tắc tổng — mặc định BẬT. Tắt thì ẩn hẳn nút mở bảng 26 dòng ở
  /// thanh công cụ và phím tắt cũng vô hiệu, nhưng nội dung 26 dòng vẫn giữ
  /// nguyên để bật lại là dùng tiếp ngay.
  bool tuDienNhapLieuNhanhBat = true;

  static const _khoaTuDienNhapLieuNhanhBat = 'ghi_noi_tu_dien_nhap_lieu_nhanh_bat';

  /// Phím tắt ẩn/hiện bảng 26 dòng — CHỈ hai lựa chọn (khác hẳn bốn lựa
  /// chọn của Micro/Ghi âm/Bộ nhớ tạm): "Alt + Shift" (MẶC ĐỊNH, cố định,
  /// không đổi được) hoặc "Ctrl + một phím tự chọn". Không tham gia vòng tự
  /// đổi hộ 3 chiều — xem `LuaChonPhimTat.altShift`.
  LuaChonPhimTat phimTatTuDienNhapLieuNhanh = const LuaChonPhimTat.altDup();

  static const _khoaPhimTatTuDienNhapLieuNhanhLoai =
      'ghi_noi_phim_tat_tu_dien_nhap_lieu_nhanh_loai';
  static const _khoaPhimTatTuDienNhapLieuNhanhPhimCtrl =
      'ghi_noi_phim_tat_tu_dien_nhap_lieu_nhanh_phim_ctrl';

  Future<void> luuTuDienNhapLieuNhanh() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaTuDienNhapLieuNhanh, jsonEncode(tuDienNhapLieuNhanh));
  }

  Future<void> datTuDienNhapLieuNhanhBat(bool bat) async {
    tuDienNhapLieuNhanhBat = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaTuDienNhapLieuNhanhBat, bat);
  }

  /// (YÊU CẦU MỚI) Lựa chọn "Ctrl + ..." của tính năng này không tham gia
  /// vòng tự đổi hộ — nơi gọi (modal cài đặt) tự kiểm tra trùng với phím tắt
  /// CỐ ĐỊNH (`tenXungDot`) và với Micro/Ghi âm/Bộ nhớ tạm TRƯỚC khi gọi hàm
  /// này, y hệt cách modal Bộ nhớ tạm đang làm cho lựa chọn "Ctrl + ..." của
  /// riêng nó.
  Future<void> datPhimTatTuDienNhapLieuNhanh(LuaChonPhimTat moi) async {
    phimTatTuDienNhapLieuNhanh = moi;
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaPhimTatTuDienNhapLieuNhanhLoai, moi.loai);
    if (moi.phim != null) {
      await kho.setString(_khoaPhimTatTuDienNhapLieuNhanhPhimCtrl, moi.phim!);
    }
  }

  /// (YÊU CẦU MỚI) Thứ tự hiển thị 26 dòng ở MODAL CÀI ĐẶT và ở modal "Thay
  /// đổi thứ tự giữa các dòng" — `'hang'` (theo hàng phím Q-W-E.../A-S-D.../
  /// Z-X-C... của bàn phím vật lý, MẶC ĐỊNH) hoặc `'bangChuCai'` (A→Z, như
  /// trước khi có tính năng này). Xem `thuTuTuDienNhapLieuNhanhTheoKieu` ở
  /// `mau_phim_tu_dien_nhap_lieu_nhanh.dart`.
  String thuTuTuDienNhapLieuNhanh = 'hang';
  static const _khoaThuTuTuDienNhapLieuNhanh =
      'ghi_noi_thu_tu_tu_dien_nhap_lieu_nhanh';

  Future<void> datThuTuTuDienNhapLieuNhanh(String gt) async {
    thuTuTuDienNhapLieuNhanh = gt;
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaThuTuTuDienNhapLieuNhanh, gt);
  }

  /// (YÊU CẦU MỚI) Tab đang mở gần nhất trong bảng 26 dòng của Từ điển nhập
  /// liệu nhanh — `'ganDay'` | `'hang'` | `'bangChuCai'`. Mặc định `'hang'`
  /// (tab giữa). Nhớ lâu dài để mở lại đúng tab cũ.
  String tabTuDienNhapLieuNhanh = 'hang';
  static const _khoaTabTuDienNhapLieuNhanh = 'ghi_noi_tab_tu_dien_nhap_lieu_nhanh';

  Future<void> datTabTuDienNhapLieuNhanh(String gt) async {
    tabTuDienNhapLieuNhanh = gt;
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaTabTuDienNhapLieuNhanh, gt);
  }

  /// (YÊU CẦU MỚI) Lịch sử dán gần nhất ở bảng 26 dòng — trước đây chỉ là
  /// biến tĩnh trong bộ nhớ (mất khi F5), giờ lưu lâu dài. Phần tử ở CUỐI
  /// danh sách là lần dán MỚI NHẤT; tối đa 10 phần tử.
  List<int> ganDayTuDienNhapLieuNhanh = [];
  static const _khoaGanDayTuDienNhapLieuNhanh =
      'ghi_noi_gan_day_tu_dien_nhap_lieu_nhanh';

  Future<void> ghiNhanGanDayTuDienNhapLieuNhanh(int i) async {
    ganDayTuDienNhapLieuNhanh.remove(i);
    ganDayTuDienNhapLieuNhanh.add(i);
    while (ganDayTuDienNhapLieuNhanh.length > 10) {
      ganDayTuDienNhapLieuNhanh.removeAt(0);
    }
    final kho = await SharedPreferences.getInstance();
    await kho.setString(
      _khoaGanDayTuDienNhapLieuNhanh,
      jsonEncode(ganDayTuDienNhapLieuNhanh),
    );
  }

  /// `null` nếu dòng [i] không nằm trong lịch sử dán gần nhất; ngược lại độ
  /// "mới" của nó (0 = mới nhất) — 0-4 tô xanh đậm, 5-9 tô xanh nhạt.
  int? doMoiTuDienNhapLieuNhanh(int i) {
    final vt = ganDayTuDienNhapLieuNhanh.lastIndexOf(i);
    if (vt == -1) return null;
    return ganDayTuDienNhapLieuNhanh.length - 1 - vt;
  }

  /// (YÊU CẦU MỚI) Định dạng thủ công kèm theo mỗi dòng trong 26 dòng của
  /// "Từ điển nhập liệu nhanh" — mỗi phần tử là JSON (DANH SÁCH vùng,
  /// `VungDinhDangDoanVan.toJson()`, KHÔNG gói base64 như gói clipboard —
  /// tự lưu/tự đọc, không cần phong bì xác minh) hoặc `null` nếu dòng đó
  /// không có định dạng gì. Gán qua `Dán`/Ctrl+V (xem
  /// `modal_tu_dien_nhap_lieu_nhanh.dart`), xoá khi gõ tay (toạ độ không
  /// còn đáng tin) hoặc xoá trắng dòng.
  List<String?> dinhDangTuDienNhapLieuNhanh = List<String?>.filled(26, null);
  static const _khoaDinhDangTuDienNhapLieuNhanh =
      'ghi_noi_dinh_dang_tu_dien_nhap_lieu_nhanh';

  Future<void> luuDinhDangTuDienNhapLieuNhanh() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(
      _khoaDinhDangTuDienNhapLieuNhanh,
      jsonEncode(dinhDangTuDienNhapLieuNhanh),
    );
  }

  Future<void> datDinhDangTuDienNhapLieuNhanh(int i, String? goi) async {
    dinhDangTuDienNhapLieuNhanh[i] = goi;
    await luuDinhDangTuDienNhapLieuNhanh();
  }

  /// (YÊU CẦU MỚI) Chiều sắp xếp tên (A→Z/Z→A) của CÂY THƯ MỤC — lưu riêng
  /// theo TỪNG thư mục (khoá là id thư mục, hoặc id "ngôi nhà chung"/gốc) —
  /// `true` = Z→A (đảo ngược), vắng mặt (không có khoá) = A→Z (mặc định).
  /// Thư mục luôn đứng TRÊN tệp bất kể chiều nào — chỉ thứ tự BÊN TRONG
  /// từng nhóm bị đảo.
  Map<String, bool> sapXepNguocTheoThuMuc = {};
  static const _khoaSapXepNguocThuMuc = 'ghi_noi_sap_xep_nguoc_thu_muc';

  bool sapXepNguoc(String thuMucId) => sapXepNguocTheoThuMuc[thuMucId] ?? false;

  Future<void> datSapXepNguoc(String thuMucId, bool nguoc) async {
    if (nguoc) {
      sapXepNguocTheoThuMuc[thuMucId] = true;
    } else {
      sapXepNguocTheoThuMuc.remove(thuMucId);
    }
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaSapXepNguocThuMuc, jsonEncode(sapXepNguocTheoThuMuc));
  }

  /// Giải mã định dạng của dòng [i] thành danh sách vùng — rỗng nếu dòng đó
  /// không có định dạng/dữ liệu hỏng.
  List<VungDinhDangDoanVan> docDinhDangTuDienNhapLieuNhanh(int i) {
    final raw = dinhDangTuDienNhapLieuNhanh[i];
    if (raw == null) return const [];
    try {
      final ds = jsonDecode(raw);
      if (ds is! List) return const [];
      final doDai = tuDienNhapLieuNhanh[i].length;
      return ds
          .map((j) => VungDinhDangDoanVan.tuJson(j, doDai))
          .whereType<VungDinhDangDoanVan>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // --------------------------------------- "Khi khởi động App: Mở tệp..."

  /// (YÊU CẦU MỚI) Một trong ba kiểu: 'ganDayNhat' (MẶC ĐỊNH) — mở lại
  /// tệp đang soạn thảo gần đây nhất, dù thuộc bộ nhớ nội bộ hay đám mây;
  /// 'tepTrong' — mở một tệp TRỐNG trong thư mục đã chọn
  /// ([khoiDongThuMucLoai]/[khoiDongThuMucId]); 'tepChiDinh' — mở đúng
  /// một tệp cố định ([khoiDongTepLoai]/[khoiDongTepId]). Xem
  /// `khoi_dong_tep.dart` cho toàn bộ logic áp dụng lúc mở app.
  String kieuMoKhiKhoiDong = 'ganDayNhat';

  /// Chỉ có ý nghĩa khi [kieuMoKhiKhoiDong] == 'tepTrong'. [khoiDongThuMucLoai]
  /// là 'noiBo' hoặc 'damMay'; [khoiDongThuMucUid] chỉ có giá trị khi là
  /// 'damMay' (phát hiện đổi tài khoản Google — tài khoản khác thì coi
  /// như thư mục không còn hợp lệ nữa).
  String? khoiDongThuMucLoai;
  String? khoiDongThuMucId;
  String? khoiDongThuMucUid;

  /// Chỉ có ý nghĩa khi [kieuMoKhiKhoiDong] == 'tepChiDinh' — dùng CHUNG
  /// cho cả hai lựa chọn con A ("tệp đang soạn thảo", tự ghim ngay lúc
  /// tích chọn) và B ("chọn tệp trong cây thư mục", tự duyệt cây) — cả
  /// hai chỉ khác nhau ở CÁCH lấy được bộ ba này, còn lưu/áp dụng thì y
  /// hệt nhau.
  String? khoiDongTepLoai;
  String? khoiDongTepId;
  String? khoiDongTepUid;

  static const _khoaKieuMoKhiKhoiDong = 'ghi_noi_kieu_mo_khi_khoi_dong';
  static const _khoaKhoiDongThuMucLoai = 'ghi_noi_khoi_dong_thu_muc_loai';
  static const _khoaKhoiDongThuMucId = 'ghi_noi_khoi_dong_thu_muc_id';
  static const _khoaKhoiDongThuMucUid = 'ghi_noi_khoi_dong_thu_muc_uid';
  static const _khoaKhoiDongTepLoai = 'ghi_noi_khoi_dong_tep_loai';
  static const _khoaKhoiDongTepId = 'ghi_noi_khoi_dong_tep_id';
  static const _khoaKhoiDongTepUid = 'ghi_noi_khoi_dong_tep_uid';

  Future<void> luuCaiDatKhoiDong() async {
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaKieuMoKhiKhoiDong, kieuMoKhiKhoiDong);
    Future<void> luuChuoi(String khoa, String? gia) =>
        gia == null ? kho.remove(khoa) : kho.setString(khoa, gia);
    await luuChuoi(_khoaKhoiDongThuMucLoai, khoiDongThuMucLoai);
    await luuChuoi(_khoaKhoiDongThuMucId, khoiDongThuMucId);
    await luuChuoi(_khoaKhoiDongThuMucUid, khoiDongThuMucUid);
    await luuChuoi(_khoaKhoiDongTepLoai, khoiDongTepLoai);
    await luuChuoi(_khoaKhoiDongTepId, khoiDongTepId);
    await luuChuoi(_khoaKhoiDongTepUid, khoiDongTepUid);
  }

  /// (YÊU CẦU MỚI) Theo dõi tệp đang soạn thảo GẦN NHẤT thuộc BỘ NHỚ ĐÁM
  /// MÂY — chỉ có ý nghĩa khi tệp gần nhất THỰC SỰ là đám mây; khi là nội
  /// bộ thì để trống cả hai (lúc đó lựa chọn "gần đây nhất" đọc THẲNG cơ
  /// chế "ghi chú đang mở" đã có sẵn của bộ nhớ nội bộ, tự nhớ đủ rồi,
  /// không cần theo dõi thêm ở đây).
  String? ganDayNhatDamMayId;
  String? ganDayNhatDamMayUid;

  static const _khoaGanDayNhatDamMayId = 'ghi_noi_gan_day_nhat_dam_may_id';
  static const _khoaGanDayNhatDamMayUid = 'ghi_noi_gan_day_nhat_dam_may_uid';

  /// Gọi mỗi khi MỞ một ghi chú MỚI, bất kể kho nào (xem `_moGhiChu` ở
  /// `trang_soan_thao.dart`). [laDamMay] false thì chỉ cần xoá dấu vết đám
  /// mây cũ — đã chuyển sang mở một ghi chú NỘI BỘ.
  Future<void> ghiNhoGanDayNhat({
    required bool laDamMay,
    String? id,
    String? uid,
  }) async {
    final kho = await SharedPreferences.getInstance();
    if (!laDamMay) {
      ganDayNhatDamMayId = null;
      ganDayNhatDamMayUid = null;
      await kho.remove(_khoaGanDayNhatDamMayId);
      await kho.remove(_khoaGanDayNhatDamMayUid);
      return;
    }
    ganDayNhatDamMayId = id;
    ganDayNhatDamMayUid = uid;
    if (id == null) {
      await kho.remove(_khoaGanDayNhatDamMayId);
    } else {
      await kho.setString(_khoaGanDayNhatDamMayId, id);
    }
    if (uid == null) {
      await kho.remove(_khoaGanDayNhatDamMayUid);
    } else {
      await kho.setString(_khoaGanDayNhatDamMayUid, uid);
    }
  }

  Future<void> tai() async {
    final kho = await SharedPreferences.getInstance();
    kieuMoKhiKhoiDong = kho.getString(_khoaKieuMoKhiKhoiDong) ?? 'ganDayNhat';
    khoiDongThuMucLoai = kho.getString(_khoaKhoiDongThuMucLoai);
    khoiDongThuMucId = kho.getString(_khoaKhoiDongThuMucId);
    khoiDongThuMucUid = kho.getString(_khoaKhoiDongThuMucUid);
    khoiDongTepLoai = kho.getString(_khoaKhoiDongTepLoai);
    khoiDongTepId = kho.getString(_khoaKhoiDongTepId);
    khoiDongTepUid = kho.getString(_khoaKhoiDongTepUid);
    ganDayNhatDamMayId = kho.getString(_khoaGanDayNhatDamMayId);
    ganDayNhatDamMayUid = kho.getString(_khoaGanDayNhatDamMayUid);
    thoiGianBatLaiGiay = kho.getDouble(_khoaThoiGianBatLai) ?? 1.0;
    tuDongChenKhoangCach = kho.getBool(_khoaTuDongChenCach) ?? true;
    kiemTraChinhTaBangAI = kho.getBool(_khoaKiemTraChinhTaAI) ?? false;
    phimTatMicro = LuaChonPhimTat.tuLuu(
      kho.getString(_khoaPhimTatMicroLoai),
      kho.getString(_khoaPhimTatMicroPhimCtrl),
    );
    phimTatGhiAm = LuaChonPhimTat.tuLuu(
      kho.getString(_khoaPhimTatGhiAmLoai) ?? 'tab',
      kho.getString(_khoaPhimTatGhiAmPhimCtrl),
    );
    phimTatBoNhoTam = LuaChonPhimTat.tuLuu(
      kho.getString(_khoaPhimTatBoNhoTamLoai) ?? 'shiftDup',
      kho.getString(_khoaPhimTatBoNhoTamPhimCtrl),
    );
    boNhoTamDanVanBanBat = kho.getBool(_khoaBoNhoTamDanVanBanBat) ?? true;
    thoiGianTuTatMicroGiay =
        (kho.getInt(_khoaThoiGianTuTatMicro) ?? 45).clamp(gioiHanDuoiTuTatMicro, gioiHanTrenTuTatMicro);
    tuDongGuiNgamTheGhiAm = kho.getBool(_khoaTuDongGuiNgamTheGhiAm) ?? true;
    nguongTuDongGuiTheGhiAmGiay = (kho.getInt(_khoaNguongTuDongGuiTheGhiAmGiay) ?? 20)
        .clamp(gioiHanDuoiNguongTuDongGuiTheGhiAm, gioiHanTrenNguongTuDongGuiTheGhiAm);
    tuDongMoBangDieuKhienGhiAm = kho.getBool(_khoaTuDongMoBangDieuKhienGhiAm);
    ghimThanhDinhDang = kho.getBool(_khoaGhimThanhDinhDang) ?? false;
    tuDongChenDauCauBangAI = kho.getBool(_khoaTuDongChenDauCau) ?? false;
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
    tuDienChinhTaBatHoatDong =
        kho.getBool(_khoaTuDienChinhTaBatHoatDong) ?? true;
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
    tuDienNhapLieuNhanhBat = kho.getBool(_khoaTuDienNhapLieuNhanhBat) ?? true;
    phimTatTuDienNhapLieuNhanh = LuaChonPhimTat.tuLuu(
      kho.getString(_khoaPhimTatTuDienNhapLieuNhanhLoai) ?? 'altDup',
      kho.getString(_khoaPhimTatTuDienNhapLieuNhanhPhimCtrl),
    );
    final tuDienNhapLieuNhanhRaw = kho.getString(_khoaTuDienNhapLieuNhanh);
    if (tuDienNhapLieuNhanhRaw != null) {
      try {
        final ds = jsonDecode(tuDienNhapLieuNhanhRaw);
        if (ds is List) {
          tuDienNhapLieuNhanh = List<String>.generate(
            26,
            (i) => i < ds.length && ds[i] is String ? ds[i] as String : '',
          );
        }
      } catch (_) {
        // Dữ liệu hỏng — giữ 26 dòng trống, không ném lỗi làm hỏng cả app.
      }
    }
    thuTuTuDienNhapLieuNhanh = kho.getString(_khoaThuTuTuDienNhapLieuNhanh) ?? 'hang';
    tabTuDienNhapLieuNhanh = kho.getString(_khoaTabTuDienNhapLieuNhanh) ?? 'hang';
    final ganDayRaw = kho.getString(_khoaGanDayTuDienNhapLieuNhanh);
    if (ganDayRaw != null) {
      try {
        final ds = jsonDecode(ganDayRaw);
        if (ds is List) {
          ganDayTuDienNhapLieuNhanh =
              ds.whereType<int>().where((i) => i >= 0 && i < 26).toList();
        }
      } catch (_) {
        // Dữ liệu hỏng — giữ lịch sử trống, không ném lỗi làm hỏng cả app.
      }
    }
    dinhDangTuDienNhapLieuNhanh = List<String?>.filled(26, null);
    final dinhDangTuDienRaw = kho.getString(_khoaDinhDangTuDienNhapLieuNhanh);
    if (dinhDangTuDienRaw != null) {
      try {
        final ds = jsonDecode(dinhDangTuDienRaw);
        if (ds is List) {
          dinhDangTuDienNhapLieuNhanh = List<String?>.generate(
            26,
            (i) => i < ds.length && ds[i] is String ? ds[i] as String : null,
          );
        }
      } catch (_) {
        // Dữ liệu hỏng — giữ 26 dòng không định dạng, không ném lỗi làm
        // hỏng cả app.
      }
    }
    final tenThietBiDaLuu = kho.getString(_khoaThietBiChonTay);
    thietBiChonTay = tenThietBiDaLuu == null
        ? null
        : ThietBi.values.cast<ThietBi?>().firstWhere(
              (t) => t!.name == tenThietBiDaLuu,
              orElse: () => null,
            );
    sapXepNguocTheoThuMuc = {};
    final sapXepRaw = kho.getString(_khoaSapXepNguocThuMuc);
    if (sapXepRaw != null) {
      try {
        final m = jsonDecode(sapXepRaw);
        if (m is Map) {
          sapXepNguocTheoThuMuc = {
            for (final e in m.entries)
              if (e.value == true) e.key as String: true,
          };
        }
      } catch (_) {
        // Dữ liệu hỏng — giữ A→Z cho mọi thư mục, không ném lỗi làm hỏng app.
      }
    }
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

  Future<void> datBoNhoTamDanVanBanBat(bool bat) async {
    boNhoTamDanVanBanBat = bat;
    final kho = await SharedPreferences.getInstance();
    await kho.setBool(_khoaBoNhoTamDanVanBanBat, bat);
  }

  Future<void> _datPhimTatBoNhoTam(LuaChonPhimTat moi) async {
    phimTatBoNhoTam = moi;
    final kho = await SharedPreferences.getInstance();
    await kho.setString(_khoaPhimTatBoNhoTamLoai, moi.loai);
    if (moi.phim != null) await kho.setString(_khoaPhimTatBoNhoTamPhimCtrl, moi.phim!);
  }

  LuaChonPhimTat phimTatCuaTinhNang(TinhNangPhimTat t) => switch (t) {
        TinhNangPhimTat.micro => phimTatMicro,
        TinhNangPhimTat.ghiAm => phimTatGhiAm,
        TinhNangPhimTat.boNhoTam => phimTatBoNhoTam,
      };

  Future<void> _datPhimTatTinhNang(TinhNangPhimTat t, LuaChonPhimTat moi) async {
    switch (t) {
      case TinhNangPhimTat.micro:
        await _datPhimTatMicro(moi);
      case TinhNangPhimTat.ghiAm:
        await _datPhimTatGhiAm(moi);
      case TinhNangPhimTat.boNhoTam:
        await _datPhimTatBoNhoTam(moi);
    }
  }

  /// (YÊU CẦU MỚI — nhánh thử nghiệm) Bản 3 CHIỀU của cơ chế tự đổi hộ —
  /// giờ có BA chức năng dùng chung bốn kiểu phím tắt (Micro, Ghi âm, Bộ
  /// nhớ tạm để dán văn bản), không chỉ hai như trước. Lưu phím tắt MỚI
  /// cho [tinhNang]; nếu nó trùng với MỘT HOẶC CẢ HAI chức năng còn lại ở
  /// một trong ba lựa chọn không tham số (xem `_vongTuDoiPhimTat`), tự đổi
  /// hộ (lần theo vòng tròn tới khi tìm được một lựa chọn không đụng chức
  /// năng thứ ba luôn — tối đa 3 lần thử, đủ cho vòng chỉ có 3 phần tử).
  /// Trả về map {chức năng bị đổi hộ: phím tắt mới của nó} — rỗng nếu
  /// không có gì tự đổi.
  Future<Map<TinhNangPhimTat, LuaChonPhimTat>> datPhimTatTinhNangVaTuHoanDoiNeuTrung({
    required TinhNangPhimTat tinhNang,
    required LuaChonPhimTat moi,
  }) async {
    final doiHo = <TinhNangPhimTat, LuaChonPhimTat>{};
    if (_vongTuDoiPhimTat.containsKey(moi.loai)) {
      for (final khac in TinhNangPhimTat.values) {
        if (khac == tinhNang) continue;
        if (!phimTatCuaTinhNang(khac).coBangVoi(moi)) continue;
        var ungVien = _vongTuDoiPhimTat[moi.loai]!;
        var vong = 0;
        bool dungDuoc() {
          if (doiHo.values.any((v) => v.coBangVoi(ungVien))) return false;
          for (final t in TinhNangPhimTat.values) {
            if (t == tinhNang || t == khac) continue;
            if (phimTatCuaTinhNang(t).coBangVoi(ungVien)) return false;
          }
          return true;
        }

        while (!dungDuoc() && vong < 3) {
          ungVien = _vongTuDoiPhimTat[ungVien.loai] ?? const LuaChonPhimTat.tab();
          vong++;
        }
        doiHo[khac] = ungVien;
      }
    }

    await _datPhimTatTinhNang(tinhNang, moi);
    for (final e in doiHo.entries) {
      await _datPhimTatTinhNang(e.key, e.value);
    }
    return doiHo;
  }

  /// Giữ lại API CŨ (bool, chỉ biết Micro/Ghi âm) cho những nơi chưa cần
  /// biết tới "Bộ nhớ tạm" — bọc quanh bản 3 chiều ở trên. Trả về `true`
  /// nếu có xảy ra tự đổi hộ ở MỘT TRONG HAI chức năng Micro/Ghi âm (bỏ
  /// qua trường hợp hiếm chỉ riêng "Bộ nhớ tạm" bị đổi hộ — màn Cài đặt
  /// Micro/Ghi âm không cần biết, đã có modal riêng của Bộ nhớ tạm tự lo).
  Future<bool> datPhimTatVaTuHoanDoiNeuTrung({
    required bool laMicro,
    required LuaChonPhimTat moi,
  }) async {
    final doiHo = await datPhimTatTinhNangVaTuHoanDoiNeuTrung(
      tinhNang: laMicro ? TinhNangPhimTat.micro : TinhNangPhimTat.ghiAm,
      moi: moi,
    );
    return doiHo.containsKey(TinhNangPhimTat.micro) || doiHo.containsKey(TinhNangPhimTat.ghiAm);
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
    'Ctrl+Enter': 'Gửi tin nhắn ở các kênh trò chuyện',
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
