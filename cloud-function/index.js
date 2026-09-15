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

/// Mỗi tính năng AI trong app ứng với một "hành động" ở đây. Muốn thêm tính
/// năng mới thì thêm một case, không cần sửa gì khác.
function huongDanTheoHanhDong(action, cauHoi) {
  switch (action) {
    case 'tom_tat':
      return 'Tóm tắt đoạn văn bản tiếng Việt sau đây, ngắn gọn, giữ đúng ý chính. Chỉ trả về đúng phần tóm tắt, không thêm lời dẫn:';
    case 'mo_rong':
      return 'Mở rộng đoạn văn bản tiếng Việt sau đây, thêm chi tiết hợp lý, giữ nguyên văn phong gốc. Chỉ trả về đúng đoạn văn đã mở rộng, không thêm lời dẫn:';
    case 'got_dua':
      return 'Sửa lỗi chính tả, ngữ pháp và câu chữ của đoạn văn bản tiếng Việt sau đây cho mượt mà, tự nhiên hơn — KHÔNG đổi ý nghĩa. Chỉ trả về đúng đoạn văn đã sửa, không thêm lời dẫn hay giải thích:';
    case 'de_xuat_y_tuong':
      return 'Dựa vào đoạn văn bản tiếng Việt sau đây, đề xuất 3-5 ý tưởng hoặc hướng phát triển tiếp theo, trình bày dạng gạch đầu dòng, ngắn gọn:';
    case 'tro_chuyen':
      return `Người dùng đang hỏi về đoạn văn bản bên dưới. Câu hỏi của họ: "${(cauHoi || '').slice(0, 2000)}". Trả lời bằng tiếng Việt, ngắn gọn, đi thẳng vào vấn đề, dựa trên nội dung văn bản được cung cấp:`;
    case 'chinh_ta':
      return 'Bạn là bộ kiểm tra CHÍNH TẢ tiếng Việt (không kiểm tra ngữ pháp, không kiểm tra dấu câu, không kiểm tra văn phong). Tìm mọi TỪ SAI CHÍNH TẢ trong đoạn văn bản sau. Với mỗi từ sai, xác định: "tu" (đúng từ sai, nguyên vẹn như trong bài), "viTri" (vị trí ký tự đầu tiên của từ đó, đếm từ 0, tính trên ĐÚNG đoạn văn bản được cung cấp bên dưới — không đếm trên gì khác), và "deXuat" (tối đa 3 từ đúng chính tả để thay thế, từ gần nghĩa/gần âm nhất trước). CHỈ trả về một mảng JSON hợp lệ, không kèm lời giải thích, không bọc trong dấu ```, đúng khuôn: [{"tu":"...","viTri":0,"deXuat":["...","..."]}]. Không có lỗi nào thì trả về mảng rỗng []. Đoạn văn bản cần kiểm tra:';
    case 'toan_van':
      return 'Bạn là biên tập viên tiếng Việt, soát lại TOÀN BỘ văn bản sau đây một cách kỹ lưỡng. Trả về DUY NHẤT một object JSON hợp lệ (không giải thích, không bọc trong dấu ```), đúng khuôn:\n' +
        '{"chinhTa":[{"tu":"...","viTri":0,"deXuat":["...","..."]}],"khongPhuHop":[{"doan":"...","viTri":0,"deXuat":"..."}],"canXoa":[{"doan":"...","viTri":0}]}\n' +
        '- "chinhTa": các từ hoặc CỤM TỪ sai chính tả. "tu" là nguyên văn cụm sai, "viTri" là vị trí ký tự bắt đầu (đếm từ 0) TRÊN TOÀN BỘ văn bản được cung cấp, "deXuat" tối đa 3 cụm đúng để thay thế.\n' +
        '- "khongPhuHop": các ĐOẠN VĂN (một câu hoặc vài câu liền nhau) không phù hợp — câu từ lủng củng, lạc đề so với toàn bài, thừa ý, lặp đi lặp lại, có quá nhiều lỗi chính tả trong cùng đoạn, hoặc nên dùng đoạn khác hay hơn để thay. "doan" là NGUYÊN VĂN đúng từng ký tự của đoạn đó như trong bài (kể cả dấu câu, khoảng trắng), "viTri" là vị trí ký tự bắt đầu của "doan" trên toàn bộ văn bản, "deXuat" là đoạn văn bạn đề xuất để thay thế toàn bộ đoạn đó.\n' +
        '- "canXoa": các ĐOẠN VĂN nên xoá hẳn, không cần thay bằng gì (thừa hoàn toàn, không đóng góp gì cho bài). "doan" là nguyên văn đoạn đó, "viTri" là vị trí ký tự bắt đầu.\n' +
        'Mọi "viTri" đều đếm trên văn bản GỐC (chưa sửa gì). Loại nào không có gì thì để mảng rỗng []. Văn bản cần kiểm tra:';
    default:
      return null;
  }
}

/// Gửi một tệp âm thanh cho Gemini phiên âm ra chữ. Khác hẳn `goiGemini()`
/// (chỉ gửi chữ) — đây gửi kèm dữ liệu nhị phân âm thanh dạng base64 theo
/// đúng khuôn `inline_data` của Gemini.
async function goiGeminiAmThanh(audioBase64, mimeType) {
  const model = process.env.GEMINI_MODEL || MODEL_MAC_DINH;
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
    `?key=${process.env.GEMINI_API_KEY}`;

  const huongDan =
    'Phiên âm CHÍNH XÁC đoạn ghi âm giọng nói tiếng Việt sau đây thành văn bản. ' +
    'Chỉ trả về đúng văn bản đã phiên âm, không thêm lời dẫn, không thêm dấu ngoặc kép bao quanh, không chú thích gì thêm.';

  const phanHoi = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [
            { text: huongDan },
            { inline_data: { mime_type: mimeType, data: audioBase64 } },
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
  if (!chu) throw new Error('Gemini không trả về nội dung (có thể ghi âm quá nhỏ hoặc im lặng hoàn toàn).');
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
  const { action, text, cauHoi } = than;

  if (!process.env.GEMINI_API_KEY) {
    res.status(500).json({ loi: 'Chưa cấu hình GEMINI_API_KEY.' });
    return;
  }

  // Nhánh riêng cho ghi âm: gửi lên là DỮ LIỆU ÂM THANH, không phải `text`,
  // nên không đi qua các kiểm tra dành cho văn bản ở dưới.
  if (action === 'ghi_am') {
    const { audioBase64, mimeType } = than;
    if (typeof audioBase64 !== 'string' || audioBase64.trim() === '') {
      res.status(400).json({ loi: 'Thiếu dữ liệu âm thanh (audioBase64).' });
      return;
    }
    // ~15 phút ghi âm ở mức nén thoại vẫn chỉ vài MB — 30MB base64 đã rất
    // rộng rãi, chặn sớm để khỏi tốn công gọi Gemini với file bất thường.
    if (audioBase64.length > 30 * 1024 * 1024) {
      res.status(400).json({ loi: 'Tệp ghi âm quá lớn.' });
      return;
    }
    try {
      const ketQua = await goiGeminiAmThanh(audioBase64, mimeType || 'audio/mp4');
      res.status(200).json({ text: ketQua });
    } catch (err) {
      res.status(502).json({ loi: String(err && err.message ? err.message : err) });
    }
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

  const huongDan = huongDanTheoHanhDong(action, cauHoi);
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
