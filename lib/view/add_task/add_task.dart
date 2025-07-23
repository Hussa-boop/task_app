import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:task_app/model/task_model.dart';
import 'package:hive/hive.dart';
import 'package:task_app/services/category_service_dynamic.dart';
import '../../helpers/notification_service.dart';
import '../category_add/add_category.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TaskType? _selectedTaskType;
  Priority _priority = Priority.medium;
  List<TaskType> _categories = [];
  final CategoryServiceDynamic _categoryService = CategoryServiceDynamic();
  List<int> _selectedWeekdays = [];
  static const List<String> _weekdayNames = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _dueDate = task.dueDate;
      _selectedTaskType = task.taskType;
      _priority = task.priority;
    }
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryService.getCategories();
    setState(() {
      _categories = cats;
      // إذا كانت الفئة المختارة لم تعد موجودة (تم حذفها)، أزلها
      if (_selectedTaskType != null &&
          !_categories.any((c) => c.id == _selectedTaskType!.id)) {
        _selectedTaskType = null;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.taskToEdit == null ? 'إضافة مهمة جديدة' : 'تعديل المهمة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTask,
            ),
          ],
        ),
        body: FutureBuilder(
          future: _categoryService.getCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              _categories = snapshot.data!;
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // حقل عنوان المهمة
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان المهمة',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال عنوان للمهمة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // حقل وصف المهمة
                    TextFormField(

                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'وصف المهمة (اختياري)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    // اختيار نوع المهمة
                    _buildTaskTypeSelector(),
                    const SizedBox(height: 16),

                    // اختيار الأولوية
                    _buildPrioritySelector(),
                    const SizedBox(height: 16),

                    // اختيار التاريخ والوقت
                    _buildDateTimeSelector(),
                    const SizedBox(height: 16),
                    _buildWeekdaysSelector(),
                    const SizedBox(height: 24),

                    // زر الحفظ
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveTask,
                        child: const Text('حفظ المهمة'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع المهمة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._categories.map((type) {
              final isSelected = _selectedTaskType?.id == type.id;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon,
                        size: 18,
                        color: isSelected ? Colors.white : type.color),
                    const SizedBox(width: 4),
                    Text(type.name),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTaskType = selected ? type : null;
                  });
                },
                backgroundColor: isSelected ? type.color : Colors.grey[200],
                selectedColor: type.color,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              );
            }).toList(),
            // زر إضافة فئة جديدة
            ActionChip(
              avatar: const Icon(Icons.add, color: Colors.blue),
              label: const Text('إضافة فئة'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCategoryScreen(),
                  ),
                );
                if (result != null && result is TaskType) {
                  await _categoryService.addCategory(result);
                  await _loadCategories();
                  setState(() {
                    _selectedTaskType = result;
                  });
                } else {
                  await _loadCategories();
                }
              },
              backgroundColor: Colors.grey[100],
              labelStyle: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أولوية المهمة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: Priority.values.map((priority) {
            final isSelected = _priority == priority;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _priority = priority;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? priority.color.withOpacity(0.2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: priority.color, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: isSelected ? priority.color : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(priority.name,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الموعد النهائي',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(intl.DateFormat.yMd().format(_dueDate)),
                onPressed: () => _selectDate(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time_outlined),
                label: Text(intl.DateFormat.Hm().format(_dueDate)),
                onPressed: () => _selectTime(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تكرار أسبوعي (اختياري):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (i) {
            final weekday = (i + 1) % 7 + 1; // Monday=1 ... Sunday=7
            return FilterChip(
              label: Text(_weekdayNames[i]),
              selected: _selectedWeekdays.contains(weekday),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekdays.add(weekday);
                  } else {
                    _selectedWeekdays.remove(weekday);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dueDate.hour,
          _dueDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTaskType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار نوع المهمة')),
        );
        return;
      }

      // إنشاء أو تعديل المهمة
      final task = widget.taskToEdit == null
          ? Task(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              dueDate: _dueDate,
              priority: _priority,
              category: _selectedTaskType!.name,
              createdAt: DateTime.now(),
              taskType: _selectedTaskType!,
            )
          : widget.taskToEdit!.copyWith(
              title: _titleController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              dueDate: _dueDate,
              priority: _priority,
              category: _selectedTaskType!.name,
              taskType: _selectedTaskType!,
            );

      try {
        // حفظ المهمة في Hive
        final box = await Hive.openBox<Task>('tasks');
        await box.put(task.id, task);

        // 1. عرض إشعار فوري ثابت في شريط الحالة
        await NotificationService.showPersistentNotification(
          id: task.id.hashCode,
          title: 'مهمة نشطة: ${task.title}',
          body: 'انقر لعرض التفاصيل',
        );

        // 2. جدولة إشعار تذكير قبل الموعد النهائي
        final reminderTime = task.dueDate.subtract(const Duration(minutes: 30));
        if (reminderTime.isAfter(DateTime.now())) {
          await NotificationService.scheduleNotification(
            id: task.id.hashCode + 1, // معرف مختلف للإشعار المزمع
            title: 'تذكير: ${task.title}',
            body: 'موعد التسليم بعد 30 دقيقة',
            scheduledDate: reminderTime,
            persistent: false, // إشعار عادي غير ثابت
          );
        }

        // 3. جدولة إشعار عند الموعد النهائي (ثابت)
        await NotificationService.scheduleNotification(
          id: task.id.hashCode + 2, // معرف مختلف آخر
          title: 'موعد التسليم: ${task.title}',
          body: 'انتهى الوقت المحدد لإكمال المهمة',
          scheduledDate: task.dueDate,
          persistent: true, // إشعار ثابت في الشريط
        );

        // 4. إذا تم اختيار أيام تكرار أسبوعي، جدولة إشعار مكرر لكل يوم
        if (_selectedWeekdays.isNotEmpty) {
          for (final weekday in _selectedWeekdays) {
            await NotificationService.scheduleWeeklyNotification(
              id: task.id.hashCode + 100 + weekday,
              title: 'تذكير أسبوعي: ${task.title}',
              body: 'اليوم المحدد لهذه المهمة',
              weekday: weekday,
              time: TimeOfDay.fromDateTime(_dueDate),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, task);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
          );
        }
      }
    }
  }
}
