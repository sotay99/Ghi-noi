import 'dart:js_util' as js_util;

/// Gọi `navigator.share({title, text, url})` thật của trình duyệt (bản
/// web) — trả `true` nếu trình duyệt HỖ TRỢ và đã mở được hộp thoại chia sẻ
/// hệ thống (người dùng có thể vẫn bấm Huỷ trong đó, không có cách nào biết
/// được — Web Share API không báo lại việc đó, coi như đã "làm xong phần
/// của app"); trả `false` nếu trình duyệt KHÔNG có `navigator.share` (ví
/// dụ Firefox desktop, một số trình duyệt cũ) — nơi gọi tự rơi về phương án
/// dự phòng copy link.
Future<bool> chiaSeUngDung({
  required String tieuDe,
  required String vanBan,
  required String url,
}) async {
  try {
    final navigator = js_util.getProperty(js_util.globalThis, 'navigator');
    final coHoTro = js_util.hasProperty(navigator, 'share');
    if (!coHoTro) return false;

    final duLieu = js_util.newObject();
    js_util.setProperty(duLieu, 'title', tieuDe);
    js_util.setProperty(duLieu, 'text', vanBan);
    js_util.setProperty(duLieu, 'url', url);

    final promise = js_util.callMethod(navigator, 'share', [duLieu]);
    await js_util.promiseToFuture<void>(promise);
    return true;
  } catch (_) {
    // Người dùng bấm Huỷ trong hộp thoại hệ thống CŨNG ném lỗi
    // (AbortError) — không coi đó là thất bại cần rơi về copy link, chỉ
    // đơn giản là họ đổi ý, không có gì để báo thêm.
    return true;
  }
}
