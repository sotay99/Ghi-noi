import 'package:flutter/material.dart';

// Ba "bản" hành vi micro trên web — chỉ có ý nghĩa khi chạy trên web
// (`kIsWeb`). App Android/iOS gốc luôn nói thẳng với hệ điều hành qua
// `speech_to_text`, không dùng tới khái niệm này.
enum ThietBi { android, pc, iphone }

extension ThongTinThietBi on ThietBi {
  String get ten => switch (this) {
        ThietBi.android => 'Android',
        ThietBi.pc => 'Máy tính (PC/Mac)',
        ThietBi.iphone => 'iPhone',
      };

  String get moTa => switch (this) {
        ThietBi.android => 'Điện thoại/máy tính bảng Android.',
        ThietBi.pc => 'Windows, macOS hoặc Linux.',
        ThietBi.iphone =>
          'iPhone/iPad — Micro (vừa nói vừa ra chữ) sẽ không khả dụng trên website.',
      };

  IconData get bieuTuong => switch (this) {
        ThietBi.android => Icons.phone_android,
        ThietBi.pc => Icons.computer,
        ThietBi.iphone => Icons.phone_iphone,
      };
}
