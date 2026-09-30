// Máy chủ trung gian giữ khoá Gemini — bản Google Cloud Functions.
//
// Dùng bản này thay cho worker/flowrite-ai-worker.js vì Cloudflare (miễn phí)
// cứ định tuyến yêu cầu qua trạm Hồng Kông, mà Gemini API chặn hẳn khu vực
// đó. Đặt máy chủ NGAY TRONG hạ tầng Google thì không còn đi qua trạm trung
// gian nào để bị chặn theo vùng nữa — Google gọi sang Google.
//
// Logic giống hệt bản Cloudflare: một điểm cuối (POST /) dùng chung cho MỌI
// tính năng AI của app, chỉ khác nhau ở tham số `action`.

const MODEL_MAC_DINH = 'gemini-flash-lite-latest';

/// Đoạn hướng dẫn DÙNG CHUNG cho mọi nơi AI sửa chính tả — cả kiểm tra tự
/// động theo từng câu (action 'chinh_ta') lẫn "Kiểm tra toàn văn" (action
/// 'toan_van'). Ưu tiên sửa CỤM TỪ, giải thích hai nguồn chữ (gõ tay/giọng
/// nói) để AI cảnh giác đúng chỗ, và cho phép đề xuất mang theo dấu câu.
const QUY_TAC_CHINH_TA_CHUNG =
  'QUY TẮC SỬA CHÍNH TẢ: Ưu tiên đề xuất sửa NGUYÊN CỤM TỪ thay vì từng từ đơn lẻ, kể cả khi trong cụm đó có từ vốn không sai chính tả — nếu cả cụm không hợp ngữ cảnh thì vẫn đề xuất thay cả cụm cho mạch lạc hơn là chỉ vá một từ. Sửa từng từ đơn lẻ vẫn được, khi đó là cách hợp lý nhất. ' +
  'Văn bản là hỗn hợp chữ từ HAI nguồn: gõ tay và giọng nói (voice-to-text). Chữ GÕ TAY ít khi sai ngữ cảnh nhưng có thể gõ nhầm phím thành từ sai chính tả. Chữ GIỌNG NÓI hầu như không bao giờ sai chính tả (bộ nhận dạng luôn trả về từ có nghĩa) nhưng RẤT DỄ sai NGỮ CẢNH vì nghe nhầm âm gần giống — ví dụ "con trỏ văn bản" bị nhận nhầm thành "con chó văn bản". Hãy cảnh giác hơn với những cụm nghe giống nhau về âm nhưng lệch hẳn về nghĩa so với mạch văn xung quanh, đó là loại lỗi giọng nói hay mắc nhất. ' +
  'Đề xuất thay thế được phép MANG THEO dấu câu bên trong nếu hợp lý, ví dụ "Nhà" có thể đề xuất thành "nhà," nếu sau đó là một mệnh đề khác, hoặc "người iu tới rùi" có thể đề xuất thành "Người yêu, tới rồi!".';

/// Mỗi tính năng AI trong app ứng với một "hành động" ở đây. Muốn thêm tính
/// năng mới thì thêm một case, không cần sửa gì khác.
function huongDanTheoHanhDong(action) {
  switch (action) {
    case 'tom_tat':
      return null; // Xử lý riêng trong huongDanTomTat() — cần ghép % độ dài và/hoặc câu lệnh tuỳ chỉnh của người dùng.
    case 'mo_rong':
      return null; // Xử lý riêng trong huongDanMoRong() — cần ghép % độ dài và/hoặc câu lệnh tuỳ chỉnh của người dùng.
    case 'got_dua':
      return null; // Xử lý riêng trong huongDanVietLai() — nhận thêm câu lệnh tuỳ chỉnh của người dùng (có thể để trống).
    case 'de_xuat_y_tuong':
      return 'Dựa vào đoạn văn bản tiếng Việt sau đây, đề xuất 3-5 ý tưởng hoặc hướng phát triển tiếp theo, trình bày dạng gạch đầu dòng, ngắn gọn:';
    case 'chinh_ta':
      return null; // Xử lý riêng trong exports.flowriteAi — cần ghép thêm vị trí ranh giới ngữ cảnh, không cố định như các action khác.
    case 'toan_van':
      return null; // Xử lý riêng trong huongDanToanVan() — cần ghép cài đặt riêng của người dùng.
    default:
      return null;
  }
}

/// Đoạn "NGỮ CẢNH ĐÃ XỬ LÝ" dùng chung cho cả ba kiểu kiểm tra toàn văn
/// (đầy đủ/chỉ chính tả/chỉ dấu câu) — trả về chuỗi rỗng nếu không có vùng
/// nào đã xử lý trước đó.
function moTaVungDaXuLy(vungDaXuLy) {
  if (vungDaXuLy.length === 0) return '';
  const ds = vungDaXuLy
    .filter((v) => v && Number.isInteger(v.batDau) && Number.isInteger(v.ketThuc))
    .map((v) => `[${v.batDau},${v.ketThuc})`)
    .join(', ');
  return `NGỮ CẢNH ĐÃ XỬ LÝ: các khoảng vị trí ký tự sau đây trên văn bản GỐC đã được xử lý xong ở lượt kiểm tra trước, TUYỆT ĐỐI không báo lỗi mới nằm trong hoặc chồng lấn bất kỳ khoảng nào trong số này — coi chúng là NGỮ CẢNH THAM KHẢO đã xong việc, không phải văn bản cần bạn can thiệp: ${ds}. `;
}

