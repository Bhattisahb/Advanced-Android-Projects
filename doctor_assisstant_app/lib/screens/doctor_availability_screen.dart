import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/doctor.dart';
import '../services/local_storage_service.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  final String doctorId;

  const DoctorAvailabilityScreen({super.key, required this.doctorId});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  Doctor? _doctor;
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doctor = _storageService.getDoctor(widget.doctorId);
      setState(() {
        _doctor = doctor;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctor data: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editAvailability() async {
    if (_doctor == null) return;

    final result = await showDialog<Doctor>(
      context: context,
      builder: (context) => _EditAvailabilityDialog(doctor: _doctor!),
    );

    if (result != null) {
      try {
        await _storageService.saveDoctor(result);
        setState(() {
          _doctor = result;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating availability: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Availability'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
        actions: [
          if (_doctor != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editAvailability,
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
                    TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly Availability',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._doctor!.availability.map((availability) => _AvailabilityItem(availability)).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _editAvailability,
        backgroundColor: const Color(0xFF137fec),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

class _AvailabilityItem extends StatefulWidget {
  final Availability availability;

  const _AvailabilityItem(this.availability);

  @override
  State<_AvailabilityItem> createState() => _AvailabilityItemState();
}

class _AvailabilityItemState extends State<_AvailabilityItem> {
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.availability.isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.availability.day,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAvailable
                        ? '${widget.availability.startTime} - ${widget.availability.endTime}'
                        : 'Not Available',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAvailabilityDialog extends StatefulWidget {
  final Doctor doctor;

  const _EditAvailabilityDialog({required this.doctor});

  @override
  State<_EditAvailabilityDialog> createState() => _EditAvailabilityDialogState();
}

class _EditAvailabilityDialogState extends State<_EditAvailabilityDialog> {
  final _formKey = GlobalKey<FormState>();
  late List<Availability> _availabilityList;

  @override
  void initState() {
    super.initState();
    // Create a copy of the availability list for editing
    _availabilityList = widget.doctor.availability.map((a) => a.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Availability'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set your weekly availability',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ..._availabilityList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final availability = entry.value;
                  return _AvailabilityEditItem(
                    availability: availability,
                    onChanged: (updatedAvailability) {
                      setState(() {
                        _availabilityList[index] = updatedAvailability;
                      });
                    },
                  );
                }).toList(),

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
          onPressed: _saveChanges,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveChanges() {
    final updatedDoctor = widget.doctor.copyWith(availability: _availabilityList);
    Navigator.of(context).pop(updatedDoctor);
  }
}

class _AvailabilityEditItem extends StatefulWidget {
  final Availability availability;
  final Function(Availability) onChanged;

  const _AvailabilityEditItem({
    required this.availability,
    required this.onChanged,
  });

  @override
  State<_AvailabilityEditItem> createState() => _AvailabilityEditItemState();
}

class _AvailabilityEditItemState extends State<_AvailabilityEditItem> {
  late bool _isAvailable;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.availability.isAvailable;
    _startTime = _parseTime(widget.availability.startTime);
    _endTime = _parseTime(widget.availability.endTime);
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.availability.day,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                ),
              ],
            ),
            if (_isAvailable) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(_formatTime(_startTime)),
                      onTap: _selectStartTime,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(_formatTime(_endTime)),
                      onTap: _selectEndTime,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  @override
  void dispose() {
    // Notify parent of changes when disposing
    final updatedAvailability = widget.availability.copyWith(
      isAvailable: _isAvailable,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
    );
    widget.onChanged(updatedAvailability);
    super.dispose();
  }
}