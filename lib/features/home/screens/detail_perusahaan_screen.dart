// lib/features/home/screens/detail_perusahaan_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import 'detail_lowongan_screen.dart'; // Import jika ingin container lowongan aktif bisa diklik

class DetailPerusahaanScreen extends StatelessWidget {
  final Map<String, dynamic> companyData;

  const DetailPerusahaanScreen({super.key, required this.companyData});

  @override
  Widget build(BuildContext context) {
    // Parsing data dari database/API map
    final String name = companyData['nama_perusahaan'] ?? 'Tanpa Nama Kafe';
    final String? logoUrl = companyData['logo_perusahaan'];
    final String address =
        companyData['alamat_perusahaan'] ?? 'Lokasi tidak diset';
    final String desc =
        companyData['deskripsi'] ?? 'Tidak ada deskripsi tentang kafe ini.';

    // Mengambil list lowongan dari model relasi perusahaan (jika ada dari API response)
    final List activeJobs = companyData['lowongan'] ?? [];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Perusahaan",
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Profil Utama Kafe
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Logo Lingkaran dengan ClipRRect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: AppColors.brownLight.withOpacity(0.3),
                      child: logoUrl != null && logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.brownDark,
                                    size: 45,
                                  ),
                            )
                          : const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.brownDark,
                              size: 45,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nama Perusahaan
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Alamat Perusahaan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          address,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Deskripsi / Tentang Perusahaan
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tentang Kafe",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMain.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Lowongan Aktif Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lowongan Aktif",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brownLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${activeJobs.length} Posisi",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List Lowongan Aktif
            activeJobs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_off_rounded,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Saat ini belum ada lowongan aktif.",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeJobs.length,
                      itemBuilder: (context, index) {
                        final job = activeJobs[index];
                        return _buildJobItemCard(
                          context: context,
                          jobData: job,
                          companyName: name,
                          logoUrl: logoUrl,
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget custom card item lowongan aktif di dalam kafe tersebut
  Widget _buildJobItemCard({
    required BuildContext context,
    required Map<String, dynamic> jobData,
    required String companyName,
    required String? logoUrl,
  }) {
    final String position = jobData['posisi'] ?? 'Posisi tidak dispesifikasi';
    final String location = jobData['lokasi'] ?? 'Indramayu';
    final String salary = jobData['gaji'] != null
        ? jobData['gaji'].toString()
        : 'Gaji Rahasia';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Ketika lowongan diklik, arahkan ke detail lowongan screen bawa serta parameternya
            // Supaya tidak null, kita bungkus kembali data perusahaan induk ke dalam object lowongan
            final Map<String, dynamic> completeJobData = Map.from(jobData);
            completeJobData['perusahaan'] = {
              'nama_perusahaan': companyName,
              'logo_perusahaan': logoUrl,
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailLowonganScreen(lowongan: completeJobData),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Info text lowongan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Row Badge Info mini lokasi & gaji
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
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
                                const SizedBox(width: 3),
                                Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brownLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              salary.toLowerCase().contains('rp') ||
                                      salary == "Gaji Rahasia"
                                  ? salary
                                  : "Rp $salary",
                              style: const TextStyle(
                                fontSize: 10,
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
                // Arrow Icon Penunjuk klik
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
