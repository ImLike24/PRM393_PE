const express = require("express");
const { getPool } = require("../configs/db");

const router = express.Router();

router.get("/:playlistId/songs", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    const playlistId = Number(req.params.playlistId);
    const pool = await getPool();
    const result = await pool
      .request()
      .input("userId", userId)
      .input("playlistId", playlistId)
      .query(`
        SELECT
          m.music_id, m.music_name, m.music_length, m.audio_url,
          m.cover_image_url, m.listen_count, a.artist_name,
          CASE WHEN l.music_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM user_playlist_music upm
        INNER JOIN music m ON m.music_id = upm.music_id
        LEFT JOIN artists a ON a.artist_id = m.artist_id
        LEFT JOIN user_liked_songs l
          ON l.music_id = m.music_id AND l.user_id = @userId
        WHERE upm.user_playlist_id = @playlistId
      `);
    res.json(result.recordset);
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.put("/:playlistId/share", async (req, res) => {
  try {
    const playlistId = Number(req.params.playlistId);
    const isShared = Number(req.body?.is_shared) ? 1 : 0;
    const pool = await getPool();
    await pool
      .request()
      .input("playlistId", playlistId)
      .input("isShared", isShared)
      .query("UPDATE user_playlist SET is_shared = @isShared WHERE user_playlist_id = @playlistId");
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.get("/public", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    const pool = await getPool();
    try {
      const result = await pool
        .request()
        .input("userId", userId)
        .query(`
          SELECT p.user_playlist_id, p.user_id, p.playlist_name,
                 p.playlist_song_list_count, p.description, p.is_shared,
                 u.username AS owner_name,
                 CASE WHEN pf.playlist_id IS NULL THEN 0 ELSE 1 END AS is_favorite
          FROM user_playlist p
          INNER JOIN users u ON u.user_id = p.user_id
          LEFT JOIN playlist_favourites pf
            ON pf.playlist_id = p.user_playlist_id AND pf.user_id = @userId
          WHERE p.is_shared = 1
          ORDER BY p.user_playlist_id DESC
        `);
      res.json(result.recordset);
    } catch (err) {
      const result = await pool.request().query(`
        SELECT p.user_playlist_id, p.user_id, p.playlist_name,
               p.playlist_song_list_count, p.description, p.is_shared,
               u.username AS owner_name, 0 AS is_favorite
        FROM user_playlist p
        INNER JOIN users u ON u.user_id = p.user_id
        WHERE p.is_shared = 1
        ORDER BY p.user_playlist_id DESC
      `);
      res.json(result.recordset);
    }
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

module.exports = router;