import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  final String initialRole;

  const RegisterScreen({super.key, this.initialRole = 'User'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  // Controller umum
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controller khusus User
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late String _selectedRole;

  // Pilihan untuk User
  String _selectedGender = 'Male';
  String _selectedActivityLevel = 'Sedentary';
  String _selectedEnvironment = 'Normal';

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _activityOptions = ['Sedentary', 'Light', 'Moderate', 'Active', 'VeryActive'];
  final List<String> _environmentOptions = ['Normal', 'Hot', 'Cold', 'Humid'];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (_selectedRole == 'User') {
        result = await _authRepository.registerUser(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          age: int.parse(_ageController.text),
          weight: double.parse(_weightController.text),
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel,
          environmentCondition: _selectedEnvironment,
        );
      } else {
        result = await _authRepository.registerExpert(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      if (result['success'] == true) {
        if (_selectedRole == 'User') {
          await _authRepository.setProfileSetupComplete(false);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil! Silakan login.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // balik ke login
      } else {
        _showError(result['message'] ?? 'Pendaftaran gagal');
      }
    } catch (e) {
      if (mounted) _showError('Tidak dapat terhubung ke server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buat Akun'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Role
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildToggleButton('User', Icons.person_outline),
                      _buildToggleButton('HealthExpert', Icons.medical_services_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _selectedRole == 'User'
                        ? 'Daftar sebagai pengguna biasa'
                        : 'Daftar sebagai tenaga kesehatan (perlu persetujuan admin)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 24),

                // Field Nama
                _buildLabel('Nama Lengkap'),
                _buildTextField(_fullNameController, 'John Doe', Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null),
                const SizedBox(height: 16),

                // Field Email
                _buildLabel('Email'),
                _buildTextField(_emailController, 'nama@email.com', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Email tidak boleh kosong' : null),
                const SizedBox(height: 16),

                // Field Password
                _buildLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Min. 6 karakter', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 16),

                // Konfirmasi Password
                _buildLabel('Konfirmasi Password'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Ulangi password', Icons.lock_outline),
                  validator: (v) =>
                      v != _passwordController.text ? 'Password tidak cocok' : null,
                ),
                const SizedBox(height: 16),

                // Field khusus User
                if (_selectedRole == 'User') ...[
                  _buildLabel('Umur'),
                  _buildTextField(_ageController, 'Contoh: 22', Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Umur tidak boleh kosong' : null),
                  const SizedBox(height: 16),

                  _buildLabel('Berat Badan (kg)'),
                  _buildTextField(_weightController, 'Contoh: 65', Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty ? 'Berat badan tidak boleh kosong' : null),
                  const SizedBox(height: 16),

                  _buildLabel('Jenis Kelamin'),
                  _buildDropdown(
                    value: _selectedGender,
                    items: _genderOptions,
                    icon: Icons.wc_outlined,
                    onChanged: (v) => setState(() => _selectedGender = v!),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Tingkat Aktivitas'),
                  _buildDropdown(
                    value: _selectedActivityLevel,
                    items: _activityOptions,
                    icon: Icons.directions_run_outlined,
                    onChanged: (v) => setState(() => _selectedActivityLevel = v!),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Kondisi Lingkungan'),
                  _buildDropdown(
                    value: _selectedEnvironment,
                    items: _environmentOptions,
                    icon: Icons.thermostat_outlined,
                    onChanged: (v) => setState(() => _selectedEnvironment = v!),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Tombol Daftar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Daftar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
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
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint, icon),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDecoration('', icon),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
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
