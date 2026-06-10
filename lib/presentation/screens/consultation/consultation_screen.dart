import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
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
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _initRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultationProvider>().fetchConsultations();
    });
  }

  Future<void> _initRole() async {
    final role = await AuthRepository().getRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _tabController = TabController(
            length: _userRole == 'HealthExpert' ? 3 : 2, vsync: this);
      });
      if (role == 'HealthExpert') {
        context.read<ConsultationProvider>().fetchIncomingConsultations();
      }
    }
  }

  @override
  void dispose() {
    if (_userRole != null) _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isExpert = _userRole == 'HealthExpert';

    final body = Column(
      children: [
        Container(
          color: const Color(0xFF2196F3),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(text: 'Konsultasi Saya'),
              if (isExpert) const Tab(text: 'Pasien Masuk'),
              const Tab(text: 'Cari Expert'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const _MyConsultationsTab(),
              if (isExpert) const _ExpertConsultationTab(),
              const _FindExpertTab(),
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
              );
            },
          ),
        );
      },
    );
  }
}

// --- Tab: Pasien Masuk (Hanya untuk Health Expert) ---
class _ExpertConsultationTab extends StatelessWidget {
  const _ExpertConsultationTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.incomingConsultations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.incomingConsultations.isEmpty) {
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
          onRefresh: provider.fetchIncomingConsultations,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.incomingConsultations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = provider.incomingConsultations[i] as Map<String, dynamic>;
              return _ExpertConsultationTile(consultation: c);
            },
          ),
        );
      },
    );
  }
}

class _ExpertConsultationTile extends StatelessWidget {
  final Map<String, dynamic> consultation;
  const _ExpertConsultationTile({required this.consultation});

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
    final myName = await AuthRepository().getFullname();
    final list = await _repo.getExpertList();
    if (mounted) {
      setState(() {
        if (list != null) {
          _experts = list.where((e) {
            final name = e['fullName'] as String? ?? e['fullname'] as String? ?? '';
            return name != myName;
          }).toList();
        } else {
          _experts = [];
        }
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
