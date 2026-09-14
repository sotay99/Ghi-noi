# Máy chủ trung gian AI của Flowrite — bản Google Cloud Functions

Bản này thay cho `worker/flowrite-ai-worker.js` (Cloudflare). Lý do đổi: gói
Cloudflare miễn phí cứ định tuyến yêu cầu của bạn qua trạm Hồng Kông, mà
Gemini API chặn hẳn khu vực đó (lỗi "User location is not supported"). Đặt
máy chủ ngay trong hạ tầng Google thì không còn trạm trung gian nào để bị
chặn theo vùng nữa.

Kiến trúc và logic giữ nguyên như bản Cloudflare:

```
Điện thoại/máy tính bảng (app Flowrite)  →  Cloud Function này (giữ khoá)  →  Gemini API
```

Một điểm cuối duy nhất phục vụ mọi tính năng AI trong app (tóm tắt, mở rộng,
gọt dũa, đề xuất ý tưởng, trò chuyện...) — chỉ khác nhau ở tham số `action`
gửi lên. Xem `huongDanTheoHanhDong()` trong `index.js`.

Toàn bộ các bước dưới đây làm được **hoàn toàn bằng trình duyệt**, không cần
máy tính, không cần cài gì — hợp với máy tính bảng của bạn.

## Làm theo đúng thứ tự dưới đây

### Bước 1 — Bật thanh toán cho dự án

Cloud Functions cần một tài khoản thanh toán được gắn vào dự án, kể cả khi
bạn chỉ dùng trong hạn mức miễn phí hàng tháng.

1. Mở **console.cloud.google.com/billing** bằng trình duyệt.
2. Vào tab **Dự án** (Projects).
3. Tìm dự án **"Ứng dụng Flowrite ghi-noi"** (mã dự án dạng
   `gen-lang-client-...`) — đây là dự án Google đã tự tạo lúc bạn lấy khoá
   Gemini ở Google AI Studio.
4. Nếu dự án đó đang ghi "Không có tài khoản thanh toán" (No billing
   account), bấm vào dự án đó, chọn **Liên kết tài khoản thanh toán**
   (Link a billing account), rồi chọn tài khoản **"Thanh toán Firebase"**
   đã có sẵn (chính là tài khoản bạn dùng cho thanh toán Firebase, đang có
   0đ chi tiêu 30 ngày qua theo ảnh bạn gửi).
5. Xác nhận liên kết.

**Không tạo tài khoản thanh toán mới** — dùng lại tài khoản Firebase sẵn có
là đủ.

### Bước 2 — Bật hai API cần thiết

1. Mở **console.cloud.google.com/functions**, đảm bảo dự án đang chọn ở góc
   trên là đúng **"Ứng dụng Flowrite ghi-noi"**.
2. Nếu Google hỏi "Enable Cloud Functions API", bấm **Enable/Bật**.
3. Tương tự, khi tạo hàm ở Bước 3, nếu Google hỏi bật thêm **Cloud Build
   API** hoặc **Artifact Registry API**, cứ bấm **Enable/Bật** hết — đều nằm
   trong hạn mức miễn phí với quy mô dùng của một app cá nhân.

### Bước 3 — Tạo hàm (Cloud Function)

1. Ở trang **Cloud Functions**, bấm **Create Function / Tạo hàm**.
2. Chọn **2nd gen** (thế hệ 2) nếu được hỏi chọn thế hệ.
3. **Tên hàm (Function name):** `flowrite-ai` (hoặc tên khác tuỳ bạn, không
   quan trọng).
4. **Vùng (Region):** chọn `asia-southeast1 (Singapore)` — **không chọn bất
   kỳ vùng nào ở Hồng Kông**. Singapore vừa gần Việt Nam vừa không bị Gemini
   chặn.
5. **Trigger type:** HTTPS.
6. **Authentication:** chọn **Allow unauthenticated invocations / Cho phép
   gọi không cần xác thực** — việc xác thực app đã tự làm bằng "mật khẩu"
   riêng (`x-flowrite-secret`) ở tầng ứng dụng, không cần lớp xác thực của
   Google ở đây.
