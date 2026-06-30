import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../services/local_storage_service.dart';

class AppointmentSchedulerScreen extends StatefulWidget {
  final String doctorId;

  const AppointmentSchedulerScreen({super.key, required this.doctorId});

  @override
  State<AppointmentSchedulerScreen> createState() => _AppointmentSchedulerScreenState();
}

class _AppointmentSchedulerScreenState extends State<AppointmentSchedulerScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  Doctor? _doctor;
  List<Appointment> _appointments = [];
  List<Patient> _patients = [];
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Appointment>> _appointmentsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load doctor data
      final doctor = _storageService.getDoctor(widget.doctorId);
      
      // Load all patients
      final patients = <Patient>[];
      for (var key in _storageService.patientBox.keys) {
        final patient = _storageService.getPatient(key.toString());
        if (patient != null) {
          patients.add(patient);
        }
      }
      
      // Load appointments for this doctor
      final appointments = _storageService.getAppointmentsForDoctor(widget.doctorId);
      
      // Group appointments by day
      final appointmentsByDay = <DateTime, List<Appointment>>{};
      for (var appointment in appointments) {
        final date = DateTime(appointment.dateTime.year, appointment.dateTime.month, appointment.dateTime.day);
        if (appointmentsByDay.containsKey(date)) {
          appointmentsByDay[date]!.add(appointment);
        } else {
          appointmentsByDay[date] = [appointment];
        }
      }
      
      setState(() {
        _doctor = doctor;
        _patients = patients;
        _appointments = appointments;
        _appointmentsByDay = appointmentsByDay;
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

  Future<void> _addNewAppointment() async {
    if (_doctor == null || _patients.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add patients before creating appointments')),
        );
      }
      return;
    }

    final result = await showDialog<Appointment>(
      context: context,
      builder: (context) => _AddAppointmentDialog(
        doctor: _doctor!,
        patients: _patients,
        selectedDate: _selectedDay ?? DateTime.now(),
      ),
    );

    if (result != null) {
      try {
        await _storageService.saveAppointment(result);
        await _loadData(); // Refresh the data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating appointment: $e')),
          );
        }
      }
    }
  }

  Future<void> _editAppointment(Appointment appointment) async {
    if (_doctor == null || _patients.isEmpty) return;

    final result = await showDialog<Appointment>(
      context: context,
      builder: (context) => _EditAppointmentDialog(
        doctor: _doctor!,
        patients: _patients,
        appointment: appointment,
      ),
    );

    if (result != null) {
      try {
        await _storageService.saveAppointment(result);
        await _loadData(); // Refresh the data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating appointment: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _storageService.deleteAppointment(appointment.id);
        await _loadData(); // Refresh the data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting appointment: $e')),
          );
        }
      }
    }
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _appointmentsByDay[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Scheduler'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctor == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
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
              : Column(
                  children: [
                    TableCalendar<Appointment>(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      eventLoader: _getAppointmentsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: const CalendarStyle(
                        // Use `CalendarStyle` to customize the day cells
                        outsideDaysVisible: true,
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDay != null
                                ? 'Appointments for ${_formatDate(_selectedDay!)}'
                                : 'Select a date',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addNewAppointment,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Expanded(
                      child: _selectedDay != null
                          ? _buildAppointmentsList(_selectedDay!)
                          : const Center(
                              child: Text(
                                'Please select a date to view appointments',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAppointment,
        backgroundColor: const Color(0xFF137fec),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppointmentsList(DateTime selectedDay) {
    final appointments = _getAppointmentsForDay(selectedDay);
    
    if (appointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No appointments scheduled',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to add a new appointment',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(appointment.patientName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatTime(appointment.dateTime)),
                Text(appointment.reason),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(appointment.status),
                    style: TextStyle(
                      color: _getStatusColor(appointment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editAppointment(appointment);
                } else if (value == 'delete') {
                  _deleteAppointment(appointment);
                } else if (value == 'mark_in_progress') {
                  _updateAppointmentStatus(appointment, AppointmentStatus.inProgress);
                } else if (value == 'mark_completed') {
                  _updateAppointmentStatus(appointment, AppointmentStatus.completed);
                } else if (value == 'mark_cancelled') {
                  _updateAppointmentStatus(appointment, AppointmentStatus.cancelled);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'mark_in_progress',
                  child: ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Mark In Progress'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'mark_completed',
                  child: ListTile(
                    leading: Icon(Icons.check),
                    title: Text('Mark Completed'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'mark_cancelled',
                  child: ListTile(
                    leading: Icon(Icons.cancel),
                    title: Text('Mark Cancelled'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
            onTap: () => _viewAppointmentDetails(appointment),
          ),
        );
      },
    );
  }

  void _updateAppointmentStatus(Appointment appointment, AppointmentStatus status) async {
    try {
      final updatedAppointment = appointment.copyWith(status: status);
      await _storageService.saveAppointment(updatedAppointment);
      await _loadData(); // Refresh the data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating appointment status: $e')),
        );
      }
    }
  }

  void _viewAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Patient', value: appointment.patientName),
            _DetailRow(
                label: 'Date & Time', value: '${_formatDate(appointment.dateTime)} at ${_formatTime(appointment.dateTime)}'),
            _DetailRow(label: 'Reason', value: appointment.reason),
            _DetailRow(label: 'Status', value: _getStatusText(appointment.status)),
            _DetailRow(label: 'Notes', value: appointment.notes),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$formattedHour:$minute $period';
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AddAppointmentDialog extends StatefulWidget {
  final Doctor doctor;
  final List<Patient> patients;
  final DateTime selectedDate;

  const _AddAppointmentDialog({
    required this.doctor,
    required this.patients,
    required this.selectedDate,
  });

  @override
  State<_AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<_AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedPatientId;
  late DateTime _selectedDateTime;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patients.first.id;
    _selectedDateTime = widget.selectedDate;
    _reasonController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Appointment'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  decoration: const InputDecoration(
                    labelText: 'Select Patient',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.patients.map((patient) {
                    return DropdownMenuItem(
                      value: patient.id,
                      child: Text(patient.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPatientId = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a patient';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Appointment Date & Time'),
                  subtitle: Text('${_formatDate(_selectedDateTime)} at ${_formatTime(_selectedDateTime)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectDateTime,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Appointment',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveAppointment,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveAppointment() {
    if (_formKey.currentState!.validate()) {
      final selectedPatient = widget.patients.firstWhere((p) => p.id == _selectedPatientId);
      
      final appointment = Appointment(
        id: 'appointment_${DateTime.now().millisecondsSinceEpoch}',
        doctorId: widget.doctor.id,
        patientId: _selectedPatientId,
        patientName: selectedPatient.name,
        dateTime: _selectedDateTime,
        reason: _reasonController.text,
        status: AppointmentStatus.scheduled,
        notes: _notesController.text,
      );

      Navigator.of(context).pop(appointment);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$formattedHour:$minute $period';
  }
}

class _EditAppointmentDialog extends StatefulWidget {
  final Doctor doctor;
  final List<Patient> patients;
  final Appointment appointment;

  const _EditAppointmentDialog({
    required this.doctor,
    required this.patients,
    required this.appointment,
  });

  @override
  State<_EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<_EditAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedPatientId;
  late DateTime _selectedDateTime;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.appointment.patientId;
    _selectedDateTime = widget.appointment.dateTime;
    _reasonController = TextEditingController(text: widget.appointment.reason);
    _notesController = TextEditingController(text: widget.appointment.notes);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Appointment'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  decoration: const InputDecoration(
                    labelText: 'Select Patient',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.patients.map((patient) {
                    return DropdownMenuItem(
                      value: patient.id,
                      child: Text(patient.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPatientId = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a patient';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Appointment Date & Time'),
                  subtitle: Text('${_formatDate(_selectedDateTime)} at ${_formatTime(_selectedDateTime)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectDateTime,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Appointment',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveAppointment,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveAppointment() {
    if (_formKey.currentState!.validate()) {
      final selectedPatient = widget.patients.firstWhere((p) => p.id == _selectedPatientId);
      
      final appointment = widget.appointment.copyWith(
        patientId: _selectedPatientId,
        patientName: selectedPatient.name,
        dateTime: _selectedDateTime,
        reason: _reasonController.text,
        notes: _notesController.text,
      );

      Navigator.of(context).pop(appointment);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$formattedHour:$minute $period';
  }
}