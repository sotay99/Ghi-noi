// (YÊU CẦU MỚI) Hộp thoại CHẶN giữa màn hình khi một NGƯỜI DÙNG chạm trần
// hạn mức AI riêng của họ (xem `GIOI_HAN_AI` trong cloud-function/index.js)
// — khác hẳn "Cảnh báo hạn mức API" (modal_canh_bao_api.dart, cấp TÀI
// KHOẢN Groq chung, chỉ admin thấy). Đây là cảnh báo cho CHÍNH người đang
// bị chặn, mọi loại tài khoản (đã/chưa đăng nhập), ba loại hạn mức.
//
// Hai việc gộp trong một tệp vì luôn đi cùng nhau:
// 1. Ghi nhớ CẢ NGÀY (SharedPreferences) đã chạm trần loại nào — để các nút
//    AI liên quan tự chặn ngay từ bước bấm, không cần gọi mạng rồi mới biết.
// 2. Hiện hộp thoại — bắt buộc bấm "Đã hiểu" mới đóng được.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ba loại hạn mức — PHẢI khớp đúng `loai` server dùng trong
/// `GIOI_HAN_AI`/`thuHanMucAi` (cloud-function/index.js): 'kyTu' (văn bản,
/// gồm cả trò chuyện AI), 'anhByte' (ảnh), 'amThanhGiay' (âm thanh).
enum LoaiHanMucAi { vanBan, hinhAnh, amThanh }

String _maLoai(LoaiHanMucAi loai) {
  switch (loai) {
    case LoaiHanMucAi.vanBan:
      return 'vanBan';
    case LoaiHanMucAi.hinhAnh:
      return 'hinhAnh';
    case LoaiHanMucAi.amThanh:
      return 'amThanh';
  }
}

String _ngayHomNay() => DateTime.now().toIso8601String().substring(0, 10);

String _khoaThongDiep(LoaiHanMucAi loai) => 'hanMucAiThongDiep_${_maLoai(loai)}_${_ngayHomNay()}';

/// `true` dành RIÊNG cho nhánh tự động (kiểm tra chính tả theo câu lúc gõ,
/// không ai bấm nút) — chỉ hiện hộp thoại lần ĐẦU trong ngày, những lần sau
/// lặng lẽ (tránh hộp thoại bật liên tục mỗi câu gõ xong).
String _khoaDaBaoTuDong(LoaiHanMucAi loai) => 'hanMucAiDaBaoTuDong_${_maLoai(loai)}_${_ngayHomNay()}';

/// Lỗi riêng khi server trả `hanMucAi: true` — các file `gui_*_gemini.dart`/
/// `kiem_tra_*.dart` ném lỗi này THAY CHO `Exception` thường, để nơi gọi
/// (trang_soan_thao.dart/man_hinh_tro_chuyen.dart) nhận diện chắc chắn và
/// hiện đúng hộp thoại, không lẫn vào các lỗi mạng/lỗi khác.
class LoiHanMucAi implements Exception {
  const LoiHanMucAi(this.loai, this.thongDiep);
  final LoaiHanMucAi loai;
  final String thongDiep;
  @override
  String toString() => thongDiep;
}

/// Ghi nhớ hôm nay đã chạm trần [loai], kèm đúng câu thông báo server trả
/// về — để lần sau KHÔNG cần gọi mạng mới biết, chặn thẳng từ bước bấm nút.
Future<void> ghiNhoDaChamHanMucAi(LoaiHanMucAi loai, String thongDiep) async {
  final kho = await SharedPreferences.getInstance();
  await kho.setString(_khoaThongDiep(loai), thongDiep);
}

/// Trả về câu thông báo đã lưu nếu HÔM NAY đã chạm trần [loai], `null` nếu
/// chưa (hoặc đã qua ngày mới — khoá mang theo ngày nên tự "hết hạn").
Future<String?> doanDaChamHanMucAiHomNay(LoaiHanMucAi loai) async {
  final kho = await SharedPreferences.getInstance();
  return kho.getString(_khoaThongDiep(loai));
}

/// CHỈ dùng cho nhánh tự động chính tả: hỏi "đã hiện hộp thoại cho loại này
/// hôm nay chưa", rồi tự đánh dấu đã hiện — gọi đúng MỘT LẦN ngay trước khi
/// quyết định có hiện hộp thoại hay lặng lẽ bỏ qua.
Future<bool> danhDauDaBaoTuDongHomNay(LoaiHanMucAi loai) async {
  final kho = await SharedPreferences.getInstance();
  final khoa = _khoaDaBaoTuDong(loai);
  if (kho.getBool(khoa) == true) return true; // đã hiện rồi — nơi gọi tự lặng lẽ.
  await kho.setBool(khoa, true);
  return false; // chưa hiện lần nào hôm nay — nơi gọi hiện hộp thoại lần này.
}

/// Hộp thoại CHẶN giữa màn hình — `barrierDismissible: false` + `PopScope`
/// chặn cả nút Back, CHỈ đóng được qua nút "Đã hiểu".
Future<void> hienHopThoaiHanMucAi(BuildContext context, String thongDiep) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.block_outlined, color: Color(0xFFC5221F), size: 36),
        title: const Text('Đã hết hạn mức AI hôm nay'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(thongDiep),
              const SizedBox(height: 14),
              const Text('Cần dùng nhiều hơn mức này? Liên hệ:'),
              const SizedBox(height: 6),
              const SelectableText('Email: lookatmevanthanhpham@gmail.com'),
              const SelectableText('Email khác: 219thanhdeptrai@gmail.com'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    ),
  );
}

/// Dùng ở ĐẦU mỗi hàm xử lý khi bấm một nút AI tường minh (ghi âm, tóm tắt,
/// mở rộng, viết lại, chuyển ảnh, trò chuyện AI, kiểm tra toàn văn...) — nếu
/// hôm nay đã biết chạm trần [loai], hiện lại hộp thoại NGAY và trả `true`
/// để nơi gọi `return` sớm, không gọi mạng. Trả `false` nếu chưa chạm trần,
/// nơi gọi tiếp tục luồng bình thường.
Future<bool> chanNeuDaChamHanMucAi(BuildContext context, LoaiHanMucAi loai) async {
  final daLuu = await doanDaChamHanMucAiHomNay(loai);
  if (daLuu == null) return false;
  if (context.mounted) await hienHopThoaiHanMucAi(context, daLuu);
  return true;
}

/// Xử lý khi một lượt gọi AI tường minh (bấm nút) THẤT BẠI vì chạm trần —
/// ghi nhớ + hiện hộp thoại luôn trong một bước. Gọi trong nhánh
/// `catch (e)` của nơi gọi, kiểm tra `e is LoiHanMucAi` trước.
Future<void> xuLyLoiHanMucAi(BuildContext context, LoiHanMucAi loi) async {
  await ghiNhoDaChamHanMucAi(loi.loai, loi.thongDiep);
  if (context.mounted) await hienHopThoaiHanMucAi(context, loi.thongDiep);
}
