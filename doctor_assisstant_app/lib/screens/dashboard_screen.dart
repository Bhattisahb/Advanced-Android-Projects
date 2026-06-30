import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/local_storage_service.dart';
import 'patient_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<Patient> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all patients from storage
      final allPatients = <Patient>[];
      
      // Debug: Print the number of keys in the patient box
      print('Number of patient keys: ${_storageService.patientBox.keys.length}');
      
      // Get all keys from the patient box
      for (var key in _storageService.patientBox.keys) {
        print('Loading patient with key: $key');
        final patient = _storageService.getPatient(key.toString());
        if (patient != null) {
          allPatients.add(patient);
          print('Loaded patient: ${patient.name}');
        } else {
          print('Failed to load patient with key: $key');
        }
      }

      print('Total patients loaded: ${allPatients.length}');

      setState(() {
        _patients = allPatients;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading patients: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPatientDetails(String patientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patientId: patientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Assistant Dashboard'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No patients found',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first patient using the + button',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats cards
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Ensure the LayoutBuilder has proper constraints
                            if (constraints.maxWidth < 800) {
                              // Single column layout for smaller screens
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStatCard('Total Patients', _patients.length.toString(), Icons.people),
                                  const SizedBox(height: 16),
                                  _buildStatCard('Today\'s Appointments', '0', Icons.calendar_today),
                                ],
                              );
                            } else {
                              // Row layout for larger screens
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard('Total Patients', _patients.length.toString(), Icons.people),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard('Today\'s Appointments', '0', Icons.calendar_today),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                      // Patients list
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Patients (${_patients.length})', // Show count
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      // Fixed the pixel overflow issue by constraining the ListView height
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _patients.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No patients found',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add your first patient using the + button',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _patients.length,
                                itemBuilder: (context, index) {
                                  final patient = _patients[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF137fec),
                                        child: Text(
                                          patient.name.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(patient.name),
                                      subtitle: Text('${patient.age} years, ${patient.gender}'),
                                      trailing: const Icon(Icons.arrow_forward_ios),
                                      onTap: () => _navigateToPatientDetails(patient.id),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPatient,
        backgroundColor: const Color(0xFF137fec),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: const Color(0xFF137fec),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _addNewPatient() {
    // Generate a new patient ID
    final newPatientId = 'patient_${DateTime.now().millisecondsSinceEpoch}';
    
    // Navigate to patient details screen with the new ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patientId: newPatientId),
      ),
    ).then((value) {
      // Refresh the patient list when returning
      _loadPatients();
    });
  }
}