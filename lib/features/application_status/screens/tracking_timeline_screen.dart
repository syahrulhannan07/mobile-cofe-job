// lib/features/home/screens/tracking_timeline_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_config.dart';

class TrackingTimelineScreen extends StatefulWidget {
  final int lamaranId;

  const TrackingTimelineScreen({super.key, required this.lamaranId});

  @override
  State<TrackingTimelineScreen> createState() => _TrackingTimelineScreenState();
}

class _TrackingTimelineScreenState extends State<TrackingTimelineScreen> {
  bool _isLoading = true;
  bool _submitting = false; // [UPDATE LOGIC] state tombol konfirmasi
  String? _errorMessage;

  Map<String, dynamic>? _data;
  Map<String, dynamic>? _wawancara;
  List<dynamic> _timelineData = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _fetchDetailLamaran();
    });
  }

  Future<void> _fetchDetailLamaran() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final String targetedUrl = ApiConfig.detailLamaran(widget.lamaranId);
      debugPrint("=== CALLING DETAIL API ===");
      debugPrint("Targeted URL: $targetedUrl");

      final response = await http.get(
        Uri.parse(targetedUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Detail Response Code: ${response.statusCode}");
      debugPrint("Detail Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final apiData = jsonResponse['data'];

          setState(() {
            _data = apiData;
            _wawancara = apiData['wawancara'];

            debugPrint("=== API DATA logo_kafe ===");
            debugPrint("logo_kafe: ${apiData['logo_kafe']}");
            debugPrint("nama_kafe: ${apiData['nama_kafe']}");
            if (apiData['timeline'] != null && apiData['timeline'] is List) {
              final rawTimeline = apiData['timeline'] as List;

              // BALIK DATA TERLEBIH DAHULU (Menjadi ASC: log lama ke baru)
              final reversedTimeline = List.from(rawTimeline.reversed);

              // SISTEMATIKAL FILTERING (Menghilangkan double container wawancara)
              // Kita kumpulkan data timeline secara bersih, sama persis dengan logic map di React
              _timelineData = reversedTimeline;
            } else {
              _timelineData = [];
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Gagal memuat data detail lamaran.";
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage =
              "Data tidak ditemukan (404). Silakan periksa kembali integrasi ID database.";
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              "Error Server internal: Status ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error detail lamaran screen: $e");
      setState(() {
        _errorMessage =
            "Koneksi gagal atau terjadi galat dalam memproses data.";
        _isLoading = false;
      });
    }
  }

  String _formatTanggal(String? tanggalRaw, {bool denganJam = false}) {
    if (tanggalRaw == null || tanggalRaw.isEmpty) {
      return 'Tanggal tidak tersedia';
    }
    try {
      DateTime dateTime = DateTime.parse(tanggalRaw).toLocal();
      if (denganJam) {
        return DateFormat("dd MMMM yyyy - HH:mm", "id_ID").format(dateTime);
      }
      return DateFormat("dd MMMM yyyy", "id_ID").format(dateTime);
    } catch (e) {
      return tanggalRaw;
    }
  }

  // [UPDATE LOGIC] Handler konfirmasi wawancara — sesuai website React
  Future<void> _handleKonfirmasi(BuildContext ctx) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/pelamar/lamaran/${widget.lamaranId}/konfirmasi-wawancara',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final json = jsonDecode(response.body);
      if (!mounted) return;
      if (json['status'] == 'success') {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih! Konfirmasi Anda telah terkirim ke perusahaan.'),
            backgroundColor: Color(0xFF3D2722),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim konfirmasi. Silakan coba lagi nanti.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error konfirmasi: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim konfirmasi. Silakan coba lagi nanti.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showJadwalPopup(BuildContext context) {
    if (_wawancara == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          elevation: 20,
          backgroundColor: const Color(0xFFFFFBF8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0EDE9), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.brownDark,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Detail Jadwal Wawancara",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D1B18),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_wawancara != null) ...[
                        // Nama Pelamar + Status (satu baris, sesuai website)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _buildPopupDetailRow(
                                "Nama Pelamar",
                                _data?['nama_pelamar'] ?? 'Pelamar',
                                Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 6),
                                  child: Text(
                                    "Status",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0x993D2722),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBB041),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 13,
                                        color: Color(0xFF2D1B18),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _wawancara?['status_jadwal'] ??
                                            _wawancara?['status'] ??
                                            'Terjadwal',
                                        style: const TextStyle(
                                          color: Color(0xFF3D2722),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Lokasi dengan brown icon box (sesuai website)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 6),
                              child: Text(
                                "Lokasi / Link Pertemuan",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0x993D2722),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F4F1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF805000),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFFFBB041),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _data?['nama_kafe'] ?? '-',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2D1B18),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _wawancara?['lokasi'] ?? '-',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0x993D2722),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Tanggal & Waktu
                        _buildPopupDetailRow(
                          "Tanggal & Waktu",
                          _formatTanggal(
                            _wawancara?['tanggal'] ??
                                _wawancara?['waktu_wawancara'],
                            denganJam: true,
                          ),
                          Icons.access_time_rounded,
                        ),

                        if (_wawancara?['catatan'] != null &&
                            (_wawancara?['catatan']?.toString().isNotEmpty ??
                                false)) ...[
                          const SizedBox(height: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 6),
                                child: Text(
                                  "Catatan Tambahan",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0x993D2722),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F4F1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '"${_wawancara?['catatan']}"',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0x993D2722),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              "Data jadwal wawancara belum tersedia.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Footer (sesuai website: bg lebih gelap + tombol kanan)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EDE9),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _handleKonfirmasi(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBB041),
                        disabledBackgroundColor: const Color(0xFFFBB041).withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF3D2722),
                              ),
                            )
                          : const Text(
                              "Konfirmasi",
                              style: TextStyle(
                                color: Color(0xFF3D2722),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupDetailRow(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0x993D2722),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF8B5E3C)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D1B18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brownDark),
        ),
      );
    }

    if (_errorMessage != null || _data == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage ?? "Data lamaran tidak ditemukan.",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _fetchDetailLamaran,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brownDark,
                  ),
                  child: const Text(
                    "Coba Lagi",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    String tanggalLamar = 'Tanggal tidak tersedia';
    if (_data!['timeline'] != null && (_data!['timeline'] as List).isNotEmpty) {
      tanggalLamar = _formatTanggal(
        _data!['timeline'][_data!['timeline'].length - 1]['waktu'] ??
            _data!['timeline'][_data!['timeline'].length - 1]['created_at'],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.brownDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tracking Timeline",
          style: TextStyle(
            color: AppColors.brownDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetailLamaran,
        color: AppColors.brownDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(tanggalLamar),
              const SizedBox(height: 30),

              const Center(
                child: Text(
                  "Tracking Timeline",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brownDark,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              _timelineData.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          "Belum ada log log aktivitas timeline.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _timelineData.length,
                      itemBuilder: (context, index) {
                        final log = _timelineData[index];
                        String statusLog = log['status'] ?? '';
                        String keteranganLog = log['keterangan'] ?? '';

                        String title = statusLog;
                        String description = keteranganLog;
                        bool hasAction = false;

                        // MENYAMAKAN SISTEMATIKAL DENGAN BACKEND LARAVEL/REACT
                        if (statusLog == 'Diproses') {
                          title = 'Lamaran Dikirim';
                          description =
                              'Lamaran Anda telah berhasil diterima oleh tim rekrutmen ${_data!['nama_kafe'] ?? 'perusahaan'}.';
                        } else if (statusLog == 'Dalam Review') {
                          title = 'Dalam Review';
                          description =
                              'Tim HRD sedang meninjau portofolio dan pengalaman kerja Anda.';
                        } else if (statusLog == 'Wawancara') {
                          if (keteranganLog ==
                              'Jadwal wawancara telah dibuat.') {
                            title = 'Jadwal Wawancara';
                            description = 'Anda diundang untuk sesi wawancara.';
                            hasAction = true;
                          } else {
                            title = 'Lamaran Diterima';
                            description =
                                'Lamaran anda lolos seleksi, selanjutnya tunggu informasi jadwal wawancara Anda.';
                            hasAction = false;
                          }
                        } else if (statusLog == 'Diterima') {
                          title = 'Lamaran Diterima';
                          description =
                              'Selamat! Anda dinyatakan diterima. Silakan tunggu informasi lebih lanjut dari perusahaan.';
                        } else if (statusLog == 'Ditolak') {
                          title = 'Lamaran Tidak Diterima';
                          description =
                              'Terima kasih atas lamaran Anda. Mohon maaf, lamaran Anda belum dapat diproses ke tahap selanjutnya.';
                        }

                        return _buildTimelineItem(
                          context: context,
                          title: title,
                          subtitle: _formatTanggal(
                            log['waktu'] ?? log['created_at'],
                            denganJam: true,
                          ),
                          description: description,
                          isLast: index == _timelineData.length - 1,
                          hasAction: hasAction,
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun URL logo persis seperti logika website React:
  ///   logo.startsWith('http') || logo.startsWith('/') → pakai apa adanya (disambung storageRoot)
  ///   selain itu → '/storage/' + logo
  ///
  /// Website memakai path relatif dari domain-nya sendiri (/storage/...).
  /// Di Flutter kita perlu storageRoot = root domain Laravel (bukan endpoint /api/...).
  /// Contoh: ApiConfig.baseUrl = "https://api.example.com/api"
  ///         → storageRoot      = "https://api.example.com"
  String _buildLogoUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final s = raw.trim();

    // Sudah URL lengkap → langsung pakai
    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    // Hitung storageRoot: buang segmen "/api" (atau "/api/v1" dll) dari baseUrl
    // agar sejajar dengan cara website memakai path relatif dari root domain.
    String base = ApiConfig.baseUrl.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);

    // Buang suffix "/api", "/api/v1", "/api/v2" dsb jika ada
    final apiSuffixPattern = RegExp(r'(/api(/v\d+)?)$');
    final storageRoot = base.replaceFirst(apiSuffixPattern, '');

    // Sama persis dengan kondisi website:
    // logo.startsWith('/') → storageRoot + logo
    if (s.startsWith('/')) return '$storageRoot$s';

    // Selain itu → storageRoot + '/storage/' + logo
    return '$storageRoot/storage/$s';
  }

  Widget _buildHeaderCard(String tanggalLamar) {
    final String? logoKafe = _data?['logo_kafe'];
    final String logoUrl = _buildLogoUrl(logoKafe);

    debugPrint("=== LOGO DEBUG ===");
    debugPrint("logo_kafe raw   : $logoKafe");
    debugPrint("logo_kafe url   : $logoUrl");
    debugPrint("ApiConfig.base  : ${ApiConfig.baseUrl}");

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brownDark,
        borderRadius: BorderRadius.circular(25),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFFBB041), width: 6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Perusahaan — persis seperti website
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFC69C6D),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    headers: const {
                      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint("Logo gagal dimuat: $error");
                      debugPrint("URL yang dicoba  : $logoUrl");
                      // Fallback: icon toko (setara placeholderProfile di website)
                      return Container(
                        color: const Color(0xFFC69C6D),
                        child: const Icon(
                          Icons.store_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFFC69C6D),
                    child: const Icon(
                      Icons.store_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          // Info Utama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _data?['posisi'] ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _data?['nama_kafe'] ?? '-',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Dikirim pada $tanggalLamar",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBB041),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _data?['status_saat_ini'] ?? _data?['status'] ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF3D2722),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required bool isLast,
    bool hasAction = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: AppColors.brownDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.coffee_rounded,
                color: Color(0xFFFBB041),
                size: 20,
              ),
            ),
            if (!isLast)
              Container(width: 3, height: 110, color: AppColors.brownDark),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF3D2722),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brownDark,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                            if (hasAction) ...[
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => _showJadwalPopup(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFBB041),
                                  minimumSize: const Size(double.infinity, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Lihat Jadwal",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF3D2722),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}