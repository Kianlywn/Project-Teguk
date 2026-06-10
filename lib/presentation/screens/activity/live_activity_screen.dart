import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/providers/activity_provider.dart';

class LiveActivityScreen extends StatefulWidget {
  final bool embedded;
  const LiveActivityScreen({super.key, this.embedded = false});

  @override
  State<LiveActivityScreen> createState() => _LiveActivityScreenState();
}

class _LiveActivityScreenState extends State<LiveActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas & Langkah'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.history.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Urutkan history dari yang terbaru (Descending)
        final historyEntries = provider.history.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        return RefreshIndicator(
          onRefresh: provider.fetchHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              // Always show step counter card
              _buildStepCounterCard(provider.currentSteps),
              const SizedBox(height: 24),
              const Text('Riwayat Langkah (Harian)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // Activities or empty state
              if (historyEntries.isEmpty)
                _buildEmptyInline()
              else
                ...historyEntries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ActivityCard(dateStr: entry.key, steps: entry.value),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyInline() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_walk_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Belum ada riwayat',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text('Riwayat langkah harian Anda akan muncul di sini secara otomatis besok.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildStepCounterCard(int steps) {
    const int goal = 6000;
    final double progress = (steps / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_walk, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Langkah Hari Ini',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('Terus bergerak!',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                steps.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/ 6000',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String dateStr;
  final int steps;
  const _ActivityCard({required this.dateStr, required this.steps});

  String _formatDate(String iso) {
    try {
      final parts = iso.split('-');
      if (parts.length != 3) return iso;
      final year = parts[0];
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      const months = [
        'Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'
      ];
      return '$day ${months[month - 1]} $year';
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history_toggle_off, color: Color(0xFF2196F3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(dateStr),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Total langkah',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$steps',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
