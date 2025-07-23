import 'dart:math';

import 'package:flutter/material.dart';
import 'package:task_app/model/app_category.dart';
import 'package:task_app/model/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  Future<void> saveCategories(List<TaskType> categories) async {
    // لا حاجة للحفظ في Hive أو SharedPreferences عند الاعتماد على AppCategory

    return;
  }

  Future<void> addCategory(TaskType newCategory) async {
    // لا يمكن إضافة فئة جديدة عند الاعتماد على AppCategory الثابت
    return;
  }

  // 1. الحصول على جميع الفئات
  Future<List<TaskType>> getCategories() async {
    return AppCategory.values
        .map((cat) => TaskType(
              id: cat.id,
              name: cat.name,
              icon: cat.icon,
              color: cat.color,
            ))
        .toList();
  }

  // 2. البحث عن فئة محددة
  Future<TaskType?> getCategoryById(String id) async {
    final categories = await getCategories();
    return categories.firstWhere((cat) => cat.id == id);
  }

  // 3. التحقق من وجود فئة بالاسم (حساس للأحرف الكبيرة/الصغيرة)
  Future<bool> categoryExists(String name) async {
    final categories = await getCategories();
    return categories
        .any((cat) => cat.name.toLowerCase() == name.toLowerCase());
  }

  // 4. الحصول على فئات مفضلة (مثال)
  Future<List<TaskType>> getFavoriteCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favoriteCategories') ?? [];
    final categories = await getCategories();
    return categories.where((cat) => favoriteIds.contains(cat.id)).toList();
  }

  // 5. تغيير حالة المفضلة لفئة
  Future<void> toggleFavorite(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favoriteCategories') ?? [];

    if (favorites.contains(categoryId)) {
      favorites.remove(categoryId);
    } else {
      favorites.add(categoryId);
    }

    await prefs.setStringList('favoriteCategories', favorites);
  }

  // 6. تصفية الفئات حسب النوع (مثال)
  Future<List<TaskType>> filterCategoriesByColor(Color color) async {
    final categories = await getCategories();
    return categories.where((cat) => cat.color == color).toList();
  }

  // 7. الحصول على فئات افتراضية (للأغراض العامة)
  Future<List<TaskType>> getDefaultCategories() async {
    return [
      TaskType(
        id: 'default_1',
        name: 'العمل',
        icon: Icons.work_outline,
        color: Colors.blue,
      ),
      TaskType(
        id: 'default_2',
        name: 'المنزل',
        icon: Icons.home_outlined,
        color: Colors.green,
      ),
    ];
  }

  // 8. دمج الفئات الثابتة مع الفئات المخصصة (إذا كانت موجودة)
  Future<List<TaskType>> getAllCategories() async {
    final appCategories = await getCategories();
    final defaultCategories = await getDefaultCategories();
    return [...appCategories, ...defaultCategories];
  }

  // 9. التحقق من صحة الفئة
  Future<bool> validateCategory(TaskType category) async {
    return category.id.isNotEmpty &&
        category.name.isNotEmpty &&
        await getCategoryById(category.id) != null;
  }

  // 10. توليد ألوان متنوعة للفئات الجديدة (مساعد)
  Color generateCategoryColor(List<TaskType> existingCategories) {
    final predefinedColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    final usedColors = existingCategories.map((c) => c.color).toList();

    for (var color in predefinedColors) {
      if (!usedColors.contains(color)) {
        return color;
      }
    }

    return Colors.primaries[Random().nextInt(Colors.primaries.length)];
  }
}
