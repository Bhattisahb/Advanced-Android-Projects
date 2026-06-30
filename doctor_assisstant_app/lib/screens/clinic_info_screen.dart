import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/local_storage_service.dart';

class ClinicInfoScreen extends StatefulWidget {
  final String doctorId;

  const ClinicInfoScreen({super.key, required this.doctorId});

  @override
  State<ClinicInfoScreen> createState() => _ClinicInfoScreenState();
}

class _ClinicInfoScreenState extends State<ClinicInfoScreen> {
  final LocalStorageService _storageService = LocalStorageService();
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
          SnackBar(content: Text('Error loading clinic data: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editClinicInfo() async {
    if (_doctor == null) return;

    final result = await showDialog<Doctor>(
      context: context,
      builder: (context) => _EditClinicInfoDialog(doctor: _doctor!),
    );

    if (result != null) {
      await _storageService.saveDoctor(result);
      setState(() {
        _doctor = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic Information'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
        actions: [
          if (_doctor != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editClinicInfo,
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
                        Icons.local_hospital,
                        size: 64,
                        color: Color(0xFF137fec),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Clinic Information Found',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Doctor profile not found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clinic Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF137fec),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _doctor!.clinicName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _doctor!.clinicAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Clinic Details
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailCard(
                              title: 'Consultation Fee',
                              value: '\$${_doctor!.consultationFee.toStringAsFixed(2)}',
                              icon: Icons.attach_money,
                            ),
                            const SizedBox(height: 16),
                            _DetailCard(
                              title: 'Working Hours',
                              value: _doctor!.workingHours,
                              icon: Icons.access_time,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              label: 'Doctor Name',
                              value: _doctor!.name,
                            ),
                            _DetailRow(
                              label: 'Specialty',
                              value: _doctor!.specialty,
                            ),
                            _DetailRow(
                              label: 'Contact Number',
                              value: _doctor!.contactNumber,
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
                            ..._doctor!.availability.map((availability) => _AvailabilityItem(availability)).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DetailCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF137fec),
              size: 30,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

class _EditClinicInfoDialog extends StatefulWidget {
  final Doctor doctor;

  const _EditClinicInfoDialog({required this.doctor});

  @override
  State<_EditClinicInfoDialog> createState() => _EditClinicInfoDialogState();
}

class _EditClinicInfoDialogState extends State<_EditClinicInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicAddressController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _workingHoursController;

  @override
  void initState() {
    super.initState();
    _clinicNameController = TextEditingController(text: widget.doctor.clinicName);
    _clinicAddressController = TextEditingController(text: widget.doctor.clinicAddress);
    _consultationFeeController = TextEditingController(text: widget.doctor.consultationFee.toString());
    _workingHoursController = TextEditingController(text: widget.doctor.workingHours);
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _consultationFeeController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Clinic Information'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_clinicNameController, 'Clinic Name', validator: _validateRequired),
                _buildTextField(_clinicAddressController, 'Clinic Address', validator: _validateRequired),
                _buildTextField(_consultationFeeController, 'Consultation Fee', validator: _validateFee),
                _buildTextField(_workingHoursController, 'Working Hours', validator: _validateRequired),
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
        final consultationFee = double.parse(_consultationFeeController.text);
        
        final updatedDoctor = widget.doctor.copyWith(
          clinicName: _clinicNameController.text,
          clinicAddress: _clinicAddressController.text,
          consultationFee: consultationFee,
          workingHours: _workingHoursController.text,
        );

        Navigator.of(context).pop(updatedDoctor);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid input data')),
        );
      }
    }
  }
}