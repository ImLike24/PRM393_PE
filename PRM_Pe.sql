CREATE DATABASE PRM392_PE;
GO

USE PRM392_PE;
GO

-- ==========================================
-- 1. QUẢN LÝ NGƯỜI DÙNG
-- ==========================================
CREATE TABLE users (
  user_id INT IDENTITY(1,1) PRIMARY KEY,
  username NVARCHAR(255) NOT NULL,
  password NVARCHAR(255) NOT NULL,
  email NVARCHAR(255),
  avatar_url NVARCHAR(MAX),
  isActive INT NOT NULL DEFAULT 1
);

-- ==========================================
-- 2. DỮ LIỆU ÂM NHẠC
-- ==========================================
CREATE TABLE artists (
  artist_id INT IDENTITY(1,1) PRIMARY KEY,
  artist_name NVARCHAR(255) NOT NULL,
  avatar_url NVARCHAR(MAX),
  bio NVARCHAR(MAX)
);

CREATE TABLE albums (
  album_id INT IDENTITY(1,1) PRIMARY KEY,
  album_name NVARCHAR(255) NOT NULL,
  artist_id INT,
  cover_image_url NVARCHAR(MAX),
  release_date VARCHAR(50),
  CONSTRAINT FK_Albums_Artists FOREIGN KEY (artist_id)
    REFERENCES artists(artist_id) ON DELETE SET NULL
);

CREATE TABLE genres (
  genre_id INT IDENTITY(1,1) PRIMARY KEY,
  genre_name NVARCHAR(100) NOT NULL
);

CREATE TABLE music (
  music_id INT IDENTITY(1,1) PRIMARY KEY,
  music_name NVARCHAR(255) NOT NULL,
  music_length VARCHAR(20) NOT NULL,
  audio_url NVARCHAR(MAX) NOT NULL,
  cover_image_url NVARCHAR(MAX),
  artist_id INT,
  album_id INT,
  genre_id INT,
  ranking INT,
  luot_nghe INT DEFAULT 0,
  CONSTRAINT FK_Music_Artists FOREIGN KEY (artist_id)
    REFERENCES artists(artist_id) ON DELETE SET NULL,
  CONSTRAINT FK_Music_Albums FOREIGN KEY (album_id)
    REFERENCES albums(album_id) ON DELETE SET NULL,
  CONSTRAINT FK_Music_Genres FOREIGN KEY (genre_id)
    REFERENCES genres(genre_id) ON DELETE SET NULL
);

-- ==========================================
-- 3. PLAYLIST HỆ THỐNG & USER
-- ==========================================
CREATE TABLE playlist (
  playlist_id INT IDENTITY(1,1) PRIMARY KEY,
  playlist_name NVARCHAR(255) NOT NULL,
  playlist_song_list_count INT DEFAULT 0,
  favourite INT NOT NULL DEFAULT 0,
  favourite_count INT DEFAULT 0,
  description NVARCHAR(MAX),
  cover_image_url NVARCHAR(MAX)
);

CREATE TABLE playlist_music (
  playlist_id INT,
  music_id INT,
  PRIMARY KEY (playlist_id, music_id),
  CONSTRAINT FK_PM_Playlist FOREIGN KEY (playlist_id)
    REFERENCES playlist(playlist_id) ON DELETE CASCADE,
  CONSTRAINT FK_PM_Music FOREIGN KEY (music_id)
    REFERENCES music(music_id) ON DELETE CASCADE
);

