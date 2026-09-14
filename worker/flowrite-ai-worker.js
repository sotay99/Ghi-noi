// Máy chủ trung gian giữ khoá Gemini — Flowrite KHÔNG BAO GIỜ gọi thẳng tới
// Google. App gọi vào đây, Worker mới là nơi duy nhất biết khoá thật.
//
// Một điểm cuối (POST /) dùng chung cho MỌI tính năng AI của app — tóm tắt,
// mở rộng, gọt dũa, đề xuất ý tưởng, trò chuyện, sửa chính tả — mỗi tính
// năng chỉ khác nhau ở tham số `action`. Thêm tính năng AI mới sau này chỉ
// cần thêm một case trong `huongDanTheoHanhDong()`, không cần một Worker
// riêng cho từng nút.
//
// Triển khai bằng `wrangler deploy` (xem README.md cùng thư mục này).

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders() });
    }
    if (request.method !== 'POST') {
      return traLoi({ loi: 'Chỉ nhận POST.' }, 405);
    }

    // Không phải khoá thật — chỉ là một "mật khẩu" giữa app và Worker, để
    // người lạ không gọi ké vào đây tiêu tốn hạn mức Gemini của bạn. Đặt
    // bằng `wrangler secret put APP_SHARED_SECRET`, và app phải gửi kèm
    // đúng giá trị này ở header mỗi lần gọi.
    const macXacThuc = request.headers.get('x-flowrite-secret');
    if (!env.APP_SHARED_SECRET || macXacThuc !== env.APP_SHARED_SECRET) {
      return traLoi({ loi: 'Không có quyền gọi.' }, 401);
    }

    let than;
    try {
      than = await request.json();
    } catch {
      return traLoi({ loi: 'Dữ liệu gửi lên không phải JSON hợp lệ.' }, 400);
    }

    const { action, text, cauHoi } = than;
    if (typeof text !== 'string' || text.trim() === '') {
      return traLoi({ loi: 'Thiếu nội dung văn bản (text).' }, 400);
    }
    // Chặn văn bản quá dài: vừa tốn tiền vô ích, vừa dễ vượt giới hạn của
    // Gemini. 20.000 ký tự đủ cho một ghi chú rất dài rồi.
    if (text.length > 20000) {
      return traLoi({ loi: 'Văn bản quá dài (tối đa 20.000 ký tự).' }, 400);
    }

    const huongDan = huongDanTheoHanhDong(action, cauHoi);
    if (!huongDan) {
      return traLoi({ loi: `Không hỗ trợ action: "${action}".` }, 400);
    }

    if (!env.GEMINI_API_KEY) {
      return traLoi({ loi: 'Worker chưa được cấu hình GEMINI_API_KEY.' }, 500);
    }

    try {
      const ketQua = await goiGemini(env, huongDan, text);
      return traLoi({ text: ketQua });
    } catch (err) {
      return traLoi({ loi: String(err && err.message ? err.message : err) }, 502);
    }
  },
};

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
    default:
      return null;
  }
}

async function goiGemini(env, huongDan, vanBan) {
  // Tên mô hình để trong biến môi trường thay vì viết chết — Google đổi tên
  // model theo thời gian. Vào Google AI Studio (aistudio.google.com) xem
  // model nào đang ghi miễn phí rồi đặt tên đó vào GEMINI_MODEL.
  const model = env.GEMINI_MODEL || 'gemini-2.0-flash';
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
    `?key=${env.GEMINI_API_KEY}`;

  const phanHoi = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [{ text: `${huongDan}\n\n"""\n${vanBan}\n"""` }],
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
  if (!chu) throw new Error('Gemini không trả về nội dung.');
  return chu;
}

function traLoi(doiTuong, trangThai = 200) {
  return new Response(JSON.stringify(doiTuong), {
    status: trangThai,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...corsHeaders(),
    },
  });
}

function corsHeaders() {
  return {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'content-type, x-flowrite-secret',
  };
}