/// Hướng dẫn cho "Kiểm tra lỗi chính tả toàn văn" (mục riêng trong menu
/// "Làm việc với AI", phía TRÊN "Kiểm tra toàn văn") — ĐÚNG cơ chế
/// `huongDanToanVan` (cùng action 'toan_van', cùng `_apDungKetQuaToanVan`
/// phía client vẽ gạch đỏ lượn sóng) nhưng CHỈ tìm lỗi chính tả, không tìm
/// đoạn không phù hợp/cần xoá/thiếu dấu câu.
function huongDanChiChinhTaToanVan(than) {
  const vungDaXuLy = Array.isArray(than.vungDaXuLy) ? than.vungDaXuLy : [];
  let huongDan =
    'Bạn là bộ kiểm tra CHÍNH TẢ tiếng Việt (không kiểm tra ngữ pháp, không kiểm tra văn phong, KHÔNG đề xuất đoạn nào cần thay thế hay xoá, KHÔNG tìm dấu câu thiếu) cho TOÀN BỘ văn bản sau đây. ' +
    QUY_TAC_CHINH_TA_CHUNG + ' ' +
    moTaVungDaXuLy(vungDaXuLy);
  huongDan +=
    'Trả về DUY NHẤT một object JSON hợp lệ (không giải thích, không bọc trong dấu ```), đúng khuôn: {"chinhTa":[{"tu":"...","viTri":0,"deXuat":["...","..."]}]}. ' +
    '"tu" là nguyên văn cụm sai chính tả, "viTri" là vị trí ký tự bắt đầu (đếm từ 0) TRÊN TOÀN BỘ văn bản được cung cấp, "deXuat" tối đa 3 cụm đúng để thay thế. Không có lỗi nào thì để mảng rỗng []. Văn bản cần kiểm tra:';
  return huongDan;
}

/// Hướng dẫn cho "Kiểm tra dấu câu toàn văn" — ĐÚNG cơ chế `huongDanToanVan`
/// nhưng CHỈ tìm chỗ thiếu dấu câu, không sửa chính tả, không đề xuất đoạn
/// cần thay thế/xoá.
function huongDanChiDauCauToanVan(than) {
  const vungDaXuLy = Array.isArray(than.vungDaXuLy) ? than.vungDaXuLy : [];
  let huongDan =
    'Bạn soát TOÀN BỘ văn bản tiếng Việt sau đây, CHỈ tìm những chỗ CÒN THIẾU dấu câu (chấm, phẩy, hỏi, than, chấm phẩy, hai chấm, ba chấm, ngoặc đơn, ngoặc kép, gạch ngang, hoặc dấu khác bạn thấy cần) và đề xuất CHÈN THÊM vào — KHÔNG sửa chính tả, KHÔNG đề xuất đoạn nào cần thay thế hay xoá. ' +
    moTaVungDaXuLy(vungDaXuLy);
  huongDan +=
    'Trả về DUY NHẤT một object JSON hợp lệ (không giải thích, không bọc trong dấu ```), đúng khuôn: {"dauCauMoi":[{"dauCau":"...","viTri":0}]}. ' +
    '"dauCau" là chuỗi dấu câu cần chèn, "viTri" là vị trí ký tự (trên văn bản GỐC) ngay TRƯỚC chỗ chèn (chèn vào SAU ký tự viTri-1, TRƯỚC ký tự viTri). Không thiếu dấu câu nào thì để mảng rỗng []. Văn bản cần kiểm tra:';
  return huongDan;
}

