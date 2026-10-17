import 'package:flutter/material.dart';
import 'package:hemalinkapp/screen/chat/chat_list_screen.dart'; // <-- Hapus tulisan lib/ yang kedua

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatListScreen(), // <-- Hapus kata 'const' di sini
    );
  }
}