const express = require("express");
const cors = require("cors");
const { getPool, props } = require("./db");

const app = express();
app.use(cors());
app.use(express.json());
const path = require("path");

app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
  next();
});

app.use("/musics", express.static(path.join(__dirname, "../musics")));

const songSelect = `
  SELECT
    m.music_id, m.music_name, m.music_length, m.audio_url,
    m.cover_image_url, m.luot_nghe, a.artist_name,
    CASE WHEN l.music_id IS NULL THEN 0 ELSE 1 END AS is_favorite
  FROM music m
  LEFT JOIN artists a ON a.artist_id = m.artist_id
  LEFT JOIN user_liked_songs l
    ON l.music_id = m.music_id AND l.user_id = @userId
`;

async function querySongs(extraWhere, inputs, orderBy = "m.music_id") {
  const pool = await getPool();
  const req = pool.request();
  for (const [k, v] of Object.entries(inputs)) req.input(k, v);
  const where = extraWhere ? `WHERE ${extraWhere}` : "";
  const result = await req.query(
    `${songSelect} ${where} ORDER BY ${orderBy}`,
  );
  return result.recordset;
}

// ---------- AUTH ----------
app.post("/auth/register", async (req, res) => {
  try {
    const { username, password, email } = req.body || {};
    if (!username || !password) {
      return res.status(400).json({ error: "Thieu username/password" });
    }
    const pool = await getPool();
    const exists = await pool
      .request()
      .input("username", username)
      .query("SELECT user_id FROM users WHERE username = @username");
    if (exists.recordset.length) {
      return res.status(409).json({ error: "Username da ton tai" });
    }
    const result = await pool
      .request()
      .input("username", username)
      .input("password", password)
      .input("email", email || null)
      .query(`
        INSERT INTO users (username, password, email, isActive)
        OUTPUT INSERTED.user_id, INSERTED.username, INSERTED.email, INSERTED.avatar_url, INSERTED.isActive
        VALUES (@username, @password, @email, 1)
      `);
    res.json(result.recordset[0]);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: String(e.message || e) });
  }
});

app.post("/auth/login", async (req, res) => {
  try {
    const { username, password } = req.body || {};
    const pool = await getPool();
    const result = await pool
      .request()
      .input("username", username)
      .input("password", password)
      .query(`
        SELECT user_id, username, email, avatar_url, isActive
        FROM users
        WHERE username = @username AND password = @password AND isActive = 1
      `);
    if (!result.recordset.length) {
      return res.status(401).json({ error: "Sai tai khoan hoac mat khau" });
    }
    res.json(result.recordset[0]);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: String(e.message || e) });
  }
});

// ---------- MUSIC ----------
app.get("/music", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    res.json(await querySongs("", { userId }));
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

// Bang xep hang theo luot nghe
app.get("/music/ranking", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    res.json(await querySongs("", { userId }, "m.luot_nghe DESC, m.music_id"));
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

app.get("/music/favorites", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    if (!userId) return res.json([]);
    res.json(await querySongs("l.music_id IS NOT NULL", { userId }));
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

app.get("/music/search", async (req, res) => {
  try {
    const userId = Number(req.query.userId) || 0;
    const keyword = (req.query.q || "").trim();
    const q = `%${keyword}%`;
    const data = await querySongs(
      "(m.music_name LIKE @q OR a.artist_name LIKE @q)",
      { userId, q },
    );
    // Luu lich su tim kiem (toi da xu ly o client + day len DB)
    if (userId && keyword) {
      const pool = await getPool();
      await pool
        .request()
        .input("userId", userId)
        .input("search_query", keyword)
        .query(`
          INSERT INTO history (user_id, search_query, type)
          VALUES (@userId, @search_query, 'search')
        `);
    }
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

app.post("/users/:userId/liked/:musicId", async (req, res) => {
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

app.delete("/users/:userId/liked/:musicId", async (req, res) => {
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("userId", Number(req.params.userId))
      .input("musicId", Number(req.params.musicId))
      .query(
        "DELETE FROM user_liked_songs WHERE user_id = @userId AND music_id = @musicId",
      );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

// ---------- PLAYLIST CUA USER ----------
app.get("/users/:userId/playlists", async (req, res) => {
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

app.post("/users/:userId/playlists", async (req, res) => {
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

// ---------- LICH SU TIM KIEM (5 gan nhat) ----------
app.get("/users/:userId/search-history", async (req, res) => {
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

app.delete("/users/:userId/search-history/:id", async (req, res) => {
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("userId", Number(req.params.userId))
      .input("id", Number(req.params.id))
      .query(
        "DELETE FROM history WHERE id = @id AND user_id = @userId AND type = 'search'",
      );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

app.delete("/users/:userId/search-history", async (req, res) => {
  try {
    const pool = await getPool();
    await pool
      .request()
      .input("userId", Number(req.params.userId))
      .query(
        "DELETE FROM history WHERE user_id = @userId AND type = 'search'",
      );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

const port = Number(props["api.port"] || 3000);
app.listen(port, "0.0.0.0", () => {
  console.log("API: http://localhost:" + port);
});

// Them bai hat vao playlist cua user
app.post("/users/:userId/playlists/:playlistId/music/:musicId", async (req, res) => {
  try {
    const userId = Number(req.params.userId);
    const playlistId = Number(req.params.playlistId);
    const musicId = Number(req.params.musicId);
    const pool = await getPool();

    // Chi cho phep playlist cua dung user
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

// Bai hat nghe gan day (tu bang history type = listen)
app.get("/music/recent", async (req, res) => {
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
          m.cover_image_url, m.luot_nghe, a.artist_name,
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
          m.cover_image_url, m.luot_nghe, a.artist_name, l.music_id
        ORDER BY MAX(h.created_at) DESC
      `);
    res.json(result.recordset);
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

// Ghi lich su nghe + tang luot_nghe
app.post("/music/:musicId/listen", async (req, res) => {
  try {
    const userId = Number(req.body?.userId) || 0;
    const musicId = Number(req.params.musicId);
    const pool = await getPool();

    await pool
      .request()
      .input("musicId", musicId)
      .query(`
        UPDATE music SET luot_nghe = ISNULL(luot_nghe, 0) + 1
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