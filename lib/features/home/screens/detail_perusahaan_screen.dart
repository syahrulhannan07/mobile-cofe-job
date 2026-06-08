// lib/features/home/screens/detail_perusahaan_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../jobs/screens/detail_lowongan_screen.dart';

class DetailPerusahaanScreen extends StatefulWidget {
  final Map<String, dynamic> companyData;

  const DetailPerusahaanScreen({super.key, required this.companyData});

  @override
  State<DetailPerusahaanScreen> createState() => _DetailPerusahaanScreenState();
}

class _DetailPerusahaanScreenState extends State<DetailPerusahaanScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _fullData;
  bool _isLoading = true;
  String? _errorMessage;

  // AnimationController untuk header masuk
  late AnimationController _headerController;
  late Animation<double> _headerFadeAnim;
  late Animation<Offset> _headerSlideAnim;

  // Controllers untuk setiap job card (staggered)
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardFadeAnims = [];
  final List<Animation<Offset>> _cardSlideAnims = [];

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));

    _headerController.forward();
    _fetchDetailPerusahaan();
  }

  @override
  void dispose() {
    _headerController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Setup animasi staggered untuk tiap job card
  void _setupCardAnimations(int count) {
    // Dispose controller lama jika ada
    for (final c in _cardControllers) {
      c.dispose();
    }
    _cardControllers.clear();
    _cardFadeAnims.clear();
    _cardSlideAnims.clear();

    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      );
      _cardControllers.add(controller);
      _cardFadeAnims.add(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      _cardSlideAnims.add(
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
      );
    }

    // Trigger staggered dengan delay per index
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: 120 + i * 90), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  Future<void> _fetchDetailPerusahaan() async {
    final idPerusahaan = widget.companyData['id_perusahaan'];

    if (idPerusahaan == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID perusahaan tidak ditemukan';
      });
      return;
    }

    try {
      final uri = Uri.parse(ApiConfig.detailPerusahaan(idPerusahaan));

      if (kDebugMode) debugPrint('[DetailPerusahaan] Fetching: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('[DetailPerusahaan] Status: ${response.statusCode}');
        debugPrint('[DetailPerusahaan] Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        Map<String, dynamic>? perusahaanData;

        if (jsonBody is Map && jsonBody['data'] != null) {
          perusahaanData = Map<String, dynamic>.from(jsonBody['data']);
        } else if (jsonBody is Map) {
          perusahaanData = Map<String, dynamic>.from(jsonBody);
        }

        if (kDebugMode && perusahaanData != null) {
          final lowongan = perusahaanData['lowongan'];
          debugPrint('[DetailPerusahaan] Lowongan type: ${lowongan.runtimeType}');
          debugPrint('[DetailPerusahaan] Lowongan count: ${lowongan is List ? lowongan.length : "bukan list"}');
        }

        setState(() {
          _fullData = perusahaanData;
          _isLoading = false;
        });

        // Setup animasi setelah data tersedia
        if (perusahaanData != null) {
          final jobs = _getJobsFromData(perusahaanData);
          if (jobs.isNotEmpty) _setupCardAnimations(jobs.length);
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data (${response.statusCode})';
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DetailPerusahaan] Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal terhubung ke server';
      });
    }
  }

  List<dynamic> _getJobsFromData(Map<String, dynamic> data) {
    final raw = data['lowongan'];
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return [];
  }

  Map<String, dynamic> get _activeData => _fullData ?? widget.companyData;

  List<dynamic> get _activeJobs => _getJobsFromData(_activeData);

  String get _name => _activeData['nama_perusahaan'] ?? 'Tanpa Nama Perusahaan';
  String? get _logoUrl => _activeData['logo_perusahaan'];
  String get _address => _activeData['alamat_perusahaan'] ?? 'Lokasi tidak diset';
  String get _desc => _activeData['deskripsi'] ?? 'Tidak ada deskripsi tentang perusahaan ini.';
  String get _email => _activeData['email']?.toString() ?? '-';
  String get _tanggalBerdiri => _activeData['tanggal_berdiri']?.toString() ?? '-';
  String? get _kecamatan => _activeData['kecamatan']?.toString();
  String? get _tagline => _activeData['tagline']?.toString();

  String get _fullAddress {
    String full = _address;
    if (_kecamatan != null && _kecamatan!.isNotEmpty && !full.contains(_kecamatan!)) {
      full += ', $_kecamatan';
    }
    if (!full.toLowerCase().contains('indramayu')) {
      full += ', Indramayu';
    }
    return full;
  }

  // ─── Warna tema ────────────────────────────────────────────────────────────
  // Gradient utama: coklat hangat → coklat gelap (sesuai AppColors brand)
  static const _gradStart = AppColors.brownDark;   // coklat tua hangat
  static const _gradEnd   = AppColors.textMain;   // coklat espresso gelap
  static const _accentAmber = Color(0xFFF5C842); // aksen kuning emas
  static const _cardBg    = Color(0xFFFAF7F4);   // krem terang untuk background

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Detail Perusahaan',
          style: TextStyle(
            color: Colors.white,
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
            // Header dengan gradient — tidak terpisah putih lagi
            FadeTransition(
              opacity: _headerFadeAnim,
              child: SlideTransition(
                position: _headerSlideAnim,
                child: _buildCompanyHeader(),
              ),
            ),
            const SizedBox(height: 20),
            // Info card
            _buildCompanyInfoCard(),
            const SizedBox(height: 24),
            // Section lowongan
            _buildJobsSectionHeader(),
            const SizedBox(height: 12),
            _buildJobsContent(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Header Gradient ───────────────────────────────────────────────────────

  Widget _buildCompanyHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradStart, _gradEnd],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Dekorasi lingkaran samar di background
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Konten utama
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 70, // safe area + appbar
              20,
              36,
            ),
            child: Column(
              children: [
                // Logo dengan border ring emas
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accentAmber, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(4),
                      child: _logoUrl != null && _logoUrl!.isNotEmpty
                          ? Image.network(
                              _logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.storefront_rounded,
                                color: _gradStart,
                                size: 48,
                              ),
                            )
                          : const Icon(
                              Icons.storefront_rounded,
                              color: _gradStart,
                              size: 48,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Nama perusahaan
                Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
                // Tagline
                if (_tagline != null && _tagline!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accentAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentAmber.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Text(
                      _tagline!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _accentAmber,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Alamat
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _fullAddress,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats row: jumlah lowongan & email
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildStatChip(
                      icon: Icons.work_outline_rounded,
                      label: _isLoading
                          ? '...'
                          : '${_activeJobs.length} Lowongan',
                    ),
                    _buildStatChip(
                      icon: Icons.email_outlined,
                      label: _email.length > 22
                          ? '${_email.substring(0, 20)}…'
                          : _email,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Info Card ─────────────────────────────────────────────────────────────

  Widget _buildCompanyInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _gradStart.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_gradStart, _gradEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sekilas tentang perusahaan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _gradEnd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nama', _name),
            _buildInfoRow('Email Bisnis', _email),
            _buildInfoRow('Alamat', _fullAddress),
            _buildInfoRow('Tanggal Berdiri', _tanggalBerdiri),
            _buildInfoRow('Deskripsi', _desc, isMultiLine: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _gradEnd,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: isMultiLine ? TextAlign.justify : TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lowongan Section Header ───────────────────────────────────────────────

  Widget _buildJobsSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lowongan Aktif',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _gradEnd,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'di $_name',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _isLoading
              ? Container(
                  width: 72,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: _activeJobs.isNotEmpty
                        ? const LinearGradient(
                            colors: [_gradStart, _gradEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _activeJobs.isEmpty ? Colors.grey[200] : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _activeJobs.isNotEmpty
                        ? [
                            BoxShadow(
                              color: _gradStart.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    '${_activeJobs.length} Posisi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _activeJobs.isNotEmpty ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ─── Lowongan Content ──────────────────────────────────────────────────────

  Widget _buildJobsContent() {
    // State 1: Loading
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: List.generate(
            2,
            (i) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _buildSkeletonCard(),
            ),
          ),
        ),
      );
    }

    // State 2: Error
    if (_errorMessage != null && _fullData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Icon(Icons.wifi_off_rounded, size: 36, color: Colors.red[300]),
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchDetailPerusahaan();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: _gradStart),
                label: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: _gradStart, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // State 3: Kosong
    if (_activeJobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Icon(Icons.work_off_rounded, size: 38, color: Colors.grey[300]),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada lowongan aktif\nuntuk saat ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // State 4: List lowongan dengan animasi staggered
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activeJobs.length,
        itemBuilder: (context, index) {
          final job = _activeJobs[index];
          final Map<String, dynamic> jobMap = job is Map<String, dynamic>
              ? job
              : Map<String, dynamic>.from(job as Map);

          // Animasi staggered: fade + slide up
          if (index < _cardControllers.length) {
            return FadeTransition(
              opacity: _cardFadeAnims[index],
              child: SlideTransition(
                position: _cardSlideAnims[index],
                child: _buildJobItemCard(context: context, jobData: jobMap, index: index),
              ),
            );
          }
          // Fallback tanpa animasi (jika controller belum siap)
          return _buildJobItemCard(context: context, jobData: jobMap, index: index);
        },
      ),
    );
  }

  // Skeleton shimmer card saat loading
  Widget _buildSkeletonCard() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 14,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 11,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  height: 26,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 26,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Job Card ──────────────────────────────────────────────────────────────

  Widget _buildJobItemCard({
    required BuildContext context,
    required Map<String, dynamic> jobData,
    int index = 0,
  }) {
    final String position = jobData['posisi'] ?? 'Posisi tidak dispesifikasi';
    final String location = jobData['lokasi'] ?? 'Lokasi belum diatur';

    String salary;
    final rawGaji = jobData['gaji'];
    if (rawGaji == null) {
      salary = 'Gaji Dirahasiakan';
    } else {
      salary = rawGaji.toString();
    }

    // Warna aksen berbeda tiap card (rotasi dari palet)
    final List<List<Color>> accentPalettes = [
      [const Color(0xFF6B3A2A), const Color(0xFF3D1F10)],
      [const Color(0xFF8B5E3C), const Color(0xFF5C3317)],
      [const Color(0xFF7A4930), const Color(0xFF4A2810)],
    ];
    final palette = accentPalettes[index % accentPalettes.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: palette[0].withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: palette[0].withValues(alpha: 0.07),
          highlightColor: Colors.transparent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailLowonganScreen(lowongan: jobData),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ikon posisi dengan gradient kiri
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: palette,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: palette[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
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
                          fontSize: 15,
                          color: _gradEnd,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        jobData['nama_kafe'] ?? _name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
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
                                    salary == 'Gaji Dirahasiakan'
                                ? salary
                                : 'Rp $salary',
                            bgColor: palette[0].withValues(alpha: 0.10),
                            textColor: palette[0],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow button
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: palette,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette[0].withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor.withValues(alpha: 0.85)),
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