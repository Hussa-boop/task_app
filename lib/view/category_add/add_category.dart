// view/screens/add_category_screen.dart
import 'package:flutter/material.dart';
import 'package:task_app/model/task_model.dart';
import 'package:task_app/services/category_services.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final CategoryService _categoryService = CategoryService();

  IconData _selectedIcon = Icons.category_outlined;
  Color _selectedColor = Colors.blue;

  final List<IconData> _icons = [
    Icons.work_outlined,
    Icons.home_outlined,
    Icons.shopping_cart_outlined,
    Icons.fitness_center_outlined,
    Icons.school_outlined,
    Icons.medical_services_outlined,
    Icons.celebration_outlined,
    Icons.drive_eta_outlined,
  ];

  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة فئة جديدة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCategory,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم الفئة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'اختر أيقونة للفئة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _icons.map((icon) {
                    return IconButton(
                      icon: Icon(icon),
                      color: _selectedIcon == icon ? _selectedColor : Colors.grey,
                      onPressed: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'اختر لوناً للفئة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveCategory,
                    child: const Text('حفظ الفئة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final newCategory = TaskType(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        icon: _selectedIcon,
        color: _selectedColor,
      );

      await _categoryService.addCategory(newCategory);

      if (mounted) {
        print(newCategory.name);
        Navigator.pop(context, newCategory);
      }
    }
  }
}