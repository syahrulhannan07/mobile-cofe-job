// lib/features/home/screens/detail_perusahaan_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../jobs/screens/detail_lowongan_screen.dart';

class DetailPerusahaanScreen extends StatefulWidget {
  final Map<String, dynamic> companyData;

  const DetailPerusahaanScreen({super.key, required this.companyData});

  @override
  State<DetailPerusahaanScreen> createState() => _DetailPerusahaanScreenState();
}

class _DetailPerusahaanScreenState extends State<DetailPerusahaanScreen> {
  late List<dynamic> activeJobs;
  late String name;
  late String? logoUrl;
  late String address;
  late String desc;

  @override
  void initState() {
    super.initState();
    _parseCompanyData();
  }

  /// Menyesuaikan parsing dengan struktur response API website:
  /// respons.data.data → setPerusahaan(respons.data.data)
  /// Artinya companyData di sini sudah berupa object perusahaan langsung,
  /// bukan wrapper { data: {...} }
  void _parseCompanyData() {
    // Debug: cetak seluruh key yang ada di companyData untuk investigasi
    if (kDebugMode) {
      debugPrint('=== DetailPerusahaanScreen: companyData keys ===');
      widget.companyData.forEach((key, value) {
        debugPrint('  [$key] → ${value.runtimeType}: $value');
      });
    }

    name = widget.companyData['nama_perusahaan'] ?? 'Tanpa Nama Perusahaan';
    logoUrl = widget.companyData['logo_perusahaan'];
    address = widget.companyData['alamat_perusahaan'] ?? 'Lokasi tidak diset';
    desc = widget.companyData['deskripsi'] ?? 'Tidak ada deskripsi tentang perusahaan ini.';

    // Parsing lowongan yang robust — menangani berbagai kemungkinan struktur
    // sesuai dengan cara website mengakses perusahaan.lowongan
    activeJobs = _extractLowongan(widget.companyData);

    if (kDebugMode) {
      debugPrint('=== Hasil parsing lowongan: ${activeJobs.length} item ===');
      for (int i = 0; i < activeJobs.length; i++) {
        debugPrint('  Lowongan[$i]: ${activeJobs[i]}');
      }
    }
  }

