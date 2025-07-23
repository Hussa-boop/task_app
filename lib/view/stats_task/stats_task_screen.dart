import 'package:flutter/material.dart';
import 'package:task_app/helpers/mock_data.dart';
import 'package:task_app/model/task_model.dart';
import 'package:task_app/view/drawer/main_darwer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_app/services/category_service_dynamic.dart';
import 'package:task_app/view/category_add/manage_categories.dart';

class TaskStatsScreen extends StatefulWidget {
  const TaskStatsScreen({super.key});

  @override
  State<TaskStatsScreen> createState() => _TaskStatsScreenState();
}

class _TaskStatsScreenState extends State<TaskStatsScreen> {
  late Future<List<TaskType>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryServiceDynamic().getCategories();
  }

  Future<void> _refreshCategories() async {
    setState(() {
      _categoriesFuture = CategoryServiceDynamic().getCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        Hive.openBox<Task>('tasks'),
        _categoriesFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final tasksBox = Hive.box<Task>('tasks');
        final tasks = tasksBox.values.toList();
        final completedTasks = tasks.where((task) => task.isCompleted).length;
        final pendingTasks = tasks.length - completedTasks;
        final overdueTasks = tasks
            .where((task) =>
                !task.isCompleted && task.dueDate.isBefore(DateTime.now()))
            .length;
        final categories = snapshot.data![1] as List<TaskType>;

        return Scaffold(
          drawer: MainDrawer(selectedMenu: 'stats'),
          appBar: AppBar(
            title: const Text('إحصائيات المهام'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatsCard(
                  context,
                  title: 'نظرة عامة',
                  children: [
                    _buildStatItem(
                        'المهام الكلية', tasks.length.toString(), Icons.task),
                    _buildStatItem('المكتملة', completedTasks.toString(),
                        Icons.check_circle),
                    _buildStatItem('المعلقة', pendingTasks.toString(),
                        Icons.pending_actions),
                    _buildStatItem('المتأخرة', overdueTasks.toString(),
                        Icons.warning_amber),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatsCard(
                  context,
                  title: 'التوزيع حسب الأولوية',
                  children: [
                    _buildPriorityStat(Priority.low, tasks),
                    _buildPriorityStat(Priority.medium, tasks),
                    _buildPriorityStat(Priority.high, tasks),
                    _buildPriorityStat(Priority.urgent, tasks),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatsCard(
                  context,
                  title: 'التوزيع حسب الفئة',
                  children: [
                    ...categories.map((type) {
                      final count = tasks
                          .where((task) => task.category == type.name)
                          .length;
                      return _buildCategoryStat(type, count, tasks.length);
                    }).toList(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('إدارة الفئات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[900],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ManageCategoriesScreen(),
                            ),
                          );
                          await _refreshCategories();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityStat(Priority priority, List<Task> tasks) {
    final count = tasks.where((task) => task.priority == priority).length;
    final safeValue = tasks.isEmpty ? 0.0 : count / tasks.length;
    final percentage =
        tasks.isEmpty ? '0.0' : (safeValue * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 24,
            color: priority.color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(priority.name),
                LinearProgressIndicator(
                  value: safeValue,
                  backgroundColor: Colors.grey[200],
                  color: priority.color,
                  minHeight: 4,
                ),
              ],
            ),
          ),
          Text('$percentage%'),
        ],
      ),
    );
  }

  Widget _buildCategoryStat(TaskType type, int count, int total) {
    final safeValue = total == 0 ? 0.0 : count / total;
    final percentage =
        total == 0 ? '0.0' : (safeValue * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(type.icon, size: 24, color: type.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.name),
                LinearProgressIndicator(
                  value: safeValue,
                  backgroundColor: Colors.grey[200],
                  color: type.color,
                  minHeight: 4,
                ),
              ],
            ),
          ),
          Text('$percentage%'),
        ],
      ),
    );
  }
}
