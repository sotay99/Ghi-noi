// Chuỗi đa ngôn ngữ cho màn Cài đặt (`man_hinh_cai_dat.dart`) — tách riêng
// khỏi `chuoi_da_ngon_ngu.dart` vì màn này có nhiều đoạn giải thích dài.
// Pattern giống `Ch`/`ChHuongDan`/`ChPhapLy`: mỗi hàm nhận `NgonNgu`, trả
// chuỗi tương ứng — thêm ngôn ngữ mới chỉ cần thêm 1 nhánh.

import 'ngon_ngu.dart';

class ChCaiDat {
  // --------------------------------------------------------------- Tiêu đề
  static String caiDatMicro(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cài đặt Micro' : 'Microphone Settings';

  static String caiDatHienThiVaTuDongSua(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Cài đặt Hiển thị và tự động sửa'
      : 'Display & Auto-correct Settings';

  static String dong(NgonNgu nn) => nn == NgonNgu.vi ? 'Đóng' : 'Close';

  static String giaiThichNganTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'GIẢI THÍCH NGẮN GỌN' : 'SHORT EXPLANATION';

  static String giaiThichChiTietTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'GIẢI THÍCH CHI TIẾT HƠN' : 'DETAILED EXPLANATION';

  static String timHieuThem(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tìm hiểu thêm' : 'Learn more';

  static String dangBatCo(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đang bật (Có)' : 'On (Yes)';

  static String dangTatKhong(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đang tắt (Không)' : 'Off (No)';

  static String giay(NgonNgu nn) => nn == NgonNgu.vi ? 'giây' : 'seconds';

  static String khongTuBatLaiMicro(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Không tự động bật lại Micro'
      : 'Never automatically turn Mic back on';

  // --------------------------------------------------------- Dòng 0 (thiết bị web)
  static String neuMicroTrucTrac(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Nếu Micro bị trục trặc, hãy '
      : 'If the Mic is misbehaving, ';

  static String bamVaoDay(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bấm vào đây' : 'tap here';

  static String chonThietBiTieuDe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chọn thiết bị - Micro (vừa nói vừa ra chữ) sẽ hoạt động '
          'ổn định với Đúng thiết bị đang chọn'
      : 'Choose a device - Mic (speak while typing) works most '
          'reliably when the Correct device is selected';

  static String tuDongNhanDienMacDinh(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tự động nhận diện (mặc định)'
      : 'Auto-detect (default)';

  static String moTaTuDongNhanDien(NgonNgu nn, String tenThietBi) =>
      nn == NgonNgu.vi
          ? 'Để app tự đoán qua trình duyệt — kết quả hiện tại: $tenThietBi.'
          : 'Let the app guess via the browser — current result: $tenThietBi.';

  // -------------------------------------------------------- Dòng 1/2 (thời gian)
  static String thoiGianBatLaiMicro(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thời gian bật lại micro sau khi gõ tay xong'
      : 'Time before Mic turns back on after typing';

  static String khiKhongNoiTuDongTat(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi không nói, tự động tắt Micro sau:'
      : 'When silent, automatically turn off Mic after:';

  static String tuDongTatMicroKhiKhongNoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tự động tắt Micro khi không nói'
      : 'Automatically turn off Mic when silent';

  static String thoiGianBatLaiMicroTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Thời gian bật lại micro' : 'Mic resume delay';

  // ------------------------------------------------------ Dòng cài đặt switch
  static String tuDongChenDauCachSauKhiNoi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tự động chèn dấu cách sau mỗi lần nói'
      : 'Automatically insert a space after each spoken segment';

  static String tuDongChenDauCachTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tự động chèn dấu cách' : 'Auto-insert space';

  static String tuDongKiemTraChinhTaVaDeXuatAI(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tự động kiểm tra chính tả và đề xuất sửa bằng AI'
      : 'Automatically check spelling and suggest AI fixes';

  static String kiemTraChinhTaBangAITieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm tra chính tả bằng AI' : 'AI spell check';

  static String tuDongChenDauCauVaoGiuaDoanVanAI(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tự động chèn dấu câu vào giữa các đoạn văn bằng AI'
      : 'Automatically insert punctuation within paragraphs using AI';

  static String tuDongChenDauCauBangAITieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tự động chèn dấu câu bằng AI' : 'AI auto-punctuation';

  static String tuDongThemDauChamTruocXuongDong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tự động thêm dấu chấm trước khi xuống dòng'
      : 'Automatically add a period before a new line';

  static String tuDongThemDauChamTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tự động thêm dấu chấm' : 'Auto-add period';

  static String tuDongThutDauDongKhiXuongDong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tự động thụt đầu dòng khi xuống dòng'
      : 'Automatically indent new lines';

  static String soDauCachChenVao(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Số dấu cách chèn vào: ' : 'Number of spaces: ';

  static String dauCachSoLuong(NgonNgu nn, int n) =>
      nn == NgonNgu.vi ? '$n dấu cách' : '$n space${n == 1 ? '' : 's'}';

  static String tuDongThutDauDongTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tự động thụt đầu dòng' : 'Auto-indent';

  static String tuDongThemDuongKeChiaKhiXuongDong2Lan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Tự động thêm đường kẻ chia đoạn văn khi xuống dòng 2 lần'
      : 'Automatically add a paragraph divider on a double line break';

  static String mauDuongKe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Màu đường kẻ: ' : 'Line color: ';

  static String chonMauDuongKeChiaDoanVan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chọn màu đường kẻ chia đoạn văn'
      : 'Choose paragraph divider color';

  static String doRo(NgonNgu nn) => nn == NgonNgu.vi ? 'Độ rõ: ' : 'Opacity: ';

  static String duongKeChiaDoanVanTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đường kẻ chia đoạn văn' : 'Paragraph divider';

  static String chamTronDanhDauCuoiVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chấm tròn đánh dấu cuối văn bản'
      : 'Dot marking the end of the text';

  static String mauChamTron(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Màu chấm tròn: ' : 'Dot color: ';

  static String chonMauChamTronCuoiVanBan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chọn màu chấm tròn cuối văn bản'
      : 'Choose end-of-text dot color';

  static String tuDongVietHoaDauCauTieuDe(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Tự động viết Hoa ở đầu câu' : 'Auto-capitalize sentences';

  static String chuanHoaCacCapDauDongMoNgoac(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chuẩn hoá các cặp dấu đóng-mở ngoặc'
      : 'Normalize opening/closing bracket pairs';

  // ------------------------------------------------------------- Phím tắt
  static String phimTatChoMicro(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Phím tắt cho Micro (vừa nói vừa ra chữ)'
      : 'Shortcut for Mic (speak while typing)';

  static String phimTatChoGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Phím tắt cho Ghi âm (Ghi âm xong mới ra chữ — tạo thẻ ghi âm)'
      : 'Shortcut for Recording (transcribe after recording — creates a recording card)';

  static String chiCoTacDungBanPhimVatLy(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Chỉ có tác dụng khi thiết bị gắn bàn phím vật lý (kể cả bàn phím '
          'rời cắm vào máy tính bảng).'
      : 'Only applies when a physical keyboard is attached (including an '
          'external keyboard plugged into a tablet).';

  static String nhanMotPhim(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Nhấn một phím' : 'Press a key';

  static String hayNhanMotPhimBatKy(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hãy nhấn một phím bất kỳ trên bàn phím...'
      : 'Press any key on your keyboard...';

  static String huy(NgonNgu nn) => nn == NgonNgu.vi ? 'Huỷ' : 'Cancel';

  static String luu(NgonNgu nn) => nn == NgonNgu.vi ? 'Lưu' : 'Save';

  static String tenChucNangMicro(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Micro (vừa nói vừa ra chữ)'
      : 'Mic (speak while typing)';

  static String tenChucNangGhiAm(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ghi âm (Ghi âm xong mới ra chữ)'
      : 'Recording (transcribe after recording)';

  static String phimTatCho(NgonNgu nn, String tenChucNang) => nn == NgonNgu.vi
      ? 'Phím tắt cho $tenChucNang'
      : 'Shortcut for $tenChucNang';

  static String phimTab(NgonNgu nn) => nn == NgonNgu.vi ? 'Tab' : 'Tab';

  static String giaiThichTab(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Phím Tab — hình mũi tên hai chiều (⇥). Nằm ở góc trên bên trái bàn '
          'phím, ngay phía trên phím Caps Lock, bên trái chữ Q.'
      : 'The Tab key — the two-way arrow icon (⇥). Located at the top-left '
          'of the keyboard, just above Caps Lock, left of the Q key.';

  static String ctrlVaPhimKhac(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Ctrl + ...' : 'Ctrl + ...';

  static String giaiThichCtrl(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Giữ phím Ctrl (góc dưới cùng bên trái bàn phím) rồi bấm thêm một '
          'phím khác — ví dụ Ctrl + G.'
      : 'Hold Ctrl (bottom-left corner of the keyboard) and press another '
          'key — for example Ctrl + G.';

  static String bamCtrl2LanLienTiep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bấm Ctrl 2 lần liên tiếp' : 'Press Ctrl twice in a row';

  static String giaiThichCtrlDup(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm phím Ctrl rồi BUÔNG RA NGAY (không giữ), sau đó bấm Ctrl thêm '
          'một lần nữa trong vòng 1 giây — giống bấm đúp chuột nhưng bằng '
          'phím Ctrl.'
      : 'Press Ctrl and RELEASE immediately (don\'t hold), then press Ctrl '
          'again within 1 second — like a double-click but with the Ctrl key.';

  static String bamShift2LanLienTiep(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bấm Shift 2 lần liên tiếp' : 'Press Shift twice in a row';

  static String giaiThichShiftDup(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm phím Shift rồi buông ra ngay, bấm Shift thêm một lần nữa trong '
          'vòng 1 giây. Lưu ý: nếu gõ chữ hoa rất nhanh, đôi khi có thể vô '
          'tình kích hoạt.'
      : 'Press Shift and release immediately, then press Shift again within '
          '1 second. Note: typing capital letters very quickly may '
          'accidentally trigger this.';

  static String bamDeChonPhim(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bấm để chọn phím' : 'Tap to choose a key';

  static String hayBamChonMotPhimTruocKhiLuu(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Hãy bấm chọn một phím trước khi lưu.'
      : 'Please choose a key before saving.';

  static String phimTatDangTrungVoiChucNang(
          NgonNgu nn, String tenChucNangKia, String nhan) =>
      nn == NgonNgu.vi
          ? 'Phím tắt này đang trùng với chức năng "$tenChucNangKia" '
              '($nhan) — chọn phím khác nhé.'
          : 'This shortcut already matches "$tenChucNangKia" '
              '($nhan) — please choose a different key.';

  static String boNhoTamDeDanVanBan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Bộ nhớ tạm để dán văn bản' : 'Clipboard for pasting text';

  static String daChonPhimChoChucNang(
          NgonNgu nn, String phim1, String chucNang1, String phim2, String chucNang2) =>
      nn == NgonNgu.vi
          ? 'Đã chọn phím $phim1 cho chức năng $chucNang1\n'
              'Đã chọn phím $phim2 cho chức năng $chucNang2'
          : 'Set $phim1 for $chucNang1\n'
              'Set $phim2 for $chucNang2';

  // -------------------------------------------------------- Quyền micro (dòng 6)
  static String dangKiemTra(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đang kiểm tra…' : 'Checking…';

  static String daCapQuyenMicro(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Đã cấp quyền micro' : 'Microphone permission granted';

  static String moTaDaCapQuyen(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ứng dụng dùng được micro để nghe và ghi lại giọng nói.'
      : 'The app can use the microphone to listen and record speech.';

  static String quyenMicroDaBiChan(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Quyền micro đã bị chặn' : 'Microphone permission blocked';

  static String moTaQuyenBiChanVinhVien(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Có thể do trước đây bạn từng từ chối và chọn "Không hỏi lại", '
          'hoặc có ai đó (kể cả chính bạn) vào Cài đặt máy rồi tắt quyền này '
          'đi. Ứng dụng không thể tự hỏi lại nữa — bấm nút bên dưới để mở '
          'màn hình cài đặt riêng của Flowrite, rồi tự bật mục "Micro" lên.'
      : 'This can happen if you previously denied access and chose "Don\'t '
          'ask again", or someone (including you) turned it off in device '
          'Settings. The app can no longer ask again automatically — tap '
          'the button below to open Flowrite\'s own settings screen and '
          'turn on "Microphone" yourself.';

  static String moCaiDatUngDung(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Mở cài đặt ứng dụng' : 'Open app settings';

  static String quyenMicroBiChanBoiThietBi(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Quyền micro bị chặn bởi thiết bị'
      : 'Microphone permission blocked by device policy';

  static String moTaQuyenBiHanChe(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Thiết bị này đang bị quản lý bởi một chính sách nào đó (ví dụ '
          'máy của cơ quan, trường học) và chặn hẳn quyền micro. Liên hệ '
          'người quản lý thiết bị để được mở.'
      : 'This device is managed by some policy (e.g. a work or school '
          'device) that blocks microphone access entirely. Contact your '
          'device administrator to have it unblocked.';

  static String chuaCapQuyenMicro(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Chưa cấp quyền micro' : 'Microphone permission not granted';

  static String moTaChuaCapQuyen(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Ứng dụng cần quyền ghi âm của máy mới nghe được giọng nói. '
          'Bấm nút bên dưới để cấp quyền.'
      : 'The app needs recording permission to hear your voice. Tap the '
          'button below to grant it.';

  static String capQuyenMicro(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Cấp quyền micro' : 'Grant microphone permission';

  static String quyenDungMicroCuaThietBi(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Quyền dùng micro của thiết bị' : 'Device microphone permission';

  static String kiemTraLai(NgonNgu nn) =>
      nn == NgonNgu.vi ? 'Kiểm tra lại' : 'Check again';

  // ----------------------------------------------------------- Giải thích dài
  static String giaiThichTuTatMicroNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Micro đang bật mà quá lâu không có thêm chữ nào (nói hay gõ tay đều '
          'tính) thì tự tắt hẳn, đỡ hao pin. Chỉnh từ **10 đến 120 giây**.'
      : 'If the Mic stays on with no new text (speaking or typing both '
          'count) for too long, it turns itself off to save battery. '
          'Adjustable from **10 to 120 seconds**.';

  static String giaiThichTuTatMicro(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Micro bật mãi mà không dùng tới rất tốn pin. Cài đặt này quy định: '
          'nếu micro đang bật mà im lặng liên tục — không có chữ nào mới '
          'xuất hiện trong bài, dù do nói hay do bạn tự gõ tay — quá số '
          'giây đặt ở đây, ứng dụng sẽ tự tắt hẳn micro. Muốn nghe lại thì '
          'tự bấm nút micro hoặc phím tắt, ứng dụng không tự bật lại.'
      : 'Leaving the Mic on without use drains battery quickly. This '
          'setting says: if the Mic is on but stays silent — no new text '
          'appears in the document, whether by speech or typing — for '
          'longer than the number of seconds set here, the app turns the '
          'Mic off completely. To listen again, tap the Mic button or use '
          'the shortcut — the app will not turn it back on by itself.';

  static String giaiThichThoiGianNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi bạn gõ phím, ứng dụng **tắt hẳn micro** một lúc để khỏi nghe '
          'nhầm tiếng gõ phím thành lời nói. Cài đặt này là **thời gian '
          'chờ** sau khi bạn ngừng gõ, trước khi micro tự bật lại. Để '
          '**ngắn** thì nói tiếp nhanh hơn nhưng dễ bắt nhầm âm thanh lúc '
          'bạn còn đang lơ đãng; để **dài** thì an toàn hơn nhưng phải chờ '
          'lâu hơn. Mặc định **1 giây** là hợp lý cho hầu hết mọi người. '
          'Chọn **"Không tự động bật lại Micro"** nếu bạn muốn hoàn toàn tự '
          'bấm nút micro mỗi lần muốn nói tiếp, không để ứng dụng tự quyết '
          'định thời điểm.'
      : 'When you type, the app **turns the Mic off** for a moment so it '
          'doesn\'t mistake keystroke sounds for speech. This setting is '
          'the **delay** after you stop typing before the Mic turns back '
          'on. **Shorter** means you can resume speaking sooner but may '
          'pick up stray sounds while you\'re still distracted; **longer** '
          'is safer but means more waiting. The default **1 second** works '
          'well for most people. Choose **"Never automatically turn Mic '
          'back on"** if you want to always tap the Mic button yourself '
          'whenever you want to keep speaking, instead of letting the app '
          'decide.';

  static String giaiThichThoiGian(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi tay bạn chạm bàn phím để gõ thêm chữ, ứng dụng **tắt hẳn '
          'micro** ngay lập tức, để tiếng gõ phím hay tiếng lẩm bẩm lúc '
          'nghĩ chữ không bị nghe nhầm thành lời nói. Cài đặt này quyết '
          'định ứng dụng chờ bao lâu, kể từ lúc bạn **ngừng gõ**, rồi mới '
          'tự bật micro nghe lại.\n\n'
          'Chọn **ngắn** thì nói tiếp được gần như ngay, nhưng nếu bạn hay '
          'gõ ngắt quãng (gõ một chữ, dừng tay suy nghĩ, gõ tiếp), micro có '
          'thể bật sớm và nghe nhầm tiếng lẩm bẩm hay tiếng ồn xung quanh '
          'thành chữ chen ngang. Chọn **dài** thì an toàn hơn nhưng phải '
          'chờ lâu hơn mới nói tiếp được.\n\n'
          'Mặc định **1 giây** là mức vừa phải, hợp với cách gõ của phần '
          'lớn mọi người.'
      : 'As soon as your hand touches the keyboard to type, the app '
          '**turns the Mic off** immediately so keystroke sounds or '
          'mumbling while thinking aren\'t mistaken for speech. This '
          'setting decides how long the app waits, counting from when you '
          '**stop typing**, before turning the Mic back on.\n\n'
          'A **shorter** delay lets you resume speaking almost instantly, '
          'but if you type in bursts (type a word, pause to think, type '
          'again), the Mic may turn on too soon and pick up mumbling or '
          'background noise as stray words. A **longer** delay is safer '
          'but means waiting longer before you can speak again.\n\n'
          'The default **1 second** is a reasonable middle ground for most '
          'typing styles.';

  static String giaiThichChenCachNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mỗi lần bạn nói xong một đoạn, ứng dụng tự thêm một **dấu cách** '
          'vào ngay sau đoạn đó, để chữ gõ tay tiếp theo (nếu có) không bị '
          'dính liền vào cuối câu vừa nói. Tắt đi thì để nguyên như bộ '
          'nhận dạng giọng nói trả về, không tự chèn gì thêm.'
      : 'Each time you finish speaking a segment, the app automatically '
          'adds a **space** right after it, so any text you type next '
          'doesn\'t run into the end of what you just said. Turn this off '
          'to keep exactly what the speech recognizer returns, with '
          'nothing auto-inserted.';

  static String giaiThichChenCach(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bộ nhận dạng giọng nói không phải lúc nào cũng tự thêm dấu cách '
          'vào cuối câu — có lúc dừng lại đúng ngay sau chữ cuối, không có '
          'khoảng trắng theo sau. Nếu ngay đó bạn gõ tay tiếp hoặc nói '
          'tiếp, chữ mới sẽ bị **dính liền** vào chữ vừa nói. Ví dụ: nói '
          'ra "Thành đẹp trai ./.", rồi gõ tay tiếp "abc" — không có tính '
          'năng này sẽ dính thành "./.abc".\n\n'
          'Bật tính năng này (mặc định **bật**), mỗi khi nói xong một '
          'đoạn, ứng dụng tự chèn một dấu cách vào cuối đoạn đó để chữ '
          'tiếp theo không bị dính. Tắt đi thì để nguyên như bộ nhận dạng '
          'trả về, không tự chèn gì thêm.\n\n'
          'Chỉ áp dụng ở cuối mỗi đoạn NÓI — gõ tay ở bất kỳ đâu trong bài '
          'luôn dính liền bình thường như một trang soạn thảo thường, '
          'không có gì tự động chèn thêm.'
      : 'The speech recognizer doesn\'t always add a trailing space — '
          'sometimes it stops right after the last word with nothing '
          'following. If you then type or speak again immediately, the '
          'new text will **run together** with what you just said. For '
          'example: say "hello world", then type "abc" right after — '
          'without this feature it becomes "worldabc".\n\n'
          'With this feature on (**on** by default), whenever you finish '
          'speaking a segment, the app inserts a space at the end so the '
          'next text doesn\'t run together. Turn it off to keep exactly '
          'what the recognizer returns, with nothing auto-inserted.\n\n'
          'This only applies at the end of a SPOKEN segment — typing '
          'anywhere else in the document behaves like a normal text '
          'editor, with nothing auto-inserted.';

  static String giaiThichChinhTaNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bật lên, mỗi khi bạn viết xong một đoạn mới (nói hoặc gõ), ứng '
          'dụng gửi ĐÚNG đoạn mới đó cho AI kiểm tra chính tả. Từ nào sai '
          'sẽ được **gạch đỏ chân** — bấm vào từ đó để xem AI đề xuất từ '
          'thay thế.'
      : 'When on, each time you finish a new segment (speaking or typing), '
          'the app sends EXACTLY that new segment to AI for spell '
          'checking. Misspelled words get a **red underline** — tap a '
          'word to see the AI\'s suggested replacement.';

  static String giaiThichChinhTa(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi tính năng này bật, mỗi lần bạn viết xong một đoạn văn mới (dù '
          'bằng giọng nói hay gõ tay), ứng dụng sẽ gửi đoạn văn đó lên máy '
          'chủ AI để kiểm tra chính tả. Chỉ đoạn văn **CHƯA từng được '
          'kiểm tra** mới được gửi đi — đoạn nào AI đã đọc qua rồi sẽ '
          'không gửi lại, để đỡ tốn dữ liệu và hạn mức AI.\n\n'
          'Từ nào AI cho là sai chính tả sẽ được **gạch chân màu đỏ** '
          'ngay trong bài. Bấm vào đúng từ đó, một menu nhỏ hiện ra:\n\n'
          '- Các dòng đầu là những từ **AI đề xuất thay thế** — bấm vào '
          'từ nào thì từ đó lập tức đè lên từ sai.\n'
          '- Dòng **"Xoá"** (màu đỏ) — xoá hẳn từ sai đó khỏi bài, không '
          'thay bằng gì cả. Đây không phải do AI đề xuất, mà là một lựa '
          'chọn có sẵn của ứng dụng cho mọi từ bị gạch đỏ.\n'
          '- Dòng **"Huỷ đề xuất"** (màu xanh lá) — bấm vào thì không có '
          'gì đổi trong bài, chỉ là ứng dụng thôi coi từ đó là sai nữa '
          '(hết gạch đỏ chân).\n\n'
          'Tắt tính năng này đi thì mọi gạch đỏ đang hiện biến mất ngay, '
          'và ứng dụng ngừng gọi AI kiểm tra chính tả cho tới khi bạn bật '
          'lại.'
      : 'When this feature is on, each time you finish writing a new '
          'paragraph (by voice or by typing), the app sends that paragraph '
          'to the AI server for spell checking. Only paragraphs that have '
          '**never been checked before** are sent — one the AI has already '
          'read is not sent again, saving data and AI quota.\n\n'
          'A word the AI flags as misspelled gets a **red underline** '
          'right in the document. Tap that word and a small menu appears:\n\n'
          '- The top rows are **AI-suggested replacements** — tap one and '
          'it instantly replaces the misspelled word.\n'
          '- A **"Delete"** row (in red) — removes the misspelled word '
          'entirely, with nothing put in its place. This isn\'t an AI '
          'suggestion; it\'s always available for any flagged word.\n'
          '- A **"Dismiss"** row (in green) — tapping it changes nothing '
          'in the text; it just tells the app to stop treating that word '
          'as misspelled (removes the underline).\n\n'
          'Turning this off immediately clears every red underline '
          'currently shown, and the app stops calling the AI for spell '
          'checking until you turn it back on.';

  static String giaiThichChenDauCauNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bật lên, AI tự chèn thêm dấu câu còn thiếu (dấu chấm, phẩy, hỏi, '
          'than...) vào những chỗ hợp lý trong bài. Đoạn dấu câu vừa chèn '
          'nhấp nháy **nền xanh dương** trong 4 giây rồi trở về chữ bình '
          'thường.'
      : 'When on, AI automatically inserts missing punctuation (periods, '
          'commas, question marks, exclamation marks...) in sensible spots '
          'in the document. Freshly inserted punctuation flashes with a '
          '**blue background** for 4 seconds before returning to normal '
          'text.';

  static String giaiThichChenDauCau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi tính năng này bật, cùng lúc với việc kiểm tra chính tả (nếu '
          'tính năng đó cũng đang bật), AI còn tự chèn thêm những dấu câu '
          'còn thiếu vào bài: dấu chấm, phẩy, hỏi, than, chấm phẩy, hai '
          'chấm, ba chấm, ngoặc đơn, ngoặc kép, gạch ngang... tuỳ chỗ nào '
          'AI thấy cần.\n\n'
          'Ngay sau khi AI chèn xong, đúng đoạn dấu câu đó **nhấp nháy '
          'nền xanh dương** trong 4 giây để bạn dễ nhận ra chỗ AI vừa '
          'sửa, rồi tự động biến mất — trở về chữ bình thường như mọi ký '
          'tự khác trong bài, không cần bấm gì thêm.\n\n'
          'Nếu cả hai tính năng "Kiểm tra chính tả bằng AI" và "Tự động '
          'chèn dấu câu bằng AI" đều bật, chúng gộp chung vào MỘT lần gọi '
          'AI duy nhất để đỡ tốn hạn mức. Tắt tính năng này đi thì AI chỉ '
          'còn sửa chính tả, không tự thêm dấu câu nào nữa.'
      : 'When this feature is on, alongside spell checking (if that '
          'feature is also on), AI inserts whatever punctuation is '
          'missing from the document: periods, commas, question marks, '
          'exclamation marks, semicolons, colons, ellipses, parentheses, '
          'quotation marks, dashes... wherever the AI judges it\'s needed.\n\n'
          'Right after AI inserts it, that exact punctuation **flashes '
          'with a blue background** for 4 seconds so you can easily spot '
          'what was just fixed, then it fades back to normal text like '
          'any other character — no action needed.\n\n'
          'If both "AI spell check" and "AI auto-punctuation" are on, they '
          'are combined into a SINGLE AI call to save quota. Turning this '
          'off leaves AI only fixing spelling, with no more automatic '
          'punctuation.';

  static String giaiThichThemDauChamNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm **Enter** ở cuối câu: nếu ký tự ngay trước con trỏ là dấu '
          'cách, nó được thay bằng dấu chấm; nếu không, ứng dụng tự thêm '
          'một dấu chấm rồi mới xuống dòng.'
      : 'Press **Enter** at the end of a sentence: if the character right '
          'before the cursor is a space, it gets replaced with a period; '
          'otherwise the app adds a period before moving to a new line.';

  static String giaiThichThemDauCham(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi bạn bấm Enter để xuống dòng, ứng dụng nhìn lại ký tự ngay '
          'trước con trỏ:\n\n'
          '- Nếu đó là một **dấu cách**, dấu cách đó được **thay** bằng '
          'dấu chấm.\n'
          '- Nếu KHÔNG phải dấu cách, ứng dụng **chèn thêm** một dấu '
          'chấm ngay trước khi xuống dòng.\n\n'
          'Nhờ vậy mỗi dòng (đoạn) trong bài luôn kết thúc bằng dấu '
          'chấm, không cần tự gõ tay. Tắt tính năng này thì Enter chỉ '
          'đơn thuần xuống dòng, không thêm bớt gì.'
      : 'When you press Enter to start a new line, the app looks at the '
          'character right before the cursor:\n\n'
          '- If it\'s a **space**, that space is **replaced** with a '
          'period.\n'
          '- If it is NOT a space, the app **inserts** a period right '
          'before moving to the new line.\n\n'
          'This way, every line (paragraph) in the document always ends '
          'with a period, with no manual typing needed. Turning this off '
          'makes Enter simply move to a new line, with nothing added.';

  static String giaiThichThutDauDongNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Sau khi xuống dòng, ứng dụng tự chèn một số dấu cách (bạn chọn '
          'từ 1-7, mặc định 3) ở đầu dòng mới, con trỏ đứng ngay sau đó — '
          'giống thụt đầu dòng của một đoạn văn.'
      : 'After a new line, the app automatically inserts some spaces (you '
          'choose 1–7, default 3) at the start of the new line, with the '
          'cursor right after them — like a paragraph indent.';

  static String giaiThichThutDauDong(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Mỗi lần bấm Enter để xuống dòng, ngay khi con trỏ vừa sang dòng '
          'mới, ứng dụng tự chèn thêm một số dấu cách vào đầu dòng đó — '
          'con trỏ đứng ngay sau các dấu cách này, sẵn sàng để bạn gõ '
          'hoặc nói tiếp. Số dấu cách do bạn chọn ở Menu thả xuống ngay '
          'dưới công tắc này (từ 1 đến 7, mặc định 3) — đổi lựa chọn thì '
          'áp dụng ngay cho lần xuống dòng kế tiếp. Đây là cách thụt đầu '
          'dòng quen thuộc của văn bản tiếng Việt. Tắt tính năng này thì '
          'dòng mới bắt đầu ngay từ cột đầu tiên, không có khoảng thụt '
          'nào.'
      : 'Each time you press Enter for a new line, as soon as the cursor '
          'moves there, the app inserts a number of spaces at the start '
          'of that line — the cursor sits right after them, ready for you '
          'to continue typing or speaking. You pick the number of spaces '
          'in the dropdown right below this switch (1 to 7, default 3) — '
          'a change applies starting with the next new line. This is a '
          'familiar paragraph-indent style. Turning this off makes new '
          'lines start right at column one, with no indent.';

  static String giaiThichDuongKeChiaNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Bấm Enter hai lần liên tiếp (tạo một dòng trống) sẽ vẽ một '
          'đường kẻ chia đoạn văn mờ ngay tại dòng trống đó, giúp nhìn ra '
          'ranh giới giữa các đoạn.'
      : 'Pressing Enter twice in a row (creating a blank line) draws a '
          'faint paragraph divider right on that blank line, making it '
          'easy to see where paragraphs begin and end.';

  static String giaiThichDuongKeChia(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Khi bạn xuống dòng và để lại một dòng TRỐNG (hoặc chỉ toàn dấu '
          'cách) — thường là do bấm Enter hai lần liên tiếp — ứng dụng tự '
          'vẽ một đường kẻ chia đoạn văn mờ ngay tại dòng trống đó, giúp '
          'phân biệt rõ các đoạn văn khác nhau trong bài. Bạn chọn được '
          'màu và độ rõ của đường kẻ này ở ngay bên trên.\n\n'
          'Đường kẻ này chỉ là một nét vẽ hiển thị, KHÔNG phải ký tự thật '
          'chèn vào bài — nó tự bám đúng dòng trống dù màn hình xoay hay '
          'đổi kích thước. Nếu bạn gõ chữ vào đúng dòng trống đó (không '
          'còn trống nữa), đường kẻ tự biến mất; xoá hẳn dòng đó cũng '
          'vậy.'
      : 'When a line break leaves a BLANK line (or one with only spaces) '
          '— usually from pressing Enter twice in a row — the app draws a '
          'faint paragraph divider right on that blank line, making '
          'different paragraphs easy to tell apart. You choose the '
          'divider\'s color and opacity just above.\n\n'
          'This divider is purely a visual mark, NOT an actual character '
          'inserted into the document — it stays locked to the right '
          'blank line even if the screen rotates or resizes. If you type '
          'into that blank line (it\'s no longer blank), the divider '
          'disappears automatically; deleting the line does the same.';

  static String giaiThichVietHoaDauCauNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Gõ xong một câu (kết thúc bằng . , : ! hoặc ?) rồi sang câu mới, '
          'chữ cái đầu của từ đầu tiên tự được viết Hoa.'
      : 'After finishing a sentence (ending with . , : ! or ?) and '
          'starting a new one, the first letter of the first word is '
          'automatically capitalized.';

  static String giaiThichVietHoaDauCau(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Sau khi bạn gõ một trong các dấu . , : ! ? rồi một dấu cách, '
          'ứng dụng ghi nhớ: từ tiếp theo cần viết Hoa chữ đầu. Khi bạn '
          'gõ xong từ đó (tới khi gặp dấu cách hoặc xuống dòng tiếp '
          'theo), ứng dụng mới viết Hoa chữ cái đầu tiên của từ — không '
          'đổi gì khác trong từ đó.\n\n'
          'Nếu ký tự đầu từ không phải chữ cái (ví dụ số), ứng dụng bỏ '
          'qua, không viết Hoa được thì thôi. Việc này áp dụng cho cả gõ '
          'tay và giọng nói. Tắt tính năng này thì chữ giữ nguyên như '
          'bạn gõ/nói, không tự viết Hoa gì cả.'
      : 'After you type one of . , : ! ? followed by a space, the app '
          'remembers that the next word needs its first letter '
          'capitalized. Once you finish typing that word (reaching the '
          'next space or line break), the app capitalizes only its first '
          'letter — nothing else in the word changes.\n\n'
          'If the word\'s first character isn\'t a letter (e.g. a '
          'number), the app skips it — it just leaves it as-is when it '
          'can\'t capitalize. This applies to both typing and speech. '
          'Turning this off leaves text exactly as typed or spoken, with '
          'no automatic capitalization.';

  static String giaiThichChuanHoaNgoacNgan(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Gõ một trong các dấu ( ) { } [ ] " thì ứng dụng tự xoá dấu cách '
          'thừa ngay sau dấu mở hoặc ngay trước dấu đóng của cặp đó.'
      : 'Typing one of ( ) { } [ ] " makes the app automatically remove '
          'any stray space right after the opening mark or right before '
          'the closing mark of that pair.';

  static String giaiThichChuanHoaNgoac(NgonNgu nn) => nn == NgonNgu.vi
      ? 'Áp dụng cho bốn cặp dấu: ngoặc đơn ( ), ngoặc nhọn { }, ngoặc '
          'vuông [ ] và ngoặc kép " ". Mỗi lần bạn gõ một trong bảy ký tự '
          'này, ứng dụng quét lại để tìm ra cặp mà ký tự đó vừa hoàn '
          'thành, rồi chuẩn hoá: nếu ngay sau dấu mở là một dấu cách, xoá '
          'nó đi; nếu ngay trước dấu đóng là một dấu cách, cũng xoá nó '
          'đi. Ví dụ "( chào )" tự thành "(chào)".\n\n'
          'Với ( ) { } [ ]: dấu mở và dấu đóng phân biệt rõ ràng, ứng '
          'dụng ghép mỗi dấu đóng với dấu mở gần nhất còn chưa có cặp. '
          'Dấu nào lẻ loi (mở mà chưa có đóng, hoặc đóng mà không có '
          'mở) thì bỏ qua, không đụng gì tới.\n\n'
          'Với " ": dấu nháy kép không phân biệt được mở/đóng qua hình '
          'dạng, nên ứng dụng dùng quy ước đơn giản — quét từ đầu bài, '
          'dấu nháy kép thứ nhất/ba/năm... luôn là dấu mở, thứ hai/tư/'
          'sáu... luôn là dấu đóng, ghép theo đúng thứ tự đó.\n\n'
          'Tắt tính năng này thì dấu cách quanh các dấu ngoặc/nháy kép '
          'giữ nguyên như bạn gõ, không tự xoá gì cả.'
      : 'Applies to four pairs: parentheses ( ), braces { }, brackets '
          '[ ] and double quotes " ". Each time you type one of these '
          'seven characters, the app scans to find the pair that '
          'character just completed, then normalizes it: if there\'s a '
          'space right after the opening mark, it\'s removed; if there\'s '
          'a space right before the closing mark, that\'s removed too. '
          'For example "( hello )" becomes "(hello)".\n\n'
          'For ( ) { } [ ]: opening and closing marks are clearly '
          'distinct, so the app pairs each closing mark with the nearest '
          'unpaired opening mark. Any mark left alone (opening with no '
          'closing, or closing with no opening) is left untouched.\n\n'
          'For " ": double quotes can\'t be told apart as opening/closing '
          'by shape alone, so the app uses a simple rule — scanning from '
          'the start of the document, the 1st/3rd/5th... quote is always '
          'an opening mark, the 2nd/4th/6th... is always a closing mark, '
          'paired in that order.\n\n'
          'Turning this off leaves spaces around brackets/quotes exactly '
          'as typed, with nothing auto-removed.';
}
