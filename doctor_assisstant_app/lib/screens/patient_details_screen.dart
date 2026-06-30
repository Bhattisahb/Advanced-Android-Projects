import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/patient.dart';
import '../models/report.dart';
import '../services/local_storage_service.dart';
import 'medical_records_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Patient? _patient;
  List<Report> _reports = [];
  final LocalStorageService _storageService = LocalStorageService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    // In a real app, you would get the patient ID from navigation parameters
    final patient = _storageService.getPatient(widget.patientId);
    if (patient != null) {
      setState(() {
        _patient = patient;
      });
    } else {
      // For new patients, we don't create a sample automatically
      // The user will need to enter patient details
      setState(() {
        _patient = null;
      });
    }

    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = _storageService.getReportsForPatient(widget.patientId);
    setState(() {
      _reports = reports;
    });
  }

  Future<void> _editPatient() async {
    if (_patient == null) {
      // Create a new patient
      final result = await showDialog<Patient>(
        context: context,
        builder: (context) => _EditPatientDialog(patient: null),
      );

      if (result != null) {
        await _storageService.savePatient(result);
        setState(() {
          _patient = result;
        });
      }
    } else {
      // Edit existing patient
      final result = await showDialog<Patient>(
        context: context,
        builder: (context) => _EditPatientDialog(patient: _patient),
      );

      if (result != null) {
        await _storageService.savePatient(result);
        setState(() {
          _patient = result;
        });
      }
    }
  }

  Future<void> _deletePatient() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text('Are you sure you want to delete this patient record?'),
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
      await _storageService.deletePatient(widget.patientId);
      if (mounted) {
        Navigator.of(context).pop(); // Go back to previous screen
      }
    }
  }

  Future<void> _showAddReportDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Add Report Manually'),
              onTap: () {
                Navigator.of(context).pop();
                _addReportManually();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Use Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _captureReportWithCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('From Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickReportFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addReportManually() async {
    final result = await showDialog<Report>(
      context: context,
      builder: (context) => _AddReportManuallyDialog(patientId: widget.patientId),
    );

    if (result != null) {
      try {
        await _storageService.saveReport(result);
        await _loadReports();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving report: $e')),
          );
        }
      }
    }
  }

  Future<void> _captureReportWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _saveReportFromImage(photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  Future<void> _pickReportFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _saveReportFromImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveReportFromImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = await _storageService.saveImageFile(bytes, fileName);

      final report = Report(
        id: '${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}',
        fileName: 'Report ${_reports.length + 1}',
        filePath: filePath,
        dateAdded: DateTime.now(),
      );

      await _storageService.saveReport(report);
      await _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    }
  }

  Future<void> _deleteReport(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
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
        // Delete the file from storage
        final file = File(report.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        // Delete from database
        await _storageService.deleteReport(report.id);
        await _loadReports();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting report: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
      ),
      body: _patient == null
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
                    'New Patient',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add patient details to get started',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _editPatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137fec),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text(
                      'Add Patient Details',
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
                  // Patient Info Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile picture and basic info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF137fec),
                              child: Text(
                                _patient!.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _patient!.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_patient!.age} years, ${_patient!.gender}',
                                    style: TextStyle(
                                      color: Colors.grey.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _patient!.contactNumber,
                                    style: TextStyle(
                                      color: Colors.grey.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Additional details
                        _DetailRow(
                          label: 'Email',
                          value: _patient!.email,
                        ),
                        _DetailRow(
                          label: 'Date of Birth',
                          value: '${_patient!.dateOfBirth.day}/${_patient!.dateOfBirth.month}/${_patient!.dateOfBirth.year}',
                        ),
                        _DetailRow(
                          label: 'Last Appointment',
                          value: '${_patient!.lastAppointment.day}/${_patient!.lastAppointment.month}/${_patient!.lastAppointment.year}',
                        ),
                        const SizedBox(height: 16),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _editPatient,
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF137fec),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _viewMedicalRecords(context),
                                icon: const Icon(Icons.description, color: Colors.white),
                                label: const Text(
                                  'Records',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF137fec),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _deletePatient,
                                icon: const Icon(Icons.delete, color: Colors.white),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reports Section
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Attached Reports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Reports Grid
                  if (_reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No reports attached',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _ReportItem(
                            report: report,
                            onDelete: () => _deleteReport(report),
                            onTap: () => _viewReport(report),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReportDialog,
        backgroundColor: const Color(0xFF137fec),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  void _viewMedicalRecords(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalRecordsScreen(patientId: widget.patientId),
      ),
    );
  }

  void _viewReport(Report report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ReportViewerScreen(report: report),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final Report report;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ReportItem({
    required this.report,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report thumbnail
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: report.filePath.isEmpty
                      ? Icon(
                          Icons.description,
                          size: 40,
                          color: Colors.grey[600],
                        )
                      : Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                ),
                // Report info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.dateAdded.day}/${report.dateAdded.month}/${report.dateAdded.year}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPatientDialog extends StatefulWidget {
  final Patient? patient;

  const _EditPatientDialog({required this.patient});

  @override
  State<_EditPatientDialog> createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends State<_EditPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _lastAppointmentController;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _nameController = TextEditingController(text: widget.patient!.name);
      _ageController = TextEditingController(text: widget.patient!.age.toString());
      _genderController = TextEditingController(text: widget.patient!.gender);
      _contactController = TextEditingController(text: widget.patient!.contactNumber);
      _emailController = TextEditingController(text: widget.patient!.email);
      _dobController = TextEditingController(text: '${widget.patient!.dateOfBirth.day}/${widget.patient!.dateOfBirth.month}/${widget.patient!.dateOfBirth.year}');
      _lastAppointmentController = TextEditingController(text: '${widget.patient!.lastAppointment.day}/${widget.patient!.lastAppointment.month}/${widget.patient!.lastAppointment.year}');
    } else {
      _nameController = TextEditingController();
      _ageController = TextEditingController();
      _genderController = TextEditingController();
      _contactController = TextEditingController();
      _emailController = TextEditingController();
      _dobController = TextEditingController();
      _lastAppointmentController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _lastAppointmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.patient == null ? 'Add Patient' : 'Edit Patient'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, 'Name', validator: _validateRequired),
                _buildTextField(_ageController, 'Age', validator: _validateAge),
                _buildTextField(_genderController, 'Gender', validator: _validateRequired),
                _buildTextField(_contactController, 'Contact Number', validator: _validateRequired),
                _buildTextField(_emailController, 'Email', validator: _validateEmail),
                _buildTextField(_dobController, 'Date of Birth (DD/MM/YYYY)', validator: _validateDate),
                _buildTextField(_lastAppointmentController, 'Last Appointment (DD/MM/YYYY)', validator: _validateDate),
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
          child: Text(widget.patient == null ? 'Add' : 'Save'),
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0) {
      return 'Please enter a valid age';
    }
    return null;
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    // Simple date validation (DD/MM/YYYY)
    final dateRegex = RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Please enter date in DD/MM/YYYY format';
    }
    return null;
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // Parse dates
      DateTime dob, lastAppointment;
      try {
        final dobParts = _dobController.text.split('/');
        dob = DateTime(int.parse(dobParts[2]), int.parse(dobParts[1]), int.parse(dobParts[0]));
        
        final lastAppointmentParts = _lastAppointmentController.text.split('/');
        lastAppointment = DateTime(int.parse(lastAppointmentParts[2]), int.parse(lastAppointmentParts[1]), int.parse(lastAppointmentParts[0]));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid date format')),
        );
        return;
      }

      final patient = widget.patient == null
          ? Patient(
              id: 'patient_${DateTime.now().millisecondsSinceEpoch}',
              name: _nameController.text,
              age: int.parse(_ageController.text),
              gender: _genderController.text,
              contactNumber: _contactController.text,
              email: _emailController.text,
              dateOfBirth: dob,
              lastAppointment: lastAppointment,
            )
          : widget.patient!.copyWith(
              name: _nameController.text,
              age: int.parse(_ageController.text),
              gender: _genderController.text,
              contactNumber: _contactController.text,
              email: _emailController.text,
              dateOfBirth: dob,
              lastAppointment: lastAppointment,
            );

      Navigator.of(context).pop(patient);
    }
  }
}

