# Lỗi tồn đọng — hoãn sửa

## Thỉnh thoảng không gõ được bằng bàn phím vật lý sau mất/được tiêu điểm (bản Web)

**Mô tả:** Trên thiết bị có gắn bàn phím vật lý (máy tính, hoặc điện
thoại/tablet gắn bàn phím ngoài), đôi lúc sau khi ô soạn thảo mất tiêu
điểm rồi được lại (ví dụ chạm ra khoảng trống rồi chạm lại vào ô), gõ
bàn phím vật lý không chèn được ký tự nữa — phải F5 mới hết. Người dùng
xác nhận: đã nhẹ đi rất nhiều sau khi thêm bước dọn `TextInput.clearClient`
ở `_khiFocusConTroDoi` (nhánh `thu-nghiem/sua-cuon-man-hinh`, v150), nhưng
vẫn còn xuất hiện lại lâu lâu — không có cách mô tả chính xác hơn để tái
hiện lại theo yêu cầu.

**Quyết định (2026-10-04):** người dùng yêu cầu HOÃN sửa tiếp — chưa mô tả
được chính xác hiện tượng còn sót để điều tra tiếp. Khi được nhờ sửa lại,
hỏi người dùng mô tả MỚI chi tiết hơn (bấm gì, thứ tự nào, trước đó đang
làm gì) trước khi thử hướng mới — đừng giả định giống y hệt mô tả gốc ở
trên vì bản thân nó cũng chỉ là suy đoán, chưa chắc đúng gốc rễ hoàn toàn.
Hướng đã thử: dọn kết nối bàn phím ảo (`TextInput.clearClient`) ngay lúc
tiêu điểm vừa chuyển từ mất sang có lại — xem `_khiFocusConTroDoi` ở
`trang_soan_thao.dart`.

## "Bãi đất trống" kẹt lại sau khi ẩn bàn phím ảo (bản Web)

**Mô tả:** Khi bật "Bộ phím nhanh cho màn hình cảm ứng" VÀ đồng thời bật nút
"bàn phím" bên trong nó (bàn phím ảo hệ thống hiện song song với các thanh
công cụ của Bộ phím nhanh), rồi bấm một số nút trong Bộ phím nhanh (ví dụ
Copy, bấm lặp lại vài lần), sau đó ẩn bàn phím ảo bằng nút Back của
Android — bàn phím ảo biến mất nhưng khoảng trống nó từng chiếm bị KẸT
LẠI, không co lại cho các thành phần phía trên trôi xuống lấp đầy. Trang
bị hẹp chiều cao, nhìn xấu. Không mất dữ liệu.

**Cách né tạm thời:** bấm một trong các nút "*", bàn phím, Lùi lại, Tiến
tới (ở Bộ phím nhanh), nút ẩn/hiện điều hướng, Đóng — lỗi tự biến mất
ngay, không cần tải lại trang. (Nút "Ẩn" từng nằm trong danh sách này đã
bỏ hẳn khỏi Bộ phím nhanh — xem phần sau của tệp này nếu cần biết lý do.)

**Đã thử (chưa dứt điểm):**
1. Thêm `didChangeMetrics` (override `WidgetsBindingObserver`, gọi
   `setState` rỗng) trong `lib/trang_soan_thao.dart` — KHÔNG đủ. Nghi ngờ:
   có đường ẩn bàn phím ảo (đặc biệt qua nút Back của Android) mà Flutter
   Engine không dịch lại thành sự kiện `didChangeMetrics` cho code Dart.
2. Thêm `lib/nghe_resize_trinh_duyet*.dart` — nghe THẲNG
   `window.onResize` của trình duyệt qua `dart:html`, độc lập hẳn với tầng
   Flutter Engine, rồi ép `setState`. Đăng ký ở `initState`, huỷ ở
   `dispose` của `_TrangSoanThaoState`. Người dùng xác nhận VẪN CÒN LỖI
   sau bản vá này (v50).

**Quyết định (2026-09-22):** người dùng yêu cầu HOÃN sửa tiếp — đã thử 2
lần không xong, sắp hết thời gian dự án. Không tự ý thử thêm hướng khác
khi chưa được yêu cầu. Khi được nhờ sửa lại (khoảng 1 tháng sau, hoặc bất
cứ khi nào người dùng thấy khó chịu và chủ động nhắc), đọc đúng mục này
trước — ĐỪNG hỏi người dùng mô tả lại lỗi từ đầu, đã có đủ mô tả và lịch
sử các hướng đã thử ở trên.

