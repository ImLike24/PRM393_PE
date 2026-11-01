import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/api_config.dart';

/// Quản lý trình phát nhạc (AudioPlayer), hàng đợi bài hát và trạng thái phát.
class PlayerController {
  PlayerController._() {
    _initPlayerListener();
  }

  static final PlayerController instance = PlayerController._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<int> playerChangeNotifier = ValueNotifier<int>(0);

  List<Song> queue = [];
  int index = 0;
  bool repeat = false;

  /// Thông báo cho các Widget cập nhật khi thay đổi bài hát phát.
  void _notifyPlayerChange() {
    playerChangeNotifier.value++;
  }

  /// Lắng nghe trạng thái bài hát. Khi bài hát phát xong và không bật lặp lại, tự động chuyển sang bài tiếp theo.
  void _initPlayerListener() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (!repeat) {
          next();
        }
      }
    });
  }

  /// Trả về bài hát đang phát hiện tại.
  Song? get current =>
      queue.isEmpty || index < 0 || index >= queue.length ? null : queue[index];

  /// Trả về trạng thái đang phát (true) hay tạm dừng (false).
  bool get playing => _player.playing;

  /// Stream thời gian vị trí hiện tại của bài hát.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream tổng thời lượng của bài hát.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream trạng thái phát nhạc (play/pause/completed).
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream âm lượng.
  Stream<double> get volumeStream => _player.volumeStream;

  /// Trả về mức âm lượng hiện tại (0.0 - 1.0).
  double get volume => _player.volume;

  /// Đặt mức âm lượng cho trình phát nhạc.
  Future<void> setVolume(double v) async {
    await _player.setVolume(v.clamp(0.0, 1.0));
  }

  /// Chuẩn hóa đường dẫn URL (chuyển localhost thành 10.0.2.2 cho máy ảo Android, thêm baseUrl nếu là đường dẫn tương đối).
  String resolveUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (url.isEmpty) return '';

    if (url.contains('localhost:3000')) {
      url = url.replaceAll('http://localhost:3000', ApiConfig.baseUrl);
      url = url.replaceAll('https://localhost:3000', ApiConfig.baseUrl);
    } else if (url.contains('127.0.0.1:3000')) {
      url = url.replaceAll('http://127.0.0.1:3000', ApiConfig.baseUrl);
      url = url.replaceAll('https://127.0.0.1:3000', ApiConfig.baseUrl);
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (!url.startsWith('/')) {
        url = '/$url';
      }
      url = '${ApiConfig.baseUrl}$url';
    }

    return url;
  }

  /// Thiết lập hàng đợi danh sách bài hát và bắt đầu phát từ vị trí chỉ định.
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    queue = List<Song>.from(songs);
    index = startIndex.clamp(0, queue.isEmpty ? 0 : queue.length - 1);
    _notifyPlayerChange();
    await _loadCurrent(autoPlay: true);
  }

  /// Phát một bài hát cụ thể trong một danh sách cho trước.
  Future<void> playSong(Song song, List<Song> fromList) async {
    final i = fromList.indexWhere((s) => s.musicId == song.musicId);
    await setQueue(fromList, startIndex: i >= 0 ? i : 0);
  }

  /// Tải và phát bài hát hiện tại ở vị trí `index`.
  Future<void> _loadCurrent({bool autoPlay = true}) async {
    final song = current;
    if (song == null) return;

    _notifyPlayerChange();

    final rawUrl = song.audioUrl.trim();
    if (rawUrl.isEmpty) {
      throw Exception('Bài hát chưa có đường dẫn audio_url');
    }

    final url = resolveUrl(rawUrl);

    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
      if (autoPlay) {
        await _player.play();
      }
    } catch (e) {
      throw Exception('Lỗi phát nhạc ($url): $e');
    }
  }

  /// Chuyển đổi trạng thái Phát / Tạm dừng.
  Future<void> togglePlay() async {
    if (current == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Chuyển sang bài tiếp theo. Nếu đã đến bài cuối cùng, tự động lặp lại bài đầu tiên (index = 0).
  Future<void> next() async {
    if (queue.isEmpty) return;
    // Tăng chỉ số bài hát; nếu quá độ dài danh sách thì lặp lại từ bài 0
    index = (index + 1) % queue.length;
    await _loadCurrent();
  }

  /// Quay lại bài trước đó (hoặc tua về đầu bài nếu đã phát quá 3 giây).
  Future<void> previous() async {
    if (queue.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (index > 0) {
      index--;
    } else {
      // Đang ở bài đầu tiên -> quay về bài cuối cùng trong danh sách
      index = queue.length - 1;
    }
    await _loadCurrent();
  }

  /// Bật/tắt chế độ lặp lại 1 bài.
  Future<void> toggleRepeat() async {
    repeat = !repeat;
    await _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
  }

  /// Tua nhạc đến vị trí thời gian `position`.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Dừng phát nhạc hoàn toàn và xóa hàng đợi (dùng khi đăng xuất tài khoản).
  Future<void> stop() async {
    await _player.stop();
    queue = [];
    index = 0;
    _notifyPlayerChange();
  }

  /// Cập nhật trạng thái yêu thích của bài hát đang phát.
  void updateCurrentFavorite(bool isFavorite) {
    final c = current;
    if (c == null) return;
    queue[index] = c.copyWith(isFavorite: isFavorite);
  }

  /// Cập nhật trạng thái yêu thích của bài hát trong toàn bộ hàng đợi.
  void updateSongFavorite(int musicId, bool isFavorite) {
    for (int i = 0; i < queue.length; i++) {
      if (queue[i].musicId == musicId) {
        queue[i] = queue[i].copyWith(isFavorite: isFavorite);
      }
    }
  }
}
