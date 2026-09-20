import 'package:audioplayers/audioplayers.dart';

// Dựng "nguồn phát" (Source của audioplayers) từ bytes ghi âm đang giữ
// trong bộ nhớ — TÁCH RIÊNG theo nền tảng vì `BytesSource` (audioplayers)
// trên WEB đi qua `setSourceBytes`, và bản đang dùng gặp lỗi
// `MEDIA_ELEMENT_ERROR: Unable to load URL due to content type (Code: 4)` —
// trình duyệt từ chối phát. Web dựng một Blob URL thật (`<audio>.src` chấp
// nhận thẳng, không qua encode/giải mã gì thêm) thay vì nhồi bytes qua
// đường `setSourceBytes`; Android/iOS gốc vẫn dùng `BytesSource` như cũ, ổn
// định sẵn.
export 'nguon_am_thanh_the_ghi_am_web.dart'
    if (dart.library.io) 'nguon_am_thanh_the_ghi_am_io.dart';

/// [nguon]: đưa thẳng vào `AudioPlayer.setSource`.
/// [urlDaTao]: Blob URL vừa tạo (chỉ trên web) — phải gọi
/// [giaiPhongNguonPhatGhiAm] khi đóng modal để trình duyệt thu hồi bộ nhớ;
/// `null` trên Android/iOS gốc (không tạo URL nào cả).
class NguonPhatGhiAm {
  const NguonPhatGhiAm(this.nguon, this.urlDaTao);

  final Source nguon;
  final String? urlDaTao;
}
