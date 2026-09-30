// Clipboard hệ thống GIÀU ĐỊNH DẠNG trên web — vượt quá khả năng của
// `Clipboard` (package:flutter/services.dart), vốn chỉ có `text/plain`. Gọi
// thẳng Clipboard API của trình duyệt (`navigator.clipboard`) qua
// `dart:js_util` — CHỦ Ý không dùng `dart:js_interop`/`package:web` (đòi
// thêm phụ thuộc mới chưa có cách tự kiểm chứng trong môi trường này, xem
// giải thích tương tự ở `lib/ghi_am_the_web.dart`). `dart:js_util` là thư
// viện lõi của SDK, không cần thêm gì vào `pubspec.yaml`.
//
// AN TOÀN TUYỆT ĐỐI với nơi gọi: MỌI hàm ở đây bọc `try/catch` quanh toàn bộ
// thân hàm, trả về `false`/`null` cho bất kỳ lỗi/thiếu hỗ trợ nào (trình
// duyệt cũ, thiếu quyền clipboard-read, không ở ngữ cảnh bảo mật...) — nơi
// gọi (`_phimAoCopy`/`_phimAoCut`/`_phimAoPaste`) LUÔN có sẵn đường lùi về
// `Clipboard` chữ thô hệt trước giờ, không bao giờ vì lỗi ở đây mà hỏng thao
// tác copy/cắt/dán cơ bản.
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

/// Ghi CẢ `text/plain` LẪN `text/html` vào clipboard hệ thống trong MỘT lượt
/// (`navigator.clipboard.write`) — trả về `true` nếu thành công. Nơi gọi chỉ
/// nên tự ghi `text/plain` riêng (qua `Clipboard.setData`) khi hàm này trả
/// về `false`, tránh ghi hai lần chồng nhau.
Future<bool> ghiClipboardCoDinhDang(String vanBanTho, String htmlNoiDung) async {
  try {
    final navigator = js_util.getProperty(js_util.globalThis, 'navigator');
    if (navigator == null) return false;
    final clipboard = js_util.getProperty(navigator, 'clipboard');
    final clipboardItemCtor = js_util.getProperty(js_util.globalThis, 'ClipboardItem');
    if (clipboard == null || clipboardItemCtor == null) return false;

    final blobPlain = html.Blob([vanBanTho], 'text/plain');
    final blobHtml = html.Blob([htmlNoiDung], 'text/html');
    // Dựng object `{'text/plain': Blob, 'text/html': Blob}` bằng
    // `newObject`/`setProperty` thay vì `jsify` một Map — `jsify` đệ quy vào
    // trong Map/List, còn giá trị ở đây (Blob) đã LÀ một tham chiếu JS thật
    // (qua `dart:html`) rồi, gán thẳng bằng `setProperty` chắc chắn hơn.
    final items = js_util.newObject();
    js_util.setProperty(items, 'text/plain', blobPlain);
    js_util.setProperty(items, 'text/html', blobHtml);
    final item = js_util.callConstructor(clipboardItemCtor, [items]);
    final promise = js_util.callMethod(clipboard, 'write', [
      js_util.jsify([item]),
    ]);
    await js_util.promiseToFuture<void>(promise);
    return true;
  } catch (_) {
    return false;
  }
}

/// Đọc mục `text/html` (nếu có) từ clipboard hệ thống — dùng để lấy lại gói
/// định dạng đã ghi bởi [ghiClipboardCoDinhDang] (xem cách nhúng/tách ở
/// `trang_soan_thao.dart`). Trả về `null` nếu không đọc được/không có mục
/// `text/html` nào — nơi gọi vẫn tiếp tục dán chữ thô như trước giờ (đã đọc
/// xong `text/plain` bằng đường riêng, không phụ thuộc kết quả hàm này).
Future<String?> docHtmlTuClipboard() async {
  try {
    final navigator = js_util.getProperty(js_util.globalThis, 'navigator');
    if (navigator == null) return null;
    final clipboard = js_util.getProperty(navigator, 'clipboard');
    if (clipboard == null) return null;

    final itemsPromise = js_util.callMethod(clipboard, 'read', []);
    final items = await js_util.promiseToFuture<Object?>(itemsPromise);
    if (items == null) return null;
    final soLuong = (js_util.getProperty(items, 'length') as num).toInt();
    for (var i = 0; i < soLuong; i++) {
      final item = js_util.getProperty(items, i);
      if (item == null) continue;
      final types = js_util.getProperty(item, 'types');
      if (types == null) continue;
      final soLoai = (js_util.getProperty(types, 'length') as num).toInt();
      var coHtml = false;
      for (var k = 0; k < soLoai; k++) {
        if (js_util.getProperty(types, k) == 'text/html') {
          coHtml = true;
          break;
        }
      }
      if (!coHtml) continue;
      final blobPromise = js_util.callMethod(item, 'getType', ['text/html']);
      final blob = await js_util.promiseToFuture<Object?>(blobPromise);
      if (blob == null) continue;
      final textPromise = js_util.callMethod(blob, 'text', []);
      final text = await js_util.promiseToFuture<Object?>(textPromise);
      if (text is String) return text;
    }
    return null;
  } catch (_) {
    return null;
  }
}