CREATE TABLE user_playlist (
  user_playlist_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  playlist_name NVARCHAR(255) NOT NULL,
  playlist_song_list_count INT DEFAULT 0,
  favourite INT NOT NULL DEFAULT 0,
  favourite_count INT DEFAULT 0,
  description NVARCHAR(MAX),
  is_shared INT NOT NULL DEFAULT 0, -- 1 public, 0 private
  CONSTRAINT FK_UserPlaylist_Users FOREIGN KEY (user_id)
    REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE user_playlist_music (
  user_playlist_id INT,
  music_id INT,
  PRIMARY KEY (user_playlist_id, music_id),
  CONSTRAINT FK_UPM_UserPlaylist FOREIGN KEY (user_playlist_id)
    REFERENCES user_playlist(user_playlist_id) ON DELETE CASCADE,
  CONSTRAINT FK_UPM_Music FOREIGN KEY (music_id)
    REFERENCES music(music_id) ON DELETE CASCADE
);

CREATE TABLE user_liked_songs (
  user_id INT,
  music_id INT,
  created_at DATETIME2 DEFAULT GETDATE(),
  PRIMARY KEY (user_id, music_id),
  CONSTRAINT FK_ULS_Users FOREIGN KEY (user_id)
    REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT FK_ULS_Music FOREIGN KEY (music_id)
    REFERENCES music(music_id) ON DELETE CASCADE
);

-- Yeu thich playlist cua nguoi khac
-- ON DELETE NO ACTION voi users de tranh multiple cascade paths
CREATE TABLE user_liked_playlists (
  user_id INT NOT NULL,
  user_playlist_id INT NOT NULL,
  created_at DATETIME2 DEFAULT GETDATE(),
  PRIMARY KEY (user_id, user_playlist_id),
  CONSTRAINT FK_ULP_Users FOREIGN KEY (user_id)
    REFERENCES users(user_id) ON DELETE NO ACTION,
  CONSTRAINT FK_ULP_Playlist FOREIGN KEY (user_playlist_id)
    REFERENCES user_playlist(user_playlist_id) ON DELETE CASCADE
);

-- ==========================================
-- 4. LỊCH SỬ
-- ==========================================
CREATE TABLE history (
  id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  search_query NVARCHAR(255),
  music_id INT,
  type VARCHAR(50) NOT NULL, -- 'search' | 'listen'
  created_at DATETIME2 DEFAULT GETDATE(),
  CONSTRAINT FK_History_Users FOREIGN KEY (user_id)
    REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT FK_History_Music FOREIGN KEY (music_id)
    REFERENCES music(music_id) ON DELETE SET NULL
);
GO

-- ==========================================
-- XÓA DATA CŨ (nếu chạy lại seed trên DB đã có)
-- Bỏ qua block này nếu DB mới vừa CREATE
-- ==========================================
/*
DELETE FROM history;
DELETE FROM user_liked_playlists;
DELETE FROM user_liked_songs;
DELETE FROM user_playlist_music;
DELETE FROM user_playlist;
DELETE FROM playlist_music;
DELETE FROM playlist;
DELETE FROM music;
DELETE FROM genres;
DELETE FROM albums;
DELETE FROM artists;
DELETE FROM users;

DBCC CHECKIDENT ('history', RESEED, 0);
DBCC CHECKIDENT ('user_playlist', RESEED, 0);
DBCC CHECKIDENT ('playlist', RESEED, 0);
DBCC CHECKIDENT ('music', RESEED, 0);
DBCC CHECKIDENT ('genres', RESEED, 0);
DBCC CHECKIDENT ('albums', RESEED, 0);
DBCC CHECKIDENT ('artists', RESEED, 0);
DBCC CHECKIDENT ('users', RESEED, 0);
*/
GO

-- ==========================================
-- SEED: BẢNG CHA
-- ==========================================
INSERT INTO users (username, password, email, avatar_url, isActive) VALUES
(N'nguyenvanA', N'123456', N'a.nv@email.com', N'https://example.com/avatars/a.jpg', 1),
(N'tranthib', N'123456', N'b.tt@email.com', N'https://example.com/avatars/b.jpg', 1),
(N'levanc', N'123456', N'c.lv@email.com', N'https://example.com/avatars/c.jpg', 1),
(N'phamthid', N'123456', N'd.pt@email.com', N'https://example.com/avatars/d.jpg', 1),
(N'hoangvane', N'123456', N'e.hv@email.com', N'https://example.com/avatars/e.jpg', 0),
(N'vuthip', N'123456', N'f.vt@email.com', N'https://example.com/avatars/f.jpg', 1),
(N'dangvang', N'123456', N'g.dv@email.com', N'https://example.com/avatars/g.jpg', 1),
(N'buihinh', N'123456', N'h.bh@email.com', N'https://example.com/avatars/h.jpg', 1),
(N'ngothii', N'123456', N'i.nt@email.com', N'https://example.com/avatars/i.jpg', 0),
(N'duongvank', N'123456', N'k.dv@email.com', N'https://example.com/avatars/k.jpg', 1);

INSERT INTO artists (artist_name, avatar_url, bio) VALUES
(N'Sơn Tùng M-TP', N'https://example.com/artists/sontung.jpg', N'Ca sĩ nhạc Pop/R&B hàng đầu Việt Nam.'),
(N'Mỹ Tâm', N'https://example.com/artists/mytam.jpg', N'Họa mi tóc nâu, biểu tượng âm nhạc V-Pop.'),
(N'Đen Vâu', N'https://example.com/artists/denvau.jpg', N'Rapper mang đậm chất thơ và cuộc sống đời thường.'),
(N'Bích Phương', N'https://example.com/artists/bichphuong.jpg', N'Nữ ca sĩ với nhiều bản hit Pop catchy.'),
(N'Hoàng Thùy Linh', N'https://example.com/artists/hoangthuylinh.jpg', N'Tiên phong kết hợp âm nhạc dân gian và hiện đại.'),
(N'Jack', N'https://example.com/artists/jack.jpg', N'Ca sĩ trẻ sở hữu lượng fan khủng tại Việt Nam.'),
(N'Hà Anh Tuấn', N'https://example.com/artists/ha_anhtuan.jpg', N'Chủ nhân của các chuỗi concert âm nhạc lãng mạn.'),
(N'Vũ.', N'https://example.com/artists/vu.jpg', N'Hoàng tử Indie của làng nhạc Việt.'),
(N'Amee', N'https://example.com/artists/amee.jpg', N'Nữ ca sĩ trẻ với giọng hát ngọt ngào, trong trẻo.'),
(N'Trúc Nhân', N'https://example.com/artists/trucnhan.jpg', N'Ca sĩ sở hữu phong cách âm nhạc độc đáo, cá tính.');

INSERT INTO genres (genre_name) VALUES
(N'Pop'),
(N'Ballad'),
(N'Rap / Hip-hop'),
(N'R&B'),
(N'Dance / Electronic'),
(N'Indie'),
(N'Rock'),
(N'Bolero'),
(N'Acoustic'),
(N'Remix');

INSERT INTO playlist (playlist_name, playlist_song_list_count, favourite, favourite_count, description, cover_image_url) VALUES
(N'Top V-Pop Thịnh Hành', 3, 1, 5400, N'Những bài hát hot nhất hiện tại.', N'https://example.com/playlists/vpop.jpg'),
(N'Nhạc Trẻ Đỉnh Cao', 2, 1, 3200, N'Tổng hợp hit trẻ được yêu thích.', N'https://example.com/playlists/nhactre.jpg'),
(N'Rap Việt Cực Cháy', 1, 0, 1500, N'Giai điệu rap đậm chất đường phố.', N'https://example.com/playlists/rapviet.jpg'),
(N'Ballad Buồn Lắng Đọng', 3, 1, 4100, N'Dành cho những tâm sự buồn.', N'https://example.com/playlists/ballad.jpg'),
(N'Indie Chill Thư Giãn', 1, 0, 890, N'Thả lỏng tâm hồn cùng nhạc indie.', N'https://example.com/playlists/indie.jpg'),
(N'Nhạc Dance Sôi Động', 2, 0, 1200, N'Khuấy động bữa tiệc của bạn.', N'https://example.com/playlists/dance.jpg'),
(N'Giai Điệu Acoustic', 1, 0, 450, N'Mộc mạc và chân thành.', N'https://example.com/playlists/acoustic.jpg'),
(N'Lofi Chill Khuya', 0, 1, 2300, N'Học tập và làm việc hiệu quả.', N'https://example.com/playlists/lofi.jpg'),
(N'Trữ Tình Quê Hương', 0, 0, 300, N'Giai điệu quê hương đong đầy.', N'https://example.com/playlists/bolero.jpg'),
(N'Top Album Cũ Mà Hay', 0, 0, 150, N'Những hoài niệm xưa cũ.', N'https://example.com/playlists/classic.jpg');

-- ==========================================
-- SEED: CẤP 1
-- ==========================================
INSERT INTO albums (album_name, artist_id, cover_image_url, release_date) VALUES
(N'm-tp MTP', 1, N'https://example.com/albums/mtpmtp.jpg', '2017-04-01'),
(N'Tâm 9', 2, N'https://example.com/albums/tam9.jpg', '2017-12-03'),
(N'Nhà Đen', 3, N'https://example.com/albums/nhaden.jpg', '2020-05-15'),
(N'Dramatic', 4, N'https://example.com/albums/dramatic.jpg', '2018-11-18'),
(N'LINK', 5, N'https://example.com/albums/link.jpg', '2022-08-11'),
(N'Hồng nhan', 6, N'https://example.com/albums/jack.jpg', '2021-01-10'),
(N'Truyện Ngắn', 7, N'https://example.com/albums/truyenngan.jpg', '2019-09-20'),
(N'Một Vạn Năm', 8, N'https://example.com/albums/motvannam.jpg', '2022-03-09'),
(N'dreAMEE', 9, N'https://example.com/albums/dreamee.jpg', '2020-06-28'),
(N'Sáng Mắt Chưa', 10, N'https://example.com/albums/sangmatchua.jpg', '2019-07-31');

INSERT INTO user_playlist (user_id, playlist_name, playlist_song_list_count, favourite, favourite_count, description, is_shared) VALUES
(1, N'Nhạc của A', 2, 0, 0, N'Playlist cá nhân nghe lúc rảnh', 1),
(1, N'Sơn Tùng Playlist', 1, 1, 0, N'Toàn bài hay của Tùng', 0),
(2, N'B Tri Âm', 2, 0, 0, N'Bài hát yêu thích của B', 1),
(3, N'Rap để nghe', 1, 0, 0, N'Tổng hợp nhạc rap', 1),
(4, N'Nhạc ngủ ngon', 2, 1, 0, N'Nghe trước khi đi ngủ', 0),
(5, N'Playlist E', 0, 0, 0, N'Nháp', 0),
(6, N'F chill', 1, 0, 0, N'Giai điệu nhẹ nhàng', 1),
(7, N'G Collection', 1, 0, 0, N'Bộ sưu tập cá nhân', 1),
(8, N'H yêu âm nhạc', 0, 0, 0, N'Chưa phân loại', 0),
(10, N'K Track', 1, 0, 0, N'Thư viện cá nhân', 1);

-- ==========================================
-- SEED: MUSIC
-- audio_url: doi sang http://10.0.2.2:3000/musics/... khi co file local
-- ==========================================
INSERT INTO music (music_name, music_length, audio_url, cover_image_url, artist_id, album_id, genre_id, ranking, luot_nghe) VALUES
(N'Lạc Trôi', '03:55', N'http://10.0.2.2:3000/musics/LacTroi.mp3', N'https://example.com/cover/lactroi.jpg', 1, 1, 1, 1, 150000),
(N'Đâu Chỉ Riêng Em', '04:12', N'http://10.0.2.2:3000/musics/DauChiRiengEm.mp3', N'https://example.com/cover/dauchiriengem.jpg', 2, 2, 2, 2, 120000),
(N'Trốn Tìm', '04:30', N'http://10.0.2.2:3000/musics/TronTim.mp3', N'https://example.com/cover/trontim.jpg', 3, 3, 3, 3, 200000),
(N'Bùa Yêu', '03:22', N'http://10.0.2.2:3000/musics/BuaYeu.mp3', N'https://example.com/cover/buayeu.jpg', 4, 4, 1, 4, 95000),
(N'Gieo Quẻ', '03:25', N'http://10.0.2.2:3000/musics/GieoQue.mp3', N'https://example.com/cover/gieoque.jpg', 5, 5, 5, 5, 110000),
(N'Đom Đóm', '04:05', N'http://10.0.2.2:3000/musics/DomDom.mp3', N'https://example.com/cover/domdom.jpg', 6, 6, 2, 6, 85000),
(N'Tháng Mấy Em Nhớ Anh?', '04:45', N'http://10.0.2.2:3000/musics/ThangMayEmNhoAnh.mp3', N'https://example.com/cover/thangmayemnhoanh.jpg', 7, 7, 2, 7, 78000),
(N'Bước Qua Nhau', '04:01', N'http://10.0.2.2:3000/musics/BuocQuaNhau.mp3', N'https://example.com/cover/buocquanhau.jpg', 8, 8, 6, 8, 134000),
(N'Sao Anh Chưa Về Nhà', '03:36', N'http://10.0.2.2:3000/musics/SaoAnhChuaVeNha.mp3', N'https://example.com/cover/saoanhchuavenha.jpg', 9, 9, 1, 9, 67000),
(N'Sáng Mắt Chưa', '03:40', N'http://10.0.2.2:3000/musics/SangMatChua.mp3', N'https://example.com/cover/sangmatchua.jpg', 10, 10, 5, 10, 89000);

-- ==========================================
-- SEED: BẢNG TRUNG GIAN
-- ==========================================
INSERT INTO playlist_music (playlist_id, music_id) VALUES
(1, 1), (1, 4), (1, 5),
(2, 1), (2, 6),
(3, 3),
(4, 2), (4, 7), (4, 8),
(5, 8);

INSERT INTO user_playlist_music (user_playlist_id, music_id) VALUES
(1, 1), (1, 2),
(2, 1),
(3, 2), (3, 7),
(4, 3),
(5, 7), (5, 8),
(7, 8),
(8, 4),
(10, 5);

INSERT INTO user_liked_songs (user_id, music_id) VALUES
(1, 1), (1, 3),
(2, 2), (2, 4),
(3, 3),
(4, 5),
(6, 1),
(7, 7),
(8, 8),
(10, 9);

INSERT INTO history (user_id, search_query, music_id, type) VALUES
(1, N'Lạc Trôi', 1, 'search'),
(1, NULL, 1, 'listen'),
(2, N'Mỹ Tâm', NULL, 'search'),
(2, NULL, 2, 'listen'),
(3, N'Đen Vâu', 3, 'search'),
(3, NULL, 3, 'listen'),
(4, N'Bùa Yêu', 4, 'search'),
(5, N'Gieo Quẻ', 5, 'search'),
(6, NULL, 6, 'listen'),
(7, N'Hà Anh Tuấn', 7, 'search');

-- Chi thich playlist PUBLIC (is_shared = 1): id 1,3,4,7,8,10
INSERT INTO user_liked_playlists (user_id, user_playlist_id) VALUES
(2, 1),
(3, 1),
(1, 3),
(1, 4),
(6, 1),
(7, 3),
(10, 7),
(2, 10);

-- Cap nhat favourite_count theo bang liked
UPDATE up
SET favourite_count = (
  SELECT COUNT(*)
  FROM user_liked_playlists ulp
  WHERE ulp.user_playlist_id = up.user_playlist_id
)
FROM user_playlist up;
GO