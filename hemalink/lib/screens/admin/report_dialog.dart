import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../services/report_service.dart';

/// Pilih bulan lalu unduh rekap sebagai PDF atau CSV (bisa dibuka di Excel).
Future<void> showReportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  late final List<DateTime> _months = List.generate(12, (i) {
    final n = DateTime.now();
    return DateTime(n.year, n.month - i);
  });
  late DateTime _month = _months.first;
  bool _busy = false;

  Future<void> _run(Future<void> Function(MonthlyReport) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final report = MonthlyReport.build(AppController.instance, _month);
      await action(report);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Gagal membuat laporan: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.slate600)),
            ),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = MonthlyReport.build(AppController.instance, _month);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ekspor Laporan Bulanan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<DateTime>(
                initialValue: _month,
                decoration: const InputDecoration(labelText: 'Bulan'),
                items: [
                  for (final m in _months)
                    DropdownMenuItem<DateTime>(
                        value: m, child: Text(monthLabel(m))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _month = v);
                },
              ),
              const SizedBox(height: 12),
              _line('Total pengajuan stok', '${r.totalRequests}'),
              _line('Kantong diminta', '${r.bagsRequested}'),
              _line('Kantong keluar', '${r.bagsReleased}'),
              _line('Golongan terbanyak', r.topLabel),
              _line('Permintaan di forum', '${r.forumRequests}'),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup')),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _run((r) => r.exportCsv()),
          icon: const Icon(Icons.table_chart_outlined, size: 16),
          label: const Text('CSV (Excel)', style: TextStyle(fontSize: 12)),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : () => _run((r) => r.exportPdf()),
          icon: const Icon(Icons.picture_as_pdf, size: 16),
          label: const Text('PDF', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
