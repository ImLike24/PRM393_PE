import 'package:flutter/material.dart';
import '../services/music_service.dart';
import 'playlist_detail_page.dart';

/// Màn hình khám phá các playlist công khai từ những người dùng khác.
class PublicPlaylistsPage extends StatefulWidget {
  const PublicPlaylistsPage({super.key});

  @override
  State<PublicPlaylistsPage> createState() => _PublicPlaylistsPageState();
}

class _PublicPlaylistsPageState extends State<PublicPlaylistsPage> {
  List<Map<String, dynamic>> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    MusicService.changeNotifier.addListener(_onDataChanged);
    _load();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  /// Lắng nghe thay đổi dữ liệu để làm mới danh sách playlist công khai real-time.
  void _onDataChanged() {
    if (mounted) _load();
  }

  /// Tải danh sách playlist công khai từ server.
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _playlists = await MusicService.instance.getPublicPlaylists();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khám phá Playlist công khai')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
          ? const Center(child: Text('Chưa có playlist công khai nào'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _playlists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = _playlists[i];
          final name = p['playlist_name'] ?? '';
          final owner = p['owner_name'] ?? 'Không rõ';
          final count = p['playlist_song_list_count'] ?? 0;
          final isFav = (p['is_favorite'] ?? 0) == 1;

          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.queue_music)),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Tạo bởi: $owner · $count bài hát'),
              trailing: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : null,
                ),
                tooltip: isFav ? 'Bỏ lưu' : 'Lưu vào yêu thích',
                onPressed: () async {
                  final id = p['user_playlist_id'];
                  if (id == null) return;
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await MusicService.instance.togglePlaylistFavorite(
                      id is int ? id : int.parse('$id'),
                      !isFav,
                    );
                    _load();
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlaylistDetailPage(playlist: p)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
