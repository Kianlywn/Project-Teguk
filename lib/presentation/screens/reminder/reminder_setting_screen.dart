import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/providers/reminder_provider.dart';

class ReminderSettingScreen extends StatefulWidget {
  final bool embedded;
  const ReminderSettingScreen({super.key, this.embedded = false});

  @override
  State<ReminderSettingScreen> createState() => _ReminderSettingScreenState();
}

class _ReminderSettingScreenState extends State<ReminderSettingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().fetchReminders();
    });
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ReminderProvider>(),
        child: const _AddReminderSheet(),
      ),
    );
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Reminder'),
        content: const Text('Yakin ingin menghapus reminder ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await context.read<ReminderProvider>().deleteReminder(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Reminder dihapus' : 'Gagal menghapus'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat Minum Air'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.reminders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            provider.reminders.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: provider.fetchReminders,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: provider.reminders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final r = provider.reminders[i] as Map<String, dynamic>;
                        return _ReminderCard(
                          reminder: r,
                          onDelete: () => _delete(r['id'] as String),
                        );
                      },
                    ),
                  ),
            Positioned(
              bottom: 16, right: 16,
              child: FloatingActionButton(
                onPressed: _showAddSheet,
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
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Belum ada pengingat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('Tambah pengingat agar kamu tidak lupa minum air.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddSheet,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Pengingat'),
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

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onDelete;
  const _ReminderCard({required this.reminder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final time = reminder['reminderTime'] as String? ?? '-';
    final interval = reminder['intervalMinutes'] as int? ?? 0;
    final displayTime = time.length >= 5 ? time.substring(0, 5) : time;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
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
            child: const Icon(Icons.notifications_active,
                color: Color(0xFF2196F3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayTime,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Setiap $interval menit',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _intervalMinutes = 30;
  bool _isLoading = false;

  final _intervalOptions = [15, 30, 60, 90, 120];

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final h = _selectedTime.hour.toString().padLeft(2, '0');
    final m = _selectedTime.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m:00';

    final success = await context
        .read<ReminderProvider>()
        .addReminder(timeStr, _intervalMinutes);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengingat berhasil ditambahkan'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambahkan pengingat'),
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
          const Text('Tambah Pengingat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Waktu Pengingat',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3)),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFF2196F3)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Interval Pengulangan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _intervalOptions.map((mins) {
              final selected = _intervalMinutes == mins;
              final label = mins >= 60
                  ? '${mins ~/ 60} jam'
                  : '$mins menit';
              return GestureDetector(
                onTap: () => setState(() => _intervalMinutes = mins),
                child: Chip(
                  label: Text(label),
                  backgroundColor: selected
                      ? const Color(0xFF2196F3)
                      : Colors.grey[100],
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal),
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
