import 'loai_thiet_bi.dart';

/// Trên Android/iOS/desktop gốc, khái niệm "bản thiết bị web" không được
/// đọc ở đâu cả (mic luôn nói thẳng với hệ điều hành qua `speech_to_text`)
/// — trả về một giá trị mặc định vô hại.
ThietBi doanThietBi() => ThietBi.android;
