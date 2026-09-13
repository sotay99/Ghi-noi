# Ghi Nói

Một trang văn bản trắng. Gõ chữ bằng bàn phím, hoặc bấm nút micro rồi nói —
chữ hiện ra theo thời gian thực, ngay tại vị trí con trỏ. Hai cách nhập chạy
song song: đang nói vẫn gõ phím được, và micro không tắt khi gõ.

Viết bằng **Flutter (Dart)** để sau này dựng thêm bản iOS từ cùng bộ mã.

## Lấy file APK

Mỗi lần đẩy mã lên, GitHub Actions tự dựng APK và đưa vào mục
**Releases** của kho này. Mở bằng điện thoại, tải tệp `GhiNoi-vN.apk`,
Android hỏi "cài từ nguồn không xác định" thì đồng ý.

APK ký bằng khoá thử (debug key): cài vào máy riêng thì được, đưa lên
Google Play thì chưa được.

## Cấu trúc

```
lib/main.dart        toàn bộ ứng dụng
tool/va_android.py   vá AndroidManifest sau khi sinh phần Android
.github/workflows/   dựng APK và đưa lên Releases
```

### Vì sao không có thư mục `android/` trong kho

Phần Android do `flutter create` sinh ra lúc dựng, bằng đúng phiên bản Flutter
đang dùng, rồi `tool/va_android.py` thêm vào ba thứ riêng của app:

- quyền `RECORD_AUDIO` và `INTERNET`
- khối `<queries>` khai `android.speech.RecognitionService` — thiếu nó thì trên
  Android 11 trở lên micro im lặng mà không báo lỗi gì
- tên hiển thị "Ghi Nói"

Cách này tránh được chuyện Gradle lệch phiên bản sau vài tháng. Khi nào cần
sửa sâu phần Android (biểu tượng riêng, ký khoá thật), thì mới đưa thư mục đó
vào kho.

## Cơ chế chèn chữ tại con trỏ

`_neo` giữ vị trí bắt đầu câu đang đọc dở, `_daiTam` giữ độ dài phần chữ tạm
đã chèn. Mỗi kết quả mới thay đúng đoạn `[_neo, _neo + _daiTam)` — nhờ vậy chữ
được sửa dần tại chỗ thay vì lặp lại.

Khi người dùng gõ phím hoặc bấm dời con trỏ, `_khiNguoiDungSua()` chốt phần
chữ tạm lại và dời neo về chỗ con trỏ mới. Cờ `_tuSua` để phân biệt lần sửa
nào là của máy, lần nào là của người.

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
