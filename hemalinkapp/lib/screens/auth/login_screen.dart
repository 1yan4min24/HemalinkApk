import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/app_controller.dart';
import '../admin/admin_dashboard_screen.dart';
import '../main/main_sheel.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _asAdmin = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final storage = await StorageService.create();
      final api = ApiService(storage);

      final result = await api.login(
        _userCtrl.text.trim(),
        _passCtrl.text.trim(),
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

      // ✅ Arahkan sesuai role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'admin'
              ? const AdminDashboardScreen()
              : const MainShell(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal login: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.lightRed,
                    child: Icon(
                      Icons.water_drop,
                      size: 34,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    AppConstants.tagline,
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                  const SizedBox(height: 24),
                  _roleSelector(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _userCtrl,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 18),
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
                          : const Text('Masuk'),
                    ),
                  ),
                  if (!_asAdmin) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text(
                            'Daftar sekarang',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    Widget tab(String label, bool admin) {
      final active = _asAdmin == admin;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _asAdmin = admin),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active
                  ? [const BoxShadow(color: Colors.black12, blurRadius: 3)]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.red : AppColors.slate500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab('User (Pendonor/Pemohon)', false),
          tab('Admin PMI', true),
        ],
      ),
    );
  }
}
