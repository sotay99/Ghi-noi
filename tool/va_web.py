#!/usr/bin/env python3
"""Vá web/index.html do `flutter create` sinh ra.

Thư mục web/ không nằm trong git: mỗi lần dựng, máy chủ tự sinh lại nó bằng
đúng phiên bản Flutter đang dùng, rồi chạy script này để thêm đoạn mã riêng
của Flowrite trước khi build.

Chiến lược PWA mặc định của Flutter Web (offline-first) tự lưu toàn bộ mã app
vào Service Worker để chạy được khi mất mạng — nhưng đổi lại, khi có bản mới,
trình duyệt để bản Service Worker mới nằm "chờ" (không kích hoạt ngay) cho tới
khi NGƯỜI DÙNG ĐÓNG HẲN mọi tab đang mở trang — bấm F5 không đóng tab, nên
Service Worker CŨ vẫn tiếp tục phục vụ lại mã CŨ dù máy chủ đã có bản mới.
Đoạn mã vá thêm dưới đây giữ nguyên khả năng chạy offline, nhưng buộc bản mới
kích hoạt ngay khi phát hiện ra (gọi `skipWaiting` — chính Service Worker do
Flutter sinh ra đã có sẵn người nghe cho tin này) rồi tải lại trang MỘT LẦN,
để F5 (hay mở lại tab bình thường) luôn ra đúng bản mới nhất.
"""
import sys
from pathlib import Path

GOC = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
INDEX = GOC / 'web' / 'index.html'

# Đánh dấu để chạy script này nhiều lần (lỡ CI chạy lại) không chèn trùng.
DAU_HIEU = '<!-- flowrite:buoc-f5-lay-ban-moi -->'

DOAN_VA = f'''{DAU_HIEU}
<script>
  // Giữ Service Worker offline-first như mặc định của Flutter, nhưng buộc
  // bản mới kích hoạt ngay khi tải trang (không chờ đóng hết tab cũ), rồi
  // tải lại MỘT LẦN — để F5 luôn ra đúng bản mới nhất, không cần người dùng
  // tự xoá cache. Theo đúng cách Flutter tài liệu hoá:
  // https://docs.flutter.dev/platform-integration/web/initialization
  //
  // SỬA LẦN 2: bản đầu chỉ nghe sự kiện 'updatefound' — nhưng trình duyệt
  // có thể đã âm thầm dò và cài xong bản mới (nằm sẵn ở `registration.
  // waiting`) TRƯỚC KHI đoạn mã này kịp gắn người nghe vào (đúng lúc trang
  // vừa tải xong) — bỏ lỡ sự kiện đó thì bản mới nằm chờ MÃI MÃI, không bao
  // giờ được đẩy lên, y hệt lỗi ban đầu. Sửa: kiểm `registration.waiting`
  // NGAY LẬP TỨC sau khi lấy được registration (bắt kịp trường hợp lỡ mất
  // sự kiện), và tự gọi `update()` để buộc dò bản mới ngay lúc này thay vì
  // trông chờ trình duyệt tự dò theo lịch riêng của nó.
  if ('serviceWorker' in navigator) {{
    function baoBanMoiKichHoatNgay(dangKy) {{
      if (dangKy.waiting) {{
        dangKy.waiting.postMessage('skipWaiting');
      }}
    }}
    navigator.serviceWorker.getRegistration().then(function (dangKy) {{
      if (!dangKy) return;
      baoBanMoiKichHoatNgay(dangKy);
      dangKy.addEventListener('updatefound', function () {{
        var moi = dangKy.installing;
        if (!moi) return;
        moi.addEventListener('statechange', function () {{
          if (moi.state === 'installed') baoBanMoiKichHoatNgay(dangKy);
        }});
      }});
      dangKy.update();
    }});
    var daTaiLaiRoi = false;
    navigator.serviceWorker.addEventListener('controllerchange', function () {{
      if (daTaiLaiRoi) return;
      daTaiLaiRoi = true;
      window.location.reload();
    }});
  }}
</script>
'''


def main() -> int:
    if not INDEX.exists():
        print(f'Khong thay {INDEX}', file=sys.stderr)
        return 1

    chu = INDEX.read_text(encoding='utf-8')
    if DAU_HIEU in chu:
        print('web/index.html da duoc va tu truoc, bo qua.')
        return 0

    if '</body>' not in chu:
        print('LOI: khong tim thay </body> trong web/index.html', file=sys.stderr)
        return 1

    chu = chu.replace('</body>', DOAN_VA + '</body>', 1)
    INDEX.write_text(chu, encoding='utf-8')
    print('Da va web/index.html: F5 se luon lay ban moi, van giu offline.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
