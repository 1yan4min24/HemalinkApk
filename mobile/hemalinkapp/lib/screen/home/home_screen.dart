import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/request_card.dart';
import '../request/request_form_dialog.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSeeRequests;
  const HomeScreen({super.key, required this.onSeeRequests});

  @override
  Widget build(BuildContext context) {
    final c = AppController.instance;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final me = c.currentUser;
        if (me == null) return const SizedBox.shrink();
        final latest = c.visibleRequests.take(3).toList();
        return SingleChildScrollView(
          child: Column(
            children: [
              _header(me.name, me.city),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _requestButton(context),
                    const SizedBox(height: 16),
                    _stockWidget(c),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Permohonan Terbaru',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        if (c.visibleRequests.length > 3)
                          TextButton(
                              onPressed: onSeeRequests,
                              child: const Text('Lihat semua')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (latest.isEmpty)
                      const EmptyState(
                        icon: Icons.bloodtype_outlined,
                        title: 'Belum ada permohonan',
                        message:
                            'Permohonan darah yang sudah diverifikasi PMI akan muncul di sini.',
                      )
                    else
                      for (final r in latest) ...[
                        RequestCard(request: r),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(String name, String city) {
    final shortCity = city.split(',').first.replaceFirst('Kota ', '');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.red, AppColors.darkRed],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELAMAT DATANG',
                        style: TextStyle(
                            color: Color(0xFFFECACA),
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600)),
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Color(0xFFFECACA)),
                    const SizedBox(width: 4),
                    Text(shortCity,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
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
              color: Colors.white12,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('"Setetes darah anda, harapan hidup masyarakat Ternate."',
                    style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                SizedBox(height: 4),
                Text(
                    'HemaLink menghubungkan langsung pendonor sukarela dengan pasien yang membutuhkan darah.',
                    style: TextStyle(color: Color(0xFFFEE2E2), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showRequestFormDialog(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Icon(Icons.add, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ajukan Permohonan Darah',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text('Butuh donor cepat? Buat permohonan baru',
                      style: TextStyle(color: Color(0xFFFEE2E2), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _stockWidget(AppController c) {
    final updated = c.stockUpdatedAt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_hospital, size: 16, color: AppColors.red),
              SizedBox(width: 6),
              Expanded(
                child: Text('Stok Darah PMI',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place, size: 12, color: AppColors.slate400),
              SizedBox(width: 4),
              Expanded(
                child: Text(AppConstants.pmiAddress,
                    style: TextStyle(fontSize: 11, color: AppColors.slate500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.35,
            children: AppConstants.bloodTypes.map((t) {
              final n = c.stock[t] ?? 0;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t,
                        style: const TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                    Text('$n Ktg',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: n <= 2 ? Colors.red : AppColors.slate600)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            updated == null
                ? 'Belum ada pembaruan stok dari PMI.'
                : 'Diperbarui ${Fmt.timeAgo(updated)}',
            style: const TextStyle(fontSize: 10, color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}
