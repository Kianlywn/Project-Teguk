import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/presentation/screens/auth/login_screen.dart';
import 'package:teguk/presentation/screens/consultation/chat_screen.dart';
import 'package:teguk/providers/consultation_provider.dart';

class ExpertDashboardScreen extends StatefulWidget {
  final String expertName;
  const ExpertDashboardScreen({super.key, required this.expertName});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().fetchConsultations();
    });
  }

  Future<void> _logout() async {
    await AuthRepository().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Dashboard' : 'Konsultasi Masuk'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Keluar',
              onPressed: _logout),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ExpertHomeTab(expertName: widget.expertName),
          const _ExpertConsultationTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF00897B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Konsultasi'),
        ],
      ),
    );
  }
}

class _ExpertHomeTab extends StatelessWidget {
  final String expertName;
  const _ExpertHomeTab({required this.expertName});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationProvider>(
      builder: (context, provider, _) {
        final count = provider.consultations.length;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.medical_services,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, $expertName!',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Text('Health Expert',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: Color(0xFF00897B), size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$count',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00897B))),
                        const Text('Konsultasi Aktif',
                            style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Konsultasi Terbaru',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (provider.consultations.isEmpty)
                Text('Belum ada konsultasi masuk',
                    style: TextStyle(color: Colors.grey[500]))
              else
                ...provider.consultations.take(3).map((c) {
                  final item = c as Map<String, dynamic>;
                  return _ConsultationTile(consultation: item);
                }),
            ],
          ),
        );
      },
    );
  }
}

class _ExpertConsultationTab extends StatelessWidget {
  const _ExpertConsultationTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.consultations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.consultations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Belum ada konsultasi masuk',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: provider.fetchConsultations,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.consultations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = provider.consultations[i] as Map<String, dynamic>;
              return _ConsultationTile(consultation: c);
            },
          ),
        );
      },
    );
  }
}

class _ConsultationTile extends StatelessWidget {
  final Map<String, dynamic> consultation;
  const _ConsultationTile({required this.consultation});

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso).toLocal();
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final consultationId = consultation['consultationId'] as String;
    final userName = consultation['userName'] as String? ?? 'User';
    final status = consultation['status'] as String? ?? '-';
    final createdAt = consultation['createdAt'] as String?;

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            consultationId: consultationId,
            peerName: userName,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!)),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.1),
        child: const Icon(Icons.person_outline, color: Color(0xFF00897B)),
      ),
      title: Text(userName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(_formatDate(createdAt),
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(status,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
