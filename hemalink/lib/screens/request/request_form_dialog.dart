import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Form permintaan ke forum pendonor (dipakai saat stok PMI kosong).
Future<void> showRequestFormDialog(BuildContext context, {String? bloodType}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _RequestFormDialog(presetBloodType: bloodType),
  );
}

class _RequestFormDialog extends StatefulWidget {
  final String? presetBloodType;
  const _RequestFormDialog({this.presetBloodType});

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
  void initState() {
    super.initState();
    _bloodType = widget.presetBloodType;
  }

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
    final err = await AppController.instance.addRequest(
      bloodType: _bloodType!,
      bags: int.parse(_bags.text),
      reason: _reason.text,
      hospital: _hospital.text,
    );
    if (!mounted) return;
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(
        content: Text(
            'Permintaan terkirim ke forum dan langsung tampil ke pendonor.')));
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final me = AppController.instance.currentUser!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ajukan ke Forum Pendonor',
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
                initialValue: _bloodType,
                decoration: const InputDecoration(
                    labelText: 'Golongan Darah Yang Dibutuhkan'),
                style: const TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.bold),
                items: AppConstants.bloodTypes
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text('Golongan $t')))
                    .toList(),
                onChanged: widget.presetBloodType == null
                    ? (v) => setState(() => _bloodType = v)
                    : null,
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
                decoration: const InputDecoration(labelText: 'Jumlah Kantong'),
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