class _ReportViewerScreen extends StatelessWidget {
  final Report report;

  const _ReportViewerScreen({required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.fileName),
        backgroundColor: const Color(0xFF137fec),
        foregroundColor: Colors.white,
      ),
      body: report.filePath.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This is a manually added report',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No file attached',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Center(
              child: FileImageProvider(report.filePath),
            ),
    );
  }
}

class FileImageProvider extends StatelessWidget {
  final String filePath;

  const FileImageProvider(this.filePath, {super.key});

  @override
  Widget build(BuildContext context) {
    // On web, we can't directly access file paths, so we'll show a placeholder
    if (kIsWeb) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text('Image preview not available on web'),
          ],
        ),
      );
    }

    if (!File(filePath).existsSync()) {
      return const Center(
        child: Text('Image not found'),
      );
    }

    return InteractiveViewer(
      child: Image.file(
        File(filePath),
        fit: BoxFit.contain,
      ),
    );
  }
}

class _AddReportManuallyDialog extends StatefulWidget {
  final String patientId;

  const _AddReportManuallyDialog({required this.patientId});

  @override
  State<_AddReportManuallyDialog> createState() => _AddReportManuallyDialogState();
}

class _AddReportManuallyDialogState extends State<_AddReportManuallyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fileNameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Report Manually'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fileNameController,
                  decoration: const InputDecoration(
                    labelText: 'Report Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a report name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
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
          onPressed: _saveReport,
          child: const Text('Add Report'),
        ),
      ],
    );
  }

  void _saveReport() {
    if (_formKey.currentState!.validate()) {
      // Create a report with no file path since it's manually added
      final report = Report(
        id: '${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}',
        fileName: _fileNameController.text,
        filePath: '', // No file path for manually added reports
        dateAdded: DateTime.now(),
      );

      Navigator.of(context).pop(report);
    }
  }
}