import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/data/services/notification_service.dart';
import 'package:teguk/presentation/screens/splash_screen.dart';
import 'package:teguk/providers/activity_provider.dart';
import 'package:teguk/providers/consultation_provider.dart';
import 'package:teguk/providers/statistics_provider.dart';
import 'package:teguk/providers/water_provider.dart';
import 'package:teguk/providers/weather_provider.dart';
import 'package:teguk/providers/admin_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }
  
  try {
    await NotificationService().init();
    await _checkHourlyReminder();
  } catch (e) {
    debugPrint('Error initializing notification service: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => ConsultationProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teguk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

Future<void> _checkHourlyReminder() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool('is_hourly_reminder_active') ?? false;
    if (isActive) {
      await NotificationService().enableHourlyReminder();
    }
  } catch (e) {
    debugPrint('Error checking hourly reminder: $e');
  }
}
