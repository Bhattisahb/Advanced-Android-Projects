import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/task_list.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'add_edit_task_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      context.read<TaskProvider>().loadTasks();
    });
    // Prompt user to enable notifications if disabled (Android)
    Future.microtask(() async {
      try {
        final enabled = await NotificationService().areNotificationsEnabled();
        if (!enabled && mounted) {
          // show a dialog prompting the user to open settings
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Enable notifications'),
                content: const Text('To receive reminders please enable notifications for this app in system settings.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Later'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await NotificationService().openAppNotificationSettings();
                    },
                    child: const Text('Open settings'),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        // ignore
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final taskProvider = context.read<TaskProvider>();
              String? filePath;
              
              switch (value) {
                case 'export_csv':
                  filePath = await ExportService.exportToCsv(taskProvider.tasks);
                  break;
                case 'export_pdf':
                  try {
                    // Suggest a default filename
                    final String suggestedName = 'tasks_${DateTime.now().millisecondsSinceEpoch}.pdf';

                    // Try system save dialog
                    final result = await getSaveLocation(suggestedName: suggestedName);
                    if (result != null) {
                      filePath = await ExportService.exportToPdf(taskProvider.tasks, outputFilePath: result.path);
                    } else {
                      // User cancelled the dialog
                      return;
                    }
                  } catch (e) {
                    // Fallback: save to app documents directory if system picker fails or is unsupported
                    try {
                      filePath = await ExportService.exportToPdf(taskProvider.tasks);
                      if (filePath != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('System save dialog unavailable — saved to app documents: $filePath')),
                        );
                      }
                    } catch (e2) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e\nFallback save failed: $e2')),
                        );
                      }
                      return;
                    }
                  }

                  break;
              }

              if (filePath != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File exported to: $filePath'),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'export_csv',
                child: Text('Export to CSV'),
              ),
              const PopupMenuItem<String>(
                value: 'export_pdf',
                child: Text('Export to PDF'),
              ),
            ],
            icon: const Icon(Icons.download),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Completed'),
            Tab(text: 'Repeated'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Today's Tasks
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return TaskList(tasks: taskProvider.todayTasks);
            },
          ),
          // Completed Tasks
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return TaskList(tasks: taskProvider.completedTasks);
            },
          ),
          // Repeated Tasks
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return TaskList(tasks: taskProvider.repeatingTasks);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}