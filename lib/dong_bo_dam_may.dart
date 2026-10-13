// Bộ nhớ đám mây — mirror của cây thư mục/ghi chú nội bộ (`kho_du_lieu.dart`)
// lên Firestore, mỗi tài khoản Google một "ngăn" riêng (`users/{uid}/...`).
//
// GIAI ĐOẠN HIỆN TẠI (bước 1-2 của kế hoạch đồng bộ): chỉ có đồng bộ MỘT
// CHIỀU, BẰNG TAY — `dongBoToanBoLenDamMay` đẩy TOÀN BỘ cây local lên
// Firestore khi người dùng tự bấm nút, để kiểm tra đường ghi/đọc chạy đúng
// trước khi chuyển sang tự động (debounce, đồng bộ ngược, UI cây thư mục
// riêng cho đám mây) ở các bước sau. CHƯA đọc gì từ Firestore, CHƯA tự động.
//
// Schema (collection con trong đúng document `users/{uid}`):
//   users/{uid}/thuMuc/{thuMucId}  — ten, chaId, mau, thoiGianXoa, capNhatLuc
//   users/{uid}/ghiChu/{ghiChuId}  — ten, chaId, noiDung, mau, thoiGianXoa,
//                                    capNhatLuc, congKhai, maChiaSe
// `congKhai`/`maChiaSe` để sẵn chỗ cho tính năng chia sẻ link sau này —
// CHƯA dùng tới ở bước này, luôn ghi `congKhai: false`.
//
// Rules Firestore đang ở "test mode" (mở toang) — sẽ siết lại theo đúng
// ranh giới `users/{uid}` này ở bước cuối cùng của kế hoạch, sau khi mọi
// luồng đọc/viết đã chạy ổn định.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'kho_du_lieu.dart';
import 'mo_hinh.dart';

class DichVuDongBoDamMay {
  DichVuDongBoDamMay._();
  static final DichVuDongBoDamMay instance = DichVuDongBoDamMay._();

  final _db = FirebaseFirestore.instance;

  /// Đẩy TOÀN BỘ cây local lên đám mây — dùng document id TRÙNG với id cục
  /// bộ, nên bấm lại nhiều lần chỉ GHI ĐÈ (không tạo trùng lặp). Firestore
  /// giới hạn 500 thao tác/batch — cây đủ lớn thì tự chia thành nhiều batch.
  Future<void> dongBoToanBoLenDamMay(KhoDuLieu kho, String uid) async {
    final gocNguoiDung = _db.collection('users').doc(uid);
    final tatCaThaoTac = <void Function(WriteBatch)>[];

    for (final t in kho.thuMuc) {
      final doc = gocNguoiDung.collection('thuMuc').doc(t.id);
      tatCaThaoTac.add((b) => b.set(doc, _thuMucSangJson(t)));
    }
    for (final g in kho.ghiChu) {
      final doc = gocNguoiDung.collection('ghiChu').doc(g.id);
      tatCaThaoTac.add((b) => b.set(doc, _ghiChuSangJson(g)));
    }

    const coToiDaMotBatch = 500;
    for (var i = 0; i < tatCaThaoTac.length; i += coToiDaMotBatch) {
      final batch = _db.batch();
      final cuoi = (i + coToiDaMotBatch < tatCaThaoTac.length)
          ? i + coToiDaMotBatch
          : tatCaThaoTac.length;
      for (var j = i; j < cuoi; j++) {
        tatCaThaoTac[j](batch);
      }
      await batch.commit();
    }
  }

  /// (BƯỚC 3 kế hoạch) Đồng bộ MỘT ghi chú — dùng cho autosave debounce lúc
  /// đang soạn thảo, rẻ hơn hẳn đẩy lại cả cây mỗi lần gõ xong.
  Future<void> dongBoMotGhiChu(GhiChuFile g, String uid) async {
    final doc = _db.collection('users').doc(uid).collection('ghiChu').doc(g.id);
    await doc.set(_ghiChuSangJson(g));
  }

  Map<String, dynamic> _thuMucSangJson(ThuMuc t) => {
        'ten': t.ten,
        'chaId': t.chaId,
        'mau': t.mau,
        'thoiGianXoa': t.thoiGianXoa == null ? null : Timestamp.fromDate(t.thoiGianXoa!),
        'capNhatLuc': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> _ghiChuSangJson(GhiChuFile g) => {
        'ten': g.ten,
        'chaId': g.chaId,
        'noiDung': g.noiDung,
        'mau': g.mau,
        'thoiGianXoa': g.thoiGianXoa == null ? null : Timestamp.fromDate(g.thoiGianXoa!),
        'capNhatLuc': FieldValue.serverTimestamp(),
        'congKhai': false,
        'maChiaSe': null,
      };
}
