import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doctor_model.dart';

class DoctorService {
  static const String _doctorsKey = 'doctors';
  
  // Save a doctor to shared preferences
  Future<void> saveDoctor(Doctor doctor) async {
    final prefs = await SharedPreferences.getInstance();
    final doctors = await getDoctors();
    
    // Check if doctor already exists (by id)
    final existingIndex = doctors.indexWhere((d) => d.id == doctor.id);
    
    if (existingIndex != -1) {
      // Update existing doctor
      doctors[existingIndex] = doctor;
    } else {
      // Add new doctor
      doctors.add(doctor);
    }
    
    // Convert doctors list to JSON
    final doctorsJson = doctors.map((d) => d.toJson()).toList();
    final jsonString = jsonEncode(doctorsJson);
    
    // Save to shared preferences
    await prefs.setString(_doctorsKey, jsonString);
  }
  
  // Get all doctors from shared preferences
  Future<List<Doctor>> getDoctors() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_doctorsKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Doctor.fromJson(json)).toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }
  
  // Delete a doctor by id
  Future<void> deleteDoctor(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final doctors = await getDoctors();
    
    // Remove doctor with matching id
    doctors.removeWhere((doctor) => doctor.id == id);
    
    // Convert doctors list to JSON
    final doctorsJson = doctors.map((d) => d.toJson()).toList();
    final jsonString = jsonEncode(doctorsJson);
    
    // Save to shared preferences
    await prefs.setString(_doctorsKey, jsonString);
  }
  
  // Get a doctor by id
  Future<Doctor?> getDoctorById(String id) async {
    final doctors = await getDoctors();
    try {
      return doctors.firstWhere((doctor) => doctor.id == id);
    } catch (e) {
      return null;
    }
  }
}