**Đã thử lần 3 (2026-10-02, v121, người dùng chủ động nhờ sửa lại):** đổi
tư duy — thay vì tiếp tục thêm một đường NGHE SỰ KIỆN khác (đã có 2, cả
hai đều có đường "hụt"), chủ động THĂM DÒ (poll) chiều cao viewport thật
mỗi 300ms qua `visualViewport.height`/`innerHeight` (hàm
`dangKyThamDoChieuCaoVienPort` ở `nghe_resize_trinh_duyet_web.dart`), lệch
so với lần đo trước mới `setState`. Cùng tư duy đã dùng để sửa dứt điểm
lỗi kẹt bàn phím ảo ở Copy/Cắt/Dán/All (đừng tin một sự kiện có thể không
bắn ra — tự xác minh trực tiếp theo nhịp). Đây KHÔNG phải một sự kiện mới
có thể "hụt" giống hai lớp cũ — dù trình duyệt không báo gì, vòng lặp vẫn
tự phát hiện ra chiều cao thật đã đổi ở lượt thăm dò kế tiếp (tối đa trễ
300ms). Nếu người dùng xác nhận VẪN còn lỗi sau bản này, nghĩa là
`visualViewport`/`innerHeight` bản thân nó cũng không đổi giá trị trong
tình huống đó (khác hẳn vấn đề "sự kiện không bắn" đã xác định trước đây)
— khi đó hướng `resizeToAvoidBottomInset: true` (để `Scaffold` tự lo, bỏ
hẳn cơ chế tự đo `caoBanPhim` hiện tại) mới còn đáng thử, rủi ro cao hơn vì
có thể phá vỡ lý do ban đầu chọn `false`, cần đọc kỹ code trước khi đổi.

**Đã thử lần 4 (2026-10-02, v123):** v121 đỡ hẳn (người dùng xác nhận: chỉ
cần bấm MỘT nút bất kỳ là hết ngay, không cần bấm nhiều nút/F5 như trước
nữa) — nhưng vẫn CHƯA hết hoàn toàn. Điều đó cho thấy đúng dự đoán ở lần
3: `MediaQuery.viewInsets` nội bộ Flutter đã có giá trị ĐÚNG, chỉ thiếu
một `setState` để vẽ lại — còn phép ĐO JS (`visualViewport.height`/
`innerHeight`) ở lần 3 KHÔNG hề đổi trong đúng tình huống lỗi này (lý do
vòng thăm dò không tự phát hiện ra). Sửa ở v123: bỏ hẳn việc so sánh số
đo, đổi `dangKyThamDoChieuCaoVienPort` thành một "nhịp tim" ép `setState`
VÔ ĐIỀU KIỆN mỗi 300ms — làm đúng việc một nút bấm tình cờ làm được, tự
động, không cần đợi người dùng.

**Quyết định (2026-10-02): DỪNG sửa tiếp, dù đã đỡ hơn rất nhiều.** Người
dùng xác nhận sau v123 lỗi VẪN CÒN (dù bây giờ phải nhẹ hơn RẤT NHIỀU so
với lúc đầu — không rõ còn tồn đọng ở mức độ nào, cần hỏi lại người dùng
mô tả hiện tượng mới nếu được nhờ sửa tiếp, ĐỪNG giả định giống mô tả cũ ở
đầu tệp này) và yêu cầu KHÔNG sửa nữa, hẹn một dịp khác. Đã thử 4 lần:
1. `didChangeMetrics` (không đủ — Flutter Engine không dịch lại sự kiện
   cho một số đường ẩn bàn phím ảo qua nút Back).
2. Nghe thẳng `window.onResize` qua `dart:html` (không đủ — trình duyệt
   cũng không luôn bắn `resize` cho đúng tình huống này).
3. Thăm dò (poll) SO SÁNH `visualViewport.height`/`innerHeight` mỗi 300ms,
   chỉ `setState` khi THẤY LỆCH (đỡ hẳn, nhưng chưa hết — số đo JS không
   đổi trong tình huống lỗi nên không tự phát hiện ra).
4. Thăm dò KHÔNG so sánh — ép `setState` vô điều kiện mỗi 300ms (nhịp
   tim). Đỡ hơn lần 3 nhưng CHƯA xác nhận hết hẳn.
ĐỪNG lặp lại 4 hướng trên nếu được nhờ sửa tiếp. Hướng CHƯA thử, đáng xem
trước tiên: đổi khoảng thăm dò 300ms xuống ngắn hơn (ví dụ 100-150ms) xem
có giảm thêm độ trễ cảm nhận được hay không (rẻ, ít rủi ro); nếu không ăn
thua nữa mới tới hướng rủi ro cao hơn: `resizeToAvoidBottomInset: true`
(để `Scaffold` tự lo, bỏ hẳn cơ chế tự đo `caoBanPhim` hiện tại) — có thể
phá vỡ lý do ban đầu chọn `false`, đọc kỹ code trước khi đổi.

**Né vấn đề thay vì sửa (2026-09-22):** lỗi này KHÔNG xảy ra ở bản APK
(chỉ web). Đã thêm dải gợi ý "Tải app APK" (nền xanh dương nhạt, dưới dải
lỗi `_loi`, trong `lib/trang_soan_thao.dart`) — chỉ hiện khi `kIsWeb` VÀ
thiết bị là Android, dẫn tới
`https://github.com/sotay99/ghi-noi/releases/latest`. Bấm X đóng thì nhớ
luôn (`caiDat.anGoiYTaiApk`, không hiện lại). Xem thêm
`lib/mo_lien_ket_ngoai*.dart` (mở tab mới trên web, no-op trên gốc).
