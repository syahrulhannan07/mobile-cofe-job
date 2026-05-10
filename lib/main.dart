// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'features/auth/screens/login_screen.dart';
import 'features/home/main_layout.dart'; // Import MainLayout untuk halaman utama

void main() async {
  // 1. Pastikan binding framework diinisialisasi karena kita menggunakan async di main
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Ambil data dari penyimpanan lokal
  final prefs = await SharedPreferences.getInstance();

  // 3. Cek apakah key 'isLoggedIn' bernilai true. Jika belum ada, default ke false.
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // 4. Jalankan aplikasi dengan membawa status login
  runApp(CafeJobApp(isLoggedIn: isLoggedIn));
}

class CafeJobApp extends StatelessWidget {
  final bool isLoggedIn;

  // Terima status login melalui constructor
  const CafeJobApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe Job',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif', useMaterial3: true),
      // 5. Logika penentuan halaman pertama:
      // Jika isLoggedIn true, langsung ke MainLayout (Beranda).
      // Jika false, arahkan ke LoginScreen.
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}
