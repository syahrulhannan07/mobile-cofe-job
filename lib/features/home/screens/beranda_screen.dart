// lib/features/home/screens/beranda_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Profil & Notif
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SYAHRUL HANNAN....",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        "S1 Terapan Rekayasa....",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMain.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textMain,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.brownLight,
                        child: Icon(Icons.person, color: AppColors.textMain),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Banner Utama (Menggunakan File Gambar Anda)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/banner_home.png', // <-- Pastikan file ini ada di folder assets
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback jika gambar tidak ditemukan
                    return Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.brownDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          "Banner Image Not Found",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. Menu Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMenuIcon(Icons.help_center_rounded, "Tutorial"),
                  _buildMenuIcon(Icons.business_rounded, "Perusahaan"),
                  _buildMenuIcon(Icons.mark_as_unread_rounded, "Bantuan"),
                ],
              ),
              const SizedBox(height: 30),

              // 4. Daftar Lowongan Terbaru
              const Text(
                "Daftar Lowongan Terbaru",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildJobPlaceholder(),
                  const SizedBox(width: 16),
                  _buildJobPlaceholder(),
                ],
              ),
              const SizedBox(height: 30),

              // 5. Daftar Perusahaan Terbaru
              const Text(
                "Daftar Perusahaan Terbaru",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.brownLight,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 35, color: AppColors.brownDark),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMain),
        ),
      ],
    );
  }

  Widget _buildJobPlaceholder() {
    return Expanded(
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.brownLight,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Icon(Icons.image, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}
