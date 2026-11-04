import 'package:flutter/material.dart';
import '../controllers/player_controller.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../services/session.dart';

/// Màn hình Tìm kiếm bài hát CHỈ THEO TÊN BÀI HÁT (tìm theo nguyên cụm từ hoặc từng từ).
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ctrl = TextEditingController();
  List<Song> results = [];
  List<Map<String, dynamic>> history = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    MusicService.changeNotifier.addListener(_onDataChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    ctrl.dispose();
    super.dispose();
  }

  /// Lắng nghe thay đổi dữ liệu để cập nhật lại kết quả tìm kiếm theo thời gian thực.
  void _onDataChanged() {
    if (!mounted) return;
    if (ctrl.text.trim().isNotEmpty) {
      _search(ctrl.text);
    } else {
      _loadHistory();
    }
  }

  /// Tải lịch sử tìm kiếm gần đây từ server.
  Future<void> _loadHistory() async {
    history = await MusicService.instance.getSearchHistory();
    if (mounted) setState(() {});
  }

  /// Tìm kiếm bài hát CHỈ THEO TÊN BÀI HÁT (hỗ trợ cả cụm từ hoặc từng từ) và lưu lịch sử.
  Future<void> _search([String? text]) async {
    final q = (text ?? ctrl.text).trim();
    if (q.isEmpty) {
      setState(() => results = []);
      return;
    }
    ctrl.text = q;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => loading = true);
    try {
      results = await MusicService.instance.searchSongs(q);
      await _loadHistory();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Phát bài hát được chọn từ kết quả tìm kiếm (hiển thị trên thanh mini player ở bottom).
  Future<void> _playSong(Song song) async {
    try {
      await PlayerController.instance.playSong(song, results);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm bài hát')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Nhập tên bài hát...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _search(),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) {
                if (val.trim().isEmpty) {
                  setState(() => results = []);
                } else {
                  _search(val);
                }
              },
              onSubmitted: _search,
            ),
          ),
          if (ctrl.text.trim().isEmpty && Session.isLoggedIn && history.isNotEmpty) ...[
            ListTile(
              title: const Text('Tìm kiếm gần đây'),
              trailing: TextButton(
                onPressed: () async {
                  await MusicService.instance.clearSearchHistory();
                  await _loadHistory();
                },
                child: const Text('Xóa tất cả'),
              ),
            ),
            ...history.map((h) {
              final id = h['id'] as int;
              final q = h['search_query']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(q),
                onTap: () => _search(q),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await MusicService.instance.deleteSearchHistoryItem(id);
                    await _loadHistory();
                  },
                ),
              );
            }),
            const Divider(),
          ],
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ctrl.text.trim().isNotEmpty && results.isEmpty
                ? const Center(child: Text('Không tìm thấy bài hát nào khớp với tên vừa nhập'))
                : ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final s = results[i];
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
                    },
                  ),
                  onTap: () => _playSong(s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
