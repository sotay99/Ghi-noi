# Lỗi tồn đọng — hoãn sửa

## "Bãi đất trống" kẹt lại sau khi ẩn bàn phím ảo (bản Web)

**Mô tả:** Khi bật "Bộ phím nhanh cho màn hình cảm ứng" VÀ đồng thời bật nút
"bàn phím" bên trong nó (bàn phím ảo hệ thống hiện song song với các thanh
công cụ của Bộ phím nhanh), rồi bấm một số nút trong Bộ phím nhanh (ví dụ
Copy, bấm lặp lại vài lần), sau đó ẩn bàn phím ảo bằng nút Back của
Android — bàn phím ảo biến mất nhưng khoảng trống nó từng chiếm bị KẸT
LẠI, không co lại cho các thành phần phía trên trôi xuống lấp đầy. Trang
bị hẹp chiều cao, nhìn xấu. Không mất dữ liệu.

**Cách né tạm thời:** bấm một trong bảy nút "*", bàn phím, Lùi lại, Tiến
tới (ở Bộ phím nhanh), nút ẩn/hiện điều hướng, Ẩn, Đóng — lỗi tự biến mất
ngay, không cần tải lại trang.

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
sử các hướng đã thử ở trên. Hướng chưa thử: gắn `visualViewport` (thay vì
`window.onResize` thường) nếu trình duyệt hỗ trợ; hoặc đổi hẳn sang
`resizeToAvoidBottomInset: true` (để `Scaffold` tự lo, bỏ hẳn cơ chế tự đo
`caoBanPhim` hiện tại) — rủi ro cao hơn vì có thể phá vỡ lý do ban đầu
chọn `false`, cần đọc kỹ code trước khi đổi.

**Né vấn đề thay vì sửa (2026-09-22):** lỗi này KHÔNG xảy ra ở bản APK
(chỉ web). Đã thêm dải gợi ý "Tải app APK" (nền xanh dương nhạt, dưới dải
lỗi `_loi`, trong `lib/trang_soan_thao.dart`) — chỉ hiện khi `kIsWeb` VÀ
thiết bị là Android, dẫn tới
`https://github.com/sotay99/ghi-noi/releases/latest`. Bấm X đóng thì nhớ
luôn (`caiDat.anGoiYTaiApk`, không hiện lại). Xem thêm
`lib/mo_lien_ket_ngoai*.dart` (mở tab mới trên web, no-op trên gốc).
