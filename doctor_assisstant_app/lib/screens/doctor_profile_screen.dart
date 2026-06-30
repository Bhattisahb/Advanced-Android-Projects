import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/doctor.dart';
import '../services/local_storage_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final ImagePicker _picker = ImagePicker();
  Doctor? _doctor;
  bool _isLoading = true;

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

  Future<void> _editDoctor() async {
    if (_doctor == null) {
      // Create a new doctor
      final result = await showDialog<Doctor>(
        context: context,
        builder: (context) => _EditDoctorDialog(doctor: null),
      );

      if (result != null) {
        await _storageService.saveDoctor(result);
        setState(() {
          _doctor = result;
        });
      }
    } else {
      // Edit existing doctor
      final result = await showDialog<Doctor>(
        context: context,
        builder: (context) => _EditDoctorDialog(doctor: _doctor),
      );

      if (result != null) {
        await _storageService.saveDoctor(result);
        setState(() {
          _doctor = result;
        });
      }
    }
  }

  Future<void> _deleteDoctor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: const Text('Are you sure you want to delete this doctor profile?'),
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
        await _storageService.deleteDoctor(widget.doctorId);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting doctor: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final fileName = 'doctor_${widget.doctorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = await _storageService.saveImageFile(bytes, fileName);
        
        if (_doctor != null) {
          final updatedDoctor = _doctor!.copyWith(profilePhotoPath: filePath);
          await _storageService.saveDoctor(updatedDoctor);
          setState(() {
            _doctor = updatedDoctor;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
        actions: [
          if (_doctor != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editDoctor,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctor == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_add,
                        size: 64,
                        color: Color(0xFF137fec),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Doctor Profile Found',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a doctor profile to get started',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _editDoctor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137fec),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text(
                          'Create Doctor Profile',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Profile Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF137fec),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickProfileImage,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: _doctor!.profilePhotoPath.isNotEmpty
                                    ? ClipOval(
                                        child: Image.file(
                                          File(_doctor!.profilePhotoPath),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Color(0xFF137fec),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _doctor!.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _doctor!.specialty,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_doctor!.experience} years experience',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Doctor Details
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Professional Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              label: 'Qualification',
                              value: _doctor!.qualification,
                            ),
                            _DetailRow(
                              label: 'Contact',
                              value: _doctor!.contactNumber,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Clinic Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              label: 'Clinic Name',
                              value: _doctor!.clinicName,
                            ),
                            _DetailRow(
                              label: 'Address',
                              value: _doctor!.clinicAddress,
                            ),
                            _DetailRow(
                              label: 'Consultation Fee',
                              value: '\$${_doctor!.consultationFee.toStringAsFixed(2)}',
                            ),
                            _DetailRow(
                              label: 'Working Hours',
                              value: _doctor!.workingHours,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Availability',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._doctor!.availability.map((availability) => _AvailabilityItem(availability)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _doctor != null
          ? FloatingActionButton(
              onPressed: _deleteDoctor,
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            )
          : null,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityItem extends StatelessWidget {
  final Availability availability;

  const _AvailabilityItem(this.availability);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              availability.day,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              availability.isAvailable
                  ? '${availability.startTime} - ${availability.endTime}'
                  : 'Not Available',
              style: TextStyle(
                fontSize: 16,
                color: availability.isAvailable ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDoctorDialog extends StatefulWidget {
  final Doctor? doctor;

  const _EditDoctorDialog({required this.doctor});

  @override
  State<_EditDoctorDialog> createState() => _EditDoctorDialogState();
}

class _EditDoctorDialogState extends State<_EditDoctorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _contactController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicAddressController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _workingHoursController;
  
  // Availability controllers
  final List<Map<String, dynamic>> _availabilityControllers = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data or empty
    if (widget.doctor != null) {
      _nameController = TextEditingController(text: widget.doctor!.name);
      _specialtyController = TextEditingController(text: widget.doctor!.specialty);
      _qualificationController = TextEditingController(text: widget.doctor!.qualification);
      _experienceController = TextEditingController(text: widget.doctor!.experience.toString());
      _contactController = TextEditingController(text: widget.doctor!.contactNumber);
      _clinicNameController = TextEditingController(text: widget.doctor!.clinicName);
      _clinicAddressController = TextEditingController(text: widget.doctor!.clinicAddress);
      _consultationFeeController = TextEditingController(text: widget.doctor!.consultationFee.toString());
      _workingHoursController = TextEditingController(text: widget.doctor!.workingHours);
      
      // Initialize availability controllers
      for (var availability in widget.doctor!.availability) {
        _availabilityControllers.add({
          'day': availability.day,
          'startTime': TextEditingController(text: availability.startTime),
          'endTime': TextEditingController(text: availability.endTime),
          'isAvailable': availability.isAvailable,
        });
      }
    } else {
      _nameController = TextEditingController();
      _specialtyController = TextEditingController();
      _qualificationController = TextEditingController();
      _experienceController = TextEditingController();
      _contactController = TextEditingController();
      _clinicNameController = TextEditingController();
      _clinicAddressController = TextEditingController();
      _consultationFeeController = TextEditingController();
      _workingHoursController = TextEditingController();
      
      // Initialize default availability for all days
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      for (var day in days) {
        _availabilityControllers.add({
          'day': day,
          'startTime': TextEditingController(text: '09:00'),
          'endTime': TextEditingController(text: '17:00'),
          'isAvailable': true,
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _contactController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _consultationFeeController.dispose();
    _workingHoursController.dispose();
    
    // Dispose availability controllers
    for (var controllerMap in _availabilityControllers) {
      (controllerMap['startTime'] as TextEditingController).dispose();
      (controllerMap['endTime'] as TextEditingController).dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.doctor == null ? 'Add Doctor' : 'Edit Doctor'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, 'Doctor Name', validator: _validateRequired),
                _buildTextField(_specialtyController, 'Specialty', validator: _validateRequired),
                _buildTextField(_qualificationController, 'Qualification', validator: _validateRequired),
                _buildTextField(_experienceController, 'Experience (years)', validator: _validateExperience),
                _buildTextField(_contactController, 'Contact Number', validator: _validateRequired),
                _buildTextField(_clinicNameController, 'Clinic Name', validator: _validateRequired),
                _buildTextField(_clinicAddressController, 'Clinic Address', validator: _validateRequired),
                _buildTextField(_consultationFeeController, 'Consultation Fee', validator: _validateFee),
                _buildTextField(_workingHoursController, 'Working Hours', validator: _validateRequired),
                const SizedBox(height: 16),
                const Text(
                  'Availability',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._availabilityControllers.map((controllerMap) => _AvailabilityEditItem(controllerMap)).toList(),
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
          child: Text(widget.doctor == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final experience = int.tryParse(value);
    if (experience == null || experience < 0) {
      return 'Please enter a valid number of years';
    }
    return null;
  }

  String? _validateFee(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final fee = double.tryParse(value);
    if (fee == null || fee < 0) {
      return 'Please enter a valid fee';
    }
    return null;
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      try {
        final experience = int.parse(_experienceController.text);
        final consultationFee = double.parse(_consultationFeeController.text);
        
        // Create availability list
        final availabilityList = <Availability>[];
        for (var controllerMap in _availabilityControllers) {
          availabilityList.add(
            Availability(
              day: controllerMap['day'],
              startTime: (controllerMap['startTime'] as TextEditingController).text,
              endTime: (controllerMap['endTime'] as TextEditingController).text,
              isAvailable: controllerMap['isAvailable'],
            ),
          );
        }
        
        final doctor = widget.doctor == null
            ? Doctor(
                id: 'doctor_${DateTime.now().millisecondsSinceEpoch}',
                name: _nameController.text,
                specialty: _specialtyController.text,
                qualification: _qualificationController.text,
                experience: experience,
                contactNumber: _contactController.text,
                profilePhotoPath: '',
                clinicName: _clinicNameController.text,
                clinicAddress: _clinicAddressController.text,
                consultationFee: consultationFee,
                workingHours: _workingHoursController.text,
                availability: availabilityList,
              )
            : widget.doctor!.copyWith(
                name: _nameController.text,
                specialty: _specialtyController.text,
                qualification: _qualificationController.text,
                experience: experience,
                contactNumber: _contactController.text,
                clinicName: _clinicNameController.text,
                clinicAddress: _clinicAddressController.text,
                consultationFee: consultationFee,
                workingHours: _workingHoursController.text,
                availability: availabilityList,
              );

        Navigator.of(context).pop(doctor);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid input data')),
        );
      }
    }
  }
}

class _AvailabilityEditItem extends StatefulWidget {
  final Map<String, dynamic> controllerMap;

  const _AvailabilityEditItem(this.controllerMap);

  @override
  State<_AvailabilityEditItem> createState() => _AvailabilityEditItemState();
}

class _AvailabilityEditItemState extends State<_AvailabilityEditItem> {
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.controllerMap['isAvailable'];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              widget.controllerMap['day'],
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: widget.controllerMap['startTime'],
              decoration: const InputDecoration(
                labelText: 'Start',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              enabled: _isAvailable,
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: widget.controllerMap['endTime'],
              decoration: const InputDecoration(
                labelText: 'End',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              enabled: _isAvailable,
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (value) {
              setState(() {
                _isAvailable = value;
                widget.controllerMap['isAvailable'] = value;
              });
            },
          ),
        ],
      ),
    );
  }
}