import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../widgets/section_card.dart';
import '../auth/login_screen.dart';
import 'add_history_dialog.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar')),
        ],
      ),
    );
    if (ok != true) return;
    await AppController.instance.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppController.instance;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final me = c.currentUser;
        if (me == null) return const SizedBox.shrink();
        final last = c.lastDonorDate;
        final wait = c.daysUntilEligible;
        final histories = c.myHistories;

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [AppColors.red, AppColors.accent]),
                        border: Border.all(color: AppColors.lightRed, width: 4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('GOL DARAH',
                              style: TextStyle(
                                  color: Color(0xFFFEE2E2),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1)),
                          Text(me.bloodType,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(me.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('@${me.username}  •  ${me.phone}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate500)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: AppColors.red),
                        const SizedBox(width: 4),
                        Text(me.city,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.slate500)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: wait == 0
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        wait == 0
                            ? 'Siap donor'
                            : 'Bisa donor lagi dalam $wait hari',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: wait == 0
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309)),
                      ),
                    ),
                    if (wait > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                            'Jeda donor ${AppConstants.donorIntervalDays} hari',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.slate400)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SectionCard(
                      title: 'Data Fisik & Donor',
                      trailing: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        ),
                        child: const Text('Edit',
                            style: TextStyle(
                                color: AppColors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      child: Row(
                        children: [
                          _stat('Terakhir Donor',
                              last == null ? '-' : Fmt.date(last)),
                          _stat('Berat', '${me.weight} kg'),
                          _stat('Tinggi', '${me.height} cm'),
                          _stat('Total Donor', '${c.totalBagsDonated} ktg'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      title: 'Riwayat Donor Darah',
                      trailing: GestureDetector(
                        onTap: () => showAddHistoryDialog(context),
                        child: const Text('+ Tambah',
                            style: TextStyle(
                                color: AppColors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      child: histories.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                  'Belum ada riwayat donor. Tekan "+ Tambah" untuk mencatat donor Anda.',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.slate500)),
                            )
                          : Column(
                              children: histories
                                  .map((h) => Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.slate50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppColors.slate100),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(h.place,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text('Alasan: ${h.reason}',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .slate500)),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                      '${Fmt.date(h.date)}  •  ${h.bags} kantong',
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          color: AppColors
                                                              .slate400)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: AppColors.slate400),
                                              onPressed: () => c
                                                  .deleteHistory(h.id),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Keluar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
              color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text(label,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 9, color: AppColors.slate400)),
              const SizedBox(height: 2),
              Text(value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}
