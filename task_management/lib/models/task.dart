import 'package:intl/intl.dart';

class Task {
  final int? id;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  bool isRepeating;
  List<String>? repeatDays;
  List<SubTask>? subTasks;
  DateTime? reminderDateTime;
  int? dueNotificationId;
  int? reminderNotificationId;
  List<String>? imagePaths;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.isRepeating = false,
    this.repeatDays,
    this.subTasks,
    this.reminderDateTime,
    this.dueNotificationId,
    this.reminderNotificationId,
    this.imagePaths,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': DateFormat('yyyy-MM-dd HH:mm').format(dueDate),
      'isCompleted': isCompleted ? 1 : 0,
      'isRepeating': isRepeating ? 1 : 0,
      'repeatDays': repeatDays?.join(','),
      'reminderDateTime': reminderDateTime != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(reminderDateTime!)
          : null,
      'dueNotificationId': dueNotificationId,
      'reminderNotificationId': reminderNotificationId,
      'imagePaths': imagePaths?.join(';'),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    List<String>? parseImagePaths(dynamic value) {
      if (value == null) return null;
      String str = value.toString();
      List<String> paths = str.split(';');
      return paths.where((p) => p.trim().isNotEmpty).toList();
    }

    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateFormat('yyyy-MM-dd HH:mm').parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      isRepeating: map['isRepeating'] == 1,
      repeatDays: map['repeatDays'] != null
          ? (map['repeatDays'] as String).split(',')
          : null,
      reminderDateTime: map['reminderDateTime'] != null
          ? DateFormat('yyyy-MM-dd HH:mm').parse(map['reminderDateTime'])
          : null,
      dueNotificationId: map['dueNotificationId'],
      reminderNotificationId: map['reminderNotificationId'],
      imagePaths: parseImagePaths(map['imagePaths']),
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isRepeating,
    List<String>? repeatDays,
    List<SubTask>? subTasks,
    DateTime? reminderDateTime,
    int? dueNotificationId,
    int? reminderNotificationId,
    List<String>? imagePaths,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatDays: repeatDays ?? this.repeatDays,
      subTasks: subTasks ?? this.subTasks,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      dueNotificationId: dueNotificationId ?? this.dueNotificationId,
      reminderNotificationId:
          reminderNotificationId ?? this.reminderNotificationId,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  double get progress {
    if (subTasks == null || subTasks!.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }
    int completed =
        subTasks!.where((subtask) => subtask.isCompleted).length;
    return completed / subTasks!.length;
  }
}

class SubTask {
  final int? id;
  final int taskId;
  String title;
  bool isCompleted;

  SubTask({
    this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'],
      taskId: map['taskId'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
    );
  }

  SubTask copyWith({
    int? id,
    int? taskId,
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
