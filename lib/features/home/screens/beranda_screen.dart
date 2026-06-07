// lib/features/home/screens/beranda_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import 'tutorial_screen.dart';
import 'perusahaan_screen.dart';
import 'bantuan_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import '../../jobs/screens/detail_lowongan_screen.dart';
import 'detail_perusahaan_screen.dart';
import '../../../core/network/api_config.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  String userName = "Memuat...";

  late Future<Map<String, dynamic>> _berandaData;

  // Jumlah notifikasi belum dibaca untuk badge lonceng
  int _unreadCount = 0;

  // Controller untuk Auto Scroll Banner
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _bannerImages = [
    'assets/banner_home1.png',
    'assets/banner_home2.png',
    'assets/banner_home3.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startAutoScroll();
    _berandaData = fetchBerandaData(); // Ambil data gabungan dari DB saat init
    _fetchUnreadCount(); // Ambil jumlah notif belum dibaca untuk badge
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "User";
    });
  }

  // Mengambil jumlah notifikasi yang belum dibaca untuk badge lonceng
  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse(ApiConfig.notificationsEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        final int count = list.where((n) => n['dibaca'] == false).length;
        if (mounted) setState(() => _unreadCount = count);
      }
    } catch (_) {
      // Gagal fetch badge tidak perlu tampilkan error ke UI
    }
  }

  // Fungsi Tunggal untuk Fetch Data Gabungan Beranda
  Future<Map<String, dynamic>> fetchBerandaData() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.beranda),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'] ?? {};
      } else {
        throw Exception("Gagal memuat data beranda");
      }
    } catch (e) {
      throw Exception("Kesalahan koneksi: $e");
    }
  }

  /// Helper untuk mengubah path relatif dari DB menjadi Full URL yang melewati folder /storage/
  String? _formatImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;

    // Jika dari database ternyata sudah berupa link penuh, langsung kembalikan
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }

    try {
      // Ekstrak base domain URL dari ApiConfig.beranda secara dinamis
      final uri = Uri.parse(ApiConfig.beranda);
      final baseUrl =
          "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";

      // Bersihkan slash di awal path database jika ada
      final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';

      // Menggabungkan domain + folder /storage + path
      return "$baseUrl/storage$cleanPath";
    } catch (e) {
      return rawUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _berandaData,
          builder: (context, snapshot) {
            // State Loading saat aplikasi mengambil data dari database
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brownDark),
              );
            }

            // State Error jika server mati atau bermasalah
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 50,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Gagal terhubung ke internet",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _berandaData = fetchBerandaData();
                        });
                      },
                      child: const Text(
                        "Coba Lagi",
                        style: TextStyle(color: AppColors.brownDark),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mengambil list data dari snapshot API
            final data = snapshot.data ?? {};
            final List lowonganList = data['lowongan_terbaru'] ?? [];
            final List perusahaanList = data['perusahaan_populer'] ?? [];

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _berandaData = fetchBerandaData();
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          Text(
                            userName.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textMain,
                            ),
                          ),
                          Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: AppColors.textMain,
                                      size: 28,
                                    ),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NotificationScreen(
                                            onUnreadChanged: (count) {
                                              if (mounted) setState(() => _unreadCount = count);
                                            },
                                          ),
                                        ),
                                      );
                                      _fetchUnreadCount();
                                    },
                                  ),
                                  if (_unreadCount > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: IgnorePointer(
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE53935),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              height: 1.1,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 4),
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

                    // 2. Banner Utama Auto-Scroll
                    _buildBanner(),
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

                    // 4. Section Lowongan Terbaru
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Lowongan Terbaru",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    lowonganList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Text(
                              "Belum ada lowongan terbaru.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : SizedBox(
                            height: 175,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 4,
                                bottom: 10,
                              ),
                              itemCount: lowonganList.length,
                              itemBuilder: (context, index) {
                                final item = lowonganList[index];
                                final perusahaan = item['perusahaan'] ?? {};

                                final formattedLogo = _formatImageUrl(
                                  perusahaan['logo_perusahaan'],
                                );

                                return _buildHorizontalJobCard(
                                  logoUrl: formattedLogo,
                                  jobTitle:
                                      item['posisi'] ??
                                      'Posisi tidak ditentukan',
                                  companyName:
                                      perusahaan['nama_perusahaan'] ??
                                      'Perusahaan Kosong',
                                  location: item['lokasi'] ?? 'Indramayu',
                                  salary: item['gaji'] != null
                                      ? item['gaji'].toString()
                                      : 'Gaji Rahasia',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailLowonganScreen(
                                              lowongan: item,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                    const SizedBox(height: 24),

                    // 5. Section Temukan Perusahaan
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Temukan Perusahaan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    perusahaanList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "Belum ada perusahaan terdaftar.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: perusahaanList.map((company) {
                                final formattedLogo = _formatImageUrl(
                                  company['logo_perusahaan'],
                                );

                                return _buildVerticalCompanyCard(
                                  logoUrl: formattedLogo,
                                  name:
                                      company['nama_perusahaan'] ??
                                      'Tanpa Nama',
                                  address:
                                      company['alamat_perusahaan'] ??
                                      'Lokasi tidak diset',
                                  desc:
                                      company['deskripsi'] ??
                                      'Tidak ada deskripsi.',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailPerusahaanScreen(
                                              companyData: company,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _bannerImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                _bannerImages[index],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.brownDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      "Cofe Job Promo ${index + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
    required String? logoUrl,
    required String jobTitle,
    required String companyName,
    required String location,
    required String salary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 46,
                    height: 46,
                    color: AppColors.brownLight.withValues(alpha: 0.25),
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.brownDark,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.coffee,
                                  color: AppColors.brownDark,
                                  size: 22,
                                ),
                          )
                        : const Icon(
                            Icons.coffee,
                            color: AppColors.brownDark,
                            size: 22,
                          ),
                  ),
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
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brownLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    salary.toLowerCase().contains('rp') ||
                            salary == "Gaji Rahasia"
                        ? salary
                        : "Rp $salary",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.brownDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCompanyCard({
    required String? logoUrl,
    required String name,
    required String address,
    required String desc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.brownLight.withValues(alpha: 0.3),
                child: logoUrl != null && logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brownDark,
                                  ),
                                ),
                              );
                            },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.storefront,
                              color: AppColors.brownDark,
                              size: 30,
                            ),
                      )
                    : const Icon(
                        Icons.storefront,
                        color: AppColors.brownDark,
                        size: 30,
                      ),
              ),
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
                      color: AppColors.textMain.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}