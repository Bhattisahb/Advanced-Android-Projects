class Song {
  final String id;
  final int? mediaId;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Duration duration;
  final String? albumArt;
  bool isFavorite;

  Song({
    required this.id,
    this.mediaId,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    required this.duration,
    this.albumArt,
    this.isFavorite = false,
  });

  @override
  String toString() => '$title - $artist';
}
