import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/providers/water_provider.dart';

class HistoryScreen extends StatefulWidget {
  /// Tanpa Scaffold sendiri saat dipakai di BottomNavigationBar.
  final bool embedded;

  const HistoryScreen({super.key, this.embedded = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Minum Air'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    return Consumer<WaterProvider>(
      builder: (context, water, _) {
        if (water.isHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (water.history.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: water.fetchHistory,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: water.history.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final entry =
                  Map<String, dynamic>.from(water.history[index] as Map);
              final amount = (entry['amountMl'] as num?)?.toInt() ?? 0;
              final drinkTime = entry['drinkTime'] as String?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      const Color(0xFF2196F3).withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.water_drop,
                    color: Color(0xFF2196F3),
                  ),
                ),
                title: Text(
                  '$amount ml',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(_formatDrinkTime(drinkTime)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Catat asupan air dari dashboard untuk melihat riwayat di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDrinkTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'Waktu tidak tersedia';

    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');

    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}
