import 'package:flutter/material.dart';
import '../controllers/player_controller.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../services/session.dart';
import 'login_page.dart';
import 'now_playing_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> recent = [];
  List<Song> topSongs = [];
  List<Map<String, dynamic>> playlists = [];
  bool loading = true;
  String? error;

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
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final ranking = await MusicService.instance.getRanking();
      final rec = Session.isLoggedIn
          ? await MusicService.instance.getRecentSongs()
          : <Song>[];
      final pl = Session.isLoggedIn
          ? await MusicService.instance.getPlaylists()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        topSongs = ranking.take(10).toList();
        recent = rec;
        playlists = pl;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  Future<void> _play(Song song, List<Song> list) async {
    try {
      await PlayerController.instance.playSong(song, list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong phat duoc: $e')),
      );
      return;
    }

    if (song.musicId != null) {
      try {
        await MusicService.instance.logListen(song.musicId!);
      } catch (_) {}
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NowPlayingPage()),
    );

    // Quay lai Home thi refresh (nghe gan day, luot nghe)
    if (mounted) await _load();
  }


  @override
  Widget build(BuildContext context) {
    final guest = !Session.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(guest ? 'Vinyl Room (Khach)' : 'Vinyl Room'),
        actions: [
          if (guest)
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
                if (mounted) await _load();
              },
              child: const Text('Dang nhap'),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (!guest) ...[
              _sectionTitle('Nghe gan day'),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Chua co lich su nghe'),
                )
              else
                _horizontalSongs(recent),
            ],
            _sectionTitle('Dang nghe nhieu'),
            if (topSongs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chua co du lieu'),
              )
            else
              _horizontalSongs(topSongs),
            _sectionTitle('Playlist cua toi'),
            if (guest)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                    if (mounted) await _load();
                  },
                  child: const Text('Dang nhap de xem playlist'),
                ),
              )
            else if (playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Chua co playlist. Tao o tab Ca nhan.'),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playlists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final p = playlists[i];
                    return Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.queue_music, size: 36),
                          const Spacer(),
                          Text(
                            '${p['playlist_name'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('${p['playlist_song_list_count'] ?? 0} bai'),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _horizontalSongs(List<Song> list) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = list[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _play(s, list),
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: s.coverImageUrl != null && s.coverImageUrl!.isNotEmpty
                        ? Image.network(
                      s.coverImageUrl!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPh(),
                    )
                        : _coverPh(),
                  ),
                  const SizedBox(height: 8),
                  Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _coverPh() {
    return Container(
      width: 140,
      height: 140,
      color: Colors.black26,
      child: const Icon(Icons.album, size: 48),
    );
  }
}