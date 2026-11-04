/// Lớp đại diện cho đối tượng Bài hát (Song) trong ứng dụng.
class Song {
  final int? musicId;
  final String musicName;
  final String musicLength;
  final String audioUrl;
  final String? coverImageUrl;
  final String? artistName;
  final bool isFavorite;
  final int luotNghe;

  Song({
    this.musicId,
    required this.musicName,
    required this.musicLength,
    required this.audioUrl,
    this.coverImageUrl,
    this.artistName,
    this.isFavorite = false,
    this.luotNghe = 0,
  });

  /// Getter trả về tên bài hát.
  String get title => musicName;

  /// Getter trả về tên ca sĩ (nếu không có thì trả về 'Không rõ').
  String get artist => artistName ?? 'Không rõ';

  /// Tạo bản sao mới của đối tượng Song với các thuộc tính được cập nhật.
  Song copyWith({bool? isFavorite, int? luotNghe}) {
    return Song(
      musicId: musicId,
      musicName: musicName,
      musicLength: musicLength,
      audioUrl: audioUrl,
      coverImageUrl: coverImageUrl,
      artistName: artistName,
      isFavorite: isFavorite ?? this.isFavorite,
      luotNghe: luotNghe ?? this.luotNghe,
    );
  }

  /// Chuyển đổi đối tượng Song thành Map (JSON).
  Map<String, dynamic> toMap() => {
    'music_id': musicId,
    'music_name': musicName,
    'music_length': musicLength,
    'audio_url': audioUrl,
    'cover_image_url': coverImageUrl,
    'artist_name': artistName,
    'is_favorite': isFavorite ? 1 : 0,
    'luot_nghe': luotNghe,
  };

  /// Chuyển đổi Map (JSON) từ API thành đối tượng Song.
  factory Song.fromMap(Map<String, dynamic> map) {
    final rawLuotNghe = map['luot_nghe'] ?? map['listen_count'];
    final parsedLuotNghe = rawLuotNghe is int
        ? rawLuotNghe
        : int.tryParse('$rawLuotNghe') ?? 0;

    return Song(
      musicId: map['music_id'] is int ? map['music_id'] as int : int.tryParse('${map['music_id']}'),
      musicName: map['music_name'] as String? ?? '',
      musicLength: map['music_length'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      coverImageUrl: map['cover_image_url'] as String?,
      artistName: map['artist_name'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      luotNghe: parsedLuotNghe,
    );
  }
}
