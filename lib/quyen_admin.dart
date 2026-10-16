// (YÊU CẦU MỚI) "Quyền admin" của Flowrite — CHỈ để ẨN/HIỆN giao diện (hai
// mục quản lý trong menu "Tài khoản và Cài đặt"), KHÔNG phải lớp bảo vệ
// thật. Lớp bảo vệ thật nằm ở luật Firestore (Console) — một người mở
// console trình duyệt tự sửa biến trạng thái vẫn không đọc/sửa được dữ
// liệu nếu luật không cho phép đúng hai email này. Đổi email ở đây mà quên
// đổi luật Firestore (hoặc ngược lại) thì một bên "tưởng là admin" nhưng
// không làm được gì, hoặc một bên làm được nhưng không thấy nút — không có
// gì nguy hiểm, chỉ bất tiện, nhưng NHỚ đổi cả hai nơi cho khớp.
const _emailsAdmin = {
  'lookatmevanthanhpham@gmail.com',
  '219thanhdeptrai@gmail.com',
};

bool laAdminEmail(String? email) =>
    email != null && _emailsAdmin.contains(email.trim().toLowerCase());
