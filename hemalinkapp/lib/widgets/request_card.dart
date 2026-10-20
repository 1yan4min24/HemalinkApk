import 'package:flutter/material.dart';
import '../controllers/app_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/blood_utils.dart';
import '../core/utils/format.dart';
import '../models/blood_request.dart';
import '../screens/chat/chat_detail_screen.dart';
import 'blood_badge.dart';

class RequestCard extends StatelessWidget {
  final BloodRequest request;
  const RequestCard({super.key, required this.request});

  Future<void> _openChat(BuildContext context) async {
    final me = AppController.instance.currentUser;
    if (me == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
      }
      return;
    }

    final thread = await AppController.instance.startChat(request);
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailScreen(threadId: thread.id)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    // ✅ Simpan context sebelum dipakai
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus permohonan?'),
        content: const Text('Permohonan ini akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await AppController.instance.deleteRequest(request.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = AppController.instance.currentUser;

    if (me == null) {
      return _buildUnauthenticatedView();
    }

    final isMine = request.requesterId == me.id;
    final compatible =
        !isMine && BloodUtils.canDonate(me.bloodType, request.bloodType);

    return _buildCardView(context, isMine, compatible);
  }

  Widget _buildCardView(BuildContext context, bool isMine, bool compatible) {
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
              BloodBadge(label: request.bloodType),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMine
                          ? '${request.requesterName} (Anda)'
                          : request.requesterName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      Fmt.timeAgo(request.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              _pill(
                'Butuh ${request.bags} Kantong',
                const Color(0xFFFEE2E2),
                AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _pill(
                'Golongan ${request.bloodType}',
                AppColors.lightRed,
                AppColors.red,
              ),
              if (compatible)
                _pill(
                  'Cocok dengan golongan darah Anda',
                  const Color(0xFFDCFCE7),
                  const Color(0xFF15803D),
                ),
              if (isMine)
                request.verified
                    ? _pill(
                        'Terverifikasi PMI',
                        const Color(0xFFDCFCE7),
                        const Color(0xFF15803D),
                      )
                    : _pill(
                        'Menunggu verifikasi PMI',
                        const Color(0xFFFEF3C7),
                        const Color(0xFFB45309),
                      ),
            ],
          ),
          const SizedBox(height: 8),
          _line('Alasan', request.reason),
          const SizedBox(height: 4),
          _line('Lokasi RS', request.hospital),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: isMine
                ? OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text(
                      'Hapus Permohonan',
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _openChat(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.slate800,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text(
                      'Mulai Komunikasi (Chat)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
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
              BloodBadge(label: request.bloodType),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      Fmt.timeAgo(request.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              _pill(
                'Butuh ${request.bags} Kantong',
                const Color(0xFFFEE2E2),
                AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _pill(
                'Golongan ${request.bloodType}',
                AppColors.lightRed,
                AppColors.red,
              ),
              request.verified
                  ? _pill(
                      'Terverifikasi PMI',
                      const Color(0xFFDCFCE7),
                      const Color(0xFF15803D),
                    )
                  : _pill(
                      'Menunggu verifikasi PMI',
                      const Color(0xFFFEF3C7),
                      const Color(0xFFB45309),
                    ),
            ],
          ),
          const SizedBox(height: 8),
          _line('Alasan', request.reason),
          const SizedBox(height: 4),
          _line('Lokasi RS', request.hospital),
        ],
      ),
    );
  }

  Widget _pill(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          t,
          style:
              TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );

  Widget _line(String k, String v) => RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: AppColors.slate600),
          children: [
            TextSpan(
              text: '$k: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
            TextSpan(text: v),
          ],
        ),
      );
}
