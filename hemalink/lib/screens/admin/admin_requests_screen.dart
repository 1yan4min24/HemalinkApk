import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/blood_request.dart';
import '../../models/stock_request.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stock_status_pill.dart';

/// Admin PMI: kelola & tanggapi pengajuan stok darah dan permintaan di forum.
class AdminRequestsScreen extends StatefulWidget {
  /// Filter status yang aktif saat layar dibuka (null = semua).
  final StockRequestStatus? initialFilter;
  const AdminRequestsScreen({super.key, this.initialFilter});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  final _c = AppController.instance;
  late StockRequestStatus? _filter = widget.initialFilter; // null = semua
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _bloodFilter;
  DateTimeRange? _range;

  static const _approveTemplates = [
    'Silakan ambil di PMI dengan membawa surat asli dan KTP.',
    'Disetujui. Harap ambil dalam 24 jam.',
    'Disetujui. Cek kesehatan dilakukan langsung di PMI.',
  ];
  static const _rejectTemplates = [
    'Surat rekomendasi tidak terbaca, mohon unggah ulang.',
    'Surat tidak lengkap (cap atau tanda tangan dokter belum ada).',
    'Data pasien tidak sesuai dengan surat rekomendasi.',
    'Surat bukan permintaan darah dari rumah sakit.',
  ];
  static const _cancelTemplates = [
    'Dibatalkan atas permintaan pemohon.',
    'Pemohon tidak datang mengambil darah.',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StockRequest> _applyFilters(List<StockRequest> all) {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      if (_filter != null && r.status != _filter) return false;
      if (_bloodFilter != null && r.bloodType != _bloodFilter) return false;
      final range = _range;
      if (range != null) {
        final start =
            DateTime(range.start.year, range.start.month, range.start.day);
        final end = DateTime(range.end.year, range.end.month, range.end.day)
            .add(const Duration(days: 1));
        if (r.createdAt.isBefore(start) || !r.createdAt.isBefore(end)) {
          return false;
        }
      }
      if (q.isNotEmpty) {
        final hay =
            '${r.patientName} ${r.hospital} ${r.letterNo} ${r.requesterName}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate:
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  void _resetFilters() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _bloodFilter = null;
      _range = null;
    });
  }

