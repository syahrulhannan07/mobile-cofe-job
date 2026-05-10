// lib/features/home/screens/beranda_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import 'tutorial_screen.dart';
import 'perusahaan_screen.dart';
import 'bantuan_screen.dart';
import 'profile_screen.dart';
import 'lowongan_screen.dart'; // Pastikan import halaman lowongan

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  String userName = "Memuat...";
  String userEducation = "Pendidikan belum diatur";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "User";
      userEducation =
          prefs.getString("user_education") ?? "S1 Rekayasa Perangkat Lunak";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Profil & Notif
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textMain,
                          ),
                        ),
                        Text(
                          userEducation,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMain.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textMain,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.brownLight,
                            child: Icon(
                              Icons.person,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Banner Utama
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildBanner(),
              ),
              const SizedBox(height: 24),

              // 3. Menu Icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMenuButton(
                      context,
                      Icons.help_center_rounded,
                      "Tutorial",
                      const TutorialScreen(),
                    ),
                    _buildMenuButton(
                      context,
                      Icons.business_rounded,
                      "Perusahaan",
                      const PerusahaanScreen(),
                    ),
                    _buildMenuButton(
                      context,
                      Icons.mark_as_unread_rounded,
                      "Bantuan",
                      const BantuanScreen(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 4. Section Lowongan Terbaru (Header + Horizontal Scroll)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Lowongan Terbaru",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textMain,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LowonganScreen(),
                        ),
                      ),
                      child: const Text(
                        "Lihat Semua",
                        style: TextStyle(
                          color: AppColors.brownDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Horizontal Scroll Lowongan
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Row(
                  children: [
                    _buildHorizontalJobCard(
                      logo: Icons.coffee,
                      jobTitle: "Mobile Developer",
                      companyName: "Cofe Job Tech",
                      location: "Indramayu",
                      salary: "Rp 5jt - 8jt",
                    ),
                    _buildHorizontalJobCard(
                      logo: Icons.computer,
                      jobTitle: "UI/UX Designer",
                      companyName: "Kopi Kenangan",
                      location: "Jakarta",
                      salary: "Rp 4jt - 7jt",
                    ),
                    _buildHorizontalJobCard(
                      logo: Icons.code,
                      jobTitle: "Backend Dev",
                      companyName: "Tech Coffee",
                      location: "Bandung",
                      salary: "Rp 6jt - 9jt",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 5. Daftar Perusahaan Terbaru
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Daftar Perusahaan Terbaru",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/banner_home.png',
        width: double.infinity,
        height: 170,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.brownDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text(
              "Cofe Job: Temukan Karirmu",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    IconData icon,
    String label,
    Widget targetScreen,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      ),
      child: Column(
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
      ),
    );
  }

  // Widget Kartu Lowongan Horizontal
  Widget _buildHorizontalJobCard({
    required IconData logo,
    required String jobTitle,
    required String companyName,
    required String location,
    required String salary,
  }) {
    return Container(
      width: 260, // Lebar kartu agar bisa terlihat scrolly-nya
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.brownLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(logo, color: AppColors.brownDark, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      companyName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.brownDark,
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              Text(
                salary,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brownDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
