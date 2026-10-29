import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Song> liked = [];
  List<Map<String, dynamic>> playlists = [];
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

  void _onDataChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    if (!Session.isLoggedIn) {
      setState(() {
        liked = [];
        playlists = [];
        loading = false;
      });
      return;
    }
    setState(() => loading = true);
    try {
      final fav = await MusicService.instance.getFavoriteSongs();
      final pl = await MusicService.instance.getPlaylists();
      if (!mounted) return;
      setState(() {
        liked = fav;
        playlists = pl;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _newPlaylist() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Playlist moi'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Ten playlist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tao'),
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
        title: const Text('Ca nhan'),
        actions: [
          IconButton(
            onPressed: () => Session.toggleTheme(),
            icon: Icon(
              Session.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!loggedIn) ...[
            const Text('Ban dang xem o che do khach.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
                if (mounted) await _load();
              },
              child: const Text('Dang nhap / Dang ky'),
            ),
          ] else ...[
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(Session.user!.username),
              subtitle: Text(Session.user!.email ?? 'Khong co email'),
              trailing: TextButton(
                onPressed: () async {
                  await Session.setUser(null);
                  await _load();
                },
                child: const Text('Dang xuat'),
              ),
            ),
            const Divider(),
            Text(
              'Yeu thich (${liked.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (liked.isEmpty)
              const ListTile(title: Text('Chua co bai yeu thich'))
            else
              ...liked.map(
                    (s) => ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.redAccent),
                  title: Text(s.title),
                  subtitle: Text(s.artist),
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Playlist (${playlists.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _newPlaylist,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (playlists.isEmpty)
              const ListTile(title: Text('Chua co playlist'))
            else
              ...playlists.map(
                    (p) => ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text('${p['playlist_name'] ?? ''}'),
                  subtitle: Text('${p['playlist_song_list_count'] ?? 0} bai'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}