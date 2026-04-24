// lib/main.dart
import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
// Jika Anda nanti membuat file app_theme.dart, import di sini.

void main() {
  runApp(const CafeJobApp());
}

class CafeJobApp extends StatelessWidget {
  const CafeJobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe Job',
      debugShowCheckedModeBanner: false,
      // Sementara kita set font default agar mirip, nanti bisa pakai font custom
      theme: ThemeData(fontFamily: 'sans-serif', useMaterial3: true),
      // Set Halaman Login sebagai halaman pertama
      home: const LoginScreen(),
    );
  }
}
