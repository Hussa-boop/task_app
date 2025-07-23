import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:task_app/model/task_model.dart';

class CategoryServiceDynamic {
  static const String boxName = 'categories';

  Future<Box<TaskType>> _openBox() async {
    return await Hive.openBox<TaskType>(boxName);
  }

  Future<List<TaskType>> getCategories() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<void> addCategory(TaskType category) async {
    final box = await _openBox();
    await box.put(category.id, category);
  }

  Future<void> updateCategory(TaskType category) async {
    final box = await _openBox();
    await box.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<TaskType?> getCategoryById(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  Future<bool> categoryExists(String name) async {
    final cats = await getCategories();
    return cats.any((cat) => cat.name.toLowerCase() == name.toLowerCase());
  }
}
