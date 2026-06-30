class PatientQueue {
  final String id;
  final String doctorId;
  final List<QueueItem> waitingPatients;
  final QueueItem? currentPatient;
  final List<QueueItem> completedAppointments;

  PatientQueue({
    required this.id,
    required this.doctorId,
    required this.waitingPatients,
    this.currentPatient,
    required this.completedAppointments,
  });

  PatientQueue copyWith({
    String? id,
    String? doctorId,
    List<QueueItem>? waitingPatients,
    QueueItem? currentPatient,
    List<QueueItem>? completedAppointments,
  }) {
    return PatientQueue(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      waitingPatients: waitingPatients ?? this.waitingPatients,
      currentPatient: currentPatient ?? this.currentPatient,
      completedAppointments: completedAppointments ?? this.completedAppointments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'waitingPatients': waitingPatients.map((q) => q.toJson()).toList(),
      'currentPatient': currentPatient?.toJson(),
      'completedAppointments': completedAppointments.map((q) => q.toJson()).toList(),
    };
  }

  factory PatientQueue.fromJson(Map<String, dynamic> json) {
    return PatientQueue(
      id: json['id'],
      doctorId: json['doctorId'],
      waitingPatients: (json['waitingPatients'] as List)
          .map((q) => QueueItem.fromJson(q))
          .toList(),
      currentPatient: json['currentPatient'] != null
          ? QueueItem.fromJson(json['currentPatient'])
          : null,
      completedAppointments: (json['completedAppointments'] as List)
          .map((q) => QueueItem.fromJson(q))
          .toList(),
    );
  }
}

class QueueItem {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime arrivalTime;
  final QueueStatus status;
  final String reason;

  QueueItem({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.arrivalTime,
    required this.status,
    required this.reason,
  });

  QueueItem copyWith({
    String? id,
    String? patientId,
    String? patientName,
    DateTime? arrivalTime,
    QueueStatus? status,
    String? reason,
  }) {
    return QueueItem(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      status: status ?? this.status,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'arrivalTime': arrivalTime.millisecondsSinceEpoch,
      'status': status.index,
      'reason': reason,
    };
  }

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      arrivalTime: DateTime.fromMillisecondsSinceEpoch(json['arrivalTime']),
      status: QueueStatus.values[json['status']],
      reason: json['reason'],
    );
  }
}

enum QueueStatus { waiting, inProgress, completed, cancelled }