/// Hướng dẫn cho "Kiểm tra toàn văn" — nhận thêm các cài đặt riêng của người
/// dùng (đoạn 3, 5 của yêu cầu): vùng đã xử lý ở lượt trước, có chèn dấu câu
/// hay không, khoảng ký tự tham khảo cho đoạn đề xuất, và câu lệnh tuỳ chỉnh.
function huongDanToanVan(than) {
  const chenDauCau = than.chenDauCau === true;
  const vungDaXuLy = Array.isArray(than.vungDaXuLy) ? than.vungDaXuLy : [];
  const doDaiMin = Number.isInteger(than.doDaiMin) ? than.doDaiMin : null;
  const doDaiMax = Number.isInteger(than.doDaiMax) ? than.doDaiMax : null;
  const cauLenhTuyChinh = typeof than.cauLenhTuyChinh === 'string' ? than.cauLenhTuyChinh.trim() : '';

  let huongDan =
    'Bạn là biên tập viên tiếng Việt, soát lại TOÀN BỘ văn bản sau đây một cách kỹ lưỡng. ' +
    QUY_TAC_CHINH_TA_CHUNG + ' ' +
    moTaVungDaXuLy(vungDaXuLy);

  let khuonMau =
    '{"chinhTa":[{"tu":"...","viTri":0,"deXuat":["...","..."]}],"khongPhuHop":[{"doan":"...","viTri":0,"deXuat":"..."}],"canXoa":[{"doan":"...","viTri":0}]';
  huongDan +=
    'Trả về DUY NHẤT một object JSON hợp lệ (không giải thích, không bọc trong dấu ```), đúng khuôn:\n' +
    khuonMau + (chenDauCau ? ',"dauCauMoi":[{"dauCau":"...","viTri":0}]}' : '}') + '\n' +
    '- "chinhTa": các từ hoặc CỤM TỪ sai chính tả. "tu" là nguyên văn cụm sai, "viTri" là vị trí ký tự bắt đầu (đếm từ 0) TRÊN TOÀN BỘ văn bản được cung cấp, "deXuat" tối đa 3 cụm đúng để thay thế.\n' +
    '- "khongPhuHop": các ĐOẠN VĂN (một câu hoặc vài câu liền nhau) không phù hợp — câu từ lủng củng, lạc đề so với toàn bài, thừa ý, lặp đi lặp lại, có quá nhiều lỗi chính tả trong cùng đoạn, hoặc nên dùng đoạn khác hay hơn để thay. "doan" là NGUYÊN VĂN đúng từng ký tự của đoạn đó như trong bài (kể cả dấu câu, khoảng trắng), "viTri" là vị trí ký tự bắt đầu của "doan" trên toàn bộ văn bản, "deXuat" là đoạn văn bạn đề xuất để thay thế toàn bộ đoạn đó.\n' +
    '- "canXoa": các ĐOẠN VĂN nên xoá hẳn, không cần thay bằng gì (thừa hoàn toàn, không đóng góp gì cho bài). "doan" là nguyên văn đoạn đó, "viTri" là vị trí ký tự bắt đầu.\n';

  if (chenDauCau) {
    huongDan +=
      '- "dauCauMoi": những chỗ CÒN THIẾU dấu câu (chấm, phẩy, hỏi, than, chấm phẩy, hai chấm, ba chấm, ngoặc đơn, ngoặc kép, gạch ngang, hoặc dấu khác bạn thấy cần) mà bạn muốn CHÈN THÊM vào — không phải sửa từ sai. "dauCau" là chuỗi dấu câu cần chèn, "viTri" là vị trí ký tự (trên văn bản GỐC) ngay TRƯỚC chỗ chèn (chèn vào SAU ký tự viTri-1, TRƯỚC ký tự viTri). TUYỆT ĐỐI không đặt "viTri" của "dauCauMoi" nằm bên trong khoảng ký tự của bất kỳ mục "chinhTa" nào — dấu câu bên trong một cụm sai chính tả phải nằm trong "deXuat" của chính mục "chinhTa" đó, không tách riêng ra "dauCauMoi".\n';
  }

  huongDan += 'Mọi "viTri" đều đếm trên văn bản GỐC (chưa sửa gì). Loại nào không có gì thì để mảng rỗng [].';

  if (doDaiMin != null && doDaiMax != null) {
    huongDan +=
      ` Với mỗi đoạn "deXuat" trong "khongPhuHop": khoảng ${doDaiMin}-${doDaiMax} ký tự là ĐỘ DÀI THAM KHẢO mong muốn, không phải giới hạn cứng — có thể vượt ra ngoài nếu ngữ cảnh đòi hỏi, và đoạn đề xuất có thể NGẮN HƠN nhiều so với đoạn "doan" gốc nếu cô đọng lại hợp lý.`;
  }

  if (cauLenhTuyChinh) {
    huongDan +=
      `\n\nNGOÀI chỉ dẫn hệ thống ở trên, đây còn có CHỈ DẪN RIÊNG của người dùng — ưu tiên làm theo ý người dùng trước, nếu có xung đột với chỉ dẫn hệ thống thì theo ý người dùng: "${cauLenhTuyChinh.slice(0, 800)}"`;
  }

  huongDan += ' Văn bản cần kiểm tra:';
  return huongDan;
}

/// Hướng dẫn cho "Tóm tắt toàn văn" (modal "Chọn kiểu tóm tắt") — nhận thêm
/// % độ dài mong muốn (`than.phanTram`, 10-90) và/hoặc câu lệnh tự do của
/// người dùng (`than.huongDanNguoiDung`). Phía client đã chặn gửi lên khi cả
/// hai đều trống (bắt buộc chọn ít nhất một), nhưng vẫn xử lý an toàn ở đây
/// nếu lỡ thiếu — rơi về tóm tắt ngắn gọn mặc định.
function huongDanTomTat(than) {
  const phanTram =
    Number.isInteger(than.phanTram) && than.phanTram >= 10 && than.phanTram <= 90
      ? than.phanTram
      : null;
  const huongDanNguoiDung =
    typeof than.huongDanNguoiDung === 'string' ? than.huongDanNguoiDung.trim() : '';

  let huongDan = 'Tóm tắt đoạn văn bản tiếng Việt sau đây, giữ đúng ý chính. ';

  if (phanTram != null) {
    huongDan +=
      `Bản tóm tắt cần dài khoảng ${phanTram}% so với độ dài văn bản gốc (ước lượng theo số từ). `;
  }
  if (huongDanNguoiDung) {
    huongDan +=
      `NGOÀI ra, người dùng còn có yêu cầu riêng cho cách tóm tắt — ưu tiên làm theo ý này, nếu xung đột với chỉ dẫn ở trên thì theo ý người dùng: "${huongDanNguoiDung.slice(0, 800)}". `;
  }
  huongDan += 'Chỉ trả về đúng phần tóm tắt, không thêm lời dẫn, không thêm chú thích:';
  return huongDan;
}

