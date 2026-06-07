import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/presentation/screens/auth/login_screen.dart';
import 'package:teguk/presentation/screens/admin/pending_experts_screen.dart';
import 'package:teguk/providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboard();
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.dashboardStats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = provider.dashboardStats;
          if (stats == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Gagal memuat statistik', style: TextStyle(color: Colors.grey[600])),
                  TextButton(
                    onPressed: provider.fetchDashboard,
                    child: const Text('Coba Lagi'),
                  )
                ],
              ),
            );
          }

          final totalUsers = stats['totalUsers'] ?? 0;
          final totalExperts = stats['totalExperts'] ?? 0;
          final totalConsultations = stats['totalConsultations'] ?? 0;

          return RefreshIndicator(
            onRefresh: provider.fetchDashboard,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Ringkasan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _StatCard('Total User', totalUsers.toString(), Icons.person_outline, Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard('Total Expert', totalExperts.toString(), Icons.medical_services_outlined, Colors.green)),
                  ],
                ),
                const SizedBox(height: 16),
                _StatCard('Total Konsultasi', totalConsultations.toString(), Icons.chat_bubble_outline, Colors.orange),
                const SizedBox(height: 32),
                
                const Text('Manajemen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildMenuCard(
                  title: 'Persetujuan Health Expert',
                  subtitle: 'Tinjau pendaftaran Health Expert baru',
                  icon: Icons.checklist,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingExpertsScreen()));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF2196F3).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF2196F3)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
