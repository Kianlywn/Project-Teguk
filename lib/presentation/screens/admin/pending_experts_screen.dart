import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/providers/admin_provider.dart';

class PendingExpertsScreen extends StatefulWidget {
  const PendingExpertsScreen({super.key});

  @override
  State<PendingExpertsScreen> createState() => _PendingExpertsScreenState();
}

class _PendingExpertsScreenState extends State<PendingExpertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPendingExperts();
    });
  }

  void _handleAction(String id, bool isApprove) async {
    final provider = context.read<AdminProvider>();
    final success = isApprove ? await provider.approveExpert(id) : await provider.rejectExpert(id);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Berhasil memproses data.' : 'Gagal memproses data.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _confirmAction(BuildContext context, String id, String name, bool isApprove) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Setujui Expert' : 'Tolak Expert'),
        content: Text('Apakah Anda yakin ingin ${isApprove ? "menyetujui" : "menolak"} $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(id, isApprove);
            },
            style: ElevatedButton.styleFrom(backgroundColor: isApprove ? Colors.green : Colors.red, foregroundColor: Colors.white),
            child: Text(isApprove ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pending Experts'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pendingExperts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pendingExperts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Tidak ada data pending', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchPendingExperts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.pendingExperts.length,
              itemBuilder: (context, index) {
                final expert = provider.pendingExperts[index];
                final id = expert['id'] ?? expert['_id'] ?? '';
                final name = expert['fullname'] ?? expert['fullName'] ?? 'Tanpa Nama';
                final email = expert['email'] ?? '';
                final profession = expert['profession'] as String? ?? '-';
                final specialization = expert['specialization'] as String? ?? '-';
                final experienceYears = expert['experienceYears'] ?? '-';

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
                              child: const Icon(Icons.person, color: Color(0xFF2196F3)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Detail profesi
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow('Profesi', profession),
                              const SizedBox(height: 4),
                              _detailRow('Spesialisasi', specialization),
                              const SizedBox(height: 4),
                              _detailRow('Pengalaman', '$experienceYears tahun'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: provider.isLoading ? null : () => _confirmAction(context, id, name, false),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: provider.isLoading ? null : () => _confirmAction(context, id, name, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text('Setujui'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
