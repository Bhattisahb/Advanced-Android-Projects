import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/add_edit_task_screen.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final bool showProgress;

  const TaskList({
    Key? key,
    required this.tasks,
    this.showProgress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks found'),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              task.title,
              style: TextStyle(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.description),
                const SizedBox(height: 4),
                if (showProgress && task.subTasks != null)
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.grey[300],
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.isRepeating)
                  const Icon(
                    Icons.repeat,
                    color: Colors.blue,
                  ),
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (bool? value) {
                    Provider.of<TaskProvider>(context, listen: false)
                        .toggleTaskCompletion(task);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    Provider.of<TaskProvider>(context, listen: false)
                        .deleteTask(task.id!);
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditTaskScreen(task: task),
                ),
              );
            },
          ),
        );
      },
    );
  }
}