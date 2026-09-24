import 'package:flutter/material.dart';

/// Bọc quanh widget gốc của app (`home:` của `MaterialApp`) để CHẶN hành vi
/// mặc định của Flutter: phím Esc tự động gọi `Navigator.maybePop()`
/// (`DismissIntent`). Ở màn hình gốc không còn gì để "lùi" thêm, nên hành
/// vi mặc định này vô hại trên Android/iOS gốc — nhưng trên WEB, Flutter
/// đồng bộ Navigator với lịch sử trình duyệt, nên nó biến thành y hệt bấm
/// nút Back của trình duyệt, phá mất phím tắt Esc (xem `LuaChonPhimTat`,
/// `CaiDat.phimTatMicro`/`phimTatGhiAm`).
///
/// KHÔNG ảnh hưởng tới hộp thoại/modal (`showDialog`) — chúng được vẽ vào
/// `Overlay` riêng của `Navigator`, nằm NGOÀI cây con này (không phải con
/// cháu của [child]), nên `Actions.invoke` tìm `DismissIntent` cho một hộp
/// thoại đang mở sẽ không đi qua đây — Esc vẫn đóng hộp thoại bình thường
/// như mọi app khác.
class ChanEscLuiTrang extends StatelessWidget {
  const ChanEscLuiTrang({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => null),
      },
      child: child,
    );
  }
}
