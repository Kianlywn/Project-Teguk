import 'package:flutter/material.dart';
import 'package:teguk/data/repositories/health_expert_repository.dart';

class ExpertApplicationScreen extends StatefulWidget {
  final String expertName;
  final Map<String, dynamic>? existingApplication;

  const ExpertApplicationScreen({
    super.key,
    required this.expertName,
    this.existingApplication,
  });

  @override
  State<ExpertApplicationScreen> createState() =>
      _ExpertApplicationScreenState();
}

class _ExpertApplicationScreenState extends State<ExpertApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _professionController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _repo = HealthExpertRepository();

  bool _isLoading = false;
  String? _status; // null = belum apply, 'Pending', 'Approved', 'Rejected'

  @override
  void initState() {
    super.initState();
    if (widget.existingApplication != null) {
      _status = widget.existingApplication!['status'] as String?;
      _professionController.text =
          widget.existingApplication!['profession'] as String? ?? '';
      _specializationController.text =
          widget.existingApplication!['specialization'] as String? ?? '';
      _licenseController.text =
          widget.existingApplication!['licenseNumber'] as String? ?? '';
      final exp = widget.existingApplication!['experienceYears'];
      if (exp != null) _experienceController.text = exp.toString();
    }
  }

  @override
  void dispose() {
    _professionController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _repo.applyAsExpert(
        profession: _professionController.text.trim(),
        specialization: _specializationController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        experienceYears: int.parse(_experienceController.text.trim()),
      );

      if (!mounted) return;

      setState(() => _status = 'Pending');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aplikasi berhasil dikirim!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_status == 'Pending') return _buildPendingView();
    if (_status == 'Rejected') return _buildRejectedView();
    // null or anything else = show form
    return _buildFormView();
  }

  // ─── Form View (belum apply / re-apply setelah rejected) ───
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services,
                      size: 44, color: Color(0xFF00897B)),
                ),
                const SizedBox(height: 16),
                const Text('Lengkapi Profil Expert',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                Text(
                  'Halo, ${widget.expertName}!\nIsi data profesi untuk tampil di daftar expert.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Profesi
          const Text('Profesi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _professionController,
            decoration: _inputDecoration('Contoh: Dokter Umum'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Profesi wajib diisi' : null,
          ),
          const SizedBox(height: 16),

          // Spesialisasi
          const Text('Spesialisasi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _specializationController,
            decoration: _inputDecoration('Contoh: Gizi Klinis'),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Spesialisasi wajib diisi'
                : null,
          ),
          const SizedBox(height: 16),

          // Nomor Lisensi
          const Text('Nomor Lisensi / STR',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _licenseController,
            decoration: _inputDecoration('Contoh: STR-123456789'),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Nomor lisensi wajib diisi'
                : null,
          ),
          const SizedBox(height: 16),

          // Pengalaman
          const Text('Pengalaman (tahun)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _experienceController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Contoh: 5'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Wajib diisi';
              if (int.tryParse(v.trim()) == null) return 'Masukkan angka valid';
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
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
                  : const Text('Kirim Aplikasi',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Pending View ───
  Widget _buildPendingView() {
    return Column(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.hourglass_top, size: 56, color: Colors.orange[600]),
              ),
              const SizedBox(height: 24),
              const Text('Menunggu Persetujuan',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Aplikasi kamu sedang ditinjau oleh admin.\nKamu akan bisa mengakses dashboard setelah disetujui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32),
              // Info card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    _infoRow('Profesi', _professionController.text),
                    const SizedBox(height: 8),
                    _infoRow('Spesialisasi', _specializationController.text),
                    const SizedBox(height: 8),
                    _infoRow('Nomor Lisensi', _licenseController.text),
                    const SizedBox(height: 8),
                    _infoRow('Pengalaman', '${_experienceController.text} tahun'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Rejected View ───
  Widget _buildRejectedView() {
    return Column(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cancel_outlined, size: 56, color: Colors.red[400]),
              ),
              const SizedBox(height: 24),
              const Text('Aplikasi Ditolak',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Maaf, aplikasi kamu telah ditolak oleh admin.\nKamu bisa mengajukan ulang dengan data yang diperbarui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _status = null); // kembali ke form
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ajukan Ulang',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
