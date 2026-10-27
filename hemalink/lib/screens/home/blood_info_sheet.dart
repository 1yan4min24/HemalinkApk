import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/blood_utils.dart';
import '../../widgets/blood_badge.dart';
import '../request/request_form_dialog.dart';
import '../request/stock_request_dialog.dart';

/// Info golongan darah + ketersediaan stok. [context] dipakai untuk membuka
/// dialog setelah sheet ditutup.
Future<void> showBloodInfoSheet(BuildContext context, String bloodType) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _BloodInfoSheet(type: bloodType, rootContext: context),
  );
}

class _BloodInfoSheet extends StatelessWidget {
  final String type;
  final BuildContext rootContext;
  const _BloodInfoSheet({required this.type, required this.rootContext});

  @override
  Widget build(BuildContext context) {
    final c = AppController.instance;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final n = c.stock[type] ?? 0;
        final available = n > 0;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.slate200,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    BloodBadge(label: type, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Golongan $type',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(AppConstants.pmiName,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.slate500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: available
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(available ? Icons.check_circle : Icons.error_outline,
                          color: available
                              ? const Color(0xFF15803D)
                              : AppColors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          available
                              ? 'Tersedia $n kantong'
                              : 'Stok darah kosong',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: available
                                  ? const Color(0xFF15803D)
                                  : AppColors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _label('Dapat mendonorkan ke'),
                _chips(BloodUtils.canDonateTo(type, AppConstants.bloodTypes)),
                const SizedBox(height: 12),
                _label('Dapat menerima dari'),
                _chips(
                    BloodUtils.canReceiveFrom(type, AppConstants.bloodTypes)),
                const SizedBox(height: 12),
                Text(BloodUtils.note(type),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.slate600)),
                const SizedBox(height: 18),
                if (available) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showStockRequestDialog(rootContext, type);
                      },
                      icon: const Icon(Icons.bloodtype, size: 18),
                      label: const Text('Ajukan Permintaan Darah',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pengajuan pertama langsung mengunci stok atas nama pemohon sampai admin PMI mengonfirmasi.',
                    style: TextStyle(fontSize: 10, color: AppColors.slate400),
                  ),
                ] else ...[
                  const Text(
                    'Stok golongan ini sedang kosong. Anda dapat mengajukan permintaan ke forum agar pendonor bisa menghubungi Anda.',
                    style: TextStyle(fontSize: 11, color: AppColors.slate600),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showRequestFormDialog(rootContext, bloodType: type);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slate800),
                      icon: const Icon(Icons.forum_outlined, size: 18),
                      label: const Text('Ajukan ke Forum Pendonor',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.slate700)),
      );

  Widget _chips(List<String> items) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items
            .map((t) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.lightRed,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(t,
                      style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ))
            .toList(),
      );
}
