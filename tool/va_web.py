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
"""
import shutil
import sys
from pathlib import Path

GOC = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
ICON_WEB_DIR = Path(__file__).resolve().parent / 'icon' / 'cho_web'

ICON_GOC = ('favicon.png',)
ICON_CON = ('Icon-192.png', 'Icon-512.png', 'Icon-maskable-192.png', 'Icon-maskable-512.png')


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

    print(f'Da thay {so_chep} icon bang logo Flowrite.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
