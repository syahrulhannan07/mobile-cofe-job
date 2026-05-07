// lib/features/home/screens/lowongan_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
// Pastikan path import di bawah ini sesuai dengan lokasi file DetailLowonganScreen Anda
import 'detail_lowongan_screen.dart';

class LowonganScreen extends StatelessWidget {
  const LowonganScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy untuk simulasi list
    final List<Map<String, String>> lowonganData = [
      {
        "posisi": "Senior Barista",
        "gaji": "Rp 4.500.000 - Rp 6.000.000",
        "tanggal": "01 Okt 2023 - 31 Okt 2023",
        "lokasi": "Jakarta Selatan",
      },
      {
        "posisi": "Store Manager",
        "gaji": "Rp 7.000.000 - Rp 9.500.000",
        "tanggal": "05 Okt 2023 - 15 Nov 2023",
        "lokasi": "Bandung City",
      },
      {
        "posisi": "Pastry Chef",
        "gaji": "Rp 5.500.000 - Rp 7.500.000",
        "tanggal": "10 Okt 2023 - 10 Nov 2023",
        "lokasi": "Surabaya",
      },
      {
        "posisi": "Roaster Apprentice",
        "gaji": "Rp 3.500.000 - Rp 4.500.000",
        "tanggal": "15 Okt 2023 - 30 Nov 2023",
        "lokasi": "Yogyakarta",
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. Header "Lowongan"
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.brownLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                "Lowongan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textMain,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  hintStyle: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMain,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: Colors.transparent,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: AppColors.textMain,
                      width: 1,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Daftar Card Lowongan
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                itemCount: lowonganData.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = lowonganData[index];

                  // Modifikasi Utama: Menambahkan GestureDetector untuk Navigasi
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailLowonganScreen(lowongan: item),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7F0), // Warna krem muda
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cardOutline.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bagian Kiri: Teks Informasi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['posisi']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['gaji']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Baris Tanggal
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['tanggal']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Baris Lokasi
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['lokasi']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Bagian Kanan: Logo Perusahaan
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/logo_cofe_job.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
