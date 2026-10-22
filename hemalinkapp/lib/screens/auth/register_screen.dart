import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/app_controller.dart';
import '../admin/admin_dashboard_screen.dart';
import '../main/main_sheel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _city = TextEditingController(text: AppConstants.defaultCity);
  String? _bloodType;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _username,
      _phone,
      _pass,
      _pass2,
      _weight,
      _height,
      _city,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  String? _intRange(String? v, int min, int max, String label) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < min || n > max) return '$label $min-$max';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final storage = await StorageService.create();
      final api = ApiService(storage);

      final result = await api.register(
        name: _name.text.trim(),
        username: _username.text.trim(),
        password: _pass.text.trim(),
        phone: _phone.text.trim(),
        bloodType: _bloodType!,
        city: _city.text.trim(),
        weight: int.parse(_weight.text),
        height: int.parse(_height.text),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      // ✅ Ambil data user & role
      final userData = result['user'] as Map<String, dynamic>;
      final role = userData['role'] as String? ?? 'user';

      // ✅ Set currentUser via method publik (tidak error)
      AppController.instance.setCurrentUserFromApi(
        id: userData['id'].toString(),
        name: userData['name'] ?? '',
        username: userData['username'] ?? '',
        phone: userData['phone'] ?? '',
        bloodType: userData['blood_type'] ?? '',
        city: userData['city'] ?? '',
        weight: (userData['weight'] as num?)?.toInt() ?? 0,
        height: (userData['height'] as num?)?.toInt() ?? 0,
        isAdmin: role == 'admin',
      );

      // Daftar berhasil → masuk sesuai role
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'admin'
              ? const AdminDashboardScreen()
              : const MainShell(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal daftar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Daftar Akun',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: _req,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  helperText: 'Huruf kecil, angka, _ atau .',
                ),
                validator: (v) {
                  final u = (v ?? '').trim().toLowerCase();
                  if (u.length < 4) return 'Minimal 4 karakter';
                  if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(u)) {
                    return 'Hanya huruf, angka, _ dan .';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. HP / WhatsApp',
                ),
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Nomor tidak valid'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass2,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Ulangi Password'),
                validator: (v) =>
                    v != _pass.text ? 'Password tidak sama' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bloodType,
                decoration: const InputDecoration(labelText: 'Golongan Darah'),
                items: AppConstants.bloodTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v),
                validator: (v) => v == null ? 'Pilih golongan darah' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Berat (kg)',
                      ),
                      validator: (v) => _intRange(v, 20, 250, 'Berat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _height,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tinggi (cm)',
                      ),
                      validator: (v) => _intRange(v, 100, 250, 'Tinggi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Kota / Domisili'),
                validator: _req,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Daftar & Masuk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
