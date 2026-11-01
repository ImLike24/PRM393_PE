import 'package:flutter/material.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'ranking_page.dart';
import 'profile_page.dart';
import 'now_playing_page.dart';
import '../controllers/player_controller.dart';
import 'package:just_audio/just_audio.dart';

/// Khung chính của ứng dụng chứa các tab điều hướng và thanh phát nhạc thu nhỏ (Mini Player).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomePage(),
          SearchPage(),
          RankingPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: PlayerController.instance.playerChangeNotifier,
        builder: (context, _, __) {
          final song = PlayerController.instance.current;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh phát nhạc thu nhỏ (Mini Player) hiển thị ngay trên bottom navigation bar, không làm chắn UI
              if (song != null)
                StreamBuilder<PlayerState>(
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
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                ),
              // Thanh điều hướng chính (Bottom Navigation Bar)
              NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => setState(() => index = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'Trang chủ'),
                  NavigationDestination(icon: Icon(Icons.search), label: 'Tìm kiếm'),
                  NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Xếp hạng'),
                  NavigationDestination(icon: Icon(Icons.person), label: 'Cá nhân'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Trả về ảnh bìa mặc định khi không tải được ảnh.
  Widget _coverPh() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.black26,
      child: const Icon(Icons.album, size: 24),
    );
  }
}
