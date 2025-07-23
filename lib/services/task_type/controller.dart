import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:task_app/model/task_model.dart';


class TaskTypeController with ChangeNotifier {
  late Box<TaskType> _taskTypesBox;
  List<TaskType> _taskTypes = [];
  bool _isLoading = false;
  String? _error;

  List<TaskType> get taskTypes => _taskTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();

      _taskTypesBox = await Hive.openBox<TaskType>('task_types');
      _taskTypes = _taskTypesBox.values.toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTaskType({
    required String name,
    required IconData icon,
    required Color color,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // التحقق من عدم وجود فئة بنفس الاسم
      if (_taskTypes.any((type) => type.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('نوع المهمة موجود مسبقاً');
      }

      final newTaskType = TaskType(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        icon: icon,
        color: color,
      );

      await _taskTypesBox.put(newTaskType.id, newTaskType);
      _taskTypes = _taskTypesBox.values.toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTaskType({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final existingType = _taskTypes.firstWhere((type) => type.id == id);
      final updatedTaskType = TaskType(
        id: id,
        name: name,
        icon: icon,
        color: color,
      );

      await _taskTypesBox.put(id, updatedTaskType);
      _taskTypes = _taskTypesBox.values.toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTaskType(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _taskTypesBox.delete(id);
      _taskTypes = _taskTypesBox.values.toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  TaskType? getTaskTypeById(String id) {
    try {
      return _taskTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> reset() async {
    _taskTypes = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}