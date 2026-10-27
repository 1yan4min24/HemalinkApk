import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _weight;
  late final TextEditingController _height;
  late final TextEditingController _city;
  late String _bloodType;

  @override
  void initState() {
    super.initState();
    final me = AppController.instance.currentUser!;
    _name = TextEditingController(text: me.name);
    _phone = TextEditingController(text: me.phone);
    _weight = TextEditingController(text: '${me.weight}');
    _height = TextEditingController(text: '${me.height}');
    _city = TextEditingController(text: me.city);
    _bloodType = me.bloodType;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _weight, _height, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  String? _intRange(String? v, int min, int max) {
    final n = int.tryParse(v ?? '');
    return (n == null || n < min || n > max) ? 'Isi $min-$max' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    await AppController.instance.updateProfile(
      name: _name.text,
      phone: _phone.text,
      bloodType: _bloodType,
      city: _city.text,
      weight: int.parse(_weight.text),
      height: int.parse(_height.text),
    );
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Profil diperbarui.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Edit Profil', style: TextStyle(fontSize: 16))),
      backgroundColor: Colors.white,
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
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'No. HP / WhatsApp'),
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Nomor tidak valid'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bloodType,
                decoration: const InputDecoration(labelText: 'Golongan Darah'),
                items: AppConstants.bloodTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v!),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Berat (kg)'),
                      validator: (v) => _intRange(v, 20, 250),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _height,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Tinggi (cm)'),
                      validator: (v) => _intRange(v, 100, 250),
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
                    onPressed: _save, child: const Text('Simpan Perubahan')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
