import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../controllers/player_controller.dart';
import '../models/song.dart';
import 'api_config.dart';
import 'session.dart';

class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static void notifyChange() {
    changeNotifier.value++;
  }

  int get _uid => Session.userId;

  Future<List<Song>> getAllSongs() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/music?userId=$_uid'),
    );
    return _decodeSongs(res);
  }

  Future<List<Song>> getRanking() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/music/ranking?userId=$_uid'),
    );
    return _decodeSongs(res);
  }

  Future<List<Song>> getFavoriteSongs() async {
    if (_uid == 0) return [];
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/music/favorites?userId=$_uid'),
    );
    return _decodeSongs(res);
  }

  Future<List<Song>> searchSongs(String keyword) async {
    final q = Uri.encodeQueryComponent(keyword.trim());
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/music/search?userId=$_uid&q=$q'),
    );
    return _decodeSongs(res);
  }

  Future<void> toggleFavorite(int musicId, bool isFavorite) async {
    if (_uid == 0) throw Exception('Hay dang nhap de yeu thich');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/users/$_uid/liked/$musicId',
    );
    final res = isFavorite ? await http.post(uri) : await http.delete(uri);
    if (res.statusCode >= 300) throw Exception('Loi yeu thich');

    PlayerController.instance.updateSongFavorite(musicId, isFavorite);
    notifyChange();
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    if (_uid == 0) return [];
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/$_uid/playlists'),
    );
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> createPlaylist(String name) async {
    if (_uid == 0) throw Exception('Hay dang nhap');
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/$_uid/playlists'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'playlist_name': name}),
    );
    if (res.statusCode >= 300) throw Exception('Loi tao playlist');
    notifyChange();
  }

  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    if (_uid == 0) return [];
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/$_uid/search-history'),
    );
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> deleteSearchHistoryItem(int id) async {
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/users/$_uid/search-history/$id'),
    );
  }

  Future<void> clearSearchHistory() async {
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/users/$_uid/search-history'),
    );
  }

  List<Song> _decodeSongs(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => Song.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addToPlaylist(int playlistId, int musicId) async {
    if (_uid == 0) throw Exception('Hay dang nhap');
    final res = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/users/$_uid/playlists/$playlistId/music/$musicId',
      ),
    );
    if (res.statusCode >= 300) {
      throw Exception('Khong them duoc vao playlist');
    }
    notifyChange();
  }

  Future<List<Song>> getRecentSongs() async {
    if (_uid == 0) return [];
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/music/recent?userId=$_uid'),
    );
    return _decodeSongs(res);
  }

  Future<void> logListen(int musicId) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/music/$musicId/listen'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': _uid}),
    );
  }
}