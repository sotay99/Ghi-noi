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
  if ('serviceWorker' in navigator) {{
    navigator.serviceWorker.getRegistration().then(function (dangKy) {{
      if (!dangKy) return;
      dangKy.addEventListener('updatefound', function () {{
        var moi = dangKy.installing;
        if (!moi) return;
        moi.addEventListener('statechange', function () {{
          if (moi.state === 'installed' && dangKy.waiting) {{
            moi.postMessage('skipWaiting');
          }}
        }});
      }});
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
