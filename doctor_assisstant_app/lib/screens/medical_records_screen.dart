import 'package:flutter/material.dart';
import '../models/medical_record.dart';
import '../models/patient.dart';
import '../services/local_storage_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String patientId;

  const MedicalRecordsScreen({super.key, required this.patientId});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoading = true;
  Patient? _patient;

  @override
  void initState() {
    super.initState();
    _loadMedicalRecords();
  }

  Future<void> _loadMedicalRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load patient data
      final patient = _storageService.getPatient(widget.patientId);
      
      // For demo purposes, we'll create sample records if patient exists
      final sampleRecords = <MedicalRecord>[];
      
      if (patient != null) {
        sampleRecords.addAll([
          MedicalRecord(
            id: 'record_001',
            patientId: widget.patientId,
            doctorId: 'doctor_001',
            title: 'Annual Physical Examination',
            description: 'Regular checkup for overall health assessment',
            date: DateTime(2025, 10, 15),
            attachments: [],
            notes: 'Patient reports feeling healthy. All vitals normal.',
            prescriptions: [
              Prescription(
                id: 'pres_001',
                medicationName: 'Multivitamin',
                dosage: '1 tablet',
                frequency: 'Once daily',
                duration: 30,
                instructions: 'Take with food',
              ),
            ],
            testResults: [
              TestResult(
                id: 'test_001',
                testName: 'Complete Blood Count',
                date: DateTime(2025, 10, 15),
                result: 'Normal',
                notes: 'All parameters within normal range',
                filePath: '',
              ),
            ],
          ),
          MedicalRecord(
            id: 'record_002',
            patientId: widget.patientId,
            doctorId: 'doctor_001',
            title: 'Follow-up Consultation',
            description: 'Review of lab results and medication effectiveness',
            date: DateTime(2025, 9, 20),
            attachments: [],
            notes: 'Patient reports improvement with current medication.',
            prescriptions: [],
            testResults: [],
          ),
        ]);
      }

      setState(() {
        _patient = patient;
        _medicalRecords = sampleRecords;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medical records: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_patient != null ? '${_patient!.name} - Medical Records' : 'Medical Records'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patient == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Patient not found',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : _medicalRecords.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No medical records found',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Medical records will appear here when added',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _medicalRecords.length,
                      itemBuilder: (context, index) {
                        final record = _medicalRecords[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ExpansionTile(
                            title: Text(record.title),
                            subtitle: Text('${record.date.day}/${record.date.month}/${record.date.year}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailSection('Description', record.description),
                                    const SizedBox(height: 8),
                                    _buildDetailSection('Notes', record.notes),
                                    const SizedBox(height: 8),
                                    if (record.prescriptions.isNotEmpty) ...[
                                      const Text(
                                        'Prescriptions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...record.prescriptions.map((prescription) => _buildPrescriptionCard(prescription)),
                                      const SizedBox(height: 8),
                                    ],
                                    if (record.testResults.isNotEmpty) ...[
                                      const Text(
                                        'Test Results',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...record.testResults.map((testResult) => _buildTestResultCard(testResult)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRecord,
        backgroundColor: const Color(0xFF137fec),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(content),
      ],
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prescription.medicationName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text('Dosage: ${prescription.dosage}'),
            Text('Frequency: ${prescription.frequency}'),
            Text('Duration: ${prescription.duration} days'),
            if (prescription.instructions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Instructions: ${prescription.instructions}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultCard(TestResult testResult) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              testResult.testName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text('${testResult.date.day}/${testResult.date.month}/${testResult.date.year}'),
            Text('Result: ${testResult.result}'),
            if (testResult.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Notes: ${testResult.notes}'),
            ],
          ],
        ),
      ),
    );
  }

  void _addNewRecord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new record functionality not implemented in this demo')),
    );
  }
}