  Future<String?> _askNote({
    required String title,
    required String hint,
    required String confirmLabel,
    required List<String> templates,
    bool mustFill = false,
  }) {
    final ctrl = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Template cepat (ketuk untuk langsung mengirim)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in templates)
                      ActionChip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        onPressed: () => Navigator.pop(ctx, t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: hint, errorText: error),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final v = ctrl.text.trim();
                if (mustFill && v.isEmpty) {
                  setLocal(() => error = 'Wajib diisi');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(StockRequest r) async {
    final note = await _askNote(
      title: 'Setujui pengajuan',
      hint:
          'Tanggapan untuk pemohon (opsional), mis. "Ambil sebelum pukul 15.00"',
      confirmLabel: 'Setujui',
      templates: _approveTemplates,
    );
    if (note == null) return;
    await _c.approveStockRequest(r.id, note: note);
  }

  Future<void> _reject(StockRequest r) async {
    final reason = await _askNote(
      title: 'Tolak pengajuan',
      hint: 'Alasan penolakan (wajib), mis. "Surat rekomendasi tidak terbaca"',
      confirmLabel: 'Tolak',
      templates: _rejectTemplates,
      mustFill: true,
    );
    if (reason == null) return;
    await _c.rejectStockRequest(r.id, reason);
  }

  Future<void> _cancel(StockRequest r) async {
    final note = await _askNote(
      title: 'Batalkan pengajuan',
      hint:
          'Alasan pembatalan (opsional). ${r.bags} kantong ${r.bloodType} dikembalikan ke stok.',
      confirmLabel: 'Batalkan',
      templates: _cancelTemplates,
    );
    if (note == null) return;
    await _c.cancelStockRequest(r.id, note: note);
  }

  Future<void> _deleteForum(BloodRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus permintaan dari forum?'),
        content: Text(
            'Permintaan ${r.bloodType} dari ${r.requesterName} akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) await _c.deleteRequest(r.id);
  }

  Future<void> _showProof(StockRequest r, Uint8List bytes) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Bukti rekomendasi RS • ${r.patientName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.slate100,
        appBar: AppBar(
          backgroundColor: AppColors.slate900,
          foregroundColor: Colors.white,
          title: const Text('Kelola Permintaan Darah',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.slate400,
            indicatorColor: AppColors.accent,
            tabs: [Tab(text: 'Pengajuan Stok'), Tab(text: 'Forum')],
          ),
        ),
        body: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => TabBarView(
            children: [_stockTab(), _forumTab()],
          ),
        ),
      ),
    );
  }

  // ---------- tab pengajuan stok ----------
  Widget _stockTab() {
    final all = _c.allStockRequests;
    final items = _applyFilters(all);
    final hasExtra =
        _query.trim().isNotEmpty || _bloodFilter != null || _range != null;
    final range = _range;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Cari nama pasien, rumah sakit, atau no. surat',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _bloodFilter,
                      isDense: true,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.slate700),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('Semua golongan')),
                        for (final t in AppConstants.bloodTypes)
                          DropdownMenuItem<String?>(
                              value: t, child: Text('Golongan $t')),
                      ],
                      onChanged: (v) => setState(() => _bloodFilter = v),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range, size: 14),
                  label: Text(
                      range == null
                          ? 'Tanggal'
                          : '${Fmt.date(range.start)} - ${Fmt.date(range.end)}',
                      style: const TextStyle(fontSize: 11)),
                ),
                if (hasExtra)
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _chip('Semua (${all.length})', null),
              for (final s in StockRequestStatus.values)
                _chip('${s.label} (${_c.stockCount(s)})', s),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Tidak ada pengajuan',
                  message: (hasExtra || _filter != null)
                      ? 'Tidak ada pengajuan yang cocok dengan pencarian atau filter.'
                      : 'Pengajuan darah dari pengguna akan muncul di sini.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _stockTile(items[i]),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, StockRequestStatus? value) {
    final active = _filter == value;
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
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _stockTile(StockRequest r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BloodBadge(label: r.bloodType, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.requesterName} • ${r.bags} kantong',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(Fmt.timeAgo(r.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.slate400)),
                  ],
                ),
              ),
              StockStatusPill(status: r.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pasien: ${r.patientName}\n'
            'RS: ${r.hospital}\n'
            'No. surat: ${r.letterNo}\n'
            'Alasan: ${r.reason}\n'
            'HP pemohon: ${r.requesterPhone}',
            style: const TextStyle(fontSize: 11, color: AppColors.slate600),
          ),
          const SizedBox(height: 8),
          _proofPreview(r),
          if (r.status == StockRequestStatus.approved) _deadlineRow(r),
          if (r.adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Tanggapan PMI: ${r.adminNote}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.slate700)),
            ),
          ],
          if (r.status == StockRequestStatus.processing) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approve(r),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                    child:
                        const Text('Setujui', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(r),
                    child: const Text('Tolak', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ] else if (r.status == StockRequestStatus.approved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _c.completeStockRequest(r.id),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Sudah Diambil',
                        style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancel(r),
                    child:
                        const Text('Batalkan', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _deadlineRow(StockRequest r) {
    final d = r.pickupDeadline;
    if (d == null) return const SizedBox.shrink();
    final left = d.difference(DateTime.now());
    final near = left <= AppConstants.nearExpiryWindow;
    final text = left.isNegative
        ? 'Batas pengambilan terlewati'
        : 'Sisa waktu ambil: ${left.inHours} jam ${left.inMinutes % 60} menit';
    final color = near ? const Color(0xFFB45309) : AppColors.slate500;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(near ? Icons.timer_outlined : Icons.schedule,
              size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text('$text (batas ${Fmt.date(d)} ${Fmt.hm(d)})',
                style: TextStyle(fontSize: 11, color: color)),
          ),
          if (near)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Hampir kedaluwarsa',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309))),
            ),
        ],
      ),
    );
  }

  Widget _proofPreview(StockRequest r) {
    return FutureBuilder<Uint8List?>(
      future: _c.stockAttachment(r.id),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) {
          return const Text(
              'Bukti rekomendasi: tidak tersedia di perangkat ini.',
              style: TextStyle(fontSize: 11, color: AppColors.slate400));
        }
        return InkWell(
          onTap: () => _showProof(r, bytes),
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(bytes,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) => Container(
                        height: 110,
                        color: AppColors.slate100,
                        alignment: Alignment.center,
                        child: const Text('Pratinjau tidak tersedia',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.slate500)))),
              ),
              Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Ketuk untuk memperbesar',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- tab forum ----------
  Widget _forumTab() {
    final items = _c.visibleRequests;
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'Forum kosong',
        message: 'Belum ada permintaan darah di forum.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BloodBadge(label: r.bloodType, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.requesterName} • ${r.bags} kantong',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${r.hospital}\n${r.reason}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate600)),
                    const SizedBox(height: 2),
                    Text(Fmt.timeAgo(r.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.slate400)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus dari forum',
                onPressed: () => _deleteForum(r),
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
              ),
            ],
          ),
        );
      },
    );
  }
}
