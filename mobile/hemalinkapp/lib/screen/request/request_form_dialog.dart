import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

Future<void> showRequestFormDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _RequestFormDialog(),
  );
}

class _RequestFormDialog extends StatefulWidget {
  const _RequestFormDialog();

  @override
  State<_RequestFormDialog> createState() => _RequestFormDialogState();
}

class _RequestFormDialogState extends State<_RequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _hospital = TextEditingController();
  final _bags = TextEditingController();
  String? _bloodType;

  @override
  void dispose() {
    _reason.dispose();
    _hospital.dispose();
    _bags.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    await AppController.instance.addRequest(
      bloodType: _bloodType!,
      bags: int.parse(_bags.text),
      reason: _reason.text,
      hospital: _hospital.text,
    );
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(
        content: Text(
            'Permohonan terkirim. Akan tampil ke pendonor setelah diverifikasi PMI.')));
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final me = AppController.instance.currentUser!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ajukan Permohonan Darah',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: me.name,
                readOnly: true,
                decoration:
                    const InputDecoration(labelText: 'Nama Akun/Pemohon'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _bloodType,
                decoration: const InputDecoration(
                    labelText: 'Golongan Darah Yang Dibutuhkan'),
                style: const TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.bold),
                items: AppConstants.bloodTypes
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text('Golongan $t')))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v),
                validator: (v) => v == null ? 'Pilih golongan darah' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reason,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alasan Butuh Darah',
                  hintText: 'Contoh: Operasi melahirkan darurat',
                ),
                validator: _req,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _hospital,
                decoration: const InputDecoration(
                  labelText: 'Rumah Sakit / Lokasi',
                  hintText: 'Nama RS dan ruangan',
                ),
                validator: _req,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bags,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Jumlah Kantong'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 20) ? 'Isi 1-20' : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(onPressed: _submit, child: const Text('Kirim')),
      ],
    );
  }
}
