import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/patient.dart';
import '../models/report.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../models/patient_queue.dart';

class LocalStorageService {
  static const String _patientBoxName = 'patients';
  static const String _reportsBoxName = 'reports';
  static const String _doctorBoxName = 'doctors';
  static const String _appointmentsBoxName = 'appointments';
  static const String _patientQueueBoxName = 'patient_queues';
  
  late Box<String> _patientBox;
  late Box<String> _reportsBox;
  late Box<String> _doctorBox;
  late Box<String> _appointmentsBox;
  late Box<String> _patientQueueBox;

  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
    
    _patientBox = await Hive.openBox<String>(_patientBoxName);
    _reportsBox = await Hive.openBox<String>(_reportsBoxName);
    _doctorBox = await Hive.openBox<String>(_doctorBoxName);
    _appointmentsBox = await Hive.openBox<String>(_appointmentsBoxName);
    _patientQueueBox = await Hive.openBox<String>(_patientQueueBoxName);
  }

  // Expose the boxes for accessing all items
  Box<String> get patientBox => _patientBox;
  Box<String> get reportsBox => _reportsBox;
  Box<String> get doctorBox => _doctorBox;
  Box<String> get appointmentsBox => _appointmentsBox;
  Box<String> get patientQueueBox => _patientQueueBox;
  
  // Patient methods
  Future<void> savePatient(Patient patient) async {
    await _patientBox.put(patient.id, jsonEncode(patient.toJson()));
  }

  Patient? getPatient(String id) {
    final data = _patientBox.get(id);
    if (data != null) {
      return Patient.fromJson(jsonDecode(data) as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> deletePatient(String id) async {
    await _patientBox.delete(id);
  }

  // Report methods
  Future<void> saveReport(Report report) async {
    await _reportsBox.put(report.id, jsonEncode(report.toJson()));
  }

  List<Report> getReportsForPatient(String patientId) {
    final reports = <Report>[];
    for (var key in _reportsBox.keys) {
      final data = _reportsBox.get(key);
      if (data != null) {
        final report = Report.fromJson(jsonDecode(data) as Map<String, dynamic>);
        // Assuming report ID contains patient ID or we could have a separate mapping
        if (report.id.startsWith(patientId)) {
          reports.add(report);
        }
      }
    }
    reports.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return reports;
  }

  Future<void> deleteReport(String id) async {
    await _reportsBox.delete(id);
  }

  // Doctor methods
  Future<void> saveDoctor(Doctor doctor) async {
    await _doctorBox.put(doctor.id, jsonEncode(doctor.toJson()));
  }

  Doctor? getDoctor(String id) {
    final data = _doctorBox.get(id);
    if (data != null) {
      return Doctor.fromJson(jsonDecode(data) as Map<String, dynamic>);
    }
    return null;
  }

  List<Doctor> getAllDoctors() {
    final doctors = <Doctor>[];
    for (var key in _doctorBox.keys) {
      final data = _doctorBox.get(key);
      if (data != null) {
        doctors.add(Doctor.fromJson(jsonDecode(data) as Map<String, dynamic>));
      }
    }
    return doctors;
  }

  Future<void> deleteDoctor(String id) async {
    await _doctorBox.delete(id);
  }

  // Appointment methods
  Future<void> saveAppointment(Appointment appointment) async {
    await _appointmentsBox.put(appointment.id, jsonEncode(appointment.toJson()));
  }

  Appointment? getAppointment(String id) {
    final data = _appointmentsBox.get(id);
    if (data != null) {
      return Appointment.fromJson(jsonDecode(data) as Map<String, dynamic>);
    }
    return null;
  }

  List<Appointment> getAppointmentsForDoctor(String doctorId) {
    final appointments = <Appointment>[];
    for (var key in _appointmentsBox.keys) {
      final data = _appointmentsBox.get(key);
      if (data != null) {
        final appointment = Appointment.fromJson(jsonDecode(data) as Map<String, dynamic>);
        if (appointment.doctorId == doctorId) {
          appointments.add(appointment);
        }
      }
    }
    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return appointments;
  }

  Future<void> deleteAppointment(String id) async {
    await _appointmentsBox.delete(id);
  }

  // Patient Queue methods
  Future<void> savePatientQueue(PatientQueue queue) async {
    await _patientQueueBox.put(queue.id, jsonEncode(queue.toJson()));
  }

  PatientQueue? getPatientQueue(String id) {
    final data = _patientQueueBox.get(id);
    if (data != null) {
      return PatientQueue.fromJson(jsonDecode(data) as Map<String, dynamic>);
    }
    return null;
  }

  PatientQueue? getPatientQueueForDoctor(String doctorId) {
    for (var key in _patientQueueBox.keys) {
      final data = _patientQueueBox.get(key);
      if (data != null) {
        final queue = PatientQueue.fromJson(jsonDecode(data) as Map<String, dynamic>);
        if (queue.doctorId == doctorId) {
          return queue;
        }
      }
    }
    return null;
  }

  Future<void> deletePatientQueue(String id) async {
    await _patientQueueBox.delete(id);
  }

  Future<String> saveImageFile(List<int> imageBytes, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final doctorsDir = Directory('${appDir.path}/doctors');
    
    if (!await doctorsDir.exists()) {
      await doctorsDir.create(recursive: true);
    }
    
    final filePath = '${doctorsDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    
    return filePath;
  }

  Future<void> closeBoxes() async {
    await _patientBox.close();
    await _reportsBox.close();
    await _doctorBox.close();
    await _appointmentsBox.close();
    await _patientQueueBox.close();
  }
}