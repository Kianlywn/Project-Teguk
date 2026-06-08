import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/data/repositories/health_expert_repository.dart';
import 'package:teguk/presentation/screens/consultation/chat_screen.dart';
import 'package:teguk/providers/consultation_provider.dart';

class ConsultationScreen extends StatefulWidget {
  final bool embedded;
  const ConsultationScreen({super.key, this.embedded = false});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().fetchConsultations();
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
              Tab(text: 'Konsultasi Saya'),
              Tab(text: 'Cari Expert'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _MyConsultationsTab(),
              _FindExpertTab(),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konsultasi'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }
}

// --- Tab: Konsultasi Saya ---
class _MyConsultationsTab extends StatelessWidget {
  const _MyConsultationsTab();

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Agu','Sep','Okt','Nov','Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

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
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Belum ada konsultasi',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('Cari Health Expert di tab "Cari Expert" untuk memulai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
              final consultationId = c['consultationId'] as String;
              final expertName = c['expertName'] as String? ?? 'Expert';
              final status = c['status'] as String? ?? '-';
              final createdAt = c['createdAt'] as String?;

              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      consultationId: consultationId,
                      peerName: expertName,
                    ),
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!)),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.12),
                  child: const Icon(Icons.medical_services_outlined,
                      color: Color(0xFF2196F3)),
                ),
                title: Text(expertName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_formatDate(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            },
          ),
        );
      },
    );
  }
}

// --- Tab: Cari Expert ---
class _FindExpertTab extends StatefulWidget {
  const _FindExpertTab();

  @override
  State<_FindExpertTab> createState() => _FindExpertTabState();
}

class _FindExpertTabState extends State<_FindExpertTab> {
  final _repo = HealthExpertRepository();
  List<dynamic> _experts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  Future<void> _loadExperts() async {
    setState(() => _isLoading = true);
    final list = await _repo.getExpertList();
    if (mounted) {
      setState(() {
        _experts = list ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _startConsultation(String expertId, String expertName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mulai Konsultasi'),
        content: Text('Mulai konsultasi dengan $expertName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white),
              child: const Text('Mulai')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success =
          await context.read<ConsultationProvider>().createConsultation(expertId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konsultasi dimulai!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memulai konsultasi'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_experts.isEmpty) {
      return Center(
        child: Text('Belum ada expert tersedia',
            style: TextStyle(color: Colors.grey[600])),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadExperts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _experts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final e = _experts[i] as Map<String, dynamic>;
          final name = e['fullName'] as String? ?? e['fullname'] as String? ?? '-';
          final profession = e['profession'] as String? ?? '-';
          final specialization = e['specialization'] as String? ?? '-';
          final years = e['experienceYears'] as int? ?? 0;
          final expertId = e['expertId'] as String;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: Color(0xFF2196F3),
                      size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(profession,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600])),
                      Text('$specialization • $years thn pengalaman',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _startConsultation(expertId, name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Chat', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
