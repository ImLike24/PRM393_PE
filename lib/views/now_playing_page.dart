import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/player_controller.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import 'login_page.dart';

/// Màn hình phát nhạc toàn màn hình (Now Playing) với giao diện chuyên nghiệp, trực quan.
class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final player = PlayerController.instance;

  @override
  void initState() {
    super.initState();
    MusicService.changeNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Lắng nghe thay đổi dữ liệu để làm mới trạng thái yêu thích bài hát.
  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// Thêm hoặc bỏ thích bài hát hiện tại.
  Future<void> _toggleFavorite() async {
    final song = player.current;
    if (song?.musicId == null) return;

    if (!Session.isLoggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final next = !song!.isFavorite;
    try {
      await MusicService.instance.toggleFavorite(song.musicId!, next);
      player.updateCurrentFavorite(next);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  /// Hiển thị bảng chọn playlist để thêm bài hát vào.
  Future<void> _addToPlaylist() async {
    final song = player.current;
    if (song?.musicId == null) return;

    if (!Session.isLoggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final playlists = await MusicService.instance.getPlaylists();
    if (!mounted) return;

    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có playlist. Hãy tạo ở tab Cá nhân.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Thêm vào playlist',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...playlists.map((p) {
                return ListTile(
                  leading: const Icon(Icons.queue_music, color: Colors.amber),
                  title: Text('${p['playlist_name'] ?? ''}', style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, p),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    final id = selected['user_playlist_id'];
    try {
      await MusicService.instance.addToPlaylist(
        id is int ? id : int.parse('$id'),
        song!.musicId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm vào playlist ${selected['playlist_name']}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  /// Định dạng thời lượng Duration thành chuỗi mm:ss.
  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Hiển thị ảnh bìa bài hát.
  Widget _cover(Song song) {
    final url = song.coverImageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  /// Hiển thị ảnh bìa mặc định khi lỗi hoặc không có ảnh.
  Widget _placeholder() {
    return Container(
      color: const Color(0xFF282828),
      child: const Center(
        child: Icon(Icons.album, size: 100, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = player.current;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E0D),
      body: SafeArea(
        child: song == null
            ? const Center(
          child: Text(
            'Chưa chọn bài hát',
            style: TextStyle(color: Colors.white),
          ),
        )
            : Column(
          children: [
            // Thanh tiêu đề trên cùng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 32,
                    ),
                    tooltip: 'Thu nhỏ',
                  ),
                  const Expanded(
                    child: Text(
                      'ĐANG PHÁT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addToPlaylist,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    tooltip: 'Tùy chọn',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Ảnh bìa album
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _cover(song),
                ),
              ),
            ),

            const Spacer(),

            // Tên bài hát, ca sĩ và nút yêu thích
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      song.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: song.isFavorite
                          ? const Color(0xFFE8A35A)
                          : Colors.white,
                    ),
                    tooltip: 'Yêu thích',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Thanh tiến trình phát nhạc (Slider)
            StreamBuilder<Duration?>(
              stream: player.durationStream,
              builder: (context, durSnap) {
                final total = durSnap.data ?? Duration.zero;
                final maxMs = total.inMilliseconds > 0
                    ? total.inMilliseconds.toDouble()
                    : 1.0;

                return StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    final value = pos.inMilliseconds
                        .clamp(0, maxMs.toInt())
                        .toDouble();

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFE8A35A),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            trackHeight: 3,
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: value,
                            max: maxMs,
                            onChanged: (v) {
                              player.seek(
                                Duration(milliseconds: v.toInt()),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 28),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format(pos),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _format(total),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 8),

            // Các nút điều khiển phát nhạc (Repeat, Previous, Play/Pause, Next, Add)
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? player.playing;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () async {
                          await player.toggleRepeat();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.repeat,
                          color: player.repeat
                              ? const Color(0xFFE8A35A)
                              : Colors.white70,
                        ),
                        tooltip: 'Lặp lại',
                      ),
                      IconButton(
                        iconSize: 40,
                        onPressed: () async {
                          await player.previous();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                        ),
                        tooltip: 'Bài trước',
                      ),
                      Material(
                        color: const Color(0xFFE8A35A),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            await player.togglePlay();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              size: 40,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 40,
                        onPressed: () async {
                          await player.next();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                        ),
                        tooltip: 'Bài tiếp theo',
                      ),
                      IconButton(
                        onPressed: _addToPlaylist,
                        icon: const Icon(
                          Icons.playlist_add,
                          color: Colors.white70,
                        ),
                        tooltip: 'Thêm vào playlist',
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Thanh điều chỉnh âm lượng (Volume Control)
            StreamBuilder<double>(
              stream: player.volumeStream,
              builder: (context, snapshot) {
                final vol = snapshot.data ?? player.volume;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          vol == 0
                              ? Icons.volume_off
                              : vol < 0.5
                                  ? Icons.volume_down
                                  : Icons.volume_up,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () {
                          player.setVolume(vol > 0 ? 0.0 : 1.0);
                        },
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFE8A35A),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: vol.clamp(0.0, 1.0),
                            onChanged: (v) => player.setVolume(v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(vol * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