/// Hướng dẫn cho "Mở rộng toàn văn" (modal "Chọn kiểu mở rộng") — ĐÚNG
/// KHUÔN `huongDanTomTat` ở trên, chỉ đảo ngược ý nghĩa: `than.phanTram`
/// (120-400) là độ dài MONG MUỐN so với bản gốc, 100% nghĩa là giữ nguyên
/// không đổi, trên 100% là mở rộng thêm — phải nói RÕ quy ước này cho AI
/// hiểu vì "200%" không tự nhiên như "tóm tắt còn 50%".
function huongDanMoRong(than) {
  const phanTram =
    Number.isInteger(than.phanTram) && than.phanTram >= 100 && than.phanTram <= 400
      ? than.phanTram
      : null;
  const huongDanNguoiDung =
    typeof than.huongDanNguoiDung === 'string' ? than.huongDanNguoiDung.trim() : '';

  let huongDan =
    'Mở rộng đoạn văn bản tiếng Việt sau đây, thêm chi tiết hợp lý, giữ nguyên văn phong gốc. ';

  if (phanTram != null) {
    huongDan +=
      `Bản mở rộng cần dài khoảng ${phanTram}% so với độ dài văn bản gốc (ước lượng theo số từ) — quy ước: 100% nghĩa là giữ nguyên không đổi, trên 100% là mở rộng thêm đúng theo tỉ lệ đó. `;
  }
  if (huongDanNguoiDung) {
    huongDan +=
      `NGOÀI ra, người dùng còn có yêu cầu riêng cho cách mở rộng — ưu tiên làm theo ý này, nếu xung đột với chỉ dẫn ở trên thì theo ý người dùng: "${huongDanNguoiDung.slice(0, 800)}". `;
  }
  huongDan += 'Chỉ trả về đúng đoạn văn đã mở rộng, không thêm lời dẫn, không thêm chú thích:';
  return huongDan;
}

/// Hướng dẫn cho "Viết lại cho hay hơn" (modal chỉ có MỘT ô câu lệnh tự do,
/// CÓ THỂ ĐỂ TRỐNG — để trống thì AI tự do chọn cách viết lại theo ý nó).
function huongDanVietLai(than) {
  const huongDanNguoiDung =
    typeof than.huongDanNguoiDung === 'string' ? than.huongDanNguoiDung.trim() : '';

  let huongDan =
    'Viết lại đoạn văn bản tiếng Việt sau đây cho hay hơn, câu chữ mượt mà và tự nhiên hơn — KHÔNG đổi ý nghĩa gốc. ';

  if (huongDanNguoiDung) {
    huongDan +=
      `Người dùng có yêu cầu riêng cho cách viết lại — ưu tiên làm theo ý này, nếu xung đột với chỉ dẫn ở trên thì theo ý người dùng: "${huongDanNguoiDung.slice(0, 800)}". `;
  } else {
    huongDan += 'Người dùng không yêu cầu gì thêm — tự do chọn cách viết lại mà bạn thấy hay nhất. ';
  }
  huongDan += 'Chỉ trả về đúng đoạn văn đã viết lại, không thêm lời dẫn, không thêm chú thích:';
  return huongDan;
}

/// Chính tả cần một hướng dẫn ĐỘNG — phần đầu văn bản gửi lên có thể là NGỮ
/// CẢNH (câu/đoạn trước đó, chỉ để AI hiểu mạch văn, không tìm lỗi ở đó),
/// phần sau [boQuaTruocViTri] mới là đoạn thật sự cần soát. Gộp ngữ cảnh vào
/// giúp AI hiểu đúng nghĩa của từ đang xét hơn hẳn so với chỉ đưa một câu cộc
/// lốc — một câu quá ngắn dễ khiến AI bỏ sót lỗi hoặc đề xuất sai vì không
/// biết ngữ cảnh xung quanh.
function huongDanChinhTa(boQuaTruocViTri, layLoiChinhTa, chenDauCau) {
  let huongDan = '';

  if (layLoiChinhTa) {
    huongDan +=
      'Bạn là bộ kiểm tra CHÍNH TẢ tiếng Việt (không kiểm tra ngữ pháp, không kiểm tra văn phong). ' + QUY_TAC_CHINH_TA_CHUNG + ' ';
  }
  if (chenDauCau) {
    huongDan +=
      'Bạn còn cần tìm những chỗ CÒN THIẾU dấu câu (chấm, phẩy, hỏi, than, chấm phẩy, hai chấm, ba chấm, ngoặc đơn, ngoặc kép, gạch ngang...) và đề xuất CHÈN THÊM vào, không phải sửa từ sai — dấu câu nằm trong một cụm sai chính tả thì phải nằm trong "deXuat" của "chinhTa" đó, không tách riêng thành "dauCauMoi". ';
  }

  huongDan +=
    `Văn bản bên dưới gồm hai phần ghép liền nhau: ${boQuaTruocViTri} ký tự ĐẦU TIÊN là NGỮ CẢNH (câu/đoạn phía trước, chỉ để bạn hiểu mạch văn và xét đúng nghĩa của từ — TUYỆT ĐỐI không tìm lỗi hay báo lỗi nằm trong phần này), phần CÒN LẠI (từ ký tự thứ ${boQuaTruocViTri} trở đi) mới là đoạn thật sự cần soát. ` +
    'Dựa vào cả ngữ cảnh lẫn nghĩa của câu để hiểu đúng ý người viết trước khi kết luận — đừng chỉ nhìn từng từ riêng lẻ tách rời câu. Mọi "viTri" đếm từ 0 trên TOÀN BỘ văn bản được cung cấp bên dưới (tính luôn phần ngữ cảnh phía trước, không đếm lại từ đầu phần cần soát). ';

  if (layLoiChinhTa) {
    huongDan +=
      'Với mỗi lỗi chính tả, xác định: "tu" (đúng từ HOẶC CỤM NHIỀU TỪ sai, nguyên vẹn như trong bài), "viTri", và "deXuat" (tối đa 5 từ/cụm đúng để thay thế, xếp từ hợp ngữ cảnh nhất trước; so sánh CHÍNH XÁC TỪNG KÝ TỰ, phân biệt hoa/thường: chỉ cấm đề xuất giống hệt "tu" từng ký tự một, kể cả khi chỉ khác nhau ở viết hoa chữ cái đầu vẫn là đề xuất hợp lệ). ';
  }

  const truong = [];
  if (layLoiChinhTa) truong.push('"chinhTa":[{"tu":"...","viTri":0,"deXuat":["...","..."]}]');
  if (chenDauCau) truong.push('"dauCauMoi":[{"dauCau":"...","viTri":0}]');
  // Không yêu cầu gì cả (cả hai cờ đều tắt) không nên tới được đây — giữ một
  // khuôn rỗng hợp lệ để không bao giờ trả về JSON hỏng nếu lỡ xảy ra.
  if (truong.length === 0) truong.push('"chinhTa":[]');

  huongDan +=
    `CHỈ trả về DUY NHẤT một object JSON hợp lệ, không kèm lời giải thích, không bọc trong dấu \`\`\`, đúng khuôn: {${truong.join(',')}}. ` +
    (chenDauCau
      ? '"dauCauMoi.viTri" là vị trí ký tự chèn dấu câu vào NGAY TRƯỚC (chèn sau ký tự viTri-1, trước ký tự viTri). '
      : '') +
    'Loại nào không có gì thì để mảng rỗng []. Văn bản (ngữ cảnh + đoạn cần soát):';
  return huongDan;
}

