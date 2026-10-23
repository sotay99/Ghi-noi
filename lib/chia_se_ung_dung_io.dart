import 'package:share_plus/share_plus.dart';

/// Bản Android/iOS/desktop — dùng `share_plus` (đã có sẵn trong app cho
/// việc chia sẻ TỆP, xem `luu_va_chia_se_tep_io.dart`) để mở màn hình chia
/// sẻ thật của hệ điều hành với TEXT + link, tương đương `navigator.share`
/// bên web. Luôn trả `true` (đã mở được màn hình chia sẻ hệ thống) —
/// `share_plus` không báo lại việc người dùng chọn ứng dụng nào hay huỷ,
/// coi như đã "làm xong phần của app", không cần rơi về copy link.
Future<bool> chiaSeUngDung({
  required String tieuDe,
  required String vanBan,
  required String url,
}) async {
  await SharePlus.instance.share(
    ShareParams(subject: tieuDe, text: '$vanBan\n$url'),
  );
  return true;
}
