import 'package:flutter/material.dart';
import 'package:task_app/services/setting/preferences_service.dart';
import 'package:task_app/services/setting/them.dart';
import 'package:task_app/services/task_type/controller.dart';
import 'package:task_app/view/home/task_home.dart';
import 'package:task_app/helpers/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_app/model/task_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(PriorityAdapter());
  Hive.registerAdapter(TaskTypeAdapter());
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskTypeController()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => PreferencesService(prefs)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);
    NotificationService.initialize();
    return  MaterialApp(
      theme: ThemeData(
        primarySwatch: createMaterialColor(themeProvider.primaryColor),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: createMaterialColor(themeProvider.primaryColor),
        brightness: Brightness.dark,
      ),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: TaskHomeScreen(),
    );
  }
}// دالة مساعدة لإنشاء MaterialColor من Color
MaterialColor createMaterialColor(Color color) {
  final strengths = <double>[.05];
  final swatch = <int, Color>{};
  final r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  for (final strength in strengths) {
    final ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : 255 - r) * ds).round(),
      g + ((ds < 0 ? g : 255 - g) * ds).round(),
      b + ((ds < 0 ? b : 255 - b) * ds).round(),
      1,
    );
  }

  return MaterialColor(color.value, swatch);
}
