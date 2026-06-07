import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/presentation/screens/activity/live_activity_screen.dart';
import 'package:teguk/presentation/screens/auth/login_screen.dart';
import 'package:teguk/presentation/screens/consultation/consultation_screen.dart';
import 'package:teguk/presentation/screens/history/history_screen.dart';
import 'package:teguk/presentation/screens/reminder/reminder_setting_screen.dart';
import 'package:teguk/presentation/screens/statistics/statistics_screen.dart';
import 'package:teguk/presentation/widgets/quick_add_button.dart';
import 'package:teguk/presentation/widgets/water_progress_ring.dart';
import 'package:teguk/presentation/widgets/weather_banner.dart';
import 'package:teguk/providers/water_provider.dart';
import 'package:teguk/providers/weather_provider.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final int waterTarget;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.waterTarget,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  static const _titles = [
    'Teguk',
    'Riwayat',
    'Aktivitas',
    'Pengingat',
    'Statistik',
    'Konsultasi',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterProvider>().initialize(
            fallbackTarget: widget.waterTarget,
          );
      context.read<WeatherProvider>().fetchWeather();
    });
  }

  Future<void> _logout() async {
    await AuthRepository().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(userName: widget.userName),
          const HistoryScreen(embedded: true),
          const LiveActivityScreen(embedded: true),
          const ReminderSettingScreen(embedded: true),
          const StatisticsScreen(embedded: true),
          const ConsultationScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) context.read<WaterProvider>().fetchHistory();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run_outlined),
            activeIcon: Icon(Icons.directions_run),
            label: 'Aktivitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Pengingat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Konsultasi',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final String userName;
  const _DashboardTab({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, water, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WeatherBanner(),
              const SizedBox(height: 16),
              Text('Halo, $userName!',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Target harian: ${water.target} ml',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              Center(
                child: WaterProgressRing(
                  progress: water.progress,
                  totalMl: water.totalDrink,
                  targetMl: water.target,
                  isLoading: water.isLoading && water.totalDrink == 0,
                ),
              ),
              const SizedBox(height: 32),
              const Text('Tambah asupan air',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  QuickAddButton(
                    amountMl: 200,
                    isLoading: water.isLoading,
                    onPressed: () => _onAdd(context, water, 200),
                  ),
                  QuickAddButton(
                    amountMl: 250,
                    isLoading: water.isLoading,
                    onPressed: () => _onAdd(context, water, 250),
                  ),
                  QuickAddButton(
                    amountMl: 330,
                    isLoading: water.isLoading,
                    onPressed: () => _onAdd(context, water, 330),
                  ),
                  QuickAddButton(
                    amountMl: 500,
                    isLoading: water.isLoading,
                    onPressed: () => _onAdd(context, water, 500),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onAdd(
      BuildContext context, WaterProvider water, int amount) async {
    final ok = await water.addWater(amount);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mencatat air. Coba lagi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
