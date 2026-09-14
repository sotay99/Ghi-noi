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
    default:
      return null;
  }
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

  if (!process.env.GEMINI_API_KEY) {
    res.status(500).json({ loi: 'Chưa cấu hình GEMINI_API_KEY.' });
    return;
  }

  try {
    const ketQua = await goiGemini(huongDan, text);
    res.status(200).json({ text: ketQua });
  } catch (err) {
    res.status(502).json({ loi: String(err && err.message ? err.message : err) });
  }
};
