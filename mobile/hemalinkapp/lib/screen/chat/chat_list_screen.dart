import 'package:flutter/material.dart';
import 'chat_room_screen.dart'; // Pastikan file chat_room_screen.dart ada di folder yang sama

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pesan Donor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('Daftar komunikasi donor darah aktif Anda', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Item 1: Siti Rahma
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Text('O+', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('Siti Rahma', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Alhamdulillah, terima kasih banyak mas!...'),
            trailing: const Text('10:42'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Perhatikan: Kata 'const' dihilangkan di sini agar tidak error
                  builder: (context) => ChatRoomScreen(
                    nama: 'Siti Rahma',
                    golDarah: 'O+',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Item 2: Budi Santoso
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Text('A+', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('Budi Santoso', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Baik mas, nanti saya kabari lagi...'),
            trailing: const Text('Kemarin'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Perhatikan: Kata 'const' juga dihilangkan di sini
                  builder: (context) => ChatRoomScreen(
                    nama: 'Budi Santoso',
                    golDarah: 'A+',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}