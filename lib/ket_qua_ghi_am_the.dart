import 'dart:typed_data';

/// Kết quả ghi âm một thẻ: dữ liệu thô + kiểu mime thật đã dùng để ghi.
///
/// Dùng một LỚP THƯỜNG thay vì kiểu record `(Uint8List, String)` (đã dùng
/// trước đây) — nghi ngờ có thật: lỗi "web luôn phải chạm 2 lần" ở trình ghi
/// âm hoá ra KHÔNG PHẢI lỗi chạm, mà là một `TypeError` ném ra ngay trong
/// đúng luồng nhận kết quả ghi âm ở LẦN GỌI ĐẦU TIÊN sau mỗi lần đổi trạng
/// thái trình ghi âm (mở/tạo phiên mới/đóng), lỗi có hình dạng đặc trưng của
/// dart2js xử lý sai kiểu record khi đi qua `Completer` ở chế độ nén tối đa
/// (`-O4 --minify`) — chưa xác nhận chắc chắn 100% (chưa đọc được stack
/// trace thật dù đã bật `--source-maps`), nhưng đổi sang lớp thường loại
/// trừ hẳn khả năng này, không đổi ý nghĩa dữ liệu.
class KetQuaGhiAmThe {
  const KetQuaGhiAmThe(this.bytes, this.mime);
  final Uint8List bytes;
  final String mime;
}
