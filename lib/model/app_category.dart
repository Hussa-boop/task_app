// models/app_categories.dart
import 'package:flutter/material.dart';

enum AppCategory {
  work,
  home,
  shopping,
  personal,
  health,
  education,
}

extension AppCategoryExtension on AppCategory {
  String get id {
    switch (this) {
      case AppCategory.work:
        return 'work';
      case AppCategory.home:
        return 'home';
      case AppCategory.shopping:
        return 'shopping';
      case AppCategory.personal:
        return 'personal';
      case AppCategory.health:
        return 'health';
      case AppCategory.education:
        return 'education';
    }
  }

  String get name {
    switch (this) {
      case AppCategory.work:
        return 'العمل';
      case AppCategory.home:
        return 'المنزل';
      case AppCategory.shopping:
        return 'التسوق';
      case AppCategory.personal:
        return 'شخصي';
      case AppCategory.health:
        return 'الصحة';
      case AppCategory.education:
        return 'التعليم';
    }
  }

  IconData get icon {
    switch (this) {
      case AppCategory.work:
        return Icons.work_outlined;
      case AppCategory.home:
        return Icons.home_outlined;
      case AppCategory.shopping:
        return Icons.shopping_cart_outlined;
      case AppCategory.personal:
        return Icons.person_outlined;
      case AppCategory.health:
        return Icons.favorite_outline;
      case AppCategory.education:
        return Icons.school_outlined;
    }
  }

  Color get color {
    switch (this) {
      case AppCategory.work:
        return Colors.blue;
      case AppCategory.home:
        return Colors.green;
      case AppCategory.shopping:
        return Colors.orange;
      case AppCategory.personal:
        return Colors.purple;
      case AppCategory.health:
        return Colors.red;
      case AppCategory.education:
        return Colors.indigo;
    }
  }
}