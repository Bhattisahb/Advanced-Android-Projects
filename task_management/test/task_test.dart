import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('Task creation test', () {
      final task = Task(
        id: 1,
        title: 'Test Task',
        description: 'Test Description',
        dueDate: DateTime(2025, 11, 1),
      );

      expect(task.id, 1);
      expect(task.title, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.isCompleted, false);
      expect(task.isRepeating, false);
    });

    test('Task progress calculation test', () {
      final task = Task(
        title: 'Test Task',
        description: 'Test Description',
        dueDate: DateTime(2025, 11, 1),
        subTasks: [
          SubTask(taskId: 1, title: 'Subtask 1', isCompleted: true),
          SubTask(taskId: 1, title: 'Subtask 2', isCompleted: false),
          SubTask(taskId: 1, title: 'Subtask 3', isCompleted: true),
        ],
      );

      expect(task.progress, 2/3);
    });

    test('Task toMap and fromMap test', () {
      final originalTask = Task(
        id: 1,
        title: 'Test Task',
        description: 'Test Description',
        dueDate: DateTime(2025, 11, 1, 10, 30),
        isRepeating: true,
        repeatDays: ['Mon', 'Wed', 'Fri'],
      );

      final map = originalTask.toMap();
      final recreatedTask = Task.fromMap(map);

      expect(recreatedTask.id, originalTask.id);
      expect(recreatedTask.title, originalTask.title);
      expect(recreatedTask.description, originalTask.description);
      expect(recreatedTask.isRepeating, originalTask.isRepeating);
      expect(recreatedTask.repeatDays, originalTask.repeatDays);
    });
  });

  group('SubTask Model Tests', () {
    test('SubTask creation test', () {
      final subtask = SubTask(
        id: 1,
        taskId: 1,
        title: 'Test Subtask',
        isCompleted: false,
      );

      expect(subtask.id, 1);
      expect(subtask.taskId, 1);
      expect(subtask.title, 'Test Subtask');
      expect(subtask.isCompleted, false);
    });

    test('SubTask toMap and fromMap test', () {
      final originalSubtask = SubTask(
        id: 1,
        taskId: 1,
        title: 'Test Subtask',
        isCompleted: true,
      );

      final map = originalSubtask.toMap();
      final recreatedSubtask = SubTask.fromMap(map);

      expect(recreatedSubtask.id, originalSubtask.id);
      expect(recreatedSubtask.taskId, originalSubtask.taskId);
      expect(recreatedSubtask.title, originalSubtask.title);
      expect(recreatedSubtask.isCompleted, originalSubtask.isCompleted);
    });
  });
}