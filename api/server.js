const express = require("express");
const cors = require("cors");
const path = require("path");
const { apiPort } = require("./configs/db");

const authRoutes = require("./routes/auth");
const musicRoutes = require("./routes/music");
const userRoutes = require("./routes/users");
const playlistRoutes = require("./routes/playlists");

const app = express();

app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
  next();
});

app.use("/musics", express.static(path.join(__dirname, "musics")));

app.use("/auth", authRoutes);
app.use("/music", musicRoutes);
app.use("/users", userRoutes);
app.use("/playlists", playlistRoutes);

app.listen(apiPort, "0.0.0.0", () => {
  console.log("API: http://localhost:" + apiPort);
});
