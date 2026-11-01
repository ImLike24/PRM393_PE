import 'package:flutter/material.dart';
import '../controllers/player_controller.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import 'now_playing_page.dart';

/// Màn hình Bảng xếp hạng các bài hát được nghe nhiều nhất.
class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<Song> songs = [];
  bool loading = true;

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

  /// Lắng nghe sự kiện thay đổi dữ liệu để làm mới bảng xếp hạng real-time.
  void _onDataChanged() {
    if (mounted) _load();
  }

  /// Tải danh sách bài hát xếp hạng từ server.
  Future<void> _load() async {
    setState(() => loading = true);
    try {
      songs = await MusicService.instance.getRanking();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Phát bài hát được chọn từ bảng xếp hạng (hiển thị trên thanh mini player ở bottom).
  Future<void> _playSong(Song song) async {
    try {
      await PlayerController.instance.playSong(song, songs);
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

  /// Trả về màu sắc huy hiệu xếp hạng (Top 1 Gold, Top 2 Silver, Top 3 Bronze).
  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Vàng Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Bạc Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Đồng Bronze
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng Hot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
          ? const Center(child: Text('Chưa có dữ liệu xếp hạng'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final s = songs[i];
          final rank = i + 1;
          final rankColor = _getRankColor(rank);

          return Card(
            elevation: rank <= 3 ? 3 : 1,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Số thứ tự xếp hạng với huy hiệu màu
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rank <= 3 ? rankColor.withValues(alpha: 0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: rank <= 3 ? Border.all(color: rankColor, width: 1.5) : null,
                    ),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: rank <= 3 ? rankColor : Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ảnh bìa bài hát
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: s.coverImageUrl != null && s.coverImageUrl!.isNotEmpty
                        ? Image.network(
                      s.coverImageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPh(),
                    )
                        : _coverPh(),
                  ),
                ],
              ),
              title: Text(
                s.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${s.artist} · ${s.luotNghe} lượt nghe',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      s.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: s.isFavorite ? Colors.redAccent : null,
                    ),
                    tooltip: s.isFavorite ? 'Bỏ thích' : 'Yêu thích',
                    onPressed: () async {
                      await MusicService.instance.toggleFavorite(s.musicId!, !s.isFavorite);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, size: 36, color: Color(0xFFE8A35A)),
                    tooltip: 'Phát nhạc',
                    onPressed: () => _playSong(s),
                  ),
                ],
              ),
              onTap: () => _playSong(s),
            ),
          );
        },
      ),
    );
  }

  /// Trả về widget ảnh bìa mặc định khi không có ảnh.
  Widget _coverPh() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.black26,
      child: const Icon(Icons.album, size: 24),
    );
  }
}
