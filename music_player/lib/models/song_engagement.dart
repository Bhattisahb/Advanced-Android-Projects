/// Persisted listening stats used to rank the home "Most played" section.
class SongEngagement {
  double score;
  int manualStarts;
  int autoplayStarts;
  int completedCount;
  int skipCount;

  SongEngagement({
    this.score = 0,
    this.manualStarts = 0,
    this.autoplayStarts = 0,
    this.completedCount = 0,
    this.skipCount = 0,
  });

  factory SongEngagement.fromJson(Map<String, dynamic> json) {
    return SongEngagement(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      manualStarts: json['manualStarts'] as int? ?? 0,
      autoplayStarts: json['autoplayStarts'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      skipCount: json['skipCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'manualStarts': manualStarts,
    'autoplayStarts': autoplayStarts,
    'completedCount': completedCount,
    'skipCount': skipCount,
  };
}
