class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String reason;
  final AppointmentStatus status;
  final String notes;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.dateTime,
    required this.reason,
    required this.status,
    required this.notes,
  });

  Appointment copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? patientName,
    DateTime? dateTime,
    String? reason,
    AppointmentStatus? status,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      dateTime: dateTime ?? this.dateTime,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'reason': reason,
      'status': status.index,
      'notes': notes,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctorId: json['doctorId'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
      reason: json['reason'],
      status: AppointmentStatus.values[json['status']],
      notes: json['notes'],
    );
  }
}

enum AppointmentStatus { scheduled, inProgress, completed, cancelled }

class TimeSlot {
  final String id;
  final DateTime dateTime;
  final bool isBooked;

  TimeSlot({
    required this.id,
    required this.dateTime,
    required this.isBooked,
  });

  TimeSlot copyWith({
    String? id,
    DateTime? dateTime,
    bool? isBooked,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      isBooked: isBooked ?? this.isBooked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'isBooked': isBooked,
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
      isBooked: json['isBooked'],
    );
  }
}