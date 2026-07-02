class Playlist {
  final String id;
  String name;
  final List<String> songKeys;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    List<String>? songKeys,
    DateTime? createdAt,
  })  : songKeys = songKeys ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get songCount => songKeys.length;

  bool containsKey(String key) => songKeys.contains(key);

  void addSongKey(String key) {
    if (!songKeys.contains(key)) {
      songKeys.add(key);
    }
  }

  void removeSongKey(String key) {
    songKeys.removeWhere((k) => k == key);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songKeys': List<String>.from(songKeys),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songKeys: (json['songKeys'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
