// helpers/mock_data.dart
import 'package:flutter/material.dart';
import 'package:task_app/model/task_model.dart';

class MockData {
  static List<TaskType> taskTypes = [
    TaskType(
      id: '1',
      name: 'العمل',
      icon: Icons.work_outline,
      color: Colors.blue,
    ),
    TaskType(
      id: '2',
      name: 'منزل',
      icon: Icons.home_outlined,
      color: Colors.green,
    ),
    TaskType(
      id: '3',
      name: 'تسوق',
      icon: Icons.shopping_cart_outlined,
      color: Colors.orange,
    ),
    TaskType(
      id: '4',
      name: 'لياقة',
      icon: Icons.fitness_center_outlined,
      color: Colors.purple,
    ),
    TaskType(
      id: '5',
      name: 'التعليم',
      icon: Icons.school_outlined,
      color: Colors.teal,
    ),
  ];
  static List<Task> generateMockTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: '1',
        title: 'إنهاء تقرير المشروع',
        description: 'كتابة القسم الثالث من التقرير النهائي',
        dueDate: now.add(const Duration(days: 2)),
        priority: Priority.high,
        category: 'العمل',
        taskType: taskTypes[0],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        taskType: taskTypes[0],        id: '2',
        title: 'شراء مستلزمات المنزل',
        dueDate: now.add(const Duration(hours: 5)),
        priority: Priority.medium,
        category: 'المنزل',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        taskType: taskTypes[0],
        id: '3',
        title: 'مكالمة مع العميل',
        description: 'مناقشة التعديلات المطلوبة',
        dueDate: now.add(const Duration(days: 1)),
        priority: Priority.urgent,
        category: 'العمل',
        createdAt: now.subtract(const Duration(hours: 3)),
        isCompleted: true,
      ),
      Task(
        taskType: taskTypes[0],
        id: '4',
        title: 'قراءة كتاب Flutter',
        dueDate: now.add(const Duration(days: 7)),
        priority: Priority.low,
        category: 'التطوير الشخصي',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Task(
        taskType: taskTypes[0],
        id: '5',
        title: 'تحديث التطبيق',
        description: 'إصلاح الأخطاء في الإصدار 2.0',
        dueDate: now.add(const Duration(days: 3)),
        priority: Priority.high,
        category: 'التطوير',
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }
}