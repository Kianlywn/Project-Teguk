import 'package:flutter/material.dart';
import 'package:teguk/core/utils/permission_helper.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/data/repositories/user_repository.dart';
import 'package:teguk/presentation/screens/auth/login_screen.dart';
import 'package:teguk/presentation/screens/dashboard/dashboard_screen.dart';
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

    // Request all permissions upfront (location, camera, notification)
    await PermissionHelper.requestAllPermissions(context);
    if (!mounted) return;

    final auth = AuthRepository();
    final token = await auth.getToken();

    if (token == null) {
      _go(const LoginScreen());
      return;
    }

    final role = await auth.getRole();
    String fullname = await auth.getFullname() ?? '';
    if (fullname.trim().isEmpty) fullname = 'Pengguna';

    if (role == 'User' || role == 'HealthExpert') {
      final profile = await UserRepository().getProfile();
      final waterTarget = profile != null
          ? (profile['targetWater'] as num).toInt()
          : 2000;
      _go(DashboardScreen(userName: fullname, waterTarget: waterTarget));
    } else if (role == 'Admin') {
      _go(const AdminDashboardScreen());
    } else {
      _go(const LoginScreen());
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