7. Bấm **Next / Tiếp theo** để sang phần nhập mã nguồn.
8. **Runtime:** chọn **Node.js 20**.
9. **Entry point:** gõ đúng `flowriteAi` (phải khớp chính xác tên hàm
   `exports.flowriteAi` trong `index.js`, phân biệt chữ hoa/thường).
10. Trong khung soạn thảo mã nguồn hiện ra bên phải, có hai tệp
    `index.js` và `package.json`:
    - Xoá hết nội dung mẫu trong `index.js`, dán toàn bộ nội dung tệp
      `index.js` gửi kèm vào.
    - Xoá hết nội dung mẫu trong `package.json`, dán toàn bộ nội dung tệp
      `package.json` gửi kèm vào.
11. **Chưa bấm Deploy vội** — sang Bước 4 để đặt biến môi trường trước.

### Bước 4 — Đặt ba biến môi trường (bí mật)

Vẫn ở màn hình tạo hàm, tìm phần **Runtime, build, connections and
security settings** (thường ẩn dưới một mũi tên xổ xuống) → tab
**Runtime environment variables** (Biến môi trường thời gian chạy).

Bấm **Add variable / Thêm biến** ba lần, nhập đúng ba cặp tên-giá trị sau:

| Tên biến | Giá trị |
|---|---|
| `GEMINI_API_KEY` | khoá Gemini của bạn (chuỗi bắt đầu `AIza...`) |
| `APP_SHARED_SECRET` | `hGzPGCntDDGc0cfAkzePuypITzrJHA55ltIvl9zq` (dùng lại đúng chuỗi đã đặt cho Worker Cloudflare trước đây) |
| `GEMINI_MODEL` | `gemini-flash-lite-latest` |

Ba biến này KHÔNG được gõ thẳng vào `index.js` — mã nguồn chỉ đọc chúng qua
`process.env`, giữ đúng nguyên tắc bí mật không nằm trong mã.

### Bước 5 — Triển khai

Bấm **Deploy / Triển khai** ở cuối trang. Quá trình build và triển khai mất
khoảng 2-5 phút — cứ để yên, đừng đóng tab.

Xong, vào lại trang chi tiết hàm `flowrite-ai`, tab **Trigger**, sẽ thấy một
địa chỉ dạng:

```
https://flowrite-ai-xxxxxxxxxx-as.a.run.app
```

**Gửi đúng địa chỉ này cho tôi** — tôi sẽ nối nó vào app Flowrite. Không cần
gửi khoá Gemini hay chuỗi bí mật, chỉ cần gửi địa chỉ này thôi.

### Bước 6 — Thử bằng Hoppscotch.io

1. Mở **hoppscotch.io** bằng trình duyệt.
2. Chọn phương thức **POST**, dán địa chỉ hàm vừa lấy ở Bước 5 vào ô URL.
3. Tab **Headers**, thêm hai dòng:
   - `content-type` → `application/json`
   - `x-flowrite-secret` → `hGzPGCntDDGc0cfAkzePuypITzrJHA55ltIvl9zq`
4. Tab **Body**, chọn kiểu **JSON**, dán:
   ```json
   {"action":"tom_tat","text":"Đây là một đoạn văn bản thử nghiệm để xem máy chủ có gọi được Gemini và trả lời đúng hay không."}
   ```
5. Bấm **Send**.

Trả lời đúng thì thấy JSON dạng `{"text":"..."}`. Nếu thấy `{"loi":"..."}`,
đọc đúng câu lỗi đó và gửi lại cho tôi để chẩn đoán tiếp.

## Sau này thêm tính năng AI mới trong app

Không cần hàm riêng cho mỗi tính năng. Chỉ cần:
1. Thêm một `case` mới trong `huongDanTheoHanhDong()` ở `index.js`.
2. Vào lại trang hàm trên Cloud Console → **Edit / Sửa** → dán mã mới →
   **Deploy** lại.
3. Phía app gọi cùng một địa chỉ, chỉ đổi giá trị `action` gửi lên.

## Cloudflare Worker cũ

Có thể để yên `worker/flowrite-ai-worker.js` không dùng tới — không tốn phí
gì cả dù không gọi tới nó nữa. Khoá Gemini vẫn dùng chung một khoá cho cả
hai nơi, không cần tạo khoá mới.
