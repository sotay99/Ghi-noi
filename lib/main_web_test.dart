// Flowrite — BẢN THỬ NGHIỆM riêng cho Flutter Web.
//
// File này là MỘT APP FLUTTER ĐỘC LẬP, có `void main()`/`runApp()` riêng.
// KHÔNG import `main.dart`, `trang_soan_thao.dart` hay bất kỳ file nào khác
// của app Android hiện có — mục đích DUY NHẤT là kiểm chứng xem thuật toán
// xử lý kết quả giọng nói (chốt dần + tìm điểm nối) có chạy ổn với nguồn dữ
// liệu từ Web Speech API (qua package `speech_to_text` chạy trên web) hay
// không, TÁCH BIỆT HOÀN TOÀN khỏi app Android.
//
// Thuật toán lõi bên dưới là bản ĐƠN GIẢN HOÁ, viết lại (không import) từ
// `_khiCoChu`/`_tuDaChotTrongPhien`/`_partialTruocDo`/`_timDiemNoiTrong` và
// LỚP 1 (re-check `idPhien`) trong `lib/trang_soan_thao.dart` — xem chú thích
// ở đó để biết đầy đủ lý do thiết kế. Ở đây bỏ bớt các phần không cần cho mục
// đích test: không có "bộ đệm chống nhân đôi qua ranh giới phiên" (LỚP 2),
// không đụng chỉnh tả/bộ nhớ đệm định dạng. CÓ gõ-phím-thắng-micro (xem
// `_khiNguoiDungGoPhim`) để test vừa nói vừa gõ tay.
//
// THÊM MỚI (vòng test di động):
// - Nhận diện thiết bị qua User-Agent (enum `ThietBi`: android/pc/iphone),
//   có nút chuyển tay (SegmentedButton) để ép chế độ khi nhận diện sai —
//   MỖI nhánh gọi một hàm xử lý kết quả RIÊNG (`_xuLyKetQuaDienThoai` /
//   `_xuLyKetQuaPc` / `_xuLyKetQuaIphone`) để sửa nhánh này không đụng
//   nhánh khác.
// - Khung "Nhật ký" hiển thị NGAY trên trang (không cần USB debug) để người
//   dùng chụp màn hình gửi lại khi rà lỗi trên điện thoại.
// - Vá lỗi nhân bản chữ đã thấy trên Chrome Android: khi không tìm được
//   điểm nối VÀ đoạn partial mới dài bằng/hơn toàn bộ phần đã chốt — dấu
//   hiệu bộ nhận dạng đang gửi lại TOÀN BỘ câu từ đầu chứ không phải phần
//   mới — thì coi partial mới là toàn bộ nội dung phiên, không nối thêm
//   (nối thêm trong trường hợp này là nguyên nhân gây chữ nhân bản chồng
//   chất trong ảnh chụp người dùng gửi).
// - Ghi âm thô + gửi Gemini phiên âm (dành cho iPhone, nơi Web Speech API
//   không hoạt động kể cả bấm tay): mỗi lần dừng ghi âm chèn một token
//   "〔🎙️ Ghi âm N〕" vào đúng vị trí con trỏ trong khung nhập — token văn
//   bản THUẦN TUÝ, không phải ô chip đồ hoạ thật (TextField của Flutter
//   không hỗ trợ chèn widget vào giữa văn bản có thể sửa). Nút "Tạo văn
//   bản" gửi từng file ghi âm cho máy chủ trung gian AI đã có sẵn action
//   'ghi_am' (xem cloud-function/index.js, app Android cũng dùng chung —
//   lib/ghi_am_ai.dart), rồi thay đúng mỗi token bằng chữ phiên âm được,
//   giữ nguyên các đoạn gõ tay xen kẽ xung quanh.
// - (v18) Thẻ hiện NGAY lúc bắt đầu ghi (token tĩnh "đang ghi âm", đồng hồ
//   đếm giờ hiển thị ở hàng tiêu đề "Kết quả", KHÔNG nhét vào trong nội
//   dung văn bản để tránh xung đột với gõ tay), đổi thành "Thẻ ghi âm số N"
//   khi dừng. Trên iPhone, nút micro CHÍNH (nút xanh lá) giờ gọi thẳng cơ
//   chế ghi-âm-rồi-gửi-Gemini thay vì thử Web Speech API (vốn không chạy
//   được trên iOS). Bàn phím ảo hiện lên thì ẩn hết các hàng bên dưới khung
//   nhập, để khung nhập giãn hết cỡ phần còn lại phía trên bàn phím.
// - (v19) Thẻ giờ KHÔNG thể sửa/xoá từng ký tự bên trong — `_ChanSuaGiuaThe`
//   (một `TextInputFormatter`) phóng to mọi chỉnh sửa chồng lấn một phần
//   vùng thẻ thành xoá TRỌN thẻ, và đẩy con trỏ ra khỏi giữa thẻ khi chỉ di
//   chuyển (không gõ). Thẻ cũng được tô màu: "Ghi âm N" xanh lá, token
//   "đang ghi âm" đỏ (`_BoDieuKhienVanBanCoThe`, override `buildTextSpan`).
//   Bỏ hai nút "Nghe lại"/"Tải xuống"; trên iPhone ẩn nút "Ghi âm" riêng vì
//   nút micro chính đã làm đúng việc đó rồi.
// - (v20) Sửa TẬN GỐC lỗi "gõ tay lúc đang ghi làm token rác/thứ tự sai":
//   thiết kế cũ (v18/v19) COI gõ tay là HUỶ bản ghi, nhưng `MediaRecorder.
//   stop()` luôn bắn sự kiện 'stop' bất đồng bộ SAU ĐÓ — trong khoảng chờ
//   đó (có thể trải qua nhiều phím gõ tiếp theo) token "đang ghi âm" vẫn
//   còn nằm lù lù trong văn bản như chữ thật, gây đúng các lỗi đã gặp.
//   Nay đổi hẳn cách hiểu: gõ tay trong lúc ghi KHÔNG huỷ mà CHỐT NGAY
//   (đồng bộ, không đợi 'stop') thẻ đang ghi thành "〔🎙️ Ghi âm N〕" tại
//   đúng vị trí cũ, rồi BẮT ĐẦU MỘT THẺ MỚI ngay sau ký tự vừa gõ, dùng lại
//   đúng luồng mic đã xin quyền — ghi âm tiếp tục liền mạch, tách thành hai
//   thẻ, không mất tiếng, không còn token rác. Số thẻ được DÀNH SẴN ngay
//   lúc bắt đầu ghi (`_soTheDangGhiHienTai`), không đợi tới lúc có blob âm
//   thanh — sự kiện 'stop' giờ CHỈ lưu blob vào đúng số thẻ đã dành sẵn,
//   không động gì tới văn bản nữa. `_chenTheGhiAmVaoVanBan` cũng được sửa
//   để GIỮ NGUYÊN vị trí tương đối của con trỏ so với phần chữ nằm sau
//   token (ví dụ dấu phẩy vừa gõ), thay vì luôn đẩy con trỏ về ngay sau
//   token — tránh lỗi con trỏ nhảy lùi đã gặp.
// - (v21) `_batDauMotThe` tách làm hai (`_taoBoGhiAmMoi` chỉ tạo
//   `MediaRecorder`, không đụng văn bản) để lúc tách thẻ có thể gộp
//   chốt-token-cũ + chèn-token-mới vào một thao tác — mục đích ban đầu là
//   sửa lỗi "phải gõ hai ký tự", nhưng chẩn đoán lúc đó SAI (xem v22).
// - (v22) TÌM RA nguyên nhân THẬT của lỗi "phải gõ hai ký tự mới tách thẻ":
//   gán `TextEditingController.value =` theo cách lập trình KHÔNG khiến
//   `TextField.onChanged` tự chạy lại — khác hẳn giả định ở các bản v18–v21.
//   Bằng chứng (log v21): token "đang ghi âm" chèn lúc 17:30:13, nhưng
//   dòng log lẽ ra phải in NGAY nếu có `onChanged` chạy lại chỉ thực sự
//   xuất hiện lúc 17:30:17 — đúng lúc người dùng gõ phím THẬT tiếp theo.
//   Cờ "bỏ qua một lần" (`_boQuaKiemTraGoTrongLucGhiMotLan`) vì vậy nằm
//   chờ mãi và NUỐT MẤT đúng lượt gõ phím thật kế tiếp — đó là lý do luôn
//   phải gõ thêm một ký tự nữa. Sửa: BỎ HẲN cơ chế cờ; mọi hàm chèn/thay
//   token giờ tự chốt cứng trạng thái (`_vanBanDaChot`, `_tuDaChot`...)
//   NGAY TẠI CHỖ bằng `_ghiVanBanChoTheVaChotCung`, không còn trông chờ
//   một `onChanged` không tồn tại nữa.
// - (v23) Chữ do MICRO NHẬN DẠNG (nút micro chính, KHÁC cơ chế thẻ ghi âm ở
//   trên) giờ chèn ĐÚNG TẠI VỊ TRÍ CON TRỎ thay vì luôn luôn chèn ở CUỐI
//   văn bản — tham khảo đúng hành vi app Android (`_neo`/`_datNeoTaiConTro`
//   trong `trang_soan_thao.dart`). Thêm `_neoChenMic` (vị trí chèn hiện
//   hành) và `_chenTuVaoViTri` (chèn giữa chuỗi thay vì nối cuối). Neo chỉ
//   được dời tới đúng vị trí con trỏ khi MỘT PHIÊN NGHE MỚI bắt đầu
//   (`_batNghe` — bấm nút, tự bật lại sau khi gõ tay xong, hay trình duyệt
//   tự khởi động lại phiên) — KHÔNG dời giữa chừng một phiên đang nói liên
//   tục, đúng hành vi Android: đang nói liên tục mà kéo con trỏ đi chỗ
//   khác thì chữ vẫn tiếp tục ra ở vị trí cũ cho tới khi có phiên nghe mới.
//   `_tuDaChot` đổi ý nghĩa thành "phần đã chốt NGAY TRƯỚC neo" (không còn
//   là "toàn bộ văn bản") — tính lại mỗi khi neo đổi, để thuật toán dò
//   trùng lặp/điểm nối không so khớp nhầm với chữ không liên quan nằm ở
//   chỗ khác trong văn bản.
// - (v24) Sửa lại v23: đang nói mà kéo con trỏ đi chỗ khác GIỮA CHỪNG một
//   phiên nghe (chưa đợi phiên tự ngắt) vẫn phải đổi chỗ chèn NGAY — đúng
//   hành vi thật của app Android (`_dongBangDoanDangNhay()` trong
//   `trang_soan_thao.dart`: mọi lần con trỏ bị người dùng dời trong lúc
//   đang nghe đều CẮT phiên hiện tại và nghe lại ngay, không có chuyện
//   "cứ nói liên tục thì bỏ qua" — điều đó ở v23 là hiểu sai). Thêm
//   `_khiGiaTriKhungNhapDoi`, gắn qua `_boDieuKhienVanBan.addListener` (bắt
//   được cả lúc CHỈ đổi vị trí con trỏ, không đổi chữ — `onChanged` không
//   bắt được ca này): con trỏ đổi trong lúc micro đang nghe → cắt hẳn
//   phiên (`_micro.cancel()`) rồi nghe lại (`_henNgheLai()`), để `_batNghe`
//   tự dời neo theo đúng vị trí mới. Bắt buộc phải CẮT PHIÊN thật (không
//   chỉ dời neo tại chỗ) vì hypothesis Web Speech API trả về là hypothesis
//   TÍCH LUỸ của CẢ PHIÊN — nếu phiên cũ cứ chạy tiếp mà neo đã đổi, lần
//   kết quả kế tiếp sẽ hiểu nhầm toàn bộ tích luỹ là "chữ mới" và chèn
//   nhân đôi.
// - (v25) Chế độ "ngăn bàn phím ảo" (nút hình bàn phím cạnh nút micro):
//   không có cách nào ra lệnh cho hệ điều hành đừng hiện bàn phím ảo của
//   MỘT Ô CÓ THỂ GÕ ĐƯỢC (giới hạn cố ý của trình duyệt), nên né bằng cách
//   chuyển khung nhập sang `readOnly` khi bật chế độ này — Flutter CHÍNH
//   THỨC hỗ trợ: chạm để di chuyển con trỏ/chọn vùng vẫn hoạt động, nhưng
//   trình duyệt không gọi bàn phím ảo lên vì ô "không cho gõ". Bù lại bằng
//   hàng phím ảo riêng (chấm/phẩy/cách/xuống dòng/xoá) — mỗi phím đi qua
//   ĐÚNG `_ChanSuaGiuaThe.formatEditUpdate` trước khi áp dụng (bảo vệ thẻ
//   ghi âm khỏi bị sửa một phần, y hệt bàn phím thật) rồi gọi
//   `_khiNguoiDungGoPhim` — coi như một lượt gõ tay bình thường.
//   Đồng thời thêm "chọn vùng rồi nói tiếp thì giọng nói ĐÈ LÊN vùng đó" —
//   y hệt tinh thần `_datNeoTaiConTro()` bên app Android: `_batNghe` giờ
//   nhớ luôn độ dài vùng đang chọn (`_doDaiVungDeDeMic`) khi đặt neo, và
//   `_apDungXoaVungChonMicNeuCo` xoá đúng vùng đó ngay lúc có chữ THẬT đầu
//   tiên để thay vào — cố tình KHÔNG xoá ngay lúc bật micro, để bật rồi
//   tắt mà chưa nói gì thì vùng chọn vẫn còn nguyên.
// - (v26) Ở chế độ ngăn bàn phím ảo: ép hiện con trỏ nhấp nháy
//   (`showCursor: true`).
// - (v27) Đổi hẳn cơ chế ngăn bàn phím ảo: BỎ `readOnly` (gây lỗi kéo-chọn-
//   vùng bằng ngón tay — vuốt không ra đầu mút, kéo đầu mút xa bị kẹt, đầu
//   mút lệch vị trí thật, vì `readOnly` đổi hẳn đường xử lý cử chỉ của ô
//   nhập sang "xem + chọn" thay vì "soạn thảo"), dùng `keyboardType:
//   TextInputType.none` thay thế — ô vẫn ở chế độ soạn thảo BÌNH THƯỜNG
//   (mọi cử chỉ chọn vùng hoạt động y hệt lúc tắt chế độ), chỉ báo hệ
//   thống đừng bật bàn phím ảo. (Sau này phát hiện: đổi này KHÔNG sửa được
//   lỗi kéo-chọn-vùng — xem v28.)
// - (v28) Lỗi kéo-chọn-vùng ở v25–v27 hoá ra không liên quan gì tới
//   `readOnly`/`keyboardType` — bằng chứng: máy tính bảng Android bị lỗi,
//   điện thoại Android CÙNG hệ điều hành lại không, kể cả khi tắt hẳn chế
//   độ ngăn bàn phím. Nguyên nhân thật: Flutter TỰ ĐOÁN kiểu bộ điều khiển
//   chọn-vùng (di động — có đầu mút kéo được — hay bàn phím/chuột — kéo
//   bằng chuột, không cần đầu mút) dựa theo tên hệ điều hành trình duyệt
//   khai báo, và bị đoán sai trên một số thiết bị cảm ứng — CÙNG KIỂU lỗi
//   User-Agent "chế độ máy tính" đã gặp ở việc nhận diện thiết bị của
//   chính trang này, nhưng lần này nằm BÊN TRONG khung Flutter, không sửa
//   được bằng `_doanThietBi()`.
//   Sửa: khi bật chế độ ngăn bàn phím ảo (người dùng đã tự xác nhận không
//   dùng chuột/bàn phím rời — đúng mục đích sinh ra nút đó), ép hẳn
//   `selectionControls: materialTextSelectionControls` — bộ điều khiển
//   kiểu di động, không để Flutter tự đoán nữa. KHÔNG ép khi tắt chế độ —
//   lúc đó không chắc người dùng có chuột/bàn phím rời hay không.
//   RÚT LẠI ý "tự kết thúc thẻ khi con trỏ di chuyển" đã ghi ở trên (v20) —
//   quá rủi ro cho một tính năng GHI ÂM (khác hẳn micro vừa nói vừa ra
//   chữ): di chuyển con trỏ trong lúc một thẻ đang ghi dở giờ KHÔNG đụng
//   gì tới nó nữa, thẻ cứ ghi tiếp tại đúng vị trí cũ dù con trỏ đi đâu.
//   Chỉ GÕ TAY thật (không phải chỉ di chuyển con trỏ) mới chốt thẻ đang
//   ghi và bắt đầu thẻ mới — logic này giữ nguyên như cũ.
// - (v29) Làm xong "chế độ tự động gửi ngầm" đã bàn ở v28:
//   - Nút riêng (icon đám mây cạnh "Tạo văn bản") bật/tắt `_tuDongGuiNgam`
//     (mặc định TẮT). Bật lên thì mỗi khi có ≥1 thẻ đã ghi xong CHƯA gửi
//     mà TỔNG thời lượng ≥20 giây, tự gửi ngầm hết các thẻ đó cho Gemini
//     (không chờ, không khoá giao diện) trong lúc thẻ mới vẫn đang ghi
//     tiếp — xong thẻ nào, thay đúng thẻ đó bằng chữ ngay, không đợi thẻ
//     khác. Nút "Tạo văn bản" thủ công vẫn giữ nguyên cho thẻ chưa đủ
//     ngưỡng hoặc muốn chuyển ngay; hai đường phối hợp qua `_theDangDuocGui`
//     để không gửi trùng một thẻ. Gemini lỗi ở một thẻ gửi ngầm thì ÂM
//     THẦM bỏ qua, lần kiểm tra sau tự thử lại — không báo ồn ào.
//   - Định dạng thẻ hoàn chỉnh đổi thành "〔Ghi âm N 🎙️ mm:ss〕" (thêm thời
//     lượng thật của thẻ) — `_thoiLuongTheoThe` lưu thời lượng theo số thẻ,
//     `_chotThoiLuongVaLayNhanThe` chốt và dựng nhãn ĐÚNG MỘT LẦN khi thẻ
//     được chốt.
//   - Giới hạn 5 phút/thẻ: cảnh báo bằng hộp thoại giữa màn hình ở phút
//     4:30 (nút "Tạo bản ghi âm mới" hoặc "Dừng và không ghi âm nữa"); nếu
//     không chọn gì, tới đúng phút thứ 5 tự động xử lý y hệt "Tạo bản ghi
//     âm mới" (chốt thẻ cũ, bắt đầu thẻ mới đếm lại từ 0) — dùng chung cơ
//     chế chốt-thẻ đã có (`_chenTheGhiAmVaoVanBan`/`_batDauMotThe`), không
//     cần logic mới. KHÔNG dùng cách dò "có tiếng nói hay không" để hoãn
//     cắt — thời điểm ngắt cố định, không phụ thuộc âm lượng/độ nhạy mic
//     (đã bàn: cách dò tiếng nói khả thi nhưng cần chỉnh ngưỡng theo từng
//     máy, không tự kiểm chứng được).

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';

