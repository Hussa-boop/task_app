import 'package:flutter/material.dart';
import 'package:task_app/services/setting/preferences_service.dart';
import 'package:task_app/view/drawer/main_darwer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../helpers/notification_service.dart';
import '../../services/setting/them.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PreferencesService _prefsService;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  Color _primaryColor = Colors.blue;
  final List<Color> _colorOptions = [
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
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _prefsService = PreferencesService(prefs);

    setState(() {
      _notificationsEnabled = _prefsService.notificationsEnabled;
      _darkModeEnabled = _prefsService.darkModeEnabled;
      _primaryColor = Color(_prefsService.primaryColorValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MainDrawer(selectedMenu: 'settings'),
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'الإعدادات العامة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSettingsSwitch(
            title: 'تمكين الإشعارات',
            value: _notificationsEnabled,
            icon: Icons.notifications_active_outlined,
            onChanged: (value) async {
              await _prefsService.setNotificationsEnabled(value);
              setState(() => _notificationsEnabled = value);

              if (!value) {
                // إلغاء جميع الإشعارات عند تعطيلها
                await NotificationService.cancelAllNotifications();
              }
            },
          ),
          _buildSettingsSwitch(
            title: 'الوضع الليلي',
            value: _darkModeEnabled,
            icon: Icons.dark_mode_outlined,
            onChanged: (value) async {
              await _prefsService.setDarkModeEnabled(value);
              setState(() => _darkModeEnabled = value);
              _updateTheme(context);
            },
          ),
          const Divider(height: 30),
          const Text(
            'المظهر',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSettingsOption(
            title: 'اختيار لون التطبيق',
            icon: Icons.color_lens_outlined,
            trailing: CircleAvatar(
              backgroundColor: _primaryColor,
              radius: 12,
            ),
            onTap: () => _showThemeColorPicker(context),
          ),
          const Divider(height: 30),
          const Text(
            'حول التطبيق',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSettingsOption(
            title: 'سياسة الخصوصية',
            icon: Icons.privacy_tip_outlined,
            onTap: () {

            },
            // onTap: () => _openUrl('https://example.com/privacy'),
          ),
          _buildSettingsOption(
            title: 'شروط الاستخدام',
            icon: Icons.description_outlined,
            onTap: () {

            },
            // onTap: () => _openUrl('https://example.com/terms'),
          ),
          _buildSettingsOption(
            title: 'تقييم التطبيق',
            icon: Icons.star_border_outlined,
            onTap: () {

            },
            // onTap: _rateApp,
          ),
          _buildSettingsOption(
            title: 'إصدار التطبيق',
            icon: Icons.info_outline,
            trailing: Text(
              '1.0.0',
              style: TextStyle(color: Colors.grey[600]),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required String title,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSettingsOption({
    required String title,
    required IconData icon,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }

  void _showThemeColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر لون التطبيق'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            children: _colorOptions
                .map((color) => _buildColorOption(color))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () async {
          await _prefsService.setPrimaryColor(color);
          setState(() => _primaryColor = color);
          _updateTheme(context);
          Navigator.pop(context);
        },
        child: CircleAvatar(
          backgroundColor: color,
          radius: 20,
          child: color == _primaryColor
              ? const Icon(Icons.check, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  void _updateTheme(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setTheme(
      darkMode: _darkModeEnabled,
      primaryColor: _primaryColor,
    );
  }

  // Future<void> _openUrl(String url) async {
  //   try {
  //     if (await canLaunch(url)) {
  //       await launch(url);
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('لا يمكن فتح الرابط: $e')),
  //     );
  //   }
  // }
  //
  // Future<void> _rateApp() async {
  //   final package = await PackageInfo.fromPlatform();
  //   final url = Uri.parse(
  //     'https://play.google.com/store/apps/details?id=${package.packageName}',
  //   );
  //
  //   if (await canLaunch(url.toString())) {
  //     await launch(url.toString());
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('لا يمكن فتح متجر التطبيقات')),
  //     );
  //   }
  // }
}
