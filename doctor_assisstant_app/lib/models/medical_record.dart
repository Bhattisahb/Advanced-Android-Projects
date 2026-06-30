class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String title;
  final String description;
  final DateTime date;
  final List<String> attachments;
  final String notes;
  final List<Prescription> prescriptions;
  final List<TestResult> testResults;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.title,
    required this.description,
    required this.date,
    required this.attachments,
    required this.notes,
    required this.prescriptions,
    required this.testResults,
  });

  MedicalRecord copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? title,
    String? description,
    DateTime? date,
    List<String>? attachments,
    String? notes,
    List<Prescription>? prescriptions,
    List<TestResult>? testResults,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      prescriptions: prescriptions ?? this.prescriptions,
      testResults: testResults ?? this.testResults,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'attachments': attachments,
      'notes': notes,
      'prescriptions': prescriptions.map((p) => p.toJson()).toList(),
      'testResults': testResults.map((t) => t.toJson()).toList(),
    };
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      title: json['title'],
      description: json['description'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      attachments: List<String>.from(json['attachments'] ?? []),
      notes: json['notes'],
      prescriptions: (json['prescriptions'] as List)
          .map((p) => Prescription.fromJson(p))
          .toList(),
      testResults: (json['testResults'] as List)
          .map((t) => TestResult.fromJson(t))
          .toList(),
    );
  }
}

class Prescription {
  final String id;
  final String medicationName;
  final String dosage;
  final String frequency;
  final int duration; // in days
  final String instructions;

  Prescription({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      medicationName: json['medicationName'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      instructions: json['instructions'],
    );
  }
}

class TestResult {
  final String id;
  final String testName;
  final DateTime date;
  final String result;
  final String notes;
  final String filePath;

  TestResult({
    required this.id,
    required this.testName,
    required this.date,
    required this.result,
    required this.notes,
    required this.filePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testName': testName,
      'date': date.millisecondsSinceEpoch,
      'result': result,
      'notes': notes,
      'filePath': filePath,
    };
  }

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      testName: json['testName'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      result: json['result'],
      notes: json['notes'],
      filePath: json['filePath'],
    );
  }
}