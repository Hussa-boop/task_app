import 'package:flutter/material.dart';
import 'package:task_app/model/task_model.dart';
import 'package:task_app/services/category_service_dynamic.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final CategoryServiceDynamic _service = CategoryServiceDynamic();
  List<TaskType> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await _service.getCategories();
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;
    final result = await showDialog<TaskType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة فئة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الفئة'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('اللون:'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('اختر لوناً'),
                        content: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            children: Colors.primaries
                                .map((c) => GestureDetector(
                                      onTap: () => Navigator.pop(context, c),
                                      child: CircleAvatar(backgroundColor: c),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    );
                    if (color != null) setState(() => selectedColor = color);
                  },
                  child: CircleAvatar(backgroundColor: selectedColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('الأيقونة:'),
                const SizedBox(width: 8),
                DropdownButton<IconData>(
                  value: selectedIcon,
                  items: [
                    Icons.category,
                    Icons.work_outline,
                    Icons.home_outlined,
                    Icons.shopping_cart,
                    Icons.person,
                    Icons.health_and_safety,
                    Icons.school,
                  ]
                      .map((icon) => DropdownMenuItem(
                            value: icon,
                            child: Icon(icon),
                          ))
                      .toList(),
                  onChanged: (icon) {
                    if (icon != null) setState(() => selectedIcon = icon);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              final cat = TaskType(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                icon: selectedIcon,
                color: selectedColor,
              );
              Navigator.pop(context, cat);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _service.addCategory(result);
      _load();
    }
  }

  Future<void> _deleteCategory(TaskType cat) async {
    await _service.deleteCategory(cat.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الفئات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _categories.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                return ListTile(
                  leading: Icon(cat.icon, color: cat.color),
                  title: Text(cat.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCategory(cat),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}
