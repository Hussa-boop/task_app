import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:task_app/model/task_model.dart';
import 'package:task_app/view/add_task/add_task.dart';
import 'package:task_app/view/drawer/main_darwer.dart';
import 'package:hive/hive.dart';
import '../../helpers/mock_data.dart';
import 'package:task_app/model/app_category.dart';
import 'package:provider/provider.dart';
import '../../services/setting/them.dart';
import '../../helpers/notification_service.dart';
import 'package:task_app/services/category_service_dynamic.dart';

class TaskHomeScreen extends StatelessWidget {
  const TaskHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return const _TaskHomeScreenBody();
      },
    );
  }
}

class _TaskHomeScreenBody extends StatefulWidget {
  const _TaskHomeScreenBody();

  @override
  State<_TaskHomeScreenBody> createState() => _TaskHomeScreenBodyState();
}

class _TaskHomeScreenBodyState extends State<_TaskHomeScreenBody>
    with TickerProviderStateMixin {
  List<Task> tasks = MockData.generateMockTasks();
  late AnimationController _timerController;

  List<TaskType> _categoryFilters = [];
  TaskType? _selectedCategory;
  Priority? _selectedPriority;
  bool? _showCompleted;

  DateTime? _selectedDate; // تاريخ محدد
  DateTimeRange? _selectedDateRange; // فترة زمنية

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _loadTasksFromHive();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  List<Task> _searchTasks(String query, List<Task> tasksToSearch) {
    if (query.isEmpty) return tasksToSearch;

    final queryLower = query.toLowerCase();

    return tasksToSearch.where((task) {
      final titleMatch = task.title.toLowerCase().contains(queryLower);
      final descMatch =
          task.description?.toLowerCase().contains(queryLower) ?? false;
      final categoryMatch = task.category.toLowerCase().contains(queryLower);
      final typeMatch = task.taskType.name.toLowerCase().contains(queryLower);
      final priorityMatch =
          task.priority.name.toLowerCase().contains(queryLower);

      return titleMatch ||
          descMatch ||
          categoryMatch ||
          typeMatch ||
          priorityMatch;
    }).toList();
  }

  Future<void> _loadTasksFromHive() async {
    var box = await Hive.openBox<Task>('tasks');
    setState(() {
      tasks = box.values.toList();
    });
  }

  Future<void> _loadCategoryFilters() async {
    final cats = await CategoryServiceDynamic().getCategories();
    setState(() {
      _categoryFilters = cats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox<Task>('tasks'),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final box = Hive.box<Task>('tasks');
        tasks = box.values.toList();
        var filteredTasks = tasks;
        // فلتر الفئة
        if (_selectedCategory != null) {
          filteredTasks = filteredTasks
              .where((task) => task.taskType.id == _selectedCategory!.id)
              .toList();
        }
        // فلتر الأولوية
        if (_selectedPriority != null) {
          filteredTasks = filteredTasks
              .where((task) => task.priority == _selectedPriority)
              .toList();
        }
        // فلتر الحالة
        if (_showCompleted != null) {
          filteredTasks = filteredTasks
              .where((task) => task.isCompleted == _showCompleted)
              .toList();
        }
        // فلتر التاريخ
        if (_selectedDate != null) {
          filteredTasks = filteredTasks
              .where((task) =>
                  task.dueDate.year == _selectedDate!.year &&
                  task.dueDate.month == _selectedDate!.month &&
                  task.dueDate.day == _selectedDate!.day)
              .toList();
        } else if (_selectedDateRange != null) {
          filteredTasks = filteredTasks
              .where((task) =>
                  task.dueDate.isAfter(_selectedDateRange!.start
                      .subtract(const Duration(days: 1))) &&
                  task.dueDate.isBefore(
                      _selectedDateRange!.end.add(const Duration(days: 1))))
              .toList();
        }
        final upcomingTasks = filteredTasks
            .where((task) => !task.isCompleted)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final completedTasks =
            filteredTasks.where((task) => task.isCompleted).toList();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.grey[100],
            drawer: MainDrawer(selectedMenu: 'home'),
            appBar: AppBar(
              title: const Text('المهام'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  tooltip: 'فلاتر متقدمة',
                  onPressed: () => _showFiltersBox(context),
                ),
              ],
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
            body: _buildTaskBody(upcomingTasks, completedTasks),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddTaskScreen()),
                );
                if (result != null && result is Task) {
                  setState(() {
                    tasks.add(result);
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskBody(List<Task> upcomingTasks, List<Task> completedTasks) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.all(12),
      child: RefreshIndicator(
        backgroundColor: Colors.blue,
        onRefresh: () async {
          await _loadTasksFromHive();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            // المهام القادمة
            SliverPadding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'المهام القادمة (${upcomingTasks.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                ),
              ),
            ),
            if (upcomingTasks.isEmpty)
              SliverToBoxAdapter(
                child:
                    _buildEmptyState('لا توجد مهام حالية', Icons.task_outlined),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTaskItem(upcomingTasks[index]),
                  childCount: upcomingTasks.length,
                ),
              ),
            // المهام المكتملة
            SliverPadding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'المهام المكتملة (${completedTasks.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                ),
              ),
            ),
            if (completedTasks.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(
                    'لا توجد مهام مكتملة', Icons.check_circle_outline),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTaskItem(completedTasks[index]),
                  childCount: completedTasks.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final bgGradient = LinearGradient(
      colors: [
        task.taskType.color.withOpacity(0.12),
        Colors.white,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final borderColor = task.isCompleted ? Colors.green : Colors.blue;

    return Directionality(
        textDirection: TextDirection.rtl,
        child: Dismissible(
            key: Key(task.id),
            direction: DismissDirection.horizontal,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.edit, color: Colors.blue),
            ),
            secondaryBackground: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                return await _showDeleteConfirmation(context, task);
              } else if (direction == DismissDirection.startToEnd) {
                _editTask(context, task);
                return false;
              }
              return false;
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                _deleteTask(task);
              }
            },
            child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: borderColor, width: 1.2),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showTaskDetails(context, task),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: bgGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  task.taskType.color.withOpacity(0.18),
                              child: Icon(task.taskType.icon,
                                  color: task.taskType.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: task.isCompleted
                                          ? Colors.green[800]
                                          : Colors.blue[900],
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!task.isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: task.priority.color.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.flag_outlined,
                                        size: 16, color: task.priority.color),
                                    const SizedBox(width: 3),
                                    Text(
                                      task.priority.name,
                                      style: TextStyle(
                                        color: task.priority.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            task.description!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.category_outlined,
                                    size: 16, color: task.taskType.color),
                                const SizedBox(width: 4),
                                Text(
                                  task.taskType.name,
                                  style: TextStyle(
                                    color: task.taskType.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.blueGrey),
                                const SizedBox(width: 4),
                                Text(
                                  intl.DateFormat('MMM dd, hh:mm a')
                                      .format(task.dueDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (!task.isCompleted) ...[
                                  const SizedBox(width: 8),
                                  AnimatedBuilder(
                                    animation: _timerController,
                                    builder: (context, child) {
                                      final now = DateTime.now();
                                      final timeLeft =
                                          task.dueDate.difference(now);
                                      final isOverdue = timeLeft.isNegative;

                                      String timeLeftText;
                                      if (timeLeft.isNegative) {
                                        final overdueDuration =
                                            now.difference(task.dueDate);
                                        timeLeftText = overdueDuration.inDays >
                                                0
                                            ? 'متأخرة ${overdueDuration.inDays} يوم'
                                            : overdueDuration.inHours > 0
                                                ? 'متأخرة ${overdueDuration.inHours} ساعة'
                                                : 'متأخرة ${overdueDuration.inMinutes} دقيقة';
                                      } else {
                                        timeLeftText = timeLeft.inDays > 0
                                            ? 'باقي ${timeLeft.inDays} يوم'
                                            : timeLeft.inHours > 0
                                                ? 'باقي ${timeLeft.inHours} ساعة'
                                                : 'باقي ${timeLeft.inMinutes} دقيقة';
                                      }

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isOverdue
                                              ? Colors.red.withOpacity(0.15)
                                              : Colors.blue.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isOverdue ? 'متأخرة' : timeLeftText,
                                          style: TextStyle(
                                            color: isOverdue
                                                ? Colors.red
                                                : Colors.blue,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        if (!task.isCompleted)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: Colors.blue,
                                tooltip: 'تعديل',
                                onPressed: () => _editTask(context, task),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                color: Colors.green,
                                tooltip: 'إنهاء',
                                onPressed: () => _toggleTaskCompletion(task),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                tooltip: 'حذف',
                                onPressed: () =>
                                    _confirmDeleteTask(context, task),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ))));
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, Task task) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف المهمة "${task.title}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _confirmDeleteTask(BuildContext context, Task task) async {
    final shouldDelete = await _showDeleteConfirmation(context, task);
    if (shouldDelete) {
      _deleteTask(task);
    }
  }

  void _deleteTask(Task task) async {
    var box = await Hive.openBox<Task>('tasks');
    await box.delete(task.id);
    // إلغاء تثبيت إشعار المهمة عند حذفها
    await NotificationService.cancelNotification(task.id.hashCode);
    await NotificationService.cancelNotification(task.id.hashCode + 2);
    setState(() {
      tasks.removeWhere((t) => t.id == task.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف المهمة "${task.title}"'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () async {
            await box.put(task.id, task);
            setState(() {
              tasks.add(task);
            });
          },
        ),
      ),
    );
  }

  void _editTask(BuildContext context, Task task) async {
    final editedTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(taskToEdit: task),
      ),
    );
    if (editedTask != null && editedTask is Task) {
      var box = await Hive.openBox<Task>('tasks');
      await box.put(editedTask.id, editedTask);
      setState(() {
        final index = tasks.indexWhere((t) => t.id == editedTask.id);
        if (index != -1) {
          tasks[index] = editedTask;
        }
      });
    }
  }

  void _toggleTaskCompletion(Task task) async {
    var box = await Hive.openBox<Task>('tasks');
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await box.put(updatedTask.id, updatedTask);
    // إلغاء تثبيت إشعار المهمة عند اكتمالها
    if (updatedTask.isCompleted) {
      await NotificationService.cancelNotification(updatedTask.id.hashCode);
      await NotificationService.cancelNotification(updatedTask.id.hashCode + 2);
    }
    setState(() {
      tasks = tasks.map((t) {
        if (t.id == updatedTask.id) {
          return updatedTask;
        }
        return t;
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedTask.isCompleted
              ? 'تم وضع المهمة "${updatedTask.title}" كمكتملة'
              : 'تم وضع المهمة "${updatedTask.title}" كغير مكتملة',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFiltersBox(BuildContext context) async {
    await _loadCategoryFilters();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 16,
          right: 16,
        ),
        child: _buildFiltersBoxContent(),
      ),
    );
  }

  Widget _buildFiltersBoxContent() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return SingleChildScrollView(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('تصفية المهام',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // فلتر الفئة
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setModalState(() => _selectedCategory = null);
                        setState(() {});
                      },
                    ),
                    ..._categoryFilters.map((cat) => FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, size: 16, color: cat.color),
                              const SizedBox(width: 4),
                              Text(cat.name),
                            ],
                          ),
                          selected: _selectedCategory?.id == cat.id,
                          selectedColor: cat.color.withOpacity(0.2),
                          onSelected: (selected) {
                            setModalState(
                                () => _selectedCategory = selected ? cat : null);
                            setState(() {});
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // فلتر الأولوية
                    FilterChip(
                      label: const Text('كل الأولويات'),
                      selected: _selectedPriority == null,
                      onSelected: (selected) {
                        setModalState(() => _selectedPriority = null);
                        setState(() {});
                      },
                    ),
                    ...Priority.values.map((priority) => FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_outlined,
                                  size: 16, color: priority.color),
                              const SizedBox(width: 4),
                              Text(priority.name),
                            ],
                          ),
                          selected: _selectedPriority == priority,
                          selectedColor: priority.color.withOpacity(0.2),
                          onSelected: (selected) {
                            setModalState(() =>
                                _selectedPriority = selected ? priority : null);
                            setState(() {});
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // فلتر الحالة
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _showCompleted == null,
                      onSelected: (selected) {
                        setModalState(() => _showCompleted = null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('مكتملة'),
                      selected: _showCompleted == true,
                      selectedColor: Colors.green.withOpacity(0.2),
                      onSelected: (selected) {
                        setModalState(
                            () => _showCompleted = selected ? true : null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('معلقة'),
                      selected: _showCompleted == false,
                      selectedColor: Colors.orange.withOpacity(0.2),
                      onSelected: (selected) {
                        setModalState(
                            () => _showCompleted = selected ? false : null);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // فلتر التاريخ
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_selectedDate != null
                            ? intl.DateFormat('yyyy/MM/dd').format(_selectedDate!)
                            : _selectedDateRange != null
                                ? '${intl.DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${intl.DateFormat('MM/dd').format(_selectedDateRange!.end)}'
                                : 'تصفية حسب التاريخ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[900],
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDateRange: _selectedDateRange,
                            locale: const Locale('ar'),
                          );
                          if (picked != null) {
                            setModalState(() {
                              _selectedDate = null;
                              _selectedDateRange = picked;
                            });
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    if (_selectedDate != null || _selectedDateRange != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'مسح التاريخ',
                        onPressed: () {
                          setModalState(() {
                            _selectedDate = null;
                            _selectedDateRange = null;
                          });
                          setState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskDetailsSheet(task: task),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بحث في المهام'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'ابحث عن مهمة...',
            border: OutlineInputBorder(),
          ),
          onChanged: (query) {
            // يمكن تطبيق البحث هنا
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              // تطبيق البحث
              Navigator.pop(context);
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }
}

class TaskDetailsSheet extends StatelessWidget {
  final Task task;
  final Color primaryColor =
      Colors.blue; // يمكن تغيير اللون الأساسي حسب التصميم

  const TaskDetailsSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.task_outlined, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description Card
            if (task.description != null) ...[
              Card(
                elevation: 0,
                color: Colors.grey[50],
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_outlined,
                          size: 20, color: Colors.grey[500]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.description!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Details Section
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.category_outlined,
                      label: 'الفئة',
                      value: task.category,
                      iconColor: Colors.purple,
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow(
                      icon: Icons.priority_high,
                      label: 'الأولوية',
                      value: task.priority.name,
                      iconColor: task.priority.color,
                      valueColor: task.priority.color,
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'تاريخ الإنشاء',
                      value: intl.DateFormat('yyyy/MM/dd - hh:mm a')
                          .format(task.createdAt),
                      iconColor: Colors.orange,
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow(
                      icon: Icons.access_time_filled,
                      label: 'الموعد النهائي',
                      value: intl.DateFormat('yyyy/MM/dd - hh:mm a')
                          .format(task.dueDate),
                      iconColor: Colors.red[400],
                      valueColor: task.dueDate.isBefore(DateTime.now())
                          ? Colors.red
                          : Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            // Buttons Section
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('إغلاق'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('تعديل المهمة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskScreen(taskToEdit: task),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? primaryColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
