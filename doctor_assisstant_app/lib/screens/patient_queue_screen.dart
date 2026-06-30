import 'package:flutter/material.dart';
import '../models/patient_queue.dart';
import '../models/doctor.dart';
import '../services/local_storage_service.dart';

class PatientQueueScreen extends StatefulWidget {
  final String doctorId;

  const PatientQueueScreen({super.key, required this.doctorId});

  @override
  State<PatientQueueScreen> createState() => _PatientQueueScreenState();
}

class _PatientQueueScreenState extends State<PatientQueueScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  PatientQueue? _patientQueue;
  Doctor? _doctor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor data
      final doctor = _storageService.getDoctor(widget.doctorId);
      
      // Load patient queue for this doctor
      PatientQueue? queue = _storageService.getPatientQueueForDoctor(widget.doctorId);
      
      // If no queue exists, create a new one
      if (queue == null) {
        queue = PatientQueue(
          id: 'queue_${widget.doctorId}',
          doctorId: widget.doctorId,
          waitingPatients: [],
          completedAppointments: [],
        );
        await _storageService.savePatientQueue(queue);
      }
      
      setState(() {
        _doctor = doctor;
        _patientQueue = queue;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshQueue() async {
    await _loadData();
  }

  Future<void> _addToQueue() async {
    if (_doctor == null || _patientQueue == null) return;

    // In a real app, you would select a patient from a list
    // For demo purposes, we'll create a sample patient
    final samplePatients = [
      QueueItem(
        id: 'queue_item_${DateTime.now().millisecondsSinceEpoch}',
        patientId: 'patient_001',
        patientName: 'John Doe',
        arrivalTime: DateTime.now(),
        status: QueueStatus.waiting,
        reason: 'Regular checkup',
      ),
      QueueItem(
        id: 'queue_item_${DateTime.now().millisecondsSinceEpoch + 1}',
        patientId: 'patient_002',
        patientName: 'Jane Smith',
        arrivalTime: DateTime.now().add(const Duration(minutes: 5)),
        status: QueueStatus.waiting,
        reason: 'Follow-up consultation',
      ),
    ];

    try {
      final updatedQueue = _patientQueue!.copyWith(
        waitingPatients: [..._patientQueue!.waitingPatients, ...samplePatients],
      );
      
      await _storageService.savePatientQueue(updatedQueue);
      await _loadData(); // Refresh the data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patients added to queue')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding patients to queue: $e')),
        );
      }
    }
  }

  Future<void> _moveToNextPatient() async {
    if (_patientQueue == null) return;

    try {
      PatientQueue updatedQueue;
      
      if (_patientQueue!.currentPatient != null) {
        // Move current patient to completed
        final completedPatient = _patientQueue!.currentPatient!.copyWith(status: QueueStatus.completed);
        
        updatedQueue = _patientQueue!.copyWith(
          currentPatient: null,
          completedAppointments: [..._patientQueue!.completedAppointments, completedPatient],
        );
      } else {
        updatedQueue = _patientQueue!;
      }
      
      // Move next patient from waiting to current
      if (updatedQueue.waitingPatients.isNotEmpty) {
        final nextPatient = updatedQueue.waitingPatients.first.copyWith(status: QueueStatus.inProgress);
        updatedQueue = updatedQueue.copyWith(
          currentPatient: nextPatient,
          waitingPatients: updatedQueue.waitingPatients.skip(1).toList(),
        );
      }
      
      await _storageService.savePatientQueue(updatedQueue);
      await _loadData(); // Refresh the data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moved to next patient')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving to next patient: $e')),
        );
      }
    }
  }

  Future<void> _markAsCompleted() async {
    if (_patientQueue == null || _patientQueue!.currentPatient == null) return;

    try {
      final completedPatient = _patientQueue!.currentPatient!.copyWith(status: QueueStatus.completed);
      final updatedQueue = _patientQueue!.copyWith(
        currentPatient: null,
        completedAppointments: [..._patientQueue!.completedAppointments, completedPatient],
      );
      
      await _storageService.savePatientQueue(updatedQueue);
      await _loadData(); // Refresh the data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking patient as completed: $e')),
        );
      }
    }
  }

  Future<void> _removeFromQueue(QueueItem patient) async {
    if (_patientQueue == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Patient'),
        content: const Text('Are you sure you want to remove this patient from the queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        List<QueueItem> updatedWaitingList = List.from(_patientQueue!.waitingPatients);
        List<QueueItem> updatedCompletedList = List.from(_patientQueue!.completedAppointments);
        
        // Remove from waiting list if present
        updatedWaitingList.removeWhere((item) => item.id == patient.id);
        
        // Remove from completed list if present
        updatedCompletedList.removeWhere((item) => item.id == patient.id);
        
        // If it's the current patient, clear it
        QueueItem? currentPatient = _patientQueue!.currentPatient;
        if (currentPatient != null && currentPatient.id == patient.id) {
          currentPatient = null;
        }
        
        final updatedQueue = _patientQueue!.copyWith(
          waitingPatients: updatedWaitingList,
          currentPatient: currentPatient,
          completedAppointments: updatedCompletedList,
        );
        
        await _storageService.savePatientQueue(updatedQueue);
        await _loadData(); // Refresh the data
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient removed from queue')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing patient from queue: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Queue Manager'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQueue,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctor == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 64,
                        color: Color(0xFF137fec),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Doctor profile not found',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please create a doctor profile first',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshQueue,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Queue Statistics
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              _buildStatCard(
                                'Waiting',
                                _patientQueue?.waitingPatients.length ?? 0,
                                Icons.hourglass_empty,
                                Colors.orange,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                'In Progress',
                                _patientQueue?.currentPatient != null ? 1 : 0,
                                Icons.play_arrow,
                                Colors.blue,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                'Completed',
                                _patientQueue?.completedAppointments.length ?? 0,
                                Icons.check,
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Current Patient
                        if (_patientQueue?.currentPatient != null)
                          _buildCurrentPatientCard(_patientQueue!.currentPatient!)
                        else
                          const Card(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.play_arrow,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No patient in consultation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Waiting Patients
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Waiting Patients',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addToQueue,
                              ),
                            ],
                          ),
                        ),
                        if (_patientQueue?.waitingPatients.isEmpty ?? true)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No patients waiting',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _patientQueue?.waitingPatients.length ?? 0,
                            itemBuilder: (context, index) {
                              final patient = _patientQueue!.waitingPatients[index];
                              return _buildQueueItemCard(patient, false);
                            },
                          ),
                        const SizedBox(height: 16),
                        // Completed Appointments
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Completed Appointments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_patientQueue?.completedAppointments.isEmpty ?? true)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No completed appointments',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _patientQueue?.completedAppointments.length ?? 0,
                            itemBuilder: (context, index) {
                              final patient = _patientQueue!.completedAppointments[index];
                              return _buildQueueItemCard(patient, true);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _patientQueue != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_patientQueue!.currentPatient != null)
                  FloatingActionButton(
                    onPressed: _markAsCompleted,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _moveToNextPatient,
                  backgroundColor: const Color(0xFF137fec),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPatientCard(QueueItem patient) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Currently in consultation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    patient.patientName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Arrived: ${_formatTime(patient.arrivalTime)}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.reason,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueItemCard(QueueItem patient, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green : Colors.orange,
          child: Text(
            patient.patientName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(patient.patientName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arrived: ${_formatTime(patient.arrivalTime)}'),
            Text(patient.reason),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(patient.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusText(patient.status),
                style: TextStyle(
                  color: _getStatusColor(patient.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeFromQueue(patient),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$formattedHour:$minute $period';
  }

  Color _getStatusColor(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return Colors.orange;
      case QueueStatus.inProgress:
        return Colors.blue;
      case QueueStatus.completed:
        return Colors.green;
      case QueueStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return 'Waiting';
      case QueueStatus.inProgress:
        return 'In Progress';
      case QueueStatus.completed:
        return 'Completed';
      case QueueStatus.cancelled:
        return 'Cancelled';
    }
  }
}