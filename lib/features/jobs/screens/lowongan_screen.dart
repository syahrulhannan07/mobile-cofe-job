// lib/features/home/screens/lowongan_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/colors.dart';
import 'detail_lowongan_screen.dart';
import '../../../core/network/api_config.dart';
import '../../auth/widgets/loading_kopi.dart';

class LowonganScreen extends StatefulWidget {
  const LowonganScreen({super.key});

  @override
  State<LowonganScreen> createState() => _LowonganScreenState();
}

class _LowonganScreenState extends State<LowonganScreen> {
  List<dynamic> _allLowongan = []; // Data asli dari API
  List<dynamic> _filteredLowongan = []; // Data setelah difilter search bar
  bool _isLoading = true;
  String _errorMessage = "";
  String? _selectedLokasi;
  bool _lokasiMenuOpen = false;
  OverlayEntry? _lokasiOverlay;

  final LayerLink _lokasiLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLowonganData();
  }

  @override
  void dispose() {
    _lokasiOverlay?.remove();
    _lokasiOverlay = null;
    _searchController.dispose();
    super.dispose();
  }

  // ==================== FUNGSI FETCH ALL DATA LOWONGAN ====================
  Future<void> _fetchLowonganData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.lowongan),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        dynamic rawData = jsonResponse['data'];
        List<dynamic> lowonganData = [];

        if (rawData is Map && rawData['data'] != null) {
          lowonganData = rawData['data'];
        } else if (rawData is List) {
          lowonganData = rawData;
        }

        final lokasiOptions = _locationsOf(lowonganData);
        if (_selectedLokasi != null &&
            !lokasiOptions.contains(_selectedLokasi)) {
          _selectedLokasi = null;
        }

        setState(() {
          _allLowongan = lowonganData;
          _filteredLowongan = _applyFilters(lowonganData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              "Gagal memuat data dari server (${response.statusCode})";
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

  List<String> _locationsOf(List<dynamic> items) {
    final set = <String>{};
    for (final item in items) {
      final lokasi = (item['lokasi'] ?? '').toString().trim();
      if (lokasi.isNotEmpty) set.add(lokasi);
    }
    final result = set.toList()..sort();
    return result;
  }

  List<dynamic> _applyFilters([List<dynamic>? source]) {
    final items = source ?? _allLowongan;
    final query = _searchController.text.trim().toLowerCase();

    return items.where((item) {
      final posisi = (item['posisi'] ?? '').toString().toLowerCase();
      final perusahaan = (item['perusahaan']?['nama_perusahaan'] ?? '')
          .toString()
          .toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          posisi.contains(query) ||
          perusahaan.contains(query);
      final matchesLokasi =
          _selectedLokasi == null ||
          (item['lokasi'] ?? '').toString().trim() == _selectedLokasi;
      return matchesSearch && matchesLokasi;
    }).toList();
  }

  // ==================== FUNGSI FILTER SEARCH BAR ====================
  void _filterSearch(String query) {
    setState(() {
      _filteredLowongan = _applyFilters();
    });
  }

  void _selectLokasi(String? lokasi) {
    setState(() {
      _selectedLokasi = lokasi;
      _filteredLowongan = _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. Header Halaman
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
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Lowongan",
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

            // 2. Search Bar
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
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: AppColors.textMain,
                            size: 20,
                          ),
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
            if (_locationsOf(_allLowongan).isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildLokasiFilter(),
            ],
            const SizedBox(height: 20),

            // 3. Area Konten Utama List View
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildLokasiFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
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
      ),
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
    final options = _locationsOf(_allLowongan);

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

  Widget _buildMainContent() {
    if (_isLoading) {
      return const LoadingKopi(
        pesan: 'Menyeduh Lowongan...',
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
              child: const Text(
                "Coba Lagi",
                style: TextStyle(
                  color: AppColors.brownDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
            Center(
              child: Text(
                "Tidak ada lowongan aktif ditemukan.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
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

          // MODIFIKASI: Langsung mengambil string dari database tanpa helper format rupiah
          final String gaji =
              item['gaji']?.toString() ?? "Gaji tidak dicantumkan";

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.cardOutline.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          gaji,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.brownLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: logoUrl != null && logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.brownDark,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.coffee_rounded,
                                    color: AppColors.brownDark,
                                    size: 26,
                                  ),
                            )
                          : const Icon(
                              Icons.coffee_rounded,
                              color: AppColors.brownDark,
                              size: 26,
                            ),
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