/// Gửi một tệp âm thanh cho Whisper Large v3 Turbo CHẠY TRÊN GROQ phiên âm ra
/// chữ. THAY cho việc gửi thẳng audio vào Gemini — audio là loại token đắt
/// nhất, nên tách hẳn bước "nghe ra chữ" sang một dịch vụ chuyên biệt rẻ hơn
/// nhiều lần, Gemini (nếu cần dùng tiếp) chỉ còn phải xử lý CHỮ (rẻ) chứ
/// không còn đụng audio. Trước đây gọi thẳng OpenAI Whisper (~0,36
/// USD/giờ) — Groq chạy CÙNG MỘT MÔ HÌNH Whisper trên phần cứng riêng (LPU)
/// của họ, giá chỉ ~0,04 USD/giờ (rẻ hơn ~9 lần), tốc độ nhanh hơn nhiều.
/// Endpoint tương thích định dạng OpenAI nên thân hàm gần như không đổi so
/// với bản gọi OpenAI trước đó, chỉ đổi địa chỉ/khoá/tên model. Cần khoá
/// riêng `GROQ_API_KEY` (Runtime environment variable), không liên quan gì
/// tới `GEMINI_API_KEY`.
///
/// [maNgonNgu]: mã ngôn ngữ ISO gửi cho Whisper (vd 'vi', 'en'...) — app
/// hiện chỉ có tiếng Việt nên luôn truyền 'vi', nhưng để sẵn tham số riêng
/// (đọc từ `than.ngonNgu` phía client nếu có) — sau này app thêm chọn ngôn
/// ngữ chỉ cần đổi giá trị gửi lên, không cần sửa lại hàm này.
///
/// [locHallucination]: CHỈ bật cho luồng THẺ GHI ÂM trong app (không bật
/// cho "Chuyển file âm thanh thành văn bản" — tệp người dùng tự tải lên có
/// thể là nhạc/podcast/nhiều giọng, ranh giới "im lặng = hallucination"
/// không đáng tin như với một lượt ghi âm giọng nói ngắn của chính người
/// dùng). Bật thì:
/// 1) Kèm `prompt` ngữ cảnh tiếng Việt ngắn — gợi ý nhẹ để model bớt rơi về
///    khuôn mẫu "cảm ơn đã xem, nhớ subscribe" nó học được từ transcript
///    YouTube.
/// 2) Xin `response_format: verbose_json` thay vì json thường — Groq trả
///    thêm từng "segment" kèm `no_speech_prob` (xác suất đoạn đó là im
///    lặng) và `avg_logprob` (độ tự tin của model). Lọc bỏ NHỮNG SEGMENT
///    model tự đánh giá là im lặng/không chắc trước khi ghép chữ trả về —
///    đúng cơ chế OpenAI Whisper dùng nội bộ để tự chặn hallucination, chỉ
///    khác là ở đây ta tự làm vì Groq không tự lọc sẵn.
async function goiGroqAmThanh(audioBase64, mimeType, maNgonNgu, locHallucination) {
  if (!process.env.GROQ_API_KEY) {
    throw new Error('Chưa cấu hình GROQ_API_KEY.');
  }

  const bytes = Buffer.from(audioBase64, 'base64');
  const phanMoRong = mimeType.includes('mp4') || mimeType.includes('m4a')
    ? 'm4a'
    : mimeType.includes('webm')
    ? 'webm'
    : mimeType.includes('wav')
    ? 'wav'
    : mimeType.includes('ogg')
    ? 'ogg'
    : 'mp3';

  const bieuMau = new FormData();
  bieuMau.append('file', new Blob([bytes], { type: mimeType }), `ghi-am.${phanMoRong}`);
  bieuMau.append('model', 'whisper-large-v3-turbo');
  bieuMau.append('language', maNgonNgu || 'vi');
  bieuMau.append('temperature', '0'); // Tường minh, dù đây vốn đã là mặc định của API.
  if (locHallucination) {
    bieuMau.append(
      'prompt',
      'Đây là một đoạn ghi âm giọng nói tiếng Việt đời thường của một người dùng ứng dụng ghi chú, không phải video YouTube.',
    );
    bieuMau.append('response_format', 'verbose_json');
  }

  const phanHoi = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
    method: 'POST',
    headers: { authorization: `Bearer ${process.env.GROQ_API_KEY}` },
    body: bieuMau,
  });

  if (!phanHoi.ok) {
    const chuLoi = await phanHoi.text();
    throw new Error(`Groq trả về lỗi ${phanHoi.status}: ${chuLoi.slice(0, 300)}`);
  }

  const duLieu = await phanHoi.json();

  if (locHallucination && Array.isArray(duLieu?.segments)) {
    // Ngưỡng tham khảo từ chính cách openai-whisper (bản chạy máy) tự lọc
    // segment hallucination: no_speech_prob cao (gần chắc chắn là im lặng)
    // NHƯNG model vẫn "cố" trả chữ, kèm avg_logprob thấp (không tự tin về
    // chữ đó) — hai điều kiện phải CÙNG đúng mới loại, để không lỡ tay xoá
    // câu nói thật chỉ vì thu nhỏ tiếng.
    const chu = duLieu.segments
      .filter((s) => !(Number(s?.no_speech_prob) > 0.6 && Number(s?.avg_logprob) < -1))
      .map((s) => (s?.text || '').trim())
      .filter(Boolean)
      .join(' ')
      .trim();
    if (!chu) throw new Error('Groq không trả về nội dung (có thể ghi âm quá nhỏ hoặc im lặng hoàn toàn).');
    return chu;
  }

  const chu = (duLieu?.text || '').trim();
  if (!chu) throw new Error('Groq không trả về nội dung (có thể ghi âm quá nhỏ hoặc im lặng hoàn toàn).');
  return chu;
}

