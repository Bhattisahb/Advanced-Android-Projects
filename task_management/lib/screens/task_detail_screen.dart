import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskDetailScreen extends StatelessWidget {
  final int taskId;
  const TaskDetailScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    Task? task;
    try {
      task = provider.tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      task = null;
    }

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task')), 
        body: const Center(child: Text('Task not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            const SizedBox(height: 12),
            Text('Due: ${task.dueDate.toLocal()}'),
            const SizedBox(height: 12),
            if (task.reminderDateTime != null) Text('Reminder: ${task.reminderDateTime!.toLocal()}'),
            const SizedBox(height: 12),
            if (task.subTasks != null && task.subTasks!.isNotEmpty) ...[
              const Text('Subtasks:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...task.subTasks!.map((s) => ListTile(
                    title: Text(s.title),
                    trailing: Icon(s.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                  ))
            ]
          ],
        ),
      ),
    );
  }
}
