import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import 'login_page.dart';
import 'playlist_detail_page.dart';
import 'public_playlists_page.dart';
import '../controllers/player_controller.dart';

/// Trang cá nhân hiển thị thông tin người dùng, bài hát yêu thích và danh sách playlist.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Song> liked = [];
  List<Map<String, dynamic>> playlists = [];
  List<Map<String, dynamic>> favPlaylists = [];
  bool loading = false;

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

  /// Hàm lắng nghe khi dữ liệu thay đổi để cập nhật giao diện real-time.
  void _onDataChanged() {
    if (mounted) _load();
  }

  /// Tải thông tin bài hát yêu thích và playlist từ server.
  Future<void> _load() async {
    if (!Session.isLoggedIn) {
      setState(() {
        liked = [];
        playlists = [];
        favPlaylists = [];
        loading = false;
      });
      return;
    }
    setState(() => loading = true);
    try {
      final fav = await MusicService.instance.getFavoriteSongs();
      final pl = await MusicService.instance.getPlaylists();
      final fpl = await MusicService.instance.getFavoritePlaylists();
      if (!mounted) return;
      setState(() {
        liked = fav;
        playlists = pl;
        favPlaylists = fpl;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  /// Hiển thị hộp thoại tạo playlist mới.
  Future<void> _newPlaylist() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo Playlist mới'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nhập tên playlist...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await MusicService.instance.createPlaylist(ctrl.text.trim());
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = Session.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PublicPlaylistsPage()),
              );
              await _load();
            },
            icon: const Icon(Icons.explore),
            tooltip: 'Khám phá playlist công khai',
          ),
          IconButton(
            onPressed: () => Session.toggleTheme(),
            icon: Icon(
              Session.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Đổi giao diện sáng/tối',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!loggedIn) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.account_circle, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Bạn chưa đăng nhập',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Đăng nhập để quản lý bài hát yêu thích và playlist.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                        if (mounted) await _load();
                      },
                      child: const Text('Đăng nhập / Đăng ký'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Thẻ thông tin người dùng
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Session.user!.username,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Session.user!.email ?? 'Chưa có email',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        // Dừng nhạc khi đăng xuất
                        await PlayerController.instance.stop();
                        await Session.setUser(null);
                        await _load();
                      },
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Phần Bài hát yêu thích
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bài hát yêu thích (${liked.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (liked.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có bài hát yêu thích nào.'),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: liked.length > 5 ? 5 : liked.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = liked[i];
                    return ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.redAccent),
                      title: Text(s.title),
                      subtitle: Text(s.artist),
                      onTap: () => PlayerController.instance.playSong(s, liked),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Phần Playlist của tôi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Playlist của tôi (${playlists.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _newPlaylist,
                  icon: const Icon(Icons.add_circle, color: Colors.amber),
                  tooltip: 'Tạo playlist mới',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (playlists.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chưa có playlist nào.'),
                      TextButton.icon(
                        onPressed: _newPlaylist,
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo ngay'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...playlists.map((p) {
                final isShared = (p['is_shared'] ?? 0) == 1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.queue_music, color: Colors.amber),
                    title: Text('${p['playlist_name'] ?? ''}'),
                    subtitle: Text('${p['playlist_song_list_count'] ?? 0} bài · ${isShared ? "Công khai" : "Riêng tư"}'),
                    trailing: Icon(isShared ? Icons.public : Icons.lock, size: 18, color: isShared ? Colors.green : Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PlaylistDetailPage(playlist: p)),
                      );
                    },
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Phần Playlist yêu thích từ người khác
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Playlist đã lưu (${favPlaylists.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PublicPlaylistsPage()),
                    );
                    await _load();
                  },
                  child: const Text('Khám phá'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (favPlaylists.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa lưu playlist công khai nào của người khác.'),
                ),
              )
            else
              ...favPlaylists.map((p) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.bookmark, color: Colors.blueAccent),
                    title: Text('${p['playlist_name'] ?? ''}'),
                    subtitle: Text('Tác giả: ${p['owner_name'] ?? ''} · ${p['playlist_song_list_count'] ?? 0} bài'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PlaylistDetailPage(playlist: p)),
                      );
                    },
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
