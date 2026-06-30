class Report {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime dateAdded;

  Report({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.dateAdded,
  });

  Report copyWith({
    String? id,
    String? fileName,
    String? filePath,
    DateTime? dateAdded,
  }) {
    return Report(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      dateAdded: DateTime.fromMillisecondsSinceEpoch(json['dateAdded']),
    );
  }
}