const express = require("express");
const { getPool } = require("../configs/db");

const router = express.Router();

const songSelect = `
  SELECT
    m.music_id, m.music_name, m.music_length, m.audio_url,
    m.cover_image_url, m.listen_count AS listen_count, m.listen_count AS luot_nghe, a.artist_name,
    CASE WHEN l.music_id IS NULL THEN 0 ELSE 1 END AS is_favorite
  FROM music m
  LEFT JOIN artists a ON a.artist_id = m.artist_id
  LEFT JOIN user_liked_songs l
    ON l.music_id = m.music_id AND l.user_id = @userId
`;

async function querySongs(extraWhere, inputs, orderBy = "m.music_id") {
  const pool = await getPool();
  const req = pool.request();
  for (const [key, value] of Object.entries(inputs)) req.input(key, value);
  const where = extraWhere ? `WHERE ${extraWhere}` : "";
  const result = await req.query(`${songSelect} ${where} ORDER BY ${orderBy}`);
  return result.recordset;
}

router.get("/", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    res.json(await querySongs("", { userId }));
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.get("/ranking", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    res.json(await querySongs("", { userId }, "m.listen_count DESC, m.music_id"));
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.get("/favorites", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    if (!userId) return res.json([]);
    res.json(await querySongs("l.music_id IS NOT NULL", { userId }));
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

// Tìm kiếm CHỈ THEO TÊN BÀI HÁT (m.music_name), hỗ trợ khớp cả cụm từ hoặc từng từ đơn lẻ
router.get("/search", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    const keyword = (req.query.q || "").trim();

    if (!keyword) {
      return res.json([]);
    }

    const words = keyword.split(/\s+/).filter((w) => w.length > 0);
    const inputs = { userId };
    let whereClause = "";
    let orderBy = "m.music_name";

    if (words.length === 1) {
      inputs.q0 = `%${words[0]}%`;
      whereClause = "m.music_name LIKE @q0";
      orderBy = "CASE WHEN m.music_name LIKE @q0 THEN 1 ELSE 2 END, m.music_name";
    } else {
      inputs.qFull = `%${keyword}%`;
      const wordConditions = words.map((w, i) => {
        const paramName = `q${i}`;
        inputs[paramName] = `%${w}%`;
        return `m.music_name LIKE @${paramName}`;
      });
      // Khớp nguyên cụm từ HOẶC khớp tất cả các từ HOẶC khớp từng từ
      whereClause = `(m.music_name LIKE @qFull OR (${wordConditions.join(" AND ")}) OR (${wordConditions.join(" OR ")}))`;
      orderBy = "CASE WHEN m.music_name LIKE @qFull THEN 1 ELSE 2 END, m.music_name";
    }

    const data = await querySongs(
      whereClause,
      inputs,
      orderBy,
    );

    if (userId && keyword) {
      try {
        const pool = await getPool();
        await pool
          .request()
          .input("userId", userId)
          .input("search_query", keyword)
          .query(`
            INSERT INTO history (user_id, search_query, type)
            VALUES (@userId, @search_query, 'search')
          `);
      } catch (_) {}
    }

    res.json(data);
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.get("/recent", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    if (!userId) return res.json([]);
    const pool = await getPool();
    const result = await pool
      .request()
      .input("userId", userId)
      .query(`
        SELECT TOP 10
          m.music_id, m.music_name, m.music_length, m.audio_url,
          m.cover_image_url, m.listen_count AS listen_count, m.listen_count AS luot_nghe, a.artist_name,
          CASE WHEN l.music_id IS NULL THEN 0 ELSE 1 END AS is_favorite,
          MAX(h.created_at) AS last_listened
        FROM history h
        INNER JOIN music m ON m.music_id = h.music_id
        LEFT JOIN artists a ON a.artist_id = m.artist_id
        LEFT JOIN user_liked_songs l
          ON l.music_id = m.music_id AND l.user_id = @userId
        WHERE h.user_id = @userId AND h.type = 'listen' AND h.music_id IS NOT NULL
        GROUP BY
          m.music_id, m.music_name, m.music_length, m.audio_url,
          m.cover_image_url, m.listen_count, a.artist_name, l.music_id
        ORDER BY MAX(h.created_at) DESC
      `);
    res.json(result.recordset);
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.post("/:musicId/listen", async (req, res) => {
  try {
    const userId = Number(req.body?.userId) || 0;
    const musicId = Number(req.params.musicId);
    const pool = await getPool();
    await pool.request().input("musicId", musicId).query(`
      UPDATE music SET listen_count = ISNULL(listen_count, 0) + 1
      WHERE music_id = @musicId
    `);
    if (userId > 0) {
      await pool
        .request()
        .input("userId", userId)
        .input("musicId", musicId)
        .query(`
          INSERT INTO history (user_id, music_id, type)
          VALUES (@userId, @musicId, 'listen')
        `);
    }
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

module.exports = router;
