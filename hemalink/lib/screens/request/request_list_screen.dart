import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/blood_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/request_card.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  String _filter = 'Semua';
  static final _filters = ['Semua', ...AppConstants.bloodGroups.map((g) => 'Gol $g')];

  @override
  Widget build(BuildContext context) {
    final c = AppController.instance;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            var items = c.visibleRequests;
            if (_filter != 'Semua') {
              final g = _filter.replaceFirst('Gol ', '');
              items = items
                  .where((r) => BloodUtils.group(r.bloodType) == g)
                  .toList();
            }
            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Forum Permintaan Darah',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((f) {
                            final active = _filter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(f,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: active
                                            ? Colors.white
                                            : AppColors.slate600)),
                                selected: active,
                                showCheckmark: false,
                                selectedColor: AppColors.red,
                                backgroundColor: AppColors.slate100,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                onSelected: (_) =>
                                    setState(() => _filter = f),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'Tidak ada permintaan',
                          message:
                              'Belum ada permintaan di forum untuk filter ini.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => RequestCard(request: items[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
