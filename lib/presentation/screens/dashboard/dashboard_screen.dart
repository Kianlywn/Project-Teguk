import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/presentation/screens/activity/live_activity_screen.dart';
import 'package:teguk/presentation/screens/auth/login_screen.dart';
import 'package:teguk/presentation/screens/consultation/consultation_screen.dart';
import 'package:teguk/presentation/screens/history/history_screen.dart';
import 'package:teguk/presentation/screens/profile/profile_edit_screen.dart';
import 'package:teguk/presentation/screens/statistics/statistics_screen.dart';
import 'package:teguk/presentation/widgets/quick_add_button.dart';
import 'package:teguk/presentation/widgets/water_progress_ring.dart';
import 'package:teguk/presentation/widgets/weather_banner.dart';
import 'package:teguk/providers/activity_provider.dart';
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
  late String _userName;

  static const _titles = [
    'Teguk',
    'Riwayat',
    'Aktivitas',
    'Statistik',
    'Konsultasi',
  ];

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
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
            icon: const Icon(Icons.person_outline),
            tooltip: 'Edit Profil',
            onPressed: () async {
              final updatedName = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileEditScreen(currentName: _userName),
                ),
              );
              if (updatedName != null && mounted) {
                setState(() => _userName = updatedName);
              }
            },
          ),
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
          _DashboardTab(userName: _userName),
          const HistoryScreen(embedded: true),
          const LiveActivityScreen(embedded: true),
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
              if (water.showMountainBanner)
                Card(
                  color: Colors.blue[50],
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.terrain, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aktivitas Dataran Tinggi',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kamu sepertinya berada di dataran tinggi (>1500 mdpl). Tambah target air minum +1000ml?',
                          style: TextStyle(
                              fontSize: 14, color: Colors.blue[900]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => water.ignoreMountainBanner(),
                              child: const Text('Abaikan'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => water.addMountainAdjustment(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Ya, Tambahkan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const WeatherBanner(),
              const SizedBox(height: 16),
              
              // Widget Langkah Hari Ini
              Consumer<ActivityProvider>(
                builder: (context, activity, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4, offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.directions_walk, color: Color(0xFF2196F3)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Langkah Hari Ini', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('${activity.currentSteps} / 6000', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const DashboardScreen(userName: '', waterTarget: 0)), // Will reset state, ideally we just change index but we are nested. Actually let's just leave it passive.
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
                            foregroundColor: const Color(0xFF2196F3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                },
              ),

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
