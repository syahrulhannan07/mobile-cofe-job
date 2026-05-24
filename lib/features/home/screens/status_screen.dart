// lib/features/home/screens/status_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_config.dart';
import 'tracking_timeline_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  String selectedStatus = "Semua";
  String kataKunci = "";
  List<dynamic> dataLamaran = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDataLamaran();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataLamaran() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      debugPrint("=== FETCHING RIWAYAT LAMARAN ===");
      debugPrint("URL: ${ApiConfig.riwayatLamaran}");

      final response = await http.get(
        Uri.parse(ApiConfig.riwayatLamaran),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success') {
          setState(() {
            dataLamaran = resData['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Gagal memuat data lamaran dari server.";
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = "Sesi Anda telah berakhir. Silakan login kembali.";
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              "Gagal memuat data (Server Error: ${response.statusCode}).";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data lamaran: $e");
      setState(() {
        _errorMessage =
            "Terjadi kesalahan koneksi internet atau internal sistem.";
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "DIPROSES":
        return Colors.orange;
      case "DALAM REVIEW":
        return Colors.amber;
      case "DITOLAK":
        return Colors.redAccent;
      case "DITERIMA":
        return Colors.green;
      case "WAWANCARA":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> dataTerpilih = dataLamaran.where((item) {
      String posisi = (item['posisi'] ?? 'Posisi Tidak Diketahui')
          .toString()
          .toLowerCase();
      String namaPerusahaan =
          (item['nama_perusahaan'] ??
                  item['nama_kafe'] ??
                  'Kafe Tidak Diketahui')
              .toString()
              .toLowerCase();
      String statusItem =
          (item['status_saat_ini'] ?? item['status'] ?? 'Diproses')
              .toString()
              .toLowerCase();

      bool cocokStatus =
          selectedStatus == "Semua" ||
          statusItem == selectedStatus.toLowerCase() ||
          (selectedStatus == "Wawancara" && statusItem.contains("wawancara"));

      bool cocokTeks =
          posisi.contains(kataKunci.toLowerCase()) ||
          namaPerusahaan.contains(kataKunci.toLowerCase());

      return cocokStatus && cocokTeks;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.brownLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                "Status Lamaran",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textMain,
                ),
              ),
            ),

            _buildSearchBar(),
            _buildStatusTabs(),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF0B85E),
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorState(_errorMessage!)
                  : dataTerpilih.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchDataLamaran,
                      color: const Color(0xFFF0B85E),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: dataTerpilih.length,
                        itemBuilder: (context, index) {
                          final item = dataTerpilih[index];
                          final int lamaranId =
                              item['id'] ??
                              item['id_lamaran'] ??
                              item['lamaran_id'] ??
                              item['id_pendaftaran'] ??
                              0;

                          // LOGIKA SINKRONISASI BASE URL UNTUK PATH LOGO PERUSAHAAN
                          String? rawLogo =
                              item['logo_perusahaan'] ??
                              item['logo'] ??
                              item['foto_kafe'];
                          String? finalLogoUrl;

                          if (rawLogo != null && rawLogo.isNotEmpty) {
                            if (rawLogo.startsWith('http://') ||
                                rawLogo.startsWith('https://')) {
                              finalLogoUrl = rawLogo;
                            } else {
                              // Memotong string url untuk mendapatkan Domain Utama (Contoh: http://vps-anda.com atau http://10.0.2.2:8000)
                              final String baseUrl = ApiConfig.riwayatLamaran
                                  .split('/api')
                                  .first;

                              // Membersihkan prefix slash ganda jika backend mengirimkan value diawali dengan '/'
                              final String cleanPath = rawLogo.startsWith('/')
                                  ? rawLogo.substring(1)
                                  : rawLogo;

                              finalLogoUrl = "$baseUrl/$cleanPath";
                            }
                          }

                          debugPrint(
                            "=== GENERATED LOGO URL FOR CARD: $finalLogoUrl ===",
                          );

                          return _buildStatusCard(
                            context,
                            jobTitle:
                                item['posisi'] ?? 'Posisi Tidak Diketahui',
                            companyName:
                                item['nama_perusahaan'] ??
                                item['nama_kafe'] ??
                                'Kafe Tidak Diketahui',
                            logoUrl: finalLogoUrl,
                            date:
                                item['dibuat_pada'] ??
                                item['tanggal_kirim'] ??
                                'Tanggal tidak tersedia',
                            status:
                                item['status_saat_ini'] ??
                                item['status'] ??
                                'Diproses',
                            id: lamaranId,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            kataKunci = value;
          });
        },
        decoration: const InputDecoration(
          hintText: "Cari posisi atau nama kafe...",
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    List<String> tabs = [
      "Semua",
      "Diproses",
      "Wawancara",
      "Diterima",
      "Ditolak",
    ];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          bool isActive =
              selectedStatus.toUpperCase() == tabs[index].toUpperCase();
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedStatus = tabs[index];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 25),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppColors.brownDark : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[index].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.brownDark : Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            kataKunci.isNotEmpty
                ? "Tidak menemukan hasil untuk '$kataKunci'"
                : "Tidak ada riwayat lamaran dengan status $selectedStatus",
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _fetchDataLamaran,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0B85E),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Coba Lagi",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String jobTitle,
    required String companyName,
    required String? logoUrl,
    required String date,
    required String status,
    required int id,
  }) {
    Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: logoUrl != null && logoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.coffee,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(Icons.coffee, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      companyName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Dikirim pada $date",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  debugPrint("Navigating to detail with Lamaran ID: $id");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TrackingTimelineScreen(lamaranId: id),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      "Lihat Detail",
                      style: TextStyle(
                        color: AppColors.brownLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.brownLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
