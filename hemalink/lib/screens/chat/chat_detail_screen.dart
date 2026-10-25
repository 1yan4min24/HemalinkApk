import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/empty_state.dart';

class ChatDetailScreen extends StatefulWidget {
  final String threadId;
  const ChatDetailScreen({super.key, required this.threadId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _c = AppController.instance;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await _c.sendMessage(widget.threadId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = _c.currentUser!;
    final maxW = MediaQuery.of(context).size.width * 0.75;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final t = _c.threadById(widget.threadId);
        if (t == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Percakapan tidak ditemukan',
                  message: ''));
        }
        return Scaffold(
          backgroundColor: AppColors.slate50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.slate800,
            elevation: 1,
            titleSpacing: 0,
            title: Row(
              children: [
                BloodBadge(label: t.bloodType, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.otherName(me.id),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Permohonan golongan ${t.bloodType}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: t.messages.isEmpty
                    ? const EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'Mulai percakapan',
                        message:
                            'Sampaikan kesediaan atau tanyakan detail lokasi donor.')
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: t.messages.length,
                        itemBuilder: (_, i) {
                          final m = t.messages[i];
                          final mine = m.senderId == me.id;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: maxW),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: mine ? AppColors.red : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(mine ? 16 : 0),
                                  bottomRight: Radius.circular(mine ? 0 : 16),
                                ),
                                border: mine
                                    ? null
                                    : Border.all(color: AppColors.slate100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(m.text,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: mine
                                              ? Colors.white
                                              : AppColors.slate700)),
                                  const SizedBox(height: 2),
                                  Text(Fmt.hm(m.sentAt),
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: mine
                                              ? Colors.white70
                                              : AppColors.slate400)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          onSubmitted: (_) => _send(),
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            filled: true,
                            fillColor: AppColors.slate100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _send,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child:
                                Icon(Icons.send, color: Colors.white, size: 18),
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
      },
    );
  }
}
