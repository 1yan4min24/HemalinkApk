import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../widgets/section_card.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _c = AppController.instance;
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final t in AppConstants.bloodTypes)
        t: TextEditingController(text: '${_c.stock[t] ?? 0}')
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveStock() async {
    final messenger = ScaffoldMessenger.of(context);
    final newStock = <String, int>{};
    for (final e in _ctrls.entries) {
      final n = int.tryParse(e.value.text);
      if (n == null || n < 0) {
        messenger.showSnackBar(SnackBar(
            content: Text('Stok ${e.key} harus berupa angka 0 atau lebih.')));
        return;
      }
      newStock[e.key] = n;
    }
    await _c.updateStock(newStock);
    messenger.showSnackBar(
        const SnackBar(content: Text('Stok darah berhasil diperbarui.')));
  }

  Future<void> _copyReport() async {
    final b = StringBuffer()
      ..writeln('LAPORAN HEMALINK - ${AppConstants.pmiName}')
      ..writeln('Tanggal: ${Fmt.date(DateTime.now())}')
      ..writeln('')
      ..writeln('Pengguna terdaftar: ${_c.totalUsers}')
      ..writeln('Pendonor dengan riwayat: ${_c.totalDonorsWithHistory}')
      ..writeln('Total kantong tercatat: ${_c.totalBagsRecorded}')
      ..writeln('Permohonan aktif: ${_c.activeRequests}')
      ..writeln('Permohonan menunggu verifikasi: ${_c.pendingRequests.length}')
      ..writeln('')
      ..writeln('Stok darah:');
    for (final t in AppConstants.bloodTypes) {
      b.writeln('- $t: ${_c.stock[t] ?? 0} kantong');
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ringkasan laporan disalin ke clipboard.')));
  }

  Future<void> _logout() async {
    await _c.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.slate900,
            padding: const EdgeInsets.fromLTRB(16, 52, 8, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADMINISTRATOR',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    SizedBox(height: 2),
                    Text(AppConstants.pmiName,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
                IconButton(
                  onPressed: _logout,
                  tooltip: 'Keluar',
                  icon: const Icon(Icons.logout, color: AppColors.slate400),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _c,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _statsRow(),
                  const SizedBox(height: 12),
                  _stockCard(),
                  const SizedBox(height: 12),
                  _verifyCard(),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Laporan',
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _copyReport,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Salin Ringkasan Laporan',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    Widget item(String label, int value) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.red)),
                const SizedBox(height: 2),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.slate500)),
              ],
            ),
          ),
        );
    return Row(children: [
      item('Pengguna', _c.totalUsers),
      item('Permohonan Aktif', _c.activeRequests),
      item('Menunggu Verifikasi', _c.pendingRequests.length),
      item('Kantong Tercatat', _c.totalBagsRecorded),
    ]);
  }

  Widget _stockCard() {
    return SectionCard(
      title: 'Kelola Stok Darah PMI',
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: _ctrls.entries
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: const TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 56,
                            child: TextField(
                              controller: e.value,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 4)),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveStock,
              child: const Text('Simpan Update Stok',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifyCard() {
    final pending = _c.pendingRequests;
    return SectionCard(
      title: 'Verifikasi Permohonan User',
      child: pending.isEmpty
          ? const Text('Tidak ada permohonan yang menunggu verifikasi.',
              style: TextStyle(fontSize: 11, color: AppColors.slate500))
          : Column(
              children: pending
                  .map((r) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${r.requesterName} • ${r.bloodType} • ${r.bags} kantong',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('${r.hospital}\n${r.reason}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.slate500)),
                            const SizedBox(height: 2),
                            Text(Fmt.timeAgo(r.createdAt),
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.slate400)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _c.approveRequest(r.id),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.green,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8)),
                                    child: const Text('Setujui',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _c.deleteRequest(r.id),
                                    child: const Text('Tolak / Hapus',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
