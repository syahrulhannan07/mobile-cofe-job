// lib/features/home/screens/perusahaan_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class PerusahaanScreen extends StatelessWidget {
  const PerusahaanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy perusahaan
    final List<Map<String, String>> daftarPerusahaan = [
      {
        "nama": "Indra Coffee Roaster",
        "alamat": "Karangampel, Indramayu",
        "deskripsiSingkat": "Pemanggang kopi artisan yang berdedikasi tinggi...",
        "deskripsiLengkap":
            "Indra Coffee Roasters adalah pemanggang kopi artisan yang berdedikasi di Karangampel, Jawa Barat. Kami fokus pada kualitas biji kopi terbaik dan pengalaman pelanggan yang unik.",
        "logo": "assets/logo_cofe_job.png", 
      },
      {
        "nama": "Warehouse Cafe",
        "alamat": "Jakarta Selatan",
        "deskripsiSingkat": "Tempat nongkrong industrial dengan kopi pilihan...",
        "deskripsiLengkap":
            "Warehouse Cafe mengusung konsep industrial modern yang nyaman untuk bekerja maupun bersantai. Kami menyediakan berbagai varian kopi dari seluruh nusantara.",
        "logo": "assets/logo_cofe_job.png",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. Header (Tombol Kembali & Judul)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.brownLight,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Color(0xFF635147)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      "Perusahaan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF635147),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Cari Perusahaan...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 3. Daftar Perusahaan
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: daftarPerusahaan.length,
                itemBuilder: (context, index) {
                  final perusahaan = daftarPerusahaan[index];
                  return _buildCardPerusahaan(context, perusahaan);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPerusahaan(BuildContext context, Map<String, String> data) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman detail baru
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPerusahaanScreen(data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Perusahaan (Sekarang Menggunakan Image)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.brownLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  data['logo']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.business, color: Color(0xFF635147)),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // Info Perusahaan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['nama']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF635147),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        data['alamat']!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['deskripsiSingkat']!,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Ikon panah dihapus sesuai permintaan
          ],
        ),
      ),
    );
  }
}

// Halaman Detail Baru
class DetailPerusahaanScreen extends StatelessWidget {
  final Map<String, String> data;
  const DetailPerusahaanScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: Text(data['nama']!,
            style: const TextStyle(color: Color(0xFF635147))),
        backgroundColor: AppColors.brownLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF635147)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(data['logo']!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              data['nama']!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF635147),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.brownDark, size: 20),
                const SizedBox(width: 5),
                Text(data['alamat']!,
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
            const Divider(height: 40),
            const Text(
              "Tentang Perusahaan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            Text(
              data['deskripsiLengkap']!,
              style: const TextStyle(
                  fontSize: 15, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}