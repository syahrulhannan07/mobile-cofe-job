// lib/features/home/screens/detail_lowongan_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import 'apply_job_screen.dart';

class DetailLowonganScreen extends StatelessWidget {
  // Ubah tipe data dari Map<String, String> menjadi dynamic
  // agar dapat menerima data berstruktur complex Object/Map hasil API
  final dynamic lowongan;

  const DetailLowonganScreen({super.key, required this.lowongan});

  @override
  Widget build(BuildContext context) {
    // Ekstraksi data relasi perusahaan dari database Cofe Job
    final perusahaan = lowongan['perusahaan'] ?? {};
    final String? logoUrl = perusahaan['logo_perusahaan'];
    final String posisiPekerjaan = lowongan['posisi'] ?? 'Posisi Pekerjaan';
    final String namaPerusahaan =
        perusahaan['nama_perusahaan'] ?? 'Perusahaan Cofe Job';

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
                                // Logo Perusahaan terintegrasi Network API
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: logoUrl != null && logoUrl.isNotEmpty
                                        ? Image.network(
                                            logoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.coffee_rounded,
                                                      color:
                                                          AppColors.brownDark,
                                                      size: 30,
                                                    ),
                                          )
                                        : const Icon(
                                            Icons.coffee_rounded,
                                            color: AppColors.brownDark,
                                            size: 30,
                                          ),
                                  ),
                                ),
                                // Tombol Lamar membawa parameter dinamis dari posisi pekerjaan
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ApplyJobScreen(
                                          jobId:
                                              lowongan['id']?.toString() ?? '',
                                          jobTitle: posisiPekerjaan,
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
                                Expanded(
                                  child: Text(
                                    namaPerusahaan,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMain,
                                    ),
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
                            Text(
                              perusahaan['deskripsi'] ??
                                  "Perusahaan yang berdedikasi tinggi menciptakan ekosistem kerja inklusif untuk masa depan.",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            const Divider(height: 25),
                            _buildInfoRow(
                              Icons.work_outline_rounded,
                              "Posisi Lowongan",
                              posisiPekerjaan,
                            ),
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              "Lokasi",
                              lowongan['lokasi'] ?? "Indramayu",
                            ),
                            _buildInfoRow(
                              Icons.payments_outlined,
                              "Estimasi Gaji",
                              lowongan['gaji'] ?? "Gaji Rahasia",
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
                    lowongan['deskripsi'] ??
                        "Sebagai $posisiPekerjaan, Anda akan berkontribusi langsung dalam operasional harian dan pengembangan standar mutu kualitas pelayanan di $namaPerusahaan.",
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textMain,
                    ),
                  ),
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

                  // Menampilkan persyaratan dari string data database secara fleksibel
                  if (lowongan['persyaratan'] != null &&
                      lowongan['persyaratan'].toString().isNotEmpty)
                    Text(
                      lowongan['persyaratan'],
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textMain,
                      ),
                    )
                  else ...[
                    // Fallback bullets jika field persyaratan database kosong
                    _buildBulletPoint(
                      "Pendidikan: Minimal SMA/K Sederajat atau Diploma/S1",
                    ),
                    _buildBulletPoint(
                      "Keahlian Teknis: Mampu bekerja dalam tim & komunikatif",
                    ),
                    _buildBulletPoint(
                      "Memiliki antusiasme tinggi di bidang industri ini",
                    ),
                    _buildBulletPoint(
                      "Lokasi penempatan sesuai dengan cabang yang dipilih",
                    ),
                  ],
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
          Expanded(
            child: Column(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
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
