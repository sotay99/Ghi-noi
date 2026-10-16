#!/usr/bin/env python3
"""Vá phần Web do `flutter create` sinh ra.

Thư mục web/ không nằm trong git (xem .gitignore): mỗi lần dựng, máy chủ tự
sinh lại nó, rồi chạy script này để chép đè icon app bằng logo Flowrite —
đúng khuôn với `va_android.py` (icon dựng SẴN trong `tool/icon/cho_web/` —
KHÔNG đặt tên "web", `.gitignore` có dòng "web/" khớp cả thư mục con tên
"web" nằm sâu bên trong — không cần công cụ render ảnh nào lúc build).

`flutter create --platforms=web` luôn sinh đúng 5 tên tệp cố định dưới
`web/icons/` (Icon-192.png, Icon-512.png, Icon-maskable-192.png,
Icon-maskable-512.png) cộng `web/favicon.png` ở thư mục gốc — `web/manifest.json`
và `web/index.html` đã tự trỏ sẵn tới đúng những tên này, nên chỉ cần chép
đè ĐÚNG NỘI DUNG, không phải sửa JSON/HTML gì cả.

Script này CŨNG vá thêm `web/index.html`: đổi `<title>` thành "Flowrite"
(mặc định là "flowrite" — tên project viết thường) và chèn thẻ Open Graph
(`og:title`/`og:description`/`og:image`...) để link chia sẻ dán vào Zalo/
Messenger/Facebook hiện đúng tên + mô tả + logo thay vì trống trơn — các
nền tảng đó đọc thẳng thẻ `<meta property="og:...">`, không đọc `manifest.json`
hay icon PWA.
"""
import re
import shutil
import sys
from pathlib import Path

GOC = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
ICON_WEB_DIR = Path(__file__).resolve().parent / 'icon' / 'cho_web'

ICON_GOC = ('favicon.png',)
ICON_CON = ('Icon-192.png', 'Icon-512.png', 'Icon-maskable-192.png', 'Icon-maskable-512.png')

# Domain thật của bản Web ĐẦY ĐỦ (channel "live", xem deploy-web-full.yml) —
# og:image BẮT BUỘC là URL TUYỆT ĐỐI, Zalo/Facebook không tự ghép domain.
_DOMAIN_THAT = 'https://flowrite219.web.app'
_MO_TA = (
    'Flowrite — ghi chú bằng giọng nói, nói và gõ tay cùng lúc, có trợ lý AI, '
    'đồng bộ nhiều thiết bị.'
)
_THE_OG = (
    f'  <meta property="og:title" content="Flowrite">\n'
    f'  <meta property="og:description" content="{_MO_TA}">\n'
    f'  <meta property="og:image" content="{_DOMAIN_THAT}/icons/Icon-512.png">\n'
    f'  <meta property="og:type" content="website">\n'
    f'  <meta property="og:url" content="{_DOMAIN_THAT}/">\n'
)


def _va_index_html() -> bool:
    tep = GOC / 'web' / 'index.html'
    if not tep.exists():
        print(f'LOI: khong thay {tep}', file=sys.stderr)
        return False
    chu = tep.read_text(encoding='utf-8')

    chu, _ = re.subn(r'<title>.*?</title>', '<title>Flowrite</title>', chu, count=1)

    if 'property="og:title"' not in chu:
        n = chu.count('</head>')
        if n == 0:
            print('LOI: khong thay </head> trong web/index.html', file=sys.stderr)
            return False
        chu = chu.replace('</head>', _THE_OG + '</head>', 1)

    tep.write_text(chu, encoding='utf-8')
    return True


def main() -> int:
    thu_muc_web = GOC / 'web'
    if not thu_muc_web.is_dir():
        print(f'LOI: khong thay {thu_muc_web}', file=sys.stderr)
        return 1

    thieu = [t for t in (*ICON_GOC, *ICON_CON) if not (ICON_WEB_DIR / t).exists()]
    if thieu:
        print(f'LOI: thieu icon da dung san {thieu} trong {ICON_WEB_DIR}', file=sys.stderr)
        return 1

    so_chep = 0
    for ten in ICON_GOC:
        dich = thu_muc_web / ten
        if dich.exists():
            shutil.copyfile(ICON_WEB_DIR / ten, dich)
            so_chep += 1
    for ten in ICON_CON:
        dich = thu_muc_web / 'icons' / ten
        if dich.exists():
            shutil.copyfile(ICON_WEB_DIR / ten, dich)
            so_chep += 1

    if so_chep == 0:
        print('LOI: khong chep duoc icon nao — cau truc web/ co the da doi', file=sys.stderr)
        return 1

    if not _va_index_html():
        return 1

    print(f'Da thay {so_chep} icon bang logo Flowrite, da va index.html.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
