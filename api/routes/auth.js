const express = require("express");
const { getPool } = require("../configs/db");

const router = express.Router();

router.post("/register", async (req, res) => {
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
      return res.status(409).json({ error: "Tên tài khoản đã tồn tại. Vui lòng chọn tên tài khoản khác!" });
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

router.post("/login", async (req, res) => {
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

module.exports = router;