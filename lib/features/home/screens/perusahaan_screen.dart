// lib/features/home/screens/perusahaan_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/colors.dart';
import 'detail_perusahaan_screen.dart';
import '../../../core/network/api_config.dart';
import '../../auth/widgets/loading_kopi.dart';

class PerusahaanScreen extends StatefulWidget {
  const PerusahaanScreen({super.key});

  @override
  State<PerusahaanScreen> createState() => _PerusahaanScreenState();
}

class _PerusahaanScreenState extends State<PerusahaanScreen> {
  late Future<List<Map<String, dynamic>>> _futurePerusahaan;
  List<Map<String, dynamic>> _allPerusahaan = [];
  List<Map<String, dynamic>> _filteredPerusahaan = [];
  String? _selectedLokasi;
  bool _lokasiMenuOpen = false;
  OverlayEntry? _lokasiOverlay;
  final LayerLink _lokasiLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futurePerusahaan = fetchPerusahaan();
  }

  @override
  void dispose() {
    _lokasiOverlay?.remove();
    _lokasiOverlay = null;
    _searchController.dispose();
    super.dispose();
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

        final lokasiOptions = _locationsOf(perusahaanList);
        if (_selectedLokasi != null &&
            !lokasiOptions.contains(_selectedLokasi)) {
          _selectedLokasi = null;
        }

        setState(() {
          _allPerusahaan = perusahaanList;
          _filteredPerusahaan = _applyFilters(perusahaanList);
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

  List<String> _locationsOf(List<Map<String, dynamic>> items) {
    final set = <String>{};
    for (final item in items) {
      final lokasi = (item['alamat_perusahaan'] ?? '').toString().trim();
      if (lokasi.isNotEmpty) set.add(lokasi);
    }
    final result = set.toList()..sort();
    return result;
  }

  List<Map<String, dynamic>> _applyFilters([List<Map<String, dynamic>>? source]) {
    final items = source ?? _allPerusahaan;
    final query = _searchController.text.trim().toLowerCase();

    return items.where((perusahaan) {
      final nama = (perusahaan['nama_perusahaan'] ?? '')
          .toString()
          .toLowerCase();
      final alamat = (perusahaan['alamat_perusahaan'] ?? '')
          .toString()
          .toLowerCase();
      final matchesSearch =
          query.isEmpty || nama.contains(query) || alamat.contains(query);
      final matchesLokasi =
          _selectedLokasi == null ||
          (perusahaan['alamat_perusahaan'] ?? '').toString().trim() ==
              _selectedLokasi;
      return matchesSearch && matchesLokasi;
    }).toList();
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredPerusahaan = _applyFilters();
    });
  }

  void _selectLokasi(String? lokasi) {
    setState(() {
      _selectedLokasi = lokasi;
      _filteredPerusahaan = _applyFilters();
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
                          color: AppColors.textMain,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      "Perusahaan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.textMain,
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
                onChanged: _filterSearch,
                decoration: InputDecoration(
                  hintText: "Cari Perusahaan...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterSearch('');
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

            if (_locationsOf(_allPerusahaan).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLokasiFilter(),
              ),
              const SizedBox(height: 20),
            ],

            // 3. Daftar Perusahaan Menggunakan FutureBuilder
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futurePerusahaan,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingKopi(
                      pesan: 'Menyeduh Perusahaan...',
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

  Widget _buildLokasiFilter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CompositedTransformTarget(
          link: _lokasiLink,
          child: SizedBox(
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _toggleLokasiMenu(constraints.maxWidth),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EDE6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF818080)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Color(0xFF4B2E2B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedLokasi ?? 'Lokasi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC69C6D),
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _lokasiMenuOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: Color(0xFF4B2E2B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleLokasiMenu(double width) {
    if (_lokasiMenuOpen) {
      _closeLokasiMenu();
    } else {
      _openLokasiMenu(width);
    }
  }

  void _openLokasiMenu(double width) {
    _lokasiOverlay?.remove();
    _lokasiOverlay = OverlayEntry(
      builder: (context) => _buildLokasiOverlay(width),
    );
    Overlay.of(context, rootOverlay: true).insert(_lokasiOverlay!);
    setState(() => _lokasiMenuOpen = true);
  }

  void _closeLokasiMenu() {
    if (_lokasiOverlay == null && !_lokasiMenuOpen) return;
    _lokasiOverlay?.remove();
    _lokasiOverlay = null;
    if (!mounted) {
      _lokasiMenuOpen = false;
      return;
    }
    setState(() => _lokasiMenuOpen = false);
  }

  Widget _buildLokasiOverlay(double width) {
    final options = _locationsOf(_allPerusahaan);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeLokasiMenu,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _lokasiLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              constraints: const BoxConstraints(maxHeight: 288),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDE6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF818080)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: const Color(0xFFF3EDE6),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: options.length + 1,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: const Color(0xFF818080).withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final String? value = index == 0
                          ? null
                          : options[index - 1];
                      final String label =
                          index == 0 ? 'Semua Lokasi' : options[index - 1];

                      return InkWell(
                        onTap: () {
                          _selectLokasi(value);
                          _closeLokasiMenu();
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B2E2B),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
