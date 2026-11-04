const express = require("express");
const { getPool } = require("../configs/db");

const router = express.Router();

router.post("/:userId/liked/:musicId", async (req, res) => {
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("userId", Number(req.params.userId))
      .input("musicId", Number(req.params.musicId))
      .query(`
        IF NOT EXISTS (
          SELECT 1 FROM user_liked_songs
          WHERE user_id = @userId AND music_id = @musicId
        )
        INSERT INTO user_liked_songs (user_id, music_id) VALUES (@userId, @musicId)
      `);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.delete("/:userId/liked/:musicId", async (req, res) => {
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("userId", Number(req.params.userId))
      .input("musicId", Number(req.params.musicId))
      .query("DELETE FROM user_liked_songs WHERE user_id = @userId AND music_id = @musicId");
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.get("/:userId/playlists", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool
      .request()
      .input("userId", Number(req.params.userId))
      .query(`
        SELECT user_playlist_id, user_id, playlist_name,
               playlist_song_list_count, favourite, description, is_shared
        FROM user_playlist
        WHERE user_id = @userId
        ORDER BY user_playlist_id DESC
      `);
    res.json(result.recordset);
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.post("/:userId/playlists", async (req, res) => {
  try {
    const { playlist_name, description } = req.body || {};
    const pool = await getPool();
    const result = await pool
      .request()
      .input("userId", Number(req.params.userId))
      .input("name", playlist_name || "Playlist moi")
      .input("description", description || null)
      .query(`
        INSERT INTO user_playlist (user_id, playlist_name, description)
        OUTPUT INSERTED.*
        VALUES (@userId, @name, @description)
      `);
    res.json(result.recordset[0]);
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.get("/:userId/search-history", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool
      .request()
      .input("userId", Number(req.params.userId))
      .query(`
        SELECT TOP 5 id, search_query, created_at
        FROM history
        WHERE user_id = @userId AND type = 'search' AND search_query IS NOT NULL
        ORDER BY created_at DESC
      `);
    res.json(result.recordset);
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.delete("/:userId/search-history/:id", async (req, res) => {
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("userId", Number(req.params.userId))
      .input("id", Number(req.params.id))
      .query("DELETE FROM history WHERE id = @id AND user_id = @userId AND type = 'search'");
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.delete("/:userId/search-history", async (req, res) => {
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("userId", Number(req.params.userId))
      .query("DELETE FROM history WHERE user_id = @userId AND type = 'search'");
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.post("/:userId/playlists/:playlistId/music/:musicId", async (req, res) => {
  try {
    const userId = Number(req.params.userId);
    const playlistId = Number(req.params.playlistId);
    const musicId = Number(req.params.musicId);
    const pool = await getPool();
    const own = await pool
      .request()
      .input("userId", userId)
      .input("playlistId", playlistId)
      .query(`
        SELECT user_playlist_id FROM user_playlist
        WHERE user_id = @userId AND user_playlist_id = @playlistId
      `);
    if (!own.recordset.length) {
      return res.status(404).json({ error: "Playlist khong ton tai" });
    }
    await pool
      .request()
      .input("playlistId", playlistId)
      .input("musicId", musicId)
      .query(`
        IF NOT EXISTS (
          SELECT 1 FROM user_playlist_music
          WHERE user_playlist_id = @playlistId AND music_id = @musicId
        )
        INSERT INTO user_playlist_music (user_playlist_id, music_id)
        VALUES (@playlistId, @musicId);

        UPDATE user_playlist
        SET playlist_song_list_count = (
          SELECT COUNT(*) FROM user_playlist_music
          WHERE user_playlist_id = @playlistId
        )
        WHERE user_playlist_id = @playlistId;
      `);
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.post("/:userId/playlists/:playlistId/favorite", async (req, res) => {
  try {
    const userId = Number(req.params.userId);
    const playlistId = Number(req.params.playlistId);
    const pool = await getPool();
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='playlist_favourites' and xtype='U')
      CREATE TABLE playlist_favourites (
        user_id INT,
        playlist_id INT,
        PRIMARY KEY (user_id, playlist_id)
      )
    `);
    await pool
      .request()
      .input("userId", userId)
      .input("playlistId", playlistId)
      .query(`
        IF NOT EXISTS (SELECT 1 FROM playlist_favourites WHERE user_id = @userId AND playlist_id = @playlistId)
        INSERT INTO playlist_favourites (user_id, playlist_id) VALUES (@userId, @playlistId)
      `);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.delete("/:userId/playlists/:playlistId/favorite", async (req, res) => {
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("userId", Number(req.params.userId))
      .input("playlistId", Number(req.params.playlistId))
      .query("DELETE FROM playlist_favourites WHERE user_id = @userId AND playlist_id = @playlistId");
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

router.get("/:userId/favorite-playlists", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool
      .request()
      .input("userId", Number(req.params.userId))
      .query(`
        SELECT p.user_playlist_id, p.user_id, p.playlist_name,
               p.playlist_song_list_count, p.description, p.is_shared,
               u.username AS owner_name, 1 AS is_favorite
        FROM playlist_favourites pf
        INNER JOIN user_playlist p ON p.user_playlist_id = pf.playlist_id
        INNER JOIN users u ON u.user_id = p.user_id
        WHERE pf.user_id = @userId
        ORDER BY p.user_playlist_id DESC
      `);
    res.json(result.recordset);
  } catch (e) {
    res.json([]);
  }
});

module.exports = router;