import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/data/repositories/user_repository.dart';
import 'package:teguk/presentation/screens/auth/register_screen.dart';
import 'package:teguk/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:teguk/presentation/screens/expert/expert_dashboard_screen.dart';
import 'package:teguk/presentation/screens/onboarding/profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'User';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await _authRepository.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final role = result['role'] as String;
        final fullname = result['fullname'] as String;

        if (role == 'User') {
          final profileDone = await _authRepository.isProfileSetupComplete();
          if (!mounted) return;
          if (!profileDone) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
            return;
          }
          final profile = await UserRepository().getProfile();
          if (!mounted) return;
          final waterTarget = profile != null
              ? (profile['targetWater'] as num).toInt()
              : 2000;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardScreen(
                userName: fullname,
                waterTarget: waterTarget,
              ),
            ),
          );
        } else if (role == 'HealthExpert') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ExpertDashboardScreen(expertName: fullname),
            ),
          );
        } else {
          _showError('Role tidak dikenali: $role');
        }
      } else {
        _showError(result['message'] ?? 'Login gagal');
      }
    } catch (e) {
      if (mounted) _showError('Tidak dapat terhubung ke server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.water_drop, size: 48,
                            color: Color(0xFF2196F3)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Selamat Datang di Teguk',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 8),
                      Text('Masuk untuk melanjutkan',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    _buildToggleButton('User', Icons.person_outline),
                    _buildToggleButton('HealthExpert', Icons.medical_services_outlined),
                  ]),
                ),
                const SizedBox(height: 32),
                const Text('Email',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('nama@email.com', Icons.email_outlined),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Email tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                const Text('Password',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('••••••••', Icons.lock_outline)
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password tidak boleh kosong' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Masuk',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum punya akun? ',
                        style: TextStyle(color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegisterScreen(initialRole: _selectedRole),
                        ),
                      ),
                      child: const Text('Daftar Sekarang',
                          style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String role, IconData icon) {
    final isSelected = _selectedRole == role;
    final label = role == 'User' ? 'User' : 'Health Expert';
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                  color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
