class Doctor {
  final String id;
  final String name;
  final String specialty;
  final int experience;
  final String contactNumber;
  final double consultationFee;
  final List<String> workingDays;
  final String startTime;
  final String endTime;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.contactNumber,
    required this.consultationFee,
    required this.workingDays,
    required this.startTime,
    required this.endTime,
  });

  // Convert Doctor object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'experience': experience,
      'contactNumber': contactNumber,
      'consultationFee': consultationFee,
      'workingDays': workingDays,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  // Create Doctor object from JSON
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'],
      experience: json['experience'],
      contactNumber: json['contactNumber'],
      consultationFee: json['consultationFee'],
      workingDays: List<String>.from(json['workingDays']),
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  // Create a copy of the Doctor with updated values
  Doctor copyWith({
    String? id,
    String? name,
    String? specialty,
    int? experience,
    String? contactNumber,
    double? consultationFee,
    List<String>? workingDays,
    String? startTime,
    String? endTime,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      experience: experience ?? this.experience,
      contactNumber: contactNumber ?? this.contactNumber,
      consultationFee: consultationFee ?? this.consultationFee,
      workingDays: workingDays ?? this.workingDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}