#!/usr/bin/env python3
"""Vá phần Android do `flutter create` sinh ra.

Thư mục android/ không nằm trong git (xem .gitignore): mỗi lần dựng, máy chủ
tự sinh lại nó bằng đúng phiên bản Flutter đang dùng, rồi chạy script này để
thêm những thứ riêng của Ghi Nói. Nhờ vậy không bao giờ lệch phiên bản Gradle.
"""
import re
import sys
from pathlib import Path

GOC = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
MANIFEST = GOC / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml'

QUYEN = (
    '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n'
    '    <uses-permission android:name="android.permission.INTERNET"/>\n'
)

# Android 11 trở lên: không khai <queries> thì ứng dụng không nhìn thấy dịch vụ
# nhận dạng giọng nói của máy, và micro sẽ im lặng không báo lỗi gì.
HOI = (
    '    <queries>\n'
    '        <intent>\n'
    '            <action android:name="android.speech.RecognitionService"/>\n'
    '        </intent>\n'
    '        <intent>\n'
    '            <action android:name="android.intent.action.PROCESS_TEXT"/>\n'
    '            <data android:mimeType="text/plain"/>\n'
    '        </intent>\n'
    '    </queries>\n'
)


def main() -> int:
    if not MANIFEST.exists():
        print(f'Khong thay {MANIFEST}', file=sys.stderr)
        return 1

    chu = MANIFEST.read_text(encoding='utf-8')

    if 'RECORD_AUDIO' not in chu:
        chu = chu.replace('<application', QUYEN + '\n    <application', 1)
    if 'android.speech.RecognitionService' not in chu:
        chu = chu.replace('<application', HOI + '\n    <application', 1)

    # Ten hien duoi bieu tuong tren man hinh chinh.
    chu, n = re.subn(r'android:label="[^"]*"', 'android:label="Ghi Nói"', chu, count=1)
    if n == 0:
        print('Canh bao: khong thay android:label de doi ten', file=sys.stderr)

    MANIFEST.write_text(chu, encoding='utf-8')

    # Kiem lai: thieu mot trong ba thu nay la ban APK dung nhung micro chet.
    lai = MANIFEST.read_text(encoding='utf-8')
    for can in ('RECORD_AUDIO', 'android.permission.INTERNET',
                'android.speech.RecognitionService'):
        if can not in lai:
            print(f'LOI: manifest van thieu {can}', file=sys.stderr)
            return 1

    print('Da va AndroidManifest.xml xong.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
