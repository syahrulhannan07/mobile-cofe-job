// lib/features/home/main_layout.dart
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'screens/beranda_screen.dart';
import 'screens/lowongan_screen.dart';
import 'screens/status_screen.dart';
import 'screens/pengaturan_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0; // Index halaman yang aktif

  // Daftar halaman yang akan ditampilkan
  final List<Widget> _screens = [
    const BerandaScreen(),
    const LowonganScreen(),
    const StatusScreen(),
    const PengaturanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: _screens[_currentIndex], // Menampilkan halaman sesuai index
      
      // --- KUSTOM BOTTOM NAVBAR ---
      // Kita bungkus SafeArea agar tidak hancur di HP yang ada notch bawah
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70, // Sesuaikan tinggi navbar
          margin: const EdgeInsets.all(16), // Jarak navbar dari pinggir layar
          decoration: BoxDecoration(
            color: AppColors.brownLight, // Warna dasar navbar (cokelat muda)
            borderRadius: BorderRadius.circular(15), // Sudut melengkung
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Kita buat fungsi reusable untuk item navbar
              _buildNavItem(index: 0, icon: Icons.home_filled),
              _buildNavItem(index: 1, icon: Icons.business_center_rounded),
              _buildNavItem(index: 2, icon: Icons.person_search_rounded), // Icon status mendekati
              _buildNavItem(index: 3, icon: Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk membuat setiap item di Navbar
  Widget _buildNavItem({required int index, required IconData icon}) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index; // Ubah index saat di-tap
        });
      },
      child: Container(
        width: 70, // Lebar kotak aktif
        height: 50, // Tinggi kotak aktif
        decoration: BoxDecoration(
          // Jika aktif, beri warna cokelat tua, jika tidak transparan
          color: isActive ? AppColors.brownDark : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 30,
          // Warna icon berubah sesuai status aktif
          color: isActive ? Colors.white : AppColors.textMain,
        ),
      ),
    );
  }
}