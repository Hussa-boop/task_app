import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:task_app/model/task_model.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initCalendarLocale(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text('التقويم')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final box = Hive.box<Task>('tasks');
        final allTasks = box.values.toList();
        Map<DateTime, List<Task>> events = {};
        for (var task in allTasks) {
          final date =
              DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          events.putIfAbsent(date, () => []).add(task);
        }
        return CalendarScaffold(events: events);
      },
    );
  }

  Future<void> _initCalendarLocale() async {
    await initializeDateFormatting('ar', null);
    await Hive.openBox<Task>('tasks');
  }
}

// شاشة التقويم مع جدول ونقاط ملونة
class CalendarScaffold extends StatefulWidget {
  final Map<DateTime, List<Task>> events;
  const CalendarScaffold({super.key, required this.events});

  @override
  State<CalendarScaffold> createState() => _CalendarScaffoldState();
}

class _CalendarScaffoldState extends State<CalendarScaffold> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول المهام'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar<Task>(
                locale: 'ar',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  final d = DateTime(day.year, day.month, day.day);
                  return widget.events[d] ?? [];
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 5,
                  todayDecoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: const TextStyle(color: Colors.redAccent),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                  leftChevronIcon:
                      const Icon(Icons.chevron_left, color: Colors.blue),
                  rightChevronIcon:
                      const Icon(Icons.chevron_right, color: Colors.blue),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        events.length > 5 ? 5 : events.length,
                        (index) {
                          final task = events[index] as Task;
                          Color color;
                          if (task.isCompleted) {
                            color = Colors.green;
                          } else if (task.dueDate.isBefore(DateTime.now())) {
                            color = Colors.red;
                          } else {
                            color = Colors.orange;
                          }
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 1.5, vertical: 4),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  final dayTasks = widget.events[DateTime(selectedDay.year,
                          selectedDay.month, selectedDay.day)] ??
                      [];
                  if (dayTasks.length == 1) {
                    _showTaskDetailsDialog(context, dayTasks.first);
                  } else if (dayTasks.length > 1) {
                    _showTasksListDialog(context, dayTasks);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildTaskListForSelectedDay(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListForSelectedDay() {
    final day = _selectedDay ?? _focusedDay;
    final tasks = widget.events[DateTime(day.year, day.month, day.day)] ?? [];
    if (tasks.isEmpty) {
      return const Center(
          child: Text('لا توجد مهام في هذا اليوم',
              style: TextStyle(fontSize: 16)));
    }
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (context, i) =>
          Divider(height: 16, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final task = tasks[index];
        IconData icon;
        Color color;
        String status;
        if (task.isCompleted) {
          icon = Icons.check_circle;
          color = Colors.green;
          status = 'مكتملة';
        } else if (task.dueDate.isBefore(DateTime.now())) {
          icon = Icons.warning_amber_rounded;
          color = Colors.red;
          status = 'منتهية';
        } else {
          icon = Icons.pending_actions;
          color = Colors.orange;
          status = 'معلقة';
        }
        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(icon, color: color, size: 28),
            title: Text(task.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(task.description!,
                        style: const TextStyle(fontSize: 13)),
                  ),
                Row(
                  children: [
                    Icon(Icons.category_outlined,
                        size: 15, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(task.category,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('hh:mm a').format(task.dueDate),
                    style: const TextStyle(fontSize: 13)),
                Text(status,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            onTap: () => _showTaskDetailsDialog(context, task),
          ),
        );
      },
    );
  }

  void _showTaskDetailsDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : task.dueDate.isBefore(DateTime.now())
                            ? Icons.warning_amber_rounded
                            : Icons.pending_actions,
                    color: task.isCompleted
                        ? Colors.green
                        : task.dueDate.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    task.description!,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ),
              const Divider(height: 24, thickness: 1),
              Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(task.category, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(DateFormat('yyyy-MM-dd - hh:mm a').format(task.dueDate),
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.flag, size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(task.priority.name,
                      style: TextStyle(
                          fontSize: 14,
                          color: task.priority.color,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('إغلاق', style: TextStyle(fontSize: 16)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTasksListDialog(BuildContext context, List<Task> tasks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المهام في هذا اليوم'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                leading: Icon(Icons.task, color: task.priority.color),
                title: Text(task.title),
                subtitle: Text(task.description ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  _showTaskDetailsDialog(context, task);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