  /// Ekstrak list lowongan dari companyData dengan menangani semua kemungkinan
  /// struktur yang mungkin dikirim oleh API Laravel/backend
  List<dynamic> _extractLowongan(Map<String, dynamic> data) {
    // Kemungkinan 1: data['lowongan'] langsung berupa List (sama seperti website)
    // → perusahaan.lowongan.map(...)
    final dynamic raw = data['lowongan'];

    if (raw == null) {
      if (kDebugMode) debugPrint('[Lowongan] key "lowongan" tidak ada atau null');
      return [];
    }

    if (raw is List) {
      if (kDebugMode) debugPrint('[Lowongan] Ditemukan sebagai List langsung: ${raw.length} item');
      return raw;
    }

    // Kemungkinan 2: API Laravel mengembalikan relasi dengan pagination
    // { data: [...], current_page: 1, ... }
    if (raw is Map) {
      if (kDebugMode) debugPrint('[Lowongan] Ditemukan sebagai Map, keys: ${raw.keys.toList()}');

      // Format pagination Laravel: { data: [...], ... }
      if (raw['data'] != null && raw['data'] is List) {
        if (kDebugMode) debugPrint('[Lowongan] Menggunakan raw["data"] sebagai List');
        return raw['data'] as List;
      }

      // Format lain: { items: [...] }
      if (raw['items'] != null && raw['items'] is List) {
        return raw['items'] as List;
      }
    }

    if (kDebugMode) debugPrint('[Lowongan] Format tidak dikenali: ${raw.runtimeType}');
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Perusahaan",
          style: TextStyle(
            color: AppColors.textMain,
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
            // 1. Header Profil Utama Perusahaan
            _buildCompanyHeader(),
            const SizedBox(height: 16),

            // 2. Info detail perusahaan (seperti website: nama, email, alamat, dll.)
            _buildCompanyInfoCard(),
            const SizedBox(height: 24),

            // 3. Section Header Lowongan Aktif
            _buildJobsSectionHeader(),
            const SizedBox(height: 16),

            // 4. List Lowongan Aktif
            _buildJobsList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          // Logo perusahaan
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brownLight.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Container(
                color: AppColors.brownLight.withValues(alpha: 0.1),
                child: logoUrl != null && logoUrl!.isNotEmpty
                    ? Image.network(
                        logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.brownDark,
                          size: 45,
                        ),
                      )
                    : const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.brownDark,
                        size: 45,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Nama perusahaan
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          // Tagline (jika ada, sesuai website)
          if (widget.companyData['tagline'] != null &&
              widget.companyData['tagline'].toString().isNotEmpty)
            Text(
              widget.companyData['tagline'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.brownDark.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 8),
          // Alamat
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppColors.brownDark,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _buildFullAddress(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun alamat lengkap seperti di website:
  /// alamat_perusahaan + kecamatan (jika belum termasuk) + ", Indramayu"
  String _buildFullAddress() {
    String fullAddress = address;
    final kecamatan = widget.companyData['kecamatan']?.toString();
    if (kecamatan != null &&
        kecamatan.isNotEmpty &&
        !fullAddress.contains(kecamatan)) {
      fullAddress += ', $kecamatan';
    }
    if (!fullAddress.toLowerCase().contains('indramayu')) {
      fullAddress += ', Indramayu';
    }
    return fullAddress;
  }

  Widget _buildCompanyInfoCard() {
    // Info perusahaan dalam format grid label-value seperti tampilan website
    final email = widget.companyData['email']?.toString() ?? '-';
    final tanggalBerdiri = widget.companyData['tanggal_berdiri']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.brownLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.brownDark,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Sekilas tentang perusahaan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Nama", name),
            _buildInfoRow("Email Bisnis", email),
            _buildInfoRow("Alamat", _buildFullAddress()),
            _buildInfoRow("Tanggal Berdiri", tanggalBerdiri),
            _buildInfoRow("Deskripsi", desc, isMultiLine: true),
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
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMain.withValues(alpha: 0.75),
                height: 1.5,
              ),
              textAlign: isMultiLine ? TextAlign.justify : TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "Lowongan di $name",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: activeJobs.isNotEmpty
                  ? AppColors.brownLight.withValues(alpha: 0.2)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${activeJobs.length} Posisi",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: activeJobs.isNotEmpty
                    ? AppColors.brownDark
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    if (activeJobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Icon(
                  Icons.work_off_rounded,
                  size: 40,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Belum ada lowongan aktif untuk saat ini.",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activeJobs.length,
        itemBuilder: (context, index) {
          final job = activeJobs[index];
          // Pastikan job adalah Map sebelum diproses
          if (job is! Map<String, dynamic>) {
            if (kDebugMode) {
              debugPrint('[Lowongan] Item[$index] bukan Map<String,dynamic>: ${job.runtimeType}');
            }
            // Coba konversi jika berupa Map<dynamic, dynamic>
            if (job is Map) {
              return _buildJobItemCard(
                context: context,
                jobData: Map<String, dynamic>.from(job),
                companyName: name,
                logoUrl: logoUrl,
              );
            }
            return const SizedBox.shrink();
          }
          return _buildJobItemCard(
            context: context,
            jobData: job,
            companyName: name,
            logoUrl: logoUrl,
          );
        },
      ),
    );
  }

  Widget _buildJobItemCard({
    required BuildContext context,
    required Map<String, dynamic> jobData,
    required String companyName,
    required String? logoUrl,
  }) {
    final String position = jobData['posisi'] ?? 'Posisi tidak dispesifikasi';
    final String location = jobData['lokasi'] ?? 'Indramayu';

    // Parsing gaji — mengikuti logika format yang sama dengan website
    String salary;
    final rawGaji = jobData['gaji'];
    if (rawGaji == null) {
      salary = 'Gaji Dirahasiakan';
    } else {
      salary = rawGaji.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.brownLight.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          onTap: () {
            // Membungkus data perusahaan induk ke dalam object lowongan
            // seperti yang dilakukan di website: navigate(`/lowongan/${job.id}`, { state: { job } })
            final Map<String, dynamic> completeJobData = Map.from(jobData);
            completeJobData['perusahaan'] = {
              'nama_perusahaan': companyName,
              'logo_perusahaan': logoUrl,
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailLowonganScreen(lowongan: completeJobData),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
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
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
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
                            bgColor:
                                AppColors.brownLight.withValues(alpha: 0.15),
                            textColor: AppColors.brownDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brownLight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.brownDark,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor.withValues(alpha: 0.8)),
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