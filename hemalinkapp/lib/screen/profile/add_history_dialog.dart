import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/utils/format.dart';

Future<void> showAddHistoryDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AddHistoryDialog(),
  );
}

class _AddHistoryDialog extends StatefulWidget {
  const _AddHistoryDialog();

  @override
  State<_AddHistoryDialog> createState() => _AddHistoryDialogState();
}

class _AddHistoryDialogState extends State<_AddHistoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _place = TextEditingController();
  final _reason = TextEditingController();
  final _bags = TextEditingController(text: '1');
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _place.dispose();
    _reason.dispose();
    _bags.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await AppController.instance.addHistory(
      place: _place.text,
      reason: _reason.text,
      bags: int.parse(_bags.text),
      date: _date,
    );
    if (mounted) Navigator.pop(context);
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Tambah Riwayat Donor',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _place,
                decoration: const InputDecoration(
                    labelText: 'Lokasi Donor (PMI / RS)'),
                validator: _req,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reason,
                decoration: const InputDecoration(
                    labelText: 'Alasan / Untuk Siapa',
                    hintText: 'Contoh: Donor rutin'),
                validator: _req,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bags,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Kantong'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 5) ? 'Isi 1-5' : null;
                },
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Tanggal Donor',
                      suffixIcon: Icon(Icons.calendar_today, size: 16)),
                  child: Text(Fmt.date(_date)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
