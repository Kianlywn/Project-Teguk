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
      context.read<ActivityProvider>().fetchActivities();
    });
  }

  void _showAddActivitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddActivitySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivitySheet,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.activities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.activities.isEmpty) {
          return _buildEmpty();
        }
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: provider.fetchActivities,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: provider.activities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final a = provider.activities[i] as Map<String, dynamic>;
                  return _ActivityCard(activity: a);
                },
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showAddActivitySheet,
                backgroundColor: const Color(0xFF2196F3),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Belum ada aktivitas',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('Catat aktivitas fisikmu untuk memantau kebutuhan air.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddActivitySheet,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Aktivitas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityCard({required this.activity});

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red[400]!;
      case 'medium':
        return Colors.orange[400]!;
      default:
        return Colors.green[400]!;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Agu','Sep','Okt','Nov','Des'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final type = activity['activityType'] as String? ?? '-';
    final level = activity['activityLevel'] as String? ?? '-';
    final createdAt = activity['createdAt'] as String?;

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
            child: Icon(_typeIcon(type), color: const Color(0xFF2196F3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(_formatDate(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _levelColor(level).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(level,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _levelColor(level))),
          ),
        ],
      ),
    );
  }
}

class _AddActivitySheet extends StatefulWidget {
  const _AddActivitySheet();

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  final _typeController = TextEditingController();
  String _selectedLevel = 'Medium';
  bool _isLoading = false;

  final _activityTypes = [
    'Running', 'Cycling', 'Swimming', 'Gym',
    'Walking', 'Yoga', 'Basketball', 'Football'
  ];
  final _levels = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final type = _typeController.text.trim();
    if (type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atau isi jenis aktivitas')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final success = await context
        .read<ActivityProvider>()
        .addActivity(type, _selectedLevel);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas berhasil dicatat'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan aktivitas'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tambah Aktivitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Jenis Aktivitas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _activityTypes.map((t) {
              final selected = _typeController.text == t;
              return GestureDetector(
                onTap: () => setState(() => _typeController.text = t),
                child: Chip(
                  label: Text(t),
                  backgroundColor: selected
                      ? const Color(0xFF2196F3)
                      : Colors.grey[100],
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _typeController,
            decoration: InputDecoration(
              hintText: 'Atau ketik manual...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true, fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          const Text('Intensitas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: _levels.map((l) {
              final selected = _selectedLevel == l;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLevel = l),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2196F3)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(l,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.grey[700])),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
