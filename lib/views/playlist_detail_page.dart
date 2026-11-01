import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/player_controller.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import 'now_playing_page.dart';

/// Màn hình chi tiết Playlist hiển thị danh sách bài hát bên trong và các tùy chọn chia sẻ/yêu thích.
class PlaylistDetailPage extends StatefulWidget {
  final Map<String, dynamic> playlist;
  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late Map<String, dynamic> _pl;
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pl = widget.playlist;
    MusicService.changeNotifier.addListener(_onDataChanged);
    _load();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Lắng nghe sự kiện thay đổi dữ liệu để làm mới chi tiết playlist.
  void _onDataChanged() {
    if (mounted) _load();
  }

  /// Tải danh sách bài hát có trong playlist từ server.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final id = _pl['user_playlist_id'] ?? _pl['playlist_id'];
      if (id != null) {
        _songs = await MusicService.instance.getPlaylistSongs(
          id is int ? id : int.parse('$id'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Phát bài hát từ playlist và hiển thị thanh mini player bên dưới.
  Future<void> _playSong(Song song) async {
    try {
      await PlayerController.instance.playSong(song, _songs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không phát được bài hát: $e')),
      );
      return;
    }

    if (song.musicId != null) {
      try {
        await MusicService.instance.logListen(song.musicId!);
      } catch (_) {}
    }
  }

  /// Kiểm tra xem người dùng hiện tại có phải là chủ sở hữu playlist này không.
  bool get _isOwner => Session.userId == (_pl['user_id'] ?? 0);

  /// Chuyển đổi trạng thái chia sẻ của playlist (Công khai / Riêng tư) và hiển thị Pop-up thông báo.
  Future<void> _toggleShare() async {
    final id = _pl['user_playlist_id'] ?? _pl['playlist_id'];
    if (id == null) return;
    final currentShared = (_pl['is_shared'] ?? 0) == 1;
    final nextShared = !currentShared;

    try {
      await MusicService.instance.updatePlaylistShare(
        id is int ? id : int.parse('$id'),
        nextShared,
      );

      // Cập nhật trạng thái trực tiếp trên giao diện local mà không cần tải lại trang
      setState(() {
        _pl['is_shared'] = nextShared ? 1 : 0;
      });

      if (!mounted) return;

      // Hiển thị Pop-up thông báo đã đổi trạng thái
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            nextShared ? Icons.public : Icons.lock,
            size: 48,
            color: nextShared ? Colors.greenAccent : Colors.orangeAccent,
          ),
          title: Text(
            nextShared ? 'Đã công khai Playlist' : 'Đã đặt chế độ Riêng tư',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            nextShared
                ? 'Playlist "${_pl['playlist_name']}" hiện đã ở chế độ Công khai (Public). Mọi người đều có thể tìm thấy và nghe playlist này!'
                : 'Playlist "${_pl['playlist_name']}" hiện đã chuyển sang chế độ Riêng tư (Private). Chỉ mình bạn có thể xem playlist này!',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thất bại'),
          content: Text('Lỗi cập nhật: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  /// Thêm hoặc bỏ thích playlist công khai của người khác.
  Future<void> _toggleFavorite() async {
    final id = _pl['user_playlist_id'] ?? _pl['playlist_id'];
    if (id == null) return;
    final currentFav = (_pl['is_favorite'] ?? 0) == 1;
    try {
      await MusicService.instance.togglePlaylistFavorite(
        id is int ? id : int.parse('$id'),
        !currentFav,
      );
      setState(() {
        _pl['is_favorite'] = !currentFav ? 1 : 0;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentFav ? 'Đã lưu playlist vào yêu thích' : 'Đã bỏ yêu thích playlist'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _pl['playlist_name'] ?? 'Playlist';
    final owner = _pl['owner_name'] ?? 'Tôi';
    final isShared = (_pl['is_shared'] ?? 0) == 1;
    final isFavorite = (_pl['is_favorite'] ?? 0) == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (_isOwner)
            IconButton(
              icon: Icon(
                isShared ? Icons.public : Icons.lock,
                color: isShared ? Colors.greenAccent : Colors.orangeAccent,
              ),
              tooltip: isShared ? 'Đang Công khai (Bấm để đổi Riêng tư)' : 'Đang Riêng tư (Bấm để đổi Công khai)',
              onPressed: _toggleShare,
            )
          else
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : null,
              ),
              tooltip: isFavorite ? 'Bỏ lưu' : 'Lưu playlist',
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tác giả: $owner · ${_songs.length} bài hát',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isShared ? Icons.public : Icons.lock,
                      size: 14,
                      color: isShared ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isShared ? 'Công khai (Public)' : 'Riêng tư (Private)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isShared ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                if (_songs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _playSong(_songs.first),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Phát tất cả'),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _songs.isEmpty
                ? const Center(child: Text('Playlist chưa có bài hát nào'))
                : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (_, i) {
                final s = _songs[i];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(s.title),
                  subtitle: Text(s.artist),
                  trailing: IconButton(
                    icon: Icon(
                      s.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: s.isFavorite ? Colors.redAccent : null,
                    ),
                    onPressed: () async {
                      await MusicService.instance.toggleFavorite(s.musicId!, !s.isFavorite);
                      _load();
                    },
                  ),
                  onTap: () => _playSong(s),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: PlayerController.instance.playerChangeNotifier,
        builder: (context, _, __) {
          final song = PlayerController.instance.current;
          if (song == null) return const SizedBox.shrink();

          return StreamBuilder<PlayerState>(
            stream: PlayerController.instance.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? PlayerController.instance.playing;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NowPlayingPage()),
                  );
                },
                child: Container(
                  height: 64,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty
                            ? Image.network(
                                song.coverImageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _coverPh(),
                              )
                            : _coverPh(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: () async {
                          await PlayerController.instance.togglePlay();
                          setState(() {});
                        },
                        tooltip: playing ? 'Tạm dừng' : 'Phát',
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: () async {
                          await PlayerController.instance.next();
                        },
                        tooltip: 'Bài tiếp theo',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Trả về ảnh bìa mặc định.
  Widget _coverPh() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.black26,
      child: const Icon(Icons.album, size: 24),
    );
  }
}
