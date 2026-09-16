# Flowrite

Một trang văn bản trắng. Gõ chữ bằng bàn phím, hoặc bấm nút micro rồi nói —
chữ hiện ra theo thời gian thực, ngay tại vị trí con trỏ. Hai cách nhập chạy
song song: đang nói vẫn gõ phím được; gõ phím thì ngắt hẳn micro trong một
giây rồi tự bật lại.

Nhiều ghi chú, sắp xếp theo cây thư mục — thêm/đổi tên/xoá/sao chép/cắt-di
chuyển thư mục và ghi chú.

Viết bằng **Flutter (Dart)** để sau này dựng thêm bản iOS từ cùng bộ mã.

## Lấy file APK

Mỗi lần đẩy mã lên, GitHub Actions tự dựng APK và đưa vào mục
**Releases** của kho này. Mở bằng điện thoại, tải tệp `Flowrite-vN.apk`,
Android hỏi "cài từ nguồn không xác định" thì đồng ý.

APK ký bằng một khoá CỐ ĐỊNH của riêng Flowrite (`tool/ky/flowrite-release
.keystore`, xem `tool/va_android.py`), không phải debug key ngẫu nhiên của
máy dựng — nhờ vậy cài đè bản mới lên bản cũ được bình thường, không cần gỡ
cài đặt trước (Android từ chối cập nhật nếu chữ ký thay đổi giữa các lần).
Vẫn chưa ký được cho Google Play (cần khoá riêng do Google quản lý).

## Cấu trúc mã nguồn

```
lib/main.dart            điểm khởi động, nạp kho dữ liệu
lib/mo_hinh.dart          mô hình ThuMuc và GhiChuFile
lib/kho_du_lieu.dart      đọc/ghi cây thư mục vào SharedPreferences
lib/man_hinh_thu_muc.dart màn hình duyệt/sửa cây thư mục
lib/thanh_cong_cu.dart    thanh công cụ dưới màn hình soạn thảo
lib/trang_soan_thao.dart  màn hình soạn thảo — micro, bàn phím, chèn chữ
tool/va_android.py       vá AndroidManifest sau khi sinh phần Android
.github/workflows/       dựng APK và đưa lên Releases
```

### Vì sao không có thư mục `android/` trong kho

Phần Android do `flutter create` sinh ra lúc dựng, bằng đúng phiên bản Flutter
đang dùng, rồi `tool/va_android.py` thêm vào những thứ riêng của app: quyền
`RECORD_AUDIO`/`INTERNET`, khối `<queries>` khai `RecognitionService` (thiếu
nó thì trên Android 11 trở lên micro im lặng mà không báo lỗi gì), tên hiển
thị "Flowrite", và nâng `compileSdk` trong `build.gradle.kts` lên mức các gói
phụ thuộc đòi hỏi (ví dụ `permission_handler_android` đòi 37, cao hơn mức mặc
định Flutter tạo sẵn) — thiếu bước này thì Gradle từ chối dựng ngay từ đầu.

## Cơ chế chèn chữ tại con trỏ

`_neo` giữ vị trí bắt đầu câu đang đọc dở, `_chuTam` giữ NGUYÊN VĂN đoạn chữ
tạm đã chèn — không chỉ độ dài. Trước mỗi lần ghi, `_vungTamConNguyen()` đọc
lại trong bài xem đoạn đó còn đúng chỗ cũ không; không còn thì đặt mốc mới,
không đè bừa. Nhờ vậy mốc có lệch (bộ gõ báo trạng thái ngược về bất đồng bộ)
cũng không sinh ra chữ lặp.

## Đánh dấu nguồn gốc từng ký tự — tự động chèn dấu cách

`_nguonKyTu` là một danh sách song song với toàn bộ văn bản, mỗi ô ghi ký tự
đó do **tay gõ** (`true`) hay do **giọng nói tạo ra** (`false`). Luôn dài bằng
đúng văn bản hiện tại; mọi chỗ đổi chữ (giọng nói chèn, tay gõ chèn/xoá, mở
ghi chú khác) đều phải cập nhật danh sách này theo cùng một nhịp.

Gõ dính ngay sau một ký tự do giọng nói tạo ra (và ký tự đó chưa phải khoảng
trắng) thì tự chèn một dấu cách trước — coi như bộ gõ không biết trước đó câu
nói đã kết thúc chưa. Gõ dính sau ký tự do tay gõ thì để dính bình thường,
coi như người dùng cố ý.

Văn bản mở từ một ghi chú đã lưu (kể cả lần đầu mở app) luôn được coi là toàn
bộ **do tay gõ** — không biết gốc gác thật của nó nữa. Bấm nút **Lưu**, bấm
**Xoá tất cả** đưa danh sách này về lại trạng thái mặc định đó (không phải
để trống, mà đặt lại toàn bộ về "tay gõ", vì danh sách luôn phải dài bằng văn
bản). Chép toàn bộ (**Chép tất cả**) KHÔNG đụng đến danh sách này — chép là
hành động chỉ đọc, không kết thúc phiên soạn thảo.

## Giới hạn đã biết — không sửa được bằng mã

Android tự ngắt nhận dạng sau vài giây im lặng. App bật lại sau 200 ms, nên
nhìn như micro luôn bật, nhưng nói đúng vào khe chuyển tiếp có thể rơi vài
chữ. Đây là cách hệ điều hành làm việc.

Nhận dạng cần Internet để chính xác, và máy phải có ứng dụng Google cùng gói
tiếng Việt cho nhận dạng giọng nói.

## Sau này làm bản iOS

Bộ mã đã chạy được trên iOS (gói `speech_to_text` gọi `SFSpeechRecognizer`
của Apple, liền mạch hơn Android). Còn thiếu:

- một chiếc iPhone thật — không có cách nào thay thế
- tài khoản Apple Developer (99 đô/năm) để ký ứng dụng
- dựng bằng Codemagic hoặc máy ảo macOS của GitHub Actions, không cần PC

Khi làm, thêm vào `ios/Runner/Info.plist` hai mục
`NSMicrophoneUsageDescription` và `NSSpeechRecognitionUsageDescription`.
