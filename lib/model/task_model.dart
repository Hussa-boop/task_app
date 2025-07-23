import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
part 'task_model.g.dart';

@HiveType(typeId: 2)
class TaskType {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int iconCodePoint;
  @HiveField(3)
  final int colorValue;

  TaskType({
    required this.id,
    required this.name,
    required IconData icon,
    required Color color,
  })  : iconCodePoint = icon.codePoint,
        colorValue = color.value;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
}

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final DateTime dueDate;
  @HiveField(4)
  final bool isCompleted;
  @HiveField(5)
  final Priority priority;
  @HiveField(6)
  final String category;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final TaskType taskType; // إضافة حقل نوع المهمة
  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = Priority.medium,
    required this.category,
    required this.createdAt,
    required this.taskType,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    Priority? priority,
    String? category,
    DateTime? createdAt,
    TaskType? taskType,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      taskType: taskType ?? this.taskType,
    );
  }
}

@HiveType(typeId: 1)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

extension PriorityExtension on Priority {
  String get name {
    switch (this) {
      case Priority.low:
        return 'منخفض';
      case Priority.medium:
        return 'متوسط';
      case Priority.high:
        return 'عالي';
      case Priority.urgent:
        return 'عاجل';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.blue;
      case Priority.medium:
        return Colors.green;
      case Priority.high:
        return Colors.orange;
      case Priority.urgent:
        return Colors.red;
    }
  }
}
