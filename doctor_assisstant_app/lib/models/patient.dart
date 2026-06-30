class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String contactNumber;
  final String email;
  final DateTime dateOfBirth;
  final DateTime lastAppointment;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contactNumber,
    required this.email,
    required this.dateOfBirth,
    required this.lastAppointment,
  });

  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? contactNumber,
    String? email,
    DateTime? dateOfBirth,
    DateTime? lastAppointment,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      lastAppointment: lastAppointment ?? this.lastAppointment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'contactNumber': contactNumber,
      'email': email,
      'dateOfBirth': dateOfBirth.millisecondsSinceEpoch,
      'lastAppointment': lastAppointment.millisecondsSinceEpoch,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      contactNumber: json['contactNumber'],
      email: json['email'],
      dateOfBirth: DateTime.fromMillisecondsSinceEpoch(json['dateOfBirth']),
      lastAppointment: DateTime.fromMillisecondsSinceEpoch(json['lastAppointment']),
    );
  }
}