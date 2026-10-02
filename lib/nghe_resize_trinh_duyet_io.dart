/// Trên Android/iOS/desktop gốc, khái niệm "resize trình duyệt" không có ý
/// nghĩa gì (không có trình duyệt) — không làm gì cả.
Object? dangKyNgheResizeTrinhDuyet(void Function() goiLai) => null;

void huyNgheResizeTrinhDuyet(Object? dangKy) {}

Object? dangKyThamDoChieuCaoVienPort(void Function() goiLai) => null;

void huyThamDoChieuCaoVienPort(Object? dangKy) {}
