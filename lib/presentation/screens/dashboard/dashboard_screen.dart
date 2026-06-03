import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/presentation/widgets/quick_add_button.dart';
import 'package:teguk/presentation/widgets/water_progress_ring.dart';
import 'package:teguk/providers/water_provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterProvider>().initialize(
            fallbackTarget: widget.waterTarget,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Teguk'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Consumer<WaterProvider>(
        builder: (context, water, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Halo, ${widget.userName}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Target harian: ${water.target} ml',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                WaterProgressRing(
                  progress: water.progress,
                  totalMl: water.totalDrink,
                  targetMl: water.target,
                  isLoading: water.isLoading && water.totalDrink == 0,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Tambah asupan air',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    QuickAddButton(
                      amountMl: 200,
                      isLoading: water.isLoading,
                      onPressed: () => _onAdd(water, 200),
                    ),
                    QuickAddButton(
                      amountMl: 250,
                      isLoading: water.isLoading,
                      onPressed: () => _onAdd(water, 250),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onAdd(WaterProvider water, int amount) async {
    final ok = await water.addWater(amount);
    if (!mounted) return;
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
