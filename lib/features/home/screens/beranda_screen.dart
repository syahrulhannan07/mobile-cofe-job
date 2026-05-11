// lib/features/home/screens/beranda_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import 'tutorial_screen.dart';
import 'perusahaan_screen.dart';
import 'bantuan_screen.dart';
import 'profile_screen.dart';
import 'lowongan_screen.dart';
import 'notification_screen.dart'; // 1. Tambahkan import ini

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
                        // 2. Modifikasi Icon Notifikasi di sini
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.textMain,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          width: 4,
                        ), // Disesuaikan sedikit agar pas
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

              // 4. Section Lowongan Terbaru (Horizontal)
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
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Row(
                  children: [
                    _buildHorizontalJobCard(
                      logo: Icons.coffee,
                      jobTitle: "Senior Barista",
                      companyName: "Indra Coffee",
                      location: "Indramayu",
                      salary: "Rp 3jt - 4jt",
                    ),
                    _buildHorizontalJobCard(
                      logo: Icons.laptop_mac,
                      jobTitle: "Mobile Developer",
                      companyName: "Cofe Job Tech",
                      location: "Bandung",
                      salary: "Rp 6jt - 9jt",
                    ),
                    _buildHorizontalJobCard(
                      logo: Icons.design_services,
                      jobTitle: "UI/UX Designer",
                      companyName: "Creative Brew",
                      location: "Jakarta",
                      salary: "Rp 5jt - 8jt",
                    ),
                    _buildHorizontalJobCard(
                      logo: Icons.account_balance,
                      jobTitle: "Finance Manager",
                      companyName: "Dermayu Beans",
                      location: "Indramayu",
                      salary: "Rp 4jt - 6jt",
                    ),
                    _buildHorizontalJobCard(
                      logo: Icons.local_shipping,
                      jobTitle: "Logistics Lead",
                      companyName: "Ship Coffee",
                      location: "Cirebon",
                      salary: "Rp 4jt - 5jt",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 5. Section Perusahaan Terbaru (Vertikal)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Perusahaan Terbaru",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildVerticalCompanyCard(
                      logo: Icons.storefront,
                      name: "Indra Coffee Roasters",
                      address: "Jl. Cimanuk No. 12, Indramayu",
                      desc:
                          "Penyedia biji kopi terbaik di wilayah Indramayu dengan standar internasional.",
                    ),
                    _buildVerticalCompanyCard(
                      logo: Icons.apartment,
                      name: "Mangga Dua Tech",
                      address: "Pusat Bisnis Indramayu",
                      desc:
                          "Perusahaan software yang fokus pada digitalisasi industri UMKM kopi.",
                    ),
                    _buildVerticalCompanyCard(
                      logo: Icons.coffee_maker,
                      name: "Brewery House",
                      address: "Jatibarang, Indramayu",
                      desc:
                          "Cafe dan tempat pelatihan barista profesional dengan sertifikasi nasional.",
                    ),
                    _buildVerticalCompanyCard(
                      logo: Icons.precision_manufacturing,
                      name: "Koperasi Petani Kopi",
                      address: "Kuningan, Jawa Barat",
                      desc:
                          "Wadah bagi petani kopi lokal untuk mendistribusikan hasil panen ke kafe modern.",
                    ),
                    _buildVerticalCompanyCard(
                      logo: Icons.precision_manufacturing,
                      name: "RoastMaster Co.",
                      address: "Bandung, Jawa Barat",
                      desc:
                          "Manufaktur mesin roasting kopi berkualitas tinggi buatan anak bangsa.",
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
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

  Widget _buildHorizontalJobCard({
    required IconData logo,
    required String jobTitle,
    required String companyName,
    required String location,
    required String salary,
  }) {
    return Container(
      width: 260,
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

  Widget _buildVerticalCompanyCard({
    required IconData logo,
    required String name,
    required String address,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.brownLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(logo, color: AppColors.brownDark, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMain.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
