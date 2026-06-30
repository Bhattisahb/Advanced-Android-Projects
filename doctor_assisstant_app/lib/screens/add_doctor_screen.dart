import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/doctor_model.dart';
import '../services/doctor_service.dart';

class AddDoctorScreen extends StatefulWidget {
  final Doctor? doctor; // If provided, we're editing an existing doctor

  const AddDoctorScreen({super.key, this.doctor});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final DoctorService _doctorService = DoctorService();

  // Controllers for text fields
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _experienceController;
  late TextEditingController _contactController;
  late TextEditingController _feeController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;

  // Working days selection
  final List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  List<String> _selectedDays = [];

  // Time values
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController();
    _specialtyController = TextEditingController();
    _experienceController = TextEditingController();
    _contactController = TextEditingController();
    _feeController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    
    // If editing existing doctor, populate fields
    if (widget.doctor != null) {
      _nameController.text = widget.doctor!.name;
      _specialtyController.text = widget.doctor!.specialty;
      _experienceController.text = widget.doctor!.experience.toString();
      _contactController.text = widget.doctor!.contactNumber;
      _feeController.text = widget.doctor!.consultationFee.toString();
      _selectedDays = List.from(widget.doctor!.workingDays);
      _startTime = _parseTime(widget.doctor!.startTime);
      _endTime = _parseTime(widget.doctor!.endTime);
    }
    
    // Set initial time controller values
    _startTimeController.text = _formatTime(_startTime);
    _endTimeController.text = _formatTime(_endTime);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _experienceController.dispose();
    _contactController.dispose();
    _feeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
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

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _startTime = picked;
        _startTimeController.text = _formatTime(picked);
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _endTime = picked;
        _endTimeController.text = _formatTime(picked);
      });
    }
  }

  void _toggleDaySelection(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _saveDoctor() async {
    if (_formKey.currentState!.validate()) {
      // Validate that at least one day is selected
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one working day'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        // Create or update doctor
        final doctor = Doctor(
          id: widget.doctor?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          specialty: _specialtyController.text.trim(),
          experience: int.parse(_experienceController.text.trim()),
          contactNumber: _contactController.text.trim(),
          consultationFee: double.parse(_feeController.text.trim()),
          workingDays: _selectedDays,
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
        );

        // Save to local storage
        await _doctorService.saveDoctor(doctor);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.doctor == null 
                  ? 'Doctor added successfully!' 
                  : 'Doctor updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to View Doctors screen
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving doctor: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctor == null ? 'Add Doctor' : 'Edit Doctor'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Name
              const Text(
                'Doctor Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter doctor name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter doctor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Specialty
              const Text(
                'Specialty',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  hintText: 'Enter specialty',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter specialty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Experience
              const Text(
                'Experience (years)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  hintText: 'Enter years of experience',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter experience';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Number
              const Text(
                'Contact Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  hintText: 'Enter contact number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Consultation Fee
              const Text(
                'Consultation Fee',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feeController,
                decoration: const InputDecoration(
                  hintText: 'Enter consultation fee',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter consultation fee';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Working Days
              const Text(
                'Working Days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      _toggleDaySelection(day);
                    },
                    selectedColor: const Color(0xFF137fec),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Timings
              const Text(
                'Timings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _startTimeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'Select start time',
                            border: OutlineInputBorder(),
                          ),
                          onTap: _selectStartTime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _endTimeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'Select end time',
                            border: OutlineInputBorder(),
                          ),
                          onTap: _selectEndTime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDoctor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137fec),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    widget.doctor == null ? 'Save Doctor' : 'Update Doctor',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}