class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String qualification;
  final int experience; // years
  final String contactNumber;
  final String profilePhotoPath; // path to locally stored image
  final String clinicName;
  final String clinicAddress;
  final double consultationFee;
  final String workingHours;
  final List<Availability> availability; // days and hours the doctor is available

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.experience,
    required this.contactNumber,
    required this.profilePhotoPath,
    required this.clinicName,
    required this.clinicAddress,
    required this.consultationFee,
    required this.workingHours,
    required this.availability,
  });

  Doctor copyWith({
    String? id,
    String? name,
    String? specialty,
    String? qualification,
    int? experience,
    String? contactNumber,
    String? profilePhotoPath,
    String? clinicName,
    String? clinicAddress,
    double? consultationFee,
    String? workingHours,
    List<Availability>? availability,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      contactNumber: contactNumber ?? this.contactNumber,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      consultationFee: consultationFee ?? this.consultationFee,
      workingHours: workingHours ?? this.workingHours,
      availability: availability ?? this.availability,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'qualification': qualification,
      'experience': experience,
      'contactNumber': contactNumber,
      'profilePhotoPath': profilePhotoPath,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'consultationFee': consultationFee,
      'workingHours': workingHours,
      'availability': availability.map((a) => a.toJson()).toList(),
    };
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'],
      qualification: json['qualification'],
      experience: json['experience'],
      contactNumber: json['contactNumber'],
      profilePhotoPath: json['profilePhotoPath'],
      clinicName: json['clinicName'],
      clinicAddress: json['clinicAddress'],
      consultationFee: json['consultationFee'],
      workingHours: json['workingHours'],
      availability: (json['availability'] as List)
          .map((a) => Availability.fromJson(a))
          .toList(),
    );
  }
}

class Availability {
  final String day; // e.g., "Monday", "Tuesday"
  final String startTime; // e.g., "09:00"
  final String endTime; // e.g., "17:00"
  final bool isAvailable; // whether the doctor is available on this day

  Availability({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  Availability copyWith({
    String? day,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) {
    return Availability(
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      day: json['day'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isAvailable: json['isAvailable'],
    );
  }
}