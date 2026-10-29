import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/api_config.dart';

class PlayerController {
  PlayerController._();
  static final PlayerController instance = PlayerController._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<int> playerChangeNotifier = ValueNotifier<int>(0);

  void _notifyPlayerChange() {
    playerChangeNotifier.value++;
  }

  List<Song> queue = [];
  int index = 0;
  bool repeat = false;

  Song? get current =>
      queue.isEmpty || index < 0 || index >= queue.length ? null : queue[index];

  bool get playing => _player.playing;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<double> get volumeStream => _player.volumeStream;
  double get volume => _player.volume;

  Future<void> setVolume(double v) async {
    await _player.setVolume(v.clamp(0.0, 1.0));
  }

  String resolveUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (url.isEmpty) return '';

    // Convert localhost or 127.0.0.1 to ApiConfig.baseUrl (10.0.2.2 on Android Emulator)
    if (url.contains('localhost:3000')) {
      url = url.replaceAll('http://localhost:3000', ApiConfig.baseUrl);
      url = url.replaceAll('https://localhost:3000', ApiConfig.baseUrl);
    } else if (url.contains('127.0.0.1:3000')) {
      url = url.replaceAll('http://127.0.0.1:3000', ApiConfig.baseUrl);
      url = url.replaceAll('https://127.0.0.1:3000', ApiConfig.baseUrl);
    }

    // Prepend ApiConfig.baseUrl if url is relative
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (!url.startsWith('/')) {
        url = '/$url';
      }
      url = '${ApiConfig.baseUrl}$url';
    }

    return url;
  }

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    queue = List<Song>.from(songs);
    index = startIndex.clamp(0, queue.isEmpty ? 0 : queue.length - 1);
    _notifyPlayerChange();
    await _loadCurrent(autoPlay: true);
  }

  Future<void> playSong(Song song, List<Song> fromList) async {
    final i = fromList.indexWhere((s) => s.musicId == song.musicId);
    await setQueue(fromList, startIndex: i >= 0 ? i : 0);
  }

  Future<void> _loadCurrent({bool autoPlay = true}) async {
    final song = current;
    if (song == null) return;

    _notifyPlayerChange();

    final rawUrl = song.audioUrl.trim();
    if (rawUrl.isEmpty) {
      throw Exception('Bai hat chua co audio_url');
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
      throw Exception('Loi phat nhạc ($url): $e');
    }
  }

  Future<void> togglePlay() async {
    if (current == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> next() async {
    if (queue.isEmpty) return;
    if (index < queue.length - 1) {
      index++;
      await _loadCurrent();
    } else if (repeat) {
      index = 0;
      await _loadCurrent();
    }
  }

  Future<void> previous() async {
    if (queue.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (index > 0) {
      index--;
      await _loadCurrent();
    } else if (repeat) {
      index = queue.length - 1;
      await _loadCurrent();
    }
  }

  Future<void> toggleRepeat() async {
    repeat = !repeat;
    await _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void updateCurrentFavorite(bool isFavorite) {
    final c = current;
    if (c == null) return;
    queue[index] = c.copyWith(isFavorite: isFavorite);
  }

  void updateSongFavorite(int musicId, bool isFavorite) {
    for (int i = 0; i < queue.length; i++) {
      if (queue[i].musicId == musicId) {
        queue[i] = queue[i].copyWith(isFavorite: isFavorite);
      }
    }
  }
}