// Ngoại lệ DUY NHẤT cho luật "không import file nào khác của app" ở đầu
// file — import CHỈ hai hằng số (địa chỉ + mật khẩu máy chủ trung gian AI),
// không kéo theo bất kỳ logic nào có thể ảnh hưởng tới thuật toán mic đã
// test kỹ. Giữ một nguồn duy nhất cho bí mật thay vì chép tay chuỗi mật
// khẩu ra thêm một chỗ trong mã nguồn.
import 'ai_cau_hinh.dart';

// Số phiên bản bản thử — TĂNG THỦ CÔNG mỗi lần đẩy bản mới lên Firebase
// Hosting, để người test biết chắc trình duyệt đã tải đúng bản mới nhất
// hay đang dùng bản cache cũ (Chrome hay giữ cache service worker của
// Flutter Web dù đã bấm tải lại thường).
const _phienBanThuNghiem = 'v31';
// v30: chữ Gemini vừa nhận nhấp nháy xanh↔đen 4 giây; tự động gửi ngầm bật
// SẴN mặc định (vẫn tắt được); tự lưu văn bản đang soạn vào localStorage
// (khôi phục lúc mở lại trang, kể cả không có mạng); Firebase Hosting đặt
// Cache-Control: no-cache cho index.html/flutter_service_worker.js/
// version.json để F5 lúc có mạng luôn lấy bản mới nhất mà không mất khả
// năng dùng ngoại tuyến (service worker vẫn còn nguyên).
// v31: bước 1 của việc "chuyển bố cục app Android sang web" — nút micro
// chuyển ra NGOÀI CÙNG bên phải của thanh công cụ dưới (đúng vị trí
// `_NutMicroTron` trong `ThanhCongCu` của app); nút "ngăn bàn phím ảo"
// chuyển vào menu "+ Thêm lựa chọn" mới (PopupMenuButton, đúng vị trí/tên
// như app Android); bộ chọn thiết bị (SegmentedButton) chuyển vào trang
// "Cài đặt" mới (mở từ "+ Thêm lựa chọn" → "Cài đặt"), đặt Ở ĐẦU TIÊN.
// Thuật toán mic/ghi âm/gửi Gemini/nhấp nháy/tự lưu — KHÔNG đổi gì.

// `diaChiMayChuAI`/`matKhauMayChuAI` đến từ ai_cau_hinh.dart (import ở
// trên) — máy chủ đó đã có sẵn action 'ghi_am' (xem cloud-function/
// index.js) dùng đúng cho việc gửi âm thanh cho Gemini phiên âm, app
// Android cũng đang dùng chung cơ chế này (lib/ghi_am_ai.dart).

// (Chỉ import đúng MỘT file `speech_to_text/speech_to_text.dart` — y hệt
// cách `trang_soan_thao.dart` đang dùng đã chứng minh hoạt động — thay vì
// đoán thêm đường import phụ (`speech_recognition_result.dart`,
// `speech_recognition_error.dart`) không có gì đảm bảo đúng khi môi trường
// này không compile-check được. `onResult`/`onError` vì thế nhận `dynamic`,
// giống hệt `_khiCoChu(dynamic ketQua, ...)` trong app chính.)

void main() {
  runApp(const UngDungThuMicroWeb());
}

class UngDungThuMicroWeb extends StatelessWidget {
  const UngDungThuMicroWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowrite — thử micro web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
      ),
      home: const TrangThuMicro(),
    );
  }
}

/// Ba nhánh thiết bị — mỗi nhánh một cách xử lý kết quả giọng nói riêng, vì
/// mỗi hệ điều hành/trình duyệt có cách trả kết quả khác nhau:
/// - `android`: Chrome trên Android (đã test kỹ, dùng bộ máy Chromium thật).
/// - `pc`: Chrome/Edge trên Windows/Linux VÀ trên macOS (Chrome trên Mac
///   dùng đúng bộ máy Chromium như Windows/Linux, không bị Apple ép dùng
///   WebKit như trên iOS — nên gộp chung một nhánh).
/// - `iPhone`: Safari/Chrome trên iOS — trên iOS, MỌI trình duyệt (kể cả
///   Chrome) đều bị Apple bắt buộc dùng chung bộ máy WebKit của Safari, nên
///   chỉ cần MỘT nhánh cho toàn bộ iPhone/iPad, bất kể tên trình duyệt.
enum ThietBi { android, pc, iphone }

String _tenThietBi(ThietBi t) {
  switch (t) {
    case ThietBi.android:
      return 'Android';
    case ThietBi.pc:
      return 'PC/Mac';
    case ThietBi.iphone:
      return 'iPhone';
  }
}

/// Đoán thiết bị bằng User-Agent — chỉ dùng làm giá trị GỢI Ý ban đầu, người
/// dùng luôn bấm được nút chuyển tay nếu đoán sai (ví dụ PC thu nhỏ cửa sổ).
ThietBi _doanThietBi() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  // iOS trước Android/mobile: iPad ở chế độ "Desktop site" vẫn có thể lẫn
  // chữ "mobile", nhưng chữ "iphone"/"ipad" luôn xuất hiện trên iOS thật.
  if (ua.contains('iphone') || ua.contains('ipad')) return ThietBi.iphone;
  if (ua.contains('android') || ua.contains('mobile')) return ThietBi.android;
  return ThietBi.pc;
}

/// Bộ điều khiển văn bản riêng, CHỈ khác `TextEditingController` chuẩn ở
/// việc tô màu: thẻ đã ghi âm xong ("〔🎙️ Ghi âm N〕") màu XANH LÁ, token
/// đang ghi dở ("〔🎙️ … đang ghi âm …〕") màu ĐỎ — để người dùng phân biệt
/// bằng mắt ngay trong khung nhập, không cần chờ bấm "Tạo văn bản". Không
/// đụng gì tới cách lưu trữ text (`text`/`value` vẫn y hệt controller gốc),
/// chỉ override cách VẼ ra màn hình.
class _BoDieuKhienVanBanCoThe extends TextEditingController {
  /// Các đoạn chữ Gemini VỪA chèn vào (thay cho một thẻ ghi âm), còn đang
  /// trong hiệu ứng nhấp nháy — (vị trí bắt đầu, vị trí kết thúc, thời điểm
  /// chèn). `buildTextSpan` tự tính màu theo thời gian trôi qua kể từ lúc
  /// chèn, và tự dọn các mục đã quá hạn nhấp nháy (xem `_thoiGianNhapNhay`).
  final List<(int, int, DateTime)> doanVuaNhanDuoc = [];

  static const _thoiGianNhapNhay = Duration(seconds: 4);
  static const _chuKyNhapNhay = Duration(milliseconds: 500);

  void danhDauVuaNhanDuoc(int batDau, int ketThuc) {
    if (batDau < 0 || ketThuc <= batDau) return;
    doanVuaNhanDuoc.add((batDau, ketThuc, DateTime.now()));
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final noiDung = text;
    final moc = <(int, int, Color)>[];
    for (final m in _TrangThuMicroState._reTheGhiAm.allMatches(noiDung)) {
      moc.add((m.start, m.end, Colors.green.shade700));
    }
    var timTu = 0;
    while (true) {
      final i = noiDung.indexOf(
          _TrangThuMicroState._tenTokenDangGhi, timTu);
      if (i < 0) break;
      moc.add((i, i + _TrangThuMicroState._tenTokenDangGhi.length,
          Colors.red.shade700));
      timTu = i + _TrangThuMicroState._tenTokenDangGhi.length;
    }

    // Hiệu ứng nhấp nháy xanh dương ↔ đen trong 4 giây cho chữ Gemini vừa
    // trả về — dọn các mục đã quá hạn, những mục còn lại tô màu dao động
    // theo sóng sin (nhấp nháy thật, không phải mờ dần một chiều).
    final bayGio = DateTime.now();
    doanVuaNhanDuoc
        .removeWhere((d) => bayGio.difference(d.$3) > _thoiGianNhapNhay);
    for (final d in doanVuaNhanDuoc) {
      if (d.$2 > noiDung.length) continue; // văn bản đổi, vị trí không còn hợp lệ.
      final troiQua = bayGio.difference(d.$3).inMilliseconds;
      final pha = (troiQua % _chuKyNhapNhay.inMilliseconds) /
          _chuKyNhapNhay.inMilliseconds;
      final heSo = (math.sin(pha * 2 * math.pi) + 1) / 2; // 0..1
      final mau =
          Color.lerp(Colors.black, Colors.blue.shade700, heSo) ?? Colors.black;
      moc.add((d.$1, d.$2, mau));
    }

    moc.sort((a, b) => a.$1.compareTo(b.$1));

    final spans = <InlineSpan>[];
    var conTro = 0;
    for (final m in moc) {
      if (m.$1 < conTro) continue; // đè nhau (không nên xảy ra) — bỏ qua.
      if (m.$1 > conTro) {
        spans.add(TextSpan(text: noiDung.substring(conTro, m.$1)));
      }
      spans.add(TextSpan(
        text: noiDung.substring(m.$1, m.$2),
        style: TextStyle(color: m.$3, fontWeight: FontWeight.bold),
      ));
      conTro = m.$2;
    }
    if (conTro < noiDung.length) {
      spans.add(TextSpan(text: noiDung.substring(conTro)));
    }
    return TextSpan(style: style, children: spans);
  }
}

/// Chặn sửa/xoá TỪNG KÝ TỰ bên trong một thẻ ghi âm (dù đã xong hay đang
/// ghi dở) — mọi chỉnh sửa CHỒNG LẤN một phần vùng ký tự của thẻ (không phủ
/// trọn thẻ) sẽ bị "phóng to" thành xoá NGUYÊN CẢ THẺ đó, để người dùng chỉ
/// có hai lựa chọn: giữ nguyên thẻ, hoặc xoá trọn một lần. Đồng thời chặn
/// con trỏ (hoặc vùng chọn) dừng lại ở GIỮA một thẻ khi người dùng chỉ di
/// chuyển con trỏ (không gõ gì) — tự đẩy ra biên gần nhất.
class _ChanSuaGiuaThe extends TextInputFormatter {
  List<(int, int)> _cacVungThe(String text) {
    final vung = <(int, int)>[];
    for (final m in _TrangThuMicroState._reTheGhiAm.allMatches(text)) {
      vung.add((m.start, m.end));
    }
    var timTu = 0;
    while (true) {
      final i = text.indexOf(_TrangThuMicroState._tenTokenDangGhi, timTu);
      if (i < 0) break;
      vung.add((i, i + _TrangThuMicroState._tenTokenDangGhi.length));
      timTu = i + _TrangThuMicroState._tenTokenDangGhi.length;
    }
    return vung;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    if (oldText == newText) {
      // Không đổi chữ — chỉ đổi vùng chọn (di chuyển con trỏ bằng phím mũi
      // tên hoặc chạm/bấm chuột). Đẩy con trỏ ra khỏi giữa thẻ nếu cần.
      final vung = _cacVungThe(newText);
      if (vung.isEmpty) return newValue;
      int day(int viTri) {
        for (final v in vung) {
          if (viTri > v.$1 && viTri < v.$2) {
            return (viTri - v.$1) < (v.$2 - viTri) ? v.$1 : v.$2;
          }
        }
        return viTri;
      }
      final base = day(newValue.selection.baseOffset);
      final extent = day(newValue.selection.extentOffset);
      if (base == newValue.selection.baseOffset &&
          extent == newValue.selection.extentOffset) {
        return newValue;
      }
      return newValue.copyWith(
        selection: TextSelection(baseOffset: base, extentOffset: extent),
      );
    }

    final vungCu = _cacVungThe(oldText);
    if (vungCu.isEmpty) return newValue;

    // Tìm đoạn khác nhau đầu/cuối giữa văn bản cũ và mới — cách đơn giản để
    // biết chính xác vùng ký tự nào trong `oldText` vừa bị đổi.
    var dau = 0;
    final ngan =
        oldText.length < newText.length ? oldText.length : newText.length;
    while (dau < ngan && oldText[dau] == newText[dau]) dau++;
    var cuoiCu = oldText.length;
    var cuoiMoi = newText.length;
    while (cuoiCu > dau &&
        cuoiMoi > dau &&
        oldText[cuoiCu - 1] == newText[cuoiMoi - 1]) {
      cuoiCu--;
      cuoiMoi--;
    }

    for (final v in vungCu) {
      final chongLan = dau < v.$2 && cuoiCu > v.$1;
      final phuTron = dau <= v.$1 && cuoiCu >= v.$2;
      if (chongLan && !phuTron) {
        // Sửa/xoá một phần của thẻ — phóng to vùng xoá ra trọn thẻ đó,
        // giữ nguyên phần chữ gõ tay còn lại ở hai đầu (nếu có).
        final vanBanKetQua = oldText.replaceRange(v.$1, v.$2, '');
        return TextEditingValue(
          text: vanBanKetQua,
          selection: TextSelection.collapsed(offset: v.$1),
        );
      }
    }
    return newValue;
  }
}

/// Một phím ảo trong hàng phím thay thế bàn phím hệ thống ở chế độ "ngăn
/// bàn phím ảo" (xem `_chanBanPhimAo`) — chấm/phẩy/cách/xuống dòng/xoá.
class _NutPhimAo extends StatelessWidget {
  const _NutPhimAo({
    required this.nhan,
    required this.onTap,
    this.moTa,
    this.mauNen,
    this.mauVien,
  });

