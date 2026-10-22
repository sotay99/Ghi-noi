import 'package:flutter/material.dart';

import 'ngon_ngu.dart';

// Ba "bản" hành vi micro trên web — chỉ có ý nghĩa khi chạy trên web
// (`kIsWeb`). App Android/iOS gốc luôn nói thẳng với hệ điều hành qua
// `speech_to_text`, không dùng tới khái niệm này.
enum ThietBi { android, pc, iphone }

extension ThongTinThietBi on ThietBi {
  String get ten {
    final laVi = ngonNguHienTai.value == NgonNgu.vi;
    return switch (this) {
      ThietBi.android => 'Android',
      ThietBi.pc => laVi ? 'Máy tính (PC/Mac)' : 'Computer (PC/Mac)',
      ThietBi.iphone => 'iPhone',
    };
  }

  String get moTa {
    final laVi = ngonNguHienTai.value == NgonNgu.vi;
    return switch (this) {
      ThietBi.android => laVi ? 'Điện thoại/máy tính bảng Android.' : 'Android phone/tablet.',
      ThietBi.pc => laVi ? 'Windows, macOS hoặc Linux.' : 'Windows, macOS or Linux.',
      ThietBi.iphone => laVi
          ? 'iPhone/iPad — Micro (vừa nói vừa ra chữ) sẽ không khả dụng trên website.'
          : "iPhone/iPad — Mic (speak while typing) won't be available on the website.",
    };
  }

  IconData get bieuTuong => switch (this) {
        ThietBi.android => Icons.phone_android,
        ThietBi.pc => Icons.computer,
        ThietBi.iphone => Icons.phone_iphone,
      };
}
