#!/usr/bin/env python3
"""Vá phần Android do `flutter create` sinh ra.

Thư mục android/ không nằm trong git (xem .gitignore): mỗi lần dựng, máy chủ
tự sinh lại nó bằng đúng phiên bản Flutter đang dùng, rồi chạy script này để
thêm những thứ riêng của Flowrite. Nhờ vậy không bao giờ lệch phiên bản Gradle.
"""
import re
import shutil
import sys
from pathlib import Path

GOC = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
MANIFEST = GOC / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
GRADLE_KTS = GOC / 'android' / 'app' / 'build.gradle.kts'
GRADLE_GROOVY = GOC / 'android' / 'app' / 'build.gradle'

# Khoá ký CỐ ĐỊNH của Flowrite — một khoá DUY NHẤT, dùng lại cho MỌI lần
# dựng, mãi mãi về sau. Không phải bí mật cần giấu (app chỉ cài tay, không
# lên Google Play, khoá này không bảo vệ gì có giá trị) — commit thẳng vào
# kho mã cho đơn giản.
#
# Lý do khoá này BẮT BUỘC phải cố định: trước đây `android/` bị sinh MỚI
# HOÀN TOÀN mỗi lần dựng (không nằm trong git), nên Gradle lúc không thấy cấu
# hình ký nào sẽ tự ký bản release bằng debug.keystore MẶC ĐỊNH — mà máy dựng
# của GitHub Actions cũng là máy ảo MỚI TINH mỗi lần, nên debug.keystore đó
# cũng tự sinh ngẫu nhiên lại mỗi lần, ra một chữ ký KHÁC NHAU cho mỗi bản
# APK. Android bắt buộc chữ ký của bản cập nhật phải khớp bản đang cài — chữ
# ký đổi liên tục là đúng nguyên nhân lỗi "xung đột ứng dụng hiện có" mỗi lần
# cập nhật, phải gỡ cài đặt bản cũ mới cài được bản mới. Ký bằng MỘT khoá cố
# định, không đổi qua các lần dựng, thì Android luôn coi là cùng một ứng
# dụng, cập nhật đè lên được bình thường — không bao giờ phải gỡ cài đặt nữa.
KHOA_KY = GOC / 'tool' / 'ky' / 'flowrite-release.keystore'
KHOA_KY_ALIAS = 'flowrite'
KHOA_KY_MAT_KHAU = 'flowrite-app-signing-2026'

# permission_handler_android đòi compileSdk 37; Flutter tạo project mới với
# compileSdk mặc định của chính nó (36 ở thời điểm viết script này), thấp hơn
# yêu cầu đó. Nâng lên đúng bằng số plugin đòi — không nâng thừa để đỡ phải
# sửa lại khi Android SDK còn tăng số nữa về sau; đọc lại lỗi bản dựng đỏ nếu
# một plugin khác trong tương lai đòi số cao hơn.
COMPILE_SDK_TOI_THIEU = 37