/// Gửi một tệp ảnh cho Gemini để trích chữ ra (OCR) — dùng cho action
/// 'chuyen_anh'. Cùng khuôn `inline_data` như audio trước đây từng dùng
/// (nay đã chuyển sang Groq), chỉ khác loại dữ liệu. Gemini được chọn thay
/// vì Groq (rẻ hơn) vì các model vision rẻ nhất của Groq (Llama 4
/// Scout/3.2 Vision) KHÔNG khai hỗ trợ chính thức tiếng Việt, còn Gemini
/// hỗ trợ đa ngôn ngữ rộng hơn nhiều — cùng rủi ro "nuốt chữ" như đã gặp
/// với audio, nhưng lần này chọn né ngay từ đầu thay vì thử rồi mới biết.
async function goiGeminiAnh(imageBase64, mimeType) {
  const model = process.env.GEMINI_MODEL || MODEL_MAC_DINH;
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
    `?key=${process.env.GEMINI_API_KEY}`;

  const huongDan =
    'Trích xuất CHÍNH XÁC toàn bộ chữ có trong ảnh sau đây thành văn bản, giữ đúng ' +
    'thứ tự đọc tự nhiên (trên xuống dưới, trái sang phải). Chỉ trả về đúng văn bản ' +
    'đã trích xuất, không thêm lời dẫn, không thêm dấu ngoặc kép bao quanh, không ' +
    'chú thích gì thêm. Nếu ảnh không có chữ nào, trả về chuỗi rỗng.';

  const phanHoi = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [
            { text: huongDan },
            { inline_data: { mime_type: mimeType, data: imageBase64 } },
          ],
        },
      ],
    }),
  });

  if (!phanHoi.ok) {
    const chuLoi = await phanHoi.text();
    throw new Error(`Gemini trả về lỗi ${phanHoi.status}: ${chuLoi.slice(0, 300)}`);
  }

  const duLieu = await phanHoi.json();
  const chu = (duLieu?.candidates?.[0]?.content?.parts || [])
    .map((p) => p.text || '')
    .join('');
  if (!chu) throw new Error('Gemini không trả về nội dung (có thể ảnh không có chữ hoặc quá mờ).');
  return chu;
}

async function goiGemini(huongDan, vanBan) {
  const model = process.env.GEMINI_MODEL || MODEL_MAC_DINH;
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
    `?key=${process.env.GEMINI_API_KEY}`;

  const phanHoi = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      contents: [
        { role: 'user', parts: [{ text: `${huongDan}\n\n"""\n${vanBan}\n"""` }] },
      ],
    }),
  });

  if (!phanHoi.ok) {
    const chuLoi = await phanHoi.text();
    throw new Error(`Gemini trả về lỗi ${phanHoi.status}: ${chuLoi.slice(0, 300)}`);
  }

  const duLieu = await phanHoi.json();
  const chu = (duLieu?.candidates?.[0]?.content?.parts || [])
    .map((p) => p.text || '')
    .join('');
  if (!chu) throw new Error('Gemini không trả về nội dung.');
  return chu;
}

