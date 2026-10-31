import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme/app_colors.dart';
import '../main/main_sheel.dart';
import 'login_screen.dart';

/// Ganti sandi. Dengan [forced] = true (setelah sandi sementara dari admin),
/// layar ini tidak bisa ditutup sampai sandi baru dibuat.
class ChangePasswordScreen extends StatefulWidget {
  final bool forced;
  const ChangePasswordScreen({super.key, this.forced = false});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final err = await AppController.instance
        .changePassword(_current.text, _new.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Sandi berhasil diubah.')));
    if (widget.forced) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _logout() async {
    await AppController.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _field(TextEditingController c, String label,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forced,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.forced,
          title: Text(widget.forced ? 'Buat Sandi Baru' : 'Ubah Sandi',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.slate800,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: _obscure ? 'Tampilkan sandi' : 'Sembunyikan sandi',
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.forced)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Anda masuk dengan sandi sementara dari admin. '
                      'Demi keamanan, buat sandi baru sekarang.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                    ),
                  ),
                _field(
                  _current,
                  widget.forced ? 'Sandi Sementara (dari admin)' : 'Sandi Lama',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                _field(
                  _new,
                  'Sandi Baru',
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Minimal 6 karakter';
                    if (v == _current.text) {
                      return 'Harus berbeda dari sandi lama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  _confirm,
                  'Ulangi Sandi Baru',
                  validator: (v) => v != _new.text ? 'Sandi tidak sama' : null,
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Simpan Sandi Baru'),
                  ),
                ),
                if (widget.forced)
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : _logout,
                      child: const Text('Keluar',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
