#!/usr/bin/env python3
"""Dựng lại toàn bộ icon PNG (Android + Web + asset trong app) từ hai tệp
nguồn SVG (`tool/icon/logo.svg` — bản vuông bo góc, `tool/icon/logo_maskable.svg`
— bản full-bleed, nội dung co lại trong vùng an toàn cho icon "maskable" của
Android/PWA). CHỈ chạy TAY khi đổi logo — không chạy trong CI (máy dựng
không có `cairosvg`, và kết quả PNG đã commit sẵn để CI chỉ việc chép đè,
xem `va_android.py`/`va_web.py`).

Cần `cairosvg` (``pip install cairosvg``) — môi trường viết script này dùng
`python3.13 -m pip install cairosvg` vì bản `python3` mặc định không có sẵn
gói này.
"""
import sys
from pathlib import Path

import cairosvg

GOC = Path(__file__).resolve().parent.parent
ICON = GOC / 'tool' / 'icon'
NGUON = ICON / 'logo.svg'
NGUON_MASKABLE = ICON / 'logo_maskable.svg'

ANDROID_MAT_DO = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}

WEB_THUONG = {
    'Icon-192.png': 192,
    'Icon-512.png': 512,
    'favicon.png': 64,
}

WEB_MASKABLE = {
    'Icon-maskable-192.png': 192,
    'Icon-maskable-512.png': 512,
}

ASSET_TRONG_APP = 256  # lib Hero của trang Hướng dẫn — xem assets/logo.png.


def main() -> int:
    if not NGUON.exists() or not NGUON_MASKABLE.exists():
        print(f'LOI: thieu {NGUON} hoac {NGUON_MASKABLE}', file=sys.stderr)
        return 1

    # Tên thư mục KHÔNG được là "android"/"web" trần — `.gitignore` của dự
    # án có dòng "android/" và "web/" (không có "/" ở đầu) khớp CẢ thư mục
    # con cùng tên nằm sâu bên trong, không chỉ thư mục gốc do `flutter
    # create` sinh ra — git sẽ âm thầm bỏ qua, không commit được các icon.
    thu_muc_android = ICON / 'cho_android'
    thu_muc_web = ICON / 'cho_web'
    thu_muc_android.mkdir(parents=True, exist_ok=True)
    thu_muc_web.mkdir(parents=True, exist_ok=True)

    for mat_do, kich in ANDROID_MAT_DO.items():
        cairosvg.svg2png(
            url=str(NGUON), write_to=str(thu_muc_android / f'mipmap-{mat_do}.png'),
            output_width=kich, output_height=kich,
        )

    for ten, kich in WEB_THUONG.items():
        cairosvg.svg2png(
            url=str(NGUON), write_to=str(thu_muc_web / ten),
            output_width=kich, output_height=kich,
        )

    for ten, kich in WEB_MASKABLE.items():
        cairosvg.svg2png(
            url=str(NGUON_MASKABLE), write_to=str(thu_muc_web / ten),
            output_width=kich, output_height=kich,
        )

    (GOC / 'assets').mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        url=str(NGUON), write_to=str(GOC / 'assets' / 'logo.png'),
        output_width=ASSET_TRONG_APP, output_height=ASSET_TRONG_APP,
    )

    print('Da dung lai toan bo icon tu SVG nguon.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