/// Gửi CẢ CUỘC HỘI THOẠI cho Gemini — dùng cho "Trò chuyện về văn bản này"
/// (action 'tro_chuyen'). Khác `goiGemini` (một lượt, ghép sẵn huongDan +
/// vanBan) ở chỗ nhận thẳng mảng `contents` nhiều lượt (user/model xen kẽ)
/// — client tự giữ toàn bộ lịch sử hội thoại (bản thân Gemini API không có
/// khái niệm phiên/session phía máy chủ), lượt đầu tiên trong mảng đã mang
/// theo toàn văn bản (xem client `lib/man_hinh_tro_chuyen.dart`) nên máy
/// chủ này không cần biết gì thêm về "văn bản đang soạn" — chỉ việc chuyển
/// tiếp nguyên `contents` cho Gemini.
async function goiGeminiChat(contents) {
  const model = process.env.GEMINI_MODEL || MODEL_MAC_DINH;
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
    `?key=${process.env.GEMINI_API_KEY}`;

  const phanHoi = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ contents }),
  });

  if (!phanHoi.ok) {
    const chuLoi = await phanHoi.text();
    throw new Error(`Gemini trả về lỗi ${phanHoi.status}: ${chuLoi.slice(0, 300)}`);
  }

  const duLieu = await phanHoi.json();
  const chu = (duLieu?.candidates?.[0]?.content?.parts || [])
    .map((p) => p.text || '')
    .join('');
  if (!chu) throw new Error('Gemini không trả về nội dung.');
  return chu;
}

