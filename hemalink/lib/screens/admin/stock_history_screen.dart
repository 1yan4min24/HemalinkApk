import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/empty_state.dart';

/// Riwayat setiap perubahan stok darah (untuk audit).
class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final _c = AppController.instance;
  String? _type; // null = semua golongan

  Widget _chip(String label, String? value) {
    final active = _type == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: active ? Colors.white : AppColors.slate600)),
        selected: active,
        selectedColor: AppColors.red,
        backgroundColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => setState(() => _type = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        title: const Text('Riwayat Perubahan Stok',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final logs = _c.stockLogs
              .where((l) => _type == null || l.bloodType == _type)
              .toList();
          return Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _chip('Semua', null),
                    for (final t in AppConstants.bloodTypes) _chip(t, t),
                  ],
                ),
              ),
              Expanded(
                child: logs.isEmpty
                    ? const EmptyState(
                        icon: Icons.history,
                        title: 'Belum ada riwayat',
                        message:
                            'Setiap perubahan stok akan tercatat di sini.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: logs.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          if (i == logs.length) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                  'Menampilkan maksimal 500 perubahan terakhir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.slate400)),
                            );
                          }
                          final l = logs[i];
                          final up = l.delta > 0;
                          final color = up ? AppColors.green : AppColors.red;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.slate100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BloodBadge(label: l.bloodType, size: 36),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${l.before} -> ${l.after} kantong  (${up ? '+' : ''}${l.delta})',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: color)),
                                      const SizedBox(height: 2),
                                      Text(l.reason,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.slate700)),
                                      const SizedBox(height: 2),
                                      Text(
                                          'Oleh ${l.actor} • ${Fmt.date(l.at)} ${Fmt.hm(l.at)}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.slate400)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
