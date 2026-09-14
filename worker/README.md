# Máy chủ trung gian AI của Flowrite

Worker này là nơi DUY NHẤT giữ khoá Gemini. App Flowrite không bao giờ cầm
khoá — nó chỉ gọi vào đây, kèm một "mật khẩu" riêng (không phải khoá Gemini),
Worker mới là nơi thật sự gọi Google.

```
Điện thoại (app Flowrite)  →  Worker này (giữ khoá)  →  Gemini API
```

Một điểm cuối duy nhất phục vụ mọi tính năng AI trong app (tóm tắt, mở rộng,
gọt dũa, đề xuất ý tưởng, trò chuyện...) — chỉ khác nhau ở tham số `action`
gửi lên. Xem `huongDanTheoHanhDong()` trong `flowrite-ai-worker.js`.

## Làm theo đúng thứ tự dưới đây

### Bước 1 — Lấy khoá Gemini (miễn phí)

1. Mở **aistudio.google.com** bằng trình duyệt trên máy tính hoặc điện thoại.
2. Đăng nhập bằng tài khoản Google.
3. Tìm mục **Get API key** (hoặc **API keys** trong menu bên trái).
4. Bấm **Create API key**, chọn một dự án Google Cloud (hoặc để Google tự
   tạo giúp một dự án mới).
5. Copy đoạn khoá hiện ra — chuỗi này bắt đầu bằng `AIza...`. **Giữ kín, đừng
   dán vào đâu công khai** (không dán lên GitHub, không chụp màn hình gửi
   chỗ khác).
6. Trong cùng trang, xem danh sách **model** đang có — model nào ghi
   "free"/miễn phí ở cột giá thì ghi lại đúng tên của nó (ví dụ dạng
   `gemini-2.0-flash`). Tên này có thể đã đổi so với những gì tôi viết sẵn
   trong `wrangler.toml`, vì Google hay đổi tên model theo thời gian —
   không sao, có thể sửa lại bất cứ lúc nào ở Bước 4.

### Bước 2 — Tạo tài khoản Cloudflare (miễn phí)

1. Mở **dash.cloudflare.com**, bấm **Sign up**, đăng ký bằng email.
2. Không cần thêm tên miền hay cấu hình gì thêm — chỉ cần tài khoản tồn tại
   là dùng được Workers.

### Bước 3 — Cài công cụ triển khai (Wrangler)

Wrangler là công cụ dòng lệnh của Cloudflare để đưa mã Worker lên máy chủ
của họ. Cần một máy có cài Node.js (máy tính Windows/Mac/Linux — điện thoại
không cài được cái này).

```sh
npm install -g wrangler
wrangler login
```

Lệnh `wrangler login` sẽ mở trình duyệt để bạn đăng nhập và cho phép Wrangler
thao tác trên tài khoản Cloudflare vừa tạo.

### Bước 4 — Đặt hai bí mật

Đứng trong thư mục `worker/` này (`cd worker`), chạy lần lượt:

```sh
wrangler secret put GEMINI_API_KEY
```
Dán khoá Gemini lấy ở Bước 1 vào khi được hỏi, bấm Enter.

```sh
wrangler secret put APP_SHARED_SECRET
```
Đây **không phải** khoá Gemini — tự bạn bịa ra một chuỗi bất kỳ, càng dài
càng khó đoán càng tốt (ví dụ một chuỗi 32 ký tự ngẫu nhiên). Chuỗi này dùng
để Worker biết yêu cầu gọi tới là từ đúng app Flowrite của bạn, không phải
người lạ gọi ké. Ghi nhớ chuỗi này lại — lát nữa phải dán y hệt vào mã app.

Muốn đổi tên model Gemini đang dùng, sửa dòng `GEMINI_MODEL` trong
`wrangler.toml` (không cần lệnh `secret` vì đây không phải bí mật).

### Bước 5 — Triển khai

```sh
wrangler deploy
```

Chạy xong, dòng cuối cùng in ra một địa chỉ web dạng:

```
https://flowrite-ai-worker.<tên-tài-khoản-của-bạn>.workers.dev
```

**Gửi đúng địa chỉ này cho tôi** (dán vào cuộc trò chuyện) — tôi sẽ nối nó
vào app Flowrite. Bạn không cần gửi khoá Gemini hay chuỗi bí mật, chỉ cần
gửi địa chỉ web này thôi (nó không phải bí mật).

### Bước 6 — Thử trước khi báo tôi (không bắt buộc, nhưng nên làm)

```sh
curl -X POST "https://flowrite-ai-worker.<tên-tài-khoản-của-bạn>.workers.dev" \
  -H "content-type: application/json" \
  -H "x-flowrite-secret: <đúng-chuỗi-bạn-đặt-ở-Bước-4>" \
  -d '{"action":"tom_tat","text":"Đây là một đoạn văn bản thử nghiệm để xem Worker có gọi được Gemini và trả lời đúng hay không."}'
```

Trả lời đúng thì thấy JSON dạng `{"text":"..."}`. Nếu thấy `{"loi":"..."}`,
đọc đúng câu lỗi đó — thường là quên đặt bí mật, hoặc gõ sai chuỗi ở header
`x-flowrite-secret`.

## Sau này thêm tính năng AI mới trong app

Không cần Worker riêng cho mỗi tính năng. Chỉ cần:
1. Thêm một `case` mới trong `huongDanTheoHanhDong()` ở `flowrite-ai-worker.js`.
2. `wrangler deploy` lại.
3. Phía app gọi cùng một địa chỉ, chỉ đổi giá trị `action` gửi lên.
