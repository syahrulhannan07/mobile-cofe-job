import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_config.dart';

class ApplyJobScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ApplyJobScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen>
    with SingleTickerProviderStateMixin {
  int currentStep = 1;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _flyAnimation;

  // --- INTEGRASI STATE API BACKEND (SIPEKA COFE-JOB) ---
  String? idLamaran;
  List<dynamic> dokumenWajib = [];
  List<dynamic> pertanyaanSeleksi = [];

  // Mapping Dokumen Tahap 1: { id_jenis_dokumen: File }
  Map<String, File> uploadedFiles = {};
  Map<String, String> uploadedFileNames = {};

  // Mapping Jawaban Tahap 2: { id_pertanyaan: TextEditingController }
  Map<String, TextEditingController> pertanyaanControllers = {};

  // --- DATA STATE TAHAP 3 (Profil Pelamar) ---
  File? _profileImage;
  String? _networkProfileImageUrl;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inisialisasiLamaranSipeka(); // Ambil dokumen & pertanyaan dinamis dari backend

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _flyAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(1.5, -1.5),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    pertanyaanControllers.forEach((_, controller) => controller.dispose());
    _namaController.dispose();
    _ttlController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // ==========================================
  // INITIALIZATION: MULAI LAMARAN & GET DETAIL
  // ==========================================
  Future<void> _inisialisasiLamaranSipeka() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      // 1. Hit POST /layananLamaran.mulaiLamaran() -> Mengambil id_lamaran dan kriteria dokumen wajib
      final resMulai = await http.post(
        Uri.parse(
          "${ApiConfig.baseUrl}/lamaran/mulai",
        ), // Sesuaikan endpoint endpoint Laravel kamu
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: {"id_lowongan": widget.jobId},
      );

      if (resMulai.statusCode == 200 || resMulai.statusCode == 201) {
        final resData = jsonDecode(resMulai.body);
        if (resData['status'] == 'success') {
          idLamaran = resData['data']['id_lamaran']?.toString();
          dokumenWajib = resData['data']['dokumen_wajib'] ?? [];
        }
      } else {
        // Handle jika profile pelamar belum lengkap di awal (Sesuai catch block Laravel)
        final errData = jsonDecode(resMulai.body);
        _showValidationError(
          errData['message'] ??
              "Gagal memulai lamaran. Pastikan profil Anda lengkap.",
        );
        Navigator.pop(context); // Lempar kembali ke halaman profil/sebelumnya
        return;
      }

      // 2. Hit GET /layananLamaran.getDetailLowongan() -> Mengambil daftar pertanyaan seleksi kustom perusahaan
      final resDetail = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/lowongan/${widget.jobId}/detail",
        ), // Sesuaikan endpoint detail lowongan Anda
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (resDetail.statusCode == 200) {
        final resData = jsonDecode(resDetail.body);
        if (resData['status'] == 'success' &&
            resData['data']['pertanyaan_seleksi'] != null) {
          pertanyaanSeleksi = resData['data']['pertanyaan_seleksi'];

          // Inisialisasi controller dinamis untuk setiap pertanyaan kustom yang ditarik
          for (var p in pertanyaanSeleksi) {
            String idPertanyaan = p['id_pertanyaan'].toString();
            pertanyaanControllers[idPertanyaan] = TextEditingController();
          }
        }
      }

      // 3. Load data Profile Pelamar eksisting untuk kebutuhan Tahap 3
      String? localName = prefs.getString("user_name");
      if (localName != null) _namaController.text = localName;

      final resProfil = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/pelamar/profil"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (resProfil.statusCode == 200) {
        final resData = jsonDecode(resProfil.body);
        var pelamar = resData['data'];
        if (pelamar != null) {
          _namaController.text =
              pelamar['nama_lengkap'] ??
              pelamar['nama_pengguna'] ??
              _namaController.text;
          _ttlController.text = pelamar['tempat_tanggal_lahir'] ?? '';
          _alamatController.text = pelamar['alamat'] ?? '';
          if (pelamar['foto_profil'] != null) {
            _networkProfileImageUrl = pelamar['foto_profil'];
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal inisialisasi runtime lamaran: $e");
      _showValidationError("Terjadi kesalahan jaringan sistem.");
    } finally {
      setState(() => _isLoading = false);
    }
    ;
  }

  // Pengambilan Dokumen Tahap 1 secara Dinamis menggunakan ID jenis dokumen
  Future<void> _pickFile(String idJenisDokumen) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        uploadedFiles[idJenisDokumen] = File(result.files.single.path!);
        uploadedFileNames[idJenisDokumen] = result.files.single.name;
      });
    }
  }

  // Pengambilan Foto Pengguna Tahap 3
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // ==========================================
  // VALIDASI PER STEP SESUAI REQUIREMENT USER
  // ==========================================
  bool _validasiStepLanjut() {
    if (currentStep == 1) {
      // TAHAP 1: Harus mengunggah dokumen yang ditandai wajib oleh lowongan
      for (var doc in dokumenWajib) {
        bool isWajib = doc['wajib'] == true || doc['wajib'] == 1;
        String idDoc = doc['id_jenis_dokumen'].toString();

        if (isWajib && !uploadedFiles.containsKey(idDoc)) {
          _showValidationError(
            "Dokumen ${doc['nama_dokumen']} wajib diunggah sebelum melanjutkan.",
          );
          return false;
        }
      }
    } else if (currentStep == 2) {
      // TAHAP 2: Harus menjawab semua pertanyaan kustom yang disediakan lowongan
      for (var q in pertanyaanSeleksi) {
        String idPertanyaan = q['id_pertanyaan'].toString();
        String jawaban = pertanyaanControllers[idPertanyaan]?.text.trim() ?? "";

        if (jawaban.isEmpty) {
          _showValidationError(
            "Harap jawab semua pertanyaan dari perusahaan sebelum melanjutkan.",
          );
          return false;
        }
      }
    } else if (currentStep == 3) {
      // TAHAP 3: Validasi kelengkapan profile dasar web (profil_pelamar, pendidikan, skill, pengalaman)
      // Jika profile sama sekali belum lengkap / kosong, block melaju ke tahap 4 review.
      if (_namaController.text.trim().isEmpty ||
          _ttlController.text.trim().isEmpty ||
          _alamatController.text.trim().isEmpty) {
        _showValidationError(
          "Profil belum lengkap! Silakan lengkapi profil Anda terlebih dahulu.",
        );
        return false;
      }
    }

    return true;
  }

  void _nextStep() {
    if (!_validasiStepLanjut()) return;

    if (currentStep < 4) {
      setState(() => currentStep++);
    } else if (currentStep == 4) {
      _submitFormLamaran(); // Jika klik kirim di tahap 4 review, lamaran dikirim ke DB
    }
  }

  void _prevStep() {
    if (currentStep > 1) {
      setState(() => currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========================================================
  // PROSES KIRIM LAMARAN - SEQUENTIAL INTEGRATION DATABASE
  // ========================================================
  Future<void> _submitFormLamaran() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (idLamaran == null) {
        _showValidationError("ID lamaran tidak valid.");
        setState(() => _isLoading = false);
        return;
      }

      // STEP 1: Simpan Jawaban Kuesioner (POST /v1/lamaran/{id}/jawaban)
      List<Map<String, dynamic>> listJawaban = [];
      pertanyaanControllers.forEach((idPertanyaan, controller) {
        listJawaban.add({
          "id_pertanyaan": int.parse(idPertanyaan),
          "jawaban": controller.text,
        });
      });

      if (listJawaban.isNotEmpty) {
        var uriJawaban = Uri.parse(
          "${ApiConfig.baseUrl}/lamaran/$idLamaran/jawaban",
        );
        var responseJawaban = await http.post(
          uriJawaban,
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(listJawaban),
        );

        if (responseJawaban.statusCode != 200 &&
            responseJawaban.statusCode != 201) {
          final err = jsonDecode(responseJawaban.body);
          _showValidationError(
            err['message'] ?? "Gagal menyimpan jawaban seleksi.",
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // STEP 2: Sinkronisasi Perubahan Profil (Bebas diupdate/opsional di Tahap 3)
      var uriUpdateProfil = Uri.parse(
        "${ApiConfig.baseUrl}/pelamar/profil/update",
      );
      var profilRequest = http.MultipartRequest('POST', uriUpdateProfil);
      profilRequest.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });
      profilRequest.fields['nama_lengkap'] = _namaController.text;
      profilRequest.fields['tempat_tanggal_lahir'] = _ttlController.text;
      profilRequest.fields['alamat'] = _alamatController.text;
      if (_profileImage != null) {
        profilRequest.files.add(
          await http.MultipartFile.fromPath('foto_profil', _profileImage!.path),
        );
      }
      await profilRequest.send();

      // STEP 3: Unggah Berkas Dokumen (POST /v1/lamaran/{id}/dokumen)
      if (uploadedFiles.isNotEmpty) {
        var uriDokumen = Uri.parse(
          "${ApiConfig.baseUrl}/lamaran/$idLamaran/dokumen",
        );
        var docRequest = http.MultipartRequest('POST', uriDokumen);
        docRequest.headers.addAll({
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        });

        // Loop dan lampirkan semua file berkas yang diupload di Tahap 1 berdasarkan ID Jenis Dokumennya
        for (var entry in uploadedFiles.entries) {
          docRequest.files.add(
            await http.MultipartFile.fromPath(
              'dokumen_${entry.key}',
              entry.value.path,
            ),
          );
        }

        var docStreamedRes = await docRequest.send();
        var docResponse = await http.Response.fromStream(docStreamedRes);

        if (docResponse.statusCode != 200 && docResponse.statusCode != 201) {
          final err = jsonDecode(docResponse.body);
          _showValidationError(
            err['message'] ?? "Gagal mengunggah file dokumen berkas.",
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // STEP 4: Finalisasi / Kirim Lamaran (POST /v1/lamaran/{id}/kirim)
      var uriKirim = Uri.parse("${ApiConfig.baseUrl}/lamaran/$idLamaran/kirim");
      var responseKirim = await http.post(
        uriKirim,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (responseKirim.statusCode == 200 || responseKirim.statusCode == 201) {
        setState(() => currentStep = 5); // Tampilkan Halaman Sukses Animasi
        _animationController.forward();
      } else {
        final errorData = jsonDecode(responseKirim.body);
        _showValidationError(
          errorData['message'] ??
              "Gagal menyelesaikan pengiriman berkas lamaran.",
        );
      }
    } catch (e) {
      _showValidationError(
        "Terjadi kesalahan sistem atau jaringan internet: $e",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep == 5) return _buildSuccessScreen();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _prevStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF0B85E)),
                )
              : Column(
                  children: [
                    _buildHeader(context),
                    _buildStepper(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: _buildCurrentStepContent(),
                      ),
                    ),
                    _buildBottomButtons(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (currentStep) {
      case 1:
        return _buildStep1Dokumen();
      case 2:
        return _buildStep2Pertanyaan();
      case 3:
        return _buildStep3Profile();
      case 4:
        return _buildStep4Review();
      default:
        return const SizedBox();
    }
  }

  // RENDERING TAHAP 1: Menyesuaikan kebutuhan dokumen wajib langsung dari kriteria lowongan DB
  Widget _buildStep1Dokumen() {
    if (dokumenWajib.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            "Tidak ada dokumen persyaratan khusus.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Silakan lengkapi dokumen persyaratan di bawah ini untuk memulai perjalanan kariermu.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        // Generate list upload card secara dinamis berdasarkan data database backend
        ...dokumenWajib.map((doc) {
          String idDoc = doc['id_jenis_dokumen'].toString();
          bool isWajib = doc['wajib'] == true || doc['wajib'] == 1;
          String labelWajib = isWajib ? " (Wajib)" : " (Opsional)";

          return _buildUploadCard(
            Icons.description_rounded,
            "${doc['nama_dokumen']}$labelWajib",
            uploadedFileNames[idDoc] ?? "Ketuk untuk memilih berkas",
            () => _pickFile(idDoc),
            isUploaded: uploadedFiles.containsKey(idDoc),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  // RENDERING TAHAP 2: Menampilkan pertanyaan deskriptif dinamis kustom milik lowongan perusahaan
  Widget _buildStep2Pertanyaan() {
    if (pertanyaanSeleksi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            "Tidak ada pertanyaan seleksi dari perusahaan.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Silakan jawab pertanyaan pada lowongan ini untuk membantu perusahaan mengenal potensi Anda lebih dalam.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        // Generate form input dinamis berdasarkan pertanyaan yang ditarik dari database lowongan
        ...pertanyaanSeleksi.map((q) {
          String idPertanyaan = q['id_pertanyaan'].toString();
          return _buildInputField(
            q['pertanyaan'] ?? "Pertanyaan Seleksi",
            "Tulis jawaban Anda di sini...",
            isTextArea: true,
            controller: pertanyaanControllers[idPertanyaan],
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  // RENDERING TAHAP 3: Edit/Lengkapi profil pelamar
  Widget _buildStep3Profile() {
    ImageProvider profileImageProvider = const NetworkImage(
      'https://via.placeholder.com/150',
    );
    if (_profileImage != null) {
      profileImageProvider = FileImage(_profileImage!);
    } else if (_networkProfileImageUrl != null &&
        _networkProfileImageUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(_networkProfileImageUrl!);
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profileImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0B85E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        _buildInputField(
          "NAMA LENGKAP",
          "Masukkan nama lengkap",
          controller: _namaController,
        ),
        _buildInputField(
          "TEMPAT, TANGGAL LAHIR",
          "Contoh: Indramayu, 12 Mei 2003",
          controller: _ttlController,
        ),
        _buildInputField(
          "ALAMAT LENGKAP",
          "Jl. Lohbener Lama No. 08, Indramayu",
          isTextArea: true,
          controller: _alamatController,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // RENDERING TAHAP 4: Mereview semua jawaban, dokumen, dan profil sebelum klik Kirim
  Widget _buildStep4Review() {
    ImageProvider reviewImageProvider = const NetworkImage(
      'https://via.placeholder.com/150',
    );
    if (_profileImage != null) {
      reviewImageProvider = FileImage(_profileImage!);
    } else if (_networkProfileImageUrl != null &&
        _networkProfileImageUrl!.isNotEmpty) {
      reviewImageProvider = NetworkImage(_networkProfileImageUrl!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Harap periksa kembali ringkasan seluruh kelengkapan data lamaran Anda sebelum dikirim.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          "Profil Pelamar",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF422E26),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: reviewImageProvider),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ttlController.text,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _alamatController.text,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Tanggapan Pertanyaan Seleksi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF422E26),
          ),
        ),
        const SizedBox(height: 10),
        ...pertanyaanSeleksi.map((q) {
          String idPertanyaan = q['id_pertanyaan'].toString();
          return _buildReviewCard(
            q['pertanyaan'] ?? "Pertanyaan",
            pertanyaanControllers[idPertanyaan]?.text ?? "-",
          );
        }),
        const SizedBox(height: 20),
        const Text(
          "Dokumen Terlampir",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF422E26),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: dokumenWajib.map((doc) {
              String idDoc = doc['id_jenis_dokumen'].toString();
              String name = uploadedFileNames[idDoc] ?? "Belum diunggah";
              return _buildFileReviewItem(
                name,
                doc['nama_dokumen'] ?? "Berkas",
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildUploadCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isUploaded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUploaded ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: const Color(0xFFB8860B)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isUploaded
                  ? Colors.green
                  : const Color(0xFFF0B85E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              isUploaded ? "Ganti" : "Pilih",
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    bool isTextArea = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF422E26),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: isTextArea ? 4 : 1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9F7F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildReviewCard(String question, String answer) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            answer.isEmpty ? "-" : answer,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileReviewItem(String fileName, String label) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file,
            color: Color(0xFFF0B85E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  fileName,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            fileName == "Belum diunggah"
                ? Icons.error_outline
                : Icons.check_circle,
            color: fileName == "Belum diunggah" ? Colors.red : Colors.green,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: _prevStep,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF6B4F31),
            ),
          ),
          Expanded(
            child: Text(
              widget.jobTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4F31),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        children: [
          _stepIndicator(1, "Dokumen"),
          _stepLine(1),
          _stepIndicator(2, "Pertanyaan"),
          _stepLine(2),
          _stepIndicator(3, "Profile"),
          _stepLine(3),
          _stepIndicator(4, "Review"),
        ],
      ),
    );
  }

  Widget _stepIndicator(int n, String label) {
    bool isActive = currentStep == n;
    bool isCompleted = currentStep > n;
    return Column(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? const Color(0xFFF0B85E)
                : const Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "$n",
              style: TextStyle(
                color: isActive || isCompleted ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _stepLine(int n) {
    return Expanded(
      child: Container(
        height: 2,
        color: currentStep > n
            ? const Color(0xFFF0B85E)
            : const Color(0xFFE0E0E0),
        margin: const EdgeInsets.only(bottom: 15),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6B4F31)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Kembali",
                style: TextStyle(color: Color(0xFF6B4F31)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0B85E),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                currentStep == 4 ? "Kirim" : "Lanjut",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF422E26),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0B85E),
                  shape: BoxShape.circle,
                ),
                child: SlideTransition(
                  position: _flyAnimation,
                  child: const Icon(
                    Icons.send_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Lamaran Terkirim",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDF2E2),
                foregroundColor: const Color(0xFF422E26),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Selesai",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
