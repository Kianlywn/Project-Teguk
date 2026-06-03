import 'package:flutter/material.dart';
import 'package:teguk/core/utils/permission_helper.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/presentation/screens/auth/login_screen.dart';
import 'package:teguk/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:teguk/presentation/screens/expert/expert_dashboard_screen.dart';
import 'package:teguk/presentation/screens/onboarding/profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _init();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _init() async {
    // Jalankan animasi + minta permission bersamaan
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      PermissionHelper.requestAllPermissions(context),
    ]);

    if (!mounted) return;

    final auth = AuthRepository();
    final token = await auth.getToken();

    final Widget next;
    if (token == null) {
      next = const LoginScreen();
    } else {
      final role = await auth.getRole();
      final fullname = await auth.getFullname() ?? 'Pengguna';
      final profileDone = await auth.isProfileSetupComplete();

      if (role == 'User' && !profileDone) {
        next = const ProfileSetupScreen();
      } else if (role == 'HealthExpert') {
        next = ExpertDashboardScreen(expertName: fullname);
      } else {
        next = DashboardScreen(userName: fullname, waterTarget: 2000);
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3), // biru sesuai tema Teguk
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon tetes air
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Nama app
                    const Text(
                      'Teguk',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Hidrasi Cerdas, Hidup Sehat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Loading indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}