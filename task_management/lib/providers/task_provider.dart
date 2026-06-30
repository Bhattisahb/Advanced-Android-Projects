import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  List<Task> _completedTasks = [];
  List<Task> _repeatingTasks = [];

  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  List<Task> get completedTasks => _completedTasks;
  List<Task> get repeatingTasks => _repeatingTasks;

  Future<void> loadTasks() async {
    _tasks = await DatabaseService.instance.readAllTasks();
    _todayTasks = await DatabaseService.instance.readTodayTasks();
    _completedTasks = await DatabaseService.instance.readCompletedTasks();
    _repeatingTasks = await DatabaseService.instance.readRepeatingTasks();
    notifyListeners();
  }

  Future<Task> addTask(Task task) async {
    // Create task in DB first
    final newTask = await DatabaseService.instance.createTask(task);

    int? dueNotificationId;
    int? reminderNotificationId;

    // schedule due notification (use task id as base id)
    if (newTask.dueDate.isAfter(DateTime.now())) {
      dueNotificationId = newTask.id; // simple mapping
      try {
        await NotificationService().scheduleTaskNotification(
          dueNotificationId ?? 0,
          newTask.title,
          newTask.description,
          newTask.dueDate,
        );
      } catch (e) {
        // ignore scheduling errors
      }
    }

    // schedule reminder if present
    if (newTask.reminderDateTime != null && newTask.reminderDateTime!.isAfter(DateTime.now())) {
      reminderNotificationId = (newTask.id ?? 0) + 2000000;
      try {
        await NotificationService().scheduleTaskNotification(
          reminderNotificationId,
          'Reminder: ${newTask.title}',
          newTask.description,
          newTask.reminderDateTime!,
        );
      } catch (e) {
        // ignore
      }
    }

    // show immediate confirmation notification
    try {
      final confirmId = (newTask.id ?? 0) + 1000000;
      await NotificationService().showNotification(
        confirmId,
        'Task saved',
        '"${newTask.title}" has been saved.',
        payload: newTask.id?.toString(),
      );
    } catch (e) {
      // ignore
    }

    // persist notification ids back to DB
    final withIds = newTask.copyWith(
      dueNotificationId: dueNotificationId,
      reminderNotificationId: reminderNotificationId,
    );
    await DatabaseService.instance.updateTask(withIds);

    _tasks.add(withIds);
    _updateTaskLists(withIds);
    notifyListeners();
    return withIds;
  }

  Future<Task> updateTask(Task task) async {
    // Cancel any existing notifications for this task (if ids are present on the stored task)
    final existing = _tasks.firstWhere((t) => t.id == task.id, orElse: () => task);
    try {
      if (existing.dueNotificationId != null) {
        await NotificationService().cancelNotification(existing.dueNotificationId!);
      }
      if (existing.reminderNotificationId != null) {
        await NotificationService().cancelNotification(existing.reminderNotificationId!);
      }
    } catch (e) {
      // ignore cancellation errors
    }

    // Update task data in DB
    await DatabaseService.instance.updateTask(task);

    int? dueNotificationId;
    int? reminderNotificationId;

    // schedule due notification again if needed
    if (task.dueDate.isAfter(DateTime.now())) {
      dueNotificationId = task.id; // reuse id base
      try {
        await NotificationService().scheduleTaskNotification(
          dueNotificationId ?? 0,
          task.title,
          task.description,
          task.dueDate,
        );
      } catch (e) {}
    }

    // schedule reminder if present
    if (task.reminderDateTime != null && task.reminderDateTime!.isAfter(DateTime.now())) {
      reminderNotificationId = (task.id ?? 0) + 2000000;
      try {
        await NotificationService().scheduleTaskNotification(
          reminderNotificationId,
          'Reminder: ${task.title}',
          task.description,
          task.reminderDateTime!,
        );
      } catch (e) {}
    }

    // persist notification ids
    final withIds = task.copyWith(
      dueNotificationId: dueNotificationId,
      reminderNotificationId: reminderNotificationId,
    );
    await DatabaseService.instance.updateTask(withIds);

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = withIds;
      _updateTaskLists(withIds);
      notifyListeners();
    }
    return withIds;
  }

  Future<void> deleteTask(int id) async {
    // cancel notifications related to this task if present
    final task = _tasks.firstWhere((t) => t.id == id, orElse: () => Task(id: id, title: '', description: '', dueDate: DateTime.now()));
    try {
      if (task.dueNotificationId != null) {
        await NotificationService().cancelNotification(task.dueNotificationId!);
      }
      if (task.reminderNotificationId != null) {
        await NotificationService().cancelNotification(task.reminderNotificationId!);
      }
    } catch (e) {
      // ignore
    }

    await DatabaseService.instance.deleteTask(id);
    _tasks.removeWhere((task) => task.id == id);
    _todayTasks.removeWhere((task) => task.id == id);
    _completedTasks.removeWhere((task) => task.id == id);
    _repeatingTasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    await updateTask(task);
  }

  void _updateTaskLists(Task task) {
    // Update today's tasks
    final isToday = task.dueDate.year == DateTime.now().year &&
        task.dueDate.month == DateTime.now().month &&
        task.dueDate.day == DateTime.now().day;
    
    if (isToday) {
      final todayIndex = _todayTasks.indexWhere((t) => t.id == task.id);
      if (todayIndex != -1) {
        _todayTasks[todayIndex] = task;
      } else {
        _todayTasks.add(task);
      }
    } else {
      _todayTasks.removeWhere((t) => t.id == task.id);
    }

    // Update completed tasks
    if (task.isCompleted) {
      if (!_completedTasks.any((t) => t.id == task.id)) {
        _completedTasks.add(task);
      }
    } else {
      _completedTasks.removeWhere((t) => t.id == task.id);
    }

    // Update repeating tasks
    if (task.isRepeating) {
      if (!_repeatingTasks.any((t) => t.id == task.id)) {
        _repeatingTasks.add(task);
      }
    } else {
      _repeatingTasks.removeWhere((t) => t.id == task.id);
    }
  }

  // Subtask operations
  Future<void> addSubTask(SubTask subtask) async {
    final newSubtask = await DatabaseService.instance.createSubTask(subtask);
    final taskIndex = _tasks.indexWhere((t) => t.id == subtask.taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].subTasks ??= [];
      _tasks[taskIndex].subTasks!.add(newSubtask);
      notifyListeners();
    }
  }

  Future<void> updateSubTask(SubTask subtask) async {
    await DatabaseService.instance.updateSubTask(subtask);
    final taskIndex = _tasks.indexWhere((t) => t.id == subtask.taskId);
    if (taskIndex != -1) {
      final subtaskIndex = _tasks[taskIndex].subTasks?.indexWhere(
            (s) => s.id == subtask.id,
          ) ??
          -1;
      if (subtaskIndex != -1) {
        _tasks[taskIndex].subTasks![subtaskIndex] = subtask;
        notifyListeners();
      }
    }
  }

  Future<void> deleteSubTask(int taskId, int subtaskId) async {
    await DatabaseService.instance.deleteSubTask(subtaskId);
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].subTasks?.removeWhere((s) => s.id == subtaskId);
      notifyListeners();
    }
  }
}