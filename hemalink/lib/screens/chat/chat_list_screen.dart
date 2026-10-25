import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/empty_state.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppController.instance;
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.red,
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 14),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pesan Donor',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17)),
              SizedBox(height: 4),
              Text('Daftar komunikasi donor darah Anda',
                  style: TextStyle(color: Color(0xFFFEE2E2), fontSize: 11)),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: c,
            builder: (context, _) {
              final me = c.currentUser;
              final threads = c.myThreads;
              if (me == null) return const SizedBox.shrink();
              if (threads.isEmpty) {
                return const EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'Belum ada percakapan',
                  message:
                      'Buka tab Donor lalu tekan "Mulai Komunikasi" pada permohonan untuk menghubungi pemohon.',
                );
              }
              return Container(
                color: Colors.white,
                child: ListView.separated(
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = threads[i];
                    final last = t.messages.isEmpty ? null : t.messages.last;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      leading: BloodBadge(label: t.bloodType, size: 44),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(t.otherName(me.id),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          Text(Fmt.chatTime(t.updatedAt),
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.slate400)),
                        ],
                      ),
                      subtitle: Text(
                          last == null
                              ? 'Belum ada pesan'
                              : (last.senderId == me.id
                                  ? 'Anda: ${last.text}'
                                  : last.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.slate500)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(threadId: t.id)),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
