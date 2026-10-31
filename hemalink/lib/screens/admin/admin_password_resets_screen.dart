import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/password_reset.dart';
import '../../widgets/empty_state.dart';

/// Admin menangani permintaan reset sandi: verifikasi pemilik akun (telepon /
/// WhatsApp), lalu buat sandi sementara dan sampaikan kepadanya.
class AdminPasswordResetsScreen extends StatefulWidget {
  const AdminPasswordResetsScreen({super.key});

  @override
  State<AdminPasswordResetsScreen> createState() =>
      _AdminPasswordResetsScreenState();
}

class _AdminPasswordResetsScreenState extends State<AdminPasswordResetsScreen> {
  final _c = AppController.instance;
  bool _busy = false;

  Future<void> _approve(PasswordReset r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buat sandi sementara untuk ${r.name}?',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(
          'Pastikan Anda sudah memverifikasi pemilik akun, misalnya lewat '
          'telepon ke ${r.phone}.\n\nSandi lama langsung tidak berlaku dan '
          '${r.name} akan keluar dari semua perangkat.',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buat Sandi')),
        ],
      ),
    );
    if (ok != true || _busy) return;

    setState(() => _busy = true);
    final res = await _c.approvePasswordReset(r.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (res.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.error!)));
      return;
    }
    await _showTemp(r, res.tempPassword!);
  }

  Future<void> _showTemp(PasswordReset r, String temp) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Sandi sementara dibuat',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                temp,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sampaikan kepada ${r.name} (${r.phone}) lewat telepon atau '
              'WhatsApp. Sandi ini hanya ditampilkan sekali; saat masuk, '
              '${r.name} akan diminta membuat sandi baru.',
              style: const TextStyle(fontSize: 11, color: AppColors.slate600),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: temp));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Sandi disalin.')));
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin'),
          ),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Selesai')),
        ],
      ),
    );
  }

  Future<void> _reject(PasswordReset r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak permintaan?'),
        content: Text(
            'Gunakan ini bila permintaan atas nama ${r.name} tidak dapat '
            'diverifikasi. Sandinya tidak diubah.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tolak')),
        ],
      ),
    );
    if (ok == true) await _c.rejectPasswordReset(r.id);
  }

  Widget _pendingCard(PasswordReset r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text('@${r.username}  •  ${r.phone}',
              style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
          Text('Diminta ${Fmt.timeAgo(r.createdAt)}',
              style: const TextStyle(fontSize: 10, color: AppColors.slate400)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _approve(r),
                  child: const Text('Buat Sandi Sementara',
                      style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy ? null : () => _reject(r),
                child: const Text('Tolak', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyRow(PasswordReset r) {
    final done = r.status == 'done';
    final when = r.handledAt ?? r.createdAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Text('@${r.username} • ${Fmt.date(when)} ${Fmt.hm(when)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.slate400)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: done ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              done ? 'Sandi dibuat' : 'Ditolak',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: done ? const Color(0xFF15803D) : AppColors.red),
            ),
          ),
        ],
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
        title: const Text('Permintaan Reset Sandi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final all = _c.passwordResets;
          final pending = all.where((r) => r.isPending).toList();
          final handled = all.where((r) => !r.isPending).toList();
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.lock_reset,
              title: 'Belum ada permintaan',
              message: 'Permintaan reset sandi dari pengguna akan muncul di sini.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Tidak ada permintaan yang menunggu.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: AppColors.slate500)),
                ),
              for (final r in pending) ...[
                _pendingCard(r),
                const SizedBox(height: 10),
              ],
              if (handled.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 4),
                  child: Text('Riwayat terbaru',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    for (final r in handled) _historyRow(r),
                  ]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
