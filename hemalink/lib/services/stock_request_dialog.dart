import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Form pengajuan pengambilan darah langsung dari stok PMI.
Future<void> showStockRequestDialog(BuildContext context, String bloodType) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StockRequestDialog(bloodType: bloodType),
  );
}

class _StockRequestDialog extends StatefulWidget {
  final String bloodType;
  const _StockRequestDialog({required this.bloodType});

  @override
  State<_StockRequestDialog> createState() => _StockRequestDialogState();
}

class _StockRequestDialogState extends State<_StockRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _hospital = TextEditingController();
  final _reason = TextEditingController();
  final _letterNo = TextEditingController();
  final _bags = TextEditingController(text: '1');
  Uint8List? _proofBytes;
  String? _proofName;
  String? _proofError;
  bool _agree = false;
  bool _showAgreeError = false;
  bool _busy = false;
  bool _picking = false;

  @override
  void dispose() {
    _patient.dispose();
    _hospital.dispose();
    _reason.dispose();
    _letterNo.dispose();
    _bags.dispose();
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _pickProof(ImageSource source) async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _proofError = null;
    });
    try {
      final x = await ImagePicker()
          .pickImage(source: source, maxWidth: 1280, imageQuality: 70);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      if (bytes.length > AppConstants.maxAttachmentBytes) {
        setState(() => _proofError =
            'Ukuran foto terlalu besar (maks. 1,5 MB). Pilih foto yang lebih kecil.');
        return;
      }
      setState(() {
        _proofBytes = bytes;
        _proofName = x.name;
        _proofError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _proofError = 'Gagal membuka foto. Coba lagi.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Widget _proofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bukti Rekomendasi Rumah Sakit',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.slate700)),
        const SizedBox(height: 2),
        const Text('Foto/scan surat rekomendasi atau permintaan darah dari RS.',
            style: TextStyle(fontSize: 11, color: AppColors.slate500)),
        const SizedBox(height: 8),
        if (_proofBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.memory(
                _proofBytes!,
                fit: BoxFit.cover,
                cacheWidth: 600,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.slate100,
                  alignment: Alignment.center,
                  child: const Text('Pratinjau tidak tersedia (file tetap terlampir)',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 11, color: AppColors.slate500)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(_proofName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.slate500)),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _proofBytes = null;
                  _proofName = null;
                }),
                child: const Text('Hapus', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ] else if (_picking)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Memproses foto...', style: TextStyle(fontSize: 11)),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickProof(ImageSource.gallery),
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Pilih Foto',
                      style: TextStyle(fontSize: 11)),
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickProof(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 16),
                    label:
                        const Text('Kamera', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ],
          ),
        if (_proofError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_proofError!,
                style: const TextStyle(fontSize: 11, color: Colors.red)),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() {
      _showAgreeError = !_agree;
      if (_proofBytes == null && _proofError == null) {
        _proofError = 'Unggah foto surat rekomendasi rumah sakit.';
      }
    });
    if (!formOk || !_agree || _proofBytes == null || _busy) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final bags = int.parse(_bags.text);
    final err = await AppController.instance.requestStock(
      bloodType: widget.bloodType,
      bags: bags,
      patientName: _patient.text,
      hospital: _hospital.text,
      reason: _reason.text,
      letterNo: _letterNo.text,
      attachment: _proofBytes!,
      attachmentName: _proofName ?? 'bukti.jpg',
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
        content: Text(
            '$bags kantong golongan ${widget.bloodType} sudah dicatat atas nama Anda. '
            'Silakan ambil di PMI, admin akan mengonfirmasi.')));
  }

  @override
  Widget build(BuildContext context) {
    final me = AppController.instance.currentUser!;
    final maxBags = AppController.instance.stock[widget.bloodType] ?? 0;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ajukan Permintaan Darah ke PMI',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Persyaratan pengambilan darah di PMI',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309))),
                    for (final r in AppConstants.pmiRequirements)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text('• $r',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.slate700)),
                      ),
                    const SizedBox(height: 4),
                    const Text(AppConstants.healthCheckNote,
                        style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.slate700)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: me.name,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Nama Pemohon'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: 'Golongan ${widget.bloodType} (stok $maxBags kantong)',
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Darah Diminta'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _patient,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Pasien'),
                validator: _req,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _hospital,
                decoration: const InputDecoration(
                  labelText: 'Rumah Sakit / Ruangan',
                  hintText: 'Nama RS dan ruangan',
                ),
                validator: _req,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _letterNo,
                decoration: const InputDecoration(
                  labelText: 'No. Surat Keterangan Rumah Sakit',
                ),
                validator: _req,
              ),
              const SizedBox(height: 12),
              _proofSection(),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reason,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alasan / Diagnosis Singkat',
                  hintText: 'Contoh: Operasi melahirkan darurat',
                ),
                validator: _req,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bags,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Jumlah Kantong (maks. $maxBags)'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > maxBags)
                      ? 'Isi 1-$maxBags'
                      : null;
                },
              ),
              const SizedBox(height: 6),
              CheckboxListTile(
                value: _agree,
                onChanged: (v) => setState(() => _agree = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                    'Saya akan membawa surat keterangan rumah sakit dan identitas asli ke PMI.',
                    style: TextStyle(fontSize: 11)),
              ),
              if (_showAgreeError && !_agree)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Centang untuk melanjutkan',
                      style: TextStyle(fontSize: 11, color: Colors.red)),
                ),
            ],
          ),
        ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Kirim Pengajuan'),
        ),
      ],
    );
  }
}