QUYEN = (
    '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n'
    '    <uses-permission android:name="android.permission.INTERNET"/>\n'
    # Mục "Chụp ảnh (camera)" (image_picker, ImageSource.camera) trong menu
    # "Làm việc với AI" — thiếu quyền này thì bấm chụp ảnh không mở được
    # camera, không báo lỗi rõ ràng.
    '    <uses-permission android:name="android.permission.CAMERA"/>\n'
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


def _va_compile_sdk() -> int:
    tep = GRADLE_KTS if GRADLE_KTS.exists() else GRADLE_GROOVY
    if not tep.exists():
        print(f'Khong thay {GRADLE_KTS} lan {GRADLE_GROOVY}', file=sys.stderr)
        return 1

    chu = tep.read_text(encoding='utf-8')
    # Khớp cả hai kiểu cú pháp: Kotlin DSL "compileSdk = 36" và Groovy
    # "compileSdk 36", cùng biến thể trỏ tới flutter.compileSdkVersion.
    moi, n = re.subn(
        r'compileSdk(Version)?\s*=?\s*(flutter\.compileSdkVersion|\d+)',
        f'compileSdk\\1 = {COMPILE_SDK_TOI_THIEU}' if tep == GRADLE_KTS
        else f'compileSdk\\1 {COMPILE_SDK_TOI_THIEU}',
        chu,
        count=1,
    )
    if n == 0:
        print(f'LOI: khong tim thay dong compileSdk trong {tep}', file=sys.stderr)
        return 1

    tep.write_text(moi, encoding='utf-8')
    print(f'Da nang compileSdk len {COMPILE_SDK_TOI_THIEU} trong {tep.name}.')
    return 0


def _va_ky_ten() -> int:
    """Chép khoá ký cố định vào android/app/, rồi trỏ signingConfig của bản
    release sang khoá đó thay vì debug.keystore ngẫu nhiên mặc định — xem
    giải thích đầy đủ ở khai báo KHOA_KY phía trên."""
    if not KHOA_KY.exists():
        print(f'LOI: khong thay khoa ky {KHOA_KY}', file=sys.stderr)
        return 1

    dich = GOC / 'android' / 'app' / KHOA_KY.name
    shutil.copyfile(KHOA_KY, dich)

    tep = GRADLE_KTS if GRADLE_KTS.exists() else GRADLE_GROOVY
    if not tep.exists():
        print(f'Khong thay {GRADLE_KTS} lan {GRADLE_GROOVY}', file=sys.stderr)
        return 1
    la_kts = tep == GRADLE_KTS

    chu = tep.read_text(encoding='utf-8')

    if la_kts:
        khoi_ky = (
            'android {\n'
            '    signingConfigs {\n'
            '        create("release") {\n'
            f'            storeFile = file("{KHOA_KY.name}")\n'
            f'            storePassword = "{KHOA_KY_MAT_KHAU}"\n'
            f'            keyAlias = "{KHOA_KY_ALIAS}"\n'
            f'            keyPassword = "{KHOA_KY_MAT_KHAU}"\n'
            '        }\n'
            '    }\n'
        )
        chu, n1 = re.subn(r'android \{', khoi_ky, chu, count=1)
        chu, n2 = re.subn(
            r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
            'signingConfig = signingConfigs.getByName("release")',
            chu,
        )
    else:
        khoi_ky = (
            'android {\n'
            '    signingConfigs {\n'
            '        release {\n'
            f'            storeFile file("{KHOA_KY.name}")\n'
            f'            storePassword "{KHOA_KY_MAT_KHAU}"\n'
            f'            keyAlias "{KHOA_KY_ALIAS}"\n'
            f'            keyPassword "{KHOA_KY_MAT_KHAU}"\n'
            '        }\n'
            '    }\n'
        )
        chu, n1 = re.subn(r'android \{', khoi_ky, chu, count=1)
        chu, n2 = re.subn(
            r'signingConfig\s+signingConfigs\.debug',
            'signingConfig signingConfigs.release',
            chu,
        )

    if n1 == 0:
        print(f'LOI: khong tim thay "android {{" trong {tep}', file=sys.stderr)
        return 1
    if n2 == 0:
        print(
            f'LOI: khong tim thay dong signingConfig cua debug trong {tep} '
            '(mau flutter create co the da doi cu phap)',
            file=sys.stderr,
        )
        return 1

    tep.write_text(chu, encoding='utf-8')
    print(f'Da tro signingConfig sang khoa ky co dinh trong {tep.name}.')
    return 0


def main() -> int:
    if not MANIFEST.exists():
        print(f'Khong thay {MANIFEST}', file=sys.stderr)
        return 1

    ket_qua_gradle = _va_compile_sdk()
    if ket_qua_gradle != 0:
        return ket_qua_gradle

    ket_qua_ky = _va_ky_ten()
    if ket_qua_ky != 0:
        return ket_qua_ky

    chu = MANIFEST.read_text(encoding='utf-8')

    if 'RECORD_AUDIO' not in chu:
        chu = chu.replace('<application', QUYEN + '\n    <application', 1)
    if 'android.speech.RecognitionService' not in chu:
        chu = chu.replace('<application', HOI + '\n    <application', 1)

    # Ten hien duoi bieu tuong tren man hinh chinh.
    chu, n = re.subn(r'android:label="[^"]*"', 'android:label="Flowrite"', chu, count=1)
    if n == 0:
        print('Canh bao: khong thay android:label de doi ten', file=sys.stderr)

    MANIFEST.write_text(chu, encoding='utf-8')

    # Kiem lai: thieu mot trong ba thu nay la ban APK dung nhung micro chet.
    lai = MANIFEST.read_text(encoding='utf-8')
    for can in ('RECORD_AUDIO', 'android.permission.INTERNET',
                'android.permission.CAMERA', 'android.speech.RecognitionService'):
        if can not in lai:
            print(f'LOI: manifest van thieu {can}', file=sys.stderr)
            return 1

    print('Da va AndroidManifest.xml xong.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
