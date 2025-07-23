import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize([BuildContext? context]) async {
    tz.initializeTimeZones();

    // إنشاء قناة إشعارات لأندرويد
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'persistent_task_channel', // يجب أن يكون مختلفاً عن القناة العادية
      'المهام الثابتة',
      description: 'إشعارات المهام الثابتة في شريط الحالة',
      importance: Importance.max,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    // تهيئة الإعدادات
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // إنشاء القناة (لأندرويد 8.0+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showPersistentNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'persistent_task_channel',
      'المهام الثابتة',
      channelDescription: 'إشعارات المهام الثابتة في شريط الحالة',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // إشعار مستمر

      autoCancel: false, // لا يختفي تلقائياً
      showWhen: false, // لا يظهر وقت الإشعار
      enableVibration: false,
      playSound: false,
      visibility: NotificationVisibility.public,
      timeoutAfter: null, // لا ينتهي تلقائياً
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        threadIdentifier: 'persistent_tasks',
      ),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool persistent = false, // هل تريد إشعاراً ثابتاً؟
  }) async {
    final now = DateTime.now();

    if (scheduledDate.isBefore(now)) {
      debugPrint('تم تجاهل الإشعار: الموعد في الماضي');
      return;
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      persistent ? 'persistent_task_channel' : 'task_channel',
      persistent ? 'المهام الثابتة' : 'تذكير بالمهام',
      channelDescription:
          persistent ? 'إشعارات المهام الثابتة' : 'تذكيرات المهام المؤقتة',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: persistent, // جعل الإشعار مستمراً إذا كان مطلوباً
      autoCancel: !persistent,
      showWhen: !persistent,
      enableVibration: !persistent,
      playSound: !persistent,
      visibility: NotificationVisibility.public,
      timeoutAfter: persistent ? null : 3600000, // ساعة واحدة للمؤقتة
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1=Monday ... 7=Sunday
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    // احسب التاريخ القادم لليوم المطلوب
    int daysUntilNext = (weekday - now.weekday) % 7;
    if (daysUntilNext < 0) daysUntilNext += 7;
    final nextDate = DateTime(
            now.year, now.month, now.day, time.hour, time.minute)
        .add(Duration(
            days: daysUntilNext == 0 &&
                    (now.hour > time.hour ||
                        (now.hour == time.hour && now.minute >= time.minute))
                ? 7
                : daysUntilNext));

    final androidDetails = AndroidNotificationDetails(
      'weekly_task_channel',
      'تذكيرات أسبوعية',
      channelDescription: 'إشعارات أسبوعية متكررة للمهام',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      showWhen: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekdayTime(weekday, time),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    int daysUntilNext = (weekday - now.weekday) % 7;
    if (daysUntilNext < 0) daysUntilNext += 7;
    var scheduled = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, time.hour, time.minute)
        .add(Duration(days: daysUntilNext));
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }
}
