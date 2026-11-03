import '../models/song.dart';
import '../services/music_service.dart';

abstract class HomeView {
  void showLoading();
  void hideLoading();
  void showSongs(List<Song> songs);
  void showFavorites(List<Song> favorites);
  void showError(String message);
  void showMessage(String message);
}

class HomePresenter {
  HomePresenter(this._view);

  final HomeView _view;
  final MusicService _service = MusicService.instance;

  Future<void> loadData() async {
    _view.showLoading();
    try {
      _view.showSongs(await _service.getAllSongs());
      _view.showFavorites(await _service.getFavoriteSongs());
    } catch (e) {
      _view.showError('Không thể tải dữ liệu: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      await loadData();
      return;
    }
    _view.showLoading();
    try {
      _view.showSongs(await _service.searchSongs(keyword));
      _view.showFavorites(const []);
    } catch (e) {
      _view.showError('Lỗi tìm kiếm: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final id = song.musicId;
    if (id == null) return;
    try {
      final next = !song.isFavorite;
      await _service.toggleFavorite(id, next);
      _view.showMessage(next ? 'Đã thêm vào yêu thích' : 'Đã bỏ yêu thích');
      await loadData();
    } catch (e) {
      _view.showError('Không thể cập nhật yêu thích');
    }
  }
}