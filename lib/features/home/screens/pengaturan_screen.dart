// lib/features/home/screens/pengaturan_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart'; // Import ini penting untuk navigasi manual

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  final AuthService _authService = AuthService();

  // --- LOGIKA UTAMA LOGOUT ---
  Future<void> _performLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Hapus token API
      await prefs.remove('token');

      // 2. Set isLoggedIn menjadi false (sesuai logika di main.dart Anda)
      await prefs.setBool('isLoggedIn', false);

      if (mounted) {
        // 3. Navigasi manual ke LoginScreen tanpa menggunakan Routes
        // Ini akan menghapus semua tumpukan halaman sehingga user tidak bisa "back"
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar("Gagal logout, silakan coba lagi.");
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Konfirmasi Keluar"),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari akun COFE JOB?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              elevation: 0,
            ),
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header Oval Pengaturan
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.brownLight,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Pengaturan",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textMain,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Keamanan Akun"),
                    _buildSettingsTile(
                      icon: Icons.email_outlined,
                      title: "Ubah Email",
                      subtitle: "Update email aktif untuk reset password",
                      onTap: () => _showSnackBar("Fitur segera tersedia"),
                    ),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: "Ganti Password",
                      subtitle: "Gunakan password lama untuk verifikasi",
                      onTap: () => _showSnackBar("Fitur segera tersedia"),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle("Aplikasi"),
                    _buildSettingsTile(
                      icon: Icons.notifications_none,
                      title: "Notifikasi",
                      subtitle: "Atur pemberitahuan lowongan kerja",
                      trailing: Switch(
                        value: true,
                        onChanged: (val) {},
                        activeColor: AppColors.buttonMain,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Tombol Logout
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          "Keluar",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.buttonMain),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