  final String nhan;
  final String? moTa;
  final VoidCallback onTap;
  final Color? mauNen;
  final Color? mauVien;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: moTa ?? nhan,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 40,
          decoration: BoxDecoration(
            color: mauNen ?? Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: mauVien ?? Colors.grey.shade400),
          ),
          alignment: Alignment.center,
          child: Text(nhan, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class TrangThuMicro extends StatefulWidget {
  const TrangThuMicro({super.key});

  @override
  State<TrangThuMicro> createState() => _TrangThuMicroState();
}

class _TrangThuMicroState extends State<TrangThuMicro> {
  final _micro = SpeechToText();

  bool _sanSang = false;
  bool _muonNghe = false; // người dùng bấm bật, kể cả khi trình duyệt tạm dừng.
  bool _dangNghe = false;
  String _loi = '';

  // Chế độ "ngăn bàn phím ảo" — khung nhập chuyển `readOnly` (Flutter CHÍNH
  // THỨC hỗ trợ: chạm để di chuyển con trỏ/chọn vùng vẫn hoạt động bình
  // thường, nhưng trình duyệt không gọi bàn phím ảo lên vì ô "không cho
  // gõ"). Không có cách nào "ra lệnh" cho hệ điều hành đừng hiện bàn phím
  // của MỘT Ô CÓ THỂ GÕ ĐƯỢC — đây là giới hạn cố ý của trình duyệt, không
  // phải thiếu sót — nên né bằng cách đổi hẳn sang ô không-thể-gõ, và bù
  // lại bằng hàng phím ảo riêng (chấm/phẩy/cách/xuống dòng/xoá) cho những
  // thao tác gõ tay tối thiểu, còn phần lớn nội dung vẫn vào bằng giọng
  // nói (micro/thẻ ghi âm) — không phụ thuộc bàn phím thật.
  bool _chanBanPhimAo = false;

  // Chế độ thiết bị: đoán ban đầu qua User-Agent, người dùng đổi được bằng
  // nút chuyển tay (SegmentedButton 3 lựa chọn). Mỗi nhánh gọi một hàm xử
  // lý kết quả RIÊNG (`_xuLyKetQuaPc`/`_xuLyKetQuaDienThoai`/
  // `_xuLyKetQuaIphone`) — sửa cho nhánh này không đụng nhánh khác.
  late ThietBi _thietBi;

  // ---- đếm để nhìn bằng mắt lúc debug ----
  int _soLanPartial = 0;
  int _soLanFinal = 0;

  // ---- văn bản đang hiển thị — giờ CHO PHÉP gõ tay trực tiếp vào khung
  // kết quả, với nguyên tắc gõ-phím-thắng-micro (y hệt tinh thần
  // `_nguoiDungVuaGo()` bên app chính): gõ một phím là micro tắt NGAY, tự
  // bật lại sau 1 giây không gõ tiếp. ----
  String _vanBan = '';
  final _boDieuKhienVanBan = _BoDieuKhienVanBanCoThe();

  // Văn bản đã "chốt cứng" — giữ NGUYÊN VĂN (kể cả dấu xuống dòng/khoảng
  // trắng người dùng tự gõ). Micro chỉ được phép NỐI THÊM vào biến này
  // (không bao giờ dựng lại toàn bộ `_vanBan` bằng cách join(' ') danh sách
  // từ — làm vậy sẽ nuốt mất mọi dấu xuống dòng gõ tay, đúng lỗi người dùng
  // báo: bấm Enter xong nói tiếp thì dấu xuống dòng biến mất).
  String _vanBanDaChot = '';

  // Cờ chặn: khi TRUE nghĩa là đoạn `_boDieuKhienVanBan.text` đang được
  // chính code (do micro) ghi vào, không phải người dùng gõ — để
  // `_khiNguoiDungGoPhim` (gắn vào `onChanged`) không hiểu nhầm là người
  // dùng gõ rồi tắt oan micro.
  bool _dangGhiTuMicro = false;

  Timer? _henMoLaiMicroSauKhiGo;

  // ---- nhật ký hiển thị ngay trên trang, để test trên điện thoại không
  // cần USB debug — mỗi dòng có giờ:phút:giây để dễ đối chiếu. ----
  final List<String> _nhatKy = [];
  final _cuonNhatKy = ScrollController();

  // ---- trạng thái thuật toán "chốt dần theo độ ổn định" + "tìm điểm nối",
  // bản đơn giản hoá cho một PHIÊN duy nhất (không cần đệm ranh giới phiên
  // vì mục đích test không cần chính xác 100% qua mỗi lần trình duyệt tự
  // ngắt — chỉ cần QUAN SÁT được thuật toán chạy ổn hay không). ----
  List<String> _tuDaChot = [];
  List<String> _partialTruocDo = [];

  // Riêng cho nhánh điện thoại: chuỗi thô (sau khi đã cắt-đoạn-cuối-sạch)
  // của lần callback TRƯỚC trong CÙNG phiên hiện tại — dùng để lấy đúng
  // phần MỚI thêm vào bằng cách so sánh chuỗi (không phụ thuộc việc đoạn
  // lặp lại có viết hoa hay không, vì cách cắt theo chữ hoa không bắt được
  // mọi trường hợp lặp — xem log thực tế: có lúc lặp lại giữa câu, không
  // hoa chữ nào). Reset về rỗng mỗi khi phiên nghe mới bắt đầu.
  String _rawTruocDoTrongPhien = '';

  // Đánh số phiên nghe, y hệt `idPhien`/`_phienNgheHienTai` bên app chính —
  // để loại bỏ callback trễ của một phiên đã đóng (LỚP 1).
  int _phienHienTai = 0;

  // Vị trí ký tự — trong `_vanBanDaChot` — nơi chữ do micro nhận dạng được
  // CHÈN VÀO, y hệt tinh thần `_neo` bên app chính (`trang_soan_thao.dart`):
  // KHÔNG phải luôn luôn ở cuối văn bản. Đặt lại (dời theo con trỏ hiện
  // tại) mỗi khi một PHIÊN NGHE MỚI bắt đầu (`_batNghe`) — bấm nút bật
  // micro, tự bật lại sau khi gõ tay xong, con trỏ bị người dùng di chuyển
  // trong lúc đang nghe (`_khiGiaTriKhungNhapDoi` chủ động cắt phiên để
  // ép một phiên mới), hay trình duyệt tự khởi động lại phiên sau khoảng
  // lặng.
  int _neoChenMic = 0;

  // Độ dài (số ký tự) của một VÙNG ĐANG CHỌN cần bị THAY THẾ bởi lần chốt
  // chữ ĐẦU TIÊN của phiên nghe kế tiếp — y hệt tinh thần `_chuTam` được
  // gán từ vùng chọn trong `_datNeoTaiConTro()` bên app chính: chọn một
  // vùng rồi nói tiếp thì giọng nói ĐÈ LÊN đúng vùng đó, giống hệt gõ tay
  // đè lên vùng đang chọn. Đặt cùng lúc với `_neoChenMic` (xem `_batNghe`),
  // tiêu thụ (đưa về 0) ngay khi có chữ THẬT đầu tiên để chèn — xem
  // `_apDungXoaVungChonMicNeuCo`. Cố tình KHÔNG xoá vùng chọn ngay lúc bật
  // micro: nếu người dùng bật rồi tắt luôn mà chưa nói được chữ nào, vùng
  // chọn phải còn nguyên, không bị xoá oan.
  int _doDaiVungDeDeMic = 0;

  Timer? _henBatLai;

  // ---- Ghi âm thô + nghe lại — TÁCH BIỆT HOÀN TOÀN khỏi Web Speech API ở
  // trên. Dùng MediaRecorder chuẩn của trình duyệt (ghi ra file âm thanh,
  // không nhận dạng chữ gì cả) — vì trên iPhone (Safari/Chrome đều chung
  // WebKit) Web Speech API không hoạt động được kể cả khi bấm tay từng lần
  // (xem log thực tế: "onError: aborted" ngay lập tức bất kể tự động hay
  // bấm tay). Mục đích: kiểm chứng máy CÓ ghi được âm thanh hay không, để
  // sau này nếu ổn thì gửi file ghi được cho một AI khác (vd Gemini) nghe
  // và chuyển thành chữ — đường vòng khi trình duyệt tự nhận dạng không ăn
  // thua trên iOS.
  html.MediaStream? _luongGhiAm; // tái sử dụng qua NHIỀU thẻ liên tiếp.
  html.MediaRecorder? _boGhiAm; // recorder của thẻ ĐANG ghi hiện tại.
  bool _dangGhiAm = false;

  // ---- Ghi âm NHIỀU LẦN, chèn thành "thẻ" giữa các đoạn gõ tay (dành riêng
  // cho iPhone, nơi Web Speech API không hoạt động). Mỗi lần dừng ghi âm,
  // một token văn bản dạng "〔🎙️ Ghi âm N〕" được chèn vào đúng vị trí con
  // trỏ trong khung nhập — ĐÂY LÀ TOKEN VĂN BẢN THUẦN TUÝ, không phải ô
  // chip đồ hoạ thật, vì TextField của Flutter không hỗ trợ chèn widget vào
  // giữa văn bản có thể sửa. Khi bấm "Tạo văn bản", từng thẻ được thay bằng
  // đúng chữ Gemini phiên âm được từ file ghi âm tương ứng.
  int _soThuTuGhiAmTiepTheo = 1;
  final Map<int, html.Blob> _cacDoanGhiAmTheoThe = {};
  bool _dangTaoVanBan = false;
  // Định dạng thẻ hoàn chỉnh giờ có kèm thời lượng: "〔Ghi âm N 🎙️ mm:ss〕" —
  // nhóm bắt (1) là số thẻ, phần thời lượng chỉ để NGƯỜI xem, không cần bắt
  // riêng (khớp lỏng bằng \d+:\d+).
  static final RegExp _reTheGhiAm = RegExp('〔Ghi âm (\\d+) 🎙️ \\d+:\\d+〕');

  // Thời lượng ghi âm THẬT của từng thẻ ĐÃ chốt (số thẻ → thời lượng) — cần
  // để: (1) in vào nhãn thẻ "〔Ghi âm N 🎙️ mm:ss〕", (2) tính tổng thời
  // lượng các thẻ chưa gửi cho chế độ tự động gửi ngầm (xem
  // `_kiemTraVaGuiNgamNeuDu`).
  final Map<int, Duration> _thoiLuongTheoThe = {};

  // ---- Chế độ tự động gửi ngầm các thẻ đã ghi xong trong lúc ghi thẻ mới
  // (nút bật/tắt riêng, mặc định TẮT). Điều kiện kích hoạt: có ≥1 thẻ đã
  // ghi xong CHƯA gửi, và TỔNG thời lượng các thẻ đó ≥
  // `_nguongTongThoiLuongTuDongGui` — đủ ngữ cảnh để Gemini phiên âm tốt
  // hơn một đoạn quá ngắn. Nút "Tạo văn bản" thủ công vẫn giữ nguyên, dùng
  // cho các thẻ chưa đủ ngưỡng hoặc muốn chuyển ngay. Thẻ nào đang được
  // gửi (thủ công hoặc tự động) được đánh dấu trong `_theDangDuocGui` để
  // hai đường không gửi trùng nhau. Gemini lỗi ở một thẻ đang gửi ngầm thì
  // ÂM THẦM để đó, lần kiểm tra sau sẽ tự thử lại — không báo lỗi ồn ào.
  bool _tuDongGuiNgam = true;
  static const _nguongTongThoiLuongTuDongGui = Duration(seconds: 20);
  final Set<int> _theDangDuocGui = {};

  // ---- Đếm giờ hiển thị lúc đang ghi thẻ — hiển thị NGOÀI khung nhập (ở
  // hàng trạng thái), không nhét vào trong nội dung văn bản: TextField
  // không hỗ trợ widget sống động chèn giữa chữ có thể sửa, và việc tự động
  // ghi đè chữ mỗi giây vào đúng lúc người dùng có thể đang gõ tay ở chỗ
  // khác sẽ phá vỡ nguyên tắc gõ-phím-thắng-micro. Token trong văn bản vẫn
  // chỉ là placeholder tĩnh, chèn một lần duy nhất lúc BẮT ĐẦU ghi (xem
  // `_chenTheDangGhiVaoVanBan`), rồi được thay bằng "Thẻ ghi âm số N" khi
  // dừng.
  Timer? _bomDongHoGhiAm;

  // Bơm vẽ lại khung nhập liên tục trong lúc còn đoạn chữ Gemini đang nhấp
  // nháy (xem `_BoDieuKhienVanBanCoThe.doanVuaNhanDuoc`) — tự dừng khi danh
  // sách đó rỗng, không chạy vô ích lúc không có gì đang nhấp nháy.
  Timer? _bomNhapNhay;

  // Tự lưu văn bản đang soạn vào localStorage của trình duyệt — sống sót qua
  // F5 và hoạt động cả khi mất mạng (localStorage không cần mạng). Ghi có
  // dồn (debounce) 500ms để không ghi liên tục theo từng ký tự lúc micro
  // đang tuôn chữ. Khôi phục lúc mở trang, TRƯỚC khi `_khoiTao()` bật micro,
  // để người dùng thấy ngay tài liệu cũ mà không bị micro ghi đè lên.
  static const _khoaLuuVanBan = 'flowrite_van_ban_dang_soan';
  Timer? _bomLuuVanBan;
  Duration _thoiLuongDangGhi = Duration.zero;
  int? _viTriTokenDangGhi; // vị trí ký tự bắt đầu của token đang ghi dở.

  // Số thẻ đã DÀNH SẴN cho lần ghi đang chạy — gán NGAY lúc bắt đầu ghi
  // (không đợi tới lúc dữ liệu âm thanh sẵn sàng ở sự kiện 'stop', vốn bất
  // đồng bộ), để việc CHỐT thẻ (do bấm dừng tay, hoặc do gõ phím giữa
  // chừng) có thể đổi ngay token hiển thị trong văn bản mà không phải chờ.
  int? _soTheDangGhiHienTai;
  static const String _tenTokenDangGhi = '〔🎙️ … đang ghi âm …〕';

  // ---- Giới hạn 5 phút MỖI thẻ ghi âm — tự động chốt thẻ đang ghi và bắt
  // đầu thẻ mới (đếm lại từ 0) nếu chạm mốc, để tránh một thẻ ghi âm dài vô
  // hạn khiến việc gửi Gemini sau này chậm/tốn. Cảnh báo trước ở phút 4:30
  // bằng hộp thoại giữa màn hình, cho người dùng chủ động chọn "Tạo bản ghi
  // âm mới" (chốt + ghi tiếp ngay) hoặc "Dừng và không ghi âm nữa" (chốt +
  // dừng hẳn) — nếu không chọn gì, tới đúng phút thứ 5 tự động xử lý y hệt
  // như bấm "Tạo bản ghi âm mới".
  static const _gioiHanThoiLuongMoiThe = Duration(minutes: 5);
  static const _moTaCanhBaoGioiHan = Duration(minutes: 4, seconds: 30);
  bool _daCanhBaoGioiHanChoThe = false;
  bool _hopThoaiCanhBaoDangMo = false;

  // Đếm số lần lỗi liên tiếp KHÔNG kèm bất kỳ chữ nào (không có partial nào
  // trước khi lỗi) — dấu hiệu bộ nhận dạng bị chặn ngay từ đầu chứ không
  // phải lỗi tạm thời giữa chừng. Thấy thật trên iPhone (Safari/WebKit):
  // liên tục "onError: aborted" ngay sau "onStatus: listening", lặp hàng
  // chục lần một giây — nhiều khả năng do WebKit trên iOS đòi hỏi mỗi lần
  // bắt đầu nhận dạng phải xuất phát trực tiếp từ một cử chỉ bấm tay của
  // người dùng (không cho tự động bật lại bằng Timer như Android/PC vẫn
  // làm được). Dừng vòng lặp lại càng sớm càng tốt để khỏi xả pin/CPU vô
  // ích và báo rõ cho người dùng biết thay vì im lặng treo.
  int _soLanLoiLienTiepKhongChu = 0;
  static const _nguongDungTuBatLai = 4;

  @override
  void initState() {
    super.initState();
    _thietBi = _doanThietBi();
    _ghiLog('Phiên bản bản thử: $_phienBanThuNghiem');
    _ghiLog('Đoán thiết bị: ${_tenThietBi(_thietBi)} '
        '(User-Agent: ${html.window.navigator.userAgent})');
    // Lắng nghe MỌI thay đổi của khung nhập (kể cả chỉ đổi vùng chọn/con
    // trỏ, không đổi chữ) — `TextField.onChanged` CHỈ bắn khi chữ đổi, nên
    // không đủ để bắt lúc người dùng chỉ di chuyển con trỏ. Xem
    // `_khiGiaTriKhungNhapDoi`.
    _boDieuKhienVanBan.addListener(_khiGiaTriKhungNhapDoi);
    _khoiPhucVanBanDaLuu();
    _khoiTao();
  }

  void _ghiLog(String dong) {
    final gio = DateTime.now();
    String hai(int n) => n.toString().padLeft(2, '0');
    final gioChuoi = '${hai(gio.hour)}:${hai(gio.minute)}:${hai(gio.second)}';
    if (!mounted) {
      _nhatKy.add('[$gioChuoi] $dong');
      return;
    }
    setState(() {
      _nhatKy.add('[$gioChuoi] $dong');
      if (_nhatKy.length > 300) _nhatKy.removeAt(0);
    });
    // Cuộn xuống dòng mới nhất sau khi khung vẽ lại.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cuonNhatKy.hasClients) {
        _cuonNhatKy.jumpTo(_cuonNhatKy.position.maxScrollExtent);
      }
    });
  }

  Future<void> _khoiTao() async {
    final duoc = await _micro.initialize(
      onStatus: _khiDoiTrangThai,
      onError: _khiCoLoi,
      debugLogging: false,
    );
    if (!mounted) return;
    setState(() {
      _sanSang = duoc;
      if (!duoc) {
        _loi = 'Trình duyệt không cấp được quyền micro/không hỗ trợ '
            'Web Speech API. Thử Chrome hoặc Edge, và bật quyền micro cho '
            'trang này.';
      }
    });
    _ghiLog('Khởi tạo micro: ${duoc ? "được" : "THẤT BẠI"}');
  }

  void _khiCoLoi(dynamic loi) {
    // Trên web, một lượt bộ nhận dạng tự ngắt vì im lặng cũng có thể bắn ra
    // qua onError tuỳ trình duyệt — coi các mã "nhẹ" như bên Android, không
    // làm phiền, cứ tự bật lại.
    final maLoi = loi.errorMsg as String? ?? '';
    final nhe = maLoi == 'error_no_match' ||
        maLoi == 'error_speech_timeout' ||
        maLoi == 'error_client' ||
        maLoi == 'error_busy';
    _ghiLog('onError: $maLoi ${nhe ? "(nhẹ, tự bật lại)" : "(HIỂN THỊ ĐỎ)"}');
    if (!nhe && mounted) {
      setState(() => _loi = 'Lỗi: $maLoi');
    }

    _soLanLoiLienTiepKhongChu++;
    if (_soLanLoiLienTiepKhongChu >= _nguongDungTuBatLai) {
      // Đã thử tự bật lại nhiều lần liên tiếp mà lần nào cũng lỗi ngay lập
      // tức, không có lấy một chữ nào — dừng hẳn vòng lặp, không đoán mò
      // thêm nữa, để người dùng biết mà tự bấm lại bằng tay.
      _ghiLog('Lỗi liên tiếp $_soLanLoiLienTiepKhongChu lần không kèm chữ '
          'nào — dừng tự bật lại micro. Có thể ${_tenThietBi(_thietBi)} '
          'không cho tự động bật micro mà cần người dùng tự bấm nút mỗi '
          'lần.');
      _henBatLai?.cancel();
      _muonNghe = false;
      if (mounted) {
        setState(() {
          _dangNghe = false;
          _loi = 'Micro liên tục bị lỗi "$maLoi" ngay khi vừa bật, không '
              'nói được câu nào. Có thể trình duyệt này không cho tự động '
              'bật lại micro — hãy bấm nút micro lại bằng tay sau mỗi câu.';
        });
      }
      return;
    }
    _henNgheLai();
  }

  void _khiDoiTrangThai(String trangThai) {
    _ghiLog('onStatus: $trangThai');
    final dangChay = trangThai == SpeechToText.listeningStatus;
    if (mounted && _dangNghe != dangChay) {
      setState(() => _dangNghe = dangChay);
    }
    if (!dangChay) {
      // Phiên vừa chết (trình duyệt tự dừng do im lặng, hoặc do web speech
      // API không hỗ trợ nghe liên tục dài như Android) — tăng số phiên NGAY,
      // đồng bộ, để mọi kết quả trễ của phiên cũ bị vứt (LỚP 1).
      _phienHienTai++;
      _henNgheLai();
    }
  }

  /// Văn bản lần gần nhất listener này thấy — để phân biệt "chữ vừa đổi"
  /// (việc khác đã lo, bỏ qua ở đây) với "chỉ vùng chọn/con trỏ đổi" (việc
  /// CHÍNH của hàm này).
  String _vanBanChoTheoDoiConTro = '';

  /// Bắt MỌI thay đổi của khung nhập, kể cả chỉ đổi vị trí con trỏ (không
  /// đổi chữ) — `TextField.onChanged` không bắt được ca này.
  ///
  /// Y HỆT tinh thần `_dongBangDoanDangNhay()` bên app chính
  /// (`trang_soan_thao.dart`): người dùng tự tay di chuyển con trỏ trong
  /// lúc micro đang nghe (dù đang nói liên tục hay không) → CẮT NGAY phiên
  /// nghe hiện tại và nghe lại ngay tại vị trí mới — không đợi phiên tự
  /// ngắt. KHÔNG chỉ đơn giản dời neo (`_neoChenMic`) tại chỗ mà giữ
  /// nguyên phiên nghe cũ chạy tiếp: hypothesis (`noi`) của Web Speech API
  /// là hypothesis TÍCH LUỸ của CẢ PHIÊN, không phải chỉ phần mới — nếu
  /// phiên cũ vẫn tiếp tục chạy mà neo đã đổi giữa chừng, lần kết quả kế
  /// tiếp sẽ hiểu nhầm toàn bộ hypothesis tích luỹ là "chữ mới toanh" và
  /// chèn NHÂN ĐÔI cả những từ đã hiện ra trước đó. Cắt hẳn phiên (như
  /// Android làm bằng `_micro.stop()`/`cancel()`) đảm bảo phiên MỚI luôn
  /// bắt đầu với hypothesis rỗng, tránh hẳn nguy cơ đó.
  Future<void> _khiGiaTriKhungNhapDoi() async {
    final gt = _boDieuKhienVanBan.value;
    if (gt.text != _vanBanChoTheoDoiConTro) {
      _vanBanChoTheoDoiConTro = gt.text;
      _luuVanBanVaoBoNhoTrinhDuyet();
      return; // Đổi CHỮ — đã có `_khiNguoiDungGoPhim` và các hàm ghi của
      // micro/thẻ ghi âm tự lo phần của chúng, không việc gì của hàm này.
    }
    final chon = gt.selection;
    if (!chon.isValid || chon.start < 0 || chon.end > gt.text.length) {
      return; // vùng chọn không hợp lệ.
    }
    final laVungChon = !chon.isCollapsed;
    final viTri = chon.isCollapsed ? chon.baseOffset : chon.start;
    // Chỉ bỏ qua khi con trỏ vẫn ở đúng chỗ cũ VÀ không phải một vùng chọn
    // mới (một vùng chọn luôn cần xử lý riêng — "đè lên vùng chọn" — dù vô
    // tình bắt đầu đúng tại neo cũ).
    if (viTri == _neoChenMic && !laVungChon) return;
    if (!_muonNghe || !_micro.isListening) return; // micro không đang nghe.

    _ghiLog('${laVungChon ? "Người dùng chọn một vùng" : "Con trỏ di chuyển tới $viTri"} '
        'trong lúc micro đang nghe — cắt phiên hiện tại, nghe lại ngay tại '
        'vị trí mới (không đợi phiên tự ngắt), tránh nhân đôi chữ do '
        'hypothesis tích luỹ của phiên cũ.');
    _phienHienTai++; // huỷ callback trễ của phiên đang cắt (LỚP 1).
    await _micro.cancel();
    _henNgheLai();
  }

  /// Y hệt `_henBatLai()` bên app chính: nếu người dùng vẫn đang muốn nghe mà
  /// phiên vừa tự ngắt (đặc điểm hay gặp trên web — Web Speech API không giữ
  /// phiên mở liên tục như Android), tự bật lại ngay để trải nghiệm như micro
  /// luôn bật.
  void _henNgheLai() {
    if (!_muonNghe) return;
    _henBatLai?.cancel();
    // Điện thoại (Android/iPhone) có xu hướng tự ngắt phiên dày hơn PC — bật
    // lại nhanh hơn một chút để đỡ hụt tiếng nói giữa hai phiên.
    final treDoiChoDo = Duration(
      milliseconds: _thietBi == ThietBi.pc ? 300 : 150,
    );
    _henBatLai = Timer(treDoiChoDo, () {
      if (_muonNghe && !_micro.isListening) _batNghe();
    });
  }

  Future<void> _batNghe() async {
    if (!_sanSang) return;

    // Dời neo chèn chữ tới ĐÚNG vị trí con trỏ hiện tại — NHƯNG chỉ khi nó
    // thật sự đổi so với neo cũ, để không phá vỡ cơ chế nối-liền-mạch giữa
    // các phiên nghe kế tiếp nhau khi con trỏ KHÔNG hề bị người dùng động
    // tới (chữ do chính micro ghi luôn tự dịch con trỏ theo neo, nên neo
    // không đổi giữa hai phiên liên tiếp nếu người dùng không tự tay di
    // chuyển con trỏ ở giữa). Khi neo đổi, `_tuDaChot` (đại diện cho phần
    // "đã chốt" NGAY TRƯỚC neo, dùng để dò trùng lặp với hypothesis phiên
    // mới) phải tính lại theo đúng vị trí neo MỚI, không thì thuật toán dò
    // điểm nối sẽ so khớp nhầm với đoạn văn bản không liên quan nằm trước
    // vị trí neo cũ.
    final vanBanHienTai = _boDieuKhienVanBan.text;
    final chonHienTai = _boDieuKhienVanBan.selection;
    var neoMoi = vanBanHienTai.length;
    var doDaiVungMoi = 0;
    if (chonHienTai.isValid) {
      if (!chonHienTai.isCollapsed) {
        // Đang CHỌN một vùng (tô đậm) — giọng nói tiếp theo sẽ ĐÈ LÊN đúng
        // vùng đó, y hệt tinh thần `_datNeoTaiConTro()` bên app Android:
        // neo đặt ở ĐẦU vùng, và nhớ luôn độ dài vùng để lần chốt chữ ĐẦU
        // TIÊN của phiên này thay thế nó (xem `_apDungXoaVungChonMicNeuCo`).
        neoMoi = chonHienTai.start;
        doDaiVungMoi = chonHienTai.end - chonHienTai.start;
      } else {
        neoMoi = chonHienTai.end;
      }
    }
    if (neoMoi < 0 || neoMoi > vanBanHienTai.length) neoMoi = vanBanHienTai.length;
    if (neoMoi != _neoChenMic || doDaiVungMoi > 0) {
      _ghiLog('Vị trí chèn chữ mic đổi từ $_neoChenMic sang $neoMoi (con '
          'trỏ đã được di chuyển${doDaiVungMoi > 0 ? ", đang chọn $doDaiVungMoi ký tự để đè lên" : ""}) '
          '— tính lại phần "đã chốt" ngay trước vị trí mới.');
      _neoChenMic = neoMoi;
      _doDaiVungDeDeMic = doDaiVungMoi;
      _tuDaChot = _tachTu(vanBanHienTai.substring(0, _neoChenMic));
      _partialTruocDo = [];
    }

    final idPhien = ++_phienHienTai;
    _rawTruocDoTrongPhien = '';
    _ghiLog('Bắt đầu phiên nghe #$idPhien (${_tenThietBi(_thietBi)}), neo '
        'chèn chữ tại vị trí $_neoChenMic.');
    try {
      await _micro.listen(
        onResult: (ketQua) {
          if (idPhien != _phienHienTai) {
            _ghiLog('Bỏ callback trễ của phiên cũ #$idPhien '
                '(phiên hiện tại là #$_phienHienTai)');
            return;
          }
          _khiCoKetQua(ketQua);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
        // Web Speech API không đảm bảo tôn trọng listenFor/pauseFor giống
        // Android (một số trình duyệt tự ngắt sớm hơn) — cứ khai để không
        // khác app chính, nhưng thiết kế phải chịu được việc trình duyệt
        // ngắt bất cứ lúc nào (_henNgheLai phía trên lo việc đó).
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 8),
      );
    } catch (loi) {
      _ghiLog('listen() ném lỗi: $loi');
      _henNgheLai();
    }
  }

  Future<void> _tatNghe() async {
    _phienHienTai++; // Phiên hiện tại coi như chết ngay (LỚP 1).
    _muonNghe = false;
    _henBatLai?.cancel();
    await _micro.cancel();
    if (mounted) setState(() => _dangNghe = false);
    _ghiLog('Người dùng tắt micro.');
  }

  void _bamNutMicro() {
    // Trên iPhone, Web Speech API không hoạt động kể cả bấm tay (xem log
    // "onError: aborted" lặp lại) — nút micro chính vì thế chuyển hẳn sang
    // cơ chế ghi-âm-rồi-gửi-Gemini (đúng nút "ghi âm" bên dưới), để người
    // dùng iPhone không cần biết có hai nút khác nhau.
    if (_thietBi == ThietBi.iphone) {
      _bamNutGhiAm();
      return;
    }
    if (_muonNghe) {
      _tatNghe();
    } else {
      _soLanLoiLienTiepKhongChu = 0; // người dùng tự bấm — cho thử lại từ đầu.
      setState(() {
        _muonNghe = true;
        _loi = '';
      });
      _batNghe();
    }
  }

  // ------------------------------------------------ ghi âm thô theo thẻ

  Future<void> _bamNutGhiAm() async {
    if (_dangGhiAm) {
      _dungHanGhiAm();
      return;
    }
    // Tắt hẳn vòng Web Speech API trước khi ghi âm thô — hai bên cùng
    // tranh giành một microphone có thể làm hỏng/im tiếng bản ghi. Ghi âm
    // thử cần độc chiếm mic để kết quả đáng tin.
    _henBatLai?.cancel();
    _henMoLaiMicroSauKhiGo?.cancel();
    _muonNghe = false;
    await _micro.cancel();
    if (mounted) setState(() => _dangNghe = false);

    final thietBiMedia = html.window.navigator.mediaDevices;
    if (thietBiMedia == null) {
      _ghiLog('Trình duyệt không hỗ trợ getUserMedia (ghi âm).');
      setState(() => _loi = 'Trình duyệt này không hỗ trợ ghi âm.');
      return;
    }
    try {
      _luongGhiAm = await thietBiMedia.getUserMedia({'audio': true});
      setState(() {
        _dangGhiAm = true;
        _loi = '';
      });
      _batDauMotThe();
      _ghiLog('Bắt đầu ghi âm thử (không qua Web Speech API).');
    } catch (e) {
      _ghiLog('Lỗi khi xin quyền/ghi âm: $e');
      if (mounted) setState(() => _loi = 'Không ghi âm được: $e');
    }
  }

  /// "mm:ss" — dùng cho cả đồng hồ đang ghi và nhãn thẻ đã chốt.
  static String _dinhDangMmSs(Duration d) {
    String hai(int n) => n.toString().padLeft(2, '0');
    return '${hai(d.inMinutes)}:${hai(d.inSeconds % 60)}';
  }

  /// Nhãn hiển thị đầy đủ của thẻ #[soThe] theo ĐÚNG thời lượng đã lưu
  /// trong `_thoiLuongTheoThe` (mặc định 0 nếu vì lý do gì đó chưa có).
  String _nhanTheHoanChinh(int soThe) =>
      '〔Ghi âm $soThe 🎙️ ${_dinhDangMmSs(_thoiLuongTheoThe[soThe] ?? Duration.zero)}〕';

  /// Chốt thời lượng hiện tại (`_thoiLuongDangGhi`) làm thời lượng CHÍNH
  /// THỨC của thẻ #[soThe] rồi trả về nhãn hiển thị đầy đủ — gọi ĐÚNG MỘT
  /// LẦN mỗi khi một thẻ được chốt (trước khi `_taoBoGhiAmMoi` reset lại
  /// `_thoiLuongDangGhi` cho thẻ tiếp theo).
  String _chotThoiLuongVaLayNhanThe(int soThe) {
    _thoiLuongTheoThe[soThe] = _thoiLuongDangGhi;
    return _nhanTheHoanChinh(soThe);
  }

  /// Đánh dấu [batDau, ketThuc) trong khung nhập là chữ Gemini VỪA trả về
  /// (nhấp nháy 4 giây) rồi bắt đầu bơm vẽ lại liên tục cho tới khi hết
  /// hiệu ứng — gọi ngay sau mỗi lần thay một thẻ bằng chữ Gemini (cả
  /// đường thủ công lẫn đường gửi ngầm).
  void _danhDauVuaNhanTuGeminiVaNhapNhay(int batDau, int ketThuc) {
    _boDieuKhienVanBan.danhDauVuaNhanDuoc(batDau, ketThuc);
    _bomNhapNhay?.cancel();
    _bomNhapNhay = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!mounted || _boDieuKhienVanBan.doanVuaNhanDuoc.isEmpty) {
        t.cancel();
        return;
      }
      setState(() {}); // chỉ để vẽ lại — buildTextSpan tự tính màu theo giờ.
    });
  }

  /// Ghi văn bản hiện tại vào localStorage, có dồn 500ms — gọi mỗi khi chữ
  /// đổi (xem `_khiGiaTriKhungNhapDoi`). Bọc try/catch vì localStorage có
  /// thể bị trình duyệt chặn (chế độ ẩn danh, đầy dung lượng...) — mất tính
  /// năng tự lưu không nên làm sập cả ứng dụng.
  void _luuVanBanVaoBoNhoTrinhDuyet() {
    _bomLuuVanBan?.cancel();
    _bomLuuVanBan = Timer(const Duration(milliseconds: 500), () {
      try {
        html.window.localStorage[_khoaLuuVanBan] = _boDieuKhienVanBan.text;
      } catch (e) {
        _ghiLog('Không lưu được văn bản vào bộ nhớ trình duyệt: $e');
      }
    });
  }

  /// Khôi phục văn bản đã lưu (nếu có) lúc mở trang — gọi trong `initState`,
  /// TRƯỚC khi `_khoiTao()` bật micro.
  void _khoiPhucVanBanDaLuu() {
    try {
      final daLuu = html.window.localStorage[_khoaLuuVanBan];
      if (daLuu == null || daLuu.isEmpty) return;
      _vanBanDaChot = daLuu;
      _tuDaChot = _tachTu(daLuu);
      _boDieuKhienVanBan.value = TextEditingValue(
        text: daLuu,
        selection: TextSelection.collapsed(offset: daLuu.length),
      );
      _vanBanChoTheoDoiConTro = daLuu;
      _ghiLog('Đã khôi phục văn bản đang soạn dở từ lần trước '
          '(${daLuu.length} ký tự).');
    } catch (e) {
      _ghiLog('Không khôi phục được văn bản đã lưu: $e');
    }
  }

  /// Bắt đầu MỘT PHIÊN `MediaRecorder` mới trên `_luongGhiAm` đã xin quyền
  /// sẵn — dùng cả lúc bấm nút ghi lần đầu VÀ lúc tách thẻ giữa chừng do gõ
  /// tay (xem `_chotTheDoGoTayVaBatDauTheMoi`). Số thẻ được DÀNH SẴN ngay
  /// tại đây, KHÔNG đợi tới lúc dữ liệu âm thanh sẵn sàng (sự kiện 'stop'
  /// bất đồng bộ) — nhờ vậy lúc cần chốt thẻ có thể đổi ngay token hiển thị
  /// mà không phải chờ, tránh đúng lỗi "token rác" đã gặp trước đây.
  void _batDauMotThe() {
    _taoBoGhiAmMoi();
    _chenTokenDangGhiVaoVanBan();
  }

  /// Phần LÕI của `_batDauMotThe` — chỉ tạo `MediaRecorder` mới và dành sẵn
  /// số thẻ, KHÔNG động gì tới văn bản. Tách riêng để dùng trong
  /// `_chotTheDoGoTayVaBatDauTheMoi`, nơi việc chèn token mới phải nằm
  /// CHUNG một lượt cập nhật văn bản DUY NHẤT với việc chốt token cũ (xem
  /// chú thích ở đó) — gọi `_chenTokenDangGhiVaoVanBan` riêng ở đây sẽ tạo
  /// thêm một lượt `.value=`/`onChanged` thứ hai, đúng nguyên nhân gây lỗi
  /// "phải gõ hai ký tự mới tách thẻ" đã gặp.
  void _taoBoGhiAmMoi() {
    final luong = _luongGhiAm;
    if (luong == null) return;
    // Safari/WebKit KHÔNG hỗ trợ 'audio/webm' (mặc định của Chrome) — nếu
    // ép ghi/gói bằng webm trên Safari, trình duyệt vẫn "ghi" được (không
    // báo lỗi) nhưng dữ liệu thực chất ở định dạng khác, khiến thẻ <audio>
    // không giải mã nổi và IM LẶNG không báo lỗi gì. Dò định dạng trình
    // duyệt THỰC SỰ hỗ trợ trước khi ghi.
    const cacDinhDangUuTien = [
      'audio/mp4',
      'audio/webm',
      'audio/ogg',
      'audio/wav',
    ];
    String? dinhDangDung;
    for (final dd in cacDinhDangUuTien) {
      if (html.MediaRecorder.isTypeSupported(dd)) {
        dinhDangDung = dd;
        break;
      }
    }
    final boGhi = dinhDangDung == null
        ? html.MediaRecorder(luong)
        : html.MediaRecorder(luong, {'mimeType': dinhDangDung});
    final soThe = _soThuTuGhiAmTiepTheo++;
    final doanGhi = <html.Blob>[];
    _boGhiAm = boGhi;
    _soTheDangGhiHienTai = soThe;
    boGhi.addEventListener('dataavailable', (suKien) {
      final doan = (suKien as html.BlobEvent).data;
      if (doan != null && doan.size > 0) doanGhi.add(doan);
    });
    // Listener này CHỈ lưu blob vào đúng số thẻ đã dành sẵn — KHÔNG động gì
    // tới văn bản nữa, vì token hiển thị đã được đổi thành "Ghi âm N" NGAY
    // LÚC CHỐT (đồng bộ, xem `_dungHanGhiAm`/`_chotTheDoGoTayVaBatDauTheMoi`)
    // chứ không đợi tới đây — sự kiện 'stop' luôn tới SAU (bất đồng bộ),
    // nên nếu vẫn còn động vào văn bản ở đây sẽ chèn sai vị trí (đúng lỗi
    // "token rác"/"chèn thẻ lộn xộn" đã gặp trước đây).
    boGhi.addEventListener('stop', (_) {
      final loaiThuc = boGhi.mimeType;
      final blob = html.Blob(doanGhi,
          (loaiThuc == null || loaiThuc.isEmpty) ? 'audio/mp4' : loaiThuc);
      _cacDoanGhiAmTheoThe[soThe] = blob;
      _ghiLog('Thẻ #$soThe: ghi xong (${doanGhi.length} đoạn dữ liệu).');
    });
    boGhi.start();
    _ghiLog('MediaRecorder.mimeType thực tế: "${boGhi.mimeType}" (thẻ #$soThe).');
    _thoiLuongDangGhi = Duration.zero;
    _daCanhBaoGioiHanChoThe = false;
    _bomDongHoGhiAm?.cancel();
    _bomDongHoGhiAm = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _thoiLuongDangGhi += const Duration(seconds: 1));
      if (_thoiLuongDangGhi >= _gioiHanThoiLuongMoiThe) {
        _dongHopThoaiCanhBaoNeuMo();
        _chotTheVaBatDauTheMoiDoQuaGioiHan();
      } else if (_thoiLuongDangGhi >= _moTaCanhBaoGioiHan) {
        _hienCanhBaoGioiHanNeuChua();
      }
    });
  }

  void _dongHopThoaiCanhBaoNeuMo() {
    if (_hopThoaiCanhBaoDangMo && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Hộp thoại cảnh báo giữa màn hình, hiện ĐÚNG MỘT LẦN mỗi thẻ khi chạm
  /// mốc 4 phút 30 giây — cho người dùng chủ động chọn trước khi bị tự
  /// động xử lý ở đúng phút thứ 5 (`_chotTheVaBatDauTheMoiDoQuaGioiHan`).
  void _hienCanhBaoGioiHanNeuChua() {
    if (_daCanhBaoGioiHanChoThe || !mounted) return;
    _daCanhBaoGioiHanChoThe = true;
    _hopThoaiCanhBaoDangMo = true;
    final soThe = _soTheDangGhiHienTai;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sắp chạm giới hạn 5 phút'),
        content: Text('Thẻ ghi âm #$soThe sắp ghi đủ 5 phút. Nếu không chọn, '
            'tới đúng phút thứ 5 nó sẽ tự động chốt và ghi tiếp bằng một '
            'thẻ mới. Bạn muốn làm gì bây giờ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chotTheVaBatDauTheMoiDoQuaGioiHan();
            },
            child: const Text('Tạo bản ghi âm mới'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dungHanGhiAm();
            },
            child: const Text('Dừng và không ghi âm nữa'),
          ),
        ],
      ),
    ).then((_) => _hopThoaiCanhBaoDangMo = false);
  }

  /// Thẻ đang ghi chạm giới hạn thời lượng (5 phút) — CHỐT ngay thành thẻ
  /// hoàn chỉnh và BẮT ĐẦU một thẻ MỚI ngay lập tức (đếm lại từ 0), ghi âm
  /// tiếp tục liền mạch. Dùng khi người dùng chủ động bấm "Tạo bản ghi âm
  /// mới" ở hộp thoại cảnh báo, HOẶC tự động khi không ai chọn gì tới đúng
  /// phút thứ 5.
  void _chotTheVaBatDauTheMoiDoQuaGioiHan() {
    if (!_dangGhiAm) return;
    final soThe = _soTheDangGhiHienTai;
    _ghiLog('Thẻ #$soThe chạm giới hạn ${_dinhDangMmSs(_gioiHanThoiLuongMoiThe)} '
        '— tự động chốt, bắt đầu thẻ mới ghi tiếp.');
    if (soThe != null) _chenTheGhiAmVaoVanBan(soThe);
    _boGhiAm?.stop();
    _batDauMotThe();
  }

  /// Ghi [vanBanMoi] vào khung nhập VÀ chốt cứng nó ngay tại đây — dùng cho
  /// MỌI chỉnh sửa văn bản do CHÍNH CODE (không phải người dùng) thực hiện
  /// xoay quanh cơ chế thẻ ghi âm (chèn/thay/xoá token).
  ///
  /// QUAN TRỌNG: gán `TextEditingController.value =` theo cách lập trình
  /// KHÔNG khiến `TextField.onChanged` (do đó `_khiNguoiDungGoPhim`) tự
  /// chạy — khác với suy đoán ban đầu ở các bản trước. Bằng chứng thực tế
  /// (log v21): token "đang ghi âm" được chèn lúc 17:30:13, nhưng dòng log
  /// đáng lẽ phải in ra NGAY SAU đó (nếu `onChanged` chạy lại) chỉ thực sự
  /// xuất hiện lúc 17:30:17 — đúng thời điểm người dùng gõ phím THẬT tiếp
  /// theo. Nghĩa là `onChanged` không hề chạy lại cho lần gán `.value=` đó;
  /// cờ "bỏ qua một lần" ở các bản trước vì vậy nằm chờ mãi và vô tình NUỐT
  /// MẤT đúng lượt gõ phím thật kế tiếp — đó là lý do phải gõ hai lần mới
  /// thấy thẻ tách ra. Sửa bằng cách bỏ hẳn cơ chế cờ, và tự chốt cứng
  /// trạng thái NGAY TẠI ĐÂY thay vì trông chờ một `onChanged` không tồn
  /// tại.
  void _ghiVanBanChoTheVaChotCung(String vanBanMoi, TextSelection luaChonMoi) {
    _boDieuKhienVanBan.value =
        TextEditingValue(text: vanBanMoi, selection: luaChonMoi);
    _vanBan = vanBanMoi;
    _vanBanDaChot = vanBanMoi;
    _tuDaChot = _tachTu(vanBanMoi);
    _partialTruocDo = [];
    _rawTruocDoTrongPhien = '';
  }

  /// Chèn token tĩnh "đang ghi âm" tại vị trí con trỏ HIỆN TẠI. Ghi lại vị
  /// trí ký tự để lúc chốt thẻ (dừng tay hoặc gõ phím) thay ĐÚNG token này
  /// bằng "〔Ghi âm N 🎙️ mm:ss〕", không chèn thêm token mới sai chỗ.
  void _chenTokenDangGhiVaoVanBan() {
    final vanBanCu = _boDieuKhienVanBan.text;
    var viTri = _boDieuKhienVanBan.selection.baseOffset;
    if (viTri < 0 || viTri > vanBanCu.length) viTri = vanBanCu.length;
    final vanBanMoi = vanBanCu.replaceRange(viTri, viTri, _tenTokenDangGhi);
    _viTriTokenDangGhi = viTri;
    _ghiVanBanChoTheVaChotCung(
      vanBanMoi,
      TextSelection.collapsed(offset: viTri + _tenTokenDangGhi.length),
    );
    _ghiLog('Chèn token "đang ghi âm" tại vị trí ký tự $viTri (thẻ '
        '#$_soTheDangGhiHienTai).');
  }

  /// Bấm nút dừng bằng tay: CHỐT thẻ đang ghi thành "〔Ghi âm N 🎙️ mm:ss〕" và
  /// dừng HẲN — không ghi tiếp, không có thẻ mới nào được tạo ra.
  void _dungHanGhiAm() {
    final soThe = _soTheDangGhiHienTai;
    _bomDongHoGhiAm?.cancel();
    _bomDongHoGhiAm = null;
    if (soThe != null) _chenTheGhiAmVaoVanBan(soThe);
    _boGhiAm?.stop();
    _boGhiAm = null;
    _soTheDangGhiHienTai = null;
    for (final track in _luongGhiAm?.getTracks() ?? const []) {
      track.stop();
    }
    _luongGhiAm = null;
    if (mounted) setState(() => _dangGhiAm = false);
    _ghiLog('Dừng ghi âm theo yêu cầu — đã chốt thẻ #$soThe.');
  }

  /// Người dùng gõ tay trong lúc thẻ đang ghi dở: đúng nguyên tắc "gõ tay
  /// luôn luôn thắng micro kể cả đang ghi âm", nhưng ở đây "thắng" nghĩa là
  /// CHỐT NGAY thẻ đang ghi thành thẻ hoàn chỉnh tại đúng vị trí cũ (trước
  /// ký tự vừa gõ), rồi bắt đầu một thẻ MỚI ngay sau chỗ vừa gõ để ghi âm
  /// tiếp tục liền mạch — KHÔNG làm mất bản ghi, chỉ tách nó thành hai thẻ.
  /// Dùng lại đúng `_luongGhiAm` đã xin quyền, không xin lại từ đầu.
  ///
  /// [vanBanSauKhiGo] là văn bản NGAY SAU khi ký tự vừa gõ đã được chèn vào
  /// (tham số gốc của `_khiNguoiDungGoPhim`). Toàn bộ việc chốt token cũ +
  /// giữ ký tự vừa gõ + chèn token mới được dựng thành MỘT chuỗi văn bản
  /// DUY NHẤT rồi gán `.value=` ĐÚNG MỘT LẦN, và trạng thái (`_vanBanDaChot`
  /// v.v.) được chốt cứng NGAY TẠI ĐÂY qua `_ghiVanBanChoTheVaChotCung` —
  /// xem chú thích ở hàm đó để biết vì sao KHÔNG được trông chờ một
  /// `onChanged` chạy lại sau khi gán `.value=`.
  void _chotTheDoGoTayVaBatDauTheMoi(String vanBanSauKhiGo) {
    if (!_dangGhiAm) return;
    final soTheCu = _soTheDangGhiHienTai;
    final viTriTokenCu = _viTriTokenDangGhi;
    final viTriConTro = _boDieuKhienVanBan.selection.baseOffset;
    final sauTokenCu = viTriTokenCu == null
        ? null
        : viTriTokenCu + _tenTokenDangGhi.length;

    if (soTheCu == null ||
        viTriTokenCu == null ||
        sauTokenCu == null ||
        sauTokenCu > vanBanSauKhiGo.length ||
        vanBanSauKhiGo.substring(viTriTokenCu, sauTokenCu) !=
            _tenTokenDangGhi ||
        viTriConTro < 0 ||
        viTriConTro < sauTokenCu) {
      // Không rơi đúng vào ca thường gặp (gõ ngay sau/tại vị trí token) —
      // ví dụ người dùng bấm con trỏ ra chỗ khác rồi gõ. Rơi về cách cũ:
      // chốt token cũ tại đúng vị trí lưu, rồi bắt đầu thẻ mới tại vị trí
      // con trỏ hiện tại (hai lượt cập nhật riêng, chấp nhận độ trễ này ở
      // ca hiếm gặp).
      _ghiLog('Người dùng gõ tay trong lúc đang ghi thẻ #$soTheCu, không '
          'phải ngay sau token — dùng đường xử lý chung (hai lượt).');
      if (soTheCu != null) _chenTheGhiAmVaoVanBan(soTheCu);
      _boGhiAm?.stop();
      _batDauMotThe();
      return;
    }

    _ghiLog('Người dùng gõ tay trong lúc đang ghi thẻ #$soTheCu — chốt '
        'ngay thành thẻ hoàn chỉnh, bắt đầu thẻ MỚI tiếp tục ghi ngay sau '
        'chỗ vừa gõ (một lượt cập nhật văn bản duy nhất).');

    final theCu = _chotThoiLuongVaLayNhanThe(soTheCu);
    final truocToken = vanBanSauKhiGo.substring(0, viTriTokenCu);
    // Phần nằm giữa hết token cũ và vị trí con trỏ hiện tại — chính là ký
    // tự (hoặc các ký tự) người dùng vừa gõ.
    final phanVuaGo = vanBanSauKhiGo.substring(sauTokenCu, viTriConTro);
    final phanConLai = vanBanSauKhiGo.substring(viTriConTro);
    final vanBanKetQua =
        '$truocToken$theCu$phanVuaGo$_tenTokenDangGhi$phanConLai';
    final conTroMoi =
        truocToken.length + theCu.length + phanVuaGo.length + _tenTokenDangGhi.length;

    _ghiVanBanChoTheVaChotCung(
      vanBanKetQua,
      TextSelection.collapsed(offset: conTroMoi),
    );

    _boGhiAm?.stop(); // 'stop' sẽ tới sau, chỉ để lưu blob vào thẻ #$soTheCu.
    _taoBoGhiAmMoi(); // thẻ mới — KHÔNG chèn token nữa, đã chèn ở trên rồi.
    _viTriTokenDangGhi = truocToken.length + theCu.length + phanVuaGo.length;
    _kiemTraVaGuiNgamNeuDu();
  }

  /// Thay ĐÚNG token tĩnh "đang ghi âm" (chèn lúc bắt đầu ghi, xem
  /// `_chenTokenDangGhiVaoVanBan`) bằng "〔Ghi âm N 🎙️ mm:ss〕", GIỮ NGUYÊN vị trí
  /// tương đối của con trỏ so với phần văn bản NẰM SAU token (ví dụ dấu
  /// phẩy người dùng vừa gõ ngay sau token) — nếu không giữ, con trỏ sẽ bị
  /// nhảy lùi về trước ký tự vừa gõ, đúng lỗi đã gặp. Nếu vì lý do gì đó
  /// không còn tìm thấy token đó nữa (người dùng đã xoá/sửa nó), rơi về
  /// hành vi cũ: chèn thẻ mới tại vị trí con trỏ hiện tại.
  void _chenTheGhiAmVaoVanBan(int soThe) {
    final the = _chotThoiLuongVaLayNhanThe(soThe);
    final vanBanCu = _boDieuKhienVanBan.text;
    final viTriToken = _viTriTokenDangGhi;
    final chonCu = _boDieuKhienVanBan.selection;
    _viTriTokenDangGhi = null;
    if (viTriToken != null &&
        viTriToken >= 0 &&
        viTriToken + _tenTokenDangGhi.length <= vanBanCu.length &&
        vanBanCu.substring(viTriToken, viTriToken + _tenTokenDangGhi.length) ==
            _tenTokenDangGhi) {
      final vanBanMoi = vanBanCu.replaceRange(
          viTriToken, viTriToken + _tenTokenDangGhi.length, the);
      final ketThucTokenCu = viTriToken + _tenTokenDangGhi.length;
      final lech = the.length - _tenTokenDangGhi.length;
      int dichChuyen(int viTri) {
        if (viTri >= ketThucTokenCu) return viTri + lech;
        if (viTri <= viTriToken) return viTri;
        return viTriToken + the.length; // rơi giữa token cũ (hiếm) — đẩy ra sau.
      }
      final baseMoi = chonCu.baseOffset < 0
          ? viTriToken + the.length
          : dichChuyen(chonCu.baseOffset);
      final extentMoi =
          chonCu.extentOffset < 0 ? baseMoi : dichChuyen(chonCu.extentOffset);
      _ghiVanBanChoTheVaChotCung(
        vanBanMoi,
        TextSelection(baseOffset: baseMoi, extentOffset: extentMoi),
      );
      _ghiLog('Thay token "đang ghi âm" bằng thẻ #$soThe tại vị trí '
          '$viTriToken (giữ con trỏ ở $baseMoi).');
      _kiemTraVaGuiNgamNeuDu();
      return;
    }
    var viTri = _boDieuKhienVanBan.selection.baseOffset;
    if (viTri < 0 || viTri > vanBanCu.length) viTri = vanBanCu.length;
    final vanBanMoi = vanBanCu.replaceRange(viTri, viTri, the);
    _ghiVanBanChoTheVaChotCung(
      vanBanMoi,
      TextSelection.collapsed(offset: viTri + the.length),
    );
    _ghiLog('Chèn thẻ ghi âm #$soThe vào văn bản tại vị trí ký tự $viTri '
        '(không tìm thấy token "đang ghi âm" — có thể đã bị xoá/sửa).');
    _kiemTraVaGuiNgamNeuDu();
  }

  // `_bamNutNgheLai`/`_taiXuongGhiAm` (nút "Nghe lại"/"Tải xuống") đã bỏ từ
  // v19 — cơ chế ghi âm đã kiểm chứng hoạt động đúng qua nhiều bản thử,
  // không cần công cụ kiểm tra nhanh này nữa; thẻ `<audio>` để nghe lại
  // cũng bỏ theo từ v20 (không còn nút nào gọi tới nó).

  /// Đọc [blob] thành chuỗi base64 thuần (không kèm tiền tố
  /// "data:...;base64,") — dùng FileReader vì Blob trên web không có sẵn
  /// phương thức đồng bộ để lấy bytes.
  Future<String> _doiBlobSangBase64(html.Blob blob) {
    final doc = html.FileReader();
    final xong = Completer<String>();
    doc.onLoadEnd.listen((_) {
      final ketQua = doc.result as String;
      final viTriPhay = ketQua.indexOf(',');
      xong.complete(viTriPhay >= 0 ? ketQua.substring(viTriPhay + 1) : ketQua);
    });
    doc.onError.listen((e) => xong.completeError(e));
    doc.readAsDataUrl(blob);
    return xong.future;
  }

  /// Nút "Tạo văn bản": quét toàn bộ văn bản tìm các thẻ "〔Ghi âm N 🎙️ mm:ss〕",
  /// gửi từng file ghi âm tương ứng cho máy chủ trung gian AI (action
  /// 'ghi_am' — đã có sẵn, xem cloud-function/index.js, app Android cũng
  /// đang dùng chung), rồi thay ĐÚNG mỗi thẻ bằng chữ Gemini phiên âm được,
  /// giữ nguyên các phần chữ gõ tay xen kẽ xung quanh.
  Future<void> _taoVanBanTuTheGhiAm() async {
    if (_dangTaoVanBan) return;
    var vanBanHienTai = _boDieuKhienVanBan.text;
    // Lưới an toàn: đáng lẽ không còn token "đang ghi âm" nào sót lại (mọi
    // lần chốt thẻ — dừng tay hoặc gõ phím giữa chừng — đều thay token
    // ngay, đồng bộ, xem `_dungHanGhiAm`/`_chotTheDoGoTayVaBatDauTheMoi`),
    // nhưng nếu vẫn còn (ví dụ lỗi chưa lường hết) thì dọn sạch trước khi
    // gửi, đừng để nó lọt vào văn bản cuối cùng dưới dạng chữ vô nghĩa.
    if (vanBanHienTai.contains(_tenTokenDangGhi)) {
      _ghiLog('Cảnh báo: còn sót token "đang ghi âm" trong văn bản — dọn '
          'trước khi tạo văn bản.');
      vanBanHienTai = vanBanHienTai.replaceAll(_tenTokenDangGhi, '');
    }
    final cacKhop = _reTheGhiAm.allMatches(vanBanHienTai).toList();
    if (cacKhop.isEmpty) {
      _ghiLog('Không có thẻ ghi âm nào trong văn bản để gửi.');
      return;
    }

    setState(() => _dangTaoVanBan = true);
    _ghiLog('Bắt đầu gửi ${cacKhop.length} thẻ ghi âm cho Gemini phiên âm…');

    // Thay TỪ CUỐI VĂN BẢN VỀ ĐẦU — để vị trí ký tự (đo trên văn bản GỐC,
    // trước khi thay bất kỳ thẻ nào) của các thẻ CHƯA xử lý luôn còn đúng,
    // vì mọi thay thế trước đó chỉ động vào phần văn bản NẰM SAU vị trí của
    // chúng.
    var vanBanMoi = vanBanHienTai;
    // Các đoạn vừa thay bằng chữ Gemini (để nhấp nháy) — đo trên `vanBanMoi`
    // sau MỖI lần thay, nên khi một lần thay tiếp theo (ở phía TRƯỚC, do đi
    // từ cuối về đầu) làm lệch độ dài văn bản, phải dịch các đoạn đã ghi
    // trước đó theo đúng độ lệch ấy.
    final cacDoanVuaThay = <(int, int)>[];
    for (final khop in cacKhop.toList().reversed) {
      final soThe = int.parse(khop.group(1)!);
      if (_theDangDuocGui.contains(soThe)) {
        _ghiLog('  Thẻ #$soThe: đang được chế độ gửi ngầm xử lý rồi — bỏ '
            'qua ở lượt thủ công này.');
        continue;
      }
      final blob = _cacDoanGhiAmTheoThe[soThe];
      if (blob == null) {
        _ghiLog('  Thẻ #$soThe: không còn dữ liệu ghi âm (đã bị thay/xoá '
            'trước đó?) — bỏ qua.');
        continue;
      }
      _theDangDuocGui.add(soThe);
      try {
        final chu = await _guiMotTheChoGemini(soThe, blob);
        vanBanMoi = vanBanMoi.replaceRange(khop.start, khop.end, chu);
        final lech = chu.length - (khop.end - khop.start);
        for (var i = 0; i < cacDoanVuaThay.length; i++) {
          final (s, e) = cacDoanVuaThay[i];
          cacDoanVuaThay[i] = (s + lech, e + lech);
        }
        cacDoanVuaThay.add((khop.start, khop.start + chu.length));
        _ghiLog('  Thẻ #$soThe: xong — "$chu"');
      } catch (e) {
        _ghiLog('  Thẻ #$soThe: LỖI — $e');
      } finally {
        _theDangDuocGui.remove(soThe);
      }
    }

    _vanBanDaChot = vanBanMoi;
    _tuDaChot = _tachTu(vanBanMoi);
    _ghiVanBanTuMicro(vanBanMoi);
    for (final (s, e) in cacDoanVuaThay) {
      _danhDauVuaNhanTuGeminiVaNhapNhay(s, e);
    }
    if (mounted) setState(() => _dangTaoVanBan = false);
    _ghiLog('Hoàn tất tạo văn bản từ các thẻ ghi âm.');
  }

  /// Gửi MỘT thẻ (đã có blob) cho Gemini phiên âm, trả về chữ nhận được
  /// hoặc ném lỗi ra ngoài — KHÔNG đụng gì tới văn bản, để nơi gọi (thủ
  /// công qua `_taoVanBanTuTheGhiAm`, hoặc tự động ngầm qua
  /// `_guiMotTheNgamRoiThayVaoVanBan`) tự lo việc thay thế đúng chỗ của nó.
  Future<String> _guiMotTheChoGemini(int soThe, html.Blob blob) async {
    final base64 = await _doiBlobSangBase64(blob);
    _ghiLog('  Thẻ #$soThe: đã mã hoá xong, đang gửi…');
    final phanHoi = await http
        .post(
          Uri.parse(diaChiMayChuAI),
          headers: {
            'content-type': 'application/json',
            'x-flowrite-secret': matKhauMayChuAI,
          },
          body: jsonEncode({
            'action': 'ghi_am',
            'audioBase64': base64,
            'mimeType': blob.type.isNotEmpty ? blob.type : 'audio/mp4',
          }),
        )
        .timeout(const Duration(minutes: 3));
    if (phanHoi.statusCode != 200) {
      throw Exception(
          'Máy chủ AI trả về lỗi ${phanHoi.statusCode}: ${phanHoi.body}');
    }
    final goc =
        jsonDecode(utf8.decode(phanHoi.bodyBytes)) as Map<String, dynamic>;
    final chu = (goc['text'] as String?)?.trim();
    if (chu == null || chu.isEmpty) {
      throw Exception(goc['loi']?.toString() ?? 'Không có nội dung trả về.');
    }
    return chu;
  }

  /// Kiểm tra điều kiện gửi ngầm (xem chú thích `_tuDongGuiNgam`) — gọi mỗi
  /// khi một thẻ vừa được chốt xong. Nếu đủ điều kiện, gửi NGẦM (không chờ,
  /// không khoá giao diện) tất cả các thẻ đã ghi xong mà chưa gửi, trong
  /// lúc thẻ mới vẫn đang ghi tiếp bình thường.
  void _kiemTraVaGuiNgamNeuDu() {
    if (!_tuDongGuiNgam) return;
    final vanBan = _boDieuKhienVanBan.text;
    final soTheChuaGui = <int>[];
    for (final khop in _reTheGhiAm.allMatches(vanBan)) {
      final soThe = int.parse(khop.group(1)!);
      if (_theDangDuocGui.contains(soThe)) continue;
      if (!_cacDoanGhiAmTheoThe.containsKey(soThe)) continue;
      soTheChuaGui.add(soThe);
    }
    if (soTheChuaGui.isEmpty) return;
    final tongThoiLuong = soTheChuaGui.fold<Duration>(
      Duration.zero,
      (tong, soThe) => tong + (_thoiLuongTheoThe[soThe] ?? Duration.zero),
    );
    if (tongThoiLuong < _nguongTongThoiLuongTuDongGui) return;

    _ghiLog('Tự động gửi ngầm ${soTheChuaGui.length} thẻ đã ghi xong (tổng '
        '${_dinhDangMmSs(tongThoiLuong)}) trong lúc tiếp tục ghi…');
    for (final soThe in soTheChuaGui) {
      _guiMotTheNgamRoiThayVaoVanBan(soThe);
    }
  }

  /// Gửi ngầm thẻ #[soThe], rồi thay đúng token của nó bằng chữ Gemini trả
  /// về — tìm lại vị trí token NGAY LÚC NÀY (không phải lúc bắt đầu gửi),
  /// vì văn bản có thể đã đổi trong lúc chờ (người dùng gõ thêm, thẻ khác
  /// đã được thay...). Không tìm thấy nữa (ví dụ người dùng đã xoá thẻ đó)
  /// thì âm thầm bỏ qua. Lỗi mạng/máy chủ cũng âm thầm bỏ qua — thẻ rơi trở
  /// lại danh sách "chưa gửi", `_kiemTraVaGuiNgamNeuDu` lần sau sẽ tự thử
  /// lại, không cần báo lỗi ồn ào giữa lúc người dùng đang ghi âm tiếp.
  Future<void> _guiMotTheNgamRoiThayVaoVanBan(int soThe) async {
    final blob = _cacDoanGhiAmTheoThe[soThe];
    if (blob == null) return;
    _theDangDuocGui.add(soThe);
    try {
      final chu = await _guiMotTheChoGemini(soThe, blob);
      final vanBanHienTai = _boDieuKhienVanBan.text;
      final theCanTim = _nhanTheHoanChinh(soThe);
      final viTri = vanBanHienTai.indexOf(theCanTim);
      if (viTri < 0) {
        _ghiLog('  Thẻ #$soThe (gửi ngầm): không còn tìm thấy trong văn bản '
            '(có thể đã bị xoá) — bỏ qua.');
        return;
      }
      final vanBanMoi =
          vanBanHienTai.replaceRange(viTri, viTri + theCanTim.length, chu);
      // Giữ nguyên vị trí con trỏ HIỆN TẠI của người dùng một cách tương
      // đối — không giật con trỏ về chỗ vừa thay, vì người dùng có thể
      // đang gõ/ghi âm ở một chỗ khác trong lúc thẻ này được gửi ngầm.
      final chonCu = _boDieuKhienVanBan.selection;
      final lech = chu.length - theCanTim.length;
      int dichChuyen(int viTriC) {
        if (viTriC >= viTri + theCanTim.length) return viTriC + lech;
        if (viTriC <= viTri) return viTriC;
        return viTri + chu.length; // con trỏ rơi giữa thẻ (hiếm) — đẩy ra sau.
      }
      final baseMoi = chonCu.baseOffset < 0
          ? vanBanMoi.length
          : dichChuyen(chonCu.baseOffset);
      _vanBanDaChot = vanBanMoi;
      _tuDaChot = _tachTu(vanBanMoi);
      _ghiVanBanTuMicro(vanBanMoi, viTriConTro: baseMoi);
      _danhDauVuaNhanTuGeminiVaNhapNhay(viTri, viTri + chu.length);
      _ghiLog('  Thẻ #$soThe (gửi ngầm): xong — "$chu"');
    } catch (e) {
      _ghiLog('  Thẻ #$soThe (gửi ngầm): LỖI — $e (sẽ tự thử lại ở lần '
          'kiểm tra sau).');
    } finally {
      _theDangDuocGui.remove(soThe);
    }
  }

  /// Gắn vào `onChanged` của khung kết quả — NGUYÊN TẮC gõ-phím-thắng-micro,
  /// y hệt tinh thần `_nguoiDungVuaGo()` bên app chính: gõ một phím là micro
  /// tắt NGAY LẬP TỨC (không đợi micro nói xong đoạn dở dang), và tự bật lại
  /// sau 1 giây không gõ tiếp — không cần bấm nút bật lại bằng tay.
  ///
  /// Chỉ coi là "người dùng gõ" khi thay đổi này KHÔNG phải do chính code tự
  /// ghi vào (`_dangGhiTuMicro`) — nếu không sẽ tắt oan micro mỗi khi chính
  /// micro cập nhật chữ.
  void _khiNguoiDungGoPhim(String vanBanMoi) {
    if (_dangGhiTuMicro) return;
    if (_dangGhiAm) {
      // Người dùng gõ tay thật trong lúc thẻ đang ghi dở — gõ tay luôn
      // thắng micro, nhưng ở đây "thắng" nghĩa là CHỐT NGAY thẻ đang ghi
      // rồi bắt đầu thẻ MỚI tiếp tục ghi (không huỷ/mất bản ghi). Hàm này
      // tự chốt cứng trạng thái ngay bên trong nó (xem
      // `_ghiVanBanChoTheVaChotCung`) — KHÔNG xử lý tiếp `vanBanMoi` ở dưới
      // nữa, kẻo ghi đè lên đúng kết quả vừa cập nhật.
      _chotTheDoGoTayVaBatDauTheMoi(vanBanMoi);
      return;
    }
    _vanBan = vanBanMoi;
    // Coi toàn bộ chữ hiện có (kể cả phần vừa gõ tay, NGUYÊN VĂN không bị
    // tách-rồi-nối lại) là đã "chốt cứng", để khi micro bật lại nó nối tiếp
    // sau đúng chỗ người dùng vừa gõ mà không đè lên, xoá mất, hay làm mất
    // định dạng (xuống dòng, khoảng trắng) người dùng tự gõ.
    _vanBanDaChot = vanBanMoi;
    _tuDaChot = _tachTu(vanBanMoi);
    _partialTruocDo = [];
    _rawTruocDoTrongPhien = '';
    _ghiLog('Người dùng gõ tay — tắt micro ngay, tự bật lại sau 1 giây '
        'nếu không gõ tiếp.');
    _ngatMicroNgayViGoPhim();
  }

  /// Bật/tắt chế độ ngăn bàn phím ảo (xem `_chanBanPhimAo`).
  void _bamNutChanBanPhimAo() {
    setState(() => _chanBanPhimAo = !_chanBanPhimAo);
    _ghiLog(_chanBanPhimAo
        ? 'Bật chế độ ngăn bàn phím ảo — chạm để di chuyển con trỏ/chọn '
            'vùng vẫn được, nhưng bàn phím ảo sẽ không hiện lên nữa. Dùng '
            'hàng phím bên dưới để chấm/phẩy/cách/xuống dòng/xoá.'
        : 'Tắt chế độ ngăn bàn phím ảo — bàn phím thật hoạt động lại bình '
            'thường.');
  }

  /// Áp một chỉnh sửa THÔ (chưa qua `_ChanSuaGiuaThe`) vào khung nhập — dùng
  /// chung cho mọi phím ảo (chấm/phẩy/cách/xuống dòng/xoá) ở chế độ ngăn
  /// bàn phím. Đi qua ĐÚNG `_ChanSuaGiuaThe.formatEditUpdate` trước khi áp
  /// dụng — y hệt bảo vệ mà bàn phím thật vẫn được hưởng (không cho sửa
  /// một phần thẻ ghi âm) — vì các phím ảo này gán `.value=` trực tiếp,
  /// không tự đi qua `TextInputFormatter` như gõ bàn phím thật.
  void _apDungChinhSuaTuPhimAo(TextEditingValue tho) {
    final cu = _boDieuKhienVanBan.value;
    final ketQua = _ChanSuaGiuaThe().formatEditUpdate(cu, tho);
    _boDieuKhienVanBan.value = ketQua;
    _khiNguoiDungGoPhim(ketQua.text);
  }

  /// Chèn [kyTu] tại vị trí đang chọn (đè lên nếu đang chọn một vùng) —
  /// dùng cho các phím ảo chấm/phẩy/cách/xuống dòng.
  void _chenKyTuTuPhimAo(String kyTu) {
    final cu = _boDieuKhienVanBan.value;
    var batDau = cu.selection.start;
    var ketThuc = cu.selection.end;
    if (batDau < 0 || batDau > cu.text.length) batDau = cu.text.length;
    if (ketThuc < 0 || ketThuc > cu.text.length) ketThuc = cu.text.length;
    final tho = TextEditingValue(
      text: cu.text.replaceRange(batDau, ketThuc, kyTu),
      selection: TextSelection.collapsed(offset: batDau + kyTu.length),
    );
    _apDungChinhSuaTuPhimAo(tho);
  }

  /// Phím ảo "Xoá": xoá cả vùng đang chọn nếu có, không thì xoá lùi một ký
  /// tự (y hệt phím Backspace thật).
  void _xoaKyTuTuPhimAo() {
    final cu = _boDieuKhienVanBan.value;
    final chon = cu.selection;
    TextEditingValue tho;
    if (chon.isValid && !chon.isCollapsed) {
      tho = TextEditingValue(
        text: cu.text.replaceRange(chon.start, chon.end, ''),
        selection: TextSelection.collapsed(offset: chon.start),
      );
    } else {
      var viTri = chon.baseOffset;
      if (viTri < 0 || viTri > cu.text.length) viTri = cu.text.length;
      if (viTri == 0) return; // đầu văn bản — không có gì để xoá lùi.
      tho = TextEditingValue(
        text: cu.text.replaceRange(viTri - 1, viTri, ''),
        selection: TextSelection.collapsed(offset: viTri - 1),
      );
    }
    _apDungChinhSuaTuPhimAo(tho);
  }

  Future<void> _ngatMicroNgayViGoPhim() async {
    _henMoLaiMicroSauKhiGo?.cancel();
    _henBatLai?.cancel();
    _phienHienTai++; // Huỷ callback của phiên đang chạy dở (LỚP 1).
    await _micro.cancel();
    if (mounted && _dangNghe) setState(() => _dangNghe = false);
    _henMoLaiMicroSauKhiGo = Timer(const Duration(seconds: 1), () {
      if (_muonNghe && !_micro.isListening) _batNghe();
    });
  }

  /// Ghi văn bản do MICRO tạo ra vào cả `_vanBan` lẫn khung gõ, mà không để
  /// `_khiNguoiDungGoPhim` hiểu nhầm là người dùng gõ (dùng cờ chặn).
  ///
  /// [viTriConTro] mặc định là CUỐI văn bản (giữ hành vi cũ cho các chỗ gọi
  /// không liên quan tới neo — ví dụ "Xoá để thử lại", chốt thẻ ghi âm) —
  /// nhưng khi ghi chữ do micro NHẬN DẠNG được (xem `_xuLyKetQuaPc` và các
  /// nhánh chị em), luôn truyền rõ vị trí ngay sau đoạn vừa chèn tại neo
  /// (`_neoChenMic`), để con trỏ luôn theo đúng chỗ chữ vừa xuất hiện thay
  /// vì luôn nhảy về cuối toàn bộ văn bản.
  void _ghiVanBanTuMicro(String vanBanMoi, {int? viTriConTro}) {
    _dangGhiTuMicro = true;
    _vanBan = vanBanMoi;
    _boDieuKhienVanBan.value = TextEditingValue(
      text: vanBanMoi,
      selection:
          TextSelection.collapsed(offset: viTriConTro ?? vanBanMoi.length),
    );
    _dangGhiTuMicro = false;
  }

  /// Chèn [tuMoi] vào GIỮA [hienTai] tại vị trí [viTri] (thay vì luôn nối
  /// vào cuối văn bản) — thêm dấu cách phân tách ở ĐẦU (nếu ký tự
  /// ngay trước [viTri] không phải khoảng trắng/xuống dòng) và ở CUỐI (nếu
  /// còn phần đuôi văn bản ngay sau [viTri] và ký tự đó không phải khoảng
  /// trắng/xuống dòng — tức đang chèn vào GIỮA một đoạn chữ có sẵn). Trả về
  /// (văn bản mới, vị trí NGAY SAU đoạn vừa chèn — dùng làm neo/con trỏ
  /// tiếp theo).
  static (String, int) _chenTuVaoViTri(
    String hienTai,
    int viTri,
    List<String> tuMoi,
  ) {
    // Kẹp lại đề phòng neo bị lệch so với văn bản hiện tại (ví dụ văn bản
    // vừa bị rút ngắn ở nơi khác mà chưa kịp đồng bộ neo) — tránh
    // RangeError thay vì cứ tin tưởng tuyệt đối vào giá trị neo truyền vào.
    if (viTri < 0) viTri = 0;
    if (viTri > hienTai.length) viTri = hienTai.length;
    if (tuMoi.isEmpty) return (hienTai, viTri);
    var phanMoi = tuMoi.join(' ');
    if (viTri > 0) {
      final kt = hienTai[viTri - 1];
      if (kt != '\n' && kt != ' ') phanMoi = ' $phanMoi';
    }
    if (viTri < hienTai.length) {
      final kt = hienTai[viTri];
      if (kt != '\n' && kt != ' ') phanMoi = '$phanMoi ';
    }
    final vanBanMoi = hienTai.replaceRange(viTri, viTri, phanMoi);
    return (vanBanMoi, viTri + phanMoi.length);
  }

  /// Xoá vùng đang chờ bị "đè lên" (nếu có, xem `_doDaiVungDeDeMic`) khỏi
  /// `_vanBanDaChot` — gọi NGAY TRƯỚC lần chèn chữ mic đầu tiên của một
  /// phiên nghe, tức đúng lúc có chữ THẬT để thay vào chỗ vùng chọn cũ.
  void _apDungXoaVungChonMicNeuCo() {
    if (_doDaiVungDeDeMic <= 0) return;
    final ketThuc =
        (_neoChenMic + _doDaiVungDeDeMic).clamp(0, _vanBanDaChot.length);
    _ghiLog('Đè lên vùng đang chọn ($_doDaiVungDeDeMic ký tự) bằng chữ '
        'vừa nhận dạng được.');
    _vanBanDaChot = _vanBanDaChot.replaceRange(_neoChenMic, ketThuc, '');
    _doDaiVungDeDeMic = 0;
  }

  Future<void> _saoChepVanBan() async {
    final noiDung = _vanBan.isEmpty ? '(chưa có chữ nào)' : _vanBan;
    await Clipboard.setData(ClipboardData(text: noiDung));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép kết quả vào bộ nhớ tạm'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saoChepNhatKy() async {
    final noiDung = _nhatKy.isEmpty ? '(chưa có nhật ký)' : _nhatKy.join('\n');
    await Clipboard.setData(ClipboardData(text: noiDung));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép nhật ký vào bộ nhớ tạm'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Nhật ký giờ nằm trong modal riêng (mở bằng nút nhỏ cạnh micro) thay vì
  /// chiếm nguyên một khối trên trang — theo yêu cầu để khung nhập to ra.
  void _moModalNhatKy() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, capNhatModal) {
            return AlertDialog(
              title: const Text('Nhật ký'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Scrollbar(
                  controller: _cuonNhatKy,
                  child: SingleChildScrollView(
                    controller: _cuonNhatKy,
                    child: SelectableText(
                      _nhatKy.isEmpty
                          ? '(chưa có nhật ký)'
                          : _nhatKy.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _saoChepNhatKy,
                  child: const Text('Sao chép tất cả'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _nhatKy.clear());
                    capNhatModal(() {});
                  },
                  child: const Text('Xoá tất cả'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _doiCheDoThietBi(ThietBi moi) {
    if (moi == _thietBi) return;
    setState(() => _thietBi = moi);
    _ghiLog('Chuyển tay sang chế độ: ${_tenThietBi(moi)}');
  }

  /// Trang Cài đặt — vị trí bố cục phỏng theo `ManHinhCaiDat` của app
  /// Android (mở qua "+ Thêm lựa chọn" → "Cài đặt"). Mục "Chuyển tay thiết
  /// bị" đặt ĐẦU TIÊN, đúng như yêu cầu — bản thử web này chỉ có mục cài
  /// đặt riêng của nó (các mục cài đặt khác của app Android như tự tắt
  /// micro, kiểm tra chính tả AI... thuộc phạm vi bước sau, chưa chuyển
  /// sang đây).
  void _moCaiDat() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Cài đặt')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Chuyển tay thiết bị (ép chế độ nhận diện thủ công):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, capNhat) => SegmentedButton<ThietBi>(
                  segments: const [
                    ButtonSegment(
                      value: ThietBi.android,
                      icon: Icon(Icons.android),
                      label: Text('Android'),
                    ),
                    ButtonSegment(
                      value: ThietBi.pc,
                      icon: Icon(Icons.laptop_mac),
                      label: Text('PC/Mac'),
                    ),
                    ButtonSegment(
                      value: ThietBi.iphone,
                      icon: Icon(Icons.phone_iphone),
                      label: Text('iPhone'),
                    ),
                  ],
                  selected: {_thietBi},
                  onSelectionChanged: (chon) {
                    _doiCheDoThietBi(chon.first);
                    capNhat(() {});
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colors.blue.shade700,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ),
              const Divider(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------ thuật toán lõi

  // Chrome Android trả `recognizedWords` bị lặp lại TOÀN BỘ lịch sử của
  // phiên như tiền tố mỗi lần có kết quả mới (vd lần 3 gửi
  // "XinXin chàoXin chàoXin chào" thay vì chỉ "Xin chào") — mỗi lần lặp lại
  // luôn bắt đầu bằng chữ hoa. Quan sát log thực tế cho thấy: ĐOẠN CUỐI
  // CÙNG (tính từ lần chuyển chữ-thường-sang-chữ-hoa gần cuối chuỗi nhất)
  // luôn là bản ghi ĐẦY ĐỦ, SẠCH của toàn phiên tới thời điểm đó — không
  // lặp lại gì cả. Vì vậy chỉ cần cắt lấy đúng đoạn cuối này, bỏ hết phần
  // lặp lại dư thừa phía trước, là có được dữ liệu y hệt một partial bình
  // thường (giống PC) để đưa vào thuật toán tìm-điểm-nối bên dưới. Chỉ
  // dùng cho nhánh điện thoại — PC không có lỗi này nên không đụng tới.
  static const _chuThuongViet =
      'a-zàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const _chuHoaViet =
      'A-ZÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  static final RegExp _reRanhGioiDoanDinh =
      RegExp('[$_chuThuongViet][$_chuHoaViet]');

  /// Cắt lấy đoạn cuối cùng (từ lần chuyển chữ-thường→chữ-hoa gần cuối
  /// chuỗi nhất tới hết chuỗi) — đây là bản ghi sạch, không lặp.
  static String _catDoanCuoiCung(String s) {
    var viTri = 0;
    for (final m in _reRanhGioiDoanDinh.allMatches(s)) {
      viTri = m.start + 1;
    }
    return s.substring(viTri);
  }

  /// Tách chuỗi thành danh sách từ theo khoảng trắng — y hệt `_tachTu`.
  static List<String> _tachTu(String s) {
    final t = s.trim();
    if (t.isEmpty) return const [];
    return t.split(RegExp(r'\s+'));
  }

  /// Chuẩn hoá một từ để so khớp nới lỏng — y hệt `_chuanHoaSoKhopTho`.
  static String _chuanHoaTho(String tu) =>
      tu.toLowerCase().replaceAll(RegExp(r'[.,!?;:]+$'), '');

  static bool _khopTho(String a, String b) =>
      _chuanHoaTho(a) == _chuanHoaTho(b);

  /// Độ dài tiền tố chung khớp CHÍNH XÁC — y hệt `_doDaiTienToChung`.
  static int _doDaiTienToChung(List<String> a, List<String> b) {
    final n = a.length < b.length ? a.length : b.length;
    var i = 0;
    while (i < n && a[i] == b[i]) {
      i++;
    }
    return i;
  }

  /// [partialMoi] có bắt đầu bằng ĐÚNG toàn bộ [daChot] hay không — y hệt
  /// `_batDauBangPhanDaChot`.
  static bool _batDauBangPhanDaChot(
    List<String> partialMoi,
    List<String> daChot,
  ) {
    if (partialMoi.length < daChot.length) return false;
    for (var i = 0; i < daChot.length; i++) {
      if (!_khopTho(partialMoi[i], daChot[i])) return false;
    }
    return true;
  }

  /// Thuật toán "tìm điểm nối": thử N từ CUỐI của [daChot] (từ dài nhất có
  /// thể xuống 1), xem [partialMoi] có bắt đầu đúng bằng N từ đó không (so
  /// khớp nới lỏng). `null` = không tìm được, coi là nội dung mới hoàn
  /// toàn. `[]` = trùng nguyên văn N từ cuối, không có gì thêm (nhân đôi).
  /// khác = phần mới thật sự nằm sau điểm nối.
  ///
  /// KHÔNG giới hạn N ở 6 như bản gốc bên app chính (nơi cụm lặp trên
  /// Android luôn ngắn) — trên nhánh điện thoại của bản test này, cụm lặp
  /// do Chrome tự lặp lại có thể dài hơn 6 từ rất nhiều (xem log thực tế:
  /// "bị lặp lại từ của tôi Bởi vậy cho nên..." lặp nguyên cụm mỗi lần),
  /// giới hạn 6 làm bỏ lỡ điểm nối và gây nối nhầm nguyên cụm dài vào cuối.
  static List<String>? _timDiemNoiTrong(
    List<String> daChot,
    List<String> partialMoi,
  ) {
    final soDaChot = daChot.length;
    final maxN = soDaChot < partialMoi.length ? soDaChot : partialMoi.length;
    for (var n = maxN; n >= 1; n--) {
      if (partialMoi.length < n) continue;
      final duoiDaChot = daChot.sublist(soDaChot - n);
      var khop = true;
      for (var i = 0; i < n; i++) {
        if (!_khopTho(partialMoi[i], duoiDaChot[i])) {
          khop = false;
          break;
        }
      }
      if (khop) {
        if (partialMoi.length == n) return const [];
        return partialMoi.sublist(n);
      }
    }
    return null;
  }

  void _khiCoKetQua(dynamic ketQua) {
    final noi = (ketQua.recognizedWords as String? ?? '').trim();
    final xong = ketQua.finalResult as bool? ?? false;

    setState(() {
      if (xong) {
        _soLanFinal++;
      } else {
        _soLanPartial++;
      }
    });
    _ghiLog('${xong ? "FINAL" : "partial"}: "$noi"');

    if (noi.isEmpty) return;
    // Có chữ thật — bộ đếm lỗi-liên-tiếp-không-chữ hết ý nghĩa, xoá về 0.
    _soLanLoiLienTiepKhongChu = 0;

    switch (_thietBi) {
      case ThietBi.android:
        _xuLyKetQuaDienThoai(noi);
      case ThietBi.pc:
        _xuLyKetQuaPc(noi, xong);
      case ThietBi.iphone:
        _xuLyKetQuaIphone(noi, xong);
    }
  }

  /// Nhánh PC: dùng nguyên thuật toán "chốt dần theo độ ổn định" gốc — coi
  /// [noi] là TOÀN BỘ hypothesis đang tăng dần của bộ nhận dạng (đúng như
  /// Web Speech API trên PC hoạt động).
  void _xuLyKetQuaPc(String noi, bool xong) {
    final tuMoi = _tachTu(noi);
    if (tuMoi.isEmpty) return;
    _apDungXoaVungChonMicNeuCo();

    // Phần từ CHƯA/MỚI cần hiển thị thêm sau `_vanBanDaChot` hiện tại —
    // không bao giờ dựng lại toàn bộ văn bản, chỉ nối thêm, để giữ nguyên
    // định dạng (xuống dòng...) người dùng có thể đã gõ tay trước đó.
    List<String> phanMoiCanNoi;
    if (_batDauBangPhanDaChot(tuMoi, _tuDaChot)) {
      final tienToChung = _doDaiTienToChung(tuMoi, _partialTruocDo);
      if (tienToChung > _tuDaChot.length) {
        // Chỉ đúng phần MỚI được coi là ổn định (tienToChung tăng thêm) mới
        // thật sự chốt cứng vào `_vanBanDaChot` — phần còn lại của tuMoi
        // (dưới đây) vẫn chỉ là xem trước, chưa ghi đè lên bản chốt. Chèn
        // ĐÚNG TẠI NEO (`_neoChenMic`), không phải luôn ở cuối văn bản, rồi
        // dời neo theo — xem chú thích ở khai báo `_neoChenMic`.
        final tuMoiChotThem = tuMoi.sublist(_tuDaChot.length, tienToChung);
        final (vbMoi, neoMoi) =
            _chenTuVaoViTri(_vanBanDaChot, _neoChenMic, tuMoiChotThem);
        _vanBanDaChot = vbMoi;
        _neoChenMic = neoMoi;
        _tuDaChot = tuMoi.sublist(0, tienToChung);
      }
      phanMoiCanNoi = tuMoi.sublist(_tuDaChot.length);
    } else {
      final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
      if (ketQuaNoi == null) {
        phanMoiCanNoi = tuMoi;
      } else if (ketQuaNoi.isEmpty) {
        _partialTruocDo = tuMoi;
        return;
      } else {
        phanMoiCanNoi = ketQuaNoi;
      }
    }

    _partialTruocDo = tuMoi;
    final (vanBanHienThi, viTriSauChen) =
        _chenTuVaoViTri(_vanBanDaChot, _neoChenMic, phanMoiCanNoi);
    setState(
        () => _ghiVanBanTuMicro(vanBanHienThi, viTriConTro: viTriSauChen));

    if (xong) {
      // Kết quả FINAL: toàn bộ nội dung hiện có (kể cả phần xem trước) coi
      // là chốt cứng, giữ nguyên văn. `_tuDaChot` dùng thẳng `tuMoi` (toàn
      // bộ từ của phiên nói này, đã có sẵn) thay vì tách từ lại
      // `vanBanHienThi` — vì `vanBanHienThi` giờ là NGUYÊN VĂN BẢN (chèn
      // giữa chừng), tách từ lại nó sẽ lẫn cả những đoạn chữ khác không
      // liên quan nằm trước/sau vị trí chèn.
      _vanBanDaChot = vanBanHienThi;
      _neoChenMic = viTriSauChen;
      _tuDaChot = tuMoi;
      _partialTruocDo = [];
    }
  }

  /// Nhánh iPhone: CHƯA có máy iOS thật để test (xem log v10 trở về trước —
  /// chỉ test được Android và PC/Mac). Trên iOS, mọi trình duyệt đều bị
  /// Apple ép dùng chung bộ máy WebKit của Safari — hoàn toàn khác bộ máy
  /// Chromium (Chrome/Edge) đang chạy trên Android và PC/Mac. Không có dữ
  /// liệu thật để biết WebKit có bị lỗi lặp-lịch-sử giống Chrome Android
  /// hay không.
  ///
  /// Tạm dùng NGUYÊN VẸN thuật toán của nhánh PC (`_xuLyKetQuaPc`) làm điểm
  /// khởi đầu — lý do chọn PC thay vì Android: thuật toán PC giả định bộ
  /// nhận dạng trả hypothesis tăng dần SẠCH (không tự lặp lại lịch sử), đây
  /// là hành vi "đúng chuẩn" của Web Speech API mà đa số trình duyệt tuân
  /// theo — lỗi lặp lịch sử là ĐẶC THÙ riêng của Chrome Android (xem thuật
  /// toán `_xuLyKetQuaDienThoai`), không có gì cho thấy WebKit trên iOS
  /// cũng mắc lỗi y hệt vậy. Tách thành hàm riêng (không gọi thẳng
  /// `_xuLyKetQuaPc`) để sau này có log/bằng chứng thật từ máy iPhone thì
  /// sửa riêng nhánh này mà không đụng tới nhánh PC đã test kỹ.
  void _xuLyKetQuaIphone(String noi, bool xong) {
    final tuMoi = _tachTu(noi);
    if (tuMoi.isEmpty) return;
    _apDungXoaVungChonMicNeuCo();

    List<String> phanMoiCanNoi;
    if (_batDauBangPhanDaChot(tuMoi, _tuDaChot)) {
      final tienToChung = _doDaiTienToChung(tuMoi, _partialTruocDo);
      if (tienToChung > _tuDaChot.length) {
        final tuMoiChotThem = tuMoi.sublist(_tuDaChot.length, tienToChung);
        final (vbMoi, neoMoi) =
            _chenTuVaoViTri(_vanBanDaChot, _neoChenMic, tuMoiChotThem);
        _vanBanDaChot = vbMoi;
        _neoChenMic = neoMoi;
        _tuDaChot = tuMoi.sublist(0, tienToChung);
      }
      phanMoiCanNoi = tuMoi.sublist(_tuDaChot.length);
    } else {
      final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
      if (ketQuaNoi == null) {
        phanMoiCanNoi = tuMoi;
      } else if (ketQuaNoi.isEmpty) {
        _partialTruocDo = tuMoi;
        return;
      } else {
        phanMoiCanNoi = ketQuaNoi;
      }
    }

    _partialTruocDo = tuMoi;
    final (vanBanHienThi, viTriSauChen) =
        _chenTuVaoViTri(_vanBanDaChot, _neoChenMic, phanMoiCanNoi);
    setState(
        () => _ghiVanBanTuMicro(vanBanHienThi, viTriConTro: viTriSauChen));

    if (xong) {
      _vanBanDaChot = vanBanHienThi;
      _neoChenMic = viTriSauChen;
      _tuDaChot = tuMoi;
      _partialTruocDo = [];
    }
  }

  /// Nhánh điện thoại: Chrome Android không gửi hypothesis tăng dần sạch —
  /// nó lặp lại lịch sử của CHÍNH PHIÊN NÀY làm tiền tố mỗi lần có kết quả
  /// mới, có lúc viết hoa đầu đoạn lặp (bắt được bằng `_catDoanCuoiCung`),
  /// có lúc KHÔNG (lặp giữa câu, toàn chữ thường — xem log thực tế: "rất"
  /// → "rấtrất là" → "rấtrất làrất là"...). Cách chắc ăn với CẢ HAI kiểu
  /// lặp: so sánh chuỗi thô của lần này với lần TRƯỚC trong cùng phiên —
  /// phần thêm vào luôn nằm ở cuối, vì bộ nhận dạng chỉ có APPEND, không
  /// bao giờ xoá. Lấy đúng phần đuôi mới đó rồi đưa vào tìm-điểm-nối để
  /// gộp vào nội dung đã chốt.
  void _xuLyKetQuaDienThoai(String noiGoc) {
    final noiDaCat = _catDoanCuoiCung(noiGoc);
    if (noiDaCat != noiGoc) {
      _ghiLog('  → cắt còn đoạn cuối sạch: "$noiDaCat"');
    }

    String phanMoi;
    if (_rawTruocDoTrongPhien.isNotEmpty &&
        noiDaCat.startsWith(_rawTruocDoTrongPhien)) {
      phanMoi = noiDaCat.substring(_rawTruocDoTrongPhien.length);
    } else {
      phanMoi = noiDaCat;
    }
    _rawTruocDoTrongPhien = noiDaCat;

    final tuMoi = _tachTu(phanMoi);
    if (tuMoi.isEmpty) return;
    _ghiLog('  → phần đuôi mới so với lần trước: "${tuMoi.join(' ')}"');

    final ketQuaNoi = _timDiemNoiTrong(_tuDaChot, tuMoi);
    List<String> tuThemVao;
    if (ketQuaNoi == null) {
      _ghiLog('  → không tìm được điểm nối, nối thẳng đuôi mới vào cuối');
      tuThemVao = tuMoi;
    } else if (ketQuaNoi.isEmpty) {
      _ghiLog('  → đuôi mới trùng hoàn toàn với phần đã chốt, bỏ qua');
      return;
    } else {
      _ghiLog('  → tìm được điểm nối, thêm ${ketQuaNoi.length} từ mới');
      tuThemVao = ketQuaNoi;
    }

    // Nhánh điện thoại không có FINAL đáng tin cậy — chốt cứng ngay mỗi lần
    // có nội dung mới, để không bao giờ mất chữ đã hiện ra. CHỈ NỐI THÊM,
    // không bao giờ dựng lại bằng join(' ') từ danh sách từ — nhưng chèn
    // ĐÚNG TẠI NEO (`_neoChenMic`), không phải luôn ở cuối văn bản.
    _apDungXoaVungChonMicNeuCo();
    final (vbMoi, neoMoi) =
        _chenTuVaoViTri(_vanBanDaChot, _neoChenMic, tuThemVao);
    _vanBanDaChot = vbMoi;
    _neoChenMic = neoMoi;
    // `_tuDaChot` đại diện cho phần "đã chốt" NGAY TRƯỚC neo — tính lại từ
    // đúng đoạn đó (không phải toàn bộ văn bản, kẻo lẫn chữ không liên quan
    // nằm sau vị trí chèn) để lần dò điểm nối tiếp theo so khớp đúng chỗ.
    _tuDaChot = _tachTu(_vanBanDaChot.substring(0, _neoChenMic));
    setState(() => _ghiVanBanTuMicro(_vanBanDaChot, viTriConTro: _neoChenMic));
  }

  @override
  void dispose() {
    _henBatLai?.cancel();
    _henMoLaiMicroSauKhiGo?.cancel();
    _bomDongHoGhiAm?.cancel();
    _bomNhapNhay?.cancel();
    _bomLuuVanBan?.cancel();
    _micro.cancel();
    _cuonNhatKy.dispose();
    _boDieuKhienVanBan.removeListener(_khiGiaTriKhungNhapDoi);
    _boDieuKhienVanBan.dispose();
    for (final track in _luongGhiAm?.getTracks() ?? const []) {
      track.stop();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- giao diện

  @override
  Widget build(BuildContext context) {
    // Bàn phím ảo đang mở hay không: `viewInsets.bottom > 0` khi hệ điều
    // hành đẩy bàn phím lên. Lúc gõ tay, người dùng chỉ cần thấy khung nhập
    // — các hàng bên dưới (trạng thái nghe, dãy nút micro/ghi âm/nghe lại/
    // tải xuống, tên trang, bộ chọn thiết bị) không cần thiết và chỉ làm
    // khung nhập bị bóp nhỏ lại. Ẩn hẳn chúng khi bàn phím đang mở, để
    // khung nhập giãn ra chiếm trọn phần còn lại phía trên bàn phím.
    final banPhimDangMo = MediaQuery.of(context).viewInsets.bottom > 0;

    // Phím tắt Ctrl+G bật/tắt micro — CallbackShortcuts bọc NGOÀI Scaffold
    // nên vẫn bắt được dù đang focus vào khung nhập kết quả (Shortcuts đi
    // theo cây tổ tiên của focus hiện tại, không cần focus đúng widget này).
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG):
            () {
          if (_sanSang) _bamNutMicro();
        },
      },
      child: Focus(
        autofocus: true,
        // Không dùng AppBar nữa — tên trang giờ nằm trong thân trang (xem
        // bên dưới), theo đúng thứ tự người dùng yêu cầu: khung nhập lên
        // đầu, kế đến thanh micro/nhật ký, rồi mới tới tên trang và cuối
        // cùng là bộ chọn thiết bị.
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Các thông báo quan trọng (đang xin quyền / lỗi) vẫn cố
                  // tình đặt trên cùng — chỉ hiện khi thật sự cần, không
                  // choán chỗ lúc bình thường.
                  if (!_sanSang)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Đang khởi tạo micro… nếu trình duyệt hỏi quyền, '
                        'hãy chọn Cho phép.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  if (_loi.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _loi,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Khung nhập liệu — lên đầu tiên.
                  Row(
                    children: [
                      Tooltip(
                        message: 'Gõ tay được — gõ phím sẽ tắt micro ngay, '
                            'tự bật lại sau 1 giây',
                        child: const Text(
                          'Kết quả',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      if (_dangGhiAm)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fiber_manual_record,
                                  color: Colors.red, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Đang ghi: ${_dinhDangMmSs(_thoiLuongDangGhi)}'
                                ' / ${_dinhDangMmSs(_gioiHanThoiLuongMoiThe)}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      Tooltip(
                        message: _tuDongGuiNgam
                            ? 'Đang tự động gửi ngầm các thẻ đã ghi xong '
                                '(bấm để tắt)'
                            : 'Bật tự động gửi ngầm các thẻ đã ghi xong '
                                'trong lúc ghi thẻ mới (từ ${_nguongTongThoiLuongTuDongGui.inSeconds}s trở lên)',
                        child: IconButton(
                          onPressed: () =>
                              setState(() => _tuDongGuiNgam = !_tuDongGuiNgam),
                          icon: Icon(
                            _tuDongGuiNgam
                                ? Icons.cloud_sync
                                : Icons.cloud_sync_outlined,
                            color: _tuDongGuiNgam
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (_dangTaoVanBan)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Tooltip(
                          message: 'Gửi tất cả thẻ 〔Ghi âm N 🎙️ mm:ss〕 '
                              'trong văn bản cho Gemini phiên âm, thay đúng '
                              'vào chỗ của từng thẻ',
                          child: TextButton(
                            onPressed: _taoVanBanTuTheGhiAm,
                            child: const Text('Tạo văn bản'),
                          ),
                        ),
                      TextButton(
                        onPressed: _saoChepVanBan,
                        child: const Text('Sao chép tất cả'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _boDieuKhienVanBan,
                        onChanged: _khiNguoiDungGoPhim,
                        inputFormatters: [_ChanSuaGiuaThe()],
                        // KHÔNG dùng `readOnly` để ngăn bàn phím ảo nữa —
                        // `readOnly` đổi hẳn đường xử lý cử chỉ của ô nhập
                        // (dành cho "xem + chọn", không phải "soạn thảo"),
                        // gây đúng các lỗi kéo-chọn-vùng đã gặp (vuốt không
                        // ra đầu mút, kéo đầu mút xa bị kẹt, đầu mút lệch vị
                        // trí thật). `TextInputType.none` mới là đúng cách:
                        // ô vẫn ở chế độ soạn thảo BÌNH THƯỜNG (mọi cử chỉ
                        // chọn vùng/kéo đầu mút hoạt động y hệt lúc không
                        // bật chế độ ngăn bàn phím), chỉ báo cho hệ thống
                        // đừng bật bàn phím ảo cho ô này.
                        keyboardType: _chanBanPhimAo
                            ? TextInputType.none
                            : TextInputType.multiline,
                        // Ở chế độ ngăn bàn phím ảo, người dùng ĐÃ tự tay
                        // xác nhận không dùng chuột/bàn phím rời (đúng mục
                        // đích sinh ra nút này) — ép hẳn bộ điều khiển
                        // chọn-vùng kiểu DI ĐỘNG (hai đầu mút kéo được)
                        // thay vì để Flutter tự đoán theo tên hệ điều hành
                        // trình duyệt khai báo. Cần ép vì bộ tự đoán này bị
                        // sai trên một số thiết bị cảm ứng (ví dụ máy tính
                        // bảng Android tự nhận nhầm là không phải di động),
                        // khiến chọn vùng bằng ngón tay không ra đầu mút
                        // hoặc đầu mút lệch/kẹt — y hệt kiểu lỗi User-Agent
                        // "chế độ máy tính" đã gặp ở việc nhận diện thiết
                        // bị của chính trang này, nhưng lần này nằm bên
                        // trong chính khung Flutter. KHÔNG ép khi tắt chế
                        // độ này — lúc đó không chắc người dùng có
                        // chuột/bàn phím rời hay không.
                        selectionControls: _chanBanPhimAo
                            ? materialTextSelectionControls
                            : null,
                        showCursor: true,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _chanBanPhimAo
                              ? '(đang ngăn bàn phím ảo — chạm để đặt con '
                                  'trỏ/chọn vùng, dùng hàng phím bên dưới '
                                  'hoặc micro để nhập chữ)'
                              : '(chưa có chữ nào — nói hoặc gõ vào đây)',
                        ),
                        style: const TextStyle(fontSize: 18, height: 1.5),
                      ),
                    ),
                  ),
                  if (_chanBanPhimAo && !banPhimDangMo)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _NutPhimAo(
                              nhan: '.', onTap: () => _chenKyTuTuPhimAo('.')),
                          _NutPhimAo(
                              nhan: ',', onTap: () => _chenKyTuTuPhimAo(',')),
                          _NutPhimAo(
                            nhan: '␣',
                            moTa: 'Dấu cách',
                            onTap: () => _chenKyTuTuPhimAo(' '),
                          ),
                          _NutPhimAo(
                            nhan: '⏎',
                            moTa: 'Xuống dòng',
                            onTap: () => _chenKyTuTuPhimAo('\n'),
                          ),
                          _NutPhimAo(
                            nhan: '⌫',
                            moTa: 'Xoá',
                            mauNen: Colors.red.shade50,
                            mauVien: Colors.red.shade300,
                            onTap: _xoaKyTuTuPhimAo,
                          ),
                        ],
                      ),
                    ),
                  if (!banPhimDangMo) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _dangNghe ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: _dangNghe ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(_dangNghe ? 'Đang nghe' : 'Không nghe'),
                      const Spacer(),
                      Text('PARTIAL: $_soLanPartial   FINAL: $_soLanFinal'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Thanh công cụ dưới cùng — bố cục phỏng theo `ThanhCongCu`
                  // của app Android: nhóm nút phụ bên trái (co giãn được),
                  // nút "Ghi âm" sát trước, và nút MICRO CHÍNH nằm NGOÀI
                  // CÙNG bên phải — đúng vị trí `_NutMicroTron` trong app.
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _ghiVanBanTuMicro('');
                                    _vanBanDaChot = '';
                                    _neoChenMic = 0;
                                    _tuDaChot = [];
                                    _partialTruocDo = [];
                                    _rawTruocDoTrongPhien = '';
                                    _soLanPartial = 0;
                                    _soLanFinal = 0;
                                  });
                                  _ghiLog('Xoá để thử lại.');
                                },
                                child: const Text('Xoá để thử lại'),
                              ),
                              // Nút nhật ký — nhỏ, mở modal riêng thay vì
                              // chiếm chỗ ngay trên trang như trước.
                              Tooltip(
                                message: 'Xem nhật ký',
                                child: IconButton(
                                  onPressed: _moModalNhatKy,
                                  icon: const Icon(Icons.receipt_long),
                                ),
                              ),
                              // "+ Thêm lựa chọn" — gộp các nút phụ ít bấm
                              // (ngăn bàn phím ảo) đúng như vị trí của nó
                              // trong menu cùng tên bên app Android.
                              Tooltip(
                                message: '+ Thêm lựa chọn',
                                child: PopupMenuButton<void>(
                                  icon: const Icon(Icons.add_circle_outline),
                                  itemBuilder: (context) => [
                                    PopupMenuItem<void>(
                                      onTap: _bamNutChanBanPhimAo,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _chanBanPhimAo
                                                ? Icons.check_box
                                                : Icons
                                                    .check_box_outline_blank,
                                            color: Colors.deepPurple,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Ngăn bàn phím ảo'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem<void>(
                                      onTap: _moCaiDat,
                                      child: const Row(
                                        children: [
                                          Icon(Icons.settings),
                                          SizedBox(width: 8),
                                          Text('Cài đặt'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Nút "Ghi âm" riêng — trên iPhone nút micro chính ở
                      // trên đã gọi thẳng đúng cơ chế này rồi (xem
                      // `_bamNutMicro`), nên ẨN nút riêng này đi để khỏi có
                      // hai nút làm cùng một việc. Trên Android/PC (nơi
                      // micro chính vẫn dùng Web Speech API) vẫn giữ nút
                      // này làm lựa chọn phụ — đây chính là chức năng ghi âm
                      // của WEB sẽ thay thế nút ghi-âm-rồi-ra-chữ của app
                      // Android khi hai bên hợp nhất.
                      if (_thietBi != ThietBi.iphone) ...[
                        Tooltip(
                          message: _dangGhiAm ? 'Dừng ghi âm' : 'Ghi âm thử',
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _bamNutGhiAm,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _dangGhiAm
                                    ? Colors.red
                                    : Colors.orange.shade100,
                                border: Border.all(
                                  color: Colors.orange.shade900,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _dangGhiAm
                                    ? Icons.stop
                                    : Icons.fiber_manual_record,
                                color: _dangGhiAm
                                    ? Colors.white
                                    : Colors.orange.shade900,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Nút micro — NGOÀI CÙNG bên phải, đúng vị trí
                      // `_NutMicroTron` trong `ThanhCongCu` của app Android.
                      // Có phím tắt Ctrl+G (xem `CallbackShortcuts` bao
                      // ngoài).
                      Tooltip(
                        message: 'Bật/tắt micro (Ctrl+G)',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: (_sanSang && !_dangGhiAm)
                              ? _bamNutMicro
                              : null,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _muonNghe
                                  ? Colors.red
                                  : Colors.lightGreen.shade200,
                              border: Border.all(
                                color: Colors.blue.shade900,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _muonNghe ? Icons.mic : Icons.mic_none,
                              color: _muonNghe
                                  ? Colors.white
                                  : Colors.blue.shade900,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // Nút "Nghe lại" và "Tải xuống" đã bỏ — cơ chế ghi âm
                      // đã kiểm chứng hoạt động đúng (không cần công cụ
                      // kiểm tra nhanh này nữa), thẻ đã được nghe qua Gemini
                      // phiên âm là đủ tin cậy.
                    ],
                  ),
                  if (_dangGhiAm)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Center(
                        child: Text(
                          'Đang ghi âm… bấm lại để dừng.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Tên trang.
                  Center(
                    child: Text(
                      'Flowrite — thử micro trên Web ($_phienBanThuNghiem)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ], // đóng `if (!banPhimDangMo) ...[`
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
