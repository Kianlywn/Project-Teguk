import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teguk/data/repositories/auth_repository.dart';
import 'package:teguk/data/repositories/user_repository.dart';
import 'package:teguk/data/repositories/health_expert_repository.dart';
import 'package:teguk/providers/water_provider.dart';
import 'package:teguk/presentation/screens/expert/expert_application_screen.dart';
import 'package:teguk/data/services/notification_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final String currentName;
  final bool isExpert;
  final Map<String, dynamic>? expertInfo; // profession, specialization, etc.

  const ProfileEditScreen({
    super.key,
    required this.currentName,
    this.isExpert = false,
    this.expertInfo,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _repo = UserRepository();

  String _selectedGender = '';
  String _selectedActivity = '';
  String _selectedEnvironment = '';
  bool _isLoading = false;
  bool _isFetching = true;
  bool _isExpertActual = false;
  Map<String, dynamic>? _myApplication;

  final _genders = ['Laki-laki', 'Perempuan'];
  final _activityLevels = ['Low', 'Medium', 'High'];
  final _environments = ['Normal', 'Hot', 'Cold'];

  bool _isHourlyReminderEnabled = false;

  @override
  void initState() {
    super.initState();
    final currentName = widget.currentName;
    _nameController.text = currentName.trim().isEmpty 
        ? 'Pengguna' 
        : currentName;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final role = await AuthRepository().getRole();
      final isExpert = role == 'HealthExpert';
      final profile = await _repo.getProfile();
      Map<String, dynamic>? myApp;
      
      if (!isExpert) {
        myApp = await HealthExpertRepository().getMyApplication();
      }

      final prefs = await SharedPreferences.getInstance();
      final reminderEnabled = prefs.getBool('is_hourly_reminder_active') ?? false;

      if (mounted) {
        setState(() {
          _isHourlyReminderEnabled = reminderEnabled;
          _isExpertActual = isExpert;
          if (profile != null) {
            _nameController.text =
                profile['fullname'] as String? ?? widget.currentName;
            _ageController.text = (profile['age'] ?? '').toString();
            _weightController.text = (profile['weight'] ?? '').toString();
            _selectedGender = profile['gender'] as String? ?? '';
            _selectedActivity = profile['activityLevel'] as String? ?? '';
            _selectedEnvironment =
                profile['environmentCondition'] as String? ?? '';
          }
          if (myApp != null) {
            _myApplication = myApp;
          }
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _repo.updateProfile(
        fullName: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        weight: double.tryParse(_weightController.text.trim()) ?? 0,
        gender: _selectedGender,
        activityLevel: _selectedActivity,
        environmentCondition: _selectedEnvironment,
      );

      if (!mounted) return;

      if (success) {
        // Update SharedPreferences fullname
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullname', _nameController.text.trim());

        // Fetch ulang profile untuk dapat waterTarget baru dari backend
        if (mounted) {
          final newProfile = await _repo.getProfile();
          if (newProfile != null && mounted) {
            final newTarget = (newProfile['targetWater'] as num).toInt();
            context.read<WaterProvider>().setTarget(newTarget);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, _nameController.text.trim());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil. Coba lagi.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor =
        widget.isExpert ? const Color(0xFF00897B) : const Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: themeColor.withValues(alpha: 0.1),
                        child: Icon(
                          widget.isExpert
                              ? Icons.medical_services
                              : Icons.person,
                          size: 40,
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Expert info (read-only)
                    if (widget.isExpert && widget.expertInfo != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF00897B)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Informasi Expert',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themeColor)),
                            const SizedBox(height: 8),
                            _readOnlyRow('Profesi',
                                widget.expertInfo!['profession'] ?? '-'),
                            _readOnlyRow('Spesialisasi',
                                widget.expertInfo!['specialization'] ?? '-'),
                            _readOnlyRow('Pengalaman',
                                '${widget.expertInfo!['experienceYears'] ?? '-'} tahun'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Name
                    _label('Nama Lengkap'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Masukkan nama', themeColor),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Age
                    if (!widget.isExpert) ...[
                      _label('Usia'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration:
                            _inputDecoration('Contoh: 25', themeColor),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Usia wajib diisi';
                          }
                          if (int.tryParse(v.trim()) == null) {
                            return 'Masukkan angka valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Weight
                      _label('Berat Badan (kg)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration:
                            _inputDecoration('Contoh: 60', themeColor),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Berat badan wajib diisi';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Masukkan angka valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      _label('Jenis Kelamin'),
                      const SizedBox(height: 8),
                      _chipSelector(
                        _genders,
                        _selectedGender,
                        (v) => setState(() => _selectedGender = v),
                        themeColor,
                      ),
                      const SizedBox(height: 16),

                      // Activity Level
                      _label('Tingkat Aktivitas'),
                      const SizedBox(height: 8),
                      _chipSelector(
                        _activityLevels,
                        _selectedActivity,
                        (v) => setState(() => _selectedActivity = v),
                        themeColor,
                      ),
                      const SizedBox(height: 16),

                      // Environment
                      _label('Kondisi Lingkungan'),
                      const SizedBox(height: 8),
                      _chipSelector(
                        _environments,
                        _selectedEnvironment,
                        (v) => setState(() => _selectedEnvironment = v),
                        themeColor,
                      ),
                      const SizedBox(height: 24),
                      
                      // Notification Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: SwitchListTile(
                          title: const Text('Pengingat Minum Tiap Jam', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Notifikasi otomatis setiap jam', style: TextStyle(fontSize: 12)),
                          value: _isHourlyReminderEnabled,
                          activeTrackColor: themeColor,
                          onChanged: (val) async {
                            setState(() => _isHourlyReminderEnabled = val);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('is_hourly_reminder_active', val);
                            if (val) {
                              await NotificationService().requestPermission();
                              await NotificationService().enableHourlyReminder();
                            } else {
                              await NotificationService().disableReminder();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
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
                            : const Text('Simpan Perubahan',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_isExpertActual)
                      Center(
                        child: _myApplication != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _myApplication!['status'] == 'Rejected'
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Status Pengajuan Expert: ${_myApplication!['status']}',
                                  style: TextStyle(
                                    color: _myApplication!['status'] == 'Rejected'
                                        ? Colors.red
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ExpertApplicationScreen(
                                        expertName: widget.currentName,
                                      ),
                                    ),
                                  ).then((_) => _loadProfile()); // Refresh after return
                                },
                                icon: const Icon(Icons.medical_services_outlined,
                                    color: Color(0xFF00897B)),
                                label: const Text(
                                  'Ingin menjadi Health Expert? Daftar di sini',
                                  style: TextStyle(
                                    color: Color(0xFF00897B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chipSelector(List<String> options, String selected,
      ValueChanged<String> onSelected, Color themeColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? themeColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(opt,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700])),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecoration(String hint, Color themeColor) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
