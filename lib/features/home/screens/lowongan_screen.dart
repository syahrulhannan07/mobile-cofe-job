// lib/features/home/screens/lowongan_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/colors.dart';
import 'detail_lowongan_screen.dart';

class LowonganScreen extends StatefulWidget {
  const LowonganScreen({super.key});

  @override
  State<LowonganScreen> createState() => _LowonganScreenState();
}

class _LowonganScreenState extends State<LowonganScreen> {
  final String baseUrl = "https://cofe-job.cicd.my.id/api/v1";
  
  List<dynamic> _allLowongan = []; // Data asli dari API
  List<dynamic> _filteredLowongan = []; // Data setelah difilter search bar
  bool _isLoading = true;
  String _errorMessage = "";
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLowonganData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi mengambil data lowongan langsung dari endpoint beranda
  Future<void> _fetchLowonganData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/beranda"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List lowonganData = jsonResponse['data']['lowongan_terbaru'] ?? [];
        
        setState(() {
          _allLowongan = lowonganData;
          _filteredLowongan = lowonganData; // Inisialisasi awal
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal memuat data dari server";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Kesalahan koneksi: $e";
        _isLoading = false;
      });
    }
  }

  // Fungsi filter pencarian lowongan berdasarkan posisi atau nama perusahaan
  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLowongan = _allLowongan;
      } else {
        _filteredLowongan = _allLowongan.where((item) {
          final posisi = (item['posisi'] ?? '').toString().toLowerCase();
          final perusahaan = (item['perusahaan']?['nama_perusahaan'] ?? '').toString().toLowerCase();
          return posisi.contains(query.toLowerCase()) || perusahaan.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Helper pembersih string angka nominal gaji
  String _prosesFormatAngka(String teksAngka) {
    String cleanString = teksAngka.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return "";
    
    int? angkaGaji = int.tryParse(cleanString);
    if (angkaGaji == null) return teksAngka;

    if (angkaGaji >= 1000000) {
      double juta = angkaGaji / 1000000;
      String hasilJuta = juta % 1 == 0 ? juta.toInt().toString() : juta.toStringAsFixed(1);
      return "${hasilJuta}JT";
    } else if (angkaGaji >= 1000) {
      double ribu = angkaGaji / 1000;
      String hasilRibu = ribu % 1 == 0 ? ribu.toInt().toString() : ribu.toStringAsFixed(1);
      return "${hasilRibu}RB";
    }
    return angkaGaji.toString();
  }

  // Fungsi utama pemformat range gaji singkat
  String formatGajiSingkat(dynamic gaji) {
    if (gaji == null) return "Gaji Rahasia";
    String gajiStr = gaji.toString().trim();
    if (gajiStr.isEmpty) return "Gaji Rahasia";

    if (gajiStr.contains('-')) {
      List<String> parts = gajiStr.split('-');
      if (parts.length == 2) {
        String minGaji = _prosesFormatAngka(parts[0]);
        String maxGaji = _prosesFormatAngka(parts[1]);
        if (minGaji.isNotEmpty && maxGaji.isNotEmpty) return "$minGaji - $maxGaji";
      }
    } else if (gajiStr.toLowerCase().contains('sampai')) {
      List<String> parts = gajiStr.toLowerCase().split('sampai');
      if (parts.length == 2) {
        String minGaji = _prosesFormatAngka(parts[0]);
        String maxGaji = _prosesFormatAngka(parts[1]);
        if (minGaji.isNotEmpty && maxGaji.isNotEmpty) return "$minGaji - $maxGaji";
      }
    }

    String hasilFormat = _prosesFormatAngka(gajiStr);
    return hasilFormat.isEmpty ? "Gaji Rahasia" : hasilFormat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 1. Header "Lowongan" dengan tombol Back opsional jika halaman ini dipush
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.brownLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (Navigator.canPop(context))
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 16,
                          child: Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textMain),
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Lowongan Pekerjaan",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Search Bar Terintegrasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterSearch,
                decoration: InputDecoration(
                  hintText: "Cari posisi lowongan",
                  hintStyle: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMain,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMain, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterSearch("");
                          },
                        )
                      : null,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: AppColors.brownDark,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Area Konten Utama (Loading / Error / List Dinamis)
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  // Router Widget Konten Utama untuk mempermudah pengecekan state
  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brownDark),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_errorMessage, style: TextStyle(color: Colors.grey[600])),
            TextButton(
              onPressed: _fetchLowonganData,
              child: const Text("Coba Lagi", style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    if (_filteredLowongan.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchLowonganData,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text("Tidak ada lowongan ditemukan.", style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLowonganData,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        itemCount: _filteredLowongan.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = _filteredLowongan[index];
          final perusahaan = item['perusahaan'] ?? {};
          final String? logoUrl = perusahaan['logo_perusahaan'];
          final String formatGaji = formatGajiSingkat(item['gaji']);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailLowonganScreen(lowongan: item),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF7F0), // Krem muda bawaan UI awal
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.cardOutline.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bagian Kiri: Teks Informasi Lowongan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['posisi'] ?? 'Posisi tidak ditentukan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perusahaan['nama_perusahaan'] ?? 'Perusahaan Rahasia',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatGaji == "Gaji Rahasia" ? formatGaji : "Rp $formatGaji",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Baris Tanggal / Keterangan Tambahan jika ada
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['updated_at'] != null 
                                    ? "Diperbarui: ${item['updated_at'].toString().substring(0, 10)}"
                                    : "Aktif",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
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
                            Expanded(
                              child: Text(
                                item['lokasi'] ?? 'Indramayu',
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Bagian Kanan: Logo Perusahaan dari Network API (Fallback ke default Icon jika kosong)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.brownLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brownDark),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.coffee_rounded, color: AppColors.brownDark, size: 26),
                            )
                          : const Icon(Icons.coffee_rounded, color: AppColors.brownDark, size: 26),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}