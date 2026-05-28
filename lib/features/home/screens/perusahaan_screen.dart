// lib/features/home/screens/perusahaan_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/colors.dart';
import 'detail_perusahaan_screen.dart';
import '../../../core/network/api_config.dart';

class PerusahaanScreen extends StatefulWidget {
  const PerusahaanScreen({super.key});

  @override
  State<PerusahaanScreen> createState() => _PerusahaanScreenState();
}

class _PerusahaanScreenState extends State<PerusahaanScreen> {
  late Future<List<Map<String, dynamic>>> _futurePerusahaan;
  List<Map<String, dynamic>> _allPerusahaan = [];
  List<Map<String, dynamic>> _filteredPerusahaan = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futurePerusahaan = fetchPerusahaan();
  }

  // ==================== FUNGSI FETCH API (FORCE ALL DATA) ====================
  Future<List<Map<String, dynamic>>> fetchPerusahaan() async {
    // Menambahkan parameter per_page=100 untuk memaksa backend mengirimkan semua data sekaligus

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.perusahaan),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Karena Laravel menggunakan API Resource + Pagination,
        // data array aslinya dibungkus di dalam data['data'] atau langsung di responseData['data']
        dynamic rawData = responseData['data'];
        List<dynamic> dataList = [];

        if (rawData is Map && rawData['data'] != null) {
          dataList = rawData['data'];
        } else if (rawData is List) {
          dataList = rawData;
        }

        List<Map<String, dynamic>> perusahaanList =
            List<Map<String, dynamic>>.from(dataList);

        setState(() {
          _allPerusahaan = perusahaanList;
          _filteredPerusahaan = perusahaanList;
        });

        return perusahaanList;
      } else {
        throw Exception(
          'Gagal memuat data dari server (${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke database server: $e');
    }
  }

  // ==================== FUNGSI FITUR SEARCH ====================
  void _filterPerusahaan(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPerusahaan = _allPerusahaan;
      } else {
        _filteredPerusahaan = _allPerusahaan
            .where(
              (perusahaan) =>
                  (perusahaan['nama_perusahaan'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  (perusahaan['alamat_perusahaan'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 10,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF635147),
                        ),
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

            // 2. Search Bar Terintegrasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPerusahaan,
                decoration: InputDecoration(
                  hintText: "Cari Perusahaan...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterPerusahaan('');
                          },
                        )
                      : null,
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

            // 3. Daftar Perusahaan Menggunakan FutureBuilder
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futurePerusahaan,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF635147),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF635147)),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _futurePerusahaan = fetchPerusahaan();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brownLight,
                              ),
                              child: const Text(
                                'Coba Lagi',
                                style: TextStyle(color: Color(0xFF635147)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (_filteredPerusahaan.isEmpty) {
                    return const Center(
                      child: Text(
                        "Tidak ada perusahaan ditemukan",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  // Data berhasil diload & dirender penuh
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _futurePerusahaan = fetchPerusahaan();
                      });
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _filteredPerusahaan.length,
                      itemBuilder: (context, index) {
                        final perusahaan = _filteredPerusahaan[index];
                        return _buildCardPerusahaan(context, perusahaan);
                      },
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

  Widget _buildCardPerusahaan(BuildContext context, Map<String, dynamic> data) {
    String deskripsi =
        data['deskripsi_perusahaan'] ??
        data['deskripsi'] ??
        'Tidak ada deskripsi.';
    if (deskripsi.length > 60) {
      deskripsi = '${deskripsi.substring(0, 60)}...';
    }

    final String? logoUrl = data['logo_perusahaan'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPerusahaanScreen(companyData: data),
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Perusahaan
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.brownLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: logoUrl != null && logoUrl.isNotEmpty
                    ? (logoUrl.startsWith('http')
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.storefront_rounded,
                                    color: Color(0xFF635147),
                                  ),
                            )
                          : Image.asset(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.storefront_rounded,
                                    color: Color(0xFF635147),
                                  ),
                            ))
                    : const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF635147),
                        size: 30,
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
                    data['nama_perusahaan'] ?? 'Tanpa Nama',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF635147),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['alamat_perusahaan'] ?? 'Lokasi tidak diset',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deskripsi,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
