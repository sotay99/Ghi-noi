// Nội dung đa ngôn ngữ cho hai trang pháp lý: "Điều khoản sử dụng"
// (`modal_dieu_khoan.dart`) và "Bảo mật và quyền riêng tư" (`modal_bao_mat.dart`).

import 'ngon_ngu.dart';

class ChPhapLy {
  ChPhapLy._();

  static String capNhatLanCuoi(NgonNgu nn, String ngay) =>
      nn == NgonNgu.vi ? 'Cập nhật lần cuối: $ngay' : 'Last updated: $ngay';

  // ------------------------------------------------------- Điều khoản sử dụng

  static String dieuKhoanTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Điều khoản sử dụng' : 'Terms of Use';

  static String dieuKhoanTomTat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Dùng Flowrite tức là bạn đồng ý với các điều khoản dưới đây. '
          'Flowrite là app ghi chú bằng giọng nói kèm trợ lý AI — đọc kỹ '
          '==phần 4== và ==phần 5== nếu bạn hay dùng tính năng AI.'
      : 'Using Flowrite means you agree to the terms below. Flowrite is a '
          'voice-note app with a built-in AI assistant — read ==section 4== '
          'and ==section 5== carefully if you often use the AI features.';

  static String dkMuc1TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Về Flowrite' : 'About Flowrite';
  static String dkMuc1(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Flowrite là ứng dụng ghi chú, soạn thảo văn bản bằng giọng nói kèm '
          'bàn phím, có thêm một số tính năng trợ lý AI (kiểm tra chính tả, '
          'tóm tắt, viết lại, trò chuyện...). App **đang tiếp tục được phát '
          'triển** — tính năng có thể thay đổi, bổ sung theo thời gian.'
      : 'Flowrite is a note-taking and writing app combining voice and '
          'keyboard, with a few AI-assistant features (spell check, '
          'summarizing, rewriting, chat...). The app **is still under active '
          'development** — features may change or be added over time.';

  static String dkMuc2TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tài khoản Google' : 'Google account';
  static String dkMuc2(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đăng nhập tài khoản Google là **hoàn toàn tuỳ chọn** — bạn dùng '
          'được đầy đủ Flowrite mà không cần đăng nhập. Đăng nhập chỉ để '
          'đồng bộ ghi chú/cài đặt giữa nhiều thiết bị. Bạn tự chịu trách '
          'nhiệm giữ an toàn tài khoản Google của mình.'
      : 'Signing in with a Google account is **entirely optional** — you '
          'can use Flowrite fully without signing in. Signing in only syncs '
          'notes/settings across devices. You are responsible for keeping '
          'your own Google account secure.';

  static String dkMuc3TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Nội dung của bạn' : 'Your content';
  static String dkMuc3(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mọi ghi chú, văn bản bạn tạo ra trong Flowrite **thuộc về bạn**. '
          'Flowrite không đọc, không kiểm duyệt nội dung đó — bạn tự chịu '
          'trách nhiệm về những gì mình viết và lưu trong app.'
      : 'Every note and piece of text you create in Flowrite **belongs to '
          'you**. Flowrite does not read or moderate that content — you are '
          'solely responsible for what you write and store in the app.';

  static String dkMuc4TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tính năng AI' : 'AI features';
  static String dkMuc4(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Các tính năng gắn nhãn AI (kiểm tra chính tả, tóm tắt, viết lại, '
          'trò chuyện, đọc ảnh/âm thanh...) do một dịch vụ AI của Google xử '
          'lý. Kết quả AI trả về **chỉ là gợi ý** — ==có thể sai, có thể '
          'thiếu chính xác==, bạn luôn là người quyết định cuối cùng trước '
          'khi dùng kết quả đó.'
      : 'Features labeled AI (spell check, summarizing, rewriting, chat, '
          'reading photos/audio...) are processed by one of Google\'s AI '
          'services. The AI\'s output is **only a suggestion** — ==it can be '
          'wrong or inaccurate==, you always make the final call before '
          'using that result.';

  static String dkMuc5TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không đảm bảo tuyệt đối' : 'No absolute guarantee';
  static String dkMuc5(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Flowrite được cung cấp "nguyên trạng" (as-is). Chúng tôi cố gắng '
          'giữ app hoạt động ổn định, nhưng không đảm bảo app luôn chạy '
          'không lỗi, không gián đoạn, hay phù hợp tuyệt đối với mọi mục '
          'đích sử dụng của bạn.'
      : 'Flowrite is provided "as-is". We try to keep the app stable, but '
          'we do not guarantee it will always run error-free, uninterrupted, '
          'or perfectly suited to every purpose you may have for it.';

  static String dkMuc6TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hành vi không được phép' : 'Prohibited conduct';
  static String dkMuc6(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không dùng Flowrite để tạo/lưu/phát tán nội dung vi phạm pháp '
          'luật, hoặc để tấn công/can thiệp vào hệ thống của Flowrite và các '
          'dịch vụ mà app sử dụng (Google, Firebase...). Vi phạm có thể dẫn '
          'tới **khoá hoặc xoá tài khoản** liên quan.'
      : 'Do not use Flowrite to create/store/spread content that violates '
          'the law, or to attack/interfere with Flowrite\'s systems or the '
          'services it relies on (Google, Firebase...). Violations can lead '
          'to **suspending or deleting** the related account.';

  static String dkMuc7TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thay đổi điều khoản' : 'Changes to these terms';
  static String dkMuc7(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Điều khoản này có thể được cập nhật theo thời gian. Thay đổi đáng '
          'kể sẽ được thông báo ngay trong app. Bạn tiếp tục dùng Flowrite '
          'sau khi điều khoản cập nhật nghĩa là bạn đồng ý với bản mới.'
      : 'These terms may be updated over time. Significant changes will be '
          'announced right in the app. Continuing to use Flowrite after the '
          'terms are updated means you agree to the new version.';

  static String dkMuc8TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Giới hạn trách nhiệm' : 'Limitation of liability';
  static String dkMuc8(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Trong phạm vi pháp luật cho phép, Flowrite không chịu trách nhiệm '
          'cho thiệt hại gián tiếp phát sinh từ việc sử dụng hoặc không thể '
          'sử dụng app, bao gồm cả thiệt hại do dựa vào kết quả của tính '
          'năng AI.'
      : 'To the extent permitted by law, Flowrite is not liable for '
          'indirect damages arising from using or being unable to use the '
          'app, including damages from relying on AI feature results.';

  static String muc9TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Liên hệ' : 'Contact';
  static String muc9Dan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Có thắc mắc, góp ý, báo lỗi, vui lòng liên hệ qua một trong các '
          'cách sau:'
      : 'For questions, feedback, or bug reports, please reach out through '
          'one of the following:';

  static String lienHeEmail(NgonNgu nn) => nn == NgonNgu.vi
      ? '**Email:** lookatmevanthanhpham@gmail.com'
      : '**Email:** lookatmevanthanhpham@gmail.com';
  static String lienHeEmailKhac(NgonNgu nn) => nn == NgonNgu.vi
      ? '**Email khác:** 219thanhdeptrai@gmail.com'
      : '**Other email:** 219thanhdeptrai@gmail.com';
  static String lienHeDienThoai(NgonNgu nn) => nn == NgonNgu.vi
      ? '**Điện thoại:** +84 91 711 4941'
      : '**Phone:** +84 91 711 4941';

  // ------------------------------------------------- Bảo mật và quyền riêng tư

  static String baoMatTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bảo mật và quyền riêng tư' : 'Privacy and Security';

  static String baoMatTomTat(NgonNgu nn) => nn == NgonNgu.vi
      ? '**Tóm tắt nhanh:** Flowrite ==không có máy chủ riêng== thu thập dữ '
          'liệu của bạn. Dữ liệu chỉ có thể nằm ở MỘT trong ba nơi: **thiết '
          'bị của bạn**, **tài khoản Google** (nếu bạn chọn đăng nhập), hoặc '
          '**dịch vụ AI của Google** (chỉ khi bạn chủ động bấm dùng một tính '
          'năng AI).'
      : '**Quick summary:** Flowrite ==has no private server== collecting '
          'your data. Your data can only live in ONE of three places: '
          '**your device**, **your Google account** (if you choose to sign '
          'in), or **Google\'s AI service** (only when you actively tap to '
          'use an AI feature).';

  static String bmMuc1TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chưa đăng nhập' : 'Not signed in';
  static String bmMuc1(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Toàn bộ ghi chú, thư mục và cài đặt của bạn chỉ lưu **ngay trên '
          'thiết bị** (hoặc trình duyệt) đang dùng. Không nơi nào khác — kể '
          'cả người viết app — đọc được dữ liệu này.'
      : 'All your notes, folders, and settings are stored **only on the '
          'device** (or browser) you are using. No one else — not even the '
          'app\'s developer — can read this data.';

  static String bmMuc2TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Khi đăng nhập Google' : 'When signed in with Google';
  static String bmMuc2(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đăng nhập là **tuỳ chọn**, chỉ để đồng bộ dữ liệu giữa nhiều thiết '
          'bị cùng tài khoản, lưu trên hạ tầng Firebase của Google. Khi đó, '
          'những thứ sau được lưu THEO TÀI KHOẢN của bạn:'
      : 'Signing in is **optional**, only to sync data across devices under '
          'the same account, stored on Google\'s Firebase infrastructure. '
          'When you do, the following are saved UNDER YOUR ACCOUNT:';
  static String bmMuc2Dong1(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi chú và thư mục trong "Bộ nhớ trên đám mây".'
      : 'Notes and folders in "Cloud storage".';
  static String bmMuc2Dong2(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Một số cài đặt hiển thị (ghim/thu gọn thanh công cụ, Micro, tự '
          'động sửa, Bộ nhớ tạm, Khi khởi động App...).'
      : 'Some display settings (pin/collapse toolbar, Mic, auto-correct, '
          'Clipboard history, On app startup...).';
  static String bmMuc2Dong3(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hai từ điển cá nhân (sửa lỗi chính tả, nhập liệu nhanh).'
      : 'Your two personal dictionaries (spell-check, quick entry).';
  static String bmMuc2Sau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đăng xuất sẽ tự xoá bản sao lưu tạm (cache) của tài khoản đó khỏi '
          'thiết bị đang dùng.'
      : "Signing out automatically clears that account's temporary cache "
          'from the device you are using.';

  static String bmMuc3TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tính năng Micro' : 'Microphone feature';
  static String bmMuc3(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Giọng nói được chuyển thành chữ bằng bộ nhận diện giọng nói **của '
          'chính thiết bị/trình duyệt** bạn đang dùng (Android, Chrome...) — '
          'không đi qua máy chủ riêng nào của Flowrite.'
      : 'Your voice is turned into text by the speech-recognition engine '
          '**built into the device/browser** you are using (Android, '
          "Chrome...) — it never goes through any of Flowrite's own "
          'servers.';

  static String bmMuc4TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tính năng AI' : 'AI features';
  static String bmMuc4(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi bạn chủ động bấm dùng một tính năng AI (kiểm tra chính tả, '
          'tóm tắt, viết lại, trò chuyện, đọc ảnh/âm thanh...), đúng phần '
          'nội dung liên quan đến tính năng đó (không phải toàn bộ ghi chú) '
          'được gửi tới **dịch vụ AI của Google** để xử lý rồi trả kết quả '
          'về. ==Không bấm dùng tính năng AI thì không có gì được gửi đi==.'
      : 'When you actively tap to use an AI feature (spell check, '
          'summarizing, rewriting, chat, reading photos/audio...), only the '
          'content relevant to that feature (not your whole note) is sent '
          'to **Google\'s AI service** for processing, then the result is '
          'returned. ==If you never tap an AI feature, nothing is ever '
          'sent==.';

  static String bmMuc5TieuDe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Flowrite không làm gì với dữ liệu của bạn'
      : "What Flowrite never does with your data";
  static String bmMuc5Dong1(NgonNgu nn) => nn == NgonNgu.vi
      ? '**Không bán**, không cho thuê dữ liệu của bạn.'
      : '**Never sells** or rents out your data.';
  static String bmMuc5Dong2(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không chia sẻ dữ liệu cho bên thứ ba vì mục đích quảng cáo.'
      : 'Never shares your data with third parties for advertising.';
  static String bmMuc5Dong3(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không tự ý đọc nội dung ghi chú của bạn.'
      : "Never reads the content of your notes on its own.";

  static String bmMuc6TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Trẻ em' : 'Children';
  static String bmMuc6(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Flowrite không nhắm tới và không chủ đích thu thập dữ liệu của trẻ '
          'em dưới 13 tuổi.'
      : 'Flowrite is not directed at, and does not knowingly collect data '
          'from, children under 13.';

  static String bmMuc7TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Quyền của bạn' : 'Your rights';
  static String bmMuc7(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bạn có thể xoá ghi chú, đăng xuất, hoặc gỡ app bất cứ lúc nào. Xoá '
          'hẳn dữ liệu đã đồng bộ trên tài khoản Google.'
      : 'You can delete notes, sign out, or uninstall the app at any time. '
          'This permanently removes the data synced to your Google account.';

  static String bmMuc8TieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thay đổi chính sách' : 'Policy changes';
  static String bmMuc8(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chính sách này có thể được cập nhật theo thời gian. Thay đổi đáng '
          'kể sẽ được thông báo ngay trong app.'
      : 'This policy may be updated over time. Significant changes will be '
          'announced right in the app.';
}
