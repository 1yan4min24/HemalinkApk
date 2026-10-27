import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/request_card.dart';
import '../../models/stock_request.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/stock_status_pill.dart';
import 'blood_info_sheet.dart';

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
                    _stockWidget(context, c),
                    if (c.myStockRequests.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _myStockRequests(c),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Forum Permintaan Darah',
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
                        title: 'Belum ada permintaan di forum',
                        message:
                            'Permintaan darah saat stok PMI kosong akan muncul di sini.',
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

  Widget _stockWidget(BuildContext context, AppController c) {
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
          const SizedBox(height: 6),
          const Text(
            'Ketuk golongan darah untuk melihat ketersediaan stok dan mengajukan permintaan.',
            style: TextStyle(fontSize: 11, color: AppColors.slate600),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: AppConstants.bloodTypes.map((t) {
              return Material(
                color: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showBloodInfoSheet(context, t),
                  child: Center(
                    child: Text(t,
                        style: const TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                  ),
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

  Widget _myStockRequests(AppController c) {
    final items = c.myStockRequests.take(3).toList();
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
          const Text('Pengajuan Darah Saya',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
            'PMI akan menanggapi pengajuanmu. Jika disetujui, ambil darah di PMI dengan membawa dokumen asli.',
            style: TextStyle(fontSize: 11, color: AppColors.slate500),
          ),
          const SizedBox(height: 10),
          for (final r in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  BloodBadge(label: r.bloodType),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r.bags} kantong • ${r.patientName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(Fmt.timeAgo(r.createdAt),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.slate400)),
                        if (r.adminNote.isNotEmpty)
                          Text('Tanggapan PMI: ${r.adminNote}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.slate600)),
                        if (r.status == StockRequestStatus.approved &&
                            r.pickupDeadline != null)
                          Text(
                              'Ambil sebelum ${Fmt.date(r.pickupDeadline!)} ${Fmt.hm(r.pickupDeadline!)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309))),
                      ],
                    ),
                  ),
                  StockStatusPill(status: r.status),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
