import 'package:flutter/material.dart';
import 'package:teguk/presentation/screens/auth/login_screen.dart';
import 'package:teguk/data/repositories/auth_repository.dart';

class ExpertDashboardScreen extends StatelessWidget {
  final String expertName;

  const ExpertDashboardScreen({super.key, required this.expertName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard Expert'),
        backgroundColor: const Color(0xFF00897B), // teal untuk expert
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthRepository().logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 56,
                  color: Color(0xFF00897B),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Halo, $expertName!',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Dashboard Health Expert',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              // Placeholder fitur expert
              _buildMenuCard(Icons.chat_outlined, 'Konsultasi Masuk', 'Lihat pertanyaan dari user'),
              const SizedBox(height: 12),
              _buildMenuCard(Icons.people_outline, 'Daftar Pasien', 'Kelola konsultasi aktif'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00897B), size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}