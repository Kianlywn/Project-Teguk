import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/providers/statistics_provider.dart';

class StatisticsScreen extends StatefulWidget {
  final bool embedded;
  const StatisticsScreen({super.key, this.embedded = false});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().fetchWeekly();
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final provider = context.read<StatisticsProvider>();
        if (_tabController.index == 0) {
          provider.fetchWeekly();
        } else {
          provider.fetchMonthly();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Container(
          color: const Color(0xFF2196F3),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: '7 Hari Terakhir'),
              Tab(text: '30 Hari Terakhir'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _StatsTab(period: 'weekly'),
              _StatsTab(period: 'monthly'),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }
}

class _StatsTab extends StatelessWidget {
  final String period;
  const _StatsTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, provider, _) {
        final data = period == 'weekly' ? provider.weekly : provider.monthly;

        if (provider.isLoading && data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data.isEmpty) {
          return Center(
            child: Text('Belum ada data',
                style: TextStyle(color: Colors.grey[500])),
          );
        }

        final totals = data
            .map((e) => (e as Map<String, dynamic>)['total'] as num? ?? 0)
            .toList();
        final maxVal =
            totals.isEmpty ? 1 : totals.reduce((a, b) => a > b ? a : b);

        // Summary card
        final totalSum = totals.fold<num>(0, (a, b) => a + b);
        final avg = totals.isEmpty ? 0 : totalSum ~/ totals.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary row
              Row(children: [
                _SummaryCard(
                    label: 'Total',
                    value: '${(totalSum / 1000).toStringAsFixed(1)}L'),
                const SizedBox(width: 12),
                _SummaryCard(
                    label: 'Rata-rata/hari',
                    value: '$avg ml'),
              ]),
              const SizedBox(height: 24),
              const Text('Grafik Konsumsi Air',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Bar chart manual
              SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.asMap().entries.map((entry) {
                    final item =
                        entry.value as Map<String, dynamic>;
                    final total =
                        (item['total'] as num?)?.toDouble() ?? 0;
                    final dateStr = item['date'] as String? ?? '';
                    final barHeight = maxVal > 0
                        ? (total / maxVal.toDouble()) * 160
                        : 0.0;
                    final date = dateStr.isNotEmpty
                        ? DateTime.tryParse(dateStr)
                        : null;
                    final label = date != null
                        ? '${date.day}/${date.month}'
                        : '';

                    return Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (total > 0)
                              Text(
                                '${(total / 1000).toStringAsFixed(1)}L',
                                style: const TextStyle(
                                    fontSize: 8,
                                    color: Color(0xFF2196F3),
                                    fontWeight: FontWeight.w600),
                              ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: barHeight.toDouble(),
                              decoration: BoxDecoration(
                                color: total >= 2000
                                    ? const Color(0xFF2196F3)
                                    : const Color(0xFF90CAF9),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(label,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 12, height: 12,
                      decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  const Text('≥ 2000 ml (target)', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 12),
                  Container(width: 12, height: 12,
                      decoration: BoxDecoration(
                          color: const Color(0xFF90CAF9),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  const Text('< 2000 ml', style: TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Detail Harian',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...data.map((e) {
                final item = e as Map<String, dynamic>;
                final total = (item['total'] as num?)?.toInt() ?? 0;
                final dateStr = item['date'] as String? ?? '';
                final date = dateStr.isNotEmpty
                    ? DateTime.tryParse(dateStr)
                    : null;
                final dateLabel = date != null
                    ? _formatDate(date)
                    : dateStr;
                final percent = maxVal > 0
                    ? (total / maxVal).clamp(0.0, 1.0)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 72,
                          child: Text(dateLabel,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600]))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent.toDouble(),
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF2196F3)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 60,
                          child: Text('$total ml',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const days = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3))),
          ],
        ),
      ),
    );
  }
}
