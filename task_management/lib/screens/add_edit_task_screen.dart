import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../services/image_picker_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({
    Key? key,
    this.task,
  }) : super(key: key);

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isRepeating = false;
  List<String> _selectedDays = [];
  List<SubTask> _subTasks = [];
  final TextEditingController _subTaskController = TextEditingController();
  // Reminder UI state (not persisted right now)
  bool _addReminder = false;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  List<String> _selectedImagePaths = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.dueDate ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(widget.task?.dueDate ?? DateTime.now());
    _isRepeating = widget.task?.isRepeating ?? false;
    _selectedDays = widget.task?.repeatDays ?? [];
    _subTasks = widget.task?.subTasks ?? [];
    _selectedImagePaths = widget.task?.imagePaths ?? [];
    // default reminder values: load from task if present
    if (widget.task?.reminderDateTime != null) {
      _addReminder = true;
      _reminderDate = DateTime(
        widget.task!.reminderDateTime!.year,
        widget.task!.reminderDateTime!.month,
        widget.task!.reminderDateTime!.day,
      );
      _reminderTime = TimeOfDay.fromDateTime(widget.task!.reminderDateTime!);
    } else {
      _addReminder = false;
      _reminderDate = null;
      _reminderTime = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addSubTask() {
    if (_subTaskController.text.isNotEmpty) {
      setState(() {
        _subTasks.add(
          SubTask(
            taskId: widget.task?.id ?? 0,
            title: _subTaskController.text,
          ),
        );
        _subTaskController.clear();
      });
    }
  }

  Future<void> _selectReminderDate(BuildContext context) async {
    final DateTime initial = _reminderDate ?? _selectedDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }

  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay initial = _reminderTime ?? _selectedTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }

  Future<void> _pickFromCamera() async {
    final imagePath = await ImagePickerService.instance.pickFromCamera();
    if (imagePath != null) {
      setState(() {
        _selectedImagePaths.add(imagePath);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final imagePath = await ImagePickerService.instance.pickFromGallery();
    if (imagePath != null) {
      setState(() {
        _selectedImagePaths.add(imagePath);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImagePaths.removeAt(index);
    });
  }

  void _showImagePreview(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Container(
              color: Colors.black,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final DateTime dueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: dueDate,
        isRepeating: _isRepeating,
        repeatDays: _isRepeating ? _selectedDays : null,
        reminderDateTime: _addReminder && _reminderDate != null && _reminderTime != null
            ? DateTime(
                _reminderDate!.year,
                _reminderDate!.month,
                _reminderDate!.day,
                _reminderTime!.hour,
                _reminderTime!.minute,
              )
            : null,
        subTasks: _subTasks,
        imagePaths: _selectedImagePaths.isNotEmpty ? _selectedImagePaths : null,
      );

      Task savedTask;
      if (widget.task == null) {
        // addTask will schedule notifications and persist their ids
        savedTask = await context.read<TaskProvider>().addTask(task);
      } else {
        // updateTask will cancel previous notifications, reschedule, and persist ids
        savedTask = await context.read<TaskProvider>().updateTask(task);
      }

      // Local UI feedback: snack bar with reminder info if present
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "${savedTask.title}" saved.')),
        );
        if (savedTask.reminderDateTime != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reminder scheduled for ${DateFormat('yyyy-MM-dd HH:mm').format(savedTask.reminderDateTime!)}')),
          );
        }
      }

      if (mounted) {
        // Refresh tasks in provider so the home screen shows the newly saved task
        await context.read<TaskProvider>().loadTasks();

        // Pop back to the root (HomeScreen / All tasks view)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
              SwitchListTile(
                title: const Text('Add a reminder'),
                value: _addReminder,
                onChanged: (bool value) {
                  setState(() {
                    _addReminder = value;
                    if (!value) {
                      _reminderDate = null;
                      _reminderTime = null;
                    } else {
                      // default reminder to 15 minutes before due date if possible
                      final defaultReminder = DateTime.now().isBefore(DateTime.now())
                          ? DateTime.now().add(const Duration(minutes: 5))
                          : DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _selectedTime.hour,
                              _selectedTime.minute,
                            ).subtract(const Duration(minutes: 15));
                      _reminderDate ??= DateTime(defaultReminder.year, defaultReminder.month, defaultReminder.day);
                      _reminderTime ??= TimeOfDay.fromDateTime(defaultReminder);
                    }
                  });
                },
              ),
              if (_addReminder) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _selectReminderDate(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_reminderDate == null
                            ? 'Select date'
                            : DateFormat('yyyy-MM-dd').format(_reminderDate!)),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _selectReminderTime(context),
                        icon: const Icon(Icons.access_time),
                        label: Text(_reminderTime == null
                            ? 'Select time'
                            : _reminderTime!.format(context)),
                      ),
                    ),
                  ],
                ),
              ],
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Repeating Task'),
                value: _isRepeating,
                onChanged: (bool value) {
                  setState(() {
                    _isRepeating = value;
                    if (!value) {
                      _selectedDays.clear();
                    }
                  });
                },
              ),
              if (_isRepeating) ...[
                const Text('Repeat on:'),
                Wrap(
                  spacing: 8.0,
                  children: [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ].map((day) {
                    return FilterChip(
                      label: Text(day),
                      selected: _selectedDays.contains(day),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Subtasks:'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subTaskController,
                      decoration: const InputDecoration(
                        hintText: 'Add a subtask',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addSubTask,
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subTasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_subTasks[index].title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeSubTask(index),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Images:', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.image),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              if (_selectedImagePaths.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Selected Images:'),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImagePaths.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GestureDetector(
                              onTap: () => _showImagePreview(_selectedImagePaths[index]),
                              child: Image.file(
                                File(_selectedImagePaths[index]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTask,
        child: const Icon(Icons.save),
      ),
    );
  }
}