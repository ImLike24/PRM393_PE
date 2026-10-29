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

  String get title => musicName;
  String get artist => artistName ?? 'Unknown';

  Song copyWith({bool? isFavorite}) {
    return Song(
      musicId: musicId,
      musicName: musicName,
      musicLength: musicLength,
      audioUrl: audioUrl,
      coverImageUrl: coverImageUrl,
      artistName: artistName,
      isFavorite: isFavorite ?? this.isFavorite,
      luotNghe: luotNghe,
    );
  }

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

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      musicId: map['music_id'] as int?,
      musicName: map['music_name'] as String? ?? '',
      musicLength: map['music_length'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      coverImageUrl: map['cover_image_url'] as String?,
      artistName: map['artist_name'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      luotNghe: map['luot_nghe'] as int? ?? 0,
    );
  }
}