import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final dynamic localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.toString()));

    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS, you might want to add DarwinInitializationSettings if targeting iOS later
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<void> requestPermission(BuildContext context) async {
    final status = await Permission.notification.request();

    // Android 12+ requires EXACT_ALARM permission separately for precise scheduling
    if (await Permission.scheduleExactAlarm.isDenied) {
      if (context.mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Izin Alarm Dibutuhkan'),
            content: const Text(
                'Untuk mengingatkan kamu minum air tepat waktu, aplikasi membutuhkan izin Alarm & Reminders. Arahkan ke Settings untuk mengaktifkannya?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Nanti')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Buka Settings')),
            ],
          ),
        );
        if (confirm == true) {
          await openAppSettings();
        }
      }
    }
  }

  // Atomic counter for unique integer ID
  Future<int> _getAndIncrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('notification_counter') ?? 1;
    await prefs.setInt('notification_counter', current + 1);
    return current;
  }

  // Get or Create integer ID from UUID
  Future<int> _getNotificationId(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    final mapStr = prefs.getString('notification_uuid_map') ?? '{}';
    final Map<String, dynamic> map = jsonDecode(mapStr);

    if (map.containsKey(uuid)) {
      return map[uuid] as int;
    }

    final newId = await _getAndIncrementCounter();
    map[uuid] = newId;
    await prefs.setString('notification_uuid_map', jsonEncode(map));
    return newId;
  }

  Future<void> scheduleReminder(String uuid, String timeStr, int intervalMinutes) async {
    final int baseId = await _getNotificationId(uuid);
    
    // Parse timeStr "HH:mm:ss"
    final parts = timeStr.split(':');
    final int targetHour = int.parse(parts[0]);
    final int targetMinute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime firstScheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, targetHour, targetMinute);

    if (firstScheduledDate.isBefore(now)) {
      firstScheduledDate = firstScheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'water_reminder_channel',
      'Water Reminders',
      channelDescription: 'Channel untuk pengingat minum air',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Pre-schedule for the next 24 hours
    // How many times does the interval fit in 24 hours?
    final int occurrences = (24 * 60) ~/ intervalMinutes;
    
    // Schedule multiple notifications forward
    for (int i = 0; i < occurrences; i++) {
      // Offset ID so they don't overwrite each other, but can still be cancelled
      // baseId * 1000 + i (Assuming max 1000 occurrences per reminder which is true since interval >= 15)
      final int scheduleId = (baseId * 1000) + i;
      final scheduleTime = firstScheduledDate.add(Duration(minutes: intervalMinutes * i));

      await _notificationsPlugin.zonedSchedule(
        id: scheduleId,
        title: 'Waktunya Minum Air! 💧',
        body: 'Jangan lupa penuhi target hidrasimu hari ini.',
        scheduledDate: scheduleTime,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelReminder(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    final mapStr = prefs.getString('notification_uuid_map') ?? '{}';
    final Map<String, dynamic> map = jsonDecode(mapStr);

    if (map.containsKey(uuid)) {
      final int baseId = map[uuid] as int;
      // Cancel all pre-scheduled items for this baseId
      // We assume max 1000 occurrences as before
      for (int i = 0; i < 100; i++) { // Cancel up to 100 slots just to be safe (24*60/15 = 96)
        await _notificationsPlugin.cancel(id: (baseId * 1000) + i);
      }
      map.remove(uuid);
      await prefs.setString('notification_uuid_map', jsonEncode(map));
    }
  }

  // Reschedule from cached list
  Future<void> rescheduleAll(List<dynamic> reminders) async {
    // First cancel all existing to avoid duplicates
    await _notificationsPlugin.cancelAll();

    for (final r in reminders) {
      final uuid = r['id'] as String;
      final timeStr = r['reminderTime'] as String;
      final interval = r['intervalMinutes'] as int;
      await scheduleReminder(uuid, timeStr, interval);
    }
  }
}
