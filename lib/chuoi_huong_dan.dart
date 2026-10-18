// Nội dung dài của trang "Hướng dẫn" (`trang_huong_dan.dart`) theo đa ngôn
// ngữ — tách riêng khỏi `chuoi_da_ngon_ngu.dart` vì khối lượng lớn. Mỗi hàm
// nhận `NgonNgu nn`, trả về bản tiếng Việt hoặc tiếng Anh tương ứng.

import 'ngon_ngu.dart';

class ChHuongDan {
  ChHuongDan._();

  static String tieuDeTrang(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Hướng dẫn' : 'Guide';

  static String heroDongTrichDan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Nói ra ý tưởng, gõ tay sửa liền — không đợi, không xung đột, '
          'không mất mạch suy nghĩ.'
      : 'Speak your ideas, type to fix them on the fly — no waiting, no '
          'conflicts, no losing your train of thought.';

  static String hopMoDau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Nói và gõ tay, xưa nay luôn phải **chọn một**: bật giọng nói thì '
          'tắt bàn phím, ngồi gõ thì im giọng nói. Flowrite phá bỏ luật đó — '
          'bạn ==nói và gõ cùng lúc, không lẫn không đè lên nhau==, lại còn '
          'quản lý nhiều ghi chú, có AI hỗ trợ, đồng bộ mọi thiết bị.'
      : 'Voice and typing have always forced you to **pick one**: turn on '
          'dictation and the keyboard goes quiet, or type and stay silent. '
          'Flowrite breaks that rule — you ==speak and type at the same '
          'time, with no clashing or overwriting==, plus multi-note '
          'organization, built-in AI, and sync across every device.';

  static String mucI(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Nói và gõ tay cùng lúc' : 'Speak and type at the same time';

  static String mucII(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Quản lý nhiều ghi chú, chuyển tệp trong một nhịp'
      : 'Manage many notes, switch files in one beat';

  static String mucIII(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Gõ nhanh hơn với bộ nhớ tạm, từ điển gõ nhanh, sửa lỗi chính tả'
      : 'Type faster with the clipboard history, quick dictionary, spell-check';

  static String mucIV(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Trợ lý AI đi kèm' : 'A built-in AI assistant';

  static String mucV(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đồng bộ nhiều thiết bị' : 'Sync across devices';

  static String mucVI(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi nhanh ngay từ màn hình chính (Android)'
      : 'Quick notes from the home screen (Android)';

  static String mucVII(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bí quyết để nhanh hơn nữa' : 'Tips to go even faster';

  static String mucVIII(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Liên hệ' : 'Contact';

  static String chiDanhAndroid(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chỉ dành cho Android — iPhone/iPad sẽ nâng cấp sau'
      : 'Android only — iPhone/iPad support coming later';

  static String theDaTepTieuDe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Phần lớn app ghi chú khác chưa chú trọng điều này'
      : 'Most other note apps overlook this';

  static List<String> dacDiemDaTep(NgonNgu nn) => nn == NgonNgu.vi
      ? [
          'Chuyển qua ghi chú khác KHÔNG phải quay lại màn hình thư mục rồi bấm mở lại từng cái — chỉ một nút, ngay tại chỗ đang soạn.',
          'Hết tệp cuối tự vòng về tệp đầu (và ngược lại) — không bao giờ "kẹt ở biên".',
          'Tìm nhanh trong thư mục, và tuỳ chọn mở sẵn đúng ghi chú mỗi khi khởi động app.',
        ]
      : [
          'Switching to another note does NOT mean going back to the folder screen and reopening each one — just one button, right where you are.',
          'The last file wraps back to the first (and vice versa) — never "stuck at the edge".',
          'Quick search inside a folder, and an option to auto-open the right note on every startup.',
        ];

  static String theGoNhanhTieuDe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ba trợ thủ nhỏ, hiệu quả lớn'
      : 'Three small helpers, a big payoff';

  static List<String> dacDiemGoNhanh(NgonNgu nn) => nn == NgonNgu.vi
      ? [
          '**Bộ nhớ tạm để dán văn bản**: lưu lại 10 lần cắt/dán/copy gần nhất, ghim lại dòng nào muốn giữ lâu — dán lại y nguyên bất cứ lúc nào, khỏi gõ lại.',
          '**Từ điển nhập liệu nhanh**: một bảng 26 dòng chứa sẵn các đoạn hay dùng, chạm một lần là dán thẳng vào bài — nhanh hơn hẳn gõ tay cho những câu lặp đi lặp lại.',
          '**Từ điển sửa lỗi chính tả**: tự động dò và gợi ý sửa lỗi gõ sai quen tay, giữ văn bản sạch mà không phải dừng lại đọc rà soát.',
        ]
      : [
          '**Clipboard history**: keeps your last 10 cut/copy/paste actions, pin any line to keep it longer — paste it back exactly any time, no retyping.',
          '**Quick-entry dictionary**: a 26-row table of your frequent snippets, one tap pastes it straight into the text — much faster than typing repeated phrases by hand.',
          '**Spelling dictionary**: automatically spots and suggests fixes for your usual typos, keeping the text clean without stopping to proofread.',
        ];

  static String theAiTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Không cần rời khỏi app' : "You never leave the app";

  static List<String> dacDiemAi(NgonNgu nn) => nn == NgonNgu.vi
      ? [
          'Kiểm tra chính tả, tóm tắt, viết lại cả bài hoặc một đoạn đang chọn.',
          'Trò chuyện hỏi đáp ngay trong app để brainstorm hoặc hỏi về nội dung bài viết.',
          'Đọc ảnh chụp hoặc file âm thanh, tự động chuyển thành văn bản.',
        ]
      : [
          'Check spelling, summarize, or rewrite the whole text or just a selected paragraph.',
          'Chat right inside the app to brainstorm or ask about your writing.',
          'Read a photo or an audio file and turn it into text automatically.',
        ];

  static String oGoiYBanPhimTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn đúng bàn phím' : 'Pick the right keyboard';

  static String oGoiYBoGoTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chọn đúng bộ gõ' : 'Pick the right input method';

  static String oGoiYMuoiNgonTieuDe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Học gõ mười ngón, không nhìn phím'
      : 'Learn 10-finger touch typing';

  static String oGoiYMicroRoiTieuDe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Dùng micro rời — nghe rõ hơn hẳn'
      : 'Use an external mic — far clearer';

  static String doan1(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Phần lớn app ghi âm chuyển chữ buộc bạn chọn MỘT trong hai: hoặc '
          '**nói**, hoặc **gõ**. Flowrite để cả hai diễn ra ĐAN XEN tự nhiên — '
          'nói một câu dài, rồi đưa tay gõ chèn ngay một từ, một con số — '
          'không cần tắt micro, không lo giọng nói và ký tự gõ tay ==đá nhau '
          'làm hỏng câu==.'
      : 'Most speech-to-text apps force you to pick ONE of the two: either '
          '**speak**, or **type**. Flowrite lets both happen naturally '
          'INTERLEAVED — say a long sentence, then reach over and type in a '
          'word or a number right away — no need to turn off the mic, no '
          'worry about voice and typed characters ==clashing and breaking the '
          'sentence==.';

  static String doan2(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi chú được tổ chức theo **thư mục lồng nhau** như một cây thư mục '
          'thật — không phải một danh sách dài vô tổ chức. Và khi đang soạn một '
          'tệp, bạn chuyển ngay sang tệp kế tiếp trong cùng thư mục bằng nút '
          '**"Tệp trước/Tệp sau"** ngay tại màn hình soạn thảo.'
      : 'Notes are organized into **nested folders**, like a real folder '
          'tree — not one long, disorganized list. And while editing a file, '
          'you can jump straight to the next file in the same folder with '
          'the **"Previous file/Next file"** button right on the editing '
          'screen.';

  static String doan3b(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Những đoạn gõ lặp lại — chữ ký, lời chào, cụm từ hay dùng — không '
          'cần gõ lại từ đầu mỗi lần. Và những lỗi chính tả nhỏ không cần tự '
          'soi từng chữ để sửa.'
      : "Repeated bits of text — signatures, greetings, frequent phrases — "
          "don't need retyping every time. And small typos don't need you "
          'to scan every word to fix them.';

  static String doan3(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không cần rời Flowrite để dùng AI — mọi tính năng AI nằm sẵn trong '
          'thanh công cụ, xử lý ngay trên văn bản đang soạn.'
      : "You don't need to leave Flowrite to use AI — every AI feature "
          'lives right in the toolbar, working directly on the text you are '
          'editing.';

  static String doan4(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đăng nhập tài khoản Google (**hoàn toàn tuỳ chọn**) để mở đúng ghi '
          'chú đó ở một thiết bị khác — điện thoại, máy tính, trình duyệt nào '
          'cũng thấy cùng một dữ liệu.'
      : 'Sign in with a Google account (**entirely optional**) to open that '
          'same note on another device — phone, computer, any browser sees '
          'the exact same data.';

  static String doan5Widget(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Đặt một **tiện ích (widget) Flowrite** ngay ngoài màn hình chính '
          'điện thoại/máy tính bảng Android — ghi một ý nhanh mà ==không cần '
          'mở app==.'
      : 'Place a **Flowrite widget** right on your Android phone/tablet '
          'home screen — jot down a quick thought ==without opening the '
          'app==.';

  static List<String> cacBuocCaiWidget(NgonNgu nn) => nn == NgonNgu.vi
      ? [
          'Chạm giữ (long-press) một khoảng trống ở màn hình chính thiết bị.',
          'Chọn mục "Widgets" (Tiện ích) trong menu hiện ra.',
          'Tìm "Flowrite" trong danh sách, kéo thả ra màn hình chính.',
          'Chọn MỘT ghi chú để tiện ích ghi vào — chỉ hỏi đúng một lần lúc vừa đặt.',
          'Xong! Chạm nút "Ghi nhanh" trên tiện ích bất cứ lúc nào để gõ liền, không cần mở app. Nút "Mở app" bên cạnh mở Flowrite bình thường.',
        ]
      : [
          'Long-press an empty spot on your device home screen.',
          'Choose "Widgets" from the menu that appears.',
          'Find "Flowrite" in the list and drag it onto the home screen.',
          'Pick ONE note for the widget to write into — asked only once, right when you place it.',
          'Done! Tap the "Quick note" button on the widget any time to type right away, no need to open the app. The "Open app" button next to it opens Flowrite normally.',
        ];

  static String doan8(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bản thân ứng dụng chỉ là một nửa câu chuyện — nửa còn lại nằm ở '
          'chính thói quen của bạn. Vài điều chỉnh nhỏ dưới đây có thể nhân '
          'đôi, nhân ba hiệu quả của việc kết hợp nói và gõ:'
      : "The app itself is only half the story — the other half is your own "
          'habits. A few small adjustments below can double or triple how '
          'effective combining voice and typing becomes:';

  static String oGoiYBanPhim(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bàn phím ảo trên màn hình cảm ứng chỉ để dùng tạm — gõ chậm hơn, dễ '
          'gõ nhầm, và không có phản hồi lực bấm để ngón tay "nhớ vị trí '
          'phím". Nếu soạn thảo nhiều, hãy **gắn thêm một bàn phím rời** cho '
          'điện thoại/máy tính bảng qua Bluetooth. Có điều kiện hơn thì bàn '
          'phím cơ (cơ khí) cho cảm giác gõ rõ ràng, độ nảy tốt, giúp gõ '
          'nhanh và chính xác hơn hẳn so với bàn phím màng thông thường.'
      : 'The on-screen touch keyboard is only for occasional use — slower '
          'to type on, easier to mistype, and with no tactile feedback for '
          'your fingers to "remember" key positions. If you write a lot, '
          '**add an external keyboard** to your phone/tablet over Bluetooth. '
          'If you can, a mechanical keyboard gives a clearer, bouncier feel '
          'that helps you type faster and more accurately than a regular '
          'membrane keyboard.';

  static String oGoiYBoGo(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hãy chắc chắn bạn đang dùng đúng bộ gõ cho ngôn ngữ mình viết — với '
          'tiếng Việt là các kiểu gõ **Telex** hoặc **VNI** quen thuộc. Một '
          'bộ gõ phù hợp, được thiết lập đúng, giúp gõ dấu nhanh và chính xác '
          'hơn nhiều so với việc gõ chữ có dấu theo kiểu thủ công từng ký '
          'tự.'
      : 'Make sure you are using the right input method for the language '
          'you write in — for Vietnamese that means the familiar **Telex** '
          'or **VNI** typing styles. A properly set-up input method types '
          'diacritics far faster and more accurately than typing accented '
          'characters manually one by one.';

  static String oGoiYMuoiNgon(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Kỹ năng có ảnh hưởng lớn nhất tới tốc độ gõ tay chính là **gõ mười '
          'ngón mà không cần nhìn xuống bàn phím**. Người mới tập thường chỉ '
          'gõ bằng vài ngón và phải liên tục liếc bàn phím, vừa chậm vừa dễ '
          'sai. Có rất nhiều trang web luyện gõ mười ngón miễn phí và trực '
          'quan — chỉ cần tìm "luyện gõ mười ngón" hoặc "typing practice" là '
          'ra hàng loạt lựa chọn để luyện tập mỗi ngày vài phút. Kiên trì một '
          'thời gian ngắn, tốc độ gõ của bạn có thể tăng gấp đôi, gấp ba so '
          'với gõ theo bản năng.'
      : 'The single skill with the biggest impact on typing speed is '
          '**touch typing with all ten fingers, without looking down at the '
          'keyboard**. Beginners usually type with just a few fingers and '
          'keep glancing at the keys, which is both slow and error-prone. '
          'There are many free, intuitive touch-typing websites — just '
          'search "touch typing practice" to find plenty of options for a '
          'few minutes of daily practice. Stick with it for a short while '
          'and your typing speed can double or triple compared to typing '
          'instinctively.';

  static String oGoiYMicroRoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Micro của điện thoại thường nằm ở cạnh dưới máy — càng xa miệng, '
          'máy càng khó nghe rõ, càng dễ nhận nhầm chữ. Một chiếc **micro '
          'rời** (micro cài áo, tai nghe có micro) đặt gần miệng hơn hẳn, '
          'giúp bộ nhận dạng nghe chuẩn hơn thấy rõ.\n\n'
          'Vài mẹo nhỏ giúp giọng nói tới máy sạch nhất: luôn để micro **sát '
          'miệng**, ưu tiên loại có ==bộ lọc chống ồn== nếu có điều kiện, và '
          'cố gắng thu âm ở nơi yên tĩnh. Ở chỗ ồn mà không có micro rời, một '
          'mẹo đơn giản là lấy tay khum lại che quanh miệng và micro của '
          'máy — vừa chắn bớt tiếng ồn xung quanh, vừa hướng giọng nói thẳng '
          'vào micro.'
      : "A phone's built-in mic usually sits at the bottom edge — the "
          'farther from your mouth, the harder it is for the device to hear '
          'clearly, and the more likely it is to mis-recognize words. An '
          '**external mic** (lapel mic, headset mic) sits much closer to '
          'your mouth, helping recognition noticeably.\n\n'
          "A few tips to keep your voice reaching the device cleanly: keep "
          'the mic **close to your mouth**, prefer one with ==noise '
          'filtering== if you can, and try to record in a quiet place. In a '
          'noisy spot without an external mic, a simple trick is to cup '
          'your hand around your mouth and the phone mic — it both blocks '
          'some ambient noise and directs your voice straight at the mic.';

  static String lienHe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Có thắc mắc, góp ý, báo lỗi, vui lòng liên hệ qua một trong các '
          'cách sau:\n\n'
          '**Email:** lookatmevanthanhpham@gmail.com\n'
          '**Email khác:** 219thanhdeptrai@gmail.com\n'
          '**Điện thoại:** +84 91 711 4941'
      : 'For questions, feedback, or bug reports, please reach out through '
          'one of the following:\n\n'
          '**Email:** lookatmevanthanhpham@gmail.com\n'
          '**Other email:** 219thanhdeptrai@gmail.com\n'
          '**Phone:** +84 91 711 4941';

  static String trichDanLon(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Nói nhanh, gõ chính xác, chuyển tệp tức khắc, có AI hỗ trợ, và mở '
          'đúng ghi chú ở bất kỳ thiết bị nào — đó là Flowrite.'
      : 'Speak fast, type precisely, switch files instantly, with AI '
          'support, and open the right note on any device — that is '
          'Flowrite.';

  static String trichDanNho(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Flowrite không thay bạn viết — nó chỉ dọn đường để ý tưởng của bạn '
          'ra tới trang giấy nhanh nhất có thể.'
      : "Flowrite doesn't write for you — it just clears the way so your "
          'ideas reach the page as fast as possible.';
}
