import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/data/repositories/health_expert_repository.dart';
import 'package:teguk/data/repositories/user_repository.dart';
import 'package:teguk/presentation/screens/auth/login_screen.dart';
import 'package:teguk/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:teguk/presentation/screens/expert/expert_application_screen.dart';
import 'package:teguk/presentation/screens/expert/expert_dashboard_screen.dart';
import 'package:teguk/presentation/screens/admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final auth = AuthRepository();
    final token = await auth.getToken();

    if (token == null) {
      _go(const LoginScreen());
      return;
    }

    final role = await auth.getRole();
    final fullname = await auth.getFullname() ?? '';

    if (role == 'User') {
      final profile = await UserRepository().getProfile();
      final waterTarget = profile != null
          ? (profile['targetWater'] as num).toInt()
          : 2000;
      _go(DashboardScreen(userName: fullname, waterTarget: waterTarget));
    } else if (role == 'HealthExpert') {
      await _handleExpertRouting(fullname);
    } else if (role == 'Admin') {
      _go(const AdminDashboardScreen());
    } else {
      _go(const LoginScreen());
    }
  }

  Future<void> _handleExpertRouting(String fullname) async {
    try {
      final application = await HealthExpertRepository().getMyApplication();
      if (!mounted) return;

      if (application == null) {
        // Belum pernah apply
        _go(ExpertApplicationScreen(expertName: fullname));
      } else {
        final status = application['status'] as String? ?? '';
        if (status == 'Approved') {
          _go(ExpertDashboardScreen(expertName: fullname));
        } else {
          // Pending atau Rejected — tampilkan application screen dengan data
          _go(ExpertApplicationScreen(
            expertName: fullname,
            existingApplication: application,
          ));
        }
      }
    } catch (e) {
      // Jika gagal fetch, tetap arahkan ke application screen
      if (mounted) {
        _go(ExpertApplicationScreen(expertName: fullname));
      }
    }
  }

  void _go(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, size: 72, color: Color(0xFF2196F3)),
            SizedBox(height: 16),
            Text(
              'Teguk',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
