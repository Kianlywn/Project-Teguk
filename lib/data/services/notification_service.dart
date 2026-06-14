import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
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

  final List<String> _hydrationTips = [
    "Jangan lupa penuhi target hidrasimu hari ini!",
    "Air putih membantu menjaga konsentrasi. Sudah minum?",
    "Merasa lelah? Segelas air mungkin yang kamu butuhkan.",
    "Kulit cerah dimulai dari hidrasi yang cukup dari dalam.",
    "Tambah asupan airmu jika beraktivitas berat atau berkeringat.",
    "Minum sedikit-sedikit tapi sering lebih baik daripada langsung banyak.",
    "Bawa selalu botol minummu ke mana pun pergi.",
    "Dehidrasi ringan dapat memicu sakit kepala lho, yuk minum!",
    "Penuhi hidrasi untuk menjaga metabolisme tubuh tetap maksimal."
  ];

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      String timezoneName = localTimezone.toString();
      final match = RegExp(r'[A-Za-z]+/[A-Za-z_]+').firstMatch(timezoneName);
      if (match != null) {
        timezoneName = match.group(0)!;
      }
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await Permission.notification.request();
  }

  Future<void> enableHourlyReminder() async {
    // Bersihkan jadwal lama sebelum menjadwalkan ulang
    await disableReminder();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'hourly_water_reminder',
      'Water Reminders',
      channelDescription: 'Pengingat rutin untuk minum air',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final now = tz.TZDateTime.now(tz.local);
    final random = Random();

    // Jadwalkan 24 notifikasi untuk 24 jam ke depan (aman dari limit 500 Android 14)
    for (int i = 1; i <= 24; i++) {
      final scheduleTime = now.add(Duration(hours: i));
      final tip = _hydrationTips[random.nextInt(_hydrationTips.length)];

      await _notificationsPlugin.zonedSchedule(
        id: i,
        title: 'Waktunya Minum Air! 💧',
        body: tip,
        scheduledDate: scheduleTime,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> disableReminder() async {
    await _notificationsPlugin.cancelAll();
  }
}