/// Điểm vào của Cloud Function — đặt tên "flowriteAi" khi tạo hàm trên
/// Google Cloud Console phải khớp đúng tên này (Entry point).
exports.flowriteAi = async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'content-type, x-flowrite-secret');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ loi: 'Chỉ nhận POST.' });
    return;
  }

  // Không phải khoá Gemini — chỉ là "mật khẩu" giữa app và máy chủ này, để
  // người lạ không gọi ké tiêu tốn hạn mức của bạn.
  const macXacThuc = req.get('x-flowrite-secret');
  if (!process.env.APP_SHARED_SECRET || macXacThuc !== process.env.APP_SHARED_SECRET) {
    res.status(401).json({ loi: 'Không có quyền gọi.' });
    return;
  }

  const than = req.body || {};
  const { action, text, boQuaTruocViTri, layLoiChinhTa, chenDauCau } = than;

  // Nhánh riêng cho ghi âm: gửi lên là DỮ LIỆU ÂM THANH, không phải `text`,
  // nên không đi qua các kiểm tra dành cho văn bản ở dưới. Đi qua Whisper
  // Large v3 Turbo chạy trên GROQ chứ KHÔNG qua Gemini nữa — audio là loại
  // token đắt nhất, tách riêng dịch vụ phiên âm ra khỏi Gemini để giảm chi
  // phí (Groq lại rẻ hơn ~9 lần so với gọi thẳng OpenAI Whisper). Vì vậy
  // nhánh này không cần GEMINI_API_KEY, chỉ cần GROQ_API_KEY.
  if (action === 'ghi_am') {
    const { audioBase64, mimeType, ngonNgu, locHallucination } = than;
    if (typeof audioBase64 !== 'string' || audioBase64.trim() === '') {
      res.status(400).json({ loi: 'Thiếu dữ liệu âm thanh (audioBase64).' });
      return;
    }
    // Groq giới hạn CỨNG 25MB cho tệp âm thanh gốc — vượt là bị chính Groq
    // từ chối, không có đường vòng. base64 làm phình dung lượng lên ~4/3
    // lần so với tệp gốc, nên giới hạn ở đây phải quy đổi theo đúng tỉ lệ
    // đó (không phải một con số tuỳ chọn) để khớp giới hạn thật, dùng cho cả
    // ghi âm trong app lẫn tệp âm thanh người dùng tự tải lên (mục "Chuyển
    // file âm thanh thành văn bản").
    const gioiHanBase64ChoTepAmThanh = Math.ceil((25 * 1024 * 1024 * 4) / 3);
    if (audioBase64.length > gioiHanBase64ChoTepAmThanh) {
      res.status(400).json({ loi: 'Tệp âm thanh quá lớn — Groq chỉ nhận tối đa 25MB/tệp. Hãy nén hoặc cắt ngắn tệp rồi thử lại.' });
      return;
    }
    try {
      const ketQua = await goiGroqAmThanh(audioBase64, mimeType || 'audio/mp4', ngonNgu, locHallucination === true);
      res.status(200).json({ text: ketQua });
    } catch (err) {
      res.status(502).json({ loi: String(err && err.message ? err.message : err) });
    }
    return;
  }

  // Nhánh riêng cho ảnh: gửi lên là DỮ LIỆU HÌNH ẢNH, không phải `text` —
  // dùng Gemini (không phải Groq) vì các model vision rẻ nhất của Groq
  // không khai hỗ trợ chính thức tiếng Việt, xem chú thích ở
  // `goiGeminiAnh`.
  if (action === 'chuyen_anh') {
    if (!process.env.GEMINI_API_KEY) {
      res.status(500).json({ loi: 'Chưa cấu hình GEMINI_API_KEY.' });
      return;
    }
    const { imageBase64, mimeType } = than;
    if (typeof imageBase64 !== 'string' || imageBase64.trim() === '') {
      res.status(400).json({ loi: 'Thiếu dữ liệu hình ảnh (imageBase64).' });
      return;
    }
    // Gemini nhận tới 100MB dữ liệu inline, nhưng ảnh thường chỉ vài MB —
    // chặn ở 15MB tệp gốc (quy đổi base64 ~4/3 lần) đã rất rộng rãi, tránh
    // gửi nhầm ảnh khổng lồ bất thường.
    const gioiHanBase64ChoAnh = Math.ceil((15 * 1024 * 1024 * 4) / 3);
    if (imageBase64.length > gioiHanBase64ChoAnh) {
      res.status(400).json({ loi: 'Ảnh quá lớn — chỉ nhận tối đa 15MB/tệp. Hãy nén ảnh rồi thử lại.' });
      return;
    }
    try {
      const ketQua = await goiGeminiAnh(imageBase64, mimeType || 'image/jpeg');
      res.status(200).json({ text: ketQua });
    } catch (err) {
      res.status(502).json({ loi: String(err && err.message ? err.message : err) });
    }
    return;
  }

  // Nhánh riêng cho "Trò chuyện về văn bản này": gửi lên CẢ CUỘC HỘI THOẠI
  // (`lichSu`), không phải `text` đơn lẻ — xem `goiGeminiChat`. Lượt đầu
  // tiên trong `lichSu` (do client tự ghép) đã mang theo toàn văn bản, nên
  // máy chủ này không cần — và không nên — kiểm tra `text` ở đây.
  if (action === 'tro_chuyen') {
    if (!process.env.GEMINI_API_KEY) {
      res.status(500).json({ loi: 'Chưa cấu hình GEMINI_API_KEY.' });
      return;
    }
    const { lichSu } = than;
    if (!Array.isArray(lichSu) || lichSu.length === 0) {
      res.status(400).json({ loi: 'Thiếu lịch sử hội thoại (lichSu).' });
      return;
    }
    if (lichSu.length > 60) {
      res.status(400).json({ loi: 'Cuộc trò chuyện quá dài (tối đa 60 lượt) — hãy mở một cuộc trò chuyện mới.' });
      return;
    }
    const contents = [];
    for (const luot of lichSu) {
      const vaiTro = luot && luot.vaiTro === 'ai' ? 'model' : 'user';
      const noiDung = luot && typeof luot.noiDung === 'string' ? luot.noiDung.trim() : '';
      if (!noiDung) {
        res.status(400).json({ loi: 'Một lượt trong lichSu thiếu nội dung (noiDung).' });
        return;
      }
      if (noiDung.length > 25000) {
        res.status(400).json({ loi: 'Một lượt trong lichSu quá dài (tối đa 25.000 ký tự).' });
        return;
      }
      contents.push({ role: vaiTro, parts: [{ text: noiDung }] });
    }
    try {
      const ketQua = await goiGeminiChat(contents);
      res.status(200).json({ text: ketQua });
    } catch (err) {
      res.status(502).json({ loi: String(err && err.message ? err.message : err) });
    }
    return;
  }

  if (!process.env.GEMINI_API_KEY) {
    res.status(500).json({ loi: 'Chưa cấu hình GEMINI_API_KEY.' });
    return;
  }

  if (typeof text !== 'string' || text.trim() === '') {
    res.status(400).json({ loi: 'Thiếu nội dung văn bản (text).' });
    return;
  }
  if (text.length > 20000) {
    res.status(400).json({ loi: 'Văn bản quá dài (tối đa 20.000 ký tự).' });
    return;
  }

  let huongDan;
  if (action === 'chinh_ta') {
    huongDan = huongDanChinhTa(
      Number.isInteger(boQuaTruocViTri) && boQuaTruocViTri > 0 ? boQuaTruocViTri : 0,
      layLoiChinhTa !== false, // mặc định true — giữ tương thích ngược
      chenDauCau === true,
    );
  } else if (action === 'toan_van') {
    if (than.loaiKiemTra === 'chinh_ta') {
      huongDan = huongDanChiChinhTaToanVan(than);
    } else if (than.loaiKiemTra === 'dau_cau') {
      huongDan = huongDanChiDauCauToanVan(than);
    } else {
      huongDan = huongDanToanVan(than);
    }
  } else if (action === 'tom_tat') {
    huongDan = huongDanTomTat(than);
  } else if (action === 'mo_rong') {
    huongDan = huongDanMoRong(than);
  } else if (action === 'got_dua') {
    huongDan = huongDanVietLai(than);
  } else {
    huongDan = huongDanTheoHanhDong(action);
  }
  if (!huongDan) {
    res.status(400).json({ loi: `Không hỗ trợ action: "${action}".` });
    return;
  }

  try {
    const ketQua = await goiGemini(huongDan, text);
    res.status(200).json({ text: ketQua });
  } catch (err) {
    res.status(502).json({ loi: String(err && err.message ? err.message : err) });
  }
};
