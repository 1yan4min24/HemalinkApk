import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Pengguna yang lupa sandi mengirim username + nomor HP. Admin PMI memverifikasi
/// lalu memberi sandi sementara lewat telepon/WhatsApp.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _username.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final err = await AppController.instance
        .forgotPassword(_username.text, _phone.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lupa Sandi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _sent ? _done() : _form(),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan username dan nomor HP yang Anda daftarkan. '
            'Admin ${AppConstants.pmiName} akan memverifikasi lalu menghubungi '
            'Anda untuk memberikan sandi sementara.',
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _username,
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
            controller: _phone,
            keyboardType: TextInputType.phone,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'No. HP / WhatsApp terdaftar',
              prefixIcon: Icon(Icons.phone_outlined, size: 18),
            ),
            validator: (v) => (v == null || v.trim().length < 9)
                ? 'Nomor tidak valid'
                : null,
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
                  : const Text('Kirim Permintaan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _done() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const CircleAvatar(
          radius: 32,
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(Icons.check, size: 34, color: Color(0xFF15803D)),
        ),
        const SizedBox(height: 16),
        const Text('Permintaan terkirim',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Jika data cocok, admin PMI akan menghubungi nomor HP Anda untuk '
          'memberikan sandi sementara. Setelah menerimanya, masuk dengan sandi '
          'itu dan Anda akan diminta membuat sandi baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke Login'),
          ),
        ),
      ],
    );
  }
}
