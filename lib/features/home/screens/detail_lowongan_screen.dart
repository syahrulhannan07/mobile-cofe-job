// lib/features/home/screens/detail_lowongan_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import 'apply_job_screen.dart'; // Pastikan import file tujuan sudah benar

class DetailLowonganScreen extends StatelessWidget {
  final Map<String, String> lowongan;

  const DetailLowonganScreen({super.key, required this.lowongan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Section
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: AppColors.brownLight,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.textMain,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                "Detail Lowongan",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // Spacer balance
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Card Profil Perusahaan Atas
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF7F0),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.brownLight,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Logo
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(
                                      'assets/logo_cofe_job.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                // Tombol Lamar (MODIFIKASI DI SINI)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ApplyJobScreen(
                                          jobTitle:
                                              lowongan['title'] ??
                                              "Posisi Pekerjaan",
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A3428),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    "Lamar Sekarang",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Text(
                                  lowongan['company'] ?? "Indra Coffee Roaster",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.brown,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "“Indra Coffee Roasters adalah pemanggang kopi artisan yang berdedikasi di Karangampel, Jawa Barat.”",
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            const Divider(height: 25),
                            _buildInfoRow(
                              Icons.calendar_month,
                              "Berdiri",
                              "5 April 2007",
                            ),
                            _buildInfoRow(
                              Icons.location_on,
                              "Lokasi",
                              lowongan['location'] ?? "Karangampel",
                            ),
                            _buildInfoRow(
                              Icons.work,
                              "Lowongan Aktif",
                              "4 Lowongan",
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brownLight,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  "Lihat Profile Perusahaan",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. Detail Pekerjaan
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF7F0),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.brownLight.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Deskripsi Pekerjaan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textAccent,
                    ),
                  ),
                  const Divider(color: AppColors.brownLight),
                  Text(
                    "Sebagai ${lowongan['title']}, Anda akan berperan penting dalam menceritakan kisah di balik setiap cangkir kopi kami...",
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildBulletPoint("Produksi Konten Kreatif"),
                  _buildBulletPoint("Copywriting"),
                  _buildBulletPoint("Social Media Management"),
                  const SizedBox(height: 25),
                  const Text(
                    "Persyaratan & Kualifikasi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textAccent,
                    ),
                  ),
                  const Divider(color: AppColors.brownLight),
                  _buildBulletPoint(
                    "Pendidikan: Mahasiswa tingkat akhir atau lulusan baru",
                  ),
                  _buildBulletPoint(
                    "Keahlian Teknis: Mahir menggunakan aplikasi editing",
                  ),
                  _buildBulletPoint(
                    "Kreativitas: Memiliki kemampuan storytelling",
                  ),
                  _buildBulletPoint(
                    "Lokasi: Bersedia ditempatkan di Karangampel, Indramayu",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(fontSize: 18, color: Colors.orange),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }
}
