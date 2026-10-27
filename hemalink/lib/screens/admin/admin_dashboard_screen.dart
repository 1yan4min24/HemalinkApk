import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/stock_request.dart';
import '../../widgets/section_card.dart';
import 'admin_requests_screen.dart';
import 'report_dialog.dart';
import 'stock_history_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _c = AppController.instance;
  late final Map<String, TextEditingController> _ctrls;
  int _lastWaiting = 0;
  final Map<String, String> _synced = {}; // nilai stok terakhir dari server per kolom
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final t in AppConstants.bloodTypes)
        t: TextEditingController(text: '${_c.stock[t] ?? 0}')
    };
    _lastWaiting = _c.stockCount(StockRequestStatus.processing);
    for (final t in AppConstants.bloodTypes) {
      _synced[t] = _ctrls[t]!.text;
    }
    _c.addListener(_onControllerChange);
    // Cek pengajuan yang lewat batas pengambilan setiap menit.
    _expiryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _c.expireOverdueStockRequests();
    });
    // Saat admin baru masuk: tampilkan pengingat untuk memeriksa pengajuan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showBriefing();
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _c.removeListener(_onControllerChange);
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Pemberitahuan saat ada pengajuan baru masuk ketika admin sedang membuka dashboard.
  void _onControllerChange() {
    // Stok bisa berubah dari pengajuan pengguna: perbarui kolom yang belum diedit admin.
    for (final t in AppConstants.bloodTypes) {
      final fresh = '${_c.stock[t] ?? 0}';
      final ctrl = _ctrls[t]!;
      if (ctrl.text == _synced[t]) {
        ctrl.text = fresh;
        _synced[t] = fresh;
      } else if (ctrl.text == fresh) {
        _synced[t] = fresh;
      }
    }
    final n = _c.stockCount(StockRequestStatus.processing);
    if (n > _lastWaiting && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Pengajuan baru masuk. $n menunggu tanggapan.'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Periksa',
            onPressed: () => _openRequests(StockRequestStatus.processing),
          ),
        ));
    }
    _lastWaiting = n;
  }

  void _openRequests([StockRequestStatus? filter]) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AdminRequestsScreen(initialFilter: filter)),
    );
  }

  Future<void> _showBriefing() async {
    final waiting = _c.stockCount(StockRequestStatus.processing);
    final approved = _c.stockCount(StockRequestStatus.approved);
    final empty =
        AppConstants.bloodTypes.where((t) => (_c.stock[t] ?? 0) <= 0).toList();
    final low = _c.lowStockTypes;
    final near = _c.nearExpiryCount;
    if (waiting == 0 && approved == 0 && empty.isEmpty && low.isEmpty) return;

    final hasPending = waiting > 0 || approved > 0;
    Widget line(IconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    final go = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(waiting > 0 ? Icons.notifications_active : Icons.info_outline,
                color: waiting > 0 ? AppColors.red : AppColors.slate600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  waiting > 0
                      ? 'Ada pengajuan yang menunggu'
                      : 'Ringkasan untuk Admin',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (waiting > 0)
              const Text(
                'Silakan periksa dan tanggapi pengajuan darah dari pengguna terlebih dahulu.',
                style: TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
            if (waiting > 0)
              line(Icons.hourglass_top, const Color(0xFFB45309),
                  '$waiting pengajuan menunggu tanggapan'),
            if (approved > 0)
              line(Icons.check_circle_outline, const Color(0xFF1D4ED8),
                  '$approved disetujui, belum ditandai sudah diambil'),
            if (near > 0)
              line(Icons.timer_outlined, const Color(0xFFB45309),
                  '$near pengajuan hampir kedaluwarsa (batas ambil kurang dari ${AppConstants.nearExpiryWindow.inHours} jam)'),
            if (empty.isNotEmpty)
              line(Icons.warning_amber_rounded, AppColors.red,
                  'Stok kosong: ${empty.join(', ')}'),
            if (low.isNotEmpty)
              line(Icons.warning_amber_rounded, const Color(0xFFA16207),
                  'Stok menipis: ${low.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(hasPending ? 'Nanti' : 'Mengerti')),
          if (hasPending)
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(waiting > 0 ? 'Periksa Sekarang' : 'Lihat Pengajuan'),
            ),
        ],
      ),
    );
    if (go == true && mounted) {
      _openRequests(waiting > 0
          ? StockRequestStatus.processing
          : StockRequestStatus.approved);
    }
  }

  Widget _alertBanner(int waiting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$waiting pengajuan menunggu tanggapan',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.red)),
                const Text('Periksa bukti rekomendasi lalu setujui atau tolak.',
                    style: TextStyle(fontSize: 11, color: AppColors.slate600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _openRequests(StockRequestStatus.processing),
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: const Text('Periksa', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
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
    final err = await _c.updateStock(newStock);
    messenger.showSnackBar(
        SnackBar(content: Text(err ?? 'Stok darah berhasil diperbarui.')));
  }

  Future<void> _copyReport() async {
    final b = StringBuffer()
      ..writeln('LAPORAN HEMALINK - ${AppConstants.pmiName}')
      ..writeln('Tanggal: ${Fmt.date(DateTime.now())}')
      ..writeln('')
      ..writeln('Pengguna terdaftar: ${_c.totalUsers}')
      ..writeln('Pendonor dengan riwayat: ${_c.totalDonorsWithHistory}')
      ..writeln('Total kantong tercatat: ${_c.totalBagsRecorded}')
      ..writeln('Permintaan di forum: ${_c.activeRequests}')
      ..writeln(
          'Pengajuan stok menunggu tanggapan: ${_c.stockCount(StockRequestStatus.processing)}')
      ..writeln(
          'Pengajuan stok disetujui: ${_c.stockCount(StockRequestStatus.approved)}')
      ..writeln(
          'Pengajuan stok sudah diambil: ${_c.stockCount(StockRequestStatus.completed)}')
      ..writeln(
          'Pengajuan stok ditolak: ${_c.stockCount(StockRequestStatus.rejected)}')
      ..writeln(
          'Pengajuan stok dibatalkan: ${_c.stockCount(StockRequestStatus.cancelled)}')
      ..writeln('')
      ..writeln('Stok darah:');
    for (final t in AppConstants.bloodTypes) {
      b.writeln('- $t: ${_c.stock[t] ?? 0} kantong');
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ringkasan laporan disalin ke clipboard.')));
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
                Row(
                  children: [
                    ListenableBuilder(
                      listenable: _c,
                      builder: (context, _) {
                        final n = _c.stockCount(StockRequestStatus.processing);
                        return IconButton(
                          onPressed: () =>
                              _openRequests(StockRequestStatus.processing),
                          tooltip: 'Pengajuan menunggu tanggapan',
                          icon: Badge(
                            isLabelVisible: n > 0,
                            label: Text('$n'),
                            child: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: _logout,
                      tooltip: 'Keluar',
                      icon: const Icon(Icons.logout, color: AppColors.slate400),
                    ),
                  ],
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
                  if (_c.stockCount(StockRequestStatus.processing) > 0)
                    _alertBanner(_c.stockCount(StockRequestStatus.processing)),
                  _statsRow(),
                  const SizedBox(height: 12),
                  _stockCard(),
                  const SizedBox(height: 12),
                  _stockRequestCard(),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Laporan',
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => showReportDialog(context),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text(
                                'Ekspor Laporan Bulanan (PDF/CSV)',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _copyReport,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Salin Ringkasan Laporan',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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
      item('Permintaan Forum', _c.activeRequests),
      item('Menunggu Tanggapan', _c.processingStockRequests.length),
      item('Kantong Tercatat', _c.totalBagsRecorded),
    ]);
  }

  Widget _stockCard() {
    final low = _c.lowStockTypes;
    return SectionCard(
      title: 'Kelola Stok Darah PMI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (low.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFACC15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFFA16207)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stok menipis (di bawah ${AppConstants.lowStockThreshold} kantong): ${low.join(', ')}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA16207)),
                    ),
                  ),
                ],
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: _ctrls.entries.map((e) {
              final n = _c.stock[e.key] ?? 0;
              final isLow = n > 0 && n < AppConstants.lowStockThreshold;
              final isEmpty = n <= 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isLow
                      ? const Color(0xFFFEF9C3)
                      : isEmpty
                          ? const Color(0xFFFEF2F2)
                          : AppColors.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLow
                        ? const Color(0xFFFACC15)
                        : isEmpty
                            ? const Color(0xFFFECACA)
                            : AppColors.slate200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(e.key,
                            style: const TextStyle(
                                color: AppColors.red,
                                fontWeight: FontWeight.bold)),
                        if (isLow) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: Color(0xFFA16207)),
                        ],
                      ],
                    ),
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
              );
            }).toList(),
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
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockHistoryScreen()),
              ),
              icon: const Icon(Icons.history, size: 16),
              label: const Text('Riwayat Perubahan Stok',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockRequestCard() {
    final waiting = _c.stockCount(StockRequestStatus.processing);
    final approved = _c.stockCount(StockRequestStatus.approved);
    Widget line(String label, int n) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.slate600)),
              ),
              Text('$n',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );
    return SectionCard(
      title: 'Pengajuan & Permintaan Darah',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line('Menunggu tanggapan', waiting),
          line('Disetujui (siap diambil)', approved),
          line('Sudah diambil', _c.stockCount(StockRequestStatus.completed)),
          line('Ditolak', _c.stockCount(StockRequestStatus.rejected)),
          line('Dibatalkan', _c.stockCount(StockRequestStatus.cancelled)),
          line('Permintaan di forum', _c.activeRequests),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openRequests(
                  waiting > 0 ? StockRequestStatus.processing : null),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: Text(
                  waiting > 0
                      ? 'Kelola & Tanggapi ($waiting baru)'
                      : 'Kelola & Tanggapi',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
