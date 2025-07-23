import 'package:flutter/material.dart';
import 'package:task_app/helpers/mock_data.dart';
import 'package:task_app/model/task_model.dart';
import 'package:task_app/services/category_services.dart';
import 'package:task_app/view/category_add/add_category.dart';
import 'package:task_app/view/home/task_home.dart';
import 'package:task_app/view/calendar/calendar_screen.dart';

import 'package:task_app/view/setting/settings_screen.dart';
import 'package:task_app/view/stats_task/stats_task_screen.dart';
import 'package:task_app/view/category_add/manage_categories.dart';

class MainDrawer extends StatelessWidget {
  final String selectedMenu; // معرف العنصر الحالي
  final CategoryService _categoryService = CategoryService();
  MainDrawer({super.key, required this.selectedMenu});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildMenuItems(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final String userName = 'اسم المستخدم';
    final String userEmail = 'user@email.com';
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[300]!],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[700],
                  child: const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // منطق تغيير الصورة الشخصية (يمكن فتح Dialog أو BottomSheet)
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'مرحباً $userName!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            userEmail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          ...[
            _buildMenuTile(
                context, Icons.home_outlined, 'الصفحة الرئيسية', 'home', () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TaskHomeScreen()),
              );
            }),
            _buildMenuTile(
                context, Icons.calendar_today_outlined, 'التقويم', 'calendar',
                () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarScreen(),
                ),
              );
            }),
            _buildMenuTile(
                context, Icons.analytics_outlined, 'الإحصائيات', 'stats', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TaskStatsScreen()),
              );
            }),
            _buildMenuTile(
                context, Icons.category_outlined, 'الفئات', 'categories', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
              );
            }),
            const Divider(height: 20, thickness: 1),
            _buildMenuTile(
                context, Icons.settings_outlined, 'الإعدادات', 'settings', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }),
            _buildMenuTile(
                context, Icons.help_outline, 'المساعدة والدعم', 'help', () {
              Navigator.pop(context);
              _showHelpDialog(context);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title,
      String menuKey, VoidCallback onTap) {
    final bool highlight = selectedMenu == menuKey;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: ListTile(
        leading: Icon(icon,
            color: highlight ? Colors.blue[700] : Colors.blueGrey[400],
            size: 26),
        title: Text(title,
            style: TextStyle(
                color: highlight ? Colors.blue[700] : Colors.blueGrey[800],
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
        onTap: onTap,
        horizontalTitleGap: 10,
        minLeadingWidth: 0,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإصدار 1.0.0',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.blueGrey[400]),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                tooltip: 'تسجيل الخروج',
                onPressed: () => _showLogoutConfirmation(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<TaskType>> _getCategories() async {
    return await _categoryService.getCategories();
  }



  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة والدعم'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لأي استفسارات أو مشاكل، يرجى التواصل معنا عبر:'),
            SizedBox(height: 10),
            Text('📧 البريد الإلكتروني: support@taskapp.com'),
            SizedBox(height: 5),
            Text('📞 الهاتف: +966123456789'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              // هنا يمكنك إضافة منطق تسجيل الخروج الفعلي
            },
            child:
                const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
