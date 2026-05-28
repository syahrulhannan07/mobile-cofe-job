// lib/features/home/screens/detail_perusahaan_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import 'detail_lowongan_screen.dart';

class DetailPerusahaanScreen extends StatelessWidget {
  final Map<String, dynamic> companyData;

  const DetailPerusahaanScreen({super.key, required this.companyData});

  @override
  Widget build(BuildContext context) {
    // Parsing data dari database/API map dengan aman
    final String name = companyData['nama_perusahaan'] ?? 'Tanpa Nama Perusahaan';
    final String? logoUrl = companyData['logo_perusahaan'];
    final String address = companyData['alamat_perusahaan'] ?? 'Lokasi tidak diset';
    final String desc = companyData['deskripsi'] ?? 'Tidak ada deskripsi tentang perusahaan ini.';

    // Penanganan ekstraksi list lowongan yang lebih fleksibel (menangani raw list atau wrapped array)
    List activeJobs = [];
    if (companyData['lowongan'] != null) {
      if (companyData['lowongan'] is List) {
        activeJobs = companyData['lowongan'];
      } else if (companyData['lowongan'] is Map && companyData['lowongan']['data'] != null) {
        activeJobs = companyData['lowongan']['data'];
      }
    }

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
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Profil Utama Perusahaan
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  // Logo dengan styling premium
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brownLight.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4), // Border effect
                    child: ClipOval(
                      child: Container(
                        color: AppColors.brownLight.withValues(alpha: 0.1),
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
                  ),
                  const SizedBox(height: 20),
                  // Nama Perusahaan
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                      letterSpacing: 0.3,
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
                        color: AppColors.brownDark,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          address,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Deskripsi / Tentang Perusahaan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.brownLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.brownDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Tentang Perusahaan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMain.withValues(alpha: 0.75),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Lowongan Aktif Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lowongan Aktif",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: activeJobs.isNotEmpty
                          ? AppColors.brownLight.withValues(alpha: 0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${activeJobs.length} Posisi",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activeJobs.isNotEmpty
                            ? AppColors.brownDark
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List Lowongan Aktif
            activeJobs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.work_off_rounded,
                              size: 40,
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Saat ini belum ada lowongan aktif.",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget custom card item lowongan aktif di dalam perusahaan tersebut
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
        : 'Gaji Dirahasiakan';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.brownLight.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          onTap: () {
            // Membungkus kembali data perusahaan induk ke dalam object lowongan
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
            padding: const EdgeInsets.all(16),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Row Badge Info lokasi & gaji
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _buildMiniBadge(
                            icon: Icons.location_on_rounded,
                            text: location,
                            bgColor: Colors.grey[100]!,
                            textColor: Colors.grey[700]!,
                          ),
                          _buildMiniBadge(
                            icon: Icons.monetization_on_rounded,
                            text: salary.toLowerCase().contains('rp') ||
                                    salary == "Gaji Dirahasiakan"
                                ? salary
                                : "Rp $salary",
                            bgColor: AppColors.brownLight.withValues(alpha: 0.15),
                            textColor: AppColors.brownDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Arrow penunjuk aksi
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brownLight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.brownDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget untuk membuat badge kecil (lokasi, gaji, dll)
  Widget _buildMiniBadge({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}