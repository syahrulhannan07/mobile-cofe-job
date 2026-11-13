// lib/features/home/screens/tracking_timeline_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_config.dart';
import '../../auth/widgets/loading_kopi.dart';
import '../../face_verification/models/face_verification_outcome.dart';
import '../../face_verification/screens/face_verification_screen.dart';

class TrackingTimelineScreen extends StatefulWidget {
  final int lamaranId;

  const TrackingTimelineScreen({super.key, required this.lamaranId});

  @override
  State<TrackingTimelineScreen> createState() => _TrackingTimelineScreenState();
}

class _TrackingTimelineScreenState extends State<TrackingTimelineScreen> {
  bool _isLoading = true;
  bool _submitting = false; // state proses presensi
  String? _errorMessage;
  String? _presensiError;

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

  // Handler presensi wajah wawancara — sesuai website React
  Future<void> _mulaiPresensi(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _presensiError = null;
    });
    _refreshPresensiDialog(dialogContext, setDialogState);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse(ApiConfig.detailWawancara(widget.lamaranId)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic> body = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          body = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      if (response.statusCode != 200 ||
          body['status'] != 'success' ||
          body['data'] is! Map) {
        if (!mounted) return;
        setState(() {
          _presensiError =
              body['message']?.toString() ??
              'Jadwal wawancara belum dapat dimuat. Silakan coba lagi.';
        });
        _refreshPresensiDialog(dialogContext, setDialogState);
        return;
      }

      final jadwal = Map<String, dynamic>.from(body['data'] as Map);
      if (!mounted) return;

      setState(() {
        _wawancara = {
          ...?_wawancara,
          ...jadwal,
          'tanggal': jadwal['tanggal_wawancara'] ?? _wawancara?['tanggal'],
          'status_jadwal': jadwal['status'] ?? _wawancara?['status_jadwal'],
        };
      });
      _refreshPresensiDialog(dialogContext, setDialogState);

      if (jadwal['presensi'] is Map) {
        if (dialogContext.mounted) Navigator.pop(dialogContext);
        _fetchDetailLamaran();
        return;
      }

      if (jadwal['can_presensi'] != true) {
        if (!mounted) return;
        setState(() {
          _presensiError =
              jadwal['alasan_presensi']?.toString() ??
              'Presensi belum tersedia untuk jadwal ini.';
        });
        _refreshPresensiDialog(dialogContext, setDialogState);
        return;
      }

      final rawIdWawancara = jadwal['id_wawancara'];
      final idWawancara = rawIdWawancara is num
          ? rawIdWawancara.toInt()
          : int.tryParse(rawIdWawancara?.toString() ?? '');

      if (idWawancara == null) {
        if (!mounted) return;
        setState(() {
          _presensiError =
              'Jadwal wawancara tidak valid. Muat ulang detail jadwal terlebih dahulu.';
        });
        _refreshPresensiDialog(dialogContext, setDialogState);
        return;
      }

      final profilResponse = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      String? fotoProfil;
      if (profilResponse.statusCode == 200) {
        final profilBody = jsonDecode(profilResponse.body);
        final profil = profilBody['data'] ?? profilBody;
        if (profil is Map) {
          fotoProfil = profil['foto_profil']?.toString();
        }
      }

      if (fotoProfil == null || fotoProfil.isEmpty) {
        if (!mounted) return;
        setState(() {
          _presensiError =
              'Lengkapi foto profil terlebih dahulu sebelum melakukan presensi.';
        });
        _refreshPresensiDialog(dialogContext, setDialogState);
        return;
      }

      if (!mounted) return;
      final outcome = await Navigator.of(context, rootNavigator: true)
          .push<FaceVerificationOutcome>(
            MaterialPageRoute(
              builder: (_) => FaceVerificationScreen(
                idLamaran: widget.lamaranId,
                idWawancara: idWawancara,
                profilePhoto: fotoProfil,
              ),
            ),
          );

      if (!mounted || outcome == null || !outcome.success) return;

      setState(() {
        _wawancara = {
          ...?_wawancara,
          'presensi': outcome.presensi,
          'status_jadwal': outcome.statusJadwal ?? 'Selesai',
          'can_presensi': false,
          'alasan_presensi': 'Presensi wawancara sudah tercatat.',
        };
        _presensiError = null;
      });
      _refreshPresensiDialog(dialogContext, setDialogState);

      if (dialogContext.mounted) Navigator.pop(dialogContext);
      _fetchDetailLamaran();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presensi berhasil. Kehadiran Anda telah dicatat.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      debugPrint("Error presensi: $e");
      if (!mounted) return;
      setState(() {
        _presensiError =
            'Gagal memproses presensi. Periksa koneksi internet lalu coba lagi.';
      });
      _refreshPresensiDialog(dialogContext, setDialogState);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _refreshPresensiDialog(dialogContext, setDialogState);
      }
    }
  }

  void _refreshPresensiDialog(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) {
    if (dialogContext.mounted) setDialogState(() {});
  }

  String _formatPresensiTime(dynamic raw) {
    if (raw == null) return '';
    try {
      final time = DateTime.parse(raw.toString()).toLocal();
      return DateFormat("dd MMMM yyyy - HH:mm", "id_ID").format(time);
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildPresensiFooter(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) {
    final presensiRaw = _wawancara?['presensi'];
    if (presensiRaw is Map) {
      final presensi = Map<String, dynamic>.from(presensiRaw);
      final waktu = _formatPresensiTime(presensi['waktu_presensi']);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hadir — Identitas terverifikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Presensi Anda sudah tercatat. Perusahaan telah diberi tahu bahwa Anda hadir dan siap diwawancarai.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                    height: 1.5,
                  ),
                ),
                if (waktu.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Waktu presensi: $waktu',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: Color(0xFF3D2722),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final canPresensi = _wawancara?['can_presensi'] == true;
    final statusJadwal = (_wawancara?['status_jadwal'] ?? _wawancara?['status'])
        ?.toString();
    final statusLamaran = (_data?['status_saat_ini'] ?? _data?['status'])
        ?.toString();
    final isScheduleActive =
        statusJadwal == 'Terjadwal' && statusLamaran == 'Wawancara';
    final alasan = _wawancara?['alasan_presensi']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          canPresensi
              ? 'Sudah hadir dan siap diwawancarai? Lakukan presensi wajah. Kehadiran hanya dicatat setelah verifikasi berhasil.'
              : (alasan?.isNotEmpty == true
                    ? alasan!
                    : 'Presensi wajah tersedia pada tanggal wawancara untuk jadwal yang masih aktif.'),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xCC3D2722),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting || !isScheduleActive
                ? null
                : () => _mulaiPresensi(dialogContext, setDialogState),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBB041),
              disabledBackgroundColor: const Color(
                0xFFFBB041,
              ).withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF3D2722),
                    ),
                  )
                : Text(
                    canPresensi
                        ? 'Presensi Wajah'
                        : 'Cek Ketersediaan Presensi',
                    style: const TextStyle(
                      color: Color(0xFF3D2722),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        if (_presensiError != null) ...[
          const SizedBox(height: 10),
          Text(
            _presensiError!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB91C1C),
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  void _showJadwalPopup(BuildContext context) {
    if (_wawancara == null) return;

    setState(() => _presensiError = null);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setDialogState) {
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
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.brownDark,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                "Detail Jadwal",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D1B18),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            Flexible(
                              child: Column(
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
                                        Flexible(
                                          child: Text(
                                            _wawancara?['status_jadwal'] ??
                                                _wawancara?['status'] ??
                                                'Terjadwal',
                                            style: const TextStyle(
                                              color: Color(0xFF3D2722),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
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

                // Footer (presensi wajah / status kehadiran)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EDE9),
                  ),
                  child: _buildPresensiFooter(dialogContext, setDialogState),
                ),
              ],
            ),
          ),
            );
          },
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
      return const LoadingKopi(
          pesan: 'Menyeduh Timeline...',
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
          "Detail Status",
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
          Flexible(
            child: Container(
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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